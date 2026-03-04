-- VanillaHub | Vanilla7.lua
-- Tabs: Build, Vehicle
-- Continuation of Vanilla6. Requires _G.VH to be loaded first.

if not _G.VH then
    warn("[VanillaHub] Vanilla7: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH = _G.VH
local TS = VH.TweenService
local Players = VH.Players
local RS = game:GetService("ReplicatedStorage")
local UIS = VH.UserInputService
local RunService = VH.RunService
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

local THEME_TEXT = VH.THEME_TEXT
local BTN_COLOR  = VH.BTN_COLOR
local BTN_HOVER  = VH.BTN_HOVER

-- ─── Shared UI helpers (same as Vanilla6, self-contained) ───────────────────

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function ripple(btn)
    if not btn.ClipsDescendants then btn.ClipsDescendants = true end
    local r = Instance.new("ImageLabel")
    r.BackgroundTransparency = 1
    r.ZIndex = btn.ZIndex + 5
    r.Image = "rbxassetid://2708891598"
    r.ImageTransparency = 0.7
    r.ImageColor3 = Color3.fromRGB(255,255,255)
    r.ScaleType = Enum.ScaleType.Fit
    r.Size = UDim2.new(0,0,0,0)
    r.AnchorPoint = Vector2.new(0.5,0.5)
    local mp = UIS:GetMouseLocation()
    local abs = btn.AbsolutePosition
    r.Position = UDim2.new(0, mp.X - abs.X, 0, mp.Y - abs.Y)
    r.Parent = btn
    TS:Create(r, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,180,0,180),
        ImageTransparency = 1,
    }):Play()
    game:GetService("Debris"):AddItem(r, 0.4)
end

local function makeScrollContent(pageFrame)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1,0,1,0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(80,60,90)
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Parent = pageFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)
    layout.Parent = sf

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0,16)
    pad.PaddingBottom = UDim.new(0,16)
    pad.PaddingLeft   = UDim.new(0,14)
    pad.PaddingRight  = UDim.new(0,14)
    pad.Parent = sf

    return sf
end

local function makeLabel(parent, text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,22)
    f.BackgroundTransparency = 1
    f.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,100,140)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    lbl.Parent = f
    return f
end

local function makeSep(parent)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1,0,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,40,55)
    s.BorderSizePixel = 0
    s.Parent = parent
    return s
end

local function makeButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = BTN_COLOR
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT
    btn.Text = text
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true
    makeCorner(btn, 6)
    btn.Parent = parent

    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        ripple(btn)
        task.spawn(callback)
    end)
    return btn
end

local function makeToggle(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,32)
    container.BackgroundColor3 = BTN_COLOR
    container.BorderSizePixel = 0
    makeCorner(container, 6)
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-50,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0,34,0,18)
    track.Position = UDim2.new(1,-44,0.5,-9)
    track.BackgroundColor3 = Color3.fromRGB(50,50,60)
    track.BorderSizePixel = 0
    makeCorner(track, 9)
    track.Parent = container

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(160,140,180)
    knob.BorderSizePixel = 0
    makeCorner(knob, 7)
    knob.Parent = track

    local state = default
    local function setState(v)
        state = v
        TS:Create(knob, TweenInfo.new(0.18), {
            Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
            BackgroundColor3 = state and Color3.fromRGB(180,100,210) or Color3.fromRGB(160,140,180),
        }):Play()
        TS:Create(track, TweenInfo.new(0.18), {
            BackgroundColor3 = state and Color3.fromRGB(90,40,120) or Color3.fromRGB(50,50,60),
        }):Play()
        callback(state)
    end
    setState(default)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1,0,1,0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = container
    clickBtn.MouseButton1Click:Connect(function() setState(not state) end)

    return {SetState = setState, GetState = function() return state end}
end

local function makeSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,52)
    container.BackgroundColor3 = BTN_COLOR
    container.BorderSizePixel = 0
    makeCorner(container, 6)
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5,0,0,24)
    lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.Parent = container

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.5,0,0,24)
    valLbl.Position = UDim2.new(0.5,0,0,4)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.Gotham
    valLbl.TextSize = 12
    valLbl.TextColor3 = Color3.fromRGB(180,160,200)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(default)
    valLbl.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-20,0,6)
    track.Position = UDim2.new(0,10,1,-18)
    track.BackgroundColor3 = Color3.fromRGB(35,35,45)
    track.BorderSizePixel = 0
    makeCorner(track, 3)
    track.Parent = container

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(150,80,200)
    fill.BorderSizePixel = 0
    makeCorner(fill, 3)
    fill.Parent = track

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,16,0,16)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(0,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(200,160,230)
    knob.BorderSizePixel = 0
    makeCorner(knob, 8)
    knob.ZIndex = 3
    knob.Parent = track

    local value = default
    local function setValue(v)
        v = math.clamp(math.floor(v), min, max)
        value = v
        local pct = (v - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = tostring(v)
        callback(v)
    end
    setValue(default)

    local dragging = false
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            setValue(math.floor(min + (max - min) * pct))
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            setValue(math.floor(min + (max - min) * pct))
        end
    end)

    return {SetValue = setValue, GetValue = function() return value end}
end

local function makeDropdown(parent, placeholder, options, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,40)
    container.BackgroundColor3 = BTN_COLOR
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    makeCorner(container, 6)
    container.Parent = parent

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1,0,0,40)
    header.BackgroundColor3 = BTN_COLOR
    header.BorderSizePixel = 0
    header.Font = Enum.Font.GothamSemibold
    header.TextSize = 13
    header.TextColor3 = Color3.fromRGB(160,140,180)
    header.Text = placeholder
    header.AutoButtonColor = false
    header.ClipsDescendants = true
    makeCorner(header, 6)
    header.Parent = container

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0,20,0,20)
    arrow.Position = UDim2.new(1,-28,0.5,-10)
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 14
    arrow.TextColor3 = Color3.fromRGB(130,110,160)
    arrow.Text = "▾"
    arrow.Parent = header

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1,0,0,0)
    list.Position = UDim2.new(0,0,1,4)
    list.BackgroundColor3 = Color3.fromRGB(30,28,38)
    list.BorderSizePixel = 0
    list.ClipsDescendants = true
    list.ZIndex = 20
    makeCorner(list, 6)
    list.Parent = container

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local listPad = Instance.new("UIPadding")
    listPad.PaddingTop    = UDim.new(0,4)
    listPad.PaddingBottom = UDim.new(0,4)
    listPad.Parent = list

    local open = false

    local function close()
        open = false
        arrow.Text = "▾"
        TS:Create(list, TweenInfo.new(0.18), {Size = UDim2.new(1,0,0,0)}):Play()
        task.delay(0.18, function() list.ClipsDescendants = true end)
    end

    local function openList()
        open = true
        arrow.Text = "▴"
        list.ClipsDescendants = false
        local contentH = listLayout.AbsoluteContentSize.Y + 8
        TS:Create(list, TweenInfo.new(0.18), {Size = UDim2.new(1,0,0,contentH)}):Play()
    end

    local function rebuild(opts)
        for _, ch in ipairs(list:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for _, opt in ipairs(opts) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1,0,0,30)
            ob.BackgroundTransparency = 1
            ob.Font = Enum.Font.Gotham
            ob.TextSize = 13
            ob.TextColor3 = THEME_TEXT
            ob.Text = opt
            ob.ZIndex = 20
            ob.AutoButtonColor = false
            ob.Parent = list

            ob.MouseEnter:Connect(function()
                TS:Create(ob, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(200,170,230)}):Play()
            end)
            ob.MouseLeave:Connect(function()
                TS:Create(ob, TweenInfo.new(0.1), {TextColor3 = THEME_TEXT}):Play()
            end)
            ob.MouseButton1Click:Connect(function()
                header.Text = opt
                header.TextColor3 = THEME_TEXT
                close()
                callback(opt)
            end)
        end
        if open then
            local contentH = listLayout.AbsoluteContentSize.Y + 8
            list.Size = UDim2.new(1,0,0,contentH)
        end
    end

    rebuild(options)
    header.MouseButton1Click:Connect(function()
        if open then close() else openList() end
    end)

    return {
        SetOptions = function(_, opts) rebuild(opts) end,
    }
end

local function makeStatus(parent, label)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,28)
    f.BackgroundColor3 = Color3.fromRGB(30,28,38)
    f.BorderSizePixel = 0
    makeCorner(f, 6)
    f.Parent = parent

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,7,0,7)
    dot.Position = UDim2.new(0,10,0.5,-3)
    dot.BackgroundColor3 = Color3.fromRGB(80,80,100)
    dot.BorderSizePixel = 0
    makeCorner(dot, 4)
    dot.Parent = f

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-30,1,0)
    lbl.Position = UDim2.new(0,24,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(150,130,170)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = f

    return {
        SetActive = function(active, msg)
            dot.BackgroundColor3 = active and Color3.fromRGB(80,200,80) or Color3.fromRGB(80,80,100)
            lbl.Text = msg or label
        end
    }
end

-- ─── Tab builder ─────────────────────────────────────────────────────────────

local function addTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1,0,0,36)
    tabBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
    tabBtn.BorderSizePixel = 0
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextSize = 13
    tabBtn.TextColor3 = Color3.fromRGB(160,160,160)
    tabBtn.Text = name
    tabBtn.AutoButtonColor = false
    tabBtn.ClipsDescendants = true
    makeCorner(tabBtn, 6)
    tabBtn.Parent = VH.tabList

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = VH.contentArea

    tabBtn.MouseButton1Click:Connect(function()
        ripple(tabBtn)
        VH.switchTab(page, tabBtn)
    end)

    return makeScrollContent(page), tabBtn, page
end

-- ── Player list helper ────────────────────────────────────────────────────────

local function getPlayerNames()
    local names = {}
    for _, p in next, Players:GetPlayers() do table.insert(names, p.Name) end
    return names
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 1: BUILD  (AutoFill / Studio Build — from Butterhub AutoBuild tab)
-- ═══════════════════════════════════════════════════════════════════════════

local buildScroll, buildBtn, buildPage = addTab("Build")

-- ── Helpers ───────────────────────────────────────────────────────────────────

local woodTPSpeed = 0.3
local buildPlayer = LP.Name
local getBlueprints_build = false  -- toggle flag for lasso

-- Is-network-owner check
local function isNetworkOwner(part)
    return pcall(function() return part.ReceiveAge == 0 end) and part.ReceiveAge == 0
end

-- Deselect all selection boxes
local function deselectAll()
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Selection" then
            pcall(function() v:Destroy() end)
        end
    end
    for _, v in pairs(workspace.Preview:GetDescendants()) do
        if v.Name == "Selection" then
            pcall(function() v:Destroy() end)
        end
    end
end

-- is_in_frame helper
local function isInFrame(screenPos, frame)
    local xPos = frame.AbsolutePosition.X
    local yPos = frame.AbsolutePosition.Y
    local xSz  = frame.AbsoluteSize.X
    local ySz  = frame.AbsoluteSize.Y
    local c1 = screenPos.X >= xPos and screenPos.X <= xPos + xSz
    local c2 = screenPos.X <= xPos and screenPos.X >= xPos + xSz
    local c3 = screenPos.Y >= yPos and screenPos.Y <= yPos + ySz
    local c4 = screenPos.Y <= yPos and screenPos.Y >= yPos + ySz
    return (c1 and c3) or (c2 and c3) or (c1 and c4) or (c2 and c4)
end

-- Lasso overlay for wood selection
local lassoActive      = false
local lassoFrame       = nil
local lassoConnection  = nil

local function setupLasso()
    if lassoFrame then pcall(function() lassoFrame.Parent:Destroy() end) end

    local sg = Instance.new("ScreenGui")
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = game.CoreGui

    lassoFrame = Instance.new("Frame")
    lassoFrame.BackgroundColor3 = Color3.fromRGB(255,160,40)
    lassoFrame.BackgroundTransparency = 0.82
    lassoFrame.BorderColor3 = Color3.fromRGB(200,120,20)
    lassoFrame.BorderSizePixel = 2
    lassoFrame.Size = UDim2.new(0,0,0,0)
    lassoFrame.Visible = false
    lassoFrame.ZIndex = 20
    lassoFrame.Parent = sg

    if lassoConnection then lassoConnection:Disconnect() end

    lassoConnection = UIS.InputBegan:Connect(function(input)
        if not lassoActive then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        lassoFrame.Visible = true
        lassoFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)

        while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            RunService.RenderStepped:Wait()
            lassoFrame.Size = UDim2.new(0, Mouse.X, 0, Mouse.Y) - lassoFrame.Position

            local cam = workspace.CurrentCamera
            for _, v in pairs(workspace.PlayerModels:GetChildren()) do
                -- Wood sections
                if v:FindFirstChild("WoodSection") then
                    local sp, vis = cam:WorldToScreenPoint(v.WoodSection.CFrame.p)
                    if vis and isInFrame(sp, lassoFrame) then
                        if not v.WoodSection:FindFirstChild("Selection") then
                            local sb = Instance.new("SelectionBox", v.WoodSection)
                            sb.Name = "Selection"
                            sb.Adornee = v.WoodSection
                            sb.SurfaceTransparency = 0.5
                            sb.LineThickness = 0.09
                            sb.SurfaceColor3 = Color3.fromRGB(0,0,0)
                            sb.Color3 = Color3.fromRGB(150,80,200)
                        end
                    end
                end
                -- Blueprints (only if getBlueprints_build enabled)
                if getBlueprints_build and v:FindFirstChild("BuildDependentWood") then
                    local sp, vis = cam:WorldToScreenPoint(v.BuildDependentWood.CFrame.p)
                    if vis and isInFrame(sp, lassoFrame) then
                        if not v.BuildDependentWood:FindFirstChild("Selection") then
                            local sb = Instance.new("SelectionBox", v.BuildDependentWood)
                            sb.Name = "Selection"
                            sb.Adornee = v.BuildDependentWood
                            sb.SurfaceTransparency = 0.5
                            sb.LineThickness = 0.09
                            sb.SurfaceColor3 = Color3.fromRGB(0,0,0)
                            sb.Color3 = Color3.fromRGB(150,80,200)
                        end
                    end
                end
            end
        end

        lassoFrame.Size = UDim2.new(0,1,0,1)
        lassoFrame.Visible = false
    end)

    table.insert(VH.cleanupTasks, function()
        pcall(function() sg:Destroy() end)
        if lassoConnection then lassoConnection:Disconnect() end
    end)
end

setupLasso()

-- Fill blueprints with selected wood
local function selectionTpWood(speed, owner)
    local selectedWood = {}
    local selectedBlueprints = {}

    for _, v in ipairs(workspace.PlayerModels:GetDescendants()) do
        if v:FindFirstChild("Selection") then
            table.insert(selectedWood, v)
        elseif v.Name == "Type" and v.Value == "Blueprint"
           and tostring(v.Parent.Owner.Value) == owner
           and v.Parent:FindFirstChild("BuildDependentWood")
           and v.Parent.BuildDependentWood.Transparency ~= 1 then
            table.insert(selectedBlueprints, v.Parent.BuildDependentWood)
        end
    end

    local count = math.min(#selectedWood, #selectedBlueprints)

    for i = 1, count do
        local wood = selectedWood[i]
        local bp   = selectedBlueprints[i]

        pcall(function()
            LP.Character.HumanoidRootPart.CFrame =
                CFrame.new(wood:FindFirstChild("Selection").Parent.CFrame.p) * CFrame.new(5,0,0)
        end)
        task.wait(speed)

        pcall(function()
            if not wood.Parent.PrimaryPart then
                wood.Parent.PrimaryPart = wood:FindFirstChild("Selection").Parent
            end

            local timeout = tick()
            while not isNetworkOwner(wood:FindFirstChild("Selection").Parent) do
                RS.Interaction.ClientIsDragging:FireServer(wood.Parent)
                task.wait(speed)
                if tick() - timeout > 6 then break end
            end

            RS.Interaction.ClientIsDragging:FireServer(wood.Parent)
            wood:FindFirstChild("Selection").Parent:PivotTo(bp.CFrame)
        end)

        task.wait(speed)
    end
end

-- Load Preview into correct world position
local function loadPreview()
    local posX, posY, posZ = 0, 0, 0

    for _, v in next, workspace.Properties:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP then
            posX = v.OriginSquare.Position.X
            posY = v.OriginSquare.Position.Y
            posZ = v.OriginSquare.Position.Z
        end
    end

    if not workspace:FindFirstChild("Preview") then return end

    local colorMap = {
        LoneCave    = {Color3.fromRGB(248,248,248), Enum.Material.Foil},
        Frost       = {Color3.fromRGB(159,243,233), Enum.Material.Ice},
        Spooky      = {Color3.fromRGB(170,85,0),    Enum.Material.Granite},
        SnowGlow    = {Color3.fromRGB(255,255,0),   Enum.Material.SmoothPlastic},
        CaveCrawler = {Color3.fromRGB(16,42,220),   Enum.Material.Neon},
        SpookyNeon  = {Color3.fromRGB(170,85,0),    Enum.Material.Neon},
        Volcano     = {Color3.fromRGB(255,0,0),     Enum.Material.Wood},
        GreenSwampy = {Color3.fromRGB(52,142,64),   Enum.Material.Wood},
        GoldSwampy  = {Color3.fromRGB(226,155,64),  Enum.Material.Wood},
        Cherry      = {Color3.fromRGB(163,75,75),   Enum.Material.Wood},
        Pine        = {Color3.fromRGB(215,197,154), Enum.Material.Wood},
        Walnut      = {Color3.fromRGB(105,64,40),   Enum.Material.Wood},
        Oak         = {Color3.fromRGB(234,184,146), Enum.Material.Wood},
        Birch       = {Color3.fromRGB(205,205,205), Enum.Material.Wood},
        Koa         = {Color3.fromRGB(143,76,42),   Enum.Material.Wood},
        Generic     = {Color3.fromRGB(204,142,105), Enum.Material.Wood},
        Palm        = {Color3.fromRGB(226,220,188), Enum.Material.Wood},
    }

    for _, v in pairs(workspace.Preview:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Position = v.Position + Vector3.new(posX, posY, posZ)
            local tc = v.Parent:FindFirstChild("TreeClass")
            if tc and v.Transparency == 0.5 then
                local info = colorMap[tc.Value]
                if info then
                    v.Color    = info[1]
                    v.Material = info[2]
                end
            end
        end
    end

    -- Remove previews that already have placed structures
    local pre = {}
    for _, v in pairs(workspace.Preview:GetChildren()) do
        local bdw = v:FindFirstChild("BuildDependentWood")
        if bdw then table.insert(pre, {model=v, bdw=bdw}) end
    end

    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP
           and v:FindFirstChild("Type") and v.Type.Value == "Structure"
           and v:FindFirstChild("MainCFrame") then
            for _, ch in pairs(v:GetChildren()) do
                if ch.Name == "BuildDependentWood" then
                    for _, pre_entry in pairs(pre) do
                        local p1 = pre_entry.bdw.CFrame.Position
                        local p2 = ch.CFrame.Position
                        if Vector3.new(math.floor(p1.X),math.floor(p1.Y),math.floor(p1.Z))
                        == Vector3.new(math.floor(p2.X),math.floor(p2.Y),math.floor(p2.Z)) then
                            pcall(function() pre_entry.model:Destroy() end)
                        end
                    end
                end
            end
        end
    end
end

-- Unload preview
local function unloadPreview()
    if workspace:FindFirstChild("Preview") then
        workspace.Preview:ClearAllChildren()
    end
end

-- Destroy selected blueprints
local function destroySelectedBlueprints()
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Selection" and v.Parent.Name == "BuildDependentWood" then
            pcall(function()
                RS.Interaction.DestroyStructure:FireServer(v.Parent.Parent)
            end)
            task.wait(1)
        end
    end
end

-- ── Build UI ──────────────────────────────────────────────────────────────────

makeLabel(buildScroll, "Studio Build (Preview)")

makeButton(buildScroll, "Load Preview Into World", function()
    loadPreview()
end)

makeButton(buildScroll, "Unload Preview", function()
    unloadPreview()
end)

makeSep(buildScroll)
makeLabel(buildScroll, "Fill Blueprints")

makeToggle(buildScroll, "Lasso Wood Tool", false, function(v)
    lassoActive = v
    getBlueprints_build = false
end)

makeToggle(buildScroll, "Include Blueprints in Lasso", false, function(v)
    getBlueprints_build = v
    lassoActive = v
end)

local speedSliderBuild = makeSlider(buildScroll, "Fill Speed", 1, 10, 3, function(v)
    woodTPSpeed = v / 10  -- 0.1 to 1.0
end)

local buildPlayerDD
do
    local names = getPlayerNames()
    buildPlayerDD = makeDropdown(buildScroll, "Wood Owner Player...", names, function(val)
        buildPlayer = val
    end)
end

makeButton(buildScroll, "Fill Blueprints with Selected Wood", function()
    task.spawn(selectionTpWood, woodTPSpeed, buildPlayer)
end)

makeButton(buildScroll, "Deselect All Items", function()
    deselectAll()
end)

makeSep(buildScroll)
makeLabel(buildScroll, "Build Help")

makeToggle(buildScroll, "Blueprint Select Tool", false, function(v)
    getBlueprints_build = v
    lassoActive = v
end)

makeButton(buildScroll, "Deselect All", function()
    deselectAll()
end)

makeButton(buildScroll, "Destroy Selected Blueprints", function()
    destroySelectedBlueprints()
end)

-- Update build player dropdown when players join/leave
Players.PlayerAdded:Connect(function()
    buildPlayerDD:SetOptions(getPlayerNames())
end)
Players.PlayerRemoving:Connect(function()
    buildPlayerDD:SetOptions(getPlayerNames())
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 2: VEHICLE
-- ═══════════════════════════════════════════════════════════════════════════

local vehicleScroll, vehicleBtn, vehiclePage = addTab("Vehicle")

-- ── Helpers ───────────────────────────────────────────────────────────────────

local vehicleFlyEnabled = false
local vehicleFlySpeed   = 1
local FLYING            = false
local flyKeyDown, flyKeyUp

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

local function setVehicleSpeed(val)
    for _, v in next, workspace.PlayerModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP then
            if v:FindFirstChild("Type") and v.Type.Value == "Vehicle" then
                if v:FindFirstChild("Configuration") then
                    pcall(function() v.Configuration.MaxSpeed.Value = val end)
                end
            end
        end
    end
end

-- Car teleport (must be seated in vehicle)
local function carTP(targetCF)
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.Seated then return end
    local seat = hum.SeatPart
    if seat and seat.Parent:FindFirstChild("Type") and seat.Parent.Type.Value == "Vehicle" then
        pcall(function()
            seat.CFrame = targetCF
            seat.Parent.RightSteer.Wheel.CFrame  = targetCF
            seat.Parent.LeftSteer.Wheel.CFrame   = targetCF
            seat.Parent.RightPower.Wheel.CFrame  = targetCF
            seat.Parent.LeftPower.Wheel.CFrame   = targetCF
        end)
    end
end

-- Vehicle fly (from Butterhub sFLY)
local function startVehicleFly()
    repeat task.wait() until LP and LP.Character and getRoot(LP.Character)
        and LP.Character:FindFirstChildOfClass("Humanoid")

    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp   then flyKeyUp:Disconnect()   end

    local T = getRoot(LP.Character)
    local CTRL  = {F=0,B=0,L=0,R=0}
    local lCTRL = {F=0,B=0,L=0,R=0}
    local SPEED = 0

    FLYING = true
    local BG = Instance.new("BodyGyro", T)
    local BV = Instance.new("BodyVelocity", T)
    BG.P = 9e4
    BG.maxTorque = Vector3.new(9e9,9e9,9e9)
    BG.cframe = T.CFrame
    BV.velocity = Vector3.new(0,0,0)
    BV.maxForce = Vector3.new(9e9,9e9,9e9)

    task.spawn(function()
        repeat task.wait()
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = true end

            local moving = CTRL.L+CTRL.R ~= 0 or CTRL.F+CTRL.B ~= 0
            SPEED = moving and (50 * vehicleFlySpeed) or 0

            local cam = workspace.CurrentCamera.CoordinateFrame
            if moving then
                BV.velocity = ((cam.lookVector*(CTRL.F+CTRL.B)) + ((cam*CFrame.new(CTRL.L+CTRL.R,(CTRL.F+CTRL.B)*0.2,0).p) - cam.p)) * SPEED
                lCTRL = {F=CTRL.F,B=CTRL.B,L=CTRL.L,R=CTRL.R}
            elseif SPEED ~= 0 then
                BV.velocity = ((cam.lookVector*(lCTRL.F+lCTRL.B)) + ((cam*CFrame.new(lCTRL.L+lCTRL.R,(lCTRL.F+lCTRL.B)*0.2,0).p) - cam.p)) * SPEED
            else
                BV.velocity = Vector3.new(0,0,0)
            end
            BG.cframe = workspace.CurrentCamera.CoordinateFrame
        until not FLYING

        CTRL  = {F=0,B=0,L=0,R=0}
        lCTRL = {F=0,B=0,L=0,R=0}
        SPEED = 0
        pcall(function() BG:Destroy() BV:Destroy() end)
        local hum2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2.PlatformStand = false end
    end)

    flyKeyDown = Mouse.KeyDown:Connect(function(key)
        local k = key:lower()
        if k == "w" then CTRL.F =  vehicleFlySpeed
        elseif k == "s" then CTRL.B = -vehicleFlySpeed
        elseif k == "a" then CTRL.L = -vehicleFlySpeed
        elseif k == "d" then CTRL.R =  vehicleFlySpeed
        end
    end)
    flyKeyUp = Mouse.KeyUp:Connect(function(key)
        local k = key:lower()
        if k == "w" then CTRL.F = 0
        elseif k == "s" then CTRL.B = 0
        elseif k == "a" then CTRL.L = 0
        elseif k == "d" then CTRL.R = 0
        end
    end)
end

local function stopVehicleFly()
    FLYING = false
    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp   then flyKeyUp:Disconnect()   end
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end)
end

-- Vehicle spawner
local selectedSpawnColor = nil
local abortSpawner       = false
local spawnerStatus

local carColors = {
    "Medium stone grey", "Sand green", "Sand red", "Faded green",
    "Dark grey metallic", "Dark grey", "Earth yellow", "Earth orange",
    "Silver", "Brick yellow", "Dark red", "Hot pink",
}

local function vehicleSpawner(color)
    if tostring(color) == "Select Color..." then return end
    abortSpawner = false

    local respawnedColorPart = nil
    local colorConn = workspace.PlayerModels.ChildAdded:Connect(function(v)
        if v:FindFirstChild("Owner") and v.Owner.Value == LP then
            if v:FindFirstChild("PaintParts") then
                local pp = v.PaintParts:FindFirstChild("Part")
                if pp then respawnedColorPart = pp end
            end
        end
    end)

    spawnerStatus.SetActive(true, "Click your car spawn pad...")

    local padConn
    padConn = Mouse.Button1Up:Connect(function()
        local target = Mouse.Target
        if not target then return end
        local parent = target.Parent
        if parent:FindFirstChild("Owner") and parent.Owner.Value == LP
           and parent:FindFirstChild("Type") and parent.Type.Value == "Vehicle Spot" then
            local pad = target
            task.spawn(function()
                repeat
                    if abortSpawner then break end
                    pcall(function()
                        RS.Interaction.RemoteProxy:FireServer(pad.Parent.ButtonRemote_SpawnButton)
                    end)
                    task.wait(1)
                    if respawnedColorPart and respawnedColorPart.BrickColor.Name == color then
                        spawnerStatus.SetActive(false, "Done! Car spawned.")
                        break
                    end
                until abortSpawner

                colorConn:Disconnect()
                padConn:Disconnect()
            end)
        end
    end)
end

local function sitInAnyVehicle()
    pcall(function()
        LP.PlayerGui.Scripts.SitPermissions.Disabled = false
    end)
end

-- ── Vehicle UI ────────────────────────────────────────────────────────────────

makeLabel(vehicleScroll, "Vehicle Controls")

makeSlider(vehicleScroll, "Vehicle Max Speed", 1, 10, 1, function(v)
    setVehicleSpeed(v)
end)

makeToggle(vehicleScroll, "Vehicle Fly", false, function(v)
    vehicleFlyEnabled = v
    if v then
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Seated then
            local seat = hum.SeatPart
            if seat and seat.Parent:FindFirstChild("Type") and seat.Parent.Type.Value == "Vehicle" then
                stopVehicleFly()
                task.wait()
                startVehicleFly()
            end
        end
    else
        stopVehicleFly()
    end
end)

makeSlider(vehicleScroll, "Vehicle Fly Speed", 1, 20, 1, function(v)
    vehicleFlySpeed = v
end)

makeSep(vehicleScroll)
makeLabel(vehicleScroll, "Vehicle Teleport")

local playerNamesVeh = getPlayerNames()

local vehTpPlayerDD
vehTpPlayerDD = makeDropdown(vehicleScroll, "Teleport Vehicle to Player...", playerNamesVeh, function(val)
    for _, p in next, Players:GetPlayers() do
        if p.Name == val and p.Character then
            carTP(p.Character.HumanoidRootPart.CFrame)
            break
        end
    end
end)

local vehTpPlotDD
vehTpPlotDD = makeDropdown(vehicleScroll, "Teleport Vehicle to Player's Plot...", playerNamesVeh, function(val)
    for _, v in next, workspace.Properties:GetChildren() do
        if v:FindFirstChild("Owner") and tostring(v.Owner.Value) == val then
            carTP(v.OriginSquare.CFrame)
            break
        end
    end
end)

makeButton(vehicleScroll, "Sit In Any Vehicle", function()
    sitInAnyVehicle()
end)

makeSep(vehicleScroll)
makeLabel(vehicleScroll, "Vehicle Spawner")

makeDropdown(vehicleScroll, "Select Spawn Color...", carColors, function(val)
    selectedSpawnColor = val
end)

spawnerStatus = makeStatus(vehicleScroll, "Idle — select color then click pad")

makeButton(vehicleScroll, "Start Vehicle Spawner", function()
    if not selectedSpawnColor then
        warn("[VanillaHub] Vehicle: Select a color first.")
        return
    end
    task.spawn(vehicleSpawner, selectedSpawnColor)
end)

makeButton(vehicleScroll, "Abort Vehicle Spawner", function()
    abortSpawner = true
    spawnerStatus.SetActive(false, "Aborted.")
end)

-- Update player dropdowns on join/leave
Players.PlayerAdded:Connect(function()
    local n = getPlayerNames()
    vehTpPlayerDD:SetOptions(n)
    vehTpPlotDD:SetOptions(n)
end)
Players.PlayerRemoving:Connect(function()
    local n = getPlayerNames()
    vehTpPlayerDD:SetOptions(n)
    vehTpPlotDD:SetOptions(n)
end)

-- ── Cleanup ───────────────────────────────────────────────────────────────────

table.insert(VH.cleanupTasks, function()
    stopVehicleFly()
    abortSpawner = true
    if lassoConnection then lassoConnection:Disconnect() end
end)

print("[VanillaHub] Vanilla7 loaded. Tabs: Build, Vehicle.")
