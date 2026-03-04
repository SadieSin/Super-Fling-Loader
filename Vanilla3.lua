-- ════════════════════════════════════════════════════
-- VANILLA3 — Settings Tab + Search Tab + Input Handler + Wood Tab
-- Imports shared state from Vanilla1 via _G.VH
-- AutoBuy system REMOVED.
-- Wood tab replaced with KronHub-style tree/log system.
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

local function showOverlay(message, subtext)
    local sg = Instance.new("ScreenGui")
    sg.Name = "VH_Overlay"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
    sg.IgnoreGuiInset = true
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = player.PlayerGui end

    local bg = Instance.new("Frame", sg)
    bg.Size = UDim2.new(0, 340, 0, 90)
    bg.AnchorPoint = Vector2.new(0.5, 0.5)
    bg.Position = UDim2.new(0.5, 0, 0.15, 0)
    bg.BackgroundColor3 = Color3.fromRGB(18, 14, 26)
    bg.BorderSizePixel = 0
    bg.BackgroundTransparency = 0.08
    corner(bg, 12)
    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = Color3.fromRGB(130, 80, 200)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2

    task.spawn(function()
        while bg and bg.Parent do
            TweenService:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency=0.6}):Play()
            task.wait(0.8)
            TweenService:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency=0.1}):Play()
            task.wait(0.8)
        end
    end)

    local dot = Instance.new("Frame", bg)
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0, 16, 0, 16)
    dot.BackgroundColor3 = Color3.fromRGB(150, 80, 220)
    dot.BorderSizePixel = 0
    corner(dot, 5)

    local title = Instance.new("TextLabel", bg)
    title.Size = UDim2.new(1, -50, 0, 28)
    title.Position = UDim2.new(0, 34, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(210, 180, 240)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = message

    if subtext then
        local sub = Instance.new("TextLabel", bg)
        sub.Size = UDim2.new(1, -16, 0, 20)
        sub.Position = UDim2.new(0, 8, 0, 38)
        sub.BackgroundTransparency = 1
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 11
        sub.TextColor3 = Color3.fromRGB(130, 110, 160)
        sub.TextXAlignment = Enum.TextXAlignment.Center
        sub.Text = subtext
    end

    local closeBtn = Instance.new("TextButton", bg)
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -24, 0, 4)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = Color3.fromRGB(120, 100, 140)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    bg.Position = UDim2.new(0.5, 0, -0.05, 0)
    TweenService:Create(bg, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.15, 0)
    }):Play()

    return {
        Dismiss = function()
            if not (sg and sg.Parent) then return end
            TweenService:Create(bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, -0.1, 0),
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.25, function() pcall(function() sg:Destroy() end) end)
        end,
        SetText = function(msg)
            if title then title.Text = msg end
        end,
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
        {"Get Tree","WoodTab"},{"Select Tree","WoodTab"},
        {"Bring All Logs","WoodTab"},{"Sell All Logs","WoodTab"},
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
-- WOOD TAB — KronHub-style replacement
-- Tree Option + Logs Option sections matching the new script.
-- All old Bring Tree engine, ModWood, DismemberTree, 1x1 Cut,
-- Click Sell, Sell Selected, etc. have been removed.
-- ════════════════════════════════════════════════════

local woodPage  = pages["WoodTab"]
local woodMouse = player:GetMouse()

-- Expose globals used by the KronHub tree engine
getgenv().GetBiggestTree = function(...) end
getgenv().GetAxe         = function(...) end
getgenv().TreeDrag       = function(...) end
getgenv().BringTools     = function(...) end

-- ── UI helpers ─────────────────────────────────────────────────────────────

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

-- Amount slider
local bringAmount = 1
local function createAmountSlider()
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
    local MIN,MAX=1,20
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

-- ── Tree Option section ─────────────────────────────────────────────────────

local TREE_LIST = {
    "Generic","Oak","Cherry","Fir","Pine","Birch","Walnut","Koa",
    "Volcano","GreenSwampy","GoldSwampy","Palm","SnowGlow","Frost",
    "CaveCrawler","Spooky","SpookyNeon","BlueSpruce","LoneCave",
}

local selectedTree = "Generic"

createWSectionLabel("Tree Option")

makeFancyDropdown(woodPage, "Tree Type:", function() return TREE_LIST end, function(val)
    selectedTree = val
end)

createAmountSlider()

createWButton("Get Tree", Color3.fromRGB(35,80,35), function()
    task.spawn(function()
        local BringToolsFunc  = getgenv().BringTools
        local GetAxeFunc      = getgenv().GetAxe
        local TreeDragFunc    = getgenv().TreeDrag
        local GetBiggestFunc  = getgenv().GetBiggestTree

        if type(BringToolsFunc) == "function" then BringToolsFunc() end

        for i = 1, bringAmount do
            if type(GetAxeFunc) == "function" then GetAxeFunc(selectedTree) end
            if type(TreeDragFunc) == "function" then TreeDragFunc(selectedTree) end
            task.wait(0.5)
        end
    end)
end)

-- ── Logs Option section ─────────────────────────────────────────────────────

createWSep()
createWSectionLabel("Logs Option")

createWButton("Bring All Logs", BTN_COLOR, function()
    task.spawn(function()
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
    end)
end)

createWButton("Sell All Logs", Color3.fromRGB(35,90,35), function()
    task.spawn(function()
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
    end)
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
    if inputConn then inputConn:Disconnect(); inputConn = nil end
end)

_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded — Settings, Search, Wood (KronHub-style)")
