-- ═══════════════════════════════════════════════════════════════════
--  esp.lua  —  Menu V1  |  ESP v2 (FIXED: death/respawn bug)
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
    addLog("ESP ▸ ON  : " .. p.Name .. "  [" .. p.UserId .. "]")
end

local function clearHL(char, p)
    if not char then return end
    local h = char:FindFirstChild("_ESP")
    if not h then return end
    if p then
        addLog("ESP ▸ OFF : " .. p.Name .. "  [" .. p.UserId .. "]")
    end
    h:Destroy()
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

    lbl(p.Name, 18, 0,  C.white,   11).Name = "NameLbl"
    lbl("",     13, 18, C.logText,  9).Name = "InfoLbl"

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

function updateESPLabels()
    if not espEnabled then return end
    local myHrp = getHRP(LocalPlayer)
    for p in pairs(espPool) do
        if not (p and p.Character) then continue end

        -- Watchdog inline
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
                parts[#parts+1] = string.format("%d/%d hp", math.floor(hum.Health), math.floor(hum.MaxHealth))
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
                math.floor(f*200 + (1-f)*50), 60)
        end

        if nameLbl then nameLbl.Visible = espShowName end
        if espHealthColor or espShowTeamColor then refreshHLColor(p) end
    end
end

-- ─── ПРИМЕНЕНИЕ ESP ──────────────────────────────────────────────────────────
local function applyESP(p)
    if not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        hrp = p.Character:WaitForChild("HumanoidRootPart", 10)
    end
    if not hrp then return end
    task.wait(0.1)
    if not espEnabled or not isEnemy(p) then return end
    makeHL(p.Character, p)
    makeBillboard(p)
end

local function removeESP(p)
    if p.Character then clearHL(p.Character, p) end
    removeBillboard(p)
end

function espRefreshAll()
    local cnt = 0
    for _ in pairs(espPool) do cnt += 1 end
    addLog("ESP ▸ refresh  pool=" .. cnt)
    for p in pairs(espPool) do
        if espEnabled and isEnemy(p) then task.spawn(applyESP, p) else removeESP(p) end
    end
end

function espClearAll()
    addLog("ESP ▸ clear all highlights")
    for p in pairs(espPool) do removeESP(p) end
end

-- ─── РЕГИСТРАЦИЯ ─────────────────────────────────────────────────────────────
function espRegister(p)
    if p == LocalPlayer or espPool[p] then return end
    espPool[p] = true

    local cc = p.CharacterAdded:Connect(function(char)
        task.spawn(function()
            task.wait(0.25)
            applyESP(p)
        end)
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            hum.Died:Connect(function()
                task.wait(0.05)
                clearHL(char, p)
                removeBillboard(p)
            end)
        end
    end)

    local cr = p.CharacterRemoving:Connect(function(char)
        clearHL(char, p)
        removeBillboard(p)
    end)

    local tc = p:GetPropertyChangedSignal("Team"):Connect(function()
        task.wait(0.1)
        if not isEnemy(p) then removeESP(p)
        elseif espEnabled then task.spawn(applyESP, p) end
    end)

    espConns[p] = { cc=cc, cr=cr, tc=tc }

    if espEnabled and isEnemy(p) then task.spawn(applyESP, p) end
    addLog("ESP ▸ register: " .. p.Name .. "  [" .. p.UserId .. "]")
end

function espUnregister(p)
    if espPool[p] then
        addLog("ESP ▸ unreg  : " .. p.Name .. "  [" .. p.UserId .. "]")
    end
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

-- ─── WATCHDOG ────────────────────────────────────────────────────────────────
task.spawn(function()
    local pass = 0
    while true do
        task.wait(5)
        pass += 1
        local removed = 0
        for p in pairs(espPool) do
            if not p or p.Parent ~= Players then
                espUnregister(p)
                removed += 1
            end
        end
        addLog("ESP ▸ cleanup #" .. pass
            .. "  pool=" .. (function() local n=0; for _ in pairs(espPool) do n+=1 end; return n end)()
            .. (removed > 0 and "  removed=" .. removed or ""))
        -- Доп: восстанавливаем пропавшие хайлайты
        if espEnabled then
            local fixed = 0
            for p in pairs(espPool) do
                if not (p and p.Parent == Players) then continue end
                if not p.Character then continue end
                if isEnemy(p) and not p.Character:FindFirstChild("_ESP") then
                    task.spawn(applyESP, p); fixed += 1
                end
            end
        end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do espRegister(p) end
Players.PlayerAdded:Connect(espRegister)
Players.PlayerRemoving:Connect(espUnregister)
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(espRefreshAll)
