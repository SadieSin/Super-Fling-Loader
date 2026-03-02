-- ════════════════════════════════════════════════════
-- VANILLA4 — Sorter Tab
-- Execute AFTER Vanilla1, Vanilla2, Vanilla3
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla4: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages
local BTN_COLOR        = _G.VH.BTN_COLOR
local THEME_TEXT       = _G.VH.THEME_TEXT or Color3.fromRGB(230, 206, 226)

local sorterPage = pages["SorterTab"]
local camera     = workspace.CurrentCamera
local RS         = game:GetService("ReplicatedStorage")
local mouse      = player:GetMouse()

-- ════════════════════════════════════════════════════
-- CONSTANTS
-- ════════════════════════════════════════════════════
local HIGHLIGHT_COLOR = Color3.fromRGB(255, 180, 0)
local PREVIEW_COLOR   = Color3.fromRGB(80, 160, 255)
local PLACED_COLOR    = Color3.fromRGB(60, 210, 100)
local ITEM_GAP        = 0.08
local SORT_TIMEOUT    = 4.0
local CONFIRM_DIST    = 4

-- ════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════
local selectedItems    = {}
local previewPart      = nil
local previewFollowing = false
local previewPlaced    = false
local isSorting        = false
local isStopped        = false   -- paused mid-sort (Stop button)
local sortThread       = nil
local currentItemConn  = nil
local sortSlots        = nil     -- full slot list, preserved for resume
local sortIndex        = 0       -- next slot index to process (1-based)
local sortTotal        = 0
local sortDone         = 0
local overflowBlocked  = false   -- true when grid is too small → block Start

local gridCols   = 3   -- X  (items per row, left→right)
local gridLayers = 1   -- Y  (vertical layers, bottom→top)
local gridRows   = 0   -- Z  (0 = auto, front→back)

local clickSelEnabled = false
local lassoEnabled    = false
local groupSelEnabled = false
local lassoStartPos   = nil
local lassoDragging   = false

local followConn = nil

-- ════════════════════════════════════════════════════
-- ITEM IDENTIFICATION
-- ════════════════════════════════════════════════════
local function isSortableItem(model)
    if not model or not model:IsA("Model") then return false end
    if model == workspace then return false end
    local mp = model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
    if not mp then return false end
    if model:FindFirstChild("TreeClass") then return false end
    return model:FindFirstChild("Owner") ~= nil
        or model:FindFirstChild("PurchasedBoxItemName") ~= nil
        or model:FindFirstChild("DraggableItem") ~= nil
        or model:FindFirstChild("ItemName") ~= nil
end

local function getMainPart(model)
    return model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
end

-- ════════════════════════════════════════════════════
-- SELECTION
-- ════════════════════════════════════════════════════
local function highlightItem(model)
    if selectedItems[model] then return end
    local hl = Instance.new("SelectionBox")
    hl.Color3              = HIGHLIGHT_COLOR
    hl.LineThickness       = 0.06
    hl.SurfaceTransparency = 0.78
    hl.SurfaceColor3       = HIGHLIGHT_COLOR
    hl.Adornee             = model
    hl.Parent              = model
    selectedItems[model]   = hl
end

local function unhighlightItem(model)
    if selectedItems[model] then
        selectedItems[model]:Destroy()
        selectedItems[model] = nil
    end
end

local function unhighlightAll()
    for model, hl in pairs(selectedItems) do
        if hl and hl.Parent then hl:Destroy() end
    end
    selectedItems = {}
end

local function countSelected()
    local n = 0
    for _ in pairs(selectedItems) do n = n + 1 end
    return n
end

local function groupSelectItem(target)
    if not isSortableItem(target) then return end
    local nv = target:FindFirstChild("ItemName") or target:FindFirstChild("PurchasedBoxItemName")
    local targetName = nv and nv.Value or target.Name
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local v = obj:FindFirstChild("ItemName") or obj:FindFirstChild("PurchasedBoxItemName")
            local n = v and v.Value or obj.Name
            if n == targetName then highlightItem(obj) end
        end
    end
end

-- ════════════════════════════════════════════════════
-- SORT SLOT CALCULATOR
-- ════════════════════════════════════════════════════
-- calculateSlots
-- Fills a 3-D grid: left→right (X cols), front→back (Z rows), bottom→top (Y layers).
-- colCount  = items per X column  (gridCols,   ≥1)
-- layerCount= vertical layers     (gridLayers, ≥1; 1 = single layer, original behaviour)
-- rowCount  = rows per layer      (gridRows,   0 = auto)
-- Items sorted tallest-first so tall items sit in row 0 and short ones fill later rows.
-- The bottom layer is filled completely before moving up to the next layer.
local function calculateSlots(items, anchorCF, colCount, layerCount, rowCount)
    colCount   = math.max(1, colCount)
    layerCount = math.max(1, layerCount)
    rowCount   = math.max(0, rowCount)   -- 0 = unlimited / auto

    local entries = {}
    for _, model in ipairs(items) do
        local ok, _cf, sz = pcall(function() return model:GetBoundingBox() end)
        local s = (ok and sz) or Vector3.new(2, 2, 2)
        table.insert(entries, { model = model, w = s.X, h = s.Y, d = s.Z })
    end

    -- Sort tallest first so tall items claim the bottom layer row-0 slots
    table.sort(entries, function(a, b) return a.h > b.h end)

    -- Determine per-layer capacity
    local total       = #entries
    -- rowsPerLayer: if rowCount=0, distribute items evenly across layers
    local rpl
    if rowCount > 0 then
        rpl = rowCount
    else
        local slotsPerLayer = math.ceil(total / layerCount)
        rpl = math.ceil(slotsPerLayer / colCount)
        rpl = math.max(1, rpl)
    end
    -- slotPerLayer = cols × rows
    local slotPerLayer = colCount * rpl

    -- Pre-compute per-row max depth and per-layer max height for proper spacing
    -- We do a two-pass approach: first assign grid positions, then convert to world offsets

    -- Pass 1: assign (layer, row, col) index to each entry
    for i, e in ipairs(entries) do
        local idx   = i - 1                          -- 0-based
        local layer = math.floor(idx / slotPerLayer) -- 0-based layer (bottom first)
        local rem   = idx % slotPerLayer
        local row   = math.floor(rem / colCount)     -- 0-based row within layer
        local col   = rem % colCount                 -- 0-based col within row
        e.layer = layer; e.row = row; e.col = col
    end

    -- Pass 2: compute per-row max-D and per-layer max-H for gap offsets
    -- layerMaxH[layer] = tallest item in that layer
    -- rowMaxD[layer][row] = deepest item in that row
    local layerMaxH = {}
    local rowMaxD   = {}
    for _, e in ipairs(entries) do
        local l, r = e.layer, e.row
        layerMaxH[l] = math.max(layerMaxH[l] or 0, e.h)
        if not rowMaxD[l] then rowMaxD[l] = {} end
        rowMaxD[l][r] = math.max(rowMaxD[l][r] or 0, e.d)
    end

    -- Cumulative layer Y offsets (bottom of each layer)
    local layerY = {}
    local accY   = 0
    local maxLayer = 0
    for _, e in ipairs(entries) do if e.layer > maxLayer then maxLayer = e.layer end end
    for l = 0, maxLayer do
        layerY[l] = accY
        accY = accY + (layerMaxH[l] or 0) + ITEM_GAP
    end

    -- Cumulative row Z offsets within each layer
    local rowZ = {}
    for l = 0, maxLayer do
        rowZ[l] = {}
        local accZ = 0
        local maxRow = 0
        for _, e in ipairs(entries) do
            if e.layer == l and e.row > maxRow then maxRow = e.row end
        end
        for r = 0, maxRow do
            rowZ[l][r] = accZ
            accZ = accZ + (rowMaxD[l] and rowMaxD[l][r] or 0) + ITEM_GAP
        end
    end

    -- Per-col max width (shared across all layers/rows for alignment)
    local colMaxW = {}
    for _, e in ipairs(entries) do
        colMaxW[e.col] = math.max(colMaxW[e.col] or 0, e.w)
    end
    local colX = {}; local accX = 0
    for c = 0, colCount - 1 do
        colX[c] = accX
        accX = accX + (colMaxW[c] or 0) + ITEM_GAP
    end

    -- Pass 3: build slot list
    local slots = {}
    for _, e in ipairs(entries) do
        local lx = colX[e.col]   + e.w / 2
        local ly = layerY[e.layer] + e.h / 2
        local lz = (rowZ[e.layer] and rowZ[e.layer][e.row] or 0) + e.d / 2
        local worldCF = anchorCF * CFrame.new(Vector3.new(lx, ly, lz))
        table.insert(slots, { model = e.model, cf = worldCF })
    end

    return slots
end

-- ════════════════════════════════════════════════════
-- PREVIEW BOX
-- ════════════════════════════════════════════════════
local function destroyPreview()
    if followConn then followConn:Disconnect(); followConn = nil end
    if previewPart and previewPart.Parent then previewPart:Destroy() end
    previewPart      = nil
    previewFollowing = false
    previewPlaced    = false
end

local function computePreviewSize()
    local entries = {}
    for model in pairs(selectedItems) do
        local ok, _cf, sz = pcall(function() return model:GetBoundingBox() end)
        local s = (ok and sz) or Vector3.new(2, 2, 2)
        table.insert(entries, { w = s.X, h = s.Y, d = s.Z })
    end
    if #entries == 0 then return 4, 4, 4 end

    local cols   = math.max(1, gridCols)
    local layers = math.max(1, gridLayers)
    local rows   = math.max(0, gridRows)

    local maxW, maxH, maxD = 0, 0, 0
    for _, e in ipairs(entries) do
        if e.w > maxW then maxW = e.w end
        if e.h > maxH then maxH = e.h end
        if e.d > maxD then maxD = e.d end
    end

    local totalItems  = #entries
    local slotPerLayer
    if rows > 0 then
        slotPerLayer = cols * rows
    else
        slotPerLayer = math.ceil(totalItems / layers)
    end
    local actualRows   = math.ceil(slotPerLayer / cols)

    local boxW = cols   * (maxW + ITEM_GAP) - ITEM_GAP
    local boxH = layers * (maxH + ITEM_GAP) - ITEM_GAP
    local boxD = actualRows * (maxD + ITEM_GAP) - ITEM_GAP
    return math.max(boxW, 1), math.max(boxH, 1), math.max(boxD, 1)
end

-- Raycast mouse → world and return a CFrame whose bottom sits on the surface.
-- The preview box cannot go below the hit point.
local function getMouseSurfaceCF(halfH)
    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local params  = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    if previewPart then table.insert(excl, previewPart) end
    local char = player.Character
    if char then table.insert(excl, char) end
    params.FilterDescendantsInstances = excl

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 600, params)

    local hitPos
    if result then
        hitPos = result.Position
    else
        -- fallback: intersect with Y=0 plane (guard against horizontal ray)
        if math.abs(unitRay.Direction.Y) > 0.001 then
            local t = unitRay.Origin.Y / -unitRay.Direction.Y
            if t > 0 then
                hitPos = unitRay.Origin + unitRay.Direction * t
            end
        end
        if not hitPos then
            hitPos = unitRay.Origin + unitRay.Direction * 40
        end
    end

    return CFrame.new(hitPos.X, hitPos.Y + halfH, hitPos.Z)
end

local function buildPreviewBox(sX, sY, sZ)
    if previewPart and previewPart.Parent then previewPart:Destroy() end

    previewPart = Instance.new("Part")
    previewPart.Name         = "VHSorterPreview"
    previewPart.Anchored     = true
    previewPart.CanCollide   = false
    previewPart.CanQuery     = false
    previewPart.CastShadow   = false
    previewPart.Size         = Vector3.new(math.max(sX,0.5), math.max(sY,0.5), math.max(sZ,0.5))
    previewPart.Color        = PREVIEW_COLOR
    previewPart.Material     = Enum.Material.SmoothPlastic
    previewPart.Transparency = 0.50
    previewPart.Parent       = workspace

    local sb = Instance.new("SelectionBox")
    sb.Color3              = PREVIEW_COLOR
    sb.LineThickness       = 0.07
    sb.SurfaceTransparency = 1.0
    sb.Adornee             = previewPart
    sb.Parent              = previewPart
end

local function startPreviewFollow()
    if not (previewPart and previewPart.Parent) then return end
    previewFollowing = true
    previewPlaced    = false

    if followConn then followConn:Disconnect(); followConn = nil end

    followConn = RunService.RenderStepped:Connect(function()
        if not previewFollowing then return end
        if not (previewPart and previewPart.Parent) then
            followConn:Disconnect(); followConn = nil; return
        end
        local halfH    = previewPart.Size.Y / 2
        local targetCF = getMouseSurfaceCF(halfH)
        -- Smooth lerp — feels like the box glides under the mouse
        previewPart.CFrame = previewPart.CFrame:Lerp(targetCF, 0.22)
    end)
end

local function placePreview()
    if not (previewPart and previewPart.Parent) then return end
    if not previewFollowing then return end

    previewFollowing = false
    if followConn then followConn:Disconnect(); followConn = nil end

    -- Snap exactly to ground
    local halfH = previewPart.Size.Y / 2
    previewPart.CFrame = getMouseSurfaceCF(halfH)

    -- Flash green to confirm
    previewPart.Color = PLACED_COLOR
    local sb = previewPart:FindFirstChildOfClass("SelectionBox")
    if sb then sb.Color3 = PLACED_COLOR end

    previewPlaced = true
end

-- ════════════════════════════════════════════════════
-- SORT ENGINE
-- Mirrors the exact server-visible drag pattern from the Item Tab:
--   1. teleport HRP next to the item
--   2. FireServer(model) — tell server we're dragging
--   3. wait a tick
--   4. set mp.CFrame = target
--   5. FireServer(model) again to lock it server-side
-- ════════════════════════════════════════════════════

local function getdragger()
    local i = RS:FindFirstChild("Interaction")
    return i and i:FindFirstChild("ClientIsDragging")
end

-- Move one item to targetCF using the same sequence as the Item Tab.
-- Returns a thread handle (task.spawn) so the caller can cancel if needed.
-- Calls onDone() when finished.
local function moveItemTo(model, targetCF, onDone)
    if not (model and model.Parent) then
        if onDone then task.spawn(onDone) end; return nil
    end
    local mp = getMainPart(model)
    if not mp then
        if onDone then task.spawn(onDone) end; return nil
    end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        if onDone then task.spawn(onDone) end; return nil
    end

    local dragger = getdragger()

    return task.spawn(function()
        -- Step 1: get the character right next to the item (same offset as Item Tab)
        hrp.CFrame = mp.CFrame * CFrame.new(0, 4, 2)
        task.wait(0.12)

        -- Step 2: tell server we are dragging this model
        if dragger then pcall(function() dragger:FireServer(model) end) end
        task.wait(0.08)

        -- Step 3: move the part to the target position
        pcall(function() mp.CFrame = targetCF end)
        task.wait(0.08)

        -- Step 4: fire drag again so server locks the new position
        if dragger then pcall(function() dragger:FireServer(model) end) end
        task.wait(0.22)

        -- Step 5: reinforce a few more times exactly like Item Tab does
        for _ = 1, 3 do
            if dragger then pcall(function() dragger:FireServer(model) end) end
            pcall(function() mp.CFrame = targetCF end)
            task.wait(0.08)
        end

        if onDone then onDone() end
    end)
end

-- ════════════════════════════════════════════════════
-- UI HELPERS
-- ════════════════════════════════════════════════════
local AXIS_COLORS = {
    X = Color3.fromRGB(220,70,70),
    Y = Color3.fromRGB(70,200,70),
    Z = Color3.fromRGB(70,120,255),
}

local function mkLabel(text)
    local lbl = Instance.new("TextLabel", sorterPage)
    lbl.Size = UDim2.new(1,-12,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function mkSep()
    local s = Instance.new("Frame", sorterPage)
    s.Size = UDim2.new(1,-12,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,40,55)
    s.BorderSizePixel = 0
end

local function mkToggle(text, default, cb)
    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1,-12,0,32)
    fr.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local tb = Instance.new("TextButton", fr)
    tb.Size = UDim2.new(0,34,0,18); tb.Position = UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3 = default and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text = ""; Instance.new("UICorner", tb).CornerRadius = UDim.new(1,0)

    local dot = Instance.new("Frame", tb)
    dot.Size = UDim2.new(0,14,0,14)
    dot.Position = UDim2.new(0, default and 18 or 2, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

    local on = default
    if cb then cb(on) end

    tb.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(tb,  TweenInfo.new(0.18, Enum.EasingStyle.Quint),
            { BackgroundColor3 = on and Color3.fromRGB(60,180,60) or BTN_COLOR }):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Quint),
            { Position = UDim2.new(0, on and 18 or 2, 0.5, -7) }):Play()
        if cb then cb(on) end
    end)
    return fr
end

local function mkBtn(text, color, cb)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", sorterPage)
    btn.Size = UDim2.new(1,-12,0,34)
    btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local hov = Color3.fromRGB(
        math.min(color.R*255+22,255)/255,
        math.min(color.G*255+10,255)/255,
        math.min(color.B*255+22,255)/255)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=hov}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=color}):Play()
    end)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

-- ════════════════════════════════════════════════════
-- SLIDER CONNECTIONS (tracked for cleanup)
-- ════════════════════════════════════════════════════
local sliderConns = {}  -- holds { changed=conn, ended=conn } per slider

local function mkIntSlider(label, axis, minV, maxV, defaultV, cb)
    local axCol = AXIS_COLORS[axis] or THEME_TEXT

    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1,-12,0,54)
    fr.BackgroundColor3 = Color3.fromRGB(22,22,30)
    fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0,6)

    local axTag = Instance.new("TextLabel", fr)
    axTag.Size = UDim2.new(0,18,0,22); axTag.Position = UDim2.new(0,8,0,5)
    axTag.BackgroundTransparency = 1; axTag.Font = Enum.Font.GothamBold
    axTag.TextSize = 14; axTag.TextColor3 = axCol; axTag.Text = axis

    local topLbl = Instance.new("TextLabel", fr)
    topLbl.Size = UDim2.new(0.55,0,0,22); topLbl.Position = UDim2.new(0,28,0,5)
    topLbl.BackgroundTransparency = 1; topLbl.Font = Enum.Font.GothamSemibold
    topLbl.TextSize = 12; topLbl.TextColor3 = THEME_TEXT
    topLbl.TextXAlignment = Enum.TextXAlignment.Left; topLbl.Text = label

    local valLbl = Instance.new("TextLabel", fr)
    valLbl.Size = UDim2.new(0.3,0,0,22); valLbl.Position = UDim2.new(0.7,0,0,5)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13; valLbl.TextColor3 = axCol
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = tostring(defaultV)

    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1,-16,0,6); track.Position = UDim2.new(0,8,0,36)
    track.BackgroundColor3 = Color3.fromRGB(38,38,52); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3 = axCol; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0,18,0,18); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((defaultV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(225,225,245); knob.Text = ""
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local dragging = false; local cur = defaultV

    local function apply(screenX)
        local ratio = math.clamp(
            (screenX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1),
            0, 1)
        local val = math.round(minV + ratio*(maxV-minV))
        if val == cur then return end
        cur = val
        fill.Size     = UDim2.new(ratio,0,1,0)
        knob.Position = UDim2.new(ratio,0,0.5,0)
        valLbl.Text   = tostring(val)
        if cb then cb(val) end
    end

    knob.MouseButton1Down:Connect(function() dragging = true end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; apply(inp.Position.X)
        end
    end)

    -- Track these connections so they can be cleaned up
    local sc = {}
    sc.changed = UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            apply(inp.Position.X)
        end
    end)
    sc.ended = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    table.insert(sliderConns, sc)

    return fr
end

-- ════════════════════════════════════════════════════
-- STATUS CARD
-- ════════════════════════════════════════════════════
local statusCard, statusLabel
do
    local card = Instance.new("Frame", sorterPage)
    card.Size = UDim2.new(1,-12,0,48)
    card.BackgroundColor3 = Color3.fromRGB(28,20,38)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(255,180,0); stroke.Thickness = 1; stroke.Transparency = 0.5

    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(1,-16,1,0); lbl.Position = UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255,210,100)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.Text = "Select items to get started."
    statusCard  = card
    statusLabel = lbl
end

local function setStatus(msg, col)
    statusLabel.Text       = msg
    statusLabel.TextColor3 = col or Color3.fromRGB(255,210,100)
end

-- ════════════════════════════════════════════════════
-- PROGRESS BAR
-- ════════════════════════════════════════════════════
local pbContainer, pbFill, pbLabel
do
    local pb = Instance.new("Frame", sorterPage)
    pb.Size = UDim2.new(1,-12,0,44); pb.BackgroundColor3 = Color3.fromRGB(18,18,24)
    pb.BorderSizePixel = 0; pb.Visible = false
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", pb)
    stroke.Color = Color3.fromRGB(60,60,80); stroke.Thickness = 1; stroke.Transparency = 0.5

    local lbl = Instance.new("TextLabel", pb)
    lbl.Size = UDim2.new(1,-12,0,16); lbl.Position = UDim2.new(0,6,0,4)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 11
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Sorting..."

    local track = Instance.new("Frame", pb)
    track.Size = UDim2.new(1,-12,0,12); track.Position = UDim2.new(0,6,0,26)
    track.BackgroundColor3 = Color3.fromRGB(30,30,42); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fl = Instance.new("Frame", track)
    fl.Size = UDim2.new(0,0,1,0); fl.BackgroundColor3 = Color3.fromRGB(255,175,55)
    fl.BorderSizePixel = 0
    Instance.new("UICorner", fl).CornerRadius = UDim.new(1,0)

    pbContainer = pb; pbFill = fl; pbLabel = lbl
end

local function hideProgress(delay)
    task.delay(delay or 2.0, function()
        if not pbContainer then return end
        TweenService:Create(pbContainer, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
        TweenService:Create(pbFill,      TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
        TweenService:Create(pbLabel,     TweenInfo.new(0.4), {TextTransparency=1}):Play()
        task.delay(0.45, function()
            if not pbContainer then return end
            pbContainer.Visible = false
            pbContainer.BackgroundTransparency = 0
            pbFill.BackgroundTransparency = 0
            pbFill.BackgroundColor3 = Color3.fromRGB(255,175,55)
            pbFill.Size = UDim2.new(0,0,1,0)
            pbLabel.TextTransparency = 0
        end)
    end)
end

-- ════════════════════════════════════════════════════
-- OVERFLOW POPUP
-- ════════════════════════════════════════════════════
local overflowPopup, overflowLabel
do
    local pop = Instance.new("Frame", sorterPage)
    pop.Size = UDim2.new(1,-12,0,56)
    pop.BackgroundColor3 = Color3.fromRGB(80,20,20)
    pop.BorderSizePixel = 0
    pop.Visible = false
    Instance.new("UICorner", pop).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", pop)
    stroke.Color = Color3.fromRGB(255,80,80); stroke.Thickness = 1.5; stroke.Transparency = 0.3

    local lbl = Instance.new("TextLabel", pop)
    lbl.Size = UDim2.new(1,-16,1,0); lbl.Position = UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255,140,140)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.Text = ""
    overflowPopup = pop
    overflowLabel = lbl
end

local function showOverflow(msg)
    overflowBlocked = true
    overflowLabel.Text = "⚠  " .. msg
    overflowPopup.Visible = true
end

local function hideOverflow()
    overflowBlocked = false
    overflowPopup.Visible = false
end

-- Returns how many items fit in the current grid settings
local function computeGridCapacity()
    local cols   = math.max(1, gridCols)
    local layers = math.max(1, gridLayers)
    local rows   = math.max(0, gridRows)
    if rows == 0 then return math.huge end   -- auto = unlimited
    return cols * rows * layers
end

-- ════════════════════════════════════════════════════
-- LASSO OVERLAY
-- ════════════════════════════════════════════════════
local coreGui    = game:GetService("CoreGui")
local lassoFrame = Instance.new("Frame", coreGui:FindFirstChild("VanillaHub") or coreGui)
lassoFrame.Name = "SorterLasso"
lassoFrame.BackgroundColor3 = Color3.fromRGB(255,160,40)
lassoFrame.BackgroundTransparency = 0.82
lassoFrame.BorderSizePixel = 0
lassoFrame.Visible = false
lassoFrame.ZIndex  = 20
local lstroke = Instance.new("UIStroke", lassoFrame)
lstroke.Color = Color3.fromRGB(255,210,80); lstroke.Thickness = 1.5

local function updateLassoVis(s, c)
    local minX = math.min(s.X,c.X); local minY = math.min(s.Y,c.Y)
    lassoFrame.Position = UDim2.new(0,minX,0,minY)
    lassoFrame.Size     = UDim2.new(0,math.abs(c.X-s.X),0,math.abs(c.Y-s.Y))
end

local function selectLasso()
    if not lassoStartPos then return end
    local cur  = Vector2.new(mouse.X, mouse.Y)
    local minX = math.min(lassoStartPos.X,cur.X); local maxX = math.max(lassoStartPos.X,cur.X)
    local minY = math.min(lassoStartPos.Y,cur.Y); local maxY = math.max(lassoStartPos.Y,cur.Y)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local mp2 = getMainPart(obj)
            if mp2 then
                local sp, vis = camera:WorldToScreenPoint(mp2.Position)
                if vis and sp.X>=minX and sp.X<=maxX and sp.Y>=minY and sp.Y<=maxY then
                    highlightItem(obj)
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════
-- START / STOP BUTTON  (forward refs so refreshStatus can style them)
-- ════════════════════════════════════════════════════
local startBtn, stopBtn

local function refreshStatus()
    local n = countSelected()
    if isSorting then
        setStatus("⏳  Sorting in progress...", Color3.fromRGB(140,220,255))
    elseif isStopped then
        setStatus("⏸  Paused — hit Start to resume from where it stopped.", Color3.fromRGB(255,210,80))
    elseif overflowBlocked then
        setStatus("❌  Too many items! Increase X, Y, or Z then regenerate.", Color3.fromRGB(255,100,100))
    elseif n == 0 then
        setStatus("👆  Select items with Click, Group, or Lasso.")
    elseif previewFollowing then
        setStatus("🖱  Preview following mouse — RIGHT-CLICK to place.", Color3.fromRGB(140,220,255))
    elseif previewPlaced then
        setStatus("✅  " .. n .. " item(s) ready. Hit Start Sorting!", Color3.fromRGB(100,220,120))
    elseif previewPart then
        setStatus("📦  Preview exists. Right-click anywhere to place it.", Color3.fromRGB(200,200,100))
    else
        setStatus("📦  " .. n .. " selected. Click Generate Preview.", Color3.fromRGB(200,200,120))
    end

    if startBtn then
        local canSort = (n > 0 or isStopped) and (previewPlaced or isStopped) and not isSorting and not overflowBlocked
        startBtn.BackgroundColor3 = canSort and Color3.fromRGB(35,100,50) or Color3.fromRGB(28,28,38)
        startBtn.TextColor3       = canSort and THEME_TEXT or Color3.fromRGB(72,72,82)
        startBtn.Text = isStopped and "▶  Resume Sorting" or "▶  Start Sorting"
    end
    if stopBtn then
        stopBtn.BackgroundColor3 = isSorting and Color3.fromRGB(100,60,20) or Color3.fromRGB(28,28,38)
        stopBtn.TextColor3       = isSorting and Color3.fromRGB(255,190,80) or Color3.fromRGB(72,72,82)
    end
end

-- ════════════════════════════════════════════════════
-- BUILD UI
-- ════════════════════════════════════════════════════
mkLabel("Status")

mkSep(); mkLabel("Selection Mode")

mkToggle("Click Selection", false, function(v)
    clickSelEnabled = v
    if v then lassoEnabled = false; groupSelEnabled = false end
end)
mkToggle("Group Selection", false, function(v)
    groupSelEnabled = v
    if v then clickSelEnabled = false; lassoEnabled = false end
end)
mkToggle("Lasso Tool", false, function(v)
    lassoEnabled = v
    if v then clickSelEnabled = false; groupSelEnabled = false end
end)

local selHint = Instance.new("TextLabel", sorterPage)
selHint.Size = UDim2.new(1,-12,0,26); selHint.BackgroundColor3 = Color3.fromRGB(18,18,24)
selHint.BorderSizePixel = 0; selHint.Font = Enum.Font.Gotham; selHint.TextSize = 11
selHint.TextColor3 = Color3.fromRGB(100,100,130); selHint.TextWrapped = true
selHint.TextXAlignment = Enum.TextXAlignment.Left
selHint.Text = "  Lasso: drag to box-select.  Group: click to select all of same type."
Instance.new("UICorner", selHint).CornerRadius = UDim.new(0,6)
Instance.new("UIPadding", selHint).PaddingLeft = UDim.new(0,6)

mkSep(); mkLabel("Sort Grid  —  X  Width · Y  Height · Z  Depth")

mkIntSlider("Width  (items per row)", "X", 1, 12, 3, function(v)
    gridCols = v
    hideOverflow()
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX,0.5), math.max(sY,0.5), math.max(sZ,0.5))
    end
end)

mkIntSlider("Height  (vertical layers)", "Y", 1, 8, 1, function(v)
    gridLayers = v
    hideOverflow()
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX,0.5), math.max(sY,0.5), math.max(sZ,0.5))
    end
end)

mkIntSlider("Depth  (rows per layer, 0=auto)", "Z", 0, 12, 0, function(v)
    gridRows = v
    hideOverflow()
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX,0.5), math.max(sY,0.5), math.max(sZ,0.5))
    end
end)

local gridHint = Instance.new("TextLabel", sorterPage)
gridHint.Size = UDim2.new(1,-12,0,28); gridHint.BackgroundColor3 = Color3.fromRGB(18,18,24)
gridHint.BorderSizePixel = 0; gridHint.Font = Enum.Font.Gotham; gridHint.TextSize = 11
gridHint.TextColor3 = Color3.fromRGB(100,100,130); gridHint.TextWrapped = true
gridHint.TextXAlignment = Enum.TextXAlignment.Left
gridHint.Text = "  Fills left→right (X), front→back (Z), bottom→top (Y).  Tallest items sort first.  Z=0 auto-distributes rows."
Instance.new("UICorner", gridHint).CornerRadius = UDim.new(0,6)
Instance.new("UIPadding", gridHint).PaddingLeft = UDim.new(0,6)

mkSep(); mkLabel("Preview")

mkBtn("Generate Preview  (follows mouse)", Color3.fromRGB(35,55,100), function()
    if countSelected() == 0 then
        setStatus("⚠  No items selected!"); return
    end
    -- Check if all items fit in the grid
    local n = countSelected()
    local cap = computeGridCapacity()
    if n > cap then
        showOverflow(
            n .. " items selected but grid only holds " .. cap ..
            " (X=" .. gridCols .. " × Z=" .. gridRows .. " × Y=" .. gridLayers ..
            "). Increase X, Y, or Z sliders.")
        refreshStatus()
        return
    end
    hideOverflow()
    local sX, sY, sZ = computePreviewSize()
    buildPreviewBox(sX, sY, sZ)
    startPreviewFollow()
    refreshStatus()
end)

mkBtn("Clear Preview", BTN_COLOR, function()
    destroyPreview(); refreshStatus()
end)

mkSep(); mkLabel("Actions")

startBtn = Instance.new("TextButton", sorterPage)
startBtn.Size = UDim2.new(1,-12,0,36)
startBtn.BackgroundColor3 = Color3.fromRGB(28,28,38)
startBtn.Text = "▶  Start Sorting"; startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14; startBtn.TextColor3 = Color3.fromRGB(72,72,82)
startBtn.BorderSizePixel = 0
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,6)

startBtn.MouseButton1Click:Connect(function()
    if isSorting then return end
    if overflowBlocked then
        setStatus("❌  Fix the grid size first!"); return
    end

    -- ── RESUME after Stop ──────────────────────────────────────────
    if isStopped and sortSlots then
        isStopped = false
        isSorting = true
        pbContainer.Visible = true
        pbFill.BackgroundColor3 = Color3.fromRGB(255,175,55)
        pbLabel.Text = "Sorting... " .. sortDone .. " / " .. sortTotal
        refreshStatus()

        sortThread = task.spawn(function()
            for i = sortIndex, sortTotal do
                if not isSorting then break end
                local slot = sortSlots[i]
                if not (slot.model and slot.model.Parent) then
                    sortDone  = sortDone + 1
                    sortIndex = i + 1
                    continue
                end

                pbLabel.Text = "Sorting... " .. sortDone .. " / " .. sortTotal

                local finished = false
                currentItemConn = moveItemTo(slot.model, slot.cf, function()
                    finished = true
                end)
                -- wait for the async move to complete (or for a stop)
                while not finished and isSorting do task.wait() end
                if currentItemConn and not finished then
                    pcall(function() task.cancel(currentItemConn) end)
                end
                currentItemConn = nil

                if not isSorting then
                    sortIndex = i   -- remember where we paused
                    break
                end

                unhighlightItem(slot.model)
                sortDone  = sortDone + 1
                sortIndex = i + 1

                local pct = math.clamp(sortDone / math.max(sortTotal,1), 0, 1)
                TweenService:Create(pbFill, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
                    { Size = UDim2.new(pct,0,1,0) }):Play()
                pbLabel.Text = "Sorting... " .. sortDone .. " / " .. sortTotal
                task.wait(0.1)  -- small gap between items
            end

            local finished = sortDone >= sortTotal
            isSorting  = false
            sortThread = nil
            currentItemConn = nil

            if finished then
                isStopped = false
                sortSlots = nil
                TweenService:Create(pbFill, TweenInfo.new(0.25),
                    { Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(90,220,110) }):Play()
                pbLabel.Text = "✔  Sorting complete!"
                destroyPreview()
                unhighlightAll()
                hideProgress(2.5)
            else
                isStopped = true
                pbLabel.Text = "⏸  Stopped at " .. sortDone .. " / " .. sortTotal
            end
            refreshStatus()
        end)
        return
    end

    -- ── FRESH START ────────────────────────────────────────────────
    if not (previewPlaced and previewPart and previewPart.Parent) then
        setStatus("⚠  Generate a preview and place it first!"); return
    end
    if countSelected() == 0 then
        setStatus("⚠  No items selected!"); return
    end

    local items = {}
    for model in pairs(selectedItems) do
        if model and model.Parent then table.insert(items, model) end
    end
    if #items == 0 then return end

    local anchorCF = previewPart.CFrame
        * CFrame.new(-previewPart.Size.X/2, -previewPart.Size.Y/2, -previewPart.Size.Z/2)

    sortSlots  = calculateSlots(items, anchorCF, gridCols, gridLayers, gridRows)
    sortTotal  = #sortSlots
    sortDone   = 0
    sortIndex  = 1
    isStopped  = false
    isSorting  = true

    pbContainer.Visible = true
    pbFill.Size = UDim2.new(0,0,1,0)
    pbFill.BackgroundColor3 = Color3.fromRGB(255,175,55)
    pbLabel.Text = "Sorting... 0 / " .. sortTotal
    refreshStatus()

    sortThread = task.spawn(function()
        for i = sortIndex, sortTotal do
            if not isSorting then
                sortIndex = i
                break
            end
            local slot = sortSlots[i]
            if not (slot.model and slot.model.Parent) then
                sortDone  = sortDone + 1
                sortIndex = i + 1
                continue
            end

            pbLabel.Text = "Sorting... " .. sortDone .. " / " .. sortTotal

            local finished = false
            currentItemConn = moveItemTo(slot.model, slot.cf, function()
                finished = true
            end)
            while not finished and isSorting do task.wait() end
            if currentItemConn and not finished then
                pcall(function() task.cancel(currentItemConn) end)
            end
            currentItemConn = nil

            if not isSorting then
                sortIndex = i
                break
            end

            unhighlightItem(slot.model)
            sortDone  = sortDone + 1
            sortIndex = i + 1

            local pct = math.clamp(sortDone / math.max(sortTotal,1), 0, 1)
            TweenService:Create(pbFill, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
                { Size = UDim2.new(pct,0,1,0) }):Play()
            pbLabel.Text = "Sorting... " .. sortDone .. " / " .. sortTotal
            task.wait(0.1)  -- small gap between items
        end

        local allDone = sortDone >= sortTotal
        isSorting  = false
        sortThread = nil
        currentItemConn = nil

        if allDone then
            isStopped = false
            sortSlots = nil
            TweenService:Create(pbFill, TweenInfo.new(0.25),
                { Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(90,220,110) }):Play()
            pbLabel.Text = "✔  Sorting complete!"
            destroyPreview()
            unhighlightAll()
            hideProgress(2.5)
        else
            isStopped = true
            pbLabel.Text = "⏸  Stopped at " .. sortDone .. " / " .. sortTotal
        end
        refreshStatus()
    end)
end)

-- Stop button — pauses mid-sort, preserves progress for resume
stopBtn = Instance.new("TextButton", sorterPage)
stopBtn.Size = UDim2.new(1,-12,0,32)
stopBtn.BackgroundColor3 = Color3.fromRGB(28,28,38)
stopBtn.Text = "⏹  Stop"; stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 13; stopBtn.TextColor3 = Color3.fromRGB(72,72,82)
stopBtn.BorderSizePixel = 0
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0,6)

stopBtn.MouseButton1Click:Connect(function()
    if not isSorting then return end
    isSorting = false
    if currentItemConn then
        pcall(function() task.cancel(currentItemConn) end)
        currentItemConn = nil
    end
    pbLabel.Text = "⏸  Stopping..."
    refreshStatus()
end)

mkBtn("Cancel  (clear all)", Color3.fromRGB(70,20,20), function()
    isSorting = false
    isStopped = false
    sortSlots = nil; sortIndex = 0; sortTotal = 0; sortDone = 0
    if currentItemConn then
        pcall(function() task.cancel(currentItemConn) end)
        currentItemConn = nil
    end
    if sortThread then pcall(function() task.cancel(sortThread) end); sortThread = nil end
    destroyPreview()
    unhighlightAll()
    hideOverflow()
    pbLabel.Text = "Cancelled."
    hideProgress(1.0)
    refreshStatus()
end)

mkBtn("Clear Selection", BTN_COLOR, function()
    unhighlightAll(); refreshStatus()
end)

pbContainer.Parent = sorterPage

-- ════════════════════════════════════════════════════
-- MOUSE INPUT
-- ════════════════════════════════════════════════════
local mouseDownConn = mouse.Button1Down:Connect(function()
    -- Lasso start
    if lassoEnabled then
        lassoDragging      = true
        lassoStartPos      = Vector2.new(mouse.X, mouse.Y)
        lassoFrame.Size    = UDim2.new(0,0,0,0)
        lassoFrame.Visible = true
        return
    end

    -- Normal item selection (left-click only when NOT placing preview)
    local target = mouse.Target
    if not target then return end
    local model = target:FindFirstAncestorOfClass("Model")
    if not model then return end

    if clickSelEnabled and isSortableItem(model) then
        if selectedItems[model] then unhighlightItem(model) else highlightItem(model) end
        refreshStatus()
    elseif groupSelEnabled and isSortableItem(model) then
        groupSelectItem(model)
        refreshStatus()
    end
end)

local mouseMoveConn = mouse.Move:Connect(function()
    if lassoDragging and lassoEnabled and lassoStartPos then
        updateLassoVis(lassoStartPos, Vector2.new(mouse.X, mouse.Y))
    end
end)

local mouseUpConn = mouse.Button1Up:Connect(function()
    if lassoDragging and lassoEnabled and lassoStartPos then
        lassoDragging = false
        selectLasso()
        lassoFrame.Visible = false
        lassoStartPos = nil
        refreshStatus()
    end
    lassoDragging = false
end)

-- Right-click to place the preview box
local mouseRightConn = mouse.Button2Down:Connect(function()
    if previewFollowing then
        placePreview()
        refreshStatus()
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    isSorting = false
    isStopped = false
    sortSlots = nil; sortIndex = 0; sortTotal = 0; sortDone = 0
    if followConn      then followConn:Disconnect();      followConn = nil end
    if currentItemConn then pcall(function() task.cancel(currentItemConn) end); currentItemConn = nil end
    if sortThread      then pcall(function() task.cancel(sortThread) end);      sortThread = nil end
    mouseDownConn:Disconnect()
    mouseMoveConn:Disconnect()
    mouseUpConn:Disconnect()
    mouseRightConn:Disconnect()
    for _, sc in ipairs(sliderConns) do
        if sc.changed then pcall(function() sc.changed:Disconnect() end) end
        if sc.ended   then pcall(function() sc.ended:Disconnect()   end) end
    end
    sliderConns = {}
    if lassoFrame and lassoFrame.Parent then lassoFrame:Destroy() end
    destroyPreview()
    unhighlightAll()
end)

refreshStatus()
print("[VanillaHub] Vanilla4 (Sorter) loaded")
