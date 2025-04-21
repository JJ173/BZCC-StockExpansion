--[[
    BZCC Scion06 Lua Mission Script
    Written by AI_Unit
    Version 1.0 21-04-2026
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
local m_MissionName = "Scion06: Ambush";

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

    m_MainPlayer = nil,
    m_Yelena = nil,
    m_Manson = nil,

    m_BraddockTurret1 = nil,
    m_BraddockTurret2 = nil,
    m_BraddockTurret3 = nil,
    m_BraddockTurret4 = nil,

    m_BraddockBasePatrol1 = nil,
    m_BraddockBasePatrol2 = nil,
    m_BraddockBasePatrol3 = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

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
    local teamNum = GetTeamNum(h);

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        -- Always max our player units.
        SetSkill(h, 3);
    end
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

            -- Check failure conditions...
            HandleFailureConditions();
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

function PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)

end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_AlliedTeam, "Scion");
    SetTeamNameForStat(Mission.m_EnemyTeam, "New Regime");
    SetTeamNameForStat(7, "Rebel Scions");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Unique to this mission. The Rebel Scions are allying with the New Regime.
    Ally(Mission.m_EnemyTeam, 7);

    -- Since the player is using the AAN, we need to set the team colour to blue.
    SetTeamColor(Mission.m_HostTeam, 0, 127, 255);

    -- Grab all of our pre-placed handles.
    Mission.m_Yelena = GetHandle("yelena");
    Mission.m_Manson = GetHandle("manson");

    -- Have Manson and Yelena patrol their base.
    Patrol(Mission.m_Manson, "manson_patrol", 1);
    Patrol(Mission.m_Yelena,"yelena_patrol", 1);

    -- Give all relevant teams scrap.
    SetScrap(Mission.m_HostTeam, 40);
    SetScrap(Mission.m_EnemyTeam, 40);
    SetScrap(Mission.m_AlliedTeam, 40);

    -- Set Braddock's AIP.
    SetAIP("scion0601_x.aip", Mission.m_EnemyTeam);

    -- Spawn some units in Braddock's base.
    BuildObject("ivatank_x", Mission.m_EnemyTeam, "ass1");
    BuildObject("ivatank_x", Mission.m_EnemyTeam, "ass2");

    -- Spawn some turrets in Braddock's base.
    Mission.m_BraddockTurret1 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret1");
    Mission.m_BraddockTurret2 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret2");
    Mission.m_BraddockTurret3 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret3");
    Mission.m_BraddockTurret4 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret4");

    -- Spawn some patrols in Braddock's base.
    Mission.m_BraddockBasePatrol1 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank1");
    Mission.m_BraddockBasePatrol2 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank2");
    Mission.m_BraddockBasePatrol3 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank3");

    -- Patrol the base.
    Patrol(Mission.m_BraddockBasePatrol1, "basetank1", 1);
    Patrol(Mission.m_BraddockBasePatrol2, "basetank2", 1);
    Patrol(Mission.m_BraddockBasePatrol3, "basetank3", 1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()

end

-- Checks for failure conditions.
function HandleFailureConditions()

end
