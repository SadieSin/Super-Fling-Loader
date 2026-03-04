-- VanillaHub | Vanilla2 — World tab (updated) + Dupe tab
-- Requires Vanilla1 to be loaded first (_G.VH must exist)

repeat task.wait() until _G.VH
local VH = _G.VH
local Players      = VH.Players
local TweenService = VH.TweenService
local RunService   = VH.RunService
local UIS          = VH.UserInputService
local RS           = game:GetService("ReplicatedStorage")
local player       = VH.player

local BTN_COLOR  = VH.BTN_COLOR
local BTN_HOVER  = VH.BTN_HOVER
local THEME_TEXT = VH.THEME_TEXT

local function addCleanup(fn) table.insert(VH.cleanupTasks, fn) end

-- ── reuse GUI builders from VH (shared helpers re-implemented here) ──────────
local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner", parent); c.CornerRadius = UDim.new(0, radius or 6); return c
end

local function makePadding(parent, t, r, b, l)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop    = UDim.new(0, t or 6)
    p.PaddingRight  = UDim.new(0, r or 8)
    p.PaddingBottom = UDim.new(0, b or 6)
    p.PaddingLeft   = UDim.new(0, l or 8)
end

local function ripple(btn)
    local rip = Instance.new("ImageLabel", btn)
    rip.BackgroundTransparency = 1; rip.Image = "rbxassetid://5028857084"
    rip.ImageColor3 = Color3.new(1,1,1); rip.ImageTransparency = 0.7
    rip.ScaleType = Enum.ScaleType.Slice; rip.SliceCenter = Rect.new(24,24,276,276)
    rip.Size = UDim2.new(0,0,0,0); rip.Position = UDim2.new(0.5,0,0.5,0)
    rip.ZIndex = btn.ZIndex + 1
    tween(rip, 0.4, {Size=UDim2.new(2,0,2,0), Position=UDim2.new(-0.5,0,-0.5,0), ImageTransparency=1})
    game:GetService("Debris"):AddItem(rip, 0.45)
end

local contentArea = VH.tabs and VH.tabs[1] and VH.tabs[1].page.Parent

-- find real content area
local screenGui = game:GetService("CoreGui"):FindFirstChild("VanillaHub")
contentArea = screenGui and screenGui.Main and screenGui.Main.ContentArea

local sidebar = screenGui and screenGui.Main and screenGui.Main.Sidebar

local function makeScrollPage()
    local scroll = Instance.new("ScrollingFrame", contentArea)
    scroll.Size = UDim2.new(1,0,1,0); scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(120,80,140)
    scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.Visible = false
    local list = Instance.new("UIListLayout", scroll)
    list.SortOrder = Enum.SortOrder.LayoutOrder; list.Padding = UDim.new(0,6)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y+12)
    end)
    makePadding(scroll, 6,6,6,6)
    return scroll
end

local function makeTabBtn(name, icon)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1,0,0,28); btn.BackgroundColor3 = BTN_COLOR
    btn.BackgroundTransparency = 0.3; btn.BorderSizePixel = 0
    btn.Text = (icon and icon.." " or "") .. name
    btn.TextColor3 = Color3.fromRGB(180,180,190)
    btn.Font = Enum.Font.Gotham; btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    makePadding(btn, 4,4,4,8); makeCorner(btn, 5)
    btn.LayoutOrder = #VH.tabs + 1
    return btn
end

local function addTab(name, icon)
    local btn  = makeTabBtn(name, icon)
    local page = makeScrollPage()
    table.insert(VH.tabs, {btn=btn, page=page})
    btn.MouseButton1Click:Connect(function() ripple(btn); VH.switchTab(page, btn) end)
    return page, btn
end

local function addSection(page, title)
    local frame = Instance.new("Frame", page)
    frame.Size = UDim2.new(1,-4,0,0); frame.BackgroundColor3 = Color3.fromRGB(26,20,36)
    frame.BorderSizePixel = 0; frame.AutomaticSize = Enum.AutomaticSize.Y
    makeCorner(frame, 7)
    local hdr = Instance.new("TextLabel", frame)
    hdr.Size = UDim2.new(1,0,0,22); hdr.BackgroundTransparency = 1
    hdr.Text = title; hdr.TextColor3 = THEME_TEXT
    hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 11
    hdr.TextXAlignment = Enum.TextXAlignment.Left; makePadding(hdr, 4,0,0,10)
    local list = Instance.new("UIListLayout", frame)
    list.SortOrder = Enum.SortOrder.LayoutOrder; list.Padding = UDim.new(0,4)
    local pad = Instance.new("UIPadding", frame)
    pad.PaddingTop=UDim.new(0,26); pad.PaddingBottom=UDim.new(0,6)
    pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6)
    frame.LayoutOrder = #page:GetChildren()
    return frame
end

local function addButton(section, text, color, callback)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", section)
    btn.Size = UDim2.new(1,0,0,26); btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0; btn.Text = text; btn.TextColor3 = THEME_TEXT
    btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.LayoutOrder = #section:GetChildren()
    makeCorner(btn, 5)
    btn.MouseEnter:Connect(function() tween(btn,0.12,{BackgroundColor3=BTN_HOVER}) end)
    btn.MouseLeave:Connect(function() tween(btn,0.12,{BackgroundColor3=color}) end)
    btn.MouseButton1Click:Connect(function() ripple(btn); task.spawn(callback) end)
    return btn
end

local function addToggle(section, text, default, callback)
    local row = Instance.new("Frame", section)
    row.Size = UDim2.new(1,0,0,26); row.BackgroundTransparency = 1; row.LayoutOrder = #section:GetChildren()
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-44,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = THEME_TEXT; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(0,36,0,18); track.Position = UDim2.new(1,-38,0.5,-9)
    track.BackgroundColor3 = default and Color3.fromRGB(60,180,60) or BTN_COLOR; track.BorderSizePixel = 0
    makeCorner(track, 9)
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = default and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0; makeCorner(knob, 7)
    local state = default
    local function setState(v)
        state = v
        tween(track, 0.2, {BackgroundColor3 = v and Color3.fromRGB(60,180,60) or BTN_COLOR})
        tween(knob,  0.2, {Position = v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)})
        task.spawn(callback, v)
    end
    if default then task.spawn(callback, true) end
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Click:Connect(function() setState(not state) end)
    return {setState=setState, getValue=function() return state end}
end

local function addDropdown(section, text, options, callback)
    local frame = Instance.new("Frame", section)
    frame.Size = UDim2.new(1,0,0,26); frame.BackgroundTransparency = 1
    frame.LayoutOrder = #section:GetChildren(); frame.ClipsDescendants = false
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.45,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = THEME_TEXT; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local header = Instance.new("TextButton", frame)
    header.Size = UDim2.new(0.52,0,1,0); header.Position = UDim2.new(0.48,0,0,0)
    header.BackgroundColor3 = BTN_COLOR; header.BorderSizePixel = 0
    header.Text = "Select..."; header.TextColor3 = THEME_TEXT
    header.Font = Enum.Font.Gotham; header.TextSize = 10; makeCorner(header, 5)
    local open = false
    local listFrame = Instance.new("Frame", frame)
    listFrame.Size = UDim2.new(0.52,0,0,0); listFrame.Position = UDim2.new(0.48,0,1,2)
    listFrame.BackgroundColor3 = Color3.fromRGB(30,24,40); listFrame.BorderSizePixel = 0
    listFrame.ClipsDescendants = true; listFrame.ZIndex = 10; makeCorner(listFrame, 5)
    Instance.new("UIListLayout", listFrame).SortOrder = Enum.SortOrder.LayoutOrder
    local function setOptions(opts)
        for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for i, opt in ipairs(opts) do
            local item = Instance.new("TextButton", listFrame)
            item.Size = UDim2.new(1,0,0,24); item.BackgroundTransparency = 1
            item.Text = opt; item.TextColor3 = THEME_TEXT
            item.Font = Enum.Font.Gotham; item.TextSize = 10; item.ZIndex = 10; item.LayoutOrder = i
            item.MouseButton1Click:Connect(function()
                header.Text = opt; open = false
                tween(listFrame, 0.15, {Size=UDim2.new(0.52,0,0,0)})
                task.spawn(callback, opt)
            end)
        end
    end
    setOptions(options)
    header.MouseButton1Click:Connect(function()
        open = not open
        local h = open and math.min(#options,5)*24 or 0
        tween(listFrame, 0.2, {Size=UDim2.new(0.52,0,0,h)})
    end)
    return {setOptions=setOptions}
end

-- ── world functions ──────────────────────────────────────────────────────────
local AlwaysDay, AlwaysNight, NoFog = false, false, false

local lightConn = game.Lighting.Changed:Connect(function()
    if AlwaysDay and not AlwaysNight then
        game.Lighting.TimeOfDay = "12:00:00"
        game.Lighting.Ambient = Color3.new(1,1,1)
        game.Lighting.ColorShift_Bottom = Color3.new(1,1,1)
        game.Lighting.ColorShift_Top = Color3.new(1,1,1)
    end
    if AlwaysNight and not AlwaysDay then
        game.Lighting.TimeOfDay = "00:00:00"
    end
    if NoFog then
        game.Lighting.FogEnd = 100000
        game.Lighting.FogStart = 100000
    end
end)
addCleanup(function() lightConn:Disconnect() end)

local function walkOnWater(val)
    pcall(function()
        for _, v in ipairs(workspace.Water:GetChildren()) do
            if v.Name == "Water" then v.CanCollide = val end
        end
    end)
end

local function removeWater(val)
    pcall(function()
        for _, v in ipairs(workspace.Water:GetChildren()) do
            if v.Name == "Water" then v.Transparency = val and 1 or 0 end
        end
    end)
end

local function bridgeDown(val)
    pcall(function()
        for _, v in ipairs(workspace.Bridge.VerticalLiftBridge.Lift:GetChildren()) do
            v.CFrame = v.CFrame + Vector3.new(0, val and -26 or 26, 0)
        end
    end)
end

local function betterGraphics()
    pcall(function()
        local light = game.Lighting
        light:ClearAllChildren()
        local cc = Instance.new("ColorCorrectionEffect", light)
        cc.Enabled = true; cc.Contrast = 0.15; cc.Brightness = 0.1
        cc.Saturation = 0.25; cc.TintColor = Color3.fromRGB(255,222,211)
        local bloom = Instance.new("BloomEffect", light)
        bloom.Enabled = true; bloom.Intensity = 1; bloom.Size = 32; bloom.Threshold = 1
        local sun = Instance.new("SunRaysEffect", light)
        sun.Enabled = true; sun.Intensity = 0.2; sun.Spread = 1
        local blur = Instance.new("BlurEffect", light)
        blur.Enabled = true; blur.Size = 3
        light.OutdoorAmbient = Color3.fromRGB(112,117,128)
        light.Outlines = false
    end)
end

local function betterWater()
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Part") and v.Name == "SeaSand" then
                v.Size = Vector3.new(2048,60,2048)
            end
        end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Part") and v.Name == "Water" then
                v.Size = Vector3.new(20480,6,20080)
                workspace.Terrain:FillBlock(v.CFrame, v.Size, Enum.Material.Water)
                v:Destroy()
            end
        end
    end)
end

-- player list helpers
local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(list, p.Name)
    end
    return list
end

local function teleportToPlayer(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == name and p.Character then
            pcall(function()
                player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame + Vector3.new(2,0,0)
            end)
            return
        end
    end
end

local function teleportToBase(name)
    for _, v in ipairs(workspace.Properties:GetChildren()) do
        if v:FindFirstChild("Owner") and tostring(v.Owner.Value) == name then
            pcall(function()
                player.Character.HumanoidRootPart.CFrame = v.OriginSquare.CFrame + Vector3.new(0,2,0)
            end)
            return
        end
    end
end

-- Dupe (item teleport between players)
local function getPlayerPlot(plrName)
    for _, v in ipairs(workspace.Properties:GetChildren()) do
        if v:FindFirstChild("Owner") and tostring(v.Owner.Value) == plrName then
            return v
        end
    end
end

local function dupeItems(giverName, receiverName, options)
    task.spawn(function()
        local receiverPlot = getPlayerPlot(receiverName)
        if not receiverPlot then return end
        local dest = receiverPlot.OriginSquare.CFrame + Vector3.new(0, 2, 0)
        for _, model in ipairs(workspace.PlayerModels:GetChildren()) do
            if model:FindFirstChild("Owner") and tostring(model.Owner.Value) == giverName then
                local hasStructure  = model:FindFirstChild("Type") and model.Type.Value == "Structure"
                local hasTruck      = model:FindFirstChild("Type") and model.Type.Value == "Vehicle"
                local hasFurniture  = model:FindFirstChild("Type") and (model.Type.Value == "Furniture" or model.Type.Value == "Item")
                local hasWood       = model:FindFirstChild("WoodSection") ~= nil
                local mp = model:FindFirstChild("Main") or model.PrimaryPart
                if not mp then continue end
                if (options.structures and hasStructure) or (options.furniture and hasFurniture)
                or (options.items and not hasStructure and not hasFurniture and not hasTruck and not hasWood)
                or (options.wood and hasWood) then
                    pcall(function()
                        player.Character.HumanoidRootPart.CFrame = mp.CFrame * CFrame.new(0,4,2)
                        task.wait(0.1)
                        RS.Interaction.ClientIsDragging:FireServer(model)
                        task.wait(0.1)
                        if not model.PrimaryPart then model.PrimaryPart = mp end
                        model:SetPrimaryPartCFrame(dest)
                        task.wait(0.3)
                    end)
                elseif options.trucks and hasTruck then
                    pcall(function()
                        -- tween truck to destination
                        local ts = TweenService
                        ts:Create(mp, TweenInfo.new(2.0, Enum.EasingStyle.Linear), {CFrame=dest}):Play()
                        task.wait(2.2)
                    end)
                end
            end
        end
    end)
end

-- ── WORLD TAB ────────────────────────────────────────────────────────────────
local worldPage, worldBtn = addTab("World", "🌍")
do
    local plrList = getPlayerList()

    -- Teleports section
    local tpSec = addSection(worldPage, "Teleports")

    local waypointNames = {
        "Spawn","Wood Dropoff","Land Store","Wood RUs","Safari","Bridge","Bob's Shack",
        "EndTimes Cave","The Swamp","The Cabin","Volcano","Boxed Cars","Tiaga Peak",
        "Link's Logic","Palm Island","Palm Island 2","Palm Island 3","Fine Art Shop",
        "SnowGlow Biome","Cave","Shrine Of Sight","Fancy Furnishings","Docks",
        "Strange Man","Snow Biome","Green Box","Cherry Meadow","Bird Cave","The Den","Lighthouse"
    }
    local WAYPOINTS_POS = {
        ["Spawn"]=CFrame.new(172,2,74),["Wood Dropoff"]=CFrame.new(323.406,-2.8,134.734),
        ["Land Store"]=CFrame.new(258,5,-99),["Wood RUs"]=CFrame.new(265,5,57),
        ["Safari"]=CFrame.new(111.853,11,-998.805),["Bridge"]=CFrame.new(112.308,11,-782.358),
        ["Bob's Shack"]=CFrame.new(260,8,-2542),["EndTimes Cave"]=CFrame.new(113,-214,-951),
        ["The Swamp"]=CFrame.new(-1209,132,-801),["The Cabin"]=CFrame.new(1244,66,2306),
        ["Volcano"]=CFrame.new(-1585,625,1140),["Boxed Cars"]=CFrame.new(509,5.2,-1463),
        ["Tiaga Peak"]=CFrame.new(1560,410,3274),["Link's Logic"]=CFrame.new(4605,3,-727),
        ["Palm Island"]=CFrame.new(2549,-5,-42),["Palm Island 2"]=CFrame.new(1960,-5.9,-1501),
        ["Palm Island 3"]=CFrame.new(4344,-5.9,-1813),["Fine Art Shop"]=CFrame.new(5207,-166,719),
        ["SnowGlow Biome"]=CFrame.new(-1086.85,-5.9,-945.316),["Cave"]=CFrame.new(3581,-179,430),
        ["Shrine Of Sight"]=CFrame.new(-1600,195,919),["Fancy Furnishings"]=CFrame.new(491,13,-1720),
        ["Docks"]=CFrame.new(1114,3.2,-197),["Strange Man"]=CFrame.new(1061,20,1131),
        ["Snow Biome"]=CFrame.new(889.955,59.8,1195.55),["Green Box"]=CFrame.new(-1668.05,351.174,1475.39),
        ["Cherry Meadow"]=CFrame.new(220.9,59.8,1305.8),["Bird Cave"]=CFrame.new(4813.1,33.5,-978.8),
        ["The Den"]=CFrame.new(323,49,1930),["Lighthouse"]=CFrame.new(1464.8,356.3,3257.2),
    }

    local waypointDD = addDropdown(tpSec, "Teleport to Waypoint", waypointNames, function(v)
        pcall(function() player.Character.HumanoidRootPart.CFrame = WAYPOINTS_POS[v] end)
    end)

    local toPlayerDD = addDropdown(tpSec, "Teleport to Player", plrList, function(v)
        teleportToPlayer(v)
    end)

    local toBaseDD = addDropdown(tpSec, "Teleport to Base", plrList, function(v)
        teleportToBase(v)
    end)

    -- update dropdowns when players join/leave
    local function updatePlayerLists()
        local list = getPlayerList()
        toPlayerDD.setOptions(list)
        toBaseDD.setOptions(list)
    end
    local joinConn  = Players.PlayerAdded:Connect(updatePlayerLists)
    local leaveConn = Players.PlayerRemoving:Connect(updatePlayerLists)
    addCleanup(function() joinConn:Disconnect(); leaveConn:Disconnect() end)

    -- World section
    local worldSec = addSection(worldPage, "World")

    addToggle(worldSec, "Always Day", false, function(v)
        AlwaysDay = v; if v then AlwaysNight = false end
    end)
    addToggle(worldSec, "Always Night", false, function(v)
        AlwaysNight = v; if v then AlwaysDay = false end
    end)
    addToggle(worldSec, "No Fog", false, function(v)
        NoFog = v
        if v then game.Lighting.FogEnd = 100000; game.Lighting.FogStart = 100000 end
    end)
    addToggle(worldSec, "Shadows", true, function(v)
        game.Lighting.GlobalShadows = v
    end)
    addToggle(worldSec, "Bridge (Lower)", false, function(v)
        bridgeDown(v)
    end)
    addButton(worldSec, "Better Graphics", Color3.fromRGB(35,55,100), betterGraphics)

    -- Water section
    local waterSec = addSection(worldPage, "Water")
    addButton(waterSec, "Better Water", Color3.fromRGB(35,55,100), betterWater)
    addToggle(waterSec, "Walk On Water", false, function(v) walkOnWater(v) end)
    addToggle(waterSec, "Remove Water", false, function(v) removeWater(v) end)
end

-- ── DUPE TAB ─────────────────────────────────────────────────────────────────
local dupePage, dupeBtn = addTab("Dupe", "📋")
do
    local giverName, receiverName = "", ""
    local plrList = getPlayerList()

    local dupeOpts = {
        structures = false,
        furniture  = false,
        trucks     = false,
        items      = false,
        wood       = false,
    }

    local giverSec = addSection(dupePage, "Players")

    local giverDD = addDropdown(giverSec, "Giver", plrList, function(v) giverName = v end)
    local recvDD  = addDropdown(giverSec, "Receiver", plrList, function(v) receiverName = v end)

    local optSec = addSection(dupePage, "Transfer Options")
    addToggle(optSec, "Structures", false, function(v) dupeOpts.structures = v end)
    addToggle(optSec, "Furniture", false, function(v) dupeOpts.furniture = v end)
    addToggle(optSec, "Trucks", false, function(v) dupeOpts.trucks = v end)
    addToggle(optSec, "Purchased Items", false, function(v) dupeOpts.items = v end)
    addToggle(optSec, "Wood", false, function(v) dupeOpts.wood = v end)

    local actSec = addSection(dupePage, "Actions")
    addButton(actSec, "Start Transfer", Color3.fromRGB(35,90,45), function()
        if giverName == "" or receiverName == "" then return end
        dupeItems(giverName, receiverName, dupeOpts)
    end)

    -- Single truck TP
    local truckSec = addSection(dupePage, "Truck Teleport")
    local truckDestPlayer = ""
    local truckDestDD = addDropdown(truckSec, "Teleport Truck To", plrList, function(v) truckDestPlayer = v end)
    addButton(truckSec, "Teleport My Truck", Color3.fromRGB(35,55,100), function()
        task.spawn(function()
            local destPlot = getPlayerPlot(truckDestPlayer)
            if not destPlot then return end
            local dest = destPlot.OriginSquare.CFrame + Vector3.new(5,2,0)
            pcall(function()
                local humanoid = player.Character.Humanoid
                if humanoid.Seated then
                    local seat = humanoid.SeatPart
                    if seat and seat.Parent:FindFirstChild("Type") and seat.Parent.Type.Value == "Vehicle" then
                        local vehicleModel = seat.Parent
                        for _, part in ipairs(vehicleModel:GetDescendants()) do
                            if part:IsA("BasePart") then
                                TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Linear), {CFrame = dest}):Play()
                            end
                        end
                        task.wait(2.2)
                    end
                end
            end)
        end)
    end)

    -- update dropdowns when players join/leave
    local function updateDupeDropdowns()
        local list = getPlayerList()
        giverDD.setOptions(list)
        recvDD.setOptions(list)
        truckDestDD.setOptions(list)
    end
    local jc = Players.PlayerAdded:Connect(updateDupeDropdowns)
    local lc = Players.PlayerRemoving:Connect(updateDupeDropdowns)
    addCleanup(function() jc:Disconnect(); lc:Disconnect() end)
end

print("[VanillaHub] Vanilla2 loaded ✓")
