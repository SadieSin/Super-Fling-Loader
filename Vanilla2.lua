-- ═══════════════════════════════════════════════════════════════
-- VANILLA2 — TRUCK LOAD DUPE  (BULLETPROOF — INTEGRATED)
-- Slots into the existing DupeTab page that Vanilla2 already owns.
-- Shares _G.VH.butter, _G.VH.player, _G.VH.pages, and all
-- RemoteProxy / ClientIsDragging remotes exactly as the rest of
-- Vanilla2 uses them.  Execute AFTER the main Vanilla2 script.
-- ═══════════════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] TruckDupe: _G.VH not found. Run Vanilla1 + Vanilla2 first.")
    return
end

-- ── Pull everything from the shared hub ─────────────────────────
local TweenService = _G.VH.TweenService
local Players      = _G.VH.Players
local player       = _G.VH.player          -- LocalPlayer
local cleanupTasks = _G.VH.cleanupTasks
local pages        = _G.VH.pages
local BTN_COLOR    = _G.VH.BTN_COLOR
local BTN_HOVER    = _G.VH.BTN_HOVER
local THEME_TEXT   = _G.VH.THEME_TEXT or Color3.fromRGB(230, 206, 226)

-- Reuse the same RemoteProxy + ClientIsDragging that Vanilla2 uses
-- so we don't create redundant remote references.
local RS           = game:GetService("ReplicatedStorage")
local Interaction  = RS:FindFirstChild("Interaction")
local RemoteProxy  = Interaction and Interaction:FindFirstChild("RemoteProxy")
local ClientIsDragging = Interaction and Interaction:FindFirstChild("ClientIsDragging")

-- ── Slot into the DupeTab — same page Vanilla2 already built ────
local page = pages["DupeTab"]
if not page then
    -- Fallback: try any page with "dupe" or "truck" in the key
    for k, v in pairs(pages) do
        if string.lower(k):find("dupe") or string.lower(k):find("truck") then
            page = v; break
        end
    end
end
if not page then
    warn("[VanillaHub] TruckDupe: cannot find DupeTab page in _G.VH.pages")
    return
end

-- ═══════════════════════════════════════════════════
-- ░░  SHARED SAFE PRIMITIVES  ░░
-- ═══════════════════════════════════════════════════

local function safeSet(part, cf)
    if not (part and part.Parent) then return false end
    return pcall(function() part.CFrame = cf end)
end

local function freeze(part)
    if not (part and part.Parent) then return end
    pcall(function()
        part.Anchored = true
        part.AssemblyLinearVelocity  = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function thaw(part)
    if not (part and part.Parent) then return end
    pcall(function() part.Anchored = false end)
end

-- ═══════════════════════════════════════════════════
-- ░░  BASE FINDER  ░░
-- Matches Vanilla2's own workspace.Properties scan exactly,
-- but validates OriginSquare is a BasePart before returning.
-- ═══════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════
-- ░░  TRUCK SCANNER  ░░
-- Matches Vanilla2's truck-finding logic (Owner child, DriveSeat).
-- Deduplicates so multi-Owner trucks only appear once.
-- ═══════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════
-- ░░  JOINT MANAGER  ░░
-- Disables every physics joint type that stresses under Anchored=true.
-- WeldConstraints are deliberately left enabled — they're rigid and move
-- correctly with the assembly; disabling them breaks the truck structure.
-- ═══════════════════════════════════════════════════
local JOINT_CLASSES = {
    "Motor6D", "HingeConstraint", "CylindricalConstraint",
    "PrismaticConstraint", "RodConstraint", "SpringConstraint",
    "TorsionSpringConstraint", "UniversalConstraint", "BallSocketConstraint",
}

local function disableJoints(model)
    local disabled = {}
    for _, v in ipairs(model:GetDescendants()) do
        for _, cls in ipairs(JOINT_CLASSES) do
            if v:IsA(cls) then
                local ok, enabled = pcall(function() return v.Enabled end)
                if ok and enabled then
                    pcall(function() v.Enabled = false end)
                    table.insert(disabled, v)
                end
                break
            end
        end
    end
    return disabled
end

local function enableJoints(list)
    for _, v in ipairs(list) do
        if v and v.Parent then pcall(function() v.Enabled = true end) end
    end
end

-- ═══════════════════════════════════════════════════
-- ░░  ANCHOR PART RESOLVER  ░░
-- Exactly matches Vanilla2's own tModel:FindFirstChild("Main") /
-- GetPrimaryPartCFrame() fallback chain, but adds BasePart validation
-- so a Script named "Main" can never become the anchor.
-- ═══════════════════════════════════════════════════
local function getAnchorPart(model)
    local main = model:FindFirstChild("Main")
    if main and main:IsA("BasePart") then return main end
    if model.PrimaryPart then return model.PrimaryPart end
    -- Final fallback: largest BasePart by volume (most likely the chassis)
    local best, bestVol = nil, 0
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local vol = p.Size.X * p.Size.Y * p.Size.Z
            if vol > bestVol then best = p; bestVol = vol end
        end
    end
    return best   -- may be nil if model is empty
end

-- ═══════════════════════════════════════════════════
-- ░░  CARGO CROSS-WELD CHECK  ░░
-- Checks BOTH sides of WeldConstraint (Part0 or Part1 may reference
-- this part) plus legacy Weld/Snap.  A part is "cross-welded" if it
-- is rigidly joined to something outside its own Model.
-- ═══════════════════════════════════════════════════
local function isCrossWelded(part)
    -- Check welds living on this part
    for _, v in ipairs(part:GetChildren()) do
        if v:IsA("WeldConstraint") then
            local other = (v.Part0 == part) and v.Part1 or v.Part0
            if other and other.Parent and other.Parent ~= part.Parent then
                return true
            end
        elseif v:IsA("Weld") or v:IsA("Snap") then
            if v.Part1 and v.Part1.Parent and v.Part1.Parent ~= part.Parent then
                return true
            end
        end
    end
    -- Also check welds living on OTHER parts that reference this one
    -- (handles the case where the weld lives on the truck, not the cargo)
    local parent = part.Parent
    if parent then
        for _, v in ipairs(parent:GetDescendants()) do
            if v:IsA("WeldConstraint") then
                if (v.Part0 == part or v.Part1 == part) then
                    local other = (v.Part0 == part) and v.Part1 or v.Part0
                    if other and other.Parent ~= part.Parent then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════
-- ░░  CARGO SCANNER  ░░
-- Matches Vanilla2's own cargo sweep (Main / WoodSection in bounding box)
-- but adds BasePart type check, deduplication, and pcall around
-- GetBoundingBox so a bad model never throws.
-- ═══════════════════════════════════════════════════
local function isInsideBox(point, boxCF, boxSz)
    local lp = boxCF:PointToObjectSpace(point)
    return math.abs(lp.X) <= boxSz.X * 0.5 + 0.5
       and math.abs(lp.Y) <= boxSz.Y * 0.5 + 1.5
       and math.abs(lp.Z) <= boxSz.Z * 0.5 + 0.5
end

local function scanCargo(truckModel)
    local cargo     = {}
    local seen      = {}
    local truckParts = {}
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then truckParts[p] = true end
    end
    local ok, boxCF, boxSz = pcall(function() return truckModel:GetBoundingBox() end)
    if not ok then return cargo end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not truckParts[obj] and not seen[obj]
            and (obj.Name == "Main" or obj.Name == "WoodSection")
            and not isCrossWelded(obj)
            and isInsideBox(obj.Position, boxCF, boxSz) then
            seen[obj] = true
            table.insert(cargo, obj)
        end
    end
    return cargo
end

-- ═══════════════════════════════════════════════════
-- ░░  SNAPSHOT  ░░
-- Records every cargo part's CFrame relative to the anchor part.
-- Returns (snapsTable, anchorCFrame) — anchorCFrame is nil on failure
-- so callers can abort rather than silently misplace everything.
-- ═══════════════════════════════════════════════════
local function snapshotCargo(truckModel, cargoList)
    local anchorPart = getAnchorPart(truckModel)
    if not anchorPart then return {}, nil end
    local anchor = anchorPart.CFrame
    local snaps  = {}
    for _, part in ipairs(cargoList) do
        if part and part.Parent then
            local ok, rel = pcall(function() return anchor:ToObjectSpace(part.CFrame) end)
            if ok then snaps[part] = rel end
        end
    end
    return snaps, anchor
end

-- ═══════════════════════════════════════════════════
-- ░░  DESTINATION CFrame  ░░
-- Same formula Vanilla2 uses: srcPos - giverOrigin + receiverOrigin,
-- preserving rotation exactly.
-- ═══════════════════════════════════════════════════
local function computeDestCF(sourceCF, giverOrigin, receiverOrigin)
    local delta = receiverOrigin.Position - giverOrigin.Position
    return CFrame.new(sourceCF.Position + delta) * sourceCF.Rotation
end

-- ═══════════════════════════════════════════════════
-- ░░  WARP ENGINE  ░░
-- Physics-safe teleport sequence:
--   1. Capture relative CFrames before anything changes
--   2. Disable all physics joints
--   3. Freeze truck + cargo
--   4. Move truck to destination
--   5. Move cargo to saved offsets from destination
--   6. Unfreeze truck then cargo
--   7. Re-enable joints
-- Everything pcall-wrapped — a destroyed part mid-warp is skipped.
-- ═══════════════════════════════════════════════════
local function warpTruck(truckModel, destCF, snapshots, savedAnchor)
    if not (truckModel and truckModel.Parent) then return end
    if not savedAnchor then return end

    -- Step 1: capture relative CFrames NOW before any physics changes
    local relCFs = {}
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then
            local ok, rel = pcall(function() return savedAnchor:ToObjectSpace(p.CFrame) end)
            if ok then relCFs[p] = rel end
        end
    end
    if not next(relCFs) then return end

    -- Step 2: disable joints before anchoring to prevent destruction
    local joints = disableJoints(truckModel)

    -- Step 3: freeze truck + cargo
    for p in pairs(relCFs) do freeze(p) end
    for part in pairs(snapshots) do freeze(part) end

    -- 3 frames for physics server to acknowledge anchored state
    task.wait(); task.wait(); task.wait()

    -- Step 4: move truck
    for p, rel in pairs(relCFs) do
        safeSet(p, destCF:ToWorldSpace(rel))
    end

    -- Step 5: move cargo to saved offsets
    for part, offset in pairs(snapshots) do
        safeSet(part, destCF:ToWorldSpace(offset))
    end

    -- 2 frames for positions to register
    task.wait(); task.wait()

    -- Step 6: unanchor truck first (it's the reference), then cargo
    for p in pairs(relCFs) do thaw(p) end
    for part in pairs(snapshots) do thaw(part) end

    -- Step 7: re-enable joints after parts are unanchored
    task.wait()
    enableJoints(joints)
end

-- ═══════════════════════════════════════════════════
-- ░░  CONFIRM + CORRECT  ░░
-- Checks each cargo piece 4+ frames after warp.
-- Drifted pieces get an anchored correction using the same
-- ClientIsDragging remote that Vanilla2 uses for its own retry loop,
-- but only if the remote is available — falls back to direct setCFrame.
-- onDone(count) fires only after ALL corrections complete.
-- ═══════════════════════════════════════════════════
local CONFIRM_DIST = 3.0

local function confirmCargo(snapshots, destCF, giverOrigin, onDone)
    task.spawn(function()
        -- Wait for physics to settle
        task.wait(); task.wait(); task.wait(); task.wait()
        task.wait(0.1)

        -- Collect drifters
        local drifters = {}
        for part, offset in pairs(snapshots) do
            if part and part.Parent then
                local ok, expected = pcall(function() return destCF:ToWorldSpace(offset) end)
                if ok and (part.Position - expected.Position).Magnitude > CONFIRM_DIST then
                    table.insert(drifters, { part = part, target = expected })
                end
            end
        end

        if #drifters == 0 then
            if onDone then onDone(0) end
            return
        end

        -- Correct all drifters concurrently
        local corrTotal = #drifters
        local corrDone  = { n = 0 }   -- table so concurrent spawns share state

        local function onOneDone()
            corrDone.n += 1
            if corrDone.n >= corrTotal and onDone then
                onDone(corrTotal)
            end
        end

        local Char = player.Character

        for _, d in ipairs(drifters) do
            task.spawn(function()
                if d.part and d.part.Parent then
                    -- Use ClientIsDragging to claim network ownership
                    -- (mirrors Vanilla2's own cargo retry logic)
                    if ClientIsDragging and Char and Char:FindFirstChild("HumanoidRootPart") then
                        local hrp = Char.HumanoidRootPart
                        if (hrp.Position - d.part.Position).Magnitude > 25 then
                            pcall(function() hrp.CFrame = d.part.CFrame end)
                            task.wait(0.08)
                        end
                        pcall(function() ClientIsDragging:FireServer(d.part.Parent) end)
                        task.wait(0.1)
                    end
                    freeze(d.part)
                    task.wait(); task.wait()
                    safeSet(d.part, d.target)
                    task.wait(); task.wait()
                    thaw(d.part)
                end
                onOneDone()
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════
-- ░░  PLAYER EJECTION  ░░
-- Uses the same Jumping → GettingUp state-change approach as Vanilla2's
-- truck teleport section.  Optionally tries the DoorHinge remote too,
-- exactly as Vanilla2 does.
-- ═══════════════════════════════════════════════════
local function ejectFromSeat(hum, seatPart, timeout)
    timeout = timeout or 2.0
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local deadline = tick() + timeout
    while hum.SeatPart and tick() < deadline do
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        task.wait(0.08)
    end
    -- Try the door hinge remote if available (matches Vanilla2)
    if RemoteProxy and seatPart and seatPart.Parent then
        local doorHinge = seatPart.Parent:FindFirstChild("PaintParts")
            and seatPart.Parent.PaintParts:FindFirstChild("DoorLeft")
            and seatPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")
        if doorHinge then
            for _ = 1, 10 do
                pcall(function() RemoteProxy:FireServer(doorHinge) end)
            end
        end
    end
    task.wait(0.1)
end

-- ═══════════════════════════════════════════════════
-- ░░  UI HELPERS  ░░
-- Identical visual style to Vanilla2's createDSection / createDSep /
-- createDBtn so the injected section looks native.
-- ═══════════════════════════════════════════════════

local function mkSep()
    local s = Instance.new("Frame", page)
    s.Size = UDim2.new(1,-12,0,1)
    s.BackgroundColor3 = Color3.fromRGB(40,40,55)
    s.BorderSizePixel  = 0
end

local function mkLabel(text)
    local lbl = Instance.new("TextLabel", page)
    lbl.Size  = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font  = Enum.Font.GothamBold;  lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function mkHint(text)
    local h = Instance.new("TextLabel", page)
    h.Size  = UDim2.new(1,-12,0,28)
    h.BackgroundColor3 = Color3.fromRGB(16,16,22)
    h.BorderSizePixel  = 0
    h.Font  = Enum.Font.Gotham; h.TextSize = 11
    h.TextColor3 = Color3.fromRGB(100,100,130)
    h.TextWrapped = true
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Text = "  " .. text
    Instance.new("UICorner", h).CornerRadius = UDim.new(0,6)
    Instance.new("UIPadding", h).PaddingLeft = UDim.new(0,6)
end

-- mkBtn returns (button, setRunning) — setRunning(true/false) dims the
-- button and blocks clicks while an operation is active.
local function mkBtn(text, color, cb)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", page)
    btn.Size  = UDim2.new(1,-12,0,34)
    btn.BackgroundColor3 = color
    btn.Text  = text
    btn.Font  = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local base = color
    local hov  = Color3.fromRGB(
        math.min(color.R*255+20, 255)/255,
        math.min(color.G*255+8,  255)/255,
        math.min(color.B*255+20, 255)/255)
    local locked = false

    btn.MouseEnter:Connect(function()
        if not locked then
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=hov}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if not locked then
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=base}):Play()
        end
    end)
    if cb then
        btn.MouseButton1Click:Connect(function()
            if not locked then cb() end
        end)
    end

    local function setRunning(state)
        locked = state
        local dim = Color3.fromRGB(
            math.max(base.R*255*0.35, 0)/255,
            math.max(base.G*255*0.35, 0)/255,
            math.max(base.B*255*0.35, 0)/255)
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and dim or base,
            TextTransparency = state and 0.5 or 0,
        }):Play()
    end
    return btn, setRunning
end

local function mkStatus(default)
    local card = Instance.new("Frame", page)
    card.Size = UDim2.new(1,-12,0,32)
    card.BackgroundColor3 = Color3.fromRGB(14,14,18)
    card.BorderSizePixel  = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,6)
    local dot = Instance.new("Frame", card)
    dot.Size = UDim2.new(0,7,0,7); dot.Position = UDim2.new(0,10,0.5,-3)
    dot.BackgroundColor3 = Color3.fromRGB(80,80,100); dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(1,-28,1,0); lbl.Position = UDim2.new(0,24,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
    lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.Text = default or "Ready"
    local function set(msg, active, col)
        lbl.Text  = msg
        lbl.TextColor3 = col or THEME_TEXT
        dot.BackgroundColor3 = active
            and Color3.fromRGB(80,200,120) or Color3.fromRGB(80,80,100)
    end
    return card, set
end

-- Progress bar with token-based stale-hide protection
local function mkProg()
    local cont = Instance.new("Frame", page)
    cont.Size = UDim2.new(1,-12,0,44)
    cont.BackgroundColor3 = Color3.fromRGB(18,18,24)
    cont.BorderSizePixel  = 0; cont.Visible = false
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
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local token = 0

    local function set(done, total, label, col)
        token += 1
        cont.BackgroundTransparency = 0
        fill.BackgroundTransparency = 0
        topLbl.TextTransparency     = 0
        cont.Visible = true
        topLbl.Text  = label or (done.." / "..total)
        local pct = math.clamp(done / math.max(total,1), 0, 1)
        TweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Size = UDim2.new(pct,0,1,0),
            BackgroundColor3 = col or Color3.fromRGB(90,160,255),
        }):Play()
    end

    local function hide(delay)
        token += 1
        local t = token
        task.delay(delay or 2, function()
            if token ~= t then return end
            TweenService:Create(cont,   TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
            TweenService:Create(fill,   TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
            TweenService:Create(topLbl, TweenInfo.new(0.4), {TextTransparency=1}):Play()
            task.delay(0.45, function()
                if token ~= t then return end
                cont.Visible = false
                cont.BackgroundTransparency = 0
                fill.BackgroundTransparency = 0
                fill.Size = UDim2.new(0,0,1,0)
                topLbl.TextTransparency = 0
            end)
        end)
    end

    local function reset()
        token += 1
        cont.Visible = false
        fill.Size = UDim2.new(0,0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(90,160,255)
        topLbl.Text = ""
        cont.BackgroundTransparency = 0
        fill.BackgroundTransparency = 0
        topLbl.TextTransparency = 0
    end

    return cont, set, hide, reset
end

-- Player dropdown — uses the same visual style as makeDupeDropdown
-- in Vanilla2 so both sections look identical.
local function mkDropdown(labelText)
    local HEADER_H = 40; local ITEM_H = 34; local MAX_SHOW = 5
    local selName = ""; local isOpen = false

    local outer = Instance.new("Frame", page)
    outer.Size = UDim2.new(1,-12,0,HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22,22,30)
    outer.BorderSizePixel  = 0; outer.ClipsDescendants = true
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
    Instance.new("UIStroke", selFrame).Color = Color3.fromRGB(70,70,110)

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

    local function setSel(name, userId)
        selName = name; selLbl.Text = name; selLbl.TextColor3 = THEME_TEXT
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
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        local playerList = Players:GetPlayers()
        table.sort(playerList, function(a,b) return a.Name < b.Name end)
        for _, plr in ipairs(playerList) do
            local row = Instance.new("TextButton", listScroll)
            row.Size = UDim2.new(1,0,0,ITEM_H)
            row.BackgroundColor3 = plr.Name==selName and Color3.fromRGB(45,45,75) or Color3.fromRGB(28,28,40)
            row.BorderSizePixel  = 0; row.Text = ""; row.LayoutOrder = plr.UserId
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
            local rAv = Instance.new("ImageLabel", row)
            rAv.Size=UDim2.new(0,22,0,22); rAv.Position=UDim2.new(0,8,0.5,-11)
            rAv.BackgroundColor3=Color3.fromRGB(45,45,60); rAv.BorderSizePixel=0; rAv.ScaleType=Enum.ScaleType.Crop
            Instance.new("UICorner",rAv).CornerRadius=UDim.new(1,0)
            local cap = plr
            task.spawn(function()
                pcall(function()
                    rAv.Image = Players:GetUserThumbnailAsync(
                        cap.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
            end)
            local rLbl = Instance.new("TextLabel", row)
            rLbl.Size=UDim2.new(1,-44,1,0); rLbl.Position=UDim2.new(0,36,0,0)
            rLbl.BackgroundTransparency=1; rLbl.Text=plr.Name
            rLbl.Font=Enum.Font.GothamSemibold; rLbl.TextSize=13
            rLbl.TextColor3 = plr.Name==selName and THEME_TEXT or Color3.fromRGB(200,200,215)
            rLbl.TextXAlignment=Enum.TextXAlignment.Left
            row.MouseButton1Click:Connect(function() setSel(plr.Name, plr.UserId); closeList() end)
            row.MouseEnter:Connect(function()
                if plr.Name~=selName then
                    TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(38,38,58)}):Play()
                end
            end)
            row.MouseLeave:Connect(function()
                if plr.Name~=selName then
                    TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(28,28,40)}):Play()
                end
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

    headerBtn.MouseButton1Click:Connect(function() if isOpen then closeList() else openList() end end)
    headerBtn.MouseEnter:Connect(function()
        TweenService:Create(selFrame,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(38,38,55)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TweenService:Create(selFrame,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(30,30,42)}):Play()
    end)

    Players.PlayerAdded:Connect(function() if isOpen then buildList() end end)
    Players.PlayerRemoving:Connect(function(leaving)
        if leaving.Name == selName then
            selName=""; selLbl.Text="Select a player..."
            selLbl.TextColor3=Color3.fromRGB(110,110,140)
            avatar.Image=""; arrow.TextColor3=Color3.fromRGB(120,120,160)
            outerStroke.Color=Color3.fromRGB(60,60,90)
        end
        if isOpen then buildList() end
    end)

    return outer, function() return selName end
end

-- ═══════════════════════════════════════════════════
-- ░░  SECTION A: SINGLE TRUCK WARP  ░░
-- Integrates with _G.VH.butter so it can't run while the main
-- dupe is running, and vice versa.
-- ═══════════════════════════════════════════════════
mkSep()
mkLabel("Single Truck Warp  (physics-safe)")
mkHint("Sit in your truck on Giver base → pick Receiver → Warp.")

local _, getSingleReceiver = mkDropdown("Receiver")
local _, singleStat        = mkStatus("Sit in truck, pick Receiver, hit Warp.")
local _, sProg, sProgHide, sProgReset = mkProg()

local singleRunning = false
local _, sBtnLock = mkBtn("Warp My Truck + Load", Color3.fromRGB(40,80,120), function()
    -- Block if main dupe or another warp is running
    if singleRunning then singleStat("Already running!", true); return end
    if _G.VH.butter and _G.VH.butter.running then
        singleStat("Wait for main dupe to finish first!", false); return
    end

    local Char = player.Character
    if not Char then singleStat("No character!", false); return end
    local hum = Char:FindFirstChildOfClass("Humanoid")
    if not hum then singleStat("No Humanoid!", false); return end
    local seat = hum.SeatPart
    if not seat or seat.Name ~= "DriveSeat" then
        singleStat("Sit in a truck's DriveSeat first!", false); return
    end

    local receiverName = getSingleReceiver()
    if receiverName == "" then singleStat("Pick a Receiver first!", false); return end

    local truckModel = seat.Parent
    if not (truckModel and truckModel:IsA("Model")) then
        singleStat("Can't find truck model!", false); return
    end

    local giverOrigin    = findBase(player.Name)
    local receiverOrigin = findBase(receiverName)
    if not giverOrigin    then singleStat("Can't find your base!", false); return end
    if not receiverOrigin then singleStat("Can't find receiver base!", false); return end

    singleRunning = true; sBtnLock(true); sProgReset()
    singleStat("Scanning cargo...", true, Color3.fromRGB(140,210,255))

    task.spawn(function()
        -- Snapshot BEFORE ejection so truck hasn't moved
        local cargo = scanCargo(truckModel)
        local snaps, anchor = snapshotCargo(truckModel, cargo)
        if not anchor then
            singleStat("ERROR: truck has no valid anchor part!", false)
            singleRunning=false; sBtnLock(false); return
        end

        singleStat("Ejecting & warping "..#cargo.." cargo...", true, Color3.fromRGB(140,210,255))
        sProg(0, 1, "Ejecting player...")

        -- Eject using same method as Vanilla2 (state change + DoorHinge)
        ejectFromSeat(hum, seat, 2.0)

        -- Verify truck still exists after ejection wait
        if not (truckModel and truckModel.Parent) then
            singleStat("Truck disappeared during ejection!", false)
            singleRunning=false; sBtnLock(false); return
        end

        sProg(0, 1, "Warping truck + cargo...")
        local destCF = computeDestCF(anchor, giverOrigin, receiverOrigin)
        warpTruck(truckModel, destCF, snaps, anchor)

        sProg(1, 1, "Confirming cargo...", Color3.fromRGB(255,175,55))

        confirmCargo(snaps, destCF, giverOrigin, function(corrections)
            local msg = corrections > 0
                and ("Done! ("..corrections.." corrected)")
                or  "Done! All cargo landed clean."
            singleStat(msg, false, Color3.fromRGB(90,220,110))
            sProg(1, 1, msg, Color3.fromRGB(90,220,110))
            sProgHide(2.5)
            singleRunning=false; sBtnLock(false)
        end)

        -- Return player to giver base
        task.wait(0.15)
        pcall(function()
            local hrp = Char and Char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(giverOrigin.Position + Vector3.new(0, 6, 0))
            end
        end)
    end)
end)

-- ═══════════════════════════════════════════════════
-- ░░  SECTION B: MULTI TRUCK WARP  ░░
-- ═══════════════════════════════════════════════════
mkSep()
mkLabel("Multi Truck Warp  (all trucks on base)")
mkHint("Scan → Warp All. Sends every truck + cargo in one burst.")

local _, getMultiGiver    = mkDropdown("Giver")
local _, getMultiReceiver = mkDropdown("Receiver")

local scanCard = Instance.new("Frame", page)
scanCard.Size = UDim2.new(1,-12,0,32)
scanCard.BackgroundColor3 = Color3.fromRGB(18,14,26)
scanCard.BorderSizePixel  = 0; scanCard.Visible = false
Instance.new("UICorner", scanCard).CornerRadius = UDim.new(0,8)
local scanCardLbl = Instance.new("TextLabel", scanCard)
scanCardLbl.Size=UDim2.new(1,-16,1,0); scanCardLbl.Position=UDim2.new(0,8,0,0)
scanCardLbl.BackgroundTransparency=1; scanCardLbl.Font=Enum.Font.GothamSemibold; scanCardLbl.TextSize=12
scanCardLbl.TextColor3=Color3.fromRGB(160,220,255); scanCardLbl.TextXAlignment=Enum.TextXAlignment.Left
scanCardLbl.TextWrapped=true; scanCardLbl.Text=""

local _, multiStat = mkStatus("Pick Giver & Receiver, scan, then warp.")
local _, mProg, mProgHide, mProgReset = mkProg()

local scannedTrucks = {}
local multiRunning  = false
local multiAbort    = false

local _, scanBtnLock = mkBtn("Scan Giver's Trucks", Color3.fromRGB(35,55,90), function()
    if multiRunning then multiStat("Warp in progress!", true); return end
    if _G.VH.butter and _G.VH.butter.running then
        multiStat("Wait for main dupe first!", false); return
    end
    local giverName = getMultiGiver()
    if giverName=="" then multiStat("Pick a Giver first!", false); return end

    scannedTrucks = {}; scanCard.Visible = false
    multiStat("Scanning...", true, Color3.fromRGB(140,210,255))
    scanBtnLock(true)

    task.spawn(function()
        local trucks = scanTrucks(giverName)
        if #trucks == 0 then
            multiStat("No trucks found for "..giverName.."!", false)
            scanBtnLock(false); return
        end
        local totalCargo = 0
        for _, tModel in ipairs(trucks) do
            if tModel and tModel.Parent then
                local cargo = scanCargo(tModel)
                local snaps, anchor = snapshotCargo(tModel, cargo)
                if anchor then
                    table.insert(scannedTrucks, {model=tModel, snaps=snaps, anchor=anchor})
                    totalCargo += #cargo
                end
            end
        end
        if #scannedTrucks == 0 then
            multiStat("Trucks found but none had valid anchors!", false)
            scanBtnLock(false); return
        end
        scanCard.Visible = true
        scanCardLbl.Text = #scannedTrucks.." truck(s) — "..totalCargo.." cargo piece(s). Ready."
        multiStat(#scannedTrucks.." truck(s) scanned. Hit Warp All!", false, Color3.fromRGB(90,220,110))
        scanBtnLock(false)
    end)
end)

local _, warpAllLock = mkBtn("Warp All Trucks + Loads", Color3.fromRGB(35,100,50), function()
    if multiRunning then multiStat("Already running!", true); return end
    if #scannedTrucks == 0 then multiStat("Scan first!", false); return end
    if _G.VH.butter and _G.VH.butter.running then
        multiStat("Wait for main dupe first!", false); return
    end

    local giverName    = getMultiGiver()
    local receiverName = getMultiReceiver()
    if giverName==""    then multiStat("Pick a Giver!",    false); return end
    if receiverName=="" then multiStat("Pick a Receiver!", false); return end

    local giverOrigin    = findBase(giverName)
    local receiverOrigin = findBase(receiverName)
    if not giverOrigin    then multiStat("Can't find Giver's base!",    false); return end
    if not receiverOrigin then multiStat("Can't find Receiver's base!", false); return end

    multiRunning=true; multiAbort=false; mProgReset(); warpAllLock(true)
    multiStat("Warping "..#scannedTrucks.." truck(s)...", true, Color3.fromRGB(140,210,255))

    task.spawn(function()
        local total       = #scannedTrucks
        local done        = 0
        local warpedCount = 0
        -- Use a table counter so concurrent confirmCargo closures share state
        local pending     = { n = 0 }

        local function onConfirmDone(_)
            pending.n -= 1
            if pending.n <= 0 and not multiAbort then
                multiRunning=false; warpAllLock(false)
                multiStat("Done! "..warpedCount.." truck(s) warped.", false, Color3.fromRGB(90,220,110))
                mProg(total, total, "Complete!", Color3.fromRGB(90,220,110))
                mProgHide(3)
                scannedTrucks={}; scanCard.Visible=false
            end
        end

        for i, entry in ipairs(scannedTrucks) do
            if multiAbort then
                -- Drain remaining slots so pending.n reaches 0 and UI unlocks
                for j = i, total do pending.n -= 1 end
                break
            end

            pending.n += 1   -- must increment BEFORE the warp attempt

            local tModel = entry.model
            local snaps  = entry.snaps
            local anchor = entry.anchor

            if not (tModel and tModel.Parent) then
                done += 1
                mProg(done, total, "Skipping missing truck "..i)
                onConfirmDone(0); continue
            end

            local destCF = computeDestCF(anchor, giverOrigin, receiverOrigin)
            warpTruck(tModel, destCF, snaps, anchor)
            warpedCount += 1; done += 1
            mProg(done, total,
                "Warped "..done.." / "..total.." trucks",
                done==total and Color3.fromRGB(255,175,55) or Color3.fromRGB(90,160,255))

            confirmCargo(snaps, destCF, giverOrigin, onConfirmDone)
            task.wait(0.15)   -- stagger so previous truck's joints re-enable
        end

        if multiAbort then
            multiRunning=false; warpAllLock(false)
            multiStat("Stopped after "..done.." / "..total..".", false)
            mProgHide(1)
        end
    end)
end)

mkBtn("Stop", Color3.fromRGB(100,40,20), function()
    multiAbort=true
    if multiRunning then
        multiRunning=false; warpAllLock(false)
        multiStat("Stopping...", false)
    end
end)

mkBtn("Re-Scan", BTN_COLOR, function()
    if multiRunning then return end
    scannedTrucks={}; scanCard.Visible=false; mProgReset()
    multiStat("Cleared. Scan again when ready.", false)
end)

-- ═══════════════════════════════════════════════════
-- ░░  SECTION C: CARGO ONLY WARP  ░░
-- ═══════════════════════════════════════════════════
mkSep()
mkLabel("Cargo Only Warp  (no truck movement)")
mkHint("Warps all wood/cargo on Giver base → Receiver. Trucks stay put.")

local _, getCargoGiver    = mkDropdown("Giver")
local _, getCargoReceiver = mkDropdown("Receiver")

local cargoRunning = false
local cargoAbort   = false

local _, cargoStat = mkStatus("Pick Giver & Receiver, then warp cargo.")
local _, cProg, cProgHide, cProgReset = mkProg()

local _, cargoBtnLock = mkBtn("Warp All Cargo", Color3.fromRGB(60,40,100), function()
    if cargoRunning then cargoStat("Already running!", true); return end
    if _G.VH.butter and _G.VH.butter.running then
        cargoStat("Wait for main dupe first!", false); return
    end

    local giverName    = getCargoGiver()
    local receiverName = getCargoReceiver()
    if giverName==""    then cargoStat("Pick a Giver!",    false); return end
    if receiverName=="" then cargoStat("Pick a Receiver!", false); return end

    local giverOrigin    = findBase(giverName)
    local receiverOrigin = findBase(receiverName)
    if not giverOrigin    then cargoStat("Can't find Giver's base!",    false); return end
    if not receiverOrigin then cargoStat("Can't find Receiver's base!", false); return end

    cargoRunning=true; cargoAbort=false; cProgReset(); cargoBtnLock(true)
    cargoStat("Scanning cargo...", true, Color3.fromRGB(140,210,255))

    task.spawn(function()
        local BASE_RADIUS = 80
        local cargo = {}

        for _, obj in ipairs(workspace:GetDescendants()) do
            if cargoAbort then break end
            if obj:IsA("BasePart")
                and (obj.Name=="Main" or obj.Name=="WoodSection")
                and not isCrossWelded(obj)
                and (obj.Position - giverOrigin.Position).Magnitude <= BASE_RADIUS then
                table.insert(cargo, obj)
            end
        end

        if #cargo == 0 then
            cargoStat("No cargo found on "..giverName.."'s base.", false)
            cargoRunning=false; cargoBtnLock(false); return
        end

        cargoStat("Warping "..#cargo.." piece(s)...", true, Color3.fromRGB(140,210,255))
        local delta = receiverOrigin.Position - giverOrigin.Position
        local total = #cargo
        local counter  = { done = 0 }
        local finished = false

        local function onPieceDone()
            counter.done += 1
            cProg(counter.done, total,
                counter.done.." / "..total,
                counter.done>=total and Color3.fromRGB(90,220,110) or Color3.fromRGB(90,160,255))
            if counter.done >= total and not finished and not cargoAbort then
                finished = true
                cargoStat("Done! "..total.." piece(s) warped.", false, Color3.fromRGB(90,220,110))
                cProg(total, total, "Complete!", Color3.fromRGB(90,220,110))
                cProgHide(2.5)
                cargoRunning=false; cargoBtnLock(false)
            end
        end

        local BATCH = 8
        for i = 1, total, BATCH do
            if cargoAbort then
                -- Drain remaining slots so the wait-loop exits
                counter.done = total; break
            end
            for j = i, math.min(i+BATCH-1, total) do
                local part = cargo[j]
                task.spawn(function()
                    if part and part.Parent then
                        freeze(part)
                        task.wait(); task.wait()
                        safeSet(part, CFrame.new(part.CFrame.Position + delta) * part.CFrame.Rotation)
                        task.wait(); task.wait()
                        thaw(part)
                    end
                    onPieceDone()
                end)
            end
            task.wait(0.05)
        end

        -- Safety timeout: if any spawned task silently fails, unlock UI
        local deadline = tick() + 8
        while counter.done < total and tick() < deadline do task.wait(0.1) end

        if cargoAbort then
            cargoStat("Stopped.", false)
            cargoRunning=false; cargoBtnLock(false)
        elseif counter.done < total then
            cargoStat("Finished (some parts may have been destroyed).", false,
                Color3.fromRGB(255,200,80))
            cargoRunning=false; cargoBtnLock(false)
        end
    end)
end)

mkBtn("Stop", Color3.fromRGB(100,40,20), function()
    cargoAbort=true
    if cargoRunning then
        cargoRunning=false; cargoBtnLock(false)
        cargoStat("Stopped.", false)
    end
end)

-- ═══════════════════════════════════════════════════
-- CLEANUP — hooks into the same cleanupTasks table that
-- Vanilla1/2 use, so all three sections reset when the
-- hub is cleaned up.
-- ═══════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    multiAbort  = true; multiRunning  = false
    cargoAbort  = true; cargoRunning  = false
    singleRunning = false
    scannedTrucks = {}
    -- Reset button states
    pcall(function() sBtnLock(false) end)
    pcall(function() warpAllLock(false) end)
    pcall(function() scanBtnLock(false) end)
    pcall(function() cargoBtnLock(false) end)
end)

print("[VanillaHub] TruckDupe (integrated bulletproof) loaded — appended to DupeTab")
