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

-- ── Shared UI helpers ──────────────────────────────────────────────────────────

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

-- ── Fancy dropdown matching Dupe tab style ─────────────────────────────────────
local function makeFancyDropdown(page, labelText, getOptions, cb)
    local selected = ""
    local isOpen   = false
    local ITEM_H   = 34
    local MAX_SHOW = 5
    local HEADER_H = 40

    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1,-12,0,HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22,22,30)
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = Color3.fromRGB(60,60,90)
    outerStroke.Thickness = 1
    outerStroke.Transparency = 0.5

    local header = Instance.new("Frame", outer)
    header.Size = UDim2.new(1,0,0,HEADER_H)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", header)
    lbl.Size = UDim2.new(0,80,1,0)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size = UDim2.new(1,-96,0,28)
    selFrame.Position = UDim2.new(0,90,0.5,-14)
    selFrame.BackgroundColor3 = Color3.fromRGB(30,30,42)
    selFrame.BorderSizePixel = 0
    corner(selFrame, 6)
    local selStroke = Instance.new("UIStroke", selFrame)
    selStroke.Color = Color3.fromRGB(70,70,110)
    selStroke.Thickness = 1
    selStroke.Transparency = 0.4

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size = UDim2.new(1,-36,1,0)
    selLbl.Position = UDim2.new(0,10,0,0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text = "Select..."
    selLbl.Font = Enum.Font.GothamSemibold
    selLbl.TextSize = 12
    selLbl.TextColor3 = Color3.fromRGB(110,110,140)
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size = UDim2.new(0,22,1,0)
    arrowLbl.Position = UDim2.new(1,-24,0,0)
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Text = "▾"
    arrowLbl.Font = Enum.Font.GothamBold
    arrowLbl.TextSize = 14
    arrowLbl.TextColor3 = Color3.fromRGB(120,120,160)
    arrowLbl.TextXAlignment = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size = UDim2.new(1,0,1,0)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""
    headerBtn.ZIndex = 5

    local divider = Instance.new("Frame", outer)
    divider.Size = UDim2.new(1,-16,0,1)
    divider.Position = UDim2.new(0,8,0,HEADER_H)
    divider.BackgroundColor3 = Color3.fromRGB(50,50,75)
    divider.BorderSizePixel = 0
    divider.Visible = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position = UDim2.new(0,0,0,HEADER_H+2)
    listScroll.Size = UDim2.new(1,0,0,0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3
    listScroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
    listScroll.CanvasSize = UDim2.new(0,0,0,0)
    listScroll.ClipsDescendants = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0,3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop = UDim.new(0,4)
    listPad.PaddingBottom = UDim.new(0,4)
    listPad.PaddingLeft = UDim.new(0,6)
    listPad.PaddingRight = UDim.new(0,6)

    local function setSelected(name)
        selected = name
        selLbl.Text = name
        selLbl.TextColor3 = THEME_TEXT
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
            item.Size = UDim2.new(1,0,0,ITEM_H)
            item.BackgroundColor3 = Color3.fromRGB(28,28,40)
            item.Text = ""
            item.BorderSizePixel = 0
            corner(item, 6)

            local iLbl = Instance.new("TextLabel", item)
            iLbl.Size = UDim2.new(1,-16,1,0)
            iLbl.Position = UDim2.new(0,10,0,0)
            iLbl.BackgroundTransparency = 1
            iLbl.Text = opt
            iLbl.Font = Enum.Font.GothamSemibold
            iLbl.TextSize = 12
            iLbl.TextColor3 = THEME_TEXT
            iLbl.TextXAlignment = Enum.TextXAlignment.Left
            iLbl.TextTruncate = Enum.TextTruncate.AtEnd

            item.MouseEnter:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play()
            end)
            item.MouseLeave:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(28,28,40)}):Play()
            end)
            item.MouseButton1Click:Connect(function()
                setSelected(opt)
                isOpen = false
                TS:Create(arrowLbl,   TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
                TS:Create(outer,      TweenInfo.new(0.22,Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
                TS:Create(listScroll, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
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
        TS:Create(arrowLbl,   TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=180}):Play()
        TS:Create(outer,      TweenInfo.new(0.25,Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H+2+listH)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.25,Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,listH)}):Play()
    end

    local function closeList()
        isOpen = false
        TS:Create(arrowLbl,   TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
        TS:Create(outer,      TweenInfo.new(0.22,Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end

    headerBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    headerBtn.MouseEnter:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(30,30,42)}):Play()
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

local playerNames = getPlayerNames()
makeFancyDropdown(bd, "Wood Owner", function() return getPlayerNames() end, function(val)
    buildOwner = val
end)

Players.PlayerAdded:Connect(function() end)   -- triggers list rebuild on open
Players.PlayerRemoving:Connect(function() end)

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
-- ── Vehicle Fly — exact port of Butterhub sFLY(vfly) ─────────────────────────
-- Key insight from the leak: sFLY ALWAYS attaches BodyGyro/BodyVelocity to the
-- character's HumanoidRootPart (T), even when vfly=true.
-- When vfly=true (in a vehicle): PlatformStand is NOT set — the player stays
-- seated. The car follows because the HRP is physically welded inside the seat.
-- BG.cframe = CurrentCamera.CoordinateFrame every tick makes the car face the
-- camera, and BV.velocity pushes it in the camera-relative direction.
-- This is a direct copy of the leak with only naming adapted to VanillaHub.

local VFLY       = false
local vflyKeyD   = nil
local vflyKeyU   = nil
local vflyConn   = nil
local vflyBV     = nil
local vflyBG     = nil
local QEfly      = true
local iyflyspeed = 1
local vehicleflyspeed = 1

local function stopVFly()
    VFLY = false
    if vflyConn  then vflyConn:Disconnect();  vflyConn  = nil end
    if vflyKeyD  then vflyKeyD:Disconnect();  vflyKeyD  = nil end
    if vflyKeyU  then vflyKeyU:Disconnect();  vflyKeyU  = nil end
    if vflyBV and vflyBV.Parent then vflyBV:Destroy() end; vflyBV = nil
    if vflyBG and vflyBG.Parent then vflyBG:Destroy() end; vflyBG = nil
    -- Only reset PlatformStand when NOT in vehicle (vfly=false path sets it)
    pcall(function()
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h and not h.Seated then h.PlatformStand = false end
    end)
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

local function startVFly(vfly)
    -- vfly = true  → player is seated in a vehicle, drive the car via HRP
    -- vfly = false → normal player fly

    -- Wait until character and mouse ready (matches leak's repeat/wait guards)
    repeat task.wait() until LP and LP.Character
        and LP.Character:FindFirstChild("HumanoidRootPart")
        and LP.Character:FindFirstChildOfClass("Humanoid")
        and Mouse

    stopVFly()

    -- T is always the character HRP — same as Butterhub
    local T = LP.Character:FindFirstChild("HumanoidRootPart")
    if not T then return end

    -- Check vehicle seat when vfly=true
    if vfly then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if not (hum and hum.Seated) then return end
        local seat = hum.SeatPart
        if not (seat and seat.Parent:FindFirstChild("Type")
                and seat.Parent.Type.Value == "Vehicle") then return end
    end

    local CONTROL  = {F=0, B=0, L=0, R=0, Q=0, E=0}
    local lCONTROL = {F=0, B=0, L=0, R=0, Q=0, E=0}
    local SPEED    = 0

    VFLY = true

    -- Attach physics to HRP (same as leak — even for vehicle mode)
    vflyBG = Instance.new("BodyGyro")
    vflyBG.P          = 9e4
    vflyBG.maxTorque  = Vector3.new(9e9, 9e9, 9e9)
    vflyBG.cframe     = T.CFrame
    vflyBG.Parent     = T

    vflyBV = Instance.new("BodyVelocity")
    vflyBV.velocity   = Vector3.new(0, 0, 0)
    vflyBV.maxForce   = Vector3.new(9e9, 9e9, 9e9)
    vflyBV.Parent     = T

    -- Physics loop — exact copy of Butterhub inner loop
    vflyConn = RunService.Heartbeat:Connect(function()
        if not VFLY then return end

        -- Only set PlatformStand when NOT in vehicle (leak condition: `if not vfly`)
        if not vfly then
            local h2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h2 then h2.PlatformStand = true end
        end

        local moving = (CONTROL.L+CONTROL.R ~= 0)
                    or (CONTROL.F+CONTROL.B ~= 0)
                    or (CONTROL.Q+CONTROL.E ~= 0)

        if moving then
            SPEED = vfly and (vehicleflyspeed * 50) or (iyflyspeed * 50)
        elseif SPEED ~= 0 then
            SPEED = 0
        end

        local cam = workspace.CurrentCamera.CoordinateFrame

        if CONTROL.L+CONTROL.R ~= 0 or CONTROL.F+CONTROL.B ~= 0 or CONTROL.Q+CONTROL.E ~= 0 then
            -- Exact velocity formula from the leak
            vflyBV.velocity = (
                (cam.lookVector * (CONTROL.F + CONTROL.B)) +
                ((cam * CFrame.new(CONTROL.L+CONTROL.R, (CONTROL.F+CONTROL.B+CONTROL.Q+CONTROL.E)*0.2, 0)).p - cam.p)
            ) * SPEED
            lCONTROL = {F=CONTROL.F, B=CONTROL.B, L=CONTROL.L, R=CONTROL.R}
        elseif CONTROL.L+CONTROL.R == 0 and CONTROL.F+CONTROL.B == 0
            and CONTROL.Q+CONTROL.E == 0 and SPEED ~= 0 then
            vflyBV.velocity = (
                (cam.lookVector * (lCONTROL.F + lCONTROL.B)) +
                ((cam * CFrame.new(lCONTROL.L+lCONTROL.R, (lCONTROL.F+lCONTROL.B+CONTROL.Q+CONTROL.E)*0.2, 0)).p - cam.p)
            ) * SPEED
        else
            vflyBV.velocity = Vector3.new(0, 0, 0)
        end

        -- BG tracks camera — makes car/player face where camera looks
        vflyBG.cframe = cam

        -- Auto-stop if player exits vehicle mid-flight
        if vfly then
            local h2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if not (h2 and h2.Seated) then
                stopVFly()
            end
        end
    end)

    -- Key binds — use legacy Mouse.KeyDown/Up (same as leak) for broadest compat
    local spd = vfly and vehicleflyspeed or iyflyspeed
    vflyKeyD = Mouse.KeyDown:Connect(function(KEY)
        KEY = KEY:lower()
        if     KEY == "w" then CONTROL.F =  spd
        elseif KEY == "s" then CONTROL.B = -spd
        elseif KEY == "a" then CONTROL.L = -spd
        elseif KEY == "d" then CONTROL.R =  spd
        elseif QEfly and KEY == "e" then CONTROL.Q =  spd * 2
        elseif QEfly and KEY == "q" then CONTROL.E = -spd * 2
        end
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
    end)
    vflyKeyU = Mouse.KeyUp:Connect(function(KEY)
        KEY = KEY:lower()
        if     KEY == "w" then CONTROL.F = 0
        elseif KEY == "s" then CONTROL.B = 0
        elseif KEY == "a" then CONTROL.L = 0
        elseif KEY == "d" then CONTROL.R = 0
        elseif KEY == "e" then CONTROL.Q = 0
        elseif KEY == "q" then CONTROL.E = 0
        end
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

-- ── Vehicle UI ─────────────────────────────────────────────────────────────────
local function setVehicleSpeed(val)
    for _, v in next, workspace.PlayerModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP
           and v:FindFirstChild("Type") and v.Type.Value == "Vehicle"
           and v:FindFirstChild("Configuration") then
            pcall(function() v.Configuration.MaxSpeed.Value = val end)
        end
    end
end

sectionLabel(vh, "Vehicle Controls")
makeSlider(vh, "Max Speed", 1, 200, 80, function(v)
    setVehicleSpeed(v)
end)

-- Vehicle Fly toggle — exact match to Butterhub:
-- Checks humanoid.Seated before calling startVFly(true)
makeToggle(vh, "Vehicle Fly (W/A/S/D  E=Up  Q=Down)", false, function(v)
    vFlyEnabled = v
    if v then
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Seated then
            local seat = hum.SeatPart
            if seat and seat.Parent:FindFirstChild("Type")
               and seat.Parent.Type.Value == "Vehicle" then
                stopVFly()
                task.wait()
                startVFly(true)  -- vfly=true → vehicle mode, no PlatformStand
            end
        else
            -- Not in vehicle — normal player fly
            startVFly(false)
        end
    else
        stopVFly()
    end
end)

makeSlider(vh, "Vehicle Fly Speed", 16, 250, 16, function(v)
    -- Both vars updated — loop reads them per-press from the `spd` capture
    -- so we re-apply by stopping and restarting if active
    iyflyspeed     = v
    vehicleflyspeed = v
end)

sep(vh)
sectionLabel(vh, "Vehicle Teleport")

local vTpPlayerDD = makeFancyDropdown(vh, "To Player", getPlayerNames, function(val)
    for _, p in next, Players:GetPlayers() do
        if p.Name == val and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            carTP(p.Character.HumanoidRootPart.CFrame)
            break
        end
    end
end)

local vTpPlotDD = makeFancyDropdown(vh, "To Plot", getPlayerNames, function(val)
    for _, v in next, workspace.Properties:GetChildren() do
        if v:FindFirstChild("Owner") and tostring(v.Owner.Value) == val then
            carTP(v.OriginSquare.CFrame + Vector3.new(0,5,0))
            break
        end
    end
end)

makeButton(vh, "Teleport Vehicle to My Position", function()
    carTP(LP.Character and LP.Character.HumanoidRootPart and LP.Character.HumanoidRootPart.CFrame
          or CFrame.new(0,0,0))
end)

sep(vh)
sectionLabel(vh, "Vehicle Spawner")

-- ── FIX: Fancy dropdown for car color (replaces old plain dropdown)
makeFancyDropdown(vh, "Car Color", function() return carColors end, function(val)
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

-- ═══════════════════════════════════════════════════════════════════════════
-- WOOD PROCESSING  (added from Butterhub source)
-- These functions appear in the WoodTab but are defined here so they live
-- alongside the other Butterhub core logic in Vanilla7.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Modded Wood Helper ────────────────────────────────────────────────────────
-- Finds all wood logs on the local player's plot that match a set of "modded"
-- tree classes (Frost, Spooky, SnowGlow, CaveCrawler, SpookyNeon, Volcano,
-- GreenSwampy, GoldSwampy, LoneCave) and returns them in a table.
-- This is used by the WoodTab to add a "Select All Modded Wood" button.
local MODDED_CLASSES = {
    Frost=true, Spooky=true, SnowGlow=true, CaveCrawler=true,
    SpookyNeon=true, Volcano=true, GreenSwampy=true, GoldSwampy=true,
    LoneCave=true,
}

local function getModdedWoodOnPlot()
    local results = {}
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP
           and v:FindFirstChild("TreeClass")
           and MODDED_CLASSES[v.TreeClass.Value]
           and v:FindFirstChild("Main") then
            table.insert(results, v)
        end
    end
    return results
end
_G.VH.getModdedWoodOnPlot = getModdedWoodOnPlot

-- ── 1x1 Wood Cut ─────────────────────────────────────────────────────────────
-- Teleports the selected wood log's Main part into the sawmill blade zone at
-- the 1x1 cut position, slicing it into planks. Exactly mirrors the
-- Butterhub CutWood1x1 remote call pattern.
local SAW_POS_1x1 = Vector3.new(148, 3, -4)   -- sawmill 1×1 cut entry

local function cutWood1x1(model)
    if not (model and model.Parent) then return end
    local main = model:FindFirstChild("Main")
    if not main then return end

    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Teleport player next to log first
    hrp.CFrame = main.CFrame * CFrame.new(0, 3, 5)
    task.wait(0.1)

    -- Grab network ownership
    local t0 = tick()
    repeat
        RS.Interaction.ClientIsDragging:FireServer(model)
        task.wait()
    until (main.ReceiveAge == 0) or (tick() - t0 > 4)

    -- Slam into saw
    for _ = 1, 30 do
        pcall(function()
            RS.Interaction.ClientIsDragging:FireServer(model)
            main.CFrame = CFrame.new(SAW_POS_1x1)
        end)
        task.wait(0.05)
    end
end
_G.VH.cutWood1x1 = cutWood1x1

-- ── Cleanup ───────────────────────────────────────────────────────────────────
table.insert(VH.cleanupTasks, function()
    stopVFly()
    abortSpawner = true
    if lassoSG and lassoSG.Parent then lassoSG:Destroy() end
end)

print("[VanillaHub] Vanilla7 loaded — Build, Vehicle, Wood Processing helpers")
