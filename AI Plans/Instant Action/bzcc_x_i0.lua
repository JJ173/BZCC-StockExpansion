-- CONST VARIABLES FOR SCRAP COST OF UNITS.
local ARMORY_SCRAP_COST = 60;
local ASS_TOWER_COST = 70;
local BOMBER_COST = 50;
local BOMBER_BAY_COST = 100;
local BUNKER_SCRAP_COST = 50;
local CONST_SCRAP_COST = 20;
local FACTORY_SCRAP_COST = 55;
local GUNTOWER_SCRAP_COST = 50;
local LANDING_PAD_COST = 60;
local MISL_SCRAP_COST = 23;
local POWER_SCRAP_COST = 30;
local RCKT_SCRAP_COST = 33;
local RCKT_TOWER_SCRAP_COST = 65;
local SBAY_SCRAP_COST = 50;
local SCAV_SCRAP_COST = 10;
local SCOUT_SCRAP_COST = 25;
local SERV_SCRAP_COST = 25;
local TANK_SCRAP_COST = 23;
local TECH_CENTER_SCRAP_COST = 80;
local TRAINING_SCRAP_COST = 70;
local TURRET_SCRAP_COST = 20;

function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua Conditions for ISDF AIP bzcc_x_i0");
end

-- MAP CONDITIONS.
function CollectFieldCondition(team, time)
    if (ScavengerCount(team, time) <= 0) then
        return false, "I don't have any Scavengers.";
    end

    if (DoesLooseScrapExist(team, time) == false) then
        return false, "I cannot find any available loose scrap.";
    end

    return true, "Tasking a Scavenger to collect loose scrap.";
end

function CollectPoolCondition(team, time)
    if (ScavengerCount(team, time) <= 0) then
        return false, "I don't have any Scavengers.";
    end

    if (DoesScrapPoolExist(team, time) == false) then
        return false, "I cannot find any available scrap pools.";
    end

    return true, "Tasking a Scavenger to collect a pool.";
end

-- BUILD PLAN CONDITIONS [UNITS]
function BuildScavengerCondition(team, time)
    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (ScavengerCount(team, time) >= 3) then
        return false, "I already have enough Scavengers.";
    end

    if (AIPUtil.GetScrap(team, false) < SCAV_SCRAP_COST) then
        return false, "I don't have enough scrap for a Scavenger.";
    end

    return true, "Tasking Recycler to build a Scavenger.";
end

function BuildConstructorCondition(team, time)
    if (DoesRecyclerExist(team, time) == false) then
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

function BuildTurretCondition(team, time)
    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (AIPUtil.GetScrap(team, false) < TURRET_SCRAP_COST) then
        return false, "I don't have enough scrap for a Turret.";
    end

    return true, "Tasking Recycler to build a Turret.";
end

function BuildScoutCommander(team, time)
    if (IsCommanderOptionEnabled(team, time) == false) then
        return false, "Commander option is disabled for this game.";
    end

    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (DoesFactoryExist(team, time) and DoesRelayBunkerExist(team, time)) then
        return false, "I have a Factory so I can build a better Commander unit.";
    end

    return true, "I can replace the Commander in a Scout unit. Tasking Recycler to build.";
end

function BuildScoutCondition(team, time)
    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time)) then
        return false, "I have a Factory so I can build better Patrol/Defender unit.";
    end

    if (AIPUtil.GetScrap(team, false) < SCOUT_SCRAP_COST) then
        return false, "I don't have enough scrap for a Scout.";
    end

    return true, "Tasking Recycler to build a Scout."
end

function BuildMissileScoutCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory so I can't build any Missile Scouts.";
    end

    if (AIPUtil.GetScrap(team, false) < MISL_SCRAP_COST) then
        return false, "I don't have enough scrap for a Missile Scout.";
    end

    return true, "Tasking Factory to build a Missile Scout..";
end

function BuildTankCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory so I can't build any Tanks.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker so I can't build any Tanks.";
    end

    if (AIPUtil.GetScrap(team, false) < TANK_SCRAP_COST) then
        return false, "I don't have enough scrap for a Tank.";
    end

    return true, "Tasking Factory to build a Tank..";
end

function BuildAssaultDefenders(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory so I can't build any Tanks.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker so I can't build any Tanks.";
    end

    if (AssaultUnitCount(team, time) <= 0) then
        return false, "I don't have any assault units yet.";
    end

    return true, "Building units to defend assault units.";
end

function BuildRocketTanks(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory so I can't build any Rocket Tanks.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker so I can't build any Rocket Tanks.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory so I can't build any Rocket Tanks.";
    end

    if (AIPUtil.GetScrap(team, false) < RCKT_SCRAP_COST) then
        return false, "I don't have enough scrap for a Rocket Tank.";
    end

    return true, "Tasking Factory to build a Rocket Tank..";
end

function BuildTankCommander(team, time)
    if (IsCommanderOptionEnabled(team, time) == false) then
        return false, "Commander option is disabled for this game.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    return true, "I can replace the Commander in a Tank unit. Tasking Factory to build.";
end

function BuildServiceTrucks(team, time)
    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (AIPUtil.GetScrap(team, false) < SERV_SCRAP_COST) then
        return false, "I don't have enough scrap for a Service Truck.";
    end

    return true, "Tasking Recycler to build Service Trucks...";
end

function BuildBomber(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesBomberBayExist(team, time) == false) then
        return false, "I don't have a Bomber Bay yet.";
    end

    if (DoesBomberExist(team, time)) then
        return false, "I already have a bomber.";
    end

    if (AIPUtil.GetScrap(team, false) < BOMBER_COST) then
        return false, "I don't have enough scrap for a Bomber.";
    end

    return true, "Tasking Factory to build a Bomber...";
end

-- BUILD PLAN CONDITIONS [BUILDINGS]
function UpgradeFirstPoolCondition(team, time)
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (UpgradedExtractorCount(team, time) >= 1) then
        return false, "I have one upgrade. I don't need another yet.";
    end

    if (AIPUtil.GetScrap(team, false) < 60) then
        return false, "I don't have enough scrap to upgrade an Extractor.";
    end

    return true, "Tasking Constructor to upgrade an Extractor.";
end

function UpgradeFirstPowerCondition(team, time)
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (AIPUtil.GetScrap(team, false) < 30) then
        return false, "I don't have enough scrap to upgrade a Power Plant.";
    end

    return true, "Tasking Constructor to upgrade a Power Plant."; 
end

function UpgradeSecondPowerCondition(team, time)
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (DoesTechCenterExist(team, time) == false) then
        return false, "I don't have a Tech Center yet.";
    end

    if (AIPUtil.GetScrap(team, false) < 30) then
        return false, "I don't have enough scrap to upgrade a Power Plant.";
    end

    return true, "Tasking Constructor to upgrade a Power Plant."; 
end

function BuildPath1BasePlate(team, time)
    if (IsPathAvailable("i_Plate_1") == false) then
        return false, "i_Plate_1 is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    return true, "Tasking a Constructor to build a Base Plate...";
end

function BuildPath2BasePlate(team, time)
    if (IsPathAvailable("i_Plate_2") == false) then
        return false, "i_Plate_2 is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    return true, "Tasking a Constructor to build a Base Plate...";
end

function BuildPath3BasePlate(team, time)
    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (IsPathAvailable("i_Plate_3") == false) then
        return false, "i_Plate_3 is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    return true, "Tasking a Constructor to build a Base Plate...";
end

function BuildPath4BasePlate(team, time)
    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (IsPathAvailable("i_Plate_4") == false) then
        return false, "i_Plate_4 is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    return true, "Tasking a Constructor to build a Base Plate...";
end

function BuildPower1(team, time)
    if (IsPathAvailable("i_Power_1") == false) then
        return false, "i_Power_1 is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildPower2(team, time)
    if (IsPathAvailable("i_Power_2") == false) then
        return false, "i_Power_2 is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
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

function BuildPower3(team, time)
    if (IsPathAvailable("i_Power_3") == false) then
        return false, "i_Power_3 is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    if (PowerPlantCount(team, time) < 2) then
        return false, "I haven't built the first or second Power Plant yet.";
    end

    if (AIPUtil.GetPower(team, false) > 0) then
        return false, "I have enough Power for now.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildFactory(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (IsPathAvailable("i_Factory") == false) then
        return false, "i_Factory is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < FACTORY_SCRAP_COST) then
        return false, "I don't have enough scrap for a Factory.";
    end

    -- Make sure I have enough Power.
    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough power for a Factory.";
    end

    return true, "Tasking a Constructor to build a Factory...";
end

function BuildArmory(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (IsPathAvailable("i_Armory") == false) then
        return false, "i_Armory is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
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

    if (IsPathAvailable("i_Bunker") == false) then
        return false, "i_Bunker is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory so I can't build any Rocket Tanks.";
    end

    if (AIPUtil.GetScrap(team, false) < BUNKER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Relay Bunker.";
    end

    return true, "Tasking a Constructor to build a Relay Bunker at main base...";
end

function BuildBaseBunker1(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (IsPathAvailable("i_Base_Bunker_1") == false) then
        return false, "i_Base_Bunker_1 is unavailable, or a building already exists on it."
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory so I can't build any Rocket Tanks.";
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Comm Bunker.";
    end

    if (AIPUtil.GetScrap(team, false) < BUNKER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Comm Bunker.";
    end

    return true, "Tasking a Constructor to build a Relay Bunker at i_Base_Bunker_1...";
end

function BuildGunTower1(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Base_Bunker_1") == false) then
        return false, "Path: i_Base_Bunker_1 hasn't got a building on it, so I can't build a Gun Tower next to it.";
    end

    if (IsPathAvailable("i_GunTower_1") == false) then
        return false, "i_GunTower_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at i_GunTower_1...";
end

function BuildGunTower2(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Base_Bunker_1") == false) then
        return false, "Path: i_Base_Bunker_1 hasn't got a building on it, so I can't build a Gun Tower next to it.";
    end

    if (IsPathAvailable("i_GunTower_2") == false) then
        return false, "i_GunTower_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at i_GunTower_2...";
end

function BuildServiceBay(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (IsPathAvailable("i_ServiceBay") == false) then
        return false, "i_ServiceBay is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory so I can't build any Rocket Tanks.";
    end

    if (AIPUtil.GetScrap(team, false) < SBAY_SCRAP_COST) then
        return false, "I don't have enough scrap for a Service Bay.";
    end

    return true, "Tasking a Constructor to build a Service Bay...";
end

function BuildTrainingCenter(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (IsPathAvailable("i_Training") == false) then
        return false, "i_Training is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory so I can't build a Training Facility.";
    end

    if (AIPUtil.GetScrap(team, false) < TRAINING_SCRAP_COST) then
        return false, "I don't have enough scrap for a Training Facility.";
    end

    return true, "Tasking a Constructor to build a Training Facility..."
end

function BuildTechCenter(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (IsPathAvailable("i_Tech") == false) then
        return false, "i_Tech is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory so I can't build a Tech Center.";
    end

    if (AIPUtil.GetScrap(team, false) < TECH_CENTER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Tech Center.";
    end

    return true, "Tasking a Constructor to build a Tech Center..."
end

function BuildBomberBay(team, time)
    if (ExtractorCount(team, time) < 3) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (IsPathAvailable("i_BomberBay") == false) then
        return false, "i_BomberBay is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesTrainingExist(team, time) == false) then
        return false, "I don't have a Training Facility yet.";
    end

    if (AIPUtil.GetScrap(team, false) < BOMBER_BAY_COST) then
        return false, "I don't have enough scrap for a Bomber Bay.";
    end

    return true, "Tasking a Constructor to build a Bomber Bay..."
end

function BuildFieldBunker1(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (IsPathAvailable("i_Field_Bunker_1") == false) then
        return false, "i_Field_Bunker_1 is unavailable, or a building already exists on it."
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory so I can't build any Rocket Tanks.";
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Comm Bunker.";
    end

    if (AIPUtil.GetScrap(team, false) < BUNKER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Comm Bunker.";
    end

    return true, "Tasking a Constructor to build a Relay Bunker at i_Field_Bunker_1...";
end

function BuildFieldGunTower1(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Field_Bunker_1") == false) then
        return false, "Path: i_Field_Bunker_1 hasn't got a building on it, so I can't build a Gun Tower next to it.";
    end

    if (IsPathAvailable("i_Field_GunTower_1") == false) then
        return false, "i_Field_GunTower_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at i_Field_GunTower_1...";
end

function BuildFieldRocketTower1(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Field_Bunker_1") == false) then
        return false, "Path: i_Field_Bunker_1 hasn't got a building on it, so I can't build a Rocket Tower next to it.";
    end

    if (IsPathAvailable("i_Field_RocketTower_1") == false) then
        return false, "i_Field_RocketTower_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Rocket Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < RCKT_TOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Rocket Tower.";
    end

    return true, "Tasking a Constructor to build a Rocket Tower at i_Field_RocketTower_1...";
end

function BuildFieldAssaultTower1A(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (DoesTechCenterExist(team, time) == false) then
        return false, "I don't have a Tech Center yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Field_Bunker_1") == false) then
        return false, "Path: i_Field_Bunker_1 hasn't got a building on it, so I can't build an Assault Tower next to it.";
    end

    if (IsPathAvailable("i_Field_AssualtTower_1_A") == false) then
        return false, "i_Field_AssualtTower_1_A is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 1) then
        return false, "I don't have enough Power for an Assault Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < ASS_TOWER_COST) then
        return false, "I don't have enough scrap for an Assault Tower.";
    end

    return true, "Tasking a Constructor to build an Assault Tower at i_Field_AssualtTower_1_A...";
end

function BuildFieldAssaultTower1B(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (DoesTechCenterExist(team, time) == false) then
        return false, "I don't have a Tech Center yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Field_Bunker_1") == false) then
        return false, "Path: i_Field_Bunker_1 hasn't got a building on it, so I can't build an Assault Tower next to it.";
    end

    if (IsPathAvailable("i_Field_AssualtTower_1_B") == false) then
        return false, "i_Field_AssualtTower_1_B is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 1) then
        return false, "I don't have enough Power for an Assault Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < ASS_TOWER_COST) then
        return false, "I don't have enough scrap for an Assault Tower.";
    end

    return true, "Tasking a Constructor to build an Assault Tower at i_Field_AssualtTower_1_B...";
end

function BuildFieldBunker2(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (IsPathAvailable("i_Field_Bunker_2") == false) then
        return false, "i_Field_Bunker_2 is unavailable, or a building already exists on it."
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory so I can't build any Rocket Tanks.";
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Comm Bunker.";
    end

    if (AIPUtil.GetScrap(team, false) < BUNKER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Comm Bunker.";
    end

    return true, "Tasking a Constructor to build a Relay Bunker at i_Field_Bunker_2...";
end

function BuildFieldGunTower2(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Field_Bunker_2") == false) then
        return false, "Path: i_Field_Bunker_2 hasn't got a building on it, so I can't build a Gun Tower next to it.";
    end

    if (IsPathAvailable("i_Field_GunTower_2") == false) then
        return false, "i_Field_GunTower_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at i_Field_GunTower_2...";
end

function BuildFieldRocketTower2(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Field_Bunker_2") == false) then
        return false, "Path: i_Field_Bunker_2 hasn't got a building on it, so I can't build a Rocket Tower next to it.";
    end

    if (IsPathAvailable("i_Field_RocketTower_2") == false) then
        return false, "i_Field_RocketTower_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Rocket Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < RCKT_TOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Rocket Tower.";
    end

    return true, "Tasking a Constructor to build a Rocket Tower at i_Field_RocketTower_2...";
end

function BuildFieldAssaultTower2A(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (DoesTechCenterExist(team, time) == false) then
        return false, "I don't have a Tech Center yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Field_Bunker_2") == false) then
        return false, "Path: i_Field_Bunker_2 hasn't got a building on it, so I can't build an Assault Tower next to it.";
    end

    if (IsPathAvailable("i_Field_AssualtTower_2_A") == false) then
        return false, "i_Field_AssualtTower_2_A is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 1) then
        return false, "I don't have enough Power for an Assault Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < ASS_TOWER_COST) then
        return false, "I don't have enough scrap for an Assault Tower.";
    end

    return true, "Tasking a Constructor to build an Assault Tower at i_Field_AssualtTower_2_A...";
end

function BuildFieldAssaultTower2B(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    if (DoesTechCenterExist(team, time) == false) then
        return false, "I don't have a Tech Center yet.";
    end

    if (AIPUtil.PathBuildingExists("i_Field_Bunker_2") == false) then
        return false, "Path: i_Field_Bunker_2 hasn't got a building on it, so I can't build an Assault Tower next to it.";
    end

    if (IsPathAvailable("i_Field_AssualtTower_2_B") == false) then
        return false, "i_Field_AssualtTower_2_B is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 1) then
        return false, "I don't have enough Power for an Assault Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < ASS_TOWER_COST) then
        return false, "I don't have enough scrap for an Assault Tower.";
    end

    return true, "Tasking a Constructor to build an Assault Tower at i_Field_AssualtTower_2_B...";
end

function BuildLandingPad(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesLandingPadExist(team, time)) then
        return false, "I already have a Landing Pad.";
    end

    if (IsPathAvailable("i_LandingPad") == false) then
        return false, "i_LandingPad is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I should prioritise the Factory first.";
    end

    if (AIPUtil.GetScrap(team, false) < LANDING_PAD_COST) then
        return false, "I don't have enough scrap for a Landing Pad.";
    end

    return true, "Tasking a Constructor to build a Landing Pad...";
end

-- COUNT FUNCTIONS TO CHECK IF A NUMBER OF GAME OBJECT EXISTS.

function ScavengerCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", "sameteam", true);
end

function ExtractorCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", "sameteam", true);
end

function UpgradedExtractorCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR_Upgraded", "sameteam", true);
end

function ConstructorCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", "sameteam", true);
end

function PowerPlantCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_POWERPLANT", "sameteam", true);
end

function AssaultUnitCount(team, time)
    return AIPUtil.CountUnits(team, "assault", "sameteam", true);
end

-- ATTACKER PLAN CONDITIONS.
function Attack1Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (DoesFactoryExist(team, time)) then
        return false, "I have a Factory already, I don't want to send Scouts to attack now.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) > 0) then
        return false, "Enemy defenses are too strong.";
    end

    return true, "First attack is being sent.";
end

function Attack2Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) > 0) then
        return false, "Enemy defenses are too strong.";
    end

    return true, "Second attack is being sent.";
end

function Attack3Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) <= 0 and AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", 'enemy', true) <= 0) then
        return false, "Enemy doesn't have any defenses to target.";
    end

    return true, "Enemies has Gun Towers / Turrets. I'll send some Mortar Bikes to attack.";
end

function Attack4Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    return true, "Sending tanks to attack.";
end

function Attack5Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesArmoryExist(team, time) == false) then
        return false, "I don't have an Armory yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    return true, "Sending assault units to attack.";
end

function HeavyAttack1Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesTechCenterExist(team, time) == false) then
        return false, "I don't have a Tech Center yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    return true, "Sending heavy units to attack."
end

function ArtilleryAttackCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesTechCenterExist(team, time) == false) then
        return false, "I don't have a Tech Center yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (DoesServiceBayExist(team, time) == false) then
        return false, "I don't have a Service Bay yet.";
    end

    return true, "Sending artillery units to attack."
end

-- BOOLEAN FUNCTIONS TO CHECK IF A SINGULAR GAME OBJECT EXISTS.

function IsCommanderOptionEnabled(team, time)
    return AIPUtil.GetVarItemInt("options.instant.bool2") == 1;
end

function IsPathAvailable(pathName)
    if (AIPUtil.PathExists(pathName) == false) then
        return false;
    elseif (AIPUtil.PathBuildingExists(pathName)) then
        return false;
    end

    return true;
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", "sameteam", true) > 0;
end

function DoesRelayBunkerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_COMMBUNKER", "sameteam", true) > 0;
end

function DoesFactoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FACTORY", "sameteam", true) > 0;
end

function DoesArmoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_ARMORY", "sameteam", true) > 0;
end

function DoesTrainingExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_BARRACKS", "sameteam", true) > 0;
end

function DoesTechCenterExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TECHCENTER", "sameteam", true) > 0;
end

function DoesServiceBayExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SUPPLYDEPOT", "sameteam", true) > 0;
end

function DoesConstructorExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", "sameteam", true) > 0;
end

function DoesLooseScrapExist(team, time)
    return AIPUtil.CountUnits(team, "resource", "friendly", true) > 0;
end

function DoesScrapPoolExist(team, time)
    return AIPUtil.CountUnits(team, "biometal", "friendly", true) > 0;
end

function DoesLandingPadExist(team, time)
    return AIPUtil.CountUnits(team, "LandingPad", "sameteam", true) > 0;
end

function DoesBomberExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_BOMBER", "sameteam", true) > 0;
end

function DoesBomberBayExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_BOMBERBAY", "sameteam", true) > 0;
end
