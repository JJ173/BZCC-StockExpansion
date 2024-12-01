--[[
    BZCC Scion07 Lua Mission Script
    Written by AI_Unit
    Version 1.0 29-09-2024
--]]

-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))();

-- Required Globals.
require("_GlobalVariables");

-- Required helper functions.
require("_HelperFunctions");

-- Cooperative.
local _Cooperative = require("_Cooperative");

-- Subtitles.
local _Subtitles = require('_Subtitles');

-- Game TPS.
local m_GameTPS = GetTPS();


-- Mission Name
local m_MissionName = "Scion07: Braddock";

-- Mission important variables.
local Mission = 
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "fspilo_r",
    -- Specific to mission.
    m_PlayerShipODF = "fvtank_r",

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_Braddock = nil,
    m_Dropship1 = nil,
    m_Inter_1 = nil,
    m_Inter_2 = nil,
    m_Tank_1 = nil,

    m_Walker1 = nil,
    m_Walker2 = nil,
    m_Walker1_Truck1 = nil,
    m_Walker1_Truck2 = nil,
    m_Walker2_Truck1 = nil,
    m_Walker2_Truck2 = nil,

    m_Rocket1 = nil,
    m_Rocket2 = nil,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    -- Steps for each section.
    m_MissionState = 1,
}

-- Functions Table
local Functions = {};

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
function InitialSetup()
    -- Check if we are cooperative mode.
    Mission.m_IsCooperativeMode = IsNetworkOn();

    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();

    -- Preload ODFs to save load times.
    PreloadODF("fvrecy_r");
    PreloadODF("ibrecy_x");
end

function Save()
    return _Cooperative.Save(), Mission;
end

function Load(CoopData, MissionData)
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();

    -- Load Coop.
    _Cooperative.Load(CoopData);

    -- Load mission data.
    Mission = MissionData;
end

function AddObject(h)

end

function DeleteObject(h)

end

function Start()
    -- Set difficulty based on whether it's coop or not.
    if (Mission.m_IsCooperativeMode) then
        Mission.m_MissionDifficulty = GetVarItemInt("network.session.ivar102") + 1;
    else
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1;
    end

    -- Call generic start logic in coop.
    _Cooperative.Start(m_MissionName, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, Mission.m_IsCooperativeMode);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;
end

function Update()
    -- This checks to see if the game is ready.
    if (Mission.m_IsCooperativeMode) then
        _Cooperative.Update();
    end

    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Get the main player
    Mission.m_MainPlayer = GetPlayerHandle(1);

    -- Start mission logic.
    if (not Mission.m_MissionOver and (Mission.m_IsCooperativeMode == false or _Cooperative.GetGameReadyStatus())) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();
        end
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, false, 0);
end

function DeletePlayer(id)
    return _Cooperative.DeletePlayer(id);
end

function PlayerEjected(DeadObjectHandle)
    return _Cooperative.PlayerEjected(DeadObjectHandle);
end

function ObjectKilled(DeadObjectHandle, KillersHandle)
    return _Cooperative.ObjectKilled(DeadObjectHandle, KillersHandle, Mission.m_PlayerPilotODF);
end

function ObjectSniped(DeadObjectHandle, KillersHandle)
    return _Cooperative.ObjectSniped(DeadObjectHandle, KillersHandle, Mission.m_PlayerPilotODF);
end

function PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF)
    return _Cooperative.PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF);
end

function PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
    return _Cooperative.PreGetIn(curWorld, pilotHandle, emptyCraftHandle);
end

function RespawnPilot(DeadObjectHandle, Team)
    return _Cooperative.RespawnPilot(DeadObjectHandle, Team, Mission.m_PlayerPilotODF);
end

function DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI)
    return _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI, Mission.m_PlayerPilotODF);
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "New Regime");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Give the player some scrap.
    SetScrap(Mission.m_HostTeam, 40);

    -- Give the AAN some scrap.
    SetScrap(Mission.m_EnemyTeam, 40);

    -- Grab our necessary pre-placed handles.
    Mission.m_Braddock = GetHandle("braddock");

    Mission.m_Walker1 = GetHandle("walker_1");
    Mission.m_Walker2 = GetHandle("walker_2");

    Mission.m_Walker1_Truck1 = GetHandle("walker_1_truck_1");
    Mission.m_Walker1_Truck2 = GetHandle("walker_1_truck_2");
    Mission.m_Walker2_Truck1 = GetHandle("walker_2_truck_1");
    Mission.m_Walker2_Truck2 = GetHandle("walker_2_truck_2");

    -- For now, hold Braddock in place.
    Defend(Mission.m_Braddock, 1);

    -- Make the Trucks follow their respective walkers.
    Follow(Mission.m_Walker1_Truck1, Mission.m_Walker1, 1);
    Follow(Mission.m_Walker1_Truck2, Mission.m_Walker1, 1);
    Follow(Mission.m_Walker2_Truck1, Mission.m_Walker2, 1);
    Follow(Mission.m_Walker2_Truck2, Mission.m_Walker2, 1);

    Mission.m_Rocket1 = GetHandle("patrol_1");
    Mission.m_Rocket2 = GetHandle("patrol_2");

    -- Send the Rocket Tanks on Patrol.
    Patrol(Mission.m_Rocket1, "end_tank1path", 1);
    Patrol(Mission.m_Rocket2, "end_tank2path", 1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()

end