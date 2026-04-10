-- ═══════════════════════════════════════════════════════════════════
--  movement.lua  —  Menu V1  |  Движение
--  Fly, WalkSpeed, NoClip, Spinbot, Infinite Jump, Jump Boost.
--  Зависит от: globals.lua
-- ═══════════════════════════════════════════════════════════════════

-- ─── SPEED ──────────────────────────────────────────────────────────────────
speedEnabled = false
speedValue   = 28
BASE_SPEED   = 16

-- ─── FLY ────────────────────────────────────────────────────────────────────
flyEnabled         = false
flySpeed           = 60
flyBodyVelocity    = nil
flyBodyGyro        = nil
flyConnection      = nil
flyCanCollideParts = {}   -- кэш { part, orig } для восстановления коллизий

-- [НОВОЕ] Плавное торможение при полёте (инерция)
flyInertia         = true
flyInertiaDecay    = 0.90  -- множитель скорости при отпускании кнопок

-- ─── NOCLIP ─────────────────────────────────────────────────────────────────
noClipEnabled    = false
noClipParts      = {}
noClipConnection = nil

-- ─── SPINBOT ────────────────────────────────────────────────────────────────
spinEnabled        = false
spinSpeedDegPerSec = 600
spinAxis           = "Y"   -- [НОВОЕ] ось вращения: "X", "Y", "Z"

-- ─── INFINITE JUMP ──────────────────────────────────────────────────────────
infiniteJumpEnabled = false
ijConn              = nil

-- ─── JUMP BOOST ─────────────────────────────────────────────────────────────
-- [НОВОЕ] Дополнительный вертикальный импульс при каждом прыжке
jumpBoostEnabled = false
jumpBoostForce   = 60    -- studs/s вверх

-- ─── УТИЛИТЫ ────────────────────────────────────────────────────────────────
--  Направление полёта по нажатым клавишам (WASD + Space/Shift).
--  Возвращает вектор направления и множитель скорости.
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
        dir = dir + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        dir = dir - Vector3.new(0, 1, 0)
    end

    -- LeftControl = медленный режим (30% скорости) для точного позиционирования
    local speedMult = 1
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        speedMult = 0.30
    end
    -- LeftAlt = ускорение (200%)
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
        speedMult = 2.0
    end

    return dir, speedMult
end

-- ─── FLY START / STOP ────────────────────────────────────────────────────────
function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Убираем старые экземпляры
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro     then flyBodyGyro:Destroy()     end
    if flyConnection   then flyConnection:Disconnect() end

    -- AutoRotate=false — минимально подозрительный способ отключить гравитацию
    hum.AutoRotate = false

    -- Снимаем коллизии со всех частей персонажа
    flyCanCollideParts = {}
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            flyCanCollideParts[#flyCanCollideParts + 1] = { part = p, orig = p.CanCollide }
            pcall(function() p.CanCollide = false end)
        end
    end

    -- BodyVelocity: MaxForce не math.huge — меньше детектирования
    flyBodyVelocity          = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVelocity.P        = 1250
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent   = hrp

    -- BodyGyro: удерживает ориентацию камеры
    flyBodyGyro           = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    flyBodyGyro.P         = 5000
    flyBodyGyro.D         = 200
    flyBodyGyro.CFrame    = hrp.CFrame
    flyBodyGyro.Parent    = hrp

    -- Текущая скорость для инерционного торможения
    local currentVel = Vector3.zero

    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not flyEnabled then return end
        if not hrp or not hrp.Parent then flyEnabled = false return end

        local dir, mult = getFlyDir()
        local targetVel

        if dir.Magnitude > 0.001 then
            targetVel = dir.Unit * flySpeed * mult
        else
            -- Инерция: постепенно тормозим
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

        -- Поддерживаем CanCollide=false каждый кадр
        for _, entry in ipairs(flyCanCollideParts) do
            if entry.part and entry.part.Parent and entry.part.CanCollide then
                pcall(function() entry.part.CanCollide = false end)
            end
        end
    end)

    addLog("FLY  ▸ ENABLED  speed=" .. flySpeed)
end

function stopFly()
    if flyConnection   then flyConnection:Disconnect();  flyConnection   = nil end
    if flyBodyVelocity then flyBodyVelocity:Destroy();   flyBodyVelocity = nil end
    if flyBodyGyro     then flyBodyGyro:Destroy();       flyBodyGyro     = nil end

    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = true end

    -- Восстанавливаем исходные коллизии
    for _, entry in ipairs(flyCanCollideParts) do
        if entry.part and entry.part.Parent then
            pcall(function() entry.part.CanCollide = entry.orig end)
        end
    end
    flyCanCollideParts = {}

    addLog("FLY  ▸ DISABLED")
end

-- ─── NOCLIP ─────────────────────────────────────────────────────────────────
function updateNoClipCache()
    noClipParts = {}
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            noClipParts[#noClipParts + 1] = p
        end
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
        if part and part.Parent then
            pcall(function() part.CanCollide = true end)
        end
    end
end

-- ─── SPINBOT ────────────────────────────────────────────────────────────────
--  Вращает HumanoidRootPart вокруг выбранной оси каждый кадр.
local SPIN_AXIS_MAP = {
    X = function(dt) return CFrame.Angles(math.rad(spinSpeedDegPerSec * dt), 0, 0) end,
    Y = function(dt) return CFrame.Angles(0, math.rad(spinSpeedDegPerSec * dt), 0) end,
    Z = function(dt) return CFrame.Angles(0, 0, math.rad(spinSpeedDegPerSec * dt)) end,
}

function getSpinDelta(dt)
    local fn = SPIN_AXIS_MAP[spinAxis] or SPIN_AXIS_MAP["Y"]
    return fn(dt)
end

-- ─── INFINITE JUMP ───────────────────────────────────────────────────────────
local function attachInfJump(char)
    if ijConn then ijConn:Disconnect(); ijConn = nil end
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    ijConn = UserInputService.JumpRequest:Connect(function()
        if not infiniteJumpEnabled then return end
        -- Меняем состояние Humanoid на прыжок (работает в воздухе)
        hum:ChangeState(Enum.HumanoidStateType.Jumping)

        -- Jump Boost: добавляем импульс вверх
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

-- ─── RESPAWN HANDLING ────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    -- Сбрасываем физику полёта (объекты уничтожаются при респавне)
    flyBodyVelocity    = nil
    flyBodyGyro        = nil
    flyCanCollideParts = {}
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end

    -- Переподключаем InfJump
    attachInfJump(char)

    -- Ждём загрузки персонажа
    task.wait(0.4)

    if flyEnabled     then startFly() end
    updateNoClipCache()

    local hum = char:FindFirstChildOfClass("Humanoid")
    if speedEnabled and hum then hum.WalkSpeed = speedValue end
end)

-- ─── ИНИЦИАЛИЗАЦИЯ ───────────────────────────────────────────────────────────
if LocalPlayer.Character then
    attachInfJump(LocalPlayer.Character)
    task.defer(updateNoClipCache)
end

startNoClip()

addLog("MOVE ▸ movement.lua загружен  (fly/speed/noclip/spin/ijump/jboost)")
