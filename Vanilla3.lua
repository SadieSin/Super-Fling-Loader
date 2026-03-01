-- ════════════════════════════════════════════════════
-- VANILLA3 — AutoBuy Tab + Settings Tab + Search Tab + Vehicle Tab + Input Handler
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

local flyKeyBtn        = _G.VH.flyKeyBtn
local keybindButtonGUI

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
-- AUTOBUY TAB (tab kept, content intentionally empty)
-- ════════════════════════════════════════════════════
local autoBuyPage = pages["AutoBuyTab"]

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
        {"Flip Vehicle", "VehicleTab"}, {"Color Spawner", "VehicleTab"},
        {"Start Spawn", "VehicleTab"}, {"Cancel Spawning", "VehicleTab"},
    }

    local seen = {}
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
-- VEHICLE TAB
-- ════════════════════════════════════════════════════
local vehiclePage = pages["VehicleTab"]

-- ── Shared helpers ────────────────────────────────────

local function createVSectionLabel(text)
    local lbl = Instance.new("TextLabel", vehiclePage)
    lbl.Size = UDim2.new(1,-12,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function createVSep()
    local s = Instance.new("Frame", vehiclePage)
    s.Size = UDim2.new(1,-12,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,40,55)
    s.BorderSizePixel = 0
end

local function createVBtn(text, color, callback)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", vehiclePage)
    btn.Size = UDim2.new(1,-12,0,36)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(210,210,220)
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local r,g,b = color.R*255, color.G*255, color.B*255
    local hov = Color3.fromRGB(
        math.min(r+22,255)/255,
        math.min(g+10,255)/255,
        math.min(b+22,255)/255
    )
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.13), {BackgroundColor3 = hov}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.13), {BackgroundColor3 = color}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ── Color options ─────────────────────────────────────
local COLOR_OPTIONS = {
    { label = "Medium Stone Grey",  brick = "Medium stone grey"  },
    { label = "Dark Grey Metallic", brick = "Dark grey metallic" },
    { label = "Dark Grey",          brick = "Dark grey"          },
    { label = "Silver",             brick = "Silver"             },
    { label = "Sand Green",         brick = "Sand green"         },
    { label = "Faded Green",        brick = "Faded green"        },
    { label = "Sand Red",           brick = "Sand red"           },
    { label = "Dark Red",           brick = "Dark red"           },
    { label = "Earth Yellow",       brick = "Earth yellow"       },
    { label = "Earth Orange",       brick = "Earth orange"       },
    { label = "Brick Yellow",       brick = "Brick yellow"       },
    { label = "Hot Pink",           brick = "Hot pink"           },
}

local selectedColorIndex = 1
local isSpawning         = false
local spawnThread        = nil
local spawnClickConn     = nil
local waitingForSpawnClick = false

-- Cleanup on exit
table.insert(cleanupTasks, function()
    isSpawning = false
    waitingForSpawnClick = false
    if spawnThread then pcall(task.cancel, spawnThread); spawnThread = nil end
    if spawnClickConn then spawnClickConn:Disconnect(); spawnClickConn = nil end
end)

-- ════ SECTION: VEHICLE TOOLS ════════════════════════

createVSectionLabel("Vehicle Tools")

-- Flip Vehicle
createVBtn("🔄  Flip Vehicle", BTN_COLOR, function()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not (hrp and hum) then return end

    -- Try to find the nearest vehicle/seat
    local bestSeat = nil
    local bestDist = 50

    -- First priority: seat the player is currently in
    if hum.SeatPart then
        bestSeat = hum.SeatPart
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if (obj:IsA("VehicleSeat") or obj:IsA("Seat")) then
                local dist = (obj.Position - hrp.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestSeat = obj
                end
            end
        end
    end

    if bestSeat then
        local model = bestSeat:FindFirstAncestorOfClass("Model")
        if model and model.PrimaryPart then
            local cf = model.PrimaryPart.CFrame
            local pos = cf.Position + Vector3.new(0, 5, 0)
            -- Flip upside-down around the Y axis of the current orientation
            model:SetPrimaryPartCFrame(
                CFrame.new(pos) *
                CFrame.fromEulerAnglesYXZ(0, select(2, cf:ToEulerAnglesYXZ()), math.pi)
            )
        end
    end
end)

createVSep()

-- ════ SECTION: COLOR SPAWNER ════════════════════════

createVSectionLabel("Color Spawner")

-- ── Inline expanding dropdown ─────────────────────────
local DROP_ITEM_H   = 32
local DROP_MAX_SHOW = 6
local DROP_HEADER_H = 38
local isDropOpen    = false

local dropOuter = Instance.new("Frame", vehiclePage)
dropOuter.Size = UDim2.new(1,-12,0,DROP_HEADER_H)
dropOuter.BackgroundColor3 = Color3.fromRGB(22,22,30)
dropOuter.BorderSizePixel = 0
dropOuter.ClipsDescendants = true
Instance.new("UICorner", dropOuter).CornerRadius = UDim.new(0,8)
local dropStroke = Instance.new("UIStroke", dropOuter)
dropStroke.Color = Color3.fromRGB(60,60,90)
dropStroke.Thickness = 1
dropStroke.Transparency = 0.5

-- Header row
local dropHeader = Instance.new("Frame", dropOuter)
dropHeader.Size = UDim2.new(1,0,0,DROP_HEADER_H)
dropHeader.BackgroundTransparency = 1

local dropPrefixLbl = Instance.new("TextLabel", dropHeader)
dropPrefixLbl.Size = UDim2.new(0,110,1,0)
dropPrefixLbl.Position = UDim2.new(0,10,0,0)
dropPrefixLbl.BackgroundTransparency = 1
dropPrefixLbl.Text = "Select Color:"
dropPrefixLbl.Font = Enum.Font.GothamBold
dropPrefixLbl.TextSize = 12
dropPrefixLbl.TextColor3 = Color3.fromRGB(140,140,170)
dropPrefixLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Selected value display
local swatchRow = Instance.new("Frame", dropHeader)
swatchRow.Size = UDim2.new(1,-120,0,26)
swatchRow.Position = UDim2.new(0,112,0.5,-13)
swatchRow.BackgroundColor3 = Color3.fromRGB(30,30,42)
swatchRow.BorderSizePixel = 0
Instance.new("UICorner", swatchRow).CornerRadius = UDim.new(0,6)
local swatchStroke = Instance.new("UIStroke", swatchRow)
swatchStroke.Color = Color3.fromRGB(70,70,110)
swatchStroke.Thickness = 1
swatchStroke.Transparency = 0.45

local colorSwatch = Instance.new("Frame", swatchRow)
colorSwatch.Size = UDim2.new(0,14,0,14)
colorSwatch.Position = UDim2.new(0,7,0.5,-7)
colorSwatch.BorderSizePixel = 0
local _ok, _bc = pcall(function() return BrickColor.new(COLOR_OPTIONS[1].brick) end)
colorSwatch.BackgroundColor3 = _ok and _bc.Color or Color3.fromRGB(180,180,180)
Instance.new("UICorner", colorSwatch).CornerRadius = UDim.new(0,3)

local selColorLbl = Instance.new("TextLabel", swatchRow)
selColorLbl.Size = UDim2.new(1,-52,1,0)
selColorLbl.Position = UDim2.new(0,28,0,0)
selColorLbl.BackgroundTransparency = 1
selColorLbl.Text = COLOR_OPTIONS[1].label
selColorLbl.Font = Enum.Font.GothamSemibold
selColorLbl.TextSize = 12
selColorLbl.TextColor3 = Color3.fromRGB(220,225,255)
selColorLbl.TextXAlignment = Enum.TextXAlignment.Left
selColorLbl.TextTruncate = Enum.TextTruncate.AtEnd

local dropArrow = Instance.new("TextLabel", swatchRow)
dropArrow.Size = UDim2.new(0,20,1,0)
dropArrow.Position = UDim2.new(1,-22,0,0)
dropArrow.BackgroundTransparency = 1
dropArrow.Text = "▾"
dropArrow.Font = Enum.Font.GothamBold
dropArrow.TextSize = 13
dropArrow.TextColor3 = Color3.fromRGB(120,120,160)
dropArrow.TextXAlignment = Enum.TextXAlignment.Center

local dropClickBtn = Instance.new("TextButton", swatchRow)
dropClickBtn.Size = UDim2.new(1,0,1,0)
dropClickBtn.BackgroundTransparency = 1
dropClickBtn.Text = ""
dropClickBtn.ZIndex = 5

-- Divider between header and list
local dropDivider = Instance.new("Frame", dropOuter)
dropDivider.Size = UDim2.new(1,-12,0,1)
dropDivider.Position = UDim2.new(0,6,0,DROP_HEADER_H)
dropDivider.BackgroundColor3 = Color3.fromRGB(50,50,75)
dropDivider.BorderSizePixel = 0
dropDivider.Visible = false

-- Scrolling list container
local dropList = Instance.new("ScrollingFrame", dropOuter)
dropList.Position = UDim2.new(0,0,0,DROP_HEADER_H+2)
dropList.Size = UDim2.new(1,0,0,0)
dropList.BackgroundTransparency = 1
dropList.BorderSizePixel = 0
dropList.ScrollBarThickness = 3
dropList.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
dropList.CanvasSize = UDim2.new(0,0,0,0)
dropList.ClipsDescendants = true

local dropListLayout = Instance.new("UIListLayout", dropList)
dropListLayout.Padding = UDim.new(0,3)
dropListLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    dropList.CanvasSize = UDim2.new(0,0,0, dropListLayout.AbsoluteContentSize.Y + 6)
end)
local dlPad = Instance.new("UIPadding", dropList)
dlPad.PaddingTop = UDim.new(0,4); dlPad.PaddingBottom = UDim.new(0,4)
dlPad.PaddingLeft = UDim.new(0,5); dlPad.PaddingRight = UDim.new(0,5)

local function refreshSwatch(idx)
    local entry = COLOR_OPTIONS[idx]
    local ok2, bc2 = pcall(function() return BrickColor.new(entry.brick) end)
    colorSwatch.BackgroundColor3 = ok2 and bc2.Color or Color3.fromRGB(180,180,180)
    selColorLbl.Text = entry.label
end

local function buildDropList()
    for _, c in ipairs(dropList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for i, entry in ipairs(COLOR_OPTIONS) do
        local isSel = (i == selectedColorIndex)
        local row = Instance.new("Frame", dropList)
        row.Size = UDim2.new(1,0,0,DROP_ITEM_H)
        row.BackgroundColor3 = isSel and Color3.fromRGB(40,40,70) or Color3.fromRGB(26,26,38)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

        local dot = Instance.new("Frame", row)
        dot.Size = UDim2.new(0,12,0,12)
        dot.Position = UDim2.new(0,8,0.5,-6)
        dot.BorderSizePixel = 0
        local ok3, bc3 = pcall(function() return BrickColor.new(entry.brick) end)
        dot.BackgroundColor3 = ok3 and bc3.Color or Color3.fromRGB(180,180,180)
        Instance.new("UICorner", dot).CornerRadius = UDim.new(0,3)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1,-48,1,0)
        nameLbl.Position = UDim2.new(0,28,0,0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = entry.label
        nameLbl.Font = Enum.Font.GothamSemibold
        nameLbl.TextSize = 12
        nameLbl.TextColor3 = isSel and Color3.fromRGB(210,215,255) or Color3.fromRGB(190,190,210)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        if isSel then
            local check = Instance.new("TextLabel", row)
            check.Size = UDim2.new(0,22,1,0)
            check.Position = UDim2.new(1,-26,0,0)
            check.BackgroundTransparency = 1
            check.Text = "✓"
            check.Font = Enum.Font.GothamBold
            check.TextSize = 13
            check.TextColor3 = Color3.fromRGB(120,180,255)
            check.TextXAlignment = Enum.TextXAlignment.Center
        end

        local rowBtn = Instance.new("TextButton", row)
        rowBtn.Size = UDim2.new(1,0,1,0)
        rowBtn.BackgroundTransparency = 1
        rowBtn.Text = ""
        rowBtn.ZIndex = 5

        rowBtn.MouseEnter:Connect(function()
            if i ~= selectedColorIndex then
                TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(36,36,55)}):Play()
            end
        end)
        rowBtn.MouseLeave:Connect(function()
            if i ~= selectedColorIndex then
                TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(26,26,38)}):Play()
            end
        end)
        rowBtn.MouseButton1Click:Connect(function()
            selectedColorIndex = i
            refreshSwatch(i)
            buildDropList()
            task.delay(0.05, function()
                isDropOpen = false
                TweenService:Create(dropArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
                TweenService:Create(dropOuter, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,DROP_HEADER_H)}):Play()
                TweenService:Create(dropList, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
                dropDivider.Visible = false
            end)
        end)
    end
end

local function openDrop()
    isDropOpen = true
    buildDropList()
    local listH = math.min(#COLOR_OPTIONS, DROP_MAX_SHOW) * (DROP_ITEM_H + 3) + 8
    local totalH = DROP_HEADER_H + 2 + listH
    dropDivider.Visible = true
    TweenService:Create(dropArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
    TweenService:Create(dropOuter, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,totalH)}):Play()
    TweenService:Create(dropList, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,listH)}):Play()
end

local function closeDrop()
    isDropOpen = false
    TweenService:Create(dropArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
    TweenService:Create(dropOuter, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,DROP_HEADER_H)}):Play()
    TweenService:Create(dropList, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
    dropDivider.Visible = false
end

dropClickBtn.MouseButton1Click:Connect(function()
    if isDropOpen then closeDrop() else openDrop() end
end)
dropClickBtn.MouseEnter:Connect(function()
    TweenService:Create(swatchRow, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(38,38,55)}):Play()
end)
dropClickBtn.MouseLeave:Connect(function()
    TweenService:Create(swatchRow, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30,30,42)}):Play()
end)

createVSep()

-- ════ SECTION: VEHICLE SPAWN ════════════════════════

createVSectionLabel("Vehicle Spawn")

-- Status pill
local spawnStatusFrame = Instance.new("Frame", vehiclePage)
spawnStatusFrame.Size = UDim2.new(1,-12,0,28)
spawnStatusFrame.BackgroundColor3 = Color3.fromRGB(14,14,18)
spawnStatusFrame.BorderSizePixel = 0
Instance.new("UICorner", spawnStatusFrame).CornerRadius = UDim.new(0,6)

local vsdot = Instance.new("Frame", spawnStatusFrame)
vsdot.Size = UDim2.new(0,7,0,7)
vsdot.Position = UDim2.new(0,10,0.5,-3)
vsdot.BackgroundColor3 = Color3.fromRGB(80,80,100)
vsdot.BorderSizePixel = 0
Instance.new("UICorner", vsdot).CornerRadius = UDim.new(1,0)

local spawnStatusLbl = Instance.new("TextLabel", spawnStatusFrame)
spawnStatusLbl.Size = UDim2.new(1,-28,1,0)
spawnStatusLbl.Position = UDim2.new(0,24,0,0)
spawnStatusLbl.BackgroundTransparency = 1
spawnStatusLbl.Font = Enum.Font.Gotham
spawnStatusLbl.TextSize = 12
spawnStatusLbl.TextColor3 = Color3.fromRGB(150,150,170)
spawnStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
spawnStatusLbl.Text = "Ready"

local function setSpawnStatus(msg, active)
    spawnStatusLbl.Text = msg
    TweenService:Create(vsdot, TweenInfo.new(0.2), {
        BackgroundColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
    }):Play()
end

-- ── Popup helper (matches VanillaHub style) ───────────
local function showVehiclePopup(message)
    local gui = game.CoreGui:FindFirstChild("VanillaHub")
    if not gui then return end

    local popup = Instance.new("Frame", gui)
    popup.Size = UDim2.new(0,380,0,0)
    popup.Position = UDim2.new(0.5,-190,0.5,-60)
    popup.BackgroundColor3 = Color3.fromRGB(18,18,24)
    popup.BackgroundTransparency = 0
    popup.BorderSizePixel = 0
    popup.ClipsDescendants = true
    popup.ZIndex = 20
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0,14)
    local pStroke = Instance.new("UIStroke", popup)
    pStroke.Color = Color3.fromRGB(80,80,120)
    pStroke.Thickness = 1.2
    pStroke.Transparency = 0.4

    local icon = Instance.new("TextLabel", popup)
    icon.Size = UDim2.new(0,40,0,40)
    icon.Position = UDim2.new(0,16,0,16)
    icon.BackgroundTransparency = 1
    icon.Text = "🚗"
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 28
    icon.ZIndex = 21

    local msgLbl = Instance.new("TextLabel", popup)
    msgLbl.Size = UDim2.new(1,-76,0,72)
    msgLbl.Position = UDim2.new(0,64,0,12)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Font = Enum.Font.GothamSemibold
    msgLbl.TextSize = 14
    msgLbl.TextColor3 = Color3.fromRGB(220,220,235)
    msgLbl.TextWrapped = true
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextYAlignment = Enum.TextYAlignment.Top
    msgLbl.Text = message
    msgLbl.ZIndex = 21

    local okBtn = Instance.new("TextButton", popup)
    okBtn.Size = UDim2.new(1,-24,0,36)
    okBtn.Position = UDim2.new(0,12,0,92)
    okBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
    okBtn.Text = "Got it — click the Spawn Button now"
    okBtn.Font = Enum.Font.GothamSemibold
    okBtn.TextSize = 13
    okBtn.TextColor3 = Color3.fromRGB(200,210,255)
    okBtn.BorderSizePixel = 0
    okBtn.ZIndex = 21
    Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0,10)

    -- Expand in
    TweenService:Create(popup, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,380,0,142)
    }):Play()

    okBtn.MouseEnter:Connect(function()
        TweenService:Create(okBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(60,60,90)}):Play()
    end)
    okBtn.MouseLeave:Connect(function()
        TweenService:Create(okBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(40,40,60)}):Play()
    end)

    local function closePopup(andStartWaiting)
        local t = TweenService:Create(popup, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0,380,0,0)
        })
        t:Play()
        t.Completed:Connect(function() popup:Destroy() end)
        if andStartWaiting then
            -- Now arm the click listener for the spawn button
            waitingForSpawnClick = true
            setSpawnStatus("Waiting for spawn button click...", true)
        end
    end

    okBtn.MouseButton1Click:Connect(function() closePopup(true) end)
end

-- ── Detect vehicle color after spawn ─────────────────
-- LT2 vehicles are in workspace.PlayerModels; their PaintParts hold BrickColor.
local function getVehicleColor(model)
    -- Check PaintParts folder first
    local pp = model:FindFirstChild("PaintParts")
    if pp then
        local part = pp:FindFirstChildWhichIsA("BasePart")
        if part then return part.BrickColor end
    end
    -- Fallback: check Body Colors
    local bc = model:FindFirstChildOfClass("BodyColors")
    if bc then return BrickColor.new(bc.TorsoColor3 or bc.HeadColor3 or Color3.new()) end
    -- Fallback: first painted BasePart
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            return p.BrickColor
        end
    end
    return nil
end

local function colorMatches(model, targetBrick)
    local vc = getVehicleColor(model)
    if not vc then return false end
    return vc == BrickColor.new(targetBrick)
end

-- ── Find the vehicle/model the player spawned most recently ──
-- LT2 spawned vehicles appear in workspace.PlayerModels with an Owner value.
local function findPlayerVehicle()
    local models = workspace:FindFirstChild("PlayerModels")
    if not models then return nil end
    for _, model in ipairs(models:GetChildren()) do
        if model:IsA("Model") then
            local owner = model:FindFirstChild("Owner")
            if owner and tostring(owner.Value) == player.Name then
                if model:FindFirstChild("DriveSeat") or model:FindFirstChild("VehicleSeat") then
                    return model
                end
            end
        end
    end
    return nil
end

-- ── Spawn button click handler ────────────────────────
-- When waitingForSpawnClick is true and the player clicks something in-world,
-- we treat the clicked object's model as the spawn button's vehicle spawn point.
-- We then spam E to cycle colors until we hit the target.

local spawnButtonPart = nil  -- the Part the player clicked as the "spawn button"

-- We hook mouse clicks globally; when waiting we capture the next world click.
local mouse = player:GetMouse()

local function beginSpawnLoop()
    if isSpawning then return end
    isSpawning = true
    local targetEntry = COLOR_OPTIONS[selectedColorIndex]
    setSpawnStatus("Spawning — targeting: " .. targetEntry.label, true)

    spawnThread = task.spawn(function()
        local attempts = 0
        local maxAttempts = 200  -- safety cap

        while isSpawning and attempts < maxAttempts do
            attempts = attempts + 1

            -- Press E to cycle/spawn the vehicle
            -- In LT2, pressing E while looking at a spawn button triggers it.
            -- We simulate by firing the VehicleSpawn RemoteEvent if accessible,
            -- or by using keypress simulation.
            local RS = game:GetService("ReplicatedStorage")

            -- Try the known LT2 remote for vehicle respawn
            local respawnRemote = RS:FindFirstChild("Interaction")
                and RS.Interaction:FindFirstChild("RemoteProxy")
            if respawnRemote and spawnButtonPart then
                respawnRemote:FireServer(spawnButtonPart)
            end

            task.wait(0.35)

            -- Check spawned vehicle color
            local vmodel = findPlayerVehicle()
            if vmodel and colorMatches(vmodel, targetEntry.brick) then
                setSpawnStatus("✓ Got " .. targetEntry.label .. "!", false)
                isSpawning = false
                spawnThread = nil
                return
            end
        end

        -- Hit cap without matching
        setSpawnStatus("Stopped — color not found after " .. maxAttempts .. " tries", false)
        isSpawning = false
        spawnThread = nil
    end)
end

-- Global mouse click listener: captures the spawn button click
-- We always have this connected, but only act when waitingForSpawnClick = true.
mouse.Button1Down:Connect(function()
    if not waitingForSpawnClick then return end
    local target = mouse.Target
    if not target then return end
    -- Record the clicked part as the spawn button
    spawnButtonPart = target
    waitingForSpawnClick = false
    setSpawnStatus("Spawn button set. Starting...", true)
    task.delay(0.1, beginSpawnLoop)
end)

-- ── Buttons ───────────────────────────────────────────

-- Start Spawn
createVBtn("▶  Start Spawn", Color3.fromRGB(35,90,45), function()
    if isSpawning then
        setSpawnStatus("Already spawning!", true)
        return
    end
    -- Show the instruction popup first; clicking OK arms the click listener
    showVehiclePopup(
        "Click the Spawn Button in-world to begin.\n\n" ..
        "This is the spawn button for LT2 vehicles, trailers, and all other Lumber Tycoon 2 vehicles.\n\n" ..
        "VanillaHub will then spam E to cycle colors until it matches your selection."
    )
    setSpawnStatus("Popup shown — read instructions", false)
end)

-- Cancel Spawning
createVBtn("■  Cancel Spawning", Color3.fromRGB(90,30,30), function()
    isSpawning = false
    waitingForSpawnClick = false
    if spawnThread then
        pcall(task.cancel, spawnThread)
        spawnThread = nil
    end
    spawnButtonPart = nil
    setSpawnStatus("Cancelled", false)
end)

-- ════════════════════════════════════════════════════
-- UNIFIED INPUT HANDLER (GUI toggle + Fly key + rebinds)
-- ════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if getWaitingForKeyGUI() then
        setWaitingForKeyGUI(false)
        setCurrentToggleKey(input.KeyCode)
        keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
        TweenService:Create(keybindButtonGUI, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true), {
            BackgroundColor3 = Color3.fromRGB(60,180,60)
        }):Play()
        return
    end

    if getWaitingForFlyKey() then
        setWaitingForFlyKey(false)
        setCurrentFlyKey(input.KeyCode)
        flyKeyBtn.Text = input.KeyCode.Name
        flyKeyBtn.BackgroundColor3 = BTN_COLOR
        return
    end

    if input.KeyCode == getCurrentToggleKey() then
        toggleGUI()
        return
    end

    if input.KeyCode == getCurrentFlyKey() and getFlyToggleEnabled() then
        if getIsFlyEnabled() then
            stopFly()
        else
            startFly()
        end
    end
end)

_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded")
