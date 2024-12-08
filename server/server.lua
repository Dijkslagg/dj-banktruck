QBCore = exports['qb-core']:GetCoreObject()

local lastHeistTime = 0
local cooldownTime = Config.CooldownTime 
local lootedGuards = {}
local truckLooted = false



AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("[dj-banktruck] Resource started, resetting cooldown.")
        lastHeistTime = 0 
        truckLooted = false
        lootedGuards = {}
        TriggerClientEvent('dj-banktruck:cleanupTruck', -1)
    end
end)


RegisterNetEvent('dj-banktruck:addLoot')
AddEventHandler('dj-banktruck:addLoot', function(payout, loot)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    local success = Player.Functions.AddItem(Config.CashItem, payout)
    if success then
        TriggerClientEvent('QBCore:Notify', src, 'You looted: $' .. payout .. ' in marked bills!', 'success')
    end


    local chance = math.random(1, 100)
    if chance <= Config.LootChance then
        local lootSuccess = Player.Functions.AddItem(loot, 1)
        if lootSuccess then
            TriggerClientEvent('QBCore:Notify', src, 'You found loot: ' .. loot, 'success')
        end
    end
end)

RegisterNetEvent('dj-banktruck:cleanupTruck')
AddEventHandler('dj-banktruck:cleanupTruck', function()
    if bankTruck ~= nil then
        DeleteEntity(bankTruck)
        RemoveBlip(bankTruckBlip)
        bankTruck = nil
    end
end)


RegisterNetEvent('dj-banktruck:lootDriver')
AddEventHandler('dj-banktruck:lootDriver', function(guardId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    if lootedGuards[guardId] then
        TriggerClientEvent('QBCore:Notify', src, 'This guard has already been looted!', 'error')
        return
    end

    lootedGuards[guardId] = true

    local success = Player.Functions.AddItem(Config.GuardLootItem, 1)
    if success then
        TriggerClientEvent('dj-banktruck:receiveLootDriver', src, guardId)
        TriggerClientEvent('dj-banktruck:syncLootedGuard', -1, guardId) 
    end
end)

RegisterNetEvent('dj-banktruck:requestStartJob')
AddEventHandler('dj-banktruck:requestStartJob', function()
    local src = source
    local currentTime = os.time()
    local Player = QBCore.Functions.GetPlayer(src)

    local copsOnline = 0
    local players = QBCore.Functions.GetPlayers()

    for _, playerId in pairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData.job.name == Config.RestrictedJob and Player.PlayerData.job.onduty then
            copsOnline = copsOnline + 1
        end
    end
    if copsOnline < Config.MinimumCops then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough cops!', 'error')
        return
    end
    if not Player.Functions.HasItem(Config.RequiredItem, 1) then
        TriggerClientEvent('QBCore:Notify', src, Config.NoRequireditem, 'error')
        return
    end 
    if (currentTime - lastHeistTime) >= cooldownTime then
        lastHeistTime = currentTime
        truckLooted = false 
        lootedGuards = {}
        TriggerClientEvent('dj-banktruck:startJob', src)
        TriggerClientEvent('dj-banktruck:syncJobState', -1, false, {}) 
    else
        TriggerClientEvent('QBCore:Notify', src, Config.CooldownMessage, 'error')
    end
end)

RegisterNetEvent('dj-banktruck:removePlantItems')
AddEventHandler('dj-banktruck:removePlantItems', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return
    end
    Player.Functions.RemoveItem(Config.GuardLootItem, 1)
    Player.Functions.RemoveItem(Config.RequiredItem, 1)
end)

RegisterNetEvent('dj-banktruck:syncRemoveInteraction')
AddEventHandler('dj-banktruck:syncRemoveInteraction', function(interactionType)
    if interactionType == "thermite" then
        TriggerClientEvent('dj-banktruck:removeThermiteInteraction', -1)
    elseif interactionType == "truck" then
        TriggerClientEvent('dj-banktruck:removeTruckInteraction', -1)
    end
end)
