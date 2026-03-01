-- ════════════════════════════════════════════════════
-- IMPORT SHARED GLOBALS FROM Vanilla1
-- ════════════════════════════════════════════════════
local TweenService     = _G.VH_TweenService
local Players          = _G.VH_Players
local UserInputService = _G.VH_UserInputService
local RunService       = _G.VH_RunService
local player           = _G.VH_player
local cleanupTasks     = _G.VH_cleanupTasks
local pages            = _G.VH_pages
local switchTab        = _G.VH_switchTab
local toggleGUI        = _G.VH_toggleGUI
local stopFly          = _G.VH_stopFly
local startFly         = _G.VH_startFly
-- _G.VH_butter.running managed via _G.VH_butter
-- _G.VH_butter.thread managed via _G.VH_butter

-- ════════════════════════════════════════════════════
-- AUTOBUY TAB
-- ════════════════════════════════════════════════════
do
local autoBuyPage = pages["AutoBuyTab"]

local autoBuyRunning   = false
local autoBuyThread    = nil
local autoBuyCircle    = nil   -- destination marker (same as item tab)
local autoBuyAmount    = 1

-- ── Item database ─────────────────────────────────────────────────────────────
-- { display, itemId (as it appears in PurchasedBoxItemName / shop remote) }
local AB_ITEMS = {
    -- ── Wood R Us ─────────────────────────────────
    { cat="Wood R Us",     name="Basic Hatchet",                id="Basic Hatchet" },
    { cat="Wood R Us",     name="Plain Axe",                    id="Plain Axe" },
    { cat="Wood R Us",     name="Steel Axe",                    id="Steel Axe" },
    { cat="Wood R Us",     name="Hardened Axe",                 id="Hardened Axe" },
    { cat="Wood R Us",     name="Silver Axe",                   id="Silver Axe" },
    { cat="Wood R Us",     name="Bluesteel Axe",                id="Bluesteel Axe" },
    { cat="Wood R Us",     name="Rukiryaxe",                    id="Rukiryaxe" },
    { cat="Wood R Us",     name="Frost Axe",                    id="Frost Axe" },
    { cat="Wood R Us",     name="Shabby Sawmill",               id="Shabby Sawmill" },
    { cat="Wood R Us",     name="Fair Sawmill",                 id="Fair Sawmill" },
    { cat="Wood R Us",     name="Chop Saw",                     id="Chop Saw" },
    { cat="Wood R Us",     name="Basic Conveyor",               id="Basic Conveyor" },
    { cat="Wood R Us",     name="End Conveyor",                 id="End Conveyor" },
    { cat="Wood R Us",     name="Wire",                         id="Wire" },
    { cat="Wood R Us",     name="Button",                       id="Button" },
    { cat="Wood R Us",     name="Lever",                        id="Lever" },
    { cat="Wood R Us",     name="Pressure Plate",               id="Pressure Plate" },
    { cat="Wood R Us",     name="Land",                         id="Land" },
    { cat="Wood R Us",     name="Bulletin Board",               id="Bulletin Board" },
    { cat="Wood R Us",     name="Dynamite",                     id="Dynamite" },
    { cat="Wood R Us",     name="Bag of Candy",                 id="Bag of Candy" },
    { cat="Wood R Us",     name="Blue Bag of Candy",            id="Blue Bag of Candy" },
    { cat="Wood R Us",     name="Crimson Bag of Candy",         id="Crimson Bag of Candy" },
    { cat="Wood R Us",     name="Plain Bag of Candy",           id="Plain Bag of Candy" },
    { cat="Wood R Us",     name="Can of Worms",                 id="Can of Worms" },
    { cat="Wood R Us",     name="Bag of Sand",                  id="Bag of Sand" },
    { cat="Wood R Us",     name="Lightbulb",                    id="Lightbulb" },
    { cat="Wood R Us",     name="Big Gift",                     id="Big Gift" },
    { cat="Wood R Us",     name="Blue Bone Turkey",             id="Blue Bone Turkey" },
    { cat="Wood R Us",     name="Can of Mashed Potatoes",       id="Can of Mashed Potatoes" },
    -- ── Boxed Cars ─────────────────────────────────
    { cat="Boxed Cars",    name="Small Transport",              id="Small Transport" },
    { cat="Boxed Cars",    name="Val's All-Purpose Hauler",     id="Val's All-Purpose Hauler" },
    { cat="Boxed Cars",    name="Small Trailer",                id="Small Trailer" },
    { cat="Boxed Cars",    name="Large Flatbed Trailer",        id="Large Flatbed Trailer" },
    -- ── Fancy Furnishings ──────────────────────────
    { cat="Fancy Furnishings", name="Couch",                   id="Couch" },
    { cat="Fancy Furnishings", name="Chair",                   id="Chair" },
    { cat="Fancy Furnishings", name="Lounge Chair",            id="Lounge Chair" },
    { cat="Fancy Furnishings", name="Table",                   id="Table" },
    { cat="Fancy Furnishings", name="Coffee Table",            id="Coffee Table" },
    { cat="Fancy Furnishings", name="Bed",                     id="Bed" },
    { cat="Fancy Furnishings", name="Lamp",                    id="Lamp" },
    { cat="Fancy Furnishings", name="Rug",                     id="Rug" },
    { cat="Fancy Furnishings", name="Shelf",                   id="Shelf" },
    { cat="Fancy Furnishings", name="Refrigerator",            id="Refrigerator" },
    { cat="Fancy Furnishings", name="Cabinet",                 id="Cabinet" },
    { cat="Fancy Furnishings", name="Door",                    id="Door" },
    { cat="Fancy Furnishings", name="Window",                  id="Window" },
    { cat="Fancy Furnishings", name="Large Glass Pane",        id="Large Glass Pane" },
    { cat="Fancy Furnishings", name="Curtains",                id="Curtains" },
    { cat="Fancy Furnishings", name="Clock",                   id="Clock" },
    { cat="Fancy Furnishings", name="Fireplace",               id="Fireplace" },
    { cat="Fancy Furnishings", name="Sink",                    id="Sink" },
    { cat="Fancy Furnishings", name="Toilet",                  id="Toilet" },
    { cat="Fancy Furnishings", name="Bathtub",                 id="Bathtub" },
    { cat="Fancy Furnishings", name="Mailbox",                 id="Mailbox" },
    { cat="Fancy Furnishings", name="TV",                      id="TV" },
    { cat="Fancy Furnishings", name="Picture Frame",           id="Picture Frame" },
    -- ── Link's Logic ───────────────────────────────
    { cat="Link's Logic",  name="Wire",                         id="Wire" },
    { cat="Link's Logic",  name="Neon Wire (Red)",              id="Neon Wire (Red)" },
    { cat="Link's Logic",  name="Neon Wire (Blue)",             id="Neon Wire (Blue)" },
    { cat="Link's Logic",  name="Lever",                        id="Lever" },
    { cat="Link's Logic",  name="Button",                       id="Button" },
    { cat="Link's Logic",  name="Pressure Plate",               id="Pressure Plate" },
    { cat="Link's Logic",  name="Wood Detector",                id="Wood Detector" },
    { cat="Link's Logic",  name="Laser Detector",               id="Laser Detector" },
    { cat="Link's Logic",  name="Signal Inverter",              id="Signal Inverter" },
    { cat="Link's Logic",  name="Signal Delay",                 id="Signal Delay" },
    { cat="Link's Logic",  name="Signal Sustain",               id="Signal Sustain" },
    { cat="Link's Logic",  name="OR Gate",                      id="OR Gate" },
    { cat="Link's Logic",  name="AND Gate",                     id="AND Gate" },
    { cat="Link's Logic",  name="XOR Gate",                     id="XOR Gate" },
    { cat="Link's Logic",  name="Clock Switch",                 id="Clock Switch" },
    { cat="Link's Logic",  name="Hatch",                        id="Hatch" },
    { cat="Link's Logic",  name="Monitor",                      id="Monitor" },
    { cat="Link's Logic",  name="Speaker",                      id="Speaker" },
    -- ── Fine Arts Shop ─────────────────────────────
    { cat="Fine Arts Shop", name="Outdoor Watercolor Sketch",   id="Outdoor Watercolor Sketch" },
    { cat="Fine Arts Shop", name="Title Unknown",               id="Title Unknown" },
    { cat="Fine Arts Shop", name="Disturbed Painting",          id="Disturbed Painting" },
    { cat="Fine Arts Shop", name="Arctic Light",                id="Arctic Light" },
    { cat="Fine Arts Shop", name="Gloomy Seascape at Dusk",     id="Gloomy Seascape at Dusk" },
    { cat="Fine Arts Shop", name="Pineapple",                   id="Pineapple" },
    { cat="Fine Arts Shop", name="Bold and Brash",              id="Bold and Brash" },
    { cat="Fine Arts Shop", name="06 In Full Context",          id="06 In Full Context" },
    -- ── Bob's Shack ────────────────────────────────
    { cat="Bob's Shack",   name="Can of Worms",                 id="Can of Worms" },
    { cat="Bob's Shack",   name="Dynamite",                     id="Dynamite" },
    { cat="Bob's Shack",   name="Orange Pumpkin",               id="Orange Pumpkin" },
    { cat="Bob's Shack",   name="Purple Pumpkin",               id="Purple Pumpkin" },
    { cat="Bob's Shack",   name="Preserved Enlarged Ostrich Eye", id="Preserved Enlarged Ostrich Eye" },
}

-- ── UI helpers (scoped to autoBuyPage) ────────────────────────────────────────
local AB_BTN   = Color3.fromRGB(45,45,50)
local AB_GREEN = Color3.fromRGB(35,90,45)

local function abSection(text)
    local lbl = Instance.new("TextLabel", autoBuyPage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function abSep()
    local s = Instance.new("Frame", autoBuyPage)
    s.Size = UDim2.new(1,-12,0,1); s.BackgroundColor3 = Color3.fromRGB(40,40,55); s.BorderSizePixel = 0
end

local function abBtn(text, color, cb)
    color = color or AB_BTN
    local btn = Instance.new("TextButton", autoBuyPage)
    btn.Size = UDim2.new(1,-12,0,32); btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(210,210,220); btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local hov = Color3.fromRGB(math.min(color.R*255+20,255)/255, math.min(color.G*255+8,255)/255, math.min(color.B*255+20,255)/255)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=hov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=color}):Play() end)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

-- ── Status pill ───────────────────────────────────────────────────────────────
abSection("Status")
local abStatusFrame = Instance.new("Frame", autoBuyPage)
abStatusFrame.Size = UDim2.new(1,-12,0,28); abStatusFrame.BackgroundColor3 = Color3.fromRGB(14,14,18)
abStatusFrame.BorderSizePixel = 0
Instance.new("UICorner", abStatusFrame).CornerRadius = UDim.new(0,6)
local abDot = Instance.new("Frame", abStatusFrame)
abDot.Size = UDim2.new(0,7,0,7); abDot.Position = UDim2.new(0,10,0.5,-3)
abDot.BackgroundColor3 = Color3.fromRGB(80,80,100); abDot.BorderSizePixel = 0
Instance.new("UICorner", abDot).CornerRadius = UDim.new(1,0)
local abStatusLbl = Instance.new("TextLabel", abStatusFrame)
abStatusLbl.Size = UDim2.new(1,-28,1,0); abStatusLbl.Position = UDim2.new(0,24,0,0)
abStatusLbl.BackgroundTransparency = 1; abStatusLbl.Font = Enum.Font.Gotham; abStatusLbl.TextSize = 12
abStatusLbl.TextColor3 = Color3.fromRGB(150,150,170); abStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
abStatusLbl.Text = "Ready"

local function setABStatus(msg, active)
    abStatusLbl.Text = msg
    abDot.BackgroundColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
end

abSep()

-- ── Item dropdown ─────────────────────────────────────────────────────────────
abSection("Select Item")

local abSelectedItem = nil   -- { name, id, cat }
local abDropOpen     = false
local AB_ITEM_H      = 34
local AB_MAX_SHOW    = 6
local AB_HEADER_H    = 42

local abDropOuter = Instance.new("Frame", autoBuyPage)
abDropOuter.Size             = UDim2.new(1,-12,0,AB_HEADER_H)
abDropOuter.BackgroundColor3 = Color3.fromRGB(22,22,30)
abDropOuter.BorderSizePixel  = 0
abDropOuter.ClipsDescendants = true
Instance.new("UICorner", abDropOuter).CornerRadius = UDim.new(0,8)
local abDropStroke = Instance.new("UIStroke", abDropOuter)
abDropStroke.Color = Color3.fromRGB(60,60,90); abDropStroke.Thickness = 1; abDropStroke.Transparency = 0.5

-- Header
local abDropHeader = Instance.new("Frame", abDropOuter)
abDropHeader.Size = UDim2.new(1,0,0,AB_HEADER_H); abDropHeader.BackgroundTransparency = 1

local abDropSelFrame = Instance.new("Frame", abDropHeader)
abDropSelFrame.Size = UDim2.new(1,-16,0,30); abDropSelFrame.Position = UDim2.new(0,8,0.5,-15)
abDropSelFrame.BackgroundColor3 = Color3.fromRGB(30,30,42); abDropSelFrame.BorderSizePixel = 0
Instance.new("UICorner", abDropSelFrame).CornerRadius = UDim.new(0,6)
local abDropSelStroke = Instance.new("UIStroke", abDropSelFrame)
abDropSelStroke.Color = Color3.fromRGB(70,70,110); abDropSelStroke.Thickness = 1; abDropSelStroke.Transparency = 0.4

local abDropSelLbl = Instance.new("TextLabel", abDropSelFrame)
abDropSelLbl.Size = UDim2.new(1,-32,1,0); abDropSelLbl.Position = UDim2.new(0,10,0,0)
abDropSelLbl.BackgroundTransparency = 1; abDropSelLbl.Font = Enum.Font.GothamSemibold; abDropSelLbl.TextSize = 12
abDropSelLbl.TextColor3 = Color3.fromRGB(110,110,140); abDropSelLbl.TextXAlignment = Enum.TextXAlignment.Left
abDropSelLbl.Text = "Select an item..."; abDropSelLbl.TextTruncate = Enum.TextTruncate.AtEnd

local abDropArrow = Instance.new("TextLabel", abDropSelFrame)
abDropArrow.Size = UDim2.new(0,22,1,0); abDropArrow.Position = UDim2.new(1,-24,0,0)
abDropArrow.BackgroundTransparency = 1; abDropArrow.Text = "▾"
abDropArrow.Font = Enum.Font.GothamBold; abDropArrow.TextSize = 14
abDropArrow.TextColor3 = Color3.fromRGB(120,120,160); abDropArrow.TextXAlignment = Enum.TextXAlignment.Center

local abDropHeaderBtn = Instance.new("TextButton", abDropSelFrame)
abDropHeaderBtn.Size = UDim2.new(1,0,1,0); abDropHeaderBtn.BackgroundTransparency = 1
abDropHeaderBtn.Text = ""; abDropHeaderBtn.ZIndex = 5

-- Search box inside dropdown (appears when open)
local abDropSearchBox = Instance.new("TextBox", abDropOuter)
abDropSearchBox.Size = UDim2.new(1,-16,0,28)
abDropSearchBox.Position = UDim2.new(0,8,0,AB_HEADER_H+2)
abDropSearchBox.BackgroundColor3 = Color3.fromRGB(28,28,40)
abDropSearchBox.BorderSizePixel = 0; abDropSearchBox.PlaceholderText = "🔍 Search items..."
abDropSearchBox.Text = ""; abDropSearchBox.Font = Enum.Font.GothamSemibold; abDropSearchBox.TextSize = 12
abDropSearchBox.TextColor3 = Color3.fromRGB(200,200,220); abDropSearchBox.ClearTextOnFocus = false
abDropSearchBox.Visible = false
Instance.new("UICorner", abDropSearchBox).CornerRadius = UDim.new(0,6)
Instance.new("UIPadding", abDropSearchBox).PaddingLeft = UDim.new(0,8)

-- Divider
local abDropDiv = Instance.new("Frame", abDropOuter)
abDropDiv.BackgroundColor3 = Color3.fromRGB(50,50,75); abDropDiv.BorderSizePixel = 0
abDropDiv.Visible = false

-- Scroll list
local abDropScroll = Instance.new("ScrollingFrame", abDropOuter)
abDropScroll.BackgroundTransparency = 1; abDropScroll.BorderSizePixel = 0
abDropScroll.ScrollBarThickness = 3; abDropScroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
abDropScroll.CanvasSize = UDim2.new(0,0,0,0); abDropScroll.ClipsDescendants = true
abDropScroll.Size = UDim2.new(1,0,0,0)

local abDropLayout = Instance.new("UIListLayout", abDropScroll)
abDropLayout.SortOrder = Enum.SortOrder.LayoutOrder; abDropLayout.Padding = UDim.new(0,3)
abDropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    abDropScroll.CanvasSize = UDim2.new(0,0,0, abDropLayout.AbsoluteContentSize.Y+6)
end)
local abDropPad = Instance.new("UIPadding", abDropScroll)
abDropPad.PaddingTop = UDim.new(0,4); abDropPad.PaddingBottom = UDim.new(0,4)
abDropPad.PaddingLeft = UDim.new(0,6); abDropPad.PaddingRight = UDim.new(0,6)

-- ── Build list helper ─────────────────────────────────────────────────────────
local function abBuildList(filter)
    filter = string.lower(filter or "")
    for _, c in ipairs(abDropScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
    local i = 0
    local lastCat = nil
    for _, item in ipairs(AB_ITEMS) do
        local matches = filter == "" or
            string.find(string.lower(item.name), filter) or
            string.find(string.lower(item.cat), filter)
        if matches then
            -- Category header if changed
            if item.cat ~= lastCat then
                lastCat = item.cat
                i += 1
                local catLbl = Instance.new("TextLabel", abDropScroll)
                catLbl.Size = UDim2.new(1,-4,0,20); catLbl.BackgroundTransparency = 1
                catLbl.Font = Enum.Font.GothamBold; catLbl.TextSize = 10
                catLbl.TextColor3 = Color3.fromRGB(100,100,140); catLbl.TextXAlignment = Enum.TextXAlignment.Left
                catLbl.Text = "  " .. string.upper(item.cat)
                catLbl.LayoutOrder = i
            end
            -- Row
            i += 1
            local isSelected = abSelectedItem and abSelectedItem.id == item.id and abSelectedItem.cat == item.cat
            local row = Instance.new("Frame", abDropScroll)
            row.Size = UDim2.new(1,0,0,AB_ITEM_H); row.LayoutOrder = i
            row.BackgroundColor3 = isSelected and Color3.fromRGB(45,45,75) or Color3.fromRGB(28,28,40)
            row.BorderSizePixel = 0
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1,-36,1,0); nameLbl.Position = UDim2.new(0,10,0,0)
            nameLbl.BackgroundTransparency = 1; nameLbl.Font = Enum.Font.GothamSemibold; nameLbl.TextSize = 12
            nameLbl.TextColor3 = isSelected and Color3.fromRGB(210,215,255) or Color3.fromRGB(200,200,215)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.Text = item.name
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

            if isSelected then
                local chk = Instance.new("TextLabel", row)
                chk.Size = UDim2.new(0,24,1,0); chk.Position = UDim2.new(1,-28,0,0)
                chk.BackgroundTransparency = 1; chk.Text = "✓"
                chk.Font = Enum.Font.GothamBold; chk.TextSize = 14
                chk.TextColor3 = Color3.fromRGB(120,180,255); chk.TextXAlignment = Enum.TextXAlignment.Center
            end

            local rowBtn = Instance.new("TextButton", row)
            rowBtn.Size = UDim2.new(1,0,1,0); rowBtn.BackgroundTransparency = 1
            rowBtn.Text = ""; rowBtn.ZIndex = 5
            rowBtn.MouseEnter:Connect(function()
                if not isSelected then TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(38,38,58)}):Play() end
            end)
            rowBtn.MouseLeave:Connect(function()
                if not isSelected then TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28,28,40)}):Play() end
            end)
            rowBtn.MouseButton1Click:Connect(function()
                abSelectedItem = item
                abDropSelLbl.Text = item.name
                abDropSelLbl.TextColor3 = Color3.fromRGB(220,225,255)
                abDropArrow.TextColor3 = Color3.fromRGB(160,160,210)
                abDropStroke.Color = Color3.fromRGB(90,90,160)
                setABStatus("Item selected: " .. item.name, false)
                task.delay(0.05, function()
                    abDropOpen = false
                    abDropSearchBox.Visible = false
                    abDropDiv.Visible = false
                    TweenService:Create(abDropArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
                    TweenService:Create(abDropOuter, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,AB_HEADER_H)}):Play()
                    TweenService:Create(abDropScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
                end)
            end)
        end
    end
end

local function abOpenDrop()
    abDropOpen = true
    abDropSearchBox.Visible = true
    abDropSearchBox.Text = ""
    abBuildList("")
    local countFiltered = 0
    for _, item in ipairs(AB_ITEMS) do countFiltered += 1 end
    local SEARCH_H = 34
    local listH = math.min(countFiltered, AB_MAX_SHOW) * (AB_ITEM_H + 3) + 8
    local totalH = AB_HEADER_H + SEARCH_H + 4 + listH
    abDropScroll.Position = UDim2.new(0,0,0, AB_HEADER_H + SEARCH_H + 4)
    abDropDiv.Size = UDim2.new(1,-16,0,1)
    abDropDiv.Position = UDim2.new(0,8,0, AB_HEADER_H + SEARCH_H + 2)
    abDropDiv.Visible = true
    TweenService:Create(abDropArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=180}):Play()
    TweenService:Create(abDropOuter, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,totalH)}):Play()
    TweenService:Create(abDropScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,listH)}):Play()
end

local function abCloseDrop()
    abDropOpen = false
    abDropSearchBox.Visible = false
    abDropDiv.Visible = false
    TweenService:Create(abDropArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
    TweenService:Create(abDropOuter, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,AB_HEADER_H)}):Play()
    TweenService:Create(abDropScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
end

abDropHeaderBtn.MouseButton1Click:Connect(function()
    if abDropOpen then abCloseDrop() else abOpenDrop() end
end)
abDropHeaderBtn.MouseEnter:Connect(function()
    TweenService:Create(abDropSelFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play()
end)
abDropHeaderBtn.MouseLeave:Connect(function()
    TweenService:Create(abDropSelFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(30,30,42)}):Play()
end)

-- Live search filter
abDropSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if not abDropOpen then return end
    local q = abDropSearchBox.Text
    abBuildList(q)
    local SEARCH_H = 34
    -- recount visible items
    local count = 0
    for _, item in ipairs(AB_ITEMS) do
        local lq = string.lower(q)
        if lq == "" or string.find(string.lower(item.name), lq) or string.find(string.lower(item.cat), lq) then
            count += 1
        end
    end
    local listH = math.min(math.max(count,1), AB_MAX_SHOW) * (AB_ITEM_H + 3) + 8
    local totalH = AB_HEADER_H + SEARCH_H + 4 + listH
    abDropOuter.Size = UDim2.new(1,-12,0,totalH)
    abDropScroll.Size = UDim2.new(1,0,0,listH)
end)

abSep()

-- ── Amount slider ─────────────────────────────────────────────────────────────
abSection("Amount")

do
    local sliderFrame = Instance.new("Frame", autoBuyPage)
    sliderFrame.Size = UDim2.new(1,-12,0,52); sliderFrame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    sliderFrame.BorderSizePixel = 0
    Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0,6)

    local topRow = Instance.new("Frame", sliderFrame)
    topRow.Size = UDim2.new(1,-16,0,22); topRow.Position = UDim2.new(0,8,0,6); topRow.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.7,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Buy Amount"

    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.3,0,1,0); valLbl.Position = UDim2.new(0.7,0,0,0)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3 = Color3.fromRGB(200,200,255); valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = "1"

    local track = Instance.new("Frame", sliderFrame)
    track.Size = UDim2.new(1,-16,0,6); track.Position = UDim2.new(0,8,0,36)
    track.BackgroundColor3 = Color3.fromRGB(40,40,55); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,80,100); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0,16,0,16); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(0,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(210,210,225); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local abSliderDragging = false
    local function updateABSlider(absX)
        local ratio = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.max(1, math.round(1 + ratio * (250 - 1)))
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valLbl.Text = tostring(val)
        autoBuyAmount = val
    end
    knob.MouseButton1Down:Connect(function() abSliderDragging = true end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            abSliderDragging = true; updateABSlider(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if abSliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateABSlider(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then abSliderDragging = false end
    end)
end

abSep()

-- ── Destination (same system as Item tab) ─────────────────────────────────────
abSection("Teleport Destination")

local abTpRow = Instance.new("Frame", autoBuyPage)
abTpRow.Size = UDim2.new(1,-12,0,32); abTpRow.BackgroundTransparency = 1

local abTpSet = Instance.new("TextButton", abTpRow)
abTpSet.Size = UDim2.new(0.5,-4,1,0); abTpSet.Position = UDim2.new(0,0,0,0)
abTpSet.BackgroundColor3 = AB_BTN; abTpSet.Font = Enum.Font.GothamSemibold
abTpSet.TextSize = 12; abTpSet.TextColor3 = Color3.fromRGB(210,210,220); abTpSet.Text = "Set Destination"
Instance.new("UICorner", abTpSet).CornerRadius = UDim.new(0,6)

local abTpRemove = Instance.new("TextButton", abTpRow)
abTpRemove.Size = UDim2.new(0.5,-4,1,0); abTpRemove.Position = UDim2.new(0.5,4,0,0)
abTpRemove.BackgroundColor3 = AB_BTN; abTpRemove.Font = Enum.Font.GothamSemibold
abTpRemove.TextSize = 12; abTpRemove.TextColor3 = Color3.fromRGB(210,210,220); abTpRemove.Text = "Remove Destination"
Instance.new("UICorner", abTpRemove).CornerRadius = UDim.new(0,6)

for _, b in {abTpSet, abTpRemove} do
    local baseCol = AB_BTN
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(70,70,80)}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=baseCol}):Play() end)
end

abTpSet.MouseButton1Click:Connect(function()
    if autoBuyCircle then autoBuyCircle:Destroy() end
    autoBuyCircle = Instance.new("Part")
    autoBuyCircle.Name = "VanillaHubABCircle"
    autoBuyCircle.Shape = Enum.PartType.Ball
    autoBuyCircle.Size = Vector3.new(3,3,3)
    autoBuyCircle.Material = Enum.Material.SmoothPlastic
    autoBuyCircle.Color = Color3.fromRGB(80,200,120)
    autoBuyCircle.Anchored = true; autoBuyCircle.CanCollide = false
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        autoBuyCircle.Position = char.HumanoidRootPart.Position
    end
    autoBuyCircle.Parent = workspace
    setABStatus("Destination set!", false)
end)

abTpRemove.MouseButton1Click:Connect(function()
    if autoBuyCircle then autoBuyCircle:Destroy(); autoBuyCircle = nil end
    setABStatus("Destination removed", false)
end)

abSep()

-- ── Progress bar ──────────────────────────────────────────────────────────────
local abProgContainer, abSetProg, abResetProg
do
    local container = Instance.new("Frame", autoBuyPage)
    container.Size = UDim2.new(1,-12,0,44); container.BackgroundColor3 = Color3.fromRGB(18,18,24)
    container.BorderSizePixel = 0; container.Visible = false
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,7)

    local topLbl = Instance.new("TextLabel", container)
    topLbl.Size = UDim2.new(0.6,0,0,18); topLbl.Position = UDim2.new(0,10,0,4)
    topLbl.BackgroundTransparency = 1; topLbl.Font = Enum.Font.GothamSemibold; topLbl.TextSize = 11
    topLbl.TextColor3 = Color3.fromRGB(180,180,220); topLbl.TextXAlignment = Enum.TextXAlignment.Left
    topLbl.Text = "Buying..."

    local cntLbl = Instance.new("TextLabel", container)
    cntLbl.Size = UDim2.new(0.4,-10,0,18); cntLbl.Position = UDim2.new(0.6,0,0,4)
    cntLbl.BackgroundTransparency = 1; cntLbl.Font = Enum.Font.GothamBold; cntLbl.TextSize = 11
    cntLbl.TextColor3 = Color3.fromRGB(120,160,255); cntLbl.TextXAlignment = Enum.TextXAlignment.Right
    cntLbl.Text = "0 / 0"

    local track = Instance.new("Frame", container)
    track.Size = UDim2.new(1,-16,0,8); track.Position = UDim2.new(0,8,0,26)
    track.BackgroundColor3 = Color3.fromRGB(30,30,42); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(0,0,1,0); fill.BackgroundColor3 = Color3.fromRGB(80,180,255)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    abProgContainer = container
    abSetProg = function(done, total)
        local pct = math.clamp(done/math.max(total,1), 0, 1)
        cntLbl.Text = done .. " / " .. total
        local blue = Color3.fromRGB(80,180,255); local green = Color3.fromRGB(60,200,110)
        local col = pct>=1 and green or Color3.fromRGB(
            math.floor(blue.R*255+(green.R*255-blue.R*255)*pct)/255,
            math.floor(blue.G*255+(green.G*255-blue.G*255)*pct)/255,
            math.floor(blue.B*255+(green.B*255-blue.B*255)*pct)/255
        )
        TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size=UDim2.new(pct,0,1,0), BackgroundColor3=col}):Play()
    end
    abResetProg = function()
        fill.Size = UDim2.new(0,0,1,0); fill.BackgroundColor3 = Color3.fromRGB(80,180,255)
        cntLbl.Text = "0 / 0"; container.Visible = false
    end
end

-- ── Buy / Cancel buttons ───────────────────────────────────────────────────────
abSection("Actions")

abBtn("Start AutoBuy", AB_GREEN, function()
    if autoBuyRunning then setABStatus("Already running!", true) return end
    if not abSelectedItem then setABStatus("Select an item first!", false) return end

    autoBuyRunning = true
    abResetProg()
    abProgContainer.Visible = true
    abSetProg(0, autoBuyAmount)
    setABStatus("Buying " .. abSelectedItem.name .. "...", true)

    autoBuyThread = task.spawn(function()
        local RS   = game:GetService("ReplicatedStorage")
        local LP   = Players.LocalPlayer
        local char = LP.Character or LP.CharacterAdded:Wait()
        local hrp  = char:WaitForChild("HumanoidRootPart")

        -- Find the shop remote — LT2 uses BuyItemServer or similar
        local buyRemote = RS:FindFirstChild("BuyItemServer")
            or RS:FindFirstChild("PurchaseItem")
            or RS:FindFirstChild("BuyItem")
            or (RS:FindFirstChild("Shop") and RS.Shop:FindFirstChildOfClass("RemoteEvent"))
            or (RS:FindFirstChild("Interaction") and RS.Interaction:FindFirstChild("BuyItemServer"))

        local done = 0
        local total = autoBuyAmount

        for i = 1, total do
            if not autoBuyRunning then break end

            -- Fire purchase remote
            if buyRemote then
                pcall(function()
                    buyRemote:FireServer(abSelectedItem.id)
                end)
            end

            -- Wait a tiny bit for the item to appear in workspace
            task.wait(0.15)

            -- If destination is set, teleport the freshly-bought item there
            if autoBuyCircle and autoBuyCircle.Parent then
                -- Find the most recently spawned item matching our selection
                local newest = nil
                local newestTime = 0
                for _, v in pairs(workspace:GetDescendants()) do
                    if v.Name == "Owner" then
                        local ownerVal = tostring(v.Value)
                        if ownerVal == LP.Name then
                            local p = v.Parent
                            local iname = p:FindFirstChild("PurchasedBoxItemName") or p:FindFirstChild("ItemName")
                            if iname and string.find(string.lower(tostring(iname.Value)), string.lower(abSelectedItem.id)) then
                                local mainPart = p:FindFirstChild("Main") or p:FindFirstChildOfClass("BasePart")
                                if mainPart then
                                    -- pick item closest to player spawnpoint (most recently bought)
                                    local dist = (hrp.Position - mainPart.Position).Magnitude
                                    if dist < 200 then
                                        newest = mainPart
                                    end
                                end
                            end
                        end
                    end
                end

                if newest then
                    -- Gain net ownership then teleport
                    for _=1,5 do
                        pcall(function() RS.Interaction.ClientIsDragging:FireServer(newest.Parent) end)
                        task.wait(0.01)
                    end
                    pcall(function() newest.CFrame = autoBuyCircle.CFrame end)
                    task.wait(0.05)
                end
            end

            done += 1
            abSetProg(done, total)
            setABStatus("Bought " .. done .. " / " .. total .. " " .. abSelectedItem.name, true)
            task.wait(0.05)
        end

        if autoBuyRunning then setABStatus("Done! Bought " .. done .. "x " .. abSelectedItem.name, false) end
        autoBuyRunning = false; autoBuyThread = nil
        abSetProg(total, total)
    end)
end)

abBtn("Cancel AutoBuy", AB_BTN, function()
    autoBuyRunning = false
    if autoBuyThread then pcall(task.cancel, autoBuyThread); autoBuyThread = nil end
    setABStatus("Cancelled", false)
    abResetProg()
end)

table.insert(cleanupTasks, function()
    autoBuyRunning = false
    if autoBuyThread then pcall(task.cancel, autoBuyThread) end
    if autoBuyCircle and autoBuyCircle.Parent then autoBuyCircle:Destroy() end
end)
end -- end AutoBuy do-block

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════
local settingsPage = pages["SettingsTab"]

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size = UDim2.new(1,0,0,70); kbFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
kbFrame.BorderSizePixel = 0; Instance.new("UICorner", kbFrame).CornerRadius = UDim.new(0,10)
local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size = UDim2.new(1,-20,0,28); kbTitle.Position = UDim2.new(0,10,0,8)
kbTitle.BackgroundTransparency = 1; kbTitle.Font = Enum.Font.GothamBold; kbTitle.TextSize = 15
kbTitle.TextColor3 = Color3.fromRGB(220,220,220); kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Text = "GUI Toggle Keybind"
keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size = UDim2.new(0,200,0,28); keybindButtonGUI.Position = UDim2.new(0,10,0,36)
keybindButtonGUI.BackgroundColor3 = Color3.fromRGB(30,30,30); keybindButtonGUI.BorderSizePixel = 0
keybindButtonGUI.Font = Enum.Font.Gotham; keybindButtonGUI.TextSize = 14
keybindButtonGUI.TextColor3 = Color3.fromRGB(200,200,200)
keybindButtonGUI.Text = "Toggle Key: " .. currentToggleKey.Name
Instance.new("UICorner", keybindButtonGUI).CornerRadius = UDim.new(0,8)
keybindButtonGUI.MouseButton1Click:Connect(function()
    if waitingForKeyGUI then return end
    keybindButtonGUI.Text = "Press any key..."
    waitingForKeyGUI = true
end)
keybindButtonGUI.MouseEnter:Connect(function() TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play() end)
keybindButtonGUI.MouseLeave:Connect(function() TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play() end)

-- ════════════════════════════════════════════════════
-- SEARCH TAB
-- ════════════════════════════════════════════════════
local searchPage = pages["SearchTab"]
local searchInput = Instance.new("TextBox", searchPage)
searchInput.Size = UDim2.new(1,-28,0,42); searchInput.BackgroundColor3 = Color3.fromRGB(22,22,28)
searchInput.PlaceholderText = "🔍 Search for functions or tabs..."; searchInput.Text = ""
searchInput.Font = Enum.Font.GothamSemibold; searchInput.TextSize = 15
searchInput.TextColor3 = Color3.fromRGB(220,220,220); searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false
Instance.new("UICorner", searchInput).CornerRadius = UDim.new(0,10)
Instance.new("UIPadding", searchInput).PaddingLeft = UDim.new(0,14)

local function updateSearchResults(query)
    for _, child in ipairs(searchPage:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local lq = string.lower(query or "")

    -- Searchable functions: {display name, target tab}
    local functions = {
        {"Fly", "PlayerTab"}, {"Noclip", "PlayerTab"}, {"InfJump", "PlayerTab"},
        {"Walkspeed", "PlayerTab"}, {"Jump Power", "PlayerTab"}, {"Fly Speed", "PlayerTab"},
        {"Fly Key", "PlayerTab"},
        {"Teleport Locations", "TeleportTab"}, {"Quick Teleport", "TeleportTab"},
        {"Spawn", "TeleportTab"}, {"Wood Dropoff", "TeleportTab"}, {"Land Store", "TeleportTab"},
        {"Teleport Selected Items", "ItemTab"}, {"Group Selection", "ItemTab"},
        {"Click Selection", "ItemTab"}, {"Lasso Tool", "ItemTab"},
        {"Clear Selection", "ItemTab"}, {"Set Destination", "ItemTab"},
        {"GUI Keybind", "SettingsTab"},
        {"Home", "HomeTab"}, {"Ping", "HomeTab"}, {"Rejoin", "HomeTab"},
    }

    local seen = {}
    -- Match tab names
    for _, name in ipairs(tabs) do
        if lq == "" or string.find(string.lower(name), lq) then
            if not seen[name.."Tab"] then
                seen[name.."Tab"] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size = UDim2.new(1,-28,0,42); resBtn.BackgroundColor3 = Color3.fromRGB(22,22,28)
                resBtn.Text = "📂  " .. name .. " Tab"; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
                resBtn.TextColor3 = Color3.fromRGB(200,200,200); resBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UIPadding", resBtn).PaddingLeft = UDim.new(0,16)
                Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0,10)
                resBtn.MouseEnter:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35,35,45), TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
                resBtn.MouseLeave:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22,22,28), TextColor3 = Color3.fromRGB(200,200,200)}):Play() end)
                resBtn.MouseButton1Click:Connect(function() switchTab(name.."Tab") end)
            end
        end
    end
    -- Match functions
    if lq ~= "" then
        for _, entry in ipairs(functions) do
            local fname, ftab = entry[1], entry[2]
            if string.find(string.lower(fname), lq) and not seen[fname] then
                seen[fname] = true
                local resBtn = Instance.new("TextButton", searchPage)
                resBtn.Size = UDim2.new(1,-28,0,42); resBtn.BackgroundColor3 = Color3.fromRGB(18,22,30)
                resBtn.Text = "⚙  " .. fname; resBtn.Font = Enum.Font.GothamSemibold; resBtn.TextSize = 15
                resBtn.TextColor3 = Color3.fromRGB(180,210,255); resBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UIPadding", resBtn).PaddingLeft = UDim.new(0,16)
                Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0,10)
                local subLbl = Instance.new("TextLabel", resBtn)
                subLbl.Size = UDim2.new(1,-20,0,16); subLbl.Position = UDim2.new(0,36,1,-18)
                subLbl.BackgroundTransparency = 1; subLbl.Font = Enum.Font.Gotham; subLbl.TextSize = 11
                subLbl.TextColor3 = Color3.fromRGB(120,120,150); subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.Text = "in " .. ftab:gsub("Tab","") .. " tab"
                resBtn.MouseEnter:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28,35,52), TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
                resBtn.MouseLeave:Connect(function() TweenService:Create(resBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18,22,30), TextColor3 = Color3.fromRGB(180,210,255)}):Play() end)
                resBtn.MouseButton1Click:Connect(function() switchTab(ftab) end)
            end
        end
    end
end
searchInput:GetPropertyChangedSignal("Text"):Connect(function() updateSearchResults(searchInput.Text) end)
task.delay(0.1, function() updateSearchResults("") end)

-- ════════════════════════════════════════════════════
-- UNIFIED INPUT HANDLER (GUI toggle + Fly key + rebinds)
-- ════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    -- GUI keybind rebind
    if waitingForKeyGUI then
        waitingForKeyGUI = false
        currentToggleKey = input.KeyCode
        keybindButtonGUI.Text = "Toggle Key: " .. currentToggleKey.Name
        TweenService:Create(keybindButtonGUI, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true), {
            BackgroundColor3 = Color3.fromRGB(60,180,60)
        }):Play()
        return
    end

    -- Fly key rebind
    if waitingForFlyKey then
        waitingForFlyKey = false
        currentFlyKey = input.KeyCode
        flyKeyBtn.Text = input.KeyCode.Name
        flyKeyBtn.BackgroundColor3 = BTN_COLOR
        return
    end

    -- GUI toggle
    if input.KeyCode == currentToggleKey then
        toggleGUI()
        return
    end

    -- Fly hotkey — ONLY works when flyToggleEnabled is true
    if input.KeyCode == currentFlyKey and flyToggleEnabled then
        if isFlyEnabled then
            stopFly()
        else
            startFly()
        end
    end
end)

print("VanillaHub v3 loaded")

print("VanillaHub Vanilla3 loaded")
