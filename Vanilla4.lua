-- ════════════════════════════════════════════════════
-- VANILLA4 — Sorter Tab  (FIXED)
-- Execute AFTER Vanilla1, Vanilla2, Vanilla3
--
-- FIXES vs original:
--   - Max 5 layers tall (slider capped, hard enforced)
--   - Fills bottom layer COMPLETELY before moving to next layer
--   - Gap-check after each layer: any item that missed its slot
--     gets one retry teleport before the next layer starts
--   - Anti-lag: no per-frame RemoteEvent spam
--     Uses anchor→move→unanchor instead (clean, no physics rejection)
--   - Sorter only — trucks/dupe live in Vanilla2
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
local mouse      = player:GetMouse()

-- ════════════════════════════════════════════════════
-- CONSTANTS
-- ════════════════════════════════════════════════════
local HIGHLIGHT_COLOR = Color3.fromRGB(255, 180, 0)
local PREVIEW_COLOR   = Color3.fromRGB(80, 160, 255)
local PLACED_COLOR    = Color3.fromRGB(60, 210, 100)
local ITEM_GAP        = 0.08
local MAX_LAYERS      = 5        -- hard cap: max 5 tall
local CONFIRM_DIST    = 2.5      -- studs: item counts as "arrived"

-- ════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════
local selectedItems    = {}
local previewPart      = nil
local previewFollowing = false
local previewPlaced    = false
local isSorting        = false
local sortAbort        = false
local followConn       = nil

local gridCols   = 3
local gridLayers = 1
local gridRows   = 0

local clickSelEnabled  = false
local lassoEnabled     = false
local groupSelEnabled  = false
local lassoStartPos    = nil
local lassoDragging    = false

-- ════════════════════════════════════════════════════
-- CLEAN TELEPORT  (no lag, no physics rejection)
-- anchor all → move with relative offsets → wait → unanchor
-- ════════════════════════════════════════════════════
local function anchorModel(model, state)
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = state
            if state then
                p.AssemblyLinearVelocity  = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end

local function cleanTeleport(model, targetCF)
    if not (model and model.Parent) then return end
    anchorModel(model, true)
    task.wait()
    local ok, curPivot = pcall(function() return model:GetPivot() end)
    if not ok then
        local mp = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if mp then curPivot = mp.CFrame else anchorModel(model, false); return end
    end
    local relCFs = {}
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then relCFs[p] = curPivot:ToObjectSpace(p.CFrame) end
    end
    for p, rel in pairs(relCFs) do
        p.CFrame = targetCF:ToWorldSpace(rel)
    end
    task.wait()
    anchorModel(model, false)
end

-- ════════════════════════════════════════════════════
-- ITEM IDENTIFICATION  (no trees / land / terrain)
-- ════════════════════════════════════════════════════
local EXCLUDED = {
    Map=true,Terrain=true,Camera=true,Baseplate=true,Base=true,Ground=true,
    Land=true,Island=true,Water=true,
    PalmTree=true,CypressTree=true,SpruceTree=true,ElmTree=true,ChestnutTree=true,
    CherryTree=true,OakTree=true,BirchTree=true,PineTree=true,FirTree=true,
    GoldTree=true,SnowyPineTree=true,VolcanicAshTree=true,
    Stump=true,Branch=true,PalmBranch=true,
    Fence=true,Road=true,Path=true,River=true,Cliff=true,Hill=true,Bridge=true,
    Rock=true,Bush=true,Grass=true,Dirt=true,
    Property=true,Plot=true,LandPlot=true,
}

local function isSortableItem(model)
    if not model or not model:IsA("Model") then return false end
    if model == workspace then return false end
    if EXCLUDED[model.Name] then return false end
    if model:FindFirstChild("OriginSquare") then return false end
    if model.Parent and model.Parent.Name == "Properties" then return false end
    local mp = model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
    if not mp then return false end
    if model:FindFirstChild("TreeClass") then
        local n = 0
        for _, v in ipairs(model:GetChildren()) do
            if v:IsA("BasePart") or v:IsA("UnionOperation") or v:IsA("MeshPart") then n += 1 end
        end
        return n <= 20
    end
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
    for _ in pairs(selectedItems) do n += 1 end
    return n
end

local function groupSelectItem(target)
    if not isSortableItem(target) then return end
    local nv = target:FindFirstChild("ItemName") or target:FindFirstChild("PurchasedBoxItemName")
    local targetName = nv and nv.Value or target.Name
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local v = obj:FindFirstChild("ItemName") or obj:FindFirstChild("PurchasedBoxItemName")
            if (v and v.Value or obj.Name) == targetName then highlightItem(obj) end
        end
    end
end

-- ════════════════════════════════════════════════════
-- SORT SLOT CALCULATOR
-- Fills bottom layer FULLY before going to next.
-- Max 5 layers enforced.
-- ════════════════════════════════════════════════════
local function calculateSlots(items, anchorCF, colCount, layerCount, rowCount)
    colCount   = math.clamp(colCount,   1, 12)
    layerCount = math.clamp(layerCount, 1, MAX_LAYERS)
    rowCount   = math.max(rowCount, 0)

    local entries = {}
    for _, model in ipairs(items) do
        local ok, _, sz = pcall(function() return model:GetBoundingBox() end)
        local s = ok and sz or Vector3.new(2, 2, 2)
        table.insert(entries, { model=model, w=s.X, h=s.Y, d=s.Z })
    end
    table.sort(entries, function(a, b) return a.h > b.h end)

    local total = #entries
    local rpl
    if rowCount > 0 then rpl = rowCount
    else rpl = math.max(1, math.ceil(math.ceil(total / layerCount) / colCount)) end
    local slotPerLayer = colCount * rpl

    -- Assign layer/row/col, filling bottom layer fully first
    for i, e in ipairs(entries) do
        local idx   = i - 1
        local layer = math.min(math.floor(idx / slotPerLayer), layerCount - 1)
        local rem   = idx % slotPerLayer
        e.layer = layer
        e.row   = math.floor(rem / colCount)
        e.col   = rem % colCount
    end

    local layerMaxH, rowMaxD, colMaxW = {}, {}, {}
    for _, e in ipairs(entries) do
        local l, r, c = e.layer, e.row, e.col
        layerMaxH[l] = math.max(layerMaxH[l] or 0, e.h)
        if not rowMaxD[l] then rowMaxD[l] = {} end
        rowMaxD[l][r] = math.max(rowMaxD[l][r] or 0, e.d)
        colMaxW[c]    = math.max(colMaxW[c] or 0, e.w)
    end

    local layerY = {}; local accY = 0
    for l = 0, layerCount - 1 do
        layerY[l] = accY
        accY += (layerMaxH[l] or 0) + ITEM_GAP
    end

    local rowZ = {}
    for l = 0, layerCount - 1 do
        rowZ[l] = {}; local accZ = 0
        local maxR = 0
        for _, e in ipairs(entries) do if e.layer==l and e.row>maxR then maxR=e.row end end
        for r = 0, maxR do
            rowZ[l][r] = accZ
            accZ += ((rowMaxD[l] and rowMaxD[l][r]) or 0) + ITEM_GAP
        end
    end

    local colX = {}; local accX = 0
    for c = 0, colCount - 1 do
        colX[c] = accX
        accX += (colMaxW[c] or 0) + ITEM_GAP
    end

    local slots = {}
    for _, e in ipairs(entries) do
        local lx = (colX[e.col] or 0)                              + e.w / 2
        local ly = (layerY[e.layer] or 0)                          + e.h / 2
        local lz = ((rowZ[e.layer] and rowZ[e.layer][e.row]) or 0) + e.d / 2
        table.insert(slots, { model=e.model, cf=anchorCF * CFrame.new(lx,ly,lz), layer=e.layer })
    end
    return slots
end

-- ════════════════════════════════════════════════════
-- SORT ENGINE — layer by layer, gap-check each layer
-- ════════════════════════════════════════════════════
local function runSort(slots, numLayers, onProgress, onDone)
    local byLayer = {}
    for _, s in ipairs(slots) do
        local l = s.layer or 0
        if not byLayer[l] then byLayer[l] = {} end
        table.insert(byLayer[l], s)
    end

    task.spawn(function()
        local done  = 0
        local total = #slots

        for layer = 0, numLayers - 1 do
            if sortAbort then break end
            local layerSlots = byLayer[layer]
            if not layerSlots then continue end

            -- Pass 1: teleport each item in this layer
            for _, s in ipairs(layerSlots) do
                if sortAbort then break end
                if s.model and s.model.Parent then
                    cleanTeleport(s.model, s.cf)
                    done += 1
                    if onProgress then onProgress(done, total) end
                    task.wait(0.06)
                end
            end

            if sortAbort then break end

            -- Pass 2: gap-check and retry any that missed
            for _, s in ipairs(layerSlots) do
                if sortAbort then break end
                if s.model and s.model.Parent then
                    local mp = getMainPart(s.model)
                    if mp and (mp.Position - s.cf.Position).Magnitude > CONFIRM_DIST then
                        cleanTeleport(s.model, s.cf)
                        task.wait(0.08)
                    end
                end
            end

            if layer < numLayers - 1 then task.wait(0.18) end
        end

        if onDone then onDone(not sortAbort) end
    end)
end

-- ════════════════════════════════════════════════════
-- PREVIEW BOX
-- ════════════════════════════════════════════════════
local function destroyPreview()
    if followConn then followConn:Disconnect(); followConn = nil end
    if previewPart and previewPart.Parent then previewPart:Destroy() end
    previewPart = nil; previewFollowing = false; previewPlaced = false
end

local function computePreviewSize()
    local entries = {}
    for model in pairs(selectedItems) do
        local ok, _, sz = pcall(function() return model:GetBoundingBox() end)
        local s = ok and sz or Vector3.new(2,2,2)
        table.insert(entries, { w=s.X, h=s.Y, d=s.Z })
    end
    if #entries == 0 then return 4,4,4 end
    local cols   = math.max(1, gridCols)
    local layers = math.clamp(gridLayers, 1, MAX_LAYERS)
    local rows   = math.max(0, gridRows)
    local maxW,maxH,maxD = 0,0,0
    for _, e in ipairs(entries) do
        if e.w>maxW then maxW=e.w end
        if e.h>maxH then maxH=e.h end
        if e.d>maxD then maxD=e.d end
    end
    local spl = rows>0 and cols*rows or math.ceil(#entries/layers)
    local actualRows = math.ceil(spl/cols)
    return math.max(cols*(maxW+ITEM_GAP)-ITEM_GAP,1),
           math.max(layers*(maxH+ITEM_GAP)-ITEM_GAP,1),
           math.max(actualRows*(maxD+ITEM_GAP)-ITEM_GAP,1)
end

local function getMouseSurfaceCF(halfH)
    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local params  = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    if previewPart then table.insert(excl, previewPart) end
    if player.Character then table.insert(excl, player.Character) end
    params.FilterDescendantsInstances = excl
    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction*600, params)
    local hitPos
    if result then hitPos = result.Position
    else
        local t = unitRay.Origin.Y / -unitRay.Direction.Y
        hitPos = unitRay.Origin + unitRay.Direction * (t>0 and t or 40)
    end
    return CFrame.new(hitPos.X, hitPos.Y+halfH, hitPos.Z)
end

local function buildAndFollowPreview()
    destroyPreview()
    local sX,sY,sZ = computePreviewSize()
    previewPart = Instance.new("Part")
    previewPart.Name="VHSorterPreview"; previewPart.Anchored=true
    previewPart.CanCollide=false; previewPart.CanQuery=false; previewPart.CastShadow=false
    previewPart.Size=Vector3.new(math.max(sX,0.5),math.max(sY,0.5),math.max(sZ,0.5))
    previewPart.Color=PREVIEW_COLOR; previewPart.Material=Enum.Material.SmoothPlastic
    previewPart.Transparency=0.50; previewPart.Parent=workspace
    local sb=Instance.new("SelectionBox")
    sb.Color3=PREVIEW_COLOR; sb.LineThickness=0.07; sb.SurfaceTransparency=1
    sb.Adornee=previewPart; sb.Parent=previewPart
    previewFollowing=true; previewPlaced=false
    followConn = RunService.RenderStepped:Connect(function()
        if not previewFollowing then return end
        if not (previewPart and previewPart.Parent) then
            followConn:Disconnect(); followConn=nil; return end
        local halfH = previewPart.Size.Y/2
        previewPart.CFrame = previewPart.CFrame:Lerp(getMouseSurfaceCF(halfH), 0.22)
    end)
end

local function placePreview()
    if not (previewPart and previewPart.Parent and previewFollowing) then return end
    previewFollowing=false
    if followConn then followConn:Disconnect(); followConn=nil end
    previewPart.CFrame = getMouseSurfaceCF(previewPart.Size.Y/2)
    previewPart.Color  = PLACED_COLOR
    local sb = previewPart:FindFirstChildOfClass("SelectionBox")
    if sb then sb.Color3=PLACED_COLOR end
    previewPlaced=true
end

-- ════════════════════════════════════════════════════
-- UI HELPERS
-- ════════════════════════════════════════════════════
local function mkLabel(text)
    local lbl=Instance.new("TextLabel",sorterPage)
    lbl.Size=UDim2.new(1,-12,0,22); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11
    lbl.TextColor3=Color3.fromRGB(120,120,150); lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=string.upper(text)
    Instance.new("UIPadding",lbl).PaddingLeft=UDim.new(0,4)
end

local function mkSep()
    local s=Instance.new("Frame",sorterPage)
    s.Size=UDim2.new(1,-12,0,1); s.BackgroundColor3=Color3.fromRGB(40,40,55); s.BorderSizePixel=0
end

local function mkToggle(text,default,cb)
    local fr=Instance.new("Frame",sorterPage)
    fr.Size=UDim2.new(1,-12,0,32); fr.BackgroundColor3=Color3.fromRGB(24,24,30)
    Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",fr)
    lbl.Size=UDim2.new(1,-50,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local tb=Instance.new("TextButton",fr)
    tb.Size=UDim2.new(0,34,0,18); tb.Position=UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3=default and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text=""; Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame",tb)
    dot.Size=UDim2.new(0,14,0,14)
    dot.Position=UDim2.new(0,default and 18 or 2,0.5,-7)
    dot.BackgroundColor3=Color3.fromRGB(255,255,255)
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local on=default; if cb then cb(on) end
    tb.MouseButton1Click:Connect(function()
        on=not on
        TweenService:Create(tb,TweenInfo.new(0.18,Enum.EasingStyle.Quint),
            {BackgroundColor3=on and Color3.fromRGB(60,180,60) or BTN_COLOR}):Play()
        TweenService:Create(dot,TweenInfo.new(0.18,Enum.EasingStyle.Quint),
            {Position=UDim2.new(0,on and 18 or 2,0.5,-7)}):Play()
        if cb then cb(on) end
    end)
    return fr
end

local function mkBtn(text,color,cb)
    color=color or BTN_COLOR
    local btn=Instance.new("TextButton",sorterPage)
    btn.Size=UDim2.new(1,-12,0,34); btn.BackgroundColor3=color
    btn.Text=text; btn.Font=Enum.Font.GothamSemibold; btn.TextSize=13
    btn.TextColor3=THEME_TEXT; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    local hov=Color3.new(math.min(color.R+0.09,1),math.min(color.G+0.04,1),math.min(color.B+0.09,1))
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=hov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=color}):Play() end)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local AXIS_COLORS={X=Color3.fromRGB(220,70,70),Y=Color3.fromRGB(70,200,70),Z=Color3.fromRGB(70,120,255)}

local function mkIntSlider(label,axis,minV,maxV,defaultV,cb)
    local axCol=AXIS_COLORS[axis] or THEME_TEXT
    local fr=Instance.new("Frame",sorterPage)
    fr.Size=UDim2.new(1,-12,0,54); fr.BackgroundColor3=Color3.fromRGB(22,22,30); fr.BorderSizePixel=0
    Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6)
    local axTag=Instance.new("TextLabel",fr)
    axTag.Size=UDim2.new(0,18,0,22); axTag.Position=UDim2.new(0,8,0,5)
    axTag.BackgroundTransparency=1; axTag.Font=Enum.Font.GothamBold
    axTag.TextSize=14; axTag.TextColor3=axCol; axTag.Text=axis
    local topLbl=Instance.new("TextLabel",fr)
    topLbl.Size=UDim2.new(0.55,0,0,22); topLbl.Position=UDim2.new(0,28,0,5)
    topLbl.BackgroundTransparency=1; topLbl.Font=Enum.Font.GothamSemibold
    topLbl.TextSize=12; topLbl.TextColor3=THEME_TEXT
    topLbl.TextXAlignment=Enum.TextXAlignment.Left; topLbl.Text=label
    local valLbl=Instance.new("TextLabel",fr)
    valLbl.Size=UDim2.new(0.3,0,0,22); valLbl.Position=UDim2.new(0.7,0,0,5)
    valLbl.BackgroundTransparency=1; valLbl.Font=Enum.Font.GothamBold
    valLbl.TextSize=13; valLbl.TextColor3=axCol
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=tostring(defaultV)
    local track=Instance.new("Frame",fr)
    track.Size=UDim2.new(1,-16,0,6); track.Position=UDim2.new(0,8,0,36)
    track.BackgroundColor3=Color3.fromRGB(38,38,52); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((defaultV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=axCol; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,18,0,18); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defaultV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(225,225,245); knob.Text=""; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local dragging=false; local cur=defaultV
    local function apply(screenX)
        local ratio=math.clamp((screenX-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
        local val=math.round(minV+ratio*(maxV-minV)); if val==cur then return end; cur=val
        fill.Size=UDim2.new(ratio,0,1,0); knob.Position=UDim2.new(ratio,0,0.5,0)
        valLbl.Text=tostring(val); if cb then cb(val) end
    end
    knob.MouseButton1Down:Connect(function() dragging=true end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; apply(inp.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then apply(inp.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    return fr
end

-- ════════════════════════════════════════════════════
-- STATUS CARD
-- ════════════════════════════════════════════════════
local statusCard=Instance.new("Frame")
statusCard.Size=UDim2.new(1,-12,0,48); statusCard.BackgroundColor3=Color3.fromRGB(28,20,38)
statusCard.BorderSizePixel=0
Instance.new("UICorner",statusCard).CornerRadius=UDim.new(0,8)
local scStroke=Instance.new("UIStroke",statusCard)
scStroke.Color=Color3.fromRGB(255,180,0); scStroke.Thickness=1; scStroke.Transparency=0.5
local statusLabel=Instance.new("TextLabel",statusCard)
statusLabel.Size=UDim2.new(1,-16,1,0); statusLabel.Position=UDim2.new(0,8,0,0)
statusLabel.BackgroundTransparency=1; statusLabel.Font=Enum.Font.GothamSemibold; statusLabel.TextSize=12
statusLabel.TextColor3=Color3.fromRGB(255,210,100)
statusLabel.TextXAlignment=Enum.TextXAlignment.Left; statusLabel.TextWrapped=true
statusLabel.Text="Select items to get started."

local function setStatus(msg,col)
    statusLabel.Text=msg; statusLabel.TextColor3=col or Color3.fromRGB(255,210,100)
end

-- ════════════════════════════════════════════════════
-- PROGRESS BAR
-- ════════════════════════════════════════════════════
local pbContainer=Instance.new("Frame")
pbContainer.Size=UDim2.new(1,-12,0,44); pbContainer.BackgroundColor3=Color3.fromRGB(18,18,24)
pbContainer.BorderSizePixel=0; pbContainer.Visible=false
Instance.new("UICorner",pbContainer).CornerRadius=UDim.new(0,8)
local pbLabel=Instance.new("TextLabel",pbContainer)
pbLabel.Size=UDim2.new(1,-12,0,16); pbLabel.Position=UDim2.new(0,6,0,4)
pbLabel.BackgroundTransparency=1; pbLabel.Font=Enum.Font.GothamSemibold; pbLabel.TextSize=11
pbLabel.TextColor3=THEME_TEXT; pbLabel.TextXAlignment=Enum.TextXAlignment.Left; pbLabel.Text="Sorting..."
local pbTrack=Instance.new("Frame",pbContainer)
pbTrack.Size=UDim2.new(1,-12,0,12); pbTrack.Position=UDim2.new(0,6,0,26)
pbTrack.BackgroundColor3=Color3.fromRGB(30,30,42); pbTrack.BorderSizePixel=0
Instance.new("UICorner",pbTrack).CornerRadius=UDim.new(1,0)
local pbFill=Instance.new("Frame",pbTrack)
pbFill.Size=UDim2.new(0,0,1,0); pbFill.BackgroundColor3=Color3.fromRGB(255,175,55)
pbFill.BorderSizePixel=0; Instance.new("UICorner",pbFill).CornerRadius=UDim.new(1,0)

local function hideProgress(delay)
    task.delay(delay or 2.0, function()
        TweenService:Create(pbContainer,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        TweenService:Create(pbFill,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        TweenService:Create(pbLabel,TweenInfo.new(0.4),{TextTransparency=1}):Play()
        task.delay(0.45,function()
            pbContainer.Visible=false; pbContainer.BackgroundTransparency=0
            pbFill.BackgroundTransparency=0; pbFill.BackgroundColor3=Color3.fromRGB(255,175,55)
            pbFill.Size=UDim2.new(0,0,1,0); pbLabel.TextTransparency=0
        end)
    end)
end

-- ════════════════════════════════════════════════════
-- LASSO OVERLAY
-- ════════════════════════════════════════════════════
local coreGui=game:GetService("CoreGui")
local lassoFrame=Instance.new("Frame",coreGui:FindFirstChild("VanillaHub") or coreGui)
lassoFrame.Name="SorterLasso"; lassoFrame.BackgroundColor3=Color3.fromRGB(255,160,40)
lassoFrame.BackgroundTransparency=0.82; lassoFrame.BorderSizePixel=0
lassoFrame.Visible=false; lassoFrame.ZIndex=20
local lstroke=Instance.new("UIStroke",lassoFrame)
lstroke.Color=Color3.fromRGB(255,210,80); lstroke.Thickness=1.5

local function updateLassoVis(s,c)
    local minX=math.min(s.X,c.X); local minY=math.min(s.Y,c.Y)
    lassoFrame.Position=UDim2.new(0,minX,0,minY)
    lassoFrame.Size=UDim2.new(0,math.abs(c.X-s.X),0,math.abs(c.Y-s.Y))
end

local function selectLasso()
    if not lassoStartPos then return end
    local cur=Vector2.new(mouse.X,mouse.Y)
    local minX=math.min(lassoStartPos.X,cur.X); local maxX=math.max(lassoStartPos.X,cur.X)
    local minY=math.min(lassoStartPos.Y,cur.Y); local maxY=math.max(lassoStartPos.Y,cur.Y)
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local mp2=getMainPart(obj)
            if mp2 then
                local sp,vis=camera:WorldToScreenPoint(mp2.Position)
                if vis and sp.X>=minX and sp.X<=maxX and sp.Y>=minY and sp.Y<=maxY then
                    highlightItem(obj) end
            end
        end
    end
end

-- ════════════════════════════════════════════════════
-- REFRESH STATUS
-- ════════════════════════════════════════════════════
local function refreshStatus()
    local n=countSelected()
    if isSorting then
        setStatus("Sorting in progress...",Color3.fromRGB(140,220,255))
    elseif n==0 then
        setStatus("Select items with Click, Group, or Lasso.")
    elseif previewFollowing then
        setStatus("Preview following mouse — click to place.",Color3.fromRGB(140,220,255))
    elseif previewPlaced then
        setStatus(n.." item(s) ready — hit Start Sorting! (Max "..MAX_LAYERS.." layers)",Color3.fromRGB(100,220,120))
    elseif previewPart then
        setStatus("Preview exists — click anywhere to place it.",Color3.fromRGB(200,200,100))
    else
        setStatus(n.." selected — click Generate Preview.")
    end
end

-- ════════════════════════════════════════════════════
-- BUILD UI
-- ════════════════════════════════════════════════════
mkLabel("Status")
statusCard.Parent=sorterPage

mkSep(); mkLabel("Selection Mode")

mkToggle("Click Selection",false,function(v)
    clickSelEnabled=v; if v then lassoEnabled=false; groupSelEnabled=false end end)
mkToggle("Group Selection",false,function(v)
    groupSelEnabled=v; if v then clickSelEnabled=false; lassoEnabled=false end end)
mkToggle("Lasso Tool",false,function(v)
    lassoEnabled=v; if v then clickSelEnabled=false; groupSelEnabled=false end end)

local selHint=Instance.new("TextLabel",sorterPage)
selHint.Size=UDim2.new(1,-12,0,26); selHint.BackgroundColor3=Color3.fromRGB(18,18,24)
selHint.BorderSizePixel=0; selHint.Font=Enum.Font.Gotham; selHint.TextSize=11
selHint.TextColor3=Color3.fromRGB(100,100,130); selHint.TextWrapped=true
selHint.TextXAlignment=Enum.TextXAlignment.Left
selHint.Text="  Lasso: drag to box-select.  Group: click to select all of same type."
Instance.new("UICorner",selHint).CornerRadius=UDim.new(0,6)
Instance.new("UIPadding",selHint).PaddingLeft=UDim.new(0,6)

mkSep(); mkLabel("Sort Grid  —  X Width   Y Height (max 5)   Z Depth")

mkIntSlider("Width  (items per row)",   "X",1,12,3,function(v) gridCols=v end)
mkIntSlider("Height  (layers, max 5)",  "Y",1,5, 1,function(v) gridLayers=math.min(v,MAX_LAYERS) end)
mkIntSlider("Depth   (rows, 0 = auto)", "Z",0,12,0,function(v) gridRows=v end)

local gridHint=Instance.new("TextLabel",sorterPage)
gridHint.Size=UDim2.new(1,-12,0,28); gridHint.BackgroundColor3=Color3.fromRGB(18,18,24)
gridHint.BorderSizePixel=0; gridHint.Font=Enum.Font.Gotham; gridHint.TextSize=11
gridHint.TextColor3=Color3.fromRGB(100,100,130); gridHint.TextWrapped=true
gridHint.TextXAlignment=Enum.TextXAlignment.Left
gridHint.Text="  Fills left->right (X), front->back (Z), bottom->top (Y).  Bottom layer full before next."
Instance.new("UICorner",gridHint).CornerRadius=UDim.new(0,6)
Instance.new("UIPadding",gridHint).PaddingLeft=UDim.new(0,6)

mkSep(); mkLabel("Preview")

mkBtn("Generate Preview  (follows mouse)",Color3.fromRGB(35,55,100),function()
    if countSelected()==0 then setStatus("No items selected!"); return end
    buildAndFollowPreview(); refreshStatus()
end)

mkBtn("Clear Preview",BTN_COLOR,function() destroyPreview(); refreshStatus() end)

mkSep(); mkLabel("Actions")

pbContainer.Parent=sorterPage

mkBtn("Start Sorting",Color3.fromRGB(35,100,50),function()
    if isSorting then return end
    if not (previewPlaced and previewPart and previewPart.Parent) then
        setStatus("Generate a preview and place it first!"); return end
    if countSelected()==0 then setStatus("No items selected!"); return end

    local items={}
    for model in pairs(selectedItems) do
        if model and model.Parent then table.insert(items,model) end
    end
    if #items==0 then return end

    local anchorCF=previewPart.CFrame
        *CFrame.new(-previewPart.Size.X/2,-previewPart.Size.Y/2,-previewPart.Size.Z/2)
    local numLayers=math.clamp(gridLayers,1,MAX_LAYERS)
    local slots=calculateSlots(items,anchorCF,gridCols,numLayers,gridRows)

    isSorting=true; sortAbort=false
    pbContainer.Visible=true
    pbFill.Size=UDim2.new(0,0,1,0); pbFill.BackgroundColor3=Color3.fromRGB(255,175,55)
    pbLabel.Text="Sorting... 0 / "..#slots
    refreshStatus()

    runSort(slots,numLayers,
        function(done,total)
            local pct=math.clamp(done/math.max(total,1),0,1)
            TweenService:Create(pbFill,TweenInfo.new(0.15,Enum.EasingStyle.Quad),
                {Size=UDim2.new(pct,0,1,0)}):Play()
            pbLabel.Text="Sorting... "..done.." / "..total
        end,
        function(success)
            isSorting=false
            if success then
                TweenService:Create(pbFill,TweenInfo.new(0.25),
                    {Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(90,220,110)}):Play()
                pbLabel.Text="Sorting complete!"
                destroyPreview(); unhighlightAll(); hideProgress(2.5)
            else
                pbLabel.Text="Sorting stopped."
            end
            refreshStatus()
        end
    )
end)

mkBtn("Stop Sorting",Color3.fromRGB(100,60,20),function()
    if not isSorting then return end
    sortAbort=true; isSorting=false; pbLabel.Text="Stopping..."; refreshStatus()
end)

mkBtn("Cancel  (clear all)",Color3.fromRGB(70,20,20),function()
    sortAbort=true; isSorting=false
    destroyPreview(); unhighlightAll()
    pbLabel.Text="Cancelled."; hideProgress(1.0); refreshStatus()
end)

mkBtn("Clear Selection",BTN_COLOR,function() unhighlightAll(); refreshStatus() end)

-- ════════════════════════════════════════════════════
-- MOUSE INPUT
-- ════════════════════════════════════════════════════
local mouseDownConn=mouse.Button1Down:Connect(function()
    if lassoEnabled then
        lassoDragging=true; lassoStartPos=Vector2.new(mouse.X,mouse.Y)
        lassoFrame.Size=UDim2.new(0,0,0,0); lassoFrame.Visible=true; return
    end
    if previewFollowing then placePreview(); refreshStatus(); return end
    local target=mouse.Target; if not target then return end
    local model=target:FindFirstAncestorOfClass("Model"); if not model then return end
    if clickSelEnabled and isSortableItem(model) then
        if selectedItems[model] then unhighlightItem(model) else highlightItem(model) end
        refreshStatus()
    elseif groupSelEnabled and isSortableItem(model) then
        groupSelectItem(model); refreshStatus()
    end
end)

local mouseMoveConn=mouse.Move:Connect(function()
    if lassoDragging and lassoEnabled and lassoStartPos then
        updateLassoVis(lassoStartPos,Vector2.new(mouse.X,mouse.Y)) end
end)

local mouseUpConn=mouse.Button1Up:Connect(function()
    if lassoDragging and lassoEnabled and lassoStartPos then
        lassoDragging=false; selectLasso()
        lassoFrame.Visible=false; lassoStartPos=nil; refreshStatus()
    end
    lassoDragging=false
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(cleanupTasks,function()
    sortAbort=true; isSorting=false
    if followConn then followConn:Disconnect(); followConn=nil end
    mouseDownConn:Disconnect(); mouseMoveConn:Disconnect(); mouseUpConn:Disconnect()
    if lassoFrame and lassoFrame.Parent then lassoFrame:Destroy() end
    destroyPreview(); unhighlightAll()
end)

refreshStatus()
print("[VanillaHub] Vanilla4 (Sorter FIXED) loaded")
