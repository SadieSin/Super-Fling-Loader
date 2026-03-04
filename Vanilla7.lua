-- VanillaHub | Vanilla7 — Vehicle tab
-- NEW FILE — Vehicle Speed, TP to Player/Plot dropdowns, Vehicle Fly toggle+speed, Vehicle Spawner
-- Requires Vanilla1–3 to be loaded first

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

-- ── shared GUI helpers ────────────────────────────────────────────────────────
local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end
local function makeCorner(p, r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 6); return c end
local function makePadding(p,t,r,b,l)
    local x=Instance.new("UIPadding",p)
    x.PaddingTop=UDim.new(0,t or 6); x.PaddingRight=UDim.new(0,r or 8)
    x.PaddingBottom=UDim.new(0,b or 6); x.PaddingLeft=UDim.new(0,l or 8)
end
local function ripple(btn)
    local rip=Instance.new("ImageLabel",btn); rip.BackgroundTransparency=1
    rip.Image="rbxassetid://5028857084"; rip.ImageColor3=Color3.new(1,1,1)
    rip.ImageTransparency=0.7; rip.ScaleType=Enum.ScaleType.Slice
    rip.SliceCenter=Rect.new(24,24,276,276); rip.Size=UDim2.new(0,0,0,0)
    rip.Position=UDim2.new(0.5,0,0.5,0); rip.ZIndex=btn.ZIndex+1
    tween(rip,0.4,{Size=UDim2.new(2,0,2,0),Position=UDim2.new(-0.5,0,-0.5,0),ImageTransparency=1})
    game:GetService("Debris"):AddItem(rip,0.45)
end

local screenGui   = game:GetService("CoreGui"):FindFirstChild("VanillaHub")
local contentArea = screenGui.Main.ContentArea
local sidebar     = screenGui.Main.Sidebar

local function makeScrollPage()
    local scroll = Instance.new("ScrollingFrame", contentArea)
    scroll.Size=UDim2.new(1,0,1,0); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=Color3.fromRGB(120,80,140)
    scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.Visible=false
    local list=Instance.new("UIListLayout",scroll)
    list.SortOrder=Enum.SortOrder.LayoutOrder; list.Padding=UDim.new(0,6)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize=UDim2.new(0,0,0,list.AbsoluteContentSize.Y+12)
    end)
    makePadding(scroll,6,6,6,6)
    return scroll
end

local function makeTabBtn(name, icon)
    local btn=Instance.new("TextButton",sidebar)
    btn.Size=UDim2.new(1,0,0,28); btn.BackgroundColor3=BTN_COLOR
    btn.BackgroundTransparency=0.3; btn.BorderSizePixel=0
    btn.Text=(icon and icon.." " or "")..name; btn.TextColor3=Color3.fromRGB(180,180,190)
    btn.Font=Enum.Font.Gotham; btn.TextSize=11; btn.TextXAlignment=Enum.TextXAlignment.Left
    makePadding(btn,4,4,4,8); makeCorner(btn,5); btn.LayoutOrder=#VH.tabs+1; return btn
end

local function addTab(name, icon)
    local btn=makeTabBtn(name, icon); local page=makeScrollPage()
    table.insert(VH.tabs,{btn=btn,page=page})
    btn.MouseButton1Click:Connect(function() ripple(btn); VH.switchTab(page,btn) end)
    return page, btn
end

local function addSection(page, title)
    local frame=Instance.new("Frame",page)
    frame.Size=UDim2.new(1,-4,0,0); frame.BackgroundColor3=Color3.fromRGB(26,20,36)
    frame.BorderSizePixel=0; frame.AutomaticSize=Enum.AutomaticSize.Y; makeCorner(frame,7)
    local hdr=Instance.new("TextLabel",frame)
    hdr.Size=UDim2.new(1,0,0,22); hdr.BackgroundTransparency=1; hdr.Text=title
    hdr.TextColor3=THEME_TEXT; hdr.Font=Enum.Font.GothamBold; hdr.TextSize=11
    hdr.TextXAlignment=Enum.TextXAlignment.Left; makePadding(hdr,4,0,0,10)
    local list=Instance.new("UIListLayout",frame)
    list.SortOrder=Enum.SortOrder.LayoutOrder; list.Padding=UDim.new(0,4)
    local pad=Instance.new("UIPadding",frame)
    pad.PaddingTop=UDim.new(0,26); pad.PaddingBottom=UDim.new(0,6)
    pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6)
    frame.LayoutOrder=#page:GetChildren()
    return frame
end

local function addButton(section, text, color, callback)
    color=color or BTN_COLOR
    local btn=Instance.new("TextButton",section)
    btn.Size=UDim2.new(1,0,0,26); btn.BackgroundColor3=color; btn.BorderSizePixel=0
    btn.Text=text; btn.TextColor3=THEME_TEXT; btn.Font=Enum.Font.Gotham; btn.TextSize=11
    btn.LayoutOrder=#section:GetChildren(); makeCorner(btn,5)
    btn.MouseEnter:Connect(function() tween(btn,0.12,{BackgroundColor3=BTN_HOVER}) end)
    btn.MouseLeave:Connect(function() tween(btn,0.12,{BackgroundColor3=color}) end)
    btn.MouseButton1Click:Connect(function() ripple(btn); task.spawn(callback) end)
    return btn
end

local function addToggle(section, text, default, callback)
    local row=Instance.new("Frame",section)
    row.Size=UDim2.new(1,0,0,26); row.BackgroundTransparency=1; row.LayoutOrder=#section:GetChildren()
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-44,1,0); lbl.BackgroundTransparency=1; lbl.Text=text
    lbl.TextColor3=THEME_TEXT; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(0,36,0,18); track.Position=UDim2.new(1,-38,0.5,-9)
    track.BackgroundColor3=default and Color3.fromRGB(60,180,60) or BTN_COLOR
    track.BorderSizePixel=0; makeCorner(track,9)
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,14,0,14)
    knob.Position=default and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0; makeCorner(knob,7)
    local state=default
    local function setState(v)
        state=v
        tween(track,0.2,{BackgroundColor3=v and Color3.fromRGB(60,180,60) or BTN_COLOR})
        tween(knob,0.2,{Position=v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)})
        task.spawn(callback,v)
    end
    if default then task.spawn(callback,true) end
    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    btn.MouseButton1Click:Connect(function() setState(not state) end)
    return {setState=setState,getValue=function() return state end}
end

local function addSlider(section, text, min, max, default, callback)
    local frame=Instance.new("Frame",section)
    frame.Size=UDim2.new(1,0,0,38); frame.BackgroundTransparency=1; frame.LayoutOrder=#section:GetChildren()
    local lbl=Instance.new("TextLabel",frame)
    lbl.Size=UDim2.new(1,-50,0,16); lbl.BackgroundTransparency=1; lbl.Text=text
    lbl.TextColor3=THEME_TEXT; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local valLbl=Instance.new("TextLabel",frame)
    valLbl.Size=UDim2.new(0,46,0,16); valLbl.Position=UDim2.new(1,-46,0,0)
    valLbl.BackgroundTransparency=1; valLbl.Text=tostring(default)
    valLbl.TextColor3=Color3.fromRGB(180,160,200); valLbl.Font=Enum.Font.GothamBold
    valLbl.TextSize=11; valLbl.TextXAlignment=Enum.TextXAlignment.Right
    local track=Instance.new("Frame",frame)
    track.Size=UDim2.new(1,0,0,6); track.Position=UDim2.new(0,0,0,22)
    track.BackgroundColor3=Color3.fromRGB(40,40,55); track.BorderSizePixel=0; makeCorner(track,3)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(130,80,160); fill.BorderSizePixel=0; makeCorner(fill,3)
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,12,0,12); knob.Position=UDim2.new((default-min)/(max-min),0,0.5,-6)
    knob.BackgroundColor3=Color3.fromRGB(210,190,225); knob.BorderSizePixel=0; makeCorner(knob,6)
    local dragging=false
    local function update(x)
        local abs=track.AbsolutePosition.X; local w=track.AbsoluteSize.X
        local pct=math.clamp((x-abs)/w,0,1)
        local val=math.floor(min+(max-min)*pct+0.5)
        fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,0,0.5,-6)
        valLbl.Text=tostring(val); task.spawn(callback,val)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    task.spawn(callback,default)
    return frame
end

local function addDropdown(section, text, options, callback)
    local frame=Instance.new("Frame",section)
    frame.Size=UDim2.new(1,0,0,26); frame.BackgroundTransparency=1
    frame.LayoutOrder=#section:GetChildren(); frame.ClipsDescendants=false
    local lbl=Instance.new("TextLabel",frame)
    lbl.Size=UDim2.new(0.45,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=text
    lbl.TextColor3=THEME_TEXT; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local header=Instance.new("TextButton",frame)
    header.Size=UDim2.new(0.52,0,1,0); header.Position=UDim2.new(0.48,0,0,0)
    header.BackgroundColor3=BTN_COLOR; header.BorderSizePixel=0
    header.Text="Select..."; header.TextColor3=THEME_TEXT
    header.Font=Enum.Font.Gotham; header.TextSize=10; makeCorner(header,5)
    local open=false
    local listFrame=Instance.new("Frame",frame)
    listFrame.Size=UDim2.new(0.52,0,0,0); listFrame.Position=UDim2.new(0.48,0,1,2)
    listFrame.BackgroundColor3=Color3.fromRGB(30,24,40); listFrame.BorderSizePixel=0
    listFrame.ClipsDescendants=true; listFrame.ZIndex=10; makeCorner(listFrame,5)
    Instance.new("UIListLayout",listFrame).SortOrder=Enum.SortOrder.LayoutOrder
    local function setOptions(opts)
        for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for i,opt in ipairs(opts) do
            local item=Instance.new("TextButton",listFrame)
            item.Size=UDim2.new(1,0,0,24); item.BackgroundTransparency=1; item.Text=opt
            item.TextColor3=THEME_TEXT; item.Font=Enum.Font.Gotham; item.TextSize=10
            item.ZIndex=10; item.LayoutOrder=i
            item.MouseButton1Click:Connect(function()
                header.Text=opt; open=false
                tween(listFrame,0.15,{Size=UDim2.new(0.52,0,0,0)})
                task.spawn(callback,opt)
            end)
        end
    end
    setOptions(options)
    header.MouseButton1Click:Connect(function()
        open=not open
        local h=open and math.min(#options,5)*24 or 0
        tween(listFrame,0.2,{Size=UDim2.new(0.52,0,0,h)})
    end)
    return {setOptions=setOptions}
end

-- ── VEHICLE FUNCTIONS ─────────────────────────────────────────────────────────
local function setVehicleSpeed(val)
    pcall(function()
        for _, v in ipairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Owner") and v.Owner.Value == player then
                if v:FindFirstChild("Type") and v.Type.Value == "Vehicle" then
                    if v:FindFirstChild("Configuration") then
                        v.Configuration.MaxSpeed.Value = val
                    end
                end
            end
        end
    end)
end

-- TP vehicle (must be seated in vehicle) to a CFrame
local function carTP(targetCFrame)
    pcall(function()
        local humanoid = player.Character.Humanoid
        if not humanoid.Seated then return end
        local seat = humanoid.SeatPart
        if not seat then return end
        local vehicle = seat.Parent
        if not vehicle:FindFirstChild("Type") or vehicle.Type.Value ~= "Vehicle" then return end
        -- Move all vehicle parts
        local root = vehicle:FindFirstChild("DriveSeat") or seat
        local offset = targetCFrame:ToObjectSpace(root.CFrame)
        for _, part in ipairs(vehicle:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CFrame = targetCFrame * offset
            end
        end
        root.CFrame = targetCFrame
    end)
end

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(list, p.Name)
    end
    return list
end

-- Vehicle Fly (sFLY equivalent)
local vFLYING = false
local vFlyBG, vFlyBV, vFlyConn
local vFlyKeyDownConn, vFlyKeyUpConn
local vehicleFlySpeed = 50
local vCtrl = {F=0,B=0,L=0,R=0,Q=0,E=0}

local function stopVehicleFly()
    vFLYING = false
    if vFlyConn    then vFlyConn:Disconnect();        vFlyConn    = nil end
    if vFlyKeyDownConn then vFlyKeyDownConn:Disconnect(); vFlyKeyDownConn = nil end
    if vFlyKeyUpConn   then vFlyKeyUpConn:Disconnect();   vFlyKeyUpConn   = nil end
    if vFlyBG then vFlyBG:Destroy(); vFlyBG = nil end
    if vFlyBV then vFlyBV:Destroy(); vFlyBV = nil end
    pcall(function() player.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false end)
end

local function startVehicleFly()
    stopVehicleFly()
    pcall(function()
        local humanoid = player.Character.Humanoid
        if not humanoid.Seated then return end
        local seat = humanoid.SeatPart
        if not seat then return end
        vFLYING = true
        local T = seat
        vFlyBG = Instance.new("BodyGyro", T)
        vFlyBG.P = 9e4; vFlyBG.maxTorque = Vector3.new(9e9,9e9,9e9); vFlyBG.CFrame = T.CFrame
        vFlyBV = Instance.new("BodyVelocity", T)
        vFlyBV.MaxForce = Vector3.new(9e9,9e9,9e9); vFlyBV.Velocity = Vector3.new(0,0,0)

        local lCtrl = {F=0,B=0,L=0,R=0,Q=0,E=0}

        vFlyConn = RunService.Heartbeat:Connect(function()
            if not vFLYING then return end
            pcall(function()
                local cam = workspace.CurrentCamera
                local speed = vehicleFlySpeed
                local fwd  = vCtrl.F + vCtrl.B
                local side = vCtrl.L + vCtrl.R
                local vert = vCtrl.Q + vCtrl.E
                if fwd~=0 or side~=0 or vert~=0 then
                    vFlyBV.Velocity = (cam.CoordinateFrame.LookVector*fwd
                        + cam.CoordinateFrame.RightVector*side
                        + Vector3.new(0,1,0)*vert) * speed
                    lCtrl = {F=fwd,B=0,L=side,R=0,Q=vert,E=0}
                else
                    vFlyBV.Velocity = Vector3.new(0,0,0)
                end
                vFlyBG.CFrame = cam.CoordinateFrame
            end)
        end)

        local mouse = player:GetMouse()
        vFlyKeyDownConn = mouse.KeyDown:Connect(function(key)
            key = key:lower()
            if key=="w" then vCtrl.F=vehicleFlySpeed
            elseif key=="s" then vCtrl.B=-vehicleFlySpeed
            elseif key=="a" then vCtrl.L=-vehicleFlySpeed
            elseif key=="d" then vCtrl.R=vehicleFlySpeed
            elseif key=="e" then vCtrl.Q=vehicleFlySpeed*2
            elseif key=="q" then vCtrl.E=-vehicleFlySpeed*2
            end
        end)
        vFlyKeyUpConn = mouse.KeyUp:Connect(function(key)
            key = key:lower()
            if key=="w" then vCtrl.F=0
            elseif key=="s" then vCtrl.B=0
            elseif key=="a" then vCtrl.L=0
            elseif key=="d" then vCtrl.R=0
            elseif key=="e" then vCtrl.Q=0
            elseif key=="q" then vCtrl.E=0
            end
        end)
    end)
end

-- Vehicle Spawner
local AbortVehicleSpawner = false
local SelectedSpawnColor = nil
local spawnerMouseConn, spawnerCarConn

local CAR_COLORS = {
    "Medium stone grey","Sand green","Sand red","Faded green",
    "Dark grey metallic","Dark grey","Earth yellow","Earth orange",
    "Silver","Brick yellow","Dark red","Hot pink"
}

local function startVehicleSpawner()
    if not SelectedSpawnColor then return end
    AbortVehicleSpawner = false
    local mouse = player:GetMouse()
    local RespawnedColor = nil

    spawnerCarConn = workspace.PlayerModels.ChildAdded:Connect(function(v)
        if v:WaitForChild("Owner", 3) and v.Owner.Value == player then
            if v:WaitForChild("PaintParts", 3) then
                local part = v.PaintParts:WaitForChild("Part", 3)
                if part then RespawnedColor = part end
            end
        end
    end)

    spawnerMouseConn = mouse.Button1Up:Connect(function()
        local tgt = mouse.Target
        if not tgt then return end
        if tgt.Parent:FindFirstChild("Owner") and tgt.Parent.Owner.Value == player then
            if tgt.Parent:FindFirstChild("Type") and tgt.Parent.Type.Value == "Vehicle Spot" then
                local pad = tgt
                task.spawn(function()
                    repeat
                        if AbortVehicleSpawner then break end
                        RS.Interaction.RemoteProxy:FireServer(pad.Parent.ButtonRemote_SpawnButton)
                        task.wait(1)
                    until RespawnedColor and RespawnedColor.BrickColor.Name == SelectedSpawnColor
                    if spawnerMouseConn then spawnerMouseConn:Disconnect(); spawnerMouseConn = nil end
                    if spawnerCarConn   then spawnerCarConn:Disconnect();   spawnerCarConn   = nil end
                end)
            end
        end
    end)
end

local function abortVehicleSpawner()
    AbortVehicleSpawner = true
    if spawnerMouseConn then spawnerMouseConn:Disconnect(); spawnerMouseConn = nil end
    if spawnerCarConn   then spawnerCarConn:Disconnect();   spawnerCarConn   = nil end
end

addCleanup(function()
    stopVehicleFly()
    abortVehicleSpawner()
end)

-- ── VEHICLE TAB UI ────────────────────────────────────────────────────────────
local vehiclePage, vehicleBtn = addTab("Vehicle", "🚗")
do
    local plrList = getPlayerList()

    -- Vehicle section
    local vSec = addSection(vehiclePage, "Vehicle")

    addSlider(vSec, "Vehicle Speed", 1, 10, 1, function(v)
        setVehicleSpeed(v)
    end)

    local tpToPlayerDD = addDropdown(vSec, "TP Vehicle to Player", plrList, function(v)
        -- find target player character
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == v and p.Character then
                carTP(p.Character.HumanoidRootPart.CFrame)
                return
            end
        end
    end)

    local tpToPlotDD = addDropdown(vSec, "TP Vehicle to Plot", plrList, function(v)
        for _, prop in ipairs(workspace.Properties:GetChildren()) do
            if prop:FindFirstChild("Owner") and tostring(prop.Owner.Value) == v then
                carTP(prop.OriginSquare.CFrame + Vector3.new(5,2,0))
                return
            end
        end
    end)

    addToggle(vSec, "Vehicle Fly", false, function(v)
        if v then startVehicleFly() else stopVehicleFly() end
    end)

    addSlider(vSec, "Vehicle Fly Speed", 10, 250, 50, function(v)
        vehicleFlySpeed = v
    end)

    -- Vehicle Spawner section
    local spawnSec = addSection(vehiclePage, "Vehicle Spawner")

    addDropdown(spawnSec, "Car Color", CAR_COLORS, function(v)
        SelectedSpawnColor = v
    end)

    addButton(spawnSec, "Start Vehicle Spawner", Color3.fromRGB(35,90,45), function()
        startVehicleSpawner()
    end)

    addButton(spawnSec, "Abort Vehicle Spawner", Color3.fromRGB(90,35,35), function()
        abortVehicleSpawner()
    end)

    -- Update dropdowns when players join/leave
    local function updateVehicleDropdowns()
        local list = getPlayerList()
        tpToPlayerDD.setOptions(list)
        tpToPlotDD.setOptions(list)
    end
    local jc = Players.PlayerAdded:Connect(updateVehicleDropdowns)
    local lc = Players.PlayerRemoving:Connect(updateVehicleDropdowns)
    addCleanup(function() jc:Disconnect(); lc:Disconnect() end)
end

print("[VanillaHub] Vanilla7 loaded ✓")
