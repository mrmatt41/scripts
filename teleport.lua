-- ═══════════════════════════════════════════════════════════════════
--  teleport.lua  —  Menu V1  |  Телепорт
--  Режимы: клик (Ctrl+ЛКМ), по нику, история, вейпоинты.
--  Зависит от: globals.lua
-- ═══════════════════════════════════════════════════════════════════

-- ─── НАСТРОЙКИ ──────────────────────────────────────────────────────────────
teleportEnabled  = false    -- Ctrl+ЛКМ телепорт
targetPlayerName = ""       -- имя цели для TP к игроку

-- Максимальная дистанция для click-TP (защита от перелёта за карту)
TP_MAX_DIST = 10000

-- ─── ИСТОРИЯ ТЕЛЕПОРТОВ ─────────────────────────────────────────────────────
TP_HISTORY_MAX = 15
tpHistory      = {}   -- { pos: Vector3, label: string, time: number }

-- Добавляет позицию в историю
local function pushTpHistory(pos, label)
    table.insert(tpHistory, 1, {
        pos   = pos,
        label = label or string.format("%.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z),
        time  = os.time(),
    })
    if #tpHistory > TP_HISTORY_MAX then
        table.remove(tpHistory, #tpHistory)
    end
end

-- ─── ВЕЙПОИНТЫ ───────────────────────────────────────────────────────────────
WAYPOINTS_MAX = 20
waypoints     = {}   -- { name: string, pos: Vector3 }

function waypointSave(name)
    local hrp = getHRP(LocalPlayer)
    if not hrp then
        addLog("TP   ▸ ⚠ нет персонажа для сохранения вейпоинта")
        return false
    end
    -- Перезаписываем если имя совпадает
    for i, wp in ipairs(waypoints) do
        if wp.name == name then
            waypoints[i].pos = hrp.Position
            addLog("TP   ▸ 📍 вейпоинт обновлён: " .. name)
            return true
        end
    end
    if #waypoints >= WAYPOINTS_MAX then
        addLog("TP   ▸ ⚠ лимит вейпоинтов (" .. WAYPOINTS_MAX .. ")")
        return false
    end
    waypoints[#waypoints+1] = { name = name, pos = hrp.Position }
    addLog("TP   ▸ 📍 вейпоинт сохранён: " .. name
           .. "  @ " .. string.format("%.0f, %.0f, %.0f",
               hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
    return true
end

function waypointGoto(name)
    for _, wp in ipairs(waypoints) do
        if wp.name == name then
            doTeleport(wp.pos, "wp:" .. name)
            return true
        end
    end
    addLog("TP   ▸ вейпоинт не найден: " .. name)
    return false
end

function waypointDelete(name)
    for i, wp in ipairs(waypoints) do
        if wp.name == name then
            table.remove(waypoints, i)
            addLog("TP   ▸ 🗑 вейпоинт удалён: " .. name)
            return true
        end
    end
    return false
end

-- ─── БАЗОВАЯ ФУНКЦИЯ ТЕЛЕПОРТА ────────────────────────────────────────────────
--  Выполняет телепорт в позицию tgtPos.
--  Перед TP: фиксируем скорость BodyVelocity=0 (сервер не успевает откинуть).
--  После TP: убираем BodyVelocity через 0.15с.
function doTeleport(tgtPos, reason)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        addLog("TP   ▸ ❌ нет HRP (персонаж не загружен?)")
        return false
    end

    local dist = (hrp.Position - tgtPos).Magnitude

    if dist > TP_MAX_DIST then
        addLog("TP   ▸ ❌ слишком далеко (" .. fmtDist(dist) .. " > " .. fmtDist(TP_MAX_DIST) .. ")")
        return false
    end

    local ok = pcall(function()
        -- Фиксируем скорость — иначе сервер физикой откинет назад
        local bv          = Instance.new("BodyVelocity")
        bv.Velocity       = Vector3.zero
        bv.MaxForce       = Vector3.new(1e9, 1e9, 1e9)
        bv.Parent         = hrp
        hrp.CFrame        = CFrame.new(tgtPos)
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        task.delay(0.18, function()
            if bv and bv.Parent then bv:Destroy() end
        end)
    end)

    local label = reason and ("  [" .. reason .. "]") or ""
    addLog("TP   ▸ " .. (ok and "✅ " or "❌ ")
           .. string.format("%.0f, %.0f, %.0f", tgtPos.X, tgtPos.Y, tgtPos.Z)
           .. "  " .. fmtDist(dist) .. " st" .. label)

    if ok then pushTpHistory(tgtPos, reason) end
    return ok
end

-- ─── ТЕЛЕПОРТ К ИГРОКУ ────────────────────────────────────────────────────────
function tpToPlayer(partialName)
    if not partialName or partialName == "" then
        addLog("TP   ▸ ⚠ введи имя игрока")
        return false
    end
    local low = string.lower(partialName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and string.lower(p.Name):find(low, 1, true) then
            local tgtHrp = getHRP(p)
            if not tgtHrp then
                addLog("TP   ▸ ⚠ у " .. p.Name .. " нет HRP (мёртв?)")
                return false
            end
            -- Телепортируемся немного за спину цели, чтобы не застрять
            local offset = tgtHrp.CFrame * CFrame.new(0, 0, 3)
            return doTeleport(offset.Position, "→" .. p.Name)
        end
    end
    addLog("TP   ▸ игрок не найден: " .. partialName)
    return false
end

-- ─── ТЕЛЕПОРТ НАЗАД (последняя позиция из истории) ───────────────────────────
function tpBack()
    if #tpHistory < 2 then
        addLog("TP   ▸ история пуста")
        return
    end
    -- Берём предыдущую позицию (не текущую)
    local entry = tpHistory[2]
    doTeleport(entry.pos, "back:" .. entry.label)
end

-- ─── CLICK-TP (Ctrl + ЛКМ) ───────────────────────────────────────────────────
--  Подключается в main_loop.lua к UserInputService.InputBegan.
--  Здесь определяем функцию-обработчик.
function handleClickTP(input)
    if not teleportEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end

    local mPos   = UserInputService:GetMouseLocation()
    local ray    = camera:ScreenPointToRay(mPos.X, mPos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { LocalPlayer.Character }

    local result = workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
    if not result then return end

    -- Поднимаем на 3 studs чтобы не застрять в земле
    local tgtPos = result.Position + Vector3.new(0, 3, 0)
    doTeleport(tgtPos, "click")
end

-- ─── ВЕЙПОИНТ ТЕКУЩЕЙ ПОЗИЦИИ (горячая клавиша) ──────────────────────────────
--  Привязывается в main_loop: F5 = сохранить "quick", F6 = перейти на "quick"
function tpQuickSave()
    waypointSave("quick")
    notify("Waypoint", "Позиция сохранена как 'quick'", 2)
end

function tpQuickGoto()
    waypointGoto("quick")
end

addLog("TP   ▸ teleport.lua загружен  (click/nick/history/waypoints)")
