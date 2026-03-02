-- ════════════════════════════════════════════════════
-- VANILLA4 — Sorter Tab
-- Execute AFTER Vanilla1, Vanilla2, Vanilla3
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla4: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local Players          = _G.VH.Players
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages
local BTN_COLOR        = _G.VH.BTN_COLOR
local BTN_HOVER        = _G.VH.BTN_HOVER
local THEME_TEXT       = _G.VH.THEME_TEXT or Color3.fromRGB(230, 206, 226)

local sorterPage = pages["SorterTab"]
local camera     = workspace.CurrentCamera
local RS         = game:GetService("ReplicatedStorage")

-- ════════════════════════════════════════════════════
-- CONSTANTS
-- ════════════════════════════════════════════════════
local PREVIEW_COLOR       = Color3.fromRGB(80, 160, 255)
local PREVIEW_ALPHA       = 0.55
local HIGHLIGHT_COLOR     = Color3.fromRGB(255, 180, 0)   -- orange — distinct from wood (green) and item (blue)
local ITEM_GAP            = 0.05   -- studs gap between packed items
local SORT_TIMEOUT        = 3.0    -- seconds per item before giving up
local CONFIRM_DIST        = 5      -- studs — item counts as "placed" when this close

-- ════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════
local selectedItems   = {}   -- model → SelectionBox
local previewPart     = nil  -- the transparent placement guide box in workspace
local previewPlaced   = false
local isSorting       = false
local sortThread      = nil

-- XYZ offsets from the preview anchor (adjusted via sliders)
local offsetX = 0
local offsetY = 0
local offsetZ = 0

-- Lasso state
local lassoActive    = false
local lassoStartPos  = nil
local mouseIsDragging = false

-- Mode flags
local clickSelEnabled  = false
local lassoEnabled     = false
local groupSelEnabled  = false

-- ════════════════════════════════════════════════════
-- ITEM IDENTIFICATION
-- Items the sorter cares about: anything with an Owner value OR
-- a PurchasedBoxItemName (bought items) OR DraggableItem (gifts).
-- Excludes logs (TreeClass) and base terrain.
-- ════════════════════════════════════════════════════
local function isSortableItem(model)
    if not model or not model:IsA("Model") then return false end
    if model == workspace then return false end
    -- Must have a physical part to move
    local mp = model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
    if not mp then return false end
    -- Exclude logs
    if model:FindFirstChild("TreeClass") then return false end
    -- Must be an owned / purchasable / gift item
    local hasOwner    = model:FindFirstChild("Owner") ~= nil
    local hasPurchased = model:FindFirstChild("PurchasedBoxItemName") ~= nil
    local hasGift     = model:FindFirstChild("DraggableItem") ~= nil
    local hasItemName = model:FindFirstChild("ItemName") ~= nil
    return hasOwner or hasPurchased or hasGift or hasItemName
end

local function getMainPart(model)
    return model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
end

-- ════════════════════════════════════════════════════
-- SELECTION HELPERS  (mirrors Item tab from Vanilla1)
-- ════════════════════════════════════════════════════
local function highlightItem(model)
    if selectedItems[model] then return end
    local hl = Instance.new("SelectionBox")
    hl.Color3             = HIGHLIGHT_COLOR
    hl.LineThickness      = 0.06
    hl.SurfaceTransparency = 0.75
    hl.SurfaceColor3      = HIGHLIGHT_COLOR
    hl.Adornee            = model
    hl.Parent             = model
    selectedItems[model]  = hl
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

-- Group select: all items sharing the same ItemName / PurchasedBoxItemName
local function groupSelectItem(targetModel)
    if not isSortableItem(targetModel) then return end
    local nameVal = targetModel:FindFirstChild("ItemName")
        or targetModel:FindFirstChild("PurchasedBoxItemName")
    local targetName = nameVal and nameVal.Value or targetModel.Name
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local nv = obj:FindFirstChild("ItemName")
                or obj:FindFirstChild("PurchasedBoxItemName")
            local n = nv and nv.Value or obj.Name
            if n == targetName then
                highlightItem(obj)
            end
        end
    end
end

-- ════════════════════════════════════════════════════
-- PREVIEW PART
-- ════════════════════════════════════════════════════
local function destroyPreview()
    if previewPart and previewPart.Parent then
        previewPart:Destroy()
    end
    previewPart   = nil
    previewPlaced = false
end

local function buildPreviewBox(sizeX, sizeY, sizeZ, position)
    destroyPreview()
    previewPart = Instance.new("Part")
    previewPart.Name        = "VHSorterPreview"
    previewPart.Anchored    = true
    previewPart.CanCollide  = false
    previewPart.CanQuery    = false
    previewPart.CastShadow  = false
    previewPart.Size        = Vector3.new(sizeX, sizeY, sizeZ)
    previewPart.CFrame      = CFrame.new(position)
    previewPart.Color       = PREVIEW_COLOR
    previewPart.Material    = Enum.Material.SmoothPlastic
    previewPart.Transparency = PREVIEW_ALPHA
    previewPart.Parent      = workspace

    -- Wireframe selection box to make boundaries obvious
    local sb = Instance.new("SelectionBox")
    sb.Color3        = PREVIEW_COLOR
    sb.LineThickness = 0.08
    sb.SurfaceTransparency = 1
    sb.Adornee = previewPart
    sb.Parent  = previewPart
end

-- Recalculate preview size from selected items and rebuild
local function refreshPreview()
    if countSelected() == 0 then
        destroyPreview()
        return
    end

    -- Measure each selected item's bounding box
    local totalVol = 0
    local maxW = 0
    local maxD = 0
    local itemSizes = {}

    for model in pairs(selectedItems) do
        local ok, cf, sz = pcall(function()
            return model:GetBoundingBox()
        end)
        if ok and sz then
            local w = math.ceil(sz.X + ITEM_GAP)
            local h = math.ceil(sz.Y + ITEM_GAP)
            local d = math.ceil(sz.Z + ITEM_GAP)
            table.insert(itemSizes, {w = w, h = h, d = d, model = model})
            totalVol = totalVol + (w * h * d)
            if w > maxW then maxW = w end
            if d > maxD then maxD = d end
        end
    end

    if #itemSizes == 0 then destroyPreview(); return end

    -- Choose a grid: try to keep it roughly square in X/Z
    -- Simple approach: arrange in a row on X axis, stack on Y
    local cols    = math.max(1, math.ceil(math.sqrt(#itemSizes)))
    local rows    = math.ceil(#itemSizes / cols)
    local cellW   = maxW
    local cellD   = maxD

    -- Max height in each column slot — we'll lay real heights during sort
    -- For the preview box just use max single-item height * rows stacked
    local maxH = 0
    for _, s in ipairs(itemSizes) do if s.h > maxH then maxH = s.h end end

    local boxW = cols * cellW
    local boxH = maxH * rows   -- rough estimate
    local boxD = cellD

    -- Position: player front + some offset, adjusted by sliders
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local basePos = hrp
        and (hrp.Position + hrp.CFrame.LookVector * 12 + Vector3.new(0, 2, 0))
        or  Vector3.new(0, 5, 0)

    local pos = basePos + Vector3.new(offsetX, offsetY, offsetZ)

    buildPreviewBox(boxW, boxH, boxD, pos)
end

-- ════════════════════════════════════════════════════
-- SORT ENGINE
-- Uses RunService.Heartbeat per item (same principle as wood sell)
-- ════════════════════════════════════════════════════
local function getInteraction()
    local i = RS:FindFirstChild("Interaction")
    return i and i:FindFirstChild("ClientIsDragging")
end

-- Move one item to targetCF using a Heartbeat loop.
-- Calls onDone(success) when confirmed or timed out.
local function moveItemTo(model, targetCF, onDone)
    if not (model and model.Parent) then
        if onDone then onDone(false) end; return
    end
    local mainPart = getMainPart(model)
    if not mainPart then if onDone then onDone(false) end; return end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then if onDone then onDone(false) end; return end

    local dragger   = getInteraction()
    local startTime = tick()
    local conn

    -- Get close enough for the server to accept the drag
    if (hrp.Position - mainPart.Position).Magnitude > 25 then
        hrp.CFrame = mainPart.CFrame * CFrame.new(0, 4, 3)
    end

    conn = RunService.Heartbeat:Connect(function()
        -- Item despawned / sold
        if not (mainPart and mainPart.Parent) then
            conn:Disconnect()
            if onDone then onDone(true) end
            return
        end

        -- Stay close each frame
        local dist = (hrp.Position - mainPart.Position).Magnitude
        if dist > 25 then
            hrp.CFrame = mainPart.CFrame * CFrame.new(0, 4, 3)
        end

        -- Fire drag + set CFrame every frame simultaneously
        if dragger then pcall(function() dragger:FireServer(model) end) end
        pcall(function() mainPart.CFrame = targetCF end)

        -- Check confirmation
        local arrived = (mainPart.Position - targetCF.Position).Magnitude < CONFIRM_DIST
        local timedOut = (tick() - startTime) >= SORT_TIMEOUT

        if arrived or timedOut then
            conn:Disconnect()
            -- Reinforce final position
            task.spawn(function()
                for _ = 1, 20 do
                    pcall(function()
                        if dragger then dragger:FireServer(model) end
                        if mainPart and mainPart.Parent then
                            mainPart.CFrame = targetCF
                        end
                    end)
                    task.wait()
                end
                if onDone then onDone(arrived) end
            end)
        end
    end)

    return conn
end

-- ════════════════════════════════════════════════════
-- SORT PLACEMENT CALCULATOR
-- Packs items from the bottom-left-front corner of the preview box,
-- filling left→right, front→back, then up — no air gaps.
-- ════════════════════════════════════════════════════
local function calculateSlots(items, anchorCF, boxSize)
    -- Each item gets its own cell. We measure the real bounding box
    -- and pack in a shelf-style layout:
    --   • Sort items tallest-first so each shelf row is as tight as possible
    --   • Fill X axis first, then Z, then Y (bottom → top)

    local slots = {}

    -- Gather sizes
    local entries = {}
    for _, model in ipairs(items) do
        local ok, _, sz = pcall(function() return model:GetBoundingBox() end)
        local s = ok and sz or Vector3.new(2, 2, 2)
        table.insert(entries, {
            model = model,
            w     = s.X,
            h     = s.Y,
            d     = s.Z,
        })
    end

    -- Sort by height descending so tall items anchor each row
    table.sort(entries, function(a, b) return a.h > b.h end)

    -- Pack: track current X, Z cursor and current shelf Y
    local curX      = -boxSize.X / 2
    local curZ      = -boxSize.Z / 2
    local curY      = -boxSize.Y / 2
    local rowMaxH   = 0
    local rowMaxD   = 0
    local shelfMaxH = 0

    for _, e in ipairs(entries) do
        local halfW = e.w / 2
        local halfH = e.h / 2
        local halfD = e.d / 2

        -- Check if this item fits in the current X row
        if curX + e.w > boxSize.X / 2 then
            -- Next row in Z
            curZ      = curZ + rowMaxD + ITEM_GAP
            curX      = -boxSize.X / 2
            rowMaxH   = 0
            rowMaxD   = 0
        end

        -- Check if the current Z row fits the shelf
        if curZ + e.d > boxSize.Z / 2 then
            -- Next shelf upward
            curY      = curY + shelfMaxH + ITEM_GAP
            curZ      = -boxSize.Z / 2
            curX      = -boxSize.X / 2
            shelfMaxH = 0
            rowMaxH   = 0
            rowMaxD   = 0
        end

        -- Local position inside the box
        local localPos = Vector3.new(
            curX + halfW,
            curY + halfH,
            curZ + halfD
        )

        -- World CFrame: anchor's CFrame * local offset
        local worldCF = anchorCF * CFrame.new(localPos)

        table.insert(slots, { model = e.model, cf = worldCF })

        curX      = curX + e.w + ITEM_GAP
        if e.h > rowMaxH   then rowMaxH   = e.h end
        if e.d > rowMaxD   then rowMaxD   = e.d end
        if e.h > shelfMaxH then shelfMaxH = e.h end
    end

    return slots
end

-- ════════════════════════════════════════════════════
-- UI HELPERS
-- ════════════════════════════════════════════════════
local function createSSectionLabel(text)
    local lbl = Instance.new("TextLabel", sorterPage)
    lbl.Size = UDim2.new(1,-12,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function createSSep()
    local s = Instance.new("Frame", sorterPage)
    s.Size = UDim2.new(1,-12,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,40,55)
    s.BorderSizePixel = 0
end

local function createSToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", sorterPage)
    frame.Size = UDim2.new(1,-12,0,32)
    frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0,34,0,18); tb.Position = UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3 = defaultState and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text = ""; Instance.new("UICorner", tb).CornerRadius = UDim.new(1,0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0,14,0,14)
    circle.Position = UDim2.new(0, defaultState and 18 or 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)
    local toggled = defaultState
    if callback then callback(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and Color3.fromRGB(60,180,60) or BTN_COLOR
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 18 or 2, 0.5, -7)
        }):Play()
        if callback then callback(toggled) end
    end)
    return frame
end

local function createSButton(text, color, callback)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", sorterPage)
    btn.Size = UDim2.new(1,-12,0,34)
    btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local hov = Color3.fromRGB(
        math.min(color.R*255+20,255)/255,
        math.min(color.G*255+8,255)/255,
        math.min(color.B*255+20,255)/255
    )
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=hov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=color}):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- XYZ slider (returns the frame + a getter function)
local function createAxisSlider(labelText, axis, minVal, maxVal, default, onChanged)
    local frame = Instance.new("Frame", sorterPage)
    frame.Size = UDim2.new(1,-12,0,52)
    frame.BackgroundColor3 = Color3.fromRGB(22,22,28)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)

    local axisColors = {X = Color3.fromRGB(220,80,80), Y = Color3.fromRGB(80,200,80), Z = Color3.fromRGB(80,120,255)}
    local axisCol = axisColors[axis] or THEME_TEXT

    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1,-16,0,22); topRow.Position = UDim2.new(0,8,0,4)
    topRow.BackgroundTransparency = 1

    local axisTag = Instance.new("TextLabel", topRow)
    axisTag.Size = UDim2.new(0,16,1,0)
    axisTag.BackgroundTransparency = 1; axisTag.Font = Enum.Font.GothamBold
    axisTag.TextSize = 13; axisTag.TextColor3 = axisCol
    axisTag.Text = axis

    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.6,0,1,0); lbl.Position = UDim2.new(0,20,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12; lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText

    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.35,0,1,0); valLbl.Position = UDim2.new(0.65,0,0,0)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12; valLbl.TextColor3 = axisCol
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(default)

    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1,-16,0,6); track.Position = UDim2.new(0,8,0,34)
    track.BackgroundColor3 = Color3.fromRGB(36,36,50); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = axisCol; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0,16,0,16); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((default-minVal)/(maxVal-minVal),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(220,220,240); knob.Text = ""
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local draggingSlider = false
    local currentVal = default

    local function updateSlider(absX)
        local ratio = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val   = math.round(minVal + ratio * (maxVal - minVal))
        fill.Size   = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valLbl.Text = tostring(val)
        currentVal  = val
        if onChanged then onChanged(val) end
    end

    knob.MouseButton1Down:Connect(function() draggingSlider = true end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true; updateSlider(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if draggingSlider and inp.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)

    return frame, function() return currentVal end
end

-- ════════════════════════════════════════════════════
-- PROGRESS BAR
-- ════════════════════════════════════════════════════
local sortProgressContainer, sortProgressFill, sortProgressLabel

do
    local pbW = Instance.new("Frame", sorterPage)
    pbW.Size = UDim2.new(1,-12,0,44); pbW.BackgroundColor3 = Color3.fromRGB(18,18,24)
    pbW.BorderSizePixel = 0; pbW.Visible = false
    Instance.new("UICorner", pbW).CornerRadius = UDim.new(0,8)
    local pbSt = Instance.new("UIStroke", pbW)
    pbSt.Color = Color3.fromRGB(60,60,80); pbSt.Thickness = 1; pbSt.Transparency = 0.5

    local pbLbl = Instance.new("TextLabel", pbW)
    pbLbl.Size = UDim2.new(1,-12,0,16); pbLbl.Position = UDim2.new(0,6,0,4)
    pbLbl.BackgroundTransparency = 1; pbLbl.Font = Enum.Font.GothamSemibold; pbLbl.TextSize = 11
    pbLbl.TextColor3 = THEME_TEXT; pbLbl.TextXAlignment = Enum.TextXAlignment.Left
    pbLbl.Text = "Sorting..."

    local pbTr = Instance.new("Frame", pbW)
    pbTr.Size = UDim2.new(1,-12,0,12); pbTr.Position = UDim2.new(0,6,0,24)
    pbTr.BackgroundColor3 = Color3.fromRGB(30,30,40); pbTr.BorderSizePixel = 0
    Instance.new("UICorner", pbTr).CornerRadius = UDim.new(1,0)

    local pbFl = Instance.new("Frame", pbTr)
    pbFl.Size = UDim2.new(0,0,1,0)
    pbFl.BackgroundColor3 = Color3.fromRGB(255,180,60)
    pbFl.BorderSizePixel = 0
    Instance.new("UICorner", pbFl).CornerRadius = UDim.new(1,0)

    sortProgressContainer = pbW
    sortProgressFill      = pbFl
    sortProgressLabel     = pbLbl
end

local function hideProgress()
    task.delay(2.0, function()
        if sortProgressContainer then
            TweenService:Create(sortProgressContainer, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
            TweenService:Create(sortProgressFill,      TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
            TweenService:Create(sortProgressLabel,     TweenInfo.new(0.4), {TextTransparency=1}):Play()
            task.delay(0.45, function()
                if sortProgressContainer then
                    sortProgressContainer.Visible = false
                    sortProgressContainer.BackgroundTransparency = 0
                    sortProgressFill.BackgroundTransparency = 0
                    sortProgressFill.BackgroundColor3 = Color3.fromRGB(255,180,60)
                    sortProgressFill.Size = UDim2.new(0,0,1,0)
                    sortProgressLabel.TextTransparency = 0
                end
            end)
        end
    end)
end

-- ════════════════════════════════════════════════════
-- STATUS CARD (popup for no-items warning + preview info)
-- ════════════════════════════════════════════════════
local statusCard, statusLabel

do
    local card = Instance.new("Frame", sorterPage)
    card.Size = UDim2.new(1,-12,0,44)
    card.BackgroundColor3 = Color3.fromRGB(30,22,40)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(255,180,0); stroke.Thickness = 1; stroke.Transparency = 0.5
    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(1,-16,1,0); lbl.Position = UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255,210,100)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Text = "No items selected."
    statusCard  = card
    statusLabel = lbl
end

local function setStatus(msg, color)
    statusLabel.Text = msg
    statusLabel.TextColor3 = color or Color3.fromRGB(255,210,100)
end

-- ════════════════════════════════════════════════════
-- LASSO OVERLAY  (same as Item tab)
-- ════════════════════════════════════════════════════
local gui = game.CoreGui:FindFirstChild("VanillaHub")
local lassoFrame = Instance.new("Frame", gui or game.CoreGui)
lassoFrame.Name = "SorterLassoRect"
lassoFrame.BackgroundColor3 = Color3.fromRGB(255,160,40)
lassoFrame.BackgroundTransparency = 0.82
lassoFrame.BorderSizePixel = 0
lassoFrame.Visible = false; lassoFrame.ZIndex = 20
local lassoStroke = Instance.new("UIStroke", lassoFrame)
lassoStroke.Color = Color3.fromRGB(255,200,80)
lassoStroke.Thickness = 1.5; lassoStroke.Transparency = 0

local function updateLassoFrame(s, c)
    local minX = math.min(s.X,c.X); local minY = math.min(s.Y,c.Y)
    lassoFrame.Position = UDim2.new(0,minX,0,minY)
    lassoFrame.Size     = UDim2.new(0,math.abs(c.X-s.X),0,math.abs(c.Y-s.Y))
end

local function selectItemsInLasso()
    if not lassoStartPos then return end
    local cur  = Vector2.new(player:GetMouse().X, player:GetMouse().Y)
    local minX = math.min(lassoStartPos.X,cur.X); local maxX = math.max(lassoStartPos.X,cur.X)
    local minY = math.min(lassoStartPos.Y,cur.Y); local maxY = math.max(lassoStartPos.Y,cur.Y)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local mp = getMainPart(obj)
            if mp then
                local sp, onScreen = camera:WorldToScreenPoint(mp.Position)
                if onScreen and sp.X>=minX and sp.X<=maxX and sp.Y>=minY and sp.Y<=maxY then
                    highlightItem(obj)
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════
-- REFRESH STATUS CARD
-- ════════════════════════════════════════════════════
local startSortBtn  -- forward ref so we can enable/disable it

local function refreshStatus()
    local n = countSelected()
    if n == 0 then
        setStatus("⚠  No items selected. Use Click, Lasso or Group selection.")
    elseif not previewPlaced then
        setStatus("✔  " .. n .. " item(s) selected. Click the preview box in the world to place it.", Color3.fromRGB(140,220,255))
    else
        setStatus("✔  " .. n .. " item(s) ready. Preview placed — click Start Sorting!", Color3.fromRGB(100,220,120))
    end
    -- Enable / disable Start Sorting
    if startSortBtn then
        local canStart = n > 0 and previewPlaced and not isSorting
        startSortBtn.BackgroundColor3 = canStart
            and Color3.fromRGB(35,90,45)
            or  Color3.fromRGB(30,30,38)
        startSortBtn.TextColor3 = canStart
            and THEME_TEXT
            or  Color3.fromRGB(80,80,90)
    end
end

-- ════════════════════════════════════════════════════
-- BUILD THE SORTER TAB UI
-- ════════════════════════════════════════════════════

-- ── Status card (top) ─────────────────────────────────────────────────────────
createSSectionLabel("Status")
-- statusCard is already parented; just ensure it appears here in layout order

-- ── Selection section ─────────────────────────────────────────────────────────
createSSep()
createSSectionLabel("Selection Mode")

createSToggle("Click Selection", false, function(val)
    clickSelEnabled = val
    if val then lassoEnabled = false; groupSelEnabled = false end
end)

createSToggle("Group Selection", false, function(val)
    groupSelEnabled = val
    if val then clickSelEnabled = false; lassoEnabled = false end
end)

createSToggle("Lasso Tool", false, function(val)
    lassoEnabled = val
    if val then clickSelEnabled = false; groupSelEnabled = false end
end)

local selInfoLbl = Instance.new("TextLabel", sorterPage)
selInfoLbl.Size = UDim2.new(1,-12,0,28)
selInfoLbl.BackgroundColor3 = Color3.fromRGB(18,18,24); selInfoLbl.BorderSizePixel = 0
selInfoLbl.Font = Enum.Font.Gotham; selInfoLbl.TextSize = 11
selInfoLbl.TextColor3 = Color3.fromRGB(100,100,130)
selInfoLbl.TextWrapped = true; selInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
selInfoLbl.Text = "  Lasso: click-drag to box-select. Group: click to select all of same type."
Instance.new("UICorner", selInfoLbl).CornerRadius = UDim.new(0,6)
Instance.new("UIPadding", selInfoLbl).PaddingLeft = UDim.new(0,6)

-- ── Position sliders ──────────────────────────────────────────────────────────
createSSep()
createSSectionLabel("Preview Position Offset")

createAxisSlider("X Offset", "X", -50, 50, 0, function(val)
    offsetX = val
    if previewPart and previewPart.Parent then
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local basePos = hrp.Position + hrp.CFrame.LookVector * 12 + Vector3.new(0,2,0)
            previewPart.CFrame = CFrame.new(basePos + Vector3.new(offsetX, offsetY, offsetZ))
        end
    end
    refreshStatus()
end)

createAxisSlider("Y Offset", "Y", -20, 30, 0, function(val)
    offsetY = val
    if previewPart and previewPart.Parent then
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local basePos = hrp.Position + hrp.CFrame.LookVector * 12 + Vector3.new(0,2,0)
            previewPart.CFrame = CFrame.new(basePos + Vector3.new(offsetX, offsetY, offsetZ))
        end
    end
    refreshStatus()
end)

createAxisSlider("Z Offset", "Z", -50, 50, 0, function(val)
    offsetZ = val
    if previewPart and previewPart.Parent then
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local basePos = hrp.Position + hrp.CFrame.LookVector * 12 + Vector3.new(0,2,0)
            previewPart.CFrame = CFrame.new(basePos + Vector3.new(offsetX, offsetY, offsetZ))
        end
    end
    refreshStatus()
end)

-- ── Preview controls ──────────────────────────────────────────────────────────
createSSep()
createSSectionLabel("Preview")

createSButton("Generate Preview", Color3.fromRGB(40,60,100), function()
    if countSelected() == 0 then
        setStatus("⚠  No items selected!"); return
    end
    previewPlaced = false
    refreshPreview()
    setStatus("✔  Preview generated. Left-click it in the world to place.", Color3.fromRGB(140,220,255))
    refreshStatus()
end)

createSButton("Clear Preview", BTN_COLOR, function()
    destroyPreview()
    refreshStatus()
end)

-- ── Actions ───────────────────────────────────────────────────────────────────
createSSep()
createSSectionLabel("Actions")

-- Start Sorting — disabled until preview is placed
startSortBtn = Instance.new("TextButton", sorterPage)
startSortBtn.Size = UDim2.new(1,-12,0,34)
startSortBtn.BackgroundColor3 = Color3.fromRGB(30,30,38)
startSortBtn.Text = "Start Sorting"; startSortBtn.Font = Enum.Font.GothamSemibold
startSortBtn.TextSize = 13; startSortBtn.TextColor3 = Color3.fromRGB(80,80,90)
startSortBtn.BorderSizePixel = 0
Instance.new("UICorner", startSortBtn).CornerRadius = UDim.new(0,6)

startSortBtn.MouseButton1Click:Connect(function()
    if isSorting then return end
    if countSelected() == 0 then setStatus("⚠  No items selected!"); return end
    if not previewPlaced then setStatus("⚠  Place the preview first!"); return end
    if not (previewPart and previewPart.Parent) then
        setStatus("⚠  Preview was removed. Generate a new one."); return
    end

    isSorting = true
    refreshStatus()

    local items = {}
    for model in pairs(selectedItems) do
        if model and model.Parent then table.insert(items, model) end
    end

    local anchorCF  = previewPart.CFrame * CFrame.new(
        -previewPart.Size.X/2,
        -previewPart.Size.Y/2,
        -previewPart.Size.Z/2
    )

    local slots  = calculateSlots(items, anchorCF, previewPart.Size)
    local total  = #slots
    local done   = 0

    sortProgressContainer.Visible = true
    sortProgressFill.Size = UDim2.new(0,0,1,0)
    sortProgressLabel.Text = "Sorting... 0 / " .. total

    sortThread = task.spawn(function()
        for i, slot in ipairs(slots) do
            if not isSorting then break end
            if not (slot.model and slot.model.Parent) then
                done = done + 1; continue
            end

            local finished = false
            local conn = moveItemTo(slot.model, slot.cf, function()
                finished = true
            end)

            -- Wait for this item to finish
            while not finished and isSorting do task.wait() end

            if conn and typeof(conn) == "RBXScriptConnection" then
                pcall(function() conn:Disconnect() end)
            end

            if not isSorting then break end

            unhighlightItem(slot.model)
            done = done + 1
            local pct = math.clamp(done / math.max(total,1), 0, 1)
            TweenService:Create(sortProgressFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Size = UDim2.new(pct,0,1,0)
            }):Play()
            sortProgressLabel.Text = "Sorting... " .. done .. " / " .. total

            -- Small gap between items
            task.wait(0.4)
        end

        isSorting   = false
        sortThread  = nil
        unhighlightAll()
        destroyPreview()
        refreshStatus()

        TweenService:Create(sortProgressFill, TweenInfo.new(0.2), {
            Size = UDim2.new(1,0,1,0),
            BackgroundColor3 = Color3.fromRGB(100,220,120)
        }):Play()
        sortProgressLabel.Text = "Sorting complete!"
        hideProgress()
    end)
end)

createSButton("Cancel", BTN_COLOR, function()
    isSorting = false
    if sortThread then pcall(task.cancel, sortThread); sortThread = nil end
    sortProgressLabel.Text = "Cancelled."
    hideProgress()
    refreshStatus()
end)

createSButton("Clear Selection", BTN_COLOR, function()
    unhighlightAll()
    refreshStatus()
end)

-- Progress bar needs to be after buttons in the list
sortProgressContainer.Parent = sorterPage

-- ════════════════════════════════════════════════════
-- MOUSE / TOUCH INPUT
-- ════════════════════════════════════════════════════
local mouse = player:GetMouse()

local mouseDownConn = mouse.Button1Down:Connect(function()
    mouseIsDragging = true

    -- ── Lasso start ──────────────────────────────────
    if lassoEnabled then
        lassoStartPos       = Vector2.new(mouse.X, mouse.Y)
        lassoFrame.Size     = UDim2.new(0,0,0,0)
        lassoFrame.Visible  = true
        return
    end

    local target = mouse.Target
    if not target then return end

    -- ── Place preview on left-click ───────────────────
    -- If the player clicks the preview box itself, lock it in place
    if target == previewPart then
        previewPlaced = true
        -- Tint green to confirm placement
        TweenService:Create(previewPart, TweenInfo.new(0.25), {
            Color = Color3.fromRGB(60,200,100)
        }):Play()
        setStatus("✔  Preview placed! Click Start Sorting to begin.", Color3.fromRGB(100,220,120))
        refreshStatus()
        return
    end

    local model = target:FindFirstAncestorOfClass("Model")
    if not model then return end

    -- ── Click Selection ───────────────────────────────
    if clickSelEnabled and isSortableItem(model) then
        if selectedItems[model] then unhighlightItem(model) else highlightItem(model) end
        refreshStatus()
        return
    end

    -- ── Group Selection ───────────────────────────────
    if groupSelEnabled and isSortableItem(model) then
        groupSelectItem(model)
        refreshStatus()
        return
    end
end)

local mouseMoveConn = mouse.Move:Connect(function()
    if mouseIsDragging and lassoEnabled and lassoStartPos then
        updateLassoFrame(lassoStartPos, Vector2.new(mouse.X, mouse.Y))
    end
end)

local mouseUpConn = mouse.Button1Up:Connect(function()
    mouseIsDragging = false
    if lassoEnabled and lassoStartPos then
        selectItemsInLasso()
        lassoFrame.Visible = false
        lassoStartPos      = nil
        refreshStatus()
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    isSorting = false
    if sortThread then pcall(task.cancel, sortThread); sortThread = nil end
    mouseDownConn:Disconnect()
    mouseMoveConn:Disconnect()
    mouseUpConn:Disconnect()
    if lassoFrame and lassoFrame.Parent then lassoFrame:Destroy() end
    destroyPreview()
    unhighlightAll()
end)

-- Initial status
refreshStatus()

print("[VanillaHub] Vanilla4 (Sorter) loaded")
