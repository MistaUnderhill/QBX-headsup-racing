local QBCore = exports['qbx-core']:GetCoreObject()
local inRace = false
local checkpoint = nil
local raceBlip = nil

RegisterCommand("startrace", function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        Notify("You must be in a vehicle to start a race.")
        return
    end

    local playersNearby = GetPlayersInVehicleRadius(Config.JoinDistance)
    if #playersNearby < 2 then
        Notify("Need at least 2 racers nearby to start a race.")
        return
    end

    -- Ask for buy-in
    local input = lib.inputDialog("Set Buy-In", {
        { type = "number", label = "Buy-In Amount ($500 - $5000)", min = 500, max = 5000, required = true }
    })

    if input then
        local buyIn = math.floor(tonumber(input[1]))
        if buyIn >= 500 and buyIn <= 5000 then
            for _, id in ipairs(playersNearby) do
                TriggerServerEvent('streetrace:playerReadyPrompt', GetPlayerServerId(id), buyIn)
            end
        else
            Notify("Invalid amount. Must be between $500 and $5000.")
        end
    end
end)

RegisterNetEvent('streetrace:joinRacePrompt', function(buyIn)
    local input = lib.inputDialog("Race Invitation", {
        { type = "select", label = ("Join Race for $%s?"):format(buyIn), options = {
            { value = "yes", label = "Yes" },
            { value = "no", label = "No" },
        }}
    })

    if input and input[1] == "yes" then
        TriggerServerEvent('streetrace:playerReady', buyIn)
    else
        TriggerServerEvent('streetrace:playerDecline')
    end
end)

RegisterNetEvent('streetrace:startRace', function(coords)
    checkpoint = coords
    inRace = true

    if raceBlip then
        RemoveBlip(raceBlip)
    end

    raceBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipRoute(raceBlip, true)
    SetBlipRouteColour(raceBlip, 5)

    Notify("Race started! First to the checkpoint wins!")
end)

CreateThread(function()
    while true do
        Wait(500)
        if inRace and checkpoint then
            local ped = PlayerPedId()
            local dist = #(GetEntityCoords(ped) - checkpoint)
            if dist < 25.0 then
                TriggerServerEvent('streetrace:finished')
                inRace = false
                if raceBlip then
                    RemoveBlip(raceBlip)
                    raceBlip = nil
                end
            end
        end
    end
end)

function GetPlayersInVehicleRadius(radius)
    local players = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, id in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(id)
        if targetPed ~= playerPed and IsPedInAnyVehicle(targetPed, false) then
            local targetCoords = GetEntityCoords(targetPed)
            if #(playerCoords - targetCoords) < radius then
                table.insert(players, id)
            end
        end
    end

    return players
end

function Notify(msg)
    -- No qb-notify dependency
    QBCore.Functions.Notify(msg, "primary")
end
