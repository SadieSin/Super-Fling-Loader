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

local function getWaitingForFlyKey() return _G.VH and _G.VH.waitingForFlyKey end
local function setWaitingForFlyKey(v) if _G.VH then _G.VH.waitingForFlyKey = v end end
local function getWaitingForKeyGUI() return _G.VH and _G.VH.waitingForKeyGUI end
local function setWaitingForKeyGUI(v) if _G.VH then _G.VH.waitingForKeyGUI = v end end
local function getCurrentFlyKey() return _G.VH and _G.VH.currentFlyKey or Enum.KeyCode.Q end
local function setCurrentFlyKey(v) if _G.VH then _G.VH.currentFlyKey = v end end
local function getCurrentToggleKey() return _G.VH and _G.VH.currentToggleKey or Enum.KeyCode.LeftAlt end
local function setCurrentToggleKey(v) if _G.VH then _G.VH.currentToggleKey = v end end
local function getFlyToggleEnabled() return _G.VH and _G.VH.flyToggleEnabled end
local function getIsFlyEnabled() return _G.VH and _G.VH.isFlyEnabled end

-- ════════════════════════════════════════════════════
-- AUTOBUY TAB
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
kbTitle.TextColor3 = THEME_TEXT; kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Text = "GUI Toggle Keybind"
keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size = UDim2.new(0,200,0,28); keybindButtonGUI.Position = UDim2.new(0,10,0,36)
keybindButtonGUI.BackgroundColor3 = Color3.fromRGB(30,30,30); keybindButtonGUI.BorderSizePixel = 0
keybindButtonGUI.Font = Enum.Font.Gotham; keybindButtonGUI.TextSize = 14
keybindButtonGUI.TextColor3 = THEME_TEXT
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
searchInput.TextColor3 = THEME_TEXT; searchInput.TextXAlignment = Enum.TextXAlignment.Left
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
        -- Wood tab entries
        {"Click Sell", "WoodTab"}, {"Group Select", "WoodTab"},
        {"Sell Selected Logs", "WoodTab"}, {"Sell Wood", "WoodTab"},
        {"Clear Wood Selection", "WoodTab"},
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
                Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0,10)
                resBtn.MouseEnter:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35,35,45), TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
                resBtn.MouseLeave:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22,22,28), TextColor3 = THEME_TEXT}):Play() end)
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
                Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0,10)
                local subLbl = Instance.new("TextLabel", resBtn)
                subLbl.Size = UDim2.new(1,-20,0,16); subLbl.Position = UDim2.new(0,36,1,-18)
                subLbl.BackgroundTransparency = 1; subLbl.Font = Enum.Font.Gotham; subLbl.TextSize = 11
                subLbl.TextColor3 = Color3.fromRGB(120,120,150); subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.Text = "in " .. ftab:gsub("Tab","") .. " tab"
                resBtn.MouseEnter:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28,35,52), TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
                resBtn.MouseLeave:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18,22,30), TextColor3 = THEME_TEXT}):Play() end)
                resBtn.MouseButton1Click:Connect(function() switchTab(ftab) end)
            end
        end
    end
end
searchInput:GetPropertyChangedSignal("Text"):Connect(function() updateSearchResults(searchInput.Text) end)
task.delay(0.1, function() updateSearchResults("") end)

-- ════════════════════════════════════════════════════
-- WOOD TAB
-- ════════════════════════════════════════════════════

-- Sell destination: Wood Dropoff conveyor entry point
local SELL_POS = Vector3.new(315.14, -0.40, 86.32)

local WOOD_TREE_CLASSES = {
    "Generic", "Elm", "Cherry", "Birch",
    "Oak", "Palm",
    "Fir", "SnowGlow",
    "Lava",
    "Cavecrawler", "Sinister",
    "Walnut", "Koa", "Spook", "Phantom",
    "GreenLog", "Gold", "Pink",
}
local WOOD_CLASS_SET = {}
for _, v in ipairs(WOOD_TREE_CLASSES) do
    WOOD_CLASS_SET[v:lower()] = true
end

local function isWoodLog(model)
    if not model or not model:IsA("Model") then return false end
    local tc = model:FindFirstChild("TreeClass")
    if not tc then return false end
    if model:FindFirstChild("DraggableItem") then return false end
    if not (model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")) then return false end
    return true
end

-- Wood tab state
local clickSellEnabled   = false
local groupSelectEnabled = false
local woodSelected       = {}
local isSellRunning      = false

local woodPage = pages["WoodTab"]

-- ── UI helpers ────────────────────────────────────────────────────────────────

local function createWSectionLabel(text)
    local lbl = Instance.new("TextLabel", woodPage)
    lbl.Size = UDim2.new(1,-12,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function createWSep()
    local sep = Instance.new("Frame", woodPage)
    sep.Size = UDim2.new(1,-12,0,1)
    sep.BackgroundColor3 = Color3.fromRGB(40,40,55)
    sep.BorderSizePixel = 0
end

local function createWToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", woodPage)
    frame.Size = UDim2.new(1,-12,0,32)
    frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0,34,0,18); tb.Position = UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3 = defaultState and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text = ""; Instance.new("UICorner", tb).CornerRadius = UDim.new(1,0)

    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0,14,0,14)
    circle.Position = UDim2.new(0, defaultState and 18 or 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)

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
    btn.Size = UDim2.new(1,-12,0,32)
    btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local hov = Color3.fromRGB(
        math.min(color.R*255+20,255)/255,
        math.min(color.G*255+8, 255)/255,
        math.min(color.B*255+20,255)/255
    )
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=hov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=color}):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ── Progress bar ──────────────────────────────────────────────────────────────
local sellProgressContainer, sellProgressFill, sellProgressLabel

do
    local pbWrapper = Instance.new("Frame", woodPage)
    pbWrapper.Size = UDim2.new(1,-12,0,44)
    pbWrapper.BackgroundColor3 = Color3.fromRGB(18,18,24)
    pbWrapper.BorderSizePixel = 0
    pbWrapper.Visible = false
    Instance.new("UICorner", pbWrapper).CornerRadius = UDim.new(0,8)
    local pbStroke = Instance.new("UIStroke", pbWrapper)
    pbStroke.Color = Color3.fromRGB(60,60,80); pbStroke.Thickness = 1; pbStroke.Transparency = 0.5

    local pbLabel = Instance.new("TextLabel", pbWrapper)
    pbLabel.Size = UDim2.new(1,-12,0,16); pbLabel.Position = UDim2.new(0,6,0,4)
    pbLabel.BackgroundTransparency = 1; pbLabel.Font = Enum.Font.GothamSemibold; pbLabel.TextSize = 11
    pbLabel.TextColor3 = THEME_TEXT; pbLabel.TextXAlignment = Enum.TextXAlignment.Left
    pbLabel.Text = "Selling..."

    local pbTrack = Instance.new("Frame", pbWrapper)
    pbTrack.Size = UDim2.new(1,-12,0,12); pbTrack.Position = UDim2.new(0,6,0,24)
    pbTrack.BackgroundColor3 = Color3.fromRGB(30,30,40); pbTrack.BorderSizePixel = 0
    Instance.new("UICorner", pbTrack).CornerRadius = UDim.new(1,0)

    local pbFill = Instance.new("Frame", pbTrack)
    pbFill.Size = UDim2.new(0,0,1,0)
    pbFill.BackgroundColor3 = Color3.fromRGB(80,200,120)
    pbFill.BorderSizePixel = 0
    Instance.new("UICorner", pbFill).CornerRadius = UDim.new(1,0)

    sellProgressContainer = pbWrapper
    sellProgressFill      = pbFill
    sellProgressLabel     = pbLabel
end

-- ── Selection helpers ─────────────────────────────────────────────────────────

local function highlightWood(model)
    if woodSelected[model] then return end
    local hl = Instance.new("SelectionBox")
    hl.Color3 = Color3.fromRGB(0,220,80)
    hl.LineThickness = 0.06
    hl.SurfaceTransparency = 0.7
    hl.SurfaceColor3 = Color3.fromRGB(0,220,80)
    hl.Adornee = model
    hl.Parent = model
    woodSelected[model] = hl
end

local function unhighlightWood(model)
    if woodSelected[model] then
        woodSelected[model]:Destroy()
        woodSelected[model] = nil
    end
end

local function unhighlightAllWood()
    for model, hl in pairs(woodSelected) do
        if hl and hl.Parent then hl:Destroy() end
    end
    woodSelected = {}
end

-- ════════════════════════════════════════════════════
-- WOOD SELL ENGINE — optimized for 0.8s per item
-- ════════════════════════════════════════════════════
--
-- Key improvements over original:
--   1. Noclip applied before each move so character can stand next to any log
--   2. Heartbeat loop fires ClientIsDragging + sets CFrame every frame simultaneously
--   3. Confirmation by proximity (< 8 studs) OR 1.2s timeout — whichever is first
--   4. 0.8s gap between logs is enforced AFTER the heartbeat confirms (not before)
--   5. Character noclip stays on during the whole sell session; restored on cancel/done

local RS = game:GetService("ReplicatedStorage")

local function getInteraction()
    local i = RS:FindFirstChild("Interaction")
    return i and i:FindFirstChild("ClientIsDragging")
end

-- Enable noclip on the local character (all BaseParts non-collidable)
local activeNoclipConn = nil
local function enableNoclip()
    if activeNoclipConn then return end
    activeNoclipConn = RunService.Stepped:Connect(function()
        local char = player.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = false end)
            end
        end
    end)
end

local function disableNoclip()
    if activeNoclipConn then
        activeNoclipConn:Disconnect()
        activeNoclipConn = nil
    end
    -- Restore collision
    local char = player.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end
end

--[[
  sellOneLog(model, onDone)
  - Noclip is assumed active (caller manages it)
  - Teleports character next to the log
  - Starts Heartbeat loop: fires ClientIsDragging + sets CFrame every frame
  - Stops when: part confirmed close to SELL_POS, part removed, or timeout
  - Calls onDone(success: bool) when finished
  - Returns the heartbeat connection (so it can be killed on cancel)
]]
local SELL_TIMEOUT     = 1.2   -- max seconds per log
local SELL_CONFIRM_DIST = 8    -- studs from SELL_POS = confirmed sold

local function sellOneLog(model, onDone)
    if not (model and model.Parent) then
        if onDone then task.spawn(onDone, false) end
        return nil
    end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        if onDone then task.spawn(onDone, false) end
        return nil
    end

    local mainPart = model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
    if not mainPart then
        if onDone then task.spawn(onDone, false) end
        return nil
    end

    local targetCF  = CFrame.new(SELL_POS)
    local dragger   = getInteraction()
    local startTime = tick()
    local heartbeatConn

    -- Step 1: Teleport character right next to the log (noclip avoids being blocked)
    hrp.CFrame = mainPart.CFrame * CFrame.new(0, 3, 3)

    -- Step 2: Heartbeat loop — fire drag + slam CFrame every frame simultaneously
    heartbeatConn = RunService.Heartbeat:Connect(function()
        -- Part removed / sold already
        if not (mainPart and mainPart.Parent) then
            heartbeatConn:Disconnect()
            if onDone then task.spawn(onDone, true) end
            return
        end

        -- Stay near the part if physics drifts us away
        local char2 = player.Character
        local hrp2  = char2 and char2:FindFirstChild("HumanoidRootPart")
        if hrp2 and (hrp2.Position - mainPart.Position).Magnitude > 18 then
            pcall(function() hrp2.CFrame = mainPart.CFrame * CFrame.new(0, 3, 3) end)
        end

        -- Fire ClientIsDragging + write CFrame on the same frame
        if dragger then pcall(function() dragger:FireServer(model) end) end
        pcall(function() mainPart.CFrame = targetCF end)

        local dist     = (mainPart.Position - SELL_POS).Magnitude
        local timedOut = (tick() - startTime) >= SELL_TIMEOUT

        if dist < SELL_CONFIRM_DIST or timedOut then
            heartbeatConn:Disconnect()
            -- Reinforce: hammer a few extra frames after server accepts
            task.spawn(function()
                for _ = 1, 20 do
                    pcall(function()
                        if dragger then dragger:FireServer(model) end
                        if mainPart and mainPart.Parent then mainPart.CFrame = targetCF end
                    end)
                    task.wait()
                end
                if onDone then onDone(dist < SELL_CONFIRM_DIST) end
            end)
        end
    end)

    return heartbeatConn
end

-- ── Click Sell ────────────────────────────────────────────────────────────────
local clickSellBusy = false
local clickSellConn = nil

local function clickSellLog(model)
    if clickSellBusy then return end
    if not isWoodLog(model) then return end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    clickSellBusy = true
    enableNoclip()

    clickSellConn = sellOneLog(model, function(success)
        clickSellConn = nil
        clickSellBusy = false
        disableNoclip()
    end)
end

-- ── Sell Selected ─────────────────────────────────────────────────────────────
local sellOriginCF    = nil
local currentSellConn = nil

local function sellSelected()
    if isSellRunning then return end

    local queue = {}
    for model in pairs(woodSelected) do
        if model and model.Parent then
            table.insert(queue, model)
        end
    end
    if #queue == 0 then return end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    isSellRunning = true
    sellOriginCF  = hrp and hrp.CFrame or nil

    -- Enable noclip for the whole sell session
    enableNoclip()

    local total = #queue
    local done  = 0

    sellProgressContainer.Visible = true
    sellProgressFill.Size = UDim2.new(0, 0, 1, 0)
    sellProgressLabel.Text = "Selling Selected... 0 / " .. total

    local function updateBar()
        local pct = math.clamp(done / math.max(total, 1), 0, 1)
        TweenService:Create(sellProgressFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Size = UDim2.new(pct, 0, 1, 0)
        }):Play()
        sellProgressLabel.Text = "Selling Selected... " .. done .. " / " .. total
    end

    local function finishSell(cancelled)
        isSellRunning   = false
        currentSellConn = nil
        disableNoclip()
        unhighlightAllWood()

        -- Return player to origin
        if sellOriginCF then
            pcall(function()
                local c = player.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if r then r.CFrame = sellOriginCF end
            end)
            sellOriginCF = nil
        end

        if cancelled then
            sellProgressLabel.Text = "Cancelled."
        else
            TweenService:Create(sellProgressFill, TweenInfo.new(0.25), {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(60, 200, 110)
            }):Play()
            sellProgressLabel.Text = "Selling Selected... Done!"
        end

        task.delay(2.0, function()
            if sellProgressContainer then
                TweenService:Create(sellProgressContainer, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
                TweenService:Create(sellProgressFill,     TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
                TweenService:Create(sellProgressLabel,    TweenInfo.new(0.4), {TextTransparency = 1}):Play()
                task.delay(0.45, function()
                    if sellProgressContainer then
                        sellProgressContainer.Visible = false
                        sellProgressContainer.BackgroundTransparency = 0
                        sellProgressFill.BackgroundTransparency = 0
                        sellProgressFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                        sellProgressFill.Size = UDim2.new(0, 0, 1, 0)
                        sellProgressLabel.TextTransparency = 0
                    end
                end)
            end
        end)
    end

    -- Process queue sequentially — 0.8 seconds between items
    task.spawn(function()
        for i, model in ipairs(queue) do
            if not isSellRunning then
                finishSell(true)
                return
            end

            -- Skip already-gone items
            if not (model and model.Parent) then
                done = done + 1
                updateBar()
                continue
            end

            sellProgressLabel.Text = "Selling Selected... " .. done .. " / " .. total

            -- Sell this log via the optimized Heartbeat loop
            local logDone = false
            currentSellConn = sellOneLog(model, function(success)
                currentSellConn = nil
                logDone = true
            end)

            -- Wait for this log to finish (or cancel)
            while not logDone and isSellRunning do
                task.wait()
            end

            if not isSellRunning then
                if currentSellConn then
                    pcall(function() currentSellConn:Disconnect() end)
                    currentSellConn = nil
                end
                finishSell(true)
                return
            end

            unhighlightWood(model)
            done = done + 1
            updateBar()

            -- 0.8s gap between logs (only between items, not after the last one)
            if i < #queue then
                task.wait(0.8)
            end
        end

        finishSell(false)
    end)
end

-- ── Group select: all same-TreeClass logs in workspace ───────────────────────

local function groupSelectLogs(targetModel)
    if not isWoodLog(targetModel) then return end
    local tc = targetModel:FindFirstChild("TreeClass")
    if not tc then return end
    local targetClass = tc.Value:lower()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isWoodLog(obj) then
            local otc = obj:FindFirstChild("TreeClass")
            if otc and otc.Value:lower() == targetClass then
                highlightWood(obj)
            end
        end
    end
end

-- ── Mouse handler ─────────────────────────────────────────────────────────────

local woodMouse    = player:GetMouse()
local woodMouseConn = nil

local function connectWoodMouse()
    if woodMouseConn then return end
    woodMouseConn = woodMouse.Button1Down:Connect(function()
        local target = woodMouse.Target
        if not target then return end
        local model = target:FindFirstAncestorOfClass("Model")
        if not model then return end

        if clickSellEnabled then
            if isWoodLog(model) and not clickSellBusy then
                task.spawn(function() clickSellLog(model) end)
            end
        elseif groupSelectEnabled then
            if isWoodLog(model) then
                groupSelectLogs(model)
            end
        else
            if isWoodLog(model) then
                if woodSelected[model] then unhighlightWood(model)
                else highlightWood(model) end
            end
        end
    end)
end

local function disconnectWoodMouse()
    if woodMouseConn then
        woodMouseConn:Disconnect()
        woodMouseConn = nil
    end
end

table.insert(cleanupTasks, function()
    isSellRunning = false
    clickSellBusy = false
    if clickSellConn then pcall(function() clickSellConn:Disconnect() end); clickSellConn = nil end
    if currentSellConn then pcall(function() currentSellConn:Disconnect() end); currentSellConn = nil end
    disconnectWoodMouse()
    disableNoclip()
    unhighlightAllWood()
end)

-- ── Build Wood Tab UI ─────────────────────────────────────────────────────────

createWSectionLabel("Sell Features")

createWToggle("Click Sell", false, function(val)
    clickSellEnabled = val
    if val then
        groupSelectEnabled = false
        connectWoodMouse()
    else
        if not groupSelectEnabled then disconnectWoodMouse() end
    end
end)

createWSep()
createWSectionLabel("Log Selection")

createWToggle("Group Select (Logs Only)", false, function(val)
    groupSelectEnabled = val
    if val then
        clickSellEnabled = false
        connectWoodMouse()
    else
        if not clickSellEnabled then disconnectWoodMouse() end
    end
end)

local infoLbl = Instance.new("TextLabel", woodPage)
infoLbl.Size = UDim2.new(1,-12,0,30)
infoLbl.BackgroundColor3 = Color3.fromRGB(18,18,24)
infoLbl.BorderSizePixel = 0
infoLbl.Font = Enum.Font.Gotham; infoLbl.TextSize = 11
infoLbl.TextColor3 = Color3.fromRGB(120,120,150)
infoLbl.TextWrapped = true; infoLbl.TextXAlignment = Enum.TextXAlignment.Left
infoLbl.Text = "  Click a log to select all matching logs. Gift items are excluded."
Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0,6)
Instance.new("UIPadding", infoLbl).PaddingLeft = UDim.new(0,6)

createWSep()
createWSectionLabel("Actions")

createWButton("Sell Selected Logs", Color3.fromRGB(35,90,45), function()
    if isSellRunning then return end
    sellSelected()
end)

createWButton("Cancel Sell", BTN_COLOR, function()
    isSellRunning = false

    if currentSellConn then
        pcall(function() currentSellConn:Disconnect() end)
        currentSellConn = nil
    end

    disableNoclip()

    if sellOriginCF then
        pcall(function()
            local c = player.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = sellOriginCF end
        end)
        sellOriginCF = nil
    end

    if sellProgressContainer and sellProgressContainer.Visible then
        sellProgressLabel.Text = "Cancelled."
        task.delay(1.5, function()
            TweenService:Create(sellProgressContainer, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            task.delay(0.45, function()
                if sellProgressContainer then
                    sellProgressContainer.Visible = false
                    sellProgressContainer.BackgroundTransparency = 0
                end
            end)
        end)
    end

    unhighlightAllWood()
end)

createWButton("Clear Selection", BTN_COLOR, function()
    unhighlightAllWood()
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
            TweenService:Create(keybindButtonGUI, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true), {
                BackgroundColor3 = Color3.fromRGB(60,180,60)
            }):Play()
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
        toggleGUI()
        return
    end

    -- Fly toggle via Q key (always works; no toggle switch required)
    if input.KeyCode == getCurrentFlyKey() and getFlyToggleEnabled() then
        if getIsFlyEnabled() then stopFly() else startFly() end
    end
end)

table.insert(cleanupTasks, function()
    if inputConn then inputConn:Disconnect(); inputConn = nil end
end)

_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded")
