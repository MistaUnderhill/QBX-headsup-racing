RegisterCommand("raceleaderboard", function()
    TriggerServerEvent('qb-street-race:getLeaderboard')
end, false)

RegisterNetEvent('qb-street-race:startClientRace')
AddEventHandler('qb-street-race:startClientRace', function(checkpoint)
    local playerPed = PlayerPedId()
    local blip = AddBlipForCoord(checkpoint.x, checkpoint.y, checkpoint.z)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 5)

    local raceActive = true

    CreateThread(function()
        while raceActive do
            Wait(1000)
            local pos = GetEntityCoords(playerPed)
            if #(pos - checkpoint) < 15.0 then
                raceActive = false
                RemoveBlip(blip)
                TriggerServerEvent('qb-street-race:finishRace')
            end
        end
    end)
end)

-- Radial Menu Integration
RegisterNetEvent('qb-street-race:startRaceRadial')
AddEventHandler('qb-street-race:startRaceRadial', function()
    TriggerServerEvent('qb-street-race:startRaceServer')
end)
