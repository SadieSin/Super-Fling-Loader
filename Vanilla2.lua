-- ════════════════════════════════════════════════════
-- VANILLA2 — World Tab + Dupe Tab
-- Imports shared state from Vanilla1 via _G.VH
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
-- SHARED HELPERS
-- ════════════════════════════════════════════════════

-- Butter's proven network-ownership check (ReceiveAge == 0 means WE are simulating it)
local function isnetworkowner(part)
    return part.ReceiveAge == 0
end

-- Claim network ownership of a part's parent model, then set its CFrame.
-- Teleports HRP close first so the server hands us ownership.
-- Returns true if we moved it, false if timed out.
local function claimAndMove(part, targetCF, hrp, RS, timeout)
    timeout = timeout or 3
    if not (part and part.Parent) then return false end

    -- Step 1: get close so server gives us ownership
    if hrp and (hrp.Position - part.Position).Magnitude > 20 then
        hrp.CFrame = part.CFrame * CFrame.new(5, 0, 0)
    end

    -- Step 2: fire ClientIsDragging until we own it
    local t0 = tick()
    while not isnetworkowner(part) do
        if not (part and part.Parent) then return false end
        if (tick() - t0) > timeout then return false end
        pcall(function()
            RS.Interaction.ClientIsDragging:FireServer(part.Parent)
        end)
        task.wait()
    end

    -- Step 3: one final drag fire + set CFrame (butter's exact pattern)
    pcall(function()
        RS.Interaction.ClientIsDragging:FireServer(part.Parent)
        part.CFrame = targetCF
    end)
    return true
end

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

    local function setVisual(state)
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = state and Color3.fromRGB(60,180,60) or BTN_COLOR
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, state and 18 or 2, 0.5, -7)
        }):Play()
    end

    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        setVisual(toggled)
        if callback then callback(toggled) end
    end)

    -- Return a setter so other toggles can force-reset this one's visual
    return frame, setVisual, function() return toggled end
end

-- ── Time mode — only one can be active at once ──────
local worldClockConn = nil

local dayFrame,   setDayVisual,   getDayState
local nightFrame, setNightVisual, getNightState
local walkOnWaterConn = nil
local walkOnWaterParts = {}

table.insert(cleanupTasks, function()
    if worldClockConn then worldClockConn:Disconnect(); worldClockConn = nil end
    if walkOnWaterConn then walkOnWaterConn:Disconnect(); walkOnWaterConn = nil end
    for _, p in ipairs(walkOnWaterParts) do
        if p and p.Parent then p:Destroy() end
    end
    walkOnWaterParts = {}
end)

createWSectionLabel("Environment")

-- Always Day
dayFrame, setDayVisual, getDayState = createWorldToggle("Always Day", true, function(v)
    if worldClockConn then worldClockConn:Disconnect(); worldClockConn = nil end
    if v then
        -- Force Night toggle OFF visually if it was on
        if nightFrame and setNightVisual then setNightVisual(false) end
        local Lighting = game:GetService("Lighting")
        Lighting.ClockTime = 14
        worldClockConn = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 14
        end)
    end
end)

-- Always Night
nightFrame, setNightVisual, getNightState = createWorldToggle("Always Night", false, function(v)
    if worldClockConn then worldClockConn:Disconnect(); worldClockConn = nil end
    if v then
        -- Force Day toggle OFF visually if it was on
        if dayFrame and setDayVisual then setDayVisual(false) end
        local Lighting = game:GetService("Lighting")
        Lighting.ClockTime = 0
        worldClockConn = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 0
        end)
    end
end)

local _origFogEnd   = game:GetService("Lighting").FogEnd
local _origFogStart = game:GetService("Lighting").FogStart
createWorldToggle("Remove Fog", false, function(v)
    local Lighting = game:GetService("Lighting")
    if v then
        -- Capture current values at toggle-on time so other scripts don't pollute them
        _origFogEnd   = Lighting.FogEnd
        _origFogStart = Lighting.FogStart
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

local function makeDupeDropdown(labelText)
    local selected = ""
    local isOpen   = false
    local ITEM_H   = 34
    local MAX_SHOW = 5
    local HEADER_H = 40

    local outer = Instance.new("Frame", dupePage)
    outer.Size             = UDim2.new(1,-12,0,HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22,22,30)
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0,8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = Color3.fromRGB(60,60,90); outerStroke.Thickness = 1; outerStroke.Transparency = 0.5

    local header = Instance.new("Frame", outer)
    header.Size = UDim2.new(1,0,0,HEADER_H); header.BackgroundTransparency = 1; header.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", header)
    lbl.Size = UDim2.new(0,80,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = labelText
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size = UDim2.new(1,-96,0,28); selFrame.Position = UDim2.new(0,90,0.5,-14)
    selFrame.BackgroundColor3 = Color3.fromRGB(30,30,42); selFrame.BorderSizePixel = 0
    Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0,6)
    local selStroke = Instance.new("UIStroke", selFrame)
    selStroke.Color = Color3.fromRGB(70,70,110); selStroke.Thickness = 1; selStroke.Transparency = 0.4

    local avatar = Instance.new("ImageLabel", selFrame)
    avatar.Size = UDim2.new(0,20,0,20); avatar.Position = UDim2.new(0,6,0.5,-10)
    avatar.BackgroundColor3 = Color3.fromRGB(45,45,60); avatar.BorderSizePixel = 0
    avatar.Image = ""; avatar.ScaleType = Enum.ScaleType.Crop
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1,0)

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size = UDim2.new(1,-60,1,0); selLbl.Position = UDim2.new(0,32,0,0)
    selLbl.BackgroundTransparency = 1; selLbl.Text = "Select a player..."
    selLbl.Font = Enum.Font.GothamSemibold; selLbl.TextSize = 12
    selLbl.TextColor3 = Color3.fromRGB(110,110,140); selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size = UDim2.new(0,22,1,0); arrowLbl.Position = UDim2.new(1,-24,0,0)
    arrowLbl.BackgroundTransparency = 1; arrowLbl.Text = "▾"
    arrowLbl.Font = Enum.Font.GothamBold; arrowLbl.TextSize = 14
    arrowLbl.TextColor3 = Color3.fromRGB(120,120,160); arrowLbl.TextXAlignment = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size = UDim2.new(1,0,1,0); headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""; headerBtn.ZIndex = 5

    local divider = Instance.new("Frame", outer)
    divider.Size = UDim2.new(1,-16,0,1); divider.Position = UDim2.new(0,8,0,HEADER_H)
    divider.BackgroundColor3 = Color3.fromRGB(50,50,75); divider.BorderSizePixel = 0
    divider.Visible = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position = UDim2.new(0,0,0,HEADER_H+2); listScroll.Size = UDim2.new(1,0,0,0)
    listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3; listScroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
    listScroll.CanvasSize = UDim2.new(0,0,0,0); listScroll.ClipsDescendants = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop = UDim.new(0,4); listPad.PaddingBottom = UDim.new(0,4)
    listPad.PaddingLeft = UDim.new(0,6); listPad.PaddingRight = UDim.new(0,6)

    local function setSelected(name, userId)
        selected = name; selLbl.Text = name; selLbl.TextColor3 = THEME_TEXT
        arrowLbl.TextColor3 = Color3.fromRGB(160,160,210)
        outerStroke.Color = Color3.fromRGB(90,90,160)
        if userId then
            pcall(function()
                avatar.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
        end
    end

    local function clearSelected()
        selected = ""; selLbl.Text = "Select a player..."
        selLbl.TextColor3 = Color3.fromRGB(110,110,140); avatar.Image = ""
        outerStroke.Color = Color3.fromRGB(60,60,90); arrowLbl.TextColor3 = Color3.fromRGB(120,120,160)
    end

    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            local item = Instance.new("TextButton", listScroll)
            item.Size = UDim2.new(1,0,0,ITEM_H); item.BackgroundColor3 = Color3.fromRGB(28,28,40)
            item.Text = ""; item.BorderSizePixel = 0
            Instance.new("UICorner", item).CornerRadius = UDim.new(0,6)
            local iAvatar = Instance.new("ImageLabel", item)
            iAvatar.Size = UDim2.new(0,24,0,24); iAvatar.Position = UDim2.new(0,8,0.5,-12)
            iAvatar.BackgroundColor3 = Color3.fromRGB(45,45,60); iAvatar.BorderSizePixel = 0
            iAvatar.ScaleType = Enum.ScaleType.Crop
            Instance.new("UICorner", iAvatar).CornerRadius = UDim.new(1,0)
            pcall(function()
                iAvatar.Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            local iLbl = Instance.new("TextLabel", item)
            iLbl.Size = UDim2.new(1,-44,1,0); iLbl.Position = UDim2.new(0,40,0,0)
            iLbl.BackgroundTransparency = 1; iLbl.Text = p.Name
            iLbl.Font = Enum.Font.GothamSemibold; iLbl.TextSize = 12
            iLbl.TextColor3 = THEME_TEXT; iLbl.TextXAlignment = Enum.TextXAlignment.Left
            item.MouseEnter:Connect(function() TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play() end)
            item.MouseLeave:Connect(function() TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(28,28,40)}):Play() end)
            item.MouseButton1Click:Connect(function()
                setSelected(p.Name, p.UserId)
                isOpen = false
                TweenService:Create(arrowLbl,  TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Rotation=0}):Play()
                TweenService:Create(outer,     TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
                TweenService:Create(listScroll,TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
                divider.Visible = false
            end)
        end
    end

    local function openList()
        isOpen = true; buildList()
        local count = #Players:GetPlayers()
        local listH = math.min(count, MAX_SHOW) * (ITEM_H+3) + 8
        divider.Visible = true
        TweenService:Create(arrowLbl,  TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Rotation=180}):Play()
        TweenService:Create(outer,     TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H+2+listH)}):Play()
        TweenService:Create(listScroll,TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,listH)}):Play()
    end

    local function closeList()
        isOpen = false
        TweenService:Create(arrowLbl,  TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Rotation=0}):Play()
        TweenService:Create(outer,     TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
        TweenService:Create(listScroll,TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end

    headerBtn.MouseButton1Click:Connect(function() if isOpen then closeList() else openList() end end)
    headerBtn.MouseEnter:Connect(function() TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play() end)
    headerBtn.MouseLeave:Connect(function() TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(30,30,42)}):Play() end)

    Players.PlayerAdded:Connect(function()
        if isOpen then
            buildList()
            local count = #Players:GetPlayers()
            local listH = math.min(count, MAX_SHOW) * (ITEM_H+3) + 8
            outer.Size = UDim2.new(1,-12,0,HEADER_H+2+listH)
            listScroll.Size = UDim2.new(1,0,0,listH)
        end
    end)
    Players.PlayerRemoving:Connect(function(leaving)
        if leaving.Name == selected then clearSelected() end
        if isOpen then
            -- Rebuild after a frame so the player is already removed from Players:GetPlayers()
            task.defer(function()
                buildList()
                local count = #Players:GetPlayers()
                local listH = math.min(count, MAX_SHOW) * (ITEM_H+3) + 8
                outer.Size = UDim2.new(1,-12,0,HEADER_H+2+listH)
                listScroll.Size = UDim2.new(1,0,0,listH)
            end)
        end
    end)

    return outer, function() return selected end
end

-- ── Players dropdowns ────────────────────────────────
createDSection("Players")
local _, getGiverName    = makeDupeDropdown("Giver")
local _, getReceiverName = makeDupeDropdown("Receiver")

-- ── What to Transfer toggles ─────────────────────────
createDSep()
createDSection("What to Transfer")

local _, getStructures = createDToggle("Teleport Structures",      false)
local _, getFurniture  = createDToggle("Teleport Furniture",       false)
local _, getTrucks     = createDToggle("Teleport Trucks",          false)
local _, getDupeItems  = createDToggle("Teleport Purchased Items", false)
local _, getGifs       = createDToggle("Teleport Gift Items",      false)
local _, getWood       = createDToggle("Teleport Wood",            false)

-- ── Status ───────────────────────────────────────────
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

createDSep()

-- ── Start / Stop buttons ─────────────────────────────
local dupeRunning = false
local dupeThread  = nil

createDBtn("Start Dupe", Color3.fromRGB(35,90,45), function()
    if dupeRunning then setDupeStatus("Already running!", true) return end

    local giverName    = getGiverName()
    local receiverName = getReceiverName()
    if giverName == ""    then setDupeStatus("Select a Giver first!",    false) return end
    if receiverName == "" then setDupeStatus("Select a Receiver first!", false) return end

    dupeRunning = true
    setDupeStatus("Running...", true)

    dupeThread = task.spawn(function()
        local ok, err = pcall(DupeBase, giverName, receiverName, {
            Structures    = getStructures(),
            Furniture     = getFurniture(),
            TeleportTrucks = getTrucks(),
            TeleportItems = getDupeItems(),
            TeleportGifs  = getGifs(),
            TeleportWood  = getWood(),
        })
        dupeRunning = false
        if ok then
            setDupeStatus("Done!", false)
        else
            setDupeStatus("Error: " .. tostring(err), false)
        end
    end)
end)

createDBtn("Stop Dupe", Color3.fromRGB(90,35,35), function()
    if dupeThread then pcall(task.cancel, dupeThread); dupeThread = nil end
    dupeRunning = false
    setDupeStatus("Stopped", false)
end)

table.insert(cleanupTasks, function()
    if dupeThread then pcall(task.cancel, dupeThread); dupeThread = nil end
    dupeRunning = false
    setDupeStatus("Stopped", false)
end)

-- ════════════════════════════════════════════════════
-- SHARED TRUCK LOAD LOGIC  (used by both DupeBase and Single Truck)
-- Butter's exact pattern: get close → ClientIsDragging until
-- ReceiveAge==0 (we own it) → fire once more → set CFrame
-- ════════════════════════════════════════════════════

local function isPointInside(point, boxCFrame, boxSize)
    local r = boxCFrame:PointToObjectSpace(point)
    return math.abs(r.X) <= boxSize.X / 2
        and math.abs(r.Y) <= (boxSize.Y / 2 + 2)
        and math.abs(r.Z) <= boxSize.Z / 2
end

--[[
    TeleportTruckAndLoad(truckModel, GiveBaseOrigin, ReceiverBaseOrigin, RS, LP, statusFn)

    1. Scans all BaseParts named "Main" or "WoodSection" inside the truck's bounding box.
    2. For every cargo piece: teleports HRP next to it, fires ClientIsDragging until
       ReceiveAge == 0, then sets its CFrame to the offset position on the receiver plot.
    3. Moves the truck itself the same way (via its Main part so welds drag everything).
    4. Sits LP in the DriveSeat, ejects, fires the door hinge remote.
    5. Runs the missed-item retry loop you wrote (unchanged).

    Returns a table of {Instance, TargetCFrame} for any callers that want to inspect results.
--]]
local function TeleportTruckAndLoad(truckModel, GiveBase, ReceiverBase, RS, LP, statusFn)
    statusFn = statusFn or function() end

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local hum  = char:WaitForChild("Humanoid")

    local ignoredParts    = {}
    local teleportedParts = {}   -- { Instance=part, TargetCFrame=cf }

    -- Mark truck parts and character parts as ignored so we don't scan them as cargo
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then ignoredParts[p] = true end
    end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then ignoredParts[p] = true end
    end

    local modelCFrame, modelSize = truckModel:GetBoundingBox()

    -- ── Step 1: Scan and move cargo using butter's ownership pattern ──
    statusFn("Scanning cargo...", true)
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not ignoredParts[part] then
            if part.Name == "Main" or part.Name == "WoodSection" then
                -- Skip pieces already welded to something else (branch nodes, etc.)
                local weld = part:FindFirstChild("Weld")
                if weld and weld.Part1 and weld.Part1.Parent ~= part.Parent then continue end

                if isPointInside(part.Position, modelCFrame, modelSize) then
                    local pCF    = part.CFrame
                    local nPos   = pCF.Position - GiveBase.Position + ReceiverBase.Position
                    local target = CFrame.new(nPos) * pCF.Rotation

                    table.insert(teleportedParts, { Instance = part, TargetCFrame = target })

                    task.spawn(function()
                        -- Butter pattern: get close, drain to owner, set CFrame
                        pcall(function()
                            if (hrp.Position - part.Position).Magnitude > 20 then
                                hrp.CFrame = part.CFrame * CFrame.new(5, 0, 0)
                            end
                            while not isnetworkowner(part) do
                                if not (part and part.Parent) then return end
                                RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                                task.wait()
                            end
                            RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                            part.CFrame = target
                        end)
                    end)
                end
            end
        end
    end

    -- Small wait for spawned cargo tasks to get started
    task.wait(0.3)

    -- ── Step 2: Move the truck itself (Main part → welds drag the whole body) ──
    local truckMain = truckModel:FindFirstChild("Main")
    if truckMain then
        local tCF   = truckMain.CFrame
        local tNPos = tCF.Position - GiveBase.Position + ReceiverBase.Position
        local tOff  = CFrame.new(tNPos) * tCF.Rotation

        task.spawn(function()
            pcall(function()
                if (hrp.Position - truckMain.Position).Magnitude > 20 then
                    hrp.CFrame = truckMain.CFrame * CFrame.new(5, 0, 0)
                end
                while not isnetworkowner(truckMain) do
                    if not (truckMain and truckMain.Parent) then return end
                    RS.Interaction.ClientIsDragging:FireServer(truckMain.Parent)
                    task.wait()
                end
                RS.Interaction.ClientIsDragging:FireServer(truckMain.Parent)
                truckMain.CFrame = tOff
            end)
        end)
    end

    -- ── Step 3: Sit in DriveSeat → eject → open door ──
    local DriveSeat = truckModel:FindFirstChild("DriveSeat")
    if DriveSeat then
        task.wait(0.1) -- small gap so sit happens while truck is still reachable
        DriveSeat:Sit(hum)
        local timeout = 0
        repeat task.wait(0.05); timeout += 0.05 until hum.SeatPart or timeout > 2

        local SitPart = hum.SeatPart
        if SitPart then
            -- Grab door hinge BEFORE we eject
            local ok2, DoorHinge = pcall(function()
                return SitPart.Parent
                    :FindFirstChild("PaintParts")
                    .DoorLeft
                    :FindFirstChild("ButtonRemote_Hinge")
            end)
            task.wait(0.07)
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.15)
            -- Don't destroy SitPart client-side — just unseat with jump state above
            if ok2 and DoorHinge then
                for i = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end
            end
        end
    end

    -- ── Step 4: Missed-item retry loop (your original logic, unchanged) ──
    task.wait(1.4)

    local retryTeleport = {}
    repeat
        retryTeleport = {}
        for _, data in ipairs(teleportedParts) do
            if data.Instance and data.Instance.Parent
                and (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 5 then
                table.insert(retryTeleport, data)
            end
        end

        if #retryTeleport > 0 then
            statusFn("Retrying " .. #retryTeleport .. " missed item(s)...", true)
            print("Misses detected: " .. #retryTeleport .. ". Retrying...")

            for _, data in ipairs(retryTeleport) do
                local item = data.Instance
                if not (item and item.Parent) then continue end
                print("RETRYING: " .. item:GetFullName())

                local lhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not lhrp then continue end

                local attempts = 0
                repeat
                    attempts += 1
                    if attempts > 3 then break end
                    pcall(function()
                        if (lhrp.Position - item.Position).Magnitude > 25 then
                            lhrp.CFrame = item.CFrame
                        end
                        RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                    end)
                    task.wait(0.2)
                until not (item and item.Parent)
                    or (item.Position - data.TargetCFrame.Position).Magnitude <= 5

                pcall(function() item.CFrame = data.TargetCFrame end)
                task.wait(0.06)
            end
        end

        task.wait(1.4)
    until #retryTeleport == 0

    print("All truck cargo successfully moved!")
    return teleportedParts
end

-- ════════════════════════════════════════════════════
-- DupeBase  (now receives params instead of reading getgenv())
-- ════════════════════════════════════════════════════

function DupeBase(giverName, receiverName, opts)
    local RS = game:GetService("ReplicatedStorage")
    local LP = Players.LocalPlayer
    local Character = LP.Character or LP.CharacterAdded:Wait()

    local GiveBaseOrigin, ReceiverBaseOrigin
    for _, v in pairs(workspace.Properties:GetDescendants()) do
        if v.Name == "Owner" then
            local val = tostring(v.Value)
            if val == giverName    then GiveBaseOrigin     = v.Parent:FindFirstChild("OriginSquare") end
            if val == receiverName then ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
        end
    end
    if not GiveBaseOrigin    then error("Giver base not found!")    end
    if not ReceiverBaseOrigin then error("Receiver base not found!") end

    -- ── Structures ──────────────────────────────────
    if opts.Structures then
        pcall(function()
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName then
                    if v.Parent:FindFirstChild("Type") and tostring(v.Parent.Type.Value) == "Structure" then
                        if v.Parent:FindFirstChildOfClass("Part") or v.Parent:FindFirstChildOfClass("WedgePart") then
                            local PartCFrame = (v.Parent:FindFirstChild("MainCFrame") and v.Parent.MainCFrame.Value)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local DumbassArg = v.Parent:FindFirstChild("BlueprintWoodClass") and v.Parent.BlueprintWoodClass.Value or nil
                            local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                            repeat task.wait()
                                pcall(function()
                                    RS.PlaceStructure.ClientPlacedStructure:FireServer(
                                        v.Parent:FindFirstChild("ItemName").Value, Offset, LP, DumbassArg, v.Parent, true)
                                end)
                            until not v.Parent
                            print("Sent Structure")
                        end
                    end
                end
            end
        end)
    end

    -- ── Furniture ───────────────────────────────────
    if opts.Furniture then
        pcall(function()
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName then
                    if v.Parent:FindFirstChild("Type") and tostring(v.Parent.Type.Value) == "Furniture" then
                        if v.Parent:FindFirstChildOfClass("Part") then
                            local PartCFrame = (v.Parent:FindFirstChild("MainCFrame") and v.Parent.MainCFrame.Value)
                                or (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local DumbassArg = v.Parent:FindFirstChild("BlueprintWoodClass") and v.Parent.BlueprintWoodClass.Value or nil
                            local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                            repeat task.wait()
                                pcall(function()
                                    RS.PlaceStructure.ClientPlacedStructure:FireServer(
                                        v.Parent:FindFirstChild("ItemName").Value, Offset, LP, DumbassArg, v.Parent, true)
                                end)
                            until not v.Parent
                            print("Sent Furniture")
                        end
                    end
                end
            end
        end)
    end

    -- ── Truck Load ──────────────────────────────────
    if opts.TeleportTrucks then
        for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
            if v.Name == "Owner" and tostring(v.Value) == giverName then
                if v.Parent:FindFirstChild("DriveSeat") and v.Parent:FindFirstChild("Main") then
                    TeleportTruckAndLoad(
                        v.Parent,
                        GiveBaseOrigin,
                        ReceiverBaseOrigin,
                        RS, LP,
                        setDupeStatus
                    )
                end
            end
        end
    end

    -- Collect already-moved parts to avoid re-moving them below
    -- (we use a set keyed by Instance for O(1) lookup)
    local movedSet = {}

    -- ── Purchased Items ──────────────────────────────
    if opts.TeleportItems then
        for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
            if v.Name == "Owner" and tostring(v.Value) == giverName then
                if v.Parent:FindFirstChild("PurchasedBoxItemName") then
                    local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                    if not part or movedSet[part] then continue end
                    local PartCFrame = part.CFrame
                    local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                    local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                    local hrp = Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - part.Position).Magnitude > 25 then
                        hrp.CFrame = part.CFrame; task.wait(0.1)
                    end
                    pcall(function()
                        while not isnetworkowner(part) do
                            RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                            task.wait()
                        end
                        RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                        part.CFrame = Offset
                    end)
                    task.wait(0.6)
                    movedSet[part] = true
                    print("Sent Item")
                end
            end
        end
    end

    -- ── Gift Items ───────────────────────────────────
    if opts.TeleportGifs then
        for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
            if v.Name == "Owner" and tostring(v.Value) == giverName then
                if v.Parent:FindFirstChildOfClass("Script") and v.Parent:FindFirstChild("DraggableItem") then
                    local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                    if not part or movedSet[part] then continue end
                    local PartCFrame = part.CFrame
                    local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                    local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                    local hrp = Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - part.Position).Magnitude > 25 then
                        hrp.CFrame = part.CFrame; task.wait(0.1)
                    end
                    pcall(function()
                        while not isnetworkowner(part) do
                            RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                            task.wait()
                        end
                        RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                        part.CFrame = Offset
                    end)
                    task.wait(0.6)
                    movedSet[part] = true
                    print("Sent Gift Item")
                end
            end
        end
    end

    -- ── Wood ─────────────────────────────────────────
    if opts.TeleportWood then
        for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
            if v.Name == "Owner" and tostring(v.Value) == giverName then
                if v.Parent:FindFirstChild("TreeClass") then
                    local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                    if not part or movedSet[part] then continue end
                    local PartCFrame = part.CFrame
                    local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                    local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                    local hrp = Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - part.Position).Magnitude > 25 then
                        hrp.CFrame = part.CFrame; task.wait(0.1)
                    end
                    pcall(function()
                        while not isnetworkowner(part) do
                            RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                            task.wait()
                        end
                        RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                        part.CFrame = Offset
                    end)
                    task.wait(0.6)
                    movedSet[part] = true
                    print("Sent Wood")
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════
-- SINGLE TRUCK TELEPORT
-- ════════════════════════════════════════════════════

createDSep()
createDSection("Single Truck Teleport")

-- Status bar
local singleTruckStatusFrame = Instance.new("Frame", dupePage)
singleTruckStatusFrame.Size = UDim2.new(1,-12,0,28)
singleTruckStatusFrame.BackgroundColor3 = Color3.fromRGB(14,14,18)
singleTruckStatusFrame.BorderSizePixel = 0
Instance.new("UICorner", singleTruckStatusFrame).CornerRadius = UDim.new(0,6)
local stDot = Instance.new("Frame", singleTruckStatusFrame)
stDot.Size = UDim2.new(0,7,0,7); stDot.Position = UDim2.new(0,10,0.5,-3)
stDot.BackgroundColor3 = Color3.fromRGB(80,80,100); stDot.BorderSizePixel = 0
Instance.new("UICorner", stDot).CornerRadius = UDim.new(1,0)
local singleTruckStatusLbl = Instance.new("TextLabel", singleTruckStatusFrame)
singleTruckStatusLbl.Size = UDim2.new(1,-28,1,0); singleTruckStatusLbl.Position = UDim2.new(0,24,0,0)
singleTruckStatusLbl.BackgroundTransparency = 1; singleTruckStatusLbl.Font = Enum.Font.Gotham
singleTruckStatusLbl.TextSize = 12; singleTruckStatusLbl.TextColor3 = THEME_TEXT
singleTruckStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
singleTruckStatusLbl.Text = "Ready"

local function setSTStatus(msg, active)
    singleTruckStatusLbl.Text = msg
    stDot.BackgroundColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
end

-- Giver + Receiver dropdowns
local _, getSTGiver    = makeDupeDropdown("Giver")
local _, getSTReceiver = makeDupeDropdown("Receiver")

local stRunning = false
local stThread  = nil

createDBtn("Teleport Single Truck", Color3.fromRGB(45,70,120), function()
    if stRunning then setSTStatus("Already running!", true) return end

    local giverName    = getSTGiver()
    local receiverName = getSTReceiver()
    if giverName    == "" then setSTStatus("Select a Giver first!",    false) return end
    if receiverName == "" then setSTStatus("Select a Receiver first!", false) return end

    stRunning = true
    setSTStatus("Running...", true)

    stThread = task.spawn(function()
        local ok, err = pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local LP = Players.LocalPlayer

            -- Locate OriginSquares
            local GiveBaseOrigin, ReceiverBaseOrigin
            for _, v in pairs(workspace.Properties:GetDescendants()) do
                if v.Name == "Owner" then
                    local val = tostring(v.Value)
                    if val == giverName    then GiveBaseOrigin     = v.Parent:FindFirstChild("OriginSquare") end
                    if val == receiverName then ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
                end
            end
            if not GiveBaseOrigin    then setSTStatus("Giver base not found!",    false) stRunning = false return end
            if not ReceiverBaseOrigin then setSTStatus("Receiver base not found!", false) stRunning = false return end

            -- Find the giver's truck
            local truckModel = nil
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName then
                    if v.Parent:FindFirstChild("DriveSeat") and v.Parent:FindFirstChild("Main") then
                        truckModel = v.Parent
                        break
                    end
                end
            end
            if not truckModel then setSTStatus("No truck found for Giver!", false) stRunning = false return end

            -- Use the exact same shared function as DupeBase
            TeleportTruckAndLoad(
                truckModel,
                GiveBaseOrigin,
                ReceiverBaseOrigin,
                RS, LP,
                setSTStatus
            )

            setSTStatus("Done! Truck + cargo moved.", false)
            print("[SingleTruck] All done!")
        end)

        stRunning = false
        if not ok then
            setSTStatus("Error: " .. tostring(err), false)
        end
    end)
end)

createDBtn("Stop Truck Teleport", Color3.fromRGB(90,35,35), function()
    if stThread then pcall(task.cancel, stThread); stThread = nil end
    stRunning = false
    setSTStatus("Stopped", false)
end)

table.insert(cleanupTasks, function()
    if stThread then pcall(task.cancel, stThread); stThread = nil end
    stRunning = false
end)

print("[VanillaHub] Vanilla2 loaded")
