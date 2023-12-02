--[[ 
    BZCC ISDF03 Lua Mission Script
    Written by AI_Unit
    Version 1.0 30-11-2023
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
    m_PlayerPilotODF = "isuser_mx";
    -- Specific to mission.
    m_PlayerShipODF = "ivscout_x";

    m_MainPlayer = nil,
    m_Shabayev = nil,
    m_Relic1 = nil,
    m_Relic2 = nil,
    m_Truck = nil,
    m_Armory = nil,
    m_Hauler1 = nil,
    m_TechCenter = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionOver = false,
    m_TunnelWarningActive = false,
    m_ShabThroughTunnel = false,
    m_FixHaulerHealth = false,

    m_Audioclip = nil,

    m_MissionDelayTime = 0,
    m_TunnelWarningTime = 0,

    -- Keep track of which functions are running.
    m_MissionState = 1
}

-- Functions Table
local Functions = {};

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
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
    PreloadODF("ivpscou");
    PreloadODF("ivplysct");
    PreloadODF("ivscout_x");
    PreloadODF("ispilo_x");
    PreloadODF("ivserv_x");
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
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1;
    else
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1;
    end

    -- Few prints to console.
    print("Welcome to ISDF08 (Lua)");
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

    -- Grab all of our pre-placed handles.
    Mission.m_Shabayev = GetHandle("shabayev");
    Mission.m_Truck = GetHandle("truck");
    Mission.m_Relic1 = GetHandle("ex_tank1");
    Mission.m_Relic2 = GetHandle("ex_tank2");
    Mission.m_Hauler1 = GetHandle("hauler1");
    Mission.m_TechCenter = GetHandle("tech_center");

    -- Give Shab her name.
    SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
    -- Highlight Shabayev.
    SetObjectiveOn(Mission.m_Shabayev);
    -- Give her the correct pilot.
    SetPilotClass(Mission.m_Shabayev, "isshab_p");
    -- So she always ejects.
    SetEjectRatio(Mission.m_Shabayev, 1);
    -- Make sure she has good skill.
    SetSkill(Mission.m_Shabayev, 3);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;
end

function Update()
    -- Keep track of the main player.
    Mission.m_MainPlayer = GetPlayerHandle(1);

    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Start mission logic.
    if (not Mission.m_MissionOver) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- For failures.
            HandleFailureConditions()
        end
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, true, 0.2);
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
    if (IsPlayer(ShooterHandle) and OrdnanceTeam == Mission.m_HostTeam and (Mission.m_Audioclip == nil or IsAudioMessageDone(Mission.m_Audioclip))) then
        if (VictimHandle == Mission.m_Shabayev) then
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("ff01.wav");
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Clean up any player spawns that haven't been taken by the player.
    CleanSpawns();

    -- Have the Hauler pick up the relic.
    Pickup(Mission.m_Hauler1, Mission.m_Relic1);

    -- This sets the Hauler to invulnerable for a short period.
    SetMaxHealth(Mission.m_Hauler1, 0);

    -- Shabayev is looking at our player.
    LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

    -- Make her not care about avoidance.
    SetAvoidType(Mission.m_Shabayev, 0);

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Shab: We're not out of the woods yet..
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0301.wav");

        -- Tiny delay
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Shabayev to look towards the tunnels.
        LookAt(Mission.m_Shabayev, Mission.m_TechCenter);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Show the objectives.
        AddObjectiveOverride("isdf0301.otf", "WHITE", 10, true);

        -- Set up a warning.
        Mission.m_TunnelWarningTime = Mission.m_MissionTime + SecondsToTurns(60);

        -- So Shabayev yells for taking too long.
        Mission.m_TunnelWarningActive = true;

        -- Have her move to the "Tall Building".
        Goto(Mission.m_Shabayev, "building_point");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- This does a check to see if players are near the trigger points.
    for i = 1, _Cooperative.m_TotalPlayerCount do
        local p = GetPlayerHandle(i);

        -- So they are in the tunnels, not above them.
        if (InBuilding(p)) then
            -- Distance check to make sure that the hauler retreats.
            if (GetDistance(p, "check3") < 12) then
                -- Force the Hauler to retreat.
                Retreat(Mission.m_Hauler1, "haulerout_path1");

                -- Show the objectives.
                AddObjectiveOverride("isdf0301.otf", "WHITE", 10, true);
                AddObjective("isdf0302.otf", "WHITE");

                -- Shab: "I'm on my way!"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0304.wav");

                -- Send her into the tunnels.
                Follow(Mission.m_Shabayev, Mission.m_Relic1);

                -- Advance the mission state...
                Mission.m_MissionState = Mission.m_MissionState + 1;
            end
        end
    end
end

Functions[6] = function()
    -- The Hauler needs to remain unkillable for the length that it's in the tunnel. I suspect this is to prevent further issue with other Haulers trying to pick up the ISDF crate.
    if (not Mission.m_FixHaulerHealth) then
        if (GetDistance(Mission.m_Hauler1, "shab_check1") < 30) then
            -- Make it killable.
            SetMaxHealth(Mission.m_Hauler1, 2500);

            -- So we don't loop
            Mission.m_FixHaulerHealth = true;
        end
    end

    -- This is to check if Shabayev has made it through the tunnel. Plays the appropriate response based on if she does or doesn't.
    if (not Mission.m_ShabThroughTunnel) then
        if (GetDistance(Mission.m_Shabayev, "shab_check1") < 55 or GetDistance(Mission.m_Hauler1) < 90) then
            -- This checks to see if the Hauler is alive.
            if (IsAlive(Mission.m_Hauler1)) then
                -- Show the objectives.
                AddObjectiveOverride("isdf0302.otf", "GREEN", 10, true);
                AddObjective("isdf0303.otf", "WHITE");

                -- Shab: Stop that Hauler!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0306.wav");

                -- Have her attack the Hauler.
                Attack(Mission.m_Shabayev, Mission.m_Hauler1);
            else
                -- Have Shabayev go to the first crate.
                Follow(Mission.m_Shabayev, Mission.m_Relic1, 1);
            end

            -- To stop us from looping.
            Mission.m_ShabThroughTunnel = true;
        end
    end

    if (not IsAlive(Mission.m_Hauler1)) then
        if (not Mission.m_ShabThroughTunnel) then
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0307.wav");
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    -- Have Shabayev follow the relic.
    Follow(Mission.m_Shabayev, Mission.m_Relic1, 1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[8] = function()

end

function HandleFailureConditions()
    -- If the player takes too long to reach the bunker.
    if (Mission.m_TunnelWarningActive) then
        if (Mission.m_TunnelWarningTime < Mission.m_MissionTime) then
            -- Shab: Did you search those tunnels?!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0302.wav");

            -- Reshow the objectives.
            AddObjectiveOverride("isdf0301.otf", "WHITE", 10, true);

            -- Set up a warning.
            Mission.m_TunnelWarningTime = Mission.m_MissionTime + SecondsToTurns(60);
        end 
    end
end