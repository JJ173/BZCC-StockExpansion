-- CONST VARIABLES FOR SCRAP COST OF UNITS.
local ARMORY_SCRAP_COST = 60;
local BUNKER_SCRAP_COST = 50;
local CONST_SCRAP_COST = 40;
local FACTORY_SCRAP_COST = 55;
local GUNTOWER_SCRAP_COST = 50;
local POWER_SCRAP_COST = 30;
local SBAY_SCRAP_COST = 50;
local SCAV_SCRAP_COST = 20;
local SERV_SCRAP_COST = 50;
local TURRET_SCRAP_COST = 40;

function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

-- MAP CONDITIONS.
function CollectFieldCondition(team, time)
    if (not DoesLooseScrapExist(team, time)) then
        return false, "I cannot find any available loose scrap.";
    end

    return true, "Tasking a Scavenger to collect loose scrap.";
end

function CollectPoolCondition(team, time)
    if (not DoesScrapPoolExist(team, time)) then
        return false, "I cannot find any available scrap pools.";
    end

    return true, "Tasking a Scavenger to collect a pool.";
end

function DoesLooseScrapExist(team, time)
    return AIPUtil.CountUnits(team, "resource", "friendly", true) > 0;
end

function DoesScrapPoolExist(team, time)
    return AIPUtil.CountUnits(team, "biometal", "friendly", true) > 0;
end

-- ATTACKER PLAN CONDITIONS.
function Attack1Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (AIPUtil.CountUnits(team, "fbspir_x", 'enemy', true) > 0) then
        return false, "Enemy defenses are too strong.";
    end

    return true, "First attack is being sent.";
end

function Attack2Condition(team, time)
    if (AIPUtil.CountUnits(team, "fvturr_x", "enemy", true) <= 0) then
        return false, "The enemy doesn't have any turrets.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesArmoryExist(team, time)) then
        return false, "I don't have an Armory yet.";
    end

    return true, "Second attack is being sent.";
end

function Attack3Condition(team, time)
    if (AIPUtil.CountUnits(team, "fbspir_x", 'enemy', true) <= 0) then
        return false, "Enemy has no Gun Spires to attack.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (not DoesArmoryExist(team, time)) then
        return false, "I don't have an Armory yet.";
    end

    return true, "Third attack is being sent.";
end

function Attack4Condition(team, time)
    if (AIPUtil.CountUnits(team, "fbspir_x", 'enemy', true) <= 1) then
        return false, "Enemy has no Gun Spires to attack.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (not DoesServiceBayExist(team, time)) then
        return false, "I don't have a Service Bay yet.";
    end

    return true, "Fourth attack is being sent.";
end

function Attack5Condition(team, time)
    if (AIPUtil.CountUnits(team, "fbkiln_x", 'enemy', true) <= 0 and AIPUtil.CountUnits(team, "fbforg_x", 'enemy', true) <= 0) then
        return false, "Enemy has no factory to attack.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    return true, "Fifth attack is being sent.";
end

-- BUILD PLAN CONDITIONS [UNITS]
function BuildScavengerCondition(team, time)
    if (not DoesRecyclerExist(team, time)) then
        return false, "I don't have a Recycler yet.";
    end

    if (ScavengerCount(team, time) >= 2) then
        return false, "I already have enough Scavengers.";
    end

    if (AIPUtil.GetScrap(team, false) < SCAV_SCRAP_COST) then
        return false, "I don't have enough scrap for a Scavenger.";
    end

    return true, "Tasking Recycler to build a Scavenger.";
end

function BuildConstructorCondition(team, time)
    if (not DoesRecyclerExist(team, time)) then
        return false, "I don't have a Recycler yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (AIPUtil.GetScrap(team, false) < CONST_SCRAP_COST) then
        return false, "I don't have enough scrap for a Constructor.";
    end

    return true, "Tasking Recycler to build a Constructor.";
end

function BuildTurrets(team, time)
    if (not DoesRecyclerExist(team, time)) then
        return false, "I don't have a Recycler yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (AIPUtil.GetScrap(team, false) < TURRET_SCRAP_COST) then
        return false, "I don't have enough scrap for a Turret.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", "sameteam", true) >= 3) then
        return false, "I already have enough turrets";
    end

    return true, "Tasking Recycler to build a Turret.";
end

function BuildServiceTrucks(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (not DoesServiceBayExist(team, time)) then
        return false, "I don't have a Service Bay yet.";
    end

    if (not DoesRecyclerExist(team, time)) then
        return false, "I don't have a Recycler yet.";
    end

    if (AIPUtil.GetScrap(team, false) < SERV_SCRAP_COST) then
        return false, "I don't have enough scrap for a Service Truck.";
    end

    return true, "Tasking Recycler to build Service Trucks...";
end

-- BUILD PLAN CONDITIONS [BUILDINGS]

function BuildPower1(team, time)
    if (not IsPathAvailable("brad_pgen1")) then
        return false, "brad_pgen1 is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildPower2(team, time)
    if (not IsPathAvailable("brad_pgen2")) then
        return false, "brad_pgen2 is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildPower3(team, time)
    if (not IsPathAvailable("brad_pgen3")) then
        return false, "brad_pgen3 is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildFactory(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("brad_factory")) then
        return false, "brad_factory is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < FACTORY_SCRAP_COST) then
        return false, "I don't have enough scrap for a Factory.";
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough power for a Factory.";
    end

    return true, "Tasking a Constructor to build a Factory...";
end

function BuildArmory(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("brad_armo")) then
        return false, "brad_armo is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.GetScrap(team, false) < ARMORY_SCRAP_COST) then
        return false, "I don't have enough scrap for an Armory.";
    end

    return true, "Tasking a Constructor to build an Armory...";
end

function BuildRelayBunker(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("brad_cbun")) then
        return false, "brad_cbun is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < BUNKER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Relay Bunker.";
    end

    return true, "Tasking a Constructor to build a Relay Bunker at main base...";
end

function BuildGunTower1(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (IsPathAvailable("brad_gtow1") == false) then
        return false, "brad_gtow1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at brad_gtow1...";
end

function BuildGunTower2(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (IsPathAvailable("brad_gtow2") == false) then
        return false, "brad_gtow2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at brad_gtow2...";
end

function BuildGunTower3(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (IsPathAvailable("brad_gtow3") == false) then
        return false, "brad_gtow3 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at brad_gtow3...";
end

function BuildServiceBay(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("brad_sbay")) then
        return false, "brad_sbay is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.GetScrap(team, false) < SBAY_SCRAP_COST) then
        return false, "I don't have enough scrap for a Service Bay.";
    end

    return true, "Tasking a Constructor to build a Service Bay...";
end

-- COUNT FUNCTIONS TO CHECK IF A NUMBER OF GAME OBJECT EXISTS.

function ScavengerCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", "sameteam", true);
end

function ExtractorCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", "sameteam", true);
end

function PowerPlantCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_POWERPLANT", "sameteam", true);
end

-- BOOLEAN FUNCTIONS TO CHECK IF A SINGULAR GAME OBJECT EXISTS.

function IsPathAvailable(pathName)
    if (not AIPUtil.PathExists(pathName)) then
        return false;
    elseif (AIPUtil.PathBuildingExists(pathName)) then
        return false;
    end

    return true;
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", "sameteam", true) > 0;
end

function DoesFactoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FACTORY", "sameteam", true) > 0;
end

function DoesRelayBunkerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_COMMBUNKER", "sameteam", true) > 0;
end

function DoesServiceBayExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SUPPLYDEPOT", "sameteam", true) > 0;
end

function DoesConstructorExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", "sameteam", true) > 0;
end

function DoesArmoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_ARMORY", "sameteam", true) > 0;
end
