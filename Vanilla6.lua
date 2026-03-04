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
local pages       = VH.pages   -- keyed "AutoBuyTab", "SlotTab", etc.

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

local function makeDropdown(page, placeholder, options, cb)
    -- outer container (not clipping so list can overflow)
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

    -- list renders inside the ScreenGui to avoid clipping
    local gui = game.CoreGui:FindFirstChild("VanillaHub")
    local list = Instance.new("Frame", gui)
    list.Name = "DropList"
    list.BackgroundColor3 = Color3.fromRGB(28,26,36)
    list.BorderSizePixel = 0
    list.ZIndex = 30
    list.Visible = false
    list.Size = UDim2.new(0,0,0,0)   -- sized dynamically
    corner(list, 6)

    local stroke = Instance.new("UIStroke", list)
    stroke.Color = Color3.fromRGB(60,50,80); stroke.Thickness = 1; stroke.Transparency = 0.5

    local ll = Instance.new("UIListLayout", list)
    ll.SortOrder = Enum.SortOrder.LayoutOrder

    local lpad = Instance.new("UIPadding", list)
    lpad.PaddingTop = UDim.new(0,3); lpad.PaddingBottom = UDim.new(0,3)

    local open = false

    local function close()
        open = false
        arrow.Text = "▾"
        list.Visible = false
    end

    local function openDrop()
        open = true
        arrow.Text = "▴"
        -- position list below the header in screen space
        local abs = hdr.AbsolutePosition
        local sz  = hdr.AbsoluteSize
        local itemH = 28
        local h = #options * itemH + 6
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
                close()
                cb(opt)
            end)
        end
    end

    rebuild(options)

    hdr.MouseButton1Click:Connect(function()
        if open then close() else openDrop() end
    end)

    -- close when clicking elsewhere
    UIS.InputBegan:Connect(function(i)
        if open and i.UserInputType == Enum.UserInputType.MouseButton1 then
            local mp = UIS:GetMouseLocation()
            local lp = list.AbsolutePosition
            local ls = list.AbsoluteSize
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
-- AUTO BUY TAB  (pages["AutoBuyTab"])
-- ═══════════════════════════════════════════════════════════════════════════

local ab = pages["AutoBuyTab"]

local ShopIDS = {
    WoodRUs=7, FurnitureStore=8, FineArt=11,
    CarStore=9, LogicStore=12, ShackShop=10,
}

local function isNetOwner(part)
    local ok, v = pcall(function() return part.ReceiveAge == 0 end)
    return ok and v
end

local function getPing()
    local t = tick()
    pcall(function() RS.TestPing:InvokeServer() end)
    return math.clamp((tick()-t)/2 + 0.5, 0.05, 3)
end

local function itemPrice(name)
    local total = 0
    for _, v in next, RS.ClientItemInfo:GetDescendants() do
        if v.Name == name and v:FindFirstChild("Price") then
            total = total + v.Price.Value
        end
    end
    return total
end

local function grabShopItems()
    local list = {}
    for _, store in next, workspace.Stores:GetChildren() do
        if store.Name == "ShopItems" then
            for _, item in next, store:GetChildren() do
                if item:FindFirstChild("Type") and item.Type.Value ~= "Blueprint"
                   and item:FindFirstChild("BoxItemName") then
                    local e = item.BoxItemName.Value.." — $"..itemPrice(item.BoxItemName.Value)
                    if not table.find(list, e) then
                        table.insert(list, e)
                        task.wait(0.01)
                    end
                end
            end
        end
    end
    table.sort(list)
    return #list > 0 and list or {"(no items found)"}
end

local function getShopPath(name)
    for _, store in next, workspace.Stores:GetChildren() do
        if store.Name == "ShopItems" then
            for _, item in next, store:GetChildren() do
                if item:FindFirstChild("Owner") and item.Owner.Value == nil
                   and item:FindFirstChild("BoxItemName") and item.BoxItemName.Value == name then
                    return item.Parent
                end
            end
        end
    end
end

local function getCounter(mainPart)
    for _, store in next, workspace.Stores:GetChildren() do
        if store.Name:lower() ~= "shopitems" then
            for _, ch in next, store:GetChildren() do
                if ch.Name:lower() == "counter"
                   and (mainPart.CFrame.p - ch.CFrame.p).Magnitude <= 200 then
                    return ch
                end
            end
        end
    end
end

local function pay(id)
    task.spawn(function()
        RS.NPCDialog.PlayerChatted:InvokeServer(
            {ID=id, Character="n", Name="n", Dialog="d"}, "ConfirmPurchase")
    end)
end

local function refreshNames()
    for _, store in next, workspace.Stores:GetChildren() do
        if store.Name == "ShopItems" then
            store.ChildAdded:Connect(function(ch)
                local bn = ch:FindFirstChild("BoxItemName")
                if bn then task.wait() ch.Name = bn.Value end
            end)
            for _, item in next, store:GetChildren() do
                if item:FindFirstChild("Owner") and item.Owner.Value == nil
                   and item:FindFirstChild("BoxItemName") then
                    item.Name = item.BoxItemName.Value
                end
            end
        end
    end
end
refreshNames()

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

local abortBuy = false
local buyItem  = nil
local buyAmt   = 1
local buyOpen  = false

local function doBuy(name, amount, openBox, prog, stat)
    if not name or name == "(no items found)" then
        stat.SetActive(false, "No item selected!")
        return
    end
    abortBuy = false
    local oldPos = LP.Character and LP.Character.HumanoidRootPart
                   and LP.Character.HumanoidRootPart.CFrame
    local path = getShopPath(name)
    if not path then stat.SetActive(false, "Item not found in stores.") return end
    stat.SetActive(true, "Buying: "..name)

    for i = 1, amount do
        if abortBuy then break end
        local m = path:FindFirstChild(name)
        if not m then task.wait(1); m = path:FindFirstChild(name) end
        if not m then break end
        local counter = m:FindFirstChild("Main") and getCounter(m.Main)
        if not counter then break end

        pcall(function() LP.Character.HumanoidRootPart.CFrame = m.Main.CFrame + Vector3.new(5,0,5) end)

        local t0 = tick()
        repeat RS.Interaction.ClientIsDragging:FireServer(m); task.wait()
        until (m.Owner.Value ~= nil) or (tick()-t0 > 5)
        if m.Owner.Value ~= LP then break end

        local t1 = tick()
        repeat RS.Interaction.ClientIsDragging:FireServer(m); task.wait()
        until isNetOwner(m.Main) or (tick()-t1 > 5)

        pcall(function()
            RS.Interaction.ClientIsDragging:FireServer(m)
            m.Main.CFrame = counter.CFrame + Vector3.new(0, m.Main.Size.Y, 0.5)
        end)
        task.wait(getPing())

        pcall(function() LP.Character.HumanoidRootPart.CFrame = counter.CFrame + Vector3.new(5,0,5) end)
        task.wait(getPing())

        local t2 = tick()
        repeat
            if abortBuy then break end
            pcall(function() RS.Interaction.ClientIsDragging:FireServer(m) end)
            pay(ShopIDS[counter.Parent.Name] or 7)
            task.wait()
        until m.Parent ~= path or (tick()-t2 > 8)

        pcall(function()
            local t3 = tick()
            repeat RS.Interaction.ClientIsDragging:FireServer(m); task.wait()
            until isNetOwner(m.Main) or (tick()-t3 > 5)
            RS.Interaction.ClientIsDragging:FireServer(m)
            if oldPos then m.Main.CFrame = oldPos end
            task.wait(getPing())
        end)

        if openBox then
            pcall(function() RS.Interaction.ClientInteracted:FireServer(m, "Open box") end)
        end

        prog.Set(i, amount, "Buying... "..i.." / "..amount)
        task.wait()
    end

    pcall(function()
        if oldPos then LP.Character.HumanoidRootPart.CFrame = oldPos + Vector3.new(5,1,0) end
    end)
    stat.SetActive(false, abortBuy and "Aborted." or "Done!")
    prog.Set(amount, amount, abortBuy and "Aborted" or "Complete!")
end

-- Build AutoBuy UI
sectionLabel(ab, "Item Selection")

local shopDD = makeDropdown(ab, "Select Item...", grabShopItems(), function(val)
    buyItem = val:match("^(.-)%s*%—") or val
end)

sectionLabel(ab, "Options")
makeSlider(ab, "Amount", 1, 100, 1, function(v) buyAmt = v end)
makeToggle(ab, "Open Box After Buying", false, function(v) buyOpen = v end)
sep(ab)

local abStat = makeStatus(ab, "Idle")
local abProg = makeProgress(ab)

makeButton(ab, "↻  Refresh Item List", function()
    shopDD:SetOptions(grabShopItems())
end)
makeButton(ab, "Purchase Selected Item(s)", function()
    task.spawn(doBuy, buyItem, buyAmt, buyOpen, abProg, abStat)
end)
makeButton(ab, "Abort Purchasing", function()
    abortBuy = true
    abStat.SetActive(false, "Aborted by user.")
end)

sep(ab)
sectionLabel(ab, "Quick Purchases")

makeButton(ab, "Buy All Missing Blueprints", function()
    local bps = getMissingBlueprints()
    abStat.SetActive(true, "Buying "..#bps.." blueprints...")
    for _, v in next, bps do
        if abortBuy then break end
        doBuy(v, 1, true, abProg, abStat)
    end
    abStat.SetActive(false, "Blueprints done.")
end)
makeButton(ab, "Pay Toll Bridge", function() pay(15) end)
makeButton(ab, "Buy Ferry Ticket", function() pay(13) end)
makeButton(ab, "Buy Power of Ease", function() pay(3) end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SLOT TAB  (pages["SlotTab"])
-- ═══════════════════════════════════════════════════════════════════════════

local sl = pages["SlotTab"]

local slotNum   = 1
local landToTake = nil
local landHL    = nil

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

-- Build Slot UI
sectionLabel(sl, "Fast Load")
makeSlider(sl, "Slot Number", 1, 6, 1, function(v) slotNum = v end)
makeToggle(sl, "Skip Loading Animation", false, function(v)
    -- skip loading flag (handled server-side once slot loads)
    _G.VH.skipSlotLoading = v
end)
makeButton(sl, "Load Base", function() loadSlot(slotNum) end)

sep(sl)
sectionLabel(sl, "Land Management")
makeButton(sl, "Claim Free Land", freeLand)
makeButton(sl, "Max Expand Land", maxLand)
makeButton(sl, "Sell Sold Sign", sellSoldSign)

sep(sl)
sectionLabel(sl, "Land Claim")

makeDropdown(sl, "Select Land Plot...", {"1","2","3","4","5","6","7","8","9"}, function(val)
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
    abortBuy = true
    if landHL then pcall(function() landHL:Destroy() end) end
end)

print("[VanillaHub] Vanilla6 loaded — AutoBuy, Slot")
