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

    -- As to not steal too much from the player, limit our extractors to 2.
    if (ExtractorCount(team, time) >= 2) then
        return false, "I have enough pools.";
    end

    return true, "Tasking a Scavenger to collect a pool.";
end

function DoesLooseScrapExist(team, time)
    return AIPUtil.CountUnits(team, "resource", "friendly", true) > 0;
end

function DoesScrapPoolExist(team, time)
    return AIPUtil.CountUnits(team, "biometal", "friendly", true) > 0;
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

function BuildTanks(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory so I can't build any Tanks.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker so I can't build any Tanks.";
    end

    -- Do a count to make sure that we have less than 4 tanks (including Manson) before building.
    if (AIPUtil.CountUnits(team, "ivtank_x", "sameteam", true) >= 4) then
        return false, "I have enough tanks.";
    end

    return true, "Building units to defend assault units.";
end

-- BUILD PLAN CONDITIONS [BUILDINGS]

function BuildPower1(team, time)
    if (not IsPathAvailable("manson_pgen1")) then
        return false, "manson_pgen1 is unavailable, or a building already exists on it."
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
    if (not IsPathAvailable("manson_pgen2")) then
        return false, "manson_pgen2 is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    if (PowerPlantCount(team, time) <= 0) then
        return false, "I haven't built the first Power Plant yet.";
    end

    if (AIPUtil.GetPower(team, false) > 0) then
        return false, "I have enough Power for now.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildRelayBunker(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("manson_cbun")) then
        return false, "manson_cbun is unavailable, or a building already exists on it."
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

    if (IsPathAvailable("manson_gtow1") == false) then
        return false, "manson_gtow1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at manson_gtow1...";
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

    if (IsPathAvailable("manson_gtow2") == false) then
        return false, "manson_gtow2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at manson_gtow2...";
end

function BuildFactory(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("manson_factory")) then
        return false, "manson_factory is unavailable, or a building already exists on it."
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

    if (not IsPathAvailable("manson_armo")) then
        return false, "manson_armo is unavailable, or a building already exists on it."
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

function BuildServiceBay(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("manson_sbay")) then
        return false, "manson_sbay is unavailable, or a building already exists on it."
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