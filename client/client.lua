local QBCore = exports['qb-core']:GetCoreObject()
lastInteractionTime = 0
local npc = nil
local bankTruck = nil
local driver = nil
local passenger = nil
local guards = {}
local hasKeyItem = false
local c4Planted = false
local keyGuard = nil
local lootCollected = false
local speedingUp = false
local bankTruckBlip = nil

function loadModel(model)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 1000 do
        timeout = timeout + 1
        Wait(10)
    end
    return HasModelLoaded(model)
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        lastHeistTime = 0  
    end
end)

Citizen.CreateThread(function()
    if Config.UseNPC then
        if not loadModel(GetHashKey(Config.NPCModel)) then return end

        npc = CreatePed(1, GetHashKey(Config.NPCModel), Config.NPCCoords.x, Config.NPCCoords.y, Config.NPCCoords.z - 1, 280.0, true, true)
        SetEntityAsMissionEntity(npc, true, true)
        SetPedCanRagdoll(npc, false)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetEntityInvincible(npc, true)
        SetPedDiesWhenInjured(npc, false)
        FreezeEntityPosition(npc, true)

        exports['qb-target']:AddEntityZone('dj-banktruck_startJob', npc, {
            name = "dj-banktruck_startJob",
            debugPoly = false,
        }, {
            options = {
                {
                    num = 1,
                    type = "client",
                    event = "dj-banktruck:startJob",
                    icon = 'fas fa-comments',
                    label = 'Check for information about trucks',
                    action = function(entity)
                        if IsPedAPlayer(entity) then return false end
                        TriggerServerEvent('dj-banktruck:requestStartJob')
                    end
                }
            },
            distance = 2.5,
        })
    else
        exports['qb-target']:AddBoxZone('dj-banktruck_startJob', Config.startLocation, 1, 1, {
            name = "dj-banktruck_startJob",
            debugPoly = false,
        }, {
            options = {
                {
                    num = 1,
                    type = "client",
                    event = "dj-banktruck:startJob",
                    icon = 'fas fa-comments',
                    label = 'Check for information about trucks',
                    action = function(entity)
                        TriggerServerEvent('dj-banktruck:requestStartJob')
                    end
                }
            },
            distance = 2.5,
        })
    end
end)

RegisterNetEvent('dj-banktruck:startJob')
AddEventHandler('dj-banktruck:startJob', function()
    local playerData = QBCore.Functions.GetPlayerData()
    
    if playerData.job.name == Config.RestrictedJob then
        QBCore.Functions.Notify(Config.PoliceInteractionMessage, 'error')
        return
    end

    local hasItem = exports['qb-inventory']:HasItem(Config.RequiredItem)
    if not hasItem then
        QBCore.Functions.Notify(Config.NoRequireditem, 'error')
        return
    end

    if bankTruck ~= nil then
        DeleteEntity(bankTruck)
        RemoveBlip(bankTruckBlip) 
        bankTruck = nil
    end

    exports['scully_emotemenu']:playEmoteByCommand("argue2")
    QBCore.Functions.Progressbar("bj-banktruck-information-about-truck", "Getting information about truck...", 4000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        exports['scully_emotemenu']:cancelEmote()
        startBankTruckJob() 
    end)
end)

function startBankTruckJob()
    lastInteractionTime = GetGameTimer()
    spawnBankTruck()
    QBCore.Functions.Notify(Config.BankTruckSpawnMessage, "success")
end

function spawnBankTruck()
    local random = math.random(1, #Config.Locations)
    local spawnLoc = Config.Locations[random]

    if not loadModel(GetHashKey(Config.BankTruckModel)) then return end

    bankTruck = CreateVehicle(GetHashKey(Config.BankTruckModel), spawnLoc.x, spawnLoc.y, spawnLoc.z, 0.0, true, false)
    SetEntityAsMissionEntity(bankTruck, true, true)

    if not DoesEntityExist(bankTruck) then
        QBCore.Functions.Notify("Failed to spawn bank truck", "error")
        return
    end

    createBankTruckBlip(bankTruck)
    spawnGuardsInVehicle(bankTruck)

    TaskVehicleDriveWander(driver, bankTruck, 20.0, 786468)

    Citizen.CreateThread(function()
        while DoesEntityExist(bankTruck) do
            local coords = GetEntityCoords(bankTruck)
            SetBlipCoords(bankTruckBlip, coords.x, coords.y, coords.z)
            checkFrontGuardsDead()
            Wait(1000)
        end
    end)

    setupThirdEyeForBackDoor()
end

function createBankTruckBlip(truck)
    if bankTruckBlip ~= nil then
        RemoveBlip(bankTruckBlip)
    end

    bankTruckBlip = AddBlipForEntity(truck)
    SetBlipSprite(bankTruckBlip, 67)
    SetBlipScale(bankTruckBlip, 1.0)
    SetBlipColour(bankTruckBlip, 1)
    SetBlipAsShortRange(bankTruckBlip, false)
    SetBlipFlashes(bankTruckBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Bank Truck")
    EndTextCommandSetBlipName(bankTruckBlip)
end

function removeBankTruckBlip()
    if bankTruckBlip ~= nil then
        RemoveBlip(bankTruckBlip)
        bankTruckBlip = nil
    end
end

function setupGuard(guardModel, truck, seat, weapon, health, armor, guardGroup, guardId)
    local guard = CreatePed(4, GetHashKey(guardModel), 0.0, 0.0, 0.0, 0.0, true, true)
    SetEntityHealth(guard, health)
    SetPedArmour(guard, armor)
    GiveWeaponToPed(guard, GetHashKey(weapon), 1000, false, true)
    SetPedIntoVehicle(guard, truck, seat)
    SetPedCanRagdoll(guard, false)
    SetPedSuffersCriticalHits(guard, true)
    SetEntityProofs(guard, false, true, true, false, false, false, false, false)

    SetPedRelationshipGroupHash(guard, GetHashKey("COP")) 
    SetPedRelationshipGroupHash(guard, guardGroup)

    SetPedCombatAttributes(guard, 46, true)
    SetPedCombatAttributes(guard, 5, true)
    SetPedCombatAttributes(guard, 2, true)
    SetPedCombatMovement(guard, 2)
    SetPedFleeAttributes(guard, 0, false)
    SetPedAccuracy(guard, Config.GuardAccuracy)
    SetPedAlertness(guard, 3)
    DisablePedPainAudio(guard, true)

    if seat == -1 then
        driver = guard
        setupThirdEyeForGuardLoot(guard, guardId)
    elseif seat == 0 then
        passenger = guard
    end

    return guard
end

function spawnGuardsInVehicle(truck)
    local guardGroup = AddRelationshipGroup("guards")
    
    SetRelationshipBetweenGroups(0, guardGroup, guardGroup)
    SetRelationshipBetweenGroups(5, guardGroup, GetHashKey("PLAYER"))
    
    guards = {}
    local seats = {-1, 0, 1, 2} 
    local models = {Config.FrontGuardModel, Config.FrontGuardModel, Config.BackGuardModel, Config.BackGuardModel}
    local weapons = {Config.FrontGuardWeapon, Config.FrontGuardWeapon, Config.BackGuardWeapon, Config.BackGuardWeapon}
    
    local passengerTaskAssigned = false
    local backGuardTasksAssigned = {false, false}
    
    for i = 1, #seats do
        guards[i] = setupGuard(models[i], truck, seats[i], weapons[i], Config.GuardHealth, Config.GuardArmor, guardGroup, i)
    end
    
    Citizen.CreateThread(function()
        while DoesEntityExist(bankTruck) do
            if IsPedDeadOrDying(driver, true) then
                if not IsPedDeadOrDying(passenger, true) and not passengerTaskAssigned then
                    TaskLeaveVehicle(passenger, bankTruck, 0)
                    Citizen.Wait(800)
                    TaskCombatPed(passenger, GetPlayerPed(-1), 0, 16)
                    passengerTaskAssigned = true
                end
            elseif IsPedDeadOrDying(passenger, true) then
                TaskVehicleDriveWander(driver, bankTruck, 20.0, 786468)
            end
            Citizen.Wait(1000)
        end
    end)
end

function setupThirdEyeForGuardLoot(guard, guardId)
    if not DoesEntityExist(guard) then
        return
    end

    exports['qb-target']:AddTargetEntity(guard, {
        options = {
            {
                type = "client",
                event = "dj-banktruck:tryLootDriver",
                icon = 'fas fa-box-open',
                label = 'Loot the driver',
                canInteract = function()
                    return IsPedDeadOrDying(guard, true)
                end,
                action = function(entity)
                    TriggerEvent('dj-banktruck:tryLootDriver', guardId)
                end
            }
        },
        distance = 2.5
    })
end

RegisterNetEvent('dj-banktruck:tryLootDriver')
AddEventHandler('dj-banktruck:tryLootDriver', function(guardId)
    exports['scully_emotemenu']:playEmoteByCommand("kneel2")
    QBCore.Functions.Progressbar("loot_guard", "Searching the driver...", 8000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        exports['scully_emotemenu']:cancelEmote()
        TriggerServerEvent('dj-banktruck:lootDriver', guardId)
    end, function()
        exports['scully_emotemenu']:cancelEmote()
    end)
end)

RegisterNetEvent('dj-banktruck:receiveLootDriver')
AddEventHandler('dj-banktruck:receiveLootDriver', function(guardId)
    QBCore.Functions.Notify('You found something!', 'success')

    if guards[guardId] then
        exports['qb-target']:RemoveTargetEntity(guards[guardId]) 
    end

    setupThirdEyeForBackDoor()  
end)

RegisterNetEvent('dj-banktruck:removeThermiteInteraction')
AddEventHandler('dj-banktruck:removeThermiteInteraction', function()
    exports['qb-target']:RemoveTargetEntity(bankTruck) 
end)

RegisterNetEvent('dj-banktruck:removeTruckInteraction')
AddEventHandler('dj-banktruck:removeTruckInteraction', function()
    exports['qb-target']:RemoveTargetEntity(bankTruck) 
end)

function setupThirdEyeForBackDoor()
    exports['qb-target']:AddTargetEntity(bankTruck, {
        options = {
            {
                type = "client",
                event = "dj-banktruck:plantThermite",
                icon = 'fas fa-bomb',
                label = 'Plant Thermite',
                canInteract = function()
                    return not c4Planted
                end
            }
        },
        distance = 2.5
    })
end

RegisterNetEvent('dj-banktruck:plantThermite')
AddEventHandler('dj-banktruck:plantThermite', function()
    local hasThermite = exports['qb-inventory']:HasItem(Config.RequiredItem)
    local hasGuardLoot = exports['qb-inventory']:HasItem(Config.GuardLootItem)

    if hasThermite and hasGuardLoot then
        exports['scully_emotemenu']:playEmoteByCommand("tablet2") 
        local success = exports['SN-Hacking']:Thermite(7, 5, 10000, 2, 2, 3000)
        if success then
            exports['scully_emotemenu']:cancelEmote()
            TriggerServerEvent('dj-banktruck:removePlantItems') 
            QBCore.Functions.Notify('Thermite planted! Stand back!', 'error')
            TriggerServerEvent('dj-banktruck:syncRemoveInteraction', "thermite")
            Citizen.SetTimeout(Config.DoorExplodeTime * 1000, function()
                explodeTruckDoors()
                releaseBackGuards()
                setupThirdEyeForLooting()
            end)
        else
            exports['scully_emotemenu']:cancelEmote()
            QBCore.Functions.Notify('Failed to plant the thermite!', 'error')
        end
    else
        QBCore.Functions.Notify('You are missing something!', 'error')
    end
end)

function releaseBackGuards()
    local playerPed = GetPlayerPed(-1)
    
    for i = 3, 4 do 
        if DoesEntityExist(guards[i]) and not IsPedDeadOrDying(guards[i], true) then
            SetEntityProofs(guards[i], false, true, true, false, false, false, false, false)
            TaskLeaveVehicle(guards[i], bankTruck, 0)
            Citizen.Wait(800)
            TaskCombatPed(guards[i], playerPed, 0, 16)
        end
    end
end

function setupThirdEyeForLooting()
    exports['qb-target']:AddTargetEntity(bankTruck, {
        options = {
            {
                type = "client",
                event = "dj-banktruck:tryLootTruck",
                icon = 'fas fa-box-open',
                label = 'Loot the truck',
                canInteract = function()
                    return not lootCollected
                end
            }
        },
        distance = 2.5
    })
end


function explodeTruckDoors()
    local truckCoords = GetEntityCoords(bankTruck)
    AddExplosion(truckCoords.x, truckCoords.y, truckCoords.z - 1, 2, 1.0, true, false, 1.0, true)

    SetVehicleDoorBroken(bankTruck, 2, true)
    SetVehicleDoorBroken(bankTruck, 3, true)
end

RegisterNetEvent('dj-banktruck:tryLootTruck')
AddEventHandler('dj-banktruck:tryLootTruck', function()
    exports['scully_emotemenu']:playEmoteByCommand("mechanic") 
    QBCore.Functions.Progressbar("loot_truck", "Looting the truck...", 10000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() 
        exports['scully_emotemenu']:cancelEmote()
        lootCollected = true
        TriggerServerEvent('dj-banktruck:addLoot', math.random(Config.minPayout, Config.maxPayout), Config.LootPool[math.random(1, #Config.LootPool)])
        exports['qb-target']:RemoveTargetEntity(bankTruck) 
        TriggerServerEvent('dj-banktruck:syncRemoveInteraction', "truck") 
    end, function()
        exports['scully_emotemenu']:cancelEmote()
    end)
end)

RegisterNetEvent('dj-banktruck:receiveTruckLoot')
AddEventHandler('dj-banktruck:receiveTruckLoot', function(payout, lootItem)
    QBCore.Functions.Notify('You looted $' .. payout .. ' and found: ' .. lootItem, 'success')
end)

function IsVehicleBeingDamaged(vehicle)
    local currentHealth = GetEntityHealth(vehicle)
    return currentHealth < GetEntityMaxHealth(vehicle)
end

function checkFrontGuardsDead()
    if IsPedDeadOrDying(guards[1], true) and IsPedDeadOrDying(guards[2], true) then
        removeBankTruckBlip()
    end
end

