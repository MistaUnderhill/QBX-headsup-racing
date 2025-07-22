local QBCore = exports['qbx-core']:GetCoreObject()
local raceParticipants = {}
local raceInProgress = false
local checkpoint = nil
local COUNTDOWN_TIME = 3 -- seconds

-- Handle player joining the race
RegisterNetEvent('streetrace:playerReady')
AddEventHandler('streetrace:playerReady', function(buyIn)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveMoney("bank", buyIn, "street-race-buyin") then
        raceParticipants[src] = { name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, accepted = true, buyIn = buyIn }
        TriggerClientEvent('streetrace:notify', src, "You joined the race for $" .. buyIn)

        -- If race has enough players, start countdown and race
        if CountAcceptedPlayers() >= 2 and not raceInProgress then
            raceInProgress = true
            checkpoint = GetValidTrafficNode(GetEntityCoords(GetPlayerPed(src)), Config.RaceDistance)
            StartRaceCountdown(GetAcceptedPlayers(), checkpoint)
        end
    else
        TriggerClientEvent('streetrace:notify', src, "Not enough money in bank.")
    end
end)

-- Handle player declining
RegisterNetEvent('streetrace:playerDecline')
AddEventHandler('streetrace:playerDecline', function()
    local src = source
    raceParticipants[src] = nil
    TriggerClientEvent('streetrace:notify', src, "You declined the race.")
end)

-- Handle race completion
RegisterNetEvent('streetrace:finished')
AddEventHandler('streetrace:finished', function()
    local src = source
    if raceInProgress and raceParticipants[src] then
        local totalPot = 0
        for id, data in pairs(raceParticipants) do
            totalPot = totalPot + data.buyIn
        end

        local tax = Config.RaceTax and math.floor(totalPot * Config.RaceTax) or 0
        local winnings = totalPot - tax

        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney("bank", winnings, "street-race-winnings")
            MySQL.update('UPDATE streetrace_leaderboard SET wins = wins + 1 WHERE identifier = ?', { Player.PlayerData.citizenid })

            TriggerClientEvent('streetrace:notify', src, "You won the race and earned $" .. winnings)
        end

        -- Reset state
        raceParticipants = {}
        raceInProgress = false
        checkpoint = nil
    end
end)

-- Leaderboard fetch callback
QBCore.Functions.CreateCallback('streetrace:getLeaderboard', function(_, cb)
    MySQL.query('SELECT * FROM streetrace_leaderboard ORDER BY wins DESC LIMIT 10', {}, function(results)
        cb(results)
    end)
end)

-- Setup player in leaderboard DB
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local Player = QBCore.Functions.GetPlayer(player)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        MySQL.query('SELECT * FROM streetrace_leaderboard WHERE identifier = ?', { citizenid }, function(result)
            if not result[1] then
                MySQL.insert('INSERT INTO streetrace_leaderboard (identifier, name, wins) VALUES (?, ?, ?)', {
                    citizenid,
                    Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                    0
                })
            end
        end)
    end
end)

-- Helper: Count accepted players
function CountAcceptedPlayers()
    local count = 0
    for _, data in pairs(raceParticipants) do
        if data.accepted then count = count + 1 end
    end
    return count
end

-- Helper: Get list of accepted players
function GetAcceptedPlayers()
    local list = {}
    for playerId, data in pairs(raceParticipants) do
        if data.accepted then
            table.insert(list, playerId)
        end
    end
    return list
end

-- Start countdown, lock players, then start race
function StartRaceCountdown(racers, checkpoint)
    for _, playerId in pairs(racers) do
        TriggerClientEvent('streetrace:lockPlayer', playerId, true)
        TriggerClientEvent('streetrace:startCountdown', playerId, COUNTDOWN_TIME)
    end

    Citizen.SetTimeout(COUNTDOWN_TIME * 1000, function()
        for _, playerId in pairs(racers) do
            TriggerClientEvent('streetrace:lockPlayer', playerId, false)
            TriggerClientEvent('streetrace:startRace', playerId, checkpoint)
        end
    end)
end

-- Ensure checkpoint is on a road near origin within given distance
function GetValidTrafficNode(origin, distance)
    local attempts = 20
    while attempts > 0 do
        local angle = math.random() * 2 * math.pi
        local offset = vector3(
            math.cos(angle) * distance,
            math.sin(angle) * distance,
            0.0
        )
        local testPos = origin + offset
        local found, road = GetClosestVehicleNode(testPos.x, testPos.y, testPos.z, 1, 3.0, 0)
        if found then return vector3(road.x, road.y, road.z) end
        attempts = attempts - 1
    end
    return origin -- fallback
end
