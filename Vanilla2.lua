-- ════════════════════════════════════════════════════
-- VANILLA2 — World Tab
-- Imports shared state from Vanilla1 via _G.VH
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla2: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local Players          = _G.VH.Players
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages
local BTN_COLOR        = _G.VH.BTN_COLOR
local BTN_HOVER        = _G.VH.BTN_HOVER
local THEME_TEXT       = _G.VH.THEME_TEXT or Color3.fromRGB(230, 206, 226)

-- ════════════════════════════════════════════════════
-- WORLD TAB
-- ════════════════════════════════════════════════════
local worldPage = pages["WorldTab"]

local function createWSectionLabel(text)
    local lbl = Instance.new("TextLabel", worldPage)
    lbl.Size = UDim2.new(1,-12,0,22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(120,120,150); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    local pad = Instance.new("UIPadding", lbl); pad.PaddingLeft = UDim.new(0, 4)
end

local function createWSep()
    local sep = Instance.new("Frame", worldPage)
    sep.Size = UDim2.new(1,-12,0,1); sep.BackgroundColor3 = Color3.fromRGB(40,40,55); sep.BorderSizePixel = 0
end

local function createWorldToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", worldPage)
    frame.Size = UDim2.new(1,-12,0,32); frame.BackgroundColor3 = Color3.fromRGB(24,24,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0,34,0,18); tb.Position = UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3 = defaultState and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text = ""; Instance.new("UICorner", tb).CornerRadius = UDim.new(1,0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0,14,0,14)
    circle.Position = UDim2.new(0, defaultState and 18 or 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)
    local toggled = defaultState
    if callback then callback(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and Color3.fromRGB(60,180,60) or BTN_COLOR
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 18 or 2, 0.5, -7)
        }):Play()
        if callback then callback(toggled) end
    end)
    return frame
end

local worldClockConn = nil
local alwaysDayActive = false
local alwaysNightActive = false
local walkOnWaterConn = nil
local walkOnWaterParts = {}

table.insert(cleanupTasks, function()
    if worldClockConn then worldClockConn:Disconnect(); worldClockConn = nil end
    if walkOnWaterConn then walkOnWaterConn:Disconnect(); walkOnWaterConn = nil end
    for _, p in ipairs(walkOnWaterParts) do
        if p and p.Parent then p:Destroy() end
    end
    walkOnWaterParts = {}
    alwaysDayActive = false
    alwaysNightActive = false
end)

createWSectionLabel("Environment")

createWorldToggle("Always Day", true, function(v)
    alwaysDayActive = v
    if worldClockConn then worldClockConn:Disconnect(); worldClockConn = nil end
    if v then
        alwaysNightActive = false
        local Lighting = game:GetService("Lighting")
        Lighting.ClockTime = 14
        worldClockConn = game:GetService("RunService").Heartbeat:Connect(function()
            Lighting.ClockTime = 14
        end)
    end
end)

createWorldToggle("Always Night", false, function(v)
    alwaysNightActive = v
    if worldClockConn then worldClockConn:Disconnect(); worldClockConn = nil end
    if v then
        alwaysDayActive = false
        local Lighting = game:GetService("Lighting")
        Lighting.ClockTime = 0
        worldClockConn = game:GetService("RunService").Heartbeat:Connect(function()
            Lighting.ClockTime = 0
        end)
    end
end)

local _origFogEnd   = game:GetService("Lighting").FogEnd
local _origFogStart = game:GetService("Lighting").FogStart
createWorldToggle("Remove Fog", false, function(v)
    local Lighting = game:GetService("Lighting")
    if v then
        Lighting.FogEnd   = 1e9
        Lighting.FogStart = 1e9
    else
        Lighting.FogEnd   = _origFogEnd
        Lighting.FogStart = _origFogStart
    end
end)

createWorldToggle("Shadows", true, function(v)
    game:GetService("Lighting").GlobalShadows = v
end)

createWSep()
createWSectionLabel("Water")

createWorldToggle("Walk On Water", false, function(v)
    if walkOnWaterConn then walkOnWaterConn:Disconnect(); walkOnWaterConn = nil end
    for _, p in ipairs(walkOnWaterParts) do
        if p and p.Parent then p:Destroy() end
    end
    walkOnWaterParts = {}
    if v then
        local function makeSolid(part)
            if part:IsA("Part") and part.Name == "Water" then
                local clone = Instance.new("Part")
                clone.Size = part.Size; clone.CFrame = part.CFrame
                clone.Anchored = true; clone.CanCollide = true
                clone.Transparency = 1; clone.Name = "WalkWaterPlane"
                clone.Parent = game:GetService("Workspace")
                table.insert(walkOnWaterParts, clone)
            end
        end
        for _, p in ipairs(game:GetService("Workspace"):GetDescendants()) do makeSolid(p) end
        walkOnWaterConn = game:GetService("Workspace").DescendantAdded:Connect(makeSolid)
    end
end)

createWorldToggle("Remove Water", false, function(v)
    if _G.VH and _G.VH.setRemovedWater then _G.VH.setRemovedWater(v) end
    for _, p in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if p:IsA("Part") and p.Name == "Water" then
            p.Transparency = v and 1 or 0.5
            p.CanCollide   = false
        end
    end
end)

-- ════════════════════════════════════════════════════
-- BUTTER LEAK — DupeBase
-- ════════════════════════════════════════════════════

function DupeBase()
    local RS          = game:GetService("ReplicatedStorage")
    local LP          = Players.LocalPlayer
    local Character   = LP.Character or LP.CharacterAdded:Wait()
    local Humanoid    = Character:WaitForChild("Humanoid")

    local GiveBase, ReceiverBase
    local GiveBaseOrigin, ReceiverBaseOrigin
    local teleportedParts = {}
    local retryTeleport   = {}
    local ignoredParts    = {}

    local function isPointInside(point, boxCFrame, boxSize)
        local r = boxCFrame:PointToObjectSpace(point)
        return math.abs(r.X) <= boxSize.X / 2
            and math.abs(r.Y) <= (boxSize.Y / 2 + 2)
            and math.abs(r.Z) <= boxSize.Z / 2
    end

    -- Locate giver and receiver bases
    for _, v in pairs(workspace.Properties:GetDescendants()) do
        if v.Name == "Owner" then
            local val = tostring(v.Value)
            if val == getgenv().GiverPlayer    then GiveBase = v;     GiveBaseOrigin     = v.Parent:FindFirstChild("OriginSquare") end
            if val == getgenv().ReceiverPlayer then ReceiverBase = v; ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
        end
    end

    -- ── Structures ──────────────────────────────────
    if getgenv().Structures then
        pcall(function()
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == getgenv().GiverPlayer then
                    if v.Parent:FindFirstChild("Type") and tostring(v.Parent.Type.Value) == "Structure" then
                        if v.Parent:FindFirstChildOfClass("Part") or v.Parent:FindFirstChildOfClass("WedgePart") then
                            local PartCFrame = (v.Parent:FindFirstChild("MainCFrame") and v.Parent.MainCFrame.Value)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local DumbassArg = v.Parent:FindFirstChild("BlueprintWoodClass") and v.Parent.BlueprintWoodClass.Value or nil
                            local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                            repeat wait()
                                pcall(function()
                                    RS.PlaceStructure.ClientPlacedStructure:FireServer(
                                        v.Parent:FindFirstChild("ItemName").Value, Offset, LP, DumbassArg, v.Parent, true)
                                end)
                            until not v.Parent
                            print("Sent Structure")
                        end
                    end
                end
            end
        end)
    end

    -- ── Furniture ───────────────────────────────────
    if getgenv().Furniture then
        pcall(function()
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == getgenv().GiverPlayer then
                    if v.Parent:FindFirstChild("Type") and tostring(v.Parent.Type.Value) == "Furniture" then
                        if v.Parent:FindFirstChildOfClass("Part") then
                            local PartCFrame = (v.Parent:FindFirstChild("MainCFrame") and v.Parent.MainCFrame.Value)
                                or (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                                or v.Parent:FindFirstChildOfClass("Part").CFrame
                            local DumbassArg = v.Parent:FindFirstChild("BlueprintWoodClass") and v.Parent.BlueprintWoodClass.Value or nil
                            local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                            repeat wait()
                                pcall(function()
                                    RS.PlaceStructure.ClientPlacedStructure:FireServer(
                                        v.Parent:FindFirstChild("ItemName").Value, Offset, LP, DumbassArg, v.Parent, true)
                                end)
                            until not v.Parent
                            print("Sent Furniture")
                        end
                    end
                end
            end
        end)
    end

    -- ── Truck Load ──────────────────────────────────
    getgenv().DidTruckTeleport = false

    local function TeleportTruck()
        if getgenv().DidTruckTeleport then return end
        if not Character.Humanoid.SeatPart then return end
        local TruckCFrame = Character.Humanoid.SeatPart.Parent:FindFirstChild("Main").CFrame
        local newPos = TruckCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
        local Offset = CFrame.new(newPos) * TruckCFrame.Rotation
        Character.Humanoid.SeatPart.Parent:SetPrimaryPartCFrame(Offset)
        getgenv().DidTruckTeleport = true
    end

    if getgenv().TeleportTrucks then
        for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
            if v.Name == "Owner" and tostring(v.Value) == getgenv().GiverPlayer then
                if v.Parent:FindFirstChild("DriveSeat") then
                    v.Parent.DriveSeat:Sit(Character.Humanoid)
                    repeat wait() v.Parent.DriveSeat:Sit(Character.Humanoid) until Character.Humanoid.SeatPart

                    local targetModel = Character.Humanoid.SeatPart.Parent
                    local modelCFrame, modelSize = targetModel:GetBoundingBox()

                    for _, p in ipairs(targetModel:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end
                    for _, p in ipairs(Character:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end

                    for _, part in ipairs(workspace:GetDescendants()) do
                        if part:IsA("BasePart") and not ignoredParts[part] then
                            if part.Name == "Main" or part.Name == "WoodSection" then
                                if part:FindFirstChild("Weld") and part.Weld.Part1.Parent ~= part.Parent then continue end
                                task.spawn(function()
                                    if isPointInside(part.Position, modelCFrame, modelSize) then
                                        TeleportTruck()
                                        local oldPos      = part.Position
                                        local PartCFrame  = part.CFrame
                                        local nPos        = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                        local targetOffset = CFrame.new(nPos) * PartCFrame.Rotation
                                        part.CFrame = targetOffset
                                        table.insert(teleportedParts, { Instance = part, OldPos = oldPos, TargetCFrame = targetOffset })
                                    end
                                end)
                            end
                        end
                    end

                    local SitPart   = Character.Humanoid.SeatPart
                    local DoorHinge = SitPart.Parent:FindFirstChild("PaintParts").DoorLeft:FindFirstChild("ButtonRemote_Hinge")
                    wait()
                    Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.1)
                    SitPart:Destroy()
                    TeleportTruck()
                    getgenv().DidTruckTeleport = false
                    task.wait(0.1)
                    for i = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end
                end
            end
        end
    end

    -- ── Retry loop (cargo that didn't move) ─────────
    task.wait(5)
    for _, data in ipairs(teleportedParts) do
        if (data.Instance.Position - data.OldPos).Magnitude < 5 then
            ignoredParts[data.Instance] = nil
            table.insert(retryTeleport, data)
        end
    end

    repeat
        task.wait(5)
        retryTeleport = {}
        for _, data in ipairs(teleportedParts) do
            if (data.Instance.Position - data.OldPos).Magnitude < 25 then
                table.insert(retryTeleport, data)
            end
        end
        if #retryTeleport > 0 then
            print("Misses detected: " .. #retryTeleport .. ". Retrying...")
            for _, data in ipairs(retryTeleport) do
                local item = data.Instance
                print("RETRYING: " .. item:GetFullName())
                while not isNetworkOwner2(item.Parent) do
                    if (LP.Character.HumanoidRootPart.Position - item.Position).Magnitude > 25 then
                        LP.Character.HumanoidRootPart.CFrame = item.CFrame
                        task.wait(0.1)
                    end
                    RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                    task.wait(0.1)
                end
                item.CFrame = data.TargetCFrame
                task.wait(0.1)
            end
        end
    until #retryTeleport == 0
    print("All items successfully moved to their targets!")

    -- ── Purchased Items ─────────────────────────────
    if getgenv().TeleportItems then
        for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
            if v.Name == "Owner" and tostring(v.Value) == getgenv().GiverPlayer then
                if v.Parent:FindFirstChild("PurchasedBoxItemName") then
                    local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                    if part and teleportedParts and table.find(teleportedParts, part) then continue end
                    local PartCFrame = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                        or v.Parent:FindFirstChildOfClass("Part").CFrame
                    local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                    local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                    if (Character.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                        Character.HumanoidRootPart.CFrame = part.CFrame
                        task.wait(0.1)
                    end
                    isitemownersecondary(part)
                    for i = 1, 200 do part.CFrame = Offset end
                    wait(GetPing())
                    print("Sent Item")
                end
            end
        end
    end

    -- ── Gift Items ───────────────────────────────────
    if getgenv().TeleportGifs then
        for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
            if v.Name == "Owner" and tostring(v.Value) == getgenv().GiverPlayer then
                if v.Parent:FindFirstChildOfClass("Script") and v.Parent:FindFirstChild("DraggableItem") then
                    local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                    if part and teleportedParts and table.find(teleportedParts, part) then continue end
                    local PartCFrame = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                        or v.Parent:FindFirstChildOfClass("Part").CFrame
                    local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                    local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                    if (Character.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                        Character.HumanoidRootPart.CFrame = part.CFrame
                        task.wait(0.1)
                    end
                    isitemownersecondary(part)
                    for i = 1, 200 do part.CFrame = Offset end
                    wait(GetPing())
                    print("Sent Item")
                end
            end
        end
    end

    -- ── Wood ────────────────────────────────────────
    if getgenv().TeleportWood then
        for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
            if v.Name == "Owner" and tostring(v.Value) == getgenv().GiverPlayer then
                if v.Parent:FindFirstChild("TreeClass") then
                    local part = v.Parent:FindFirstChild("Main") or v.Parent:FindFirstChildOfClass("Part")
                    if part and teleportedParts and table.find(teleportedParts, part) then continue end
                    local PartCFrame = (v.Parent:FindFirstChild("Main") and v.Parent.Main.CFrame)
                        or v.Parent:FindFirstChildOfClass("Part").CFrame
                    local newPos = PartCFrame.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                    local Offset = CFrame.new(newPos) * PartCFrame.Rotation
                    if (Character.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                        Character.HumanoidRootPart.CFrame = part.CFrame
                        task.wait(0.1)
                    end
                    for i = 1, 50 do
                        task.wait(0.05)
                        RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                    end
                    isitemownersecondary(part)
                    for i = 1, 200 do part.CFrame = Offset end
                    wait(GetPing())
                    print("Sent Item")
                end
            end
        end
    end
end

print("[VanillaHub] Vanilla2 loaded")
