-- ═══════════════════════════════════════════════════════════════════
--  aim.lua  —  Menu V1  |  Aim Assist / Silent Aim / Trigger Bot
-- ═══════════════════════════════════════════════════════════════════

isAimAssistEnabled  = false
isSilentAimEnabled  = false
isTriggerBotEnabled = false
allowWallbang       = false

aimKey              = Enum.UserInputType.MouseButton2
aimPartName         = "Head"
aimSmoothness       = 0.15
fovHalfSize         = 120
fovVisible          = false

aimPrediction       = false
aimPredictMult      = 0.07

triggerCooldownSec  = 0.10
lastTriggerFireAt   = 0
lastTargetScanAt    = 0

currentTool     = nil
aimLockedTarget = nil

_tbTog    = nil
_tbAccent = nil
_tbRow    = nil
_tbState  = false

function simulateLMB()
    if mouse1click then
        pcall(mouse1click)
    elseif mouse1press and mouse1release then
        pcall(mouse1press)
        task.delay(0.05, function() pcall(mouse1release) end)
    else
        local tool = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
    end
end

function hasDirectLoS(origin, dest, targetChar)
    local dir = dest - origin
    if dir.Magnitude < 0.001 then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { LocalPlayer.Character, targetChar }
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, dir, params)
    if not result then return true end
    return result.Instance and result.Instance:IsDescendantOf(targetChar)
end

function losOrPenetrate(origin, dest, targetChar)
    local dir = dest - origin
    if dir.Magnitude < 0.001 then return false end
    local dirU    = dir.Unit
    local params  = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { LocalPlayer.Character, targetChar }
    params.IgnoreWater = true
    local remaining = dir.Magnitude
    local cur       = origin
    local hits      = 0
    local MAX_HITS  = 1
    while remaining > 0.01 do
        local result = workspace:Raycast(cur, dirU * remaining, params)
        if not result then return true end
        if result.Instance and result.Instance:IsDescendantOf(targetChar) then return true end
        hits += 1
        if hits > MAX_HITS then return false end
        cur       = result.Position + dirU * 0.2
        remaining = (dest - cur).Magnitude
    end
    return false
end

function isPointInFOV(sp2d)
    local m  = UserInputService:GetMouseLocation()
    local dx = math.abs(sp2d.X - m.X)
    local dy = math.abs(sp2d.Y - m.Y)
    return (dx <= fovHalfSize and dy <= fovHalfSize), math.max(dx, dy)
end

function getBestTarget(includeOccluded)
    local closest, bestMetric = nil, math.huge
    local origin = camera.CFrame.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if not isEnemy(p) or not p.Character then continue end
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end
        local aimPart = p.Character:FindFirstChild(aimPartName)
                     or p.Character:FindFirstChild("HumanoidRootPart")
        if not aimPart then
            for _, d in ipairs(p.Character:GetChildren()) do
                if d:IsA("BasePart") then aimPart = d break end
            end
        end
        if not aimPart then continue end
        local v2, onScreen = camera:WorldToViewportPoint(aimPart.Position)
        if not onScreen then continue end
        local inside, metric = isPointInFOV(Vector2.new(v2.X, v2.Y))
        if not inside then continue end
        if includeOccluded or losOrPenetrate(origin, aimPart.Position, p.Character) then
            if metric < bestMetric then closest, bestMetric = p, metric end
        end
    end
    return closest
end

function getAimPos(p)
    if not (p and p.Character) then return nil end
    local h = p.Character:FindFirstChild(aimPartName)
           or p.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local pos = h.Position
    if aimPrediction then
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel   = hrp.AssemblyLinearVelocity
            local dist  = (camera.CFrame.Position - pos).Magnitude
            local tFlight = dist * 0.0028
            pos = pos + vel * (aimPredictMult + tFlight)
        end
    end
    return pos
end

getHeadPos = getAimPos

function aimCameraAt(worldPt)
    if not worldPt then return end
    local camCF   = camera.CFrame
    local desired = (worldPt - camCF.Position).Unit
    local t       = 1 - math.clamp(aimSmoothness, 0, 0.999)
    local smoothed = camCF.LookVector:Lerp(desired, t)
    camera.CFrame  = CFrame.new(camCF.Position, camCF.Position + smoothed)
end

function forceDisableTriggerBot(reason)
    isTriggerBotEnabled = false
    _tbState            = false
    if _tbTog then
        _tbTog.Text             = "OFF"
        _tbTog.BackgroundColor3 = C.togOff
        _tbTog.TextColor3       = C.textDim
    end
    if _tbAccent then _tbAccent.BackgroundColor3 = C.accentDim end
    if reason then addLog("BOT ▸ ❌ авто-выкл: " .. reason) end
end

function bindTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    currentTool = tool
    tool.AncestryChanged:Connect(function(_, parent)
        if not parent and currentTool == tool then currentTool = nil end
    end)
    tool.Activated:Connect(function()
        if not isSilentAimEnabled then return end
        local tgt = getBestTarget(allowWallbang)
        if not tgt then return end
        local aimPos = getAimPos(tgt)
        if not aimPos then return end
        local orig = camera.CFrame
        camera.CFrame = CFrame.new(orig.Position, aimPos)
        RunService.RenderStepped:Wait()
        camera.CFrame = orig
    end)
end

function bindAllTools()
    if LocalPlayer.Character then
        for _, t in ipairs(LocalPlayer.Character:GetChildren()) do
            if t:IsA("Tool") then bindTool(t) end
        end
    end
    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") then bindTool(t) end
    end
end

if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(d)
        if d:IsA("Tool") then bindTool(d) end
    end)
    task.defer(bindAllTools)
end

LocalPlayer.Backpack.ChildAdded:Connect(function(d)
    if d:IsA("Tool") then bindTool(d) end
end)
