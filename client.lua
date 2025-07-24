local QBCore = exports['qbx-core']:GetCoreObject()
local isInvited = false
local raceCheckpoint = nil
local isCountdownActive = false
local raceActive = false

-- New: Prompt buy-in and trigger server event for race start
RegisterNetEvent('qbx-street-racing:startRaceRadial', function()
    local input = lib.inputDialog('Street Race Buy-In', {
        { type = 'number', label = 'Buy-In ($)', description = 'Enter your wager', min = Config.MinBuyIn, max = Config.MaxBuyIn, required = true }
    })

    if not input or not input[1] then return end

    local buyIn = tonumber(input[1])
    if not buyIn or buyIn < Config.MinBuyIn or buyIn > Config.MaxBuyIn then
        QBCore.Functions.Notify('Invalid buy-in amount.', 'error')
        return
    end

    TriggerServerEvent('qbx-street-racing:startRaceRadial', buyIn)
end)

RegisterNetEvent('qbx-street-racing:inviteToRace', function(data)
    if isInvited then return end
    isInvited = true

    local countdown = Config.ConfirmationTimeout
    CreateThread(function()
        while countdown > 0 do
            Wait(1000)
            countdown -= 1
        end

        if isInvited then
            TriggerServerEvent('qbx-street-racing:declineRace')
            QBCore.Functions.Notify('Race invitation timed out.', 'error')
            isInvited = false
        end
    end)

    CreateThread(function()
        while isInvited do
            Wait(0)
            if IsControlJustPressed(0, 38) then -- E
                TriggerServerEvent('qbx-street-racing:confirmRace')
                isInvited = false
                break
            end
        end
    end)

    QBCore.Functions.Notify("You've been invited to a street race. Press [E] to join.")
end)

RegisterNetEvent('qbx-street-racing:lockPlayer', function()
    local player = PlayerPedId()
    FreezeEntityPosition(player, true)
end)

RegisterNetEvent('qbx-street-racing:startCountdown', function()
    if isCountdownActive then return end  -- Prevent multiple countdowns
    isCountdownActive = true

    local countdown = Config.CountdownTime
    CreateThread(function()
        while countdown > 0 do
            TriggerEvent('chat:addMessage', { args = { tostring(countdown) } })
            Wait(1000)
            countdown -= 1
        end
        TriggerEvent('chat:addMessage', { args = { 'GO!' } })
        TriggerServerEvent('qbx-street-racing:unlockPlayer')

        isCountdownActive = false -- Reset flag when countdown finishes
    end)
end)

RegisterNetEvent('qbx-street-racing:unlockPlayer', function()
    local player = PlayerPedId()
    FreezeEntityPosition(player, false)
end)

RegisterNetEvent('qbx-street-racing:setCheckpoint', function(coords)
    if DoesBlipExist(raceCheckpoint) then
        RemoveBlip(raceCheckpoint)
    end

    raceCheckpoint = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipRoute(raceCheckpoint, true)
    SetBlipRouteColour(raceCheckpoint, 5)

    raceActive = true  -- Race started/active

    CreateThread(function()
        while raceActive do
            Wait(1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            if #(playerCoords - coords) < 5.0 then
                TriggerServerEvent('qbx-street-racing:finishRace')
                RemoveBlip(raceCheckpoint)
                raceCheckpoint = nil
                raceActive = false
                break
            end
        end
    end)
end)

RegisterNetEvent('qbx-street-racing:resetRace', function()
    raceActive = false
    if DoesBlipExist(raceCheckpoint) then
        RemoveBlip(raceCheckpoint)
        raceCheckpoint = nil
    end
    -- Optionally reset other flags like isInvited etc.
end)

RegisterCommand("raceleaderboard", function()
    TriggerServerEvent("qbx-street-racing:requestLeaderboard")
end)

RegisterNetEvent("qbx-street-racing:showLeaderboard", function(data)
    for i, racer in ipairs(data) do
        TriggerEvent("chat:addMessage", {
            args = { ("%d. %s - %d wins"):format(i, racer.name, racer.wins) }
        })
    end
end)

RegisterNetEvent('qbx-street-racing:resetInviteFlag', function()
    isInvited = false
end)
