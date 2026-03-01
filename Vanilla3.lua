-- ════════════════════════════════════════════════════
-- VANILLA3 — AutoBuy Tab + Settings Tab + Search Tab
--           + Wood Tab (Tree Getter) + Input Handler
-- Imports shared state from Vanilla1 via _G.VH
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla3: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local Players          = _G.VH.Players
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages
local tabs             = _G.VH.tabs
local BTN_COLOR        = _G.VH.BTN_COLOR
local BTN_HOVER        = _G.VH.BTN_HOVER
local switchTab        = _G.VH.switchTab
local toggleGUI        = _G.VH.toggleGUI
local stopFly          = _G.VH.stopFly
local startFly         = _G.VH.startFly
local flyKeyBtn        = _G.VH.flyKeyBtn
local keybindButtonGUI

local function getWaitingForFlyKey()   return _G.VH and _G.VH.waitingForFlyKey end
local function setWaitingForFlyKey(v)  if _G.VH then _G.VH.waitingForFlyKey = v end end
local function getWaitingForKeyGUI()   return _G.VH and _G.VH.waitingForKeyGUI end
local function setWaitingForKeyGUI(v)  if _G.VH then _G.VH.waitingForKeyGUI = v end end
local function getCurrentFlyKey()      return _G.VH and _G.VH.currentFlyKey or Enum.KeyCode.Q end
local function setCurrentFlyKey(v)     if _G.VH then _G.VH.currentFlyKey = v end end
local function getCurrentToggleKey()   return _G.VH and _G.VH.currentToggleKey or Enum.KeyCode.LeftAlt end
local function setCurrentToggleKey(v)  if _G.VH then _G.VH.currentToggleKey = v end end
local function getFlyToggleEnabled()   return _G.VH and _G.VH.flyToggleEnabled end
local function getIsFlyEnabled()       return _G.VH and _G.VH.isFlyEnabled end

-- ════════════════════════════════════════════════════
-- AUTOBUY TAB (placeholder)
-- ════════════════════════════════════════════════════
local autoBuyPage = pages["AutoBuyTab"]

-- ════════════════════════════════════════════════════
-- WOOD TAB — Tree Getter
-- ════════════════════════════════════════════════════
local woodPage = pages["WoodTab"]

-- ── Colours (matching VanillaHub dark theme) ─────────────────
local ACCENT      = Color3.fromRGB(200, 60, 60)        -- red accent (hub style)
local ACCENT_HOV  = Color3.fromRGB(225, 80, 80)
local DARK_BG     = Color3.fromRGB(14, 14, 18)
local CARD_BG     = Color3.fromRGB(22, 22, 28)
local CARD_BG2    = Color3.fromRGB(28, 28, 36)
local LABEL_DIM   = Color3.fromRGB(120, 120, 150)
local LABEL_MAIN  = Color3.fromRGB(220, 220, 220)
local LABEL_SUB   = Color3.fromRGB(170, 170, 200)
local FILL_COLOR  = Color3.fromRGB(80, 180, 255)

-- ── Services needed for tree logic ───────────────────────────
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")

-- ── Helper: section label (matches Item/Player tab style) ────
local function makeWoodSection(text)
    local lbl = Instance.new("TextLabel", woodPage)
    lbl.Size               = UDim2.new(1, -12, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 11
    lbl.TextColor3         = LABEL_DIM
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function makeWoodSep()
    local s = Instance.new("Frame", woodPage)
    s.Size             = UDim2.new(1, -12, 0, 1)
    s.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    s.BorderSizePixel  = 0
end

-- ── Tree Getter core state ────────────────────────────────────
local treeIsRunning   = false
local treeStop        = false
local treeTargetAmt   = 1
local treeActiveBtn   = nil

-- ── Gather tree regions & classes from workspace ─────────────
local treeRegions  = {}
local treeClasses  = {}

for _, obj in next, workspace:GetChildren() do
    if obj.Name == "TreeRegion" then
        table.insert(treeRegions, obj)
    end
end
for _, region in next, treeRegions do
    for _, obj in next, region:GetChildren() do
        if obj:FindFirstChild("TreeClass") and not table.find(treeClasses, obj.TreeClass.Value) then
            table.insert(treeClasses, obj.TreeClass.Value)
        end
    end
end

-- ── Core tree functions (ported from Pink_theme_tree_getter) ──
local axeClasses = ReplicatedStorage:WaitForChild("AxeClasses")

local function getAxeStats(axeName, treeClass)
    local module = axeClasses:FindFirstChild("AxeClass_" .. axeName)
    if not module then return end
    local stats = require(module).new()
    if stats.SpecialTrees and stats.SpecialTrees[treeClass] then
        for key, val in next, stats.SpecialTrees[treeClass] do stats[key] = val end
    end
    return stats
end

local function getModelMass(model)
    local total, woodSections = 0, 0
    for _, part in next, model:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= "Leaves" then
            if part.Name == "WoodSection" then woodSections += 1 end
            total += part.Mass
        end
    end
    return total, woodSections
end

local function getBestTreeOfClass(treeClass)
    local candidates = {}
    for _, region in next, treeRegions do
        for _, obj in next, region:GetChildren() do
            if obj:IsA("Model") and obj:FindFirstChild("CutEvent") then
                local classTag = obj:FindFirstChild("TreeClass")
                local owner    = obj:FindFirstChild("Owner")
                if owner and classTag and owner.Value == nil and classTag.Value == treeClass then
                    local mass, sections = getModelMass(obj)
                    if sections > 1 then
                        table.insert(candidates, { tree = obj, mass = mass })
                    end
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.mass > b.mass end)
    return candidates[1] and candidates[1].tree or false, "No tree found."
end

local function chopTree(tree, axe)
    task.wait()
    player.Character.HumanoidRootPart.CFrame = CFrame.new(tree.WoodSection.Position + Vector3.new(5, 0, 0))
    task.wait(0.25)
    local stats = getAxeStats(axe.ToolName.Value, tree.TreeClass.Value)
    local properties = {
        tool         = axe,
        height       = 0.3,
        faceVector   = Vector3.new(1, 0, 0),
        sectionId    = 1,
        hitPoints    = stats.Damage,
        cooldown     = stats.SwingCooldown,
        cuttingClass = "Axe"
    }
    local logModel, connection = nil, nil
    connection = workspace.LogModels.ChildAdded:Connect(function(log)
        task.wait()
        if log.Owner.Value == player then
            logModel = log
            connection:Disconnect()
        end
    end)
    repeat
        ReplicatedStorage.Interaction.RemoteProxy:FireServer(tree.CutEvent, properties)
        task.wait(stats.SwingCooldown)
    until logModel ~= nil
    return logModel
end

local function breakRootJoint()
    local rootJoint = player.Character.HumanoidRootPart.RootJoint
    rootJoint:Clone().Parent = rootJoint.Parent
    rootJoint:Destroy()
    task.wait()
end

local function bringTree(treeClass)
    local savedCFrame = player.Character.HumanoidRootPart.CFrame
    player.Character.Humanoid:UnequipTools()
    task.wait()

    local axeList = {}
    for _, item in next, player.Backpack:GetChildren() do
        if item.Name ~= "BlueprintTool" and item:FindFirstChild("ToolName") then
            local stats = getAxeStats(item.ToolName.Value, treeClass)
            if stats then table.insert(axeList, { axe = item, stats = stats }) end
        end
    end
    if #axeList == 0 then return false, "Please pick up an axe first." end
    table.sort(axeList, function(a, b) return a.stats.Damage > b.stats.Damage end)
    local bestAxe = axeList[1].axe

    local tree, msg = getBestTreeOfClass(treeClass)
    if not tree then return false, msg end

    if treeClass == "LoneCave" then
        if bestAxe.ToolName.Value ~= "EndTimesAxe" then
            return false, "End Times Axe required for this tree."
        end
        breakRootJoint()
    end

    local loopConn = nil
    if treeClass ~= "LoneCave" then
        loopConn = RunService.Heartbeat:Connect(function()
            player.Character.HumanoidRootPart.CFrame =
                CFrame.new(tree.WoodSection.Position + Vector3.new(5, 3, 0))
        end)
    end

    tree = chopTree(tree, bestAxe)
    if loopConn then loopConn:Disconnect() end

    task.wait(0.1)
    player.Character.HumanoidRootPart.CFrame = CFrame.new(tree.WoodSection.Position + Vector3.new(2, 0, 0))
    task.wait(0.1)

    task.spawn(function()
        for i = 1, 60 do
            ReplicatedStorage.Interaction.ClientIsDragging:FireServer(tree)
            task.wait()
        end
    end)

    task.wait(0.05)
    tree.PrimaryPart = tree.WoodSection
    for i = 1, 60 do
        tree.PrimaryPart.Velocity = Vector3.new(0, 0, 0)
        tree:PivotTo(savedCFrame)
        task.wait()
    end

    if treeClass == "LoneCave" then
        player.Character.Humanoid:UnequipTools()
        task.wait()
        player.Character.Head:Destroy()
        player.CharacterAdded:Wait()
        task.wait(1.5)
    end

    player.Character.HumanoidRootPart.CFrame = tree.WoodSection.CFrame
    return true, "Tree retrieved successfully!"
end

-- ── Notify helper ─────────────────────────────────────────────
local function treeNotify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = dur })
    end)
end

-- ════════════════════════════════════════════════════
-- WOOD TAB UI
-- ════════════════════════════════════════════════════

makeWoodSection("Amount")

-- Amount row card
local amtCard = Instance.new("Frame", woodPage)
amtCard.Size             = UDim2.new(1, -12, 0, 54)
amtCard.BackgroundColor3 = CARD_BG
amtCard.BorderSizePixel  = 0
Instance.new("UICorner", amtCard).CornerRadius = UDim.new(0, 8)

-- Minus button
local minusBtn = Instance.new("TextButton", amtCard)
minusBtn.Size             = UDim2.new(0, 32, 0, 32)
minusBtn.Position         = UDim2.new(0, 10, 0.5, -16)
minusBtn.BackgroundColor3 = BTN_COLOR
minusBtn.BorderSizePixel  = 0
minusBtn.Font             = Enum.Font.GothamBold
minusBtn.Text             = "−"
minusBtn.TextSize         = 20
minusBtn.TextColor3       = LABEL_MAIN
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 6)
minusBtn.MouseEnter:Connect(function() TweenService:Create(minusBtn, TweenInfo.new(0.12), {BackgroundColor3 = BTN_HOVER}):Play() end)
minusBtn.MouseLeave:Connect(function() TweenService:Create(minusBtn, TweenInfo.new(0.12), {BackgroundColor3 = BTN_COLOR}):Play() end)

-- Amount display (TextBox)
local amtBox = Instance.new("TextBox", amtCard)
amtBox.Size             = UDim2.new(1, -110, 0, 32)
amtBox.Position         = UDim2.new(0, 50, 0.5, -16)
amtBox.BackgroundColor3 = DARK_BG
amtBox.BorderSizePixel  = 0
amtBox.Font             = Enum.Font.GothamBold
amtBox.Text             = "1"
amtBox.TextSize         = 18
amtBox.TextColor3       = LABEL_MAIN
amtBox.ClearTextOnFocus = true
Instance.new("UICorner", amtBox).CornerRadius = UDim.new(0, 6)
local amtBoxStroke = Instance.new("UIStroke", amtBox)
amtBoxStroke.Color = Color3.fromRGB(50, 50, 70); amtBoxStroke.Thickness = 1; amtBoxStroke.Transparency = 0.5

-- Plus button
local plusBtn = Instance.new("TextButton", amtCard)
plusBtn.Size             = UDim2.new(0, 32, 0, 32)
plusBtn.Position         = UDim2.new(1, -42, 0.5, -16)
plusBtn.BackgroundColor3 = ACCENT
plusBtn.BorderSizePixel  = 0
plusBtn.Font             = Enum.Font.GothamBold
plusBtn.Text             = "+"
plusBtn.TextSize         = 20
plusBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 6)
plusBtn.MouseEnter:Connect(function() TweenService:Create(plusBtn, TweenInfo.new(0.12), {BackgroundColor3 = ACCENT_HOV}):Play() end)
plusBtn.MouseLeave:Connect(function() TweenService:Create(plusBtn, TweenInfo.new(0.12), {BackgroundColor3 = ACCENT}):Play() end)

-- Amount logic
local function clampAmt(v) return math.clamp(math.floor(tonumber(v) or 1), 1, 100) end
local function setAmt(v)
    treeTargetAmt  = clampAmt(v)
    amtBox.Text    = tostring(treeTargetAmt)
end
minusBtn.MouseButton1Click:Connect(function() setAmt(treeTargetAmt - 1) end)
plusBtn.MouseButton1Click:Connect(function()  setAmt(treeTargetAmt + 1) end)
amtBox.FocusLost:Connect(function() setAmt(amtBox.Text) end)

-- Hold-repeat
local function holdRepeat(btn, delta)
    btn.MouseButton1Down:Connect(function()
        task.wait(0.4)
        while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            setAmt(treeTargetAmt + delta)
            task.wait(0.07)
        end
    end)
end
holdRepeat(minusBtn, -1)
holdRepeat(plusBtn,   1)

-- Preset quick-select row
local presetRow = Instance.new("Frame", woodPage)
presetRow.Size               = UDim2.new(1, -12, 0, 28)
presetRow.BackgroundTransparency = 1
local presetLayout = Instance.new("UIListLayout", presetRow)
presetLayout.FillDirection        = Enum.FillDirection.Horizontal
presetLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
presetLayout.Padding              = UDim.new(0, 8)

for _, val in next, {10, 25, 50, 100} do
    local pb = Instance.new("TextButton", presetRow)
    pb.Size             = UDim2.new(0, 50, 1, 0)
    pb.BackgroundColor3 = CARD_BG2
    pb.BorderSizePixel  = 0
    pb.Font             = Enum.Font.GothamSemibold
    pb.Text             = tostring(val)
    pb.TextColor3       = LABEL_SUB
    pb.TextSize         = 13
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 6)
    local pbStroke = Instance.new("UIStroke", pb)
    pbStroke.Color = Color3.fromRGB(50, 50, 70); pbStroke.Thickness = 1; pbStroke.Transparency = 0.5
    pb.MouseEnter:Connect(function()
        TweenService:Create(pb, TweenInfo.new(0.12), {BackgroundColor3 = BTN_HOVER, TextColor3 = LABEL_MAIN}):Play()
        pbStroke.Transparency = 0.1
    end)
    pb.MouseLeave:Connect(function()
        TweenService:Create(pb, TweenInfo.new(0.12), {BackgroundColor3 = CARD_BG2, TextColor3 = LABEL_SUB}):Play()
        pbStroke.Transparency = 0.5
    end)
    pb.MouseButton1Click:Connect(function() setAmt(val) end)
end

makeWoodSep()
makeWoodSection("Status")

-- Status row
local statusCard = Instance.new("Frame", woodPage)
statusCard.Size             = UDim2.new(1, -12, 0, 44)
statusCard.BackgroundColor3 = DARK_BG
statusCard.BorderSizePixel  = 0
Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 8)

local statusDot = Instance.new("Frame", statusCard)
statusDot.Size             = UDim2.new(0, 8, 0, 8)
statusDot.Position         = UDim2.new(0, 10, 0.5, -4)
statusDot.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
statusDot.BorderSizePixel  = 0
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusLbl = Instance.new("TextLabel", statusCard)
statusLbl.Size             = UDim2.new(0.6, -30, 0, 18)
statusLbl.Position         = UDim2.new(0, 26, 0.5, -9)
statusLbl.BackgroundTransparency = 1
statusLbl.Font             = Enum.Font.Gotham
statusLbl.TextSize         = 12
statusLbl.TextColor3       = LABEL_SUB
statusLbl.TextXAlignment   = Enum.TextXAlignment.Left
statusLbl.Text             = "Ready"

local progressCountLbl = Instance.new("TextLabel", statusCard)
progressCountLbl.Size            = UDim2.new(0.4, -10, 0, 18)
progressCountLbl.Position        = UDim2.new(0.6, 0, 0.5, -9)
progressCountLbl.BackgroundTransparency = 1
progressCountLbl.Font            = Enum.Font.GothamBold
progressCountLbl.TextSize        = 12
progressCountLbl.TextColor3      = FILL_COLOR
progressCountLbl.TextXAlignment  = Enum.TextXAlignment.Right
progressCountLbl.Text            = "0 / 0"

-- Progress bar
local pbTrack = Instance.new("Frame", woodPage)
pbTrack.Size             = UDim2.new(1, -12, 0, 10)
pbTrack.BackgroundColor3 = DARK_BG
pbTrack.BorderSizePixel  = 0
Instance.new("UICorner", pbTrack).CornerRadius = UDim.new(1, 0)

local pbFill = Instance.new("Frame", pbTrack)
pbFill.Size             = UDim2.new(0, 0, 1, 0)
pbFill.BackgroundColor3 = FILL_COLOR
pbFill.BorderSizePixel  = 0
Instance.new("UICorner", pbFill).CornerRadius = UDim.new(1, 0)

-- Shimmer on progress fill
local pbShimmer = Instance.new("Frame", pbFill)
pbShimmer.Size               = UDim2.new(0.5, 0, 1, 0)
pbShimmer.Position           = UDim2.new(-0.5, 0, 0, 0)
pbShimmer.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
pbShimmer.BackgroundTransparency = 0.75
pbShimmer.BorderSizePixel    = 0
pbShimmer.ZIndex             = 2
Instance.new("UICorner", pbShimmer).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    while true do
        task.wait()
        if pbFill.Size.X.Scale > 0.05 then
            local t = TweenService:Create(pbShimmer,
                TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Position = UDim2.new(1.2, 0, 0, 0) })
            t:Play(); t.Completed:Wait()
            pbShimmer.Position = UDim2.new(-0.5, 0, 0, 0)
        else
            task.wait(0.5)
        end
    end
end)

-- UI helpers
local function treeSetStatus(msg, color)
    statusLbl.Text      = msg
    statusLbl.TextColor3 = color or LABEL_SUB
    statusDot.BackgroundColor3 = treeIsRunning
        and Color3.fromRGB(80, 200, 120)
        or  Color3.fromRGB(80, 80, 100)
end

local function treeSetProgress(done, total)
    local pct = total > 0 and (done / total) or 0
    local green = Color3.fromRGB(60, 200, 110)
    local blue  = FILL_COLOR
    local col   = pct >= 1 and green or Color3.fromRGB(
        math.floor(blue.R*255 + (green.R*255 - blue.R*255)*pct) / 255,
        math.floor(blue.G*255 + (green.G*255 - blue.G*255)*pct) / 255,
        math.floor(blue.B*255 + (green.B*255 - blue.B*255)*pct) / 255
    )
    TweenService:Create(pbFill, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = col,
    }):Play()
    progressCountLbl.Text = done .. " / " .. total
    statusDot.BackgroundColor3 = treeIsRunning
        and Color3.fromRGB(80, 200, 120)
        or  Color3.fromRGB(80, 80, 100)
end

makeWoodSep()
makeWoodSection("Tree Classes")

-- ── Tree class buttons ────────────────────────────────────────
local function addTreeButton(treeClass)
    local row = Instance.new("Frame", woodPage)
    row.Size             = UDim2.new(1, -12, 0, 36)
    row.BackgroundColor3 = CARD_BG
    row.BorderSizePixel  = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local tBtn = Instance.new("TextButton", row)
    tBtn.Size             = UDim2.new(1, -68, 1, 0)
    tBtn.Position         = UDim2.new(0, 0, 0, 0)
    tBtn.BackgroundTransparency = 1
    tBtn.Font             = Enum.Font.GothamSemibold
    tBtn.Text             = treeClass
    tBtn.TextSize         = 13
    tBtn.TextColor3       = LABEL_MAIN
    tBtn.TextXAlignment   = Enum.TextXAlignment.Left
    Instance.new("UIPadding", tBtn).PaddingLeft = UDim.new(0, 12)

    -- Stop button (hidden until run starts for this tree)
    local stopBtn = Instance.new("TextButton", row)
    stopBtn.Size             = UDim2.new(0, 52, 0, 24)
    stopBtn.Position         = UDim2.new(1, -60, 0.5, -12)
    stopBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
    stopBtn.BorderSizePixel  = 0
    stopBtn.Font             = Enum.Font.GothamBold
    stopBtn.Text             = "STOP"
    stopBtn.TextSize         = 11
    stopBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    stopBtn.Visible          = false
    Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)
    stopBtn.MouseEnter:Connect(function()
        TweenService:Create(stopBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(210, 60, 60)}):Play()
    end)
    stopBtn.MouseLeave:Connect(function()
        TweenService:Create(stopBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(180, 45, 45)}):Play()
    end)
    stopBtn.MouseButton1Click:Connect(function()
        treeStop = true
        treeSetStatus("Stopping...", Color3.fromRGB(255, 100, 100))
    end)

    -- Row hover (only when not running)
    tBtn.MouseEnter:Connect(function()
        if not treeIsRunning then
            TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = CARD_BG2}):Play()
            TweenService:Create(tBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end
    end)
    tBtn.MouseLeave:Connect(function()
        if treeActiveBtn ~= tBtn then
            TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = CARD_BG}):Play()
            TweenService:Create(tBtn, TweenInfo.new(0.15), {TextColor3 = LABEL_MAIN}):Play()
        end
    end)

    tBtn.MouseButton1Click:Connect(function()
        if treeIsRunning then return end

        local amount      = treeTargetAmt
        treeIsRunning     = true
        treeStop          = false
        treeActiveBtn     = tBtn

        -- Active visual
        TweenService:Create(row, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 50)}):Play()
        TweenService:Create(tBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        stopBtn.Visible = true
        treeSetProgress(0, amount)
        treeSetStatus("Starting...", Color3.fromRGB(200, 200, 100))

        task.spawn(function()
            local completed, failed = 0, 0

            for i = 1, amount do
                if treeStop then break end

                treeSetStatus("Fetching " .. i .. " / " .. amount .. "...", Color3.fromRGB(180, 200, 255))

                local ok, msg = bringTree(treeClass)

                if ok then
                    completed += 1
                else
                    failed += 1
                    if msg == "Please pick up an axe first." or msg == "End Times Axe required for this tree." then
                        treeSetStatus("Error: " .. msg, Color3.fromRGB(255, 80, 80))
                        break
                    end
                    task.wait(1)
                end

                treeSetProgress(i, amount)
                task.wait(0.1)
            end

            -- Finished
            treeIsRunning = false
            treeStop      = false
            treeActiveBtn = nil
            stopBtn.Visible = false

            TweenService:Create(row, TweenInfo.new(0.25), {BackgroundColor3 = CARD_BG}):Play()
            TweenService:Create(tBtn, TweenInfo.new(0.25), {TextColor3 = LABEL_MAIN}):Play()

            if completed == amount then
                treeSetStatus("Done! Got " .. completed .. " trees ✓", Color3.fromRGB(80, 220, 130))
                treeSetProgress(amount, amount)
                treeNotify("Tree Getter", "All " .. amount .. " trees retrieved!", 6)
            else
                treeSetStatus("Stopped. Got " .. completed .. " trees.", Color3.fromRGB(220, 150, 80))
                treeNotify("Tree Getter", completed .. "/" .. amount .. " trees retrieved.", 5)
            end

            task.wait(3.5)
            treeSetStatus("Ready", LABEL_SUB)
            treeSetProgress(0, 0)
            progressCountLbl.Text = "0 / 0"
        end)
    end)
end

if #treeClasses > 0 then
    for _, tc in next, treeClasses do addTreeButton(tc) end
else
    -- Fallback label if no trees found
    local noLbl = Instance.new("TextLabel", woodPage)
    noLbl.Size               = UDim2.new(1, -12, 0, 32)
    noLbl.BackgroundColor3   = DARK_BG
    noLbl.Font               = Enum.Font.Gotham
    noLbl.TextSize           = 13
    noLbl.TextColor3         = LABEL_DIM
    noLbl.Text               = "No tree classes found in workspace."
    noLbl.TextXAlignment     = Enum.TextXAlignment.Center
    Instance.new("UICorner", noLbl).CornerRadius = UDim.new(0, 6)
end

-- Cleanup: stop any running tree session on hub close
table.insert(cleanupTasks, function()
    treeIsRunning = false
    treeStop      = true
end)

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════
local settingsPage = pages["SettingsTab"]

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size             = UDim2.new(1, 0, 0, 70)
kbFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
kbFrame.BorderSizePixel  = 0
Instance.new("UICorner", kbFrame).CornerRadius = UDim.new(0, 10)

local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size             = UDim2.new(1, -20, 0, 28)
kbTitle.Position         = UDim2.new(0, 10, 0, 8)
kbTitle.BackgroundTransparency = 1
kbTitle.Font             = Enum.Font.GothamBold
kbTitle.TextSize         = 15
kbTitle.TextColor3       = Color3.fromRGB(220, 220, 220)
kbTitle.TextXAlignment   = Enum.TextXAlignment.Left
kbTitle.Text             = "GUI Toggle Keybind"

keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size             = UDim2.new(0, 200, 0, 28)
keybindButtonGUI.Position         = UDim2.new(0, 10, 0, 36)
keybindButtonGUI.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
keybindButtonGUI.BorderSizePixel  = 0
keybindButtonGUI.Font             = Enum.Font.Gotham
keybindButtonGUI.TextSize         = 14
keybindButtonGUI.TextColor3       = Color3.fromRGB(200, 200, 200)
keybindButtonGUI.Text             = "Toggle Key: " .. getCurrentToggleKey().Name
Instance.new("UICorner", keybindButtonGUI).CornerRadius = UDim.new(0, 8)

keybindButtonGUI.MouseButton1Click:Connect(function()
    if getWaitingForKeyGUI() then return end
    keybindButtonGUI.Text = "Press any key..."
    setWaitingForKeyGUI(true)
end)
keybindButtonGUI.MouseEnter:Connect(function()
    TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
end)
keybindButtonGUI.MouseLeave:Connect(function()
    TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
end)

-- ════════════════════════════════════════════════════
-- SEARCH TAB
-- ════════════════════════════════════════════════════
local searchPage = pages["SearchTab"]

local searchInput = Instance.new("TextBox", searchPage)
searchInput.Size             = UDim2.new(1, -28, 0, 42)
searchInput.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
searchInput.PlaceholderText  = "🔍 Search for functions or tabs..."
searchInput.Text             = ""
searchInput.Font             = Enum.Font.GothamSemibold
searchInput.TextSize         = 15
searchInput.TextColor3       = Color3.fromRGB(220, 220, 220)
searchInput.TextXAlignment   = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false
Instance.new("UICorner", searchInput).CornerRadius = UDim.new(0, 10)
Instance.new("UIPadding", searchInput).PaddingLeft = UDim.new(0, 14)

local function updateSearchResults(query)
    for _, child in ipairs(searchPage:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local lq = string.lower(query or "")

    local functions = {
        {"Fly", "PlayerTab"}, {"Noclip", "PlayerTab"}, {"InfJump", "PlayerTab"},
        {"Walkspeed", "PlayerTab"}, {"Jump Power", "PlayerTab"}, {"Fly Speed", "PlayerTab"},
        {"Fly Key", "PlayerTab"},
        {"Teleport Locations", "TeleportTab"}, {"Quick Teleport", "TeleportTab"},
        {"Spawn", "TeleportTab"}, {"Wood Dropoff", "TeleportTab"}, {"Land Store", "TeleportTab"},
        {"Teleport Selected Items", "ItemTab"}, {"Group Selection", "ItemTab"},
        {"Click Selection", "ItemTab"}, {"Lasso Tool", "ItemTab"},
        {"Clear Selection", "ItemTab"}, {"Set Destination", "ItemTab"},
        {"GUI Keybind", "SettingsTab"},
        {"Home", "HomeTab"}, {"Ping", "HomeTab"}, {"Rejoin", "HomeTab"},
        {"Tree Getter", "WoodTab"}, {"Chop Tree", "WoodTab"}, {"Bring Tree", "WoodTab"},
        {"Tree Amount", "WoodTab"}, {"Tree Classes", "WoodTab"},
    }

    local seen = {}
    for _, name in ipairs(tabs) do
        if lq == "" or string.find(string.lower(name), lq) then
            if not seen[name .. "Tab"] then
                seen[name .. "Tab"] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size             = UDim2.new(1, -28, 0, 42)
                resBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
                resBtn.Text             = "📂  " .. name .. " Tab"
                resBtn.Font             = Enum.Font.GothamSemibold
                resBtn.TextSize         = 15
                resBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
                resBtn.TextXAlignment   = Enum.TextXAlignment.Left
                Instance.new("UIPadding", resBtn).PaddingLeft = UDim.new(0, 16)
                Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0, 10)
                resBtn.MouseEnter:Connect(function()
                    TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 45), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                end)
                resBtn.MouseLeave:Connect(function()
                    TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 22, 28), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
                end)
                resBtn.MouseButton1Click:Connect(function() switchTab(name .. "Tab") end)
            end
        end
    end

    if lq ~= "" then
        for _, entry in ipairs(functions) do
            local fname, ftab = entry[1], entry[2]
            if string.find(string.lower(fname), lq) and not seen[fname] then
                seen[fname] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size             = UDim2.new(1, -28, 0, 42)
                resBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
                resBtn.Text             = "⚙  " .. fname
                resBtn.Font             = Enum.Font.GothamSemibold
                resBtn.TextSize         = 15
                resBtn.TextColor3       = Color3.fromRGB(180, 210, 255)
                resBtn.TextXAlignment   = Enum.TextXAlignment.Left
                Instance.new("UIPadding", resBtn).PaddingLeft = UDim.new(0, 16)
                Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0, 10)
                local subLbl = Instance.new("TextLabel", resBtn)
                subLbl.Size             = UDim2.new(1, -20, 0, 16)
                subLbl.Position         = UDim2.new(0, 36, 1, -18)
                subLbl.BackgroundTransparency = 1
                subLbl.Font             = Enum.Font.Gotham
                subLbl.TextSize         = 11
                subLbl.TextColor3       = Color3.fromRGB(120, 120, 150)
                subLbl.TextXAlignment   = Enum.TextXAlignment.Left
                subLbl.Text             = "in " .. ftab:gsub("Tab", "") .. " tab"
                resBtn.MouseEnter:Connect(function()
                    TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 35, 52), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                end)
                resBtn.MouseLeave:Connect(function()
                    TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 22, 30), TextColor3 = Color3.fromRGB(180, 210, 255)}):Play()
                end)
                resBtn.MouseButton1Click:Connect(function() switchTab(ftab) end)
            end
        end
    end
end

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
    updateSearchResults(searchInput.Text)
end)
task.delay(0.1, function() updateSearchResults("") end)

-- ════════════════════════════════════════════════════
-- UNIFIED INPUT HANDLER
-- ════════════════════════════════════════════════════
local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if not _G.VH then return end

    if getWaitingForKeyGUI() then
        setWaitingForKeyGUI(false)
        setCurrentToggleKey(input.KeyCode)
        if keybindButtonGUI and keybindButtonGUI.Parent then
            keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
            TweenService:Create(keybindButtonGUI,
                TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true),
                { BackgroundColor3 = Color3.fromRGB(60, 180, 60) }
            ):Play()
        end
        return
    end

    if getWaitingForFlyKey() then
        setWaitingForFlyKey(false)
        setCurrentFlyKey(input.KeyCode)
        if flyKeyBtn and flyKeyBtn.Parent then
            flyKeyBtn.Text             = input.KeyCode.Name
            flyKeyBtn.BackgroundColor3 = BTN_COLOR
        end
        return
    end

    if input.KeyCode == getCurrentToggleKey() then
        toggleGUI()
        return
    end

    if input.KeyCode == getCurrentFlyKey() and getFlyToggleEnabled() then
        if getIsFlyEnabled() then stopFly() else startFly() end
    end
end)

table.insert(cleanupTasks, function()
    if inputConn then inputConn:Disconnect(); inputConn = nil end
end)

_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded")
