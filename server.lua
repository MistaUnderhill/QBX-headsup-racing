local QBCore = exports['qbx-core']:GetCoreObject()
local participants = {}
local raceData = {
    isActive = false,
    buyIn = 0,
    coords = nil
}

local function resetRace()
    for _, data in pairs(participants) do
        local src = data.src
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.SetMetaData('inrace', false)
        end
        TriggerClientEvent('qbx-street-racing:unlockPlayer', src)
        TriggerClientEvent('qbx-street-racing:resetInviteFlag', src)
    end
    participants = {}
    readyStatus = {}
    raceData = { isActive = false, buyIn = 0, coords = nil }
end



RegisterNetEvent('qbx-street-racing:startRaceRadial', function(buyIn)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if raceData.isActive then
        TriggerClientEvent('QBCore:Notify', src, 'A race is already in progress!', 'error')
        return
    end

    raceData.isActive = true
    raceData.confirmationOpen = true  -- <---- Set confirmation open here

    if not buyIn or type(buyIn) ~= "number" or buyIn < Config.MinBuyIn or buyIn > Config.MaxBuyIn then
        TriggerClientEvent('QBCore:Notify', src, 'Buy-in must be between $'..Config.MinBuyIn..' and $'..Config.MaxBuyIn, 'error')
        raceData.isActive = false
        raceData.confirmationOpen = false  -- Also reset if invalid
        return
    end

    -- Initialize participant list
    participants = {}

    local players = QBCore.Functions.GetPlayers()
    for _, id in ipairs(players) do
        if #participants >= Config.MaxRacers then break end
        if id ~= src then
            local inRaceMeta = QBCore.Functions.GetPlayerMeta(id, 'inrace')
            if not inRaceMeta then
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
    end

    participants[#participants+1] = { src = src, confirmed = true }
    QBCore.Functions.SetPlayerMeta(src, 'inrace', true)
    raceData.buyIn = buyIn

    CreateThread(function()
        Wait(Config.ConfirmationTimeout * 1000)

        raceData.confirmationOpen = false  -- <---- Set confirmation closed here

        -- Cleanup: Remove declined/unconfirmed participants
        local confirmedParticipants = {}
        for _, p in pairs(participants) do
            if p.confirmed then
                table.insert(confirmedParticipants, p)
            else
                local player = QBCore.Functions.GetPlayer(p.src)
                if player then
                    player.Functions.SetMetaData('inrace', false)
                end
                TriggerClientEvent('QBCore:Notify', p.src, 'You declined the race or did not respond.', 'error')
            end
        end
        participants = confirmedParticipants

        local readyCount = #participants

        if readyCount < 2 then
            for _, p in pairs(participants) do
                TriggerClientEvent('QBCore:Notify', p.src, 'Racers not ready, race cancelled', 'error')
            end
            resetRace()
            return
        end

        -- Deduct buy-in from race initiator
        local initiator = QBCore.Functions.GetPlayer(src)
        if initiator and initiator.Functions.RemoveMoney('cash', raceData.buyIn, "street-race-buyin") then
            QBCore.Functions.SetPlayerMeta(src, 'inrace', true)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Insufficient funds to start the race.', 'error')
            resetRace()
            return
        end

        -- Generate destination within ±100m of Config.RaceDistance
        local origin = GetEntityCoords(GetPlayerPed(src))
        local found, coords

        local nodeSpacing = 10 -- assumed node spacing in meters
        local minNodeIndex = math.floor((Config.RaceDistance - 100) / nodeSpacing)
        local maxNodeIndex = math.floor((Config.RaceDistance + 100) / nodeSpacing)

        for i = minNodeIndex, maxNodeIndex do
            local nodeFound, nodeCoords = GetNthClosestVehicleNode(origin.x, origin.y, origin.z, i, 0, 0, 0)
            if nodeFound then
                local distFromOrigin = #(vector3(origin.x, origin.y, origin.z) - nodeCoords)
                if distFromOrigin >= (Config.RaceDistance - 100) and distFromOrigin <= (Config.RaceDistance + 100) then
                    found = true
                    coords = nodeCoords
                    break
                end
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
    end)
end)


RegisterNetEvent('qbx-street-racing:confirmRace', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if not raceData.confirmationOpen then
        TriggerClientEvent('QBCore:Notify', src, 'Race confirmation has expired.', 'error')
        return
    end

    for i, p in pairs(participants) do
        if p.src == src then
            if not p.confirmed then
                if player.Functions.RemoveMoney('cash', raceData.buyIn, "street-race-buyin") then
                    participants[i].confirmed = true
                    player.Functions.SetMetaData('inrace', true)
                    TriggerClientEvent('QBCore:Notify', src, 'You have joined the race!', 'success')
                else
                    TriggerClientEvent('QBCore:Notify', src, 'Insufficient funds for buy-in.', 'error')
                end
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

    -- Prevent negative or zero payout
    if payout <= 0 then
        payout = 0
        QBCore.Functions.Notify(src, 'You won the race, but the tax took all your winnings.', 'error')
    else
        Player.Functions.AddMoney('cash', payout)
        QBCore.Functions.Notify(src, 'You won the race! Payout: $'..payout)
    end

    -- Always record the win, even with zero payout
    local wins = Player.PlayerData.metadata['racewins'] or 0
    Player.Functions.SetMetaData('racewins', wins + 1)

    resetRace()
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    for i, p in ipairs(participants) do
        if p.src == src then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                Player.Functions.SetMetaData('inrace', false)
            end
            table.remove(participants, i)
            break
        end
    end
end)


RegisterNetEvent('qbx-street-racing:requestLeaderboard', function()
    local src = source
    local results = MySQL.query.await('SELECT metadata FROM players')
    local leaderboard = {}

    for _, result in pairs(results) do
        local metadata = json.decode(result.metadata or '{}')
        local rpName = metadata['charinfo'] and metadata['charinfo']['firstname'] .. ' ' .. metadata['charinfo']['lastname'] or 'Unknown'
        local wins = metadata['racewins'] or 0
        if wins > 0 then
            table.insert(leaderboard, {
                name = rpName,
                wins = wins
            })
        end
    end

    table.sort(leaderboard, function(a, b) return a.wins > b.wins end)
    TriggerClientEvent('qbx-street-racing:showLeaderboard', src, leaderboard)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    local players = QBCore.Functions.GetPlayers()
    for _, src in pairs(players) do
        TriggerClientEvent('qbx-street-racing:resetInviteFlag', src)
    end
end)

AddEventHandler('playerSpawned', function()
    local src = source
    TriggerClientEvent('qbx-street-racing:resetInviteFlag', src)
end)
