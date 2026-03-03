-- ═══════════════════════════════════════════════════════════════
-- VANILLA2 — TRUCK LOAD DUPE  (BULLETPROOF REWRITE)
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

-- ── PAGE LOOKUP ──────────────────────────────────────
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
-- ░░  SAFE HELPERS  ░░
-- All engine functions wrap CFrame writes in pcall so a single
-- destroyed-mid-teleport part never halts the whole operation.
-- ═══════════════════════════════════════════════════

-- Safe CFrame write. Returns true on success.
local function setCFrame(part, cf)
    if not (part and part.Parent) then return false end
    local ok = pcall(function() part.CFrame = cf end)
    return ok
end

-- Safe anchor/unanchor + velocity zero.
local function freezePart(part)
    if not (part and part.Parent) then return end
    pcall(function()
        part.Anchored = true
        part.AssemblyLinearVelocity  = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function thawPart(part)
    if not (part and part.Parent) then return end
    pcall(function() part.Anchored = false end)
end

-- ═══════════════════════════════════════════════════
-- ░░  CORE ENGINE  ░░
-- ═══════════════════════════════════════════════════

-- ── 1. BASE FINDER ──────────────────────────────────
-- Searches Properties for the player's OriginSquare.
-- Returns nil cleanly if not found instead of erroring.
local function findBase(playerName)
    local props = workspace:FindFirstChild("Properties")
    if not props then return nil end
    for _, v in ipairs(props:GetDescendants()) do
        if v.Name == "Owner" and tostring(v.Value) == playerName then
            local sq = v.Parent and v.Parent:FindFirstChild("OriginSquare")
            if sq and sq:IsA("BasePart") then return sq end
        end
    end
    return nil
end

-- ── 2. TRUCK SCANNER ────────────────────────────────
-- Deduplicates results — a truck can only appear once even if it
-- has multiple "Owner" values (shouldn't happen, but belt+braces).
local function scanTrucks(ownerName)
    local seen   = {}
    local trucks = {}
    local pm = workspace:FindFirstChild("PlayerModels")
    if not pm then return trucks end
    for _, v in ipairs(pm:GetDescendants()) do
        if v.Name == "Owner" and tostring(v.Value) == ownerName then
            local m = v.Parent
            if m and m:IsA("Model") and m:FindFirstChild("DriveSeat") and not seen[m] then
                seen[m] = true
                table.insert(trucks, m)
            end
        end
    end
    return trucks
end

-- ── 3. JOINT MANAGEMENT ─────────────────────────────
-- Disables ALL physics joints that can stress under Anchored=true:
--   Motor6D, HingeConstraint, CylindricalConstraint,
--   PrismaticConstraint, RodConstraint, SpringConstraint,
--   TorsionSpringConstraint, UniversalConstraint, BallSocketConstraint
-- WeldConstraints are intentionally NOT disabled — they are rigid and
-- will move correctly with the anchor without stressing.
local JOINT_CLASSES = {
    "Motor6D", "HingeConstraint", "CylindricalConstraint",
    "PrismaticConstraint", "RodConstraint", "SpringConstraint",
    "TorsionSpringConstraint", "UniversalConstraint", "BallSocketConstraint",
}

local function disableJoints(truckModel)
    local disabled = {}
    for _, v in ipairs(truckModel:GetDescendants()) do
        for _, cls in ipairs(JOINT_CLASSES) do
            if v:IsA(cls) then
                local wasEnabled = pcall(function() return v.Enabled end) and v.Enabled
                if wasEnabled then
                    pcall(function() v.Enabled = false end)
                    table.insert(disabled, v)
                end
                break
            end
        end
    end
    return disabled
end

local function enableJoints(disabledList)
    for _, v in ipairs(disabledList) do
        if v and v.Parent then
            pcall(function() v.Enabled = true end)
        end
    end
end

-- ── 4. ANCHOR PART RESOLVER ──────────────────────────
-- Finds the best anchor BasePart on the truck.
-- Specifically avoids non-BasePart instances named "Main" (scripts, folders, etc).
local function getAnchorPart(truckModel)
    local main = truckModel:FindFirstChild("Main")
    if main and main:IsA("BasePart") then return main end
    if truckModel.PrimaryPart then return truckModel.PrimaryPart end
    -- Fall back: use the largest BasePart (most likely the chassis)
    local best, bestVol = nil, 0
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then
            local vol = p.Size.X * p.Size.Y * p.Size.Z
            if vol > bestVol then best = p; bestVol = vol end
        end
    end
    return best
end

-- ── 5. CARGO SCANNER ────────────────────────────────
-- Scans for cargo parts (Main / WoodSection BaseParts) inside the
-- truck bounding box. Handles WeldConstraint (Part0/Part1 either way),
-- legacy Weld, and Snap.
local function isInsideBox(point, boxCF, boxSz)
    local lp = boxCF:PointToObjectSpace(point)
    return math.abs(lp.X) <= boxSz.X * 0.5 + 0.5
       and math.abs(lp.Y) <= boxSz.Y * 0.5 + 1.5
       and math.abs(lp.Z) <= boxSz.Z * 0.5 + 0.5
end

-- Returns true if `part` is welded to something that lives outside its own model.
local function isCrossWelded(part)
    for _, v in ipairs(part:GetChildren()) do
        -- WeldConstraint: find the OTHER part
        if v:IsA("WeldConstraint") then
            local other = (v.Part0 == part) and v.Part1 or v.Part0
            if other and other.Parent and other.Parent ~= part.Parent then
                return true
            end
        -- Legacy Weld / Snap
        elseif v:IsA("Weld") or v:IsA("Snap") then
            if v.Part1 and v.Part1.Parent and v.Part1.Parent ~= part.Parent then
                return true
            end
        end
    end
    return false
end

local function scanCargo(truckModel)
    local cargo     = {}
    local seenCargo = {}

    -- Build a fast lookup of all truck parts
    local truckParts = {}
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then truckParts[p] = true end
    end

    local ok, boxCF, boxSz = pcall(function()
        return truckModel:GetBoundingBox()
    end)
    if not ok then return cargo end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if not obj:IsA("BasePart")      then continue end
        if truckParts[obj]              then continue end
        if seenCargo[obj]               then continue end
        if obj.Name ~= "Main" and obj.Name ~= "WoodSection" then continue end
        if isCrossWelded(obj)           then continue end
        if isInsideBox(obj.Position, boxCF, boxSz) then
            seenCargo[obj] = true
            table.insert(cargo, obj)
        end
    end
    return cargo
end

-- ── 6. SNAPSHOT ──────────────────────────────────────
-- Records every cargo part's CFrame relative to the truck's anchor part.
-- If anchor part is gone/nil we bail early rather than snapping everything
-- to world-origin (CFrame.new()).
local function snapshotCargo(truckModel, cargoList)
    local anchorPart = getAnchorPart(truckModel)
    if not anchorPart then
        return {}, nil   -- nil anchor signals caller to abort
    end
    local anchor = anchorPart.CFrame
    local snaps  = {}
    for _, part in ipairs(cargoList) do
        if part and part.Parent then
            local ok, rel = pcall(function()
                return anchor:ToObjectSpace(part.CFrame)
            end)
            if ok then snaps[part] = rel end
        end
    end
    return snaps, anchor
end

-- ── 7. WARP ──────────────────────────────────────────
-- Full sequence:
--   1. Capture relative CFrames of all truck parts (BEFORE anything changes)
--   2. Disable all physics joints
--   3. Freeze truck + cargo
--   4. Move truck → destCF
--   5. Move cargo → saved relative offsets from destCF
--   6. Thaw truck + cargo
--   7. Re-enable joints
-- Everything is pcall-wrapped so a destroyed part mid-warp is skipped,
-- not fatal.
local function warpTruck(truckModel, destCF, snapshots, savedAnchor)
    -- Guard: if the truck disappeared between scan and warp, bail cleanly
    if not (truckModel and truckModel.Parent) then return end
    if not savedAnchor then return end

    -- Step 1: Capture truck part relative CFrames NOW using the snapshot anchor.
    -- This must happen before anchoring so physics settling doesn't introduce drift.
    local relCFs = {}
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then
            local ok, rel = pcall(function()
                return savedAnchor:ToObjectSpace(p.CFrame)
            end)
            if ok then relCFs[p] = rel end
        end
    end

    if not next(relCFs) then return end   -- empty truck, nothing to do

    -- Step 2: Disable joints BEFORE anchoring to prevent destruction
    local joints = disableJoints(truckModel)

    -- Step 3: Freeze every truck part
    for p in pairs(relCFs) do freezePart(p) end

    -- Step 4: Freeze all cargo
    for part in pairs(snapshots) do freezePart(part) end

    -- Wait for Roblox physics to acknowledge the anchored state.
    -- 2 frames is enough on a healthy server; 3 frames is insurance.
    task.wait()
    task.wait()
    task.wait()

    -- Step 5: Teleport truck parts to destination
    for p, rel in pairs(relCFs) do
        setCFrame(p, destCF:ToWorldSpace(rel))
    end

    -- Step 6: Teleport cargo to their saved offsets from destCF
    for part, offset in pairs(snapshots) do
        setCFrame(part, destCF:ToWorldSpace(offset))
    end

    -- One more frame for positions to register before unanchoring
    task.wait()
    task.wait()

    -- Step 7: Unanchor truck FIRST (it's the reference), then cargo.
    -- This ensures if cargo physics wakes it can't collide with a
    -- truck part that hasn't moved yet.
    for p in pairs(relCFs) do thawPart(p) end
    for part in pairs(snapshots) do thawPart(part) end

    -- Step 8: Re-enable joints after everything is unanchored
    task.wait()
    enableJoints(joints)
end

-- ── 8. CONFIRM + CORRECT ─────────────────────────────
-- After warp settles, checks every cargo piece.
-- Any that drifted beyond tolerance get a precise anchored correction.
-- All corrections run CONCURRENTLY so this never blocks on lag.
-- onDone(corrections) fires only after ALL corrections are applied.
local CONFIRM_DIST = 3.0   -- studs — tighter tolerance

local function confirmCargo(snapshots, destCF, onDone)
    task.spawn(function()
        -- Give physics 4 frames to settle before measuring
        task.wait(); task.wait(); task.wait(); task.wait()
        task.wait(0.1)

        local corrections   = 0
        local corrTotal     = 0
        local corrDone      = 0

        -- First pass: collect all drifters
        local drifters = {}
        for part, offset in pairs(snapshots) do
            if part and part.Parent then
                local ok, expected = pcall(function()
                    return destCF:ToWorldSpace(offset)
                end)
                if ok and (part.Position - expected.Position).Magnitude > CONFIRM_DIST then
                    table.insert(drifters, { part = part, target = expected })
                    corrTotal += 1
                end
            end
        end

        if corrTotal == 0 then
            if onDone then onDone(0) end
            return
        end

        -- Second pass: correct all drifters concurrently
        local function onOneCorrectionDone()
            corrDone += 1
            if corrDone >= corrTotal then
                if onDone then onDone(corrTotal) end
            end
        end

        for _, d in ipairs(drifters) do
            corrections += 1
            task.spawn(function()
                if d.part and d.part.Parent then
                    freezePart(d.part)
                    task.wait(); task.wait()
                    setCFrame(d.part, d.target)
                    task.wait(); task.wait()
                    thawPart(d.part)
                end
                onOneCorrectionDone()
            end)
        end
    end)
end

-- ── 9. DESTINATION CFrame ────────────────────────────
-- Translates the truck anchor from giver coords to receiver coords.
-- Preserves the truck's rotation exactly — only the world position shifts.
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
    lbl.TextColor3 = Color3.fromRGB(120,120,150)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
end

local function uiSep()
    local s = Instance.new("Frame", page)
    s.Size = UDim2.new(1,-12,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,40,55)
    s.BorderSizePixel = 0
end

local function uiHint(text)
    local h = Instance.new("TextLabel", page)
    h.Size = UDim2.new(1,-12,0,28)
    h.BackgroundColor3 = Color3.fromRGB(16,16,22)
    h.BorderSizePixel = 0
    h.Font = Enum.Font.Gotham; h.TextSize = 11
    h.TextColor3 = Color3.fromRGB(100,100,130)
    h.TextWrapped = true
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Text = "  " .. text
    Instance.new("UICorner", h).CornerRadius = UDim.new(0,6)
    Instance.new("UIPadding", h).PaddingLeft = UDim.new(0,6)
    return h
end

-- uiBtn: returns the button AND a setRunning(bool) function that
-- dims + disables the button while an operation is in progress,
-- preventing double-clicks from starting two operations.
local function uiBtn(text, color, cb)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(1,-12,0,34)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local baseColor = color
    local hov = Color3.new(
        math.min(color.R+0.09,1), math.min(color.G+0.04,1), math.min(color.B+0.09,1))
    local running = false

    btn.MouseEnter:Connect(function()
        if not running then
            TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=hov}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if not running then
            TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=baseColor}):Play()
        end
    end)

    if cb then
        btn.MouseButton1Click:Connect(function()
            if not running then cb() end
        end)
    end

    local function setRunning(state)
        running = state
        local dim = Color3.new(
            math.max(baseColor.R*0.4,0), math.max(baseColor.G*0.4,0), math.max(baseColor.B*0.4,0))
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and dim or baseColor,
            TextTransparency = state and 0.5 or 0,
        }):Play()
    end

    return btn, setRunning
end

local function uiStatusCard(defaultText)
    local card = Instance.new("Frame", page)
    card.Size = UDim2.new(1,-12,0,40)
    card.BackgroundColor3 = Color3.fromRGB(20,16,28)
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
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12
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

-- uiProgressBar: the hide token pattern prevents a stale task.delay
-- from hiding a freshly-started bar. Each call to hide() gets a token;
-- when the delay fires it checks the token is still current before hiding.
local function uiProgressBar()
    local cont = Instance.new("Frame", page)
    cont.Size = UDim2.new(1,-12,0,44)
    cont.BackgroundColor3 = Color3.fromRGB(18,18,24)
    cont.BorderSizePixel = 0; cont.Visible = false
    Instance.new("UICorner", cont).CornerRadius = UDim.new(0,8)
    local topLbl = Instance.new("TextLabel", cont)
    topLbl.Size = UDim2.new(1,-12,0,16); topLbl.Position = UDim2.new(0,6,0,4)
    topLbl.BackgroundTransparency = 1
    topLbl.Font = Enum.Font.GothamSemibold; topLbl.TextSize = 11
    topLbl.TextColor3 = THEME_TEXT; topLbl.TextXAlignment = Enum.TextXAlignment.Left
    topLbl.Text = ""
    local track = Instance.new("Frame", cont)
    track.Size = UDim2.new(1,-12,0,12); track.Position = UDim2.new(0,6,0,26)
    track.BackgroundColor3 = Color3.fromRGB(28,28,38); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(90,160,255)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local hideToken = 0   -- incremented each time hide() is called

    local function setProgress(done, total, label, color)
        -- Cancel any pending hide by advancing the token
        hideToken += 1
        cont.BackgroundTransparency = 0
        fill.BackgroundTransparency = 0
        topLbl.TextTransparency = 0
        cont.Visible = true
        topLbl.Text = label or ("Warping... "..done.." / "..total)
        local pct = math.clamp(done / math.max(total,1), 0, 1)
        TweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Size = UDim2.new(pct,0,1,0),
            BackgroundColor3 = color or Color3.fromRGB(90,160,255),
        }):Play()
    end

    local function hide(delay)
        hideToken += 1
        local myToken = hideToken
        task.delay(delay or 2, function()
            if hideToken ~= myToken then return end   -- bar was reused, don't hide
            TweenService:Create(cont,  TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
            TweenService:Create(fill,  TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
            TweenService:Create(topLbl,TweenInfo.new(0.4), {TextTransparency=1}):Play()
            task.delay(0.45, function()
                if hideToken ~= myToken then return end
                cont.Visible = false
                cont.BackgroundTransparency = 0
                fill.BackgroundTransparency = 0
                fill.Size = UDim2.new(0,0,1,0)
                topLbl.TextTransparency = 0
            end)
        end)
    end

    local function reset()
        hideToken += 1
        cont.Visible = false
        fill.Size = UDim2.new(0,0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(90,160,255)
        topLbl.Text = ""
        cont.BackgroundTransparency = 0
        fill.BackgroundTransparency = 0
        topLbl.TextTransparency = 0
    end

    return cont, setProgress, hide, reset
end

-- Player dropdown — identical UX, but with a selectedUserId stored
-- alongside the name so callers can always get both.
local function uiPlayerDropdown(labelText)
    local HEADER_H = 40; local ITEM_H = 34; local MAX_SHOW = 5
    local selectedName = ""; local selectedUID = nil; local isOpen = false

    local outer = Instance.new("Frame", page)
    outer.Size = UDim2.new(1,-12,0,HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22,22,30)
    outer.BorderSizePixel = 0; outer.ClipsDescendants = true
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
    selLbl.TextColor3 = Color3.fromRGB(110,110,140)
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local arrow = Instance.new("TextLabel", selFrame)
    arrow.Size = UDim2.new(0,22,1,0); arrow.Position = UDim2.new(1,-24,0,0)
    arrow.BackgroundTransparency = 1; arrow.Text = "▾"
    arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 14
    arrow.TextColor3 = Color3.fromRGB(120,120,160)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

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
    listScroll.ScrollBarThickness = 3
    listScroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,130)
    listScroll.CanvasSize = UDim2.new(0,0,0,0); listScroll.ClipsDescendants = true
    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y+6)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop=UDim.new(0,4); listPad.PaddingBottom=UDim.new(0,4)
    listPad.PaddingLeft=UDim.new(0,6); listPad.PaddingRight=UDim.new(0,6)

    local function setSelected(name, userId)
        selectedName = name; selectedUID = userId
        selLbl.Text = name; selLbl.TextColor3 = THEME_TEXT
        arrow.TextColor3 = Color3.fromRGB(160,160,210)
        outerStroke.Color = Color3.fromRGB(90,90,160)
        if userId then
            task.spawn(function()
                pcall(function()
                    avatar.Image = Players:GetUserThumbnailAsync(
                        userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
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
            row.Size = UDim2.new(1,0,0,ITEM_H)
            row.BackgroundColor3 = Color3.fromRGB(30,30,45)
            row.BorderSizePixel = 0; row.Text = ""
            row.LayoutOrder = plr.UserId
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
            local rAv = Instance.new("ImageLabel", row)
            rAv.Size=UDim2.new(0,24,0,24); rAv.Position=UDim2.new(0,8,0.5,-12)
            rAv.BackgroundColor3=Color3.fromRGB(45,45,60); rAv.BorderSizePixel=0
            rAv.ScaleType=Enum.ScaleType.Crop
            Instance.new("UICorner",rAv).CornerRadius=UDim.new(1,0)
            local capturedPlr = plr
            task.spawn(function()
                pcall(function()
                    rAv.Image = Players:GetUserThumbnailAsync(
                        capturedPlr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
            end)
            local rLbl = Instance.new("TextLabel", row)
            rLbl.Size=UDim2.new(1,-44,1,0); rLbl.Position=UDim2.new(0,38,0,0)
            rLbl.BackgroundTransparency=1; rLbl.Text=plr.Name
            rLbl.Font=Enum.Font.GothamSemibold; rLbl.TextSize=13
            rLbl.TextColor3 = plr.Name==selectedName
                and Color3.fromRGB(200,200,255) or THEME_TEXT
            rLbl.TextXAlignment=Enum.TextXAlignment.Left
            row.MouseButton1Click:Connect(function()
                setSelected(plr.Name, plr.UserId); closeList()
            end)
            row.MouseEnter:Connect(function()
                TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(42,42,62)}):Play()
            end)
            row.MouseLeave:Connect(function()
                TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(30,30,45)}):Play()
            end)
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

    headerBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    headerBtn.MouseEnter:Connect(function()
        TweenService:Create(selFrame,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(38,38,55)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TweenService:Create(selFrame,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(30,30,42)}):Play()
    end)

    Players.PlayerAdded:Connect(function() if isOpen then buildList() end end)
    Players.PlayerRemoving:Connect(function(leaving)
        if leaving.Name == selectedName then
            selectedName=""; selectedUID=nil
            selLbl.Text="Select a player..."; selLbl.TextColor3=Color3.fromRGB(110,110,140)
            avatar.Image=""; arrow.TextColor3=Color3.fromRGB(120,120,160)
            outerStroke.Color=Color3.fromRGB(60,60,90)
        end
        if isOpen then buildList() end
    end)

    return outer, function() return selectedName end
end

-- ═══════════════════════════════════════════════════
-- ░░  SECTION 1: SINGLE TRUCK WARP  ░░
-- ═══════════════════════════════════════════════════

uiLabel("Single Truck Warp")
uiHint("Sit in your truck on Giver base, pick a Receiver, hit Warp.")

local _, getSingleReceiver = uiPlayerDropdown("Receiver")
local _, singleStatus = uiStatusCard("Sit in your truck, pick receiver, hit Warp.")
local _, singleProg, singleProgHide, singleProgReset = uiProgressBar()

local singleRunning = false
local _, singleBtnSetRunning = uiBtn("Warp My Truck + Load", Color3.fromRGB(40,80,120), function()
    if singleRunning then
        singleStatus("Already running!", true)
        return
    end

    local Char = player.Character
    if not Char then singleStatus("No character found!", false); return end
    local hum = Char:FindFirstChildOfClass("Humanoid")
    if not hum then singleStatus("No Humanoid found!", false); return end
    local seat = hum.SeatPart
    if not seat or seat.Name ~= "DriveSeat" then
        singleStatus("You must be seated in a truck's DriveSeat!", false); return end

    local receiverName = getSingleReceiver()
    if receiverName == "" then singleStatus("Pick a receiver first!", false); return end

    -- Snap references now — in case truck/model changes between click and task
    local truckModel = seat.Parent
    if not (truckModel and truckModel:IsA("Model")) then
        singleStatus("Couldn't find the truck model!", false); return end

    local giverOrigin    = findBase(player.Name)
    local receiverOrigin = findBase(receiverName)
    if not giverOrigin    then singleStatus("Can't find your base!", false);     return end
    if not receiverOrigin then singleStatus("Can't find receiver base!", false); return end

    singleRunning = true
    singleBtnSetRunning(true)
    singleProgReset()
    singleStatus("Scanning cargo...", true, Color3.fromRGB(140,210,255))

    task.spawn(function()
        -- Snapshot BEFORE ejecting player so the truck hasn't moved
        local cargo = scanCargo(truckModel)
        local snaps, anchor = snapshotCargo(truckModel, cargo)

        if not anchor then
            singleStatus("ERROR: Can't find truck anchor part!", false)
            singleRunning = false; singleBtnSetRunning(false); return
        end

        singleStatus("Ejecting player & warping "..#cargo.." cargo...", true, Color3.fromRGB(140,210,255))
        singleProg(0, 1, "Ejecting player...")

        -- Eject player from seat with a timeout
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        local ejectDeadline = tick() + 2.0
        while hum.SeatPart and tick() < ejectDeadline do
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            task.wait(0.08)
        end
        -- Extra wait so seat reference fully clears
        task.wait(0.1)

        -- Verify the truck model is still valid after ejection wait
        if not (truckModel and truckModel.Parent) then
            singleStatus("Truck disappeared during ejection!", false)
            singleRunning = false; singleBtnSetRunning(false); return
        end

        singleProg(0, 1, "Warping truck + cargo...")
        local destCF = computeDestCF(anchor, giverOrigin, receiverOrigin)
        warpTruck(truckModel, destCF, snaps, anchor)

        singleProg(1, 1, "Confirming cargo positions...", Color3.fromRGB(255,175,55))

        confirmCargo(snaps, destCF, function(corrections)
            local msg = corrections > 0
                and ("Done! ("..corrections.." piece(s) corrected)")
                or  "Done! All cargo landed clean."
            singleStatus(msg, false, Color3.fromRGB(90,220,110))
            singleProg(1, 1, msg, Color3.fromRGB(90,220,110))
            singleProgHide(2.5)
            singleRunning = false
            singleBtnSetRunning(false)
        end)

        -- Return player to giver base
        task.wait(0.1)
        pcall(function()
            local hrp = Char and Char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(giverOrigin.Position + Vector3.new(0, 6, 0))
            end
        end)
    end)
end)

-- ═══════════════════════════════════════════════════
-- ░░  SECTION 2: MULTI TRUCK WARP  ░░
-- ═══════════════════════════════════════════════════

uiSep(); uiLabel("Multi Truck Warp  (all trucks on base)")
uiHint("Scans all trucks on Giver base, warps them all + cargo to Receiver.")

local _, getMultiGiver    = uiPlayerDropdown("Giver")
local _, getMultiReceiver = uiPlayerDropdown("Receiver")

local scanResultCard = Instance.new("Frame", page)
scanResultCard.Size=UDim2.new(1,-12,0,34)
scanResultCard.BackgroundColor3=Color3.fromRGB(18,14,26)
scanResultCard.BorderSizePixel=0; scanResultCard.Visible=false
Instance.new("UICorner",scanResultCard).CornerRadius=UDim.new(0,8)
local scanResultLbl = Instance.new("TextLabel", scanResultCard)
scanResultLbl.Size=UDim2.new(1,-16,1,0); scanResultLbl.Position=UDim2.new(0,8,0,0)
scanResultLbl.BackgroundTransparency=1
scanResultLbl.Font=Enum.Font.GothamSemibold; scanResultLbl.TextSize=12
scanResultLbl.TextColor3=Color3.fromRGB(160,220,255)
scanResultLbl.TextXAlignment=Enum.TextXAlignment.Left
scanResultLbl.TextWrapped=true; scanResultLbl.Text=""

local _, multiStatus  = uiStatusCard("Pick Giver & Receiver, scan, then warp.")
local _, multiProg, multiProgHide, multiProgReset = uiProgressBar()

local scannedTrucks = {}
local multiRunning  = false
local multiAbort    = false

local _, scanBtnSetRunning = uiBtn("Scan Giver's Trucks", Color3.fromRGB(35,55,90), function()
    if multiRunning then multiStatus("Warp in progress!", true); return end
    local giverName = getMultiGiver()
    if giverName == "" then multiStatus("Pick a Giver first!", false); return end

    scannedTrucks = {}
    scanResultCard.Visible = false
    multiStatus("Scanning...", true, Color3.fromRGB(140,210,255))
    scanBtnSetRunning(true)

    task.spawn(function()
        local trucks = scanTrucks(giverName)
        if #trucks == 0 then
            multiStatus("No trucks found for "..giverName.."!", false)
            scanBtnSetRunning(false); return
        end

        local totalCargo = 0
        for _, tModel in ipairs(trucks) do
            -- Only include trucks that are still valid
            if tModel and tModel.Parent then
                local cargo = scanCargo(tModel)
                local snaps, anchor = snapshotCargo(tModel, cargo)
                if anchor then   -- skip trucks with no valid anchor part
                    table.insert(scannedTrucks, {
                        model  = tModel,
                        cargo  = cargo,
                        snaps  = snaps,
                        anchor = anchor,
                    })
                    totalCargo += #cargo
                end
            end
        end

        if #scannedTrucks == 0 then
            multiStatus("Found trucks but none had valid anchor parts!", false)
            scanBtnSetRunning(false); return
        end

        scanResultCard.Visible = true
        scanResultLbl.Text = #scannedTrucks.." truck(s) — "..totalCargo.." cargo piece(s). Ready."
        multiStatus(#scannedTrucks.." truck(s) scanned. Hit Warp All!", false, Color3.fromRGB(90,220,110))
        scanBtnSetRunning(false)
    end)
end)

local _, warpAllBtnSetRunning = uiBtn("Warp All Trucks + Loads", Color3.fromRGB(35,100,50), function()
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
    warpAllBtnSetRunning(true)
    multiStatus("Warping "..#scannedTrucks.." truck(s)...", true, Color3.fromRGB(140,210,255))

    task.spawn(function()
        local total = #scannedTrucks
        local done  = 0

        -- Thread-safe counter using a closure table
        local pendingConfirm = { value = 0 }
        local warpedCount    = 0

        -- onConfirmDone fires when EACH truck's cargo confirmation finishes.
        -- Only declares complete when ALL confirmations are done.
        local function onConfirmDone(_)
            pendingConfirm.value -= 1
            if pendingConfirm.value <= 0 and not multiAbort then
                multiRunning = false
                warpAllBtnSetRunning(false)
                multiStatus("All done! "..warpedCount.." truck(s) + cargo warped.", false, Color3.fromRGB(90,220,110))
                multiProg(total, total, "Complete!", Color3.fromRGB(90,220,110))
                multiProgHide(3)
                scannedTrucks = {}
                scanResultCard.Visible = false
            end
        end

        for i, entry in ipairs(scannedTrucks) do
            if multiAbort then break end

            local tModel  = entry.model
            local snaps   = entry.snaps
            local anchor  = entry.anchor

            -- Count this slot as needing a confirm before we attempt it,
            -- so the counter is correct even if we skip/continue
            pendingConfirm.value += 1

            if not (tModel and tModel.Parent) then
                -- Truck is gone — fire onConfirmDone immediately to drain counter
                done += 1
                multiProg(done, total, "Skipped (missing truck "..i..")")
                onConfirmDone(0)
                continue
            end

            local destCF = computeDestCF(anchor, giverOrigin, receiverOrigin)
            warpTruck(tModel, destCF, snaps, anchor)
            warpedCount += 1
            done += 1
            multiProg(done, total,
                "Warped "..done.." / "..total.." trucks",
                done == total and Color3.fromRGB(255,175,55) or Color3.fromRGB(90,160,255))

            confirmCargo(snaps, destCF, onConfirmDone)

            -- Stagger so WheelJoints from previous truck fully re-enable
            task.wait(0.15)
        end

        -- If we aborted partway through, handle cleanup
        if multiAbort then
            multiRunning = false
            warpAllBtnSetRunning(false)
            multiStatus("Stopped after "..done.." / "..total.." trucks.", false)
            multiProgHide(1)
        end
    end)
end)

uiBtn("Stop", Color3.fromRGB(100,40,20), function()
    multiAbort = true
    if multiRunning then
        multiRunning = false
        warpAllBtnSetRunning(false)
        multiStatus("Stopped.", false)
    end
end)

uiBtn("Re-Scan", BTN_COLOR, function()
    if multiRunning then return end
    scannedTrucks = {}
    scanResultCard.Visible = false
    multiProgReset()
    multiStatus("Cleared. Scan again when ready.", false)
end)

-- ═══════════════════════════════════════════════════
-- ░░  SECTION 3: CARGO ONLY WARP  ░░
-- ═══════════════════════════════════════════════════

uiSep(); uiLabel("Cargo Only Warp  (no truck movement)")
uiHint("Warps all wood/cargo on Giver base to Receiver — trucks stay put.")

local _, getCargoGiver    = uiPlayerDropdown("Giver")
local _, getCargoReceiver = uiPlayerDropdown("Receiver")

local cargoRunning = false
local cargoAbort   = false

local _, cargoStatus  = uiStatusCard("Pick Giver & Receiver, then warp cargo.")
local _, cargoProg, cargoProgHide, cargoProgReset = uiProgressBar()

local _, cargoBtnSetRunning = uiBtn("Warp All Cargo", Color3.fromRGB(60,40,100), function()
    if cargoRunning then cargoStatus("Already running!", true); return end

    local giverName    = getCargoGiver()
    local receiverName = getCargoReceiver()
    if giverName==""    then cargoStatus("Pick a Giver!",    false); return end
    if receiverName=="" then cargoStatus("Pick a Receiver!", false); return end

    local giverOrigin    = findBase(giverName)
    local receiverOrigin = findBase(receiverName)
    if not giverOrigin    then cargoStatus("Can't find Giver's base!",    false); return end
    if not receiverOrigin then cargoStatus("Can't find Receiver's base!", false); return end

    cargoRunning = true; cargoAbort = false
    cargoProgReset()
    cargoBtnSetRunning(true)
    cargoStatus("Scanning cargo on base...", true, Color3.fromRGB(140,210,255))

    task.spawn(function()
        local BASE_RADIUS = 80
        local cargo = {}

        for _, obj in ipairs(workspace:GetDescendants()) do
            if cargoAbort then break end
            if obj:IsA("BasePart")
                and (obj.Name == "Main" or obj.Name == "WoodSection")
                and not isCrossWelded(obj)
                and (obj.Position - giverOrigin.Position).Magnitude <= BASE_RADIUS then
                table.insert(cargo, obj)
            end
        end

        if #cargo == 0 then
            cargoStatus("No cargo found on "..giverName.."'s base.", false)
            cargoRunning = false; cargoBtnSetRunning(false); return
        end

        cargoStatus("Warping "..#cargo.." piece(s)...", true, Color3.fromRGB(140,210,255))

        local delta = receiverOrigin.Position - giverOrigin.Position
        local total = #cargo

        -- Use a mutex table for the counter so concurrent task.spawns
        -- can't race on a raw upvalue.
        local counter  = { done = 0 }
        local finished = false

        local function onPieceDone()
            counter.done += 1
            cargoProg(counter.done, total,
                "Warping cargo "..counter.done.." / "..total,
                counter.done >= total and Color3.fromRGB(90,220,110) or Color3.fromRGB(90,160,255))

            if counter.done >= total and not finished and not cargoAbort then
                finished = true
                cargoStatus("Done! "..total.." cargo piece(s) warped.", false, Color3.fromRGB(90,220,110))
                cargoProg(total, total, "Complete!", Color3.fromRGB(90,220,110))
                cargoProgHide(2.5)
                cargoRunning = false
                cargoBtnSetRunning(false)
            end
        end

        local BATCH = 8
        for i = 1, total, BATCH do
            if cargoAbort then
                -- Drain remaining counter slots so UI doesn't hang
                for j = i, total do
                    counter.done += 1
                end
                break
            end
            for j = i, math.min(i + BATCH - 1, total) do
                local part = cargo[j]
                task.spawn(function()
                    if part and part.Parent then
                        freezePart(part)
                        task.wait(); task.wait()
                        -- Apply delta preserving full CFrame (rotation + position)
                        setCFrame(part,
                            CFrame.new(part.CFrame.Position + delta) * part.CFrame.Rotation)
                        task.wait(); task.wait()
                        thawPart(part)
                    end
                    onPieceDone()
                end)
            end
            task.wait(0.05)
        end

        -- Safety timeout — if some tasks never fire onPieceDone (destroyed parts),
        -- we don't leave the UI permanently stuck.
        local deadline = tick() + 8
        while counter.done < total and tick() < deadline do
            task.wait(0.1)
        end

        if cargoAbort then
            cargoStatus("Stopped at "..counter.done.." / "..total..".", false)
            cargoRunning = false; cargoBtnSetRunning(false)
        elseif counter.done < total then
            -- Timed out but not aborted
            cargoStatus("Finished ("..counter.done.."/"..total.." — some parts may have been missing).", false,
                Color3.fromRGB(255,200,80))
            cargoRunning = false; cargoBtnSetRunning(false)
        end
    end)
end)

uiBtn("Stop", Color3.fromRGB(100,40,20), function()
    cargoAbort = true
    if cargoRunning then
        cargoRunning = false
        cargoBtnSetRunning(false)
        cargoStatus("Stopped.", false)
    end
end)

-- ═══════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    multiAbort   = true;  multiRunning   = false
    cargoAbort   = true;  cargoRunning   = false
    singleRunning = false
    scannedTrucks = {}
end)

print("[VanillaHub] Vanilla2_TruckDupe loaded — BULLETPROOF edition ready")
