--[[
    BZCC Scion06 Lua Mission Script
    Written by AI_Unit
    Version 1.0 18-05-2025
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
local m_MissionName = "Scion01: Transformation";

-- Difficulty tables for attackers.
local m_WaveAttackers = {
    { { "ivscout_x", "ivscout_x" },            { "ivmisl_x", "ivscout_x" },             { "ivtank_x", "ivscout_x" } },                        -- Attack 1
    { { "ivscout_x", "ivmisl_x" },             { "ivmisl_x", "ivtank_x" },              { "ivtank_x", "ivscout_x", "ivmbike_x" } },           -- Attack 2
    { { "ivtank_x", "ivmisl_x" },              { "ivtank_x", "ivtank_x", "ivscout_x" }, { "ivtank_x", "ivtank_x", "ivrckt_x", "ivmisl_x" } }, -- Attack 3
    { { "ivtank_x", "ivscout_x", "ivmisl_x" }, { "ivtank_x", "ivtank_x", "ivrckt_x" },  { "ivrckt_x", "ivtank_x", "ivatank_x", "ivtank_x" } } -- Attack 4
}

local m_WaveCooldowns = { 45, 60, 75, 90 };

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

    m_MainPlayer = nil,
    m_Yelena = nil,

    m_Cons = nil,
    m_Kiln = nil,
    m_PlayersRecy = nil,
    m_Escort2A = nil,
    m_Escort2B = nil,

    m_PlayerSentry1 = nil,
    m_PlayerSentry2 = nil,
    m_PlayerSentry3 = nil,
    m_PlayerSentry4 = nil,

    m_OldPlayerTank = nil,

    m_Landslide = nil,
    m_Jak1 = nil,
    m_Jak2 = nil,
    m_Jak3 = nil,
    m_Jak4 = nil,
    m_Jak5 = nil,
    m_Jak6 = nil,
    m_Jak7 = nil,
    m_Jak8 = nil,
    m_Jak9 = nil,
    m_Jak10 = nil,

    m_JakStay1 = nil,
    m_JakStay2 = nil,

    m_CamLook1 = nil,
    m_CamLook2 = nil,
    m_IntroShot2Look = nil,
    m_PilotsLook1 = nil,
    m_DropshipCam1Look = nil,

    m_ISDFAttacker1 = nil,
    m_ISDFAttacker2 = nil,
    m_ISDFAttacker3 = nil,
    m_ISDFAttacker4 = nil,

    m_PlayerPilo1 = nil,
    m_ShabPilo = nil,
    m_ShabPilo3 = nil,

    m_DeltaSquad1 = nil,
    m_DeltaSquad2 = nil,
    m_Hauler = nil,
    m_PowerCrystal = nil,

    m_Nav1 = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_PilotsMoved = false,
    m_ConstructorMoved = false,
    m_IntroCutsceneDone = false,
    m_ShabInShip = false,
    m_ShabRelook = false,
    m_EnableAnimals = false,
    m_PowerLungWarningActive = false,
    m_MorphWarningActive = false,
    m_PlayerTookTooLongMorphing = false,
    m_PowerObjectivesShown = false,
    m_MorphObjectivesShown = false,
    m_EnableISDF = false,
    m_EnableISDFWaves = false,
    m_ISDFWaveSpawned = false,
    m_YelenaUnderFire = false,
    m_YelenaPraise = false,
    m_YelenaReturnToPatrol = false,
    m_SpawnDeltaSquad = false,
    m_MeetDeltaWarningActive = false,
    m_DeltaBrainActive = false,
    m_Escort1Close = false,
    m_Escort1Far = false,

    m_JakStop1 = false,
    m_JakStop2 = false,

    m_Jak12Spawned = false,

    m_CutsceneAudioClip = nil,
    m_Audioclip = nil,
    m_PowerClip = nil,
    m_MorphClip = nil,
    m_AudioTimer = 0,

    m_JakGoTime2 = 0,
    m_Jak12SpawnTime = 0,
    m_Jak910SpawnTime = 0,

    m_DeltaSquadSpawnTime = 0,
    m_PilotMoveTime = 0,
    m_MissionDelayTime = 0,
    m_PowerLunchTookTooLongTime = 0,
    m_MorphTookTooLongTime = 0,
    m_MorphTookTooLongWarningCount = 0,
    m_ISDFWaveTime = 0,
    m_ISDFWaveCount = 1,
    m_DeltaWarningCount = 0,

    -- Steps for each section.
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

    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();

    -- Preload any ODFs that are spawned in for the ISDF.
    PreloadODF("ivscout_x");
    PreloadODF("ivmisl_x");
    PreloadODF("ivtank_x");
    PreloadODF("ivmbike_x");
    PreloadODF("ivrckt_x");
    PreloadODF("ivatank_x");
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
    local objClass = GetClassLabel(h);

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        -- Always max our player units.
        SetSkill(h, 3);
    end
end

function DeleteObject(h)
    if (h == Mission.m_Jak1) then
        Mission.m_Jak1 = nil;
    elseif (h == Mission.m_Jak2) then
        Mission.m_Jak2 = nil;
    elseif (h == Mission.m_Jak3) then
        Mission.m_Jak3 = nil;
    elseif (h == Mission.m_Jak4) then
        Mission.m_Jak4 = nil;
    elseif (h == Mission.m_Jak5) then
        Mission.m_Jak5 = nil;
    elseif (h == Mission.m_Jak6) then
        Mission.m_Jak6 = nil;
    elseif (h == Mission.m_Jak7) then
        Mission.m_Jak7 = nil;
    elseif (h == Mission.m_Jak8) then
        Mission.m_Jak8 = nil;
    elseif (h == Mission.m_Jak9) then
        Mission.m_Jak9 = nil;
    elseif (h == Mission.m_Jak10) then
        Mission.m_Jak10 = nil;
    elseif (h == Mission.m_JakStay1) then
        Mission.m_JakStay1 = nil;
    elseif (h == Mission.m_JakStay2) then
        Mission.m_JakStay2 = nil;
    end

    -- Specific to ISDF wave logic.
    if (Mission.m_EnableISDFWaves and Mission.m_ISDFWaveSpawned) then
        if (h == Mission.m_ISDFAttacker1) then
            Mission.m_ISDFAttacker1 = nil;
        elseif (h == Mission.m_ISDFAttacker2) then
            Mission.m_ISDFAttacker2 = nil;
        elseif (h == Mission.m_ISDFAttacker3) then
            Mission.m_ISDFAttacker3 = nil;
        elseif (h == Mission.m_ISDFAttacker4) then
            Mission.m_ISDFAttacker4 = nil;
        end

        -- Check that all of the above are dead. If so, reset the wave spawn.
        if (Mission.m_ISDFAttacker1 == nil and Mission.m_ISDFAttacker2 == nil and Mission.m_ISDFAttacker3 == nil and Mission.m_ISDFAttacker4 == nil) then
            -- Increase the wave count.
            Mission.m_ISDFWaveCount = Mission.m_ISDFWaveCount + 1;

            -- if we are on the final wave. Disable ISDF waves.
            if (Mission.m_ISDFWaveCount > #m_WaveAttackers) then
                -- Disable ISDF waves.
                Mission.m_EnableISDFWaves = false;

                -- Prepare the spawn for Delta squad.
                Mission.m_DeltaSquadSpawnTime = Mission.m_MissionTime + SecondsToTurns(30);

                -- Get ready to spawn Delta squad.
                Mission.m_SpawnDeltaSquad = true;
            else
                -- Add a delay before the next wave.
                Mission.m_ISDFWaveTime = Mission.m_MissionTime + SecondsToTurns(m_WaveCooldowns[Mission.m_ISDFWaveCount]);

                -- Reset the wave spawn.
                Mission.m_ISDFWaveSpawned = false;
            end
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
        _Cooperative.Update(m_GameTPS);
    end

    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Get the main player
    Mission.m_MainPlayer = GetPlayerHandle(1);

    -- Start mission logic.
    if (Mission.m_MissionOver == false) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Check failure conditions...
            HandleFailureConditions();

            if (Mission.m_EnableAnimals) then
                HandleMireAnimals();
            end

            if (Mission.m_EnableISDF) then
                HandleISDF();
            end

            if (Mission.m_DeltaBrainActive) then
                HandleDeltaBrain();
            end

            -- Check to see if the intro cutscene has been skipped.
            if (Mission.m_IsCooperativeMode == false and Mission.m_IntroCutsceneDone == false) then
                if (CameraCancelled()) then
                    -- Set the cutscene as done.
                    Mission.m_IntroCutsceneDone = true;

                    if (IsAround(Mission.m_PlayerPilo1)) then
                        RemoveObject(Mission.m_PlayerPilo1);
                    end

                    if (IsAround(Mission.m_ShabPilo)) then
                        RemoveObject(Mission.m_ShabPilo);
                    end

                    if (IsAround(Mission.m_ShabPilo3)) then
                        RemoveObject(Mission.m_ShabPilo3);
                    end

                    if (Mission.m_ConstructorMoved == false) then
                        Goto(Mission.m_Cons, "builder_path2", 0);
                        Mission.m_ConstructorMoved = true;
                    end

                    if (IsAudioMessageDone(Mission.m_CutsceneAudioClip) == false) then
                        StopAudioMessage(Mission.m_CutsceneAudioClip);
                    end

                    CameraFinish();

                    -- Create Shabayev's pilot.
                    CreateShab3Pilot();
                end
            end
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
    -- Unique to this mission.
    if (pilotHandle == Mission.m_ShabPilo3 and emptyCraftHandle == Mission.m_Yelena and Mission.m_ShabInShip == false) then
        -- Prevent a loop.
        Mission.m_ShabInShip = true;
    end

    -- This makes sure that Shabayev looks at the first player who enters their ship.
    if (Mission.m_ShabRelook == false and Mission.m_ShabInShip and (emptyCraftHandle == Mission.m_PlayerSentry1 or emptyCraftHandle == Mission.m_PlayerSentry2 or emptyCraftHandle == Mission.m_PlayerSentry3 or emptyCraftHandle == Mission.m_PlayerSentry4)) then
        LookAt(Mission.m_Yelena, emptyCraftHandle);
        Mission.m_ShabRelook = true;
    end

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
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_AlliedTeam, "Scion");
    SetTeamNameForStat(Mission.m_EnemyTeam, "ISDF");
    SetTeamNameForStat(7, "Scion Rebels");

    SetTeamColor(7, 85, 255, 85);

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Grab any important pre-placed objects.
    Mission.m_Yelena = GetHandle("shab");

    Mission.m_Cons = GetHandle("fvcons1");
    Mission.m_Kiln = GetHandle("kiln");
    Mission.m_PlayersRecy = GetHandle("playersrecy");

    Mission.m_PlayerSentry1 = GetHandle("player_sentry_1");
    Mission.m_PlayerSentry2 = GetHandle("player_sentry_2");
    Mission.m_PlayerSentry3 = GetHandle("player_sentry_3");
    Mission.m_PlayerSentry4 = GetHandle("player_sentry_4");

    Mission.m_JakStay1 = GetHandle("jakstay1");
    Mission.m_JakStay2 = GetHandle("jakstay2");

    Mission.m_Jak3 = GetHandle("jak3");
    Mission.m_Jak4 = GetHandle("jak4");
    Mission.m_Jak5 = GetHandle("jak5");
    Mission.m_Jak7 = GetHandle("jak7");
    Mission.m_Jak8 = GetHandle("jak8");

    Mission.m_Escort2A = GetHandle("escort2a");
    Mission.m_Escort2B = GetHandle("escort2b");

    Mission.m_Landslide = GetHandle("landslide");

    Mission.m_CamLook1 = GetHandle("camlook1");
    Mission.m_CamLook2 = GetHandle("camlook2");
    Mission.m_IntroShot2Look = GetHandle("intro_shot2look");
    Mission.m_PilotsLook1 = GetHandle("pilots_look1");
    Mission.m_DropshipCam1Look = GetHandle("dropship_cam1look");

    Mission.m_PlayerPilo1 = GetHandle("player_pilo1");
    Mission.m_ShabPilo = GetHandle("shab_pilo");

    Mission.m_OldPlayerTank = GetHandle("player_old_tank");

    -- Remove the player sentries depending on the player count.
    if (_Cooperative.m_TotalPlayerCount < 4) then
        RemoveObject(Mission.m_PlayerSentry4);

        if (_Cooperative.m_TotalPlayerCount < 3) then
            RemoveObject(Mission.m_PlayerSentry3);

            if (_Cooperative.m_TotalPlayerCount < 2) then
                RemoveObject(Mission.m_PlayerSentry2);
            end
        end
    end

    -- Clean up any player spawns that haven't been taken by the player.
    _Cooperative.CleanSpawns();

    -- Advance the mission state...
    if (Mission.m_IsCooperativeMode) then
        -- Remove the player and Shabayev.
        RemoveObject(Mission.m_PlayerPilo1);
        RemoveObject(Mission.m_ShabPilo);

        -- Set the mission state to 7 for coop.
        Mission.m_MissionState = 7;
    else
        -- Set the mission state to 2 for single player.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[2] = function()
    -- Start by moving the constructor a new location.
    Goto(Mission.m_Cons, "builder_path1");

    -- Prepare the Camera.
    CameraReady();

    -- Set a timer for the cutscene.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(17);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[3] = function()
    CameraPath("shot1_path1", 500, 1000, Mission.m_ShabPilo);

    if (Mission.m_MissionTime > Mission.m_MissionDelayTime) then
        -- Move the player and Shabayev to inside the Kiln.
        Retreat(Mission.m_PlayerPilo1, "player_pilo1_path1");
        Retreat(Mission.m_ShabPilo, "shab_pilo_path1");
        Goto(Mission.m_Cons, "builder_path2", 0);

        -- If the player cancels the camera, this is used later to see if we need to move the constructor.
        Mission.m_ConstructorMoved = true;

        -- Set a timer for the cutscene.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    CameraPath("intro_shot2path", 500, 0, Mission.m_IntroShot2Look);

    if (Mission.m_MissionTime > Mission.m_MissionDelayTime) then
        -- Remove the player and Shabayev and switch cameras.
        RemoveObject(Mission.m_PlayerPilo1);
        RemoveObject(Mission.m_ShabPilo);

        -- Cooke: "The scions gave me the same gift that they gave Yelena..."
        Mission.m_CutsceneAudioClip = _Subtitles.AudioWithSubtitles("cutsc0101.wav",
            SUBTITLE_PANEL_SIZES["SubtitlesPanel_Medium"]);

        -- Set a timer for the cutscene.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(28);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- Set the camera to the pilot's view.
    CameraPath("intro_shot3path", 1500, 100, Mission.m_Kiln);

    if (Mission.m_MissionTime > Mission.m_MissionDelayTime) then
        Mission.m_PlayerPilo1 = BuildObject("fspilo_xs01", 0, "player_pilo1_spawn");
        Mission.m_ShabPilo = BuildObject("fspilo_rs01", 0, "shab_pilo_spawn");

        LookAt(Mission.m_PlayerPilo1, Mission.m_PilotsLook1);
        LookAt(Mission.m_ShabPilo, Mission.m_PilotsLook1);

        -- Set a timer for the cutscene.
        Mission.m_PilotMoveTime = Mission.m_MissionTime + SecondsToTurns(5);
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(18);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    CameraPath("intro_shot4path", 200, 0, Mission.m_PlayerPilo1);

    -- Move the pilots to the dropship.
    if (Mission.m_PilotsMoved == false and Mission.m_MissionTime > Mission.m_PilotMoveTime) then
        Retreat(Mission.m_PlayerPilo1, "player_path");
        Retreat(Mission.m_ShabPilo, "shab_path");
        Mission.m_PilotsMoved = true;
    end

    if (Mission.m_MissionTime > Mission.m_MissionDelayTime) then
        RemoveObject(Mission.m_PlayerPilo1);
        RemoveObject(Mission.m_ShabPilo);

        CameraFinish();

        Mission.m_IntroCutsceneDone = true;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    -- Create Shabayev's pilot.
    CreateShab3Pilot();

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[8] = function()
    if (Mission.m_ShabInShip) then
        -- Highlight her ship.
        SetObjectiveName(Mission.m_Yelena, "Yelena");
        SetObjectiveOn(Mission.m_Yelena);

        -- Have her look at the "main" player.
        LookAt(Mission.m_Yelena, Mission.m_MainPlayer);

        -- Make sure Yelena can't be sniped.
        SetCanSnipe(Mission.m_Yelena, 0);

        -- Give the player some scrap.
        SetScrap(Mission.m_HostTeam, 0);

        -- Give Yelena infinite health.
        SetMaxHealth(Mission.m_Yelena, 0);
        SetCurHealth(Mission.m_Yelena, 0);

        -- Max out her skill.
        SetSkill(Mission.m_Yelena, 3);

        -- Send the Jak's to patrol.
        Patrol(Mission.m_Jak3, "jak_3_4_path");
        Follow(Mission.m_Jak4, Mission.m_Jak3);

        Patrol(Mission.m_Jak5, "jak_5_path");
        Patrol(Mission.m_Jak6, "jak_6_path");
        Patrol(Mission.m_Jak7, "jak_7_8_path");
        Follow(Mission.m_Jak8, Mission.m_Jak7);

        -- Halt the "Jak Stays".
        Stop(Mission.m_JakStay1);
        Stop(Mission.m_JakStay2);

        -- Small delay before we spawn Jak 9 and Jak 10.
        Mission.m_Jak910SpawnTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Enable the mire animal handler.
        Mission.m_EnableAnimals = true;

        -- Small delay before the next mission state.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end;

    -- Yelena: "You're new to body, I understand. It took me a while to get used to it too."
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0101.wav");

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(20.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[10] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Yelena: "Scion's use power differently than the ISDF."
    Mission.m_PowerClip = _Subtitles.AudioWithSubtitles("scion0106.wav", SUBTITLE_PANEL_SIZES["SubtitlesPanel_Medium"]);

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(26.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

-- Todo, refactor this to use booleans for the dialog and objectives so we can effectively skip this part if the player does something early.
Functions[11] = function()
    if (IsPowered(Mission.m_Kiln)) then
        -- Stop Yelena from talking.
        StopAudioMessage(Mission.m_PowerClip);

        -- Disable the power lung warning.
        Mission.m_PowerLungWarningActive = false;

        -- Small delay after the power lung is built.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Advance to mission state 13.
        Mission.m_MissionState = Mission.m_MissionState + 1;

        -- So we don't execute the rest of this function.
        return;
    end

    if (Mission.m_PowerObjectivesShown == false) then
        if (IsAudioMessageFinished(Mission.m_PowerClip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            -- Show Objectives.
            AddObjectiveOverride("scion0113.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode);

            -- Activate the power lung warning.
            Mission.m_PowerLungWarningActive = true;

            -- Set the time for the power lung warning.
            Mission.m_PowerLunchTookTooLongTime = Mission.m_MissionTime + SecondsToTurns(90);

            -- Set the flag that we have shown the power objectives.
            Mission.m_PowerObjectivesShown = true;
        end
    end
end

Functions[12] = function()
    if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end;

    -- Yelena: "Good job, now the Kiln is powered.  You should also learn how to morph..."
    Mission.m_MorphClip = _Subtitles.AudioWithSubtitles("scion0102.wav");

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(13.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[13] = function()
    local isPlayerDeployed = false;

    for i = 1, _Cooperative.m_TotalPlayerCount do
        local playerHandle = GetPlayerHandle(i);

        -- Check if the player has deployed.
        if (IsDeployed(playerHandle)) then
            isPlayerDeployed = true;
            break;
        end
    end

    if (isPlayerDeployed or Mission.m_PlayerTookTooLongMorphing) then
        if (isPlayerDeployed) then
            -- Stop the morph audio.
            StopAudioMessage(Mission.m_MorphClip);

            -- Yelena: "Good while morhped your ships can use different weapons and tactics."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0103.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(17.5);

            -- Disable the morph warning.
            Mission.m_MorphWarningActive = false;
        else
            -- Yelena: "You maybe have been a major in braddock's army, but you are just a student here..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0118.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;

        -- So we don't execute the rest of this function.
        return;
    end

    if (Mission.m_MorphObjectivesShown == false) then
        if (IsAudioMessageFinished(Mission.m_MorphClip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            -- Show Objectives.
            AddObjectiveOverride("scion0110.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode);

            -- Activate the morph warning.
            Mission.m_MorphWarningActive = true;

            -- Set the time for the morph warning.
            Mission.m_MorphTookTooLongTime = Mission.m_MissionTime + SecondsToTurns(40);

            -- Set the flag that we have shown the morph objectives.
            Mission.m_MorphObjectivesShown = true;
        end
    end
end

Functions[14] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Small delay before the next mission state.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[15] = function()
    if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end;

    -- Yelena: "OK JOHN, LETS GET READY FOR THE ESCORT.  UPGRADE THE KILN INTO A FORGE AND BEGIN BUILDING SOME WARRIORS AND SENTRY'S."
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0134.wav");

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[16] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Show Objectives.
    AddObjectiveOverride("scion0101.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode);

    -- Enable ISDF attacks.
    Mission.m_EnableISDF = true;

    -- Enable ISDF waves.
    Mission.m_EnableISDFWaves = true;

    -- Small cooldown before the waves.
    Mission.m_ISDFWaveTime = Mission.m_MissionTime + SecondsToTurns(m_WaveCooldowns[Mission.m_ISDFWaveCount]);

    -- Send Yelena to patrol.
    Patrol(Mission.m_Yelena, "shab_patrol");

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[17] = function()
    if (Mission.m_YelenaUnderFire == false) then
        local attacker = nil;

        -- Check if any of the ISDF attackers are within 50 meters of Yelena.
        if (Mission.m_ISDFAttacker1 and GetDistance(Mission.m_ISDFAttacker1, Mission.m_Yelena) < 100) then
            attacker = Mission.m_ISDFAttacker1;
        elseif (Mission.m_ISDFAttacker2 and GetDistance(Mission.m_ISDFAttacker2, Mission.m_Yelena) < 100) then
            attacker = Mission.m_ISDFAttacker2;
        elseif (Mission.m_ISDFAttacker3 and GetDistance(Mission.m_ISDFAttacker3, Mission.m_Yelena) < 100) then
            attacker = Mission.m_ISDFAttacker3;
        elseif (Mission.m_ISDFAttacker4 and GetDistance(Mission.m_ISDFAttacker4, Mission.m_Yelena) < 100) then
            attacker = Mission.m_ISDFAttacker4;
        end

        if (attacker) then
            -- Have Yelena attack.
            Attack(Mission.m_Yelena, attacker);

            -- Yelena: "I'm under fire, John!  Help me out!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0107.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Set the flag that Yelena is under fire.
            Mission.m_YelenaUnderFire = true;
        end
    elseif (Mission.m_YelenaReturnToPatrol == false) then
        if (Mission.m_ISDFAttacker1 == nil and Mission.m_ISDFAttacker2 == nil and Mission.m_ISDFAttacker3 == nil and Mission.m_ISDFAttacker4 == nil) then
            -- Send Yelena back to patrol.
            Patrol(Mission.m_Yelena, "shab_patrol");

            -- Small delay before we praise.
            Mission.m_YelenaPraiseDelay = Mission.m_MissionTime + SecondsToTurns(1.3);

            -- Set the flag that Yelena is returning to patrol.
            Mission.m_YelenaReturnToPatrol = true;
        end
    elseif (Mission.m_YelenaPraise == false and Mission.m_YelenaPraiseDelay < Mission.m_MissionTime) then
        -- Yelena: "Thanks for the help, John.  I appreciate it."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0108.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Set the flag that Yelena has been praised.
        Mission.m_YelenaPraise = true;
    end

    if (Mission.m_SpawnDeltaSquad and Mission.m_DeltaSquadSpawnTime < Mission.m_MissionTime) then
        -- Spawn Delta squad.
        Mission.m_DeltaSquad1 = BuildObject("fvscout_x", Mission.m_HostTeam, "escort1a");
        Mission.m_DeltaSquad2 = BuildObject("fvscout_x", Mission.m_HostTeam, "escort1b");

        Mission.m_Hauler = BuildObject("fvtug", Mission.m_HostTeam, "tug1");
        Mission.m_PowerCrystal = BuildObject("cotran01", 0, "power");

        -- Small delay before the Hauler picks up the crystal.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Delta: "Delta wing--We have the power source, ETA to rondevous is 3 minutes."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0109.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[18] = function()
    if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end;

    -- Have the Hauler pick up the crystal.
    Pickup(Mission.m_Hauler, Mission.m_PowerCrystal);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[19] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Have Delta squad escort the Hauler.
    Retreat(Mission.m_DeltaSquad1, "rondevous1");
    Retreat(Mission.m_Hauler, "rondevous1");
    Follow(Mission.m_DeltaSquad2, Mission.m_PowerCrystal);

    -- Controls Delta squad whilst they move to the rendezvous nav.
    Mission.m_DeltaBrainActive = true;

    -- Yelena: "Excellent, Delta wing. Cooke you're up. Take a couple wingmen, and meet them at Nav 1. Leave a few ships to help me defend the base."
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0110.wav");

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[20] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Build a nav point for the player to go to.
    Mission.m_Nav1 = BuildObject("ibnav", Mission.m_HostTeam, "nav1");

    -- Mark the nav point as an objective.
    SetObjectiveName(Mission.m_Nav1, TranslateString("MissionS0101"));
    SetObjectiveOn(Mission.m_Nav1);
    SetObjectiveOff(Mission.m_Yelena);

    -- Show Objectives.
    AddObjectiveOverride("scion0102.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode);

    -- Add time to the warning for meeting Delta.
    Mission.m_MeetDeltaWarningTime = Mission.m_MissionTime + SecondsToTurns(45);

    -- Activate the warning for meeting Delta.
    Mission.m_MeetDeltaWarningActive = true;

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[21] = function()
    -- This checks to see if a Player has reached the nav point.
    if (GetDistance(Mission.m_Hauler, "rondevous1") and IsPlayerWithinDistance(Mission.m_Hauler, 125, _Cooperative.m_TotalPlayerCount)) then
        -- Delta: Delta wing here, we have Cook on radar. Lt. Shabayev, are you sure we can trust this man with the power source?
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0113.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Stop the first Escort.
        Stop(Mission.m_DeltaSquad1);

        -- Remove the highlight from Nav 1.
        SetObjectiveOff(Mission.m_Nav1);

        -- Remove the brain logic.
        Mission.m_DeltaBrainActive = false;

        -- De-activate the warning for meeting Delta.
        Mission.m_MeetDeltaWarningActive = false;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[22] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;
    -- Yelena: You have my word on it.
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0123.wav");

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[23] = function()

end

function HandleFailureConditions()
    if (Mission.m_PowerLungWarningActive) then
        if (Mission.m_MissionTime > Mission.m_PowerLunchTookTooLongTime) then
            ClearObjectives();
            AddObjective("scion0113b.otf", "RED");
            AddObjective("scion0113c.otf", "RED");

            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0136.wav");

            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("You must follow Shabayev's orders and build a Lung on your Kiln.");
                DoGameover(10);
            else
                FailMission(GetTime() + 10, "scion01L6.txt");
            end

            -- Set the mission over.
            Mission.m_MissionOver = true;
        end
    end

    if (Mission.m_MorphWarningActive) then
        if (Mission.m_MissionTime > Mission.m_MorphTookTooLongTime) then
            if (Mission.m_MorphTookTooLongWarningCount == 0) then
                -- Yelena: "There's no time to waste, John...morph your ship now!".
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0104.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

                -- Increase the warning time.
                Mission.m_MorphTookTooLongTime = Mission.m_MissionTime + SecondsToTurns(20);

                -- Increase the warning count.
                Mission.m_MorphTookTooLongWarningCount = Mission.m_MorphTookTooLongWarningCount + 1;
            elseif (Mission.m_MorphTookTooLongWarningCount == 1) then
                -- Show that the player took too long to morph.
                Mission.m_PlayerTookTooLongMorphing = true;

                -- Disable this warning.
                Mission.m_MorphWarningActive = false;
            end
        end
    end

    if (Mission.m_MeetDeltaWarningActive) then
        if (Mission.m_MissionTime > Mission.m_MeetDeltaWarningTime) then
            if (Mission.m_DeltaWarningCount == 0) then
                -- Delta: "Delta wing here, I'm at the rondevous point, where are you?"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0112.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                -- Increase the warning time.
                Mission.m_MeetDeltaWarningTime = Mission.m_MissionTime + SecondsToTurns(30);

                -- Increase the warning count.
                Mission.m_DeltaWarningCount = Mission.m_DeltaWarningCount + 1;
            elseif (Mission.m_DeltaWarningCount == 1) then
                -- Yelena: "Hurry up Cooke! They could run into trouble out there."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0111.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                -- Increase the warning time.
                Mission.m_MeetDeltaWarningTime = Mission.m_MissionTime + SecondsToTurns(30);

                -- Increase the warning count.
                Mission.m_DeltaWarningCount = Mission.m_DeltaWarningCount + 1;
            elseif (Mission.m_DeltaWarningCount == 2) then
                -- Yelena: "That's it John, I have to let you go! If you cannot follow orders...."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0124.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

                -- Increase the warning count.
                Mission.m_DeltaWarningCount = Mission.m_DeltaWarningCount + 1;
            elseif (Mission.m_DeltaWarningCount == 3 and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, _Mission.m_IsCooperativeMode)) then
                -- Disable this warning.
                Mission.m_MeetDeltaWarningActive = false;

                -- Show the failure message.
                AddObjectiveOverride("scion0102.otf", "RED", 10, true, Mission.m_IsCooperativeMode);

                if (Mission.m_IsCooperativeMode) then
                    NoteGameoverWithCustomMessage(
                        "By leaving Delta Wing alone at Nav 1, you failed to follow orders and left the Power Crystal vulnerable.");
                    DoGameover(6);
                else
                    FailMission(GetTime() + 6, "scion01L1.txt");
                end

                -- Set the mission over.
                Mission.m_MissionOver = true;
            end
        end
    end
end

function HandleMireAnimals()
    if (Mission.m_Jak12Spawned == false and Mission.m_Jak12SpawnTime < Mission.m_MissionTime) then
        -- Spawn the Jak 1 and 2.
        Mission.m_Jak1 = BuildObject("mcjak01", 0, "jak1spawn");
        Mission.m_Jak2 = BuildObject("mcjak01", 0, "jak2spawn");

        -- Move the creatures around.
        Goto(Mission.m_Jak1, "jakstop1");
        Follow(Mission.m_Jak2, Mission.m_Jak1);

        -- So we don't loop.
        Mission.m_Jak12Spawned = true;
    elseif (Mission.m_Jak12Spawned) then
        if (Mission.m_JakStop1 == false and GetDistance(Mission.m_Jak1, "jakstop1" < 15)) then
            if (IsAlive(Mission.m_Jak1)) then
                LookAt(Mission.m_Jak1, Mission.m_PlayersRecy);
            end

            if (IsAlive(Mission.m_Jak2)) then
                LookAt(Mission.m_Jak2, Mission.m_PlayersRecy);
            end

            Mission.m_JakGoTime2 = Mission.m_MissionTime + SecondsToTurns(10);

            -- So we don't loop.
            Mission.m_JakStop1 = true;
        elseif (Mission.m_JakStop2 == false and Mission.m_JakGoTime2 < Mission.m_MissionTime) then
            if (IsAlive(Mission.m_Jak1)) then
                Goto(Mission.m_Jak1, "jakstop2");

                if (IsAlive(Mission.m_Jak2)) then
                    Follow(Mission.m_Jak2, Mission.m_Jak1);
                end
            end

            -- So we don't loop.
            Mission.m_JakStop2 = true;
        end
    end

    if (Mission.m_Jak910SpawnTime < Mission.m_MissionTime) then
        -- Spawn the Jak 9 and Jak 10.
        Mission.m_Jak9 = BuildObject("mcjak01", 0, "jak9spawn");
        Mission.m_Jak10 = BuildObject("mcjak01", 0, "jak10spawn");

        -- Set them to patrol.
        Goto(Mission.m_Jak9, "jak_go1");
        Goto(Mission.m_Jak10, "jak_go1");

        -- Small delay before we spawn Jak 9 and Jak 10.
        Mission.m_Jak910SpawnTime = Mission.m_MissionTime + SecondsToTurns(300);
    end
end

function HandleISDF()
    -- Wave logic.
    if (Mission.m_EnableISDFWaves) then
        -- If a wave has spawned, we don't want to spawn another one.
        if (Mission.m_ISDFWaveSpawned) then return end;

        -- Check if the wave time has passed.
        if (Mission.m_ISDFWaveTime > Mission.m_MissionTime) then return end;

        -- Get the attack wave that we want to spawn.
        local waveAttack = m_WaveAttackers[Mission.m_ISDFWaveCount][Mission.m_MissionDifficulty];

        -- Spawn each attacker in the wave.
        for i = 1, #waveAttack do
            local attackerODF = waveAttack[i];
            local spawnPoint = "";
            local safePoint = "";

            if (i % 2 == 0) then
                spawnPoint = "spawn_2_a";
                safePoint = "spawn_2_b";
            else
                spawnPoint = "spawn_1_a";
                safePoint = "spawn_1_b";
            end

            -- Build the attacker.
            local attackerHandle = BuildObjectAtSafePath(attackerODF, Mission.m_EnemyTeam, spawnPoint, safePoint,
                _Cooperative.m_TotalPlayerCount);

            -- Add to the ISDF attackers.
            if (i == 1) then
                Mission.m_ISDFAttacker1 = attackerHandle;
            elseif (i == 2) then
                Mission.m_ISDFAttacker2 = attackerHandle;
            elseif (i == 3) then
                Mission.m_ISDFAttacker3 = attackerHandle;
            elseif (i == 4) then
                Mission.m_ISDFAttacker4 = attackerHandle;
            end
        end

        -- Depending on the wave, we may want to set some behaviors.
        if (Mission.m_ISDFWaveCount == 1) then
            -- Wave 1: Attack the player.
            Attack(Mission.m_ISDFAttacker1, Mission.m_Yelena);
            Attack(Mission.m_ISDFAttacker2, Mission.m_MainPlayer);
        elseif (Mission.m_ISDFWaveCount == 2) then
            -- Wave 2: Attack the player and Yelena.
            Attack(Mission.m_ISDFAttacker1, Mission.m_MainPlayer);
            Attack(Mission.m_ISDFAttacker2, Mission.m_Kiln);

            if (Mission.m_ISDFAttacker3) then
                -- If we have a third attacker, attack the player.
                Attack(Mission.m_ISDFAttacker3, Mission.m_PlayersRecy);
            end
        elseif (Mission.m_ISDFWaveCount == 3) then
            -- Wave 3: Attack the player and Yelena, but also attack the constructor.
            Attack(Mission.m_ISDFAttacker1, Mission.m_Kiln);
            Attack(Mission.m_ISDFAttacker2, Mission.m_MainPlayer);

            if (Mission.m_ISDFAttacker3) then
                -- If we have a third attacker, attack the player.
                Attack(Mission.m_ISDFAttacker3, Mission.m_Cons);
            end

            if (Mission.m_ISDFAttacker4) then
                -- If we have a fourth attacker, attack the player.
                Attack(Mission.m_ISDFAttacker4, Mission.m_PlayersRecy);
            end
        elseif (Mission.m_ISDFWaveCount == 4) then
            -- Wave 4: Attack the player, Yelena, and the constructor.
            Attack(Mission.m_ISDFAttacker1, Mission.m_MainPlayer);
            Attack(Mission.m_ISDFAttacker2, Mission.m_Yelena);
            Attack(Mission.m_ISDFAttacker3, Mission.m_Cons);

            if (Mission.m_ISDFAttacker4) then
                -- If we have a fourth attacker, attack the player.
                Attack(Mission.m_ISDFAttacker4, Mission.m_PlayersRecy);
            end
        end

        -- Mark that a wave has spawned.
        Mission.m_ISDFWaveSpawned = true;
    end
end

function HandleDeltaBrain()
    if (Mission.m_Escort1Far == false and GetDistance(Mission.m_DeltaSquad1, Mission.m_Hauler) > 100) then
        LookAt(Mission.m_DeltaSquad1, Mission.m_Hauler, 1);
        Mission.m_Escort1Far = true;
        Mission.m_Escort1Close = false;
    elseif (Mission.m_Escort1Close == false and GetDistance(Mission.m_DeltaSquad1, Mission.m_Hauler < 99)) then
        Retreat(Mission.m_DeltaSquad1, "rondevous1", 1);
        Mission.m_Escort1Close = true;
        Mission.m_Escort1Far = false;
    end
end

function CreateShab3Pilot()
    -- Create the Shabayev pilot.
    Mission.m_ShabPilo3 = BuildObject("fspilo_r", Mission.m_HostTeam, "shab_spawn2");
    SetMaxHealth(Mission.m_ShabPilo3, 0);
    SetCurHealth(Mission.m_ShabPilo3, 0);
    SetCanSnipe(Mission.m_ShabPilo3, 0);
    Retreat(Mission.m_ShabPilo3, Mission.m_Yelena);
end
