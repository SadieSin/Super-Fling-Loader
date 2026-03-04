-- ════════════════════════════════════════════════════
-- VANILLA3 — AutoBuy Tab + Settings Tab + Search Tab + Input Handler + Wood Tab
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
local THEME_TEXT       = _G.VH.THEME_TEXT or Color3.fromRGB(230, 206, 226)
local switchTab        = _G.VH.switchTab
local toggleGUI        = _G.VH.toggleGUI
local stopFly          = _G.VH.stopFly
local startFly         = _G.VH.startFly
local flyKeyBtn        = _G.VH.flyKeyBtn
local keybindButtonGUI

local RS = game:GetService("ReplicatedStorage")

local function getWaitingForFlyKey()    return _G.VH and _G.VH.waitingForFlyKey end
local function setWaitingForFlyKey(v)   if _G.VH then _G.VH.waitingForFlyKey = v end end
local function getWaitingForKeyGUI()    return _G.VH and _G.VH.waitingForKeyGUI end
local function setWaitingForKeyGUI(v)   if _G.VH then _G.VH.waitingForKeyGUI = v end end
local function getCurrentFlyKey()       return _G.VH and _G.VH.currentFlyKey or Enum.KeyCode.Q end
local function setCurrentFlyKey(v)      if _G.VH then _G.VH.currentFlyKey = v end end
local function getCurrentToggleKey()    return _G.VH and _G.VH.currentToggleKey or Enum.KeyCode.LeftAlt end
local function setCurrentToggleKey(v)   if _G.VH then _G.VH.currentToggleKey = v end end
local function getFlyToggleEnabled()    return _G.VH and _G.VH.flyToggleEnabled end
local function getIsFlyEnabled()        return _G.VH and _G.VH.isFlyEnabled end

-- ════════════════════════════════════════════════════
-- SHARED UI HELPERS
-- ════════════════════════════════════════════════════

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

-- ── Fancy accordion dropdown (matches Dupe tab style) ────────────────────────
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
    local selStroke = Instance.new("UIStroke", selFrame)
    selStroke.Color = Color3.fromRGB(70,70,110); selStroke.Thickness = 1; selStroke.Transparency = 0.4

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
            item.Text = ""; item.BorderSizePixel = 0
            corner(item, 6)
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
                setSelected(opt)
                isOpen = false
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
-- SETTINGS TAB
-- ════════════════════════════════════════════════════
local settingsPage = pages["SettingsTab"]

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size = UDim2.new(1,0,0,70); kbFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
kbFrame.BorderSizePixel = 0; corner(kbFrame, 10)
local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size = UDim2.new(1,-20,0,28); kbTitle.Position = UDim2.new(0,10,0,8)
kbTitle.BackgroundTransparency = 1; kbTitle.Font = Enum.Font.GothamBold; kbTitle.TextSize = 15
kbTitle.TextColor3 = THEME_TEXT; kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Text = "GUI Toggle Keybind"
keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size = UDim2.new(0,200,0,28); keybindButtonGUI.Position = UDim2.new(0,10,0,36)
keybindButtonGUI.BackgroundColor3 = Color3.fromRGB(30,30,30); keybindButtonGUI.BorderSizePixel = 0
keybindButtonGUI.Font = Enum.Font.Gotham; keybindButtonGUI.TextSize = 14
keybindButtonGUI.TextColor3 = THEME_TEXT
keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
corner(keybindButtonGUI, 8)
keybindButtonGUI.MouseButton1Click:Connect(function()
    if getWaitingForKeyGUI() then return end
    keybindButtonGUI.Text = "Press any key..."
    setWaitingForKeyGUI(true)
end)
keybindButtonGUI.MouseEnter:Connect(function()
    TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
end)
keybindButtonGUI.MouseLeave:Connect(function()
    TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
end)

-- ════════════════════════════════════════════════════
-- SEARCH TAB
-- ════════════════════════════════════════════════════
local searchPage  = pages["SearchTab"]
local searchInput = Instance.new("TextBox", searchPage)
searchInput.Size = UDim2.new(1,-28,0,42); searchInput.BackgroundColor3 = Color3.fromRGB(22,22,28)
searchInput.PlaceholderText = "🔍 Search for functions or tabs..."; searchInput.Text = ""
searchInput.Font = Enum.Font.GothamSemibold; searchInput.TextSize = 15
searchInput.TextColor3 = THEME_TEXT; searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false
corner(searchInput, 10)
Instance.new("UIPadding", searchInput).PaddingLeft = UDim.new(0,14)

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
        {"GUI Keybind","SettingsTab"},
        {"Home","HomeTab"},{"Ping","HomeTab"},{"Rejoin","HomeTab"},
        {"Bring Tree","WoodTab"},{"Select Tree","WoodTab"},{"Mod Wood","WoodTab"},
        {"1x1 Cut","WoodTab"},{"Bring All Logs","WoodTab"},{"Sell All Logs","WoodTab"},
        {"Click Sell","WoodTab"},{"Group Select","WoodTab"},
        {"Sell Selected Logs","WoodTab"},{"Clear Selection","WoodTab"},
        {"Dismember Tree","WoodTab"},{"View LoneCave","WoodTab"},
    }

    local seen = {}
    for _, name in ipairs(tabs) do
        if lq == "" or string.find(string.lower(name), lq) then
            if not seen[name.."Tab"] then
                seen[name.."Tab"] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size = UDim2.new(1,-28,0,42); resBtn.BackgroundColor3 = Color3.fromRGB(22,22,28)
                resBtn.Text = "📂  " .. name .. " Tab"; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
                resBtn.TextColor3 = THEME_TEXT; resBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UIPadding", resBtn).PaddingLeft = UDim.new(0,16)
                corner(resBtn, 10)
                resBtn.MouseEnter:Connect(function()
                    TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(35,35,45),TextColor3=Color3.fromRGB(255,255,255)}):Play()
                end)
                resBtn.MouseLeave:Connect(function()
                    TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(22,22,28),TextColor3=THEME_TEXT}):Play()
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
                resBtn.Size = UDim2.new(1,-28,0,42); resBtn.BackgroundColor3 = Color3.fromRGB(18,22,30)
                resBtn.Text = "⚙  " .. fname; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
                resBtn.TextColor3 = THEME_TEXT; resBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UIPadding", resBtn).PaddingLeft = UDim.new(0,16)
                corner(resBtn, 10)
                local subLbl = Instance.new("TextLabel", resBtn)
                subLbl.Size = UDim2.new(1,-20,0,16); subLbl.Position = UDim2.new(0,36,1,-18)
                subLbl.BackgroundTransparency = 1; subLbl.Font = Enum.Font.Gotham; subLbl.TextSize = 11
                subLbl.TextColor3 = Color3.fromRGB(120,120,150); subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.Text = "in " .. ftab:gsub("Tab","") .. " tab"
                resBtn.MouseEnter:Connect(function()
                    TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(28,35,52),TextColor3=Color3.fromRGB(255,255,255)}):Play()
                end)
                resBtn.MouseLeave:Connect(function()
                    TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(18,22,30),TextColor3=THEME_TEXT}):Play()
                end)
                resBtn.MouseButton1Click:Connect(function() switchTab(ftab) end)
            end
        end
    end
end
searchInput:GetPropertyChangedSignal("Text"):Connect(function() updateSearchResults(searchInput.Text) end)
task.delay(0.1, function() updateSearchResults("") end)

-- ════════════════════════════════════════════════════
-- WOOD TAB  — CORE ENGINE (ported from Butterhub leak)
-- ════════════════════════════════════════════════════

local woodPage = pages["WoodTab"]
local woodMouse = player:GetMouse()

-- Sell destination: wood dropoff conveyor entry
local SELL_POS = Vector3.new(315.14, -0.40, 86.32)

-- ── Axe hit point table (from Butterhub source) ───────────────────────────────
local HitPoints = {
    Beesaxe=1.4, AxeAmber=3.39, ManyAxe=10.2, BasicHatchet=0.2,
    Axe1=0.55, Axe2=0.93, AxeAlphaTesters=1.5, Rukiryaxe=1.68,
    Axe3=1.45, AxeBetaTesters=1.45, FireAxe=0.6, SilverAxe=1.6,
    EndTimesAxe=1.58, AxeChicken=0.9, CandyCaneAxe=0, AxeTwitter=1.65,
}

local AxeClassesFolder = RS.AxeClasses

-- ── Tree helper functions (exact port from Butterhub) ─────────────────────────

local function isnetworkowner(Part)
    return Part.ReceiveAge == 0
end

local function calculateHitsForEndPart(part)
    return math.round((math.sqrt(part.Size.X * part.Size.Z) ^ 2 * 8e7) / 1e7)
end

local function DropTools()
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v.Name == "Tool" then
            RS.Interaction.ClientInteracted:FireServer(v, "Drop tool",
                player.Character.Head.CFrame * CFrame.new(0,4,-4))
            task.wait(0.5)
        end
    end
end

local function GetToolsfix()
    for _, a in pairs(workspace.PlayerModels:GetDescendants()) do
        if a.Name == "Model" and a:FindFirstChild("Owner") then
            if a:FindFirstChild("ToolName") and a.ToolName.Value == "EndTimesAxe" then
                RS.Interaction.ClientInteracted:FireServer(a, "Pick up tool")
            end
        end
    end
end

local function GetBestAxe(Tree)
    if player.Character:FindFirstChild("Tool") then
        player.Character.Humanoid:UnequipTools()
    end
    local SelectedTool = nil
    local HighestAxeDamage = 0
    for _, v in next, player.Backpack:GetChildren() do
        if v.Name == "Tool" then
            local axeClass = require(AxeClassesFolder:FindFirstChild("AxeClass_"..v.ToolName.Value)).new()
            if axeClass.Damage > HighestAxeDamage then
                HighestAxeDamage = axeClass.Damage
                SelectedTool = v
                if axeClass.SpecialTrees and axeClass.SpecialTrees[Tree] then
                    return v
                end
            end
        end
    end
    return SelectedTool
end

local function GetAxeDamage(Tree)
    if player.Character:FindFirstChild("Tool") then
        player.Character.Humanoid:UnequipTools()
    end
    local bestAxe = GetBestAxe(Tree)
    if not bestAxe then return 1 end
    local axeClass = require(AxeClassesFolder:FindFirstChild("AxeClass_"..bestAxe.ToolName.Value)).new()
    if axeClass.SpecialTrees and axeClass.SpecialTrees[Tree] then
        return axeClass.SpecialTrees[Tree].Damage
    end
    return axeClass.Damage
end

local function ChopTree(CutEventRemote, ID, Height, Tree)
    RS.Interaction.RemoteProxy:FireServer(CutEventRemote, {
        tool        = GetBestAxe(Tree),
        faceVector  = Vector3.new(1, 0, 0),
        height      = Height,
        sectionId   = ID,
        hitPoints   = GetAxeDamage(Tree),
        cooldown    = 0.25837870788574,
        cuttingClass= "Axe",
    })
end

-- Higher-fidelity getBestAxe used by bringTree (supports SpecialTrees properly)
local function getToolStats(tool)
    local toolName = (typeof(tool) ~= "string") and tool.ToolName.Value or tool
    return require(RS.AxeClasses["AxeClass_"..toolName]).new()
end

local function getTools()
    player.Character.Humanoid:UnequipTools()
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
    local toolStats = {}
    local tool
    for _, v in next, tools do
        if treeClass == "LoneCave" and v.ToolName.Value == "EndTimesAxe" then
            tool = v; break
        end
        local axeStats = getToolStats(v)
        if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
            for i, sv in next, axeStats.SpecialTrees[treeClass] do axeStats[i] = sv end
        end
        table.insert(toolStats, {tool=v, damage=axeStats.Damage})
    end
    if not tool and treeClass == "LoneCave" then return nil, "Need EndTimesAxe" end
    table.sort(toolStats, function(a,b) return a.damage > b.damage end)
    return tool or (toolStats[1] and toolStats[1].tool), nil
end

local function cutPart(event, section, height, tool, treeClass)
    local axeStats = getToolStats(tool)
    if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
        for i, v in next, axeStats.SpecialTrees[treeClass] do axeStats[i] = v end
    end
    RS.Interaction.RemoteProxy:FireServer(event, {
        tool         = tool,
        faceVector   = Vector3.new(-1, 0, 0),
        height       = height or 0.3,
        sectionId    = section or 1,
        hitPoints    = axeStats.Damage,
        cooldown     = axeStats.SwingCooldown,
        cuttingClass = "Axe",
    })
end

local treeClasses = {}
local treeRegions = {}
task.spawn(function()
    while task.wait() do
        for _, v in next, workspace:GetChildren() do
            if v.Name == "TreeRegion" then
                treeRegions[v] = treeRegions[v] or {}
                for _, v2 in next, v:GetChildren() do
                    if v2:FindFirstChild("TreeClass") then
                        if not table.find(treeClasses, v2.TreeClass.Value) then
                            table.insert(treeClasses, v2.TreeClass.Value)
                        end
                        if not table.find(treeRegions[v], v2.TreeClass.Value) then
                            table.insert(treeRegions[v], v2.TreeClass.Value)
                        end
                    end
                end
            end
        end
    end
end)

local function getBiggestTree(treeClass)
    local trees = {}
    for i, v in next, treeRegions do
        if table.find(v, treeClass) then
            for _, v2 in next, i:GetChildren() do
                if v2:IsA("Model") and v2:FindFirstChild("Owner") then
                    if v2:FindFirstChild("TreeClass") and v2.TreeClass.Value == treeClass
                       and (v2.Owner.Value == nil or v2.Owner.Value == player) then
                        local totalMass, treeTrunk = 0, nil
                        for _, v3 in next, v2:GetChildren() do
                            if v3:IsA("BasePart") then
                                if v3:FindFirstChild("ID") and v3.ID.Value == 1 then
                                    treeTrunk = v3
                                end
                                totalMass = totalMass + v3:GetMass()
                            end
                        end
                        table.insert(trees, {tree=v2, trunk=treeTrunk, mass=totalMass})
                    end
                end
            end
        end
    end
    table.sort(trees, function(a,b) return a.mass > b.mass end)
    return trees[1] or nil
end

local treeListener = function(treeClass, callback)
    local childAdded
    childAdded = workspace.LogModels.ChildAdded:Connect(function(child)
        local owner = child:WaitForChild("Owner")
        if owner.Value == player and child.TreeClass.Value == treeClass then
            childAdded:Disconnect()
            callback(child)
        end
    end)
    return childAdded
end

local function GetLava()
    for _, Lava in ipairs(workspace["Region_Volcano"]:GetChildren()) do
        if Lava:FindFirstChild("Lava") and
           Lava.Lava.CFrame == CFrame.new(-1675.2002,255.002533,1284.19983,
               0.866007268,0,0.500031412,0,1,0,-0.500031412,0,0.866007268) then
            return Lava
        end
    end
end

local function GodMode(tpCF)
    local LavaPart = GetLava()
    player.Character.HumanoidRootPart.CFrame = CFrame.new(-1439.45, 433.4, 1317.61)
    repeat
        task.wait(1)
        firetouchinterest(player.Character.HumanoidRootPart, LavaPart.Lava, 0)
    until player.Character.HumanoidRootPart:FindFirstChild("LavaFire")
    player.Character.HumanoidRootPart.LavaFire:Destroy()
    task.wait(1)
    local Clone = player.Character.Torso:Clone()
    Clone.Name = "HumanoidRootPart"; Clone.Transparency = 1
    Clone.Parent = player.Character
    player.Character.HumanoidRootPart.CFrame = tpCF
    Clone.CFrame = tpCF
end

-- getgenv flags used by bringTree
getgenv().treeCut   = false
getgenv().treestop  = true
getgenv().doneend   = true
getgenv().Infeaxerange = nil

local function bringTree(treeClass, godmodeval)
    getgenv().treestop = true
    player.Character.Humanoid.BreakJointsOnDeath = false

    local success, data = getBestAxeForTree(treeClass)
    if not success then return end

    local tree = getBiggestTree(treeClass)
    if not tree then return end
    if not (tree.trunk.Size.X >= 1 and tree.trunk.Size.Y >= 2 and tree.trunk.Size.Z >= 1) then
        return
    end

    local oldPosition = player.Character.HumanoidRootPart.CFrame.Position

    if godmodeval then
        workspace.Camera.CameraType = Enum.CameraType.Fixed
        GodMode(tree.trunk.CFrame)
        workspace.Camera.CameraType = Enum.CameraType.Custom
        player.Character:SetPrimaryPartCFrame(tree.trunk.CFrame)
    end
    task.wait(0.5)

    treeListener(treeClass, function(log)
        log.PrimaryPart = log:FindFirstChild("WoodSection")
        getgenv().treeCut = true
        for _ = 1, 60 do
            pcall(function()
                RS.Interaction.ClientIsDragging:FireServer(log)
                RS.Interaction.ClientIsDragging:FireServer(log)
                RS.Interaction.ClientIsDragging:FireServer(log)
                RS.Interaction.ClientIsDragging:FireServer(log)
                log:MoveTo(oldPosition)
                log:MoveTo(oldPosition)
            end)
            task.wait()
        end
    end)
    task.wait(0.15)

    task.spawn(function()
        if treeClass == "LoneCave" then
            getgenv().doneend = false
            repeat
                if not getgenv().treestop then break end
                player.Character:SetPrimaryPartCFrame(tree.trunk.CFrame)
                task.wait()
            until getgenv().treeCut
        else
            repeat
                if not getgenv().treestop then break end
                player.Character:SetPrimaryPartCFrame(tree.trunk.CFrame)
                task.wait()
            until getgenv().treeCut
        end
    end)
    task.wait()

    if treeClass == "LoneCave" and godmodeval then
        local numHits = calculateHitsForEndPart(tree.trunk) - 1
        for _ = 1, numHits do
            cutPart(tree.tree.CutEvent, 1, 0.3, data, treeClass)
            task.wait(1)
        end
        getgenv().treeCut   = false
        getgenv().treestop  = false
        DropTools()
        task.wait(0.3)
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-1675, 261, 1284)
        task.wait(0.5)
        pcall(function()
            repeat task.wait() until player.Character.Humanoid.Health == 100
        end)
        task.wait(0.3)
        GetToolsfix()
        task.wait(0.5)
        bringTree("LoneCave", false)
    else
        repeat
            if not getgenv().treestop then break end
            cutPart(tree.tree.CutEvent, 1, 0.3, data, treeClass)
            task.wait()
        until getgenv().treeCut
    end

    if treeClass == "LoneCave" then
        task.wait(1)
        player.Character:SetPrimaryPartCFrame(CFrame.new(oldPosition))
        getgenv().doneend  = true
        getgenv().treeCut  = false
        getgenv().treestop = false
    else
        task.wait(1)
        getgenv().treeCut = false
        player.Character:SetPrimaryPartCFrame(CFrame.new(oldPosition))
    end
end

-- ── BringAllLogs (exact port) ─────────────────────────────────────────────────
local function BringAllLogs()
    local OldPos = player.Character.HumanoidRootPart.CFrame
    for _, v in next, workspace.LogModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == player then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(v:FindFirstChild("WoodSection").CFrame.p)
            if not v.PrimaryPart then v.PrimaryPart = v:FindFirstChild("WoodSection") end
            for _ = 1, 50 do
                RS.Interaction.ClientIsDragging:FireServer(v)
                v:SetPrimaryPartCFrame(OldPos)
                task.wait()
            end
        end
        task.wait()
    end
    player.Character.HumanoidRootPart.CFrame = OldPos
end

-- ── SellAllLogs (exact port) ──────────────────────────────────────────────────
local function SellAllLogs()
    local OldPos = player.Character.HumanoidRootPart.CFrame
    for _, v in next, workspace.LogModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == player then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(v:FindFirstChild("WoodSection").CFrame.p)
            task.wait(0.3)
            if not v.PrimaryPart then v.PrimaryPart = v:FindFirstChild("WoodSection") end
            task.spawn(function()
                for _ = 1, 50 do
                    RS.Interaction.ClientIsDragging:FireServer(v)
                    v:SetPrimaryPartCFrame(CFrame.new(314, -0.5, 86.822))
                    task.wait()
                end
            end)
        end
        task.wait()
    end
    task.wait()
    player.Character.HumanoidRootPart.CFrame = OldPos
end

-- ── DismemberTree (exact port) ────────────────────────────────────────────────
local function DismemberTree()
    local OldPos = player.Character.HumanoidRootPart.CFrame
    local LogChopped = false
    local TreeToJointCut = nil
    local branchadded = workspace.LogModels.ChildAdded:Connect(function(v)
        if v:WaitForChild("Owner") and v.Owner.Value == player then
            if v:WaitForChild("WoodSection") then LogChopped = true end
        end
    end)
    local DismemberTreeC = woodMouse.Button1Up:Connect(function()
        local Clicked = woodMouse.Target
        if Clicked and Clicked.Parent:FindFirstAncestor("LogModels") then
            if Clicked.Parent:FindFirstChild("Owner") and Clicked.Parent.Owner.Value == player then
                TreeToJointCut = Clicked.Parent
            end
        end
    end)
    repeat task.wait() until TreeToJointCut ~= nil
    if TreeToJointCut:FindFirstChild("WoodClass")
       and TreeToJointCut.WoodClass.Value == "LoneCave"
       and GetBestAxe("LoneCave").ToolName.Value ~= "EndTimesAxe" then
        branchadded:Disconnect(); DismemberTreeC:Disconnect(); return
    end
    for _, v in next, TreeToJointCut:GetChildren() do
        if v.Name == "WoodSection" and v:FindFirstChild("ID") and v.ID.Value ~= 1 then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(v.CFrame.p)
            repeat
                ChopTree(v.Parent:FindFirstChild("CutEvent"), v.ID.Value, 0, v.Parent:FindFirstChild("TreeClass").Value)
                task.wait()
            until LogChopped == true
            LogChopped = false
            task.wait(1)
        end
    end
    branchadded:Disconnect(); DismemberTreeC:Disconnect()
    player.Character.HumanoidRootPart.CFrame = OldPos
end

-- ── ViewEndTree (exact port) ──────────────────────────────────────────────────
local function ViewEndTree(Val)
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "TreeRegion" then
            for _, v2 in pairs(v:GetChildren()) do
                if v2:FindFirstChild("Owner") and tostring(v2.Owner.Value) == "nil" then
                    if v2:FindFirstChild("TreeClass") and tostring(v2.TreeClass.Value) == "LoneCave" then
                        workspace.Camera.CameraSubject = Val
                            and v2:FindFirstChild("WoodSection")
                            or  player.Character.Humanoid
                    end
                end
            end
        end
    end
end

-- ── OneUnitCutter (exact port from Butterhub) ─────────────────────────────────
local UnitCutter      = false
local PlankReAdded    = nil
local UnitCutterClick = nil
local SelTree         = nil

local function PlrHasTool()
    return player.Backpack:FindFirstChild("Tool") ~= nil
        or player.Character:FindFirstChild("Tool") ~= nil
end

local function OneUnitCutter(Val)
    if not Val then
        if PlankReAdded   then PlankReAdded:Disconnect();   PlankReAdded   = nil end
        if UnitCutterClick then UnitCutterClick:Disconnect(); UnitCutterClick = nil end
        return
    end
    PlankReAdded = workspace.PlayerModels.ChildAdded:Connect(function(v)
        if v:WaitForChild("TreeClass") and v:WaitForChild("WoodSection") then
            SelTree = v
            task.wait()
        end
    end)
    UnitCutterClick = woodMouse.Button1Up:Connect(function()
        local Clicked = woodMouse.Target
        if not PlrHasTool() then return end
        if Clicked and Clicked.Name == "WoodSection" then
            SelTree = Clicked.Parent
            player.Character:MoveTo(Clicked.Position + Vector3.new(0,3,-3))
            repeat
                if not UnitCutter then break end
                ChopTree(SelTree.CutEvent, 1, 1, SelTree.TreeClass.Value)
                if SelTree:FindFirstChild("WoodSection") then
                    player.Character:MoveTo(SelTree.WoodSection.Position + Vector3.new(0,3,-3))
                end
                task.wait()
            until SelTree.WoodSection.Size.X <= 1.88
              and SelTree.WoodSection.Size.Y <= 1.88
              and SelTree.WoodSection.Size.Z <= 1.88
        end
    end)
end

-- ── ModWood (exact port from Butterhub) ───────────────────────────────────────
-- Modded wood: uses lava-fire to separate a branch from the tree then
-- delivers the selected branch to the sawmill's cut zone.
local ModWoodSawmill  = nil
local ModWoodOn       = false
local ModwoodConn     = nil
local worked          = false
local addedstuff      = nil
local treelimbblist   = {}
local childbranch     = nil
local parentbranch    = nil
local childbranchId   = nil
local firstpart       = nil

-- SelectSawmill: player clicks a sawmill and we store the reference
local SelectSawmillConn = nil
local function SelectSawmill(typeStr)
    SelectSawmillConn = woodMouse.Button1Up:Connect(function()
        local target = woodMouse.Target
        if not target then return end
        local model = target.Parent
        if model:FindFirstChild("ItemName") and model.ItemName.Value:find("Sawmill") then
            ModWoodSawmill = model
            if SelectSawmillConn then SelectSawmillConn:Disconnect(); SelectSawmillConn = nil end
        end
    end)
end

local function ifworked()
    worked = false
    addedstuff = workspace.LogModels.ChildAdded:Connect(function(v)
        if v:WaitForChild("Owner") and v.Owner.Value == player then
            if v:WaitForChild("WoodSection") then worked = true end
        end
    end)
end

local function ModWood()
    ModWoodSawmill = nil
    SelectSawmill("Mod Wood")
    repeat task.wait() until ModWoodSawmill

    ModWoodOn = true
    treelimbblist = {}
    childbranch   = nil
    parentbranch  = nil
    firstpart     = nil

    ModwoodConn = woodMouse.Button1Down:Connect(function()
        local Clicked = woodMouse.Target
        if not Clicked then return end
        if Clicked.Parent:FindFirstAncestor("LogModels") then
            if Clicked.Parent:FindFirstChild("Owner") and Clicked.Parent.Owner.Value == player then
                for _, v in pairs(Clicked.Parent:GetDescendants()) do
                    if v.Name == "ChildIDs" and #(v:GetChildren()) == 0 then
                        table.insert(treelimbblist, v.Parent.ID.Value)
                    end
                end
                table.sort(treelimbblist)
                for _, v in pairs(Clicked.Parent:GetDescendants()) do
                    if v.Name == "ChildIDs" then
                        for _, v2 in pairs(v:GetChildren()) do
                            if v2.Value == treelimbblist[#treelimbblist] then
                                parentbranch = v2.Parent.Parent
                                Instance.new("Highlight", parentbranch)
                            end
                        end
                    else
                        if v.Name == "ID" and v.Value == treelimbblist[#treelimbblist] then
                            Instance.new("Highlight", v.Parent).FillColor = Color3.new(0,1,0)
                            childbranchId = treelimbblist[#treelimbblist]
                            childbranch   = v.Parent
                        end
                    end
                end
            end
        end
    end)

    repeat task.wait() until childbranch

    local oldpos   = player.Character.HumanoidRootPart.CFrame
    local LavaPart = GetLava()
    firstpart = childbranch.Parent:FindFirstChild("WoodSection")

    player.Character.HumanoidRootPart.CFrame = firstpart.CFrame
    task.wait(0.2)

    -- Burn parent branch in lava to separate it
    repeat
        task.wait()
        while not isnetworkowner(parentbranch) do
            RS.Interaction.ClientIsDragging:FireServer(parentbranch.Parent)
            task.wait()
        end
        RS.Interaction.ClientIsDragging:FireServer(parentbranch.Parent)
        parentbranch:PivotTo(CFrame.new(-1425, 489, 1244))
        firetouchinterest(parentbranch, LavaPart.Lava, 0)
        firetouchinterest(parentbranch, LavaPart.Lava, 1)
    until parentbranch:FindFirstChild("LavaFire")

    firstpart = childbranch.Parent:FindFirstChild("WoodSection")
    player.Character.HumanoidRootPart.CFrame = firstpart.CFrame
    task.wait(0.3)

    while not isnetworkowner(firstpart) do
        RS.Interaction.ClientIsDragging:FireServer(firstpart.Parent)
        firstpart.Velocity = Vector3.new(0,0,0)
        childbranch.Velocity = Vector3.new(0,0,0)
        task.wait()
    end
    RS.Interaction.ClientIsDragging:FireServer(firstpart.Parent)
    firstpart:PivotTo(CFrame.new(-1055, 291, -458))
    task.wait(0.3)

    player.Character.HumanoidRootPart.CFrame = childbranch.CFrame * CFrame.new(5,0,0)
    while not isnetworkowner(childbranch) do
        RS.Interaction.ClientIsDragging:FireServer(childbranch.Parent)
        task.wait()
    end
    RS.Interaction.ClientIsDragging:FireServer(childbranch.Parent)
    childbranch:PivotTo(CFrame.new(-1055, 291, -458))

    -- Clean up lava forces
    pcall(function() parentbranch:FindFirstChild("LavaFire"):Destroy() end)
    pcall(function() parentbranch:FindFirstChild("BodyAngularVelocity"):Destroy() end)
    pcall(function() parentbranch:FindFirstChild("BodyVelocity"):Destroy() end)

    player.Character.HumanoidRootPart.CFrame = parentbranch.CFrame
    task.wait(0.1)

    -- Sell the parent branch at wood dropoff
    repeat
        RS.Interaction.ClientIsDragging:FireServer(parentbranch.Parent)
        parentbranch:PivotTo(CFrame.new(314.54, -0.5, 86.823))
        task.wait()
    until not parentbranch.Parent

    firstpart = childbranch.Parent:FindFirstChild("WoodSection")
    ifworked()

    task.spawn(function()
        repeat
            task.wait()
            player.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            player.Character.HumanoidRootPart.CFrame   = firstpart.CFrame * CFrame.new(5,0,0)
        until worked
    end)

    -- Chop the child branch off with best axe
    repeat
        task.wait()
        RS.Interaction.RemoteProxy:FireServer(
            childbranch.Parent:FindFirstChild("CutEvent"), {
                tool         = GetBestAxe(childbranch.Parent:FindFirstChild("TreeClass").Value),
                faceVector   = Vector3.new(1, 0, 0),
                height       = 0.3,
                sectionId    = 1,
                hitPoints    = GetAxeDamage(childbranch.Parent:FindFirstChild("TreeClass").Value),
                cooldown     = 0.25837870788574,
                cuttingClass = "Axe",
            }
        )
    until worked
    task.wait(0.3)

    player.Character.HumanoidRootPart.CFrame = childbranch.CFrame * CFrame.new(5,0,0)
    while not isnetworkowner(childbranch) do
        player.Character.HumanoidRootPart.CFrame = childbranch.CFrame * CFrame.new(5,0,0)
        RS.Interaction.ClientIsDragging:FireServer(childbranch.Parent)
        task.wait()
    end

    player.Character.HumanoidRootPart.CFrame = childbranch.CFrame * CFrame.new(5,0,0)
    task.wait(0.2)
    RS.Interaction.ClientIsDragging:FireServer(childbranch.Parent)
    task.wait(0.3)

    -- Deliver child branch to sawmill
    childbranch:PivotTo(ModWoodSawmill.Particles.CFrame + Vector3.new(0, .5, 0))

    player.Character.HumanoidRootPart.CFrame = oldpos

    -- Reset all state
    ModWoodOn     = false
    childbranch   = nil
    parentbranch  = nil
    worked        = false
    treelimbblist = {}
    firstpart     = nil
    ModWoodSawmill = nil
    if addedstuff      then addedstuff:Disconnect();   addedstuff   = nil end
    if ModwoodConn     then ModwoodConn:Disconnect();  ModwoodConn  = nil end
end

-- ════════════════════════════════════════════════════
-- WOOD TAB — SELL ENGINE  (smooth per-log sell)
-- ════════════════════════════════════════════════════

local SELL_CONFIRM = 6     -- studs
local SELL_TIMEOUT = 3.0

local function isWoodLog(model)
    if not model or not model:IsA("Model") then return false end
    if not model:FindFirstChild("TreeClass")  then return false end
    if model:FindFirstChild("DraggableItem")  then return false end
    if not (model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")) then return false end
    return true
end

-- Selection state
local woodSelected    = {}
local clickSellEnabled   = false
local groupSelectEnabled = false
local isSellRunning      = false
local sellOriginCF       = nil
local currentSellConn    = nil
local clickSellBusy      = false
local clickSellConn      = nil

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
    for model, hl in pairs(woodSelected) do
        if hl and hl.Parent then hl:Destroy() end
    end
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
        local c2  = player.Character
        local h2  = c2 and c2:FindFirstChild("HumanoidRootPart")
        if not h2 then conn:Disconnect(); if onDone then task.spawn(onDone,false) end; return end
        if (h2.Position - mainPart.Position).Magnitude > 20 then
            h2.CFrame = mainPart.CFrame * CFrame.new(0,3,3)
        end
        disableCharCollision(c2)
        if dragger then pcall(function() dragger:FireServer(model) end) end
        pcall(function() mainPart.CFrame = targetCF end)
        local dist     = (mainPart.Position - SELL_POS).Magnitude
        local timedOut = (tick() - startTime) >= SELL_TIMEOUT
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

local function groupSelectLogs(targetModel)
    if not isWoodLog(targetModel) then return end
    local tc = targetModel:FindFirstChild("TreeClass"); if not tc then return end
    local targetClass = tc.Value:lower()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isWoodLog(obj) then
            local otc = obj:FindFirstChild("TreeClass")
            if otc and otc.Value:lower() == targetClass then highlightWood(obj) end
        end
    end
end

local function clickSellLog(model)
    if clickSellBusy then return end
    if not isWoodLog(model) then return end
    local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    clickSellBusy = true
    local originCF = hrp.CFrame
    clickSellConn = sellOneLog(model, function()
        enableCharCollision(player.Character)
        pcall(function()
            local c = player.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = originCF end
        end)
        clickSellConn = nil; clickSellBusy = false
    end)
end

local woodMouseConn = nil
local function connectWoodMouse()
    if woodMouseConn then return end
    woodMouseConn = woodMouse.Button1Down:Connect(function()
        local target = woodMouse.Target; if not target then return end
        local model  = target:FindFirstAncestorOfClass("Model"); if not model then return end
        if clickSellEnabled then
            if isWoodLog(model) and not clickSellBusy then task.spawn(function() clickSellLog(model) end) end
        elseif groupSelectEnabled then
            if isWoodLog(model) then groupSelectLogs(model) end
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
-- WOOD TAB UI HELPERS
-- ════════════════════════════════════════════════════

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

-- Progress bar
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
            end)
            sellOriginCF = nil
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
-- WOOD TAB UI — Build
-- ════════════════════════════════════════════════════

local TREE_LIST = {
    "Generic","Walnut","Cherry","Oak","Birch","Koa","Fir",
    "Pine","Palm","Koa",
    "SnowGlow","Frost","Spooky","SpookyNeon",
    "Volcano","GreenSwampy","GoldSwampy","CaveCrawler",
    "LoneCave",
}
-- deduplicate
do
    local seen = {}; local out = {}
    for _, v in ipairs(TREE_LIST) do
        if not seen[v] then seen[v]=true; table.insert(out,v) end
    end
    TREE_LIST = out
end

local selectedTree = nil
local bringAmount  = 1

-- ── Bring Tree section ───────────────────────────────────────────────────────
createWSectionLabel("Bring Tree")
makeFancyDropdown(woodPage, "Tree", function() return TREE_LIST end, function(val)
    selectedTree = val
end)

-- Amount slider
do
    local slFrame = Instance.new("Frame", woodPage)
    slFrame.Size = UDim2.new(1,-12,0,52); slFrame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    slFrame.BorderSizePixel = 0; corner(slFrame, 6)
    local slLbl = Instance.new("TextLabel", slFrame)
    slLbl.Size = UDim2.new(0.6,0,0,22); slLbl.Position = UDim2.new(0,8,0,6)
    slLbl.BackgroundTransparency=1; slLbl.Font=Enum.Font.GothamSemibold; slLbl.TextSize=13
    slLbl.TextColor3=THEME_TEXT; slLbl.TextXAlignment=Enum.TextXAlignment.Left; slLbl.Text="Amount"
    local slVal = Instance.new("TextLabel", slFrame)
    slVal.Size = UDim2.new(0.4,0,0,22); slVal.Position = UDim2.new(0.6,-8,0,6)
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
    local dragging=false
    local MIN,MAX=1,30
    local function update(absX)
        local ratio=math.clamp((absX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val=math.round(MIN+ratio*(MAX-MIN))
        fill.Size=UDim2.new(ratio,0,1,0); knob.Position=UDim2.new(ratio,0,0.5,0)
        slVal.Text=tostring(val); bringAmount=val
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

createWButton("Bring Tree", Color3.fromRGB(35,80,35), function()
    if not selectedTree then return end
    task.spawn(function()
        if selectedTree == "LoneCave" then
            bringTree(selectedTree, true)
        else
            for _ = 1, bringAmount do
                bringTree(selectedTree, false)
            end
        end
    end)
end)

createWButton("Abort Bring", BTN_COLOR, function()
    getgenv().treestop = false
    task.wait(5)
    getgenv().treestop = true
end)

createWSep()
-- ── Log Actions ───────────────────────────────────────────────────────────────
createWSectionLabel("Log Actions")
createWButton("Bring All Logs", BTN_COLOR, function()
    task.spawn(BringAllLogs)
end)
createWButton("Sell All Logs", Color3.fromRGB(35,90,35), function()
    task.spawn(SellAllLogs)
end)

createWSep()
-- ── Click Sell / Selection ────────────────────────────────────────────────────
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
    isSellRunning=false
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
            task.delay(0.45,function() if sellProgressContainer then sellProgressContainer.Visible=false; sellProgressContainer.BackgroundTransparency=0 end end)
        end)
    end
    unhighlightAllWood()
end)
createWButton("Clear Selection", BTN_COLOR, function() unhighlightAllWood() end)

createWSep()
-- ── 1x1 Cut ───────────────────────────────────────────────────────────────────
createWSectionLabel("Sawmill — 1x1 Cut")
createWInfoLabel("  Enables click-to-cut. Click any plank/WoodSection to chop it down to 1×1 size.")
createWToggle("1x1 Cut (click to cut)", false, function(val)
    UnitCutter = val
    OneUnitCutter(val)
end)

createWSep()
-- ── Advanced ──────────────────────────────────────────────────────────────────
createWSectionLabel("Advanced Wood")
createWButton("Mod Wood (click tree branch)", Color3.fromRGB(60,40,80), function()
    task.spawn(ModWood)
end)
createWButton("Dismember Tree (click log)", BTN_COLOR, function()
    task.spawn(DismemberTree)
end)

local viewEndActive = false
createWToggle("View LoneCave Tree", false, function(val)
    viewEndActive = val
    ViewEndTree(val)
end)

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
                {BackgroundColor3 = Color3.fromRGB(60,180,60)}):Play()
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

    if input.KeyCode == getCurrentToggleKey() then
        toggleGUI(); return
    end

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
    if clickSellConn   then pcall(function() clickSellConn:Disconnect()   end); clickSellConn   = nil end
    if currentSellConn then pcall(function() currentSellConn:Disconnect() end); currentSellConn = nil end
    if PlankReAdded    then PlankReAdded:Disconnect();   PlankReAdded   = nil end
    if UnitCutterClick then UnitCutterClick:Disconnect(); UnitCutterClick = nil end
    if ModwoodConn     then ModwoodConn:Disconnect();    ModwoodConn    = nil end
    if addedstuff      then addedstuff:Disconnect();     addedstuff     = nil end
    if SelectSawmillConn then SelectSawmillConn:Disconnect(); SelectSawmillConn = nil end
    disconnectWoodMouse()
    enableCharCollision(player.Character)
    unhighlightAllWood()
    getgenv().treestop = false
end)

_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded — Settings, Search, Wood (full)")
