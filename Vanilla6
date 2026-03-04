-- VanillaHub | Vanilla6 — Slot tab
-- NEW FILE — Fast Load, Slot section, Land Claim (1-9)
-- Requires Vanilla1–3 to be loaded first

repeat task.wait() until _G.VH
local VH = _G.VH
local Players      = VH.Players
local TweenService = VH.TweenService
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

-- ── SLOT FUNCTIONS ─────────────────────────────────────────────────────────────
local skipLoading = false

local function getFreePlot()
    for _, v in ipairs(workspace.Properties:GetChildren()) do
        local owner = v:FindFirstChild("Owner")
        if owner and owner.Value == nil then return v end
    end
end

local function loadSlot(slot)
    task.spawn(function()
        pcall(function()
            local LoadSaveRequests = RS.LoadSaveRequests
            repeat task.wait() until LoadSaveRequests.ClientMayLoad:InvokeServer(player)
            LoadSaveRequests.RequestLoad:InvokeServer(slot, player)
        end)
    end)
end

local function freeLand()
    pcall(function()
        for _, v in ipairs(workspace.Properties:GetChildren()) do
            if v:FindFirstChild("Owner") and v.Owner.Value == nil then
                RS.PropertyPurchasing.ClientPurchasedProperty:FireServer(v, v.OriginSquare.Position)
                player.Character.HumanoidRootPart.CFrame = v.OriginSquare.CFrame + Vector3.new(0,2,0)
                break
            end
        end
    end)
end

local function maxLand()
    pcall(function()
        for _, d in ipairs(workspace.Properties:GetChildren()) do
            if d:FindFirstChild("Owner") and d:FindFirstChild("OriginSquare")
            and d.Owner.Value == player then
                local PlotPos = d.OriginSquare.Position
                local expand = RS.PropertyPurchasing.ClientExpandedProperty
                local offsets = {
                    Vector3.new(40,0,0), Vector3.new(-40,0,0),
                    Vector3.new(0,0,40), Vector3.new(0,0,-40),
                    Vector3.new(40,0,40), Vector3.new(40,0,-40),
                    Vector3.new(-40,0,40), Vector3.new(-40,0,-40),
                    Vector3.new(80,0,0), Vector3.new(-80,0,0),
                    Vector3.new(0,0,80), Vector3.new(0,0,-80),
                    Vector3.new(80,0,80), Vector3.new(80,0,-80),
                    Vector3.new(-80,0,80), Vector3.new(-80,0,-80),
                    Vector3.new(40,0,80), Vector3.new(-40,0,80),
                    Vector3.new(80,0,40), Vector3.new(80,0,-40),
                    Vector3.new(-80,0,40), Vector3.new(-80,0,-40),
                    Vector3.new(40,0,-80), Vector3.new(-40,0,-80),
                }
                for _, offset in ipairs(offsets) do
                    expand:FireServer(d, CFrame.new(PlotPos + offset))
                end
            end
        end
    end)
end

-- LandArt
local landArtClickConn, landArtMoveConn
local function landArt(val)
    if landArtClickConn then landArtClickConn:Disconnect(); landArtClickConn = nil end
    if landArtMoveConn  then landArtMoveConn:Disconnect();  landArtMoveConn  = nil end
    local folder = workspace:FindFirstChild("PlotFolder")
    if folder then folder:Destroy() end
    if not val then return end

    -- find player plot
    local plot = nil
    for _, v in ipairs(workspace.Properties:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == player then
            plot = v; break
        end
    end
    if not plot then return end

    local landVecs = {
        Vector3.new(40,0,0),Vector3.new(-40,0,0),Vector3.new(0,0,40),Vector3.new(0,0,-40),
        Vector3.new(40,0,40),Vector3.new(40,0,-40),Vector3.new(-40,0,40),Vector3.new(-40,0,-40),
        Vector3.new(80,0,0),Vector3.new(-80,0,0),Vector3.new(0,0,80),Vector3.new(0,0,-80),
        Vector3.new(80,0,80),Vector3.new(80,0,-80),Vector3.new(-80,0,80),Vector3.new(-80,0,-80),
        Vector3.new(40,0,80),Vector3.new(-40,0,80),Vector3.new(80,0,40),Vector3.new(80,0,-40),
        Vector3.new(-80,0,40),Vector3.new(-80,0,-40),Vector3.new(40,0,-80),Vector3.new(-40,0,-80),
    }

    local newFolder = Instance.new("Folder", workspace); newFolder.Name = "PlotFolder"
    local selection = Instance.new("SelectionBox", newFolder); selection.Name = "Selection"
    local mouse = player:GetMouse()

    for _, v in ipairs(landVecs) do
        local part = Instance.new("Part", newFolder)
        part.Name = "LandPreview"
        part.Transparency = 0.5
        part.CFrame = CFrame.new(plot.OriginSquare.Position + v)
        part.Size = plot.OriginSquare.Size
        part.Color = Color3.fromRGB(124,92,70)
        part.Material = Enum.Material.Concrete
        part.Anchored = true
        part.CanCollide = false
    end

    landArtMoveConn = mouse.Move:Connect(function()
        local tgt = mouse.Target
        if tgt and tgt:IsA("Part") and tgt.Name == "LandPreview" then
            selection.Adornee = tgt
        else
            selection.Adornee = nil
        end
    end)

    landArtClickConn = mouse.Button1Down:Connect(function()
        local tgt = mouse.Target
        if tgt and tgt:IsA("Part") and tgt.Name == "LandPreview" then
            RS.PropertyPurchasing.ClientExpandedProperty:FireServer(plot, CFrame.new(tgt.CFrame.p))
            tgt:Destroy()
        end
    end)
end

local function sellSoldSign()
    pcall(function()
        for _, v in ipairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Owner") and v.Owner.Value == player then
                if v:FindFirstChild("ItemName") and v.ItemName.Value == "PropertySoldSign" then
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(v.Main.CFrame.p) + Vector3.new(0,0,2)
                    RS.Interaction.ClientInteracted:FireServer(v, "Take down sold sign")
                    for i = 1, 30 do
                        RS.Interaction.ClientIsDragging:FireServer(v)
                        v.Main.CFrame = CFrame.new(314.54,-0.5,86.823)
                        task.wait()
                    end
                end
            end
        end
    end)
end

-- Land Claim
local selectedLandIdx = 1
local selectedLandHighlight = nil

local function selectLand(idx)
    selectedLandIdx = idx
    if selectedLandHighlight then selectedLandHighlight:Destroy(); selectedLandHighlight = nil end
    local props = workspace.Properties:GetChildren()
    local plot = props[idx]
    if plot and plot:FindFirstChild("OriginSquare") then
        selectedLandHighlight = Instance.new("Highlight")
        selectedLandHighlight.Parent = plot.OriginSquare
        selectedLandHighlight.FillColor = Color3.fromRGB(0,255,0)
        selectedLandHighlight.OutlineColor = Color3.fromRGB(0,200,0)
    end
end

local function takeLand()
    pcall(function()
        local props = workspace.Properties:GetChildren()
        local plot = props[selectedLandIdx]
        if not plot then return end
        RS.PropertyPurchasing.ClientPurchasedProperty:FireServer(plot, plot.OriginSquare.Position)
        player.Character.HumanoidRootPart.CFrame = plot.OriginSquare.CFrame + Vector3.new(0,2,0)
        task.wait(0.3)
        if selectedLandHighlight then selectedLandHighlight:Destroy(); selectedLandHighlight = nil end
    end)
end

-- ── SLOT TAB UI ───────────────────────────────────────────────────────────────
local slotPage, slotBtn = addTab("Slot", "💾")
do
    -- Fast Load section
    local fastSec = addSection(slotPage, "Fast Load")
    local slotNum = 1

    addSlider(fastSec, "Slot Number", 1, 6, 1, function(v) slotNum = v end)

    local fastToggle = addToggle(fastSec, "Fast Load", false, function(v)
        skipLoading = v
    end)

    addButton(fastSec, "Load Base", Color3.fromRGB(35,90,45), function()
        loadSlot(slotNum)
    end)

    -- Slot section
    local slotSec = addSection(slotPage, "Slot")

    addButton(slotSec, "Free Land", Color3.fromRGB(35,55,100), function()
        freeLand()
    end)

    addButton(slotSec, "Max Land", Color3.fromRGB(35,55,100), function()
        maxLand()
    end)

    addToggle(slotSec, "LandArt", false, function(v)
        landArt(v)
        addCleanup(function()
            if landArtClickConn then landArtClickConn:Disconnect() end
            if landArtMoveConn  then landArtMoveConn:Disconnect()  end
            local f = workspace:FindFirstChild("PlotFolder")
            if f then f:Destroy() end
        end)
    end)

    addButton(slotSec, "Sell Sold Sign", BTN_COLOR, function()
        sellSoldSign()
    end)

    -- Land Claim section
    local claimSec = addSection(slotPage, "Land Claim")

    addDropdown(claimSec, "Select Land (1-9)", {"1","2","3","4","5","6","7","8","9"}, function(v)
        selectLand(tonumber(v))
    end)

    addButton(claimSec, "Take Land", Color3.fromRGB(35,90,45), function()
        takeLand()
    end)
end

print("[VanillaHub] Vanilla6 loaded ✓")
