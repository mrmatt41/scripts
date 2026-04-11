-- ═══════════════════════════════════════════════════════════════════
--  misc.lua  —  Menu V1  |  Разное
-- ═══════════════════════════════════════════════════════════════════

-- ─── ANTI-AFK ────────────────────────────────────────────────────────────────
antiAfkEnabled = false
local _afkThread = nil

local function startAntiAfk()
    if _afkThread then task.cancel(_afkThread); _afkThread = nil end
    _afkThread = task.spawn(function()
        while antiAfkEnabled do
            task.wait(55)
            if not antiAfkEnabled then break end
            local ok = pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new(0,0))
            end)
            if not ok then
                pcall(function()
                    local hum = LocalPlayer.Character
                        and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            end
        end
    end)
end

function setAntiAfk(state)
    antiAfkEnabled = state
    if state then
        startAntiAfk()
    else
        if _afkThread then task.cancel(_afkThread); _afkThread = nil end
    end
end

-- ─── HITBOX EXPANDER ─────────────────────────────────────────────────────────
hitboxEnabled = false
hitboxSize    = 8
local _hitboxConns     = {}
local _hitboxOrigSizes = {}

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
    local orig = _hitboxOrigSizes[hrp] or Vector3.new(2,2,1)
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

-- ─── KILL AURA ───────────────────────────────────────────────────────────────
killAuraEnabled = false
killAuraRadius  = 15
killAuraRate    = 0.2
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
                if d < bestDist then best=p; bestDist=d end
            end
            if best then pcall(function() tool:Activate() end) end
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

-- ─── SERVER INFO ─────────────────────────────────────────────────────────────
function printServerInfo()
    addLog("─────────────── SERVER INFO ───────────────")
    addLog("SRV  ▸ PlaceId  : " .. game.PlaceId)
    addLog("SRV  ▸ JobId    : " .. tostring(game.JobId):sub(1,18) .. "…")
    addLog("SRV  ▸ Игроков  : " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
    addLog("SRV  ▸ Me       : " .. LocalPlayer.Name .. " [" .. LocalPlayer.UserId .. "]")
    addLog("SRV  ▸ Команда  : " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "нет"))
    addLog("SRV  ▸ FE       : " .. (workspace.FilteringEnabled and "ON" or "OFF"))
    addLog("SRV  ▸ Gravity  : " .. workspace.Gravity)
    for _, p in ipairs(Players:GetPlayers()) do
        local team = p.Team and p.Team.Name or "—"
        local hum  = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        local hp   = hum and string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)) or "dead"
        addLog(string.format("  %-20s  hp=%-9s  team=%s", p.Name, hp, team))
    end
    addLog("──────────────────────────────────────────")
end

-- ─── AUTO-REJOIN ─────────────────────────────────────────────────────────────
function autoRejoin()
    local ok = pcall(function()
        local TS = game:GetService("TeleportService")
        TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    addLog("REJOIN▸ " .. (ok and "✅ переподключение…" or "❌ TeleportService заблокирован"))
end

-- ─── GRAVITY ─────────────────────────────────────────────────────────────────
gravityEnabled = false
gravityValue   = 196.2

function applyGravity()
    pcall(function() workspace.Gravity = gravityValue end)
end

function resetGravity()
    pcall(function() workspace.Gravity = 196.2 end)
end
