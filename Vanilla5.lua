-- ════════════════════════════════════════════════════
-- VANILLA5 — Pixel Art Tab
-- Execute AFTER Vanilla1, Vanilla2, Vanilla3, Vanilla4
-- Requires: workspace.Builds folder with Model children
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla5: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages
local BTN_COLOR        = _G.VH.BTN_COLOR   -- Color3.fromRGB(45,45,50)
local BTN_HOVER        = _G.VH.BTN_HOVER   -- Color3.fromRGB(70,70,80)
local THEME_TEXT       = _G.VH.THEME_TEXT  -- Color3.fromRGB(230,206,226)

local camera = workspace.CurrentCamera
local mouse  = player:GetMouse()

-- ════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════
local cfg = {
    moveStep       = 1,
    rotStep        = 90,
    followingMouse = false,
}

-- ════════════════════════════════════════════════════
-- MODEL HELPERS
-- ════════════════════════════════════════════════════
local function getBuilds()
    local folder = workspace:FindFirstChild("Builds")
    if not folder then return {} end
    local out = {}
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            if not m.PrimaryPart then
                m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart")
            end
            if m.PrimaryPart then
                table.insert(out, m)
            end
        end
    end
    return out
end

local function getPivot(models)
    local sum, n = Vector3.zero, 0
    for _, m in ipairs(models) do
        sum = sum + m.PrimaryPart.Position
        n   = n + 1
    end
    return n > 0 and CFrame.new(sum / n) or CFrame.new()
end

local function snap(x, s)   return math.round(x / s) * s end
local function snapV3(v, s)  return Vector3.new(snap(v.X,s), snap(v.Y,s), snap(v.Z,s)) end

-- ════════════════════════════════════════════════════
-- CORE OPERATIONS
-- ════════════════════════════════════════════════════
local function moveModels(delta)
    for _, m in ipairs(getBuilds()) do
        m:SetPrimaryPartCFrame(m.PrimaryPart.CFrame + delta)
    end
end

local function rotateModels(axis, deg)
    local models = getBuilds()
    if #models == 0 then return end
    local pivot = getPivot(models)
    local rot   = CFrame.Angles(
        axis.X * math.rad(deg),
        axis.Y * math.rad(deg),
        axis.Z * math.rad(deg)
    )
    for _, m in ipairs(models) do
        local rel = pivot:ToObjectSpace(m.PrimaryPart.CFrame)
        m:SetPrimaryPartCFrame(pivot * rot * rel)
    end
end

local function setPosition(pos)
    local models = getBuilds()
    if #models == 0 then return end
    local diff = pos - getPivot(models).Position
    for _, m in ipairs(models) do
        m:SetPrimaryPartCFrame(m.PrimaryPart.CFrame + diff)
    end
end

local function snapToGrid()
    for _, m in ipairs(getBuilds()) do
        local snapped = snapV3(m.PrimaryPart.Position, cfg.moveStep)
        m:SetPrimaryPartCFrame(CFrame.new(snapped) * m.PrimaryPart.CFrame.Rotation)
    end
end

-- Camera-relative nudge so direction buttons feel natural at any camera angle
local function nudge(rawDir)
    local _, yaw, _ = camera.CFrame:ToEulerAnglesYXZ()
    local camRel    = CFrame.Angles(0, yaw, 0) * rawDir * cfg.moveStep

    local function toAxis(v)
        if math.abs(v.X) > math.abs(v.Z) then
            return Vector3.new(math.sign(v.X), 0, 0)
        else
            return Vector3.new(0, 0, math.sign(v.Z))
        end
    end

    local effective
    if rawDir.Y ~= 0 then
        effective = Vector3.new(0, math.sign(rawDir.Y), 0) * cfg.moveStep
    else
        effective = toAxis(camRel) * cfg.moveStep
    end
    moveModels(effective)
end

-- ════════════════════════════════════════════════════
-- CENTER ON PLOT
-- ════════════════════════════════════════════════════
local function centerOnPlot()
    local ray    = mouse.UnitRay
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    for _, m in ipairs(getBuilds()) do table.insert(excl, m) end
    if player.Character then table.insert(excl, player.Character) end
    params.FilterDescendantsInstances = excl

    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if not (result and result.Instance) then return end

    local properties = workspace:FindFirstChild("Properties")
    if not properties then return end

    for _, plot in ipairs(properties:GetChildren()) do
        if result.Instance:IsDescendantOf(plot) then
            local plotCenterPos, floorY = nil, math.huge
            local cSum, cCnt = Vector3.zero, 0

            for _, part in ipairs(plot:GetDescendants()) do
                if part:IsA("BasePart") then
                    floorY = math.min(floorY, part.Position.Y - part.Size.Y / 2)
                    cSum   = cSum + part.Position
                    cCnt   = cCnt + 1
                end
            end

            local pp = plot.PrimaryPart
            plotCenterPos = (pp and pp.Position) or (cCnt > 0 and cSum / cCnt) or nil
            if not plotCenterPos then return end

            local models = getBuilds()
            if #models == 0 then return end
            local pivot  = getPivot(models)

            local minY = math.huge
            for _, m in ipairs(models) do
                minY = math.min(minY, m.PrimaryPart.Position.Y - m.PrimaryPart.Size.Y / 2)
            end

            moveModels(Vector3.new(
                plotCenterPos.X - pivot.Position.X,
                (floorY - minY) + 0.05,
                plotCenterPos.Z - pivot.Position.Z
            ))
            return
        end
    end
end

-- ════════════════════════════════════════════════════
-- MOUSE-FOLLOW
-- ════════════════════════════════════════════════════
local followConn

local function startFollow()
    if followConn then return end
    followConn = RunService.RenderStepped:Connect(function()
        if not cfg.followingMouse then return end
        local ray    = mouse.UnitRay
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local excl = {}
        for _, m in ipairs(getBuilds()) do table.insert(excl, m) end
        if player.Character then table.insert(excl, player.Character) end
        params.FilterDescendantsInstances = excl

        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if not result then return end

        local targetPos = result.Position + result.Normal * (cfg.moveStep * 0.5)
        setPosition(snapV3(targetPos, cfg.moveStep))
    end)
end

local function stopFollow()
    cfg.followingMouse = false
    if followConn then followConn:Disconnect(); followConn = nil end
end

startFollow()
table.insert(cleanupTasks, stopFollow)

-- ════════════════════════════════════════════════════
-- KEYBOARD INPUT  (only when Pixel Art tab is active)
-- ════════════════════════════════════════════════════
local paInputConn = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local paPage = pages["Pixel ArtTab"]
    if not (paPage and paPage.Visible) then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local k = input.KeyCode
    if     k == Enum.KeyCode.Up       then nudge(Vector3.new( 0, 0,-1))
    elseif k == Enum.KeyCode.Down     then nudge(Vector3.new( 0, 0, 1))
    elseif k == Enum.KeyCode.Left     then nudge(Vector3.new(-1, 0, 0))
    elseif k == Enum.KeyCode.Right    then nudge(Vector3.new( 1, 0, 0))
    elseif k == Enum.KeyCode.PageUp   then nudge(Vector3.new( 0, 1, 0))
    elseif k == Enum.KeyCode.PageDown then nudge(Vector3.new( 0,-1, 0))
    elseif k == Enum.KeyCode.R        then rotateModels(Vector3.new(0,1,0),  cfg.rotStep)
    elseif k == Enum.KeyCode.T        then rotateModels(Vector3.new(0,1,0), -cfg.rotStep)
    elseif k == Enum.KeyCode.F        then rotateModels(Vector3.new(1,0,0),  cfg.rotStep)
    elseif k == Enum.KeyCode.G        then rotateModels(Vector3.new(1,0,0), -cfg.rotStep)
    end
end)

table.insert(cleanupTasks, function()
    if paInputConn then paInputConn:Disconnect(); paInputConn = nil end
end)

-- ════════════════════════════════════════════════════
-- UI HELPERS  —  identical style to every other tab
-- ════════════════════════════════════════════════════
local paPage = pages["Pixel ArtTab"]

local function mkLabel(text)
    local lbl = Instance.new("TextLabel", paPage)
    lbl.Size               = UDim2.new(1,-12,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 11
    lbl.TextColor3         = Color3.fromRGB(120,120,150)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function mkSep()
    local s = Instance.new("Frame", paPage)
    s.Size             = UDim2.new(1,-12,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,40,55)
    s.BorderSizePixel  = 0
end

-- Full-width button
local function mkBtn(text, color, callback)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", paPage)
    btn.Size             = UDim2.new(1,-12,0,32)
    btn.BackgroundColor3 = color
    btn.Text             = text
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = THEME_TEXT
    btn.BorderSizePixel  = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local hov = Color3.fromRGB(
        math.min(color.R*255+20,255)/255,
        math.min(color.G*255+8, 255)/255,
        math.min(color.B*255+20,255)/255
    )
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=hov}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=color}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Half-width paired button row
local function mkBtnRow(textL, textR, cbL, cbR)
    local row = Instance.new("Frame", paPage)
    row.Size               = UDim2.new(1,-12,0,32)
    row.BackgroundTransparency = 1

    local function half(text, posX, offsetX, cb)
        local b = Instance.new("TextButton", row)
        b.Size             = UDim2.new(0.5,-4,1,0)
        b.Position         = UDim2.new(posX, offsetX, 0, 0)
        b.BackgroundColor3 = BTN_COLOR
        b.Text             = text
        b.Font             = Enum.Font.GothamSemibold
        b.TextSize         = 12
        b.TextColor3       = THEME_TEXT
        b.BorderSizePixel  = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        b.MouseEnter:Connect(function()
            TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play()
        end)
        b.MouseButton1Click:Connect(cb)
        return b
    end

    half(textL, 0,   0, cbL)
    half(textR, 0.5, 4, cbR)
    return row
end

-- Toggle — identical to every other tab
local function mkToggle(text, default, callback)
    local frame = Instance.new("Frame", paPage)
    frame.Size             = UDim2.new(1,-12,0,32)
    frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(1,-50,1,0)
    lbl.Position           = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = THEME_TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local tb = Instance.new("TextButton", frame)
    tb.Size             = UDim2.new(0,34,0,18)
    tb.Position         = UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3 = default and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text             = ""
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1,0)

    local dot = Instance.new("Frame", tb)
    dot.Size             = UDim2.new(0,14,0,14)
    dot.Position         = UDim2.new(0, default and 18 or 2, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

    local on = default
    if callback then callback(on) end

    local function setOn(v)
        on = v
        TweenService:Create(tb,  TweenInfo.new(0.2, Enum.EasingStyle.Quint),
            {BackgroundColor3 = v and Color3.fromRGB(60,180,60) or BTN_COLOR}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quint),
            {Position = UDim2.new(0, v and 18 or 2, 0.5, -7)}):Play()
    end

    tb.MouseButton1Click:Connect(function()
        on = not on
        setOn(on)
        if callback then callback(on) end
    end)

    return frame, setOn, function() return on end
end

-- Slider — same style and colours as Vanilla1's player sliders
local function mkSlider(label, minV, maxV, defaultV, cb)
    local fr = Instance.new("Frame", paPage)
    fr.Size             = UDim2.new(1,-12,0,52)
    fr.BackgroundColor3 = Color3.fromRGB(24,24,30)
    fr.BorderSizePixel  = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0,6)

    local topRow = Instance.new("Frame", fr)
    topRow.Size               = UDim2.new(1,-16,0,22)
    topRow.Position           = UDim2.new(0,8,0,6)
    topRow.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size               = UDim2.new(0.7,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = THEME_TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = label

    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size               = UDim2.new(0.3,0,1,0)
    valLbl.Position           = UDim2.new(0.7,0,0,0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font               = Enum.Font.GothamBold
    valLbl.TextSize           = 13
    valLbl.TextColor3         = THEME_TEXT
    valLbl.TextXAlignment     = Enum.TextXAlignment.Right
    valLbl.Text               = tostring(defaultV)

    local track = Instance.new("Frame", fr)
    track.Size             = UDim2.new(1,-16,0,6)
    track.Position         = UDim2.new(0,8,0,36)
    track.BackgroundColor3 = Color3.fromRGB(40,40,55)
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((defaultV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,80,100)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("TextButton", track)
    knob.Size             = UDim2.new(0,16,0,16)
    knob.AnchorPoint      = Vector2.new(0.5,0.5)
    knob.Position         = UDim2.new((defaultV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(210,210,225)
    knob.Text             = ""
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local dragging = false
    local cur      = defaultV

    local function apply(screenX)
        local ratio = math.clamp(
            (screenX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X,1),
            0, 1)
        local val = math.max(1, math.round(minV + ratio*(maxV-minV)))
        if val == cur then return end
        cur           = val
        fill.Size     = UDim2.new(ratio,0,1,0)
        knob.Position = UDim2.new(ratio,0,0.5,0)
        valLbl.Text   = tostring(val)
        if cb then cb(val) end
    end

    knob.MouseButton1Down:Connect(function() dragging = true end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; apply(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            apply(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return fr
end

-- Hint row
local function mkHint(text)
    local fr = Instance.new("Frame", paPage)
    fr.Size             = UDim2.new(1,-12,0,28)
    fr.BackgroundColor3 = Color3.fromRGB(18,18,24)
    fr.BorderSizePixel  = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0,6)
    local lbl = Instance.new("TextLabel", fr)
    lbl.Size               = UDim2.new(1,-12,1,0)
    lbl.Position           = UDim2.new(0,6,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 11
    lbl.TextColor3         = Color3.fromRGB(110,110,140)
    lbl.TextWrapped        = true
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = text
end

-- ════════════════════════════════════════════════════
-- BUILD UI
-- ════════════════════════════════════════════════════

mkLabel("Grid Settings")

mkSlider("Grid Size (studs)", 1, 20, 1, function(v)
    cfg.moveStep = v
end)

mkSlider("Rotation Step (deg)", 15, 180, 90, function(v)
    cfg.rotStep = v
end)

mkSep()
mkLabel("Placement")

local _, setFollowToggle = mkToggle("Follow Mouse", false, function(v)
    cfg.followingMouse = v
    if v then startFollow() end
end)

mkHint("Click anywhere in-world while following to place and lock.")

mkSep()
mkLabel("Move  (Arrow Keys / PgUp / PgDn)")

mkBtnRow("Left",    "Right",
    function() nudge(Vector3.new(-1,0,0)) end,
    function() nudge(Vector3.new( 1,0,0)) end)

mkBtnRow("Forward", "Back",
    function() nudge(Vector3.new(0,0,-1)) end,
    function() nudge(Vector3.new(0,0, 1)) end)

mkBtnRow("Up",      "Down",
    function() nudge(Vector3.new(0, 1,0)) end,
    function() nudge(Vector3.new(0,-1,0)) end)

mkSep()
mkLabel("Rotate  (R / T / F / G)")

mkBtnRow("Yaw Left (T)",   "Yaw Right (R)",
    function() rotateModels(Vector3.new(0,1,0), -cfg.rotStep) end,
    function() rotateModels(Vector3.new(0,1,0),  cfg.rotStep) end)

mkBtnRow("Pitch Up (F)",   "Pitch Down (G)",
    function() rotateModels(Vector3.new(1,0,0),  cfg.rotStep) end,
    function() rotateModels(Vector3.new(1,0,0), -cfg.rotStep) end)

mkSep()
mkLabel("Utilities")

mkBtn("Snap to Grid", BTN_COLOR, function()
    snapToGrid()
end)

mkBtn("Center on Plot  (aim at plot first)", BTN_COLOR, function()
    centerOnPlot()
end)

mkSep()
mkLabel("Remove")

mkHint("Removes all models inside workspace.Builds. Cannot be undone.")

mkBtn("Remove Pixel Art", Color3.fromRGB(180,45,45), function()
    local folder = workspace:FindFirstChild("Builds")
    if not folder then return end
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            pcall(function() m:Destroy() end)
        end
    end
    cfg.followingMouse = false
    setFollowToggle(false)
end)

-- ════════════════════════════════════════════════════
-- STOP FOLLOW ON WORLD-CLICK
-- ════════════════════════════════════════════════════
local clickStopConn = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if cfg.followingMouse then
            cfg.followingMouse = false
            setFollowToggle(false)
        end
    end
end)

table.insert(cleanupTasks, function()
    if clickStopConn then clickStopConn:Disconnect(); clickStopConn = nil end
    stopFollow()
end)

print("[VanillaHub] Vanilla5 (Pixel Art) loaded")
