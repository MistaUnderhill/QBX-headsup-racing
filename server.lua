local QBCore = exports['qb-core']:GetCoreObject()
local activeRace = false
local raceParticipants = {}
local checkpoint = nil

RegisterNetEvent('qb-street-race:startRaceServer')
AddEventHandler('qb-street-race:startRaceServer', function()
    local src = source
    if activeRace then
        TriggerClientEvent('QBCore:Notify', src, "A race is already in progress.", "error")
        return
    end

    local initiator = QBCore.Functions.GetPlayer(src)
    local coords = GetEntityCoords(GetPlayerPed(src))
    local allPlayers = QBCore.Functions.GetPlayers()
    local invited = {}

    -- Invite nearby players in vehicles
    for _, id in ipairs(allPlayers) do
        local ped = GetPlayerPed(id)
        if IsPedInAnyVehicle(ped, false) then
            local pos = GetEntityCoords(ped)
            if #(pos - coords) <= Config.JoinDistance then
                TriggerClientEvent('qb-street-race:inviteToRace', id, src)
                table.insert(invited, id)
            end
        end
    end

    if #invited < 2 then
        TriggerClientEvent('QBCore:Notify', src, "Not enough players nearby to start a race.", "error")
        return
    end

    -- Wait for responses
    activeRace = true
    raceParticipants = {}
    checkpoint = GetRandomCheckpoint(coords)

    CreateThread(function()
        Wait(10000) -- 10 second response window

        if #raceParticipants < 2 then
            for _, id in ipairs(raceParticipants) do
                local p = QBCore.Functions.GetPlayer(id)
                if p then
                    p.Functions.AddMoney("bank", Config.BuyInAmount, "race-refund")
                    TriggerClientEvent('QBCore:Notify', id, "Race canceled. Not enough participants.", "error")
                end
            end
            activeRace = false
            raceParticipants = {}
            return
        end

        -- Start race
        for _, id in ipairs(raceParticipants) do
            TriggerClientEvent('qb-street-race:startClientRace', id, checkpoint)
        end
    end)
end)

RegisterNetEvent('qb-street-race:raceResponse')
AddEventHandler('qb-street-race:raceResponse', function(accepted, initiator)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not activeRace then return end

    if accepted then
        local bank = player.Functions.GetMoney("bank")
        if bank >= Config.BuyInAmount then
            player.Functions.RemoveMoney("bank", Config.BuyInAmount, "street-race-buyin")
            table.insert(raceParticipants, src)
            TriggerClientEvent('QBCore:Notify', src, "You’ve joined the race!", "success")
        else
            TriggerClientEvent('QBCore:Notify', src, "Not enough money to join the race.", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You declined the race.", "primary")
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
    local min = Config.MinDistance
    local max = Config.MaxDistance
    local angle = math.random() * 2 * math.pi
    local distance = math.random(min, max)
    
    local x = origin.x + distance * math.cos(angle)
    local y = origin.y + distance * math.sin(angle)
    local z = origin.z

    -- Ensure it's on a road
    local found, roadCoord = GetNthClosestVehicleNode(x, y, 0, 1, 3.0, 0.0)

    if found then
        return roadCoord
    else
        -- Fallback: return origin + forward offset if no node found (very rare)
        return vec3(x, y, z)
    end
end
