-- CONST VARIABLES FOR SCRAP COST OF UNITS.
local APC_SCRAP_COST = 25;
local ATANK_SCRAP_COST = 35;
local BOMBER_SCRAP_COST = 33;
local CONST_SCRAP_COST = 20;
local MLAY_SCRAP_COST = 25;
local MISL_SCRAP_COST = 23;
local MBIKE_SCRAP_COST = 23;
local POD_SCRAP_COST = 2;
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

-- BUILD PLAN CONDITIONS.

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


-- COUNT FUNCTIONS TO CHECK IF A NUMBER OF GAME OBJECT EXISTS.

function ScavengerCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", "sameteam", true);
end

-- BOOLEAN FUNCTIONS TO CHECK IF A SINGULAR GAME OBJECT EXISTS.

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