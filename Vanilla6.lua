-- VanillaHub | Vanilla6.lua
-- Tabs: AutoBuy, Slot
-- Continuation of Vanilla5. Requires _G.VH to be loaded first.

if not _G.VH then
    warn("[VanillaHub] Vanilla6: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH = _G.VH
local TS = VH.TweenService
local Players = VH.Players
local RS = game:GetService("ReplicatedStorage")
local UIS = VH.UserInputService
local RunService = VH.RunService
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

local THEME_TEXT = VH.THEME_TEXT  -- Color3.fromRGB(230, 206, 226)
local BTN_COLOR  = VH.BTN_COLOR   -- Color3.fromRGB(45, 45, 50)
local BTN_HOVER  = VH.BTN_HOVER   -- Color3.fromRGB(70, 70, 80)

-- ─── Helpers (mirrors Vanilla1 helpers) ─────────────────────────────────────

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function ripple(btn)
    if not btn.ClipsDescendants then btn.ClipsDescendants = true end
    local r = Instance.new("ImageLabel")
    r.BackgroundTransparency = 1
    r.ZIndex = btn.ZIndex + 5
    r.Image = "rbxassetid://2708891598"
    r.ImageTransparency = 0.7
    r.ImageColor3 = Color3.fromRGB(255,255,255)
    r.ScaleType = Enum.ScaleType.Fit
    r.Size = UDim2.new(0,0,0,0)
    r.AnchorPoint = Vector2.new(0.5,0.5)
    local mp = UIS:GetMouseLocation()
    local abs = btn.AbsolutePosition
    r.Position = UDim2.new(0, mp.X - abs.X, 0, mp.Y - abs.Y)
    r.Parent = btn
    TS:Create(r, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,180,0,180),
        ImageTransparency = 1,
    }):Play()
    game:GetService("Debris"):AddItem(r, 0.4)
end

-- Build a standard tab content scroll frame into the given page frame
local function makeScrollContent(pageFrame)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1,0,1,0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(80,60,90)
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Parent = pageFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)
    layout.Parent = sf

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0,16)
    pad.PaddingBottom = UDim.new(0,16)
    pad.PaddingLeft   = UDim.new(0,14)
    pad.PaddingRight  = UDim.new(0,14)
    pad.Parent = sf

    return sf
end

-- Section label
local function makeLabel(parent, text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,22)
    f.BackgroundTransparency = 1
    f.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,100,140)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    lbl.Parent = f
    return f
end

-- Separator
local function makeSep(parent)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1,0,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,40,55)
    s.BorderSizePixel = 0
    s.Parent = parent
    return s
end

-- Standard button
local function makeButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = BTN_COLOR
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT
    btn.Text = text
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true
    makeCorner(btn, 6)
    btn.Parent = parent

    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        ripple(btn)
        task.spawn(callback)
    end)
    return btn
end

-- Toggle
local function makeToggle(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,32)
    container.BackgroundColor3 = BTN_COLOR
    container.BorderSizePixel = 0
    makeCorner(container, 6)
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-50,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.Parent = container

    -- Switch track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0,34,0,18)
    track.Position = UDim2.new(1,-44,0.5,-9)
    track.BackgroundColor3 = Color3.fromRGB(50,50,60)
    track.BorderSizePixel = 0
    makeCorner(track, 9)
    track.Parent = container

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(160,140,180)
    knob.BorderSizePixel = 0
    makeCorner(knob, 7)
    knob.Parent = track

    local state = default
    local function setState(v)
        state = v
        TS:Create(knob, TweenInfo.new(0.18), {
            Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
            BackgroundColor3 = state and Color3.fromRGB(180,100,210) or Color3.fromRGB(160,140,180),
        }):Play()
        TS:Create(track, TweenInfo.new(0.18), {
            BackgroundColor3 = state and Color3.fromRGB(90,40,120) or Color3.fromRGB(50,50,60),
        }):Play()
        callback(state)
    end

    setState(default)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1,0,1,0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = container
    clickBtn.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    return {SetState = setState, GetState = function() return state end}
end

-- Slider
local function makeSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,52)
    container.BackgroundColor3 = BTN_COLOR
    container.BorderSizePixel = 0
    makeCorner(container, 6)
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5,0,0,24)
    lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.Parent = container

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.5,0,0,24)
    valLbl.Position = UDim2.new(0.5,0,0,4)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.Gotham
    valLbl.TextSize = 12
    valLbl.TextColor3 = Color3.fromRGB(180,160,200)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(default)
    valLbl.Parent = container

    -- track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-20,0,6)
    track.Position = UDim2.new(0,10,1,-18)
    track.BackgroundColor3 = Color3.fromRGB(35,35,45)
    track.BorderSizePixel = 0
    makeCorner(track, 3)
    track.Parent = container

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(150,80,200)
    fill.BorderSizePixel = 0
    makeCorner(fill, 3)
    fill.Parent = track

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,16,0,16)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(0,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(200,160,230)
    knob.BorderSizePixel = 0
    makeCorner(knob, 8)
    knob.ZIndex = 3
    knob.Parent = track

    local value = default
    local function setValue(v)
        v = math.clamp(math.floor(v), min, max)
        value = v
        local pct = (v - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = tostring(v)
        callback(v)
    end
    setValue(default)

    local dragging = false
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            setValue(math.floor(min + (max - min) * pct))
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            setValue(math.floor(min + (max - min) * pct))
        end
    end)

    return {SetValue = setValue, GetValue = function() return value end}
end

-- Dropdown (matches Vanilla2 dupe dropdown style)
local function makeDropdown(parent, placeholder, options, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,40)
    container.BackgroundColor3 = BTN_COLOR
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    makeCorner(container, 6)
    container.Parent = parent

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1,0,0,40)
    header.BackgroundColor3 = BTN_COLOR
    header.BorderSizePixel = 0
    header.Font = Enum.Font.GothamSemibold
    header.TextSize = 13
    header.TextColor3 = Color3.fromRGB(160,140,180)
    header.Text = placeholder
    header.AutoButtonColor = false
    header.ClipsDescendants = true
    makeCorner(header, 6)
    header.Parent = container

    -- arrow
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0,20,0,20)
    arrow.Position = UDim2.new(1,-28,0.5,-10)
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 14
    arrow.TextColor3 = Color3.fromRGB(130,110,160)
    arrow.Text = "▾"
    arrow.Parent = header

    -- dropdown list (rendered above other elements via ZIndex)
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1,0,0,0)
    list.Position = UDim2.new(0,0,1,4)
    list.BackgroundColor3 = Color3.fromRGB(30,28,38)
    list.BorderSizePixel = 0
    list.ClipsDescendants = true
    list.ZIndex = 20
    makeCorner(list, 6)
    list.Parent = container

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local listPad = Instance.new("UIPadding")
    listPad.PaddingTop    = UDim.new(0,4)
    listPad.PaddingBottom = UDim.new(0,4)
    listPad.Parent = list

    local open = false
    local selectedText = placeholder

    local function close()
        open = false
        arrow.Text = "▾"
        TS:Create(list, TweenInfo.new(0.18), {Size = UDim2.new(1,0,0,0)}):Play()
        task.delay(0.18, function() list.ClipsDescendants = true end)
    end

    local function openList()
        open = true
        arrow.Text = "▴"
        list.ClipsDescendants = false
        local contentH = listLayout.AbsoluteContentSize.Y + 8
        TS:Create(list, TweenInfo.new(0.18), {Size = UDim2.new(1,0,0,contentH)}):Play()
    end

    local function rebuild(opts)
        for _, ch in ipairs(list:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for _, opt in ipairs(opts) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1,0,0,30)
            ob.BackgroundTransparency = 1
            ob.Font = Enum.Font.Gotham
            ob.TextSize = 13
            ob.TextColor3 = THEME_TEXT
            ob.Text = opt
            ob.ZIndex = 20
            ob.AutoButtonColor = false
            ob.Parent = list

            ob.MouseEnter:Connect(function()
                TS:Create(ob, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(200,170,230)}):Play()
            end)
            ob.MouseLeave:Connect(function()
                TS:Create(ob, TweenInfo.new(0.1), {TextColor3 = THEME_TEXT}):Play()
            end)
            ob.MouseButton1Click:Connect(function()
                selectedText = opt
                header.Text = opt
                header.TextColor3 = THEME_TEXT
                close()
                callback(opt)
            end)
        end
        if open then
            local contentH = listLayout.AbsoluteContentSize.Y + 8
            list.Size = UDim2.new(1,0,0,contentH)
        end
    end

    rebuild(options)

    header.MouseButton1Click:Connect(function()
        if open then close() else openList() end
    end)

    return {
        SetOptions = function(_, opts) rebuild(opts) end,
        GetSelected = function() return selectedText end,
    }
end

-- Status dot bar (like Vanilla2 dupe status)
local function makeStatus(parent, label)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,28)
    f.BackgroundColor3 = Color3.fromRGB(30,28,38)
    f.BorderSizePixel = 0
    makeCorner(f, 6)
    f.Parent = parent

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,7,0,7)
    dot.Position = UDim2.new(0,10,0.5,-3)
    dot.BackgroundColor3 = Color3.fromRGB(80,80,100)
    dot.BorderSizePixel = 0
    makeCorner(dot, 4)
    dot.Parent = f

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-30,1,0)
    lbl.Position = UDim2.new(0,24,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(150,130,170)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = f

    return {
        SetActive = function(active, msg)
            dot.BackgroundColor3 = active and Color3.fromRGB(80,200,80) or Color3.fromRGB(80,80,100)
            lbl.Text = msg or label
        end
    }
end

-- Progress bar
local function makeProgressBar(parent)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,0,44)
    bg.BackgroundColor3 = Color3.fromRGB(30,28,38)
    bg.BorderSizePixel = 0
    makeCorner(bg, 6)
    bg.Parent = parent

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-20,0,10)
    track.Position = UDim2.new(0,10,0.5,-5)
    track.BackgroundColor3 = Color3.fromRGB(40,38,50)
    track.BorderSizePixel = 0
    makeCorner(track, 5)
    track.Parent = bg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(150,80,200)
    fill.BorderSizePixel = 0
    makeCorner(fill, 5)
    fill.Parent = track

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.Position = UDim2.new(0,0,0,2)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(180,160,200)
    lbl.Text = ""
    lbl.ZIndex = 3
    lbl.Parent = bg

    return {
        Set = function(current, total, msg)
            local pct = total > 0 and (current / total) or 0
            TS:Create(fill, TweenInfo.new(0.2), {Size = UDim2.new(pct,0,1,0)}):Play()
            lbl.Text = msg or (tostring(current).." / "..tostring(total))
        end,
        Reset = function()
            fill.Size = UDim2.new(0,0,1,0)
            lbl.Text = ""
        end
    }
end

-- ─── Register tabs into VH ───────────────────────────────────────────────────

local function addTab(name)
    -- Add sidebar button
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1,0,0,36)
    tabBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
    tabBtn.BorderSizePixel = 0
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextSize = 13
    tabBtn.TextColor3 = Color3.fromRGB(160,160,160)
    tabBtn.Text = name
    tabBtn.AutoButtonColor = false
    tabBtn.ClipsDescendants = true
    makeCorner(tabBtn, 6)
    tabBtn.Parent = VH.tabList

    -- Page frame
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = VH.contentArea

    tabBtn.MouseButton1Click:Connect(function()
        ripple(tabBtn)
        VH.switchTab(page, tabBtn)
    end)

    return makeScrollContent(page), tabBtn, page
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 1: AUTO BUY
-- ═══════════════════════════════════════════════════════════════════════════

local autoBuyScroll, autoBuyBtn, autoBuyPage = addTab("AutoBuy")

-- ── Helpers ──────────────────────────────────────────────────────────────────

local ShopIDS = {
    WoodRUs       = 7,
    FurnitureStore = 8,
    FineArt       = 11,
    CarStore      = 9,
    LogicStore    = 12,
    ShackShop     = 10,
}

local function isNetworkOwner(part)
    return pcall(function() return part.ReceiveAge == 0 end) and part.ReceiveAge == 0
end

local function getPing()
    local t = tick()
    pcall(function() RS.TestPing:InvokeServer() end)
    return ((tick() - t) / 2) + 0.5
end

local function getItemPrice(item)
    local price = 0
    for _, v in next, RS.ClientItemInfo:GetDescendants() do
        if v.Name == item and v:FindFirstChild("Price") then
            price = price + v.Price.Value
        end
    end
    return price
end

local function grabShopItems()
    local list = {}
    for _, v in next, workspace.Stores:GetChildren() do
        if v.Name == "ShopItems" then
            for _, item in next, v:GetChildren() do
                if item:FindFirstChild("Type") and item.Type.Value ~= "Blueprint"
                   and item:FindFirstChild("BoxItemName") then
                    local entry = item.BoxItemName.Value.." - $"..getItemPrice(item.BoxItemName.Value)
                    if not table.find(list, entry) then
                        table.insert(list, entry)
                        task.wait(0.01)
                    end
                end
            end
        end
        table.sort(list)
    end
    return list
end

local function itemPath(itemName)
    for _, v in next, workspace.Stores:GetChildren() do
        if v.Name == "ShopItems" then
            for _, item in next, v:GetChildren() do
                if item:FindFirstChild("Owner") and item.Owner.Value == nil then
                    if item:FindFirstChild("BoxItemName") and item.BoxItemName.Value == itemName then
                        return item.Parent
                    end
                end
            end
        end
    end
end

local function getCounter(item)
    local closest = nil
    for _, store in next, workspace.Stores:GetChildren() do
        if store.Name:lower() ~= "shopitems" then
            for _, ch in next, store:GetChildren() do
                if ch.Name:lower() == "counter" then
                    if (item.CFrame.p - ch.CFrame.p).Magnitude <= 200 then
                        closest = ch
                    end
                end
            end
        end
    end
    return closest
end

local function payCounter(id)
    task.spawn(function()
        RS.NPCDialog.PlayerChatted:InvokeServer({ID=id, Character="n", Name="n", Dialog="d"}, "ConfirmPurchase")
    end)
end

local function updateShopNames()
    for _, v in next, workspace.Stores:GetChildren() do
        if v.Name == "ShopItems" then
            v.ChildAdded:Connect(function(ch)
                ch.Name = ch:WaitForChild("BoxItemName").Value
            end)
            for _, item in next, v:GetChildren() do
                if item:FindFirstChild("Owner") and item.Owner.Value == nil
                   and item:FindFirstChild("BoxItemName") then
                    item.Name = item.BoxItemName.Value
                end
            end
        end
    end
end
updateShopNames()

local function getBlueprints()
    local bps = {}
    for _, v in next, RS.ClientItemInfo:GetChildren() do
        if v:FindFirstChild("Type") and (v.Type.Value == "Structure" or v.Type.Value == "Furniture") then
            if v:FindFirstChild("WoodCost") then
                if not LP.PlayerBlueprints.Blueprints:FindFirstChild(v.Name) then
                    table.insert(bps, v.Name)
                end
            end
        end
    end
    return bps
end

-- ── State ─────────────────────────────────────────────────────────────────────

local abortAutoBuy = false
local itemToBuy    = nil
local autoBuyAmt   = 1
local openBox      = false

-- ── AutoBuy function ──────────────────────────────────────────────────────────

local function autoBuyFunc(item, amount, doOpen, progressBar, statusBar)
    if not item then
        warn("[VanillaHub] AutoBuy: No item selected.")
        return
    end
    local totalPrice = getItemPrice(item) * amount
    if LP.leaderstats and LP.leaderstats.Money and LP.leaderstats.Money.Value < totalPrice then
        warn("[VanillaHub] AutoBuy: Not enough money.")
        return
    end

    abortAutoBuy = false
    local oldPos = LP.Character and LP.Character.HumanoidRootPart and LP.Character.HumanoidRootPart.CFrame
    local path = itemPath(item)
    if not path then warn("[VanillaHub] AutoBuy: Item not found in stores.") return end

    statusBar.SetActive(true, "Buying: "..item)

    for i = 1, amount do
        if abortAutoBuy then break end

        local itemModel = path:WaitForChild(item, 5)
        if not itemModel then break end

        local counter = getCounter(itemModel.Main)
        if not counter then break end

        pcall(function()
            LP.Character.HumanoidRootPart.CFrame = itemModel.Main.CFrame + Vector3.new(5,0,5)
        end)

        -- grab ownership
        local grabbed = false
        local gTimeout = tick()
        repeat
            pcall(function() RS.Interaction.ClientIsDragging:FireServer(itemModel) end)
            task.wait()
        until (itemModel.Owner.Value ~= nil) or (tick() - gTimeout > 5)

        if itemModel.Owner.Value ~= LP then break end

        local noTimeout = tick()
        repeat
            pcall(function() RS.Interaction.ClientIsDragging:FireServer(itemModel) end)
            task.wait()
        until isNetworkOwner(itemModel.Main) or (tick() - noTimeout > 5)

        pcall(function()
            RS.Interaction.ClientIsDragging:FireServer(itemModel)
            itemModel.Main.CFrame = counter.CFrame + Vector3.new(0, itemModel.Main.Size.Y, 0.5)
        end)
        task.wait(getPing())

        pcall(function()
            LP.Character.HumanoidRootPart.CFrame = counter.CFrame + Vector3.new(5,0,5)
        end)
        task.wait(getPing())

        local payTimeout = tick()
        repeat
            if abortAutoBuy then break end
            pcall(function() RS.Interaction.ClientIsDragging:FireServer(itemModel) end)
            payCounter(ShopIDS[counter.Parent.Name] or 7)
            task.wait()
        until itemModel.Parent ~= path or (tick() - payTimeout > 8)

        pcall(function()
            local no2 = tick()
            repeat
                RS.Interaction.ClientIsDragging:FireServer(itemModel)
                task.wait()
            until isNetworkOwner(itemModel.Main) or tick() - no2 > 5

            RS.Interaction.ClientIsDragging:FireServer(itemModel)
            itemModel.Main.CFrame = oldPos
            task.wait(getPing())
        end)

        if doOpen then
            pcall(function()
                RS.Interaction.ClientInteracted:FireServer(itemModel, "Open box")
            end)
        end

        progressBar.Set(i, amount, "Buying... "..i.." / "..amount)
        task.wait()
    end

    pcall(function()
        LP.Character.HumanoidRootPart.CFrame = oldPos + Vector3.new(5,1,0)
    end)

    statusBar.SetActive(false, abortAutoBuy and "Aborted." or "Done.")
    progressBar.Set(amount, amount, abortAutoBuy and "Aborted" or "Complete!")
end

-- ── Build AutoBuy UI ──────────────────────────────────────────────────────────

makeLabel(autoBuyScroll, "Item Selection")

-- Dynamic dropdown populated from shops
local shopItemsDD = makeDropdown(autoBuyScroll, "Select Item...", grabShopItems(), function(val)
    itemToBuy = val:match("^(.-)%s*%-") -- strip " - $price"
end)

makeLabel(autoBuyScroll, "Options")

makeSlider(autoBuyScroll, "Amount", 1, 100, 1, function(v)
    autoBuyAmt = v
end)

makeToggle(autoBuyScroll, "Open Box After Buy", false, function(v)
    openBox = v
end)

makeSep(autoBuyScroll)

local abStatusBar = makeStatus(autoBuyScroll, "Idle")
local abProgress  = makeProgressBar(autoBuyScroll)

makeButton(autoBuyScroll, "Refresh Item List", function()
    shopItemsDD:SetOptions(grabShopItems())
end)

makeButton(autoBuyScroll, "Purchase Selected Item(s)", function()
    task.spawn(autoBuyFunc, itemToBuy, autoBuyAmt, openBox, abProgress, abStatusBar)
end)

makeButton(autoBuyScroll, "Abort Purchasing", function()
    abortAutoBuy = true
    abStatusBar.SetActive(false, "Aborted by user.")
end)

makeSep(autoBuyScroll)
makeLabel(autoBuyScroll, "Buying Misc")

makeButton(autoBuyScroll, "Purchase All Missing Blueprints", function()
    local bps = getBlueprints()
    abStatusBar.SetActive(true, "Buying blueprints...")
    for i, v in next, bps do
        if abortAutoBuy then break end
        autoBuyFunc(v, 1, true, abProgress, abStatusBar)
    end
    abStatusBar.SetActive(false, "Blueprints done.")
end)

makeButton(autoBuyScroll, "Pay Toll Bridge ($)", function()
    pcall(function()
        RS.NPCDialog.PlayerChatted:InvokeServer({ID=15,Character="n",Name="n",Dialog="d"}, "ConfirmPurchase")
    end)
end)

makeButton(autoBuyScroll, "Buy Ferry Ticket ($)", function()
    pcall(function()
        RS.NPCDialog.PlayerChatted:InvokeServer({ID=13,Character="n",Name="n",Dialog="d"}, "ConfirmPurchase")
    end)
end)

makeButton(autoBuyScroll, "Buy Power of Ease ($)", function()
    pcall(function()
        RS.NPCDialog.PlayerChatted:InvokeServer({ID=3,Character="n",Name="n",Dialog="d"}, "ConfirmPurchase")
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 2: SLOT
-- ═══════════════════════════════════════════════════════════════════════════

local slotScroll, slotBtn, slotPage = addTab("Slot")

-- ── Helpers ───────────────────────────────────────────────────────────────────

local skipLoading  = false
local slot2Num     = 1
local landToTake   = nil
local landHighlight = nil

local function setSlotTo(value, password)
    pcall(function()
        LP.CurrentSaveSlot.Set:Invoke(value, password)
    end)
end

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
        if d:FindFirstChild("Owner") and d:FindFirstChild("OriginSquare")
           and d.Owner.Value == LP then
            local p = d.OriginSquare.Position
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
            for _, off in ipairs(offsets) do
                pcall(function()
                    RS.PropertyPurchasing.ClientExpandedProperty:FireServer(d, CFrame.new(p + off))
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
        if v:FindFirstChild("Owner") and v.Owner.Value == LP then
            if v:FindFirstChild("ItemName") and v.ItemName.Value == "PropertySoldSign" then
                pcall(function()
                    LP.Character.HumanoidRootPart.CFrame = CFrame.new(v.Main.CFrame.p) + Vector3.new(0,0,2)
                    RS.Interaction.ClientInteracted:FireServer(v, "Take down sold sign")
                    for i = 1, 30 do
                        RS.Interaction.ClientIsDragging:FireServer(v)
                        v.Main.CFrame = CFrame.new(314.54, -0.5, 86.823)
                        task.wait()
                    end
                end)
            end
        end
    end
end

-- ── Build Slot UI ─────────────────────────────────────────────────────────────

makeLabel(slotScroll, "Fast Load")

makeSlider(slotScroll, "Slot Number", 1, 6, 1, function(v)
    slot2Num = v
end)

makeToggle(slotScroll, "Fast Load (Skip Animation)", false, function(v)
    skipLoading = v
end)

makeButton(slotScroll, "Load Base", function()
    loadSlot(slot2Num)
end)

makeSep(slotScroll)
makeLabel(slotScroll, "Land Management")

makeButton(slotScroll, "Claim Free Land", function()
    freeLand()
end)

makeButton(slotScroll, "Max Expand Land", function()
    maxLand()
end)

makeButton(slotScroll, "Sell Sold Sign", function()
    sellSoldSign()
end)

makeSep(slotScroll)
makeLabel(slotScroll, "Land Claim")

local landOptions = {"1","2","3","4","5","6","7","8","9"}
makeDropdown(slotScroll, "Select Land Plot...", landOptions, function(val)
    -- remove old highlight
    if landHighlight then pcall(function() landHighlight:Destroy() end) end

    landToTake = tonumber(val)
    local props = workspace.Properties:GetChildren()
    if props[landToTake] then
        local originSq = props[landToTake].OriginSquare
        landHighlight = Instance.new("Highlight")
        landHighlight.FillColor = Color3.fromRGB(80, 200, 80)
        landHighlight.Parent = originSq
    end
end)

makeButton(slotScroll, "Take Selected Land", function()
    if not landToTake then
        warn("[VanillaHub] Slot: No land selected.")
        return
    end
    local props = workspace.Properties:GetChildren()
    if props[landToTake] then
        local land = props[landToTake]
        pcall(function()
            RS.PropertyPurchasing.ClientPurchasedProperty:FireServer(land, land.OriginSquare.Position)
            LP.Character.HumanoidRootPart.CFrame = land.OriginSquare.CFrame + Vector3.new(0,2,0)
            if landHighlight then landHighlight:Destroy() end
        end)
    end
end)

-- ── Player list update hook (for dropdowns that need it in other tabs) ────────
local function getPlayerNames()
    local names = {}
    for _, p in next, Players:GetPlayers() do
        table.insert(names, p.Name)
    end
    return names
end

-- ── Cleanup ───────────────────────────────────────────────────────────────────

table.insert(VH.cleanupTasks, function()
    if landHighlight then pcall(function() landHighlight:Destroy() end) end
    abortAutoBuy = true
end)

print("[VanillaHub] Vanilla6 loaded. Tabs: AutoBuy, Slot.")
