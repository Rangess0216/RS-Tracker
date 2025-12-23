ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('rs-tracker:payout')
AddEventHandler('rs-tracker:payout', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        if Config.RewardType == 'money' then
            xPlayer.addMoney(Config.RewardAmount)
        else
            xPlayer.addAccountMoney(Config.RewardType, Config.RewardAmount)
        end
    end
end)

RegisterNetEvent('rs-tracker:alertPolice')
AddEventHandler('rs-tracker:alertPolice', function(targetNetId)
    local xPlayers = ESX.GetPlayers()
    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.job.name == 'police' then
            TriggerClientEvent('rs-tracker:setPoliceBlip', xPlayers[i], targetNetId)
        end
    end
end)