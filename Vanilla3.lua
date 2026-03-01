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
-- AUTOBUY TAB (kept empty)
-- ════════════════════════════════════════════════════
local autoBuyPage = pages["AutoBuyTab"]

-- ════════════════════════════════════════════════════
-- VEHICLE TAB
-- ════════════════════════════════════════════════════
local vehiclePage = pages["VehicleTab"]

local flipVehicleBtn = Instance.new("TextButton", vehiclePage)
flipVehicleBtn.Size = UDim2.new(1,-12,0,32)
flipVehicleBtn.BackgroundColor3 = BTN_COLOR
flipVehicleBtn.Text = "Flip Vehicle"
flipVehicleBtn.Font = Enum.Font.GothamSemibold
flipVehicleBtn.TextSize = 13
flipVehicleBtn.TextColor3 = Color3.fromRGB(210,210,220)
flipVehicleBtn.BorderSizePixel = 0
Instance.new("UICorner", flipVehicleBtn).CornerRadius = UDim.new(0,6)
flipVehicleBtn.MouseEnter:Connect(function()
    TweenService:Create(flipVehicleBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play()
end)
flipVehicleBtn.MouseLeave:Connect(function()
    TweenService:Create(flipVehicleBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play()
end)

local isFlipping = false

flipVehicleBtn.MouseButton1Click:Connect(function()
    if isFlipping then return end

    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or not hum.SeatPart then return end

    local seat = hum.SeatPart
    local vehicle = seat.Parent

    -- Collect all BaseParts in the vehicle
    local parts = {}
    for _, p in ipairs(vehicle:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(parts, p) end
    end
    if #parts == 0 then return end

    -- Find root part to use as the rotation pivot
    local root = vehicle.PrimaryPart
    if not root then
        for _, p in ipairs(parts) do
            if p.Name == "Main" or p.Name == "Body" or p.Name == "Chassis" then
                root = p; break
            end
        end
        if not root then root = parts[1] end
    end
    if not root then return end

    isFlipping = true

    -- Unseat the player cleanly without fling
    hum.Sit = false
    task.wait(0.06)

    -- Anchor all parts to take over positioning from physics
    local wasAnchored = {}
    for _, p in ipairs(parts) do
        wasAnchored[p] = p.Anchored
        p.Anchored = true
    end

    -- Smoothstep easing (S-curve, feels natural)
    local function ss(t)
        t = math.clamp(t, 0, 1)
        return t * t * (3 - 2 * t)
    end

    -- ── Phase 1: Lift +8 studs over 0.3s ────────────────────
    local LIFT_H = 8
    local LIFT_STEPS = 18
    local LIFT_TIME = 0.3

    local startCFs = {}
    for _, p in ipairs(parts) do startCFs[p] = p.CFrame end

    for i = 1, LIFT_STEPS do
        local dy = LIFT_H * ss(i / LIFT_STEPS)
        for _, p in ipairs(parts) do
            if p and p.Parent then
                p.CFrame = startCFs[p] + Vector3.new(0, dy, 0)
            end
        end
        task.wait(LIFT_TIME / LIFT_STEPS)
    end

    -- ── Phase 2: Rotate 180° around Z axis over 0.5s ────────
    -- Pivots every part around the root's current lifted CFrame,
    -- preserving each part's relative offset so the vehicle stays intact.
    local ROTATE_STEPS = 30
    local ROTATE_TIME = 0.5

    local pivotCF = root.CFrame
    local offsets = {}
    for _, p in ipairs(parts) do
        if p and p.Parent then
            offsets[p] = pivotCF:ToObjectSpace(p.CFrame)
        end
    end

    for i = 1, ROTATE_STEPS do
        local angle = math.pi * ss(i / ROTATE_STEPS)
        -- Rotate purely on Z so the top goes backward and wheels end up pointing down
        local newPivot = CFrame.new(pivotCF.Position)
            * CFrame.fromMatrix(pivotCF.XVector, pivotCF.YVector, pivotCF.ZVector)
            * CFrame.Angles(0, 0, angle)
        for _, p in ipairs(parts) do
            if p and p.Parent and offsets[p] then
                p.CFrame = newPivot * offsets[p]
            end
        end
        task.wait(ROTATE_TIME / ROTATE_STEPS)
    end

    -- ── Phase 3: Lower back to ground (original Y + 1 stud) over 0.3s ──
    local DROP_STEPS = 18
    local DROP_TIME = 0.3

    local postRotCFs = {}
    for _, p in ipairs(parts) do
        if p and p.Parent then postRotCFs[p] = p.CFrame end
    end

    local targetY   = startCFs[root].Position.Y + 1
    local currentY  = root.CFrame.Position.Y
    local dropDelta = targetY - currentY   -- negative = dropping down

    for i = 1, DROP_STEPS do
        local dy = dropDelta * ss(i / DROP_STEPS)
        for _, p in ipairs(parts) do
            if p and p.Parent and postRotCFs[p] then
                p.CFrame = postRotCFs[p] + Vector3.new(0, dy, 0)
            end
        end
        task.wait(DROP_TIME / DROP_STEPS)
    end

    -- Restore physics to all parts
    for _, p in ipairs(parts) do
        if p and p.Parent then
            p.Anchored = wasAnchored[p] or false
        end
    end

    isFlipping = false
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
searchInput.PlaceholderText = "Search for functions or tabs..."; searchInput.Text = ""
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
        {"Flip Vehicle", "VehicleTab"},
    }

    local seen = {}
    for _, name in ipairs(tabs) do
        if lq == "" or string.find(string.lower(name), lq) then
            if not seen[name.."Tab"] then
                seen[name.."Tab"] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size = UDim2.new(1,-28,0,42); resBtn.BackgroundColor3 = Color3.fromRGB(22,22,28)
                resBtn.Text = "   " .. name .. " Tab"; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
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
                resBtn.Text = "   " .. fname; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
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
