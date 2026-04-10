-- ═══════════════════════════════════════════════════════════════════
--  globals.lua  —  Menu V1  |  ЗАГРУЖАЕТСЯ ПЕРВЫМ
--  Сервисы, цветовая палитра, лог-система, общие утилиты.
--  Все переменные глобальные — доступны из любого следующего файла.
-- ═══════════════════════════════════════════════════════════════════

-- ─── СЕРВИСЫ ────────────────────────────────────────────────────────────────
Players          = game:GetService("Players")
UserInputService = game:GetService("UserInputService")
RunService       = game:GetService("RunService")
GuiService       = game:GetService("GuiService")
Lighting         = game:GetService("Lighting")
TweenService     = game:GetService("TweenService")
HttpService      = game:GetService("HttpService")

LocalPlayer = Players.LocalPlayer
PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
camera      = workspace.CurrentCamera

-- ─── ЦВЕТОВАЯ ПАЛИТРА ───────────────────────────────────────────────────────
C = {
    bg         = Color3.fromRGB(11,   4,  22),
    bar        = Color3.fromRGB(65,   0, 135),
    tabBg      = Color3.fromRGB(19,   5,  36),
    tabOn      = Color3.fromRGB(108,  0, 210),
    tabOff     = Color3.fromRGB(35,  12,  60),
    content    = Color3.fromRGB(15,   4,  28),
    rowBg      = Color3.fromRGB(24,   8,  46),
    rowHover   = Color3.fromRGB(32,  12,  58),
    togOn      = Color3.fromRGB(118,  0, 228),
    togOff     = Color3.fromRGB(42,  17,  70),
    sliderBg   = Color3.fromRGB(32,  11,  56),
    sliderFill = Color3.fromRGB(138, 18, 252),
    border     = Color3.fromRGB(98,  28, 198),
    borderDim  = Color3.fromRGB(48,  15,  98),
    text       = Color3.fromRGB(232, 205, 255),
    textDim    = Color3.fromRGB(135,  95, 195),
    sep        = Color3.fromRGB(52,  19, 100),
    toggleBtn  = Color3.fromRGB(48,   0, 105),
    inputBg    = Color3.fromRGB(21,   7,  40),
    btnAction  = Color3.fromRGB(70,   0, 145),
    btnHover   = Color3.fromRGB(94,   0, 182),
    accent     = Color3.fromRGB(162,  42, 255),
    accentDim  = Color3.fromRGB(100,  20, 170),
    logBg      = Color3.fromRGB(10,   4,  20),
    logText    = Color3.fromRGB(155, 225, 130),
    logSys     = Color3.fromRGB(100, 180, 255),
    green      = Color3.fromRGB(80,  200,  80),
    orange     = Color3.fromRGB(255, 160,  30),
    red        = Color3.fromRGB(220,  50,  50),
    yellow     = Color3.fromRGB(255, 220,  50),
    cyan       = Color3.fromRGB(80,  220, 255),
    white      = Color3.fromRGB(255, 255, 255),
    pink       = Color3.fromRGB(255, 120, 200),
}

-- ─── ЛОГ-СИСТЕМА ────────────────────────────────────────────────────────────
LOG_MAX   = 200      -- максимум строк в буфере
logBuffer = {}
logDirty  = false
logLabel  = nil      -- TextBox — назначается в gui.lua
debugMode = false    -- true = дублировать лог в output

function addLog(msg)
    local ts    = string.format("[%05.1f]", tick() % 1000)
    local entry = ts .. " " .. tostring(msg)
    logBuffer[#logBuffer + 1] = entry
    if #logBuffer > LOG_MAX then table.remove(logBuffer, 1) end
    logDirty = true
    if debugMode then
        print(entry)
    end
end

-- Очищает буфер и принудительно обновляет UI
function clearLog()
    logBuffer = {}
    logDirty  = true
    addLog("LOG ▸ очищен")
end

-- ─── УВЕДОМЛЕНИЯ (StarterGui:SetCore) ───────────────────────────────────────
--  Показывает всплывающее уведомление в правом нижнем углу экрана.
function notify(title, body, duration)
    duration = duration or 3
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = tostring(title or "Menu V1"),
            Text     = tostring(body  or ""),
            Duration = duration,
        })
    end)
end

-- ─── ОБЩИЕ УТИЛИТЫ ──────────────────────────────────────────────────────────

-- Округление до N знаков после запятой
function round(n, digits)
    local m = 10 ^ (digits or 0)
    return math.floor(n * m + 0.5) / m
end

-- Форматирование дистанции в studs (компактно)
function fmtDist(d)
    if d >= 1000 then
        return string.format("%.1fk", d / 1000)
    end
    return string.format("%d", math.floor(d))
end

-- Форматирование здоровья: "75/100 HP"
function fmtHealth(hum)
    if not hum then return "? HP" end
    return string.format("%d/%d HP",
        math.floor(hum.Health), math.floor(hum.MaxHealth))
end

-- Безопасный pcall с логированием ошибки
function safeCall(tag, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        addLog("[ERR] " .. tostring(tag) .. ": " .. tostring(err))
    end
    return ok
end

-- Проверяет, является ли игрок врагом LocalPlayer.
-- Правила:
--   • Нет персонажа        → не враг (нельзя прицелиться)
--   • Нет команды у кого-либо → FFA, все враги кроме себя
--   • Разные команды       → враг
function isEnemy(p)
    if p == LocalPlayer       then return false end
    if not p.Character        then return false end
    if not p.Team or not LocalPlayer.Team then return true end
    return p.Team ~= LocalPlayer.Team
end

-- Возвращает HumanoidRootPart персонажа игрока (или nil)
function getHRP(p)
    return p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
end

-- Возвращает Humanoid персонажа игрока (или nil)
function getHum(p)
    return p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
end

-- Линейная интерполяция числа
function lerp(a, b, t) return a + (b - a) * t end

-- ─── ВЕРСИЯ ─────────────────────────────────────────────────────────────────
MENU_VERSION = "v3.0"

addLog("GLOBAL ▸ globals.lua загружен  Menu V1 " .. MENU_VERSION)
addLog("GLOBAL ▸ игроков на сервере: " .. #Players:GetPlayers())
