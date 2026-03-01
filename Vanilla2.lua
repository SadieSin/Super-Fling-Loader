-- ════════════════════════════════════════════════════
-- VANILLA2 — World Tab + Dupe Tab
-- Imports shared state from Vanilla1 via _G.VH
-- ════════════════════════════════════════════════════

-- Guard: if _G.VH is missing, Vanilla1 wasn't executed first (or was already cleaned up)
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

-- ════════════════════════════════════════════════════
-- WORLD TAB
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

local BTN_COLOR_W = Color3.fromRGB(45, 45, 50)

local function createWorldToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", worldPage)
    frame.Size = UDim2.new(1,-12,0,32); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0,34,0,18); tb.Position = UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3 = defaultState and Color3.fromRGB(60,180,60) or BTN_COLOR_W
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
            BackgroundColor3 = toggled and Color3.fromRGB(60,180,60) or BTN_COLOR_W
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 18 or 2, 0.5, -7)
        }):Play()
        if callback then callback(toggled) end
    end)
    return frame
end

local worldClockConn = nil
local alwaysDayActive = false
local alwaysNightActive = false
local walkOnWaterConn = nil
local walkOnWaterParts = {}

-- Register world-specific cleanup with the shared task list
table.insert(cleanupTasks, function()
    if worldClockConn then worldClockConn:Disconnect(); worldClockConn = nil end
    if walkOnWaterConn then walkOnWaterConn:Disconnect(); walkOnWaterConn = nil end
    for _, p in ipairs(walkOnWaterParts) do
        if p and p.Parent then p:Destroy() end
    end
    walkOnWaterParts = {}
    alwaysDayActive = false
    alwaysNightActive = false
end)

createWSectionLabel("Environment")

createWorldToggle("Always Day", false, function(v)
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
    for _, p in ipairs(walkOnWaterParts) do
        if p and p.Parent then p:Destroy() end
    end
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
    for _, p in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if p:IsA("Part") and p.Name == "Water" then
            p.Transparency = v and 1 or 0.5
            p.CanCollide = false
        end
    end
end)

-- ════════════════════════════════════════════════════
-- DUPE TAB  (Butter Leak system)
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
    btn.TextColor3 = Color3.fromRGB(210,210,220); btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local hov = Color3.fromRGB(math.min(color.R*255+20,255)/255, math.min(color.G*255+8,255)/255, math.min(color.B*255+20,255)/255)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=hov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=color}):Play() end)
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
    lbl.TextSize = 13; lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.TextXAlignment = Enum.TextXAlignment.Left
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

local function makeDupeDropdown(labelText)
    local selected  = ""
    local isOpen    = false
    local ITEM_H    = 34
    local MAX_SHOW  = 5
    local HEADER_H  = 40

    local outer = Instance.new("Frame", dupePage)
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
    lbl.TextColor3         = Color3.fromRGB(140,140,170)
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
        selLbl.Text      = name
        selLbl.TextColor3 = Color3.fromRGB(220,225,255)
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
            if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
        end
        local playerList = Players:GetPlayers()
        table.sort(playerList, function(a,b) return a.Name < b.Name end)
        for i, plr in ipairs(playerList) do
            local isSelected = (plr.Name == selected)
            local row = Instance.new("Frame", listScroll)
            row.Size             = UDim2.new(1,0,0,ITEM_H)
            row.BackgroundColor3 = isSelected and Color3.fromRGB(45,45,75) or Color3.fromRGB(28,28,40)
            row.BorderSizePixel  = 0
            row.LayoutOrder      = i
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
            local miniAvatar = Instance.new("ImageLabel", row)
            miniAvatar.Size             = UDim2.new(0,22,0,22)
            miniAvatar.Position         = UDim2.new(0,8,0.5,-11)
            miniAvatar.BackgroundColor3 = Color3.fromRGB(40,40,58)
            miniAvatar.BorderSizePixel  = 0
            miniAvatar.ScaleType        = Enum.ScaleType.Crop
            Instance.new("UICorner", miniAvatar).CornerRadius = UDim.new(1,0)
            task.spawn(function()
                pcall(function()
                    miniAvatar.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
            end)
            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size               = UDim2.new(1,-70,1,0)
            nameLbl.Position           = UDim2.new(0,36,0,0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text               = plr.Name
            nameLbl.Font               = Enum.Font.GothamSemibold
            nameLbl.TextSize           = 13
            nameLbl.TextColor3         = isSelected and Color3.fromRGB(210,215,255) or Color3.fromRGB(200,200,215)
            nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
            nameLbl.TextTruncate       = Enum.TextTruncate.AtEnd
            if isSelected then
                local check = Instance.new("TextLabel", row)
                check.Size               = UDim2.new(0,24,1,0)
                check.Position           = UDim2.new(1,-28,0,0)
                check.BackgroundTransparency = 1
                check.Text               = "✓"
                check.Font               = Enum.Font.GothamBold
                check.TextSize           = 14
                check.TextColor3         = Color3.fromRGB(120,180,255)
                check.TextXAlignment     = Enum.TextXAlignment.Center
            end
            local rowBtn = Instance.new("TextButton", row)
            rowBtn.Size               = UDim2.new(1,0,1,0)
            rowBtn.BackgroundTransparency = 1
            rowBtn.Text               = ""
            rowBtn.ZIndex             = 5
            rowBtn.MouseEnter:Connect(function()
                if plr.Name ~= selected then
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(38,38,58)}):Play()
                end
            end)
            rowBtn.MouseLeave:Connect(function()
                if plr.Name ~= selected then
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28,28,40)}):Play()
                end
            end)
            rowBtn.MouseButton1Click:Connect(function()
                if plr.Name == selected then clearSelected() else setSelected(plr.Name, plr.UserId) end
                buildList()
                task.delay(0.05, function()
                    isOpen = false
                    TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
                    TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H)}):Play()
                    TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
                    divider.Visible = false
                end)
            end)
        end
    end

    local function openList()
        isOpen = true
        buildList()
        local count    = #Players:GetPlayers()
        local listH    = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
        local totalH   = HEADER_H + 2 + listH
        divider.Visible = true
        TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
        TweenService:Create(outer, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,totalH)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,listH)}):Play()
    end

    local function closeList()
        isOpen = false
        TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
        TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end

    headerBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    headerBtn.MouseEnter:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(38,38,55)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30,30,42)}):Play()
    end)

    Players.PlayerAdded:Connect(function()
        if isOpen then
            buildList()
            local count  = #Players:GetPlayers()
            local listH  = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
            outer.Size      = UDim2.new(1,-12,0,HEADER_H + 2 + listH)
            listScroll.Size = UDim2.new(1,0,0,listH)
        end
    end)

    Players.PlayerRemoving:Connect(function(leaving)
        if leaving.Name == selected then clearSelected() end
        if isOpen then
            buildList()
            local count  = #Players:GetPlayers()
            local listH  = math.min(math.max(count-1,0), MAX_SHOW) * (ITEM_H + 3) + 8
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
dupeStatusLbl.TextColor3 = Color3.fromRGB(150,150,170); dupeStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
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
    topLbl.TextColor3 = Color3.fromRGB(180,180,220); topLbl.TextXAlignment = Enum.TextXAlignment.Left
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

-- Register dupe cancellation in the shared cleanup list
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

        -- ══════════════════════════════════════════
        -- TRUCK SECTION
        -- Key fixes:
        --   1. Snapshot the truck model BEFORE sitting (owner changes on sit)
        --   2. Teleport the truck explicitly even if it has no cargo (empty trucks)
        --   3. After all trucks done, warp back to giver plot for leftover slot items
        --   4. Gifts/items land 2.70 studs above the receiver-side truck
        -- ══════════════════════════════════════════
        local teleportedParts  = {}
        local ignoredParts     = {}
        local truckDestPositions = {}  -- receiver-side truck positions, for item placement

        local ABOVE_TRUCK_Y = 2.70

        if getTrucks() and _G.VH.butter.running then

            -- ── Snapshot all giver trucks BEFORE any sitting changes Owner ──
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
                    -- Safety: model must still exist
                    if not (tModel and tModel.Parent) then
                        truckDone += 1; setProgTrucks(truckDone, truckCount); continue
                    end

                    local driveSeat = tModel:FindFirstChild("DriveSeat")
                    if not driveSeat then
                        truckDone += 1; setProgTrucks(truckDone, truckCount); continue
                    end

                    -- Mark all truck parts as ignored before sitting
                    for _, p in ipairs(tModel:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end
                    for _, p in ipairs(Char:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end

                    -- Sit to gain net ownership
                    driveSeat:Sit(Char.Humanoid)
                    local sitTimeout = 0
                    repeat task.wait(0.05); sitTimeout += 0.05; driveSeat:Sit(Char.Humanoid)
                    until Char.Humanoid.SeatPart or sitTimeout > 5

                    if not Char.Humanoid.SeatPart then
                        truckDone += 1; setProgTrucks(truckDone, truckCount); continue
                    end

                    -- Compute destination CFrame for this truck (giver→receiver offset)
                    local mainPart = tModel:FindFirstChild("Main")
                    local truckSrcCF = mainPart and mainPart.CFrame or tModel:GetPrimaryPartCFrame()
                    local truckDestPos = truckSrcCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                    local truckDestCF  = CFrame.new(truckDestPos) * truckSrcCF.Rotation
                    table.insert(truckDestPositions, truckDestPos)

                    -- Scan cargo in the truck's bounding box
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

                    -- Teleport the truck itself explicitly (covers empty trucks too)
                    tModel:SetPrimaryPartCFrame(truckDestCF)

                    local SitPart = Char.Humanoid.SeatPart
                    local DoorHinge = SitPart.Parent:FindFirstChild("PaintParts")
                        and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                        and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")

                    task.wait(0.5)
                    Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.1); SitPart:Destroy(); task.wait(0.1)
                    if DoorHinge then
                        for i = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end
                    end

                    truckDone += 1; setProgTrucks(truckDone, truckCount)
                end

                -- Retry missed cargo
                task.wait(5)
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
                    task.wait(5); retryList = {}
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
                            task.wait(0.1); item.CFrame = data.TargetCFrame; task.wait(0.1)
                            cargoDone = cargoTotal - #retryList
                            setProgTrucks(cargoDone, cargoTotal)
                        end
                    end
                until #retryList == 0 or not _G.VH.butter.running
                setProgTrucks(cargoTotal, cargoTotal)
            end

            -- Return to giver's base so slot items are within reach
            if _G.VH.butter.running and Char:FindFirstChild("HumanoidRootPart") then
                setDupeStatus("Returning to giver slot...", true)
                Char.HumanoidRootPart.CFrame = CFrame.new(GiveBaseOrigin.Position + Vector3.new(0, 5, 0))
                task.wait(0.5)
            end
        end

        -- ── Helpers ──────────────────────────────────────────────────────────
        -- "above truck" destination: 2.70 studs above the first receiver truck
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
                setDupeStatus("Sending wood...", true); local done=0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not _G.VH.butter.running then break end
                        if v.Name=="Owner" and tostring(v.Value)==giverName and v.Parent:FindFirstChild("TreeClass") then
                            local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                            if not part then continue end
                            local PCF  = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame) or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                                Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.1)
                            end
                            for i=1,50 do task.wait(0.05); RS.Interaction.ClientIsDragging:FireServer(part.Parent) end
                            for i=1,200 do part.CFrame = CFrame.new(nPos) * PCF.Rotation end
                            task.wait(0.5) -- 0.5s pacing
                            done+=1; setProgWood(done, total)
                        end
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

print("[VanillaHub] Vanilla2 loaded")
