Config = {}


Config.UseNPC = true
Config.NPCModel = "a_f_m_bodybuild_01"
Config.NPCCoords = vector3(-66.66, -1350.37, 29.31)

-- only effective when Config.useNPC is set to false
Config.startLocation = vector3(-74.47, -1346.49, 29.29)


Config.CooldownMessage = "Can't find any trucks at this moment.."
Config.BankTruckSpawnMessage = "Find the banktruck and steal the goods!"
Config.PoliceInteractionMessage = "fuck off, cop"


Config.RequiredItem = "thermite"
Config.NoRequireditem = "How are you supposed to blow the doors off?"


Config.MinimumCops = 0
Config.CooldownTime = 120 -- cooldown in seconds
Config.BankTruckModel = "stockade"
Config.Locations = {
    vector3(878.67, -89.18, 79.27),
    vector3(1984.7, -930.32, 79.2),
    vector3(26.39, -2624.35, 6.0),
    vector3(2557.14, 2630.62, 37.92),
    vector3(2599.64, 5306.16, 44.62),
    vector3(-2659.26, 2294.4, 22.6),
    vector3(-383.27, 5973.19, 31.64),
    vector3(-1359.01, -673.38, 25.53)
}


Config.RestricedJob = "police"
Config.FrontGuardModel = 's_m_m_armoured_01'
Config.BackGuardModel = 's_m_m_armoured_01'

Config.FrontGuardWeapon = 'WEAPON_CARBINERIFLE'
Config.BackGuardWeapon = 'WEAPON_SMG'

Config.GuardHealth = 300
Config.GuardArmor = 50
-- Config.GuardHealth = 100 -- 1shot
-- Config.GuardArmor = 5
Config.GuardAccuracy = 80 
Config.GuardLootItem = "lighter"


Config.DoorExplodeTime = 10 -- seconds

Config.minPayout = 10000
Config.maxPayout = 30000
Config.CashItem = "markedbills"

Config.LootChance = 75
Config.LootPool = {'security_card_01', 'thermite', 'heavyarmor'}
