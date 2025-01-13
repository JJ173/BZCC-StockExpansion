-- CONST VARIABLES FOR SCRAP COST OF UNITS.
local APC_SCRAP_COST = 25;
local ATANK_SCRAP_COST = 35;
local BOMBER_SCRAP_COST = 33;
local CONST_SCRAP_COST = 20;
local MLAY_SCRAP_COST = 25;
local MISL_SCRAP_COST = 23;
local MBIKE_SCRAP_COST = 23;
local POD_SCRAP_COST = 2;
local POWER_SCRAP_COST = 30;
local RCKT_SCRAP_COST = 33;
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
function UpgradePoolCondition(team, time)
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
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

function BuildScoutCommander(team, time)
    -- Check if the Commander option was enabled in the lobby before we build this unit.
    if (IsCommanderOptionEnabled(team, time) == false) then
        return false, "Commander option is disabled for this game.";
    end

    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (DoesFactoryExist(team, time) and DoesCommBunkerExist(team, time)) then
        return false, "I have a Factory so I can build a better Commander unit.";
    end

    return true, "I can replace the Commander in a Scout unit. Tasking Recycler to build.";
end

function BuildTankCommander(team, time)
    -- Check if the Commander option was enabled in the lobby before we build this unit.
    if (IsCommanderOptionEnabled(team, time) == false) then
        return false, "Commander option is disabled for this game.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesCommBunkerExist(team, time) == false) then
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

    return true, "The right path exists, there's no building there, so I will construct a Base Plate. Tasking a Constructor to build a Base Plate...";
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

    return true, "The right path exists, there's no building there, so I will construct a Base Plate. Tasking a Constructor to build a Base Plate...";
end

function BuildPath3BasePlate(team, time)

end

function BuildPath4BasePlate(team, time)

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

    return true, "The right path exists, there's no building there, so I will construct a Power Plant. Tasking a Constructor to build a Power Plant...";
end

-- COUNT FUNCTIONS TO CHECK IF A NUMBER OF GAME OBJECT EXISTS.

function ScavengerCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", "sameteam", true);
end

function ExtractorCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", "sameteam", true);
end

function ConstructorCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", "sameteam", true);
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
