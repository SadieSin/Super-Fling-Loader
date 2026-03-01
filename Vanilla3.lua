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

local function createVSection(text)
    local lbl = Instance.new("TextLabel", vehiclePage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function createVSep()
    local s = Instance.new("Frame", vehiclePage)
    s.Size = UDim2.new(1,-12,0,1); s.BackgroundColor3 = Color3.fromRGB(40,40,55); s.BorderSizePixel = 0
end

local function createVBtn(text, color, callback)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", vehiclePage)
    btn.Size = UDim2.new(1,-12,0,32); btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(210,210,220); btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local r,g,b = color.R*255, color.G*255, color.B*255
    local hov = Color3.fromRGB(math.min(r+20,255)/255*255, math.min(g+8,255)/255*255, math.min(b+20,255)/255*255)
    -- Fix: just brighten manually
    local hovCol = Color3.fromRGB(math.clamp(r+20,0,255), math.clamp(g+8,0,255), math.clamp(b+20,0,255))
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = hovCol}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = color}):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ── VEHICLE CONTROLS ─────────────────────────────────────
createVSection("Vehicle Controls")

-- Flip Vehicle (server-side via FireServer on the seat's flip remote if available,
-- otherwise use a safe CFrame rotation of the vehicle model the player is seated in)
createVBtn("Flip Vehicle", BTN_COLOR, function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or not hum.SeatPart then return end

    local seat = hum.SeatPart
    local vehicle = seat.Parent

    -- Unseat the player first so they don't get flung
    hum.Jump = true
    task.wait(0.1)

    -- Find the primary part or any BasePart to flip
    local root = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    -- Flip: rotate 180 degrees on Z axis while keeping X/Z position, raise Y slightly
    local cf = root.CFrame
    local pos = cf.Position
    root.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi) * CFrame.new(0, 2, 0)
end)

createVSep()

-- ── COLOR SELECTION ───────────────────────────────────────
createVSection("Select Color")

local colorOptions = {
    "Medium Stone Grey",
    "Dark Grey Metallic",
    "Dark Grey",
    "Silver",
    "Sand Green",
    "Faded Green",
    "Sand Red",
    "Dark Red",
    "Earth Yellow",
    "Earth Orange",
    "Brick Yellow",
    "Hot Pink",
}

-- Map display names to BrickColor names used by Roblox
local colorToBrickColor = {
    ["Medium Stone Grey"]   = "Medium stone grey",
    ["Dark Grey Metallic"]  = "Dark grey metallic",
    ["Dark Grey"]           = "Dark grey",
    ["Silver"]              = "Mid gray",
    ["Sand Green"]          = "Sand green",
    ["Faded Green"]         = "Faded green",
    ["Sand Red"]            = "Sand red",
    ["Dark Red"]            = "Dark red",
    ["Earth Yellow"]        = "Earth yellow",
    ["Earth Orange"]        = "Earth orange",
    ["Brick Yellow"]        = "Brick yellow",
    ["Hot Pink"]            = "Hot pink",
}

local selectedColor = colorOptions[1]
local colorDropdownOpen = false
local COLOR_ITEM_H = 30
local COLOR_HEADER_H = 34

-- Outer dropdown container
local colorOuter = Instance.new("Frame", vehiclePage)
colorOuter.Size = UDim2.new(1,-12,0,COLOR_HEADER_H)
colorOuter.BackgroundColor3 = Color3.fromRGB(22,22,30)
colorOuter.BorderSizePixel = 0
colorOuter.ClipsDescendants = true
Instance.new("UICorner", colorOuter).CornerRadius = UDim.new(0,8)
local colorStroke = Instance.new("UIStroke", colorOuter)
colorStroke.Color = Color3.fromRGB(60,60,90); colorStroke.Thickness = 1; colorStroke.Transparency = 0.5

-- Header
local colorHeader = Instance.new("Frame", colorOuter)
colorHeader.Size = UDim2.new(1,0,0,COLOR_HEADER_H)
colorHeader.BackgroundTransparency = 1

local colorLbl = Instance.new("TextLabel", colorHeader)
colorLbl.Size = UDim2.new(0,70,1,0); colorLbl.Position = UDim2.new(0,10,0,0)
colorLbl.BackgroundTransparency = 1; colorLbl.Text = "Color:"
colorLbl.Font = Enum.Font.GothamBold; colorLbl.TextSize = 12
colorLbl.TextColor3 = Color3.fromRGB(140,140,170); colorLbl.TextXAlignment = Enum.TextXAlignment.Left

local colorSelFrame = Instance.new("Frame", colorHeader)
colorSelFrame.Size = UDim2.new(1,-82,0,24); colorSelFrame.Position = UDim2.new(0,76,0.5,-12)
colorSelFrame.BackgroundColor3 = Color3.fromRGB(30,30,42); colorSelFrame.BorderSizePixel = 0
Instance.new("UICorner", colorSelFrame).CornerRadius = UDim.new(0,6)

local colorSelLbl = Instance.new("TextLabel", colorSelFrame)
colorSelLbl.Size = UDim2.new(1,-26,1,0); colorSelLbl.Position = UDim2.new(0,8,0,0)
colorSelLbl.BackgroundTransparency = 1; colorSelLbl.Text = selectedColor
colorSelLbl.Font = Enum.Font.GothamSemibold; colorSelLbl.TextSize = 12
colorSelLbl.TextColor3 = Color3.fromRGB(220,225,255); colorSelLbl.TextXAlignment = Enum.TextXAlignment.Left
colorSelLbl.TextTruncate = Enum.TextTruncate.AtEnd

local colorArrow = Instance.new("TextLabel", colorSelFrame)
colorArrow.Size = UDim2.new(0,20,1,0); colorArrow.Position = UDim2.new(1,-22,0,0)
colorArrow.BackgroundTransparency = 1; colorArrow.Text = "▾"
colorArrow.Font = Enum.Font.GothamBold; colorArrow.TextSize = 13
colorArrow.TextColor3 = Color3.fromRGB(140,140,180); colorArrow.TextXAlignment = Enum.TextXAlignment.Center

local colorHeaderBtn = Instance.new("TextButton", colorSelFrame)
colorHeaderBtn.Size = UDim2.new(1,0,1,0); colorHeaderBtn.BackgroundTransparency = 1; colorHeaderBtn.Text = ""; colorHeaderBtn.ZIndex = 5

-- Scroll list inside dropdown
local colorScroll = Instance.new("ScrollingFrame", colorOuter)
colorScroll.Position = UDim2.new(0,0,0,COLOR_HEADER_H+1)
colorScroll.Size = UDim2.new(1,0,0,0)
colorScroll.BackgroundTransparency = 1; colorScroll.BorderSizePixel = 0
colorScroll.ScrollBarThickness = 3; colorScroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
colorScroll.CanvasSize = UDim2.new(0,0,0,0); colorScroll.ClipsDescendants = true

local colorListLayout = Instance.new("UIListLayout", colorScroll)
colorListLayout.SortOrder = Enum.SortOrder.LayoutOrder; colorListLayout.Padding = UDim.new(0,2)
colorListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    colorScroll.CanvasSize = UDim2.new(0,0,0, colorListLayout.AbsoluteContentSize.Y + 6)
end)
local colorListPad = Instance.new("UIPadding", colorScroll)
colorListPad.PaddingTop = UDim.new(0,3); colorListPad.PaddingBottom = UDim.new(0,3)
colorListPad.PaddingLeft = UDim.new(0,5); colorListPad.PaddingRight = UDim.new(0,5)

local MAX_COLOR_ROWS = 5
local function buildColorList()
    for _, c in ipairs(colorScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for i, name in ipairs(colorOptions) do
        local isSelected = (name == selectedColor)
        local row = Instance.new("Frame", colorScroll)
        row.Size = UDim2.new(1,0,0,COLOR_ITEM_H); row.LayoutOrder = i
        row.BackgroundColor3 = isSelected and Color3.fromRGB(45,45,75) or Color3.fromRGB(28,28,40)
        row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,5)
        local rowLbl = Instance.new("TextLabel", row)
        rowLbl.Size = UDim2.new(1,-32,1,0); rowLbl.Position = UDim2.new(0,10,0,0)
        rowLbl.BackgroundTransparency = 1; rowLbl.Text = name
        rowLbl.Font = Enum.Font.GothamSemibold; rowLbl.TextSize = 12
        rowLbl.TextColor3 = isSelected and Color3.fromRGB(210,215,255) or Color3.fromRGB(200,200,215)
        rowLbl.TextXAlignment = Enum.TextXAlignment.Left
        if isSelected then
            local check = Instance.new("TextLabel", row)
            check.Size = UDim2.new(0,22,1,0); check.Position = UDim2.new(1,-24,0,0)
            check.BackgroundTransparency = 1; check.Text = "✓"
            check.Font = Enum.Font.GothamBold; check.TextSize = 13
            check.TextColor3 = Color3.fromRGB(120,180,255); check.TextXAlignment = Enum.TextXAlignment.Center
        end
        local rowBtn = Instance.new("TextButton", row)
        rowBtn.Size = UDim2.new(1,0,1,0); rowBtn.BackgroundTransparency = 1; rowBtn.Text = ""; rowBtn.ZIndex = 5
        rowBtn.MouseEnter:Connect(function()
            if name ~= selectedColor then TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(38,38,58)}):Play() end
        end)
        rowBtn.MouseLeave:Connect(function()
            if name ~= selectedColor then TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28,28,40)}):Play() end
        end)
        rowBtn.MouseButton1Click:Connect(function()
            selectedColor = name
            colorSelLbl.Text = name
            buildColorList()
            task.delay(0.05, function()
                colorDropdownOpen = false
                TweenService:Create(colorArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
                local targetH = COLOR_HEADER_H
                TweenService:Create(colorOuter, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,targetH)}):Play()
                TweenService:Create(colorScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
            end)
        end)
    end
end

local function openColorList()
    colorDropdownOpen = true
    buildColorList()
    local listH = math.min(#colorOptions, MAX_COLOR_ROWS) * (COLOR_ITEM_H + 2) + 8
    local totalH = COLOR_HEADER_H + 1 + listH
    TweenService:Create(colorArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
    TweenService:Create(colorOuter, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,totalH)}):Play()
    TweenService:Create(colorScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,listH)}):Play()
end

local function closeColorListClean()
    colorDropdownOpen = false
    TweenService:Create(colorArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
    TweenService:Create(colorOuter, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,COLOR_HEADER_H)}):Play()
    TweenService:Create(colorScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
end

colorHeaderBtn.MouseButton1Click:Connect(function()
    if colorDropdownOpen then closeColorListClean() else openColorList() end
end)
colorHeaderBtn.MouseEnter:Connect(function() TweenService:Create(colorSelFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(38,38,55)}):Play() end)
colorHeaderBtn.MouseLeave:Connect(function() TweenService:Create(colorSelFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30,30,42)}):Play() end)

createVSep()

-- ── VEHICLE SPAWN ─────────────────────────────────────────
createVSection("Vehicle Spawn")

-- State
local isSpawning = false
local spawnThread = nil
local spawnClickMode = false  -- waiting for player to click spawn button

-- Popup notification helper (bottom-center, no emoji)
local function showVehiclePopup(msg, duration)
    duration = duration or 5
    local gui = player:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")
    -- Use CoreGui like Vanilla1 does
    local coreGui = game:GetService("CoreGui")
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "VHVehiclePopup"
    popupGui.ResetOnSpawn = false
    popupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    popupGui.Parent = coreGui

    local frame = Instance.new("Frame", popupGui)
    frame.Size = UDim2.new(0, 420, 0, 72)
    frame.Position = UDim2.new(0.5, -210, 1, -100)
    frame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(80,80,120); stroke.Thickness = 1.2; stroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-20,1,-10)
    lbl.Position = UDim2.new(0,10,0,5)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(230,230,255)
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.TextTransparency = 1
    lbl.Text = msg

    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.25}):Play()
    TweenService:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()

    task.delay(duration, function()
        if not (popupGui and popupGui.Parent) then return end
        TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
        local t = TweenService:Create(lbl, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 1})
        t:Play()
        t.Completed:Connect(function() if popupGui and popupGui.Parent then popupGui:Destroy() end end)
    end)
end

-- Status label for spawn section
local spawnStatusFrame = Instance.new("Frame", vehiclePage)
spawnStatusFrame.Size = UDim2.new(1,-12,0,28); spawnStatusFrame.BackgroundColor3 = Color3.fromRGB(14,14,18)
spawnStatusFrame.BorderSizePixel = 0
Instance.new("UICorner", spawnStatusFrame).CornerRadius = UDim.new(0,6)
local spawnDot = Instance.new("Frame", spawnStatusFrame)
spawnDot.Size = UDim2.new(0,7,0,7); spawnDot.Position = UDim2.new(0,10,0.5,-3)
spawnDot.BackgroundColor3 = Color3.fromRGB(80,80,100); spawnDot.BorderSizePixel = 0
Instance.new("UICorner", spawnDot).CornerRadius = UDim.new(1,0)
local spawnStatusLbl = Instance.new("TextLabel", spawnStatusFrame)
spawnStatusLbl.Size = UDim2.new(1,-28,1,0); spawnStatusLbl.Position = UDim2.new(0,24,0,0)
spawnStatusLbl.BackgroundTransparency = 1; spawnStatusLbl.Font = Enum.Font.Gotham; spawnStatusLbl.TextSize = 12
spawnStatusLbl.TextColor3 = Color3.fromRGB(150,150,170); spawnStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
spawnStatusLbl.Text = "Ready"

local function setSpawnStatus(msg, active)
    spawnStatusLbl.Text = msg
    spawnDot.BackgroundColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
end

-- Start Spawn button
local startSpawnBtn = Instance.new("TextButton", vehiclePage)
startSpawnBtn.Size = UDim2.new(1,-12,0,32)
startSpawnBtn.BackgroundColor3 = Color3.fromRGB(35,90,45)
startSpawnBtn.Text = "Start Spawn"; startSpawnBtn.Font = Enum.Font.GothamSemibold; startSpawnBtn.TextSize = 13
startSpawnBtn.TextColor3 = Color3.fromRGB(210,210,220); startSpawnBtn.BorderSizePixel = 0
Instance.new("UICorner", startSpawnBtn).CornerRadius = UDim.new(0,6)
startSpawnBtn.MouseEnter:Connect(function() TweenService:Create(startSpawnBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(50,120,60)}):Play() end)
startSpawnBtn.MouseLeave:Connect(function() TweenService:Create(startSpawnBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(35,90,45)}):Play() end)

-- Cancel Spawning button
local cancelSpawnBtn = Instance.new("TextButton", vehiclePage)
cancelSpawnBtn.Size = UDim2.new(1,-12,0,32)
cancelSpawnBtn.BackgroundColor3 = BTN_COLOR
cancelSpawnBtn.Text = "Cancel Spawning"; cancelSpawnBtn.Font = Enum.Font.GothamSemibold; cancelSpawnBtn.TextSize = 13
cancelSpawnBtn.TextColor3 = Color3.fromRGB(210,210,220); cancelSpawnBtn.BorderSizePixel = 0
Instance.new("UICorner", cancelSpawnBtn).CornerRadius = UDim.new(0,6)
cancelSpawnBtn.MouseEnter:Connect(function() TweenService:Create(cancelSpawnBtn, TweenInfo.new(0.12), {BackgroundColor3 = BTN_HOVER}):Play() end)
cancelSpawnBtn.MouseLeave:Connect(function() TweenService:Create(cancelSpawnBtn, TweenInfo.new(0.12), {BackgroundColor3 = BTN_COLOR}):Play() end)

-- Cleanup spawning on exit
table.insert(cleanupTasks, function()
    isSpawning = false
    spawnClickMode = false
    if spawnThread then pcall(task.cancel, spawnThread); spawnThread = nil end
end)

-- Helper: check if a vehicle matches the target BrickColor
local function vehicleMatchesColor(vehicleModel, targetBrickColorName)
    local bc = BrickColor.new(targetBrickColorName)
    -- Check paint parts or main part color
    local paintParts = vehicleModel:FindFirstChild("PaintParts")
    if paintParts then
        for _, part in ipairs(paintParts:GetChildren()) do
            if part:IsA("BasePart") and part.BrickColor == bc then
                return true
            end
        end
    end
    -- Fallback: check any part named "Body" or the primary part
    local body = vehicleModel:FindFirstChild("Body") or vehicleModel.PrimaryPart
    if body and body:IsA("BasePart") and body.BrickColor == bc then
        return true
    end
    return false
end

-- Helper: find all spawn buttons for LT2 vehicles in workspace
local function findSpawnButtons()
    local buttons = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "spawnbutton") then
            table.insert(buttons, obj)
        end
    end
    return buttons
end

-- The spawning loop: called after user clicks a spawn button
local function runSpawnLoop(spawnButtonPart)
    local RS = game:GetService("ReplicatedStorage")
    local targetBrickName = colorToBrickColor[selectedColor] or "Medium stone grey"
    local maxAttempts = 200
    local attempt = 0

    setSpawnStatus("Spawning for color: " .. selectedColor, true)

    while isSpawning and attempt < maxAttempts do
        attempt = attempt + 1

        -- Fire the spawn remote (server-side)
        pcall(function()
            RS.Interaction.RemoteProxy:FireServer(spawnButtonPart)
        end)

        task.wait(0.35)

        -- Check if any newly spawned vehicle near player matches our color
        -- We check workspace.PlayerModels for a vehicle owned by the player
        local found = false
        pcall(function()
            local playerModels = workspace:FindFirstChild("PlayerModels")
            if not playerModels then return end
            for _, model in ipairs(playerModels:GetChildren()) do
                local ownerVal = model:FindFirstChild("Owner")
                if ownerVal and tostring(ownerVal.Value) == player.Name then
                    if model:FindFirstChild("DriveSeat") or model:FindFirstChild("VehicleSeat") then
                        if vehicleMatchesColor(model, targetBrickName) then
                            found = true
                        end
                    end
                end
            end
        end)

        if found then
            setSpawnStatus("Found matching color: " .. selectedColor, false)
            isSpawning = false
            break
        end

        -- Press E to despawn/respawn (simulate key press via keypress if executor supports it,
        -- otherwise use UserInputService simulation via a remote or direct input)
        -- Since we can't directly simulate key presses in a safe way, we re-fire the spawn remote
        -- which effectively cycles the vehicle. The game handles E via its own input.
        -- We'll use the FireServer approach each loop iteration as the "spam E" equivalent.
        task.wait(0.15)
    end

    if not isSpawning then
        -- was cancelled
        setSpawnStatus("Cancelled", false)
    elseif attempt >= maxAttempts then
        setSpawnStatus("Max attempts reached", false)
    end

    isSpawning = false
    spawnClickMode = false
    spawnThread = nil
end

-- Start Spawn: show popup instruction then enter click-detection mode
startSpawnBtn.MouseButton1Click:Connect(function()
    if isSpawning then setSpawnStatus("Already spawning!", true) return end

    -- Show instruction popup
    showVehiclePopup("Click on the SpawnButton to begin. The SpawnButton is the spawn button for Lumber Tycoon 2 vehicles, trailers, and all other LT2 vehicles.", 7)
    setSpawnStatus("Waiting for SpawnButton click...", true)
    spawnClickMode = true
end)

-- Cancel Spawning
cancelSpawnBtn.MouseButton1Click:Connect(function()
    isSpawning = false
    spawnClickMode = false
    if spawnThread then pcall(task.cancel, spawnThread); spawnThread = nil end
    setSpawnStatus("Cancelled", false)
end)

-- Mouse click detection for spawn button selection
local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
    if not spawnClickMode then return end

    local target = mouse.Target
    if not target then return end

    -- Accept any part with "spawnbutton" in name (case-insensitive), or whatever the user clicked
    -- We'll treat any clicked BasePart as the spawn button when in spawnClickMode
    if target:IsA("BasePart") then
        spawnClickMode = false
        isSpawning = true
        setSpawnStatus("Spawning...", true)
        spawnThread = task.spawn(function()
            runSpawnLoop(target)
        end)
    end
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
        {"Flip Vehicle", "VehicleTab"}, {"Select Color", "VehicleTab"},
        {"Start Spawn", "VehicleTab"}, {"Cancel Spawning", "VehicleTab"},
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
