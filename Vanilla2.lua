-- ═══════════════════════════════════════════════════════════════
-- VANILLA2 — TRUCK LOAD DUPE  (FIXED VERSION)
-- Execute AFTER Vanilla1
-- ═══════════════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla2_TruckDupe: _G.VH not found. Run Vanilla1 first.")
    return
end

local TweenService = _G.VH.TweenService
local Players      = _G.VH.Players
local player       = _G.VH.player
local cleanupTasks = _G.VH.cleanupTasks
local pages        = _G.VH.pages
local BTN_COLOR    = _G.VH.BTN_COLOR
local THEME_TEXT   = _G.VH.THEME_TEXT or Color3.fromRGB(230, 206, 226)

local RS = game:GetService("ReplicatedStorage")

-- ───────────────────────────────────────────────────
-- find the dupe page
-- ───────────────────────────────────────────────────
local page = pages["TruckDupeTab"] or pages["DupeTab"] or pages["TruckTab"]
if not page then
    for k, v in pairs(pages) do
        if string.lower(k):find("truck") or string.lower(k):find("dupe") then
            page = v; break
        end
    end
end
if not page then
    warn("[VanillaHub] Vanilla2_TruckDupe: no suitable tab page found in _G.VH.pages")
    return
end

-- ═══════════════════════════════════════════════════
-- ░░  CORE ENGINE  ░░
-- ═══════════════════════════════════════════════════

-- ── 1. BASE FINDER ──────────────────────────────────
local function findBase(playerName)
    local props = workspace:FindFirstChild("Properties")
    if not props then return nil end
    for _, v in pairs(props:GetDescendants()) do
        if v.Name == "Owner" and tostring(v.Value) == playerName then
            local sq = v.Parent and v.Parent:FindFirstChild("OriginSquare")
            if sq then return sq end
        end
    end
    return nil
end

-- ── 2. TRUCK SCANNER ────────────────────────────────
local function scanTrucks(ownerName)
    local trucks = {}
    local pm = workspace:FindFirstChild("PlayerModels")
    if not pm then return trucks end
    for _, v in pairs(pm:GetDescendants()) do
        if v.Name == "Owner" and tostring(v.Value) == ownerName then
            local m = v.Parent
            if m and m:IsA("Model") and m:FindFirstChild("DriveSeat") then
                table.insert(trucks, m)
            end
        end
    end
    return trucks
end

-- ── 3. CARGO SCANNER ────────────────────────────────
local function isInsideBox(point, boxCF, boxSz)
    local local_p = boxCF:PointToObjectSpace(point)
    return  math.abs(local_p.X) <= boxSz.X * 0.5 + 0.5
        and math.abs(local_p.Y) <= boxSz.Y * 0.5 + 1.5
        and math.abs(local_p.Z) <= boxSz.Z * 0.5 + 0.5
end

local function scanCargo(truckModel)
    local cargo = {}
    local truckParts = {}
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then truckParts[p] = true end
    end

    local boxCF, boxSz = truckModel:GetBoundingBox()

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not truckParts[obj]
            and (obj.Name == "Main" or obj.Name == "WoodSection") then
            -- FIX: Skip cargo welded to a DIFFERENT model, not skip cargo welded inside its own model
            local weld = obj:FindFirstChildWhichIsA("WeldConstraint")
                      or obj:FindFirstChildWhichIsA("Weld")
            if weld then
                local other = (weld:IsA("WeldConstraint") and (weld.Part0 == obj and weld.Part1 or weld.Part0))
                           or (weld:IsA("Weld") and weld.Part1)
                if other and other.Parent and other.Parent ~= obj.Parent and truckParts[other] == nil then
                    continue
                end
            end
            if isInsideBox(obj.Position, boxCF, boxSz) then
                table.insert(cargo, obj)
            end
        end
    end
    return cargo
end

-- ── 4. SNAPSHOT ─────────────────────────────────────
local function getAnchorCF(truckModel)
    local mp = truckModel:FindFirstChild("Main")
            or truckModel.PrimaryPart
            or truckModel:FindFirstChildWhichIsA("BasePart")
    return mp and mp.CFrame or CFrame.new()
end

local function snapshotCargo(truckModel, cargoList)
    local anchor = getAnchorCF(truckModel)
    local snaps = {}
    for _, part in ipairs(cargoList) do
        if part and part.Parent then
            snaps[part] = anchor:ToObjectSpace(part.CFrame)
        end
    end
    return snaps, anchor
end

-- ── 5. JOINT HELPERS ────────────────────────────────
-- FIX: Disable Motor6D/WheelJoints before anchoring to prevent joint destruction.
-- Simply setting Enabled=false preserves the joint; re-enable after unanchoring.
local function disableMotors(truckModel)
    local disabled = {}
    for _, v in ipairs(truckModel:GetDescendants()) do
        if v:IsA("Motor6D") or v:IsA("CylindricalConstraint") then
            if v.Enabled then
                v.Enabled = false
                table.insert(disabled, v)
            end
        end
    end
    return disabled
end

local function enableMotors(disabledList)
    for _, v in ipairs(disabledList) do
        if v and v.Parent then
            v.Enabled = true
        end
    end
end

-- ── 6. WARP ─────────────────────────────────────────
-- FIX: Capture ALL relative CFrames BEFORE task.wait() so physics settling
-- doesn't introduce drift. Disable motors before anchoring. Use savedAnchor
-- as the single source of truth for both truck and cargo positioning.
local function warpTruck(truckModel, destCF, snapshots, savedAnchor)
    -- Step A: Disable motors/joints first to prevent WheelJoint destruction
    local disabledMotors = disableMotors(truckModel)

    -- Step B: Capture relative CFrames of all truck parts NOW, before anchoring,
    -- using the exact same savedAnchor used during snapshotCargo
    local curAnchor = savedAnchor or getAnchorCF(truckModel)
    local relCFs = {}
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then
            relCFs[p] = curAnchor:ToObjectSpace(p.CFrame)
        end
    end

    if not next(relCFs) then
        enableMotors(disabledMotors)
        return
    end

    -- Step C: Freeze truck
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = true
            p.AssemblyLinearVelocity  = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
    end

    -- Step D: Freeze cargo
    for part in pairs(snapshots) do
        if part and part.Parent then
            part.Anchored = true
            part.AssemblyLinearVelocity  = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    -- FIX: Slightly longer wait to ensure server acknowledges anchored state,
    -- preventing physics from interfering with the move
    task.wait(0.05)

    -- Step E: Move all truck parts using pre-captured relative CFrames
    for p, rel in pairs(relCFs) do
        if p and p.Parent then
            p.CFrame = destCF:ToWorldSpace(rel)
        end
    end

    -- Step F: Place cargo at their saved offsets from destCF
    for part, offset in pairs(snapshots) do
        if part and part.Parent then
            part.CFrame = destCF:ToWorldSpace(offset)
        end
    end

    task.wait(0.05)

    -- Step G: Unfreeze cargo first, then truck, then re-enable motors
    for part in pairs(snapshots) do
        if part and part.Parent then part.Anchored = false end
    end

    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then p.Anchored = false end
    end

    -- FIX: Re-enable motors AFTER unanchoring so joints reconnect cleanly
    task.wait(0.02)
    enableMotors(disabledMotors)
end

-- ── 7. CONFIRM ──────────────────────────────────────
-- FIX: Removed the bogus ClientIsDragging remote call which was corrupting
-- physics state. Now just anchors, corrects, unanchors directly.
local CONFIRM_DIST = 3.5

local function confirmCargo(snapshots, destCF, onDone)
    task.spawn(function()
        task.wait(0.3)

        local corrections = 0
        for part, offset in pairs(snapshots) do
            if part and part.Parent then
                local expected = destCF:ToWorldSpace(offset)
                if (part.Position - expected.Position).Magnitude > CONFIRM_DIST then
                    corrections += 1
                    -- FIX: Direct anchored correction, no remote calls
                    part.Anchored = true
                    part.AssemblyLinearVelocity  = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                    task.wait(0.05)
                    part.CFrame   = expected
                    task.wait(0.02)
                    part.Anchored = false
                end
            end
        end

        if onDone then onDone(corrections) end
    end)
end

-- ── 8. DELTA HELPER ─────────────────────────────────
local function computeDestCF(sourceCF, giverOrigin, receiverOrigin)
    local delta = receiverOrigin.Position - giverOrigin.Position
    return CFrame.new(sourceCF.Position + delta) * sourceCF.Rotation
end

-- ═══════════════════════════════════════════════════
-- ░░  UI BUILDER HELPERS  ░░
-- ═══════════════════════════════════════════════════

local function uiLabel(text)
    local lbl = Instance.new("TextLabel", page)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function uiSep()
    local s = Instance.new("Frame", page)
    s.Size = UDim2.new(1,-12,0,1); s.BackgroundColor3 = Color3.fromRGB(40,40,55); s.BorderSizePixel = 0
end

local function uiBtn(text, color, cb)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(1,-12,0,34); btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local hov = Color3.new(
        math.min(color.R+0.09,1), math.min(color.G+0.04,1), math.min(color.B+0.09,1))
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=hov}):Play() end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=color}):Play() end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function uiStatusCard(defaultText)
    local card = Instance.new("Frame", page)
    card.Size = UDim2.new(1,-12,0,40); card.BackgroundColor3 = Color3.fromRGB(20,16,28)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(255,180,0); stroke.Thickness = 1; stroke.Transparency = 0.55
    local dot = Instance.new("Frame", card)
    dot.Size = UDim2.new(0,7,0,7); dot.Position = UDim2.new(0,10,0.5,-3)
    dot.BackgroundColor3 = Color3.fromRGB(80,80,100); dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(1,-28,1,0); lbl.Position = UDim2.new(0,24,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255,210,100)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.Text = defaultText or "Ready."

    local function setStatus(msg, active, col)
        lbl.Text = msg
        lbl.TextColor3 = col or Color3.fromRGB(255,210,100)
        dot.BackgroundColor3 = active
            and Color3.fromRGB(80,210,120)
            or  Color3.fromRGB(80,80,100)
    end
    return card, setStatus
end

local function uiProgressBar()
    local cont = Instance.new("Frame", page)
    cont.Size = UDim2.new(1,-12,0,44); cont.BackgroundColor3 = Color3.fromRGB(18,18,24)
    cont.BorderSizePixel = 0; cont.Visible = false
    Instance.new("UICorner", cont).CornerRadius = UDim.new(0,8)
    local topLbl = Instance.new("TextLabel", cont)
    topLbl.Size = UDim2.new(1,-12,0,16); topLbl.Position = UDim2.new(0,6,0,4)
    topLbl.BackgroundTransparency = 1; topLbl.Font = Enum.Font.GothamSemibold; topLbl.TextSize = 11
    topLbl.TextColor3 = THEME_TEXT; topLbl.TextXAlignment = Enum.TextXAlignment.Left
    topLbl.Text = ""
    local track = Instance.new("Frame", cont)
    track.Size = UDim2.new(1,-12,0,12); track.Position = UDim2.new(0,6,0,26)
    track.BackgroundColor3 = Color3.fromRGB(28,28,38); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(0,0,1,0); fill.BackgroundColor3 = Color3.fromRGB(90,160,255)
    fill.BorderSizePixel = 0; Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local function setProgress(done, total, label, color)
        cont.BackgroundTransparency = 0
        fill.BackgroundTransparency = 0
        topLbl.TextTransparency    = 0
        cont.Visible = true
        topLbl.Text = label or ("Warping... "..done.." / "..total)
        local pct = math.clamp(done / math.max(total, 1), 0, 1)
        local targetColor = color or Color3.fromRGB(90, 160, 255)
        TweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quint),
            { Size = UDim2.new(pct, 0, 1, 0), BackgroundColor3 = targetColor }):Play()
    end
    local function hide(delay)
        task.delay(delay or 2, function()
            TweenService:Create(cont,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
            TweenService:Create(fill,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
            TweenService:Create(topLbl,TweenInfo.new(0.4),{TextTransparency=1}):Play()
            task.delay(0.45, function()
                cont.Visible = false
                cont.BackgroundTransparency = 0
                fill.BackgroundTransparency = 0
                fill.Size = UDim2.new(0,0,1,0)
                topLbl.TextTransparency = 0
            end)
        end)
    end
    local function reset()
        cont.Visible = false
        fill.Size = UDim2.new(0,0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(90,160,255)
        topLbl.Text = ""
    end
    return cont, setProgress, hide, reset
end

-- Player dropdown (compact, reused for both modes)
local function uiPlayerDropdown(labelText)
    local HEADER_H = 40; local ITEM_H = 34; local MAX_SHOW = 5
    local selected = ""; local isOpen = false

    local outer = Instance.new("Frame", page)
    outer.Size = UDim2.new(1,-12,0,HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22,22,30); outer.BorderSizePixel = 0
    outer.ClipsDescendants = true
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0,8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = Color3.fromRGB(60,60,90); outerStroke.Thickness = 1; outerStroke.Transparency = 0.5

    local header = Instance.new("Frame", outer)
    header.Size = UDim2.new(1,0,0,HEADER_H); header.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", header)
    lbl.Size = UDim2.new(0,80,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = labelText
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size = UDim2.new(1,-96,0,28); selFrame.Position = UDim2.new(0,90,0.5,-14)
    selFrame.BackgroundColor3 = Color3.fromRGB(30,30,42); selFrame.BorderSizePixel = 0
    Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0,6)
    local selStroke = Instance.new("UIStroke", selFrame)
    selStroke.Color = Color3.fromRGB(70,70,110); selStroke.Thickness = 1; selStroke.Transparency = 0.4

    local avatar = Instance.new("ImageLabel", selFrame)
    avatar.Size = UDim2.new(0,20,0,20); avatar.Position = UDim2.new(0,6,0.5,-10)
    avatar.BackgroundColor3 = Color3.fromRGB(45,45,60); avatar.BorderSizePixel = 0
    avatar.Image = ""; avatar.ScaleType = Enum.ScaleType.Crop
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1,0)

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size = UDim2.new(1,-60,1,0); selLbl.Position = UDim2.new(0,32,0,0)
    selLbl.BackgroundTransparency = 1; selLbl.Text = "Select a player..."
    selLbl.Font = Enum.Font.GothamSemibold; selLbl.TextSize = 12
    selLbl.TextColor3 = Color3.fromRGB(110,110,140); selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local arrow = Instance.new("TextLabel", selFrame)
    arrow.Size = UDim2.new(0,22,1,0); arrow.Position = UDim2.new(1,-24,0,0)
    arrow.BackgroundTransparency = 1; arrow.Text = "▾"
    arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 14
    arrow.TextColor3 = Color3.fromRGB(120,120,160); arrow.TextXAlignment = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size = UDim2.new(1,0,1,0); headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""; headerBtn.ZIndex = 5

    local divider = Instance.new("Frame", outer)
    divider.Size = UDim2.new(1,-16,0,1); divider.Position = UDim2.new(0,8,0,HEADER_H)
    divider.BackgroundColor3 = Color3.fromRGB(50,50,75); divider.BorderSizePixel = 0
    divider.Visible = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position = UDim2.new(0,0,0,HEADER_H+2); listScroll.Size = UDim2.new(1,0,0,0)
    listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3; listScroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
    listScroll.CanvasSize = UDim2.new(0,0,0,0); listScroll.ClipsDescendants = true
    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y+6) end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop=UDim.new(0,4); listPad.PaddingBottom=UDim.new(0,4)
    listPad.PaddingLeft=UDim.new(0,6); listPad.PaddingRight=UDim.new(0,6)

    local function setSelected(name, userId)
        selected = name; selLbl.Text = name; selLbl.TextColor3 = THEME_TEXT
        arrow.TextColor3 = Color3.fromRGB(160,160,210); outerStroke.Color = Color3.fromRGB(90,90,160)
        if userId then
            pcall(function()
                avatar.Image = Players:GetUserThumbnailAsync(
                    userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
        end
    end

    local function closeList()
        isOpen = false
        TweenService:Create(arrow,      TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Rotation=0}):Play()
        TweenService:Create(outer,      TweenInfo.new(0.22,Enum.EasingStyle.Quint),{Size=UDim2.new(1,-12,0,HEADER_H)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.22,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end

    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            local row = Instance.new("TextButton", listScroll)
            row.Size = UDim2.new(1,0,0,ITEM_H); row.BackgroundColor3 = Color3.fromRGB(30,30,45)
            row.BorderSizePixel = 0; row.Text = ""; row.LayoutOrder = plr.UserId
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
            local rAv = Instance.new("ImageLabel", row)
            rAv.Size=UDim2.new(0,24,0,24); rAv.Position=UDim2.new(0,8,0.5,-12)
            rAv.BackgroundColor3=Color3.fromRGB(45,45,60); rAv.BorderSizePixel=0; rAv.ScaleType=Enum.ScaleType.Crop
            Instance.new("UICorner",rAv).CornerRadius=UDim.new(1,0)
            pcall(function()
                rAv.Image=Players:GetUserThumbnailAsync(plr.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)
            local rLbl = Instance.new("TextLabel", row)
            rLbl.Size=UDim2.new(1,-44,1,0); rLbl.Position=UDim2.new(0,38,0,0)
            rLbl.BackgroundTransparency=1; rLbl.Text=plr.Name
            rLbl.Font=Enum.Font.GothamSemibold; rLbl.TextSize=13
            rLbl.TextColor3=plr.Name==selected and Color3.fromRGB(200,200,255) or THEME_TEXT
            rLbl.TextXAlignment=Enum.TextXAlignment.Left
            row.MouseButton1Click:Connect(function()
                setSelected(plr.Name, plr.UserId); closeList() end)
            row.MouseEnter:Connect(function()
                TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(42,42,62)}):Play() end)
            row.MouseLeave:Connect(function()
                TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(30,30,45)}):Play() end)
        end
    end

    local function openList()
        isOpen = true; buildList()
        local count = #Players:GetPlayers()
        local listH = math.min(count,MAX_SHOW)*(ITEM_H+3)+8
        divider.Visible = true
        TweenService:Create(arrow,      TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Rotation=180}):Play()
        TweenService:Create(outer,      TweenInfo.new(0.25,Enum.EasingStyle.Quint),{Size=UDim2.new(1,-12,0,HEADER_H+2+listH)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.25,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,listH)}):Play()
    end

    headerBtn.MouseButton1Click:Connect(function() if isOpen then closeList() else openList() end end)
    headerBtn.MouseEnter:Connect(function()
        TweenService:Create(selFrame,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(38,38,55)}):Play() end)
    headerBtn.MouseLeave:Connect(function()
        TweenService:Create(selFrame,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(30,30,42)}):Play() end)

    Players.PlayerAdded:Connect(function() if isOpen then buildList() end end)
    Players.PlayerRemoving:Connect(function(leaving)
        if leaving.Name == selected then
            selected=""; selLbl.Text="Select a player..."; selLbl.TextColor3=Color3.fromRGB(110,110,140)
            avatar.Image=""; arrow.TextColor3=Color3.fromRGB(120,120,160); outerStroke.Color=Color3.fromRGB(60,60,90)
        end
        if isOpen then buildList() end
    end)

    return outer, function() return selected end
end

-- ═══════════════════════════════════════════════════
-- ░░  SECTION 1: SINGLE TRUCK WARP  ░░
-- ═══════════════════════════════════════════════════

uiLabel("Single Truck Warp")

local hintSingle = Instance.new("TextLabel", page)
hintSingle.Size=UDim2.new(1,-12,0,28); hintSingle.BackgroundColor3=Color3.fromRGB(16,16,22)
hintSingle.BorderSizePixel=0; hintSingle.Font=Enum.Font.Gotham; hintSingle.TextSize=11
hintSingle.TextColor3=Color3.fromRGB(100,100,130); hintSingle.TextWrapped=true
hintSingle.TextXAlignment=Enum.TextXAlignment.Left
hintSingle.Text="  Sit in your truck on Giver base, pick a Receiver, hit Warp."
Instance.new("UICorner",hintSingle).CornerRadius=UDim.new(0,6)
Instance.new("UIPadding",hintSingle).PaddingLeft=UDim.new(0,6)

local _, getSingleReceiver = uiPlayerDropdown("Receiver")

local _, singleStatus = uiStatusCard("Sit in your truck, pick receiver, hit Warp.")
local _, singleProg, singleProgHide = uiProgressBar()

uiBtn("Warp My Truck + Load", Color3.fromRGB(40,80,120), function()
    local Char = player.Character
    if not Char then singleStatus("No character found!", false); return end
    local hum  = Char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if not seat or seat.Name ~= "DriveSeat" then
        singleStatus("You must be seated in a truck's DriveSeat!", false); return end

    local receiverName = getSingleReceiver()
    if receiverName == "" then singleStatus("Pick a receiver first!", false); return end

    local truckModel = seat.Parent
    if not (truckModel and truckModel.Parent) then
        singleStatus("Couldn't find the truck model!", false); return end

    local giverOrigin    = findBase(player.Name)
    local receiverOrigin = findBase(receiverName)
    if not giverOrigin    then singleStatus("Can't find your base!", false);     return end
    if not receiverOrigin then singleStatus("Can't find receiver base!", false); return end

    singleStatus("Scanning cargo...", true, Color3.fromRGB(140,210,255))

    task.spawn(function()
        local cargo          = scanCargo(truckModel)
        local snaps, anchor  = snapshotCargo(truckModel, cargo)

        singleStatus("Warping truck + "..#cargo.." cargo...", true, Color3.fromRGB(140,210,255))
        singleProg(0, 1, "Warping truck...")

        local destCF = computeDestCF(anchor, giverOrigin, receiverOrigin)

        -- FIX: Robust seat ejection — loop until actually unseated or timeout
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        local ejectStart = tick()
        while hum.SeatPart and (tick() - ejectStart) < 1.5 do
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            task.wait(0.08)
        end
        task.wait(0.05)

        warpTruck(truckModel, destCF, snaps, anchor)

        singleProg(1, 1, "Confirming cargo...", Color3.fromRGB(255,175,55))

        confirmCargo(snaps, destCF, function(corrections)
            local msg = corrections > 0
                and ("Done! ("..corrections.." cargo corrected)")
                or  "Done! All cargo landed clean."
            singleStatus(msg, false, Color3.fromRGB(90,220,110))
            singleProg(1, 1, msg, Color3.fromRGB(90,220,110))
            singleProgHide(2.5)
        end)

        task.wait(0.15)
        pcall(function()
            local hrp = Char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(giverOrigin.Position + Vector3.new(0, 5, 0))
            end
        end)
    end)
end)

-- ═══════════════════════════════════════════════════
-- ░░  SECTION 2: MULTI TRUCK WARP  ░░
-- ═══════════════════════════════════════════════════

uiSep(); uiLabel("Multi Truck Warp  (all trucks on base)")

local hintMulti = Instance.new("TextLabel", page)
hintMulti.Size=UDim2.new(1,-12,0,28); hintMulti.BackgroundColor3=Color3.fromRGB(16,16,22)
hintMulti.BorderSizePixel=0; hintMulti.Font=Enum.Font.Gotham; hintMulti.TextSize=11
hintMulti.TextColor3=Color3.fromRGB(100,100,130); hintMulti.TextWrapped=true
hintMulti.TextXAlignment=Enum.TextXAlignment.Left
hintMulti.Text="  Scans all trucks on Giver base, warps them all + cargo to Receiver."
Instance.new("UICorner",hintMulti).CornerRadius=UDim.new(0,6)
Instance.new("UIPadding",hintMulti).PaddingLeft=UDim.new(0,6)

local _, getMultiGiver    = uiPlayerDropdown("Giver")
local _, getMultiReceiver = uiPlayerDropdown("Receiver")

local scanResultCard = Instance.new("Frame", page)
scanResultCard.Size=UDim2.new(1,-12,0,34); scanResultCard.BackgroundColor3=Color3.fromRGB(18,14,26)
scanResultCard.BorderSizePixel=0; scanResultCard.Visible=false
Instance.new("UICorner",scanResultCard).CornerRadius=UDim.new(0,8)
local scanResultLbl = Instance.new("TextLabel", scanResultCard)
scanResultLbl.Size=UDim2.new(1,-16,1,0); scanResultLbl.Position=UDim2.new(0,8,0,0)
scanResultLbl.BackgroundTransparency=1; scanResultLbl.Font=Enum.Font.GothamSemibold; scanResultLbl.TextSize=12
scanResultLbl.TextColor3=Color3.fromRGB(160,220,255); scanResultLbl.TextXAlignment=Enum.TextXAlignment.Left
scanResultLbl.TextWrapped=true; scanResultLbl.Text=""

local _, multiStatus  = uiStatusCard("Pick Giver & Receiver, scan, then warp.")
local _, multiProg, multiProgHide, multiProgReset = uiProgressBar()

local scannedTrucks   = {}
local multiRunning    = false
local multiAbort      = false

uiBtn("Scan Giver's Trucks", Color3.fromRGB(35,55,90), function()
    if multiRunning then multiStatus("Warp in progress!", true); return end
    local giverName = getMultiGiver()
    if giverName == "" then multiStatus("Pick a Giver first!", false); return end

    scannedTrucks = {}
    scanResultCard.Visible = false
    multiStatus("Scanning...", true, Color3.fromRGB(140,210,255))

    task.spawn(function()
        local trucks = scanTrucks(giverName)
        if #trucks == 0 then
            multiStatus("No trucks found on "..giverName.."'s base!", false)
            return
        end

        local totalCargo = 0
        for _, tModel in ipairs(trucks) do
            local cargo          = scanCargo(tModel)
            local snaps, anchor  = snapshotCargo(tModel, cargo)
            -- FIX: Store anchor explicitly in entry so warpTruck always uses the correct reference
            table.insert(scannedTrucks, { model=tModel, cargo=cargo, snaps=snaps, anchor=anchor })
            totalCargo += #cargo
        end

        scanResultCard.Visible = true
        scanResultLbl.Text = #trucks.." truck(s) found — "..totalCargo.." cargo piece(s) total. Ready to warp."
        multiStatus(#trucks.." truck(s) scanned. Hit Warp All!", false, Color3.fromRGB(90,220,110))
    end)
end)

uiBtn("Warp All Trucks + Loads", Color3.fromRGB(35,100,50), function()
    if multiRunning then multiStatus("Already running!", true); return end
    if #scannedTrucks == 0 then multiStatus("Scan first!", false); return end

    local giverName    = getMultiGiver()
    local receiverName = getMultiReceiver()
    if giverName==""    then multiStatus("Pick a Giver!",    false); return end
    if receiverName=="" then multiStatus("Pick a Receiver!", false); return end

    local giverOrigin    = findBase(giverName)
    local receiverOrigin = findBase(receiverName)
    if not giverOrigin    then multiStatus("Can't find Giver's base!",    false); return end
    if not receiverOrigin then multiStatus("Can't find Receiver's base!", false); return end

    multiRunning = true; multiAbort = false
    multiProgReset()
    multiStatus("Warping "..#scannedTrucks.." truck(s)...", true, Color3.fromRGB(140,210,255))

    task.spawn(function()
        local total   = #scannedTrucks
        local done    = 0

        -- FIX: Track pending confirmations with a simple atomic counter.
        -- Use a table so closures share the same reference.
        local pendingCount = { value = total }

        local function onConfirmDone(_corrections)
            pendingCount.value -= 1
            if pendingCount.value <= 0 and not multiAbort then
                multiRunning = false
                multiStatus("All done! Trucks + cargo warped.", false, Color3.fromRGB(90,220,110))
                multiProg(total, total, "Complete!", Color3.fromRGB(90,220,110))
                multiProgHide(3)
                scannedTrucks = {}
                scanResultCard.Visible = false
            end
        end

        for _, entry in ipairs(scannedTrucks) do
            if multiAbort then
                -- FIX: Properly drain pending counter for skipped trucks
                -- so multiRunning always gets reset
                pendingCount.value -= 1
                if pendingCount.value <= 0 then break end
                continue
            end

            local tModel  = entry.model
            local snaps   = entry.snaps
            local anchor  = entry.anchor   -- FIX: use the stored anchor, not recomputed

            if not (tModel and tModel.Parent) then
                done += 1
                multiProg(done, total, "Warping... "..done.." / "..total)
                onConfirmDone(0)
                continue
            end

            local destCF = computeDestCF(anchor, giverOrigin, receiverOrigin)
            warpTruck(tModel, destCF, snaps, anchor)

            done += 1
            multiProg(done, total,
                "Warped "..done.." / "..total.." trucks",
                done == total and Color3.fromRGB(255,175,55) or Color3.fromRGB(90,160,255))

            confirmCargo(snaps, destCF, onConfirmDone)

            task.wait(0.12)
        end

        if multiAbort then
            multiRunning = false
            multiStatus("Stopped.", false)
            multiProgHide(1)
        end
    end)
end)

uiBtn("Stop", Color3.fromRGB(100,40,20), function()
    multiAbort = true; multiRunning = false
    multiStatus("Stopping...", false)
end)

uiBtn("Re-Scan", BTN_COLOR, function()
    if multiRunning then return end
    scannedTrucks={}; scanResultCard.Visible=false; multiProgReset()
    multiStatus("Cleared. Scan again when ready.", false)
end)

-- ═══════════════════════════════════════════════════
-- ░░  SECTION 3: PRECISION CARGO ONLY  ░░
-- ═══════════════════════════════════════════════════

uiSep(); uiLabel("Cargo Only Warp  (no truck movement)")

local hintCargo = Instance.new("TextLabel", page)
hintCargo.Size=UDim2.new(1,-12,0,28); hintCargo.BackgroundColor3=Color3.fromRGB(16,16,22)
hintCargo.BorderSizePixel=0; hintCargo.Font=Enum.Font.Gotham; hintCargo.TextSize=11
hintCargo.TextColor3=Color3.fromRGB(100,100,130); hintCargo.TextWrapped=true
hintCargo.TextXAlignment=Enum.TextXAlignment.Left
hintCargo.Text="  Warps all wood/cargo on Giver base to Receiver — trucks stay put."
Instance.new("UICorner",hintCargo).CornerRadius=UDim.new(0,6)
Instance.new("UIPadding",hintCargo).PaddingLeft=UDim.new(0,6)

local _, getCargoGiver    = uiPlayerDropdown("Giver")
local _, getCargoReceiver = uiPlayerDropdown("Receiver")

local cargoOnlyRunning = false
local cargoOnlyAbort   = false

local _, cargoStatus  = uiStatusCard("Pick Giver & Receiver, then warp cargo.")
local _, cargoProg, cargoProgHide, cargoProgReset = uiProgressBar()

uiBtn("Warp All Cargo", Color3.fromRGB(60,40,100), function()
    if cargoOnlyRunning then cargoStatus("Already running!", true); return end
    local giverName    = getCargoGiver()
    local receiverName = getCargoReceiver()
    if giverName==""    then cargoStatus("Pick a Giver!",    false); return end
    if receiverName=="" then cargoStatus("Pick a Receiver!", false); return end

    local giverOrigin    = findBase(giverName)
    local receiverOrigin = findBase(receiverName)
    if not giverOrigin    then cargoStatus("Can't find Giver's base!",    false); return end
    if not receiverOrigin then cargoStatus("Can't find Receiver's base!", false); return end

    cargoOnlyRunning = true; cargoOnlyAbort = false
    cargoStatus("Scanning cargo on base...", true, Color3.fromRGB(140,210,255))
    cargoProgReset()

    task.spawn(function()
        local BASE_RADIUS = 80
        local cargo = {}

        for _, obj in ipairs(workspace:GetDescendants()) do
            if cargoOnlyAbort then break end
            if obj:IsA("BasePart")
                and (obj.Name=="Main" or obj.Name=="WoodSection") then
                if (obj.Position - giverOrigin.Position).Magnitude <= BASE_RADIUS then
                    -- FIX: Same weld check fix as scanCargo — skip if welded to a DIFFERENT model
                    local weld = obj:FindFirstChildWhichIsA("WeldConstraint")
                              or obj:FindFirstChildWhichIsA("Weld")
                    local skip = false
                    if weld then
                        local other = (weld:IsA("WeldConstraint") and (weld.Part0 == obj and weld.Part1 or weld.Part0))
                                   or (weld:IsA("Weld") and weld.Part1)
                        if other and other.Parent and other.Parent ~= obj.Parent then
                            skip = true
                        end
                    end
                    if not skip then
                        table.insert(cargo, obj)
                    end
                end
            end
        end

        if #cargo == 0 then
            cargoStatus("No cargo found on "..giverName.."'s base.", false)
            cargoOnlyRunning = false; return
        end

        cargoStatus("Warping "..#cargo.." cargo pieces...", true, Color3.fromRGB(140,210,255))

        -- FIX: Compute full CFrame delta (not just position delta) so rotation
        -- and vertical offset are correctly preserved when bases are at different heights
        local delta = receiverOrigin.Position - giverOrigin.Position

        local total    = #cargo
        local done     = 0
        local finished = false

        local BATCH = 8
        for i = 1, total, BATCH do
            if cargoOnlyAbort then break end
            for j = i, math.min(i + BATCH - 1, total) do
                local part = cargo[j]
                if not (part and part.Parent) then
                    done += 1; continue
                end
                task.spawn(function()
                    part.Anchored = true
                    part.AssemblyLinearVelocity  = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                    task.wait(0.05)
                    -- FIX: Apply delta to the full CFrame so rotation is preserved
                    -- and parts don't land at wrong Y if base heights differ
                    part.CFrame = CFrame.new(part.CFrame.Position + delta) * part.CFrame.Rotation
                    task.wait(0.02)
                    part.Anchored = false
                    done += 1
                    cargoProg(done, total,
                        "Warping cargo "..done.." / "..total,
                        done >= total and Color3.fromRGB(90,220,110) or Color3.fromRGB(90,160,255))
                    if done >= total and not finished and not cargoOnlyAbort then
                        finished = true
                        cargoStatus("Done! "..total.." cargo pieces warped.", false, Color3.fromRGB(90,220,110))
                        cargoProg(total, total, "Complete!", Color3.fromRGB(90,220,110))
                        cargoProgHide(2.5)
                        cargoOnlyRunning = false
                    end
                end)
            end
            task.wait(0.04)
        end

        local waitStart = tick()
        while done < total and (tick() - waitStart) < 5 do task.wait(0.1) end

        if cargoOnlyAbort then
            cargoStatus("Stopped at "..done.." / "..total..".", false)
            cargoOnlyRunning = false
        end
    end)
end)

uiBtn("Stop", Color3.fromRGB(100,40,20), function()
    cargoOnlyAbort = true; cargoOnlyRunning = false
    cargoStatus("Stopped.", false)
end)

-- ═══════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    multiAbort      = true; multiRunning      = false
    cargoOnlyAbort  = true; cargoOnlyRunning  = false
    scannedTrucks   = {}
end)

print("[VanillaHub] Vanilla2_TruckDupe loaded — FIXED 3-mode warp system ready")
