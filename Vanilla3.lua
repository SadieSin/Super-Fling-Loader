-- ════════════════════════════════════════════════════
-- VANILLA3 — FULL REWRITE (Aggressive Bypass Edition)
-- Complete rewrite of tree cutting + log dragging
-- Uses sethiddenproperty, firetouchinterest, and
-- direct CFrame manipulation to bypass all checks
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
local THEME_TEXT       = _G.VH.THEME_TEXT or Color3.fromRGB(230, 206, 226)
local switchTab        = _G.VH.switchTab
local toggleGUI        = _G.VH.toggleGUI
local stopFly          = _G.VH.stopFly
local startFly         = _G.VH.startFly
local flyKeyBtn        = _G.VH.flyKeyBtn

local RS = game:GetService("ReplicatedStorage")
local WS = workspace
local AxeClassesFolder = RS:WaitForChild("AxeClasses")

-- ── Key state getters/setters ───────────────────────
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
-- UI HELPERS
-- ════════════════════════════════════════════════════

local woodPage  = pages["WoodTab"]
local woodMouse = player:GetMouse()

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function createWSectionLabel(text)
    local lbl = Instance.new("TextLabel", woodPage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function createWSep()
    local s = Instance.new("Frame", woodPage)
    s.Size = UDim2.new(1,-12,0,1); s.BackgroundColor3 = Color3.fromRGB(40,40,55); s.BorderSizePixel = 0
end

local function createWToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", woodPage)
    frame.Size = UDim2.new(1,-12,0,32); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    corner(frame, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0,34,0,18); tb.Position = UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3 = defaultState and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text = ""; corner(tb, 9)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0,14,0,14); circle.Position = UDim2.new(0, defaultState and 18 or 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255); corner(circle, 7)
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

local function createWButton(text, color, callback)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", woodPage)
    btn.Size = UDim2.new(1,-12,0,32); btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    corner(btn, 6)
    local hov = Color3.fromRGB(
        math.min(color.R*255+20,255)/255,
        math.min(color.G*255+8, 255)/255,
        math.min(color.B*255+20,255)/255)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=hov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=color}):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createWInfoLabel(text)
    local lbl = Instance.new("TextLabel", woodPage)
    lbl.Size = UDim2.new(1,-12,0,30); lbl.BackgroundColor3 = Color3.fromRGB(18,18,24)
    lbl.BorderSizePixel = 0; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text
    corner(lbl, 6); Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,6)
end

local function createWStatusLabel(initText)
    local f = Instance.new("Frame", woodPage)
    f.Size = UDim2.new(1,-12,0,28); f.BackgroundColor3 = Color3.fromRGB(22,22,28)
    f.BorderSizePixel = 0; corner(f, 6)
    local dot = Instance.new("Frame", f)
    dot.Size = UDim2.new(0,7,0,7); dot.Position = UDim2.new(0,10,0.5,-3)
    dot.BackgroundColor3 = Color3.fromRGB(80,80,100); dot.BorderSizePixel = 0; corner(dot, 4)
    local lb = Instance.new("TextLabel", f)
    lb.Size = UDim2.new(1,-26,1,0); lb.Position = UDim2.new(0,22,0,0)
    lb.BackgroundTransparency = 1; lb.Font = Enum.Font.Gotham; lb.TextSize = 12
    lb.TextColor3 = Color3.fromRGB(150,130,170); lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Text = initText
    return {
        SetActive = function(on, msg)
            dot.BackgroundColor3 = on and Color3.fromRGB(60,200,60) or Color3.fromRGB(80,80,100)
            if msg then lb.Text = msg end
        end
    }
end

local function makeFancyDropdown(page, labelText, getOptions, cb)
    local selected  = ""
    local isOpen    = false
    local ITEM_H    = 34
    local MAX_SHOW  = 5
    local HEADER_H  = 40

    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1,-12,0,HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22,22,30)
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    corner(outer, 8)
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
    corner(selFrame, 6)

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size = UDim2.new(1,-36,1,0); selLbl.Position = UDim2.new(0,10,0,0)
    selLbl.BackgroundTransparency = 1; selLbl.Text = "Select..."
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
    listScroll.ScrollBarThickness = 3; listScroll.CanvasSize = UDim2.new(0,0,0,0)
    listScroll.ClipsDescendants = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local lp2 = Instance.new("UIPadding", listScroll)
    lp2.PaddingTop=UDim.new(0,4); lp2.PaddingBottom=UDim.new(0,4)
    lp2.PaddingLeft=UDim.new(0,6); lp2.PaddingRight=UDim.new(0,6)

    local function setSelected(name)
        selected = name; selLbl.Text = name; selLbl.TextColor3 = THEME_TEXT
        arrowLbl.TextColor3 = Color3.fromRGB(160,160,210)
        outerStroke.Color = Color3.fromRGB(90,90,160)
        cb(name)
    end

    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local opts = getOptions()
        for _, opt in ipairs(opts) do
            local item = Instance.new("TextButton", listScroll)
            item.Size = UDim2.new(1,0,0,ITEM_H); item.BackgroundColor3 = Color3.fromRGB(28,28,40)
            item.Text = ""; item.BorderSizePixel = 0; corner(item, 6)
            local iLbl = Instance.new("TextLabel", item)
            iLbl.Size = UDim2.new(1,-16,1,0); iLbl.Position = UDim2.new(0,10,0,0)
            iLbl.BackgroundTransparency = 1; iLbl.Text = opt
            iLbl.Font = Enum.Font.GothamSemibold; iLbl.TextSize = 12
            iLbl.TextColor3 = THEME_TEXT; iLbl.TextXAlignment = Enum.TextXAlignment.Left
            iLbl.TextTruncate = Enum.TextTruncate.AtEnd
            item.MouseEnter:Connect(function()
                TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play()
            end)
            item.MouseLeave:Connect(function()
                TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(28,28,40)}):Play()
            end)
            item.MouseButton1Click:Connect(function()
                setSelected(opt); isOpen = false
                TweenService:Create(arrowLbl,   TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
                TweenService:Create(outer,      TweenInfo.new(0.22,Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
                TweenService:Create(listScroll, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
                divider.Visible = false
            end)
        end
        return #opts
    end

    local function openList()
        isOpen = true
        local count = buildList()
        local listH = math.min(count, MAX_SHOW) * (ITEM_H+3) + 8
        divider.Visible = true
        TweenService:Create(arrowLbl,   TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=180}):Play()
        TweenService:Create(outer,      TweenInfo.new(0.25,Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H+2+listH)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.25,Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,listH)}):Play()
    end

    local function closeList()
        isOpen = false
        TweenService:Create(arrowLbl,   TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
        TweenService:Create(outer,      TweenInfo.new(0.22,Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end

    headerBtn.MouseButton1Click:Connect(function() if isOpen then closeList() else openList() end end)
    headerBtn.MouseEnter:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(30,30,42)}):Play()
    end)

    return {
        GetSelected = function() return selected end,
        Refresh = function()
            if isOpen then
                local count = buildList()
                local listH = math.min(count, MAX_SHOW) * (ITEM_H+3) + 8
                outer.Size = UDim2.new(1,-12,0,HEADER_H+2+listH)
                listScroll.Size = UDim2.new(1,0,0,listH)
            end
        end
    }
end

-- ════════════════════════════════════════════════════
-- CORE HELPERS
-- ════════════════════════════════════════════════════

local SELL_POS = Vector3.new(315.14, -0.40, 86.32)

local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function safeTP(cf)
    local hrp = getHRP()
    if hrp then pcall(function() hrp.CFrame = cf end) end
end

-- Aggressive network ownership claim — fires drag many times rapidly
local function claimNetworkOwner(part, timeout)
    timeout = timeout or 5
    local t0 = tick()
    repeat
        pcall(function() RS.Interaction.ClientIsDragging:FireServer(part.Parent or part) end)
        pcall(function() RS.Interaction.ClientIsDragging:FireServer(part.Parent or part) end)
        pcall(function() RS.Interaction.ClientIsDragging:FireServer(part.Parent or part) end)
        task.wait(0.03)
    until (tick()-t0 > timeout) or pcall(function()
        assert(part.ReceiveAge == 0)
    end)
end

-- Force a model to a position, many times
local function forceModelCF(model, targetCF, iters, waitTime)
    iters = iters or 60
    waitTime = waitTime or 0
    local pp = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not pp then return end
    for _ = 1, iters do
        pcall(function()
            RS.Interaction.ClientIsDragging:FireServer(model)
            RS.Interaction.ClientIsDragging:FireServer(model)
            model:SetPrimaryPartCFrame(targetCF)
        end)
        if waitTime > 0 then task.wait(waitTime) end
    end
end

-- ════════════════════════════════════════════════════
-- AXE HELPERS
-- ════════════════════════════════════════════════════

local function getToolStats(tool)
    local name = (type(tool) ~= "string") and tool.ToolName.Value or tool
    return require(AxeClassesFolder["AxeClass_"..name]).new()
end

local function getTools()
    if player.Character and player.Character:FindFirstChild("Tool") then
        player.Character.Humanoid:UnequipTools()
    end
    local tools = {}
    for _, v in ipairs(player.Backpack:GetChildren()) do
        if v.Name ~= "BlueprintTool" and v.Name ~= "Delete" and v.Name ~= "Undo" then
            tools[#tools+1] = v
        end
    end
    return tools
end

local function getBestAxeForTree(treeClass)
    local tools = getTools()
    if #tools == 0 then return nil, "Need Axe" end
    if treeClass == "LoneCave" then
        for _, v in ipairs(tools) do
            if v.ToolName and v.ToolName.Value == "EndTimesAxe" then return v, nil end
        end
        return nil, "Need EndTimesAxe"
    end
    local best, bestDmg = nil, 0
    for _, v in ipairs(tools) do
        local ok, stats = pcall(getToolStats, v)
        if ok then
            local dmg = stats.Damage or 1
            if stats.SpecialTrees and stats.SpecialTrees[treeClass] then
                dmg = stats.SpecialTrees[treeClass].Damage or dmg
            end
            if dmg > bestDmg then bestDmg = dmg; best = v end
        end
    end
    return best, best and nil or "No axe found"
end

local function cutPart(event, sectionId, height, tool, treeClass)
    if not (event and tool) then return end
    local ok, stats = pcall(getToolStats, tool)
    if not ok then return end
    if stats.SpecialTrees and stats.SpecialTrees[treeClass] then
        for k,v in pairs(stats.SpecialTrees[treeClass]) do stats[k] = v end
    end
    pcall(function()
        RS.Interaction.RemoteProxy:FireServer(event, {
            tool         = tool,
            faceVector   = Vector3.new(-1,0,0),
            height       = height or 0.3,
            sectionId    = sectionId or 1,
            hitPoints    = stats.Damage or 1,
            cooldown     = stats.SwingCooldown or 0.25,
            cuttingClass = "Axe",
        })
    end)
end

-- ════════════════════════════════════════════════════
-- TREE SCANNER
-- ════════════════════════════════════════════════════

-- Scan ALL workspace children for trees, no region restriction
local function findBestTree(treeClass)
    local best = nil
    local bestMass = 0

    -- Search everywhere: TreeRegion folders and raw workspace
    local function scanContainer(container)
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("TreeClass")
               and v.TreeClass.Value == treeClass
               and v:FindFirstChild("Owner")
               and (v.Owner.Value == nil or v.Owner.Value == player) then
                -- find trunk (ID==1) and calculate mass
                local trunk = nil
                local mass  = 0
                for _, p in ipairs(v:GetDescendants()) do
                    if p:IsA("BasePart") then
                        mass = mass + p.Size.X * p.Size.Y * p.Size.Z
                        if p:FindFirstChild("ID") and p.ID.Value == 1 then trunk = p end
                    end
                end
                -- fallback: largest base part
                if not trunk then
                    local biggestVol = 0
                    for _, p in ipairs(v:GetDescendants()) do
                        if p:IsA("BasePart") then
                            local vol = p.Size.X * p.Size.Y * p.Size.Z
                            if vol > biggestVol then biggestVol = vol; trunk = p end
                        end
                    end
                end
                if trunk and mass > bestMass then
                    bestMass = mass
                    best = {tree=v, trunk=trunk}
                end
            end
        end
    end

    for _, child in ipairs(WS:GetChildren()) do
        if child.Name:find("Region") or child.Name:find("Tree") or child.Name:find("Forest") then
            scanContainer(child)
        end
    end
    -- Also scan direct workspace children
    scanContainer(WS)

    return best
end

-- ════════════════════════════════════════════════════
-- GLOBAL STOP FLAGS
-- ════════════════════════════════════════════════════

getgenv().treestop = true
getgenv().doneend  = true

local globalAbort = false

-- ════════════════════════════════════════════════════
-- BRING TREE — FULL REWRITE (Aggressive Bypass)
-- Strategy:
--   1. Find tree trunk
--   2. Hook ChildAdded on LogModels FIRST
--   3. Teleport player on top of trunk every frame
--   4. Spam cutPart until log spawns
--   5. Once log spawns, spam drag it to player origin
-- ════════════════════════════════════════════════════

local function bringTree(treeClass, statusCallback)
    if globalAbort then return false end

    player.Character.Humanoid.BreakJointsOnDeath = false

    local tool, err = getBestAxeForTree(treeClass)
    if not tool then
        warn("[VH] bringTree: "..(err or "no tool"))
        if statusCallback then statusCallback("No axe: "..(err or "")) end
        return false
    end

    local treeData = findBestTree(treeClass)
    if not treeData then
        warn("[VH] bringTree: no tree found for "..treeClass)
        if statusCallback then statusCallback("No tree found for "..treeClass) end
        return false
    end

    local trunk = treeData.trunk
    local tree  = treeData.tree

    -- Make sure tree has a PrimaryPart set
    if not tree.PrimaryPart then
        tree.PrimaryPart = trunk
    end

    local originCF = getHRP() and getHRP().CFrame or CFrame.new(0,5,0)
    if statusCallback then statusCallback("Cutting: "..treeClass) end

    -- ── Step 1: Teleport onto trunk ──
    safeTP(trunk.CFrame * CFrame.new(0, 2, 3))
    task.wait(0.2)

    -- ── Step 2: Hook log spawn listener BEFORE cutting ──
    local logSpawned   = false
    local spawnedLog   = nil
    local logConn

    logConn = WS.LogModels.ChildAdded:Connect(function(log)
        task.spawn(function()
            -- Wait for Owner value to replicate (up to 3s)
            local t0 = tick()
            repeat task.wait(0.05) until
                log:FindFirstChild("Owner") or (tick()-t0 > 3)

            local ownerVal = log:FindFirstChild("Owner")
            local tcVal    = log:FindFirstChild("TreeClass")

            -- Accept log if owned by us OR unowned (server sometimes delays ownership assignment)
            local ownedByUs  = ownerVal and ownerVal.Value == player
            local rightClass = tcVal and tcVal.Value == treeClass

            if rightClass and (ownedByUs or not ownerVal or ownerVal.Value == nil) then
                if logConn then logConn:Disconnect(); logConn = nil end
                logSpawned = true
                spawnedLog = log

                -- Set PrimaryPart immediately
                if not log.PrimaryPart then
                    log.PrimaryPart = log:FindFirstChild("WoodSection")
                        or log:FindFirstChildWhichIsA("BasePart")
                end

                -- ── Aggressively drag log to origin ──
                local logPP = log.PrimaryPart
                if logPP then
                    local t1 = tick()
                    repeat
                        pcall(function()
                            RS.Interaction.ClientIsDragging:FireServer(log)
                            RS.Interaction.ClientIsDragging:FireServer(log)
                            RS.Interaction.ClientIsDragging:FireServer(log)
                            log:SetPrimaryPartCFrame(originCF * CFrame.new(0,2,0))
                        end)
                        task.wait(0.03)
                    until not log.Parent or (tick()-t1 > 12)
                end
            end
        end)
    end)

    -- ── Step 3: Cut loop — spam cuts + keep player glued to trunk ──
    local cutTimeout = treeClass == "LoneCave" and 90 or 45
    local t0 = tick()
    local cutEvent = tree:FindFirstChild("CutEvent")

    repeat
        if globalAbort then break end
        if not cutEvent then cutEvent = tree:FindFirstChild("CutEvent") end

        -- Re-anchor player to trunk every iteration
        pcall(function()
            local hrp = getHRP()
            if hrp then hrp.CFrame = trunk.CFrame * CFrame.new(0, 2, 3) end
        end)

        -- Spam cut from multiple sections/heights for reliability
        for section = 1, 3 do
            if cutEvent then
                cutPart(cutEvent, section, 0.1 * section, tool, treeClass)
                cutPart(cutEvent, section, 0.5,            tool, treeClass)
            end
        end

        task.wait(0.06)
    until logSpawned or globalAbort or (tick()-t0 > cutTimeout) or not tree.Parent

    if logConn then logConn:Disconnect(); logConn = nil end

    -- ── Step 4: Return player to origin ──
    task.wait(0.5)
    safeTP(originCF)

    if logSpawned then
        if statusCallback then statusCallback("Log delivered!") end
        return true
    else
        if statusCallback then statusCallback("Cut timeout / aborted") end
        return false
    end
end

-- ════════════════════════════════════════════════════
-- BRING ALL LOGS
-- ════════════════════════════════════════════════════

local function BringAllLogs()
    local origin = getHRP() and getHRP().CFrame or CFrame.new(0,5,0)
    for _, log in ipairs(WS.LogModels:GetChildren()) do
        if log:FindFirstChild("Owner") and log.Owner.Value == player then
            if not log.PrimaryPart then
                log.PrimaryPart = log:FindFirstChild("WoodSection")
                    or log:FindFirstChildWhichIsA("BasePart")
            end
            local pp = log.PrimaryPart
            if pp then
                local logOriginCF = pp.CFrame
                safeTP(CFrame.new(logOriginCF.p))
                forceModelCF(log, origin * CFrame.new(0,2,0), 60, 0.03)
            end
        end
        task.wait(0.05)
    end
    safeTP(origin)
end

-- ════════════════════════════════════════════════════
-- SELL ALL LOGS — Aggressive drag to sell zone
-- ════════════════════════════════════════════════════

local SELL_CF = CFrame.new(314, -0.5, 86.822)

local function SellAllLogs()
    local origin = getHRP() and getHRP().CFrame or CFrame.new(0,5,0)
    for _, log in ipairs(WS.LogModels:GetChildren()) do
        if log:FindFirstChild("Owner") and log.Owner.Value == player then
            if not log.PrimaryPart then
                log.PrimaryPart = log:FindFirstChild("WoodSection")
                    or log:FindFirstChildWhichIsA("BasePart")
            end
            local pp = log.PrimaryPart
            if pp then
                -- Teleport player near log first
                safeTP(CFrame.new(pp.CFrame.p) * CFrame.new(0,2,3))
                task.wait(0.1)
                -- Drag to sell zone aggressively
                forceModelCF(log, SELL_CF, 80, 0.02)
            end
        end
        task.wait(0.05)
    end
    task.wait(0.5)
    safeTP(origin)
end

-- ════════════════════════════════════════════════════
-- SELL SELECTED ENGINE
-- ════════════════════════════════════════════════════

local SELL_CONFIRM    = 6
local SELL_TIMEOUT    = 5.0
local woodSelected    = {}
local clickSellEnabled   = false
local groupSelectEnabled = false
local isSellRunning      = false
local sellOriginCF       = nil
local currentSellConn    = nil
local clickSellBusy      = false
local clickSellConn      = nil

local function isWoodLog(model)
    if not model or not model:IsA("Model") then return false end
    if not model:FindFirstChild("TreeClass")  then return false end
    if model:FindFirstChild("DraggableItem")  then return false end
    if not (model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")) then return false end
    return true
end

local function highlightWood(model)
    if woodSelected[model] then return end
    local hl = Instance.new("SelectionBox")
    hl.Color3 = Color3.fromRGB(0,220,80); hl.LineThickness = 0.06
    hl.SurfaceTransparency = 0.7; hl.SurfaceColor3 = Color3.fromRGB(0,220,80)
    hl.Adornee = model; hl.Parent = model
    woodSelected[model] = hl
end

local function unhighlightWood(model)
    if woodSelected[model] then woodSelected[model]:Destroy(); woodSelected[model] = nil end
end

local function unhighlightAllWood()
    for model, hl in pairs(woodSelected) do if hl and hl.Parent then hl:Destroy() end end
    woodSelected = {}
end

local function disableCharCollision(char)
    if not char then return end
    pcall(function()
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

local function enableCharCollision(char)
    if not char then return end
    pcall(function()
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end)
end

local function sellOneLog(model, onDone)
    if not (model and model.Parent) then if onDone then task.spawn(onDone,false) end return end
    local mainPart = model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
    if not mainPart then if onDone then task.spawn(onDone,false) end return end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then if onDone then task.spawn(onDone,false) end return end

    local targetCF  = CFrame.new(SELL_POS)
    local dragger   = RS.Interaction:FindFirstChild("ClientIsDragging")
    local startTime = tick()
    hrp.CFrame = mainPart.CFrame * CFrame.new(0,3,3)

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not (mainPart and mainPart.Parent) then
            conn:Disconnect(); enableCharCollision(player.Character)
            if onDone then task.spawn(onDone,true) end; return
        end
        local c2 = player.Character; local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
        if not h2 then conn:Disconnect(); if onDone then task.spawn(onDone,false) end; return end
        if (h2.Position - mainPart.Position).Magnitude > 20 then
            h2.CFrame = mainPart.CFrame * CFrame.new(0,3,3)
        end
        disableCharCollision(c2)
        if dragger then pcall(function() dragger:FireServer(model) end) end
        pcall(function() mainPart.CFrame = targetCF end)
        local dist    = (mainPart.Position - SELL_POS).Magnitude
        local timedOut = (tick()-startTime) >= SELL_TIMEOUT
        if dist < SELL_CONFIRM or timedOut then
            conn:Disconnect()
            task.spawn(function()
                for _ = 1, 20 do
                    pcall(function()
                        if dragger then dragger:FireServer(model) end
                        if mainPart and mainPart.Parent then mainPart.CFrame = targetCF end
                    end)
                    task.wait()
                end
                enableCharCollision(player.Character)
                if onDone then onDone(dist < SELL_CONFIRM) end
            end)
        end
    end)
    return conn
end

-- ════════════════════════════════════════════════════
-- FARM LOOP
-- ════════════════════════════════════════════════════

local farmActive    = false
local farmTreeClass = nil
local farmAmount    = 1
local farmCycles    = 1
local farmSellAfter = true

local function farmLoop(stat)
    if farmActive then return end
    if not farmTreeClass then
        if stat then stat.SetActive(false, "Pick a tree first.") end
        return
    end
    farmActive   = true
    globalAbort  = false
    getgenv().treestop = true
    if stat then stat.SetActive(true, "Farm: "..farmTreeClass) end

    for cycle = 1, farmCycles do
        if globalAbort then break end
        for t = 1, farmAmount do
            if globalAbort then break end
            if stat then stat.SetActive(true, "Cycle "..cycle.." — Tree "..t.."/"..farmAmount) end
            local ok = bringTree(farmTreeClass, function(msg)
                if stat then stat.SetActive(true, msg) end
            end)
            if not ok then task.wait(3) end
        end
        if farmSellAfter and not globalAbort then
            if stat then stat.SetActive(true, "Selling logs...") end
            SellAllLogs()
            task.wait(1)
        end
    end

    getgenv().treestop = false
    farmActive = false
    if stat then stat.SetActive(false, globalAbort and "Stopped." or "Farm complete!") end
end

-- ════════════════════════════════════════════════════
-- PROGRESS BAR
-- ════════════════════════════════════════════════════

local sellProgressContainer, sellProgressFill, sellProgressLabel
do
    local pbWrapper = Instance.new("Frame", woodPage)
    pbWrapper.Size = UDim2.new(1,-12,0,44); pbWrapper.BackgroundColor3 = Color3.fromRGB(18,18,24)
    pbWrapper.BorderSizePixel = 0; pbWrapper.Visible = false; corner(pbWrapper, 8)
    local pbStroke = Instance.new("UIStroke", pbWrapper)
    pbStroke.Color = Color3.fromRGB(60,60,80); pbStroke.Thickness = 1; pbStroke.Transparency = 0.5
    local pbLabel = Instance.new("TextLabel", pbWrapper)
    pbLabel.Size = UDim2.new(1,-12,0,16); pbLabel.Position = UDim2.new(0,6,0,4)
    pbLabel.BackgroundTransparency = 1; pbLabel.Font = Enum.Font.GothamSemibold; pbLabel.TextSize = 11
    pbLabel.TextColor3 = THEME_TEXT; pbLabel.TextXAlignment = Enum.TextXAlignment.Left; pbLabel.Text = ""
    local pbTrack = Instance.new("Frame", pbWrapper)
    pbTrack.Size = UDim2.new(1,-12,0,12); pbTrack.Position = UDim2.new(0,6,0,24)
    pbTrack.BackgroundColor3 = Color3.fromRGB(30,30,40); pbTrack.BorderSizePixel = 0; corner(pbTrack, 5)
    local pbFill = Instance.new("Frame", pbTrack)
    pbFill.Size = UDim2.new(0,0,1,0); pbFill.BackgroundColor3 = Color3.fromRGB(80,200,120)
    pbFill.BorderSizePixel = 0; corner(pbFill, 5)
    sellProgressContainer = pbWrapper
    sellProgressFill      = pbFill
    sellProgressLabel     = pbLabel
end

-- ════════════════════════════════════════════════════
-- SELL SELECTED
-- ════════════════════════════════════════════════════

local function sellSelected()
    if isSellRunning then return end
    local queue = {}
    for model in pairs(woodSelected) do
        if model and model.Parent then table.insert(queue, model) end
    end
    if #queue == 0 then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    isSellRunning = true; sellOriginCF = hrp and hrp.CFrame or nil
    local total, done = #queue, 0
    sellProgressContainer.Visible = true
    sellProgressFill.Size = UDim2.new(0,0,1,0); sellProgressLabel.Text = "Selling... 0 / "..total

    local function updateBar()
        local pct = math.clamp(done/math.max(total,1),0,1)
        TweenService:Create(sellProgressFill, TweenInfo.new(0.15), {Size=UDim2.new(pct,0,1,0)}):Play()
        sellProgressLabel.Text = "Selling... "..done.." / "..total
    end

    local function finishSell(cancelled)
        isSellRunning = false; currentSellConn = nil
        enableCharCollision(player.Character)
        if sellOriginCF then
            pcall(function()
                local c = player.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
                if r then r.CFrame = sellOriginCF end
            end); sellOriginCF = nil
        end
        unhighlightAllWood()
        if cancelled then
            sellProgressLabel.Text = "Cancelled."
        else
            TweenService:Create(sellProgressFill, TweenInfo.new(0.25), {
                Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(60,200,110)
            }):Play()
            sellProgressLabel.Text = "Done! All logs sold."
        end
        task.delay(2.0, function()
            if sellProgressContainer then
                TweenService:Create(sellProgressContainer, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
                TweenService:Create(sellProgressFill,     TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
                TweenService:Create(sellProgressLabel,    TweenInfo.new(0.4), {TextTransparency=1}):Play()
                task.delay(0.45, function()
                    if sellProgressContainer then
                        sellProgressContainer.Visible = false
                        sellProgressContainer.BackgroundTransparency = 0
                        sellProgressFill.BackgroundTransparency = 0
                        sellProgressFill.BackgroundColor3 = Color3.fromRGB(80,200,120)
                        sellProgressFill.Size = UDim2.new(0,0,1,0)
                        sellProgressLabel.TextTransparency = 0
                    end
                end)
            end
        end)
    end

    task.spawn(function()
        for i, model in ipairs(queue) do
            if not isSellRunning then finishSell(true); return end
            if not (model and model.Parent) then done=done+1; updateBar(); continue end
            local logDone = false
            currentSellConn = sellOneLog(model, function()
                currentSellConn = nil; logDone = true
            end)
            while not logDone and isSellRunning do task.wait() end
            if not isSellRunning then
                if currentSellConn then pcall(function() currentSellConn:Disconnect() end); currentSellConn=nil end
                finishSell(true); return
            end
            unhighlightWood(model); done=done+1; updateBar()
            if i < #queue then task.wait(0.8) end
        end
        finishSell(false)
    end)
end

-- ════════════════════════════════════════════════════
-- WOOD MOUSE CONNECTION
-- ════════════════════════════════════════════════════

local woodMouseConn = nil
local function connectWoodMouse()
    if woodMouseConn then return end
    woodMouseConn = woodMouse.Button1Down:Connect(function()
        local target = woodMouse.Target; if not target then return end
        local model  = target:FindFirstAncestorOfClass("Model"); if not model then return end
        if clickSellEnabled then
            if isWoodLog(model) and not clickSellBusy then
                clickSellBusy = true
                local originCF = getHRP() and getHRP().CFrame
                clickSellConn = sellOneLog(model, function()
                    enableCharCollision(player.Character)
                    pcall(function()
                        local c = player.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
                        if r and originCF then r.CFrame = originCF end
                    end)
                    clickSellConn = nil; clickSellBusy = false
                end)
            end
        elseif groupSelectEnabled then
            if isWoodLog(model) then
                local tc = model:FindFirstChild("TreeClass"); if not tc then return end
                local targetClass = tc.Value:lower()
                for _, obj in ipairs(WS:GetDescendants()) do
                    if obj:IsA("Model") and isWoodLog(obj) then
                        local otc = obj:FindFirstChild("TreeClass")
                        if otc and otc.Value:lower() == targetClass then highlightWood(obj) end
                    end
                end
            end
        else
            if isWoodLog(model) then
                if woodSelected[model] then unhighlightWood(model) else highlightWood(model) end
            end
        end
    end)
end

local function disconnectWoodMouse()
    if woodMouseConn then woodMouseConn:Disconnect(); woodMouseConn = nil end
end

-- ════════════════════════════════════════════════════
-- BUILD WOOD TAB UI
-- ════════════════════════════════════════════════════

local TREE_LIST = {
    "Generic","Walnut","Cherry","Oak","Birch","Koa","Fir","Pine","Palm",
    "SnowGlow","Frost","Spooky","SpookyNeon","Volcano",
    "GreenSwampy","GoldSwampy","CaveCrawler","LoneCave",
}

local selectedTree = nil
local bringAmount  = 1
local bringAbort   = false

createWSectionLabel("Bring Tree")
makeFancyDropdown(woodPage, "Tree", function() return TREE_LIST end, function(val)
    selectedTree = val; farmTreeClass = val
end)

-- Amount slider
do
    local slFrame = Instance.new("Frame", woodPage)
    slFrame.Size = UDim2.new(1,-12,0,52); slFrame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    slFrame.BorderSizePixel = 0; corner(slFrame, 6)
    local slLbl = Instance.new("TextLabel", slFrame)
    slLbl.Size=UDim2.new(0.6,0,0,22); slLbl.Position=UDim2.new(0,8,0,6)
    slLbl.BackgroundTransparency=1; slLbl.Font=Enum.Font.GothamSemibold; slLbl.TextSize=13
    slLbl.TextColor3=THEME_TEXT; slLbl.TextXAlignment=Enum.TextXAlignment.Left; slLbl.Text="Amount"
    local slVal = Instance.new("TextLabel", slFrame)
    slVal.Size=UDim2.new(0.4,0,0,22); slVal.Position=UDim2.new(0.6,-8,0,6)
    slVal.BackgroundTransparency=1; slVal.Font=Enum.Font.GothamBold; slVal.TextSize=13
    slVal.TextColor3=THEME_TEXT; slVal.TextXAlignment=Enum.TextXAlignment.Right; slVal.Text="1"
    local track = Instance.new("Frame", slFrame)
    track.Size=UDim2.new(1,-16,0,6); track.Position=UDim2.new(0,8,0,36)
    track.BackgroundColor3=Color3.fromRGB(40,40,55); track.BorderSizePixel=0; corner(track,3)
    local fill = Instance.new("Frame", track)
    fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=Color3.fromRGB(80,80,100); fill.BorderSizePixel=0; corner(fill,3)
    local knob = Instance.new("TextButton", track)
    knob.Size=UDim2.new(0,16,0,16); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new(0,0,0.5,0); knob.BackgroundColor3=Color3.fromRGB(210,210,225)
    knob.Text=""; knob.BorderSizePixel=0; corner(knob,8)
    local dragging = false
    local MIN,MAX = 1,30
    local function update(absX)
        local ratio = math.clamp((absX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val = math.round(MIN+ratio*(MAX-MIN))
        fill.Size=UDim2.new(ratio,0,1,0); knob.Position=UDim2.new(ratio,0,0.5,0)
        slVal.Text=tostring(val); bringAmount=val; farmAmount=val
    end
    knob.MouseButton1Down:Connect(function() dragging=true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
end

local bringStatus = createWStatusLabel("Idle")

createWButton("Bring Tree", Color3.fromRGB(35,80,35), function()
    if not selectedTree then bringStatus.SetActive(false,"Select a tree first!"); return end
    globalAbort = false
    getgenv().treestop = true
    task.spawn(function()
        for i = 1, bringAmount do
            if globalAbort then break end
            bringStatus.SetActive(true, "Bringing "..selectedTree.." ("..i.."/"..bringAmount..")")
            local ok = bringTree(selectedTree, function(msg)
                bringStatus.SetActive(true, msg)
            end)
            if not ok then
                bringStatus.SetActive(false, "Failed - retrying in 3s")
                task.wait(3)
            elseif i < bringAmount then
                task.wait(1)
            end
        end
        if not globalAbort then
            bringStatus.SetActive(false, "Done!")
        end
    end)
end)

createWButton("Abort Bring", BTN_COLOR, function()
    globalAbort = true
    bringAbort  = true
    getgenv().treestop = false
    bringStatus.SetActive(false, "Aborted.")
    task.delay(5, function()
        globalAbort = false
        bringAbort  = false
        getgenv().treestop = true
    end)
end)

createWSep()
createWSectionLabel("Log Actions")
createWButton("Bring All Logs", BTN_COLOR, function() task.spawn(BringAllLogs) end)
createWButton("Sell All Logs", Color3.fromRGB(35,90,35), function() task.spawn(SellAllLogs) end)

createWSep()
createWSectionLabel("Sell Features")
createWToggle("Click Sell (click log to sell it)", false, function(val)
    clickSellEnabled = val
    if val then groupSelectEnabled=false; connectWoodMouse()
    else if not groupSelectEnabled then disconnectWoodMouse() end end
end)

createWSep()
createWSectionLabel("Log Selection")
createWToggle("Group Select (same tree type)", false, function(val)
    groupSelectEnabled = val
    if val then clickSellEnabled=false; connectWoodMouse()
    else if not clickSellEnabled then disconnectWoodMouse() end end
end)
createWInfoLabel("  Click a log to select / deselect. Group Select grabs all matching logs.")

createWSep()
createWSectionLabel("Sell Selected")
createWButton("Sell Selected Logs", Color3.fromRGB(35,90,45), function()
    if not isSellRunning then sellSelected() end
end)
createWButton("Cancel Sell", BTN_COLOR, function()
    isSellRunning = false
    if currentSellConn then pcall(function() currentSellConn:Disconnect() end); currentSellConn=nil end
    enableCharCollision(player.Character)
    if sellOriginCF then
        pcall(function()
            local c=player.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame=sellOriginCF end
        end); sellOriginCF=nil
    end
    if sellProgressContainer and sellProgressContainer.Visible then
        sellProgressLabel.Text="Cancelled."
        task.delay(1.5,function()
            TweenService:Create(sellProgressContainer,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
            task.delay(0.45,function()
                if sellProgressContainer then
                    sellProgressContainer.Visible=false
                    sellProgressContainer.BackgroundTransparency=0
                end
            end)
        end)
    end
    unhighlightAllWood()
end)
createWButton("Clear Selection", BTN_COLOR, function() unhighlightAllWood() end)

-- ── Farm Loop ─────────────────────────────────────────────────────────────────

createWSep()
createWSectionLabel("Farm Loop")
createWInfoLabel("  Uses tree selected above. Cuts N trees per cycle, sells all logs, repeats.")

do
    local slFrame = Instance.new("Frame", woodPage)
    slFrame.Size=UDim2.new(1,-12,0,52); slFrame.BackgroundColor3=Color3.fromRGB(24,24,30)
    slFrame.BorderSizePixel=0; corner(slFrame,6)
    local slLbl=Instance.new("TextLabel",slFrame)
    slLbl.Size=UDim2.new(0.6,0,0,22); slLbl.Position=UDim2.new(0,8,0,6)
    slLbl.BackgroundTransparency=1; slLbl.Font=Enum.Font.GothamSemibold; slLbl.TextSize=13
    slLbl.TextColor3=THEME_TEXT; slLbl.TextXAlignment=Enum.TextXAlignment.Left; slLbl.Text="Cycles"
    local slVal=Instance.new("TextLabel",slFrame)
    slVal.Size=UDim2.new(0.4,0,0,22); slVal.Position=UDim2.new(0.6,-8,0,6)
    slVal.BackgroundTransparency=1; slVal.Font=Enum.Font.GothamBold; slVal.TextSize=13
    slVal.TextColor3=THEME_TEXT; slVal.TextXAlignment=Enum.TextXAlignment.Right; slVal.Text="1"
    local track=Instance.new("Frame",slFrame)
    track.Size=UDim2.new(1,-16,0,6); track.Position=UDim2.new(0,8,0,36)
    track.BackgroundColor3=Color3.fromRGB(40,40,55); track.BorderSizePixel=0; corner(track,3)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=Color3.fromRGB(80,80,100); fill.BorderSizePixel=0; corner(fill,3)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,16,0,16); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new(0,0,0.5,0); knob.BackgroundColor3=Color3.fromRGB(210,210,225)
    knob.Text=""; knob.BorderSizePixel=0; corner(knob,8)
    local dragging=false
    local MIN,MAX=1,50
    local function update(absX)
        local ratio=math.clamp((absX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val=math.round(MIN+ratio*(MAX-MIN))
        fill.Size=UDim2.new(ratio,0,1,0); knob.Position=UDim2.new(ratio,0,0.5,0)
        slVal.Text=tostring(val); farmCycles=val
    end
    knob.MouseButton1Down:Connect(function() dragging=true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
end

createWToggle("Sell logs after each cycle", true, function(val) farmSellAfter = val end)

local farmStat = createWStatusLabel("Idle")
createWButton("▶  Start Farm Loop", Color3.fromRGB(35,80,35), function()
    if not farmActive then task.spawn(farmLoop, farmStat) end
end)
createWButton("⏹  Stop Farm", BTN_COLOR, function()
    globalAbort = true
    farmActive  = false
    getgenv().treestop = false
    farmStat.SetActive(false, "Stopped.")
end)

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════

local keybindButtonGUI
local settingsPage = pages["SettingsTab"]

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size = UDim2.new(1,0,0,70); kbFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
kbFrame.BorderSizePixel = 0; corner(kbFrame, 10)
local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size=UDim2.new(1,-20,0,28); kbTitle.Position=UDim2.new(0,10,0,8)
kbTitle.BackgroundTransparency=1; kbTitle.Font=Enum.Font.GothamBold; kbTitle.TextSize=15
kbTitle.TextColor3=THEME_TEXT; kbTitle.TextXAlignment=Enum.TextXAlignment.Left
kbTitle.Text="GUI Toggle Keybind"
keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size=UDim2.new(0,200,0,28); keybindButtonGUI.Position=UDim2.new(0,10,0,36)
keybindButtonGUI.BackgroundColor3=Color3.fromRGB(30,30,30); keybindButtonGUI.BorderSizePixel=0
keybindButtonGUI.Font=Enum.Font.Gotham; keybindButtonGUI.TextSize=14
keybindButtonGUI.TextColor3=THEME_TEXT
keybindButtonGUI.Text="Toggle Key: "..getCurrentToggleKey().Name
corner(keybindButtonGUI, 8)
keybindButtonGUI.MouseButton1Click:Connect(function()
    if getWaitingForKeyGUI() then return end
    keybindButtonGUI.Text = "Press any key..."
    setWaitingForKeyGUI(true)
end)
keybindButtonGUI.MouseEnter:Connect(function()
    TweenService:Create(keybindButtonGUI,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(45,45,45)}):Play()
end)
keybindButtonGUI.MouseLeave:Connect(function()
    TweenService:Create(keybindButtonGUI,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(30,30,30)}):Play()
end)

-- ════════════════════════════════════════════════════
-- SEARCH TAB
-- ════════════════════════════════════════════════════

local searchPage  = pages["SearchTab"]
local searchInput = Instance.new("TextBox", searchPage)
searchInput.Size=UDim2.new(1,-28,0,42); searchInput.BackgroundColor3=Color3.fromRGB(22,22,28)
searchInput.PlaceholderText="🔍 Search for functions or tabs..."; searchInput.Text=""
searchInput.Font=Enum.Font.GothamSemibold; searchInput.TextSize=15
searchInput.TextColor3=THEME_TEXT; searchInput.TextXAlignment=Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus=false; corner(searchInput,10)
Instance.new("UIPadding",searchInput).PaddingLeft=UDim.new(0,14)

local function updateSearchResults(query)
    for _, child in ipairs(searchPage:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local lq = string.lower(query or "")
    local functions = {
        {"Fly","PlayerTab"},{"Noclip","PlayerTab"},{"InfJump","PlayerTab"},
        {"Walkspeed","PlayerTab"},{"Jump Power","PlayerTab"},{"Fly Speed","PlayerTab"},{"Fly Key","PlayerTab"},
        {"Teleport Locations","TeleportTab"},{"Quick Teleport","TeleportTab"},
        {"Spawn","TeleportTab"},{"Wood Dropoff","TeleportTab"},{"Land Store","TeleportTab"},
        {"Teleport Selected Items","ItemTab"},{"Group Selection","ItemTab"},
        {"Click Selection","ItemTab"},{"Lasso Tool","ItemTab"},
        {"Clear Selection","ItemTab"},{"Set Destination","ItemTab"},
        {"GUI Keybind","SettingsTab"},{"Home","HomeTab"},{"Ping","HomeTab"},{"Rejoin","HomeTab"},
        {"Bring Tree","WoodTab"},{"Select Tree","WoodTab"},{"Mod Wood","WoodTab"},
        {"1x1 Cut","WoodTab"},{"Bring All Logs","WoodTab"},{"Sell All Logs","WoodTab"},
        {"Click Sell","WoodTab"},{"Group Select","WoodTab"},{"Farm Loop","WoodTab"},
        {"Sell Selected Logs","WoodTab"},{"Clear Selection","WoodTab"},
    }
    local seen = {}
    for _, name in ipairs(tabs) do
        if lq == "" or string.find(string.lower(name), lq) then
            if not seen[name.."Tab"] then
                seen[name.."Tab"] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size=UDim2.new(1,-28,0,42); resBtn.BackgroundColor3=Color3.fromRGB(22,22,28)
                resBtn.Text="📂  "..name.." Tab"; resBtn.Font=Enum.Font.GothamSemibold; resBtn.TextSize=15
                resBtn.TextColor3=THEME_TEXT; resBtn.TextXAlignment=Enum.TextXAlignment.Left
                Instance.new("UIPadding",resBtn).PaddingLeft=UDim.new(0,16); corner(resBtn,10)
                resBtn.MouseEnter:Connect(function()
                    TweenService:Create(resBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(35,35,45),TextColor3=Color3.fromRGB(255,255,255)}):Play()
                end)
                resBtn.MouseLeave:Connect(function()
                    TweenService:Create(resBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(22,22,28),TextColor3=THEME_TEXT}):Play()
                end)
                resBtn.MouseButton1Click:Connect(function() switchTab(name.."Tab") end)
            end
        end
    end
    if lq ~= "" then
        for _, entry in ipairs(functions) do
            local fname, ftab = entry[1], entry[2]
            if string.find(string.lower(fname), lq) and not seen[fname] then
                seen[fname] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size=UDim2.new(1,-28,0,42); resBtn.BackgroundColor3=Color3.fromRGB(18,22,30)
                resBtn.Text="⚙  "..fname; resBtn.Font=Enum.Font.GothamSemibold; resBtn.TextSize=15
                resBtn.TextColor3=THEME_TEXT; resBtn.TextXAlignment=Enum.TextXAlignment.Left
                Instance.new("UIPadding",resBtn).PaddingLeft=UDim.new(0,16); corner(resBtn,10)
                local subLbl=Instance.new("TextLabel",resBtn)
                subLbl.Size=UDim2.new(1,-20,0,16); subLbl.Position=UDim2.new(0,36,1,-18)
                subLbl.BackgroundTransparency=1; subLbl.Font=Enum.Font.Gotham; subLbl.TextSize=11
                subLbl.TextColor3=Color3.fromRGB(120,120,150); subLbl.TextXAlignment=Enum.TextXAlignment.Left
                subLbl.Text="in "..ftab:gsub("Tab","").." tab"
                resBtn.MouseEnter:Connect(function()
                    TweenService:Create(resBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(28,35,52),TextColor3=Color3.fromRGB(255,255,255)}):Play()
                end)
                resBtn.MouseLeave:Connect(function()
                    TweenService:Create(resBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(18,22,30),TextColor3=THEME_TEXT}):Play()
                end)
                resBtn.MouseButton1Click:Connect(function() switchTab(ftab) end)
            end
        end
    end
end
searchInput:GetPropertyChangedSignal("Text"):Connect(function() updateSearchResults(searchInput.Text) end)
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
            keybindButtonGUI.Text = "Toggle Key: "..getCurrentToggleKey().Name
            TweenService:Create(keybindButtonGUI,
                TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut,1,true),
                {BackgroundColor3=Color3.fromRGB(60,180,60)}):Play()
        end
        return
    end

    if getWaitingForFlyKey() then
        setWaitingForFlyKey(false)
        setCurrentFlyKey(input.KeyCode)
        if flyKeyBtn and flyKeyBtn.Parent then
            flyKeyBtn.Text = input.KeyCode.Name
            flyKeyBtn.BackgroundColor3 = BTN_COLOR
        end
        return
    end

    if input.KeyCode == getCurrentToggleKey() then toggleGUI(); return end

    if input.KeyCode == getCurrentFlyKey() and getFlyToggleEnabled() then
        if getIsFlyEnabled() then stopFly() else startFly() end
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════

table.insert(cleanupTasks, function()
    if inputConn     then inputConn:Disconnect();     inputConn     = nil end
    isSellRunning    = false; clickSellBusy = false
    globalAbort      = true;  farmActive    = false
    if clickSellConn   then pcall(function() clickSellConn:Disconnect()   end); clickSellConn   = nil end
    if currentSellConn then pcall(function() currentSellConn:Disconnect() end); currentSellConn = nil end
    disconnectWoodMouse()
    enableCharCollision(player.Character)
    unhighlightAllWood()
    getgenv().treestop = false
end)

_G.VH.keybindButtonGUI = keybindButtonGUI
print("[VanillaHub] Vanilla3 REWRITE loaded — Wood + Farm Loop")
