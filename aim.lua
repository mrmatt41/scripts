-- ═══════════════════════════════════════════════════════════════════
--  aim.lua  —  Menu V1  |  Aim Assist / Silent Aim / Trigger Bot
--  Зависит от: globals.lua, esp.lua (espEnabled)
-- ═══════════════════════════════════════════════════════════════════

-- ─── НАСТРОЙКИ AIM ──────────────────────────────────────────────────────────
isAimAssistEnabled  = false
isSilentAimEnabled  = false
isTriggerBotEnabled = false
allowWallbang       = false

aimKey              = Enum.UserInputType.MouseButton2   -- кнопка захвата
aimPartName         = "Head"       -- часть тела для прицеливания
aimSmoothness       = 0.15         -- 0=мгновенно, 0.99=очень плавно
fovHalfSize         = 120          -- половина стороны FOV-квадрата (px)
fovVisible          = false

-- [НОВОЕ] Упреждение цели: учитывает скорость цели при захвате
aimPrediction       = false
aimPredictMult      = 0.07         -- коэффициент (секунды упреждения)

-- ─── НАСТРОЙКИ TRIGGERBOT ────────────────────────────────────────────────────
triggerCooldownSec  = 0.10         -- минимальный интервал между выстрелами
lastTriggerFireAt   = 0
lastTargetScanAt    = 0            -- throttle getBestTarget до 20fps

-- ─── ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ───────────────────────────────────────────────────
currentTool     = nil
aimLockedTarget = nil              -- цель, захваченная Aim Assist

-- UI-ссылки TriggerBot (назначаются в gui.lua)
_tbTog    = nil
_tbAccent = nil
_tbRow    = nil
_tbState  = false

-- ─── СИМУЛЯЦИЯ НАЖАТИЯ ЛКМ ──────────────────────────────────────────────────
--  Пробует executor API, при отсутствии — tool:Activate() как fallback.
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

-- ─── ВИДИМОСТЬ ЦЕЛИ ─────────────────────────────────────────────────────────

--  Строгая проверка (0 пробитий) — используется TriggerBot.
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

--  С пробиванием до 1 тонкого объекта — используется Aim Assist.
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
        if result.Instance and result.Instance:IsDescendantOf(targetChar) then
            return true
        end
        hits += 1
        if hits > MAX_HITS then return false end
        cur       = result.Position + dirU * 0.2
        remaining = (dest - cur).Magnitude
    end
    return false
end

-- ─── FOV ────────────────────────────────────────────────────────────────────
--  Возвращает (внутри: bool, метрика: number) для экранной точки.
function isPointInFOV(sp2d)
    local m  = UserInputService:GetMouseLocation()
    local dx = math.abs(sp2d.X - m.X)
    local dy = math.abs(sp2d.Y - m.Y)
    return (dx <= fovHalfSize and dy <= fovHalfSize), math.max(dx, dy)
end

-- ─── ВЫБОР ЛУЧШЕЙ ЦЕЛИ ──────────────────────────────────────────────────────
function getBestTarget(includeOccluded)
    local closest, bestMetric = nil, math.huge
    local origin = camera.CFrame.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if not isEnemy(p) or not p.Character then continue end

        -- Пропускаем мёртвых
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end

        -- Fallback: Head → HRP → первая BasePart
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
            if metric < bestMetric then
                closest, bestMetric = p, metric
            end
        end
    end

    return closest
end

-- ─── ПОЗИЦИЯ ПРИЦЕЛИВАНИЯ (с упреждением) ───────────────────────────────────
function getAimPos(p)
    if not (p and p.Character) then return nil end
    local h = p.Character:FindFirstChild(aimPartName)
           or p.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local pos = h.Position

    -- Упреждение: сдвигаем точку прицеливания на вектор скорости × коэф
    if aimPrediction then
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.AssemblyLinearVelocity
            -- Дистанция влияет на нужное упреждение
            local dist = (camera.CFrame.Position - pos).Magnitude
            local tFlight = dist * 0.0028  -- примерное время полёта пули
            pos = pos + vel * (aimPredictMult + tFlight)
        end
    end

    return pos
end

-- Обратная совместимость
getHeadPos = getAimPos

-- ─── УПРАВЛЕНИЕ КАМЕРОЙ ─────────────────────────────────────────────────────
function aimCameraAt(worldPt)
    if not worldPt then return end
    local camCF   = camera.CFrame
    local desired = (worldPt - camCF.Position).Unit
    local t       = 1 - math.clamp(aimSmoothness, 0, 0.999)
    local smoothed = camCF.LookVector:Lerp(desired, t)
    camera.CFrame  = CFrame.new(camCF.Position, camCF.Position + smoothed)
end

-- ─── АВТОВЫКЛЮЧЕНИЕ TRIGGERBOT ───────────────────────────────────────────────
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

-- ─── ПРИВЯЗКА ИНСТРУМЕНТОВ (Silent Aim) ──────────────────────────────────────
function bindTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    currentTool = tool

    -- Очищаем currentTool когда инструмент убирается
    tool.AncestryChanged:Connect(function(_, parent)
        if not parent and currentTool == tool then
            currentTool = nil
        end
    end)

    -- При активации (выстреле) — мгновенно поворачиваем камеру на цель
    tool.Activated:Connect(function()
        if not isSilentAimEnabled then return end
        local tgt = getBestTarget(allowWallbang)
        if not tgt then return end
        local aimPos = getAimPos(tgt)
        if not aimPos then return end
        local orig = camera.CFrame
        camera.CFrame = CFrame.new(orig.Position, aimPos)
        -- Ждём один кадр, затем возвращаем камеру (невидимо для игрока)
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

-- ─── ИНИЦИАЛИЗАЦИЯ ───────────────────────────────────────────────────────────
if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(d)
        if d:IsA("Tool") then bindTool(d) end
    end)
    task.defer(bindAllTools)
end

LocalPlayer.Backpack.ChildAdded:Connect(function(d)
    if d:IsA("Tool") then bindTool(d) end
end)

addLog("AIM  ▸ aim.lua загружен  (assist/silent/triggerbot/fov/prediction)")
