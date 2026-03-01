-- ════════════════════════════════════════════════════
-- VANILLA3 — AutoBuy Tab + Settings Tab + Search Tab + Input Handler
-- Imports shared state from Vanilla1 via _G.VH
-- ════════════════════════════════════════════════════
local TweenService     = _G.VH.TweenService
local Players          = _G.VH.Players
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages
local tabs             = _G.VH.tabs
local BTN_COLOR        = _G.VH.BTN_COLOR
local BTN_HOVER        = _G.VH.BTN_HOVER
local switchTab        = _G.VH.switchTab
local toggleGUI        = _G.VH.toggleGUI
local stopFly          = _G.VH.stopFly
local startFly         = _G.VH.startFly

local flyKeyBtn        = _G.VH.flyKeyBtn
local keybindButtonGUI

local function getWaitingForFlyKey() return _G.VH.waitingForFlyKey end
local function setWaitingForFlyKey(v) _G.VH.waitingForFlyKey = v end
local function getWaitingForKeyGUI() return _G.VH.waitingForKeyGUI end
local function setWaitingForKeyGUI(v) _G.VH.waitingForKeyGUI = v end
local function getCurrentFlyKey() return _G.VH.currentFlyKey end
local function setCurrentFlyKey(v) _G.VH.currentFlyKey = v end
local function getCurrentToggleKey() return _G.VH.currentToggleKey end
local function setCurrentToggleKey(v) _G.VH.currentToggleKey = v end
local function getFlyToggleEnabled() return _G.VH.flyToggleEnabled end
local function getIsFlyEnabled() return _G.VH.isFlyEnabled end

-- ════════════════════════════════════════════════════
-- AUTOBUY TAB
-- ════════════════════════════════════════════════════
local autoBuyPage = pages["AutoBuyTab"]

local function createABSection(text)
    local lbl = Instance.new("TextLabel", autoBuyPage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function createABSep()
    local sep = Instance.new("Frame", autoBuyPage)
    sep.Size = UDim2.new(1,-12,0,1); sep.BackgroundColor3 = Color3.fromRGB(40,40,55); sep.BorderSizePixel = 0
end

local function createABBtn(text, callback)
    local btn = Instance.new("TextButton", autoBuyPage)
    btn.Size = UDim2.new(1,-12,0,32); btn.BackgroundColor3 = BTN_COLOR
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(210,210,220); btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ── Store counter locations ───────────────────────────────────────────────────
local STORE_COUNTERS = {
    ["Wood RUs"]           = Vector3.new(267.70,  5.20,   67.36),
    ["Fancy Furnishings"]  = Vector3.new(477.68,  5.60, -1720.56),
    ["Boxed Cars"]         = Vector3.new(528.07,  5.60, -1460.46),
    ["Bob's Shack"]        = Vector3.new(260.39, 10.40, -2550.87),
    ["Link's Logic"]       = Vector3.new(4595,    9.40,  -784.71),
    ["Fine Art Shop"]      = Vector3.new(5237.45,-164.00,  739.92),
}

-- ── Item catalogue — NON-LIMITED items only, each mapped to their store ───────
-- Format: { itemName, storeName, price }
-- Prices are approximate LT2 in-game values. Update as needed.
local AB_ITEMS_RAW = {
    -- ══════════════════════════════════════════════════════════════════
    -- WOOD R US  (open 24/7 — Main Biome, near spawn)
    -- Axes (5 always available year-round):
    -- ══════════════════════════════════════════════════════════════════
    { "Basic Hatchet",          "Wood RUs",          12      },
    { "Plain Axe",              "Wood RUs",          90      },
    { "Steel Axe",              "Wood RUs",          190     },
    { "Hardened Axe",           "Wood RUs",          550     },
    { "Silver Axe",             "Wood RUs",          2040    },
    -- Sawmills:
    { "Shabby Sawmill",         "Wood RUs",          130     },
    { "Fair Sawmill",           "Wood RUs",          1600    },
    { "Sawmax 01",              "Wood RUs",          11000   },
    { "Sawmax 02",              "Wood RUs",          22500   },
    { "Sawmax 02L",             "Wood RUs",          86500   },
    -- Conveyors:
    { "Straight Conveyor",      "Wood RUs",          80      },
    { "Tilted Conveyor",        "Wood RUs",          95      },
    { "Funnel Conveyor",        "Wood RUs",          60      },
    { "Tight Turn Conveyor",    "Wood RUs",          100     },
    { "Switch Conveyor",        "Wood RUs",          320     },
    { "Wood Sweeper",           "Wood RUs",          430     },
    { "Straight Support",       "Wood RUs",          12      },
    { "Turn Support",           "Wood RUs",          20      },
    { "Straight Switch Left",   "Wood RUs",          480     },
    { "Straight Switch Right",  "Wood RUs",          480     },
    -- Misc:
    { "Worklight",              "Wood RUs",          80      },
    { "Bag of Sand",            "Wood RUs",          1600    },
    { "Utility Vehicle",        "Wood RUs",          400     },

    -- ══════════════════════════════════════════════════════════════════
    -- FANCY FURNISHINGS  (Safari — closes at night)
    -- Glass Panes:
    -- ══════════════════════════════════════════════════════════════════
    { "Tiny Glass Pane",        "Fancy Furnishings", 12      },
    { "Small Glass Pane",       "Fancy Furnishings", 50      },
    { "Regular Glass Pane",     "Fancy Furnishings", 220     },
    { "Large Glass Pane",       "Fancy Furnishings", 550     },
    { "Glass Door",             "Fancy Furnishings", 720     },
    -- Cabinets & counters:
    { "Thin Cabinet",           "Fancy Furnishings", 80      },
    { "Kitchen Cabinet",        "Fancy Furnishings", 150     },
    { "Corner Cabinet",         "Fancy Furnishings", 150     },
    { "Wide Corner Cabinet",    "Fancy Furnishings", 220     },
    { "Short Countertop",       "Fancy Furnishings", 100     },
    { "Countertop",             "Fancy Furnishings", 180     },
    { "Corner Countertop",      "Fancy Furnishings", 300     },
    -- Furniture & lighting:
    { "Toilet",                 "Fancy Furnishings", 90      },
    { "Wall Light",             "Fancy Furnishings", 90      },
    { "Floodlight",             "Fancy Furnishings", 90      },
    { "Lamp",                   "Fancy Furnishings", 90      },
    { "Floor Lamp",             "Fancy Furnishings", 110     },
    { "Armchair",               "Fancy Furnishings", 130     },
    { "Loveseat",               "Fancy Furnishings", 150     },
    { "Couch",                  "Fancy Furnishings", 200     },
    { "Single Bed",             "Fancy Furnishings", 250     },
    { "Refrigerator",           "Fancy Furnishings", 310     },
    { "Stove",                  "Fancy Furnishings", 340     },
    { "Twin Bed",               "Fancy Furnishings", 350     },
    { "Dishwasher",             "Fancy Furnishings", 380     },

    -- ══════════════════════════════════════════════════════════════════
    -- BOXED CARS  (Safari — closes at night)
    -- ══════════════════════════════════════════════════════════════════
    { "Utility Vehicle XL",     "Boxed Cars",        5000    },
    { "Small Trailer",          "Boxed Cars",        1800    },
    { "531 Hauler",             "Boxed Cars",        13000   },
    { "Val's All-Purpose Hauler","Boxed Cars",       19000   },

    -- ══════════════════════════════════════════════════════════════════
    -- BOB'S SHACK  (Mountainside — open 24/7)
    -- Only permanent, year-round purchasable items:
    -- ══════════════════════════════════════════════════════════════════
    { "Dynamite",               "Bob's Shack",       220     },
    { "Can of Worms",           "Bob's Shack",       3200    },

    -- ══════════════════════════════════════════════════════════════════
    -- LINK'S LOGIC  (Tropics — closes at night)
    -- ══════════════════════════════════════════════════════════════════
    { "Wire",                   "Link's Logic",      205     },
    { "Neon Wires",             "Link's Logic",      720     },
    { "Button",                 "Link's Logic",      320     },
    { "Lever",                  "Link's Logic",      520     },
    { "Pressure Plate",         "Link's Logic",      640     },
    { "Signal Sustain",         "Link's Logic",      520     },
    { "Signal Delay",           "Link's Logic",      520     },
    { "Signal Inverter",        "Link's Logic",      200     },
    { "AND Gate",               "Link's Logic",      260     },
    { "OR Gate",                "Link's Logic",      260     },
    { "XOR Gate",               "Link's Logic",      260     },
    { "Clock",                  "Link's Logic",      902     },
    { "Hatch",                  "Link's Logic",      830     },
    { "Laser",                  "Link's Logic",      11300   },
    { "Laser Detector",         "Link's Logic",      3200    },
    { "Wood Detector",          "Link's Logic",      11300   },

    -- ══════════════════════════════════════════════════════════════════
    -- FINE ARTS SHOP  (inside the Maze)
    -- All permanently-stocked paintings:
    -- ══════════════════════════════════════════════════════════════════
    { "Outdoor Watercolor Sketch","Fine Art Shop",   6        },
    { "Disturbed Painting",     "Fine Art Shop",     2006    },
    { "Title Unknown",          "Fine Art Shop",     5980    },
    { "Arctic Light",           "Fine Art Shop",     16000   },
    { "Gloomy Seascape at Dusk","Fine Art Shop",     16800   },
    { "The Lonely Giraffe",     "Fine Art Shop",     26800   },
    { "Pineapple",              "Fine Art Shop",     2406000 },
}

-- Build a lookup table by item name
local AB_ITEM_LOOKUP = {}
for _, entry in ipairs(AB_ITEMS_RAW) do
    AB_ITEM_LOOKUP[entry[1]] = { store = entry[2], price = entry[3] }
end

-- Sorted list of item names for display
local AB_ITEMS_SORTED = {}
for _, entry in ipairs(AB_ITEMS_RAW) do
    table.insert(AB_ITEMS_SORTED, entry[1])
end
table.sort(AB_ITEMS_SORTED)

-- ── State ─────────────────────────────────────────────────────────────────────
local abSelectedItem  = ""
local abBuyAmount     = 1
local abRunning       = false
local abThread        = nil
local abCircle        = nil
local abIsMoving      = false

-- ── Popup helper (shows a message and auto-dismisses after a delay) ───────────
local function showABPopup(message, color)
    color = color or Color3.fromRGB(200, 60, 60)
    -- Remove old popup if any
    local gui = game.CoreGui:FindFirstChild("VanillaHub")
    if not gui then return end
    local old = gui:FindFirstChild("ABPopup")
    if old then old:Destroy() end

    local popup = Instance.new("Frame")
    popup.Name = "ABPopup"
    popup.Size = UDim2.new(0, 340, 0, 68)
    popup.Position = UDim2.new(0.5, -170, 0, 60)
    popup.BackgroundColor3 = Color3.fromRGB(14,14,20)
    popup.BorderSizePixel = 0
    popup.ZIndex = 20
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0,12)
    local stroke = Instance.new("UIStroke", popup)
    stroke.Color = color; stroke.Thickness = 1.5; stroke.Transparency = 0.3

    local icon = Instance.new("TextLabel", popup)
    icon.Size = UDim2.new(0,34,0,34); icon.Position = UDim2.new(0,12,0.5,-17)
    icon.BackgroundTransparency = 1; icon.Text = "⚠"; icon.Font = Enum.Font.GothamBold
    icon.TextSize = 24; icon.TextColor3 = color; icon.ZIndex = 21

    local msg = Instance.new("TextLabel", popup)
    msg.Size = UDim2.new(1,-58,1,0); msg.Position = UDim2.new(0,52,0,0)
    msg.BackgroundTransparency = 1; msg.Text = message
    msg.Font = Enum.Font.GothamSemibold; msg.TextSize = 13
    msg.TextColor3 = Color3.fromRGB(225,225,235); msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextWrapped = true; msg.ZIndex = 21
    Instance.new("UIPadding", msg).PaddingRight = UDim.new(0,8)

    popup.BackgroundTransparency = 1; msg.TextTransparency = 1; icon.TextTransparency = 1
    popup.Parent = gui

    TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
    TweenService:Create(msg,   TweenInfo.new(0.35, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
    TweenService:Create(icon,  TweenInfo.new(0.35, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()

    task.delay(3, function()
        if popup and popup.Parent then
            TweenService:Create(popup, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
            TweenService:Create(msg,   TweenInfo.new(0.4), {TextTransparency=1}):Play()
            TweenService:Create(icon,  TweenInfo.new(0.4), {TextTransparency=1}):Play()
            task.delay(0.45, function() if popup and popup.Parent then popup:Destroy() end end)
        end
    end)
end

-- ── Get player's current cash ─────────────────────────────────────────────────
local function getPlayerCash()
    local stats = player:FindFirstChild("leaderstats") or player:FindFirstChild("stats")
    if stats then
        local money = stats:FindFirstChild("Money") or stats:FindFirstChild("Cash")
            or stats:FindFirstChild("Dollars") or stats:FindFirstChild("Coins")
        if money then return tonumber(money.Value) or 0 end
    end
    -- Try to find money in PlayerGui or other locations
    for _, child in ipairs(player:GetChildren()) do
        if child.Name == "leaderstats" then
            for _, val in ipairs(child:GetChildren()) do
                if val:IsA("IntValue") or val:IsA("NumberValue") then
                    return tonumber(val.Value) or 0
                end
            end
        end
    end
    return math.huge -- fallback: assume enough if we can't read it
end

-- ══════════════════════════════════════════════════════
-- SECTION 1 — ITEM DROPDOWN (with store names + search)
-- ══════════════════════════════════════════════════════
createABSection("Item to Purchase")

-- Store color map for store labels in dropdown
local STORE_COLORS = {
    ["Wood RUs"]          = Color3.fromRGB(120, 200, 120),
    ["Fancy Furnishings"] = Color3.fromRGB(200, 160, 90),
    ["Boxed Cars"]        = Color3.fromRGB(110, 170, 230),
    ["Bob's Shack"]       = Color3.fromRGB(190, 120, 90),
    ["Link's Logic"]      = Color3.fromRGB(150, 130, 220),
    ["Fine Art Shop"]     = Color3.fromRGB(220, 140, 170),
}

do
    local ITEM_H   = 36
    local MAX_SHOW = 6
    local HEADER_H = 40
    local SEARCH_H = 36

    local outer = Instance.new("Frame", autoBuyPage)
    outer.Size             = UDim2.new(1,-12,0,HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22,22,30)
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0,8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = Color3.fromRGB(60,60,90); outerStroke.Thickness = 1; outerStroke.Transparency = 0.5

    -- Header
    local header = Instance.new("Frame", outer)
    header.Size = UDim2.new(1,0,0,HEADER_H); header.BackgroundTransparency = 1

    local labelTag = Instance.new("TextLabel", header)
    labelTag.Size = UDim2.new(0,60,1,0); labelTag.Position = UDim2.new(0,12,0,0)
    labelTag.BackgroundTransparency = 1; labelTag.Text = "Item"
    labelTag.Font = Enum.Font.GothamBold; labelTag.TextSize = 12
    labelTag.TextColor3 = Color3.fromRGB(140,140,170); labelTag.TextXAlignment = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size = UDim2.new(1,-76,0,28); selFrame.Position = UDim2.new(0,70,0.5,-14)
    selFrame.BackgroundColor3 = Color3.fromRGB(30,30,42); selFrame.BorderSizePixel = 0
    Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", selFrame).Color = Color3.fromRGB(70,70,110)

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size = UDim2.new(1,-30,1,0); selLbl.Position = UDim2.new(0,10,0,0)
    selLbl.BackgroundTransparency = 1; selLbl.Font = Enum.Font.GothamSemibold; selLbl.TextSize = 12
    selLbl.TextColor3 = Color3.fromRGB(110,110,140); selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.Text = "Select an item..."; selLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size = UDim2.new(0,22,1,0); arrowLbl.Position = UDim2.new(1,-24,0,0)
    arrowLbl.BackgroundTransparency = 1; arrowLbl.Text = "▾"
    arrowLbl.Font = Enum.Font.GothamBold; arrowLbl.TextSize = 14
    arrowLbl.TextColor3 = Color3.fromRGB(120,120,160); arrowLbl.TextXAlignment = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size = UDim2.new(1,0,1,0); headerBtn.BackgroundTransparency = 1; headerBtn.Text = ""; headerBtn.ZIndex = 5

    -- Divider
    local divider = Instance.new("Frame", outer)
    divider.Size = UDim2.new(1,-16,0,1); divider.Position = UDim2.new(0,8,0,HEADER_H)
    divider.BackgroundColor3 = Color3.fromRGB(50,50,75); divider.BorderSizePixel = 0; divider.Visible = false

    -- Search bar (inside dropdown)
    local searchBox = Instance.new("TextBox", outer)
    searchBox.Size = UDim2.new(1,-16,0,SEARCH_H-6)
    searchBox.Position = UDim2.new(0,8,0,HEADER_H+6)
    searchBox.BackgroundColor3 = Color3.fromRGB(30,30,42); searchBox.BorderSizePixel = 0
    searchBox.PlaceholderText = "🔍 Search items..."; searchBox.Text = ""
    searchBox.Font = Enum.Font.GothamSemibold; searchBox.TextSize = 12
    searchBox.TextColor3 = Color3.fromRGB(210,210,220); searchBox.PlaceholderColor3 = Color3.fromRGB(100,100,130)
    searchBox.TextXAlignment = Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus = false
    searchBox.Visible = false
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0,6)
    Instance.new("UIPadding", searchBox).PaddingLeft = UDim.new(0,10)

    -- List scroll
    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position = UDim2.new(0,0,0,HEADER_H+SEARCH_H+2)
    listScroll.Size = UDim2.new(1,0,0,0)
    listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3; listScroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
    listScroll.CanvasSize = UDim2.new(0,0,0,0); listScroll.ClipsDescendants = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y+6)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop = UDim.new(0,4); listPad.PaddingBottom = UDim.new(0,4)
    listPad.PaddingLeft = UDim.new(0,6); listPad.PaddingRight = UDim.new(0,6)

    local isOpen = false

    -- Track which store header was last inserted so we avoid duplicates
    local function buildList(filter)
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end
        local lf = string.lower(filter or "")
        local filtered = {}
        for _, name in ipairs(AB_ITEMS_SORTED) do
            if lf == "" or string.find(string.lower(name), lf, 1, true) then
                table.insert(filtered, name)
            end
        end

        local rowIndex = 0
        local lastStore = nil

        for _, name in ipairs(filtered) do
            local info = AB_ITEM_LOOKUP[name]
            local storeName = info and info.store or "Unknown"
            local storeColor = STORE_COLORS[storeName] or Color3.fromRGB(160,160,180)

            -- Insert a store section header when the store changes
            if storeName ~= lastStore then
                lastStore = storeName
                rowIndex = rowIndex + 1
                local storeHeader = Instance.new("TextLabel", listScroll)
                storeHeader.Size = UDim2.new(1,0,0,22)
                storeHeader.LayoutOrder = rowIndex
                storeHeader.BackgroundColor3 = Color3.fromRGB(18,18,28)
                storeHeader.BorderSizePixel = 0
                storeHeader.Font = Enum.Font.GothamBold
                storeHeader.TextSize = 10
                storeHeader.TextColor3 = storeColor
                storeHeader.TextXAlignment = Enum.TextXAlignment.Left
                storeHeader.Text = "  🏪 " .. string.upper(storeName)
                Instance.new("UICorner", storeHeader).CornerRadius = UDim.new(0,4)
            end

            rowIndex = rowIndex + 1
            local row = Instance.new("TextButton", listScroll)
            row.Size = UDim2.new(1,0,0,ITEM_H); row.LayoutOrder = rowIndex
            row.BackgroundColor3 = (name == abSelectedItem) and Color3.fromRGB(45,45,75) or Color3.fromRGB(28,28,40)
            row.BorderSizePixel = 0; row.Text = ""
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

            -- Item name label
            local itemLbl = Instance.new("TextLabel", row)
            itemLbl.Size = UDim2.new(1,-70,1,0); itemLbl.Position = UDim2.new(0,10,0,0)
            itemLbl.BackgroundTransparency = 1
            itemLbl.Font = Enum.Font.GothamSemibold; itemLbl.TextSize = 12
            itemLbl.TextColor3 = (name == abSelectedItem) and Color3.fromRGB(210,215,255) or Color3.fromRGB(200,200,215)
            itemLbl.TextXAlignment = Enum.TextXAlignment.Left; itemLbl.Text = name
            itemLbl.TextTruncate = Enum.TextTruncate.AtEnd

            -- Price label
            local priceLbl = Instance.new("TextLabel", row)
            priceLbl.Size = UDim2.new(0,60,1,0); priceLbl.Position = UDim2.new(1,-66,0,0)
            priceLbl.BackgroundTransparency = 1
            priceLbl.Font = Enum.Font.Gotham; priceLbl.TextSize = 11
            priceLbl.TextColor3 = Color3.fromRGB(120,200,140)
            priceLbl.TextXAlignment = Enum.TextXAlignment.Right
            priceLbl.Text = "$" .. tostring(info and info.price or 0)
            Instance.new("UIPadding", priceLbl).PaddingRight = UDim.new(0,6)

            row.MouseEnter:Connect(function()
                if name ~= abSelectedItem then
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(38,38,58)}):Play()
                end
            end)
            row.MouseLeave:Connect(function()
                if name ~= abSelectedItem then
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28,28,40)}):Play()
                end
            end)
            row.MouseButton1Click:Connect(function()
                abSelectedItem = (abSelectedItem == name) and "" or name
                if abSelectedItem ~= "" then
                    local iInfo = AB_ITEM_LOOKUP[abSelectedItem]
                    local storeTag = iInfo and (" [" .. iInfo.store .. "]") or ""
                    selLbl.Text = abSelectedItem .. storeTag
                else
                    selLbl.Text = "Select an item..."
                end
                selLbl.TextColor3 = abSelectedItem ~= "" and Color3.fromRGB(220,225,255) or Color3.fromRGB(110,110,140)
                outerStroke.Color = abSelectedItem ~= "" and Color3.fromRGB(90,90,160) or Color3.fromRGB(60,60,90)
                buildList(searchBox.Text)
                task.delay(0.05, function()
                    isOpen = false; searchBox.Visible = false; divider.Visible = false
                    TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
                    TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
                    TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
                end)
            end)
        end
        return rowIndex
    end

    local function openList()
        isOpen = true
        searchBox.Text = ""; searchBox.Visible = true; divider.Visible = true
        local count = buildList("")
        local listH = math.min(count, MAX_SHOW)*(ITEM_H+3)+8
        local totalH = HEADER_H+SEARCH_H+2+listH
        TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=180}):Play()
        TweenService:Create(outer, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,totalH)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,listH)}):Play()
    end

    local function closeList()
        isOpen = false; searchBox.Visible = false; divider.Visible = false
        TweenService:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation=0}):Play()
        TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,0)}):Play()
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if not isOpen then return end
        local count = buildList(searchBox.Text)
        local listH = math.min(count, MAX_SHOW)*(ITEM_H+3)+8
        local totalH = HEADER_H+SEARCH_H+2+listH
        outer.Size = UDim2.new(1,-12,0,totalH)
        listScroll.Size = UDim2.new(1,0,0,listH)
    end)

    headerBtn.MouseButton1Click:Connect(function() if isOpen then closeList() else openList() end end)
    headerBtn.MouseEnter:Connect(function() TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(38,38,55)}):Play() end)
    headerBtn.MouseLeave:Connect(function() TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(30,30,42)}):Play() end)
end

createABSep()

-- ══════════════════════════════════════════════════════
-- SECTION 2 — AMOUNT SLIDER (1–250) with live cost display
-- ══════════════════════════════════════════════════════
createABSection("Amount")

local abCostLabel -- declared here so runAutoBuy can access it

do
    local minVal, maxVal, defaultVal = 1, 250, 1
    local frame = Instance.new("Frame", autoBuyPage)
    frame.Size = UDim2.new(1,-12,0,68); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)

    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1,-16,0,22); topRow.Position = UDim2.new(0,8,0,6); topRow.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.55,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = "Buy Amount"

    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.2,0,1,0); valLbl.Position = UDim2.new(0.55,0,0,0); valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3 = Color3.fromRGB(200,200,255); valLbl.TextXAlignment = Enum.TextXAlignment.Center
    valLbl.Text = tostring(defaultVal)

    -- Cost label (right side of topRow)
    local costLbl = Instance.new("TextLabel", topRow)
    costLbl.Size = UDim2.new(0.25,0,1,0); costLbl.Position = UDim2.new(0.75,0,0,0)
    costLbl.BackgroundTransparency = 1
    costLbl.Font = Enum.Font.Gotham; costLbl.TextSize = 11
    costLbl.TextColor3 = Color3.fromRGB(120,200,140); costLbl.TextXAlignment = Enum.TextXAlignment.Right
    costLbl.Text = "Cost: $0"
    abCostLabel = costLbl

    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1,-16,0,6); track.Position = UDim2.new(0,8,0,36)
    track.BackgroundColor3 = Color3.fromRGB(40,40,55); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,80,100); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0,16,0,16); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(210,210,225); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    -- Tooltip popup frame for cost while dragging
    local dragTooltip = Instance.new("Frame", frame)
    dragTooltip.Size = UDim2.new(0,110,0,28)
    dragTooltip.AnchorPoint = Vector2.new(0.5,1)
    dragTooltip.Position = UDim2.new(0,0,0,34)
    dragTooltip.BackgroundColor3 = Color3.fromRGB(30,30,44)
    dragTooltip.BorderSizePixel = 0; dragTooltip.Visible = false; dragTooltip.ZIndex = 10
    Instance.new("UICorner", dragTooltip).CornerRadius = UDim.new(0,6)
    local ttStroke = Instance.new("UIStroke", dragTooltip)
    ttStroke.Color = Color3.fromRGB(80,80,130); ttStroke.Thickness = 1; ttStroke.Transparency = 0.4
    local dragTooltipLbl = Instance.new("TextLabel", dragTooltip)
    dragTooltipLbl.Size = UDim2.new(1,0,1,0); dragTooltipLbl.BackgroundTransparency = 1
    dragTooltipLbl.Font = Enum.Font.GothamBold; dragTooltipLbl.TextSize = 12
    dragTooltipLbl.TextColor3 = Color3.fromRGB(130,220,160); dragTooltipLbl.ZIndex = 11
    dragTooltipLbl.Text = "Cost: $0"

    local draggingABSlider = false

    local function getItemPrice()
        if abSelectedItem ~= "" then
            local info = AB_ITEM_LOOKUP[abSelectedItem]
            return info and info.price or 0
        end
        return 0
    end

    local function updateCostDisplay(val)
        local price = getItemPrice()
        local total = price * val
        local totalStr = "$" .. tostring(total)
        abCostLabel.Text = "Cost: " .. totalStr
        dragTooltipLbl.Text = totalStr .. " total"
    end

    local function updateABSlider(absX)
        local ratio = math.clamp((absX - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        local val = math.max(1, math.round(minVal + ratio*(maxVal-minVal)))
        abBuyAmount = val
        fill.Size = UDim2.new(ratio,0,1,0); knob.Position = UDim2.new(ratio,0,0.5,0)
        valLbl.Text = tostring(val)
        -- Position tooltip above knob
        dragTooltip.Position = UDim2.new(ratio, 0, 0, 30)
        updateCostDisplay(val)
    end

    knob.MouseButton1Down:Connect(function()
        draggingABSlider = true
        dragTooltip.Visible = true
        updateCostDisplay(abBuyAmount)
    end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingABSlider = true
            dragTooltip.Visible = true
            updateABSlider(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingABSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateABSlider(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingABSlider = false
            dragTooltip.Visible = false
        end
    end)

    -- Update cost label when item selection changes
    -- (we hook via a RunService heartbeat check since there's no direct event)
    local lastItemForCost = ""
    RunService.Heartbeat:Connect(function()
        if abSelectedItem ~= lastItemForCost then
            lastItemForCost = abSelectedItem
            updateCostDisplay(abBuyAmount)
        end
    end)
end

createABSep()

-- ══════════════════════════════════════════════════════
-- SECTION 3 — DESTINATION
-- ══════════════════════════════════════════════════════
createABSection("Delivery Destination")

do
    local tpRow = Instance.new("Frame", autoBuyPage)
    tpRow.Size = UDim2.new(1,-12,0,32); tpRow.BackgroundTransparency = 1

    local tpSet = Instance.new("TextButton", tpRow)
    tpSet.Size = UDim2.new(0.5,-4,1,0); tpSet.Position = UDim2.new(0,0,0,0)
    tpSet.BackgroundColor3 = BTN_COLOR; tpSet.Font = Enum.Font.GothamSemibold
    tpSet.TextSize = 12; tpSet.TextColor3 = Color3.fromRGB(210,210,220); tpSet.Text = "Set Destination"
    Instance.new("UICorner", tpSet).CornerRadius = UDim.new(0,6)

    local tpRemove = Instance.new("TextButton", tpRow)
    tpRemove.Size = UDim2.new(0.5,-4,1,0); tpRemove.Position = UDim2.new(0.5,4,0,0)
    tpRemove.BackgroundColor3 = BTN_COLOR; tpRemove.Font = Enum.Font.GothamSemibold
    tpRemove.TextSize = 12; tpRemove.TextColor3 = Color3.fromRGB(210,210,220); tpRemove.Text = "Remove Destination"
    Instance.new("UICorner", tpRemove).CornerRadius = UDim.new(0,6)

    for _, b in {tpSet, tpRemove} do
        b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=BTN_HOVER}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=BTN_COLOR}):Play() end)
    end

    tpSet.MouseButton1Click:Connect(function()
        if abCircle then abCircle:Destroy() end
        abCircle = Instance.new("Part")
        abCircle.Name = "VanillaHubABCircle"
        abCircle.Shape = Enum.PartType.Ball
        abCircle.Size = Vector3.new(3,3,3)
        abCircle.Material = Enum.Material.SmoothPlastic
        abCircle.Color = Color3.fromRGB(80,200,120)
        abCircle.Anchored = true; abCircle.CanCollide = false
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            abCircle.Position = char.HumanoidRootPart.Position
        end
        abCircle.Parent = workspace
    end)

    tpRemove.MouseButton1Click:Connect(function()
        if abCircle then abCircle:Destroy(); abCircle = nil end
    end)

    table.insert(cleanupTasks, function()
        if abCircle and abCircle.Parent then abCircle:Destroy() end
    end)
end

createABSep()

-- ══════════════════════════════════════════════════════
-- SECTION 4 — ACTIONS
-- ══════════════════════════════════════════════════════
createABSection("Actions")

-- Status label
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

-- Progress bar
local abProgressContainer, abProgressFill, abProgressLabel
do
    local container = Instance.new("Frame", autoBuyPage)
    container.Size = UDim2.new(1,-12,0,44); container.BackgroundColor3 = Color3.fromRGB(18,18,24)
    container.BorderSizePixel = 0; container.Visible = false
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,8)
    local pbStroke = Instance.new("UIStroke", container)
    pbStroke.Color = Color3.fromRGB(60,60,80); pbStroke.Thickness = 1; pbStroke.Transparency = 0.5
    local pbLabel = Instance.new("TextLabel", container)
    pbLabel.Size = UDim2.new(1,-12,0,16); pbLabel.Position = UDim2.new(0,6,0,4)
    pbLabel.BackgroundTransparency = 1; pbLabel.Font = Enum.Font.GothamSemibold; pbLabel.TextSize = 11
    pbLabel.TextColor3 = Color3.fromRGB(170,170,200); pbLabel.TextXAlignment = Enum.TextXAlignment.Left
    pbLabel.Text = "Buying..."
    local pbTrack = Instance.new("Frame", container)
    pbTrack.Size = UDim2.new(1,-12,0,12); pbTrack.Position = UDim2.new(0,6,0,24)
    pbTrack.BackgroundColor3 = Color3.fromRGB(30,30,40); pbTrack.BorderSizePixel = 0
    Instance.new("UICorner", pbTrack).CornerRadius = UDim.new(1,0)
    local pbFill = Instance.new("Frame", pbTrack)
    pbFill.Size = UDim2.new(0,0,1,0); pbFill.BackgroundColor3 = Color3.fromRGB(80,200,120)
    pbFill.BorderSizePixel = 0; Instance.new("UICorner", pbFill).CornerRadius = UDim.new(1,0)
    abProgressContainer = container; abProgressFill = pbFill; abProgressLabel = pbLabel
end

-- ── Core buy function ─────────────────────────────────────────────────────────
-- Teleports player to store counter → clicks item on shelf → item comes to counter
-- → clicks it at counter → item goes to destination. Repeats for amount.
local function runAutoBuy(remoteTeleport)
    if abSelectedItem == "" then setABStatus("No item selected!", false); return end
    if abRunning then return end

    -- Get item info
    local itemInfo = AB_ITEM_LOOKUP[abSelectedItem]
    if not itemInfo then
        setABStatus("Item data not found!", false)
        return
    end

    -- ── Cash check ────────────────────────────────────────────────────────────
    local totalCost = itemInfo.price * abBuyAmount
    local playerCash = getPlayerCash()
    if playerCash < totalCost then
        setABStatus("Not enough cash!", false)
        showABPopup(
            string.format("Not enough cash!\nNeed $%d  |  Have $%d", totalCost, playerCash),
            Color3.fromRGB(220, 60, 60)
        )
        return
    end

    abRunning = true; abIsMoving = false
    local storeName   = itemInfo.store
    local counterPos  = STORE_COUNTERS[storeName]

    abThread = task.spawn(function()
        setABStatus("Running...", true)
        abProgressContainer.Visible = true
        abProgressFill.Size = UDim2.new(0,0,1,0)
        abProgressLabel.Text = "Buying 0 / " .. abBuyAmount

        -- Find the clickable shelf/display item inside the store for the selected name
        local function findShelfItem()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("Part") then
                    local nm = obj:FindFirstChild("ItemName")
                    if nm and string.lower(nm.Value) == string.lower(abSelectedItem) then
                        -- Make sure it's a shop display (not a purchased copy)
                        -- Shop items typically do NOT have an Owner value
                        local own = obj:FindFirstChild("Owner")
                        if not own then return obj end
                    end
                    -- Also check by model name directly (some items stored as e.g. "Basic Hatchet" model)
                    if string.lower(obj.Name) == string.lower(abSelectedItem) then
                        local own = obj:FindFirstChild("Owner")
                        if not own then return obj end
                    end
                end
            end
            return nil
        end

        local RS = game:GetService("ReplicatedStorage")
        local bought = 0

        for i = 1, abBuyAmount do
            if not abRunning then break end

            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.5); continue end

            -- Step 1: Teleport to the store counter
            if counterPos then
                hrp.CFrame = CFrame.new(counterPos + Vector3.new(0, 3, 0))
                task.wait(0.25)
            end

            -- Step 2: Find the shelf display item
            local shelfItem = findShelfItem()
            if shelfItem then
                local shelfPart = shelfItem.PrimaryPart
                    or (shelfItem:IsA("Model") and shelfItem:FindFirstChildWhichIsA("BasePart"))
                    or (shelfItem:IsA("BasePart") and shelfItem)

                if shelfPart and shelfPart:IsA("BasePart") then
                    -- Step 3: Teleport near the shelf item and click it
                    hrp.CFrame = shelfPart.CFrame * CFrame.new(0, 3, 3)
                    task.wait(0.18)

                    -- Fire ClientIsDragging to simulate picking up / interacting
                    local dragRemote = RS:FindFirstChild("Interaction")
                        and RS.Interaction:FindFirstChild("ClientIsDragging")
                    if dragRemote then
                        pcall(function() dragRemote:FireServer(
                            shelfItem:IsA("Model") and shelfItem or shelfItem.Parent
                        ) end)
                    end
                    task.wait(0.12)

                    -- Step 4: Move item to counter position (simulating dragging to purchase point)
                    if counterPos then
                        pcall(function()
                            shelfPart.CFrame = CFrame.new(counterPos + Vector3.new(0, 2, 0))
                        end)
                        task.wait(0.12)
                    end

                    -- Step 5: Fire the buy remote
                    local buyRemote = RS:FindFirstChild("Interaction")
                        and RS.Interaction:FindFirstChild("BuyItem")
                    if buyRemote then
                        pcall(function() buyRemote:FireServer(shelfItem) end)
                    end
                    task.wait(0.35)

                    -- Step 6: Move purchased item to destination if set
                    if abCircle and remoteTeleport then
                        task.wait(0.2)
                        -- Find the newly purchased copy (has Owner = player)
                        local newItem = nil
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("Model") then
                                local nm  = obj:FindFirstChild("ItemName")
                                local own = obj:FindFirstChild("Owner")
                                local nameMatch = (nm and string.lower(nm.Value) == string.lower(abSelectedItem))
                                    or string.lower(obj.Name) == string.lower(abSelectedItem)
                                local ownedByMe = own and (
                                    (own:IsA("ObjectValue") and own.Value == player) or
                                    (own:IsA("StringValue") and own.Value == player.Name)
                                )
                                if nameMatch and ownedByMe then newItem = obj; break end
                            end
                        end

                        if newItem then
                            local mainPart = newItem.PrimaryPart or newItem:FindFirstChildWhichIsA("BasePart")
                            if mainPart then
                                local dragger = RS:FindFirstChild("Interaction")
                                    and RS.Interaction:FindFirstChild("ClientIsDragging")
                                -- TP near the purchased item
                                hrp.CFrame = mainPart.CFrame * CFrame.new(0,4,2)
                                task.wait(0.12)
                                -- Grab it
                                if dragger then pcall(function() dragger:FireServer(newItem) end) end
                                task.wait(0.08)
                                -- Snap to destination
                                mainPart.CFrame = abCircle.CFrame
                                task.wait(0.08)
                                -- Release
                                if dragger then pcall(function() dragger:FireServer(newItem) end) end
                                task.wait(0.15)
                            end
                        end
                    end

                    bought = bought + 1
                else
                    task.wait(0.3)
                end
            else
                -- Fallback: no shelf item found, try the BuyItem remote directly
                local buyRemote = RS:FindFirstChild("Interaction")
                    and RS.Interaction:FindFirstChild("BuyItem")
                if buyRemote then
                    pcall(function() buyRemote:FireServer(abSelectedItem) end)
                    task.wait(0.4)
                    bought = bought + 1
                else
                    task.wait(0.3)
                end
            end

            -- Progress bar update
            local pct = bought / math.max(abBuyAmount, 1)
            TweenService:Create(abProgressFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Size = UDim2.new(pct, 0, 1, 0)
            }):Play()
            abProgressLabel.Text = "Buying " .. bought .. " / " .. abBuyAmount
        end

        abRunning = false; abThread = nil
        TweenService:Create(abProgressFill, TweenInfo.new(0.2), {Size=UDim2.new(1,0,1,0)}):Play()
        abProgressLabel.Text = "Done! " .. bought .. " / " .. abBuyAmount .. " bought"
        setABStatus("Done! " .. bought .. " bought", false)
        task.delay(2.5, function()
            if abProgressContainer then
                TweenService:Create(abProgressContainer, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
                TweenService:Create(abProgressFill, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
                TweenService:Create(abProgressLabel, TweenInfo.new(0.4), {TextTransparency=1}):Play()
                task.delay(0.45, function()
                    if abProgressContainer then
                        abProgressContainer.Visible = false
                        abProgressContainer.BackgroundTransparency = 0
                        abProgressFill.BackgroundTransparency = 0
                        abProgressLabel.TextTransparency = 0
                    end
                end)
            end
        end)
    end)
end

-- "Buy Items" — finds item on shelf, teleports to it, picks it up, brings to counter,
-- purchases it, then moves it to the set destination (if any). Repeats for amount.
createABBtn("Buy Items", function()
    -- Always pass true so destination logic runs whenever abCircle is set
    runAutoBuy(true)
end)

createABBtn("Cancel", function()
    abRunning = false
    if abThread then pcall(task.cancel, abThread); abThread = nil end
    setABStatus("Cancelled", false)
end)

table.insert(cleanupTasks, function()
    abRunning = false
    if abThread then pcall(task.cancel, abThread); abThread = nil end
    if abCircle and abCircle.Parent then abCircle:Destroy() end
end)

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
keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
Instance.new("UICorner", keybindButtonGUI).CornerRadius = UDim.new(0,8)
keybindButtonGUI.MouseButton1Click:Connect(function()
    if getWaitingForKeyGUI() then return end
    keybindButtonGUI.Text = "Press any key..."
    setWaitingForKeyGUI(true)
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

    if getWaitingForKeyGUI() then
        setWaitingForKeyGUI(false)
        setCurrentToggleKey(input.KeyCode)
        keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
        TweenService:Create(keybindButtonGUI, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true), {
            BackgroundColor3 = Color3.fromRGB(60,180,60)
        }):Play()
        return
    end

    if getWaitingForFlyKey() then
        setWaitingForFlyKey(false)
        setCurrentFlyKey(input.KeyCode)
        flyKeyBtn.Text = input.KeyCode.Name
        flyKeyBtn.BackgroundColor3 = BTN_COLOR
        return
    end

    if input.KeyCode == getCurrentToggleKey() then
        toggleGUI()
        return
    end

    if input.KeyCode == getCurrentFlyKey() and getFlyToggleEnabled() then
        if getIsFlyEnabled() then
            stopFly()
        else
            startFly()
        end
    end
end)

_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded")
