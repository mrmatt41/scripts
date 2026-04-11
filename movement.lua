-- ═══════════════════════════════════════════════════════════════════
--  movement.lua  —  Menu V1  |  Движение
-- ═══════════════════════════════════════════════════════════════════

speedEnabled = false
speedValue   = 28
BASE_SPEED   = 16

flyEnabled         = false
flySpeed           = 60
flyBodyVelocity    = nil
flyBodyGyro        = nil
flyConnection      = nil
flyCanCollideParts = {}

flyInertia      = true
flyInertiaDecay = 0.90

noClipEnabled    = false
noClipParts      = {}
noClipConnection = nil

spinEnabled        = false
spinSpeedDegPerSec = 600
spinAxis           = "Y"

infiniteJumpEnabled = false
ijConn              = nil

jumpBoostEnabled = false
jumpBoostForce   = 60

local function getFlyDir()
    local camCF   = camera.CFrame
    local forward = camCF.LookVector
    local right   = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
    if right.Magnitude > 0.001 then right = right.Unit end
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right   end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right   end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        dir = dir + Vector3.new(0,1,0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        dir = dir - Vector3.new(0,1,0)
    end
    local speedMult = 1
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then speedMult = 0.30 end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)     then speedMult = 2.0  end
    return dir, speedMult
end

function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro     then flyBodyGyro:Destroy()     end
    if flyConnection   then flyConnection:Disconnect() end
    hum.AutoRotate = false
    flyCanCollideParts = {}
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            flyCanCollideParts[#flyCanCollideParts+1] = { part=p, orig=p.CanCollide }
            pcall(function() p.CanCollide = false end)
        end
    end
    flyBodyVelocity          = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBodyVelocity.P        = 1250
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent   = hrp
    flyBodyGyro           = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(4e5,4e5,4e5)
    flyBodyGyro.P         = 5000
    flyBodyGyro.D         = 200
    flyBodyGyro.CFrame    = hrp.CFrame
    flyBodyGyro.Parent    = hrp
    local currentVel = Vector3.zero
    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not flyEnabled then return end
        if not hrp or not hrp.Parent then flyEnabled = false return end
        local dir, mult = getFlyDir()
        local targetVel
        if dir.Magnitude > 0.001 then
            targetVel = dir.Unit * flySpeed * mult
        else
            if flyInertia then
                targetVel = currentVel * flyInertiaDecay
                if targetVel.Magnitude < 0.3 then targetVel = Vector3.zero end
            else
                targetVel = Vector3.zero
            end
        end
        currentVel               = targetVel
        flyBodyVelocity.Velocity = targetVel
        flyBodyGyro.CFrame       = CFrame.new(hrp.Position, hrp.Position + camera.CFrame.LookVector)
        for _, entry in ipairs(flyCanCollideParts) do
            if entry.part and entry.part.Parent and entry.part.CanCollide then
                pcall(function() entry.part.CanCollide = false end)
            end
        end
    end)
end

function stopFly()
    if flyConnection   then flyConnection:Disconnect();  flyConnection   = nil end
    if flyBodyVelocity then flyBodyVelocity:Destroy();   flyBodyVelocity = nil end
    if flyBodyGyro     then flyBodyGyro:Destroy();       flyBodyGyro     = nil end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = true end
    for _, entry in ipairs(flyCanCollideParts) do
        if entry.part and entry.part.Parent then
            pcall(function() entry.part.CanCollide = entry.orig end)
        end
    end
    flyCanCollideParts = {}
end

function updateNoClipCache()
    noClipParts = {}
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then noClipParts[#noClipParts+1] = p end
    end
end

function startNoClip()
    if noClipConnection then noClipConnection:Disconnect() end
    noClipConnection = RunService.Stepped:Connect(function()
        if not noClipEnabled then return end
        for _, part in ipairs(noClipParts) do
            if part and part.Parent then part.CanCollide = false end
        end
    end)
end

function stopNoClip()
    noClipEnabled = false
    for _, part in ipairs(noClipParts) do
        if part and part.Parent then pcall(function() part.CanCollide = true end) end
    end
end

local SPIN_AXIS_MAP = {
    X = function(dt) return CFrame.Angles(math.rad(spinSpeedDegPerSec*dt), 0, 0) end,
    Y = function(dt) return CFrame.Angles(0, math.rad(spinSpeedDegPerSec*dt), 0) end,
    Z = function(dt) return CFrame.Angles(0, 0, math.rad(spinSpeedDegPerSec*dt)) end,
}

function getSpinDelta(dt)
    local fn = SPIN_AXIS_MAP[spinAxis] or SPIN_AXIS_MAP["Y"]
    return fn(dt)
end

local function attachInfJump(char)
    if ijConn then ijConn:Disconnect(); ijConn = nil end
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    ijConn = UserInputService.JumpRequest:Connect(function()
        if not infiniteJumpEnabled then return end
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        if jumpBoostEnabled then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.new(
                        hrp.AssemblyLinearVelocity.X,
                        jumpBoostForce,
                        hrp.AssemblyLinearVelocity.Z)
                end)
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    flyBodyVelocity    = nil
    flyBodyGyro        = nil
    flyCanCollideParts = {}
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    attachInfJump(char)
    task.wait(0.4)
    if flyEnabled then startFly() end
    updateNoClipCache()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if speedEnabled and hum then hum.WalkSpeed = speedValue end
end)

if LocalPlayer.Character then
    attachInfJump(LocalPlayer.Character)
    task.defer(updateNoClipCache)
end

startNoClip()
