-- ═══════════════════════════════════════════════════════════════════
--  visuals.lua  —  Menu V1  |  Визуальные эффекты
--  Туман, яркость, время суток, прозрачность игроков,
--  пользовательский кроссхейр.
--  Зависит от: globals.lua
-- ═══════════════════════════════════════════════════════════════════

-- ─── ПЕРЕМЕННЫЕ СОСТОЯНИЯ ────────────────────────────────────────────────────
visualFogEnabled    = false
visualBrightEnabled = false
visualTimeEnabled   = false   -- [НОВОЕ] фиксированное время суток
visualChamsEnabled  = false   -- [НОВОЕ] прозрачность персонажей других игроков
visualCrosshairOn   = false   -- [НОВОЕ] пользовательский кроссхейр

brightnessValue     = 2       -- уровень яркости (слайдер 1–10)
visualTimeValue     = 14      -- час суток (0–24), используется если TimeEnabled
visualChamsAlpha    = 0.55    -- прозрачность чамсов (0=видно, 1=невидимо)

-- ─── ОРИГИНАЛЬНЫЕ ЗНАЧЕНИЯ (для восстановления) ──────────────────────────────
local _origFogEnd    = nil
local _origFogStart  = nil
local _origFogColor  = nil
local _origBright    = nil
local _origAmbient   = nil
local _origOutdoor   = nil
local _origSoftness  = nil
local _origClockTime = nil

local function snapLighting()
    if _origFogEnd == nil then
        _origFogEnd    = Lighting.FogEnd
        _origFogStart  = Lighting.FogStart
        _origFogColor  = Lighting.FogColor
        _origBright    = Lighting.Brightness
        _origAmbient   = Lighting.Ambient
        _origOutdoor   = Lighting.OutdoorAmbient
        _origSoftness  = Lighting.ShadowSoftness
        _origClockTime = Lighting.ClockTime
    end
end

-- ─── ТУМАН ───────────────────────────────────────────────────────────────────
function applyNoFog()
    snapLighting()
    pcall(function()
        Lighting.FogEnd   = 1e6
        Lighting.FogStart = 1e6
        Lighting.FogColor = Color3.fromRGB(0, 0, 0)

        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            atm.Density = 0 ; atm.Haze = 0 ; atm.Glare = 0
        end

        -- Отключаем Smoke / Fire / Sparkles в workspace
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                pcall(function() obj.Enabled = false end)
            end
        end
    end)
    addLog("VIS  ▸ туман убран")
end

function restoreFog()
    if not _origFogEnd then return end
    pcall(function()
        Lighting.FogEnd   = _origFogEnd
        Lighting.FogStart = _origFogStart
        Lighting.FogColor = _origFogColor or Color3.fromRGB(191,191,191)

        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = 0.3 ; atm.Haze = 0 end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                pcall(function() obj.Enabled = true end)
            end
        end
    end)
    addLog("VIS  ▸ туман восстановлен")
end

-- ─── ЯРКОСТЬ ─────────────────────────────────────────────────────────────────
function applyBrightness(val)
    snapLighting()
    pcall(function()
        Lighting.Brightness     = val
        Lighting.Ambient        = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.ShadowSoftness = 0

        -- Bloom: затемняет при высокой яркости — отключаем
        local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
        if bloom then bloom.Enabled = false end

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if cc then cc.Brightness = 0.3 ; cc.Contrast = 0 ; cc.Saturation = 0 end
    end)
end

function restoreBrightness()
    if not _origBright then return end
    pcall(function()
        Lighting.Brightness     = _origBright
        Lighting.Ambient        = _origAmbient or Color3.fromRGB(70,70,70)
        Lighting.OutdoorAmbient = _origOutdoor or Color3.fromRGB(140,140,140)
        Lighting.ShadowSoftness = _origSoftness or 0.5

        local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
        if bloom then bloom.Enabled = true end

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if cc then cc.Brightness = 0 ; cc.Contrast = 0 ; cc.Saturation = 0 end
    end)
end

-- ─── ВРЕМЯ СУТОК ─────────────────────────────────────────────────────────────
-- [НОВОЕ] Фиксирует ClockTime и держит его каждый кадр (некоторые игры
-- принудительно меняют время — нужно перебивать в Heartbeat).
local _timeConn = nil

function applyFixedTime(hour)
    visualTimeValue = hour
    snapLighting()
    if _timeConn then _timeConn:Disconnect(); _timeConn = nil end
    if not visualTimeEnabled then return end
    -- Устанавливаем сразу
    pcall(function() Lighting.ClockTime = hour end)
    -- И держим в Heartbeat (игра может сбрасывать)
    _timeConn = RunService.Heartbeat:Connect(function()
        if not visualTimeEnabled then
            _timeConn:Disconnect() ; _timeConn = nil ; return
        end
        if math.abs(Lighting.ClockTime - hour) > 0.05 then
            pcall(function() Lighting.ClockTime = hour end)
        end
    end)
    addLog("VIS  ▸ время зафиксировано: " .. string.format("%.1f ч", hour))
end

function restoreTime()
    if _timeConn then _timeConn:Disconnect() ; _timeConn = nil end
    if _origClockTime then
        pcall(function() Lighting.ClockTime = _origClockTime end)
    end
    addLog("VIS  ▸ время восстановлено")
end

-- ─── ЧАМСЫ (прозрачность чужих персонажей) ───────────────────────────────────
-- [НОВОЕ] Делает тела других игроков полупрозрачными, сохраняет оригинал.
local _chamsBackup = {}   -- { [BasePart] = оригинальная Transparency }

local function applyChamsToPlayer(p)
    if not p.Character then return end
    for _, obj in ipairs(p.Character:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
            if _chamsBackup[obj] == nil then
                _chamsBackup[obj] = obj.Transparency
            end
            pcall(function() obj.Transparency = visualChamsAlpha end)
        end
    end
end

local function clearChamsFromPlayer(p)
    if not p.Character then return end
    for _, obj in ipairs(p.Character:GetDescendants()) do
        if obj:IsA("BasePart") then
            local orig = _chamsBackup[obj]
            if orig ~= nil then
                pcall(function() obj.Transparency = orig end)
                _chamsBackup[obj] = nil
            end
        end
    end
end

function applyChams()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isEnemy(p) then
            applyChamsToPlayer(p)
        end
    end
    addLog("VIS  ▸ чамсы включены  alpha=" .. visualChamsAlpha)
end

function clearChams()
    for _, p in ipairs(Players:GetPlayers()) do
        clearChamsFromPlayer(p)
    end
    _chamsBackup = {}
    addLog("VIS  ▸ чамсы выключены")
end

-- Обновляем чамсы при появлении нового персонажа
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if visualChamsEnabled then
            task.wait(0.5)
            if isEnemy(p) then applyChamsToPlayer(p) end
        end
    end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            if visualChamsEnabled then
                task.wait(0.5)
                if isEnemy(p) then applyChamsToPlayer(p) end
            end
        end)
    end
end

-- ─── КРОССХЕЙР ───────────────────────────────────────────────────────────────
-- [НОВОЕ] SVG-подобный кроссхейр поверх экрана (Frame + UIStroke).
local _crosshairGui  = nil
local _crosshairConn = nil

local CROSS_SIZE  = 14   -- половина длины линии (px)
local CROSS_GAP   = 4    -- зазор в центре (px)
local CROSS_THICK = 1.5  -- толщина (px)
local CROSS_COLOR = Color3.fromRGB(0, 255, 100)

local function buildCrosshair()
    if _crosshairGui then _crosshairGui:Destroy() end

    local sg              = Instance.new("ScreenGui")
    sg.Name               = "_Crosshair"
    sg.ResetOnSpawn       = false
    sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset     = true
    sg.Parent             = PlayerGui
    _crosshairGui         = sg

    local function line(horiz)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = CROSS_COLOR
        f.BorderSizePixel  = 0
        if horiz then
            f.Size     = UDim2.new(0, CROSS_SIZE, 0, CROSS_THICK)
            f.AnchorPoint = Vector2.new(0.5, 0.5)
        else
            f.Size     = UDim2.new(0, CROSS_THICK, 0, CROSS_SIZE)
            f.AnchorPoint = Vector2.new(0.5, 0.5)
        end
        f.Parent = sg
        return f
    end

    local lLeft  = line(true)
    local lRight = line(true)
    local lUp    = line(false)
    local lDown  = line(false)

    -- Обновляем позиции в RenderStepped (следуем за мышью)
    _crosshairConn = RunService.RenderStepped:Connect(function()
        if not visualCrosshairOn then return end
        local m  = UserInputService:GetMouseLocation()
        local cx = m.X ; local cy = m.Y

        lLeft.Position  = UDim2.new(0, cx - CROSS_GAP - CROSS_SIZE/2, 0, cy)
        lRight.Position = UDim2.new(0, cx + CROSS_GAP + CROSS_SIZE/2, 0, cy)
        lUp.Position    = UDim2.new(0, cx, 0, cy - CROSS_GAP - CROSS_SIZE/2)
        lDown.Position  = UDim2.new(0, cx, 0, cy + CROSS_GAP + CROSS_SIZE/2)
    end)
end

function showCrosshair()
    visualCrosshairOn = true
    buildCrosshair()
    addLog("VIS  ▸ кроссхейр включён")
end

function hideCrosshair()
    visualCrosshairOn = false
    if _crosshairConn then _crosshairConn:Disconnect() ; _crosshairConn = nil end
    if _crosshairGui  then _crosshairGui:Destroy()     ; _crosshairGui  = nil end
    addLog("VIS  ▸ кроссхейр выключен")
end

-- ─── БЫСТРЫЕ ПРЕСЕТЫ ─────────────────────────────────────────────────────────
-- [НОВОЕ] Preset "night": ночь + полная яркость (видно всё без теней)
function presetNightVision()
    visualTimeEnabled = true
    applyFixedTime(0)
    visualBrightEnabled = true
    applyBrightness(6)
    addLog("VIS  ▸ пресет: NIGHT VISION активирован")
end

-- Preset "day": сброс всего к дневному свету
function presetRestore()
    if visualFogEnabled    then restoreFog()        end
    if visualBrightEnabled then restoreBrightness() end
    if visualTimeEnabled   then restoreTime()       end
    if visualChamsEnabled  then clearChams()        end
    visualFogEnabled    = false
    visualBrightEnabled = false
    visualTimeEnabled   = false
    visualChamsEnabled  = false
    addLog("VIS  ▸ все эффекты сброшены")
end

addLog("VIS  ▸ visuals.lua загружен  (fog/bright/time/chams/crosshair/presets)")
