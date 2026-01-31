function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team)
end

function CollectPoolCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time)
    local poolExists = DoesScrapPoolExist(team, time)

    if (recyclerExists and poolExists) then
        return true, "Braddock is collecting a pool..."
    else
        return false, "Braddock cannot find a pool..."
    end
end

function CollectFieldCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time)
    local fieldExists = DoesLooseScrapExist(team, time)

    if (recyclerExists and fieldExists) then
        return true, "Braddock is collecting scrap..."
    else
        return false, "Braddock cannot find scrap..."
    end
end

function ScavengerCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time)
    local scavengerCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", 'sameteam', true)

    if (recyclerExists and scavengerCount < 2) then
        return true, "Braddock is building a scavenger..."
    else
        return false, "Braddock has enough scavengers..."
    end
end

function ConstructorCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time)
    local consCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", 'sameteam', true)

    if (recyclerExists and consCount < 1) then
        return true, "Braddock is building a constructor..."
    else
        return false, "Braddock has enough constructors..."
    end
end

function TurretCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time)
    local turretCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", 'sameteam', true)

    if (recyclerExists and turretCount < 4) then
        return true, "Braddock is building a turret..."
    else
        return false, "Braddock has enough turrets..."
    end
end

function RocketTankCondition(team, time)
    if (not DoesFactoryExist(team, time)) then
        return false, "Braddock doesn't have a Factory and can't build any Rocket Tanks..."
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "Braddock doesn't have a Relay Bunker and can't build any Rocket Tanks..."
    end

    if (not DoesArmoryExist(team, time)) then
        return false, "Braddock doesn't have an Armory and can't build any Rocket Tanks..."
    end

    return true, "Tasking Factory to build a Rocket Tank..."
end

function ServiceTruckCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time)

    if (recyclerExists) then
        return true, "Braddock is building a Service Truck..."
    else
        return false, "Braddock has enough Service Trucks..."
    end
end

function BuildAssaultServicers(team, time)
    if (not DoesServiceBayExist(team, time)) then
        return false, "Braddock doesn't have a Service Bay so I can't build any Trucks..."
    end

    local assaultCount = AssaultUnitCount(team, time)

    if (assaultCount <= 0) then
        return false, "Braddock doesn't have any assault units yet..."
    end

    if (AssaultServiceUnitCount(team, time) >= assaultCount) then
        return false, "Braddock has enough servicers for assault units for now..."
    end

    return true, "Building units to service assault units..."
end

function BuildAssaultDefenders(team, time)
    if (not DoesFactoryExist(team, time)) then
        return false, "Braddock doesn't have a Factory and can't build any Tanks..."
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "Braddock doesn't have a Relay Bunker and can't build any Tanks..."
    end

    local assaultCount = AssaultUnitCount(team, time)

    if (assaultCount <= 0) then
        return false, "Braddock doesn't have any assault units yet..."
    end

    if (DefenderUnitCount(team, time) >= assaultCount) then
        return false, "Braddock has enough defenders for assault units for now..."
    end

    return true, "Building units to defend assault units..."
end

function BuildBomber(team, time)
    if (not DoesFactoryExist(team, time)) then
        return false, "Braddock doesn't have a Factory yet...";
    end

    if (not DoesBomberBayExist(team, time)) then
        return false, "Braddock doesn't have a Bomber Bay yet...";
    end

    if (DoesBomberExist(team, time)) then
        return false, "Braddock already has a bomber...";
    end

    return true, "Tasking Factory to build a Bomber...";
end

function ProbeAttackCondition(team, time)
    -- Special case: If the player has an ISDF Gun Tower, do not attack the base.
    -- We need to exclude Yelena's base from these checks.
    -- TODO: Add a custom provide for ISDF / Scion Gun Towers?
    local gunTowerExists = AIPUtil.CountUnits(team, "ibgtow_x", 'enemy', true) > 0

    if (gunTowerExists) then
        return false, "Braddock is not attacking the base: Player has too many Gun Towers..."
    end

    if (not DoesRecyclerExist(team, time)) then
        return false, "Braddock is not attacking the base: Recycler doesn't exist..."
    end

    return true, "Braddock is attacking the base..."
end

function ExtractorAttackCondition(team, time)
    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'enemy', true) <= 0) then
        return false, "Braddock could not find any extractors to attack..."
    end

    if (not DoesRecyclerExist(team, time)) then
        return false, "Braddock is not attacking extractors: Recycler doesn't exist..."
    end

    return true, "Braddock is attacking extractors..."
end

function AntiUnitAttackCondition(team, time)
    if (time > 900) then
        return false, "Too late in the mission to launch anti-unit attacks..."
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "Braddock is not attacking player units: Factory doesn't exist..."
    end

    return true, "Braddock is attacking player units..."
end

function AntiAssaultAttackCondition(team, time)
    if (not DoesPlayerAssaultUnitExist(team, time)) then
        return false, "Braddock can't find any Assault Units to attack..."
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "Braddock is not attacking player assault units: Factory doesn't exist..."
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "Braddock is not attacking player assault units: Relay bunker doesn't exist..."
    end

    return true, "Braddock is attacking player assault units..."
end

function LightAPCAttackCondition(team, time)
    -- So we're not overwhelming the player and spamming units, do this only after 10 minutes.
    if (time < 600) then
        return false, "Too early in the mission to launch APC attacks"
    end

    if (time > 1200) then
        return false, "Too late in the mission to launch weaker APC attacks"
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "Braddock is not attacking with APCs: Factory doesn't exist..."
    end

    if (not DoesTrainingExist(team, time)) then
        return false, "Braddock is not attacking with APCs: Training Facility doesn't exist..."
    end

    return true, "Braddock is sending lighter APC platoon to attack the player..."
end

function HeavyAPCAttackCondition(team, time)
    -- So we're not overwhelming the player and spamming units, do this only after 20 minutes.
    if (time < 1200) then
        return false, "Too early in the mission to launch heavy APC attacks"
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "Braddock is not attacking with APCs: Factory doesn't exist..."
    end

    if (not DoesTrainingExist(team, time)) then
        return false, "Braddock is not attacking with APCs: Training Facility doesn't exist..."
    end

    return true, "Braddock is sending heavier APC platoon to attack the player..."
end

function HeavyBaseAttackCondition(team, time)
    -- So we're not overwhelming the player and spamming units, do this only after 15 minutes.
    if (time < 900) then
        return false, "Too early in the mission to launch Heavy Assault"
    end

    if (not CanBuildAssaultTanks(team, time)) then
        return false, "Braddock can't build any Assault Tanks..."
    end

    if (not CanBuildWalkers(team, time)) then
        return false, "Braddock can't build any Walkers..."
    end

    return true, "Braddock is attacking the Player Base..."
end

function HeavyBaseAttackWithTanksCondition(team, time)
    -- So we're not overwhelming the player and spamming units, do this only after 15 minutes.
    if (time < 900) then
        return false, "Too early in the mission to launch Heavy Assault"
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "Braddock is not attacking with APCs: Factory doesn't exist..."
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "Braddock is not attacking player assault units: Relay bunker doesn't exist..."
    end

    return true, "Braddock is attacking the Player Base..."
end

function GunTowerAttackCondition(team, time)
    local gunTowerExists = AIPUtil.CountUnits(team, "ibgtow_x", 'enemy', true) > 0

    if (not gunTowerExists) then
        return false, "Player has no Gun Towers to attack..."
    end

    if (not CanBuildAssaultTanks(team, time)) then
        return false, "Braddock can't build any Assault Tanks..."
    end

    return true, "Braddock is attacking Gun Towers..."
end

function GunTowerAttackCondition2(team, time)
    local enoughGunTowersExist = AIPUtil.CountUnits(team, "ibgtow_x", 'enemy', true) > 1

    if (not enoughGunTowersExist) then
        return false, "Player doesn't have enough Gun Towers to attack..."
    end

    if (not CanBuildAssaultTanks(team, time)) then
        return false, "Braddock can't build any Assault Tanks..."
    end

    return true, "Braddock is attacking Gun Towers..."
end

function GunTowerAttackCondition3(team, time)
    local enoughGunTowersExist = AIPUtil.CountUnits(team, "ibgtow_x", 'enemy', true) > 2

    if (not enoughGunTowersExist) then
        return false, "Player doesn't have enough Gun Towers to attack..."
    end

    if (not CanBuildWalkers(team, time)) then
        return false, "Braddock can't build any Walkers..."
    end

    return true, "Braddock is attacking Gun Towers..."
end

function PowerAttackCondition(team, time)
    local powerPlantExists = AIPUtil.CountUnits(team, "ibpgen_x", 'enemy', true) > 0

    if (not powerPlantExists) then
        return false, "Player doesn't have enough Power Plants to attack..."
    end

    if (not CanBuildMortarBikes(team, time)) then
        return false, "Braddock can't build any Mortar Bikes..."
    end

    return true, "Braddock is attacking Power Plants..."
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", 'sameteam', true) > 0
end

function DoesFactoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FACTORY", "sameteam", true) > 0
end

function DoesRelayBunkerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_COMMBUNKER", "sameteam", true) > 0
end

function DoesArmoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_ARMORY", "sameteam", true) > 0
end

function DoesServiceBayExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SUPPLYDEPOT", "sameteam", true) > 0
end

function DoesTrainingExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_BARRACKS", "sameteam", true) > 0
end

function DoesTechCenterExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TECHCENTER", "sameteam", true) > 0
end

function DoesBomberExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_BOMBER", "sameteam", true) > 0
end

function DoesBomberBayExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_BOMBERBAY", "sameteam", true) > 0
end

function DoesScrapPoolExist(team, time)
    return AIPUtil.CountUnits(team, "biometal", "friendly", true) > 0
end

function DoesLooseScrapExist(team, time)
    return AIPUtil.CountUnits(team, "resource", "friendly", true) > 0
end

function DoesPlayerAssaultUnitExist(team, time)
    return AIPUtil.CountUnits(team, "ivatank_x", 'enemy', true) > 0 or
        AIPUtil.CountUnits(team, "ivrckt_x", 'enemy', true) > 0 or
        AIPUtil.CountUnits(team, "ivwalk_x", 'enemy', true) > 0
end

function AssaultUnitCount(team, time)
    return AIPUtil.CountUnits(team, "assault", "sameteam", true)
end

function AssaultServiceUnitCount(team, time)
    return AIPUtil.CountUnits(team, "AssaultServicer", "sameteam", true)
end

function CanBuildAssaultTanks(team, time)
    return DoesFactoryExist(team, time) and DoesRelayBunkerExist(team, time) and DoesServiceBayExist(team, time)
end

function CanBuildMortarBikes(team, time)
    return DoesFactoryExist(team, time) and DoesArmoryExist(team, time)
end

function CanBuildWalkers(team, time)
    return DoesFactoryExist(team, time) and DoesTechCenterExist(team, time)
end