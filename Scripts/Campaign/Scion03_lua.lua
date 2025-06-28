--[[
    BZCC Scion03 Lua Mission Script
    Written by AI_Unit
    Version 1.0 14-12-2024
--]]

-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))();

-- Required Globals.
require("_GlobalVariables");

-- Required AI Commands.
require("_AICmd");

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

    m_BadPlayer = nil,

    m_Nav1 = nil,
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
    m_ISDFTank1 = nil,
    m_ISDFTank2 = nil,
    m_ISDFTank3 = nil,

    m_Wave_Unit_A = nil,
    m_Wave_Unit_B = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_MissionPaused = false,
    m_Punishment = false,

    m_AlphaSpotted = false,
    m_WavesActive = false,
    m_Wave1Spawned = false,
    m_Wave2Spawned = false,
    m_YelenaBrainActive = false,

    m_Tank1Moved = false,
    m_Tank2Moved = false,
    m_Tank3Moved = false,

    m_PlayerHasPower = false,
    m_PlayerDistanceChecker = true,
    m_PlayerDistanceWarningCount = 0,
    m_PlayerDistanceCheckerDelay = 0,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_PunishDelay = 0,
    m_MissionDelayTime = 0,
    m_WaveTimer = 0,
    m_TankMoveTimer = 0,

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

        -- Grab tanks for the AIP Helper.
        if (IsOdf(h, "ivtank_x")) then
            -- Assign some time before we move the tanks.
            Mission.m_TankMoveTimer = Mission.m_MissionTime + SecondsToTurns(2);

            -- This will handle assigning the tanks to the relevant variables for the helper.
            if (IsAliveAndEnemy(Mission.m_ISDFTank1, Mission.m_EnemyTeam) == false) then
                Mission.m_ISDFTank1 = h;
                Mission.m_Tank1Moved = false;
            elseif (IsAliveAndEnemy(Mission.m_ISDFTank2, Mission.m_EnemyTeam) == false) then
                Mission.m_ISDFTank2 = h;
                Mission.m_Tank2Moved = false;
            elseif (IsAliveAndEnemy(Mission.m_ISDFTank3, Mission.m_EnemyTeam) == false) then
                Mission.m_ISDFTank3 = h;
                Mission.m_Tank3Moved = false;
            end
        end
    elseif (team < Mission.m_AlliedTeam and team > 0) then
        SetSkill(h, 3);

        if (ObjClass == "VIRTUAL_CLASS_TUG") then
            Mission.m_Hauler = h;
        end
    end
end

function DeleteObject(h)
    if (h == Mission.m_Recy1) then
        -- Recycler has been destroyed.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0303.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
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

    -- Start mission logic.
    if (Mission.m_MissionOver == false) then
        if (Mission.m_StartDone) then
            if (Mission.m_MissionPaused == false) then
                -- Run each function for the mission.
                Functions[Mission.m_MissionState]();
            end

            -- Check failure conditions...
            HandleFailureConditions();

            -- Method for waves while Alpha Squad are scouting.
            if (Mission.m_WavesActive) then
                WaveBrain();
            end

            -- Run logic for the AIP Helper.
            AIPHelper();

            if (Mission.m_MissionPaused and Mission.m_Punishment) then
                PunishmentBrain();
            end

            -- Check to see if the player is too far from the Matriarch.
            if (Mission.m_PlayerDistanceChecker) then
                PlayerDistanceChecker();
            end

            -- Brain for Yelena.
            if (Mission.m_YelenaBrainActive) then
                YelenaBrain();
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
        -- Show Objectives.
        AddObjective("scion0304.otf", "WHITE");

        -- Stop her from doing anything.
        Stop(Mission.m_Yelena, 1);

        -- Activate Yelena's brain.
        Mission.m_YelenaBrainActive = true;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    -- This will check to see if the waves are completed, and dead.
    if (Mission.m_Wave2Spawned and (IsAliveAndEnemy(Mission.m_Wave_Unit_A, 7) == false and IsAliveAndEnemy(Mission.m_Wave_Unit_B, 7) == false)) then
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(8);

        -- Stop the player distance checker.
        Mission.m_PlayerDistanceChecker = false;

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

            -- Switch the AI Plan.
            SetAIP("scion0302_x.aip", Mission.m_EnemyTeam);

            -- Send the patrols back to their patrol paths.
            Patrol(Mission.m_Misl1, "misl1_patrol");
            Patrol(Mission.m_Misl2, "misl2_patrol");

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[13] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- SHAB - We've lost contact with Alpha Wing.  Luckily, we were able to get the coordinates
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0314.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Run a small delay here before Yelena gives us the coordinates.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(10);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- SHAB - I'm giving you the coordinates of the base. First, focus on destroying the base's defenses.  Then when you are able, move in with a Hauler and bring the power crystal back to your base.  Expect VERY heavy resistance, the ISDF will do whatever they can to keep us from the power crystal. Those two Scions died for this mission, Cooke.  If you fail, their deaths will be in vain.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0301.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(20.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[15] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        ClearObjectives();
        AddObjective("scion0301.otf", "WHITE");

        Mission.m_Nav1 = BuildObject("ibnav", Mission.m_HostTeam, "nav1");
        SetObjectiveName(Mission.m_Nav1, TranslateString("MissionS0301"));
        SetObjectiveOn(Mission.m_Nav1);

        SetObjectiveName(Mission.m_Power, TranslateString("MissionS0302"));
        SetObjectiveOn(Mission.m_Power);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[16] = function()
    -- This will check to see if the player has grabbed the Power Crystal.
    if (Mission.m_PlayerHasPower == false and GetTug(Mission.m_Power)) then
        -- Prevent looping.
        Mission.m_PlayerHasPower = true;

        -- SHAB - Good Cooke, you've got it.  Bring it back to base, hurry!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0302.wav");

        -- Timer for the audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Converge enemy Rocket Tanks on to the Hauler.
        if (IsAlive(Mission.m_Hauler)) then
            SendRocketTanksToTarget(Mission.m_Hauler);
        end
    elseif (Mission.m_PlayerHasPower) then
        -- Run a distance check to see if the power is near the player Recycler.
        if (Mission.m_MissionTime % SecondsToTurns(0.5) == 0 and GetDistance(Mission.m_Power, Mission.m_PlayersRecy) < 150) then
            -- Burns - All is going according to plan.  Thank you, John.  You're a worthy protege.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0304.wav");

            -- Timer for the audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[17] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- So we don't loop.
        Mission.m_MissionOver = true;

        -- Show success objective.
        AddObjectiveOverride("scion0303.otf", "WHITE", 10, true);

        -- Succeed.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(12);
        else
            SucceedMission(GetTime() + 12, "scion03w1.txt");
        end
    end
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
    elseif (IsAround(Mission.m_PlayersRecy) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Show failure objective.
        AddObjectiveOverride("scion0305.otf", "RED", 10, true);

        -- Mission failed.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0399.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The Matriarch was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "scion03L3.txt");
        end
    end
end

function WaveBrain()
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

function PunishmentBrain()
    if (Mission.m_PunishDelay < Mission.m_MissionTime) then
        -- Spawn in a bunch of units to attack the Matriarch to ensure this mission is over.
        for i = 1, 12 do
            local path = '';
            local handle = nil;

            -- Determine safer spawn points to use.
            if (i % 2 == 0) then
                -- Build our unit.
                handle = BuildObjectAtSafePath("ivtank_x", 7, "punish_2", "spawn_2", _Cooperative.m_TotalPlayerCount);
            else
                handle = BuildObjectAtSafePath("ivtank_x", 7, "punish_1", "spawn_1", _Cooperative.m_TotalPlayerCount);
            end

            -- Give it a weapon upgrade.
            GiveWeapon(handle, "gspstab_c");

            -- Send it to attack.
            Attack(handle, Mission.m_PlayersRecy, 1);
        end

        -- Add a delay so this isn't instant.
        Mission.m_PunishDelay = Mission.m_MissionTime + SecondsToTurns(40);
    end
end

function AIPHelper()
    -- Handle the tanks movement.
    if (Mission.m_TankMoveTimer < Mission.m_MissionTime) then
        -- Check that the tanks exist.
        if (Mission.m_Tank1Moved == false and IsAliveAndEnemy(Mission.m_ISDFTank1, Mission.m_EnemyTeam)) then
            -- Mark this as done so we don't loop.
            Mission.m_Tank1Moved = true;

            -- Move the unit to the right path.
            Goto(Mission.m_ISDFTank1, "scout1point");
        end

        if (Mission.m_Tank2Moved == false and IsAliveAndEnemy(Mission.m_ISDFTank2, Mission.m_EnemyTeam)) then
            -- Mark this as done so we don't loop.
            Mission.m_Tank2Moved = true;

            -- Move the unit to the right path.
            Goto(Mission.m_ISDFTank2, "scout2point");
        end

        if (Mission.m_Tank3Moved == false and IsAliveAndEnemy(Mission.m_ISDFTank3, Mission.m_EnemyTeam)) then
            -- Mark this as done so we don't loop.
            Mission.m_Tank3Moved = true;

            -- Move the unit to the right path.
            Goto(Mission.m_ISDFTank3, "scout3point");
        end
    end
end

function YelenaBrain()
    -- This will run every 5 seconds to see if Yelena is doing something. If she's not, we will move her to a random position in the base.
    if (Mission.m_MissionTime % SecondsToTurns(10) == 0 and GetCurrentCommand(Mission.m_Yelena) == AiCommand.CMD_NONE) then
        -- Pick a random position near her path.
        local pathPos = GetPosition("YelenaRadius");
        local chosenPos = GetPositionNear(pathPos, 5, 60);

        -- Send Yelena to the position.
        Goto(Mission.m_Yelena, chosenPos, 1);
    end
end

function PlayerDistanceChecker()
    -- Check to see how many players are active and then do a distance check every .5 of a second.
    if (Mission.m_MissionTime % SecondsToTurns(0.5) == 0) then
        for i = 1, _Cooperative.m_TotalPlayerCount do
            local handle = GetPlayerHandle(i);

            -- Check to see if this player is the "Faulting Player". If so, check if they have returned.
            if (Mission.m_MissionPaused and handle == Mission.m_BadPlayer) then
                -- Check Distance to see if they have returned to base.
                if (GetDistance(handle, Mission.m_PlayersRecy) < 500) then
                    -- Clear the faulting player handle.
                    Mission.m_BadPlayer = nil;

                    -- Returned to base as per instructions. Unpause the mission, restart the sequence that was interrupted.
                    Mission.m_MissionPaused = false;
                end
            end

            if (GetDistance(handle, Mission.m_PlayersRecy) >= 500) then
                -- This will pause the missions.
                Mission.m_MissionPaused = true;

                -- Mark the player as the "Faulting" Player.
                Mission.m_BadPlayer = handle;

                if (Mission.m_PlayerDistanceCheckerDelay < Mission.m_MissionTime) then
                    -- Stop any preceeding messages from playing.
                    StopAudioMessage(Mission.m_Audioclip);

                    -- Remove the timer.
                    Mission.m_AudioTimer = 0;

                    -- Check how many warnings have passed.
                    if (Mission.m_PlayerDistanceWarningCount == 0) then
                        -- Add a timer so this isn't instant per cycler.
                        Mission.m_PlayerDistanceCheckerDelay = Mission.m_MissionTime + SecondsToTurns(20);

                        -- Yelena - Cooke, where are you going?  You must stay at the base, I can't defend it by myself.
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0315.wav");

                        -- Set the timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);
                    elseif (Mission.m_PlayerDistanceWarningCount == 1) then
                        -- Add a timer so this isn't instant per cycler.
                        Mission.m_PlayerDistanceCheckerDelay = Mission.m_MissionTime + SecondsToTurns(25);

                        -- Yelena - John, you must get back to the base now, or this mission is scrubbed.
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0316.wav");

                        -- Set the timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
                    else
                        -- Player has gone too far and must be punished.
                        Mission.m_Punishment = true;

                        -- Start punishment process for ISDF to destroy the Matriarch.
                        SendRocketTanksToTarget(Mission.m_PlayersRecy);

                        -- Disable this so it stops.
                        Mission.m_PlayerDistanceChecker = false;
                    end

                    -- Add delay again.
                    Mission.m_PlayerDistanceWarningCount = Mission.m_PlayerDistanceWarningCount + 1;
                end
            end
        end
    end
end

function SendRocketTanksToTarget(targetHandle)
    if (IsAliveAndEnemy(Mission.m_Rocket1, Mission.m_EnemyTeam)) then
        Attack(Mission.m_Rocket1, targetHandle);
    end

    if (IsAliveAndEnemy(Mission.m_Rocket2, Mission.m_EnemyTeam)) then
        Attack(Mission.m_Rocket2, targetHandle);
    end

    if (IsAliveAndEnemy(Mission.m_Rocket3, Mission.m_EnemyTeam)) then
        Attack(Mission.m_Rocket3, targetHandle);
    end

    if (IsAliveAndEnemy(Mission.m_Rocket4, Mission.m_EnemyTeam)) then
        Attack(Mission.m_Rocket4, targetHandle);
    end

    if (IsAliveAndEnemy(Mission.m_Rocket5, Mission.m_EnemyTeam)) then
        Attack(Mission.m_Rocket5, targetHandle);
    end

    if (IsAliveAndEnemy(Mission.m_Rocket6, Mission.m_EnemyTeam)) then
        Attack(Mission.m_Rocket6, targetHandle);
    end

    if (IsAliveAndEnemy(Mission.m_Rocket7, Mission.m_EnemyTeam)) then
        Attack(Mission.m_Rocket7, targetHandle);
    end
end