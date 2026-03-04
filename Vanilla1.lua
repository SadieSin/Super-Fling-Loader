-- VanillaHub | Vanilla1 — Core GUI + Home + Player + Teleport + Item tabs
-- Run this FIRST. Creates _G.VH shared state and GUI scaffold.

if game.PlaceId ~= 13822889 then return end
if _G.VanillaHubCleanup then _G.VanillaHubCleanup() end

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RS           = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local char      = player.Character or player.CharacterAdded:Wait()
local mouse     = player:GetMouse()

-- ── shared global ──────────────────────────────────────────────────────────
_G.VH = {
    TweenService = TweenService,
    Players      = Players,
    UserInputService = UIS,
    RunService   = RunService,
    player       = player,
    cleanupTasks = {},
    pages        = {},
    tabs         = {},
    BTN_COLOR    = Color3.fromRGB(45,45,50),
    BTN_HOVER    = Color3.fromRGB(70,70,80),
    THEME_TEXT   = Color3.fromRGB(230,206,226),
    flyToggleEnabled  = false,
    isFlyEnabled      = false,
    currentFlyKey     = Enum.KeyCode.Q,
    waitingForFlyKey  = false,
    currentToggleKey  = Enum.KeyCode.LeftAlt,
    waitingForKeyGUI  = false,
    -- sprint state
    sprintEnabled     = true,
    baseWalkSpeed     = 16,
    sprintSpeed       = 65,
    -- misc toggles
    noclipEnabled     = false,
    infJumpEnabled    = false,
    antiAFKConn       = nil,
    lightPart         = nil,
    customDragger     = false,
    -- dragger connection
    draggerConn       = nil,
}

local VH = _G.VH
local BTN_COLOR  = VH.BTN_COLOR
local BTN_HOVER  = VH.BTN_HOVER
local THEME_TEXT = VH.THEME_TEXT

-- ── helpers ─────────────────────────────────────────────────────────────────
local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function addCleanup(fn) table.insert(VH.cleanupTasks, fn) end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner", parent); c.CornerRadius = UDim.new(0, radius or 6); return c
end

local function makePadding(parent, t, r, b, l)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop    = UDim.new(0, t or 6)
    p.PaddingRight  = UDim.new(0, r or 8)
    p.PaddingBottom = UDim.new(0, b or 6)
    p.PaddingLeft   = UDim.new(0, l or 8)
end

local function ripple(btn)
    local rip = Instance.new("ImageLabel", btn)
    rip.BackgroundTransparency = 1
    rip.Image = "rbxassetid://5028857084"
    rip.ImageColor3 = Color3.new(1,1,1)
    rip.ImageTransparency = 0.7
    rip.ScaleType = Enum.ScaleType.Slice
    rip.SliceCenter = Rect.new(24,24,276,276)
    rip.Size = UDim2.new(0,0,0,0)
    rip.Position = UDim2.new(0.5,0,0.5,0)
    rip.ZIndex = btn.ZIndex + 1
    tween(rip, 0.4, {Size=UDim2.new(2,0,2,0), Position=UDim2.new(-0.5,0,-0.5,0), ImageTransparency=1})
    game:GetService("Debris"):AddItem(rip, 0.45)
end

-- ── GUI scaffold ─────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VanillaHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")
addCleanup(function() screenGui:Destroy() end)

local main = Instance.new("Frame", screenGui)
main.Name = "Main"
main.Size = UDim2.new(0,520,0,340)
main.Position = UDim2.new(0.5,-260,0.5,-170)
main.BackgroundColor3 = Color3.fromRGB(18,18,24)
main.BorderSizePixel = 0
makeCorner(main, 10)

-- title bar
local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1,0,0,36)
titleBar.BackgroundColor3 = Color3.fromRGB(28,20,38)
titleBar.BorderSizePixel = 0
makeCorner(titleBar, 10)
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1,0,0.5,0)
titleFix.Position = UDim2.new(0,0,0.5,0)
titleFix.BackgroundColor3 = Color3.fromRGB(28,20,38)
titleFix.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1,-60,1,0)
titleLabel.Position = UDim2.new(0,12,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🍦 VanillaHub"
titleLabel.TextColor3 = THEME_TEXT
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0,28,0,22)
closeBtn.Position = UDim2.new(1,-32,0.5,-11)
closeBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
makeCorner(closeBtn, 5)
closeBtn.MouseButton1Click:Connect(function()
    if _G.VanillaHubCleanup then _G.VanillaHubCleanup() end
end)

-- sidebar
local sidebar = Instance.new("Frame", main)
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0,110,1,-36)
sidebar.Position = UDim2.new(0,0,0,36)
sidebar.BackgroundColor3 = Color3.fromRGB(22,16,30)
sidebar.BorderSizePixel = 0
makeCorner(sidebar, 8)
local sideList = Instance.new("UIListLayout", sidebar)
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Padding = UDim.new(0,2)
makePadding(sidebar, 6,4,6,4)

-- content area
local contentArea = Instance.new("Frame", main)
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1,-118,1,-44)
contentArea.Position = UDim2.new(0,114,0,40)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true

-- drag
do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position
            startPos = main.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- toggle visibility
local guiVisible = true
function VH.toggleGUI()
    guiVisible = not guiVisible
    tween(main, 0.2, {GroupTransparency = guiVisible and 0 or 1})
    main.Visible = guiVisible
end

-- ── tab system ───────────────────────────────────────────────────────────────
local currentTab = nil

local function makeTabBtn(name, icon)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1,0,0,28)
    btn.BackgroundColor3 = BTN_COLOR
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = (icon and icon.." " or "") .. name
    btn.TextColor3 = Color3.fromRGB(180,180,190)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    makePadding(btn, 4,4,4,8)
    makeCorner(btn, 5)
    btn.LayoutOrder = #VH.tabs + 1
    return btn
end

local function makeScrollPage()
    local scroll = Instance.new("ScrollingFrame", contentArea)
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(120,80,140)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Visible = false
    local list = Instance.new("UIListLayout", scroll)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0,6)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y+12)
    end)
    makePadding(scroll, 6,6,6,6)
    return scroll
end

local function switchTab(page, btn)
    if currentTab then
        currentTab[1].Visible = false
        tween(currentTab[2], 0.15, {BackgroundTransparency=0.3, TextColor3=Color3.fromRGB(180,180,190)})
    end
    page.Visible = true
    tween(btn, 0.15, {BackgroundTransparency=0, TextColor3=THEME_TEXT})
    currentTab = {page, btn}
end
VH.switchTab = switchTab

local function addTab(name, icon)
    local btn  = makeTabBtn(name, icon)
    local page = makeScrollPage()
    table.insert(VH.tabs, {btn=btn, page=page})
    btn.MouseButton1Click:Connect(function() ripple(btn); switchTab(page, btn) end)
    return page, btn
end

-- ── section + component builders ─────────────────────────────────────────────
local function addSection(page, title)
    local frame = Instance.new("Frame", page)
    frame.Size = UDim2.new(1,-4,0,0)
    frame.BackgroundColor3 = Color3.fromRGB(26,20,36)
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.Y
    makeCorner(frame, 7)
    local hdr = Instance.new("TextLabel", frame)
    hdr.Size = UDim2.new(1,0,0,22)
    hdr.BackgroundTransparency = 1
    hdr.Text = title
    hdr.TextColor3 = THEME_TEXT
    hdr.Font = Enum.Font.GothamBold
    hdr.TextSize = 11
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    makePadding(hdr, 4,0,0,10)
    local list = Instance.new("UIListLayout", frame)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0,4)
    local pad = Instance.new("UIPadding", frame)
    pad.PaddingTop    = UDim.new(0,26)
    pad.PaddingBottom = UDim.new(0,6)
    pad.PaddingLeft   = UDim.new(0,6)
    pad.PaddingRight  = UDim.new(0,6)
    frame.LayoutOrder = #page:GetChildren()
    return frame
end

local function addButton(section, text, color, callback)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", section)
    btn.Size = UDim2.new(1,0,0,26)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = THEME_TEXT
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.LayoutOrder = #section:GetChildren()
    makeCorner(btn, 5)
    btn.MouseEnter:Connect(function() tween(btn,0.12,{BackgroundColor3=BTN_HOVER}) end)
    btn.MouseLeave:Connect(function() tween(btn,0.12,{BackgroundColor3=color}) end)
    btn.MouseButton1Click:Connect(function() ripple(btn); task.spawn(callback) end)
    return btn
end

local function addToggle(section, text, default, callback)
    local row = Instance.new("Frame", section)
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = #section:GetChildren()
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-44,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = THEME_TEXT
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(0,36,0,18)
    track.Position = UDim2.new(1,-38,0.5,-9)
    track.BackgroundColor3 = default and Color3.fromRGB(60,180,60) or BTN_COLOR
    track.BorderSizePixel = 0
    makeCorner(track, 9)
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = default and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    makeCorner(knob, 7)
    local state = default
    local function setState(v)
        state = v
        tween(track, 0.2, {BackgroundColor3 = v and Color3.fromRGB(60,180,60) or BTN_COLOR})
        tween(knob,  0.2, {Position = v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)})
        task.spawn(callback, v)
    end
    if default then task.spawn(callback, true) end
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function() setState(not state) end)
    return {setState = setState, getValue = function() return state end}
end

local function addSlider(section, text, min, max, default, callback)
    local frame = Instance.new("Frame", section)
    frame.Size = UDim2.new(1,0,0,38)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = #section:GetChildren()
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,0,16)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = THEME_TEXT
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(0,46,0,16)
    valLbl.Position = UDim2.new(1,-46,0,0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = Color3.fromRGB(180,160,200)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 11
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1,0,0,6)
    track.Position = UDim2.new(0,0,0,22)
    track.BackgroundColor3 = Color3.fromRGB(40,40,55)
    track.BorderSizePixel = 0
    makeCorner(track, 3)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(130,80,160)
    fill.BorderSizePixel = 0
    makeCorner(fill, 3)
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0,12,0,12)
    knob.Position = UDim2.new((default-min)/(max-min),0,0.5,-6)
    knob.BackgroundColor3 = Color3.fromRGB(210,190,225)
    knob.BorderSizePixel = 0
    makeCorner(knob, 6)
    local dragging = false
    local function update(x)
        local abs = track.AbsolutePosition.X
        local w   = track.AbsoluteSize.X
        local pct = math.clamp((x - abs)/w, 0, 1)
        local val = math.floor(min + (max-min)*pct + 0.5)
        fill.Size = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,0,0.5,-6)
        valLbl.Text = tostring(val)
        task.spawn(callback, val)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; update(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    task.spawn(callback, default)
    return frame
end

local function addDropdown(section, text, options, callback)
    local frame = Instance.new("Frame", section)
    frame.Size = UDim2.new(1,0,0,26)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = #section:GetChildren()
    frame.ClipsDescendants = false
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.45,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = THEME_TEXT
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local header = Instance.new("TextButton", frame)
    header.Size = UDim2.new(0.52,0,1,0)
    header.Position = UDim2.new(0.48,0,0,0)
    header.BackgroundColor3 = BTN_COLOR
    header.BorderSizePixel = 0
    header.Text = options[1] or "Select..."
    header.TextColor3 = THEME_TEXT
    header.Font = Enum.Font.Gotham
    header.TextSize = 10
    makeCorner(header, 5)
    local open = false
    local listFrame = Instance.new("Frame", frame)
    listFrame.Size = UDim2.new(0.52,0,0,0)
    listFrame.Position = UDim2.new(0.48,0,1,2)
    listFrame.BackgroundColor3 = Color3.fromRGB(30,24,40)
    listFrame.BorderSizePixel = 0
    listFrame.ClipsDescendants = true
    listFrame.ZIndex = 10
    makeCorner(listFrame, 5)
    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local function setOptions(opts)
        for _, c in ipairs(listFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, opt in ipairs(opts) do
            local item = Instance.new("TextButton", listFrame)
            item.Size = UDim2.new(1,0,0,24)
            item.BackgroundTransparency = 1
            item.Text = opt
            item.TextColor3 = THEME_TEXT
            item.Font = Enum.Font.Gotham
            item.TextSize = 10
            item.ZIndex = 10
            item.LayoutOrder = i
            item.MouseButton1Click:Connect(function()
                header.Text = opt
                open = false
                tween(listFrame, 0.15, {Size=UDim2.new(0.52,0,0,0)})
                task.spawn(callback, opt)
            end)
        end
    end
    setOptions(options)
    header.MouseButton1Click:Connect(function()
        open = not open
        local h = open and math.min(#options,5)*24 or 0
        tween(listFrame, 0.2, {Size=UDim2.new(0.52,0,0,h)})
    end)
    return {setOptions = setOptions, getHeader = function() return header end}
end

local function addKeybindRow(section, text, default, callback)
    local row = Instance.new("Frame", section)
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = #section:GetChildren()
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-80,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = THEME_TEXT
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local kbtn = Instance.new("TextButton", row)
    kbtn.Size = UDim2.new(0,74,0,20)
    kbtn.Position = UDim2.new(1,-76,0.5,-10)
    kbtn.BackgroundColor3 = BTN_COLOR
    kbtn.Text = tostring(default):gsub("Enum%.KeyCode%.","")
    kbtn.TextColor3 = THEME_TEXT
    kbtn.Font = Enum.Font.Gotham
    kbtn.TextSize = 10
    makeCorner(kbtn, 4)
    local waiting = false
    kbtn.MouseButton1Click:Connect(function()
        waiting = true
        kbtn.Text = "..."
        kbtn.BackgroundColor3 = Color3.fromRGB(60,40,80)
    end)
    UIS.InputBegan:Connect(function(inp, gpe)
        if waiting and not gpe then
            waiting = false
            kbtn.Text = inp.KeyCode.Name
            kbtn.BackgroundColor3 = BTN_COLOR
            task.spawn(callback, inp.KeyCode)
        end
    end)
    return kbtn
end

-- ── PLAYER FUNCTIONS ──────────────────────────────────────────────────────────
local noclipConn, infJumpConn, walkConn

local function setWalkspeed(v)
    VH.baseWalkSpeed = v
    pcall(function() player.Character.Humanoid.WalkSpeed = v end)
    if not walkConn then
        walkConn = player.CharacterAdded:Connect(function(c)
            c:WaitForChild("Humanoid").WalkSpeed = VH.baseWalkSpeed
        end)
        addCleanup(function() if walkConn then walkConn:Disconnect() end end)
    end
end

local function setJumpPower(v)
    pcall(function() player.Character.Humanoid.JumpPower = v end)
end

local function setFOV(v)
    workspace.CurrentCamera.FieldOfView = v
end

local function startNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        pcall(function()
            for _, p in ipairs(player.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end)
    addCleanup(function() if noclipConn then noclipConn:Disconnect() end end)
end
local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    pcall(function()
        for _, p in ipairs(player.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end)
end

local function startInfJump()
    infJumpConn = UIS.JumpRequest:Connect(function()
        pcall(function()
            player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end)
    addCleanup(function() if infJumpConn then infJumpConn:Disconnect() end end)
end
local function stopInfJump()
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
end

-- Fly system
local flyBG, flyBV, flyConn
local flyCtrl = {f=0,b=0,l=0,r=0,u=0,d=0}
local lastFlyCtrl = {f=0,b=0,l=0,r=0,u=0,d=0}
local FLY_SPEED = 100

local function stopFly()
    VH.isFlyEnabled = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    pcall(function() player.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false end)
end

local function startFly()
    stopFly()
    VH.isFlyEnabled = true
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    flyBG = Instance.new("BodyGyro", hrp)
    flyBG.P = 9e4; flyBG.maxTorque = Vector3.new(9e9,9e9,9e9); flyBG.CFrame = hrp.CFrame
    flyBV = Instance.new("BodyVelocity", hrp)
    flyBV.MaxForce = Vector3.new(9e9,9e9,9e9); flyBV.Velocity = Vector3.new(0,0,0)
    flyConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            player.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
            local cam = workspace.CurrentCamera
            local cf  = cam.CoordinateFrame
            local fwd = (flyCtrl.f + flyCtrl.b)
            local side = (flyCtrl.l + flyCtrl.r)
            local up   = (flyCtrl.u + flyCtrl.d)
            local speed = FLY_SPEED
            if fwd ~= 0 or side ~= 0 or up ~= 0 then
                flyBV.Velocity = (cf.LookVector*fwd + cf.RightVector*side + Vector3.new(0,1,0)*up)*speed
                lastFlyCtrl = {f=fwd,b=0,l=side,r=0,u=up,d=0}
            else
                flyBV.Velocity = Vector3.new(0,0,0)
            end
            flyBG.CFrame = cf
        end)
    end)
    addCleanup(stopFly)
end

VH.startFly = startFly; VH.stopFly = stopFly

UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.W then flyCtrl.f = 1
    elseif inp.KeyCode == Enum.KeyCode.S then flyCtrl.b = -1
    elseif inp.KeyCode == Enum.KeyCode.A then flyCtrl.l = -1
    elseif inp.KeyCode == Enum.KeyCode.D then flyCtrl.r = 1
    elseif inp.KeyCode == Enum.KeyCode.Space then flyCtrl.u = 1
    elseif inp.KeyCode == Enum.KeyCode.LeftShift then flyCtrl.d = -1
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.W then flyCtrl.f = 0
    elseif inp.KeyCode == Enum.KeyCode.S then flyCtrl.b = 0
    elseif inp.KeyCode == Enum.KeyCode.A then flyCtrl.l = 0
    elseif inp.KeyCode == Enum.KeyCode.D then flyCtrl.r = 0
    elseif inp.KeyCode == Enum.KeyCode.Space then flyCtrl.u = 0
    elseif inp.KeyCode == Enum.KeyCode.LeftShift then flyCtrl.d = 0
    end
end)

-- Sprint system
local sprintBegin, sprintEnd
local function initSprint()
    sprintBegin = UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if not VH.sprintEnabled then return end
        if inp.KeyCode == Enum.KeyCode.LeftShift then
            pcall(function()
                if not player.PlayerGui.ItemDraggingGUI.CanRotate.Visible then
                    player.Character.Humanoid.WalkSpeed = VH.sprintSpeed
                end
            end)
        end
    end)
    sprintEnd = UIS.InputEnded:Connect(function(inp)
        if inp.KeyCode == Enum.KeyCode.LeftShift then
            pcall(function() player.Character.Humanoid.WalkSpeed = VH.baseWalkSpeed end)
        end
    end)
    addCleanup(function()
        if sprintBegin then sprintBegin:Disconnect() end
        if sprintEnd then sprintEnd:Disconnect() end
    end)
end
initSprint()

-- Anti AFK
local function setAntiAFK(v)
    if VH.antiAFKConn then VH.antiAFKConn:Disconnect(); VH.antiAFKConn = nil end
    if v then
        VH.antiAFKConn = Players.LocalPlayer.Idled:Connect(function()
            game:GetService("VirtualInputManager"):SendKeyEvent(true, "W", false, game)
            task.wait()
            game:GetService("VirtualInputManager"):SendKeyEvent(false, "W", false, game)
        end)
        addCleanup(function() if VH.antiAFKConn then VH.antiAFKConn:Disconnect() end end)
    end
end

-- Light toggle
local function setLight(v)
    pcall(function()
        local head = player.Character:FindFirstChild("Head")
        if v then
            if head and not head:FindFirstChild("VH_PointLight") then
                local pl = Instance.new("PointLight", head)
                pl.Name = "VH_PointLight"
                pl.Range = 100; pl.Brightness = 1; pl.Shadows = false
                VH.lightPart = pl
            end
        else
            local pl = head and head:FindFirstChild("VH_PointLight")
            if pl then pl:Destroy() end
            VH.lightPart = nil
        end
    end)
end

-- Safe Death — uses GodMode approach: teleport to lava region, die, respawn cleanly
local function safeDeath()
    task.spawn(function()
        pcall(function()
            local function getLava()
                for _, v in ipairs(workspace["Region_Volcano"]:GetChildren()) do
                    if v:FindFirstChild("Lava") then return v end
                end
            end
            local hrp = player.Character.HumanoidRootPart
            local lava = getLava()
            if not lava then return end
            workspace.Gravity = 100000
            hrp.CFrame = lava.Lava.CFrame
            workspace.Gravity = 196.2
        end)
    end)
end

-- Custom Dragger
local function initDragger()
    if VH.draggerConn then return end
    VH.draggerConn = workspace.ChildAdded:Connect(function(a)
        if a.Name == "Dragger" then
            local bp = a:WaitForChild("BodyPosition", 3)
            local bg = a:WaitForChild("BodyGyro", 3)
            if not bp or not bg then return end
            task.spawn(function()
                while a and a.Parent do
                    task.wait()
                    pcall(function()
                        if VH.customDragger then
                            bp.P = 120000; bp.D = 1000
                            bp.maxForce = Vector3.new(math.huge,math.huge,math.huge)
                            bg.maxTorque = Vector3.new(math.huge,math.huge,math.huge)
                        else
                            bp.P = 10000; bp.D = 800
                            bp.maxForce = Vector3.new(17000,17000,17000)
                            bg.maxTorque = Vector3.new(200,200,200)
                        end
                    end)
                end
            end)
        end
    end)
    addCleanup(function() if VH.draggerConn then VH.draggerConn:Disconnect() end end)
end
initDragger()

-- BTools
local function giveBTools()
    local plr = Players.LocalPlayer
    local del = Instance.new("Tool", plr.Backpack)
    del.Name = "Delete"; del.CanBeDropped = true; del.RequiresHandle = false
    local undo = Instance.new("Tool", plr.Backpack)
    undo.Name = "Undo"; undo.CanBeDropped = true; undo.RequiresHandle = false
    local edited, parents, positions = {}, {}, {}
    del.Activated:Connect(function()
        local tgt = mouse.Target
        if not tgt then return end
        table.insert(edited, tgt); table.insert(parents, tgt.Parent); table.insert(positions, tgt.CFrame)
        tgt.Parent = nil
    end)
    undo.Activated:Connect(function()
        if #edited == 0 then return end
        edited[#edited].Parent   = parents[#parents]
        edited[#edited].CFrame   = positions[#positions]
        table.remove(edited,#edited); table.remove(parents,#parents); table.remove(positions,#positions)
    end)
end

-- ── TELEPORT DATA ─────────────────────────────────────────────────────────────
local WAYPOINTS = {
    ["Spawn"]           = CFrame.new(172,2,74),
    ["Wood Dropoff"]    = CFrame.new(323.406,-2.8,134.734),
    ["Land Store"]      = CFrame.new(258,5,-99),
    ["Wood RUs"]        = CFrame.new(265,5,57),
    ["Safari"]          = CFrame.new(111.853,11,-998.805),
    ["Bridge"]          = CFrame.new(112.308,11,-782.358),
    ["Bob's Shack"]     = CFrame.new(260,8,-2542),
    ["EndTimes Cave"]   = CFrame.new(113,-214,-951),
    ["The Swamp"]       = CFrame.new(-1209,132,-801),
    ["The Cabin"]       = CFrame.new(1244,66,2306),
    ["Volcano"]         = CFrame.new(-1585,625,1140),
    ["Boxed Cars"]      = CFrame.new(509,5.2,-1463),
    ["Tiaga Peak"]      = CFrame.new(1560,410,3274),
    ["Link's Logic"]    = CFrame.new(4605,3,-727),
    ["Palm Island"]     = CFrame.new(2549,-5,-42),
    ["Palm Island 2"]   = CFrame.new(1960,-5.9,-1501),
    ["Palm Island 3"]   = CFrame.new(4344,-5.9,-1813),
    ["Fine Art Shop"]   = CFrame.new(5207,-166,719),
    ["SnowGlow Biome"]  = CFrame.new(-1086.85,-5.9,-945.316),
    ["Cave"]            = CFrame.new(3581,-179,430),
    ["Shrine Of Sight"] = CFrame.new(-1600,195,919),
    ["Fancy Furnishings"]= CFrame.new(491,13,-1720),
    ["Docks"]           = CFrame.new(1114,3.2,-197),
    ["Strange Man"]     = CFrame.new(1061,20,1131),
    ["Snow Biome"]      = CFrame.new(889.955,59.8,1195.55),
    ["Green Box"]       = CFrame.new(-1668.05,351.174,1475.39),
    ["Cherry Meadow"]   = CFrame.new(220.9,59.8,1305.8),
    ["Bird Cave"]       = CFrame.new(4813.1,33.5,-978.8),
    ["The Den"]         = CFrame.new(323,49,1930),
    ["Lighthouse"]      = CFrame.new(1464.8,356.3,3257.2),
}

-- ── ITEM SELECTION SYSTEM ────────────────────────────────────────────────────
local isItemTeleporting = false
local tpDestCFrame = nil
local tpDestPart = nil

local function isMoveableItem(model)
    if not model:IsA("Model") then return false end
    local hasOwner = model:FindFirstChild("Owner") ~= nil
    local hasBase  = model:FindFirstChild("Main") or model:FindFirstChild("BasePart")
    if not hasOwner or not hasBase then return false end
    local name = model.Name:lower()
    if string.find(name,"tree") or string.find(name,"terrain") then return false end
    return true
end

local function getModelPrimaryPart(model)
    return model:FindFirstChild("Main") or model:FindFirstChild("BasePart") or model.PrimaryPart
end

local function getSelectedItems()
    local items = {}
    for _, model in ipairs(workspace.PlayerModels:GetChildren()) do
        local mp = getModelPrimaryPart(model)
        if mp and mp:FindFirstChild("Selection") then
            table.insert(items, model)
        end
    end
    return items
end

local function clearAllSelections()
    for _, model in ipairs(workspace.PlayerModels:GetChildren()) do
        for _, part in ipairs(model:GetDescendants()) do
            if part.Name == "Selection" then part:Destroy() end
        end
    end
end

local function selectModel(model)
    local mp = getModelPrimaryPart(model)
    if not mp then return end
    if mp:FindFirstChild("Selection") then return end
    local box = Instance.new("SelectionBox", mp)
    box.Name = "Selection"
    box.Adornee = mp
    box.SurfaceTransparency = 0.5
    box.LineThickness = 0.09
    box.SurfaceColor3 = Color3.new(0,0,0)
    box.Color3 = Color3.fromRGB(0,172,240)
end

-- ── BUILD UI ──────────────────────────────────────────────────────────────────

-- ── HOME TAB ─────────────────────────────────────────────────────────────────
local homePage, homeBtn = addTab("Home", "🏠")
do
    local s = addSection(homePage, "About")
    local lbl = Instance.new("TextLabel", s)
    lbl.Size = UDim2.new(1,0,0,18)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🍦 VanillaHub — LT2 Script Suite"
    lbl.TextColor3 = THEME_TEXT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.LayoutOrder = 2

    local s2 = addSection(homePage, "GUI")
    addButton(s2, "Toggle GUI (LeftAlt)", Color3.fromRGB(50,40,70), function()
        VH.toggleGUI()
    end)
    addKeybindRow(s2, "Toggle Key", VH.currentToggleKey, function(key)
        VH.currentToggleKey = key
    end)
end

-- ── PLAYER TAB ───────────────────────────────────────────────────────────────
local playerPage, playerBtn = addTab("Player", "🧍")
do
    local mov = addSection(playerPage, "Movement")

    addSlider(mov, "Walkspeed", 16, 150, 16, function(v)
        VH.baseWalkSpeed = v
        setWalkspeed(v)
    end)

    addSlider(mov, "Sprint Speed (Shift)", 16, 250, 65, function(v)
        VH.sprintSpeed = v
    end)

    addSlider(mov, "Jump Power", 50, 300, 50, function(v)
        setJumpPower(v)
    end)

    addSlider(mov, "Flight Speed", 50, 500, 100, function(v)
        FLY_SPEED = v
    end)

    addSlider(mov, "FOV", 70, 120, 70, function(v)
        setFOV(v)
    end)

    addToggle(mov, "Sprint (hold Shift)", true, function(v)
        VH.sprintEnabled = v
    end)

    local flyToggle
    flyToggle = addToggle(mov, "Flight", false, function(v)
        VH.flyToggleEnabled = v
        if v then startFly() else stopFly() end
    end)

    addKeybindRow(mov, "Fly Keybind", Enum.KeyCode.Q, function(key)
        VH.currentFlyKey = key
        UIS.InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            if inp.KeyCode == VH.currentFlyKey and VH.flyToggleEnabled then
                if VH.isFlyEnabled then stopFly() else startFly() end
            end
        end)
    end)

    addToggle(mov, "Infinite Jump", false, function(v)
        if v then startInfJump() else stopInfJump() end
    end)

    addToggle(mov, "NoClip", false, function(v)
        if v then startNoclip() else stopNoclip() end
    end)

    -- Misc section
    local misc = addSection(playerPage, "Misc")

    addToggle(misc, "Anti AFK", false, function(v)
        setAntiAFK(v)
    end)

    addToggle(misc, "Light", false, function(v)
        setLight(v)
    end)

    addButton(misc, "Safe Death", Color3.fromRGB(90,35,35), function()
        safeDeath()
    end)

    addToggle(misc, "Custom Dragger", false, function(v)
        VH.customDragger = v
    end)

    addButton(misc, "BTools", Color3.fromRGB(35,55,100), function()
        giveBTools()
    end)
end

-- ── TELEPORT TAB ─────────────────────────────────────────────────────────────
local tpPage, tpBtn = addTab("Teleport", "📍")
do
    local sec = addSection(tpPage, "Waypoints")
    local waypointNames = {}
    for k in pairs(WAYPOINTS) do table.insert(waypointNames, k) end
    table.sort(waypointNames)
    for _, name in ipairs(waypointNames) do
        addButton(sec, name, BTN_COLOR, function()
            pcall(function()
                player.Character.HumanoidRootPart.CFrame = WAYPOINTS[name]
            end)
        end)
    end
end

-- ── ITEM TAB ─────────────────────────────────────────────────────────────────
local itemPage, itemBtn = addTab("Items", "📦")
do
    local sel = addSection(itemPage, "Selection")

    addToggle(sel, "Click Select", false, function(v)
        VH.clickSelectEnabled = v
        if v then
            VH.clickSelectConn = mouse.Button1Down:Connect(function()
                local model = mouse.Target and mouse.Target.Parent
                if model and isMoveableItem(model) then
                    selectModel(model)
                end
            end)
            addCleanup(function() if VH.clickSelectConn then VH.clickSelectConn:Disconnect() end end)
        else
            if VH.clickSelectConn then VH.clickSelectConn:Disconnect(); VH.clickSelectConn = nil end
        end
    end)

    addToggle(sel, "Group Select", false, function(v)
        VH.groupSelectEnabled = v
        if v then
            VH.groupSelectConn = mouse.Button1Down:Connect(function()
                local target = mouse.Target and mouse.Target.Parent
                if not target or not isMoveableItem(target) then return end
                local itemName = target:FindFirstChild("ItemName") and target.ItemName.Value
                    or target:FindFirstChild("PurchasedBoxItemName") and target.PurchasedBoxItemName.Value
                if not itemName then return end
                for _, model in ipairs(workspace.PlayerModels:GetChildren()) do
                    local n = (model:FindFirstChild("ItemName") and model.ItemName.Value)
                           or (model:FindFirstChild("PurchasedBoxItemName") and model.PurchasedBoxItemName.Value)
                    if n == itemName then selectModel(model) end
                end
            end)
            addCleanup(function() if VH.groupSelectConn then VH.groupSelectConn:Disconnect() end end)
        else
            if VH.groupSelectConn then VH.groupSelectConn:Disconnect(); VH.groupSelectConn = nil end
        end
    end)

    addButton(sel, "Deselect All", Color3.fromRGB(90,35,35), clearAllSelections)

    local tpSec = addSection(itemPage, "Teleport")

    addButton(tpSec, "Set Destination (Here)", Color3.fromRGB(35,55,100), function()
        pcall(function()
            if tpDestPart then tpDestPart:Destroy() end
            tpDestPart = Instance.new("Part", workspace)
            tpDestPart.Name = "VanillaHubTpCircle"
            tpDestPart.Anchored = true
            tpDestPart.CanCollide = false
            tpDestPart.Shape = Enum.PartType.Ball
            tpDestPart.Size = Vector3.new(3,3,3)
            tpDestPart.Material = Enum.Material.Neon
            tpDestPart.Color = Color3.fromRGB(130,80,200)
            tpDestPart.Transparency = 0.4
            tpDestPart.CFrame = player.Character.HumanoidRootPart.CFrame
            tpDestCFrame = tpDestPart.CFrame
        end)
    end)

    addButton(tpSec, "Teleport Selected Items", Color3.fromRGB(35,90,45), function()
        local dest = tpDestCFrame
        if not dest then return end
        local items = getSelectedItems()
        if #items == 0 then return end
        isItemTeleporting = true
        for _, model in ipairs(items) do
            if not isItemTeleporting then break end
            local mp = getModelPrimaryPart(model)
            if not mp then continue end
            pcall(function()
                player.Character.HumanoidRootPart.CFrame = mp.CFrame * CFrame.new(0,4,2)
                task.wait(0.08)
                RS.Interaction.ClientIsDragging:FireServer(model)
                task.wait(0.08)
                if not model.PrimaryPart then model.PrimaryPart = mp end
                model:SetPrimaryPartCFrame(dest)
                task.wait(0.08)
                RS.Interaction.ClientIsDragging:FireServer(model)
                task.wait(0.22)
            end)
        end
        isItemTeleporting = false
        clearAllSelections()
    end)

    addButton(tpSec, "Cancel Teleport", Color3.fromRGB(90,35,35), function()
        isItemTeleporting = false
    end)
end

-- ── activate first tab ───────────────────────────────────────────────────────
switchTab(homePage, homeBtn)

-- ── global keybind (toggle GUI) ───────────────────────────────────────────────
local toggleConn = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == VH.currentToggleKey then VH.toggleGUI() end
end)
addCleanup(function() toggleConn:Disconnect() end)

-- ── cleanup function ─────────────────────────────────────────────────────────
function _G.VanillaHubCleanup()
    stopFly()
    stopNoclip()
    stopInfJump()
    pcall(function()
        player.Character.Humanoid.WalkSpeed = 16
        player.Character.Humanoid.JumpPower = 50
    end)
    for _, fn in ipairs(VH.cleanupTasks) do pcall(fn) end
    VH.cleanupTasks = {}
    if screenGui and screenGui.Parent then screenGui:Destroy() end
    _G.VH = nil
end

print("[VanillaHub] Vanilla1 loaded ✓")
