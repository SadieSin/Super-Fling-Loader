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
-- AUTOBUY TAB (kept empty intentionally)
-- ════════════════════════════════════════════════════
local autoBuyPage = pages["AutoBuyTab"]

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════
local settingsPage = pages["SettingsTab"]

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size = UDim2.new(1,0,0,70)
kbFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
kbFrame.BorderSizePixel = 0
Instance.new("UICorner", kbFrame).CornerRadius = UDim.new(0,10)

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
keybindButtonGUI.MouseEnter:Connect(function()
    TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
end)
keybindButtonGUI.MouseLeave:Connect(function()
    TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
end)

-- ════════════════════════════════════════════════════
-- SEARCH TAB
-- ════════════════════════════════════════════════════
local searchPage = pages["SearchTab"]
local searchInput = Instance.new("TextBox", searchPage)
searchInput.Size = UDim2.new(1,-28,0,42)
searchInput.BackgroundColor3 = Color3.fromRGB(22,22,28)
searchInput.PlaceholderText = "Search for functions or tabs..."
searchInput.Text = ""
searchInput.Font = Enum.Font.GothamSemibold; searchInput.TextSize = 15
searchInput.TextColor3 = Color3.fromRGB(220,220,220)
searchInput.TextXAlignment = Enum.TextXAlignment.Left
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
                resBtn.Text = name .. " Tab"; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
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
                resBtn.Text = fname; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
                resBtn.TextColor3 = Color3.fromRGB(180,210,255); resBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UIPadding", resBtn).PaddingLeft = UDim.new(0,16)
                Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0,10)
                local subLbl = Instance.new("TextLabel", resBtn)
                subLbl.Size = UDim2.new(1,-20,0,16); subLbl.Position = UDim2.new(0,0,1,-18)
                subLbl.BackgroundTransparency = 1; subLbl.Font = Enum.Font.Gotham; subLbl.TextSize = 11
                subLbl.TextColor3 = Color3.fromRGB(120,120,150); subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.Text = "in " .. ftab:gsub("Tab","") .. " tab"
                Instance.new("UIPadding", subLbl).PaddingLeft = UDim.new(0,16)
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

-- ── Helpers ───────────────────────────────────────────
local function createVLabel(text)
    local lbl = Instance.new("TextLabel", vehiclePage)
    lbl.Size = UDim2.new(1,-12,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function createVSep()
    local s = Instance.new("Frame", vehiclePage)
    s.Size = UDim2.new(1,-12,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,40,55)
    s.BorderSizePixel = 0
end

-- All vehicle buttons use the same grey theme — BTN_COLOR
local function createVBtn(text, callback)
    local btn = Instance.new("TextButton", vehiclePage)
    btn.Size = UDim2.new(1,-12,0,34)
    btn.BackgroundColor3 = BTN_COLOR
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(210,210,220)
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.13), {BackgroundColor3 = BTN_HOVER}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.13), {BackgroundColor3 = BTN_COLOR}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ── State ─────────────────────────────────────────────
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

local selectedColorIndex   = 1
local isSpawning           = false
local spawnThread          = nil
local waitingForSpawnClick = false
local spawnButtonPart      = nil

table.insert(cleanupTasks, function()
    isSpawning = false
    waitingForSpawnClick = false
    if spawnThread then pcall(task.cancel, spawnThread); spawnThread = nil end
end)

-- ── Status pill ───────────────────────────────────────
-- Declared early so flip and other helpers can call setVehicleStatus
local vStatusFrame = Instance.new("Frame", vehiclePage)
vStatusFrame.Size = UDim2.new(1,-12,0,26)
vStatusFrame.BackgroundColor3 = Color3.fromRGB(14,14,18)
vStatusFrame.BorderSizePixel = 0
Instance.new("UICorner", vStatusFrame).CornerRadius = UDim.new(0,6)

local vDot = Instance.new("Frame", vStatusFrame)
vDot.Size = UDim2.new(0,6,0,6)
vDot.Position = UDim2.new(0,10,0.5,-3)
vDot.BackgroundColor3 = Color3.fromRGB(80,80,100)
vDot.BorderSizePixel = 0
Instance.new("UICorner", vDot).CornerRadius = UDim.new(1,0)

local vStatusLbl = Instance.new("TextLabel", vStatusFrame)
vStatusLbl.Size = UDim2.new(1,-26,1,0)
vStatusLbl.Position = UDim2.new(0,22,0,0)
vStatusLbl.BackgroundTransparency = 1
vStatusLbl.Font = Enum.Font.Gotham
vStatusLbl.TextSize = 12
vStatusLbl.TextColor3 = Color3.fromRGB(150,150,170)
vStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
vStatusLbl.Text = "Ready"

local function setVehicleStatus(msg, active)
    vStatusLbl.Text = msg
    TweenService:Create(vDot, TweenInfo.new(0.2), {
        BackgroundColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
    }):Play()
end

-- ════ VEHICLE TOOLS ══════════════════════════════════

createVLabel("Vehicle Tools")

-- Flip Vehicle:
-- Fires RemoteProxy with the vehicle's flip/reset ButtonRemote part.
-- Never touches the humanoid state or CFrame on the client.
createVBtn("Flip Vehicle", function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not (hum and hum.SeatPart) then
        setVehicleStatus("Not seated in a vehicle", false)
        return
    end

    local model = hum.SeatPart:FindFirstAncestorOfClass("Model")
    if not model then return end

    local RS = game:GetService("ReplicatedStorage")
    local remoteProxy = RS:FindFirstChild("Interaction")
        and RS.Interaction:FindFirstChild("RemoteProxy")
    if not remoteProxy then
        setVehicleStatus("RemoteProxy not found", false)
        return
    end

    -- Search for a ButtonRemote_ flip/reset part inside the vehicle
    local flipPart = nil
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            local n = desc.Name:lower()
            if n:find("flip") or n:find("reset") then
                flipPart = desc
                break
            end
        end
    end

    if flipPart then
        remoteProxy:FireServer(flipPart)
        setVehicleStatus("Flip fired", false)
    else
        setVehicleStatus("No flip button found on this vehicle", false)
    end
end)

createVSep()

-- ════ COLOR SPAWNER ══════════════════════════════════

createVLabel("Color Spawner")

-- Compact inline dropdown — single row, 28px tall, expands downward
local DROP_ITEM_H   = 26
local DROP_MAX_SHOW = 6
local DROP_H        = 28   -- closed height
local isDropOpen    = false

local dropOuter = Instance.new("Frame", vehiclePage)
dropOuter.Size = UDim2.new(1,-12,0,DROP_H)
dropOuter.BackgroundColor3 = Color3.fromRGB(24,24,30)
dropOuter.BorderSizePixel = 0
dropOuter.ClipsDescendants = true
Instance.new("UICorner", dropOuter).CornerRadius = UDim.new(0,7)
local dropStroke = Instance.new("UIStroke", dropOuter)
dropStroke.Color = Color3.fromRGB(55,55,80)
dropStroke.Thickness = 1
dropStroke.Transparency = 0.5

-- The single visible header row
local dropHeaderBtn = Instance.new("TextButton", dropOuter)
dropHeaderBtn.Size = UDim2.new(1,0,0,DROP_H)
dropHeaderBtn.BackgroundTransparency = 1
dropHeaderBtn.Text = ""
dropHeaderBtn.ZIndex = 4

-- Color swatch dot
local headerDot = Instance.new("Frame", dropOuter)
headerDot.Size = UDim2.new(0,10,0,10)
headerDot.Position = UDim2.new(0,10,0.5,-5)   -- vertically centred in closed height
headerDot.BorderSizePixel = 0
local _ok0, _bc0 = pcall(function() return BrickColor.new(COLOR_OPTIONS[1].brick) end)
headerDot.BackgroundColor3 = _ok0 and _bc0.Color or Color3.fromRGB(180,180,180)
Instance.new("UICorner", headerDot).CornerRadius = UDim.new(0,2)

local headerLbl = Instance.new("TextLabel", dropOuter)
headerLbl.Size = UDim2.new(1,-50,0,DROP_H)
headerLbl.Position = UDim2.new(0,28,0,0)
headerLbl.BackgroundTransparency = 1
headerLbl.Text = COLOR_OPTIONS[1].label
headerLbl.Font = Enum.Font.GothamSemibold
headerLbl.TextSize = 12
headerLbl.TextColor3 = Color3.fromRGB(210,210,225)
headerLbl.TextXAlignment = Enum.TextXAlignment.Left

local dropArrow = Instance.new("TextLabel", dropOuter)
dropArrow.Size = UDim2.new(0,18,0,DROP_H)
dropArrow.Position = UDim2.new(1,-22,0,0)
dropArrow.BackgroundTransparency = 1
dropArrow.Text = "v"
dropArrow.Font = Enum.Font.GothamBold
dropArrow.TextSize = 11
dropArrow.TextColor3 = Color3.fromRGB(100,100,130)
dropArrow.TextXAlignment = Enum.TextXAlignment.Center

-- Divider between header and list
local dropDiv = Instance.new("Frame", dropOuter)
dropDiv.Size = UDim2.new(1,-10,0,1)
dropDiv.Position = UDim2.new(0,5,0,DROP_H)
dropDiv.BackgroundColor3 = Color3.fromRGB(45,45,65)
dropDiv.BorderSizePixel = 0
dropDiv.Visible = false

-- Scrolling list
local dropScroll = Instance.new("ScrollingFrame", dropOuter)
dropScroll.Position = UDim2.new(0,0,0,DROP_H+1)
dropScroll.Size = UDim2.new(1,0,0,0)
dropScroll.BackgroundTransparency = 1
dropScroll.BorderSizePixel = 0
dropScroll.ScrollBarThickness = 3
dropScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,120)
dropScroll.CanvasSize = UDim2.new(0,0,0,0)
dropScroll.ClipsDescendants = true

local dropLayout = Instance.new("UIListLayout", dropScroll)
dropLayout.Padding = UDim.new(0,2)
dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    dropScroll.CanvasSize = UDim2.new(0,0,0, dropLayout.AbsoluteContentSize.Y + 4)
end)
local dropPad = Instance.new("UIPadding", dropScroll)
dropPad.PaddingTop = UDim.new(0,3); dropPad.PaddingBottom = UDim.new(0,3)
dropPad.PaddingLeft = UDim.new(0,4); dropPad.PaddingRight = UDim.new(0,4)

local function refreshHeader(idx)
    local entry = COLOR_OPTIONS[idx]
    local ok2, bc2 = pcall(function() return BrickColor.new(entry.brick) end)
    headerDot.BackgroundColor3 = ok2 and bc2.Color or Color3.fromRGB(180,180,180)
    headerLbl.Text = entry.label
end

local function buildDropList()
    for _, c in ipairs(dropScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for i, entry in ipairs(COLOR_OPTIONS) do
        local isSel = (i == selectedColorIndex)
        local row = Instance.new("Frame", dropScroll)
        row.Size = UDim2.new(1,0,0,DROP_ITEM_H)
        row.BackgroundColor3 = isSel and Color3.fromRGB(40,40,60) or Color3.fromRGB(28,28,38)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,5)

        local dot = Instance.new("Frame", row)
        dot.Size = UDim2.new(0,9,0,9)
        dot.Position = UDim2.new(0,7,0.5,-4)
        dot.BorderSizePixel = 0
        local ok3, bc3 = pcall(function() return BrickColor.new(entry.brick) end)
        dot.BackgroundColor3 = ok3 and bc3.Color or Color3.fromRGB(180,180,180)
        Instance.new("UICorner", dot).CornerRadius = UDim.new(0,2)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1,-36,1,0)
        nameLbl.Position = UDim2.new(0,22,0,0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = entry.label
        nameLbl.Font = Enum.Font.GothamSemibold
        nameLbl.TextSize = 11
        nameLbl.TextColor3 = isSel and Color3.fromRGB(210,215,255) or Color3.fromRGB(180,180,200)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        if isSel then
            local check = Instance.new("TextLabel", row)
            check.Size = UDim2.new(0,18,1,0)
            check.Position = UDim2.new(1,-20,0,0)
            check.BackgroundTransparency = 1
            check.Text = "+"
            check.Font = Enum.Font.GothamBold
            check.TextSize = 12
            check.TextColor3 = Color3.fromRGB(140,160,220)
            check.TextXAlignment = Enum.TextXAlignment.Center
        end

        local rowBtn = Instance.new("TextButton", row)
        rowBtn.Size = UDim2.new(1,0,1,0)
        rowBtn.BackgroundTransparency = 1
        rowBtn.Text = ""
        rowBtn.ZIndex = 5

        rowBtn.MouseEnter:Connect(function()
            if i ~= selectedColorIndex then
                TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(36,36,52)}):Play()
            end
        end)
        rowBtn.MouseLeave:Connect(function()
            if i ~= selectedColorIndex then
                TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28,28,38)}):Play()
            end
        end)
        rowBtn.MouseButton1Click:Connect(function()
            selectedColorIndex = i
            refreshHeader(i)
            buildDropList()
            task.delay(0.04, function()
                isDropOpen = false
                TweenService:Create(dropArrow, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
                TweenService:Create(dropOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,DROP_H)}):Play()
                TweenService:Create(dropScroll, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
                dropDiv.Visible = false
            end)
        end)
    end
end

local function openDrop()
    isDropOpen = true
    buildDropList()
    local listH = math.min(#COLOR_OPTIONS, DROP_MAX_SHOW) * (DROP_ITEM_H + 2) + 6
    dropDiv.Visible = true
    TweenService:Create(dropArrow, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
    TweenService:Create(dropOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,DROP_H+1+listH)}):Play()
    TweenService:Create(dropScroll, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,listH)}):Play()
end

local function closeDrop()
    isDropOpen = false
    TweenService:Create(dropArrow, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
    TweenService:Create(dropOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,DROP_H)}):Play()
    TweenService:Create(dropScroll, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
    dropDiv.Visible = false
end

dropHeaderBtn.MouseButton1Click:Connect(function()
    if isDropOpen then closeDrop() else openDrop() end
end)
dropHeaderBtn.MouseEnter:Connect(function()
    TweenService:Create(dropOuter, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30,30,38)}):Play()
end)
dropHeaderBtn.MouseLeave:Connect(function()
    TweenService:Create(dropOuter, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(24,24,30)}):Play()
end)

createVSep()

-- ════ SPAWN ══════════════════════════════════════════

createVLabel("Spawn")

-- Find the player's currently spawned vehicle in workspace.PlayerModels
local function findPlayerVehicle()
    local models = workspace:FindFirstChild("PlayerModels")
    if not models then return nil end
    for _, model in ipairs(models:GetChildren()) do
        if model:IsA("Model") then
            local owner = model:FindFirstChild("Owner")
            if owner and tostring(owner.Value) == player.Name then
                if model:FindFirstChild("DriveSeat") or model:FindFirstChildWhichIsA("VehicleSeat") then
                    return model
                end
            end
        end
    end
    return nil
end

-- Check if the spawned vehicle matches the target BrickColor.
-- LT2 vehicles store color in PaintParts children.
local function vehicleColorMatches(model, targetBrick)
    local target = BrickColor.new(targetBrick)
    local pp = model:FindFirstChild("PaintParts")
    if pp then
        for _, p in ipairs(pp:GetDescendants()) do
            if p:IsA("BasePart") then
                return p.BrickColor == target
            end
        end
    end
    -- Fallback: any BasePart in the model
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            return p.BrickColor == target
        end
    end
    return false
end

-- Spawn loop:
-- Calls RemoteProxy:FireServer(spawnButtonPart) repeatedly — server-side only,
-- no client CFrame changes — until the vehicle color matches the selection.
local function beginSpawnLoop()
    if isSpawning then return end
    if not spawnButtonPart then
        setVehicleStatus("No spawn button selected", false)
        return
    end

    local RS = game:GetService("ReplicatedStorage")
    local remoteProxy = RS:FindFirstChild("Interaction")
        and RS.Interaction:FindFirstChild("RemoteProxy")
    if not remoteProxy then
        setVehicleStatus("RemoteProxy not found", false)
        return
    end

    isSpawning = true
    local targetEntry = COLOR_OPTIONS[selectedColorIndex]
    setVehicleStatus("Spawning for: " .. targetEntry.label, true)

    spawnThread = task.spawn(function()
        local attempts = 0
        local maxAttempts = 300

        while isSpawning and attempts < maxAttempts do
            attempts = attempts + 1

            -- Fire exactly as SimpleSpy recorded:
            -- game:GetService("ReplicatedStorage").Interaction.RemoteProxy
            --     :FireServer(workspace.PlayerModels.Pickup1.ButtonRemote_SpawnButton)
            pcall(function()
                remoteProxy:FireServer(spawnButtonPart)
            end)

            task.wait(1)

            local vmodel = findPlayerVehicle()
            if vmodel and vehicleColorMatches(vmodel, targetEntry.brick) then
                setVehicleStatus("Done - got " .. targetEntry.label .. " (" .. attempts .. " tries)", false)
                isSpawning = false
                spawnThread = nil
                return
            end

            setVehicleStatus("Attempt " .. attempts .. " / " .. maxAttempts, true)
        end

        setVehicleStatus("Stopped after " .. maxAttempts .. " attempts", false)
        isSpawning = false
        spawnThread = nil
    end)
end

-- Mouse click capture: when waiting, next world-click is treated as the spawn button.
-- Walks up from the clicked part to find ButtonRemote_SpawnButton in the vehicle model.
local vMouse = player:GetMouse()
vMouse.Button1Down:Connect(function()
    if not waitingForSpawnClick then return end

    local target = vMouse.Target
    if not target then return end

    -- If the player clicked exactly the button part, use it directly
    if target.Name == "ButtonRemote_SpawnButton" then
        spawnButtonPart = target
        waitingForSpawnClick = false
        setVehicleStatus("Spawn button set. Starting...", true)
        task.delay(0.1, beginSpawnLoop)
        return
    end

    -- Walk up to find the model containing ButtonRemote_SpawnButton
    local model = target:FindFirstAncestorOfClass("Model") or target.Parent
    local found = nil
    if model then
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name == "ButtonRemote_SpawnButton" then
                found = desc
                break
            end
        end
    end

    if not found then
        setVehicleStatus("Could not find ButtonRemote_SpawnButton - click the button directly", false)
        waitingForSpawnClick = false
        return
    end

    spawnButtonPart = found
    waitingForSpawnClick = false
    setVehicleStatus("Spawn button set. Starting...", true)
    task.delay(0.1, beginSpawnLoop)
end)

-- Popup: shown before waiting for spawn button click
local function showSpawnInstructions()
    local gui = game.CoreGui:FindFirstChild("VanillaHub")
    if not gui then return end

    local popup = Instance.new("Frame", gui)
    popup.Size = UDim2.new(0,360,0,0)
    popup.Position = UDim2.new(0.5,-180,0.5,-55)
    popup.BackgroundColor3 = Color3.fromRGB(18,18,24)
    popup.BackgroundTransparency = 0
    popup.BorderSizePixel = 0
    popup.ClipsDescendants = true
    popup.ZIndex = 20
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0,12)
    local pStroke = Instance.new("UIStroke", popup)
    pStroke.Color = Color3.fromRGB(70,70,100)
    pStroke.Thickness = 1
    pStroke.Transparency = 0.45

    local msgLbl = Instance.new("TextLabel", popup)
    msgLbl.Size = UDim2.new(1,-24,0,56)
    msgLbl.Position = UDim2.new(0,12,0,10)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Font = Enum.Font.GothamSemibold
    msgLbl.TextSize = 13
    msgLbl.TextColor3 = Color3.fromRGB(210,210,225)
    msgLbl.TextWrapped = true
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextYAlignment = Enum.TextYAlignment.Top
    msgLbl.Text = "Click the spawn button on the vehicle spawn pad. VanillaHub will then cycle spawns until the selected color is matched."
    msgLbl.ZIndex = 21

    local okBtn = Instance.new("TextButton", popup)
    okBtn.Size = UDim2.new(1,-24,0,30)
    okBtn.Position = UDim2.new(0,12,0,74)
    okBtn.BackgroundColor3 = BTN_COLOR
    okBtn.Text = "OK - I will click the spawn button"
    okBtn.Font = Enum.Font.GothamSemibold
    okBtn.TextSize = 12
    okBtn.TextColor3 = Color3.fromRGB(200,200,215)
    okBtn.BorderSizePixel = 0
    okBtn.ZIndex = 21
    Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0,8)

    TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,360,0,116)
    }):Play()

    okBtn.MouseEnter:Connect(function()
        TweenService:Create(okBtn, TweenInfo.new(0.12), {BackgroundColor3 = BTN_HOVER}):Play()
    end)
    okBtn.MouseLeave:Connect(function()
        TweenService:Create(okBtn, TweenInfo.new(0.12), {BackgroundColor3 = BTN_COLOR}):Play()
    end)
    okBtn.MouseButton1Click:Connect(function()
        local t = TweenService:Create(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0,360,0,0)
        })
        t:Play()
        t.Completed:Connect(function() popup:Destroy() end)
        waitingForSpawnClick = true
        setVehicleStatus("Click the spawn button in-world...", true)
    end)
end

-- Buttons
createVBtn("Start Spawn", function()
    if isSpawning then
        setVehicleStatus("Already spawning", true)
        return
    end
    showSpawnInstructions()
end)

createVBtn("Cancel Spawning", function()
    isSpawning = false
    waitingForSpawnClick = false
    if spawnThread then pcall(task.cancel, spawnThread); spawnThread = nil end
    spawnButtonPart = nil
    setVehicleStatus("Cancelled", false)
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
