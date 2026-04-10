-- ═══════════════════════════════════════════════════════════════════
--  esp.lua  —  Menu V1  |  ESP v2 (FIXED: death/respawn bug)
--  Highlight + BillboardGui (HP-бар, дистанция, имя).
--  ИСПРАВЛЕНО:
--    • Ждём HumanoidRootPart (WaitForChild 10s) перед навеской
--    • CharacterRemoving → немедленная очистка ДО respawn
--    • Humanoid.Died → убираем хайлайт сразу при смерти
--    • Watchdog каждые 3с: восстанавливает пропавшие хайлайты
--  НОВОЕ:
--    • Цвет контура по HP / Team.TeamColor
--    • Billboard: HP-бар + дистанция + имя
-- ═══════════════════════════════════════════════════════════════════

espEnabled          = false
espShowHealth       = true
espShowDist         = true
espShowName         = true
espHealthColor      = false
espShowTeamColor    = false
espFillOpacity      = 0.80
espOutlineOpacity   = 0.0
ESP_COLOR           = Color3.fromRGB(170, 0, 255)

espPool       = {}
espConns      = {}
espBillboards = {}

-- ─── ЦВЕТ ────────────────────────────────────────────────────────────────────
local function getESPColor(p)
    if espShowTeamColor and p.Team then return p.Team.TeamColor.Color end
    if espHealthColor then
        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.MaxHealth > 0 then
            local f = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            return Color3.fromRGB(math.floor((1-f)*220), math.floor(f*200), 60)
        end
    end
    return ESP_COLOR
end

-- ─── HIGHLIGHT ───────────────────────────────────────────────────────────────
local function makeHL(char, p)
    if char:FindFirstChild("_ESP") then return end
    local h               = Instance.new("Highlight")
    h.Name                = "_ESP"
    h.FillTransparency    = espFillOpacity
    h.OutlineTransparency = espOutlineOpacity
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    local col             = getESPColor(p)
    h.OutlineColor        = col
    h.FillColor           = col
    h.Parent              = char
end

local function clearHL(char)
    if not char then return end
    local h = char:FindFirstChild("_ESP")
    if h then h:Destroy() end
end

local function refreshHLColor(p)
    if not (p and p.Character) then return end
    local h = p.Character:FindFirstChild("_ESP")
    if not h then return end
    local col = getESPColor(p)
    h.OutlineColor = col
    h.FillColor    = col
end

-- ─── BILLBOARD ───────────────────────────────────────────────────────────────
local function makeBillboard(p)
    if not (p and p.Character) then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if espBillboards[p] then
        pcall(function() espBillboards[p]:Destroy() end)
        espBillboards[p] = nil
    end

    local bb          = Instance.new("BillboardGui")
    bb.Name           = "_ESPBill"
    bb.Size           = UDim2.new(0,92,0,50)
    bb.StudsOffset    = Vector3.new(0,3.6,0)
    bb.AlwaysOnTop    = true
    bb.ResetOnSpawn   = false
    bb.LightInfluence = 0
    bb.Parent         = hrp

    local function lbl(text, sizeY, posY, col, fs)
        local l = Instance.new("TextLabel")
        l.Size                   = UDim2.new(1,0,0,sizeY)
        l.Position               = UDim2.new(0,0,0,posY)
        l.BackgroundTransparency = 1
        l.Text                   = text
        l.TextColor3             = col or C.white
        l.Font                   = Enum.Font.GothamBold
        l.TextSize               = fs or 11
        l.TextStrokeTransparency = 0.35
        l.TextStrokeColor3       = Color3.new(0,0,0)
        l.Parent                 = bb
        return l
    end

    lbl(p.Name, 18, 0, C.white, 11).Name         = "NameLbl"
    lbl("",     13, 18, C.logText, 9).Name        = "InfoLbl"

    local barBg            = Instance.new("Frame")
    barBg.Name             = "BarBg"
    barBg.Size             = UDim2.new(1,0,0,4)
    barBg.Position         = UDim2.new(0,0,0,34)
    barBg.BackgroundColor3 = Color3.fromRGB(30,8,50)
    barBg.BorderSizePixel  = 0
    barBg.Parent           = bb

    local barFill            = Instance.new("Frame")
    barFill.Name             = "BarFill"
    barFill.Size             = UDim2.new(1,0,1,0)
    barFill.BackgroundColor3 = C.green
    barFill.BorderSizePixel  = 0
    barFill.Parent           = barBg

    espBillboards[p] = bb
end

local function removeBillboard(p)
    if espBillboards[p] then
        pcall(function() espBillboards[p]:Destroy() end)
        espBillboards[p] = nil
    end
end

-- ─── ОБНОВЛЕНИЕ МЕТОК (вызывать из main_loop ~0.15с) ────────────────────────
function updateESPLabels()
    if not espEnabled then return end
    local myHrp = getHRP(LocalPlayer)
    for p in pairs(espPool) do
        if not (p and p.Character) then continue end

        -- Watchdog inline: восстанавливаем пропавший хайлайт
        if isEnemy(p) and not p.Character:FindFirstChild("_ESP") then
            makeHL(p.Character, p)
        end

        local bb = espBillboards[p]
        if not (bb and bb.Parent) and isEnemy(p) then
            makeBillboard(p); bb = espBillboards[p]
        end
        if not (bb and bb.Parent) then continue end

        local hum     = getHum(p)
        local tHrp    = getHRP(p)
        local infoLbl = bb:FindFirstChild("InfoLbl")
        local barFill = bb:FindFirstChild("BarBg") and bb.BarBg:FindFirstChild("BarFill")
        local nameLbl = bb:FindFirstChild("NameLbl")

        if infoLbl then
            local parts = {}
            if espShowHealth and hum then
                parts[#parts+1] = string.format("%d/%d hp",
                    math.floor(hum.Health), math.floor(hum.MaxHealth))
            end
            if espShowDist and myHrp and tHrp then
                parts[#parts+1] = fmtDist((myHrp.Position - tHrp.Position).Magnitude) .. " st"
            end
            infoLbl.Text = table.concat(parts, "  │  ")
        end

        if barFill and hum and hum.MaxHealth > 0 then
            local f = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            barFill.Size             = UDim2.new(f,0,1,0)
            barFill.BackgroundColor3 = Color3.fromRGB(
                math.floor((1-f)*220 + f*80),
                math.floor(f*200    + (1-f)*50), 60)
        end

        if nameLbl then nameLbl.Visible = espShowName end
        if espHealthColor or espShowTeamColor then refreshHLColor(p) end
    end
end

-- ─── ПРИМЕНЕНИЕ ESP (ждём HRP) ───────────────────────────────────────────────
local function applyESP(p)
    if not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        hrp = p.Character:WaitForChild("HumanoidRootPart", 10)
    end
    if not hrp then return end
    task.wait(0.1)   -- даём время Humanoid загрузиться тоже
    if not espEnabled or not isEnemy(p) then return end
    makeHL(p.Character, p)
    makeBillboard(p)
    addLog("ESP  ▸ ON  " .. p.Name)
end

local function removeESP(p)
    if p.Character then clearHL(p.Character) end
    removeBillboard(p)
end

-- ─── REFRESH / CLEAR ─────────────────────────────────────────────────────────
function espRefreshAll()
    addLog("ESP  ▸ refresh  pool=" .. (function() local n=0; for _ in pairs(espPool) do n+=1 end; return n end)())
    for p in pairs(espPool) do
        if espEnabled and isEnemy(p) then task.spawn(applyESP, p) else removeESP(p) end
    end
end

function espClearAll()
    addLog("ESP  ▸ clear all")
    for p in pairs(espPool) do removeESP(p) end
end

-- ─── РЕГИСТРАЦИЯ ─────────────────────────────────────────────────────────────
function espRegister(p)
    if p == LocalPlayer or espPool[p] then return end
    espPool[p] = true

    -- CharacterAdded: новый персонаж (respawn)
    local cc = p.CharacterAdded:Connect(function(char)
        task.spawn(function()
            task.wait(0.25)  -- ← ключевая задержка для respawn
            applyESP(p)
        end)
        -- Подписываемся на смерть нового персонажа
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            hum.Died:Connect(function()
                task.wait(0.05)
                clearHL(char)
                removeBillboard(p)
                addLog("ESP  ▸ died  " .. p.Name)
            end)
        end
    end)

    -- CharacterRemoving: персонаж уничтожается (до respawn)
    local cr = p.CharacterRemoving:Connect(function(char)
        clearHL(char)
        removeBillboard(p)
    end)

    -- Смена команды
    local tc = p:GetPropertyChangedSignal("Team"):Connect(function()
        task.wait(0.1)
        if not isEnemy(p) then removeESP(p)
        elseif espEnabled then task.spawn(applyESP, p) end
    end)

    espConns[p] = { cc=cc, cr=cr, tc=tc }

    if espEnabled and isEnemy(p) then task.spawn(applyESP, p) end
    addLog("ESP  ▸ +reg  " .. p.Name)
end

function espUnregister(p)
    if espPool[p] then addLog("ESP  ▸ -reg  " .. p.Name) end
    local c = espConns[p]
    if c then
        if c.cc then c.cc:Disconnect() end
        if c.cr then c.cr:Disconnect() end
        if c.tc then c.tc:Disconnect() end
        espConns[p] = nil
    end
    removeESP(p)
    espPool[p] = nil
end

-- ─── ФОНОВЫЙ WATCHDOG ────────────────────────────────────────────────────────
-- Каждые 3с: восстанавливает хайлайты если они пропали по любой причине
task.spawn(function()
    local n = 0
    while true do
        task.wait(3)
        if not espEnabled then continue end
        n += 1
        local fixed = 0
        for p in pairs(espPool) do
            if not (p and p.Parent == Players) then espUnregister(p); continue end
            if not p.Character then continue end
            local hasHL = p.Character:FindFirstChild("_ESP") ~= nil
            local enemy = isEnemy(p)
            if enemy and not hasHL then
                task.spawn(applyESP, p); fixed += 1
            elseif not enemy and hasHL then
                clearHL(p.Character); removeBillboard(p); fixed += 1
            end
        end
        if fixed > 0 then addLog("ESP  ▸ watchdog #"..n.."  fixed="..fixed) end
    end
end)

-- ─── INIT ────────────────────────────────────────────────────────────────────
for _, p in ipairs(Players:GetPlayers()) do espRegister(p) end
Players.PlayerAdded:Connect(espRegister)
Players.PlayerRemoving:Connect(espUnregister)
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(espRefreshAll)

addLog("ESP  ▸ v2 загружен  (death-fix + watchdog + billboard)")
