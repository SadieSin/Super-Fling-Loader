-- VanillaHub | Vanilla7.lua
-- Populates: Build, Vehicle tabs
-- Requires Vanilla1 (_G.VH) to already be loaded.

if not _G.VH then
    warn("[VanillaHub] Vanilla7: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH          = _G.VH
local TS          = VH.TweenService
local Players     = VH.Players
local RS          = game:GetService("ReplicatedStorage")
local UIS         = VH.UserInputService
local RunService  = VH.RunService
local LP          = Players.LocalPlayer
local Mouse       = LP:GetMouse()

local THEME_TEXT  = VH.THEME_TEXT
local BTN_COLOR   = VH.BTN_COLOR
local BTN_HOVER   = VH.BTN_HOVER
local pages       = VH.pages

-- ── Shared UI helpers (self-contained copy) ────────────────────────────────────

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function sectionLabel(page, text)
    local lbl = Instance.new("TextLabel", page)
    lbl.Size = UDim2.new(1,-12,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,100,140)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function sep(page)
    local s = Instance.new("Frame", page)
    s.Size = UDim2.new(1,-12,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,38,55)
    s.BorderSizePixel = 0
end

local function makeButton(page, text, cb)
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(1,-12,0,34)
    btn.BackgroundColor3 = BTN_COLOR
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT
    btn.Text = text
    btn.AutoButtonColor = false
    corner(btn, 6)
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play()
    end)
    btn.MouseButton1Click:Connect(function() task.spawn(cb) end)
    return btn
end

local function makeToggle(page, text, default, cb)
    local frame = Instance.new("Frame", page)
    frame.Size = UDim2.new(1,-12,0,32)
    frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    frame.BorderSizePixel = 0
    corner(frame, 6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-52,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text

    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0,34,0,18)
    tb.Position = UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3 = default and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text = ""
    tb.BorderSizePixel = 0
    corner(tb, 9)

    local knob = Instance.new("Frame", tb)
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(0, default and 18 or 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    corner(knob, 7)

    local state = default
    local function setState(v)
        state = v
        TS:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = v and Color3.fromRGB(60,180,60) or BTN_COLOR
        }):Play()
        TS:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, v and 18 or 2, 0.5, -7)
        }):Play()
        cb(v)
    end
    setState(default)
    tb.MouseButton1Click:Connect(function() setState(not state) end)
    return {Set = setState, Get = function() return state end}
end

local function makeSlider(page, text, min, max, default, cb)
    local frame = Instance.new("Frame", page)
    frame.Size = UDim2.new(1,-12,0,52)
    frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    frame.BorderSizePixel = 0
    corner(frame, 6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6,0,0,22)
    lbl.Position = UDim2.new(0,8,0,6)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text

    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(0.4,0,0,22)
    valLbl.Position = UDim2.new(0.6,-8,0,6)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextColor3 = THEME_TEXT
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(default)

    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1,-16,0,6)
    track.Position = UDim2.new(0,8,0,36)
    track.BackgroundColor3 = Color3.fromRGB(40,40,55)
    track.BorderSizePixel = 0
    corner(track, 3)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,80,100)
    fill.BorderSizePixel = 0
    corner(fill, 3)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0,16,0,16)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((default-min)/(max-min),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(210,210,225)
    knob.Text = ""
    knob.BorderSizePixel = 0
    corner(knob, 8)

    local dragging = false
    local function update(absX)
        local ratio = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.round(min + ratio*(max-min))
        fill.Size = UDim2.new(ratio,0,1,0)
        knob.Position = UDim2.new(ratio,0,0.5,0)
        valLbl.Text = tostring(val)
        cb(val)
    end
    knob.MouseButton1Down:Connect(function() dragging = true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; update(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local function makeDropdown(page, placeholder, options, cb)
    local wrap = Instance.new("Frame", page)
    wrap.Name = "DropWrap"
    wrap.Size = UDim2.new(1,-12,0,34)
    wrap.BackgroundTransparency = 1
    wrap.ClipsDescendants = false

    local hdr = Instance.new("TextButton", wrap)
    hdr.Size = UDim2.new(1,0,1,0)
    hdr.BackgroundColor3 = BTN_COLOR
    hdr.BorderSizePixel = 0
    hdr.Font = Enum.Font.GothamSemibold
    hdr.TextSize = 13
    hdr.TextColor3 = Color3.fromRGB(160,140,180)
    hdr.Text = "  "..placeholder
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.AutoButtonColor = false
    corner(hdr, 6)

    local arrow = Instance.new("TextLabel", hdr)
    arrow.Size = UDim2.new(0,24,1,0)
    arrow.Position = UDim2.new(1,-28,0,0)
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 14
    arrow.TextColor3 = THEME_TEXT
    arrow.Text = "▾"

    local gui = game.CoreGui:FindFirstChild("VanillaHub")
    local list = Instance.new("Frame", gui)
    list.Name = "DropList"
    list.BackgroundColor3 = Color3.fromRGB(28,26,36)
    list.BorderSizePixel = 0
    list.ZIndex = 30
    list.Visible = false
    list.Size = UDim2.new(0,0,0,0)
    corner(list, 6)

    local stroke = Instance.new("UIStroke", list)
    stroke.Color = Color3.fromRGB(60,50,80); stroke.Thickness = 1; stroke.Transparency = 0.5

    local ll = Instance.new("UIListLayout", list)
    ll.SortOrder = Enum.SortOrder.LayoutOrder

    local lpad = Instance.new("UIPadding", list)
    lpad.PaddingTop = UDim.new(0,3); lpad.PaddingBottom = UDim.new(0,3)

    local open = false

    local function close()
        open = false; arrow.Text = "▾"; list.Visible = false
    end

    local function openDrop()
        open = true; arrow.Text = "▴"
        local abs = hdr.AbsolutePosition
        local sz  = hdr.AbsoluteSize
        local h = #options * 28 + 6
        list.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 2)
        list.Size = UDim2.new(0, sz.X, 0, h)
        list.Visible = true
    end

    local function rebuild(opts)
        options = opts
        for _, ch in ipairs(list:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for _, opt in ipairs(opts) do
            local ob = Instance.new("TextButton", list)
            ob.Size = UDim2.new(1,0,0,28)
            ob.BackgroundTransparency = 1
            ob.Font = Enum.Font.Gotham
            ob.TextSize = 13
            ob.TextColor3 = THEME_TEXT
            ob.Text = opt
            ob.ZIndex = 30
            ob.AutoButtonColor = false
            ob.MouseEnter:Connect(function()
                TS:Create(ob, TweenInfo.new(0.08), {TextColor3 = Color3.fromRGB(210,170,240)}):Play()
            end)
            ob.MouseLeave:Connect(function()
                TS:Create(ob, TweenInfo.new(0.08), {TextColor3 = THEME_TEXT}):Play()
            end)
            ob.MouseButton1Click:Connect(function()
                hdr.Text = "  "..opt
                hdr.TextColor3 = THEME_TEXT
                close(); cb(opt)
            end)
        end
    end

    rebuild(options)
    hdr.MouseButton1Click:Connect(function()
        if open then close() else openDrop() end
    end)
    UIS.InputBegan:Connect(function(i)
        if open and i.UserInputType == Enum.UserInputType.MouseButton1 then
            local mp = UIS:GetMouseLocation()
            local lp = list.AbsolutePosition; local ls = list.AbsoluteSize
            if not (mp.X >= lp.X and mp.X <= lp.X+ls.X and mp.Y >= lp.Y and mp.Y <= lp.Y+ls.Y) then
                close()
            end
        end
    end)

    table.insert(VH.cleanupTasks, function()
        if list and list.Parent then list:Destroy() end
    end)

    return {SetOptions = function(_, opts) rebuild(opts) end}
end

local function makeStatus(page, initText)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(1,-12,0,28)
    f.BackgroundColor3 = Color3.fromRGB(22,22,28)
    f.BorderSizePixel = 0
    corner(f, 6)

    local dot = Instance.new("Frame", f)
    dot.Size = UDim2.new(0,7,0,7)
    dot.Position = UDim2.new(0,10,0.5,-3)
    dot.BackgroundColor3 = Color3.fromRGB(80,80,100)
    dot.BorderSizePixel = 0
    corner(dot, 4)

    local lb = Instance.new("TextLabel", f)
    lb.Size = UDim2.new(1,-26,1,0)
    lb.Position = UDim2.new(0,22,0,0)
    lb.BackgroundTransparency = 1
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 12
    lb.TextColor3 = Color3.fromRGB(150,130,170)
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Text = initText

    return {
        SetActive = function(on, msg)
            dot.BackgroundColor3 = on and Color3.fromRGB(60,200,60) or Color3.fromRGB(80,80,100)
            if msg then lb.Text = msg end
        end
    }
end

local function getPlayerNames()
    local names = {}
    for _, p in next, Players:GetPlayers() do table.insert(names, p.Name) end
    return names
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BUILD TAB  (pages["BuildTab"])
-- ═══════════════════════════════════════════════════════════════════════════

local bd = pages["BuildTab"]

local fillSpeed   = 0.3
local buildOwner  = LP.Name
local lassoActive = false
local includeBPs  = false
local lassoSG     = nil
local lassoRect   = nil
local lassoConn   = nil

local function isNetOwner(part)
    local ok, v = pcall(function() return part.ReceiveAge == 0 end)
    return ok and v
end

local function deselectAll()
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Selection" then pcall(function() v:Destroy() end) end
    end
    if workspace:FindFirstChild("Preview") then
        for _, v in pairs(workspace.Preview:GetDescendants()) do
            if v.Name == "Selection" then pcall(function() v:Destroy() end) end
        end
    end
end

local function inRect(rect, screenPos)
    local minX = math.min(rect.sx, rect.ex)
    local maxX = math.max(rect.sx, rect.ex)
    local minY = math.min(rect.sy, rect.ey)
    local maxY = math.max(rect.sy, rect.ey)
    return screenPos.X >= minX and screenPos.X <= maxX
       and screenPos.Y >= minY and screenPos.Y <= maxY
end

-- Setup lasso overlay
local function setupLasso()
    if lassoSG then pcall(function() lassoSG:Destroy() end) end
    lassoSG = Instance.new("ScreenGui")
    lassoSG.Name = "VH_Lasso"
    lassoSG.ResetOnSpawn = false
    lassoSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    lassoSG.Parent = game.CoreGui

    lassoRect = Instance.new("Frame", lassoSG)
    lassoRect.BackgroundColor3 = Color3.fromRGB(180,100,220)
    lassoRect.BackgroundTransparency = 0.85
    lassoRect.BorderSizePixel = 0
    lassoRect.Visible = false
    lassoRect.ZIndex = 20
    local stroke = Instance.new("UIStroke", lassoRect)
    stroke.Color = Color3.fromRGB(200,130,240)
    stroke.Thickness = 1.5

    table.insert(VH.cleanupTasks, function()
        if lassoSG and lassoSG.Parent then lassoSG:Destroy() end
        if lassoConn then lassoConn:Disconnect() end
    end)
end
setupLasso()

-- Lasso input handler
UIS.InputBegan:Connect(function(input)
    if not lassoActive then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local rect = {sx = Mouse.X, sy = Mouse.Y, ex = Mouse.X, ey = Mouse.Y}
    lassoRect.Position = UDim2.new(0, rect.sx, 0, rect.sy)
    lassoRect.Size = UDim2.new(0, 0, 0, 0)
    lassoRect.Visible = true

    local cam = workspace.CurrentCamera
    local conn; conn = RunService.RenderStepped:Connect(function()
        if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            conn:Disconnect()
            lassoRect.Visible = false

            -- Select items inside lasso
            for _, v in pairs(workspace.PlayerModels:GetChildren()) do
                local main = v:FindFirstChild("WoodSection") or v:FindFirstChild("Main")
                if main then
                    local sp, vis = cam:WorldToScreenPoint(main.CFrame.p)
                    if vis and inRect(rect, sp) then
                        if not main:FindFirstChild("Selection") then
                            local sb = Instance.new("SelectionBox", main)
                            sb.Name = "Selection"
                            sb.Adornee = main
                            sb.SurfaceTransparency = 0.6
                            sb.LineThickness = 0.08
                            sb.Color3 = Color3.fromRGB(150,80,200)
                        end
                    end
                end
                if includeBPs and v:FindFirstChild("BuildDependentWood") then
                    local bdw = v.BuildDependentWood
                    local sp, vis = cam:WorldToScreenPoint(bdw.CFrame.p)
                    if vis and inRect(rect, sp) then
                        if not bdw:FindFirstChild("Selection") then
                            local sb = Instance.new("SelectionBox", bdw)
                            sb.Name = "Selection"; sb.Adornee = bdw
                            sb.SurfaceTransparency = 0.6; sb.LineThickness = 0.08
                            sb.Color3 = Color3.fromRGB(100,200,150)
                        end
                    end
                end
            end
            return
        end

        rect.ex = Mouse.X; rect.ey = Mouse.Y
        local minX = math.min(rect.sx, rect.ex)
        local minY = math.min(rect.sy, rect.ey)
        lassoRect.Position = UDim2.new(0, minX, 0, minY)
        lassoRect.Size = UDim2.new(0, math.abs(rect.ex-rect.sx), 0, math.abs(rect.ey-rect.sy))
    end)
end)

local function fillBlueprints(speed, owner)
    local wood = {}
    local bps  = {}

    for _, v in ipairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Selection" then table.insert(wood, v.Parent) end
    end
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Type") and v.Type.Value == "Blueprint"
           and tostring(v:FindFirstChild("Owner") and v.Owner.Value) == owner
           and v:FindFirstChild("BuildDependentWood")
           and v.BuildDependentWood.Transparency ~= 1 then
            table.insert(bps, v.BuildDependentWood)
        end
    end

    for i = 1, math.min(#wood, #bps) do
        local w = wood[i]; local bp = bps[i]
        if not (w and w.Parent and bp and bp.Parent) then continue end

        pcall(function()
            LP.Character.HumanoidRootPart.CFrame = w.CFrame * CFrame.new(5,0,0)
        end)
        task.wait(speed)

        pcall(function()
            local t0 = tick()
            while not isNetOwner(w) do
                RS.Interaction.ClientIsDragging:FireServer(w.Parent)
                task.wait(speed)
                if tick()-t0 > 6 then break end
            end
            RS.Interaction.ClientIsDragging:FireServer(w.Parent)
            w:PivotTo(bp.CFrame)
        end)
        task.wait(speed)
    end
end

local function loadPreview()
    if not workspace:FindFirstChild("Preview") then return end
    local baseCF
    for _, v in next, workspace.Properties:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP then
            baseCF = v.OriginSquare.CFrame
        end
    end
    if not baseCF then return end
    local offset = baseCF.Position

    local colorMap = {
        LoneCave={Color3.fromRGB(248,248,248),Enum.Material.Foil},
        Frost={Color3.fromRGB(159,243,233),Enum.Material.Ice},
        Spooky={Color3.fromRGB(170,85,0),Enum.Material.Granite},
        SnowGlow={Color3.fromRGB(255,255,0),Enum.Material.SmoothPlastic},
        CaveCrawler={Color3.fromRGB(16,42,220),Enum.Material.Neon},
        SpookyNeon={Color3.fromRGB(170,85,0),Enum.Material.Neon},
        Volcano={Color3.fromRGB(255,0,0),Enum.Material.Wood},
        GreenSwampy={Color3.fromRGB(52,142,64),Enum.Material.Wood},
        GoldSwampy={Color3.fromRGB(226,155,64),Enum.Material.Wood},
        Cherry={Color3.fromRGB(163,75,75),Enum.Material.Wood},
        Pine={Color3.fromRGB(215,197,154),Enum.Material.Wood},
        Walnut={Color3.fromRGB(105,64,40),Enum.Material.Wood},
        Oak={Color3.fromRGB(234,184,146),Enum.Material.Wood},
        Birch={Color3.fromRGB(205,205,205),Enum.Material.Wood},
        Koa={Color3.fromRGB(143,76,42),Enum.Material.Wood},
        Generic={Color3.fromRGB(204,142,105),Enum.Material.Wood},
        Palm={Color3.fromRGB(226,220,188),Enum.Material.Wood},
    }

    for _, v in pairs(workspace.Preview:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Position = v.Position + offset
            local tc = v.Parent:FindFirstChild("TreeClass")
            if tc and v.Transparency == 0.5 then
                local info = colorMap[tc.Value]
                if info then v.Color = info[1]; v.Material = info[2] end
            end
        end
    end
end

-- Build UI
sectionLabel(bd, "Studio Preview")
makeButton(bd, "Load Preview Into World", loadPreview)
makeButton(bd, "Unload Preview", function()
    if workspace:FindFirstChild("Preview") then
        workspace.Preview:ClearAllChildren()
    end
end)

sep(bd)
sectionLabel(bd, "Fill Blueprints")

makeToggle(bd, "Lasso Wood Tool", false, function(v)
    lassoActive = v
end)
makeToggle(bd, "Include Blueprints in Lasso", false, function(v)
    includeBPs = v
end)
makeSlider(bd, "Fill Speed", 1, 10, 3, function(v)
    fillSpeed = v / 10
end)

local buildOwnerDD
do
    local names = getPlayerNames()
    buildOwnerDD = makeDropdown(bd, "Wood Owner...", names, function(val)
        buildOwner = val
    end)
    Players.PlayerAdded:Connect(function()
        buildOwnerDD:SetOptions(getPlayerNames())
    end)
    Players.PlayerRemoving:Connect(function()
        buildOwnerDD:SetOptions(getPlayerNames())
    end)
end

makeButton(bd, "Fill Blueprints with Selected Wood", function()
    task.spawn(fillBlueprints, fillSpeed, buildOwner)
end)
makeButton(bd, "Deselect All", deselectAll)

sep(bd)
sectionLabel(bd, "Blueprints")
makeButton(bd, "Destroy Selected Blueprints", function()
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Selection" and v.Parent and v.Parent.Name == "BuildDependentWood" then
            pcall(function()
                RS.Interaction.DestroyStructure:FireServer(v.Parent.Parent)
            end)
            task.wait(1)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- VEHICLE TAB  (pages["VehicleTab"])
-- ═══════════════════════════════════════════════════════════════════════════

local vh = pages["VehicleTab"]

local vFlyEnabled  = false
local vFlySpeed    = 1
local VFLY         = false
local vflyBV, vflyBG, vflyConn
local vflyKeyD, vflyKeyU

local function setVehicleSpeed(val)
    for _, v in next, workspace.PlayerModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP
           and v:FindFirstChild("Type") and v.Type.Value == "Vehicle"
           and v:FindFirstChild("Configuration") then
            pcall(function() v.Configuration.MaxSpeed.Value = val end)
        end
    end
end

local function stopVFly()
    VFLY = false
    if vflyConn then vflyConn:Disconnect(); vflyConn = nil end
    if vflyKeyD then vflyKeyD:Disconnect(); vflyKeyD = nil end
    if vflyKeyU then vflyKeyU:Disconnect(); vflyKeyU = nil end
    if vflyBV and vflyBV.Parent then vflyBV:Destroy(); vflyBV = nil end
    if vflyBG and vflyBG.Parent then vflyBG:Destroy(); vflyBG = nil end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function startVFly()
    stopVFly()
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    VFLY = true
    hum.PlatformStand = true
    vflyBV = Instance.new("BodyVelocity", root)
    vflyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
    vflyBV.Velocity = Vector3.zero
    vflyBG = Instance.new("BodyGyro", root)
    vflyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
    vflyBG.P = 9e4; vflyBG.D = 100

    local ctrl = {F=0,B=0,L=0,R=0}
    vflyKeyD = Mouse.KeyDown:Connect(function(key)
        local k = key:lower()
        if k=="w" then ctrl.F=1 elseif k=="s" then ctrl.B=-1
        elseif k=="a" then ctrl.L=-1 elseif k=="d" then ctrl.R=1 end
    end)
    vflyKeyU = Mouse.KeyUp:Connect(function(key)
        local k = key:lower()
        if k=="w" then ctrl.F=0 elseif k=="s" then ctrl.B=0
        elseif k=="a" then ctrl.L=0 elseif k=="d" then ctrl.R=0 end
    end)

    vflyConn = RunService.Heartbeat:Connect(function()
        if not VFLY then return end
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand = true end
        local cam = workspace.CurrentCamera.CoordinateFrame
        local speed = 50 * vFlySpeed
        local mv = ctrl.F+ctrl.B ~= 0 or ctrl.L+ctrl.R ~= 0
        if mv then
            vflyBV.Velocity = ((cam.lookVector*(ctrl.F+ctrl.B)) +
                ((cam*CFrame.new(ctrl.L+ctrl.R,0,0)).p - cam.p)) * speed
        else
            vflyBV.Velocity = Vector3.zero
        end
        vflyBG.CFrame = workspace.CurrentCamera.CoordinateFrame
    end)
end

local function carTP(targetCF)
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.Seated then return end
    local seat = hum.SeatPart
    if not seat then return end
    local car = seat.Parent
    if not (car:FindFirstChild("Type") and car.Type.Value == "Vehicle") then return end
    pcall(function()
        for _, part in pairs(car:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CFrame = targetCF + (part.CFrame.p - seat.CFrame.p)
            end
        end
    end)
end

local abortSpawner = false
local spawnColor   = nil
local spawnStat

local carColors = {
    "Medium stone grey","Sand green","Sand red","Faded green",
    "Dark grey metallic","Dark grey","Earth yellow","Earth orange",
    "Silver","Brick yellow","Dark red","Hot pink",
}

local function vehicleSpawner(color)
    if not color then return end
    abortSpawner = false
    spawnStat.SetActive(true, "Click your spawn pad...")

    local padConn; padConn = Mouse.Button1Up:Connect(function()
        local target = Mouse.Target
        if not target then return end
        local car = target.Parent
        if not (car:FindFirstChild("Owner") and car.Owner.Value == LP
            and car:FindFirstChild("Type") and car.Type.Value == "Vehicle Spot") then return end

        padConn:Disconnect()
        task.spawn(function()
            local found = false
            local t0 = tick()
            local newCar
            local conn = workspace.PlayerModels.ChildAdded:Connect(function(v)
                if v:FindFirstChild("Owner") and v.Owner.Value == LP
                   and v:FindFirstChild("Type") and v.Type.Value == "Vehicle" then
                    local pp = v:FindFirstDescendant("PaintPart") or v:FindFirstDescendant("Body")
                    if pp and pp.BrickColor.Name == color then
                        newCar = v; found = true
                    end
                end
            end)

            repeat
                if abortSpawner then break end
                pcall(function()
                    RS.Interaction.RemoteProxy:FireServer(target.Parent.ButtonRemote_SpawnButton)
                end)
                task.wait(1)
            until found or abortSpawner or tick()-t0 > 30

            conn:Disconnect()
            spawnStat.SetActive(false, found and "Car spawned!" or "Aborted.")
        end)
    end)
end

-- Vehicle UI
sectionLabel(vh, "Vehicle Controls")
makeSlider(vh, "Max Speed", 1, 200, 80, function(v)
    setVehicleSpeed(v)
end)

local vflyTog = makeToggle(vh, "Vehicle Fly (W/A/S/D)", false, function(v)
    vFlyEnabled = v
    if v then startVFly() else stopVFly() end
end)

makeSlider(vh, "Vehicle Fly Speed", 1, 20, 1, function(v)
    vFlySpeed = v
end)

sep(vh)
sectionLabel(vh, "Vehicle Teleport")

local playerNamesV = getPlayerNames()

local vTpPlayerDD = makeDropdown(vh, "Teleport to Player...", playerNamesV, function(val)
    for _, p in next, Players:GetPlayers() do
        if p.Name == val and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            carTP(p.Character.HumanoidRootPart.CFrame)
            break
        end
    end
end)

local vTpPlotDD = makeDropdown(vh, "Teleport to Player's Plot...", playerNamesV, function(val)
    for _, v in next, workspace.Properties:GetChildren() do
        if v:FindFirstChild("Owner") and tostring(v.Owner.Value) == val then
            carTP(v.OriginSquare.CFrame + Vector3.new(0,5,0))
            break
        end
    end
end)

Players.PlayerAdded:Connect(function()
    local n = getPlayerNames()
    vTpPlayerDD:SetOptions(n); vTpPlotDD:SetOptions(n)
end)
Players.PlayerRemoving:Connect(function()
    local n = getPlayerNames()
    vTpPlayerDD:SetOptions(n); vTpPlotDD:SetOptions(n)
end)

makeButton(vh, "Teleport Vehicle to My Position", function()
    carTP(LP.Character and LP.Character.HumanoidRootPart and LP.Character.HumanoidRootPart.CFrame
          or CFrame.new(0,0,0))
end)

sep(vh)
sectionLabel(vh, "Vehicle Spawner")

makeDropdown(vh, "Select Car Color...", carColors, function(val)
    spawnColor = val
end)

spawnStat = makeStatus(vh, "Select a color, then click Start")

makeButton(vh, "Start Vehicle Spawner", function()
    task.spawn(vehicleSpawner, spawnColor)
end)
makeButton(vh, "Abort Spawner", function()
    abortSpawner = true
    spawnStat.SetActive(false, "Aborted.")
end)

-- ── Cleanup ───────────────────────────────────────────────────────────────────
table.insert(VH.cleanupTasks, function()
    stopVFly()
    abortSpawner = true
    if lassoSG and lassoSG.Parent then lassoSG:Destroy() end
end)

print("[VanillaHub] Vanilla7 loaded — Build, Vehicle")
