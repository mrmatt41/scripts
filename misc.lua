-- ═══════════════════════════════════════════════════════════════════
--  misc.lua  —  Menu V1  |  Разное  v2
--  Зависит от: globals.lua
-- ═══════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════
-- ANTI-AFK
-- Лучший метод: LocalPlayer.Idled — срабатывает ТОЛЬКО когда
-- Roblox реально собирается кикнуть (не таймер-цикл).
-- VirtualUser.Idled = встроенное событие движка, не детектируется.
-- ═══════════════════════════════════════════════════════════════════
antiAfkEnabled = false
local _afkConn  = nil   -- соединение на Idled
local _afkConn2 = nil   -- резервный таймер (для игр с кастомным AFK)

local VU = game:GetService("VirtualUser")

local function _doAntiAfkTick()
    -- Button2Down/Up — наименее детектируемый способ (ПКМ без движения)
    local ok = pcall(function()
        VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
    -- Fallback: CaptureController + ClickButton2 (старый API)
    if not ok then
        pcall(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new(0,0))
        end)
    end
end

function setAntiAfk(state)
    antiAfkEnabled = state

    -- Отключаем всё предыдущее
    if _afkConn  then _afkConn:Disconnect();  _afkConn  = nil end
    if _afkConn2 then _afkConn2:Disconnect(); _afkConn2 = nil end

    if not state then return end

    -- Метод 1: Idled event (срабатывает за ~секунду до кика)
    _afkConn = LocalPlayer.Idled:Connect(function()
        if not antiAfkEnabled then return end
        _doAntiAfkTick()
    end)

    -- Метод 2: резервный таймер каждые 4 мин (для игр с кастомными AFK)
    -- Не делаем это основным — слишком часто = подозрительно
    _afkConn2 = RunService.Heartbeat:Connect(function()
        if not antiAfkEnabled then return end
    end)
    -- На самом деле резерв — просто задержка раз в 4 минуты
    task.spawn(function()
        while antiAfkEnabled do
            task.wait(240)   -- 4 минуты
            if not antiAfkEnabled then break end
            _doAntiAfkTick()
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- HITBOX EXPANDER
-- Увеличивает HumanoidRootPart врагов локально.
-- ═══════════════════════════════════════════════════════════════════
hitboxEnabled    = false
hitboxSize       = 8
hitboxTransparent = false   -- [НОВОЕ] делать хитбокс прозрачным (виден только ты)
local _hitboxConns     = {}
local _hitboxOrigSizes = {}
local _hitboxOrigTrans = {}

local function applyHitbox(p)
    if not (p and p.Character) then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if _hitboxOrigSizes[hrp] == nil then
        _hitboxOrigSizes[hrp] = hrp.Size
        _hitboxOrigTrans[hrp] = hrp.LocalTransparencyModifier
    end
    pcall(function()
        hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        if hitboxTransparent then
            hrp.LocalTransparencyModifier = 1
        end
    end)
end

local function removeHitbox(p)
    if not (p and p.Character) then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local origSize  = _hitboxOrigSizes[hrp] or Vector3.new(2,2,1)
    local origTrans = _hitboxOrigTrans[hrp]  or 0
    pcall(function()
        hrp.Size = origSize
        hrp.LocalTransparencyModifier = origTrans
    end)
    _hitboxOrigSizes[hrp] = nil
    _hitboxOrigTrans[hrp] = nil
end

local function hitboxRegister(p)
    if p == LocalPlayer or _hitboxConns[p] then return end
    local cc = p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if hitboxEnabled then applyHitbox(p) end
    end)
    _hitboxConns[p] = cc
    if hitboxEnabled then applyHitbox(p) end
end

local function hitboxUnregister(p)
    if _hitboxConns[p] then _hitboxConns[p]:Disconnect(); _hitboxConns[p] = nil end
    removeHitbox(p)
end

function setHitbox(state)
    hitboxEnabled = state
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if state then applyHitbox(p) else removeHitbox(p) end
        end
    end
end

function refreshHitboxSize()
    if not hitboxEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then applyHitbox(p) end
    end
end

for _, p in ipairs(Players:GetPlayers()) do hitboxRegister(p) end
Players.PlayerAdded:Connect(hitboxRegister)
Players.PlayerRemoving:Connect(hitboxUnregister)

-- ═══════════════════════════════════════════════════════════════════
-- KILL AURA
-- Активирует Tool на ближайшего врага в радиусе.
-- Режимы: Nearest (ближайший) / Lowest HP (самый слабый)
-- ═══════════════════════════════════════════════════════════════════
killAuraEnabled  = false
killAuraRadius   = 15
killAuraRate     = 0.2
killAuraMode     = 1     -- 1=Nearest  2=LowestHP
local _kaThread  = nil

local function findKillAuraTarget()
    local myHrp = getHRP(LocalPlayer)
    if not myHrp then return nil end

    local best, bestVal = nil, nil

    for _, p in ipairs(Players:GetPlayers()) do
        if not isEnemy(p) or not p.Character then continue end
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local dist = (myHrp.Position - hrp.Position).Magnitude
        if dist > killAuraRadius then continue end

        if killAuraMode == 1 then
            -- Ближайший
            if not bestVal or dist < bestVal then
                best = p; bestVal = dist
            end
        else
            -- Слабейший по HP
            local hpFrac = hum.Health / math.max(hum.MaxHealth, 1)
            if not bestVal or hpFrac < bestVal then
                best = p; bestVal = hpFrac
            end
        end
    end

    return best
end

local function startKillAura()
    if _kaThread then task.cancel(_kaThread); _kaThread = nil end
    _kaThread = task.spawn(function()
        while killAuraEnabled do
            task.wait(killAuraRate)
            if not killAuraEnabled then break end

            local myChar = LocalPlayer.Character
            local tool   = myChar and myChar:FindFirstChildOfClass("Tool")
            if not tool then continue end

            local tgt = findKillAuraTarget()
            if tgt then
                pcall(function() tool:Activate() end)
            end
        end
    end)
end

function setKillAura(state)
    killAuraEnabled = state
    if state then startKillAura()
    else
        if _kaThread then task.cancel(_kaThread); _kaThread = nil end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- FULLBRIGHT (независимый от visuals.lua)
-- Мгновенно максимальная видимость без изменения Brightness (менее
-- заметный метод — только Ambient / OutdoorAmbient).
-- ═══════════════════════════════════════════════════════════════════
fullbrightEnabled   = false
local _fbOrigAmb    = nil
local _fbOrigOutAmb = nil

function setFullbright(state)
    fullbrightEnabled = state
    if state then
        _fbOrigAmb    = Lighting.Ambient
        _fbOrigOutAmb = Lighting.OutdoorAmbient
        pcall(function()
            Lighting.Ambient        = Color3.new(1,1,1)
            Lighting.OutdoorAmbient = Color3.new(1,1,1)
        end)
    else
        pcall(function()
            Lighting.Ambient        = _fbOrigAmb    or Color3.fromRGB(70,70,70)
            Lighting.OutdoorAmbient = _fbOrigOutAmb or Color3.fromRGB(140,140,140)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- INFINITE STAMINA
-- Держит стамину (обычно энергию / выносливость) на максимуме.
-- Работает для игр у которых есть NumberValue "Stamina" или
-- Humanoid.WalkSpeed управляется через Value-объект.
-- ═══════════════════════════════════════════════════════════════════
infStaminaEnabled = false
local _staminaConn = nil

function setInfStamina(state)
    infStaminaEnabled = state
    if _staminaConn then _staminaConn:Disconnect(); _staminaConn = nil end
    if not state then return end

    _staminaConn = RunService.Heartbeat:Connect(function()
        if not infStaminaEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        -- Ищем любой NumberValue с именем содержащим "stamina/energy/mana"
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local low = v.Name:lower()
                if low:find("stamina") or low:find("energy") or low:find("mana") or low:find("sprint") then
                    if v.Value < v.Value * 0.9 or v.Value < 10 then
                        pcall(function() v.Value = 100 end)
                    end
                end
            end
        end
        -- Также ищем в PlayerGui и leaderstats
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, v in ipairs(pg:GetDescendants()) do
                if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                    local low = v.Name:lower()
                    if low:find("stamina") or low:find("energy") then
                        pcall(function() v.Value = 100 end)
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- PLAYER MUTE (локальное отключение звука игрока)
-- ═══════════════════════════════════════════════════════════════════
local _mutedPlayers = {}

function mutePlayer(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name:lower():find(name:lower(), 1, true) then
            if p.Character then
                for _, v in ipairs(p.Character:GetDescendants()) do
                    if v:IsA("Sound") then
                        _mutedPlayers[v] = v.Volume
                        pcall(function() v.Volume = 0 end)
                    end
                end
            end
            addLog("MUTE ▸ заглушён: " .. p.Name)
            return
        end
    end
    addLog("MUTE ▸ не найден: " .. name)
end

function unmuteAll()
    for sound, vol in pairs(_mutedPlayers) do
        if sound and sound.Parent then
            pcall(function() sound.Volume = vol end)
        end
    end
    _mutedPlayers = {}
    addLog("MUTE ▸ все звуки восстановлены")
end

-- ═══════════════════════════════════════════════════════════════════
-- SERVER INFO
-- ═══════════════════════════════════════════════════════════════════
function printServerInfo()
    addLog("─────────────── SERVER INFO ───────────────")
    addLog("SRV  ▸ PlaceId  : " .. game.PlaceId)
    addLog("SRV  ▸ JobId    : " .. tostring(game.JobId):sub(1,18) .. "…")
    addLog("SRV  ▸ Игроков  : " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
    addLog("SRV  ▸ Me       : " .. LocalPlayer.Name .. " [" .. LocalPlayer.UserId .. "]")
    addLog("SRV  ▸ Команда  : " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "нет"))
    addLog("SRV  ▸ FE       : " .. (workspace.FilteringEnabled and "ON" or "OFF"))
    addLog("SRV  ▸ Gravity  : " .. workspace.Gravity)
    addLog("SRV  ▸ Ping     : " .. math.floor(LocalPlayer.NetworkPing * 1000) .. " ms")
    addLog("SRV  ▸ Version  : Menu V1 " .. MENU_VERSION)
    for _, p in ipairs(Players:GetPlayers()) do
        local team = p.Team and p.Team.Name or "—"
        local hum  = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        local hp   = hum and string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)) or "dead"
        local ping = math.floor(p.NetworkPing * 1000)
        addLog(string.format("  %-20s  hp=%-9s  ping=%-4d  team=%s",
            p.Name, hp, ping, team))
    end
    addLog("──────────────────────────────────────────")
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-REJOIN
-- ═══════════════════════════════════════════════════════════════════
function autoRejoin()
    local ok = pcall(function()
        local TS = game:GetService("TeleportService")
        TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    addLog("REJOIN▸ " .. (ok and "✅ переподключение…" or "❌ TeleportService заблокирован"))
end

-- ═══════════════════════════════════════════════════════════════════
-- GRAVITY
-- ═══════════════════════════════════════════════════════════════════
gravityEnabled = false
gravityValue   = 196.2

function applyGravity()
    pcall(function() workspace.Gravity = gravityValue end)
end

function resetGravity()
    pcall(function() workspace.Gravity = 196.2 end)
end
