-- ═══════════════════════════════════════════════════════════════════
--  loader.lua  —  Menu V1  |  ГЛАВНЫЙ ЗАГРУЗЧИК
--  Запускай ТОЛЬКО ЭТОТ файл в executor!
--
--  Алгоритм:
--    1) Проверяем доступность КАЖДОГО файла (HEAD-запрос через HttpGet).
--       Если хотя бы один недоступен — выводим ошибку и ПРЕРЫВАЕМСЯ.
--    2) Только если ВСЕ файлы доступны — загружаем их поочерёдно
--       через loadstring(game:HttpGet(""))().
--
--  Репозиторий: github.com/mrmatt41/scripts (branch: main)
-- ═══════════════════════════════════════════════════════════════════

local REPO_USER   = "mrmatt41"
local REPO_NAME   = "scripts"
local REPO_BRANCH = "main"
local REPO_RAW    = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/",
    REPO_USER, REPO_NAME, REPO_BRANCH)

-- ── Порядок загрузки (СТРОГО сверху вниз) ───────────────────────────────────
--  Каждый следующий файл имеет доступ к глобальным переменным предыдущих.
local FILES = {
    "globals.lua",     -- 1. Сервисы, цвета, лог, утилиты
    "esp.lua",         -- 2. ESP: подсветка врагов
    "aim.lua",         -- 3. Aim Assist / Silent Aim / TriggerBot
    "movement.lua",    -- 4. Fly / Speed / NoClip / Spin / Jump
    "nds.lua",         -- 5. NDS: захват объектов карты
    "teleport.lua",    -- 6. Teleport: по клику и по нику
    "visuals.lua",     -- 7. Visuals: туман / яркость / кроссхейр
    "misc.lua",        -- 8. Anti-AFK / KillAura / ChatSpy / ServerInfo
    "gui.lua",         -- 9. GUI: весь интерфейс
    "main_loop.lua",   -- 10. Главный цикл: Heartbeat / RenderStepped / Input
}

-- ── ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ─────────────────────────────────────────────────
local function hr() print(string.rep("═", 52)) end

local function log(msg)   print("[Loader]  " .. tostring(msg)) end
local function err(msg)   warn("[Loader] ❌ " .. tostring(msg)) end
local function ok(msg)    print("[Loader] ✅ " .. tostring(msg)) end
local function fail(msg)  warn("[Loader] 🔴 " .. tostring(msg)) end

-- ── ШАГ 1: ПРОВЕРКА ДОСТУПНОСТИ ─────────────────────────────────────────────
hr()
log("Menu V1 Loader  —  github.com/" .. REPO_USER .. "/" .. REPO_NAME)
log("Ветка: " .. REPO_BRANCH .. "   Файлов: " .. #FILES)
hr()
log("Шаг 1/2: проверка доступности файлов...")

local failedFiles   = {}  -- список недоступных файлов
local contentCache  = {}  -- кэш содержимого (чтобы не качать дважды)

for i, name in ipairs(FILES) do
    local url    = REPO_RAW .. name
    local status = "❓"
    local bytes  = 0

    local loadOk, result = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not loadOk then
        -- HttpGet сам бросил ошибку (сеть, таймаут)
        status = "ОШИБКА"
        failedFiles[#failedFiles + 1] = { name = name, reason = tostring(result) }
    elseif type(result) ~= "string" or #result < 8 then
        -- Пустой или слишком короткий ответ = файл не найден
        status = "НЕ НАЙДЕН"
        failedFiles[#failedFiles + 1] = { name = name, reason = "пустой ответ" }
    else
        -- Проверяем что это не страница 404 от GitHub
        local firstLine = result:sub(1, 80):lower()
        if firstLine:find("404") or firstLine:find("not found") then
            status = "404"
            failedFiles[#failedFiles + 1] = { name = name, reason = "GitHub вернул 404" }
        else
            status  = "OK"
            bytes   = #result
            contentCache[name] = result  -- сохраняем контент для шага 2
        end
    end

    local line = string.format("[%d/%d] %-20s  %s",
        i, #FILES, name, status)
    if bytes > 0 then
        line = line .. string.format("  (%d bytes)", bytes)
    end

    if status == "OK" then
        ok(line)
    else
        err(line)
    end
end

-- ── Итог проверки ────────────────────────────────────────────────────────────
hr()

if #failedFiles > 0 then
    fail("ЗАГРУЗКА ПРЕРВАНА — недоступны " .. #failedFiles .. "/" .. #FILES .. " файлов:")
    for _, f in ipairs(failedFiles) do
        fail("  • " .. f.name .. "  →  " .. f.reason)
    end
    fail("")
    fail("Что сделать:")
    fail("  1) Убедись что файлы запушены в ветку '" .. REPO_BRANCH .. "'")
    fail("  2) Проверь точность названий: регистр имеет значение")
    fail("  3) Проверь доступность GitHub с устройства (VPN?)")
    fail("  4) Репозиторий: https://github.com/" .. REPO_USER .. "/" .. REPO_NAME)
    hr()
    return  -- ПРЕРЫВАЕМ выполнение, ничего не загружаем
end

log("Все " .. #FILES .. " файлов доступны.")

-- ── ШАГ 2: ЗАГРУЗКА В ПРОЦЕСС ────────────────────────────────────────────────
hr()
log("Шаг 2/2: загрузка файлов в процесс (сверху вниз)...")

for i, name in ipairs(FILES) do
    local src = contentCache[name]
    if not src then
        -- На случай если кэш пуст — качаем снова
        local retry_ok, retry_res = pcall(function()
            return game:HttpGet(REPO_RAW .. name, true)
        end)
        if not retry_ok or not retry_res then
            fail("Повторная загрузка " .. name .. " провалилась.")
            fail("Прерываем — состояние скрипта непредсказуемо.")
            hr()
            return
        end
        src = retry_res
    end

    -- Компиляция Lua
    local fn, compileErr = loadstring(src, "@" .. name)
    if not fn then
        fail("Ошибка компиляции [" .. name .. "]:")
        fail("  " .. tostring(compileErr))
        fail("Прерываем. Остальные файлы НЕ загружены.")
        hr()
        return
    end

    -- Выполнение
    local runOk, runErr = pcall(fn)
    if not runOk then
        fail("Ошибка выполнения [" .. name .. "]:")
        fail("  " .. tostring(runErr))
        fail("Прерываем. Состояние скрипта частично загружено.")
        hr()
        return
    end

    ok(string.format("[%d/%d] %s", i, #FILES, name))
end

-- ── ГОТОВО ───────────────────────────────────────────────────────────────────
hr()
ok("Menu V1 успешно загружен!")
ok("Репозиторий: github.com/" .. REPO_USER .. "/" .. REPO_NAME)
hr()
