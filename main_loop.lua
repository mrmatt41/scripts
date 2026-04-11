-- ═══════════════════════════════════════════════════════════════════
--  main_loop.lua  —  Menu V1  |  Главный цикл
--  Загружается ПОСЛЕДНИМ.
-- ═══════════════════════════════════════════════════════════════════

RunService.Heartbeat:Connect(function(dt)
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    local hrp = myChar:FindFirstChild("HumanoidRootPart")

    if speedEnabled and hum then
        hum.WalkSpeed = speedValue
    end

    if spinEnabled and hrp then
        hrp.CFrame = hrp.CFrame * getSpinDelta(dt)
    end

    if flyEnabled and hrp then
        if not flyBodyVelocity or not flyBodyVelocity.Parent then
            startFly()
        end
    end
end)

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
    addLog("BOT ▸ 🔫 " .. tgt.Name)
end)

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
                        addLog("AIM ▸ захват: " .. tgt.Name)
                    end
                    aimCameraAt(getAimPos(tgt))
                else
                    lastLocked      = nil
                    aimLockedTarget = nil
                end
                RunService.Heartbeat:Wait()
            end
            aimLockedTarget = nil
            if lastLocked then addLog("AIM ▸ снят захват") end
        end)
    end

    -- Click Teleport (Ctrl + ЛКМ) — функция handleClickTP из teleport.lua
    if input.UserInputType == Enum.UserInputType.MouseButton1
       and teleportEnabled
       and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        pcall(handleClickTP, input)
    end
end)

-- ─── BYPASS ПРОВЕРКИ ─────────────────────────────────────────────────────────
task.spawn(function()
    task.wait(1)

    local _feOk, feEnabled = pcall(function() return workspace.FilteringEnabled end)
    feEnabled = _feOk and feEnabled
    if feEnabled then
        addLog("SYS  ▸ FE=ON  (эффекты видны только локально, не другим игрокам)")
    else
        addLog("SYS  ▸ FE=OFF (изменения видны всем — полный контроль)")
    end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local ok = pcall(function() local _ = hrp.CFrame end)
        addLog("SYS  ▸ CFrame доступ: " .. (ok and "✅ OK" or "❌ ЗАБЛОКИРОВАНО"))
    end

    local hasAlignPos = pcall(function()
        local ap = Instance.new("AlignPosition"); ap:Destroy()
    end)
    addLog("SYS  ▸ AlignPosition: " .. (hasAlignPos and "✅ доступен" or "❌ недоступен"))

    addLog("SYS  ▸ Игроков на сервере: " .. #Players:GetPlayers())
end)

addLog("SYSTEM ▸ Menu V1 initialized  [v3.0]")
addLog("ESP    ▸ tracking " .. math.max(#Players:GetPlayers() - 1, 0) .. " players")
