-- ═══════════════════════════════════════════════════════════════════
--  loader.lua  —  Menu V1  |  ГЛАВНЫЙ ЗАГРУЗЧИК
--  Запускай ТОЛЬКО ЭТОТ файл в executor!
-- ═══════════════════════════════════════════════════════════════════

local FILES = {
    { name="globals.lua",   url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/globals.lua"   },
    { name="esp.lua",       url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/esp.lua"       },
    { name="aim.lua",       url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/aim.lua"       },
    { name="movement.lua",  url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/movement.lua"  },
    { name="nds.lua",       url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/nds.lua"       },
    { name="teleport.lua",  url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/teleport.lua"  },
    { name="visuals.lua",   url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/visuals.lua"   },
    { name="misc.lua",      url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/misc.lua"      },
    { name="gui.lua",       url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/gui.lua"       },
    { name="main_loop.lua", url="https://raw.githubusercontent.com/mrmatt41/scripts/refs/heads/main/main_loop.lua" },
}

local function hr()    print(string.rep("═", 54)) end
local function log(m)  print("[Loader]  " .. tostring(m)) end
local function ok(m)   print("[Loader] ✅ " .. tostring(m)) end
local function fail(m) warn("[Loader] 🔴 " .. tostring(m)) end
local function err(m)  warn("[Loader] ❌ " .. tostring(m)) end

hr()
log("Menu V1  |  mrmatt41/scripts  branch: main")
log("Файлов: " .. #FILES)
hr()
log("Шаг 1/2: проверка доступности...")

local failed = {}
local cache  = {}

for i, f in ipairs(FILES) do
    local loadOk, result = pcall(function()
        return game:HttpGet(f.url, true)
    end)
    if not loadOk then
        err(string.format("[%d/%d] %-20s  ОШИБКА СЕТИ", i, #FILES, f.name))
        failed[#failed+1] = { name=f.name, reason=tostring(result) }
    elseif type(result) ~= "string" or #result < 10 then
        err(string.format("[%d/%d] %-20s  ПУСТОЙ ОТВЕТ", i, #FILES, f.name))
        failed[#failed+1] = { name=f.name, reason="пустой ответ" }
    else
        local first = result:sub(1,100):lower()
        if first:find("404") or first:find("not found") then
            err(string.format("[%d/%d] %-20s  404", i, #FILES, f.name))
            failed[#failed+1] = { name=f.name, reason="404 от GitHub" }
        else
            ok(string.format("[%d/%d] %-20s  OK (%d bytes)", i, #FILES, f.name, #result))
            cache[f.name] = result
        end
    end
end

hr()

if #failed > 0 then
    fail("ПРЕРВАНО — " .. #failed .. "/" .. #FILES .. " файлов недоступны:")
    for _, f in ipairs(failed) do
        fail("  • " .. f.name .. "  →  " .. f.reason)
    end
    hr(); return
end

log("Все " .. #FILES .. " файлов OK. Загружаю в процесс...")
hr()

for i, f in ipairs(FILES) do
    local src = cache[f.name]
    if not src then
        local r_ok, r_res = pcall(function() return game:HttpGet(f.url, true) end)
        if not r_ok or type(r_res) ~= "string" then
            fail("Повторная загрузка [" .. f.name .. "] провалилась. Прерываем."); hr(); return
        end
        src = r_res
    end

    local fn, compErr = loadstring(src, "@" .. f.name)
    if not fn then
        fail("Ошибка компиляции [" .. f.name .. "]: " .. tostring(compErr)); hr(); return
    end

    local runOk, runErr = pcall(fn)
    if not runOk then
        fail("Ошибка выполнения [" .. f.name .. "]: " .. tostring(runErr)); hr(); return
    end

    ok(string.format("[%d/%d] %s", i, #FILES, f.name))
end

hr()
ok("Menu V1 загружен! Кнопка '◈ MENU' или RightAlt.")
hr()
