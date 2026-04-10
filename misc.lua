-- ═══════════════════════════════════════════════════════════════════
--  misc.lua  —  Menu V1  |  Разное
--  Anti-AFK, Kill Aura, Chat Spy, Server Info, Hitbox Expander,
--  Auto-Rejoin, Fake Lag (ping spoof локальный).
--  Зависит от: globals.lua
-- ═══════════════════════════════════════════════════════════════════

-- ─── ANTI-AFK ────────────────────────────────────────────────────────────────
-- Имитирует ввод каждые 60 секунд чтобы не вылететь за AFK.
antiAfkEnabled = false
local _afkThread = nil

local function startAntiAfk()
    if _afkThread then task.cancel(_afkThread); _afkThread = nil end
    _afkThread = task.spawn(function()
        while antiAfkEnabled do
            task.wait(55)
            if not antiAfkEnabled then break end
            -- Мгновенно прыгаем через VirtualUser (не видно игроку)
            local ok = pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new(0,0))
            end)
            if not ok then
                -- Fallback: синтетический JumpRequest
                pcall(function()
                    local hum = LocalPlayer.Character
                        and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            end
            addLog("AFK  ▸ anti-afk tick")
        end
    end)
end

function setAntiAfk(state)
    antiAfkEnabled = state
    if state then
        startAntiAfk()
        addLog("AFK  ▸ ENABLED  (тик каждые 55с)")
    else
        if _afkThread then task.cancel(_afkThread); _afkThread = nil end
        addLog("AFK  ▸ DISABLED")
    end
end

-- ─── HITBOX EXPANDER ─────────────────────────────────────────────────────────
-- Увеличивает хитбоксы HumanoidRootPart всех врагов локально.
-- Сервер не видит изменений — только твои пули "попадают" чаще.
hitboxEnabled = false
hitboxSize    = 8    -- размер куба (studs); по умолчанию HRP ≈ 2×2×1
local _hitboxConns = {}  -- { [Player] = { charConn, sizeConn } }
local _hitboxOrigSizes = {}  -- { [Part] = Vector3 } оригинальные размеры

local function applyHitbox(p)
    if not (p and p.Character) then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    _hitboxOrigSizes[hrp] = hrp.Size
    pcall(function() hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize) end)
end

local function removeHitbox(p)
    if not (p and p.Character) then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local orig = _hitboxOrigSizes[hrp] or Vector3.new(2, 2, 1)
    pcall(function() hrp.Size = orig end)
    _hitboxOrigSizes[hrp] = nil
end

local function hitboxRegister(p)
    if p == LocalPlayer or _hitboxConns[p] then return end
    local cc = p.CharacterAdded:Connect(function()
        task.wait(0.3)
        if hitboxEnabled then applyHitbox(p) end
    end)
    _hitboxConns[p] = cc
    if hitboxEnabled then applyHitbox(p) end
end

local function hitboxUnregister(p)
    if _hitboxConns[p] then
        _hitboxConns[p]:Disconnect()
        _hitboxConns[p] = nil
    end
    removeHitbox(p)
end

function setHitbox(state)
    hitboxEnabled = state
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if state then applyHitbox(p) else removeHitbox(p) end
        end
    end
    addLog("HITBOX▸ " .. (state and "ENABLED  size=" .. hitboxSize or "DISABLED"))
end

function refreshHitboxSize()
    if not hitboxEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then applyHitbox(p) end
    end
end

-- Инициализация hitbox
for _, p in ipairs(Players:GetPlayers()) do hitboxRegister(p) end
Players.PlayerAdded:Connect(hitboxRegister)
Players.PlayerRemoving:Connect(hitboxUnregister)

-- ─── KILL AURA (базовая) ──────────────────────────────────────────────────────
-- Активирует Tool на ближайшего врага в радиусе.
-- ВАЖНО: работает только с инструментами у которых есть Tool:Activate()
-- и зависит от FE-настроек игры.
killAuraEnabled = false
killAuraRadius  = 15     -- studs
killAuraRate    = 0.2    -- секунд между атаками
local _kaThread = nil

local function startKillAura()
    if _kaThread then task.cancel(_kaThread); _kaThread = nil end
    _kaThread = task.spawn(function()
        while killAuraEnabled do
            task.wait(killAuraRate)
            if not killAuraEnabled then break end

            local myChar = LocalPlayer.Character
            local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tool   = myChar and myChar:FindFirstChildOfClass("Tool")
            if not (myHrp and tool) then continue end

            local best, bestDist = nil, killAuraRadius
            for _, p in ipairs(Players:GetPlayers()) do
                if not isEnemy(p) or not p.Character then continue end
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health <= 0 then continue end
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                local d = (myHrp.Position - hrp.Position).Magnitude
                if d < bestDist then best = p; bestDist = d end
            end

            if best then
                pcall(function() tool:Activate() end)
                addLog("AURA ▸ 💀 " .. best.Name .. "  " .. math.floor(bestDist) .. " st")
            end
        end
    end)
end

function setKillAura(state)
    killAuraEnabled = state
    if state then
        startKillAura()
        addLog("AURA ▸ ENABLED  R=" .. killAuraRadius .. " st")
    else
        if _kaThread then task.cancel(_kaThread); _kaThread = nil end
        addLog("AURA ▸ DISABLED")
    end
end

-- ─── CHAT SPY ────────────────────────────────────────────────────────────────
-- Логирует весь чат (включая TeamChat) в наш лог-буфер.
chatSpyEnabled = false
local _chatConn = nil

function setChatSpy(state)
    chatSpyEnabled = state
    if state then
        if _chatConn then _chatConn:Disconnect() end
        -- TextChatService (новый API Roblox)
        local ok = pcall(function()
            local TCS = game:GetService("TextChatService")
            _chatConn = TCS.MessageReceived:Connect(function(msg)
                if not chatSpyEnabled then return end
                local from = msg.TextSource and msg.TextSource.Name or "?"
                addLog("CHAT ▸ [" .. from .. "]: " .. msg.Text)
            end)
        end)
        -- Fallback: старый Players.LocalPlayer:GetMouse()
        if not ok then
            local ok2 = pcall(function()
                _chatConn = game:GetService("Chat").Chatted:Connect(function(channel, msg)
                    if not chatSpyEnabled then return end
                    addLog("CHAT ▸ " .. msg)
                end)
            end)
            if not ok2 then
                -- Подписываемся на каждого игрока
                for _, p in ipairs(Players:GetPlayers()) do
                    local cc = p.Chatted:Connect(function(msg)
                        if not chatSpyEnabled then return end
                        addLog("CHAT ▸ [" .. p.Name .. "]: " .. msg)
                    end)
                    -- Сохраняем соединение в _chatConn (упрощённо: только одно)
                end
                addLog("CHAT ▸ режим: Players.Chatted (ограниченный)")
            end
        end
        addLog("CHAT ▸ ENABLED")
    else
        if _chatConn then _chatConn:Disconnect(); _chatConn = nil end
        addLog("CHAT ▸ DISABLED")
    end
end

-- ─── SERVER INFO ─────────────────────────────────────────────────────────────
function printServerInfo()
    addLog("─────────────── SERVER INFO ───────────────")
    addLog("SRV  ▸ PlaceId   : " .. game.PlaceId)
    addLog("SRV  ▸ JobId     : " .. tostring(game.JobId):sub(1, 18) .. "…")
    addLog("SRV  ▸ Игроков   : " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
    addLog("SRV  ▸ Me        : " .. LocalPlayer.Name .. " [" .. LocalPlayer.UserId .. "]")
    addLog("SRV  ▸ Команда   : " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "нет"))
    local fe = pcall(function() return workspace.FilteringEnabled end)
    addLog("SRV  ▸ FE        : " .. (workspace.FilteringEnabled and "ON" or "OFF"))
    addLog("SRV  ▸ Gravity   : " .. workspace.Gravity)
    addLog("SRV  ▸ Version   : Menu V1 " .. MENU_VERSION)
    -- Список игроков
    for _, p in ipairs(Players:GetPlayers()) do
        local team = p.Team and p.Team.Name or "—"
        local hum  = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        local hp   = hum and string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)) or "dead"
        addLog(string.format("  %-20s  hp=%-9s  team=%s", p.Name, hp, team))
    end
    addLog("──────────────────────────────────────────")
end

-- ─── FAKE PING (локальное замедление) ────────────────────────────────────────
-- Добавляет искусственную задержку к Heartbeat (не реальный пинг,
-- но позволяет проверить поведение фич при высоком пинге).
fakeLagEnabled = false
fakeLagMs      = 100
local _lagConn = nil

function setFakeLag(state)
    fakeLagEnabled = state
    if state then
        if _lagConn then _lagConn:Disconnect() end
        _lagConn = RunService.Heartbeat:Connect(function()
            if not fakeLagEnabled then return end
            -- Блокируем поток на fakeLagMs миллисекунд
            -- (task.wait точный до кадра, но создаёт иллюзию lag)
            local t = tick()
            while tick() - t < fakeLagMs / 1000 do end
        end)
        addLog("LAG  ▸ ENABLED  " .. fakeLagMs .. " ms")
    else
        if _lagConn then _lagConn:Disconnect(); _lagConn = nil end
        addLog("LAG  ▸ DISABLED")
    end
end

-- ─── AUTO-REJOIN ─────────────────────────────────────────────────────────────
-- Переподключается к тому же серверу при вылете.
-- Только если игра поддерживает TeleportService.
function autoRejoin()
    local ok = pcall(function()
        local TS = game:GetService("TeleportService")
        TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    addLog("REJOIN▸ " .. (ok and "✅ переподключение…" or "❌ TeleportService заблокирован"))
end

-- ─── GRAVITY CONTROL ─────────────────────────────────────────────────────────
-- Изменяет гравитацию workspace локально.
-- [ПРИМЕЧАНИЕ] На FE-серверах изменение видно только тебе.
gravityEnabled  = false
gravityValue    = 196.2   -- stud/s² (стандарт Roblox = 196.2)

function applyGravity()
    pcall(function()
        workspace.Gravity = gravityValue
    end)
    addLog("GRAV ▸ gravity=" .. gravityValue)
end

function resetGravity()
    pcall(function() workspace.Gravity = 196.2 end)
    addLog("GRAV ▸ сброс → 196.2")
end

addLog("MISC ▸ misc.lua загружен  (afk/hitbox/aura/chatspy/srvinfo/gravity)")
