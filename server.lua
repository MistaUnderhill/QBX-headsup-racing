local QBCore = exports['qb-core']:GetCoreObject()
local activeRace = false
local raceParticipants = {}
local checkpoint = nil

RegisterNetEvent('qb-street-race:startRaceServer')
AddEventHandler('qb-street-race:startRaceServer', function()
    local src = source
    local players = QBCore.Functions.GetPlayers()
    local initiator = QBCore.Functions.GetPlayer(src)
    local coords = GetEntityCoords(GetPlayerPed(src))

    if activeRace then
        TriggerClientEvent('QBCore:Notify', src, "A race is already in progress.", "error")
        return
    end

    raceParticipants = {}

    for _, id in ipairs(players) do
        local player = QBCore.Functions.GetPlayer(id)
        if player and player.PlayerData.job.name ~= "police" then
            local ped = GetPlayerPed(id)
            if IsPedInAnyVehicle(ped, false) then
                local pos = GetEntityCoords(ped)
                if #(pos - coords) <= Config.JoinDistance then
                    local bank = player.Functions.GetMoney("bank")
                    if bank >= Config.BuyInAmount then
                        player.Functions.RemoveMoney("bank", Config.BuyInAmount, "street-race-buyin")
                        raceParticipants[#raceParticipants + 1] = id
                        TriggerClientEvent('QBCore:Notify', id, "You’ve joined the race!", "success")
                    else
                        TriggerClientEvent('QBCore:Notify', id, "Not enough money for race entry.", "error")
                    end
                end
            end
        end
    end

    if #raceParticipants < 2 then
        for _, id in ipairs(raceParticipants) do
            local p = QBCore.Functions.GetPlayer(id)
            if p then
                p.Functions.AddMoney("bank", Config.BuyInAmount, "race-refund")
                TriggerClientEvent('QBCore:Notify', id, "Race canceled. Not enough players.", "error")
            end
        end
        raceParticipants = {}
        return
    end

    checkpoint = GetRandomCheckpoint(coords)
    activeRace = true

    for _, id in ipairs(raceParticipants) do
        TriggerClientEvent('qb-street-race:startClientRace', id, checkpoint)
    end
end)

RegisterNetEvent('qb-street-race:finishRace')
AddEventHandler('qb-street-race:finishRace', function()
    local src = source
    if not activeRace then return end

    local winner = QBCore.Functions.GetPlayer(src)
    if not winner then return end

    local totalPot = Config.BuyInAmount * #raceParticipants
    local tax = math.floor(totalPot * Config.TaxPercent)
    local payout = totalPot - tax

    winner.Functions.AddMoney("bank", payout, "street-race-win")

    MySQL.insert([[
        INSERT INTO street_race_leaderboard (identifier, name, wins)
        VALUES (?, ?, 1)
        ON DUPLICATE KEY UPDATE wins = wins + 1, name = VALUES(name)
    ]], {
        winner.PlayerData.citizenid,
        winner.PlayerData.charinfo.firstname .. ' ' .. winner.PlayerData.charinfo.lastname
    })

    for _, id in ipairs(raceParticipants) do
        if id ~= src then
            TriggerClientEvent('QBCore:Notify', id, "You lost the race!", "error")
        end
    end

    TriggerClientEvent('QBCore:Notify', src, ("You won $%d!"):format(payout), "success")

    raceParticipants = {}
    activeRace = false
end)

RegisterNetEvent('qb-street-race:getLeaderboard')
AddEventHandler('qb-street-race:getLeaderboard', function()
    local src = source
    MySQL.query("SELECT name, wins FROM street_race_leaderboard ORDER BY wins DESC LIMIT 10", {}, function(results)
        for i, row in ipairs(results) do
            TriggerClientEvent('chat:addMessage', src, {
                args = { string.format("%d. %s - %d wins", i, row.name, row.wins) }
            })
        end
    end)
end)

function GetRandomCheckpoint(origin)
    local x = origin.x + math.random(Config.MinDistance, Config.MaxDistance)
    local y = origin.y + math.random(Config.MinDistance, Config.MaxDistance)
    local z = origin.z
    return vector3(x, y, z)
end
