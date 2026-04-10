-- ═══════════════════════════════════════════════════════════════════
--  main_loop.lua  —  Menu V1  |  Главный цикл
--  Heartbeat   — скорость, спин, полёт
--  RenderStepped — FOV квадрат, TriggerBot, ESP метки
--  InputBegan  — Aim Assist, Click TP
--  Bypass-проверки при запуске.
--  Загружается ПОСЛЕДНИМ — все глобалы уже определены.
-- ═══════════════════════════════════════════════════════════════════

-- ─── HEARTBEAT ───────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
    local myChar = LocalPlayer.Character
    if not myChar then return end

    local hum = myChar:FindFirstChildOfClass("Humanoid")
    local hrp = myChar:FindFirstChild("HumanoidRootPart")

    -- Speed
    if speedEnabled and hum then
        hum.WalkSpeed = speedValue
    end

    -- Spin
    if spinEnabled and hrp then
        hrp.CFrame = hrp.CFrame * getSpinDelta(dt)
    end

    -- Fly: если bodyVelocity пропал — перезапускаем
    if flyEnabled and hrp then
        if not flyBodyVelocity or not flyBodyVelocity.Parent then
            startFly()
        end
    end
end)

-- ─── RENDER STEPPED ──────────────────────────────────────────────────────────
local _espLabelTimer = 0

RunService.RenderStepped:Connect(function(dt)

    -- FOV квадрат
    if fovSquare and fovSquare.Visible then
        local inset = GuiService:GetGuiInset()
        local m     = UserInputService:GetMouseLocation()
        fovSquare.Size     = UDim2.fromOffset(fovHalfSize * 2, fovHalfSize * 2)
        fovSquare.Position = UDim2.fromOffset(
            m.X - fovHalfSize,
            m.Y - fovHalfSize - inset.Y)
    end

    -- ESP метки каждые 0.1с
    _espLabelTimer += dt
    if _espLabelTimer >= 0.10 then
        _espLabelTimer = 0
        if espEnabled then pcall(updateESPLabels) end
    end

    -- TRIGGER BOT
    if not isTriggerBotEnabled then return end
    if not espEnabled then
        forceDisableTriggerBot("ESP выключен")
        return
    end

    local equippedTool = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    if not aimLockedTarget then return end

    local now = tick()
    if now - lastTriggerFireAt < triggerCooldownSec then return end
    if now - lastTargetScanAt  < 0.05              then return end
    lastTargetScanAt = now

    local tgt = getBestTarget(allowWallbang)
    if not tgt or not tgt.Character then return end

    local aimPart = tgt.Character:FindFirstChild(aimPartName)
                 or tgt.Character:FindFirstChild("HumanoidRootPart")
    if not aimPart then return end

    local hum = tgt.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    if not allowWallbang then
        if not hasDirectLoS(camera.CFrame.Position, aimPart.Position, tgt.Character) then
            return
        end
    end

    simulateLMB()
    lastTriggerFireAt = now
    addLog("BOT  ▸ 🔫 " .. tgt.Name)
end)

-- ─── INPUT BEGAN ─────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Aim Assist (удержание ПКМ)
    if input.UserInputType == aimKey and isAimAssistEnabled then
        task.spawn(function()
            local lastLocked = nil
            while UserInputService:IsMouseButtonPressed(aimKey) do
                local tgt = getBestTarget(allowWallbang)
                if tgt then
                    if tgt ~= lastLocked then
                        lastLocked      = tgt
                        aimLockedTarget = tgt
                        addLog("AIM  ▸ захват: " .. tgt.Name)
                    end
                    aimCameraAt(getAimPos(tgt))
                else
                    lastLocked      = nil
                    aimLockedTarget = nil
                end
                RunService.Heartbeat:Wait()
            end
            aimLockedTarget = nil
            if lastLocked then addLog("AIM  ▸ снят захват") end
        end)
    end

    -- Click Teleport (Ctrl + ЛКМ)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       and teleportEnabled
       and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        pcall(handleTeleportInput, input, gp)
    end
end)

-- ─── BYPASS ПРОВЕРКИ ─────────────────────────────────────────────────────────
task.spawn(function()
    task.wait(1)

    local _ok, fe = pcall(function() return workspace.FilteringEnabled end)
    addLog("SYS  ▸ FE=" .. ((_ok and fe)
        and "ON  (локальные эффекты)"
        or  "OFF (изменения видны всем)"))

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local ok2 = pcall(function() local _ = hrp.CFrame end)
        addLog("SYS  ▸ CFrame: " .. (ok2 and "✅" or "❌ заблокирован"))
    end

    local ok3 = pcall(function() local ap = Instance.new("AlignPosition"); ap:Destroy() end)
    addLog("SYS  ▸ AlignPosition: " .. (ok3 and "✅" or "❌"))

    local ok4 = pcall(function() local bv = Instance.new("BodyVelocity"); bv:Destroy() end)
    addLog("SYS  ▸ BodyVelocity: "  .. (ok4 and "✅" or "❌"))

    local hasMouse = type(mouse1click) == "function"
        or (type(mouse1press) == "function" and type(mouse1release) == "function")
    addLog("SYS  ▸ mouse1click: " .. (hasMouse and "✅" or "⚠ fallback"))

    addLog("SYS  ▸ игроков: " .. #Players:GetPlayers())
    addLog("SYS  ▸ Menu V1 " .. MENU_VERSION .. " ✅ загружен полностью")
end)

addLog("LOOP ▸ main_loop.lua загружен")
