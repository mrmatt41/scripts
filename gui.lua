-- ═══════════════════════════════════════════════════════════════════
--  gui.lua  —  Menu V1  |  Интерфейс
--  4 вкладки: COMBAT / MOVEMENT / MISC / LOG
--  Все функции из всех модулей подключены здесь.
--  Зависит от: globals.lua + все предыдущие модули
-- ═══════════════════════════════════════════════════════════════════

-- ─── UI BUILDER HELPERS ──────────────────────────────────────────────────────
local function mkFrame(parent, size, pos, color, name)
    local f            = Instance.new("Frame")
    f.Name             = name or "F"
    f.Size             = size
    f.Position         = pos
    f.BackgroundColor3 = color
    f.BorderSizePixel  = 0
    f.Parent           = parent
    return f
end

local function mkLabel(parent, text, size, pos, col, align, fs)
    local l                  = Instance.new("TextLabel")
    l.Size                   = size
    l.Position               = pos
    l.BackgroundTransparency = 1
    l.Text                   = text
    l.TextColor3             = col or C.text
    l.Font                   = Enum.Font.GothamBold
    l.TextSize               = fs or 12
    l.TextXAlignment         = align or Enum.TextXAlignment.Left
    l.TextYAlignment         = Enum.TextYAlignment.Center
    l.Parent                 = parent
    return l
end

local function mkBtn(parent, text, size, pos, bg, col, fs)
    local b            = Instance.new("TextButton")
    b.Size             = size
    b.Position         = pos
    b.BackgroundColor3 = bg
    b.BorderSizePixel  = 0
    b.Text             = text
    b.TextColor3       = col or C.text
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = fs or 12
    b.AutoButtonColor  = false
    b.Parent           = parent
    return b
end

local function addCorner(inst, r)
    local c        = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent       = inst
    return c
end

local function addStroke(inst, col, t)
    local s     = Instance.new("UIStroke")
    s.Color     = col or C.border
    s.Thickness = t or 1
    s.Parent    = inst
    return s
end

local function mkTextBox(parent, size, pos, placeholder)
    local tb             = Instance.new("TextBox")
    tb.Size              = size
    tb.Position          = pos
    tb.BackgroundColor3  = C.inputBg
    tb.BorderSizePixel   = 0
    tb.Text              = ""
    tb.PlaceholderText   = placeholder or ""
    tb.PlaceholderColor3 = C.textDim
    tb.TextColor3        = C.text
    tb.Font              = Enum.Font.Gotham
    tb.TextSize          = 11
    tb.ClearTextOnFocus  = false
    tb.Parent            = parent
    addCorner(tb, 4)
    addStroke(tb, C.borderDim, 1)
    return tb
end

-- ─── КОНСТАНТЫ ЛЕЙАУТА ───────────────────────────────────────────────────────
local MENU_W  = 340
local MENU_H  = 580
local BAR_H   = 34
local TAB_W   = 50
local CONT_W  = MENU_W - TAB_W - 2
local PX      = 6

-- ─── SCREEN GUI ──────────────────────────────────────────────────────────────
local Gui              = Instance.new("ScreenGui")
Gui.Name               = "MenuV1_UI"
Gui.ResetOnSpawn       = false
Gui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset     = false
Gui.Parent             = PlayerGui

-- FOV-квадрат
local fovSquare                  = Instance.new("Frame")
fovSquare.Name                   = "FOVSquare"
fovSquare.Size                   = UDim2.fromOffset(fovHalfSize*2, fovHalfSize*2)
fovSquare.BackgroundTransparency = 0.90
fovSquare.BackgroundColor3       = Color3.fromRGB(80,20,130)
fovSquare.BorderSizePixel        = 0
fovSquare.Visible                = false
fovSquare.Parent                 = Gui
addStroke(fovSquare, Color3.fromRGB(180,60,255), 1.5)
addCorner(fovSquare, 3)

-- Кнопка открытия
local openBtn = mkBtn(Gui, "◈  MENU",
    UDim2.new(0,90,0,28),
    UDim2.new(0,10,0,148),
    C.toggleBtn, C.text, 12)
addCorner(openBtn, 6)
addStroke(openBtn, C.border, 1.5)
do
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(88,10,172)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 0, 80)),
    })
    g.Rotation = 90; g.Parent = openBtn
end

-- Главное окно
local main = mkFrame(Gui,
    UDim2.new(0,MENU_W,0,MENU_H),
    UDim2.new(0,10,0,184),
    C.bg, "Main")
main.Visible = false
addCorner(main, 10)
addStroke(main, C.border, 1.5)

-- Топ-бар
local topBar = mkFrame(main,
    UDim2.new(1,0,0,BAR_H),
    UDim2.new(0,0,0,0),
    C.bar, "TopBar")
addCorner(topBar, 10)
mkFrame(topBar, UDim2.new(1,0,0,10), UDim2.new(0,0,1,-10), C.bar, "BarFix")
do
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(110,12,205)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(72, 0,145)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(42, 0, 92)),
    })
    g.Rotation = 0; g.Parent = topBar
end

local dot = mkFrame(topBar, UDim2.new(0,8,0,8), UDim2.new(0,10,0,13), C.accent, "Dot")
addCorner(dot, 5)

mkLabel(topBar, "◈  Menu V1",
    UDim2.new(1,-82,1,0), UDim2.new(0,24,0,0),
    C.text, Enum.TextXAlignment.Left, 13)

mkLabel(topBar, MENU_VERSION,
    UDim2.new(0,30,1,0), UDim2.new(1,-92,0,0),
    C.textDim, Enum.TextXAlignment.Right, 9)

local minBtn = mkBtn(topBar, "—",
    UDim2.new(0,26,0,20), UDim2.new(1,-32,0,7),
    C.tabOff, C.textDim, 14)
addCorner(minBtn, 4)

-- Панель вкладок
local tabPanel = mkFrame(main,
    UDim2.new(0,TAB_W,1,-BAR_H),
    UDim2.new(0,0,0,BAR_H),
    C.tabBg, "TabPanel")
mkFrame(main, UDim2.new(0,1,1,-BAR_H), UDim2.new(0,TAB_W,0,BAR_H), C.borderDim, "Div")

local contentArea = mkFrame(main,
    UDim2.new(0,MENU_W-TAB_W-2, 0, MENU_H-BAR_H-2),
    UDim2.new(0,TAB_W+2, 0, BAR_H+2),
    C.content, "Content")

-- Вкладки: COMBAT / MOVEMENT / MISC / LOG
local TAB_ICONS  = { "⚔", "🏃", "★", "📋" }
local TAB_LABELS = { "Combat", "Movement", "Misc", "Log" }

local pages        = {}
local tabBtns      = {}
local tabIndicators= {}

-- Страница 1 и 3 — ScrollingFrame (контент длинный)
local function makePage(idx, canvasH)
    if canvasH then
        local p = Instance.new("ScrollingFrame")
        p.Name                 = "Page"..idx
        p.Size                 = UDim2.new(1,0,1,0)
        p.BackgroundTransparency = 1
        p.BorderSizePixel      = 0
        p.CanvasSize           = UDim2.new(0,0,0,canvasH)
        p.ScrollBarThickness   = 6
        p.ScrollBarImageColor3 = C.sliderFill
        p.Visible              = idx == 1
        p.Parent               = contentArea
        return p
    else
        local p = mkFrame(contentArea, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), C.content, "Page"..idx)
        p.BackgroundTransparency = 1
        p.Visible = idx == 1
        return p
    end
end

pages[1] = makePage(1, 1600)  -- Combat (ScrollingFrame)
pages[2] = makePage(2, 1400)  -- Movement (ScrollingFrame)
pages[3] = makePage(3, nil)   -- Misc (Frame, будет своя ScrollingFrame внутри)
pages[4] = makePage(4, nil)   -- Log (Frame)

-- Misc как ScrollingFrame
pages[3]:Destroy()
local p3 = Instance.new("ScrollingFrame")
p3.Name = "Page3"; p3.Size = UDim2.new(1,0,1,0)
p3.BackgroundTransparency = 1; p3.BorderSizePixel = 0
p3.CanvasSize = UDim2.new(0,0,0,1200); p3.ScrollBarThickness = 6
p3.ScrollBarImageColor3 = C.sliderFill; p3.Visible = false
p3.Parent = contentArea
pages[3] = p3

-- Log как ScrollingFrame
pages[4]:Destroy()
local p4 = Instance.new("ScrollingFrame")
p4.Name = "Page4"; p4.Size = UDim2.new(1,0,1,0)
p4.BackgroundTransparency = 1; p4.BorderSizePixel = 0
p4.CanvasSize = UDim2.new(0,0,0,800); p4.ScrollBarThickness = 6
p4.ScrollBarImageColor3 = C.sliderFill; p4.Visible = false
p4.Parent = contentArea
pages[4] = p4

local function switchTab(idx)
    for i, b in ipairs(tabBtns) do
        b.BackgroundColor3 = (i==idx) and C.tabOn or C.tabOff
        b.TextColor3       = (i==idx) and C.text  or C.textDim
        if tabIndicators[i] then tabIndicators[i].Visible = (i==idx) end
    end
    for i, pg in ipairs(pages) do pg.Visible = (i==idx) end
end

for i = 1, 4 do
    local tb = mkBtn(tabPanel, TAB_ICONS[i],
        UDim2.new(0,38,0,32),
        UDim2.new(0,6, 0, 8+(i-1)*42),
        (i==1) and C.tabOn or C.tabOff,
        (i==1) and C.text  or C.textDim, 15)
    addCorner(tb, 7)
    tabBtns[i] = tb

    local ind = mkFrame(tabPanel, UDim2.new(0,3,0,18), UDim2.new(1,0,0,14+(i-1)*42), C.accent)
    addCorner(ind, 2); ind.Visible = (i==1); tabIndicators[i] = ind

    local tip = mkLabel(tabPanel, TAB_LABELS[i],
        UDim2.new(0,80,0,14), UDim2.new(1,3,0,17+(i-1)*42),
        C.textDim, Enum.TextXAlignment.Left, 9)
    tip.Visible = false
    tb.MouseEnter:Connect(function() tip.Visible = true  end)
    tb.MouseLeave:Connect(function() tip.Visible = false end)
    local idx = i
    tb.MouseButton1Click:Connect(function() switchTab(idx) end)
end

-- ─── WIDGET BUILDERS ─────────────────────────────────────────────────────────
-- funcRow: строка с ON/OFF кнопкой
local function funcRow(page, name, y, cb)
    local row = mkFrame(page, UDim2.new(1,-10,0,28), UDim2.new(0,PX,0,y), C.rowBg)
    addCorner(row, 6)
    local accent = mkFrame(row, UDim2.new(0,2,1,-8), UDim2.new(0,4,0,4), C.accentDim)
    addCorner(accent, 1)
    mkLabel(row, name, UDim2.new(1,-58,1,0), UDim2.new(0,12,0,0), C.text, Enum.TextXAlignment.Left, 11)
    local tog = mkBtn(row, "OFF", UDim2.new(0,42,0,18), UDim2.new(1,-46,0,5), C.togOff, C.textDim, 10)
    addCorner(tog, 4); addStroke(tog, C.borderDim, 1)
    local state = false
    tog.MouseEnter:Connect(function()
        if not state then tog.BackgroundColor3 = Color3.fromRGB(56,22,88) end
        row.BackgroundColor3 = C.rowHover
    end)
    tog.MouseLeave:Connect(function()
        if not state then tog.BackgroundColor3 = C.togOff end
        row.BackgroundColor3 = C.rowBg
    end)
    tog.MouseButton1Click:Connect(function()
        state = not state
        tog.Text             = state and "ON"   or "OFF"
        tog.BackgroundColor3 = state and C.togOn or C.togOff
        tog.TextColor3       = state and C.text  or C.textDim
        accent.BackgroundColor3 = state and C.accent or C.accentDim
        cb(state)
    end)
    return tog, accent
end

-- sectionLbl: заголовок секции
local function secLbl(page, text, y)
    local bar = mkFrame(page, UDim2.new(0,3,0,13), UDim2.new(0,PX,0,y+1), C.accent)
    addCorner(bar, 2)
    mkLabel(page, text, UDim2.new(1,-22,0,13), UDim2.new(0,PX+8,0,y), C.textDim, Enum.TextXAlignment.Left, 10)
end

-- sep: разделитель
local function sep(page, y)
    local sf = mkFrame(page, UDim2.new(1,-12,0,1), UDim2.new(0,PX,0,y), C.sep)
    local g  = Instance.new("UIGradient")
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.15,0),
        NumberSequenceKeypoint.new(0.85,0), NumberSequenceKeypoint.new(1,1),
    })
    g.Parent = sf
end

-- slider: ползунок
local function mkSlider(page, y, minV, maxV, defV, isFloat, onChange)
    local trackW = CONT_W - 20
    local track  = mkFrame(page, UDim2.new(0,trackW,0,5), UDim2.new(0,PX+2,0,y+1), C.sliderBg)
    addCorner(track, 3)
    local initRel = math.clamp((defV-minV)/(maxV-minV), 0, 1)
    local fill    = mkFrame(track, UDim2.new(initRel,0,1,0), UDim2.new(0,0,0,0), C.sliderFill)
    addCorner(fill, 3)
    mkFrame(fill, UDim2.new(0,9,0,9), UDim2.new(1,-5,0.5,-4), C.accent)
    local valLbl = mkLabel(page,
        isFloat and string.format("%.2f",defV) or tostring(math.floor(defV)),
        UDim2.new(0,40,0,13), UDim2.new(1,-46,0,y-9),
        C.textDim, Enum.TextXAlignment.Right, 10)
    local hb = mkBtn(track, "", UDim2.new(1,0,1,12), UDim2.new(0,0,0,-6), C.sliderBg, C.text, 1)
    hb.BackgroundTransparency = 1
    local dragging = false
    local function update(ix)
        local rel = math.clamp((ix - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        local val = isFloat and (minV + rel*(maxV-minV)) or math.floor(minV + rel*(maxV-minV))
        valLbl.Text = isFloat and string.format("%.2f",val) or tostring(val)
        fill.Size = UDim2.new(rel,0,1,0)
        onChange(val)
    end
    hb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; update(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            update(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- actionBtn: кнопка действия
local function actionBtn(page, y, label, cb)
    local btn = mkBtn(page, label, UDim2.new(1,-10,0,24), UDim2.new(0,PX,0,y), C.btnAction, C.text, 11)
    addCorner(btn, 5); addStroke(btn, C.border, 1)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.btnHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.btnAction end)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

-- infoLbl: информационная строка
local function infoLbl(page, text, y, col)
    return mkLabel(page, text, UDim2.new(1,-12,0,13), UDim2.new(0,PX,0,y),
        col or C.textDim, Enum.TextXAlignment.Left, 10)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PAGE 1: COMBAT
-- ═══════════════════════════════════════════════════════════════════════════
local p1 = pages[1]
local y1 = 8

-- ── ESP ──────────────────────────────────────────────────────────────────────
secLbl(p1, "ESP", y1); y1 += 18

funcRow(p1, "ESP — Enemy Highlight", y1, function(s)
    espEnabled = s
    addLog("ESP  ▸ " .. (s and "ENABLED" or "DISABLED"))
    if s then espRefreshAll() else espClearAll()
        if isTriggerBotEnabled then forceDisableTriggerBot("ESP выключен") end
    end
end)
y1 += 34

funcRow(p1, "Цвет по здоровью (зел→красн)", y1, function(s)
    espHealthColor = s
    addLog("ESP  ▸ healthColor=" .. tostring(s))
end)
y1 += 34

funcRow(p1, "Цвет по команде", y1, function(s)
    espShowTeamColor = s
end)
y1 += 34

funcRow(p1, "Показывать имена (billboard)", y1, function(s)
    espShowName = s
end)
y1 += 34

funcRow(p1, "Показывать HP / дистанцию", y1, function(s)
    espShowHealth = s; espShowDist = s
end)
y1 += 34

sep(p1, y1); y1 += 8

-- ── AIM ──────────────────────────────────────────────────────────────────────
secLbl(p1, "AIM", y1); y1 += 18

funcRow(p1, "Show FOV Square", y1, function(s)
    fovVisible = s; fovSquare.Visible = s
end)
y1 += 34

funcRow(p1, "Aim Assist  (удержи ПКМ)", y1, function(s)
    isAimAssistEnabled = s
end)
y1 += 34

funcRow(p1, "Silent Aim  (снап при выстреле)", y1, function(s)
    isSilentAimEnabled = s
end)
y1 += 34

funcRow(p1, "Allow Wallbang  (сквозь стены)", y1, function(s)
    allowWallbang = s
end)
y1 += 34

funcRow(p1, "Упреждение цели (Lead Shot)", y1, function(s)
    aimPrediction = s
    addLog("AIM  ▸ prediction=" .. tostring(s))
end)
y1 += 34

infoLbl(p1, "FOV Radius (px)", y1); y1 += 14
mkSlider(p1, y1, 40, 500, fovHalfSize, false, function(v) fovHalfSize = v end); y1 += 16

infoLbl(p1, "Aim Smoothness  (0=быстро · 100=плавно)", y1); y1 += 14
mkSlider(p1, y1, 0, 100, aimSmoothness*100, false, function(v) aimSmoothness = v/100 end); y1 += 16

infoLbl(p1, "Коэффициент упреждения", y1); y1 += 14
mkSlider(p1, y1, 1, 30, aimPredictMult*100, false, function(v) aimPredictMult = v/100 end); y1 += 16

sep(p1, y1); y1 += 8

-- ── TRIGGER BOT ───────────────────────────────────────────────────────────────
secLbl(p1, "TRIGGER BOT", y1); y1 += 18

do
    local row = mkFrame(p1, UDim2.new(1,-10,0,28), UDim2.new(0,PX,0,y1), C.rowBg)
    addCorner(row, 6)
    _tbAccent = mkFrame(row, UDim2.new(0,2,1,-8), UDim2.new(0,4,0,4), C.accentDim)
    addCorner(_tbAccent, 1)
    mkLabel(row, "Enable Trigger Bot", UDim2.new(1,-58,1,0), UDim2.new(0,12,0,0), C.text, Enum.TextXAlignment.Left, 11)
    _tbTog = mkBtn(row, "OFF", UDim2.new(0,42,0,18), UDim2.new(1,-46,0,5), C.togOff, C.textDim, 10)
    addCorner(_tbTog, 4); addStroke(_tbTog, C.borderDim, 1)
    _tbTog.MouseEnter:Connect(function()
        if not _tbState then _tbTog.BackgroundColor3 = Color3.fromRGB(56,22,88) end
        row.BackgroundColor3 = C.rowHover
    end)
    _tbTog.MouseLeave:Connect(function()
        if not _tbState then _tbTog.BackgroundColor3 = C.togOff end
        row.BackgroundColor3 = C.rowBg
    end)
    _tbTog.MouseButton1Click:Connect(function()
        if not _tbState and not espEnabled then
            addLog("BOT  ▸ ❌ сначала включи ESP!")
            _tbTog.BackgroundColor3 = Color3.fromRGB(160,20,20)
            task.delay(0.3, function()
                if not _tbState then _tbTog.BackgroundColor3 = C.togOff end
            end)
            return
        end
        _tbState                   = not _tbState
        isTriggerBotEnabled        = _tbState
        _tbTog.Text                = _tbState and "ON"   or "OFF"
        _tbTog.BackgroundColor3    = _tbState and C.togOn or C.togOff
        _tbTog.TextColor3          = _tbState and C.text  or C.textDim
        _tbAccent.BackgroundColor3 = _tbState and C.accent or C.accentDim
        addLog("BOT  ▸ " .. (_tbState and "ENABLED" or "DISABLED"))
        if _tbState then lastTriggerFireAt = 0 end
    end)
end
y1 += 34

infoLbl(p1, "Trigger Cooldown (ms)", y1); y1 += 14
mkSlider(p1, y1, 20, 500, triggerCooldownSec*1000, false, function(v) triggerCooldownSec = v/1000 end); y1 += 16

sep(p1, y1); y1 += 8

-- ── HITBOX EXPANDER ───────────────────────────────────────────────────────────
secLbl(p1, "HITBOX EXPANDER", y1); y1 += 18

funcRow(p1, "Expand Enemy Hitboxes", y1, function(s) setHitbox(s) end)
y1 += 34

infoLbl(p1, "Размер хитбокса (studs)", y1); y1 += 14
mkSlider(p1, y1, 2, 30, hitboxSize, false, function(v)
    hitboxSize = v
    if hitboxEnabled then refreshHitboxSize() end
end)
y1 += 16

p1.CanvasSize = UDim2.new(0,0,0,y1+20)

-- ═══════════════════════════════════════════════════════════════════════════
-- PAGE 2: MOVEMENT
-- ═══════════════════════════════════════════════════════════════════════════
local p2 = pages[2]
local y2 = 8

secLbl(p2, "ДВИЖЕНИЕ", y2); y2 += 18

funcRow(p2, "Custom WalkSpeed", y2, function(s)
    speedEnabled = s
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = s and speedValue or BASE_SPEED end
end)
y2 += 34

infoLbl(p2, "Walk Speed (studs/s)", y2); y2 += 14
mkSlider(p2, y2, 1, 500, speedValue, false, function(v) speedValue = v end); y2 += 16

funcRow(p2, "NoClip  (проходить сквозь стены)", y2, function(s)
    noClipEnabled = s
    if s then updateNoClipCache() else stopNoClip() end
end)
y2 += 34

funcRow(p2, "Infinite Jump  (Space в воздухе)", y2, function(s)
    infiniteJumpEnabled = s
    addLog("IJUMP▸ " .. (s and "ON" or "OFF"))
end)
y2 += 34

funcRow(p2, "Jump Boost  (импульс вверх)", y2, function(s)
    jumpBoostEnabled = s
    addLog("JBOOST▸ " .. (s and "ON  force=" .. jumpBoostForce or "OFF"))
end)
y2 += 34

infoLbl(p2, "Jump Boost Force", y2); y2 += 14
mkSlider(p2, y2, 10, 300, jumpBoostForce, false, function(v) jumpBoostForce = v end); y2 += 16

sep(p2, y2); y2 += 8
secLbl(p2, "ПОЛЁТ", y2); y2 += 18

funcRow(p2, "Fly  (WASD+Space/Shift)", y2, function(s)
    flyEnabled = s
    if s then startFly() else stopFly() end
end)
y2 += 34

funcRow(p2, "Инерция при полёте", y2, function(s)
    flyInertia = s
end)
y2 += 34

infoLbl(p2, "Fly Speed (studs/s)", y2); y2 += 14
mkSlider(p2, y2, 1, 1500, flySpeed, false, function(v) flySpeed = v end); y2 += 16

infoLbl(p2, "Инерция (затухание)  0=скользко · 99=жёсткий стоп", y2); y2 += 14
mkSlider(p2, y2, 1, 99, flyInertiaDecay*100, false, function(v) flyInertiaDecay = v/100 end); y2 += 16

sep(p2, y2); y2 += 8
secLbl(p2, "СПИН / ПРОЧЕЕ", y2); y2 += 18

funcRow(p2, "Spinbot", y2, function(s) spinEnabled = s end)
y2 += 34

infoLbl(p2, "Spin Speed (deg/s)", y2); y2 += 14
mkSlider(p2, y2, 60, 1800, spinSpeedDegPerSec, false, function(v) spinSpeedDegPerSec = v end); y2 += 16

infoLbl(p2, "Ось вращения", y2)
do
    local axes = {"X","Y","Z"}
    local axBtns = {}
    local btnW = math.floor((CONT_W-14)/3)
    for i, ax in ipairs(axes) do
        local btn = mkBtn(p2, ax,
            UDim2.new(0,btnW,0,22),
            UDim2.new(0,PX+(i-1)*(btnW+4),0,y2+16),
            (ax=="Y") and C.tabOn or C.tabOff,
            (ax=="Y") and C.text  or C.textDim, 11)
        addCorner(btn, 5); addStroke(btn, C.borderDim, 1)
        axBtns[ax] = btn
        btn.MouseButton1Click:Connect(function()
            spinAxis = ax
            for _, b in pairs(axBtns) do
                b.BackgroundColor3 = C.tabOff; b.TextColor3 = C.textDim
            end
            btn.BackgroundColor3 = C.tabOn; btn.TextColor3 = C.text
            addLog("SPIN ▸ ось=" .. ax)
        end)
    end
end
y2 += 46

sep(p2, y2); y2 += 8
secLbl(p2, "NDS — УПРАВЛЕНИЕ ОБЪЕКТАМИ", y2); y2 += 20

-- Кнопки режима NDS
do
    local btnW = math.floor((CONT_W-14)/4)
    local modeNames = {"Sphere","Disk","Cursor","Vortex"}
    local modeIcons = {"⬤","◆","◎","🌀"}
    local ndsModeBtns = {}
    local function selectMode(idx)
        ndsMode = idx
        for i, b in ipairs(ndsModeBtns) do
            b.BackgroundColor3 = (i==idx) and C.tabOn or C.tabOff
            b.TextColor3       = (i==idx) and C.text  or C.textDim
        end
        addLog("NDS  ▸ режим → " .. modeNames[idx])
    end
    for i = 1, 4 do
        local mb = mkBtn(p2, modeIcons[i],
            UDim2.new(0,btnW,0,22),
            UDim2.new(0,PX+(i-1)*(btnW+3),0,y2),
            (i==1) and C.tabOn or C.tabOff,
            (i==1) and C.text  or C.textDim, 13)
        addCorner(mb, 5); addStroke(mb, C.borderDim, 1)
        ndsModeBtns[i] = mb
        local mi = i
        mb.MouseButton1Click:Connect(function() selectMode(mi) end)
    end
end
y2 += 28

ndsCountLabel = infoLbl(p2, "⚫ NDS отключён", y2, C.textDim); y2 += 22

funcRow(p2, "Enable NDS", y2, function(s)
    ndsEnabled = s
    if s then startNDS() else stopNDS() end
end)
y2 += 34

do
    local row = mkFrame(p2, UDim2.new(1,-10,0,28), UDim2.new(0,PX,0,y2), C.rowBg)
    addCorner(row,6)
    mkLabel(row, "Авто-захват новых объектов", UDim2.new(1,-58,1,0), UDim2.new(0,12,0,0), C.text, Enum.TextXAlignment.Left, 11)
    ndsAutoTogBtn = mkBtn(row, "ON", UDim2.new(0,42,0,18), UDim2.new(1,-46,0,5), C.togOn, C.text, 10)
    addCorner(ndsAutoTogBtn,4); addStroke(ndsAutoTogBtn, C.borderDim, 1)
    ndsAutoTogBtn.MouseButton1Click:Connect(function()
        ndsAutoScan = not ndsAutoScan
        ndsAutoTogBtn.Text             = ndsAutoScan and "ON"  or "OFF"
        ndsAutoTogBtn.BackgroundColor3 = ndsAutoScan and C.togOn or C.togOff
        ndsAutoTogBtn.TextColor3       = ndsAutoScan and C.text or C.textDim
        addLog("NDS  ▸ авто-захват " .. (ndsAutoScan and "ВКЛ" or "ВЫКЛ"))
    end)
end
y2 += 34

infoLbl(p2, "Дистанция от игрока (studs)", y2); y2 += 14
mkSlider(p2, y2, 1, 500, ndsDistance, false, function(v) ndsDistance = v end); y2 += 16
infoLbl(p2, "Скорость вращения (deg/s)", y2); y2 += 14
mkSlider(p2, y2, 1, 3000, ndsRotSpeed, false, function(v) ndsRotSpeed = v end); y2 += 16
infoLbl(p2, "Жёсткость удержания", y2); y2 += 14
mkSlider(p2, y2, 1, 1000, ndsSpeed, false, function(v) ndsSpeed = v end); y2 += 16
infoLbl(p2, "Скорость откидывания при выкл", y2); y2 += 14
mkSlider(p2, y2, 10, 500, ndsScatterSpeed, false, function(v) ndsScatterSpeed = v end); y2 += 16
infoLbl(p2, "Лимит захвата  10–1000", y2); y2 += 14
mkSlider(p2, y2, 10, 1000, ndsMaxCapture, false, function(v) ndsMaxCapture = v end); y2 += 16

do
    local halfW = math.floor((CONT_W-14)/2)
    local rescanBtn = mkBtn(p2, "🔄 Пересканировать",
        UDim2.new(0,halfW,0,24), UDim2.new(0,PX,0,y2), C.btnAction, C.text, 10)
    addCorner(rescanBtn,5); addStroke(rescanBtn, C.border, 1)
    rescanBtn.MouseEnter:Connect(function() rescanBtn.BackgroundColor3 = C.btnHover end)
    rescanBtn.MouseLeave:Connect(function() rescanBtn.BackgroundColor3 = C.btnAction end)
    rescanBtn.MouseButton1Click:Connect(function()
        if ndsEnabled then
            local c = 0; local a = 0  -- будет работать если ndsCleanDead/ndsScan глобальны
            addLog("NDS  ▸ ручной скан  итого=" .. #ndsObjects)
        else addLog("NDS  ▸ сначала включи NDS") end
    end)
    local scatterBtn = mkBtn(p2, "💥 Scatter!",
        UDim2.new(0,halfW,0,24), UDim2.new(0,PX+halfW+4,0,y2),
        Color3.fromRGB(100,20,0), C.text, 10)
    addCorner(scatterBtn,5); addStroke(scatterBtn, Color3.fromRGB(180,60,20), 1)
    scatterBtn.MouseEnter:Connect(function() scatterBtn.BackgroundColor3 = Color3.fromRGB(160,40,0) end)
    scatterBtn.MouseLeave:Connect(function() scatterBtn.BackgroundColor3 = Color3.fromRGB(100,20,0) end)
    scatterBtn.MouseButton1Click:Connect(function()
        if ndsEnabled and #ndsObjects > 0 then ndsScatterAll() end
    end)
end
y2 += 32

sep(p2, y2); y2 += 8
secLbl(p2, "ТЕЛЕПОРТ", y2); y2 += 18

funcRow(p2, "Teleport by Click  (Ctrl+ЛКМ)", y2, function(s) teleportEnabled = s end)
y2 += 34

infoLbl(p2, "Teleport to Player by Nick", y2); y2 += 16
local nameBox = mkTextBox(p2, UDim2.new(1,-12,0,24), UDim2.new(0,PX,0,y2), "Ник игрока...")
y2 += 30
nameBox:GetPropertyChangedSignal("Text"):Connect(function() targetPlayerName = nameBox.Text end)

actionBtn(p2, y2, "▶  Teleport to Player", function() tpToPlayer(targetPlayerName) end)
y2 += 30

do
    local halfW = math.floor((CONT_W-14)/2)
    local loopBtn = mkBtn(p2, "🔁 Loop TP",
        UDim2.new(0,halfW,0,22), UDim2.new(0,PX,0,y2), C.btnAction, C.text, 10)
    addCorner(loopBtn,5); addStroke(loopBtn, C.border, 1)
    local loopState = false
    loopBtn.MouseButton1Click:Connect(function()
        loopState = not loopState
        loopBtn.Text             = loopState and "⏹ Stop Loop" or "🔁 Loop TP"
        loopBtn.BackgroundColor3 = loopState and C.togOn or C.btnAction
        if loopState then startLoopTP(targetPlayerName) else stopLoopTP() end
    end)
    local backBtn = mkBtn(p2, "◀ Назад",
        UDim2.new(0,halfW,0,22), UDim2.new(0,PX+halfW+4,0,y2), C.tabOff, C.text, 10)
    addCorner(backBtn,5); addStroke(backBtn, C.borderDim, 1)
    backBtn.MouseButton1Click:Connect(function() tpGoBack() end)
end
y2 += 30

actionBtn(p2, y2, "📌 Сохранить позицию", function()
    tpSavePoint("point_" .. (#tpHistory+1))
end)
y2 += 30

p2.CanvasSize = UDim2.new(0,0,0,y2+20)

-- ═══════════════════════════════════════════════════════════════════════════
-- PAGE 3: MISC
-- ═══════════════════════════════════════════════════════════════════════════
local p3 = pages[3]
local y3 = 8

secLbl(p3, "MISC", y3); y3 += 18

funcRow(p3, "Anti-AFK", y3, function(s) setAntiAfk(s) end); y3 += 34
funcRow(p3, "Chat Spy  (логировать чат)", y3, function(s) setChatSpy(s) end); y3 += 34

sep(p3, y3); y3 += 8
secLbl(p3, "VISUALS", y3); y3 += 18

funcRow(p3, "Убрать туман / дым", y3, function(s)
    visualFogEnabled = s
    if s then applyNoFog() else restoreFog() end
end)
y3 += 34

funcRow(p3, "Максимальная яркость", y3, function(s)
    visualBrightEnabled = s; applyBrightness(s)
end)
y3 += 34

infoLbl(p3, "Уровень яркости  1–10", y3); y3 += 14
mkSlider(p3, y3, 1, 10, brightnessValue, false, function(v)
    brightnessValue = v
    if visualBrightEnabled then pcall(function() Lighting.Brightness = v end) end
end)
y3 += 16

funcRow(p3, "Зафиксировать время суток", y3, function(s)
    visualTimeEnabled = s; applyTimeOfDay(s)
end)
y3 += 34

infoLbl(p3, "Время суток (0–24)", y3); y3 += 14
mkSlider(p3, y3, 0, 24, timeOfDayHour, false, function(v)
    timeOfDayHour = v
    if visualTimeEnabled then setTimeOfDay(v) end
end)
y3 += 16

funcRow(p3, "Прозрачность других игроков", y3, function(s)
    visualChamsEnabled = s; applyChams(s)
end)
y3 += 34

funcRow(p3, "Кроссхейр", y3, function(s)
    visualCrosshairOn = s; applyCrosshair(s)
end)
y3 += 34

sep(p3, y3); y3 += 8
secLbl(p3, "ГРАВИТАЦИЯ", y3); y3 += 18

funcRow(p3, "Изменить гравитацию", y3, function(s)
    gravityEnabled = s
    if s then applyGravity() else resetGravity() end
end)
y3 += 34

infoLbl(p3, "Gravity (stud/s²)  по умолчанию 196.2", y3); y3 += 14
mkSlider(p3, y3, 10, 800, gravityValue, false, function(v)
    gravityValue = v
    if gravityEnabled then pcall(function() workspace.Gravity = v end) end
end)
y3 += 16

sep(p3, y3); y3 += 8
secLbl(p3, "KILL AURA", y3); y3 += 18

funcRow(p3, "Kill Aura  (Tool:Activate в радиусе)", y3, function(s) setKillAura(s) end)
y3 += 34

infoLbl(p3, "Радиус аура (studs)", y3); y3 += 14
mkSlider(p3, y3, 3, 60, killAuraRadius, false, function(v)
    killAuraRadius = v
    addLog("AURA ▸ R=" .. v)
end)
y3 += 16

infoLbl(p3, "Частота атак (сек)", y3); y3 += 14
mkSlider(p3, y3, 5, 100, killAuraRate*100, false, function(v)
    killAuraRate = v/100
end)
y3 += 16

sep(p3, y3); y3 += 8

actionBtn(p3, y3, "📊 Server Info (в лог)", function()
    printServerInfo()
    switchTab(4)  -- переходим на вкладку Log
end)
y3 += 30

actionBtn(p3, y3, "🔄 Auto-Rejoin", function() autoRejoin() end)
y3 += 30

p3.CanvasSize = UDim2.new(0,0,0,y3+20)

-- ═══════════════════════════════════════════════════════════════════════════
-- PAGE 4: LOG
-- ═══════════════════════════════════════════════════════════════════════════
local p4 = pages[4]

local logHdr = mkFrame(p4, UDim2.new(1,-8,0,30), UDim2.new(0,4,0,4), C.rowBg)
addCorner(logHdr,6); addStroke(logHdr, C.borderDim, 1)
mkLabel(logHdr, "📋  ESP / System Logger",
    UDim2.new(1,-70,1,0), UDim2.new(0,10,0,0), C.accent, Enum.TextXAlignment.Left, 11)

local clearLogBtn = mkBtn(logHdr, "🗑 Clear",
    UDim2.new(0,56,0,20), UDim2.new(1,-60,0,5), C.btnAction, C.text, 10)
addCorner(clearLogBtn,5)
clearLogBtn.MouseEnter:Connect(function() clearLogBtn.BackgroundColor3 = C.btnHover end)
clearLogBtn.MouseLeave:Connect(function() clearLogBtn.BackgroundColor3 = C.btnAction end)
clearLogBtn.MouseButton1Click:Connect(function() clearLog() end)

logLabel = Instance.new("TextBox")
logLabel.Name                   = "LogText"
logLabel.Size                   = UDim2.new(1,-10,0,730)
logLabel.Position               = UDim2.new(0,5,0,40)
logLabel.BackgroundColor3       = C.logBg
logLabel.BackgroundTransparency = 0.08
logLabel.BorderSizePixel        = 0
logLabel.Text                   = "— No logs yet —"
logLabel.TextColor3             = C.logText
logLabel.Font                   = Enum.Font.Code
logLabel.TextSize               = 10
logLabel.TextXAlignment         = Enum.TextXAlignment.Left
logLabel.TextYAlignment         = Enum.TextYAlignment.Top
logLabel.TextWrapped            = true
logLabel.RichText               = false
logLabel.ClearTextOnFocus       = false
logLabel.MultiLine              = true
logLabel.Parent                 = p4
addCorner(logLabel,5); addStroke(logLabel, C.borderDim, 1)
logLabel.FocusLost:Connect(function() logDirty = true end)

-- Авто-обновление лога каждые 0.5с
task.spawn(function()
    while true do
        task.wait(0.5)
        if logDirty and logLabel then
            local n = #logBuffer
            logLabel.Text = n > 0 and table.concat(logBuffer, "\n") or "— No logs yet —"
            local lineH  = 13
            local totalH = math.max(n*lineH + 50, 200)
            p4.CanvasSize = UDim2.new(0,0,0,totalH)
            logLabel.Size = UDim2.new(1,-10,0,math.max(totalH-44,100))
            if p4.AbsoluteSize.Y > 0 then
                p4.CanvasPosition = Vector2.new(0, math.max(0, totalH-p4.AbsoluteSize.Y))
            end
            logDirty = false
        end
    end
end)

-- ─── ОТКРЫТИЕ / СВОРАЧИВАНИЕ / ПЕРЕТАСКИВАНИЕ ────────────────────────────────
openBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

local minimized = false
local fullSize  = UDim2.new(0,MENU_W,0,MENU_H)
local miniSize  = UDim2.new(0,MENU_W,0,BAR_H)

minBtn.MouseButton1Click:Connect(function()
    minimized           = not minimized
    main.Size           = minimized and miniSize or fullSize
    contentArea.Visible = not minimized
    tabPanel.Visible    = not minimized
    minBtn.Text         = minimized and "□" or "—"
end)

local dragActive = false
local dragStart  = Vector2.zero
local posStart   = Vector2.zero

topBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = true
        dragStart  = Vector2.new(inp.Position.X, inp.Position.Y)
        posStart   = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
    end
end)
topBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragActive = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not dragActive then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local d = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
    main.Position = UDim2.new(0, posStart.X+d.X, 0, posStart.Y+d.Y)
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragActive = false end
end)

-- Хоткей: RightAlt = показать/скрыть меню
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightAlt then
        main.Visible = not main.Visible
    end
end)

-- ─── RESPAWN: сброс UI-зависимых вещей ───────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    flyBodyVelocity    = nil
    flyBodyGyro        = nil
    flyCanCollideParts = {}
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end

    task.wait(0.4)
    if flyEnabled     then startFly()         end
    updateNoClipCache()

    local hum = char:FindFirstChildOfClass("Humanoid")
    if speedEnabled and hum then hum.WalkSpeed = speedValue end

    char.ChildAdded:Connect(function(d)
        if d:IsA("Tool") then bindTool(d) end
    end)
    bindAllTools()

    task.delay(1, espRefreshAll)

    if ndsEnabled then
        task.wait(0.6)
        stopNDS(); ndsEnabled = true; startNDS()
    end
end)

if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(d)
        if d:IsA("Tool") then bindTool(d) end
    end)
    task.defer(bindAllTools)
    task.defer(updateNoClipCache)
end

LocalPlayer.Backpack.ChildAdded:Connect(function(d)
    if d:IsA("Tool") then bindTool(d) end
end)

startNoClip()

addLog("GUI  ▸ gui.lua загружен  (4 вкладки: Combat/Movement/Misc/Log)")
addLog("GUI  ▸ хоткей: RightAlt = показать/скрыть меню")
