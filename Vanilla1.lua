-- DESTROY OLD GUI + cleanup (also kills all active connections from a previous run)
if type(_G.VanillaHubCleanup) == "function" then
    pcall(_G.VanillaHubCleanup)
    _G.VanillaHubCleanup = nil
end

-- Nuke leftover GUIs
for _, name in pairs({"VanillaHub", "VanillaHubWarning"}) do
    if game.CoreGui:FindFirstChild(name) then
        game.CoreGui[name]:Destroy()
    end
end

-- Nuke leftover _G.VH table completely
if _G.VH then
    -- Cancel any running dupe thread
    if _G.VH.butter and _G.VH.butter.running then
        _G.VH.butter.running = false
        if _G.VH.butter.thread then pcall(task.cancel, _G.VH.butter.thread) end
        _G.VH.butter.thread = nil
    end
    _G.VH = nil
end

-- Nuke leftover workspace markers
if workspace:FindFirstChild("VanillaHubTpCircle") then
    workspace.VanillaHubTpCircle:Destroy()
end

-- Only Lumber Tycoon 2
if game.PlaceId ~= 13822889 then
    task.spawn(function()
        task.wait(0.4)
        local warnGui = Instance.new("ScreenGui")
        warnGui.Name = "VanillaHubWarning"
        warnGui.Parent = game.CoreGui
        warnGui.ResetOnSpawn = false
        local frame = Instance.new("Frame", warnGui)
        frame.Size = UDim2.new(0, 400, 0, 220)
        frame.Position = UDim2.new(0.5, -200, 0.5, -110)
        frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        frame.BackgroundTransparency = 0.25
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
        local uiStroke = Instance.new("UIStroke", frame)
        uiStroke.Color = Color3.fromRGB(190, 50, 50)
        uiStroke.Thickness = 1.5
        uiStroke.Transparency = 0.45
        local icon = Instance.new("TextLabel", frame)
        icon.Size = UDim2.new(0, 48, 0, 48)
        icon.Position = UDim2.new(0, 24, 0, 24)
        icon.BackgroundTransparency = 1
        icon.Font = Enum.Font.GothamBlack
        icon.TextSize = 42
        icon.TextColor3 = Color3.fromRGB(255, 90, 90)
        icon.Text = "!"
        local msg = Instance.new("TextLabel", frame)
        msg.Size = UDim2.new(1, -100, 0, 120)
        msg.Position = UDim2.new(0, 90, 0, 30)
        msg.BackgroundTransparency = 1
        msg.Font = Enum.Font.GothamSemibold
        msg.TextSize = 15
        msg.TextColor3 = Color3.fromRGB(225, 225, 225)
        msg.TextXAlignment = Enum.TextXAlignment.Left
        msg.TextYAlignment = Enum.TextYAlignment.Top
        msg.TextWrapped = true
        msg.Text = "VanillaHub is made exclusively for Lumber Tycoon 2 (Place ID: 13822889).\n\nPlease join Lumber Tycoon 2 and re-execute the script there."
        local okBtn = Instance.new("TextButton", frame)
        okBtn.Size = UDim2.new(0, 160, 0, 50)
        okBtn.Position = UDim2.new(0.5, -80, 1, -70)
        okBtn.BackgroundColor3 = Color3.fromRGB(190, 50, 50)
        okBtn.BorderSizePixel = 0
        okBtn.Font = Enum.Font.GothamBold
        okBtn.TextSize = 17
        okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        okBtn.Text = "I Understand"
        Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 12)
        local TS2 = game:GetService("TweenService")
        frame.BackgroundTransparency = 1; msg.TextTransparency = 1; icon.TextTransparency = 1
        okBtn.BackgroundTransparency = 1; okBtn.TextTransparency = 1
        TS2:Create(frame, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.25}):Play()
        TS2:Create(msg,   TweenInfo.new(0.85, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        TS2:Create(icon,  TweenInfo.new(0.85, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        TS2:Create(okBtn, TweenInfo.new(0.95, Enum.EasingStyle.Quint), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        okBtn.MouseButton1Click:Connect(function()
            local outTween = TS2:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
            outTween:Play()
            TS2:Create(msg,   TweenInfo.new(0.8), {TextTransparency = 1}):Play()
            TS2:Create(icon,  TweenInfo.new(0.8), {TextTransparency = 1}):Play()
            TS2:Create(okBtn, TweenInfo.new(0.8), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
            outTween.Completed:Connect(function() if warnGui and warnGui.Parent then warnGui:Destroy() end end)
        end)
    end)
    return
end

-- ════════════════════════════════════════════════════
-- SERVICES & PLAYER
-- ════════════════════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")
local Stats            = game:GetService("Stats")
local player           = Players.LocalPlayer

-- ════════════════════════════════════════════════════
-- CLEANUP REGISTRY
-- ════════════════════════════════════════════════════
local cleanupTasks = {}
local butterRunning = false
local butterThread  = nil

local function onExit()
    -- Stop dupe if running
    butterRunning = false
    if butterThread then pcall(task.cancel, butterThread); butterThread = nil end

    -- Cancel butter via _G.VH if Vanilla2 set it
    if _G.VH and _G.VH.butter then
        _G.VH.butter.running = false
        if _G.VH.butter.thread then
            pcall(task.cancel, _G.VH.butter.thread)
            _G.VH.butter.thread = nil
        end
    end

    -- Run all registered cleanup functions
    for _, fn in ipairs(cleanupTasks) do
        pcall(fn)
    end
    cleanupTasks = {}

    -- Hard-restore humanoid state
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        local char = lp and lp.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.PlatformStand = false
            hum.WalkSpeed     = 16
            hum.JumpPower     = 50
        end
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end)

    -- Destroy teleport circle marker if it survived
    pcall(function()
        if workspace:FindFirstChild("VanillaHubTpCircle") then
            workspace.VanillaHubTpCircle:Destroy()
        end
    end)

    -- Nuke walk-on-water planes left by Vanilla2
    pcall(function()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "WalkWaterPlane" then obj:Destroy() end
        end
    end)

    -- Nuke the shared globals table so Vanilla2/3 can't fire stale references
    _G.VH = nil
    _G.VanillaHubCleanup = nil
end

-- ════════════════════════════════════════════════════
-- GUI SCAFFOLD
-- ════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "VanillaHub"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
table.insert(cleanupTasks, function()
    if gui and gui.Parent then gui:Destroy() end
end)

-- Register cleanup in _G immediately so a second execute can kill this run
_G.VanillaHubCleanup = onExit

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 0, 0, 0)
main.Position = UDim2.new(0.5, -260, 0.5, -170)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

TweenService:Create(main, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 520, 0, 340),
    BackgroundTransparency = 0
}):Play()

-- TOP BAR
local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topBar.BorderSizePixel = 0

local hubIcon = Instance.new("ImageLabel", topBar)
hubIcon.Size               = UDim2.new(0, 30, 0, 30)
hubIcon.Position           = UDim2.new(0, 6, 0.5, -15)
hubIcon.BackgroundTransparency = 1
hubIcon.BorderSizePixel    = 0
hubIcon.ScaleType          = Enum.ScaleType.Fit
hubIcon.Image = "rbxassetid://91848271495779"
Instance.new("UICorner", hubIcon).CornerRadius = UDim.new(0, 5)

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(1, -90, 1, 0)
titleLbl.Position = UDim2.new(0, 42, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "VanillaHub"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 17
titleLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -38, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- CONFIRM CLOSE DIALOG
local function showConfirmClose()
    if main:FindFirstChild("ConfirmOverlay") then return end
    local overlay = Instance.new("Frame", main)
    overlay.Name = "ConfirmOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.ZIndex = 9
    local dialog = Instance.new("Frame", main)
    dialog.Name = "ConfirmDialog"
    dialog.Size = UDim2.new(0, 360, 0, 180)
    dialog.Position = UDim2.new(0.5, -180, 0.5, -90)
    dialog.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 10
    Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 14)
    local dStroke = Instance.new("UIStroke", dialog)
    dStroke.Color = Color3.fromRGB(90, 90, 100)
    dStroke.Thickness = 1.2
    dStroke.Transparency = 0.6
    local dtitle = Instance.new("TextLabel", dialog)
    dtitle.Size = UDim2.new(1, 0, 0, 40)
    dtitle.BackgroundTransparency = 1
    dtitle.Font = Enum.Font.GothamBold
    dtitle.TextSize = 19
    dtitle.TextColor3 = Color3.fromRGB(230, 230, 230)
    dtitle.Text = "Confirm Exit"
    dtitle.ZIndex = 11
    local dmsg = Instance.new("TextLabel", dialog)
    dmsg.Size = UDim2.new(1, -40, 0, 60)
    dmsg.Position = UDim2.new(0, 20, 0, 45)
    dmsg.BackgroundTransparency = 1
    dmsg.Font = Enum.Font.Gotham
    dmsg.TextSize = 15
    dmsg.TextColor3 = Color3.fromRGB(200, 200, 210)
    dmsg.Text = "Are you sure you want to close VanillaHub?\n\nYou will need to re-execute the script to use it again."
    dmsg.TextWrapped = true
    dmsg.TextYAlignment = Enum.TextYAlignment.Center
    dmsg.ZIndex = 11
    local cancelBtn2 = Instance.new("TextButton", dialog)
    cancelBtn2.Size = UDim2.new(0, 150, 0, 46)
    cancelBtn2.Position = UDim2.new(0.5, -160, 1, -65)
    cancelBtn2.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    cancelBtn2.Text = "Cancel"
    cancelBtn2.Font = Enum.Font.GothamSemibold
    cancelBtn2.TextSize = 16
    cancelBtn2.TextColor3 = Color3.fromRGB(210, 210, 220)
    cancelBtn2.ZIndex = 11
    Instance.new("UICorner", cancelBtn2).CornerRadius = UDim.new(0, 10)
    local confirmBtn2 = Instance.new("TextButton", dialog)
    confirmBtn2.Size = UDim2.new(0, 150, 0, 46)
    confirmBtn2.Position = UDim2.new(0.5, 10, 1, -65)
    confirmBtn2.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
    confirmBtn2.Text = "Exit VanillaHub"
    confirmBtn2.Font = Enum.Font.GothamSemibold
    confirmBtn2.TextSize = 16
    confirmBtn2.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn2.ZIndex = 11
    Instance.new("UICorner", confirmBtn2).CornerRadius = UDim.new(0, 10)
    for _, b in {cancelBtn2, confirmBtn2} do
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (b == confirmBtn2) and Color3.fromRGB(210, 60, 60) or Color3.fromRGB(70, 70, 80)
            }):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (b == confirmBtn2) and Color3.fromRGB(180, 45, 45) or Color3.fromRGB(45, 45, 50)
            }):Play()
        end)
    end
    cancelBtn2.MouseButton1Click:Connect(function() overlay:Destroy(); dialog:Destroy() end)
    confirmBtn2.MouseButton1Click:Connect(function()
        overlay:Destroy(); dialog:Destroy()
        -- Full cleanup first (stops fly, noclip, dupe, clears _G.VH, etc.)
        onExit()
        -- Animate GUI out then destroy it
        local t = TweenService:Create(main, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        })
        t:Play()
        t.Completed:Connect(function()
            if gui and gui.Parent then gui:Destroy() end
        end)
    end)
end

closeBtn.MouseButton1Click:Connect(showConfirmClose)

-- DRAG
local dragging, dragStart, startPos = false, nil, nil
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- SIDE PANEL
local side = Instance.new("ScrollingFrame", main)
side.Size = UDim2.new(0, 160, 1, -38)
side.Position = UDim2.new(0, 0, 0, 38)
side.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
side.BorderSizePixel = 0
side.ScrollBarThickness = 4
side.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
side.CanvasSize = UDim2.new(0, 0, 0, 0)
local sideLayout = Instance.new("UIListLayout", side)
sideLayout.Padding = UDim.new(0, 8)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    side.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y + 24)
end)

-- CONTENT AREA
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -160, 1, -38)
content.Position = UDim2.new(0, 160, 0, 38)
content.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
content.BorderSizePixel = 0

-- WELCOME POPUP
task.spawn(function()
    task.wait(0.8)
    if not (gui and gui.Parent) then return end
    local wf = Instance.new("Frame", gui)
    wf.Size = UDim2.new(0, 380, 0, 90)
    wf.Position = UDim2.new(0.5, -190, 1, -110)
    wf.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    wf.BackgroundTransparency = 1
    wf.BorderSizePixel = 0
    Instance.new("UICorner", wf).CornerRadius = UDim.new(0, 14)
    local ws = Instance.new("UIStroke", wf)
    ws.Color = Color3.fromRGB(35, 35, 35); ws.Thickness = 1.2; ws.Transparency = 0.6
    local pfp = Instance.new("ImageLabel", wf)
    pfp.Size = UDim2.new(0, 64, 0, 64)
    pfp.Position = UDim2.new(0, 20, 0.5, -32)
    pfp.BackgroundTransparency = 1
    pfp.ImageTransparency = 1
    pfp.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    Instance.new("UICorner", pfp).CornerRadius = UDim.new(1, 0)
    local wt = Instance.new("TextLabel", wf)
    wt.Size = UDim2.new(1, -110, 1, -20)
    wt.Position = UDim2.new(0, 100, 0, 10)
    wt.BackgroundTransparency = 1
    wt.Font = Enum.Font.GothamSemibold; wt.TextSize = 18
    wt.TextColor3 = Color3.fromRGB(220, 220, 220)
    wt.TextXAlignment = Enum.TextXAlignment.Left
    wt.TextYAlignment = Enum.TextYAlignment.Center
    wt.TextWrapped = true; wt.TextTransparency = 1
    wt.Text = "Welcome back,\n" .. player.DisplayName
    TweenService:Create(wf, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.35}):Play()
    TweenService:Create(wt, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
    TweenService:Create(pfp, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
    task.delay(7, function()
        if not (wf and wf.Parent) then return end
        local ot = TweenService:Create(wf, TweenInfo.new(1.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
        ot:Play()
        TweenService:Create(wt, TweenInfo.new(1.2), {TextTransparency = 1}):Play()
        TweenService:Create(pfp, TweenInfo.new(1.2), {ImageTransparency = 1}):Play()
        ot.Completed:Connect(function() if wf and wf.Parent then wf:Destroy() end end)
    end)
end)

-- ════════════════════════════════════════════════════
-- TABS
-- ════════════════════════════════════════════════════
local tabs = {"Home","Player","World","Teleport","Wood","Slot","Dupe","Item","Sorter","AutoBuy","Build","Vehicle","Search","Settings"}
local pages = {}

for _, name in ipairs(tabs) do
    local page = Instance.new("ScrollingFrame", content)
    page.Name = name .. "Tab"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 12)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 16); pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 40)
    end)
    pages[name .. "Tab"] = page
end

-- TAB SWITCHING
local activeTabButton = nil
local function switchTab(targetName)
    for _, page in pairs(pages) do page.Visible = (page.Name == targetName) end
    if activeTabButton then
        TweenService:Create(activeTabButton, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(18,18,18),
            TextColor3 = Color3.fromRGB(160,160,160)
        }):Play()
    end
    local btn = side:FindFirstChild(targetName:gsub("Tab",""))
    if btn then
        activeTabButton = btn
        TweenService:Create(btn, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(40,40,40),
            TextColor3 = Color3.fromRGB(255,255,255)
        }):Play()
    end
end

for _, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", side)
    btn.Name = name
    btn.Size = UDim2.new(0.92, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(18,18,18)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(160,160,160)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 16)
    btn.MouseEnter:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28,28,28), TextColor3 = Color3.fromRGB(220,220,220)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(18,18,18), TextColor3 = Color3.fromRGB(160,160,160)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(name.."Tab") end)
end

switchTab("HomeTab")

-- ════════════════════════════════════════════════════
-- GUI TOGGLE
-- ════════════════════════════════════════════════════
local currentToggleKey = Enum.KeyCode.LeftAlt
local waitingForKeyGUI = false
local guiOpen = true
local isAnimatingGUI = false
local keybindButtonGUI

local function toggleGUI()
    if isAnimatingGUI then return end
    guiOpen = not guiOpen
    isAnimatingGUI = true
    if guiOpen then
        main.Visible = true
        main.Size = UDim2.new(0,0,0,0)
        main.BackgroundTransparency = 1
        local t = TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0,520,0,340), BackgroundTransparency = 0
        })
        t:Play()
        t.Completed:Connect(function() isAnimatingGUI = false end)
    else
        local t = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1
        })
        t:Play()
        t.Completed:Connect(function() main.Visible = false; isAnimatingGUI = false end)
    end
end

-- ════════════════════════════════════════════════════
-- HOME TAB
-- ════════════════════════════════════════════════════
local homePage = pages["HomeTab"]
local welcomeCard = Instance.new("Frame", homePage)
welcomeCard.Size = UDim2.new(1, 0, 0, 110)
welcomeCard.BackgroundColor3 = Color3.fromRGB(18,18,18)
welcomeCard.BorderSizePixel = 0
Instance.new("UICorner", welcomeCard).CornerRadius = UDim.new(0, 10)
local pfpCard = Instance.new("ImageLabel", welcomeCard)
pfpCard.Size = UDim2.new(0,64,0,64)
pfpCard.Position = UDim2.new(0,16,0.5,-32)
pfpCard.BackgroundTransparency = 1
pfpCard.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
Instance.new("UICorner", pfpCard).CornerRadius = UDim.new(1,0)
local textArea = Instance.new("Frame", welcomeCard)
textArea.Size = UDim2.new(1,-100,1,0)
textArea.Position = UDim2.new(0,90,0,0)
textArea.BackgroundTransparency = 1
local greeting = Instance.new("TextLabel", textArea)
greeting.Size = UDim2.new(1,0,0,30); greeting.Position = UDim2.new(0,0,0,12)
greeting.BackgroundTransparency = 1; greeting.Font = Enum.Font.GothamBold; greeting.TextSize = 22
greeting.TextColor3 = Color3.fromRGB(200,60,60); greeting.TextXAlignment = Enum.TextXAlignment.Left
greeting.Text = "Hey " .. player.DisplayName .. "!"
local usernameLabel = Instance.new("TextLabel", textArea)
usernameLabel.Size = UDim2.new(1,0,0,20); usernameLabel.Position = UDim2.new(0,0,0,42)
usernameLabel.BackgroundTransparency = 1; usernameLabel.Font = Enum.Font.Gotham; usernameLabel.TextSize = 14
usernameLabel.TextColor3 = Color3.fromRGB(160,160,180); usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
usernameLabel.Text = "@" .. player.Name
local message = Instance.new("TextLabel", textArea)
message.Size = UDim2.new(1,0,0,36); message.Position = UDim2.new(0,0,0,64)
message.BackgroundTransparency = 1; message.Font = Enum.Font.Gotham; message.TextSize = 13
message.TextColor3 = Color3.fromRGB(190,190,210); message.TextXAlignment = Enum.TextXAlignment.Left
message.TextYAlignment = Enum.TextYAlignment.Top; message.TextWrapped = true
message.Text = "Welcome back to VanillaHub!\nEnjoy your time here 🌸"

local statsContainer = Instance.new("Frame", homePage)
statsContainer.Size = UDim2.new(1, 0, 0, 160)
statsContainer.BackgroundTransparency = 1
local gridLayout = Instance.new("UIGridLayout", statsContainer)
gridLayout.CellSize = UDim2.new(0,148,0,42)
gridLayout.CellPadding = UDim2.new(0,12,0,12)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createStatusBox(text, color)
    local box = Instance.new("Frame", statsContainer)
    box.BackgroundColor3 = Color3.fromRGB(22,22,28); box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", box)
    lbl.Size = UDim2.new(1,-8,1,-4); lbl.Position = UDim2.new(0,4,0,2)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.TextColor3 = color or Color3.fromRGB(180,180,200)
    lbl.Text = text; lbl.TextWrapped = true; lbl.TextXAlignment = Enum.TextXAlignment.Center
    return lbl
end

local pingLabel = createStatusBox("Ping: calculating...")
createStatusBox("Lag detected: No", Color3.fromRGB(100,200,100))
createStatusBox("Account age: " .. player.AccountAge .. " days")
createStatusBox("Executor: Unknown / Custom")

local rejoinBtn = Instance.new("TextButton", statsContainer)
rejoinBtn.Size = UDim2.new(0,148,0,42)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(22,22,28); rejoinBtn.BorderSizePixel = 0
rejoinBtn.Font = Enum.Font.Gotham; rejoinBtn.TextSize = 14
rejoinBtn.TextColor3 = Color3.fromRGB(180,180,200); rejoinBtn.Text = "Rejoin"
Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 8)
rejoinBtn.MouseEnter:Connect(function()
    TweenService:Create(rejoinBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(35,35,45), TextColor3 = Color3.fromRGB(210,210,230)}):Play()
end)
rejoinBtn.MouseLeave:Connect(function()
    TweenService:Create(rejoinBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(22,22,28), TextColor3 = Color3.fromRGB(180,180,200)}):Play()
end)
rejoinBtn.MouseButton1Click:Connect(function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end)

local pingConn = RunService.Heartbeat:Connect(function()
    local ok, ping = pcall(function() return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    pingLabel.Text = ok and ("Ping: " .. ping .. " ms") or "Ping: N/A"
end)
table.insert(cleanupTasks, function()
    if pingConn then pingConn:Disconnect(); pingConn = nil end
end)

-- ════════════════════════════════════════════════════
-- TELEPORT TAB
-- ════════════════════════════════════════════════════
local teleportPage = pages["TeleportTab"]
local tpHeader = Instance.new("TextLabel", teleportPage)
tpHeader.Size = UDim2.new(1,-12,0,28); tpHeader.BackgroundTransparency = 1
tpHeader.Font = Enum.Font.GothamBold; tpHeader.TextSize = 14
tpHeader.TextColor3 = Color3.fromRGB(180,180,200); tpHeader.TextXAlignment = Enum.TextXAlignment.Left
tpHeader.Text = "Quick Teleport Locations"

local locations = {
    {name="Spawn",x=172,y=3,z=74},{name="The Den",x=323,y=41.8,z=1930},
    {name="LightHouse",x=1464.8,y=355.25,z=3257.2},{name="Safari",x=111.85,y=11,z=-998.8},
    {name="Bridge",x=112.31,y=11,z=-782.36},{name="Bob's Shack",x=260,y=8.4,z=-2542},
    {name="EndTimesCave",x=113,y=-213,z=-951},{name="The Swamp",x=-1209,y=132.32,z=-801},
    {name="The Cabin",x=1244,y=63.6,z=2306},{name="Volcano",x=-1585,y=622.8,z=1140},
    {name="Boxed Cars",x=509,y=3.2,z=-1463},{name="Tiaga Peak",x=1560,y=410.32,z=3274},
    {name="Land Store",x=258,y=3.2,z=-99},{name="Link's Logic",x=4605,y=3,z=-727},
    {name="Palm Island",x=2549,y=-5.9,z=-42},{name="Palm Island 2",x=1960,y=-5.9,z=-1501},
    {name="Palm Island 3",x=4344,y=-5.9,z=-1813},{name="Fine Art Shop",x=5207,y=-166.2,z=719},
    {name="SnowGlow Biome",x=-1086.85,y=-5.9,z=-945.32},{name="Cave",x=3581,y=-179.54,z=430},
    {name="Shrine Of Sight",x=-1600,y=195.4,z=919},{name="Fancy Furnishings",x=491,y=3.2,z=-1720},
    {name="Docks",x=1114,y=-1.2,z=-197},{name="Strange Man",x=1061,y=16.8,z=1131},
    {name="Wood Dropoff",x=323.41,y=-2.8,z=134.73},{name="Snow Biome",x=889.96,y=59.8,z=1195.55},
    {name="Wood RU's",x=265,y=3.2,z=57},{name="Green Box",x=-1668.05,y=349.6,z=1475.39},
    {name="Cherry Meadow",x=220.9,y=59.8,z=1305.8},{name="Bird Cave",x=4813.1,y=17.7,z=-978.8},
}

for _, loc in ipairs(locations) do
    local btn = Instance.new("TextButton", teleportPage)
    btn.Size = UDim2.new(1,-12,0,36); btn.BackgroundColor3 = Color3.fromRGB(20,20,26)
    btn.BorderSizePixel = 0; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(220,220,220); btn.Text = loc.name
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(38,38,50), TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20,20,26), TextColor3 = Color3.fromRGB(220,220,220)}):Play() end)
    btn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(loc.x, loc.y + 3, loc.z)
        end
    end)
end

-- ════════════════════════════════════════════════════
-- ITEM TAB
-- ════════════════════════════════════════════════════
local itemPage = pages["ItemTab"]
local itemList = itemPage:FindFirstChildOfClass("UIListLayout")
if itemList then itemList.Padding = UDim.new(0, 6) end

local BTN_COLOR = Color3.fromRGB(45, 45, 50)
local BTN_HOVER = Color3.fromRGB(70, 70, 80)

local clickSelection = false
local lassoTool = false
local groupSelection = false
local selectedItems = {}
local tpCircle = nil
local isItemTeleporting = false
local tpProgressContainer = nil
local tpProgressFill = nil
local tpProgressLabel = nil

local function createSectionLabel(text)
    local lbl = Instance.new("TextLabel", itemPage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    local pad = Instance.new("UIPadding", lbl); pad.PaddingLeft = UDim.new(0, 4)
end

local function createSep()
    local sep = Instance.new("Frame", itemPage)
    sep.Size = UDim2.new(1,-12,0,1); sep.BackgroundColor3 = Color3.fromRGB(40,40,55); sep.BorderSizePixel = 0
end

local function createItemButton(text, callback)
    local btn = Instance.new("TextButton", itemPage)
    btn.Size = UDim2.new(1,-12,0,32); btn.BackgroundColor3 = BTN_COLOR
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(210,210,220)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createItemToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", itemPage)
    frame.Size = UDim2.new(1,-12,0,32); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.TextXAlignment = Enum.TextXAlignment.Left
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

createSectionLabel("Selection Mode")
createItemToggle("Click Selection", false, function(val) clickSelection = val; if val then lassoTool = false end end)
createItemToggle("Lasso Tool", false, function(val) lassoTool = val; if val then clickSelection = false end end)
createItemToggle("Group Selection", false, function(val) groupSelection = val end)
createSep()

local function getOwner(model)
    local ov = model:FindFirstChild("Owner")
    if ov then
        if ov:IsA("ObjectValue") then return ov.Value
        elseif ov:IsA("StringValue") then return ov.Value end
    end
    return nil
end

local function getItemCategory(model)
    local iv = model:FindFirstChild("ItemName")
    if iv and iv:IsA("StringValue") then return iv.Value end
    return model.Name
end

local function isMoveableItem(model)
    local mp = model.PrimaryPart or model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
    if not mp then return false end
    if model == workspace then return false end
    local staticNames = {
        Map=true,Terrain=true,Camera=true,Baseplate=true,Base=true,Ground=true,
        Land=true,Island=true,Water=true,Tree=true,Palm=true,Bush=true,Rock=true,
        Stump=true,Branch=true,Log=true,PalmTree=true,CypressTree=true,SpruceTree=true,
        ElmTree=true,ChestnutTree=true,CherryTree=true,OakTree=true,BirchTree=true,
        Fence=true,Road=true,Path=true,River=true,Cliff=true,Hill=true,Bridge=true,
    }
    if staticNames[model.Name] then return false end
    local hasOwner = model:FindFirstChild("Owner") ~= nil
    if not hasOwner then
        local hasItemName = model:FindFirstChild("ItemName") ~= nil
        if not hasItemName then return false end
    end
    return true
end

local function highlightModel(model)
    if selectedItems[model] then return end
    local hl = Instance.new("SelectionBox")
    hl.Color3 = Color3.fromRGB(0,170,255); hl.LineThickness = 0.05
    hl.Adornee = model; hl.Parent = model
    selectedItems[model] = hl
end

local function unhighlightModel(model)
    if selectedItems[model] then selectedItems[model]:Destroy(); selectedItems[model] = nil end
end

local function unhighlightAll()
    for model, hl in pairs(selectedItems) do
        if hl and hl.Parent then hl:Destroy() end
    end
    selectedItems = {}
end

local function handleSelection(target, forceSelect)
    if not target then return end
    local model = target:FindFirstAncestorOfClass("Model")
    if not (model and isMoveableItem(model)) then return end
    if groupSelection then
        local ownerVal = getOwner(model)
        local cat = getItemCategory(model)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isMoveableItem(obj) then
                local objCat = getItemCategory(obj)
                if objCat == cat then
                    local objOwner = getOwner(obj)
                    local ownerMatch = true
                    if ownerVal ~= nil and objOwner ~= nil then
                        ownerMatch = tostring(ownerVal) == tostring(objOwner)
                    end
                    if ownerMatch then highlightModel(obj) end
                end
            end
        end
    else
        if forceSelect then
            highlightModel(model)
        else
            if selectedItems[model] then unhighlightModel(model) else highlightModel(model) end
        end
    end
end

createSectionLabel("Item Teleport Destination")

local tpRow = Instance.new("Frame", itemPage)
tpRow.Size = UDim2.new(1,-12,0,32); tpRow.BackgroundTransparency = 1

local tpSet = Instance.new("TextButton", tpRow)
tpSet.Size = UDim2.new(0.5,-4,1,0); tpSet.Position = UDim2.new(0,0,0,0)
tpSet.BackgroundColor3 = BTN_COLOR; tpSet.Font = Enum.Font.GothamSemibold
tpSet.TextSize = 12; tpSet.TextColor3 = Color3.fromRGB(210,210,220); tpSet.Text = "Set Destination"
Instance.new("UICorner", tpSet).CornerRadius = UDim.new(0, 6)

local tpRemove = Instance.new("TextButton", tpRow)
tpRemove.Size = UDim2.new(0.5,-4,1,0); tpRemove.Position = UDim2.new(0.5,4,0,0)
tpRemove.BackgroundColor3 = BTN_COLOR; tpRemove.Font = Enum.Font.GothamSemibold
tpRemove.TextSize = 12; tpRemove.TextColor3 = Color3.fromRGB(210,210,220); tpRemove.Text = "Remove Destination"
Instance.new("UICorner", tpRemove).CornerRadius = UDim.new(0, 6)

for _, b in {tpSet, tpRemove} do
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
end

tpSet.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy() end
    tpCircle = Instance.new("Part")
    tpCircle.Name = "VanillaHubTpCircle"
    tpCircle.Shape = Enum.PartType.Ball
    tpCircle.Size = Vector3.new(3,3,3)
    tpCircle.Material = Enum.Material.SmoothPlastic
    tpCircle.Color = Color3.fromRGB(120,120,130)
    tpCircle.Anchored = true; tpCircle.CanCollide = false
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        tpCircle.Position = char.HumanoidRootPart.Position
    end
    tpCircle.Parent = workspace
end)

tpRemove.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy(); tpCircle = nil end
end)

table.insert(cleanupTasks, function()
    if tpCircle and tpCircle.Parent then tpCircle:Destroy(); tpCircle = nil end
    unhighlightAll()
end)

createSep()
createSectionLabel("Actions")

createItemButton("Teleport Selected Items", function()
    if not tpCircle then return end
    if isItemTeleporting then return end
    isItemTeleporting = true

    task.spawn(function()
        local queue = {}
        for model in pairs(selectedItems) do
            if model and model.Parent then table.insert(queue, model) end
        end
        local total = #queue
        local done = 0
        if tpProgressContainer then
            tpProgressContainer.Visible = true
            tpProgressFill.Size = UDim2.new(0, 0, 1, 0)
            tpProgressLabel.Text = "Teleporting... 0 / " .. total
        end
        for _, model in ipairs(queue) do
            if not isItemTeleporting then break end
            if not (model and model.Parent) then done = done + 1; continue end
            local mainPart = model.PrimaryPart or model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
            if not mainPart then done = done + 1; continue end
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then done = done + 1; continue end
            hrp.CFrame = mainPart.CFrame * CFrame.new(0, 4, 2)
            task.wait(0.12)
            local dragger = game.ReplicatedStorage:FindFirstChild("Interaction")
                and game.ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
            if dragger then dragger:FireServer(model) end
            task.wait(0.08)
            if mainPart and mainPart.Parent then mainPart.CFrame = tpCircle.CFrame end
            task.wait(0.08)
            if dragger then dragger:FireServer(model) end
            task.wait(0.22)
            local hl = selectedItems[model]
            if hl and hl.Parent then hl:Destroy() end
            selectedItems[model] = nil
            done = done + 1
            if tpProgressContainer and tpProgressContainer.Visible then
                local pct = done / math.max(total, 1)
                TweenService:Create(tpProgressFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                    Size = UDim2.new(pct, 0, 1, 0)
                }):Play()
                tpProgressLabel.Text = "Teleporting... " .. done .. " / " .. total
            end
        end
        isItemTeleporting = false
        if tpProgressContainer and tpProgressContainer.Visible then
            TweenService:Create(tpProgressFill, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 1, 0)}):Play()
            tpProgressLabel.Text = "Done! " .. done .. " / " .. total .. " teleported"
            task.delay(1.8, function()
                if tpProgressContainer then
                    TweenService:Create(tpProgressContainer, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(tpProgressFill, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(tpProgressLabel, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
                    task.delay(0.45, function()
                        if tpProgressContainer then
                            tpProgressContainer.Visible = false
                            tpProgressContainer.BackgroundTransparency = 0
                            tpProgressFill.BackgroundTransparency = 0
                            tpProgressLabel.TextTransparency = 0
                        end
                    end)
                end
            end)
        end
    end)
end)

createItemButton("Cancel Teleport", function() isItemTeleporting = false end)
createItemButton("Clear Selection", function() unhighlightAll() end)

do
    local pbWrapper = Instance.new("Frame", itemPage)
    pbWrapper.Size = UDim2.new(1,-12,0,44)
    pbWrapper.BackgroundColor3 = Color3.fromRGB(18,18,24)
    pbWrapper.BorderSizePixel = 0
    pbWrapper.Visible = false
    Instance.new("UICorner", pbWrapper).CornerRadius = UDim.new(0, 8)
    local pbStroke = Instance.new("UIStroke", pbWrapper)
    pbStroke.Color = Color3.fromRGB(60,60,80); pbStroke.Thickness = 1; pbStroke.Transparency = 0.5
    local pbLabel = Instance.new("TextLabel", pbWrapper)
    pbLabel.Size = UDim2.new(1,-12,0,16)
    pbLabel.Position = UDim2.new(0,6,0,4)
    pbLabel.BackgroundTransparency = 1
    pbLabel.Font = Enum.Font.GothamSemibold; pbLabel.TextSize = 11
    pbLabel.TextColor3 = Color3.fromRGB(170,170,200)
    pbLabel.TextXAlignment = Enum.TextXAlignment.Left
    pbLabel.Text = "Teleporting..."
    local pbTrack = Instance.new("Frame", pbWrapper)
    pbTrack.Size = UDim2.new(1,-12,0,12)
    pbTrack.Position = UDim2.new(0,6,0,24)
    pbTrack.BackgroundColor3 = Color3.fromRGB(30,30,40)
    pbTrack.BorderSizePixel = 0
    Instance.new("UICorner", pbTrack).CornerRadius = UDim.new(1,0)
    local pbFill = Instance.new("Frame", pbTrack)
    pbFill.Size = UDim2.new(0,0,1,0)
    pbFill.BackgroundColor3 = Color3.fromRGB(80,180,255)
    pbFill.BorderSizePixel = 0
    Instance.new("UICorner", pbFill).CornerRadius = UDim.new(1,0)
    tpProgressContainer = pbWrapper
    tpProgressFill = pbFill
    tpProgressLabel = pbLabel
end

local lassoFrame = Instance.new("Frame", gui)
lassoFrame.Name = "LassoRect"
lassoFrame.BackgroundColor3 = Color3.fromRGB(60,120,200)
lassoFrame.BackgroundTransparency = 0.82
lassoFrame.BorderSizePixel = 0
lassoFrame.Visible = false; lassoFrame.ZIndex = 20
local lassoStroke = Instance.new("UIStroke", lassoFrame)
lassoStroke.Color = Color3.fromRGB(100,160,255); lassoStroke.Thickness = 1.5; lassoStroke.Transparency = 0

local lassoStartPos = nil

local function updateLassoFrame(s, c)
    local minX = math.min(s.X, c.X); local minY = math.min(s.Y, c.Y)
    lassoFrame.Position = UDim2.new(0, minX, 0, minY)
    lassoFrame.Size = UDim2.new(0, math.abs(c.X-s.X), 0, math.abs(c.Y-s.Y))
end

local camera = workspace.CurrentCamera
local function selectItemsInLasso()
    if not lassoStartPos then return end
    local cur = Vector2.new(player:GetMouse().X, player:GetMouse().Y)
    local minX = math.min(lassoStartPos.X, cur.X); local maxX = math.max(lassoStartPos.X, cur.X)
    local minY = math.min(lassoStartPos.Y, cur.Y); local maxY = math.max(lassoStartPos.Y, cur.Y)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isMoveableItem(obj) then
            local mp = obj.PrimaryPart or obj:FindFirstChild("Main") or obj:FindFirstChildWhichIsA("BasePart")
            if mp then
                local sp, onScreen = camera:WorldToScreenPoint(mp.Position)
                if onScreen and sp.X >= minX and sp.X <= maxX and sp.Y >= minY and sp.Y <= maxY then
                    highlightModel(obj)
                end
            end
        end
    end
end

local mouse = player:GetMouse()
local mouseIsDragging = false

mouse.Button1Down:Connect(function()
    mouseIsDragging = true
    if lassoTool then
        lassoStartPos = Vector2.new(mouse.X, mouse.Y)
        lassoFrame.Size = UDim2.new(0,0,0,0)
        lassoFrame.Visible = true
    elseif clickSelection or groupSelection then
        handleSelection(mouse.Target, false)
    end
end)

mouse.Button1Up:Connect(function()
    mouseIsDragging = false
    if lassoTool then
        selectItemsInLasso()
        lassoFrame.Visible = false
        lassoStartPos = nil
    end
end)

mouse.Move:Connect(function()
    if mouseIsDragging and lassoTool and lassoStartPos then
        updateLassoFrame(lassoStartPos, Vector2.new(mouse.X, mouse.Y))
    end
end)

-- ════════════════════════════════════════════════════
-- PLAYER TAB
-- ════════════════════════════════════════════════════
local playerPage = pages["PlayerTab"]

local function createPSection(text)
    local lbl = Instance.new("TextLabel", playerPage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function createPSep()
    local s = Instance.new("Frame", playerPage)
    s.Size = UDim2.new(1,-12,0,1); s.BackgroundColor3 = Color3.fromRGB(40,40,55); s.BorderSizePixel = 0
end

local savedWalkSpeed = 16
local savedJumpPower = 50

local statsConn2 = RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    if hum.WalkSpeed ~= savedWalkSpeed then hum.WalkSpeed = savedWalkSpeed end
    if hum.JumpPower ~= savedJumpPower then hum.JumpPower = savedJumpPower end
end)
table.insert(cleanupTasks, function()
    if statsConn2 then statsConn2:Disconnect(); statsConn2 = nil end
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
    end
end)

local function createPSlider(labelText, minVal, maxVal, defaultVal, onChanged)
    local frame = Instance.new("Frame", playerPage)
    frame.Size = UDim2.new(1,-12,0,52); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)
    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1,-16,0,22); topRow.Position = UDim2.new(0,8,0,6); topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.7,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.3,0,1,0); valLbl.Position = UDim2.new(0.7,0,0,0); valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3 = Color3.fromRGB(200,200,255); valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defaultVal)
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1,-16,0,6); track.Position = UDim2.new(0,8,0,36)
    track.BackgroundColor3 = Color3.fromRGB(40,40,55); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,80,100); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0,16,0,16); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(210,210,225); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local draggingSlider = false
    local function updateSlider(absX)
        local ratio = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.round(minVal + ratio*(maxVal-minVal))
        fill.Size = UDim2.new(ratio,0,1,0)
        knob.Position = UDim2.new(ratio,0,0.5,0)
        valLbl.Text = tostring(val)
        if onChanged then onChanged(val) end
    end
    knob.MouseButton1Down:Connect(function() draggingSlider = true end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true; updateSlider(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
    end)
    return frame
end

local function createPToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", playerPage)
    frame.Size = UDim2.new(1,-12,0,32); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.TextXAlignment = Enum.TextXAlignment.Left
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
    local function setToggled(val)
        toggled = val
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and Color3.fromRGB(60,180,60) or BTN_COLOR
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 18 or 2, 0.5, -7)
        }):Play()
    end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        setToggled(toggled)
        if callback then callback(toggled) end
    end)
    return frame, setToggled, function() return toggled end
end

createPSection("Movement")

createPSlider("Walkspeed", 16, 150, 16, function(val)
    savedWalkSpeed = val
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = val end
end)

createPSlider("Jumpower", 50, 300, 50, function(val)
    savedJumpPower = val
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.JumpPower = val end
end)

local flySpeed = 100
createPSlider("Fly Speed", 100, 500, 100, function(val) flySpeed = val end)

local flyKeyFrame = Instance.new("Frame", playerPage)
flyKeyFrame.Size = UDim2.new(1,-12,0,32); flyKeyFrame.BackgroundColor3 = Color3.fromRGB(24,24,30)
Instance.new("UICorner", flyKeyFrame).CornerRadius = UDim.new(0,6)
local flyKeyLabel = Instance.new("TextLabel", flyKeyFrame)
flyKeyLabel.Size = UDim2.new(0.6,0,1,0); flyKeyLabel.Position = UDim2.new(0,10,0,0)
flyKeyLabel.BackgroundTransparency = 1; flyKeyLabel.Font = Enum.Font.GothamSemibold; flyKeyLabel.TextSize = 13
flyKeyLabel.TextColor3 = Color3.fromRGB(220,220,220); flyKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
flyKeyLabel.Text = "Fly Key"
local currentFlyKey = Enum.KeyCode.Q
local waitingForFlyKey = false
local flyKeyBtn = Instance.new("TextButton", flyKeyFrame)
flyKeyBtn.Size = UDim2.new(0,60,0,22); flyKeyBtn.Position = UDim2.new(1,-68,0.5,-11)
flyKeyBtn.BackgroundColor3 = BTN_COLOR; flyKeyBtn.Font = Enum.Font.GothamSemibold
flyKeyBtn.TextSize = 12; flyKeyBtn.TextColor3 = Color3.fromRGB(210,210,220); flyKeyBtn.Text = "Q"
flyKeyBtn.BorderSizePixel = 0; Instance.new("UICorner", flyKeyBtn).CornerRadius = UDim.new(0,6)
flyKeyBtn.MouseEnter:Connect(function() TweenService:Create(flyKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
flyKeyBtn.MouseLeave:Connect(function() TweenService:Create(flyKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
flyKeyBtn.MouseButton1Click:Connect(function()
    if _G.VH and _G.VH.waitingForFlyKey then return end
    if _G.VH then _G.VH.waitingForFlyKey = true end
    flyKeyBtn.Text = "..."
    flyKeyBtn.BackgroundColor3 = Color3.fromRGB(60,100,60)
end)

local isFlyEnabled = false
local flyToggleEnabled = true
local flyBV, flyBG, flyConn

local function stopFly()
    isFlyEnabled = false
    if _G.VH then _G.VH.isFlyEnabled = false end
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV and flyBV.Parent then flyBV:Destroy(); flyBV = nil end
    if flyBG and flyBG.Parent then flyBG:Destroy(); flyBG = nil end
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = false
    end
end

local function startFly()
    stopFly()
    isFlyEnabled = true
    if _G.VH then _G.VH.isFlyEnabled = true end
    local char = player.Character
    if not char then isFlyEnabled = false; return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then isFlyEnabled = false; return end
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBG.P = 1e4; flyBG.D = 100
    flyConn = RunService.Heartbeat:Connect(function()
        if not (flyBV and flyBV.Parent and flyBG and flyBG.Parent) then return end
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not (hum and root) then return end
        local cam = workspace.CurrentCamera
        local cf = cam.CFrame
        local UIS = UserInputService
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        hum.PlatformStand = true
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        flyBG.CFrame = cf
    end)
end

table.insert(cleanupTasks, stopFly)

local _, setFlyToggle = createPToggle("Fly", true, function(val)
    flyToggleEnabled = val
    if val then
        local char = Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            startFly()
        else
            Players.LocalPlayer.CharacterAdded:Wait()
            task.wait(0.1)
            startFly()
        end
    else
        stopFly()
    end
end)

createPSep()
createPSection("Character")

local noclipEnabled = false
local noclipConn
createPToggle("Noclip", false, function(val)
    noclipEnabled = val
    if val then
        noclipConn = RunService.Stepped:Connect(function()
            if not noclipEnabled then return end
            local char = player.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local char = player.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)
table.insert(cleanupTasks, function()
    noclipEnabled = false
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end)

local infJumpEnabled = false
local infJumpConn
createPToggle("InfJump", false, function(val)
    infJumpEnabled = val
    if val then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            if not infJumpEnabled then return end
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end
end)
table.insert(cleanupTasks, function()
    infJumpEnabled = false
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
end)

-- ════════════════════════════════════════════════════
-- SHARED GLOBALS — exported for Vanilla2 and Vanilla3
-- ════════════════════════════════════════════════════
_G.VH = {
    TweenService     = TweenService,
    Players          = Players,
    UserInputService = UserInputService,
    RunService       = RunService,
    TeleportService  = TeleportService,
    Stats            = Stats,
    player           = player,
    cleanupTasks     = cleanupTasks,
    pages            = pages,
    tabs             = tabs,
    BTN_COLOR        = BTN_COLOR,
    BTN_HOVER        = BTN_HOVER,
    switchTab        = switchTab,
    toggleGUI        = toggleGUI,
    stopFly          = stopFly,
    startFly         = startFly,
    butter           = { running = false, thread = nil },
    flyToggleEnabled = true,
    isFlyEnabled     = false,
    currentFlyKey    = Enum.KeyCode.Q,
    waitingForFlyKey = false,
    flyKeyBtn        = flyKeyBtn,
    currentToggleKey = currentToggleKey,
    waitingForKeyGUI = waitingForKeyGUI,
    keybindButtonGUI = nil,
}

-- Point _G.VanillaHubCleanup at onExit so any future execute or re-execute
-- will fully tear down this instance before starting fresh.
_G.VanillaHubCleanup = onExit

print("[VanillaHub] Vanilla1 loaded")
