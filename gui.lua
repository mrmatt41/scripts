-- ═══════════════════════════════════════════════════════════════════
--  gui.lua  —  Menu V1  |  Интерфейс v2
--  НОВОЕ: статус-бар, счётчики на вкладках, поиск, запоминание
--         вкладки, 3 цветовые темы (Purple / Blue / Red)
-- ═══════════════════════════════════════════════════════════════════

-- ─── ТЕМЫ ────────────────────────────────────────────────────────────────────
local THEMES = {
    {   -- 1: Purple (оригинал)
        name       = "Purple",
        bar        = Color3.fromRGB(65,   0, 135),
        tabOn      = Color3.fromRGB(108,  0, 210),
        tabOff     = Color3.fromRGB(35,  12,  60),
        togOn      = Color3.fromRGB(118,  0, 228),
        sliderFill = Color3.fromRGB(138, 18, 252),
        border     = Color3.fromRGB(98,  28, 198),
        accent     = Color3.fromRGB(162, 42, 255),
        accentDim  = Color3.fromRGB(100, 20, 170),
        toggleBtn  = Color3.fromRGB(48,   0, 105),
        btnAction  = Color3.fromRGB(70,   0, 145),
        btnHover   = Color3.fromRGB(94,   0, 182),
        barGrad0   = Color3.fromRGB(110, 12, 205),
        barGrad1   = Color3.fromRGB(72,   0, 145),
        barGrad2   = Color3.fromRGB(42,   0,  92),
    },
    {   -- 2: Blue
        name       = "Blue",
        bar        = Color3.fromRGB(0,  40, 120),
        tabOn      = Color3.fromRGB(0,  90, 220),
        tabOff     = Color3.fromRGB(10, 25,  70),
        togOn      = Color3.fromRGB(0, 110, 255),
        sliderFill = Color3.fromRGB(30, 140, 255),
        border     = Color3.fromRGB(30, 80, 200),
        accent     = Color3.fromRGB(60, 160, 255),
        accentDim  = Color3.fromRGB(20,  70, 170),
        toggleBtn  = Color3.fromRGB(0,  30,  95),
        btnAction  = Color3.fromRGB(0,  60, 160),
        btnHover   = Color3.fromRGB(0,  80, 200),
        barGrad0   = Color3.fromRGB(0,  70, 200),
        barGrad1   = Color3.fromRGB(0,  50, 140),
        barGrad2   = Color3.fromRGB(0,  30,  90),
    },
    {   -- 3: Red
        name       = "Red",
        bar        = Color3.fromRGB(100,  8,  8),
        tabOn      = Color3.fromRGB(200, 20, 20),
        tabOff     = Color3.fromRGB(55,  10, 10),
        togOn      = Color3.fromRGB(220, 30, 30),
        sliderFill = Color3.fromRGB(240, 60, 60),
        border     = Color3.fromRGB(180, 40, 40),
        accent     = Color3.fromRGB(255, 80, 80),
        accentDim  = Color3.fromRGB(160, 30, 30),
        toggleBtn  = Color3.fromRGB(80,   8,  8),
        btnAction  = Color3.fromRGB(130, 15, 15),
        btnHover   = Color3.fromRGB(170, 25, 25),
        barGrad0   = Color3.fromRGB(190, 20, 20),
        barGrad1   = Color3.fromRGB(130, 12, 12),
        barGrad2   = Color3.fromRGB(80,   8,  8),
    },
}
local currentThemeIdx = 1

-- Применяет тему к C-таблице и обновляет ключевые UI-элементы
local _themeElements = {}   -- { element, property, themeKey }
local function applyTheme(t)
    C.bar        = t.bar
    C.tabOn      = t.tabOn
    C.tabOff     = t.tabOff
    C.togOn      = t.togOn
    C.sliderFill = t.sliderFill
    C.border     = t.border
    C.accent     = t.accent
    C.accentDim  = t.accentDim
    C.toggleBtn  = t.toggleBtn
    C.btnAction  = t.btnAction
    C.btnHover   = t.btnHover
    for _, e in ipairs(_themeElements) do
        pcall(function()
            e.inst[e.prop] = t[e.key]
        end)
    end
end

local function trackTheme(inst, prop, key)
    _themeElements[#_themeElements+1] = { inst=inst, prop=prop, key=key }
end

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
local MENU_W    = 340
local MENU_H    = 586
local BAR_H     = 34
local STATUS_H  = 22     -- статус-бар снизу
local SEARCH_H  = 30     -- строка поиска
local TAB_W     = 50
local CONT_W    = MENU_W - TAB_W - 2
local CONT_H    = MENU_H - BAR_H - STATUS_H
local PX        = 6

-- ─── СИСТЕМА ПОИСКА И СЧЁТЧИКОВ ──────────────────────────────────────────────
local allRows     = {}          -- { frame, name, tabIdx } — каждый funcRow
local tabCounts   = {0,0,0,0}   -- сколько фич включено на каждой вкладке
local tabBadges   = {}          -- TextLabel-значки на кнопках вкладок
local statusLabel = nil         -- строка статуса внизу

-- Список активных фич для статус-бара
local activeFeatureNames = {}   -- { [key] = "ESP" }

local function updateStatusBar()
    if not statusLabel then return end
    local parts = {}
    for _, v in pairs(activeFeatureNames) do
        parts[#parts+1] = v
    end
    table.sort(parts)
    if #parts == 0 then
        statusLabel.Text      = "Нет активных функций"
        statusLabel.TextColor3 = C.textDim
    else
        statusLabel.Text      = table.concat(parts, "  ·  ")
        statusLabel.TextColor3 = C.accent
    end
end

local function updateTabBadge(tabIdx)
    local badge = tabBadges[tabIdx]
    if not badge then return end
    local cnt = tabCounts[tabIdx] or 0
    badge.Visible = cnt > 0
    badge.Text    = tostring(cnt)
end

-- Вызывается из funcRow при изменении состояния
local function onFeatureToggle(tabIdx, name, state, featureKey)
    tabCounts[tabIdx] = (tabCounts[tabIdx] or 0) + (state and 1 or -1)
    if tabCounts[tabIdx] < 0 then tabCounts[tabIdx] = 0 end
    updateTabBadge(tabIdx)

    if state then
        activeFeatureNames[featureKey] = name
    else
        activeFeatureNames[featureKey] = nil
    end
    updateStatusBar()
end

-- Фильтрация поиска
local searchQuery = ""
local function applySearch(query)
    searchQuery = query:lower()
    for _, r in ipairs(allRows) do
        if searchQuery == "" then
            r.frame.Visible = true
        else
            r.frame.Visible = r.name:find(searchQuery, 1, true) ~= nil
        end
    end
end

-- ─── SCREEN GUI ──────────────────────────────────────────────────────────────
local Gui          = Instance.new("ScreenGui")
Gui.Name           = "MenuV1_UI"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset = false
Gui.Parent         = PlayerGui

fovSquare                  = Instance.new("Frame")
fovSquare.Name             = "FOVSquare"
fovSquare.Size             = UDim2.fromOffset(fovHalfSize*2, fovHalfSize*2)
fovSquare.BackgroundTransparency = 0.90
fovSquare.BackgroundColor3 = Color3.fromRGB(80,20,130)
fovSquare.BorderSizePixel  = 0
fovSquare.Visible          = false
fovSquare.Parent           = Gui
addStroke(fovSquare, Color3.fromRGB(180,60,255), 1.5)
addCorner(fovSquare, 3)

local openBtn = mkBtn(Gui, "◈  MENU",
    UDim2.new(0,90,0,28), UDim2.new(0,10,0,148),
    C.toggleBtn, C.text, 12)
addCorner(openBtn, 6)
addStroke(openBtn, C.border, 1.5)
do
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(88,10,172)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(34,0,80)),
    })
    g.Rotation = 90; g.Parent = openBtn
end

-- Главное окно
local main = mkFrame(Gui,
    UDim2.new(0,MENU_W,0,MENU_H), UDim2.new(0,10,0,184),
    C.bg, "Main")
main.Visible = false
addCorner(main, 10)
addStroke(main, C.border, 1.5)

-- Топ-бар
local topBar = mkFrame(main,
    UDim2.new(1,0,0,BAR_H), UDim2.new(0,0,0,0),
    C.bar, "TopBar")
addCorner(topBar, 10)
mkFrame(topBar, UDim2.new(1,0,0,10), UDim2.new(0,0,1,-10), C.bar, "BarFix")
trackTheme(topBar, "BackgroundColor3", "bar")

local _topBarGrad = Instance.new("UIGradient")
_topBarGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(110,12,205)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(72,0,145)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(42,0,92)),
})
_topBarGrad.Rotation = 0; _topBarGrad.Parent = topBar

local dot = mkFrame(topBar, UDim2.new(0,8,0,8), UDim2.new(0,10,0,13), C.accent, "Dot")
addCorner(dot, 5)
trackTheme(dot, "BackgroundColor3", "accent")

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
    UDim2.new(0,TAB_W,0,CONT_H), UDim2.new(0,0,0,BAR_H),
    C.tabBg, "TabPanel")
mkFrame(main, UDim2.new(0,1,0,CONT_H), UDim2.new(0,TAB_W,0,BAR_H), C.borderDim, "Div")

-- Область контента (без статус-бара и поиска)
local contentArea = mkFrame(main,
    UDim2.new(0,MENU_W-TAB_W-2, 0, CONT_H),
    UDim2.new(0,TAB_W+2, 0,BAR_H),
    C.content, "Content")

-- ─── СТРОКА ПОИСКА ───────────────────────────────────────────────────────────
local searchBar = mkFrame(contentArea,
    UDim2.new(1,-8,0,SEARCH_H-4),
    UDim2.new(0,4,0,3),
    C.inputBg, "SearchBar")
addCorner(searchBar, 5)
addStroke(searchBar, C.borderDim, 1)

mkLabel(searchBar, "🔍",
    UDim2.new(0,18,1,0), UDim2.new(0,4,0,0),
    C.textDim, Enum.TextXAlignment.Left, 11)

local searchBox         = Instance.new("TextBox")
searchBox.Size          = UDim2.new(1,-28,1,-4)
searchBox.Position      = UDim2.new(0,22,0,2)
searchBox.BackgroundTransparency = 1
searchBox.Text          = ""
searchBox.PlaceholderText = "Поиск функций..."
searchBox.PlaceholderColor3 = C.textDim
searchBox.TextColor3    = C.text
searchBox.Font          = Enum.Font.Gotham
searchBox.TextSize      = 10
searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent        = searchBar

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    applySearch(searchBox.Text)
end)

-- ─── СТРАНИЦЫ (смещены вниз на SEARCH_H) ─────────────────────────────────────
local PAGE_TOP = SEARCH_H
local PAGE_H   = CONT_H - PAGE_TOP

local pages        = {}
local tabBtns      = {}
local tabIndicators= {}

local function makeScrollPage(idx, canvasH, visible)
    local p = Instance.new("ScrollingFrame")
    p.Name                   = "Page"..idx
    p.Size                   = UDim2.new(1,0,0,PAGE_H)
    p.Position               = UDim2.new(0,0,0,PAGE_TOP)
    p.BackgroundTransparency = 1
    p.BorderSizePixel        = 0
    p.CanvasSize             = UDim2.new(0,0,0,canvasH)
    p.ScrollBarThickness     = 6
    p.ScrollBarImageColor3   = C.sliderFill
    p.Visible                = visible
    p.Parent                 = contentArea
    return p
end

pages[1] = makeScrollPage(1, 1600, true)
pages[2] = makeScrollPage(2, 1500, false)
pages[3] = makeScrollPage(3, 1200, false)
pages[4] = makeScrollPage(4, 800,  false)

-- ─── ЗАПОМИНАНИЕ ВКЛАДКИ ─────────────────────────────────────────────────────
local lastTabIdx = 1

local function switchTab(idx)
    lastTabIdx = idx
    for i, b in ipairs(tabBtns) do
        b.BackgroundColor3 = (i==idx) and C.tabOn or C.tabOff
        b.TextColor3       = (i==idx) and C.text  or C.textDim
        if tabIndicators[i] then tabIndicators[i].Visible = (i==idx) end
    end
    for i, pg in ipairs(pages) do pg.Visible = (i==idx) end
    -- Сбрасываем поиск при смене вкладки (опционально)
    -- searchBox.Text = ""; applySearch("")
end

-- ─── ВКЛАДКИ + ЗНАЧКИ ────────────────────────────────────────────────────────
local TAB_ICONS  = { "⚔", "🏃", "★", "📋" }
local TAB_LABELS = { "Combat", "Movement", "Misc", "Log" }

for i = 1, 4 do
    local tb = mkBtn(tabPanel, TAB_ICONS[i],
        UDim2.new(0,38,0,32), UDim2.new(0,6,0,8+(i-1)*42),
        (i==1) and C.tabOn or C.tabOff,
        (i==1) and C.text  or C.textDim, 15)
    addCorner(tb, 7)
    tabBtns[i] = tb
    trackTheme(tb, "BackgroundColor3", (i==1) and "tabOn" or "tabOff")

    local ind = mkFrame(tabPanel, UDim2.new(0,3,0,18), UDim2.new(1,0,0,14+(i-1)*42), C.accent)
    addCorner(ind, 2); ind.Visible = (i==1); tabIndicators[i] = ind
    trackTheme(ind, "BackgroundColor3", "accent")

    local tip = mkLabel(tabPanel, TAB_LABELS[i],
        UDim2.new(0,80,0,14), UDim2.new(1,3,0,17+(i-1)*42),
        C.textDim, Enum.TextXAlignment.Left, 9)
    tip.Visible = false
    tb.MouseEnter:Connect(function() tip.Visible = true  end)
    tb.MouseLeave:Connect(function() tip.Visible = false end)

    -- Значок-счётчик активных фич на вкладке
    local badge = mkLabel(tb, "0",
        UDim2.new(0,14,0,10), UDim2.new(1,-14,0,0),
        C.accent, Enum.TextXAlignment.Center, 8)
    badge.BackgroundColor3 = Color3.fromRGB(0,0,0)
    badge.BackgroundTransparency = 0.4
    badge.Visible = false
    addCorner(badge, 3)
    tabBadges[i] = badge

    local idx = i
    tb.MouseButton1Click:Connect(function() switchTab(idx) end)
end

-- ─── СТАТУС-БАР ──────────────────────────────────────────────────────────────
local statusBarFrame = mkFrame(main,
    UDim2.new(1,-2,0,STATUS_H),
    UDim2.new(0,1,1,-STATUS_H-1),
    Color3.fromRGB(8,3,16), "StatusBar")
addStroke(statusBarFrame, C.borderDim, 1)

statusLabel = mkLabel(statusBarFrame,
    "Нет активных функций",
    UDim2.new(1,-8,1,0), UDim2.new(0,4,0,0),
    C.textDim, Enum.TextXAlignment.Left, 9)

-- Пинг в правом углу статус-бара (обновляется каждые 2 сек)
local pingLabel = mkLabel(statusBarFrame,
    "-- ms",
    UDim2.new(0,40,1,0), UDim2.new(1,-44,0,0),
    C.textDim, Enum.TextXAlignment.Right, 9)

task.spawn(function()
    while true do
        task.wait(2)
        local ping = math.floor(LocalPlayer.NetworkPing * 1000)
        local col = ping < 80 and C.green or (ping < 150 and C.orange or C.red)
        pingLabel.Text       = ping .. " ms"
        pingLabel.TextColor3 = col
    end
end)

-- ─── ПЕРЕКЛЮЧАТЕЛЬ ТЕМ ───────────────────────────────────────────────────────
-- 3 маленькие точки в правой части топ-бара
local THEME_COLORS = {
    Color3.fromRGB(162,42,255),   -- purple
    Color3.fromRGB(60,160,255),   -- blue
    Color3.fromRGB(255,80,80),    -- red
}
local themeDots = {}

for i = 1, 3 do
    local dot_t = mkBtn(topBar, "",
        UDim2.new(0,8,0,8),
        UDim2.new(1, -62 + (i-1)*12, 0, 13),
        THEME_COLORS[i], C.text, 1)
    addCorner(dot_t, 5)
    dot_t.BackgroundTransparency = (i==1) and 0 or 0.5
    themeDots[i] = dot_t

    local ti = i
    dot_t.MouseButton1Click:Connect(function()
        currentThemeIdx = ti
        applyTheme(THEMES[ti])
        -- Обновляем scrollbar цвет
        for _, pg in ipairs(pages) do
            if pg:IsA("ScrollingFrame") then
                pg.ScrollBarImageColor3 = C.sliderFill
            end
        end
        -- Обновляем прозрачность точек
        for j, d in ipairs(themeDots) do
            d.BackgroundTransparency = (j==ti) and 0 or 0.5
        end
        -- Обновляем вкладки
        for j, b in ipairs(tabBtns) do
            b.BackgroundColor3 = (j==lastTabIdx) and C.tabOn or C.tabOff
            b.TextColor3       = (j==lastTabIdx) and C.text  or C.textDim
        end
        -- Обновляем openBtn
        openBtn.BackgroundColor3 = C.toggleBtn
    end)
end

-- ─── WIDGET HELPERS ──────────────────────────────────────────────────────────
-- funcRow теперь принимает tabIdx и featureKey для счётчиков
local function funcRow(page, name, y, cb, tabIdx, featureKey)
    tabIdx     = tabIdx     or 0
    featureKey = featureKey or name

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
        -- Обновляем счётчики и статус-бар
        onFeatureToggle(tabIdx, name, state, featureKey)
        cb(state)
    end)

    -- Регистрируем для поиска
    allRows[#allRows+1] = { frame=row, name=name:lower(), tabIdx=tabIdx }

    return tog, accent
end

local function secLbl(page, text, y)
    local bar = mkFrame(page, UDim2.new(0,3,0,13), UDim2.new(0,PX,0,y+1), C.accent)
    addCorner(bar, 2)
    mkLabel(page, text, UDim2.new(1,-22,0,13), UDim2.new(0,PX+8,0,y), C.textDim, Enum.TextXAlignment.Left, 10)
end

local function sep(page, y)
    local sf = mkFrame(page, UDim2.new(1,-12,0,1), UDim2.new(0,PX,0,y), C.sep)
    local g  = Instance.new("UIGradient")
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.15,0),
        NumberSequenceKeypoint.new(0.85,0), NumberSequenceKeypoint.new(1,1),
    })
    g.Parent = sf
end

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
        local rel = math.clamp((ix-track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        local val = isFloat and (minV+rel*(maxV-minV)) or math.floor(minV+rel*(maxV-minV))
        valLbl.Text = isFloat and string.format("%.2f",val) or tostring(val)
        fill.Size   = UDim2.new(rel,0,1,0)
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

local function actionBtn(page, y, label, cb)
    local btn = mkBtn(page, label, UDim2.new(1,-10,0,24), UDim2.new(0,PX,0,y), C.btnAction, C.text, 11)
    addCorner(btn, 5); addStroke(btn, C.border, 1)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.btnHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.btnAction end)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function infoLbl(page, text, y, col)
    return mkLabel(page, text, UDim2.new(1,-12,0,13), UDim2.new(0,PX,0,y),
        col or C.textDim, Enum.TextXAlignment.Left, 10)
end

-- ═══════════════════════════════════════════════════════════════════
-- PAGE 1: COMBAT  (tabIdx = 1)
-- ═══════════════════════════════════════════════════════════════════
local p1 = pages[1]
local y1 = 8

secLbl(p1, "ESP", y1); y1 += 18

funcRow(p1, "ESP — Enemy Highlight", y1, function(s)
    espEnabled = s
    addLog("ESP ▸ " .. (s and "ENABLED" or "DISABLED"))
    if s then espRefreshAll() else espClearAll()
        if isTriggerBotEnabled then forceDisableTriggerBot("ESP выключен") end
    end
end, 1, "esp")
y1 += 34

funcRow(p1, "Цвет контура по здоровью", y1, function(s)
    espHealthColor = s
end, 1, "esp_hcol")
y1 += 34

funcRow(p1, "Цвет контура по команде", y1, function(s)
    espShowTeamColor = s
end, 1, "esp_tcol")
y1 += 34

funcRow(p1, "Показывать имена (billboard)", y1, function(s)
    espShowName = s
end, 1, "esp_name")
y1 += 34

funcRow(p1, "Показывать HP / дистанцию", y1, function(s)
    espShowHealth = s; espShowDist = s
end, 1, "esp_hp")
y1 += 34

sep(p1, y1); y1 += 8
secLbl(p1, "AIM", y1); y1 += 18

funcRow(p1, "Show FOV Square", y1, function(s)
    fovVisible = s; fovSquare.Visible = s
end, 1, "fov")
y1 += 34

funcRow(p1, "Aim Assist  (удержи ПКМ)", y1, function(s)
    isAimAssistEnabled = s
end, 1, "aim_assist")
y1 += 34

funcRow(p1, "Silent Aim  (снап при выстреле)", y1, function(s)
    isSilentAimEnabled = s
end, 1, "silent_aim")
y1 += 34

funcRow(p1, "Allow Wallbang", y1, function(s)
    allowWallbang = s
end, 1, "wallbang")
y1 += 34

funcRow(p1, "Упреждение цели (Lead Shot)", y1, function(s)
    aimPrediction = s
end, 1, "prediction")
y1 += 34

infoLbl(p1, "FOV Radius (px)", y1); y1 += 14
mkSlider(p1, y1, 40, 500, fovHalfSize, false, function(v) fovHalfSize = v end); y1 += 16

infoLbl(p1, "Aim Smoothness  (0=быстро · 100=плавно)", y1); y1 += 14
mkSlider(p1, y1, 0, 100, aimSmoothness*100, false, function(v) aimSmoothness=v/100 end); y1 += 16

sep(p1, y1); y1 += 8
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
            addLog("BOT ▸ ❌ сначала включи ESP!")
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
        addLog("BOT ▸ " .. (_tbState and "ENABLED" or "DISABLED"))
        if _tbState then lastTriggerFireAt = 0 end
        onFeatureToggle(1, "TriggerBot", _tbState, "triggerbot")
    end)
    allRows[#allRows+1] = { frame=row, name="trigger bot", tabIdx=1 }
end
y1 += 34

infoLbl(p1, "Trigger Cooldown (ms)", y1); y1 += 14
mkSlider(p1, y1, 20, 500, triggerCooldownSec*1000, false, function(v) triggerCooldownSec=v/1000 end); y1 += 16

sep(p1, y1); y1 += 8
secLbl(p1, "HITBOX EXPANDER", y1); y1 += 18

funcRow(p1, "Expand Enemy Hitboxes", y1, function(s) setHitbox(s) end, 1, "hitbox")
y1 += 34

infoLbl(p1, "Размер хитбокса (studs)", y1); y1 += 14
mkSlider(p1, y1, 2, 30, hitboxSize, false, function(v)
    hitboxSize = v
    if hitboxEnabled then refreshHitboxSize() end
end)
y1 += 16

funcRow(p1, "Прозрачный хитбокс", y1, function(s)
    hitboxTransparent = s
    if hitboxEnabled then refreshHitboxSize() end
end, 1, "hitbox_tr")
y1 += 34

p1.CanvasSize = UDim2.new(0,0,0,y1+20)

-- ═══════════════════════════════════════════════════════════════════
-- PAGE 2: MOVEMENT  (tabIdx = 2)
-- ═══════════════════════════════════════════════════════════════════
local p2 = pages[2]
local y2 = 8

secLbl(p2, "ДВИЖЕНИЕ", y2); y2 += 18

funcRow(p2, "Custom WalkSpeed", y2, function(s)
    speedEnabled = s
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = s and speedValue or BASE_SPEED end
end, 2, "speed")
y2 += 34

infoLbl(p2, "Walk Speed (studs/s)", y2); y2 += 14
mkSlider(p2, y2, 1, 500, speedValue, false, function(v) speedValue=v end); y2 += 16

funcRow(p2, "NoClip", y2, function(s)
    noClipEnabled = s
    if s then updateNoClipCache() else stopNoClip() end
end, 2, "noclip")
y2 += 34

funcRow(p2, "Infinite Jump  (Space в воздухе)", y2, function(s)
    infiniteJumpEnabled = s
end, 2, "ijump")
y2 += 34

funcRow(p2, "Jump Boost", y2, function(s)
    jumpBoostEnabled = s
end, 2, "jboost")
y2 += 34

infoLbl(p2, "Jump Boost Force", y2); y2 += 14
mkSlider(p2, y2, 10, 300, jumpBoostForce, false, function(v) jumpBoostForce=v end); y2 += 16

sep(p2, y2); y2 += 8
secLbl(p2, "ПОЛЁТ", y2); y2 += 18

funcRow(p2, "Fly  (WASD+Space/Shift)", y2, function(s)
    flyEnabled = s
    if s then startFly() else stopFly() end
end, 2, "fly")
y2 += 34

funcRow(p2, "Инерция при полёте", y2, function(s) flyInertia=s end, 2, "fly_inertia")
y2 += 34

infoLbl(p2, "Fly Speed (studs/s)", y2); y2 += 14
mkSlider(p2, y2, 1, 1500, flySpeed, false, function(v) flySpeed=v end); y2 += 16

sep(p2, y2); y2 += 8
secLbl(p2, "СПИН", y2); y2 += 18

funcRow(p2, "Spinbot", y2, function(s) spinEnabled=s end, 2, "spin")
y2 += 34

infoLbl(p2, "Spin Speed (deg/s)", y2); y2 += 14
mkSlider(p2, y2, 60, 1800, spinSpeedDegPerSec, false, function(v) spinSpeedDegPerSec=v end); y2 += 16

do
    local axes = {"X","Y","Z"}
    local axBtns = {}
    local btnW = math.floor((CONT_W-14)/3)
    for i, ax in ipairs(axes) do
        local btn = mkBtn(p2, ax,
            UDim2.new(0,btnW,0,22), UDim2.new(0,PX+(i-1)*(btnW+4),0,y2),
            (ax=="Y") and C.tabOn or C.tabOff,
            (ax=="Y") and C.text  or C.textDim, 11)
        addCorner(btn,5); addStroke(btn, C.borderDim, 1)
        axBtns[ax] = btn
        btn.MouseButton1Click:Connect(function()
            spinAxis = ax
            for _, b in pairs(axBtns) do b.BackgroundColor3=C.tabOff; b.TextColor3=C.textDim end
            btn.BackgroundColor3=C.tabOn; btn.TextColor3=C.text
        end)
    end
end
y2 += 30

sep(p2, y2); y2 += 8
secLbl(p2, "NDS — УПРАВЛЕНИЕ ОБЪЕКТАМИ", y2); y2 += 20

do
    local btnW = math.floor((CONT_W-14)/4)
    local modeNames = {"Sphere","Disk","Cursor","Vortex"}
    local modeIcons = {"⬤","◆","◎","🌀"}
    local ndsMBtns  = {}
    local function selectMode(idx)
        ndsMode = idx
        for i, b in ipairs(ndsMBtns) do
            b.BackgroundColor3 = (i==idx) and C.tabOn or C.tabOff
            b.TextColor3       = (i==idx) and C.text  or C.textDim
        end
        addLog("NDS ▸ режим → " .. modeNames[idx])
    end
    for i = 1,4 do
        local mb = mkBtn(p2, modeIcons[i],
            UDim2.new(0,btnW,0,22), UDim2.new(0,PX+(i-1)*(btnW+3),0,y2),
            (i==1) and C.tabOn or C.tabOff,
            (i==1) and C.text  or C.textDim, 13)
        addCorner(mb,5); addStroke(mb, C.borderDim, 1)
        ndsMBtns[i] = mb
        local mi = i
        mb.MouseButton1Click:Connect(function() selectMode(mi) end)
    end
end
y2 += 28

ndsCountLabel = infoLbl(p2, "⚫ NDS отключён", y2, C.textDim); y2 += 22

funcRow(p2, "Enable NDS", y2, function(s)
    ndsEnabled = s
    if s then startNDS() else stopNDS() end
end, 2, "nds")
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
        addLog("NDS ▸ авто-захват " .. (ndsAutoScan and "ВКЛ" or "ВЫКЛ"))
    end)
end
y2 += 34

infoLbl(p2, "Дистанция от игрока (studs)", y2); y2 += 14
mkSlider(p2, y2, 1, 500, ndsDistance, false, function(v) ndsDistance=v end); y2 += 16
infoLbl(p2, "Скорость вращения (deg/s)", y2); y2 += 14
mkSlider(p2, y2, 1, 3000, ndsRotSpeed, false, function(v) ndsRotSpeed=v end); y2 += 16
infoLbl(p2, "Жёсткость удержания", y2); y2 += 14
mkSlider(p2, y2, 1, 1000, ndsSpeed, false, function(v) ndsSpeed=v end); y2 += 16
infoLbl(p2, "Скорость откидывания", y2); y2 += 14
mkSlider(p2, y2, 10, 500, ndsScatterSpeed, false, function(v) ndsScatterSpeed=v end); y2 += 16
infoLbl(p2, "Лимит захвата  10–1000", y2); y2 += 14
mkSlider(p2, y2, 10, 1000, ndsMaxCapture, false, function(v) ndsMaxCapture=v end); y2 += 16

do
    local halfW = math.floor((CONT_W-14)/2)
    local rBtn = mkBtn(p2, "🔄 Пересканировать",
        UDim2.new(0,halfW,0,24), UDim2.new(0,PX,0,y2), C.btnAction, C.text, 10)
    addCorner(rBtn,5); addStroke(rBtn, C.border, 1)
    rBtn.MouseEnter:Connect(function() rBtn.BackgroundColor3=C.btnHover end)
    rBtn.MouseLeave:Connect(function() rBtn.BackgroundColor3=C.btnAction end)
    rBtn.MouseButton1Click:Connect(function()
        if ndsEnabled then addLog("NDS ▸ ручной скан  итого=" .. #ndsObjects)
        else addLog("NDS ▸ сначала включи NDS") end
    end)
    local sBtn = mkBtn(p2, "💥 Scatter!",
        UDim2.new(0,halfW,0,24), UDim2.new(0,PX+halfW+4,0,y2),
        Color3.fromRGB(100,20,0), C.text, 10)
    addCorner(sBtn,5); addStroke(sBtn, Color3.fromRGB(180,60,20), 1)
    sBtn.MouseEnter:Connect(function() sBtn.BackgroundColor3=Color3.fromRGB(160,40,0) end)
    sBtn.MouseLeave:Connect(function() sBtn.BackgroundColor3=Color3.fromRGB(100,20,0) end)
    sBtn.MouseButton1Click:Connect(function()
        if ndsEnabled and #ndsObjects > 0 then ndsScatterAll() end
    end)
end
y2 += 32

sep(p2, y2); y2 += 8
secLbl(p2, "ТЕЛЕПОРТ", y2); y2 += 18

funcRow(p2, "Teleport by Click  (Ctrl+ЛКМ)", y2, function(s) teleportEnabled=s end, 2, "tp_click")
y2 += 34

infoLbl(p2, "Teleport to Player by Nick", y2); y2 += 16
local nameBox = mkTextBox(p2, UDim2.new(1,-12,0,24), UDim2.new(0,PX,0,y2), "Ник игрока...")
y2 += 30
nameBox:GetPropertyChangedSignal("Text"):Connect(function() targetPlayerName=nameBox.Text end)

actionBtn(p2, y2, "▶  Teleport to Player", function() tpToPlayer(targetPlayerName) end)
y2 += 30

do
    local halfW = math.floor((CONT_W-14)/2)
    local loopState = false
    local loopBtn = mkBtn(p2, "🔁 Loop TP",
        UDim2.new(0,halfW,0,22), UDim2.new(0,PX,0,y2), C.btnAction, C.text, 10)
    addCorner(loopBtn,5); addStroke(loopBtn, C.border, 1)
    loopBtn.MouseButton1Click:Connect(function()
        loopState = not loopState
        loopBtn.Text             = loopState and "⏹ Stop" or "🔁 Loop TP"
        loopBtn.BackgroundColor3 = loopState and C.togOn or C.btnAction
        if loopState then
            if startLoopTP then startLoopTP(targetPlayerName) end
        else
            if stopLoopTP then stopLoopTP() end
        end
    end)
    local backBtn = mkBtn(p2, "◀ Назад",
        UDim2.new(0,halfW,0,22), UDim2.new(0,PX+halfW+4,0,y2), C.tabOff, C.text, 10)
    addCorner(backBtn,5); addStroke(backBtn, C.borderDim, 1)
    backBtn.MouseButton1Click:Connect(function() if tpBack then tpBack() end end)
end
y2 += 30

p2.CanvasSize = UDim2.new(0,0,0,y2+20)

-- ═══════════════════════════════════════════════════════════════════
-- PAGE 3: MISC  (tabIdx = 3)
-- ═══════════════════════════════════════════════════════════════════
local p3 = pages[3]
local y3 = 8

secLbl(p3, "MISC", y3); y3 += 18

funcRow(p3, "Anti-AFK", y3, function(s) setAntiAfk(s) end, 3, "anti_afk"); y3 += 34
funcRow(p3, "Inf Stamina (авто-заполнение)", y3, function(s) setInfStamina(s) end, 3, "inf_stamina"); y3 += 34

sep(p3, y3); y3 += 8
secLbl(p3, "VISUALS", y3); y3 += 18

funcRow(p3, "Убрать туман / дым", y3, function(s)
    visualFogEnabled = s
    if s then applyNoFog() else restoreFog() end
end, 3, "fog")
y3 += 34

funcRow(p3, "Максимальная яркость", y3, function(s)
    visualBrightEnabled = s
    if s then applyBrightness(brightnessValue) else restoreBrightness() end
end, 3, "bright")
y3 += 34

infoLbl(p3, "Уровень яркости  1–10", y3); y3 += 14
mkSlider(p3, y3, 1, 10, brightnessValue, false, function(v)
    brightnessValue = v
    if visualBrightEnabled then pcall(function() Lighting.Brightness=v end) end
end)
y3 += 16

funcRow(p3, "Fullbright (Ambient метод)", y3, function(s) setFullbright(s) end, 3, "fullbright")
y3 += 34

funcRow(p3, "Зафиксировать время суток", y3, function(s)
    visualTimeEnabled = s
    if s then applyFixedTime(visualTimeValue) else restoreTime() end
end, 3, "time_fix")
y3 += 34

infoLbl(p3, "Время суток (0–24)", y3); y3 += 14
mkSlider(p3, y3, 0, 24, visualTimeValue, false, function(v)
    visualTimeValue = v
    if visualTimeEnabled then applyFixedTime(v) end
end)
y3 += 16

funcRow(p3, "Прозрачность врагов (Chams)", y3, function(s)
    visualChamsEnabled = s
    if s then applyChams() else clearChams() end
end, 3, "chams")
y3 += 34

funcRow(p3, "Кроссхейр", y3, function(s)
    visualCrosshairOn = s
    if s then showCrosshair() else hideCrosshair() end
end, 3, "crosshair")
y3 += 34

do
    local halfW = math.floor((CONT_W-14)/2)
    local nvBtn = mkBtn(p3, "🌙 Night Vision",
        UDim2.new(0,halfW,0,22), UDim2.new(0,PX,0,y3), C.btnAction, C.text, 10)
    addCorner(nvBtn,5); addStroke(nvBtn, C.border, 1)
    nvBtn.MouseEnter:Connect(function() nvBtn.BackgroundColor3=C.btnHover end)
    nvBtn.MouseLeave:Connect(function() nvBtn.BackgroundColor3=C.btnAction end)
    nvBtn.MouseButton1Click:Connect(function() presetNightVision() end)
    local rstBtn = mkBtn(p3, "☀ Сброс",
        UDim2.new(0,halfW,0,22), UDim2.new(0,PX+halfW+4,0,y3), C.tabOff, C.text, 10)
    addCorner(rstBtn,5); addStroke(rstBtn, C.borderDim, 1)
    rstBtn.MouseButton1Click:Connect(function() presetRestore() end)
end
y3 += 30

sep(p3, y3); y3 += 8
secLbl(p3, "ГРАВИТАЦИЯ", y3); y3 += 18

funcRow(p3, "Изменить гравитацию", y3, function(s)
    gravityEnabled = s
    if s then applyGravity() else resetGravity() end
end, 3, "gravity")
y3 += 34

infoLbl(p3, "Gravity  стандарт = 196.2", y3); y3 += 14
mkSlider(p3, y3, 10, 800, gravityValue, false, function(v)
    gravityValue = v
    if gravityEnabled then pcall(function() workspace.Gravity=v end) end
end)
y3 += 16

sep(p3, y3); y3 += 8
secLbl(p3, "KILL AURA", y3); y3 += 18

funcRow(p3, "Kill Aura  (Tool в радиусе)", y3, function(s) setKillAura(s) end, 3, "kill_aura")
y3 += 34

do
    local modeNames = {"Nearest","LowestHP"}
    local kaBtns = {}
    local halfW = math.floor((CONT_W-14)/2)
    for i = 1,2 do
        local mb = mkBtn(p3, modeNames[i],
            UDim2.new(0,halfW,0,20), UDim2.new(0,PX+(i-1)*(halfW+4),0,y3),
            (i==1) and C.tabOn or C.tabOff,
            (i==1) and C.text  or C.textDim, 10)
        addCorner(mb,5)
        kaBtns[i] = mb
        local mi = i
        mb.MouseButton1Click:Connect(function()
            killAuraMode = mi
            for j, b in ipairs(kaBtns) do
                b.BackgroundColor3 = (j==mi) and C.tabOn or C.tabOff
                b.TextColor3       = (j==mi) and C.text  or C.textDim
            end
        end)
    end
end
y3 += 28

infoLbl(p3, "Радиус Kill Aura (studs)", y3); y3 += 14
mkSlider(p3, y3, 3, 60, killAuraRadius, false, function(v) killAuraRadius=v end); y3 += 16

sep(p3, y3); y3 += 8

actionBtn(p3, y3, "📊 Server Info (в лог)", function()
    printServerInfo(); switchTab(4)
end)
y3 += 30

actionBtn(p3, y3, "💾 SaveInstance (дамп игры)", function()
    local ok = pcall(function() saveinstance() end)
    addLog("DUMP ▸ " .. (ok and "✅ сохранение запущено" or "❌ saveinstance недоступен"))
end)
y3 += 30

actionBtn(p3, y3, "🔄 Auto-Rejoin", function() autoRejoin() end)
y3 += 30

p3.CanvasSize = UDim2.new(0,0,0,y3+20)

-- ═══════════════════════════════════════════════════════════════════
-- PAGE 4: LOG
-- ═══════════════════════════════════════════════════════════════════
local p4 = pages[4]

local logHdr = mkFrame(p4, UDim2.new(1,-8,0,30), UDim2.new(0,4,0,4), C.rowBg)
addCorner(logHdr,6); addStroke(logHdr, C.borderDim, 1)
mkLabel(logHdr, "📋  ESP / System Logger",
    UDim2.new(1,-70,1,0), UDim2.new(0,10,0,0), C.accent, Enum.TextXAlignment.Left, 11)

local clearLogBtn = mkBtn(logHdr, "🗑 Clear",
    UDim2.new(0,56,0,20), UDim2.new(1,-60,0,5), C.btnAction, C.text, 10)
addCorner(clearLogBtn,5)
clearLogBtn.MouseEnter:Connect(function() clearLogBtn.BackgroundColor3=C.btnHover end)
clearLogBtn.MouseLeave:Connect(function() clearLogBtn.BackgroundColor3=C.btnAction end)
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
logLabel.FocusLost:Connect(function() logDirty=true end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if logDirty and logLabel then
            local n = #logBuffer
            logLabel.Text = n > 0 and table.concat(logBuffer, "\n") or "— No logs yet —"
            local lineH  = 13
            local totalH = math.max(n*lineH+50, 200)
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
    -- При открытии — восстанавливаем последнюю вкладку
    if main.Visible then switchTab(lastTabIdx) end
end)

local minimized = false
local fullSize  = UDim2.new(0,MENU_W,0,MENU_H)
local miniSize  = UDim2.new(0,MENU_W,0,BAR_H)

minBtn.MouseButton1Click:Connect(function()
    minimized           = not minimized
    main.Size           = minimized and miniSize or fullSize
    contentArea.Visible = not minimized
    tabPanel.Visible    = not minimized
    statusBarFrame.Visible = not minimized
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
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragActive=false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not dragActive then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local d = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
    main.Position = UDim2.new(0, posStart.X+d.X, 0, posStart.Y+d.Y)
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragActive=false end
end)

-- RightAlt = показать/скрыть (с восстановлением последней вкладки)
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightAlt then
        main.Visible = not main.Visible
        if main.Visible then switchTab(lastTabIdx) end
    end
end)

-- ─── RESPAWN ─────────────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    flyBodyVelocity    = nil
    flyBodyGyro        = nil
    flyCanCollideParts = {}
    if flyConnection then flyConnection:Disconnect(); flyConnection=nil end
    task.wait(0.4)
    if flyEnabled then startFly() end
    updateNoClipCache()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if speedEnabled and hum then hum.WalkSpeed=speedValue end
    char.ChildAdded:Connect(function(d)
        if d:IsA("Tool") then bindTool(d) end
    end)
    bindAllTools()
    task.delay(1, espRefreshAll)
    if ndsEnabled then
        task.wait(0.6)
        stopNDS(); ndsEnabled=true; startNDS()
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
