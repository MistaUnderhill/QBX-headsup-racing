
local QBCore = exports['qb-core']:GetCoreObject()
local CurrentRace = nil

RegisterNetEvent('qb-street-race:initiateRace', function(buyIn)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if buyIn < Config.MinBuyIn or buyIn > Config.MaxBuyIn then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Buy-in must be between 500 and 5000.'})
        return
    end

    local coords = GetEntityCoords(GetPlayerPed(src))
    local checkpoint = GetRandomCheckpoint(coords)

    CurrentRace = {
        buyIn = buyIn,
        racers = {},
        checkpoint = checkpoint,
        status = "waiting"
    }

    -- Notify nearby players and allow them to accept or decline
    for _, id in pairs(GetPlayers()) do
        local targetPed = GetPlayerPed(id)
        if IsPedInAnyVehicle(targetPed, false) then
            local dist = #(coords - GetEntityCoords(targetPed))
            if dist <= Config.JoinDistance then
                TriggerClientEvent('qb-street-race:promptJoin', id, buyIn)
            end
        end
    end
end)

RegisterNetEvent('qb-street-race:playerAccepted', function()
    local src = source
    if not CurrentRace or CurrentRace.status ~= "waiting" then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveMoney("bank", CurrentRace.buyIn) then
        table.insert(CurrentRace.racers, src)
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'You joined the race!'})
    else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Not enough funds!'})
    end

    -- Start race if 2 or more racers
    if #CurrentRace.racers >= 2 then
        CurrentRace.status = "racing"
        for _, id in ipairs(CurrentRace.racers) do
            TriggerClientEvent('qb-street-race:startRace', id, CurrentRace.checkpoint)
        end
    end
end)

RegisterNetEvent('qb-street-race:finishRace', function()
    local src = source
    if not CurrentRace or CurrentRace.status ~= "racing" then return end

    CurrentRace.status = "complete"
    local pot = CurrentRace.buyIn * #CurrentRace.racers
    local tax = math.floor(pot * Config.TaxPercent)
    local payout = pot - tax

    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddMoney("bank", payout)
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = "You won $" .. payout})
    end

    -- Save win to database, reset state
    MySQL.update('INSERT INTO street_race_leaderboard (identifier, name, wins) VALUES (?, ?, 1) ON DUPLICATE KEY UPDATE wins = wins + 1', {
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    })

    CurrentRace = nil
end)

function GetRandomCheckpoint(origin)
    local min = Config.MinDistance
    local max = Config.MaxDistance
    local angle = math.random() * 2 * math.pi
    local distance = math.random(min, max)
    local x = origin.x + distance * math.cos(angle)
    local y = origin.y + distance * math.sin(angle)
    local z = origin.z
    local found, roadCoord = GetNthClosestVehicleNode(x, y, z, 1, 3.0, 0.0)
    return found and roadCoord or vec3(x, y, z)
end
