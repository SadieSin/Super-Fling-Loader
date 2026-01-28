-- Super Fling By SadieSin (Sparklee_Diva) - REDESIGNED GUI + Camera-Follow Fly + Fly Popup
-- Save as: SuperFling_CameraFollowFly.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Prevent duplicate GUIs
if game.CoreGui:FindFirstChild("SuperFling") then
    game.CoreGui.SuperFling:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "SuperFling"
sg.Parent = game.CoreGui
sg.ResetOnSpawn = false

-- Main frame
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 420, 0, 580)
main.Position = UDim2.new(0.5, -210, 0.5, -290)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
main.BorderSizePixel = 0
main.Parent = sg

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 15))
}
mainGradient.Rotation = 45
mainGradient.Parent = main

local uc = Instance.new("UICorner")
uc.CornerRadius = UDim.new(0, 16)
uc.Parent = main

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(100, 80, 255)
uiStroke.Transparency = 0.6
uiStroke.Thickness = 2
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiStroke.Parent = main

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 28)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 35))
}
titleGradient.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SUPER FLINGER"
title.TextColor3 = Color3.fromRGB(180, 140, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -80, 0, 16)
subtitle.Position = UDim2.new(0, 20, 0, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text = "by SadieSin • Enhanced Edition"
subtitle.TextColor3 = Color3.fromRGB(120, 120, 180)
subtitle.TextSize = 11
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -46, 0.5, -18)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 80)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 22
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

-- Draggable
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 80, 100)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 60, 80)}):Play()
end)

closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

-- Player list (left side)
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0, 240, 1, -110)
scroll.Position = UDim2.new(0, 16, 0, 70)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 60, 180)
scroll.Parent = main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

-- Right panel (controls)
local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(0, 140, 1, -110)
rightPanel.Position = UDim2.new(1, -156, 0, 70)
rightPanel.BackgroundTransparency = 1
rightPanel.Parent = main

-- Fly Speed Popup GUI
local flyPopup = Instance.new("Frame")
flyPopup.Name = "FlySpeedPopup"
flyPopup.Size = UDim2.new(0, 220, 0, 140)
flyPopup.Position = UDim2.new(0.5, -110, 0.5, -70)
flyPopup.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
flyPopup.BackgroundTransparency = 0.15
flyPopup.Visible = false
flyPopup.Parent = sg
flyPopup.Draggable = true
flyPopup.Active = true

local popupCorner = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 14)
popupCorner.Parent = flyPopup

local popupStroke = Instance.new("UIStroke")
popupStroke.Color = Color3.fromRGB(140, 120, 255)
popupStroke.Thickness = 2
popupStroke.Transparency = 0.4
popupStroke.Parent = flyPopup

local popupTitleBar = Instance.new("Frame")
popupTitleBar.Size = UDim2.new(1, 0, 0, 36)
popupTitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
popupTitleBar.BorderSizePixel = 0
popupTitleBar.Parent = flyPopup

local popupTitle = Instance.new("TextLabel")
popupTitle.Size = UDim2.new(1, -50, 1, 0)
popupTitle.Position = UDim2.new(0, 12, 0, 0)
popupTitle.BackgroundTransparency = 1
popupTitle.Text = "FLY SPEED CONTROL"
popupTitle.TextColor3 = Color3.fromRGB(200, 180, 255)
popupTitle.TextSize = 15
popupTitle.Font = Enum.Font.GothamBold
popupTitle.TextXAlignment = Enum.TextXAlignment.Left
popupTitle.Parent = popupTitleBar

local popupClose = Instance.new("TextButton")
popupClose.Size = UDim2.new(0, 30, 0, 30)
popupClose.Position = UDim2.new(1, -38, 0.5, -15)
popupClose.BackgroundColor3 = Color3.fromRGB(220, 60, 80)
popupClose.Text = "×"
popupClose.TextColor3 = Color3.new(1,1,1)
popupClose.TextSize = 20
popupClose.Font = Enum.Font.GothamBold
popupClose.Parent = popupTitleBar

local popupCloseCorner = Instance.new("UICorner")
popupCloseCorner.CornerRadius = UDim.new(0, 8)
popupCloseCorner.Parent = popupClose

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 25)
speedLabel.Position = UDim2.new(0, 10, 0, 50)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed (no limit):"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
speedLabel.TextSize = 14
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.Parent = flyPopup

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(1, -20, 0, 40)
speedBox.Position = UDim2.new(0, 10, 0, 80)
speedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.Text = "80"
speedBox.TextSize = 18
speedBox.Font = Enum.Font.Gotham
speedBox.ClearTextOnFocus = false
speedBox.Parent = flyPopup

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 10)
boxCorner.Parent = speedBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(140, 120, 255)
boxStroke.Transparency = 0.5
boxStroke.Thickness = 1.5
boxStroke.Parent = speedBox

-- Variables
local selectedPlayers = {}
local flinging = false
local flying = false
local noclipping = false
local distanceLabelsEnabled = false
local infJumping = false
local clickFlingEnabled = false
local walkFlingEnabled = false
local mainLoop = nil
local cycleTimer = nil
local savedPosition = nil
local flyLoop = nil
local flyCleanup = nil
local noclipLoop = nil
local jumpConn = nil
local espConnections = {}
local distanceConnections = {}
local flySpeed = 80
local messageActive = false
local originalCollisions = {}
local playerButtons = {}
local clickConn = nil
local walkLoop = nil
local flingCooldowns = {}
local activeFling = false
local flingTarget = nil
local flingStartCFrame = nil
local flingConn = nil

-- Fly speed popup close → stop flying
popupClose.MouseButton1Click:Connect(function()
    if flying then
        flying = false
        flyPopup.Visible = false
        if flyLoop then flyLoop:Disconnect() flyLoop = nil end
        if flyCleanup then flyCleanup() flyCleanup = nil end
        showMessage("Flying stopped (speed GUI closed)")
    end
end)

popupClose.MouseEnter:Connect(function()
    TweenService:Create(popupClose, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 80, 100)}):Play()
end)
popupClose.MouseLeave:Connect(function()
    TweenService:Create(popupClose, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 60, 80)}):Play()
end)

-- Speed change (no limit)
speedBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local num = tonumber(speedBox.Text)
        if num and num > 0 then
            flySpeed = num
            showMessage("Fly speed set to: " .. num)
        else
            speedBox.Text = tostring(flySpeed)
        end
    end
end)

-- ESP + Distance Labels (with Username + DisplayName)
local function createESPAndLabel(player)
    if player == LocalPlayer then return end
    
    local function setupForChar(char)
        if not char or not char:FindFirstChild("Head") or not char:FindFirstChild("HumanoidRootPart") then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "SadieESP"
        highlight.FillTransparency = 1
        highlight.OutlineColor = Color3.fromRGB(140, 100, 255)
        highlight.OutlineTransparency = 0.1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = char
        highlight.Parent = char

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "SadieDistance"
        billboard.Adornee = char.Head
        billboard.Size = UDim2.new(0, 180, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 4.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = char.Head

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(220, 200, 255)
        textLabel.TextStrokeTransparency = 0.4
        textLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 16
        textLabel.TextScaled = true
        textLabel.Parent = billboard

        local conn = RunService.Heartbeat:Connect(function()
            if not distanceLabelsEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                billboard.Enabled = false
                return
            end
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            local dist = (myRoot.Position - char.HumanoidRootPart.Position).Magnitude
            
            local display = player.DisplayName
            local username = player.Name
            local nameText = (display ~= username) and (display .. "  @" .. username) or username
            
            textLabel.Text = nameText .. "\n" .. string.format("%.1f studs", dist)
            billboard.Enabled = true
        end)

        table.insert(distanceConnections, conn)

        local removeConn = char.AncestryChanged:Connect(function()
            if not char.Parent then
                if highlight then highlight:Destroy() end
                if billboard then billboard:Destroy() end
                if conn then conn:Disconnect() end
            end
        end)
        table.insert(espConnections, removeConn)
    end

    if player.Character then setupForChar(player.Character) end
    local charAdded = player.CharacterAdded:Connect(setupForChar)
    table.insert(espConnections, charAdded)
end

local function removeAllESPAndLabels()
    for _, conn in ipairs(espConnections) do pcall(function() conn:Disconnect() end) end
    for _, conn in ipairs(distanceConnections) do pcall(function() conn:Disconnect() end) end
    espConnections = {}
    distanceConnections = {}
    for _, p in Players:GetPlayers() do
        if p.Character then
            if p.Character:FindFirstChild("SadieESP") then p.Character.SadieESP:Destroy() end
            if p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("SadieDistance") then
                p.Character.Head.SadieDistance:Destroy()
            end
        end
    end
end

local function toggleESPAndDistance()
    distanceLabelsEnabled = not distanceLabelsEnabled
    if distanceLabelsEnabled then
        for _, p in Players:GetPlayers() do
            createESPAndLabel(p)
        end
        local paConn = Players.PlayerAdded:Connect(function(p)
            createESPAndLabel(p)
        end)
        table.insert(espConnections, paConn)
    else
        removeAllESPAndLabels()
    end
end

-- Button animation helper
local function animateButton(btn, isHover, isClick)
    local goal = {}
    if isClick then
        goal = {Size = UDim2.new(1, -16, 0, 54), BackgroundTransparency = 0.1}
    elseif isHover then
        goal = {BackgroundTransparency = 0.2, Size = UDim2.new(1, -8, 0, 54)}
    else
        goal = {BackgroundTransparency = 0.4, Size = UDim2.new(1, -8, 0, 54)}
    end
    TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

-- Player list update
local function updateList()
    for _, child in scroll:GetChildren() do
        if child:IsA("TextButton") then child:Destroy() end
    end
    playerButtons = {}

    local currentlySelected = {}
    for _, p in selectedPlayers do currentlySelected[p] = true end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 52)
            b.BackgroundColor3 = currentlySelected[p] and Color3.fromRGB(80, 60, 180) or Color3.fromRGB(30, 30, 50)
            b.BackgroundTransparency = currentlySelected[p] and 0.3 or 0.5
            b.BorderSizePixel = 0
            b.Text = p.Name
            b.TextColor3 = Color3.fromRGB(220, 210, 255)
            b.TextSize = 14
            b.Font = Enum.Font.GothamSemibold
            b.AutoButtonColor = false
            b.Parent = scroll

            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 12)
            bc.Parent = b

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(120, 100, 255)
            stroke.Transparency = currentlySelected[p] and 0.3 or 0.7
            stroke.Thickness = 1.5
            stroke.Parent = b

            playerButtons[p] = b

            b.MouseEnter:Connect(function() if not currentlySelected[p] then animateButton(b, true, false) end end)
            b.MouseLeave:Connect(function() if not currentlySelected[p] then animateButton(b, false, false) end end)

            b.MouseButton1Click:Connect(function()
                local index = table.find(selectedPlayers, p)
                if index then
                    table.remove(selectedPlayers, index)
                    b.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
                    b.BackgroundTransparency = 0.5
                    stroke.Transparency = 0.7
                else
                    table.insert(selectedPlayers, p)
                    b.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
                    b.BackgroundTransparency = 0.3
                    stroke.Transparency = 0.3
                end
                animateButton(b, false, true)
                task.delay(0.18, function() animateButton(b, false, false) end)
            end)
        end
    end
end

updateList()
Players.PlayerAdded:Connect(updateList)
Players.PlayerRemoving:Connect(updateList)

task.spawn(function()
    while sg.Parent do
        updateList()
        task.wait(3)
    end
end)

local function showMessage(text)
    if messageActive then return end
    messageActive = true
    local msg = Instance.new("Message")
    msg.Text = text
    msg.Parent = game.Workspace
    task.delay(2.5, function()
        if msg and msg.Parent then msg:Destroy() end
        messageActive = false
    end)
end

-- Fling logic (attach for 3 sec then tp back)
local function startAttachFling(target, startCFrame)
    if activeFling then return end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    pcall(function() root:SetNetworkOwner(LocalPlayer) end)
    
    activeFling = true
    flingTarget = target
    flingStartCFrame = startCFrame
    
    flingConn = RunService.Heartbeat:Connect(function()
        if not activeFling then return end
        local targetRoot = target.Character.HumanoidRootPart
        local offset = Vector3.new(math.random(-1.2,1.2), math.random(-0.4,1.6), math.random(-1.2,1.2))
        local targetVel = targetRoot.AssemblyLinearVelocity
        if targetVel.Magnitude > 5 then
            offset = offset + targetVel.Unit * 1.8
        end
        root.CFrame = targetRoot.CFrame * CFrame.new(offset)
        root.AssemblyAngularVelocity = Vector3.new(18000 + math.random(-4000,4000), 18000 + math.random(-4000,4000), 18000 + math.random(-4000,4000))
        root.AssemblyLinearVelocity = Vector3.new(math.random(-220,220), math.random(-120,350), math.random(-220,220))
    end)
    
    task.delay(3, function()
        if flingConn then flingConn:Disconnect() end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if flingStartCFrame then
            root.CFrame = flingStartCFrame
        end
        activeFling = false
        flingTarget = nil
        flingStartCFrame = nil
    end)
end

-- Super Fling
local function startSuperFling()
    if #selectedPlayers == 0 then return end
    flinging = true
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    savedPosition = root.CFrame
    pcall(function() root:SetNetworkOwner(LocalPlayer) end)
    local currentIndex = 1
    mainLoop = RunService.Heartbeat:Connect(function()
        if not flinging or not root or not root.Parent then return end
        local target = selectedPlayers[currentIndex]
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = target.Character.HumanoidRootPart
            local offset = Vector3.new(math.random(-1,1), math.random(-0.5,1.5), math.random(-1,1))
            local targetVel = targetRoot.AssemblyLinearVelocity
            if targetVel.Magnitude > 5 then
                offset = offset + targetVel.Unit * 1.5
            end
            root.CFrame = targetRoot.CFrame * CFrame.new(offset)
        end
        root.AssemblyAngularVelocity = Vector3.new(15000 + math.random(-3000,3000), 15000 + math.random(-3000,3000), 15000 + math.random(-3000,3000))
        local burst = Vector3.new(math.random(-200,200), math.random(-100,300), math.random(-200,200))
        root.AssemblyLinearVelocity = burst
    end)
    local function cycle()
        if not flinging then return end
        currentIndex = currentIndex + 1
        if currentIndex > #selectedPlayers then currentIndex = 1 end
        cycleTimer = task.delay(2, cycle)
    end
    cycle()
end

local function stopSuperFling()
    flinging = false
    if mainLoop then mainLoop:Disconnect() mainLoop = nil end
    if cycleTimer then task.cancel(cycleTimer) cycleTimer = nil end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if savedPosition then root.CFrame = savedPosition end
    end
end

-- Fly logic – body follows camera direction
local function startFly()
    flying = true
    flyPopup.Visible = true
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") then return end
    local humanoid = char.Humanoid
    local root = char.HumanoidRootPart
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    humanoid.PlatformStand = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)

    local keys = {Forward = false, Backward = false, Left = false, Right = false, Up = false, Down = false}

    local inputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.W then keys.Forward = true end
        if input.KeyCode == Enum.KeyCode.S then keys.Backward = true end
        if input.KeyCode == Enum.KeyCode.A then keys.Left = true end
        if input.KeyCode == Enum.KeyCode.D then keys.Right = true end
        if input.KeyCode == Enum.KeyCode.E then keys.Up = true end
        if input.KeyCode == Enum.KeyCode.Q then keys.Down = true end
    end)

    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then keys.Forward = false end
        if input.KeyCode == Enum.KeyCode.S then keys.Backward = false end
        if input.KeyCode == Enum.KeyCode.A then keys.Left = false end
        if input.KeyCode == Enum.KeyCode.D then keys.Right = false end
        if input.KeyCode == Enum.KeyCode.E then keys.Up = false end
        if input.KeyCode == Enum.KeyCode.Q then keys.Down = false end
    end)

    flyLoop = RunService.RenderStepped:Connect(function()
        if not flying or not root or not root.Parent then return end

        local cam = workspace.CurrentCamera

        -- Body follows camera rotation (look direction)
        local lookCFrame = cam.CFrame - cam.CFrame.Position
        root.CFrame = CFrame.new(root.Position) * lookCFrame

        -- Movement direction based on keys + camera
        local moveDir = Vector3.new()
        if keys.Forward  then moveDir = moveDir + cam.CFrame.LookVector end
        if keys.Backward then moveDir = moveDir - cam.CFrame.LookVector end
        if keys.Left     then moveDir = moveDir - cam.CFrame.RightVector end
        if keys.Right    then moveDir = moveDir + cam.CFrame.RightVector end
        if keys.Up       then moveDir = moveDir + Vector3.new(0,1,0) end
        if keys.Down     then moveDir = moveDir - Vector3.new(0,1,0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * flySpeed
        end

        -- Anti-stuck lift when close to ground
        local ray = Ray.new(root.Position, Vector3.new(0, -5, 0))
        local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {char})
        if hit and (root.Position - pos).Magnitude < 3 then
            moveDir = moveDir + Vector3.new(0, 15, 0)
        end

        root.AssemblyLinearVelocity = moveDir
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    flyCleanup = function()
        inputBegan:Disconnect()
        inputEnded:Disconnect()
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        for _, state in {Enum.HumanoidStateType.Running, Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.GettingUp} do
            humanoid:SetStateEnabled(state, true)
        end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        flyPopup.Visible = false
    end
end

local function stopFly()
    flying = false
    flyPopup.Visible = false
    if flyLoop then flyLoop:Disconnect() flyLoop = nil end
    if flyCleanup then flyCleanup() flyCleanup = nil end
end

-- Noclip
local function toggleNoclip()
    noclipping = not noclipping
    local char = LocalPlayer.Character
    if not char then return end
    if noclipping then
        originalCollisions = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                originalCollisions[part] = true
                part.CanCollide = false
            end
        end
        noclipLoop = RunService.Stepped:Connect(function()
            if not noclipping then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    else
        if noclipLoop then noclipLoop:Disconnect() noclipLoop = nil end
        for part, wasCollidable in pairs(originalCollisions) do
            if part and part.Parent then part.CanCollide = wasCollidable end
        end
        originalCollisions = {}
    end
end

-- Infinite Jump
local function toggleInfJump()
    infJumping = not infJumping
    if infJumping then
        jumpConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    else
        if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    end
end

-- Select All / Deselect All
local selectAllBtn = Instance.new("TextButton")
selectAllBtn.Size = UDim2.new(0.48, -4, 0, 38)
selectAllBtn.Position = UDim2.new(0, 16, 1, -54)
selectAllBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 120)
selectAllBtn.BackgroundTransparency = 0.4
selectAllBtn.Text = "SELECT ALL"
selectAllBtn.TextColor3 = Color3.new(1,1,1)
selectAllBtn.TextSize = 13
selectAllBtn.Font = Enum.Font.GothamSemibold
selectAllBtn.Parent = main

local selCorner = Instance.new("UICorner")
selCorner.CornerRadius = UDim.new(0, 10)
selCorner.Parent = selectAllBtn

local deselectAllBtn = Instance.new("TextButton")
deselectAllBtn.Size = UDim2.new(0.48, -4, 0, 38)
deselectAllBtn.Position = UDim2.new(0.52, 0, 1, -54)
deselectAllBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 80)
deselectAllBtn.BackgroundTransparency = 0.4
deselectAllBtn.Text = "DESELECT ALL"
deselectAllBtn.TextColor3 = Color3.new(1,1,1)
deselectAllBtn.TextSize = 13
deselectAllBtn.Font = Enum.Font.GothamSemibold
deselectAllBtn.Parent = main

local deselCorner = Instance.new("UICorner")
deselCorner.CornerRadius = UDim.new(0, 10)
deselCorner.Parent = deselectAllBtn

selectAllBtn.MouseButton1Click:Connect(function()
    selectedPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and playerButtons[p] then
            table.insert(selectedPlayers, p)
            local b = playerButtons[p]
            b.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
            b.BackgroundTransparency = 0.3
            b:FindFirstChildOfClass("UIStroke").Transparency = 0.3
        end
    end
end)

deselectAllBtn.MouseButton1Click:Connect(function()
    selectedPlayers = {}
    for _, b in pairs(playerButtons) do
        b.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        b.BackgroundTransparency = 0.5
        b:FindFirstChildOfClass("UIStroke").Transparency = 0.7
    end
end)

-- Control buttons function
local yOffset = 0

local function addControlButton(text, baseColor, emoji)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 54)
    btn.Position = UDim2.new(0, 0, 0, yOffset)
    btn.BackgroundColor3 = baseColor
    btn.BackgroundTransparency = 0.4
    btn.BorderSizePixel = 0
    btn.Text = emoji .. "  " .. text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = rightPanel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = baseColor
    stroke.Transparency = 0.5
    stroke.Thickness = 2
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        animateButton(btn, true, false)
        TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.2}):Play()
    end)

    btn.MouseLeave:Connect(function()
        animateButton(btn, false, false)
        TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
    end)

    btn.MouseButton1Down:Connect(function()
        animateButton(btn, false, true)
    end)

    btn.MouseButton1Up:Connect(function()
        task.delay(0.15, function() animateButton(btn, false, false) end)
    end)

    yOffset = yOffset + 58
    return btn
end

-- Super Fling button
local btnFling = addControlButton("SUPER FLING", Color3.fromRGB(50, 180, 120), "🚀")

local function updateFlingText()
    btnFling.Text = flinging and "🛑 STOP FLING" or "🚀 SUPER FLING"
    btnFling.BackgroundColor3 = flinging and Color3.fromRGB(180, 60, 80) or Color3.fromRGB(50, 180, 120)
    btnFling:FindFirstChildOfClass("UIStroke").Color = btnFling.BackgroundColor3
end

btnFling.MouseButton1Click:Connect(function()
    if flying then 
        showMessage("Cannot fling while flying!")
        return 
    end
    if flinging then
        stopSuperFling()
    else
        startSuperFling()
    end
    updateFlingText()
end)
updateFlingText()

-- Fly button
local btnFly = addControlButton("FLY", Color3.fromRGB(60, 120, 220), "🕊️")

local function updateFlyText()
    btnFly.Text = flying and "🛑 STOP FLY" or "🕊️ FLY"
    btnFly.BackgroundColor3 = flying and Color3.fromRGB(180, 60, 80) or Color3.fromRGB(60, 120, 220)
    btnFly:FindFirstChildOfClass("UIStroke").Color = btnFly.BackgroundColor3
end

btnFly.MouseButton1Click:Connect(function()
    if flinging then 
        showMessage("Cannot fly while flinging!")
        return 
    end
    if flying then
        stopFly()
    else
        startFly()
    end
    updateFlyText()
end)
updateFlyText()

-- Noclip button
local btnNoclip = addControlButton("NOCLIP", Color3.fromRGB(140, 80, 220), "👻")

local function updateNoclipText()
    btnNoclip.Text = noclipping and "👻 NOCLIP ON" or "👻 NOCLIP OFF"
    btnNoclip.BackgroundColor3 = noclipping and Color3.fromRGB(180, 100, 255) or Color3.fromRGB(140, 80, 220)
    btnNoclip:FindFirstChildOfClass("UIStroke").Color = btnNoclip.BackgroundColor3
end

btnNoclip.MouseButton1Click:Connect(function()
    toggleNoclip()
    updateNoclipText()
end)
updateNoclipText()

-- ESP button
local btnESP = addControlButton("ESP + DISTANCE", Color3.fromRGB(100, 100, 255), "👀")

local function updateESPText()
    btnESP.Text = distanceLabelsEnabled and "👀 ESP ON" or "👀 ESP OFF"
    btnESP.BackgroundColor3 = distanceLabelsEnabled and Color3.fromRGB(160, 120, 255) or Color3.fromRGB(100, 100, 255)
    btnESP:FindFirstChildOfClass("UIStroke").Color = btnESP.BackgroundColor3
end

btnESP.MouseButton1Click:Connect(function()
    toggleESPAndDistance()
    updateESPText()
end)
updateESPText()

-- Inf Jump button
local btnInfJump = addControlButton("INF JUMP", Color3.fromRGB(220, 120, 60), "⬆️")

local function updateInfJumpText()
    btnInfJump.Text = infJumping and "⬆️ INF JUMP ON" or "⬆️ INF JUMP OFF"
    btnInfJump.BackgroundColor3 = infJumping and Color3.fromRGB(255, 140, 80) or Color3.fromRGB(220, 120, 60)
    btnInfJump:FindFirstChildOfClass("UIStroke").Color = btnInfJump.BackgroundColor3
end

btnInfJump.MouseButton1Click:Connect(function()
    toggleInfJump()
    updateInfJumpText()
end)
updateInfJumpText()

-- Click Fling button
local btnClickFling = addControlButton("CLICK FLING", Color3.fromRGB(120, 200, 80), "🖱️")

local function updateClickFlingText()
    btnClickFling.Text = clickFlingEnabled and "🖱️ CLICK FLING ON" or "🖱️ CLICK FLING OFF"
    btnClickFling.BackgroundColor3 = clickFlingEnabled and Color3.fromRGB(140, 220, 100) or Color3.fromRGB(120, 200, 80)
    btnClickFling:FindFirstChildOfClass("UIStroke").Color = btnClickFling.BackgroundColor3
end

btnClickFling.MouseButton1Click:Connect(function()
    if flying or flinging or walkFlingEnabled then 
        showMessage("Cannot enable while flying, flinging, or walk fling!")
        return 
    end
    clickFlingEnabled = not clickFlingEnabled
    if clickFlingEnabled then
        clickConn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mouse = LocalPlayer:GetMouse()
                if mouse.Target then
                    local model = mouse.Target:FindFirstAncestorWhichIsA("Model")
                    local target = Players:GetPlayerFromCharacter(model)
                    if target and target ~= LocalPlayer then
                        startAttachFling(target, LocalPlayer.Character.HumanoidRootPart.CFrame)
                    end
                end
            end
        end)
    else
        if clickConn then clickConn:Disconnect() clickConn = nil end
    end
    updateClickFlingText()
end)
updateClickFlingText()

-- Walk Fling button
local btnWalkFling = addControlButton("WALK FLING", Color3.fromRGB(200, 100, 50), "🚶")

local function updateWalkFlingText()
    btnWalkFling.Text = walkFlingEnabled and "🚶 WALK FLING ON" or "🚶 WALK FLING OFF"
    btnWalkFling.BackgroundColor3 = walkFlingEnabled and Color3.fromRGB(220, 120, 70) or Color3.fromRGB(200, 100, 50)
    btnWalkFling:FindFirstChildOfClass("UIStroke").Color = btnWalkFling.BackgroundColor3
end

btnWalkFling.MouseButton1Click:Connect(function()
    if flying or flinging or clickFlingEnabled then 
        showMessage("Cannot enable while flying, flinging, or click fling!")
        return 
    end
    walkFlingEnabled = not walkFlingEnabled
    if walkFlingEnabled then
        walkLoop = RunService.Heartbeat:Connect(function()
            if activeFling then return end

            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local root = char.HumanoidRootPart

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local tRoot = p.Character.HumanoidRootPart
                    local dist = (root.Position - tRoot.Position).Magnitude
                    if dist < 5.5 and (not flingCooldowns[p] or tick() - flingCooldowns[p] > 4) then
                        startAttachFling(p, root.CFrame)
                        flingCooldowns[p] = tick()
                        break
                    end
                end
            end
        end)
    else
        if walkLoop then walkLoop:Disconnect() walkLoop = nil end
        activeFling = false
    end
    updateWalkFlingText()
end)
updateWalkFlingText()

-- Breathing animation
local breathing = TweenService:Create(uiStroke, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Transparency = 0.4
})
breathing:Play()
