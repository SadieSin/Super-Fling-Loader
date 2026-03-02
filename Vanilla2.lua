-- ════════════════════════════════════════════════════
-- PINK HUB — Ultimate Edition
-- Lumber Tycoon 2
-- Tab 1: Item Teleport
-- Tab 2: Butter Leak (Smooth Truck System)
-- Toggle: Left-middle screen button  |  Keybind: ]
-- ════════════════════════════════════════════════════

if game.CoreGui:FindFirstChild("PinkHub") then
    game.CoreGui.PinkHub:Destroy()
end

-- ── SERVICES ──────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local player           = Players.LocalPlayer

-- ══════════════════════════════════════════
-- THEME
-- ══════════════════════════════════════════
local C = {
    BG          = Color3.fromRGB(18, 10, 18),
    PANEL       = Color3.fromRGB(26, 14, 26),
    CARD        = Color3.fromRGB(34, 18, 34),
    TOPBAR      = Color3.fromRGB(10, 5, 12),
    PINK        = Color3.fromRGB(255, 105, 180),
    PINK_DIM    = Color3.fromRGB(200, 70, 140),
    PINK_DARK   = Color3.fromRGB(120, 30, 80),
    PINK_GLOW   = Color3.fromRGB(255, 160, 210),
    BTN         = Color3.fromRGB(50, 25, 50),
    BTN_HOV     = Color3.fromRGB(80, 35, 75),
    BORDER      = Color3.fromRGB(80, 30, 70),
    TEXT        = Color3.fromRGB(255, 220, 240),
    TEXT_DIM    = Color3.fromRGB(160, 110, 150),
    RED         = Color3.fromRGB(200, 40, 80),
    GREEN       = Color3.fromRGB(60, 200, 110),
    BLUE        = Color3.fromRGB(60, 130, 220),
}

-- ── CLEANUP ────────────────────────────────────────────
local cleanupTasks = {}
local function addCleanup(fn) table.insert(cleanupTasks, fn) end
local function runCleanup()
    for _, fn in ipairs(cleanupTasks) do pcall(fn) end
end

-- ══════════════════════════════════════════
-- ROOT GUI
-- ══════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name          = "PinkHub"
gui.Parent        = game.CoreGui
gui.ResetOnSpawn  = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
addCleanup(function() if gui and gui.Parent then gui:Destroy() end end)

-- ══════════════════════════════════════════
-- TOGGLE BUTTON
-- ══════════════════════════════════════════
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size              = UDim2.new(0, 28, 0, 90)
toggleBtn.Position          = UDim2.new(0, 0, 0.5, -45)
toggleBtn.BackgroundColor3  = C.PINK_DARK
toggleBtn.BorderSizePixel   = 0
toggleBtn.Text              = "♡\nH\nU\nB"
toggleBtn.Font              = Enum.Font.GothamBold
toggleBtn.TextSize          = 10
toggleBtn.TextColor3        = C.PINK_GLOW
toggleBtn.ZIndex            = 30
toggleBtn.AutoButtonColor   = false
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
local tgStroke = Instance.new("UIStroke", toggleBtn)
tgStroke.Color       = C.PINK
tgStroke.Thickness   = 1.2
tgStroke.Transparency = 0.3
TweenService:Create(tgStroke,
    TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.85}
):Play()

-- ══════════════════════════════════════════
-- MAIN WINDOW
-- ══════════════════════════════════════════
local main = Instance.new("Frame", gui)
main.Name                   = "Main"
main.Size                   = UDim2.new(0, 0, 0, 0)
main.Position               = UDim2.new(0.5, -195, 0.5, -230)
main.BackgroundColor3       = C.BG
main.BackgroundTransparency = 1
main.BorderSizePixel        = 0
main.ClipsDescendants       = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color       = C.BORDER
mainStroke.Thickness   = 1.4
mainStroke.Transparency = 0.2

local isOpen = false
local function openWindow()
    isOpen = true
    TweenService:Create(main,
        TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 390, 0, 460), BackgroundTransparency = 0}
    ):Play()
end
local function closeWindow()
    isOpen = false
    TweenService:Create(main,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}
    ):Play()
end

toggleBtn.MouseButton1Click:Connect(function()
    if isOpen then closeWindow() else openWindow() end
end)
openWindow()

-- ── TOP BAR ───────────────────────────────────────────
local topBar = Instance.new("Frame", main)
topBar.Size             = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = C.TOPBAR
topBar.BorderSizePixel  = 0
local topGrad = Instance.new("UIGradient", topBar)
topGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 10, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 5, 12)),
})
topGrad.Rotation = 90
local dot = Instance.new("Frame", topBar)
dot.Size            = UDim2.new(0, 8, 0, 8)
dot.Position        = UDim2.new(0, 14, 0.5, -4)
dot.BackgroundColor3 = C.PINK
dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size               = UDim2.new(1, -100, 1, 0)
titleLbl.Position           = UDim2.new(0, 30, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text               = "♡  Pink Hub"
titleLbl.Font               = Enum.Font.GothamBold
titleLbl.TextSize           = 16
titleLbl.TextColor3         = C.PINK_GLOW
titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size               = UDim2.new(0, 28, 0, 28)
closeBtn.Position           = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3   = C.RED
closeBtn.Text               = "×"
closeBtn.Font               = Enum.Font.GothamBold
closeBtn.TextSize           = 18
closeBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel    = 0
closeBtn.AutoButtonColor    = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)
closeBtn.MouseButton1Click:Connect(function()
    runCleanup(); closeWindow()
end)

-- ── DRAG ──────────────────────────────────────────────
local dragging, dragStart, startPos = false, nil, nil
topBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ── TAB BAR ───────────────────────────────────────────
local tabBar = Instance.new("Frame", main)
tabBar.Size             = UDim2.new(1, 0, 0, 34)
tabBar.Position         = UDim2.new(0, 0, 0, 40)
tabBar.BackgroundColor3 = C.PANEL
tabBar.BorderSizePixel  = 0
local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection       = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.SortOrder           = Enum.SortOrder.LayoutOrder

local function makeTabBtn(text, order)
    local tb = Instance.new("TextButton", tabBar)
    tb.Size              = UDim2.new(0, 130, 1, 0)
    tb.BackgroundColor3  = C.PANEL
    tb.BorderSizePixel   = 0
    tb.Text              = text
    tb.Font              = Enum.Font.GothamSemibold
    tb.TextSize          = 12
    tb.TextColor3        = C.TEXT_DIM
    tb.LayoutOrder       = order
    tb.AutoButtonColor   = false
    return tb
end
local tabItem   = makeTabBtn("⬟  Item Teleport", 1)
local tabButter = makeTabBtn("⬠  Butter Leak",   2)

local function makeUnderline(parent)
    local ul = Instance.new("Frame", parent)
    ul.Size              = UDim2.new(1, 0, 0, 2)
    ul.Position          = UDim2.new(0, 0, 1, -2)
    ul.BackgroundColor3  = C.PINK
    ul.BorderSizePixel   = 0
    ul.Visible           = false
    return ul
end
local ulItem   = makeUnderline(tabItem)
local ulButter = makeUnderline(tabButter)

-- ── CONTENT AREA ─────────────────────────────────────
local contentArea = Instance.new("Frame", main)
contentArea.Size             = UDim2.new(1, 0, 1, -74)
contentArea.Position         = UDim2.new(0, 0, 0, 74)
contentArea.BackgroundColor3 = C.PANEL
contentArea.BorderSizePixel  = 0
contentArea.ClipsDescendants = true

-- ══════════════════════════════════════════════════════
-- SHARED WIDGET HELPERS
-- ══════════════════════════════════════════════════════
local function makeScroll(parent)
    local s = Instance.new("ScrollingFrame", parent)
    s.Size                  = UDim2.new(1, 0, 1, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel       = 0
    s.ScrollBarThickness    = 3
    s.ScrollBarImageColor3  = C.PINK_DIM
    s.CanvasSize            = UDim2.new(0, 0, 0, 0)
    local ll = Instance.new("UIListLayout", s)
    ll.Padding              = UDim.new(0, 6)
    ll.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    ll.SortOrder            = Enum.SortOrder.LayoutOrder
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 18)
    end)
    local pad = Instance.new("UIPadding", s)
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    return s, ll
end

local function sectionLabel(parent, text, order)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size                = UDim2.new(1, -20, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextSize            = 10
    lbl.TextColor3          = C.PINK_DIM
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.Text                = "▸  " .. string.upper(text)
    lbl.LayoutOrder         = order or 0
    local p = Instance.new("UIPadding", lbl); p.PaddingLeft = UDim.new(0, 4)
    return lbl
end

local function sep(parent, order)
    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(1, -20, 0, 1)
    f.BackgroundColor3 = C.BORDER
    f.BorderSizePixel  = 0
    f.BackgroundTransparency = 0.5
    f.LayoutOrder      = order or 0
    return f
end

local function makeBtn(parent, text, color, order)
    color = color or C.BTN
    local btn = Instance.new("TextButton", parent)
    btn.Size             = UDim2.new(1, -20, 0, 34)
    btn.BackgroundColor3 = color
    btn.Text             = text
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    btn.LayoutOrder      = order or 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.6
    local hov = Color3.fromRGB(
        math.min(color.R*255+30,255)/255,
        math.min(color.G*255+10,255)/255,
        math.min(color.B*255+25,255)/255
    )
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = hov}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = color}):Play()
    end)
    return btn
end

local function makeToggle(parent, text, default, order, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, -20, 0, 34)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel  = 0
    frame.LayoutOrder      = order or 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.6
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(1, -56, 1, 0)
    lbl.Position           = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 12
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size              = UDim2.new(0, 36, 0, 20)
    tb.Position          = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3  = default and C.PINK_DARK or C.BTN
    tb.Text              = ""
    tb.BorderSizePixel   = 0
    tb.AutoButtonColor   = false
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", tb)
    knob.Size            = UDim2.new(0, 14, 0, 14)
    knob.Position        = UDim2.new(0, default and 19 or 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local toggled = default
    if cb then cb(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and C.PINK_DARK or C.BTN
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 19 or 3, 0.5, -7)
        }):Play()
        if cb then cb(toggled) end
    end)
    return frame, function() return toggled end
end

local function makeInputRow(parent, labelText, placeholder, order)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, -20, 0, 34)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel  = 0
    frame.LayoutOrder      = order or 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.5
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(0, 100, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 11
    lbl.TextColor3         = C.TEXT_DIM
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    local box = Instance.new("TextBox", frame)
    box.Size               = UDim2.new(1, -115, 0, 24)
    box.Position           = UDim2.new(0, 108, 0.5, -12)
    box.BackgroundColor3   = C.BTN
    box.BorderSizePixel    = 0
    box.Text               = ""
    box.PlaceholderText    = placeholder or "..."
    box.PlaceholderColor3  = C.TEXT_DIM
    box.Font               = Enum.Font.Gotham
    box.TextSize           = 11
    box.TextColor3         = C.TEXT
    box.ClearTextOnFocus   = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    local pad = Instance.new("UIPadding", box); pad.PaddingLeft = UDim.new(0, 6)
    return frame, box
end

local function statusPill(parent, order)
    local bar = Instance.new("Frame", parent)
    bar.Size             = UDim2.new(1, -20, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(12, 6, 14)
    bar.BorderSizePixel  = 0
    bar.LayoutOrder      = order or 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", bar)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.4
    local sdot = Instance.new("Frame", bar)
    sdot.Size            = UDim2.new(0, 7, 0, 7)
    sdot.Position        = UDim2.new(0, 10, 0.5, -3)
    sdot.BackgroundColor3 = C.PINK_DIM
    sdot.BorderSizePixel = 0
    Instance.new("UICorner", sdot).CornerRadius = UDim.new(1, 0)
    local stxt = Instance.new("TextLabel", bar)
    stxt.Size               = UDim2.new(1, -70, 1, 0)
    stxt.Position           = UDim2.new(0, 24, 0, 0)
    stxt.BackgroundTransparency = 1
    stxt.Font               = Enum.Font.Gotham
    stxt.TextSize           = 11
    stxt.TextColor3         = C.TEXT_DIM
    stxt.TextXAlignment     = Enum.TextXAlignment.Left
    stxt.Text               = "Ready"
    local scnt = Instance.new("TextLabel", bar)
    scnt.Size               = UDim2.new(0, 60, 1, 0)
    scnt.Position           = UDim2.new(1, -68, 0, 0)
    scnt.BackgroundTransparency = 1
    scnt.Font               = Enum.Font.GothamBold
    scnt.TextSize           = 11
    scnt.TextColor3         = C.PINK
    scnt.TextXAlignment     = Enum.TextXAlignment.Right
    return bar, stxt, scnt, sdot
end

-- progress bar helper
local function makeProgress(parent, order)
    local bg = Instance.new("Frame", parent)
    bg.Size             = UDim2.new(1, -20, 0, 6)
    bg.BackgroundColor3 = Color3.fromRGB(28, 14, 28)
    bg.BorderSizePixel  = 0
    bg.LayoutOrder      = order or 0
    bg.Visible          = false
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", bg)
    fill.Size            = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.PINK
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local function set(done, total)
        local pct = math.clamp(done / math.max(total, 1), 0, 1)
        local blue  = Color3.fromRGB(80, 180, 255)
        local green = C.GREEN
        local col = pct >= 1 and green or Color3.fromRGB(
            math.floor(blue.R*255 + (green.R*255 - blue.R*255)*pct)/255,
            math.floor(blue.G*255 + (green.G*255 - blue.G*255)*pct)/255,
            math.floor(blue.B*255 + (green.B*255 - blue.B*255)*pct)/255
        )
        TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Size = UDim2.new(pct, 0, 1, 0), BackgroundColor3 = col
        }):Play()
    end
    local function reset()
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = C.PINK
        bg.Visible = false
    end
    return bg, set, reset
end

-- ══════════════════════════════════════════════════════
-- ▌ TAB 1: ITEM TELEPORT
-- ══════════════════════════════════════════════════════
local scrollItem, _ = makeScroll(contentArea)
scrollItem.Visible = true

local clickSel    = false
local lassoMode   = false
local groupMode   = false
local selectedItems = {}
local tpCircle    = nil
local isTeleporting = false

local sb1, sTxt1, sCnt1, sDot1 = statusPill(scrollItem, 1)
local function setStatus1(msg) sTxt1.Text = msg end
local function updateCount1()
    local n = 0; for _ in pairs(selectedItems) do n += 1 end; sCnt1.Text = n .. " sel"
end

sectionLabel(scrollItem, "Selection Mode", 2)
makeToggle(scrollItem, "Click Selection", false, 3, function(v)
    clickSel = v; if v then lassoMode = false end
    setStatus1(v and "Click mode active" or "Click mode off")
end)
makeToggle(scrollItem, "Lasso Tool", false, 4, function(v)
    lassoMode = v; if v then clickSel = false end
    setStatus1(v and "Drag to lasso items" or "Lasso off")
end)
makeToggle(scrollItem, "Group Selection (same type)", false, 5, function(v)
    groupMode = v; setStatus1(v and "Group mode on" or "Group mode off")
end)

sep(scrollItem, 6)
sectionLabel(scrollItem, "Teleport Destination", 7)

local destRow = Instance.new("Frame", scrollItem)
destRow.Size = UDim2.new(1, -20, 0, 34); destRow.BackgroundTransparency = 1; destRow.LayoutOrder = 8

local tpSetBtn = Instance.new("TextButton", destRow)
tpSetBtn.Size = UDim2.new(0.5, -3, 1, 0); tpSetBtn.BackgroundColor3 = C.BTN
tpSetBtn.Text = "⊕  Set Marker"; tpSetBtn.Font = Enum.Font.GothamSemibold
tpSetBtn.TextSize = 12; tpSetBtn.TextColor3 = C.TEXT; tpSetBtn.BorderSizePixel = 0
tpSetBtn.AutoButtonColor = false
Instance.new("UICorner", tpSetBtn).CornerRadius = UDim.new(0, 7)

local tpRemBtn = Instance.new("TextButton", destRow)
tpRemBtn.Size = UDim2.new(0.5, -3, 1, 0); tpRemBtn.Position = UDim2.new(0.5, 3, 0, 0)
tpRemBtn.BackgroundColor3 = C.BTN; tpRemBtn.Text = "⊗  Remove"
tpRemBtn.Font = Enum.Font.GothamSemibold; tpRemBtn.TextSize = 12
tpRemBtn.TextColor3 = C.TEXT; tpRemBtn.BorderSizePixel = 0; tpRemBtn.AutoButtonColor = false
Instance.new("UICorner", tpRemBtn).CornerRadius = UDim.new(0, 7)

for _, b in {tpSetBtn, tpRemBtn} do
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HOV}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN}):Play() end)
end

local destPill = Instance.new("Frame", scrollItem)
destPill.Size = UDim2.new(1, -20, 0, 26); destPill.BackgroundColor3 = Color3.fromRGB(12, 6, 14)
destPill.BorderSizePixel = 0; destPill.LayoutOrder = 9
Instance.new("UICorner", destPill).CornerRadius = UDim.new(0, 6)
local ddot = Instance.new("Frame", destPill)
ddot.Size = UDim2.new(0, 8, 0, 8); ddot.Position = UDim2.new(0, 10, 0.5, -4)
ddot.BackgroundColor3 = Color3.fromRGB(80, 50, 80); ddot.BorderSizePixel = 0
Instance.new("UICorner", ddot).CornerRadius = UDim.new(1, 0)
local dtxt = Instance.new("TextLabel", destPill)
dtxt.Size = UDim2.new(1, -28, 1, 0); dtxt.Position = UDim2.new(0, 26, 0, 0)
dtxt.BackgroundTransparency = 1; dtxt.Font = Enum.Font.Gotham; dtxt.TextSize = 11
dtxt.TextColor3 = C.TEXT_DIM; dtxt.TextXAlignment = Enum.TextXAlignment.Left
dtxt.Text = "No destination set"

sep(scrollItem, 10)
sectionLabel(scrollItem, "Actions", 11)
local progBg1, setProgBar1, _ = makeProgress(scrollItem, 12)
progBg1.Visible = false

local tpBtn1    = makeBtn(scrollItem, "▶  Teleport Selected Items", Color3.fromRGB(100, 30, 70), 13)
local cancelBtn = makeBtn(scrollItem, "■  Cancel Teleport", C.BTN, 14)
local clearBtn  = makeBtn(scrollItem, "✕  Clear Selection", C.BTN, 15)

-- Item helpers
local function getOwner(m)
    local ov = m:FindFirstChild("Owner")
    if ov then
        if ov:IsA("ObjectValue") then return ov.Value
        elseif ov:IsA("StringValue") then return ov.Value end
    end
end
local function getCategory(m)
    local iv = m:FindFirstChild("ItemName")
    if iv and iv:IsA("StringValue") then return iv.Value end
    return m.Name
end
local function isMov(m)
    if not getOwner(m) then return false end
    return (m.PrimaryPart or m:FindFirstChild("Main") or m:FindFirstChildWhichIsA("BasePart")) ~= nil
end
local function highlight(m)
    if selectedItems[m] then return end
    local hl = Instance.new("SelectionBox")
    hl.Color3 = C.PINK; hl.LineThickness = 0.05; hl.Adornee = m; hl.Parent = m
    selectedItems[m] = hl; updateCount1()
end
local function unhighlight(m)
    if selectedItems[m] then selectedItems[m]:Destroy(); selectedItems[m] = nil; updateCount1() end
end
local function unhighlightAll()
    for m, hl in pairs(selectedItems) do if hl and hl.Parent then hl:Destroy() end end
    selectedItems = {}; updateCount1()
end
local function handleSel(target, force)
    if not target then return end
    local m = target:FindFirstAncestorOfClass("Model")
    if not (m and isMov(m)) then return end
    if groupMode then
        local ow, cat = getOwner(m), getCategory(m)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isMov(obj) and getOwner(obj) == ow and getCategory(obj) == cat then
                highlight(obj)
            end
        end
    else
        if force then highlight(m)
        elseif selectedItems[m] then unhighlight(m)
        else highlight(m) end
    end
end

tpSetBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy() end
    tpCircle = Instance.new("Part")
    tpCircle.Name = "PinkHubTpMarker"; tpCircle.Shape = Enum.PartType.Ball
    tpCircle.Size = Vector3.new(3, 3, 3); tpCircle.Material = Enum.Material.Neon
    tpCircle.Color = C.PINK; tpCircle.Transparency = 0.35
    tpCircle.Anchored = true; tpCircle.CanCollide = false
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        tpCircle.Position = char.HumanoidRootPart.Position
    end
    tpCircle.Parent = workspace
    ddot.BackgroundColor3 = C.PINK
    local p = tpCircle.Position
    dtxt.Text = string.format("Set → (%.0f, %.0f, %.0f)", p.X, p.Y, p.Z)
    dtxt.TextColor3 = C.PINK_GLOW
    setStatus1("Destination placed ♡")
end)

tpRemBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy(); tpCircle = nil end
    ddot.BackgroundColor3 = Color3.fromRGB(80, 50, 80)
    dtxt.Text = "No destination set"; dtxt.TextColor3 = C.TEXT_DIM
    setStatus1("Destination removed")
end)

addCleanup(function() if tpCircle and tpCircle.Parent then tpCircle:Destroy() end end)

-- Teleport logic (kept exactly from Pink's working system)
tpBtn1.MouseButton1Click:Connect(function()
    if not tpCircle then setStatus1("⚠ Set a destination first!") return end
    if isTeleporting then return end
    isTeleporting = true
    progBg1.Visible = true
    task.spawn(function()
        local queue = {}
        for m in pairs(selectedItems) do
            if m and m.Parent then table.insert(queue, m) end
        end
        local total = #queue
        while #queue > 0 and isTeleporting do
            local failed = {}
            local done = total - #queue
            for _, m in ipairs(queue) do
                if not isTeleporting then break end
                if not (m and m.Parent) then continue end
                local mp = m.PrimaryPart or m:FindFirstChild("Main") or m:FindFirstChildWhichIsA("BasePart")
                if not mp then continue end
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                setStatus1("Teleporting... " .. done .. "/" .. total)
                setProgBar1(done, total)
                hrp.CFrame = mp.CFrame * CFrame.new(0, 4, 2)
                task.wait(0.1)
                local dragger = game.ReplicatedStorage:FindFirstChild("Interaction")
                    and game.ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
                if dragger then dragger:FireServer(m) end
                task.wait(0.05)
                if mp and mp.Parent then mp.CFrame = tpCircle.CFrame end
                task.wait(0.05)
                if dragger then dragger:FireServer(m) end
                task.wait(0.2)
                if mp and mp.Parent then
                    local dist = (mp.Position - tpCircle.Position).Magnitude
                    if dist > 8 then
                        table.insert(failed, m)
                    else
                        local hl = selectedItems[m]
                        if hl and hl.Parent then hl:Destroy() end
                        selectedItems[m] = nil; done += 1; updateCount1()
                    end
                end
            end
            queue = failed
            if #queue > 0 and isTeleporting then
                setStatus1("Retrying " .. #queue .. " item(s)...")
                task.wait(0.6)
            end
        end
        task.wait(0.5)
        progBg1.Visible = false
        isTeleporting = false
        setStatus1(#queue == 0 and "✓ All items teleported! ♡" or "Cancelled")
    end)
end)

cancelBtn.MouseButton1Click:Connect(function() isTeleporting = false; setStatus1("Cancelled") end)
clearBtn.MouseButton1Click:Connect(function() unhighlightAll(); setStatus1("Selection cleared") end)

-- Lasso
local lassoFrame = Instance.new("Frame", gui)
lassoFrame.BackgroundColor3    = C.PINK
lassoFrame.BackgroundTransparency = 0.85
lassoFrame.BorderSizePixel     = 0
lassoFrame.Visible             = false
lassoFrame.ZIndex              = 20
local lassoStroke = Instance.new("UIStroke", lassoFrame)
lassoStroke.Color = C.PINK_GLOW; lassoStroke.Thickness = 1.5
local lassoStart = nil
local camera = workspace.CurrentCamera

local function updateLasso(s, c)
    lassoFrame.Position = UDim2.new(0, math.min(s.X,c.X), 0, math.min(s.Y,c.Y))
    lassoFrame.Size = UDim2.new(0, math.abs(c.X-s.X), 0, math.abs(c.Y-s.Y))
end
local function selectInLasso()
    if not lassoStart then return end
    local mouse = player:GetMouse()
    local cur = Vector2.new(mouse.X, mouse.Y)
    local minX,maxX = math.min(lassoStart.X,cur.X), math.max(lassoStart.X,cur.X)
    local minY,maxY = math.min(lassoStart.Y,cur.Y), math.max(lassoStart.Y,cur.Y)
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isMov(obj) then
            local mp = obj.PrimaryPart or obj:FindFirstChild("Main") or obj:FindFirstChildWhichIsA("BasePart")
            if mp then
                local sp, onScreen = camera:WorldToScreenPoint(mp.Position)
                if onScreen and sp.X >= minX and sp.X <= maxX and sp.Y >= minY and sp.Y <= maxY then
                    highlight(obj); count += 1
                end
            end
        end
    end
    setStatus1(count > 0 and "Lasso: " .. count .. " item(s)" or "No items in lasso")
end

local mouse = player:GetMouse()
local mDrag = false
mouse.Button1Down:Connect(function()
    mDrag = true
    if lassoMode then
        lassoStart = Vector2.new(mouse.X, mouse.Y)
        lassoFrame.Size = UDim2.new(0,0,0,0); lassoFrame.Visible = true
    elseif clickSel then
        handleSel(mouse.Target, false)
    end
end)
mouse.Button1Up:Connect(function()
    mDrag = false
    if lassoMode then selectInLasso(); lassoFrame.Visible = false; lassoStart = nil end
end)
mouse.Move:Connect(function()
    if mDrag and lassoMode and lassoStart then
        updateLasso(lassoStart, Vector2.new(mouse.X, mouse.Y))
    end
end)

-- ══════════════════════════════════════════════════════
-- ▌ TAB 2: BUTTER LEAK — SMOOTH TRUCK SYSTEM
-- ══════════════════════════════════════════════════════
local scrollButter, _ = makeScroll(contentArea)
scrollButter.Visible = false

local sb2, sTxt2, sCnt2, sDot2 = statusPill(scrollButter, 1)
local function setStatus2(msg, active)
    sTxt2.Text = msg
    sDot2.BackgroundColor3 = active and C.PINK or C.PINK_DIM
end

sectionLabel(scrollButter, "Players", 2)
local _, giverBox    = makeInputRow(scrollButter, "Giver Name",    "player username", 3)
local _, receiverBox = makeInputRow(scrollButter, "Receiver Name", "player username", 4)

sep(scrollButter, 5)
sectionLabel(scrollButter, "What to Transfer", 6)
local _, getStructures = makeToggle(scrollButter, "Structures",     false, 7)
local _, getFurniture  = makeToggle(scrollButter, "Furniture",      false, 8)
local _, getTrucks     = makeToggle(scrollButter, "Trucks + Cargo", false, 9)
local _, getItems      = makeToggle(scrollButter, "Purchased Items",false, 10)
local _, getGifs       = makeToggle(scrollButter, "Gif Items",      false, 11)
local _, getWood       = makeToggle(scrollButter, "Wood",           false, 12)

sep(scrollButter, 13)
sectionLabel(scrollButter, "Progress", 14)
local progBg2, setProgBar2, resetProgBar2 = makeProgress(scrollButter, 15)

sep(scrollButter, 16)
sectionLabel(scrollButter, "Execute", 17)
local runBtn  = makeBtn(scrollButter, "▶  Run Butter Dupe",  Color3.fromRGB(100, 30, 70), 18)
local stopBtn = makeBtn(scrollButter, "■  Stop",             C.BTN,                        19)

local butterRunning = false
local butterThread  = nil

stopBtn.MouseButton1Click:Connect(function()
    butterRunning = false
    if butterThread then pcall(task.cancel, butterThread) end
    butterThread = nil
    setStatus2("Stopped", false)
    resetProgBar2()
end)

addCleanup(function()
    butterRunning = false
    if butterThread then pcall(task.cancel, butterThread) end
    butterThread = nil
end)

runBtn.MouseButton1Click:Connect(function()
    if butterRunning then setStatus2("Already running!", true) return end

    local giverName    = giverBox.Text
    local receiverName = receiverBox.Text
    if giverName == "" or receiverName == "" then
        setStatus2("⚠ Enter both player names!", false); return
    end

    butterRunning = true
    setStatus2("Finding bases...", true)
    resetProgBar2()

    butterThread = task.spawn(function()
        local RS        = game:GetService("ReplicatedStorage")
        local Char      = player.Character or player.CharacterAdded:Wait()

        -- ── Find base origins ─────────────────────────────
        local GiveBaseOrigin, ReceiverBaseOrigin
        for _, v in pairs(workspace.Properties:GetDescendants()) do
            if v.Name == "Owner" then
                local val = tostring(v.Value)
                if val == giverName    then GiveBaseOrigin    = v.Parent:FindFirstChild("OriginSquare") end
                if val == receiverName then ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
            end
        end
        if not (GiveBaseOrigin and ReceiverBaseOrigin) then
            setStatus2("⚠ Couldn't find bases!", false); butterRunning = false; return
        end

        -- ── Helpers ───────────────────────────────────────
        local function isPointInside(point, boxCFrame, boxSize)
            local r = boxCFrame:PointToObjectSpace(point)
            return math.abs(r.X) <= boxSize.X/2
               and math.abs(r.Y) <= boxSize.Y/2 + 2
               and math.abs(r.Z) <= boxSize.Z/2
        end

        local function setCharNoclip(state)
            pcall(function()
                for _, p in ipairs(Char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = not state end
                end
            end)
        end

        local function freezeCargo(part)
            pcall(function()
                part.Anchored = true; part.CanCollide = false
                for _, mp in ipairs(part.Parent:GetDescendants()) do
                    if mp:IsA("BasePart") then mp.Anchored = true; mp.CanCollide = false end
                end
            end)
        end

        local function releaseCargo(part, targetCF)
            pcall(function()
                part.CFrame   = targetCF
                part.Anchored = false; part.CanCollide = true
                for _, mp in ipairs(part.Parent:GetDescendants()) do
                    if mp:IsA("BasePart") then mp.Anchored = false; mp.CanCollide = true end
                end
            end)
        end

        local function seekNetOwn(part)
            if not butterRunning then return end
            if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.1)
            end
            for i = 1, 50 do
                task.wait(0.05)
                RS.Interaction.ClientIsDragging:FireServer(part.Parent)
            end
        end

        local function sendItem(part, Offset)
            if not butterRunning then return end
            if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.1)
            end
            seekNetOwn(part)
            for i = 1, 200 do part.CFrame = Offset end
            task.wait(0.2)
        end

        local function countGiver(check)
            local n = 0
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName and check(v.Parent) then n += 1 end
            end
            return n
        end

        -- ══════════════════════════════════════════════════
        -- STRUCTURES
        -- ══════════════════════════════════════════════════
        if getStructures() and butterRunning then
            local total = countGiver(function(p)
                return p:FindFirstChild("Type") and tostring(p.Type.Value) == "Structure"
                   and (p:FindFirstChildOfClass("Part") or p:FindFirstChildOfClass("WedgePart"))
            end)
            if total > 0 then
                progBg2.Visible = true; setProgBar2(0, total)
                setStatus2("Sending structures... (0/" .. total .. ")", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName
                            and v.Parent:FindFirstChild("Type") and tostring(v.Parent.Type.Value) == "Structure"
                            and (v.Parent:FindFirstChildOfClass("Part") or v.Parent:FindFirstChildOfClass("WedgePart")) then
                            local PCF = (v.Parent:FindFirstChild("MainCFrame") and v.Parent.MainCFrame.Value)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local DA  = v.Parent:FindFirstChild("BlueprintWoodClass") and v.Parent.BlueprintWoodClass.Value or nil
                            local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local Off  = CFrame.new(nPos) * PCF.Rotation
                            repeat task.wait()
                                pcall(function()
                                    RS.PlaceStructure.ClientPlacedStructure:FireServer(
                                        v.Parent.ItemName.Value, Off, player, DA, v.Parent, true)
                                end)
                            until not v.Parent
                            done += 1; setProgBar2(done, total)
                            setStatus2("Structures: " .. done .. "/" .. total, true)
                        end
                    end
                end)
                setProgBar2(total, total)
            end
        end

        -- ══════════════════════════════════════════════════
        -- FURNITURE
        -- ══════════════════════════════════════════════════
        if getFurniture() and butterRunning then
            local total = countGiver(function(p)
                return p:FindFirstChild("Type") and tostring(p.Type.Value) == "Furniture"
                   and p:FindFirstChildOfClass("Part")
            end)
            if total > 0 then
                progBg2.Visible = true; setProgBar2(0, total)
                setStatus2("Sending furniture... (0/" .. total .. ")", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName
                            and v.Parent:FindFirstChild("Type") and tostring(v.Parent.Type.Value) == "Furniture"
                            and v.Parent:FindFirstChildOfClass("Part") then
                            local PCF = (v.Parent:FindFirstChild("MainCFrame") and v.Parent.MainCFrame.Value)
                                or (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local DA  = v.Parent:FindFirstChild("BlueprintWoodClass") and v.Parent.BlueprintWoodClass.Value or nil
                            local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local Off  = CFrame.new(nPos) * PCF.Rotation
                            repeat task.wait()
                                pcall(function()
                                    RS.PlaceStructure.ClientPlacedStructure:FireServer(
                                        v.Parent.ItemName.Value, Off, player, DA, v.Parent, true)
                                end)
                            until not v.Parent
                            done += 1; setProgBar2(done, total)
                            setStatus2("Furniture: " .. done .. "/" .. total, true)
                        end
                    end
                end)
                setProgBar2(total, total)
            end
        end

        -- ══════════════════════════════════════════════════
        -- TRUCKS — SMOOTH SYSTEM
        -- No mid-air freeze. Cargo anchored + noclipped during
        -- transit. Placed 2s after truck lands. Then released.
        -- ══════════════════════════════════════════════════
        if getTrucks() and butterRunning then
            local giverTrucks = {}
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName then
                    local model = v.Parent
                    if model and model:FindFirstChild("DriveSeat") then
                        table.insert(giverTrucks, model)
                    end
                end
            end

            local truckCount = #giverTrucks
            if truckCount > 0 then
                progBg2.Visible = true; setProgBar2(0, truckCount)
                setStatus2("Sending trucks (0/" .. truckCount .. ")...", true)
                local truckDone = 0
                local ignoredParts = {}

                for tIdx, tModel in ipairs(giverTrucks) do
                    if not butterRunning then break end
                    if not (tModel and tModel.Parent) then
                        truckDone += 1; setProgBar2(truckDone, truckCount); continue
                    end

                    local driveSeat = tModel:FindFirstChild("DriveSeat")
                    if not driveSeat then
                        truckDone += 1; setProgBar2(truckDone, truckCount); continue
                    end

                    -- mark truck + char as ignored for cargo sweep
                    for _, p in ipairs(tModel:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end
                    for _, p in ipairs(Char:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end

                    -- teleport into seat instantly (noclip so no physics stall)
                    setCharNoclip(true)
                    Char.HumanoidRootPart.CFrame = driveSeat.CFrame
                    task.wait(0.05)
                    driveSeat:Sit(Char.Humanoid)
                    local sitT = 0
                    repeat
                        task.wait(0.05); sitT += 0.05
                        if not Char.Humanoid.SeatPart then driveSeat:Sit(Char.Humanoid) end
                    until Char.Humanoid.SeatPart or sitT > 3
                    setCharNoclip(false)

                    if not Char.Humanoid.SeatPart then
                        truckDone += 1; setProgBar2(truckDone, truckCount); continue
                    end

                    -- compute destination
                    local mainPart    = tModel:FindFirstChild("Main")
                    local truckSrcCF  = mainPart and mainPart.CFrame or tModel:GetPrimaryPartCFrame()
                    local truckDestPos = truckSrcCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                    local truckDestCF  = CFrame.new(truckDestPos) * truckSrcCF.Rotation

                    -- sweep cargo, anchor+noclip it, teleport to destination
                    local thisCargo = {}
                    local mCF, mSz  = tModel:GetBoundingBox()
                    for _, part in ipairs(workspace:GetDescendants()) do
                        if part:IsA("BasePart") and not ignoredParts[part]
                            and (part.Name == "Main" or part.Name == "WoodSection") then
                            if part:FindFirstChild("Weld") and part.Weld.Part1
                                and part.Weld.Part1.Parent ~= part.Parent then continue end
                            if isPointInside(part.Position, mCF, mSz) then
                                local PCF  = part.CFrame
                                local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                local tOff = CFrame.new(nPos) * PCF.Rotation
                                freezeCargo(part)
                                pcall(function() part.CFrame = tOff end)
                                table.insert(thisCargo, {Instance = part, TargetCFrame = tOff})
                            end
                        end
                    end

                    -- move truck while seated — instant, no hang
                    tModel:SetPrimaryPartCFrame(truckDestCF)
                    task.wait(0.05)

                    -- eject into next truck OR go back to giver base
                    local SitPart   = Char.Humanoid.SeatPart
                    local DoorHinge = SitPart and SitPart.Parent:FindFirstChild("PaintParts")
                        and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                        and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")

                    local nextTruck = giverTrucks[tIdx + 1]
                    local nextSeat  = nextTruck and nextTruck:FindFirstChild("DriveSeat")

                    setCharNoclip(true)
                    if SitPart then pcall(function() SitPart:Destroy() end) end
                    task.wait(0.05)

                    if nextSeat then
                        -- jump straight into next truck — zero float time
                        Char.HumanoidRootPart.CFrame = nextSeat.CFrame
                    else
                        -- last truck — return to giver base
                        Char.HumanoidRootPart.CFrame = CFrame.new(GiveBaseOrigin.Position + Vector3.new(0, 5, 0))
                    end
                    setCharNoclip(false)

                    if DoorHinge then
                        task.spawn(function()
                            for i = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end
                        end)
                    end

                    -- 2s after truck landed: snap cargo to final pos then unanchor
                    local captured = thisCargo
                    task.spawn(function()
                        task.wait(2)
                        for _, data in ipairs(captured) do
                            releaseCargo(data.Instance, data.TargetCFrame)
                        end
                    end)

                    truckDone += 1
                    setProgBar2(truckDone, truckCount)
                    setStatus2("Trucks: " .. truckDone .. "/" .. truckCount, true)
                end

                -- wait for all cargo releases
                task.wait(2.1)
                setProgBar2(truckCount, truckCount)

                -- return to giver base when done
                if butterRunning and Char:FindFirstChild("HumanoidRootPart") then
                    Char.HumanoidRootPart.CFrame = CFrame.new(GiveBaseOrigin.Position + Vector3.new(0, 5, 0))
                    task.wait(0.3)
                end
            end
        end

        -- ══════════════════════════════════════════════════
        -- PURCHASED ITEMS
        -- ══════════════════════════════════════════════════
        if getItems() and butterRunning then
            local total = countGiver(function(p)
                return p:FindFirstChild("PurchasedBoxItemName")
                   and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progBg2.Visible = true; setProgBar2(0, total)
                setStatus2("Sending purchased items...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName
                            and v.Parent:FindFirstChild("PurchasedBoxItemName") then
                            local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                            if not part then continue end
                            local PCF = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            sendItem(part, CFrame.new(nPos) * PCF.Rotation)
                            done += 1; setProgBar2(done, total)
                            setStatus2("Items: " .. done .. "/" .. total, true)
                        end
                    end
                end)
                setProgBar2(total, total)
            end
        end

        -- ══════════════════════════════════════════════════
        -- GIF ITEMS
        -- ══════════════════════════════════════════════════
        if getGifs() and butterRunning then
            local total = countGiver(function(p)
                return p:FindFirstChildOfClass("Script") and p:FindFirstChild("DraggableItem")
                   and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progBg2.Visible = true; setProgBar2(0, total)
                setStatus2("Sending gif items...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName
                            and v.Parent:FindFirstChildOfClass("Script") and v.Parent:FindFirstChild("DraggableItem") then
                            local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                            if not part then continue end
                            local PCF = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            sendItem(part, CFrame.new(nPos) * PCF.Rotation)
                            done += 1; setProgBar2(done, total)
                            setStatus2("Gif items: " .. done .. "/" .. total, true)
                        end
                    end
                end)
                setProgBar2(total, total)
            end
        end

        -- ══════════════════════════════════════════════════
        -- WOOD — Heartbeat noclip approach
        -- ══════════════════════════════════════════════════
        if getWood() and butterRunning then
            local total = countGiver(function(p)
                return p:FindFirstChild("TreeClass")
                   and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progBg2.Visible = true; setProgBar2(0, total)
                setStatus2("Sending wood... (0/" .. total .. ")", true)
                local done = 0
                local dragger = RS:FindFirstChild("Interaction") and RS.Interaction:FindFirstChild("ClientIsDragging")
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if not (v.Name == "Owner" and tostring(v.Value) == giverName and v.Parent:FindFirstChild("TreeClass")) then continue end
                        local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                        if not part then continue end
                        local PCF = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                            or v.Parent:FindFirstChildOfClass("Part").CFrame
                        local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                        local targetCF = CFrame.new(nPos) * PCF.Rotation
                        local model = v.Parent
                        if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 20 then
                            Char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 3, 3)
                            task.wait(0.08)
                        end
                        local startT  = tick()
                        local done2   = false
                        local conn
                        conn = RunService.Heartbeat:Connect(function()
                            if not (part and part.Parent) then conn:Disconnect(); done2 = true; return end
                            if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 20 then
                                Char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 3, 3)
                            end
                            setCharNoclip(true)
                            if dragger then pcall(function() dragger:FireServer(model) end) end
                            pcall(function() part.CFrame = targetCF end)
                            if (part.Position - targetCF.Position).Magnitude < 5 or (tick() - startT) >= 2 then
                                conn:Disconnect(); done2 = true
                            end
                        end)
                        local ws = tick()
                        while not done2 and (tick() - ws) < 2.5 do task.wait() end
                        if conn then pcall(function() conn:Disconnect() end) end
                        setCharNoclip(false)
                        done += 1; setProgBar2(done, total)
                        setStatus2("Wood: " .. done .. "/" .. total, true)
                        task.wait(0.6)
                    end
                end)
                setProgBar2(total, total)
            end
        end

        if butterRunning then
            setStatus2("✓ Done! ♡", false)
        end
        butterRunning = false
        butterThread  = nil
    end)
end)

-- ══════════════════════════════════════════════════════
-- TAB SWITCHING
-- ══════════════════════════════════════════════════════
local function switchTab(name)
    local isItem = (name == "item")
    scrollItem.Visible   = isItem
    scrollButter.Visible = not isItem
    TweenService:Create(tabItem, TweenInfo.new(0.18), {
        TextColor3 = isItem and C.PINK or C.TEXT_DIM,
        BackgroundColor3 = isItem and Color3.fromRGB(30, 14, 30) or C.PANEL
    }):Play()
    TweenService:Create(tabButter, TweenInfo.new(0.18), {
        TextColor3 = (not isItem) and C.PINK or C.TEXT_DIM,
        BackgroundColor3 = (not isItem) and Color3.fromRGB(30, 14, 30) or C.PANEL
    }):Play()
    ulItem.Visible   = isItem
    ulButter.Visible = not isItem
end

tabItem.MouseButton1Click:Connect(function()   switchTab("item")   end)
tabButter.MouseButton1Click:Connect(function() switchTab("butter") end)
switchTab("item")

-- ── KEYBIND: ] ───────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightBracket then
        if isOpen then closeWindow() else openWindow() end
    end
end)

print("[PinkHub Ultimate] Loaded ♡  |  Press ] or click the side button to toggle")
