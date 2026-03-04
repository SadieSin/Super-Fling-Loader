-- VanillaHub | Vanilla6.lua
-- Populates: AutoBuy, Slot tabs
-- Requires Vanilla1 (_G.VH) to already be loaded.

if not _G.VH then
    warn("[VanillaHub] Vanilla6: _G.VH not found. Load Vanilla1 first.")
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

-- ── UI helpers ────────────────────────────────────────────────────────────────

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

-- ── Fancy dropdown ─────────────────────────────────────────────────────────────
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

local function makeProgress(page)
    local bg = Instance.new("Frame", page)
    bg.Size = UDim2.new(1,-12,0,40)
    bg.BackgroundColor3 = Color3.fromRGB(22,22,28)
    bg.BorderSizePixel = 0
    corner(bg, 6)
    local lb = Instance.new("TextLabel", bg)
    lb.Size = UDim2.new(1,-12,0,16)
    lb.Position = UDim2.new(0,6,0,4)
    lb.BackgroundTransparency = 1
    lb.Font = Enum.Font.GothamSemibold
    lb.TextSize = 11
    lb.TextColor3 = THEME_TEXT
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Text = ""
    local track = Instance.new("Frame", bg)
    track.Size = UDim2.new(1,-12,0,10)
    track.Position = UDim2.new(0,6,0,24)
    track.BackgroundColor3 = Color3.fromRGB(35,35,45)
    track.BorderSizePixel = 0
    corner(track, 5)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,80,100)
    fill.BorderSizePixel = 0
    corner(fill, 5)
    return {
        Set = function(cur, tot, msg)
            local pct = tot > 0 and cur/tot or 0
            TS:Create(fill, TweenInfo.new(0.18), {Size = UDim2.new(pct,0,1,0)}):Play()
            lb.Text = msg or (cur.." / "..tot)
        end,
        Reset = function() fill.Size = UDim2.new(0,0,1,0); lb.Text = "" end
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTO BUY TAB
-- ═══════════════════════════════════════════════════════════════════════════

local ab = pages["AutoBuyTab"]

-- ── Core functions ─────────────────────────────────────────────────────────

local ShopIDS = {
    WoodRUs=7, FurnitureStore=8, FineArt=11,
    CarStore=9, LogicStore=12, ShackShop=10,
}

local function isnetworkowner(Part)
    local ok, v = pcall(function() return Part.ReceiveAge == 0 end)
    return ok and v
end

local function GetPing()
    local Time = tick()
    pcall(function() RS.TestPing:InvokeServer() end)
    return math.clamp((tick() - Time) / 2, 0.05, 0.3)
end

local function GetPrice(Item, Amount)
    local Price = 0
    for _, v in next, RS.ClientItemInfo:GetDescendants() do
        if v.Name == Item and v:FindFirstChild("Price") then
            Price = Price + v.Price.Value * (Amount or 1)
        end
    end
    return Price
end

local function GrabShopItems()
    local ItemList = {}
    for _, v in next, workspace.Stores:GetChildren() do
        if v.Name == "ShopItems" then
            for _, item in next, v:GetChildren() do
                if item:FindFirstChild("Type") and item.Type.Value ~= "Blueprint"
                   and item:FindFirstChild("BoxItemName") then
                    local entry = item.BoxItemName.Value.." - $"..GetPrice(item.BoxItemName.Value, 1)
                    if not table.find(ItemList, entry) then
                        table.insert(ItemList, entry)
                    end
                end
            end
        end
        table.sort(ItemList)
    end
    return #ItemList > 0 and ItemList or {"(no items found)"}
end

local function UpdateNames()
    for _, v in next, workspace.Stores:GetChildren() do
        if v.Name == "ShopItems" then
            v.ChildAdded:Connect(function(child)
                child.Name = child:WaitForChild("BoxItemName").Value
            end)
            for _, item in next, v:GetChildren() do
                if item:FindFirstChild("Owner") and item.Owner.Value == nil then
                    if item:FindFirstChild("BoxItemName") then
                        item.Name = item.BoxItemName.Value
                    end
                end
            end
        end
    end
end
UpdateNames()

local function ItemPath(Item)
    for _, v in next, workspace.Stores:GetChildren() do
        if v.Name == "ShopItems" then
            for _, item in next, v:GetChildren() do
                if item:FindFirstChild("Owner") and item.Owner.Value == nil then
                    if item:FindFirstChild("BoxItemName") and tostring(item.BoxItemName.Value) == Item then
                        return item.Parent
                    end
                end
            end
        end
    end
end

local function GetCounter(Item)
    local ClosestCounter = nil
    local closestDist = math.huge
    for _, v in next, workspace.Stores:GetChildren() do
        if v.Name:lower() ~= "shopitems" then
            for _, child in next, v:GetChildren() do
                if child.Name:lower() == "counter" then
                    local dist = (Item.CFrame.p - child.CFrame.p).Magnitude
                    if dist <= 200 and dist < closestDist then
                        closestDist = dist
                        ClosestCounter = child
                    end
                end
            end
        end
    end
    return ClosestCounter
end

-- FIX: Pay fires synchronously in a tight loop — no spawn wrapper to avoid lag
local function Pay(ID)
    pcall(function()
        RS.NPCDialog.PlayerChatted:InvokeServer(
            {ID=ID, Character="name", Name="name", Dialog="Dialog"},
            "ConfirmPurchase"
        )
    end)
end

-- State
local AbortAutoBuy  = false
local ItemToBuy     = nil
local AutoBuyAmount = 1
local OpenBox       = false

-- ── FIXED AutoBuy — faster, correct parent name check ────────────────────────
local function AutoBuy(ItemName, Amount, op, bpop, prog, stat)
    if ItemName == nil then
        if stat then stat.SetActive(false, "No item selected!") end
        return
    end
    if LP.leaderstats.Money.Value < GetPrice(ItemName, 1) then
        if stat then stat.SetActive(false, "Not enough money!") end
        return
    end

    AbortAutoBuy = false
    local OldPos = LP.Character.HumanoidRootPart.CFrame
    local Path = ItemPath(ItemName)

    if not Path then
        if stat then stat.SetActive(false, "Item not found in stores.") end
        return
    end

    if stat then stat.SetActive(true, "Buying: "..ItemName) end

    for i = 1, Amount do
        if AbortAutoBuy then break end

        -- Wait for item to appear/respawn in ShopItems
        local Item = nil
        local waitStart = tick()
        repeat
            task.wait()
            for _, v in next, Path:GetChildren() do
                if v:FindFirstChild("BoxItemName") and v.BoxItemName.Value == ItemName
                   and v:FindFirstChild("Owner") and v.Owner.Value == nil then
                    Item = v; break
                end
            end
        until Item or (tick() - waitStart > 20) or AbortAutoBuy

        if not Item then
            if stat then stat.SetActive(false, "Item wait timed out.") end
            break
        end

        local mainPart = Item:FindFirstChild("Main") or Item:FindFirstChildWhichIsA("BasePart")
        if not mainPart then continue end

        local Counter = GetCounter(mainPart)
        if not Counter then
            if stat then stat.SetActive(false, "No counter found.") end
            break
        end

        -- Move player next to item
        LP.Character.HumanoidRootPart.CFrame = mainPart.CFrame + Vector3.new(3, 0, 3)
        task.wait(0.05)

        -- Grab ownership — tight loop, no sleep
        local t0 = tick()
        repeat
            RS.Interaction.ClientIsDragging:FireServer(Item)
            task.wait()
        until (Item.Owner and Item.Owner.Value ~= nil) or (tick()-t0 > 5) or AbortAutoBuy

        if not (Item.Owner and Item.Owner.Value == LP) then continue end

        -- Get network ownership — tight loop
        t0 = tick()
        repeat
            RS.Interaction.ClientIsDragging:FireServer(Item)
            task.wait()
        until isnetworkowner(mainPart) or (tick()-t0 > 5)

        -- Move item to counter top
        RS.Interaction.ClientIsDragging:FireServer(Item)
        pcall(function()
            mainPart.CFrame = Counter.CFrame + Vector3.new(0, mainPart.Size.Y / 2 + 0.5, 0)
        end)
        task.wait(0.05)

        -- Move player to counter
        pcall(function()
            LP.Character.HumanoidRootPart.CFrame = Counter.CFrame + Vector3.new(3, 0, 3)
        end)
        task.wait(0.05)

        -- ── FIX: Corrected pay loop ─────────────────────────────────────────────
        -- Checks Item.Parent.Name (string) not Item.Parent (instance vs string)
        -- Fires both remotes every frame for maximum speed
        local shopID = ShopIDS[Counter.Parent.Name]
        local payStart = tick()
        repeat
            if AbortAutoBuy then break end
            RS.Interaction.ClientIsDragging:FireServer(Item)
            -- Keep item on counter while paying
            pcall(function()
                mainPart.CFrame = Counter.CFrame + Vector3.new(0, mainPart.Size.Y / 2 + 0.5, 0)
            end)
            Pay(shopID)
            task.wait()
        until (not Item.Parent)
          or (Item.Parent and Item.Parent.Name ~= "ShopItems")
          or (tick() - payStart > 20)

        -- Re-grab network ownership then send item to player's original position
        pcall(function()
            if not Item.Parent then return end
            local t1 = tick()
            repeat
                RS.Interaction.ClientIsDragging:FireServer(Item)
                task.wait()
            until (not Item.Parent) or isnetworkowner(mainPart) or tick()-t1 > 3

            if Item.Parent then
                RS.Interaction.ClientIsDragging:FireServer(Item)
                mainPart.CFrame = OldPos * CFrame.new(0, 2, 0)
                task.wait(0.05)
            end
        end)

        if op and Item.Parent then
            pcall(function()
                RS.Interaction.ClientInteracted:FireServer(Item, "Open box")
            end)
        end

        if prog and not bpop then
            prog.Set(i, Amount, "Buying... "..i.." / "..Amount)
        end
    end

    -- Return player to start
    LP.Character.HumanoidRootPart.CFrame = OldPos * CFrame.new(0, 1, 0)

    if stat then
        stat.SetActive(false, AbortAutoBuy and "Aborted." or "Done!")
    end
    if prog then
        prog.Set(Amount, Amount, AbortAutoBuy and "Aborted" or "Complete!")
    end
end

local function getMissingBlueprints()
    local out = {}
    for _, v in next, RS.ClientItemInfo:GetChildren() do
        if v:FindFirstChild("Type")
           and (v.Type.Value == "Structure" or v.Type.Value == "Furniture")
           and v:FindFirstChild("WoodCost")
           and not LP.PlayerBlueprints.Blueprints:FindFirstChild(v.Name) then
            table.insert(out, v.Name)
        end
    end
    return out
end

-- ── AutoBuy UI ────────────────────────────────────────────────────────────────

sectionLabel(ab, "Item Selection")

local shopItemsCache = GrabShopItems()
local shopDD = makeFancyDropdown(ab, "Item", function() return shopItemsCache end, function(val)
    ItemToBuy = val:match("^(.-)%s*%-%s*%$") or val
end)

sectionLabel(ab, "Options")
makeSlider(ab, "Amount", 1, 100, 1, function(v) AutoBuyAmount = v end)
makeToggle(ab, "Open Box After Buying", false, function(v) OpenBox = v end)
sep(ab)

local abStat = makeStatus(ab, "Idle")
local abProg = makeProgress(ab)

makeButton(ab, "↻  Refresh Item List", function()
    shopItemsCache = GrabShopItems()
    shopDD.Refresh()
end)

makeButton(ab, "Purchase Selected Item(s)", function()
    task.spawn(AutoBuy, ItemToBuy, AutoBuyAmount, OpenBox, false, abProg, abStat)
end)

makeButton(ab, "Abort", function()
    AbortAutoBuy = true
    abStat.SetActive(false, "Aborted.")
end)

sep(ab)
sectionLabel(ab, "Quick Purchases")

makeButton(ab, "Buy All Missing Blueprints", function()
    local bps = getMissingBlueprints()
    if #bps == 0 then abStat.SetActive(false, "No blueprints missing!") return end
    abStat.SetActive(true, "Buying "..#bps.." blueprints...")
    for _, v in next, bps do
        if AbortAutoBuy then break end
        AutoBuy(v, 1, true, true, abProg, nil)
    end
    abStat.SetActive(false, AbortAutoBuy and "Aborted." or "Done!")
end)

makeButton(ab, "Pay Toll Bridge", function() Pay(15) end)
makeButton(ab, "Buy Ferry Ticket",  function() Pay(13) end)
makeButton(ab, "Buy Power of Ease", function() Pay(3)  end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SLOT TAB
-- ═══════════════════════════════════════════════════════════════════════════

local sl = pages["SlotTab"]

local slotNum    = 1
local landToTake = nil
local landHL     = nil

local function freeLand()
    for _, v in next, workspace.Properties:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == nil then
            pcall(function()
                RS.PropertyPurchasing.ClientPurchasedProperty:FireServer(v, v.OriginSquare.Position)
                LP.Character.HumanoidRootPart.CFrame = v.OriginSquare.CFrame + Vector3.new(0,2,0)
            end)
            break
        end
    end
end

local function maxLand()
    for _, d in pairs(workspace.Properties:GetChildren()) do
        if d:FindFirstChild("Owner") and d:FindFirstChild("OriginSquare") and d.Owner.Value == LP then
            local p = d.OriginSquare.Position
            local offsets = {
                Vector3.new(40,0,0),  Vector3.new(-40,0,0),
                Vector3.new(0,0,40),  Vector3.new(0,0,-40),
                Vector3.new(40,0,40), Vector3.new(40,0,-40),
                Vector3.new(-40,0,40),Vector3.new(-40,0,-40),
                Vector3.new(80,0,0),  Vector3.new(-80,0,0),
                Vector3.new(0,0,80),  Vector3.new(0,0,-80),
                Vector3.new(80,0,80), Vector3.new(80,0,-80),
                Vector3.new(-80,0,80),Vector3.new(-80,0,-80),
                Vector3.new(40,0,80), Vector3.new(-40,0,80),
                Vector3.new(80,0,40), Vector3.new(80,0,-40),
                Vector3.new(-80,0,40),Vector3.new(-80,0,-40),
                Vector3.new(40,0,-80),Vector3.new(-40,0,-80),
            }
            for _, off in ipairs(offsets) do
                pcall(function()
                    RS.PropertyPurchasing.ClientExpandedProperty:FireServer(d, CFrame.new(p+off))
                end)
            end
        end
    end
end

local function loadSlot(slot)
    pcall(function()
        if not RS.LoadSaveRequests.ClientMayLoad:InvokeServer(LP) then
            repeat task.wait() until RS.LoadSaveRequests.ClientMayLoad:InvokeServer(LP)
        end
        RS.LoadSaveRequests.RequestLoad:InvokeServer(slot, LP)
    end)
end

local function sellSoldSign()
    for _, v in next, workspace.PlayerModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP
           and v:FindFirstChild("ItemName") and v.ItemName.Value == "PropertySoldSign" then
            pcall(function()
                LP.Character.HumanoidRootPart.CFrame = CFrame.new(v.Main.CFrame.p) + Vector3.new(0,0,2)
                RS.Interaction.ClientInteracted:FireServer(v, "Take down sold sign")
                for _ = 1, 30 do
                    RS.Interaction.ClientIsDragging:FireServer(v)
                    v.Main.CFrame = CFrame.new(314.54, -0.5, 86.823)
                    task.wait()
                end
            end)
        end
    end
end

sectionLabel(sl, "Fast Load")
makeSlider(sl, "Slot Number", 1, 6, 1, function(v) slotNum = v end)
makeButton(sl, "Load Base", function() loadSlot(slotNum) end)

sep(sl)
sectionLabel(sl, "Land Management")
makeButton(sl, "Claim Free Land", freeLand)
makeButton(sl, "Max Expand Land", maxLand)
makeButton(sl, "Sell Sold Sign", sellSoldSign)

sep(sl)
sectionLabel(sl, "Land Claim")

local landPlotOptions = {"1","2","3","4","5","6","7","8","9"}
makeFancyDropdown(sl, "Plot", function() return landPlotOptions end, function(val)
    if landHL then pcall(function() landHL:Destroy() end) end
    landToTake = tonumber(val)
    local props = workspace.Properties:GetChildren()
    if props[landToTake] and props[landToTake]:FindFirstChild("OriginSquare") then
        landHL = Instance.new("Highlight")
        landHL.FillColor = Color3.fromRGB(80,200,80)
        landHL.FillTransparency = 0.5
        landHL.Parent = props[landToTake].OriginSquare
    end
end)

makeButton(sl, "Take Selected Land", function()
    if not landToTake then return end
    local props = workspace.Properties:GetChildren()
    if props[landToTake] then
        local land = props[landToTake]
        pcall(function()
            RS.PropertyPurchasing.ClientPurchasedProperty:FireServer(land, land.OriginSquare.Position)
            LP.Character.HumanoidRootPart.CFrame = land.OriginSquare.CFrame + Vector3.new(0,2,0)
        end)
        if landHL then pcall(function() landHL:Destroy() end); landHL = nil end
    end
end)

-- ── Cleanup ───────────────────────────────────────────────────────────────────
table.insert(VH.cleanupTasks, function()
    AbortAutoBuy = true
    if landHL then pcall(function() landHL:Destroy() end) end
end)

print("[VanillaHub] Vanilla6 loaded — AutoBuy, Slot")
