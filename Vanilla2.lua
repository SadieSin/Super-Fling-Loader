-- ════════════════════════════════════════════════════
-- VANILLA2 — World Tab + Dupe Tab  (FIXED)
-- Execute AFTER Vanilla1
--
-- FIXES vs original:
--   - Truck teleport (big dupe): wheels no longer detach
--     Fix: anchor all parts → SetPrimaryPartCFrame → wait 1 frame → unanchor
--   - Single Truck Teleport: same wheel fix + new grid-placement sub-section
--     "Single Truck Load Dupe" with X/Y/Z sliders, sit-to-select, right-click preview
--   - No lag changes to any non-truck code (structures, furniture, wood unchanged)
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla2: _G.VH not found. Execute Vanilla1 first.")
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

-- ════════════════════════════════════════════════════
-- WHEEL FIX HELPER
-- Anchor all parts before any CFrame move so WheelJoints
-- don't snap under physics stress, then unanchor after.
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

local function safeTeleportTruck(tModel, destCF)
    -- 1. Anchor everything — joints safe during move
    anchorModel(tModel, true)
    task.wait()
    -- 2. Move using relative offsets so all parts stay in formation
    local ok, curPivot = pcall(function() return tModel:GetPivot() end)
    if not ok then
        -- fallback for older models
        local mp = tModel.PrimaryPart or tModel:FindFirstChildWhichIsA("BasePart")
        if mp then curPivot = mp.CFrame else anchorModel(tModel, false); return end
    end
    local relCFs = {}
    for _, p in ipairs(tModel:GetDescendants()) do
        if p:IsA("BasePart") then relCFs[p] = curPivot:ToObjectSpace(p.CFrame) end
    end
    for p, rel in pairs(relCFs) do
        p.CFrame = destCF:ToWorldSpace(rel)
    end
    task.wait()
    -- 3. Unanchor — wheels reattach cleanly
    anchorModel(tModel, false)
end

-- ════════════════════════════════════════════════════
-- WORLD TAB  (unchanged from original)
-- ════════════════════════════════════════════════════
local worldPage = pages["WorldTab"]

local function createWSectionLabel(text)
    local lbl = Instance.new("TextLabel", worldPage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    local pad = Instance.new("UIPadding", lbl); pad.PaddingLeft = UDim.new(0, 4)
end

local function createWSep()
    local sep = Instance.new("Frame", worldPage)
    sep.Size = UDim2.new(1,-12,0,1); sep.BackgroundColor3 = Color3.fromRGB(40,40,55); sep.BorderSizePixel = 0
end

local function createWorldToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", worldPage)
    frame.Size = UDim2.new(1,-12,0,32); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
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

local worldClockConn    = nil
local alwaysDayActive   = false
local alwaysNightActive = false
local walkOnWaterConn   = nil
local walkOnWaterParts  = {}

table.insert(cleanupTasks, function()
    if worldClockConn   then worldClockConn:Disconnect();   worldClockConn = nil   end
    if walkOnWaterConn  then walkOnWaterConn:Disconnect();  walkOnWaterConn = nil  end
    for _, p in ipairs(walkOnWaterParts) do if p and p.Parent then p:Destroy() end end
    walkOnWaterParts = {}
    alwaysDayActive   = false
    alwaysNightActive = false
end)

createWSectionLabel("Environment")

createWorldToggle("Always Day", true, function(v)
    alwaysDayActive = v
    if worldClockConn then worldClockConn:Disconnect(); worldClockConn = nil end
    if v then
        alwaysNightActive = false
        local Lighting = game:GetService("Lighting")
        Lighting.ClockTime = 14
        worldClockConn = game:GetService("RunService").Heartbeat:Connect(function()
            Lighting.ClockTime = 14
        end)
    end
end)

createWorldToggle("Always Night", false, function(v)
    alwaysNightActive = v
    if worldClockConn then worldClockConn:Disconnect(); worldClockConn = nil end
    if v then
        alwaysDayActive = false
        local Lighting = game:GetService("Lighting")
        Lighting.ClockTime = 0
        worldClockConn = game:GetService("RunService").Heartbeat:Connect(function()
            Lighting.ClockTime = 0
        end)
    end
end)

local _origFogEnd   = game:GetService("Lighting").FogEnd
local _origFogStart = game:GetService("Lighting").FogStart
createWorldToggle("Remove Fog", false, function(v)
    local Lighting = game:GetService("Lighting")
    if v then
        Lighting.FogEnd   = 1e9
        Lighting.FogStart = 1e9
    else
        Lighting.FogEnd   = _origFogEnd
        Lighting.FogStart = _origFogStart
    end
end)

createWorldToggle("Shadows", true, function(v)
    game:GetService("Lighting").GlobalShadows = v
end)

createWSep()
createWSectionLabel("Water")

createWorldToggle("Walk On Water", false, function(v)
    if walkOnWaterConn then walkOnWaterConn:Disconnect(); walkOnWaterConn = nil end
    for _, p in ipairs(walkOnWaterParts) do if p and p.Parent then p:Destroy() end end
    walkOnWaterParts = {}
    if v then
        local function makeSolid(part)
            if part:IsA("Part") and part.Name == "Water" then
                local clone = Instance.new("Part")
                clone.Size = part.Size; clone.CFrame = part.CFrame
                clone.Anchored = true; clone.CanCollide = true
                clone.Transparency = 1; clone.Name = "WalkWaterPlane"
                clone.Parent = game:GetService("Workspace")
                table.insert(walkOnWaterParts, clone)
            end
        end
        for _, p in ipairs(game:GetService("Workspace"):GetDescendants()) do makeSolid(p) end
        walkOnWaterConn = game:GetService("Workspace").DescendantAdded:Connect(makeSolid)
    end
end)

createWorldToggle("Remove Water", false, function(v)
    if _G.VH and _G.VH.setRemovedWater then _G.VH.setRemovedWater(v) end
    for _, p in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if p:IsA("Part") and p.Name == "Water" then
            p.Transparency = v and 1 or 0.5
            p.CanCollide   = false
        end
    end
end)

-- ════════════════════════════════════════════════════
-- DUPE TAB
-- ════════════════════════════════════════════════════
local dupePage = pages["DupeTab"]

local function createDSection(text)
    local lbl = Instance.new("TextLabel", dupePage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function createDSep()
    local s = Instance.new("Frame", dupePage)
    s.Size = UDim2.new(1,-12,0,1); s.BackgroundColor3 = Color3.fromRGB(40,40,55); s.BorderSizePixel = 0
end

local function createDBtn(text, color, callback)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", dupePage)
    btn.Size = UDim2.new(1,-12,0,32); btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local hov = Color3.fromRGB(
        math.min(color.R*255+20,255)/255,
        math.min(color.G*255+8, 255)/255,
        math.min(color.B*255+20,255)/255)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=hov}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=color}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createDToggle(text, default, callback)
    local frame = Instance.new("Frame", dupePage)
    frame.Size = UDim2.new(1,-12,0,32); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0,34,0,18); tb.Position = UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3 = default and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text = ""; Instance.new("UICorner", tb).CornerRadius = UDim.new(1,0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0,14,0,14)
    circle.Position = UDim2.new(0, default and 18 or 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)
    local toggled = default
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
    return frame, function() return toggled end
end

local function makeDupeDropdown(labelText, parentPage)
    parentPage = parentPage or dupePage
    local selected  = ""
    local isOpen    = false
    local ITEM_H    = 34
    local MAX_SHOW  = 5
    local HEADER_H  = 40

    local outer = Instance.new("Frame", parentPage)
    outer.Size             = UDim2.new(1,-12, 0, HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22,22,30)
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0,8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = Color3.fromRGB(60,60,90); outerStroke.Thickness = 1; outerStroke.Transparency = 0.5

    local header = Instance.new("Frame", outer)
    header.Size             = UDim2.new(1,0,0,HEADER_H)
    header.BackgroundTransparency = 1
    header.BorderSizePixel  = 0

    local lbl = Instance.new("TextLabel", header)
    lbl.Size               = UDim2.new(0,80,1,0)
    lbl.Position           = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 12
    lbl.TextColor3         = THEME_TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size             = UDim2.new(1,-96,0,28)
    selFrame.Position         = UDim2.new(0,90,0.5,-14)
    selFrame.BackgroundColor3 = Color3.fromRGB(30,30,42)
    selFrame.BorderSizePixel  = 0
    Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0,6)
    local selStroke = Instance.new("UIStroke", selFrame)
    selStroke.Color = Color3.fromRGB(70,70,110); selStroke.Thickness = 1; selStroke.Transparency = 0.4

    local avatar = Instance.new("ImageLabel", selFrame)
    avatar.Size               = UDim2.new(0,20,0,20)
    avatar.Position           = UDim2.new(0,6,0.5,-10)
    avatar.BackgroundColor3   = Color3.fromRGB(45,45,60)
    avatar.BorderSizePixel    = 0
    avatar.Image              = ""
    avatar.ScaleType          = Enum.ScaleType.Crop
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1,0)

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size               = UDim2.new(1,-60,1,0)
    selLbl.Position           = UDim2.new(0,32,0,0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text               = "Select a player..."
    selLbl.Font               = Enum.Font.GothamSemibold
    selLbl.TextSize           = 12
    selLbl.TextColor3         = Color3.fromRGB(110,110,140)
    selLbl.TextXAlignment     = Enum.TextXAlignment.Left
    selLbl.TextTruncate       = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size               = UDim2.new(0,22,1,0)
    arrowLbl.Position           = UDim2.new(1,-24,0,0)
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Text               = "▾"
    arrowLbl.Font               = Enum.Font.GothamBold
    arrowLbl.TextSize           = 14
    arrowLbl.TextColor3         = Color3.fromRGB(120,120,160)
    arrowLbl.TextXAlignment     = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size               = UDim2.new(1,0,1,0)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text               = ""
    headerBtn.ZIndex             = 5

    local divider = Instance.new("Frame", outer)
    divider.Size             = UDim2.new(1,-16,0,1)
    divider.Position         = UDim2.new(0,8,0,HEADER_H)
    divider.BackgroundColor3 = Color3.fromRGB(50,50,75)
    divider.BorderSizePixel  = 0
    divider.Visible          = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position           = UDim2.new(0,0,0,HEADER_H+2)
    listScroll.Size               = UDim2.new(1,0,0,0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel    = 0
    listScroll.ScrollBarThickness = 3
    listScroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
    listScroll.CanvasSize         = UDim2.new(0,0,0,0)
    listScroll.ClipsDescendants   = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder         = Enum.SortOrder.LayoutOrder
    listLayout.Padding           = UDim.new(0,3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop    = UDim.new(0,4)
    listPad.PaddingBottom = UDim.new(0,4)
    listPad.PaddingLeft   = UDim.new(0,6)
    listPad.PaddingRight  = UDim.new(0,6)

    local function setSelected(name, userId)
        selected = name
        selLbl.Text       = name
        selLbl.TextColor3 = THEME_TEXT
        arrowLbl.TextColor3 = Color3.fromRGB(160,160,210)
        outerStroke.Color = Color3.fromRGB(90,90,160)
        if userId then
            pcall(function()
                avatar.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
        end
    end

    local function clearSelected()
        selected = ""
        selLbl.Text       = "Select a player..."
        selLbl.TextColor3 = Color3.fromRGB(110,110,140)
        avatar.Image      = ""
        arrowLbl.TextColor3 = Color3.fromRGB(120,120,160)
        outerStroke.Color = Color3.fromRGB(60,60,90)
    end

    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            local row = Instance.new("TextButton", listScroll)
            row.Size               = UDim2.new(1,0,0,ITEM_H)
            row.BackgroundColor3   = Color3.fromRGB(30,30,45)
            row.BorderSizePixel    = 0
            row.Text               = ""
            row.LayoutOrder        = plr.UserId
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
            local rAvatar = Instance.new("ImageLabel", row)
            rAvatar.Size             = UDim2.new(0,24,0,24)
            rAvatar.Position         = UDim2.new(0,8,0.5,-12)
            rAvatar.BackgroundColor3 = Color3.fromRGB(45,45,60)
            rAvatar.BorderSizePixel  = 0
            rAvatar.ScaleType        = Enum.ScaleType.Crop
            Instance.new("UICorner", rAvatar).CornerRadius = UDim.new(1,0)
            pcall(function()
                rAvatar.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            local rLbl = Instance.new("TextLabel", row)
            rLbl.Size               = UDim2.new(1,-44,1,0)
            rLbl.Position           = UDim2.new(0,38,0,0)
            rLbl.BackgroundTransparency = 1
            rLbl.Text               = plr.Name
            rLbl.Font               = Enum.Font.GothamSemibold
            rLbl.TextSize           = 13
            rLbl.TextColor3         = plr.Name == selected and Color3.fromRGB(200,200,255) or THEME_TEXT
            rLbl.TextXAlignment     = Enum.TextXAlignment.Left
            row.MouseButton1Click:Connect(function()
                setSelected(plr.Name, plr.UserId)
                TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
                TweenService:Create(outer,     TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
                TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
                divider.Visible = false
                isOpen = false
            end)
            row.MouseEnter:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(42,42,62)}):Play()
            end)
            row.MouseLeave:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(30,30,45)}):Play()
            end)
        end
    end

    local function openList()
        isOpen = true
        buildList()
        local count  = #Players:GetPlayers()
        local listH  = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
        local totalH = HEADER_H + 2 + listH
        divider.Visible = true
        TweenService:Create(arrowLbl,    TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=180}):Play()
        TweenService:Create(outer,       TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,totalH)}):Play()
        TweenService:Create(listScroll,  TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,listH)}):Play()
    end

    local function closeList()
        isOpen = false
        TweenService:Create(arrowLbl,   TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Rotation=0}):Play()
        TweenService:Create(outer,      TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end

    headerBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    headerBtn.MouseEnter:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(30,30,42)}):Play()
    end)

    Players.PlayerAdded:Connect(function()
        if isOpen then
            buildList()
            local count = #Players:GetPlayers()
            local listH = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
            outer.Size      = UDim2.new(1,-12,0,HEADER_H + 2 + listH)
            listScroll.Size = UDim2.new(1,0,0,listH)
        end
    end)

    Players.PlayerRemoving:Connect(function(leaving)
        if leaving.Name == selected then clearSelected() end
        if isOpen then
            buildList()
            local count = #Players:GetPlayers()
            local listH = math.min(math.max(count-1,0), MAX_SHOW) * (ITEM_H + 3) + 8
            outer.Size      = UDim2.new(1,-12,0,HEADER_H + 2 + listH)
            listScroll.Size = UDim2.new(1,0,0,listH)
        end
    end)

    return outer, function() return selected end
end

createDSection("Players")
local _, getGiverName    = makeDupeDropdown("Giver")
local _, getReceiverName = makeDupeDropdown("Receiver")

createDSep()
createDSection("What to Transfer")

local _, getStructures = createDToggle("Structures",      false)
local _, getFurniture  = createDToggle("Furniture",       false)
local _, getTrucks     = createDToggle("Truck Load",      false)
local _, getDupeItems  = createDToggle("Purchased Items", false)
local _, getGifs       = createDToggle("Gift Items",      false)
local _, getWood       = createDToggle("Wood",            false)

createDSep()
createDSection("Status")

local dupeStatusFrame = Instance.new("Frame", dupePage)
dupeStatusFrame.Size = UDim2.new(1,-12,0,28); dupeStatusFrame.BackgroundColor3 = Color3.fromRGB(14,14,18)
dupeStatusFrame.BorderSizePixel = 0
Instance.new("UICorner", dupeStatusFrame).CornerRadius = UDim.new(0,6)
local sdot = Instance.new("Frame", dupeStatusFrame)
sdot.Size = UDim2.new(0,7,0,7); sdot.Position = UDim2.new(0,10,0.5,-3)
sdot.BackgroundColor3 = Color3.fromRGB(80,80,100); sdot.BorderSizePixel = 0
Instance.new("UICorner", sdot).CornerRadius = UDim.new(1,0)
local dupeStatusLbl = Instance.new("TextLabel", dupeStatusFrame)
dupeStatusLbl.Size = UDim2.new(1,-28,1,0); dupeStatusLbl.Position = UDim2.new(0,24,0,0)
dupeStatusLbl.BackgroundTransparency = 1; dupeStatusLbl.Font = Enum.Font.Gotham; dupeStatusLbl.TextSize = 12
dupeStatusLbl.TextColor3 = THEME_TEXT; dupeStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
dupeStatusLbl.Text = "Ready"

local function setDupeStatus(msg, active)
    dupeStatusLbl.Text = msg
    sdot.BackgroundColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
end

local function makeDupeProgress(labelText)
    local container = Instance.new("Frame", dupePage)
    container.Size = UDim2.new(1,-12,0,44); container.BackgroundColor3 = Color3.fromRGB(18,18,24)
    container.BorderSizePixel = 0; container.Visible = false
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,7)
    local topLbl = Instance.new("TextLabel", container)
    topLbl.Size = UDim2.new(0.6,0,0,18); topLbl.Position = UDim2.new(0,10,0,4)
    topLbl.BackgroundTransparency = 1; topLbl.Font = Enum.Font.GothamSemibold; topLbl.TextSize = 11
    topLbl.TextColor3 = THEME_TEXT; topLbl.TextXAlignment = Enum.TextXAlignment.Left
    topLbl.Text = labelText
    local cntLbl = Instance.new("TextLabel", container)
    cntLbl.Size = UDim2.new(0.4,-10,0,18); cntLbl.Position = UDim2.new(0.6,0,0,4)
    cntLbl.BackgroundTransparency = 1; cntLbl.Font = Enum.Font.GothamBold; cntLbl.TextSize = 11
    cntLbl.TextColor3 = Color3.fromRGB(120,160,255); cntLbl.TextXAlignment = Enum.TextXAlignment.Right
    cntLbl.Text = "0 / 0"
    local track = Instance.new("Frame", container)
    track.Size = UDim2.new(1,-16,0,8); track.Position = UDim2.new(0,8,0,26)
    track.BackgroundColor3 = Color3.fromRGB(30,30,42); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(0,0,1,0); fill.BackgroundColor3 = Color3.fromRGB(80,180,255); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local function setProgress(done, total)
        local pct = math.clamp(done / math.max(total,1), 0, 1)
        cntLbl.Text = done .. " / " .. total
        local green = Color3.fromRGB(60,200,110)
        local blue  = Color3.fromRGB(80,180,255)
        local col = pct >= 1 and green or Color3.fromRGB(
            math.floor(blue.R*255 + (green.R*255 - blue.R*255)*pct)/255,
            math.floor(blue.G*255 + (green.G*255 - blue.G*255)*pct)/255,
            math.floor(blue.B*255 + (green.B*255 - blue.B*255)*pct)/255
        )
        TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Size = UDim2.new(pct,0,1,0), BackgroundColor3 = col
        }):Play()
    end
    local function reset()
        fill.Size = UDim2.new(0,0,1,0); fill.BackgroundColor3 = Color3.fromRGB(80,180,255)
        cntLbl.Text = "0 / 0"; container.Visible = false
    end
    return container, setProgress, reset
end

local progStructures, setProgStructures, resetProgStructures = makeDupeProgress("Structures")
local progFurniture,  setProgFurniture,  resetProgFurniture  = makeDupeProgress("Furniture")
local progTrucks,     setProgTrucks,     resetProgTrucks     = makeDupeProgress("Truck Load")
local progItems,      setProgItems,      resetProgItems      = makeDupeProgress("Purchased Items")
local progGifs,       setProgGifs,       resetProgGifs       = makeDupeProgress("Gift Items")
local progWood,       setProgWood,       resetProgWood       = makeDupeProgress("Wood")

createDSep()

local function resetAllDupeProgress()
    resetProgStructures(); resetProgFurniture(); resetProgTrucks()
    resetProgItems(); resetProgGifs(); resetProgWood()
end

table.insert(cleanupTasks, function()
    if _G.VH and _G.VH.butter then
        _G.VH.butter.running = false
        if _G.VH.butter.thread then
            pcall(task.cancel, _G.VH.butter.thread)
            _G.VH.butter.thread = nil
        end
    end
    setDupeStatus("Stopped", false)
    resetAllDupeProgress()
end)

createDBtn("Start Dupe", Color3.fromRGB(35,90,45), function()
    if _G.VH.butter.running then setDupeStatus("Already running!", true) return end
    local giverName    = getGiverName()
    local receiverName = getReceiverName()
    if giverName == "" or receiverName == "" then setDupeStatus("Select both players!", false) return end

    _G.VH.butter.running = true
    setDupeStatus("Finding bases...", true)
    resetAllDupeProgress()

    _G.VH.butter.thread = task.spawn(function()
        local RS   = game:GetService("ReplicatedStorage")
        local LP   = Players.LocalPlayer
        local Char = LP.Character or LP.CharacterAdded:Wait()

        local GiveBaseOrigin, ReceiverBaseOrigin

        for _, v in pairs(workspace.Properties:GetDescendants()) do
            if v.Name == "Owner" then
                local val = tostring(v.Value)
                if val == giverName    then GiveBaseOrigin    = v.Parent:FindFirstChild("OriginSquare") end
                if val == receiverName then ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
            end
        end

        if not (GiveBaseOrigin and ReceiverBaseOrigin) then
            setDupeStatus("Couldn't find bases!", false); _G.VH.butter.running=false; return
        end

        local function isPointInside(point, boxCFrame, boxSize)
            local r = boxCFrame:PointToObjectSpace(point)
            return math.abs(r.X)<=boxSize.X/2 and math.abs(r.Y)<=boxSize.Y/2+2 and math.abs(r.Z)<=boxSize.Z/2
        end

        local function countItems(typeCheck)
            local n = 0
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name=="Owner" and tostring(v.Value)==giverName and typeCheck(v.Parent) then n+=1 end
            end
            return n
        end

        if getStructures() then
            local total = countItems(function(p)
                return p:FindFirstChild("Type") and tostring(p.Type.Value)=="Structure"
                    and (p:FindFirstChildOfClass("Part") or p:FindFirstChildOfClass("WedgePart"))
            end)
            if total > 0 then
                progStructures.Visible=true; setProgStructures(0,total)
                setDupeStatus("Sending structures...", true); local done=0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not _G.VH.butter.running then break end
                        if v.Name=="Owner" and tostring(v.Value)==giverName
                            and v.Parent:FindFirstChild("Type") and tostring(v.Parent.Type.Value)=="Structure"
                            and (v.Parent:FindFirstChildOfClass("Part") or v.Parent:FindFirstChildOfClass("WedgePart")) then
                            local PCF = (v.Parent:FindFirstChild("MainCFrame") and v.Parent.MainCFrame.Value)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local DA  = v.Parent:FindFirstChild("BlueprintWoodClass") and v.Parent.BlueprintWoodClass.Value or nil
                            local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local Off  = CFrame.new(nPos) * PCF.Rotation
                            repeat task.wait()
                                pcall(function() RS.PlaceStructure.ClientPlacedStructure:FireServer(v.Parent.ItemName.Value, Off, LP, DA, v.Parent, true) end)
                            until not v.Parent
                            done+=1; setProgStructures(done, total)
                        end
                    end
                end)
                setProgStructures(total, total)
            end
        end

        if getFurniture() and _G.VH.butter.running then
            local total = countItems(function(p)
                return p:FindFirstChild("Type") and tostring(p.Type.Value)=="Furniture" and p:FindFirstChildOfClass("Part")
            end)
            if total > 0 then
                progFurniture.Visible=true; setProgFurniture(0,total)
                setDupeStatus("Sending furniture...", true); local done=0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not _G.VH.butter.running then break end
                        if v.Name=="Owner" and tostring(v.Value)==giverName
                            and v.Parent:FindFirstChild("Type") and tostring(v.Parent.Type.Value)=="Furniture"
                            and v.Parent:FindFirstChildOfClass("Part") then
                            local PCF = (v.Parent:FindFirstChild("MainCFrame") and v.Parent.MainCFrame.Value)
                                or (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local DA  = v.Parent:FindFirstChild("BlueprintWoodClass") and v.Parent.BlueprintWoodClass.Value or nil
                            local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local Off  = CFrame.new(nPos) * PCF.Rotation
                            repeat task.wait()
                                pcall(function() RS.PlaceStructure.ClientPlacedStructure:FireServer(v.Parent.ItemName.Value, Off, LP, DA, v.Parent, true) end)
                            until not v.Parent
                            done+=1; setProgFurniture(done, total)
                        end
                    end
                end)
                setProgFurniture(total, total)
            end
        end

        local teleportedParts    = {}
        local ignoredParts       = {}
        local truckDestPositions = {}
        local ABOVE_TRUCK_Y = 2.70

        if getTrucks() and _G.VH.butter.running then
            local giverTrucks = {}
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName then
                    local model = v.Parent
                    if model and model:FindFirstChild("DriveSeat") then
                        table.insert(giverTrucks, model)
                    end
                end
            end

            local truckCount = #giverTrucks
            if truckCount > 0 then
                progTrucks.Visible = true; setProgTrucks(0, truckCount)
                setDupeStatus("Sending trucks...", true)
                local truckDone = 0

                for _, tModel in ipairs(giverTrucks) do
                    if not _G.VH.butter.running then break end
                    if not (tModel and tModel.Parent) then
                        truckDone += 1; setProgTrucks(truckDone, truckCount); continue
                    end

                    local driveSeat = tModel:FindFirstChild("DriveSeat")
                    if not driveSeat then
                        truckDone += 1; setProgTrucks(truckDone, truckCount); continue
                    end

                    for _, p in ipairs(tModel:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end
                    for _, p in ipairs(Char:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end

                    driveSeat:Sit(Char.Humanoid)
                    local sitTimeout = 0
                    repeat task.wait(0.05); sitTimeout += 0.05; driveSeat:Sit(Char.Humanoid)
                    until Char.Humanoid.SeatPart or sitTimeout > 5

                    if not Char.Humanoid.SeatPart then
                        truckDone += 1; setProgTrucks(truckDone, truckCount); continue
                    end

                    local mainPart     = tModel:FindFirstChild("Main")
                    local truckSrcCF   = mainPart and mainPart.CFrame or tModel:GetPrimaryPartCFrame()
                    local truckDestPos = truckSrcCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                    local truckDestCF  = CFrame.new(truckDestPos) * truckSrcCF.Rotation
                    table.insert(truckDestPositions, truckDestPos)

                    -- Sweep cargo BEFORE teleport (positions still valid)
                    local mCF, mSz = tModel:GetBoundingBox()
                    for _, part in ipairs(workspace:GetDescendants()) do
                        if part:IsA("BasePart") and not ignoredParts[part]
                            and (part.Name == "Main" or part.Name == "WoodSection") then
                            if part:FindFirstChild("Weld") and part.Weld.Part1
                                and part.Weld.Part1.Parent ~= part.Parent then continue end
                            task.spawn(function()
                                if isPointInside(part.Position, mCF, mSz) then
                                    local PCF  = part.CFrame
                                    local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                    local tOff = CFrame.new(nPos) * PCF.Rotation
                                    part.CFrame = tOff
                                    table.insert(teleportedParts, {Instance=part, OldPos=PCF.Position, TargetCFrame=tOff})
                                end
                            end)
                        end
                    end

                    -- *** WHEEL FIX: use safeTeleportTruck instead of SetPrimaryPartCFrame ***
                    safeTeleportTruck(tModel, truckDestCF)

                    local SitPart  = Char.Humanoid.SeatPart
                    local DoorHinge = SitPart and SitPart.Parent:FindFirstChild("PaintParts")
                        and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                        and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")

                    task.wait(0.5)
                    Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.1)
                    if SitPart then pcall(function() SitPart:Destroy() end) end
                    task.wait(0.1)
                    if DoorHinge then
                        for i = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end
                    end

                    truckDone += 1; setProgTrucks(truckDone, truckCount)
                end

                task.wait(1)
                local retryList = {}
                for _, data in ipairs(teleportedParts) do
                    if data.Instance and data.Instance.Parent
                        and (data.Instance.Position - data.OldPos).Magnitude < 5 then
                        ignoredParts[data.Instance] = nil
                        table.insert(retryList, data)
                    end
                end
                local cargoTotal = #teleportedParts
                local cargoDone  = cargoTotal - #retryList
                if cargoTotal > 0 then setProgTrucks(cargoDone, cargoTotal) end
                repeat
                    task.wait(1); retryList = {}
                    for _, data in ipairs(teleportedParts) do
                        if data.Instance and data.Instance.Parent
                            and (data.Instance.Position - data.OldPos).Magnitude < 25 then
                            table.insert(retryList, data)
                        end
                    end
                    if #retryList > 0 then
                        setDupeStatus("Retrying " .. #retryList .. " cargo...", true)
                        for _, data in ipairs(retryList) do
                            if not _G.VH.butter.running then break end
                            local item = data.Instance
                            while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 do
                                Char.HumanoidRootPart.CFrame = item.CFrame; task.wait(0.1)
                            end
                            RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                            task.wait(0.6)
                            item.CFrame = data.TargetCFrame
                            cargoDone = cargoTotal - #retryList
                            setProgTrucks(cargoDone, cargoTotal)
                        end
                    end
                until #retryList == 0 or not _G.VH.butter.running
                setProgTrucks(cargoTotal, cargoTotal)
            end

            if _G.VH.butter.running and Char:FindFirstChild("HumanoidRootPart") then
                setDupeStatus("Returning to giver slot...", true)
                Char.HumanoidRootPart.CFrame = CFrame.new(GiveBaseOrigin.Position + Vector3.new(0, 5, 0))
                task.wait(0.5)
            end
        end

        local function getAboveTruckCFrame(srcPCF)
            local basePos = (#truckDestPositions > 0)
                and truckDestPositions[1]
                or  (ReceiverBaseOrigin.Position)
            return CFrame.new(basePos.X, basePos.Y + ABOVE_TRUCK_Y, basePos.Z) * srcPCF.Rotation
        end

        local function seekNetOwn(part)
            if not _G.VH.butter.running then return end
            if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.1)
            end
            for i = 1, 50 do task.wait(0.05); RS.Interaction.ClientIsDragging:FireServer(part.Parent) end
        end

        local function sendItem(part, Offset)
            if not _G.VH.butter.running then return end
            if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.1)
            end
            seekNetOwn(part)
            for i = 1, 200 do part.CFrame = Offset end
            task.wait(0.5)
        end

        if getDupeItems() and _G.VH.butter.running then
            local total = countItems(function(p)
                return p:FindFirstChild("PurchasedBoxItemName") and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progItems.Visible = true; setProgItems(0, total)
                setDupeStatus("Sending purchased items (above truck)...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not _G.VH.butter.running then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName
                            and v.Parent:FindFirstChild("PurchasedBoxItemName") then
                            local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                            if not part then continue end
                            local PCF = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            sendItem(part, getAboveTruckCFrame(PCF))
                            done += 1; setProgItems(done, total)
                        end
                    end
                end)
                setProgItems(total, total)
            end
        end

        if getGifs() and _G.VH.butter.running then
            local total = countItems(function(p)
                return p:FindFirstChildOfClass("Script") and p:FindFirstChild("DraggableItem")
                    and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progGifs.Visible = true; setProgGifs(0, total)
                setDupeStatus("Sending gift items (above truck)...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not _G.VH.butter.running then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName
                            and v.Parent:FindFirstChildOfClass("Script") and v.Parent:FindFirstChild("DraggableItem") then
                            local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                            if not part then continue end
                            local PCF = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            sendItem(part, getAboveTruckCFrame(PCF))
                            done += 1; setProgGifs(done, total)
                        end
                    end
                end)
                setProgGifs(total, total)
            end
        end

        if getWood() and _G.VH.butter.running then
            local total = countItems(function(p)
                return p:FindFirstChild("TreeClass") and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progWood.Visible=true; setProgWood(0,total)
                setDupeStatus("Sending wood...", true)
                local done  = 0
                local RS2   = game:GetService("ReplicatedStorage")
                local dragger2 = RS2:FindFirstChild("Interaction") and RS2.Interaction:FindFirstChild("ClientIsDragging")

                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not _G.VH.butter.running then break end
                        if not (v.Name=="Owner" and tostring(v.Value)==giverName and v.Parent:FindFirstChild("TreeClass")) then continue end

                        local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                        if not part then continue end

                        local PCF  = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame) or v.Parent:FindFirstChildOfClass("Part").CFrame
                        local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                        local targetCF = CFrame.new(nPos) * PCF.Rotation
                        local model = v.Parent

                        if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 20 then
                            Char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 3, 3)
                            task.wait(0.08)
                        end

                        local startT = tick()
                        local TIMEOUT = 2.0
                        local CONFIRM = 5

                        local conn
                        local done2 = false
                        conn = RunService.Heartbeat:Connect(function()
                            if not (part and part.Parent) then
                                conn:Disconnect(); done2 = true; return
                            end
                            if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 20 then
                                Char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 3, 3)
                            end
                            pcall(function()
                                for _, p in ipairs(Char:GetDescendants()) do
                                    if p:IsA("BasePart") then p.CanCollide = false end
                                end
                            end)
                            if dragger2 then pcall(function() dragger2:FireServer(model) end) end
                            pcall(function() part.CFrame = targetCF end)
                            local dist = (part.Position - targetCF.Position).Magnitude
                            if dist < CONFIRM or (tick() - startT) >= TIMEOUT then
                                conn:Disconnect(); done2 = true
                            end
                        end)

                        local waitStart = tick()
                        while not done2 and (tick() - waitStart) < 2.5 do task.wait() end
                        if conn then pcall(function() conn:Disconnect() end) end

                        pcall(function()
                            for _, p in ipairs(Char:GetDescendants()) do
                                if p:IsA("BasePart") then p.CanCollide = true end
                            end
                        end)

                        done += 1; setProgWood(done, total)
                        task.wait(0.6)
                    end
                end)
                setProgWood(total, total)
            end
        end

        if _G.VH.butter.running then setDupeStatus("Done!", false) end
        _G.VH.butter.running = false; _G.VH.butter.thread = nil
    end)
end)

createDBtn("Cancel Dupe", BTN_COLOR, function()
    _G.VH.butter.running = false
    if _G.VH.butter.thread then pcall(task.cancel, _G.VH.butter.thread) end
    _G.VH.butter.thread = nil
    setDupeStatus("Stopped", false)
    resetAllDupeProgress()
end)

-- ════════════════════════════════════════════════════
-- SINGLE TRUCK LOAD DUPE
-- NEW vs original:
--   - Sit in truck → click "Select Truck" → jump out → repeat
--   - X / Y / Z grid sliders
--   - Generate Preview box (follows mouse, right-click to place)
--   - Start → teleports each selected truck to its grid slot
--     using safeTeleportTruck so wheels never detach
-- ════════════════════════════════════════════════════
createDSep()
createDSection("Single Truck Load Dupe")

-- Hint
local stHint = Instance.new("TextLabel", dupePage)
stHint.Size = UDim2.new(1,-12,0,30); stHint.BackgroundColor3 = Color3.fromRGB(16,16,22)
stHint.BorderSizePixel = 0; stHint.Font = Enum.Font.Gotham; stHint.TextSize = 11
stHint.TextColor3 = Color3.fromRGB(100,100,130); stHint.TextWrapped = true
stHint.TextXAlignment = Enum.TextXAlignment.Left
stHint.Text = "  1. Sit in truck  2. Select Truck  3. Jump out  4. Repeat  5. Preview + Start"
Instance.new("UICorner", stHint).CornerRadius = UDim.new(0,6)
Instance.new("UIPadding",  stHint).PaddingLeft = UDim.new(0,6)

-- Status card
local stCard = Instance.new("Frame", dupePage)
stCard.Size = UDim2.new(1,-12,0,36); stCard.BackgroundColor3 = Color3.fromRGB(18,14,26)
stCard.BorderSizePixel = 0
Instance.new("UICorner", stCard).CornerRadius = UDim.new(0,8)
local stCardStroke = Instance.new("UIStroke", stCard)
stCardStroke.Color = Color3.fromRGB(255,180,0); stCardStroke.Thickness = 1; stCardStroke.Transparency = 0.55
local stDot = Instance.new("Frame", stCard)
stDot.Size = UDim2.new(0,7,0,7); stDot.Position = UDim2.new(0,10,0.5,-3)
stDot.BackgroundColor3 = Color3.fromRGB(80,80,100); stDot.BorderSizePixel = 0
Instance.new("UICorner", stDot).CornerRadius = UDim.new(1,0)
local stLbl = Instance.new("TextLabel", stCard)
stLbl.Size = UDim2.new(1,-28,1,0); stLbl.Position = UDim2.new(0,24,0,0)
stLbl.BackgroundTransparency = 1; stLbl.Font = Enum.Font.GothamSemibold; stLbl.TextSize = 12
stLbl.TextColor3 = Color3.fromRGB(255,210,100); stLbl.TextXAlignment = Enum.TextXAlignment.Left
stLbl.Text = "Sit in a truck then click Select Truck"

local function setSTStatus(msg, active)
    stLbl.Text = msg
    stDot.BackgroundColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
end

-- State
local stSelectedTrucks  = {}
local stHighlights      = {}
local stGridCols        = 2
local stGridLayers      = 1
local stGridRows        = 1
local stGap             = 1.0
local stPrevPart        = nil
local stPrevFollowing   = false
local stPrevPlaced      = false
local stFollowConn      = nil
local stRunning         = false
local stAbort           = false

local camera2 = workspace.CurrentCamera
local mouse2  = player:GetMouse()

local PREVIEW_COL = Color3.fromRGB(80,160,255)
local PLACED_COL  = Color3.fromRGB(60,210,100)

local function stHlTruck(model, on)
    if on then
        if stHighlights[model] then return end
        local hl = Instance.new("SelectionBox")
        hl.Color3 = Color3.fromRGB(80,200,255); hl.LineThickness = 0.08
        hl.SurfaceTransparency = 0.75; hl.SurfaceColor3 = Color3.fromRGB(80,200,255)
        hl.Adornee = model; hl.Parent = model; stHighlights[model] = hl
    else
        if stHighlights[model] then stHighlights[model]:Destroy(); stHighlights[model]=nil end
    end
end

local function stClearTrucks()
    for _, m in ipairs(stSelectedTrucks) do stHlTruck(m,false) end
    stSelectedTrucks={}; stHighlights={}
end

local function stDestroyPreview()
    if stFollowConn then stFollowConn:Disconnect(); stFollowConn=nil end
    if stPrevPart and stPrevPart.Parent then stPrevPart:Destroy() end
    stPrevPart=nil; stPrevFollowing=false; stPrevPlaced=false
end

local function stGetMouseHitCF(halfH)
    local unitRay = camera2:ScreenPointToRay(mouse2.X, mouse2.Y)
    local params  = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    if stPrevPart then table.insert(excl, stPrevPart) end
    if player.Character then table.insert(excl, player.Character) end
    params.FilterDescendantsInstances = excl
    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 800, params)
    local hitPos
    if result then hitPos = result.Position
    else
        local t = unitRay.Origin.Y / -unitRay.Direction.Y
        hitPos = unitRay.Origin + unitRay.Direction * (t > 0 and t or 40)
    end
    return CFrame.new(hitPos.X, hitPos.Y + halfH, hitPos.Z)
end

local function stGetTruckSize(model)
    local ok, _, sz = pcall(function() return model:GetBoundingBox() end)
    return ok and sz or Vector3.new(6,3,12)
end

local function stComputePreviewSize()
    local maxW,maxH,maxD = 0,0,0
    for _, m in ipairs(stSelectedTrucks) do
        local s = stGetTruckSize(m)
        if s.X>maxW then maxW=s.X end
        if s.Y>maxH then maxH=s.Y end
        if s.Z>maxD then maxD=s.Z end
    end
    if maxW==0 then maxW=6; maxH=3; maxD=12 end
    local cols=math.max(1,stGridCols); local layers=math.max(1,stGridLayers); local rows=math.max(1,stGridRows)
    return (cols*(maxW+stGap)-stGap), (layers*(maxH+stGap)-stGap), (rows*(maxD+stGap)-stGap)
end

-- INT SLIDER helper (local to dupe page)
local AXIS_COL = {X=Color3.fromRGB(220,70,70),Y=Color3.fromRGB(70,200,70),Z=Color3.fromRGB(70,120,255)}
local function mkSTSlider(labelTxt, axis, minV, maxV, defV, cb)
    local axCol = AXIS_COL[axis] or THEME_TEXT
    local fr = Instance.new("Frame", dupePage)
    fr.Size = UDim2.new(1,-12,0,54); fr.BackgroundColor3 = Color3.fromRGB(22,22,30); fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0,6)
    local axT = Instance.new("TextLabel", fr)
    axT.Size=UDim2.new(0,18,0,22); axT.Position=UDim2.new(0,8,0,5)
    axT.BackgroundTransparency=1; axT.Font=Enum.Font.GothamBold
    axT.TextSize=14; axT.TextColor3=axCol; axT.Text=axis
    local topL = Instance.new("TextLabel", fr)
    topL.Size=UDim2.new(0.6,0,0,22); topL.Position=UDim2.new(0,28,0,5)
    topL.BackgroundTransparency=1; topL.Font=Enum.Font.GothamSemibold
    topL.TextSize=12; topL.TextColor3=THEME_TEXT
    topL.TextXAlignment=Enum.TextXAlignment.Left; topL.Text=labelTxt
    local valL = Instance.new("TextLabel", fr)
    valL.Size=UDim2.new(0.25,0,0,22); valL.Position=UDim2.new(0.75,0,0,5)
    valL.BackgroundTransparency=1; valL.Font=Enum.Font.GothamBold
    valL.TextSize=13; valL.TextColor3=axCol
    valL.TextXAlignment=Enum.TextXAlignment.Right; valL.Text=tostring(defV)
    local track = Instance.new("Frame", fr)
    track.Size=UDim2.new(1,-16,0,6); track.Position=UDim2.new(0,8,0,36)
    track.BackgroundColor3=Color3.fromRGB(38,38,52); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size=UDim2.new((defV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=axCol; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob = Instance.new("TextButton", track)
    knob.Size=UDim2.new(0,18,0,18); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(225,225,245); knob.Text=""; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local drag=false; local cur=defV
    local function apply(sx)
        local r=math.clamp((sx-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
        local v=math.round(minV+r*(maxV-minV)); if v==cur then return end; cur=v
        fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,0,0.5,0); valL.Text=tostring(v)
        if cb then cb(v) end
    end
    knob.MouseButton1Down:Connect(function() drag=true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; apply(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then apply(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- SELECT BUTTON
createDBtn("Select Truck  (sit in it first)", Color3.fromRGB(40,55,90), function()
    local char = player.Character; if not char then setSTStatus("No character!",false); return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if not seat then setSTStatus("Not sitting in any vehicle!",false); return end
    local model = seat:FindFirstAncestorOfClass("Model") or seat.Parent
    if not (model and model:IsA("Model")) then setSTStatus("Can't find truck model.",false); return end
    for _, m in ipairs(stSelectedTrucks) do
        if m==model then setSTStatus("Already selected!",false); return end
    end
    table.insert(stSelectedTrucks, model); stHlTruck(model,true)
    setSTStatus(#stSelectedTrucks.." truck(s) selected — jump out and repeat, or Generate Preview.", true)
end)

createDBtn("Remove Last Truck", BTN_COLOR, function()
    if #stSelectedTrucks==0 then return end
    local m=table.remove(stSelectedTrucks); stHlTruck(m,false); stHighlights[m]=nil
    setSTStatus(#stSelectedTrucks.." selected.", false)
end)

createDBtn("Clear All Trucks", Color3.fromRGB(70,20,20), function()
    stClearTrucks(); setSTStatus("Cleared.",false)
end)

-- GRID SLIDERS
mkSTSlider("Width  (trucks per row)",  "X", 1, 10, 2, function(v) stGridCols=v end)
mkSTSlider("Height  (layers)",          "Y", 1, 5,  1, function(v) stGridLayers=v end)
mkSTSlider("Depth   (rows)",            "Z", 1, 10, 1, function(v) stGridRows=v end)
mkSTSlider("Gap between trucks (x0.5)","X", 1, 20, 2, function(v) stGap=v*0.5 end)

-- PREVIEW
createDBtn("Generate Preview  (follows mouse)", Color3.fromRGB(35,55,100), function()
    if #stSelectedTrucks==0 then setSTStatus("No trucks selected!",false); return end
    stDestroyPreview()
    local sX,sY,sZ = stComputePreviewSize()
    local p = Instance.new("Part")
    p.Name="STPreview"; p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CastShadow=false
    p.Size=Vector3.new(math.max(sX,0.5),math.max(sY,0.5),math.max(sZ,0.5))
    p.Color=PREVIEW_COL; p.Material=Enum.Material.SmoothPlastic; p.Transparency=0.52; p.Parent=workspace
    local sb=Instance.new("SelectionBox",p)
    sb.Color3=PREVIEW_COL; sb.LineThickness=0.07; sb.SurfaceTransparency=1; sb.Adornee=p
    stPrevPart=p; stPrevFollowing=true; stPrevPlaced=false
    if stFollowConn then stFollowConn:Disconnect() end
    stFollowConn = RunService.RenderStepped:Connect(function()
        if not stPrevFollowing then return end
        if not (stPrevPart and stPrevPart.Parent) then
            stFollowConn:Disconnect(); stFollowConn=nil; return end
        local halfH = stPrevPart.Size.Y/2
        stPrevPart.CFrame = stPrevPart.CFrame:Lerp(stGetMouseHitCF(halfH), 0.22)
    end)
    setSTStatus("Preview following mouse — right-click to place.", true)
end)

-- RIGHT-CLICK to place preview
local stRClick = mouse2.Button2Down:Connect(function()
    if stPrevFollowing and stPrevPart and stPrevPart.Parent then
        stPrevFollowing=false
        if stFollowConn then stFollowConn:Disconnect(); stFollowConn=nil end
        local halfH=stPrevPart.Size.Y/2
        stPrevPart.CFrame=stGetMouseHitCF(halfH)
        stPrevPart.Color=PLACED_COL
        local sb=stPrevPart:FindFirstChildOfClass("SelectionBox")
        if sb then sb.Color3=PLACED_COL end
        stPrevPlaced=true
        setSTStatus(#stSelectedTrucks.." truck(s) ready — hit Start!", true)
    end
end)

createDBtn("Clear Preview", BTN_COLOR, function()
    stDestroyPreview(); setSTStatus("Preview cleared.",false)
end)

-- PROGRESS BAR
local stPbCont=Instance.new("Frame",dupePage)
stPbCont.Size=UDim2.new(1,-12,0,44); stPbCont.BackgroundColor3=Color3.fromRGB(18,18,24)
stPbCont.BorderSizePixel=0; stPbCont.Visible=false
Instance.new("UICorner",stPbCont).CornerRadius=UDim.new(0,8)
local stPbLbl=Instance.new("TextLabel",stPbCont)
stPbLbl.Size=UDim2.new(1,-12,0,16); stPbLbl.Position=UDim2.new(0,6,0,4)
stPbLbl.BackgroundTransparency=1; stPbLbl.Font=Enum.Font.GothamSemibold; stPbLbl.TextSize=11
stPbLbl.TextColor3=THEME_TEXT; stPbLbl.TextXAlignment=Enum.TextXAlignment.Left; stPbLbl.Text=""
local stPbTrack=Instance.new("Frame",stPbCont)
stPbTrack.Size=UDim2.new(1,-12,0,12); stPbTrack.Position=UDim2.new(0,6,0,26)
stPbTrack.BackgroundColor3=Color3.fromRGB(30,30,42); stPbTrack.BorderSizePixel=0
Instance.new("UICorner",stPbTrack).CornerRadius=UDim.new(1,0)
local stPbFill=Instance.new("Frame",stPbTrack)
stPbFill.Size=UDim2.new(0,0,1,0); stPbFill.BackgroundColor3=Color3.fromRGB(80,160,255)
stPbFill.BorderSizePixel=0; Instance.new("UICorner",stPbFill).CornerRadius=UDim.new(1,0)

-- START BUTTON
createDBtn("Start Teleporting Trucks", Color3.fromRGB(35,100,50), function()
    if stRunning then setSTStatus("Already running!",true); return end
    if not (stPrevPlaced and stPrevPart and stPrevPart.Parent) then
        setSTStatus("Generate a preview and right-click to place it first!",false); return end
    if #stSelectedTrucks==0 then setSTStatus("No trucks selected!",false); return end

    stRunning=true; stAbort=false
    stPbCont.Visible=true
    stPbFill.Size=UDim2.new(0,0,1,0); stPbFill.BackgroundColor3=Color3.fromRGB(80,160,255)
    stPbLbl.Text="Teleporting... 0 / "..#stSelectedTrucks

    -- Anchor CF is the back-left-bottom corner of the preview box
    local anchorCF = stPrevPart.CFrame
        * CFrame.new(-stPrevPart.Size.X/2, -stPrevPart.Size.Y/2, -stPrevPart.Size.Z/2)

    -- Compute uniform cell size from all trucks
    local maxW,maxH,maxD=0,0,0
    for _,m in ipairs(stSelectedTrucks) do
        local s=stGetTruckSize(m)
        if s.X>maxW then maxW=s.X end; if s.Y>maxH then maxH=s.Y end; if s.Z>maxD then maxD=s.Z end
    end
    local cellW=maxW+stGap; local cellH=maxH+stGap; local cellD=maxD+stGap
    local cols=math.max(1,stGridCols); local rows=math.max(1,stGridRows)

    task.spawn(function()
        for i, model in ipairs(stSelectedTrucks) do
            if stAbort then break end
            if model and model.Parent then
                local idx=i-1
                local layer=math.floor(idx/(cols*rows))
                local rem=idx%(cols*rows)
                local row=math.floor(rem/cols)
                local col=rem%cols
                local s=stGetTruckSize(model)
                local targetCF=anchorCF * CFrame.new(col*cellW+s.X/2, layer*cellH+s.Y/2, row*cellD+s.Z/2)

                -- *** WHEEL FIX ***
                safeTeleportTruck(model, targetCF)

                local pct=i/#stSelectedTrucks
                TweenService:Create(stPbFill,TweenInfo.new(0.15),{Size=UDim2.new(pct,0,1,0)}):Play()
                stPbLbl.Text="Teleporting... "..i.." / "..#stSelectedTrucks
                task.wait(0.15)  -- stagger to avoid server lag
            end
        end
        stRunning=false
        if not stAbort then
            TweenService:Create(stPbFill,TweenInfo.new(0.25),
                {Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(90,220,110)}):Play()
            stPbLbl.Text="All trucks placed!"
            stDestroyPreview()
            task.delay(2.5, function() stPbCont.Visible=false end)
            setSTStatus("Done! All trucks placed.", false)
        else
            stPbLbl.Text="Stopped."; setSTStatus("Stopped.",false)
        end
    end)
end)

createDBtn("Stop Teleport", Color3.fromRGB(100,40,20), function()
    stAbort=true; stRunning=false; setSTStatus("Stopped.",false)
end)

-- Cleanup for single truck dupe
table.insert(cleanupTasks, function()
    stAbort=true; stRunning=false
    if stFollowConn then stFollowConn:Disconnect(); stFollowConn=nil end
    stRClick:Disconnect()
    stDestroyPreview(); stClearTrucks()
end)

-- ════════════════════════════════════════════════════
-- ORIGINAL Single Truck Teleport  (giver→receiver, wheel fixed)
-- ════════════════════════════════════════════════════
createDSep()
createDSection("Single Truck Teleport  (giver to receiver base)")

local _, getSingleGiver    = makeDupeDropdown("Giver",    dupePage)
local _, getSingleReceiver = makeDupeDropdown("Receiver", dupePage)

local stFrame2 = Instance.new("Frame", dupePage)
stFrame2.Size = UDim2.new(1,-12,0,28); stFrame2.BackgroundColor3 = Color3.fromRGB(14,14,18)
stFrame2.BorderSizePixel = 0
Instance.new("UICorner", stFrame2).CornerRadius = UDim.new(0,6)
local stDot2 = Instance.new("Frame", stFrame2)
stDot2.Size = UDim2.new(0,7,0,7); stDot2.Position = UDim2.new(0,10,0.5,-3)
stDot2.BackgroundColor3 = Color3.fromRGB(80,80,100); stDot2.BorderSizePixel = 0
Instance.new("UICorner", stDot2).CornerRadius = UDim.new(1,0)
local stLbl2 = Instance.new("TextLabel", stFrame2)
stLbl2.Size = UDim2.new(1,-28,1,0); stLbl2.Position = UDim2.new(0,24,0,0)
stLbl2.BackgroundTransparency = 1; stLbl2.Font = Enum.Font.Gotham; stLbl2.TextSize = 12
stLbl2.TextColor3 = THEME_TEXT; stLbl2.TextXAlignment = Enum.TextXAlignment.Left
stLbl2.Text = "Select Giver & Receiver, then press Teleport"

local function setSTStatus2(msg, active)
    stLbl2.Text = msg
    stDot2.BackgroundColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
end

createDBtn("Teleport My Truck", Color3.fromRGB(60,40,100), function()
    local giverName    = getSingleGiver()
    local receiverName = getSingleReceiver()
    if giverName == "" then setSTStatus2("Select a giver first!",false); return end
    if receiverName == "" then setSTStatus2("Select a receiver first!",false); return end

    local RS2  = game:GetService("ReplicatedStorage")
    local LP   = Players.LocalPlayer
    local Char = LP.Character or LP.CharacterAdded:Wait()
    local hum  = Char:FindFirstChild("Humanoid")

    local seatPart = hum and hum.SeatPart
    if not seatPart or seatPart.Name ~= "DriveSeat" then
        setSTStatus2("You must be sitting in a truck!",false); return end

    local tModel = seatPart.Parent
    if not tModel then setSTStatus2("Couldn't find truck model!",false); return end

    local GiveBaseOrigin, ReceiverBaseOrigin
    for _, v in pairs(workspace.Properties:GetDescendants()) do
        if v.Name == "Owner" then
            local val = tostring(v.Value)
            if val == giverName    then GiveBaseOrigin    = v.Parent:FindFirstChild("OriginSquare") end
            if val == receiverName then ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
        end
    end
    if not GiveBaseOrigin    then setSTStatus2("Couldn't find giver's base!",false);    return end
    if not ReceiverBaseOrigin then setSTStatus2("Couldn't find receiver's base!",false); return end

    setSTStatus2("Teleporting truck...", true)

    task.spawn(function()
        local ignoredParts    = {}
        local teleportedParts = {}

        for _, p in ipairs(tModel:GetDescendants()) do
            if p:IsA("BasePart") then ignoredParts[p] = true end
        end
        for _, p in ipairs(Char:GetDescendants()) do
            if p:IsA("BasePart") then ignoredParts[p] = true end
        end

        local mainPart     = tModel:FindFirstChild("Main")
        local truckSrcCF   = mainPart and mainPart.CFrame or tModel:GetPrimaryPartCFrame()
        local truckDestPos = truckSrcCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
        local truckDestCF  = CFrame.new(truckDestPos) * truckSrcCF.Rotation

        local function isPointInside(point, boxCF, boxSz)
            local r = boxCF:PointToObjectSpace(point)
            return math.abs(r.X)<=boxSz.X/2 and math.abs(r.Y)<=boxSz.Y/2+2 and math.abs(r.Z)<=boxSz.Z/2
        end

        local mCF, mSz = tModel:GetBoundingBox()
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not ignoredParts[part]
                and (part.Name == "Main" or part.Name == "WoodSection") then
                if part:FindFirstChild("Weld") and part.Weld.Part1
                    and part.Weld.Part1.Parent ~= part.Parent then continue end
                task.spawn(function()
                    if isPointInside(part.Position, mCF, mSz) then
                        local PCF  = part.CFrame
                        local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                        local tOff = CFrame.new(nPos) * PCF.Rotation
                        part.CFrame = tOff
                        table.insert(teleportedParts, {Instance=part, OldPos=PCF.Position, TargetCFrame=tOff})
                    end
                end)
            end
        end

        -- *** WHEEL FIX ***
        safeTeleportTruck(tModel, truckDestCF)

        local DoorHinge = seatPart.Parent:FindFirstChild("PaintParts")
            and seatPart.Parent.PaintParts:FindFirstChild("DoorLeft")
            and seatPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")

        task.wait(0.5)
        Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.1); pcall(function() seatPart:Destroy() end); task.wait(0.1)
        if DoorHinge then
            for i = 1, 10 do RS2.Interaction.RemoteProxy:FireServer(DoorHinge) end
        end

        task.wait(0.3)
        pcall(function()
            Char.HumanoidRootPart.CFrame = CFrame.new(GiveBaseOrigin.Position + Vector3.new(0, 5, 0))
        end)

        if #teleportedParts == 0 then
            setSTStatus2("Truck teleported!", false); return
        end

        task.wait(1)
        local retryList = {}
        for _, data in ipairs(teleportedParts) do
            if data.Instance and data.Instance.Parent
                and (data.Instance.Position - data.OldPos).Magnitude < 5 then
                table.insert(retryList, data)
            end
        end

        local attempts = 0
        while #retryList > 0 and attempts < 4 do
            attempts += 1
            setSTStatus2("Retrying " .. #retryList .. " cargo...", true)
            for _, data in ipairs(retryList) do
                local item = data.Instance
                if not (item and item.Parent) then continue end
                while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 do
                    Char.HumanoidRootPart.CFrame = item.CFrame; task.wait(0.1)
                end
                RS2.Interaction.ClientIsDragging:FireServer(item.Parent)
                task.wait(0.6)
                item.CFrame = data.TargetCFrame
            end
            task.wait(1)
            retryList = {}
            for _, data in ipairs(teleportedParts) do
                if data.Instance and data.Instance.Parent
                    and (data.Instance.Position - data.OldPos).Magnitude < 25 then
                    table.insert(retryList, data)
                end
            end
        end

        setSTStatus2("Truck teleported!", false)
    end)
end)

print("[VanillaHub] Vanilla2 (FIXED) loaded")
