-- CONST VARIABLES FOR SCRAP COST OF UNITS.
local APC_SCRAP_COST = 25;
local ARMORY_SCRAP_COST = 60;
local ATANK_SCRAP_COST = 35;
local BOMBER_SCRAP_COST = 33;
local BUNKER_SCRAP_COST = 50;
local CONST_SCRAP_COST = 20;
local FACTORY_SCRAP_COST = 55;
local LANDING_PAD_COST = 60;
local MLAY_SCRAP_COST = 25;
local MISL_SCRAP_COST = 23;
local MBIKE_SCRAP_COST = 23;
local POD_SCRAP_COST = 2;
local POWER_SCRAP_COST = 30;
local RCKT_SCRAP_COST = 33;
local SBAY_SCRAP_COST = 50;
local SCAV_SCRAP_COST = 10;
local SCOUT_SCRAP_COST = 25;
local SERV_SCRAP_COST = 25;
local TANK_SCRAP_COST = 23;
local TURRET_SCRAP_COST = 20;
local WALKER_SCRAP_COST = 50;

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

-- BUILD PLAN CONDITIONS.
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

    return true, "I have an Extractor that can be upgraded. Tasking Constructor to upgrade an Extractor.";
end

function BuildServicePodCondition(team, time)
    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    -- Check we have at least 2 Scavengers in the field before doing this.
    if (ScavengerCount(team, time) < 2) then
        return false, "I need to prioritise Scavengers over Service Pods first.";
    end

    if (AIPUtil.GetScrap(team, false) < POD_SCRAP_COST) then
        return false, "I don't have enough scrap for a Service Pod.";
    end

    -- Check to see if Service Pods exist.
    if (AIPUtil.CountUnits(team, "apserv", "sameteam", false) >= 1) then
        return false, "I already have enough Service Pods.";
    end

    if (DoesServiceBayExist(team, time)) then
        return false, "I have a Service Bay now, no more pods are needed.";
    end

    return true, "Building Service Pods for Recovery.";
end

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

    return true, "My Recycler is healthy, and I need more Scavengers. Tasking Recycler to build a Scavenger.";
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

    return true,
        "My Recycler is healthy, I have an Extractor, and I need more Constructors. Tasking Recycler to build a Constructor.";
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

    return true,
        "My Recycler is healthy, I have an Extractor, and I need more Turrets. Tasking Recycler to build a Turret.";
end

function BuildScoutCommander(team, time)
    -- Check if the Commander option was enabled in the lobby before we build this unit.
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

    -- Make sure we have a pool first.
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time)) then
        return false, "I have a Factory so I can build better Patrol/Defender unit.";
    end

    -- Check that we have enough to build a scout.
    if (AIPUtil.GetScrap(team, false) < SCOUT_SCRAP_COST) then
        return false, "I don't have enough scrap for a Scout.";
    end

    return true, "I can build a Scout unit."
end

function BuildMissileScoutCondition(team, time)
    -- Make sure we have a pool first.
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory so I can't build any Missile Scouts.";
    end

    -- Check that we have enough to build a Missile Scout.
    if (AIPUtil.GetScrap(team, false) < MISL_SCRAP_COST) then
        return false, "I don't have enough scrap for a Missile Scout.";
    end

    return true, "I can build a Missile Scout.";
end

function BuildTankCondition(team, time)
    -- Make sure we have a pool first.
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory so I can't build any Tanks.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker so I can't build any Tanks.";
    end

    -- Check that we have enough to build a Missile Scout.
    if (AIPUtil.GetScrap(team, false) < TANK_SCRAP_COST) then
        return false, "I don't have enough scrap for a Tank.";
    end

    return true, "I can build a Tank.";
end

function BuildTankCommander(team, time)
    -- Check if the Commander option was enabled in the lobby before we build this unit.
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

function BuildPath1BasePlate(team, time)
    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Plate_1") == false) then
        return false, "Path: i_Plate_1 doesn't exist, so I can't build a Base Plate there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Plate_1")) then
        return false, "Path: i_Plate_1 has a building on it, so I can't build a Base Plate there.";
    end

    -- Check that I have a constructor.
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    return true,
        "The right path exists, there's no building there, so I will construct a Base Plate. Tasking a Constructor to build a Base Plate...";
end

function BuildPath2BasePlate(team, time)
    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Plate_2") == false) then
        return false, "Path: i_Plate_2 doesn't exist, so I can't build a Base Plate there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Plate_2")) then
        return false, "Path: i_Plate_2 has a building on it, so I can't build a Base Plate there.";
    end

    -- Check that I have a constructor.
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    return true,
        "The right path exists, there's no building there, so I will construct a Base Plate. Tasking a Constructor to build a Base Plate...";
end

function BuildPath3BasePlate(team, time)
    -- Check we have a Factory first.
    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Plate_3") == false) then
        return false, "Path: i_Plate_3 doesn't exist, so I can't build a Base Plate there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Plate_3")) then
        return false, "Path: i_Plate_3 has a building on it, so I can't build a Base Plate there.";
    end

    -- Check that I have a constructor.
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    return true,
        "The right path exists, there's no building there, so I will construct a Base Plate. Tasking a Constructor to build a Base Plate...";
end

function BuildPath4BasePlate(team, time)
    -- Check we have a Factory first.
    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Plate_4") == false) then
        return false, "Path: i_Plate_4 doesn't exist, so I can't build a Base Plate there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Plate_4")) then
        return false, "Path: i_Plate_4 has a building on it, so I can't build a Base Plate there.";
    end

    -- Check that I have a constructor.
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    return true,
        "The right path exists, there's no building there, so I will construct a Base Plate. Tasking a Constructor to build a Base Plate...";
end

function BuildPower1(team, time)
    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Power_1") == false) then
        return false, "Path: i_Power_1 doesn't exist, so I can't build a Base Plate there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Power_1")) then
        return false, "Path: i_Power_1 has a building on it, so I can't build a Base Plate there.";
    end

    -- Check that I have a constructor.
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    return true,
        "The right path exists, there's no building there, so I will construct a Power Plant. Tasking a Constructor to build a Power Plant...";
end

function BuildPower2(team, time)
    -- Check that I have a constructor.
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    -- Check if a Power Plant exists.
    if (PowerPlantCount(team, time) <= 0) then
        return false, "I haven't built the first Power Plant yet.";
    end

    if (AIPUtil.GetPower(team, false) > 0) then
        return false, "I have enough Power for now.";
    end

    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Power_2") == false) then
        return false, "Path: i_Power_2 doesn't exist, so I can't build a Base Plate there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Power_2")) then
        return false, "Path: i_Power_2 has a building on it, so I can't build a Base Plate there.";
    end

    return true,
        "The right path exists, there's no building there, so I will construct a Power Plant. Tasking a Constructor to build a Power Plant...";
end

function BuildFactory(team, time)
    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Factory") == false) then
        return false, "Path: i_Factory doesn't exist, so I can't build a Factory there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Factory")) then
        return false, "Path: i_Factory has a building on it, so I can't build a Factory there.";
    end

    -- Check that I have a constructor.
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

    return true,
        "The right path exists, there's no building there, so I will construct a Factory. Tasking a Constructor to build a Factory...";
end

function BuildArmory(team, time)
    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Armory") == false) then
        return false, "Path: i_Armory doesn't exist, so I can't build an Armory there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Armory")) then
        return false, "Path: i_Armory has a building on it, so I can't build an Armory there.";
    end

    -- Check that I have a constructor.
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    -- Check we have a Factory first.
    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.GetScrap(team, false) < ARMORY_SCRAP_COST) then
        return false, "I don't have enough scrap for an Armory.";
    end

    return true,
        "The right path exists, there's no building there, so I will construct an Armory. Tasking a Constructor to build an Armory...";
end

function BuildFieldBunker1(team, time)
    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Field_Bunker_1") == false) then
        return false, "Path: i_Field_Bunker_1 doesn't exist, so I can't build a Relay Bunker there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Field_Bunker_1")) then
        return false, "Path: i_Field_Bunker_1 has a building on it, so I can't build a Relay Bunker there.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    -- Check we have a Factory first.
    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Comm Bunker.";
    end

    if (AIPUtil.GetScrap(team, false) < BUNKER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Comm Bunker.";
    end

    return true,
        "The right path exists, there's no building there, so I will construct a Relay Bunker. Tasking a Constructor to build a Relay Bunker...";
end

function BuildFieldGunTower1(team, time)
    -- Check that a Relay Bunker has been built on the right path.
    if (AIPUtil.PathBuildingExists("i_Field_Bunker_1") == false) then
        return false, "Path: i_Field_Bunker_1 hasn't got a building on it, so I can't build a Gun Tower next to it.";
    end

    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_Field_GunTower_1") == false) then
        return false, "Path: i_Field_GunTower_1 doesn't exist, so I can't build a Gun Tower there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_Field_GunTower_1")) then
        return false, "Path: i_Field_GunTower_1 has a building on it, so I can't build a Gun Tower there.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    return true, "I can build a Gun Tower on i_Field_GunTower_1";
end

function BuildLandingPad(team, time)
    -- Check to see if we already have a landing pad.
    if (DoesLandingPadExist(team, time)) then
        return false, "I already have a Landing Pad.";
    end

    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_LandingPad") == false) then
        return false, "Path: i_LandingPad doesn't exist, so I can't build a Landing Pad there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_LandingPad")) then
        return false, "Path: i_LandingPad has a building on it, so I can't build a Landing Pad there.";
    end

    -- Check that I have a constructor.
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    -- Check that I have a Factory.
    if (DoesFactoryExist(team, time) == false) then
        return false, "I should prioritise the Factory first.";
    end

    if (AIPUtil.GetScrap(team, false) < LANDING_PAD_COST) then
        return false, "I don't have enough scrap for a Landing Pad.";
    end

    return true, "I can build a Landing Pad.";
end

function BuildServiceBay(team, time)
    -- Check that the path exists first.
    if (AIPUtil.PathExists("i_ServiceBay") == false) then
        return false, "Path: i_ServiceBay doesn't exist, so I can't build a Service Bay there.";
    end

    -- Check that the path doesn't have a building first.
    if (AIPUtil.PathBuildingExists("i_ServiceBay")) then
        return false, "Path: i_ServiceBay has a building on it, so I can't build a Service Bay there.";
    end

    -- Check that I have a constructor.
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    -- Check we have a Factory first.
    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.GetScrap(team, false) < SBAY_SCRAP_COST) then
        return false, "I don't have enough scrap for an Service Bay.";
    end

    return true,
        "The right path exists, there's no building there, so I will construct a Service Bay. Tasking a Constructor to build an Service Bay...";
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

-- ATTACKER PLAN CONDITIONS.
function Attack1Condition(team, time)
    -- Make sure we have a pool first.
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
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
    -- Make sure we have a pool first.
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) > 1) then
        return false, "Enemy defenses are too strong.";
    end

    return true, "Second attack is being sent.";
end

function Attack3Condition(team, time)
    -- Make sure we have a pool first.
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
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

-- BOOLEAN FUNCTIONS TO CHECK IF A SINGULAR GAME OBJECT EXISTS.

function IsCommanderOptionEnabled(team, time)
    return AIPUtil.GetVarItemInt("options.instant.bool2") == 1;
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
