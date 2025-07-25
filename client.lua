local QBCore = exports['qbx-core']:GetCoreObject()
local isInvited = false
local raceCheckpoint = nil
local isCountdownActive = false
local raceActive = false

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
                TriggerEvent('qbx-street-racing:showConfirmVisual')        
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
    local countdown = Config.CountdownTime or 3

    while countdown > 0 do
        QBCore.Functions.Notify(tostring(countdown), "primary")
        Wait(1000)
        countdown -= 1
    end

    QBCore.Functions.Notify("GO!", "success")
end)


RegisterNetEvent('qbx-street-racing:unlockPlayer', function()
    local player = PlayerPedId()
    FreezeEntityPosition(player, false)
end)

local checkpointThreadActive = false

RegisterNetEvent('qbx-street-racing:setCheckpoint', function(coords)
    if DoesBlipExist(raceCheckpoint) then
        RemoveBlip(raceCheckpoint)
    end

    raceCheckpoint = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipRoute(raceCheckpoint, true)
    SetBlipRouteColour(raceCheckpoint, 5)

    raceActive = true
    checkpointThreadActive = true

    CreateThread(function()
        while raceActive and checkpointThreadActive do
            Wait(1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            if #(playerCoords - coords) < 5.0 then
                TriggerServerEvent('qbx-street-racing:finishRace')
                if DoesBlipExist(raceCheckpoint) then
                    RemoveBlip(raceCheckpoint)
                    raceCheckpoint = nil
                end
                raceActive = false
                checkpointThreadActive = false
                break
            end
        end
    end)
end)


RegisterNetEvent('qbx-street-racing:resetRace', function()
    raceActive = false
    checkpointThreadActive = false

    if DoesBlipExist(raceCheckpoint) then
        RemoveBlip(raceCheckpoint)
        raceCheckpoint = nil
    end

    isInvited = false
end)

RegisterCommand("raceleaderboard", function()
    TriggerServerEvent("qbx-street-racing:requestLeaderboard")
end)

RegisterNetEvent('qbx-street-racing:showLeaderboard', function(leaderboard)
    QBCore.Functions.Notify("Race Leaderboard:", "primary")

    for i, racer in ipairs(leaderboard) do
        QBCore.Functions.Notify(i .. ". " .. racer.name .. " (" .. racer.time .. "s)", "inform")
    end
end)


RegisterNetEvent('qbx-street-racing:resetInviteFlag', function()
    isInvited = false
end)

RegisterNetEvent('qbx-street-racing:showConfirmVisual', function()
    QBCore.Functions.Notify("Race joined!", "success")
end)
