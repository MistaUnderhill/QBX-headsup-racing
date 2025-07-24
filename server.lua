local QBCore = exports['qbx-core']:GetCoreObject()
local participants = {}
local readyStatus = {}
local raceData = {
    isActive = false,
    buyIn = 0,
    coords = nil
}

local function resetRace()
    for _, data in pairs(participants) do
        local src = data.src
        QBCore.Functions.SetPlayerMeta(src, 'inrace', false)
        TriggerClientEvent('qbx-street-racing:unlockPlayer', src)
    end
    participants = {}
    readyStatus = {}
    raceData = { isActive = false, buyIn = 0, coords = nil }
end

RegisterNetEvent('qbx-street-racing:startRaceRadial', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if raceData.isActive then
        TriggerClientEvent('QBCore:Notify', src, 'A race is already in progress!', 'error')
        return
    end

    local buyIn = 0
    TriggerClientEvent('QBCore:Notify', src, 'Set your buy-in between $'..Config.MinBuyIn..' - $'..Config.MaxBuyIn, 'primary')
    
    -- For simplicity in this example, we're setting static buyIn
    buyIn = Config.MinBuyIn

    local players = QBCore.Functions.GetPlayers()
    for _, id in ipairs(players) do
        if #participants >= Config.MaxRacers then break end
        if id ~= src then
            local targetPed = GetPlayerPed(id)
            if IsPedInAnyVehicle(targetPed, false) then
                local dist = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(targetPed))
                if dist < Config.JoinDistance then
                    participants[#participants+1] = { src = id, confirmed = false }
                    QBCore.Functions.SetPlayerMeta(id, 'inrace', true)
                    TriggerClientEvent('qbx-street-racing:inviteToRace', id)
                end
            end
        end
    end

    participants[#participants+1] = { src = src, confirmed = true }
    QBCore.Functions.SetPlayerMeta(src, 'inrace', true)
    raceData.buyIn = buyIn
    raceData.isActive = true

    CreateThread(function()
        Wait(Config.ConfirmationTimeout * 1000)
        local readyCount = 0
        for _, p in pairs(participants) do
            if p.confirmed then readyCount += 1 end
        end

        if readyCount < 2 then
            for _, p in pairs(participants) do
                TriggerClientEvent('QBCore:Notify', p.src, 'Racers not ready, race cancelled', 'error')
            end
            resetRace()
            return
        end

-- Generate destination
local origin = GetEntityCoords(GetPlayerPed(src))
local found, coords
local maxAttempts = 20 -- Max number of node search attempts

for i = 1, maxAttempts do
    found, coords = GetNthClosestVehicleNode(origin.x, origin.y, origin.z, i * 5, 0, 0, 0)
    if found then
        break
    end
end

if not found then
    TriggerClientEvent('QBCore:Notify', src, 'Could not find a valid race destination after multiple attempts!', 'error')
    resetRace()
    return
end

raceData.coords = coords

for _, p in pairs(participants) do
    if p.confirmed then
        TriggerClientEvent('qbx-street-racing:lockPlayer', p.src)
        TriggerClientEvent('qbx-street-racing:setCheckpoint', p.src, coords)
        TriggerClientEvent('qbx-street-racing:startCountdown', p.src)
    end
end


RegisterNetEvent('qbx-street-racing:confirmRace', function()
    local src = source
    for i, p in pairs(participants) do
        if p.src == src then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player.Functions.RemoveMoney('cash', raceData.buyIn) then
                participants[i].confirmed = true
                QBCore.Functions.Notify(src, 'Buy-in accepted, you are race ready.')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Not enough cash for buy-in.', 'error')
                participants[i].confirmed = false
            end
            break
        end
    end
end)

RegisterNetEvent('qbx-street-racing:declineRace', function()
    local src = source
    for i, p in pairs(participants) do
        if p.src == src then
            participants[i].confirmed = false
            break
        end
    end
end)

RegisterNetEvent('qbx-street-racing:unlockPlayer', function()
    local src = source
    TriggerClientEvent('qbx-street-racing:unlockPlayer', src)
end)

RegisterNetEvent('qbx-street-racing:finishRace', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local winnings = raceData.buyIn * #participants
    local tax = Config.RaceTax * winnings
    local payout = math.floor(winnings - tax)

    Player.Functions.AddMoney('cash', payout)
    local wins = Player.PlayerData.metadata['racewins'] or 0
    Player.Functions.SetMetaData('racewins', wins + 1)
    QBCore.Functions.Notify(src, 'You won the race! Payout: $'..payout)

    resetRace()
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    for i, p in ipairs(participants) do
        if p.src == src then
            table.remove(participants, i)
            break
        end
    end
end)

RegisterNetEvent('qbx-street-racing:requestLeaderboard', function()
    local src = source
    local results = MySQL.query.await('SELECT name, metadata FROM players')
    local leaderboard = {}

    for _, result in pairs(results) do
        local metadata = json.decode(result.metadata or '{}')
        if metadata['racewins'] then
            table.insert(leaderboard, {
                name = result.name,
                wins = metadata['racewins']
            })
        end
    end

    table.sort(leaderboard, function(a, b) return a.wins > b.wins end)
    TriggerClientEvent('qbx-street-racing:showLeaderboard', src, leaderboard)
end)
