-- VanillaHub | Vanilla3 — AutoBuy tab (full) + Wood tab (full) + Search + Settings + Input Handler
-- Requires Vanilla1 + Vanilla2 to be loaded first

repeat task.wait() until _G.VH
local VH = _G.VH
local Players      = VH.Players
local TweenService = VH.TweenService
local RunService   = VH.RunService
local UIS          = VH.UserInputService
local RS           = game:GetService("ReplicatedStorage")
local player       = VH.player
local mouse        = player:GetMouse()

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
    return {setOptions=setOptions, getHeader=function() return header end}
end

-- ── AUTO BUY FUNCTIONS ────────────────────────────────────────────────────────
local AbortAutoBuy = false

local function getPing()
    local stats = game:GetService("Stats")
    return stats.Network.ServerStatsItem["Data Ping"].Value / 1000
end

local function isNetworkOwner(part)
    if not part then return false end
    local ok, result = pcall(function() return part:GetNetworkOwner() == player end)
    return ok and result
end

local function getPrice(item, amount)
    local price = 0
    for _, v in ipairs(RS.ClientItemInfo:GetDescendants()) do
        if v.Name == item and v:FindFirstChild("Price") then
            price = price + v.Price.Value * amount
        end
    end
    return price
end

local ShopIDS = {
    WoodRUs=7, FurnitureStore=8, FineArt=11, CarStore=9, LogicStore=12, ShackShop=10
}

local function getCounter(item)
    local closest = nil
    for _, v in ipairs(workspace.Stores:GetChildren()) do
        if v.Name:lower() ~= "shopitems" then
            for _, c in ipairs(v:GetChildren()) do
                if c.Name:lower() == "counter" then
                    if (item.CFrame.p - c.CFrame.p).Magnitude <= 200 then
                        closest = c
                    end
                end
            end
        end
    end
    return closest
end

local function pay(id)
    task.spawn(function()
        RS.NPCDialog.PlayerChatted:InvokeServer({ID=id, Character="name", Name="name", Dialog="Dialog"}, "ConfirmPurchase")
    end)
end

local function itemPath(itemName)
    for _, v in ipairs(workspace.Stores:GetChildren()) do
        if v.Name == "ShopItems" then
            for _, item in ipairs(v:GetChildren()) do
                if item:FindFirstChild("Owner") and item.Owner.Value == nil then
                    if item:FindFirstChild("BoxItemName") and item.BoxItemName.Value == itemName then
                        return item.Parent
                    end
                end
            end
        end
    end
end

local function grabShopItems()
    local list = {}
    for _, v in ipairs(workspace.Stores:GetChildren()) do
        if v.Name == "ShopItems" then
            for _, item in ipairs(v:GetChildren()) do
                if item:FindFirstChild("Type") and item.Type.Value ~= "Blueprint"
                and item:FindFirstChild("BoxItemName") then
                    local entry = item.BoxItemName.Value .. " - $" .. getPrice(item.BoxItemName.Value, 1)
                    if not table.find(list, entry) then
                        table.insert(list, entry)
                    end
                end
            end
        end
    end
    table.sort(list)
    return list
end

local function autoBuy(itemName, amount, openBox)
    if not itemName then return end
    AbortAutoBuy = false
    local oldPos = player.Character.HumanoidRootPart.CFrame
    local path = itemPath(itemName)
    if not path then return end

    for i = 1, amount do
        if AbortAutoBuy then break end
        local item = path:WaitForChild(itemName, 5)
        if not item then break end
        local counter = getCounter(item.Main)
        if not counter then break end

        player.Character.HumanoidRootPart.CFrame = item.Main.CFrame + Vector3.new(5,0,5)
        repeat RS.Interaction.ClientIsDragging:FireServer(item); task.wait() until item.Owner.Value ~= nil
        if item.Owner.Value ~= player then break end
        repeat RS.Interaction.ClientIsDragging:FireServer(item); task.wait() until isNetworkOwner(item.Main)
        RS.Interaction.ClientIsDragging:FireServer(item)
        pcall(function() item.Main.CFrame = counter.CFrame + Vector3.new(0, item.Main.Size.Y, 0.5) end)
        task.wait(getPing())
        pcall(function() player.Character.HumanoidRootPart.CFrame = counter.CFrame + Vector3.new(5,0,5) end)
        task.wait(getPing())
        repeat
            if AbortAutoBuy then break end
            RS.Interaction.ClientIsDragging:FireServer(item)
            pay(ShopIDS[counter.Parent.Name])
            task.wait()
        until item.Parent ~= path
        pcall(function()
            repeat RS.Interaction.ClientIsDragging:FireServer(item); task.wait() until isNetworkOwner(item.Main)
            RS.Interaction.ClientIsDragging:FireServer(item)
            item.Main.CFrame = oldPos
            task.wait(getPing())
        end)
        if openBox then
            RS.Interaction.ClientInteracted:FireServer(item, "Open box")
        end
        task.wait()
    end
    player.Character.HumanoidRootPart.CFrame = oldPos + Vector3.new(5,1,0)
end

local function getBlueprints()
    local list = {}
    for _, v in ipairs(RS.ClientItemInfo:GetDescendants()) do
        if v:IsA("ModuleScript") and not player.PlayerBlueprints.Blueprints:FindFirstChild(v.Name) then
            -- attempt autobuy of blueprints from shop
            for _, s in ipairs(workspace.Stores:GetChildren()) do
                if s.Name == "ShopItems" then
                    for _, item in ipairs(s:GetChildren()) do
                        if item:FindFirstChild("Type") and item.Type.Value == "Blueprint"
                        and item:FindFirstChild("BoxItemName") and item.BoxItemName.Value == v.Name then
                            if not table.find(list, v.Name) then
                                table.insert(list, v.Name)
                            end
                        end
                    end
                end
            end
        end
    end
    return list
end

-- ── WOOD FUNCTIONS ────────────────────────────────────────────────────────────
local SELL_POS = Vector3.new(314, -0.5, 86.822)
local woodSellActive = false
local unitCutterConn, unitPlankAddedConn
local SelTree

local function isWoodLog(model)
    return model:FindFirstChild("TreeClass") and model:FindFirstChild("WoodSection")
       and not model:FindFirstChild("DraggableItem")
end

local function bringAllLogs()
    local oldPos = player.Character.HumanoidRootPart.CFrame
    for _, v in ipairs(workspace.LogModels:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == player then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(v.WoodSection.CFrame.p)
            if not v.PrimaryPart then v.PrimaryPart = v.WoodSection end
            for i = 1, 50 do
                RS.Interaction.ClientIsDragging:FireServer(v)
                v:SetPrimaryPartCFrame(oldPos)
                task.wait()
            end
        end
        task.wait()
    end
    player.Character.HumanoidRootPart.CFrame = oldPos
end

local function sellAllLogs()
    local oldPos = player.Character.HumanoidRootPart.CFrame
    for _, v in ipairs(workspace.LogModels:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == player then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(v.WoodSection.CFrame.p)
            task.wait(0.3)
            if not v.PrimaryPart then v.PrimaryPart = v.WoodSection end
            task.spawn(function()
                for i = 1, 50 do
                    RS.Interaction.ClientIsDragging:FireServer(v)
                    v:SetPrimaryPartCFrame(CFrame.new(SELL_POS))
                    task.wait()
                end
            end)
        end
        task.wait()
    end
    task.wait()
    player.Character.HumanoidRootPart.CFrame = oldPos
end

local function modSawmill()
    task.spawn(function()
        local ClientPlacedBlueprint = RS.PlaceStructure.ClientPlacedBlueprint
        for _, v in ipairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Owner") and v.Owner.Value == player then
                if v:FindFirstChild("Type") and (v.Type.Value == "Sawmill" or v.Name:lower():find("saw")) then
                    local mp = v:FindFirstChild("Main") or v.PrimaryPart
                    if mp then
                        player.Character.HumanoidRootPart.CFrame = mp.CFrame + Vector3.new(5,0,0)
                        task.wait(0.1)
                        pcall(function()
                            ClientPlacedBlueprint:FireServer(v.ItemName.Value, mp.CFrame, player)
                        end)
                        task.wait(0.5)
                    end
                end
            end
        end
    end)
end

local function modWood()
    -- resize all planks to 1x1x1
    task.spawn(function()
        for _, v in ipairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Owner") and v.Owner.Value == player then
                local ws = v:FindFirstChild("WoodSection")
                if ws then
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(ws.CFrame.p) + Vector3.new(3,0,0)
                    task.wait(0.1)
                    for i = 1, 30 do
                        RS.Interaction.ClientIsDragging:FireServer(v)
                        task.wait()
                    end
                end
            end
        end
    end)
end

local function getAxeClasses() return RS:FindFirstChild("AxeClasses") end

local function getBestAxe(treeClass)
    local axeClasses = getAxeClasses()
    if not axeClasses then return nil end
    local best, bestDmg = nil, 0
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool.Name == "Tool" and tool:FindFirstChild("ToolName") then
            local mod = axeClasses:FindFirstChild("AxeClass_"..tool.ToolName.Value)
            if mod then
                local ok, stats = pcall(function() return require(mod).new() end)
                if ok and stats then
                    if stats.SpecialTrees and stats.SpecialTrees[treeClass] then
                        return tool
                    elseif (stats.Damage or 0) > bestDmg then
                        best = tool; bestDmg = stats.Damage or 0
                    end
                end
            end
        end
    end
    return best
end

local function chopTree(cutEvent, id, height, treeClass)
    local axe = getBestAxe(treeClass)
    if not axe then return end
    RS.Interaction.RemoteProxy:FireServer(cutEvent, {
        tool=axe, faceVector=Vector3.new(1,0,0),
        height=height, sectionId=id,
        hitPoints=10, cooldown=0.25837870788574,
        cuttingClass="Axe"
    })
end

local function getBiggestTree(treeClass)
    local best, bestMass = nil, 0
    for _, region in ipairs(workspace:GetChildren()) do
        if region.Name == "TreeRegion" then
            for _, tree in ipairs(region:GetChildren()) do
                if tree:FindFirstChild("TreeClass") and tree.TreeClass.Value == treeClass then
                    local owner = tree:FindFirstChild("Owner")
                    if owner and (owner.Value == nil or owner.Value == player) then
                        local trunk = tree:FindFirstChild("WoodSection")
                        if trunk then
                            local mass = trunk.Size.X * trunk.Size.Y * trunk.Size.Z
                            if mass > bestMass then
                                best = {tree=tree, trunk=trunk}; bestMass = mass
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local treestop = true

local function bringTree(treeClass, amount)
    treestop = false
    local oldPos = player.Character.HumanoidRootPart.CFrame
    for i = 1, amount do
        if treestop then break end
        local data = getBiggestTree(treeClass)
        if not data then break end
        local tree, trunk = data.tree, data.trunk
        if not (trunk.Size.X >= 1 and trunk.Size.Y >= 2 and trunk.Size.Z >= 1) then continue end
        player.Character.HumanoidRootPart.CFrame = CFrame.new(trunk.CFrame.p) + Vector3.new(5,0,0)
        local chopped = false
        local addConn = workspace.LogModels.ChildAdded:Connect(function(v)
            if v:FindFirstChild("Owner") and v.Owner.Value == player then
                if v:FindFirstChild("TreeClass") and v.TreeClass.Value == treeClass then
                    if v:FindFirstChild("WoodSection") then
                        if not v.PrimaryPart then v.PrimaryPart = v.WoodSection end
                        for j = 1, 50 do
                            RS.Interaction.ClientIsDragging:FireServer(v)
                            v:SetPrimaryPartCFrame(oldPos)
                            task.wait()
                        end
                        chopped = true
                    end
                end
            end
        end)
        -- chop trunk sections
        for _, section in ipairs(tree:GetChildren()) do
            if section.Name == "WoodSection" and section:FindFirstChild("ID") then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(section.CFrame.p) + Vector3.new(3,0,0)
                task.wait(0.1)
                for j = 1, 3 do
                    chopTree(tree:FindFirstChild("CutEvent"), section.ID.Value, 0.3, treeClass)
                    task.wait(0.3)
                    if chopped then break end
                end
                if chopped then break end
            end
        end
        addConn:Disconnect()
        task.wait(0.5)
    end
    treestop = true
end

local function dickmemberTree()
    task.spawn(function()
        local TreeToJointCut = nil
        local LogChopped = false
        local branchAdded = workspace.LogModels.ChildAdded:Connect(function(v)
            if v:FindFirstChild("Owner") and v.Owner.Value == player then
                if v:FindFirstChild("WoodSection") then LogChopped = true end
            end
        end)
        local clickConn = mouse.Button1Up:Connect(function()
            local tgt = mouse.Target
            if tgt and tgt.Parent:FindFirstAncestor("LogModels") then
                if tgt.Parent:FindFirstChild("Owner") and tgt.Parent.Owner.Value == player then
                    TreeToJointCut = tgt.Parent
                end
            end
        end)
        repeat task.wait() until TreeToJointCut ~= nil
        for _, v in ipairs(TreeToJointCut:GetChildren()) do
            if v.Name == "WoodSection" and v:FindFirstChild("ID") and v.ID.Value ~= 1 then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(v.CFrame.p)
                repeat
                    chopTree(TreeToJointCut:FindFirstChild("CutEvent"), v.ID.Value, 0.3,
                        TreeToJointCut:FindFirstChild("TreeClass") and TreeToJointCut.TreeClass.Value or "Generic")
                    task.wait()
                until LogChopped
                LogChopped = false
                task.wait(1)
            end
        end
        branchAdded:Disconnect(); clickConn:Disconnect()
    end)
end

local function viewLoneCave(val)
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name == "TreeRegion" then
            for _, tree in ipairs(v:GetChildren()) do
                if tree:FindFirstChild("TreeClass") and tree.TreeClass.Value == "LoneCave" then
                    if tree:FindFirstChild("Owner") and tree.Owner.Value == nil then
                        workspace.Camera.CameraSubject = val
                            and tree:FindFirstChild("WoodSection")
                            or player.Character.Humanoid
                    end
                end
            end
        end
    end
end

local function oneUnitCutter(val)
    if unitCutterConn then unitCutterConn:Disconnect(); unitCutterConn = nil end
    if unitPlankAddedConn then unitPlankAddedConn:Disconnect(); unitPlankAddedConn = nil end
    if not val then return end
    unitPlankAddedConn = workspace.PlayerModels.ChildAdded:Connect(function(v)
        if v:FindFirstChild("TreeClass") and v:FindFirstChild("WoodSection") then
            SelTree = v; task.wait()
        end
    end)
    unitCutterConn = mouse.Button1Up:Connect(function()
        local clicked = mouse.Target
        if not clicked then return end
        if clicked.Name == "WoodSection" then
            SelTree = clicked.Parent
            player.Character:MoveTo(clicked.Position + Vector3.new(0,3,-3))
            task.spawn(function()
                repeat
                    if not val then break end
                    if not SelTree or not SelTree:FindFirstChild("WoodSection") then break end
                    chopTree(SelTree.CutEvent, 1, 1, SelTree.TreeClass.Value)
                    local ws = SelTree:FindFirstChild("WoodSection")
                    if ws then player.Character:MoveTo(ws.Position + Vector3.new(0,3,-3)) end
                    task.wait()
                until SelTree and SelTree:FindFirstChild("WoodSection")
                    and SelTree.WoodSection.Size.X <= 1.88
                    and SelTree.WoodSection.Size.Y <= 1.88
                    and SelTree.WoodSection.Size.Z <= 1.88
            end)
        end
    end)
end

-- ── AUTO BUY TAB ──────────────────────────────────────────────────────────────
local autobuyPage, autobuyBtn = addTab("Auto Buy", "🛒")
do
    local buyAmount = 1
    local openBox = false
    local selectedItem = nil

    local buySec = addSection(autobuyPage, "AutoBuy")

    addSlider(buySec, "Amount", 1, 100, 1, function(v) buyAmount = v end)
    addToggle(buySec, "Open Box", false, function(v) openBox = v end)

    -- Live shop dropdown
    local shopItems = {}
    task.spawn(function()
        shopItems = grabShopItems()
    end)
    local itemDD = addDropdown(buySec, "Select Item", shopItems, function(v)
        selectedItem = v:split(" - ")[1]
    end)

    addButton(buySec, "Refresh Shop Items", BTN_COLOR, function()
        shopItems = grabShopItems()
        itemDD.setOptions(shopItems)
    end)
    addButton(buySec, "Purchase Selected Item(s)", Color3.fromRGB(35,90,45), function()
        autoBuy(selectedItem, buyAmount, openBox)
    end)
    addButton(buySec, "Abort Purchasing", Color3.fromRGB(90,35,35), function()
        AbortAutoBuy = true
    end)

    -- Buying Misc section
    local miscSec = addSection(autobuyPage, "Buying Misc")
    addButton(miscSec, "Purchase All Blueprints", Color3.fromRGB(35,55,100), function()
        task.spawn(function()
            local bps = getBlueprints()
            for _, bp in ipairs(bps) do
                autoBuy(bp, 1, true)
            end
        end)
    end)
    addButton(miscSec, "Toll Bridge Payment", BTN_COLOR, function() pay(15) end)
    addButton(miscSec, "Ferry Ticket Payment", BTN_COLOR, function() pay(13) end)
    addButton(miscSec, "Power Of Ease Payment", BTN_COLOR, function() pay(3) end)
end

-- ── WOOD TAB ──────────────────────────────────────────────────────────────────
local woodPage, woodBtn = addTab("Wood", "🪓")
do
    local treeTypes = {
        "Generic","Walnut","Cherry","SnowGlow","Oak","Birch","Koa","Fir",
        "Volcano","GreenSwampy","CaveCrawler","Palm","GoldSwampy","Frost",
        "Spooky","SpookyNeon","LoneCave"
    }
    local selectedTree = "Generic"
    local treeAmount = 1

    local getSec = addSection(woodPage, "Get Tree")
    addDropdown(getSec, "Tree Type", treeTypes, function(v) selectedTree = v end)
    addButton(getSec, "Bring Tree", Color3.fromRGB(35,90,45), function()
        bringTree(selectedTree, treeAmount)
    end)
    addSlider(getSec, "Amount", 1, 30, 1, function(v) treeAmount = v end)
    addButton(getSec, "Abort", Color3.fromRGB(90,35,35), function() treestop = true end)

    local treeSec = addSection(woodPage, "Tree")
    addToggle(treeSec, "Cut Plank to 1×1", false, function(v) oneUnitCutter(v) end)
    addButton(treeSec, "Bring All Logs", Color3.fromRGB(35,55,100), function()
        task.spawn(bringAllLogs)
    end)
    addButton(treeSec, "Sell All Logs", Color3.fromRGB(35,90,45), function()
        task.spawn(sellAllLogs)
    end)

    local modSec = addSection(woodPage, "Mod Stuff")
    addButton(modSec, "Mod Sawmill", BTN_COLOR, function() modSawmill() end)
    addButton(modSec, "Mod Wood", BTN_COLOR, function() modWood() end)

    local helpSec = addSection(woodPage, "Tree Help")
    addButton(helpSec, "DickmemberTree", BTN_COLOR, function() dickmemberTree() end)
    addToggle(helpSec, "View LoneCave Tree", false, function(v) viewLoneCave(v) end)
end

-- ── SEARCH TAB ────────────────────────────────────────────────────────────────
local searchPage, searchBtn = addTab("Search", "🔍")
do
    local searchSec = addSection(searchPage, "Search")
    local inputFrame = Instance.new("Frame", searchSec)
    inputFrame.Size = UDim2.new(1,0,0,28)
    inputFrame.BackgroundColor3 = Color3.fromRGB(30,24,40)
    inputFrame.BorderSizePixel = 0
    inputFrame.LayoutOrder = 1
    makeCorner(inputFrame, 5)
    local searchBox = Instance.new("TextBox", inputFrame)
    searchBox.Size = UDim2.new(1,0,1,0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search tabs and features..."
    searchBox.TextColor3 = THEME_TEXT
    searchBox.PlaceholderColor3 = Color3.fromRGB(120,100,140)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 11
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    makePadding(searchBox, 4,4,4,8)
    searchBox.ClearTextOnFocus = false

    local resultsSec = addSection(searchPage, "Results")

    local function doSearch(query)
        for _, c in ipairs(resultsSec:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        if query == "" then return end
        query = query:lower()
        for _, tabData in ipairs(VH.tabs) do
            local tabText = tabData.btn.Text:lower()
            if tabText:find(query) then
                addButton(resultsSec, "📂 " .. tabData.btn.Text, BTN_COLOR, function()
                    VH.switchTab(tabData.page, tabData.btn)
                end)
            end
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        doSearch(searchBox.Text)
    end)
end

-- ── SETTINGS TAB ─────────────────────────────────────────────────────────────
local settingsPage, settingsBtn = addTab("Settings", "⚙️")
do
    local s = addSection(settingsPage, "Keybinds")

    local function addKBRow(section, text, default, callback)
        local row = Instance.new("Frame", section)
        row.Size = UDim2.new(1,0,0,26); row.BackgroundTransparency = 1
        row.LayoutOrder = #section:GetChildren()
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1,-80,1,0); lbl.BackgroundTransparency = 1
        lbl.Text = text; lbl.TextColor3 = THEME_TEXT; lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local kbtn = Instance.new("TextButton", row)
        kbtn.Size = UDim2.new(0,74,0,20); kbtn.Position = UDim2.new(1,-76,0.5,-10)
        kbtn.BackgroundColor3 = BTN_COLOR
        kbtn.Text = tostring(default):gsub("Enum%.KeyCode%.","")
        kbtn.TextColor3 = THEME_TEXT; kbtn.Font = Enum.Font.Gotham; kbtn.TextSize = 10
        makeCorner(kbtn, 4)
        local waiting = false
        kbtn.MouseButton1Click:Connect(function()
            waiting = true; kbtn.Text = "..."; kbtn.BackgroundColor3 = Color3.fromRGB(60,40,80)
        end)
        UIS.InputBegan:Connect(function(inp, gpe)
            if waiting and not gpe then
                waiting = false; kbtn.Text = inp.KeyCode.Name; kbtn.BackgroundColor3 = BTN_COLOR
                task.spawn(callback, inp.KeyCode)
            end
        end)
        return kbtn
    end

    addKBRow(s, "GUI Toggle Key", VH.currentToggleKey, function(key)
        VH.currentToggleKey = key
    end)
    addKBRow(s, "Fly Key", VH.currentFlyKey, function(key)
        VH.currentFlyKey = key
    end)
end

-- ── global input handler (fly key) ───────────────────────────────────────────
local inputConn = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == VH.currentFlyKey and VH.flyToggleEnabled then
        if VH.isFlyEnabled then VH.stopFly() else VH.startFly() end
    end
end)
addCleanup(function() inputConn:Disconnect() end)

print("[VanillaHub] Vanilla3 loaded ✓")
