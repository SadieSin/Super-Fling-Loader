-- ════════════════════════════════════════════════════
-- VANILLA3 — AutoBuy Tab + Settings Tab + Search Tab + Input Handler
-- Imports shared state from Vanilla1 via _G.VH
-- ════════════════════════════════════════════════════
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

-- Fly/keybind state — mutable values accessed via _G.VH so Vanilla1 and Vanilla3 share state
-- Read-only snapshot for flyKeyBtn (GUI object reference, safe as local)
local flyKeyBtn        = _G.VH.flyKeyBtn
-- All mutable flags are read/written through _G.VH directly (see input handler below)
local keybindButtonGUI -- set below in Settings tab, then written to _G.VH

-- Helpers to read/write shared mutable state cleanly
local function getWaitingForFlyKey() return _G.VH.waitingForFlyKey end
local function setWaitingForFlyKey(v) _G.VH.waitingForFlyKey = v end
local function getWaitingForKeyGUI() return _G.VH.waitingForKeyGUI end
local function setWaitingForKeyGUI(v) _G.VH.waitingForKeyGUI = v end
local function getCurrentFlyKey() return _G.VH.currentFlyKey end
local function setCurrentFlyKey(v) _G.VH.currentFlyKey = v end
local function getCurrentToggleKey() return _G.VH.currentToggleKey end
local function setCurrentToggleKey(v) _G.VH.currentToggleKey = v end
local function getFlyToggleEnabled() return _G.VH.flyToggleEnabled end
local function getIsFlyEnabled() return _G.VH.isFlyEnabled end

-- ════════════════════════════════════════════════════
-- AUTOBUY TAB
-- ════════════════════════════════════════════════════
local autoBuyPage = pages["AutoBuyTab"]

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function createABSection(text)
    local lbl = Instance.new("TextLabel", autoBuyPage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function createABSep()
    local sep = Instance.new("Frame", autoBuyPage)
    sep.Size = UDim2.new(1,-12,0,1); sep.BackgroundColor3 = Color3.fromRGB(40,40,55); sep.BorderSizePixel = 0
end

local function createABBtn(text, callback)
    local btn = Instance.new("TextButton", autoBuyPage)
    btn.Size = UDim2.new(1,-12,0,32); btn.BackgroundColor3 = BTN_COLOR
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(210,210,220); btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ── Item catalogue (every purchaseable non-limited item from LT2 stores) ─────
local AB_ITEMS = {
    -- Wood R Us
    "Basic Hatchet", "Plain Axe", "Steel Axe", "Silver Axe", "Golden Axe",
    "Rukiryaxe", "Beesaxe", "Alpha Axe of Testing",
    -- Fancy Furnishings
    "Door", "Window", "Chair", "Table", "Couch", "Bed", "Bookshelf",
    "Cupboard", "Lamp", "Fan", "Candle", "Clock", "Picture Frame",
    "Rug", "Vase", "Flower Pot", "Mirror", "Shelf", "Cabinet",
    "Fireplace", "Desk", "Piano", "Washing Machine", "Toilet", "Bathtub",
    "Shower", "Sink", "Fridge", "Oven", "Stove", "Microwave",
    "Television", "Computer Desk", "Office Chair", "Sofa", "Hammock",
    "End Table", "Coffee Table", "Dining Table", "Bench", "Bar Stool",
    -- Land Store
    "Small Plot", "Medium Plot", "Large Plot",
    -- Link's Logic
    "Button", "Pressure Plate", "Switch", "Wire", "Basic Gate", "NOT Gate",
    "AND Gate", "OR Gate", "NAND Gate", "NOR Gate", "XOR Gate",
    "Signal Light", "Alarm", "Door Sensor", "Counter", "Timer", "Delay",
    "Conveyor", "Display", "Speaker", "Detector",
    -- Fine Art Shop (non-limited paintings/statues)
    "Canvas", "Sculpture Block", "Painting: Landscape", "Painting: Abstract",
    "Painting: Portrait", "Statue Base", "Picture",
    -- Bob's Shack / Swamp Shack
    "Dynamite", "Fire Extinguisher",
    -- Vehicles / Lumber Yard Store
    "Truck", "Trailer", "Flatbed",
    -- Miscellaneous purchaseable items
    "End Times Chest", "Blueprint", "Fertilizer", "Plank", "Sawmill",
    "Painting Easel", "Wooden Crate", "Storage Box", "Sign",
    "Streetlight", "Lantern", "Campfire",
}
table.sort(AB_ITEMS)

-- ── State ─────────────────────────────────────────────────────────────────────
local abSelectedItem  = ""
local abBuyAmount     = 1
local abRunning       = false
local abThread        = nil
local abCircle        = nil
local abIsMoving      = false

-- ══════════════════════════════════════════════════════
-- SECTION 1 — ITEM DROPDOWN  (with search bar, inline expand)
-- ══════════════════════════════════════════════════════
createABSection("Item to Purchase")

do
    local ITEM_H   = 32
    local MAX_SHOW = 6
    local HEADER_H = 40
    local SEARCH_H = 36

    local outer = Instance.new("Frame", autoBuyPage)
    outer.Size             = UDim2.new(1,-12,0,HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22,22,30)
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0,8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = Color3.fromRGB(60,60,90); outerStroke.Thickness = 1; outerStroke.Transparency = 0.5

    -- Header
    local header = Instance.new("Frame", outer)
    header.Size = UDim2.new(1,0,0,HEADER_H); header.BackgroundTransparency = 1

    local labelTag = Instance.new("TextLabel", header)
    labelTag.Size = UDim2.new(0,60,1,0); labelTag.Position = UDim2.new(0,12,0,0)
    labelTag.BackgroundTransparency = 1; labelTag.Text = "Item"
    labelTag.Font = Enum.Font.GothamBold; labelTag.TextSize = 12
    labelTag.TextColor3 = Color3.fromRGB(140,140,170); labelTag.TextXAlignment = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size = UDim2.new(1,-76,0,28); selFrame.Position = UDim2.new(0,70,0.5,-14)
    selFrame.BackgroundColor3 = Color3.fromRGB(30,30,42); selFrame.BorderSizePixel = 0
    Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", selFrame).Color = Color3.fromRGB(70,70,110)

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size = UDim2.new(1,-30,1,0); selLbl.Position = UDim2.new(0,10,0,0)
    selLbl.BackgroundTransparency = 1; selLbl.Font = Enum.Font.GothamSemibold; selLbl.TextSize = 12
    selLbl.TextColor3 = Color3.fromRGB(110,110,140); selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.Text = "Select an item..."; selLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size = UDim2.new(0,22,1,0); arrowLbl.Position = UDim2.new(1,-24,0,0)
    arrowLbl.BackgroundTransparency = 1; arrowLbl.Text = "▾"
    arrowLbl.Font = Enum.Font.GothamBold; arrowLbl.TextSize = 14
    arrowLbl.TextColor3 = Color3.fromRGB(120,120,160); arrowLbl.TextXAlignment = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size = UDim2.new(1,0,1,0); headerBtn.BackgroundTransparency = 1; headerBtn.Text = ""; headerBtn.ZIndex = 5

    -- Divider
    local divider = Instance.new("Frame", outer)
    divider.Size = UDim2.new(1,-16,0,1); divider.Position = UDim2.new(0,8,0,HEADER_H)
    divider.BackgroundColor3 = Color3.fromRGB(50,50,75); divider.BorderSizePixel = 0; divider.Visible = false

    -- Search bar (inside dropdown)
    local searchBox = Instance.new("TextBox", outer)
    searchBox.Size = UDim2.new(1,-16,0,SEARCH_H-6)
    searchBox.Position = UDim2.new(0,8,0,HEADER_H+6)
    searchBox.BackgroundColor3 = Color3.fromRGB(30,30,42); searchBox.BorderSizePixel = 0
    searchBox.PlaceholderText = "🔍 Search items..."; searchBox.Text = ""
    searchBox.Font = Enum.Font.GothamSemibold; searchBox.TextSize = 12
    searchBox.TextColor3 = Color3.fromRGB(210,210,220); searchBox.PlaceholderColor3 = Color3.fromRGB(100,100,130)
    searchBox.TextXAlignment = Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus = false
    searchBox.Visible = false
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0,6)
    Instance.new("UIPadding", searchBox).PaddingLeft = UDim.new(0,10)

    -- List scroll
    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position = UDim2.new(0,0,0,HEADER_H+SEARCH_H+2)
    listScroll.Size = UDim2.new(1,0,0,0)
    listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3; listScroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
    listScroll.CanvasSize = UDim2.new(0,0,0,0); listScroll.ClipsDescendants = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y+6)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop = UDim.new(0,4); listPad.PaddingBottom = UDim.new(0,4)
    listPad.PaddingLeft = UDim.new(0,6); listPad.PaddingRight = UDim.new(0,6)

    local isOpen = false

    local function buildList(filter)
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        local lf = string.lower(filter or "")
        local filtered = {}
        for _, name in ipairs(AB_ITEMS) do
            if lf == "" or string.find(string.lower(name), lf, 1, true) then
                table.insert(filtered, name)
            end
        end
        for i, name in ipairs(filtered) do
            local row = Instance.new("TextButton", listScroll)
            row.Size = UDim2.new(1,0,0,ITEM_H); row.LayoutOrder = i
            row.BackgroundColor3 = (name == abSelectedItem) and Color3.fromRGB(45,45,75) or Color3.fromRGB(28,28,40)
            row.BorderSizePixel = 0; row.Text = name
            row.Font = Enum.Font.GothamSemibold; row.TextSize = 12
            row.TextColor3 = (name == abSelectedItem) and Color3.fromRGB(210,215,255) or Color3.fromRGB(200,200,215)
            row.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
            Instance.new("UIPadding", row).PaddingLeft = UDim.new(0,10)
            row.MouseEnter:Connect(function()
                if name ~= abSelectedItem then
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(38,38,58)}):Play()
                end
            end)
            row.MouseLeave:Connect(function()
                if name ~= abSelectedItem then
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28,28,40)}):Play()
                end
            end)
            row.MouseButton1Click:Connect(function()
                abSelectedItem = (abSelectedItem == name) and "" or name
                selLbl.Text = abSelectedItem ~= "" and abSelectedItem or "Select an item..."
                selLbl.TextColor3 = abSelectedItem ~= "" and Color3.fromRGB(220,225,255) or Color3.fromRGB(110,110,140)
                outerStroke.Color = abSelectedItem ~= "" and Color3.fromRGB(90,90,160) or Color3.fromRGB(60,60,90)
                buildList(searchBox.Text)
                task.delay(0.05, function()
                    isOpen = false; searchBox.Visible = false; divider.Visible = false
                    TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
                    TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
                    TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
                end)
            end)
        end
        return #filtered
    end

    local function openList()
        isOpen = true
        searchBox.Text = ""; searchBox.Visible = true; divider.Visible = true
        local count = buildList("")
        local listH = math.min(count, MAX_SHOW)*(ITEM_H+3)+8
        local totalH = HEADER_H+SEARCH_H+2+listH
        TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=180}):Play()
        TweenService:Create(outer, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,totalH)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,listH)}):Play()
    end

    local function closeList()
        isOpen = false; searchBox.Visible = false; divider.Visible = false
        TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
        TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if not isOpen then return end
        local count = buildList(searchBox.Text)
        local listH = math.min(count, MAX_SHOW)*(ITEM_H+3)+8
        local totalH = HEADER_H+SEARCH_H+2+listH
        outer.Size = UDim2.new(1,-12,0,totalH)
        listScroll.Size = UDim2.new(1,0,0,listH)
    end)

    headerBtn.MouseButton1Click:Connect(function() if isOpen then closeList() else openList() end end)
    headerBtn.MouseEnter:Connect(function() TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play() end)
    headerBtn.MouseLeave:Connect(function() TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(30,30,42)}):Play() end)
end

createABSep()

-- ══════════════════════════════════════════════════════
-- SECTION 2 — AMOUNT SLIDER (1–250)
-- ══════════════════════════════════════════════════════
createABSection("Amount")

do
    local minVal, maxVal, defaultVal = 1, 250, 1
    local frame = Instance.new("Frame", autoBuyPage)
    frame.Size = UDim2.new(1,-12,0,52); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)
    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1,-16,0,22); topRow.Position = UDim2.new(0,8,0,6); topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.7,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = "Buy Amount"
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
    local draggingABSlider = false
    local function updateABSlider(absX)
        local ratio = math.clamp((absX - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        local val = math.max(1, math.round(minVal + ratio*(maxVal-minVal)))
        abBuyAmount = val
        fill.Size = UDim2.new(ratio,0,1,0); knob.Position = UDim2.new(ratio,0,0.5,0)
        valLbl.Text = tostring(val)
    end
    knob.MouseButton1Down:Connect(function() draggingABSlider = true end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingABSlider = true; updateABSlider(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingABSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateABSlider(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingABSlider = false end
    end)
end

createABSep()

-- ══════════════════════════════════════════════════════
-- SECTION 3 — DESTINATION  (same system as Item tab)
-- ══════════════════════════════════════════════════════
createABSection("Delivery Destination")

do
    local tpRow = Instance.new("Frame", autoBuyPage)
    tpRow.Size = UDim2.new(1,-12,0,32); tpRow.BackgroundTransparency = 1

    local tpSet = Instance.new("TextButton", tpRow)
    tpSet.Size = UDim2.new(0.5,-4,1,0); tpSet.Position = UDim2.new(0,0,0,0)
    tpSet.BackgroundColor3 = BTN_COLOR; tpSet.Font = Enum.Font.GothamSemibold
    tpSet.TextSize = 12; tpSet.TextColor3 = Color3.fromRGB(210,210,220); tpSet.Text = "Set Destination"
    Instance.new("UICorner", tpSet).CornerRadius = UDim.new(0,6)

    local tpRemove = Instance.new("TextButton", tpRow)
    tpRemove.Size = UDim2.new(0.5,-4,1,0); tpRemove.Position = UDim2.new(0.5,4,0,0)
    tpRemove.BackgroundColor3 = BTN_COLOR; tpRemove.Font = Enum.Font.GothamSemibold
    tpRemove.TextSize = 12; tpRemove.TextColor3 = Color3.fromRGB(210,210,220); tpRemove.Text = "Remove Destination"
    Instance.new("UICorner", tpRemove).CornerRadius = UDim.new(0,6)

    for _, b in {tpSet, tpRemove} do
        b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=BTN_HOVER}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=BTN_COLOR}):Play() end)
    end

    tpSet.MouseButton1Click:Connect(function()
        if abCircle then abCircle:Destroy() end
        abCircle = Instance.new("Part")
        abCircle.Name = "VanillaHubABCircle"
        abCircle.Shape = Enum.PartType.Ball
        abCircle.Size = Vector3.new(3,3,3)
        abCircle.Material = Enum.Material.SmoothPlastic
        abCircle.Color = Color3.fromRGB(80,200,120)
        abCircle.Anchored = true; abCircle.CanCollide = false
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            abCircle.Position = char.HumanoidRootPart.Position
        end
        abCircle.Parent = workspace
    end)

    tpRemove.MouseButton1Click:Connect(function()
        if abCircle then abCircle:Destroy(); abCircle = nil end
    end)

    table.insert(cleanupTasks, function()
        if abCircle and abCircle.Parent then abCircle:Destroy() end
    end)
end

createABSep()

-- ══════════════════════════════════════════════════════
-- SECTION 4 — ACTIONS (Teleport To / Remote Teleport To / Cancel)
-- ══════════════════════════════════════════════════════
createABSection("Actions")

-- Status label
local abStatusFrame = Instance.new("Frame", autoBuyPage)
abStatusFrame.Size = UDim2.new(1,-12,0,28); abStatusFrame.BackgroundColor3 = Color3.fromRGB(14,14,18)
abStatusFrame.BorderSizePixel = 0
Instance.new("UICorner", abStatusFrame).CornerRadius = UDim.new(0,6)
local abDot = Instance.new("Frame", abStatusFrame)
abDot.Size = UDim2.new(0,7,0,7); abDot.Position = UDim2.new(0,10,0.5,-3)
abDot.BackgroundColor3 = Color3.fromRGB(80,80,100); abDot.BorderSizePixel = 0
Instance.new("UICorner", abDot).CornerRadius = UDim.new(1,0)
local abStatusLbl = Instance.new("TextLabel", abStatusFrame)
abStatusLbl.Size = UDim2.new(1,-28,1,0); abStatusLbl.Position = UDim2.new(0,24,0,0)
abStatusLbl.BackgroundTransparency = 1; abStatusLbl.Font = Enum.Font.Gotham; abStatusLbl.TextSize = 12
abStatusLbl.TextColor3 = Color3.fromRGB(150,150,170); abStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
abStatusLbl.Text = "Ready"

local function setABStatus(msg, active)
    abStatusLbl.Text = msg
    abDot.BackgroundColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
end

-- Progress bar
local abProgressContainer, abProgressFill, abProgressLabel
do
    local container = Instance.new("Frame", autoBuyPage)
    container.Size = UDim2.new(1,-12,0,44); container.BackgroundColor3 = Color3.fromRGB(18,18,24)
    container.BorderSizePixel = 0; container.Visible = false
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,8)
    local pbStroke = Instance.new("UIStroke", container)
    pbStroke.Color = Color3.fromRGB(60,60,80); pbStroke.Thickness = 1; pbStroke.Transparency = 0.5
    local pbLabel = Instance.new("TextLabel", container)
    pbLabel.Size = UDim2.new(1,-12,0,16); pbLabel.Position = UDim2.new(0,6,0,4)
    pbLabel.BackgroundTransparency = 1; pbLabel.Font = Enum.Font.GothamSemibold; pbLabel.TextSize = 11
    pbLabel.TextColor3 = Color3.fromRGB(170,170,200); pbLabel.TextXAlignment = Enum.TextXAlignment.Left
    pbLabel.Text = "Buying..."
    local pbTrack = Instance.new("Frame", container)
    pbTrack.Size = UDim2.new(1,-12,0,12); pbTrack.Position = UDim2.new(0,6,0,24)
    pbTrack.BackgroundColor3 = Color3.fromRGB(30,30,40); pbTrack.BorderSizePixel = 0
    Instance.new("UICorner", pbTrack).CornerRadius = UDim.new(1,0)
    local pbFill = Instance.new("Frame", pbTrack)
    pbFill.Size = UDim2.new(0,0,1,0); pbFill.BackgroundColor3 = Color3.fromRGB(80,200,120)
    pbFill.BorderSizePixel = 0; Instance.new("UICorner", pbFill).CornerRadius = UDim.new(1,0)
    abProgressContainer = container; abProgressFill = pbFill; abProgressLabel = pbLabel
end

-- ── Core buy function (teleports player to store, buys N items, tps them to dest)
local function runAutoBuy(remoteTeleport)
    if abSelectedItem == "" then setABStatus("No item selected!", false); return end
    if abRunning then return end
    abRunning = true; abIsMoving = false

    task.spawn(function()
        setABStatus("Running...", true)
        abProgressContainer.Visible = true
        abProgressFill.Size = UDim2.new(0,0,1,0)
        abProgressLabel.Text = "Buying 0 / " .. abBuyAmount

        -- Find the store item in workspace/game
        local function findStoreItem()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("Part") then
                    local nm = obj:FindFirstChild("ItemName")
                    if nm and string.lower(nm.Value) == string.lower(abSelectedItem) then return obj end
                    if string.lower(obj.Name) == string.lower(abSelectedItem) then return obj end
                end
            end
            return nil
        end

        local bought = 0
        for i = 1, abBuyAmount do
            if not abRunning then break end

            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.5); continue end

            -- Find a buyable store item matching the selected name
            local storeItem = findStoreItem()
            if storeItem then
                -- Teleport player near it and interact
                local mp = storeItem.PrimaryPart or storeItem:FindFirstChildWhichIsA("BasePart") or storeItem
                if mp:IsA("BasePart") then
                    hrp.CFrame = mp.CFrame * CFrame.new(0, 4, 3)
                    task.wait(0.15)
                end
                -- Fire purchase remote
                local buyRemote = game.ReplicatedStorage:FindFirstChild("Interaction")
                    and game.ReplicatedStorage.Interaction:FindFirstChild("BuyItem")
                if buyRemote then
                    pcall(function() buyRemote:FireServer(storeItem) end)
                end
                task.wait(0.3)

                -- If destination set and remote teleport enabled, move last purchased item there
                if abCircle and remoteTeleport then
                    -- Find the item in the player's plot / workspace (recently spawned)
                    task.wait(0.2)
                    -- Try to find a newly-owned instance of this item
                    local newItem = nil
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Model") then
                            local nm = obj:FindFirstChild("ItemName")
                            local own = obj:FindFirstChild("Owner")
                            local nameMatch = (nm and string.lower(nm.Value) == string.lower(abSelectedItem))
                                or string.lower(obj.Name) == string.lower(abSelectedItem)
                            local ownedByMe = own and (
                                (own:IsA("ObjectValue") and own.Value == player) or
                                (own:IsA("StringValue") and own.Value == player.Name)
                            )
                            if nameMatch and ownedByMe then newItem = obj; break end
                        end
                    end
                    if newItem then
                        local mainPart = newItem.PrimaryPart or newItem:FindFirstChildWhichIsA("BasePart")
                        if mainPart then
                            local dragger = game.ReplicatedStorage:FindFirstChild("Interaction")
                                and game.ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
                            hrp.CFrame = mainPart.CFrame * CFrame.new(0,4,2)
                            task.wait(0.12)
                            if dragger then dragger:FireServer(newItem) end
                            task.wait(0.08)
                            mainPart.CFrame = abCircle.CFrame
                            task.wait(0.08)
                            if dragger then dragger:FireServer(newItem) end
                            task.wait(0.15)
                        end
                    end
                end

                bought = bought + 1
            else
                task.wait(0.3)
            end

            -- Progress update
            local pct = bought / math.max(abBuyAmount, 1)
            TweenService:Create(abProgressFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Size = UDim2.new(pct, 0, 1, 0)
            }):Play()
            abProgressLabel.Text = "Buying " .. bought .. " / " .. abBuyAmount
        end

        abRunning = false
        TweenService:Create(abProgressFill, TweenInfo.new(0.2), {Size=UDim2.new(1,0,1,0)}):Play()
        abProgressLabel.Text = "Done! " .. bought .. " / " .. abBuyAmount .. " bought"
        setABStatus("Done! " .. bought .. " bought", false)
        task.delay(2.5, function()
            if abProgressContainer then
                TweenService:Create(abProgressContainer, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
                TweenService:Create(abProgressFill, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
                TweenService:Create(abProgressLabel, TweenInfo.new(0.4), {TextTransparency=1}):Play()
                task.delay(0.45, function()
                    if abProgressContainer then
                        abProgressContainer.Visible = false
                        abProgressContainer.BackgroundTransparency = 0
                        abProgressFill.BackgroundTransparency = 0
                        abProgressLabel.TextTransparency = 0
                    end
                end)
            end
        end)
    end)
end

-- Action buttons row 1
do
    local row = Instance.new("Frame", autoBuyPage)
    row.Size = UDim2.new(1,-12,0,32); row.BackgroundTransparency = 1

    local tpBtn = Instance.new("TextButton", row)
    tpBtn.Size = UDim2.new(0.5,-4,1,0); tpBtn.Position = UDim2.new(0,0,0,0)
    tpBtn.BackgroundColor3 = BTN_COLOR; tpBtn.Font = Enum.Font.GothamSemibold
    tpBtn.TextSize = 12; tpBtn.TextColor3 = Color3.fromRGB(210,210,220); tpBtn.Text = "Teleport To"
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0,6)

    local remoteTpBtn = Instance.new("TextButton", row)
    remoteTpBtn.Size = UDim2.new(0.5,-4,1,0); remoteTpBtn.Position = UDim2.new(0.5,4,0,0)
    remoteTpBtn.BackgroundColor3 = Color3.fromRGB(45,70,55); remoteTpBtn.Font = Enum.Font.GothamSemibold
    remoteTpBtn.TextSize = 12; remoteTpBtn.TextColor3 = Color3.fromRGB(180,230,200); remoteTpBtn.Text = "Remote Teleport To"
    Instance.new("UICorner", remoteTpBtn).CornerRadius = UDim.new(0,6)

    for _, b in {tpBtn, remoteTpBtn} do
        local base = b.BackgroundColor3
        local hov  = (b == tpBtn) and BTN_HOVER or Color3.fromRGB(60,95,75)
        b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=hov}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=base}):Play() end)
    end

    -- "Teleport To" — teleports player to where the store item is
    tpBtn.MouseButton1Click:Connect(function()
        if abSelectedItem == "" then setABStatus("No item selected!", false); return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            local nm = obj:FindFirstChild("ItemName")
            local nameMatch = (nm and string.lower(nm.Value) == string.lower(abSelectedItem))
                or string.lower(obj.Name) == string.lower(abSelectedItem)
            if nameMatch then
                local mp = (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
                    or (obj:IsA("BasePart") and obj)
                if mp then
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = mp.CFrame * CFrame.new(0,4,3) end
                    return
                end
            end
        end
        setABStatus("Item not found in world", false)
    end)

    -- "Remote Teleport To" — buy and send items to destination
    remoteTpBtn.MouseButton1Click:Connect(function()
        if not abCircle then setABStatus("Set a destination first!", false); return end
        runAutoBuy(true)
    end)
end

createABBtn("Buy Items", function()
    runAutoBuy(false)
end)

createABBtn("Cancel", function()
    abRunning = false
    if abThread then pcall(task.cancel, abThread); abThread = nil end
    setABStatus("Cancelled", false)
end)

table.insert(cleanupTasks, function()
    abRunning = false
    if abThread then pcall(task.cancel, abThread); abThread = nil end
    if abCircle and abCircle.Parent then abCircle:Destroy() end
end)

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════
local settingsPage = pages["SettingsTab"]

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size = UDim2.new(1,0,0,70); kbFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
kbFrame.BorderSizePixel = 0; Instance.new("UICorner", kbFrame).CornerRadius = UDim.new(0,10)
local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size = UDim2.new(1,-20,0,28); kbTitle.Position = UDim2.new(0,10,0,8)
kbTitle.BackgroundTransparency = 1; kbTitle.Font = Enum.Font.GothamBold; kbTitle.TextSize = 15
kbTitle.TextColor3 = Color3.fromRGB(220,220,220); kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Text = "GUI Toggle Keybind"
keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size = UDim2.new(0,200,0,28); keybindButtonGUI.Position = UDim2.new(0,10,0,36)
keybindButtonGUI.BackgroundColor3 = Color3.fromRGB(30,30,30); keybindButtonGUI.BorderSizePixel = 0
keybindButtonGUI.Font = Enum.Font.Gotham; keybindButtonGUI.TextSize = 14
keybindButtonGUI.TextColor3 = Color3.fromRGB(200,200,200)
keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
Instance.new("UICorner", keybindButtonGUI).CornerRadius = UDim.new(0,8)
keybindButtonGUI.MouseButton1Click:Connect(function()
    if getWaitingForKeyGUI() then return end
    keybindButtonGUI.Text = "Press any key..."
    setWaitingForKeyGUI(true)
end)
keybindButtonGUI.MouseEnter:Connect(function() TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play() end)
keybindButtonGUI.MouseLeave:Connect(function() TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play() end)

-- ════════════════════════════════════════════════════
-- SEARCH TAB
-- ════════════════════════════════════════════════════
local searchPage = pages["SearchTab"]
local searchInput = Instance.new("TextBox", searchPage)
searchInput.Size = UDim2.new(1,-28,0,42); searchInput.BackgroundColor3 = Color3.fromRGB(22,22,28)
searchInput.PlaceholderText = "🔍 Search for functions or tabs..."; searchInput.Text = ""
searchInput.Font = Enum.Font.GothamSemibold; searchInput.TextSize = 15
searchInput.TextColor3 = Color3.fromRGB(220,220,220); searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false
Instance.new("UICorner", searchInput).CornerRadius = UDim.new(0,10)
Instance.new("UIPadding", searchInput).PaddingLeft = UDim.new(0,14)

local function updateSearchResults(query)
    for _, child in ipairs(searchPage:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local lq = string.lower(query or "")

    -- Searchable functions: {display name, target tab}
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
    }

    local seen = {}
    -- Match tab names
    for _, name in ipairs(tabs) do
        if lq == "" or string.find(string.lower(name), lq) then
            if not seen[name.."Tab"] then
                seen[name.."Tab"] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size = UDim2.new(1,-28,0,42); resBtn.BackgroundColor3 = Color3.fromRGB(22,22,28)
                resBtn.Text = "📂  " .. name .. " Tab"; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
                resBtn.TextColor3 = Color3.fromRGB(200,200,200); resBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UIPadding", resBtn).PaddingLeft = UDim.new(0,16)
                Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0,10)
                resBtn.MouseEnter:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35,35,45), TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
                resBtn.MouseLeave:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22,22,28), TextColor3 = Color3.fromRGB(200,200,200)}):Play() end)
                resBtn.MouseButton1Click:Connect(function() switchTab(name.."Tab") end)
            end
        end
    end
    -- Match functions
    if lq ~= "" then
        for _, entry in ipairs(functions) do
            local fname, ftab = entry[1], entry[2]
            if string.find(string.lower(fname), lq) and not seen[fname] then
                seen[fname] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size = UDim2.new(1,-28,0,42); resBtn.BackgroundColor3 = Color3.fromRGB(18,22,30)
                resBtn.Text = "⚙  " .. fname; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
                resBtn.TextColor3 = Color3.fromRGB(180,210,255); resBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UIPadding", resBtn).PaddingLeft = UDim.new(0,16)
                Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0,10)
                local subLbl = Instance.new("TextLabel", resBtn)
                subLbl.Size = UDim2.new(1,-20,0,16); subLbl.Position = UDim2.new(0,36,1,-18)
                subLbl.BackgroundTransparency = 1; subLbl.Font = Enum.Font.Gotham; subLbl.TextSize = 11
                subLbl.TextColor3 = Color3.fromRGB(120,120,150); subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.Text = "in " .. ftab:gsub("Tab","") .. " tab"
                resBtn.MouseEnter:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28,35,52), TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
                resBtn.MouseLeave:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18,22,30), TextColor3 = Color3.fromRGB(180,210,255)}):Play() end)
                resBtn.MouseButton1Click:Connect(function() switchTab(ftab) end)
            end
        end
    end
end
searchInput:GetPropertyChangedSignal("Text"):Connect(function() updateSearchResults(searchInput.Text) end)
task.delay(0.1, function() updateSearchResults("") end)

-- ════════════════════════════════════════════════════
-- UNIFIED INPUT HANDLER (GUI toggle + Fly key + rebinds)
-- ════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    -- GUI keybind rebind
    if getWaitingForKeyGUI() then
        setWaitingForKeyGUI(false)
        setCurrentToggleKey(input.KeyCode)
        keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
        TweenService:Create(keybindButtonGUI, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true), {
            BackgroundColor3 = Color3.fromRGB(60,180,60)
        }):Play()
        return
    end

    -- Fly key rebind
    if getWaitingForFlyKey() then
        setWaitingForFlyKey(false)
        setCurrentFlyKey(input.KeyCode)
        flyKeyBtn.Text = input.KeyCode.Name
        flyKeyBtn.BackgroundColor3 = BTN_COLOR
        return
    end

    -- GUI toggle
    if input.KeyCode == getCurrentToggleKey() then
        toggleGUI()
        return
    end

    -- Fly hotkey — ONLY works when flyToggleEnabled is true
    if input.KeyCode == getCurrentFlyKey() and getFlyToggleEnabled() then
        if getIsFlyEnabled() then
            stopFly()
        else
            startFly()
        end
    end
end)



-- Export keybindButtonGUI so cleanup in Vanilla1 can access if needed
_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded")
