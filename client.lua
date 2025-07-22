RegisterNetEvent('qb-street-race:promptJoin', function(buyIn)
    local accept = lib.alertDialog({
        header = 'Street Race Invite',
        content = "Buy-in: $" .. buyIn .. "\nDo you want to join?",
        centered = true,
        cancel = true
    })

    if accept == 'confirm' then
        TriggerServerEvent('qb-street-race:playerAccepted')
    end
end)

RegisterNetEvent('qb-street-race:startRace', function(checkpoint)
    local ped = PlayerPedId()
    SetNewWaypoint(checkpoint.x, checkpoint.y)
    lib.notify({type = 'inform', description = "Race started! Reach the checkpoint."})

    CreateThread(function()
        local finished = false
        while not finished do
            Wait(500)
            local dist = #(GetEntityCoords(ped) - checkpoint)
            if dist < 10.0 then
                finished = true
                TriggerServerEvent('qb-street-race:finishRace')
            end
        end
    end)
end)

lib.registerRadial({
    id = 'start_race',
    label = 'Start Street Race',
    icon = 'car',
    onSelect = function()
        local input = lib.inputDialog('Set Race Buy-In', {
            {type = 'number', label = 'Buy-In Amount ($)', icon = 'dollar-sign', required = true, min = Config.MinBuyIn, max = Config.MaxBuyIn}
        })

        if input and input[1] then
            local buyIn = tonumber(input[1])
            if buyIn >= Config.MinBuyIn and buyIn <= Config.MaxBuyIn then
                TriggerServerEvent('qb-street-race:initiateRace', buyIn)
            else
                lib.notify({type = 'error', description = 'Buy in must be between 500 and 5000.'})
            end
        end
    end
})
