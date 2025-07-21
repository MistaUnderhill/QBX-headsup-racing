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

RegisterNetEvent('qb-street-race:inviteToRace')
AddEventHandler('qb-street-race:inviteToRace', function(initiator)
    local accept = lib.alertDialog({
        header = 'Street Race Invitation',
        content = 'Another racer is inviting you to a street race. Buy-in: $' .. Config.BuyInAmount,
        centered = true,
        cancel = true
    })

    local accepted = (accept == 'confirm')
    TriggerServerEvent('qb-street-race:raceResponse', accepted, initiator)
end)
