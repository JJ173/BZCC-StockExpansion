--[[ 
    BZCC ISDF07 Lua Mission Script
    Written by AI_Unit
    Version 1.0 23-10-2022
--]]

-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")),"_requirefix.lua"))();

-- Required Globals.
require("_GlobalVariables");

-- Required helper functions.
require("_HelperFunctions");

-- Cooperative.
local _Cooperative = require("_Cooperative");

-- Subtitles.
local _Subtitles = require('_Subtitles');

-- Game TPS.
local m_GameTPS = 20;

-- Mission important variables.
local Mission = 
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "ispilo";
    -- Specific to mission.
    m_PlayerShipODF = "ivtank";

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionStartDone = false,
    m_MissionFailed = false,

    m_Recycler = nil,
    m_Shabayev = nil,
    m_Dropship = nil,
    
    m_Audioclip = nil,

    -- Steps for each section.
}

---------------------------
-- Event Driven Functions
---------------------------
function InitialSetup()
    -- Check if we are cooperative mode.
    Mission.m_IsCooperativeMode = IsNetworkOn();

    -- Enable high TPS.
    m_GameTPS = EnableHighTPS();

    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    if (Mission.m_IsCooperativeMode) then
        WantBotKillMessages();
    end

    -- Preload to save load times.
    PreloadODF("ivrecy");
    PreloadODF("ivtank");
    PreloadODF("fvsent");
    PreloadODF("fvtank");
    PreloadODF("fvartl");
    PreloadODF("fvarch");
end

function Save() 
    return Mission;
end

function Load(MissionData)
    -- Enable high TPS.
    m_GameTPS = EnableHighTPS();

    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- Load mission data.
	Mission = MissionData;
end

function AddObject(h)
    -- Handle unit skill for enemy.
    if (GetTeamNum(h) == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);       
    end
end

function Start()
    -- Set difficulty based on whether it's coop or not.
    if (Mission.m_IsCooperativeMode) then
        -- TODO: introduce new ivar for difficulty?
    else
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1;
    end

    -- Few prints to console.
    print("Welcome to ISDF07 (Lua)");
    print("Written by AI_Unit");
    
    if (Mission.m_IsCooperativeMode) then
        print("Cooperative mode enabled: Yes");
    else
        print("Cooperative mode enabled: No");
    end

    print("Chosen difficulty: " .. Mission.m_MissionDifficulty);
    print("Good luck and have fun :)");

    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Ally teams to be sure.
    Ally(Mission.m_HostTeam, Mission.m_AlliedTeam);

    -- Grab the Recycler.
    Mission.m_Recycler = GetHandle("recycler");

    -- Create Shabayev.
    Mission.m_Shabayev = BuildObject("ivtank", Mission.m_AlliedTeam, "spawn_shab");
    -- Give Shab her name.
    SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
    -- Do not allow control of Shabayev.
    Stop(Mission.m_Shabayev, 1);
    -- Highlight Shabayev.
    SetObjectiveOn(Mission.m_Shabayev);
    -- Give her the correct pilot.
    SetPilotClass(Mission.m_Shabayev, "isshab_p");
    -- So she always ejects.
    SetEjectRatio(Mission.m_Shabayev, 1);
    -- Make sure she has good skill.
    SetSkill(Mission.m_Shabayev, 3);

    -- Get the Dropship.
    Mission.m_Dropship = GetHandle("dropship");
    -- Make it immortal.
    SetMaxHealth(Mission.m_Dropship, 0);

    -- Remove the player ODF that is saved as part of the BZN.
    local PlayerEntryH = GetPlayerHandle(1);

	if (PlayerEntryH ~= nil) then
		RemoveObject(PlayerEntryH);
	end

    -- Get Team Number.
    local LocalTeamNum = GetLocalPlayerTeamNumber();

    -- Create the player for the server.
    local PlayerH = _Cooperative.SetupPlayer(LocalTeamNum, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF);

    -- Make sure we give the player control of their ship.
    SetAsUser(PlayerH, LocalTeamNum);

    -- Make sure the handle has a pilot so the player can hop out.
    AddPilotByHandle(PlayerH);

    -- Give the player some scrap.
    SetScrap(Mission.m_HostTeam, 40);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;
end

function Update()
    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Start mission logic.
    if (Mission.m_StartDone) then
        HandleMissionLogic();
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF);
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

---------------------------
-- Mission Related Logic
---------------------------
function HandleMissionLogic()
    if (not Mission.m_MissionFailed) then
        CheckVitalObjectsExist();
    end
end

function CheckVitalObjectsExist()
    -- Recycler is dead, mission failed.
    if (not IsAround(Mission.m_Recycler) and not Mission.m_MissionFailed) then
        -- Mission failed.
        Mission.m_MissionFailed = true;

         -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("You allowed your Recycler to be destroyed. Without it, ISDF Beatrice base cannot survive.");
            DoGameover(10);
        else
            FailMission(10, "isdf07l1.txt");
        end
    end
end