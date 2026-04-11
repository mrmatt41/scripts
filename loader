-- ═══════════════════════════════════════════════════════════════════
--  loader.lua  —  Menu V1  |  ГЛАВНЫЙ ЗАГРУЗЧИК
--  Запускай ТОЛЬКО ЭТОТ файл в executor!
-- ═══════════════════════════════════════════════════════════════════

local REPO_RAW = "https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/"

local FILES = {
    "globals.lua",
    "esp.lua",
    "aim.lua",
    "movement.lua",
    "nds.lua",
    "teleport.lua",
    "visuals.lua",
    "misc.lua",
    "gui.lua",
    "main_loop.lua",
}

local function hr()   print(string.rep("═", 52)) end
local function log(m) print("[Loader]  " .. tostring(m)) end
local function ok(m)  print("[Loader] ✅ " .. tostring(m)) end
local function fail(m) warn("[Loader] 🔴 " .. tostring(m)) end
local function err(m)  warn("[Loader] ❌ " .. tostring(m)) end

hr()
log("Menu V1 Loader  —  github.com/mrmatt41/scripts")
log("Ветка: main   Файлов: " .. #FILES)
hr()
log("Шаг 1/2: проверка доступности...")

local failed = {}
local cache  = {}

for i, name in ipairs(FILES) do
    local url = REPO_RAW .. name
    local loadOk, result = pcall(function() return game:HttpGet(url, true) end)
    if not loadOk then
        err(string.format("[%d/%d] %-20s  ОШИБКА", i, #FILES, name))
        failed[#failed+1] = { name=name, reason=tostring(result) }
    elseif type(result) ~= "string" or #result < 8 then
        err(string.format("[%d/%d] %-20s  НЕ НАЙДЕН", i, #FILES, name))
        failed[#failed+1] = { name=name, reason="пустой ответ" }
    else
        local first = result:sub(1,80):lower()
        if first:find("404") or first:find("not found") then
            err(string.format("[%d/%d] %-20s  404", i, #FILES, name))
            failed[#failed+1] = { name=name, reason="GitHub вернул 404" }
        else
            ok(string.format("[%d/%d] %-20s  OK  (%d bytes)", i, #FILES, name, #result))
            cache[name] = result
        end
    end
end

hr()

if #failed > 0 then
    fail("ЗАГРУЗКА ПРЕРВАНА — недоступны " .. #failed .. "/" .. #FILES .. " файлов:")
    for _, f in ipairs(failed) do
        fail("  • " .. f.name .. "  →  " .. f.reason)
    end
    fail("Проверь: файлы в ветке main, названия точные, GitHub доступен.")
    hr()
    return
end

log("Все " .. #FILES .. " файлов доступны.")
hr()
log("Шаг 2/2: загрузка в процесс (сверху вниз)...")

for i, name in ipairs(FILES) do
    local src = cache[name]
    if not src then
        local r_ok, r_res = pcall(function() return game:HttpGet(REPO_RAW .. name, true) end)
        if not r_ok or not r_res then
            fail("Повторная загрузка " .. name .. " провалилась. Прерываем.")
            hr(); return
        end
        src = r_res
    end

    local fn, compErr = loadstring(src, "@" .. name)
    if not fn then
        fail("Ошибка компиляции [" .. name .. "]: " .. tostring(compErr))
        fail("Прерываем. Остальные файлы НЕ загружены.")
        hr(); return
    end

    local runOk, runErr = pcall(fn)
    if not runOk then
        fail("Ошибка выполнения [" .. name .. "]: " .. tostring(runErr))
        fail("Прерываем. Скрипт частично загружен.")
        hr(); return
    end

    ok(string.format("[%d/%d] %s", i, #FILES, name))
end

hr()
ok("Menu V1 успешно загружен!")
hr()
