local QBCore = exports['qbx-core']:GetCoreObject()
local inRace = false
local inCountdown = false
local checkpoint = nil
local raceBlip = nil

RegisterNetEvent('streetrace:notify', function(msg)
    QBCore.Functions.Notify(msg, "primary")
end)

RegisterNetEvent('streetrace:lockPlayer', function(lock)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, lock)
end)

RegisterNetEvent('streetrace:startCountdown', function(seconds)
    inCountdown = true
    Citizen.CreateThread(function()
        local count = seconds
        while count > 0 do
            Citizen.Wait(0)
            DrawTxt(0.5, 0.4, 1.0, 1.0, 1.0, tostring(count), 255, 0, 0, 255)
            Citizen.Wait(1000)
            count = count - 1
        end
        inCountdown = false
    end)
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

    QBCore.Functions.Notify("Race started! First to the checkpoint wins!", "success")
end)

CreateThread(function()
    while true do
        Citizen.Wait(500)
        if inRace and checkpoint and not inCountdown then
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

-- Helper function to draw text on screen
function DrawTxt(x, y, width, height, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2)
end
