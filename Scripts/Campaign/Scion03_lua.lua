--[[
    BZCC Scion03 Lua Mission Script
    Written by AI_Unit
    Version 1.0 14-12-2024
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
local m_GameTPS = 20;

-- Mission Name
local m_MissionName = "Scion03: Crystals";

-- Difficulty Tables.
local Wave1Unit_A = { "ivscout_x", "ivmisl_x", "ivtank_x" };
local Wave1Unit_B = { "ivscout_x", "ivscout_x", "ivmisl_x" };

local Wave2Unit_A = { "ivmisl_x", "ivtank_x", "ivtank_x" };
local Wave2Unit_B = { "ivscout_x", "ivmisl_x", "ivtank_x" };

-- Mission important variables.
local Mission =
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "fspilo_x",
    -- Specific to mission.
    m_PlayerShipODF = "fvtank_x",

    m_Power = nil,
    m_Recy1 = nil,
    m_Alpha1 = nil,
    m_Alpha2 = nil,
    m_Misl1 = nil,
    m_Misl2 = nil,
    m_PlayersRecy = nil,
    m_Jak1 = nil,
    m_Jak2 = nil,
    m_Jak3 = nil,
    m_Jak4 = nil,
    m_Jak5 = nil,
    m_Jak6 = nil,
    m_Jak7 = nil,
    m_Rocket1 = nil,
    m_Rocket2 = nil,
    m_Rocket3 = nil,
    m_Rocket4 = nil,
    m_Rocket5 = nil,
    m_Rocket6 = nil,
    m_Rocket7 = nil,
    m_ISDFScav1 = nil,
    m_Hauler = nil,
    m_Yelena = nil,

    m_Wave_Unit_A = nil,
    m_Wave_Unit_B = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_AlphaSpotted = false,
    m_WavesActive = false,
    m_Wave1Spawned = false,
    m_Wave2Spawned = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_WaveTimer = 0,

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
    PreloadODF("ivrecy_x");
    PreloadODF("fvrecy_x");
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
    local team = GetTeamNum(h);
    local ObjClass = GetClassLabel(h);

    -- Handle unit skill for enemy.
    if (team == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);
    elseif (team < Mission.m_AlliedTeam and team > 0) then
        SetSkill(h, 3);

        if (ObjClass == "VIRTUAL_CLASS_TUG") then
            Mission.m_Hauler = h;
        end
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

    -- Start mission logic.
    if (not Mission.m_MissionOver and (Mission.m_IsCooperativeMode == false or _Cooperative.GetGameReadyStatus())) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Check failure conditions...
            HandleFailureConditions();

            if (Mission.m_WavesActive) then
                WavesLogic();
            end
        end
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

function PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
    if (IsPlayer(ShooterHandle) and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (IsAlive(Mission.m_Yelena) and VictimHandle == Mission.m_Yelena) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scngen30.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        end

        if (Mission.m_AlphaSpotted == false) then
            if (VictimHandle == Mission.m_Alpha1 or VictimHandle == Mission.m_Alpha2) then
                if (GetCurrentHealth(VictimHandle) < 150) then
                    -- Stop the mission.
                    Mission.m_MissionOver = true;

                    -- Mission failed.
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scngen08.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

                    -- Objectives.
                    AddObjectiveOverride("scion0306.otf", "RED", 15, true);

                    -- Failure.
                    if (Mission.m_IsCooperativeMode) then
                        NoteGameoverWithCustomMessage("Friendly fire will not be tolerated.");
                        DoGameover(15);
                    else
                        FailMission(GetTime() + 15, "scion03L1.txt");
                    end
                end
            end
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "ISDF");
    SetTeamNameForStat(7, "ISDF");
    SetTeamNameForStat(Mission.m_AlliedTeam, "Scion");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Ally both enemy teams.
    Ally(6, 7);

    -- Give teams scrap.
    SetScrap(Mission.m_HostTeam, 40);
    SetScrap(Mission.m_EnemyTeam, 30);

    -- Grab any pre-placed handles.
    Mission.m_Yelena = GetHandle("yelena");

    Mission.m_Alpha1 = GetHandle("alpha1");
    Mission.m_Alpha2 = GetHandle("alpha2");
    Mission.m_Power = GetHandle("power");
    Mission.m_Recy1 = GetHandle("recy1");
    Mission.m_Misl1 = GetHandle("misl1");
    Mission.m_Misl2 = GetHandle("misl2");
    Mission.m_PlayersRecy = GetHandle("playersrecy");

    Mission.m_Jak1 = GetHandle("jak1");
    Mission.m_Jak2 = GetHandle("jak2");
    Mission.m_Jak3 = GetHandle("jak3");
    Mission.m_Jak4 = GetHandle("jak4");
    Mission.m_Jak5 = GetHandle("jak5");
    Mission.m_Jak6 = GetHandle("jak6");
    Mission.m_Jak7 = GetHandle("jak7");

    Mission.m_Rocket1 = GetHandle("ivrckt1");
    Mission.m_Rocket2 = GetHandle("ivrckt2");
    Mission.m_Rocket3 = GetHandle("ivrckt3");
    Mission.m_Rocket4 = GetHandle("ivrckt4");
    Mission.m_Rocket5 = GetHandle("ivrckt5");
    Mission.m_Rocket6 = GetHandle("ivrckt6");
    Mission.m_Rocket7 = GetHandle("ivrckt7");

    Mission.m_ISDFScav1 = GetHandle("isdf_scav1");

    -- Set initial orders for units.
    Stop(Mission.m_Alpha1, 1);
    Stop(Mission.m_Alpha2, 1);

    Patrol(Mission.m_Misl1, "misl1_patrol");
    Patrol(Mission.m_Misl2, "misl2_patrol");

    Patrol(Mission.m_Jak1, "jak_1_2_path");
    Follow(Mission.m_Jak2, Mission.m_Jak1);

    Patrol(Mission.m_Jak3, "jak_3_path");
    Patrol(Mission.m_Jak4, "jak_4_path");
    Patrol(Mission.m_Jak5, "jak_5_path");
    Patrol(Mission.m_Jak6, "jak_6_7_path");
    Follow(Mission.m_Jak7, Mission.m_Jak6);

    -- Set the enemy AIP plan.
    SetAIP("scion0301_x.aip", Mission.m_EnemyTeam);

    -- Give Yelena infinite health.
    SetMaxHealth(Mission.m_Yelena, 0);

    -- Give her a name.
    SetObjectiveName(Mission.m_Yelena, "Yelena");
    SetObjectiveOn(Mission.m_Yelena);

    -- So she can't be commanded.
    Stop(Mission.m_Yelena, 1);

    -- Stop Yelena from being sniped.
    SetCanSnipe(Mission.m_Yelena, 0);

    -- Stop Alpha Wing from being sniped.
    SetCanSnipe(Mission.m_Alpha1, 0);
    SetCanSnipe(Mission.m_Alpha2, 0);

    -- To account for distance, reduce the timer to 60 seconds from original 70.
    Mission.m_WaveTimer = Mission.m_MissionTime + SecondsToTurns(60);

    -- Activate the waves.
    Mission.m_WavesActive = true;

    -- Small delay before the first interaction.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(4);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- SHAB - We still do not have precise coordinates of the ISDF base. I'm sending out a scout patrol to find the base . . .
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0306.wav");

        LookAt(Mission.m_Yelena, GetPlayerHandle(1), 1);
        LookAt(Mission.m_Alpha1, Mission.m_Yelena, 1);
        LookAt(Mission.m_Alpha2, Mission.m_Yelena, 1);

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- ALPHA1 - Yes, Shabayev.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0307.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- SHAB - Alpha wing, do a recon sweep to the North and get us the precise coordinates of the ISDF base..
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0308.wav");

        -- Have Yelena look at the first scout ship.
        LookAt(Mission.m_Yelena, Mission.m_Alpha1, 1);

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- ALPHA1 - As you wish.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0309.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(1.5);

        -- So the enemy doesn't attack Alpha.
        SetPerceivedTeam(Mission.m_Alpha1, Mission.m_EnemyTeam);
        SetPerceivedTeam(Mission.m_Alpha2, Mission.m_EnemyTeam);
        SetIndependence(Mission.m_Alpha2, 0);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Send Alpha down their path.
        Retreat(Mission.m_Alpha1, "alphapath");
        Follow(Mission.m_Alpha2, Mission.m_Alpha1);

        -- SHAB - Cooke, focus on building the base while Alpha wing searches for the ISDF.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0310.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Have Yelena look at the first player.
        LookAt(Mission.m_Yelena, GetPlayerHandle(1), 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        AddObjective("scion0304.otf", "WHITE");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    -- Stop the player from assisting Alpha Wing for the time being.


    -- This will check to see if the waves are completed, and dead.
    if (Mission.m_Wave2Spawned and (IsAliveAndEnemy(Mission.m_Wave_Unit_A, 7) == false and IsAliveAndEnemy(Mission.m_Wave_Unit_B, 7) == false)) then
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(8);

        -- Stop the wave logic.
        Mission.m_WavesActive = false;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- ALPHA1 - Alpha wing reporting, we think we've found the base.  Oh no, we've been spotted!  We Are under attack!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0311.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Send Alpha to die.
        SetPerceivedTeam(Mission.m_Alpha1, 1);
        SetPerceivedTeam(Mission.m_Alpha2, 1);

        SetIndependence(Mission.m_Alpha1, 1);
        SetIndependence(Mission.m_Alpha2, 1);

        Goto(Mission.m_Alpha1, "enemybase");
        Goto(Mission.m_Alpha2, "enemybase");

        Attack(Mission.m_Misl1, Mission.m_Alpha1);
        Attack(Mission.m_Misl2, Mission.m_Alpha2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[10] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- SHAB - Alpha wing, can you handle the situation?
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0312.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- ALPHA1 - Negative, negative, there are too many of them.  I'm breaking up!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0313.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Wait to see if both Alpha units are dead.
        if (IsAlive(Mission.m_Alpha1) == false and IsAlive(Mission.m_Alpha2) == false) then
            -- Small delay before Yelena's next message.
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(6);

            -- Send the patrols back to their patrol paths.
            Patrol(Mission.m_Misl1, "misl1_patrol");
            Patrol(Mission.m_Misl2, "misl2_patrol");

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[13] = function()

end

function HandleFailureConditions()
    if (IsAround(Mission.m_Power) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Show failure objective.
        AddObjectiveOverride("scion0302.otf", "RED", 10, true);

        -- Mission failed.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0305.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The Power Crystal was destroyed.");
            DoGameover(15);
        else
            FailMission(GetTime() + 15, "scion03L2.txt");
        end
    end
end

function WavesLogic()
    if (Mission.m_WaveTimer < Mission.m_MissionTime) then
        if (Mission.m_Wave1Spawned == false) then
            -- Build enemies.
            Mission.m_Wave_Unit_A = BuildObject(Wave1Unit_A[Mission.m_MissionDifficulty], 7, "spawn1");
            Mission.m_Wave_Unit_B = BuildObject(Wave1Unit_B[Mission.m_MissionDifficulty], 7, "spawn2");

            -- Have the second unit, follow the first.
            Defend2(Mission.m_Wave_Unit_B, Mission.m_Wave_Unit_A);

            -- Have the first unit move to the base.
            Goto(Mission.m_Wave_Unit_A, "wave_1_path");

            -- New timer.
            Mission.m_WaveTimer = Mission.m_MissionTime + SecondsToTurns(110);

            Mission.m_Wave1Spawned = true;
        elseif (Mission.m_Wave2Spawned == false) then
            -- Build enemies.
            Mission.m_Wave_Unit_A = BuildObject(Wave2Unit_A[Mission.m_MissionDifficulty], 7, "spawn3");
            Mission.m_Wave_Unit_B = BuildObject(Wave2Unit_B[Mission.m_MissionDifficulty], 7, "spawn4");

            -- Have the second unit, follow the first.
            Defend2(Mission.m_Wave_Unit_B, Mission.m_Wave_Unit_A);

            -- Have the first unit move to the base.
            Goto(Mission.m_Wave_Unit_A, "wave_2_path");

            Mission.m_Wave2Spawned = true;
        end
    end
end
