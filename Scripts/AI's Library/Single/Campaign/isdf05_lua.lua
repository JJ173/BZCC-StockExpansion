--[[
    BZCC ISDF05 Lua Mission Script
    Written by AI_Unit
    Version 2.0 24-01-2024
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
local m_MissionName = "ISDF05: The Dark Planet";

-- Difficulty tables for times and spawns.
local m_ConstructorBuildDelay = { 15, 20, 30 };
local m_ScionPlayerAttacker = { "fvscout_x", "fvsent_x", "fvtank_x" };
local m_ScionFirstPoolGuard = { "fvsent_x", "fvtank_x", "fvarch_x" };
local m_ScionFirstLurker = { "fvscout_x", "fvsent_x", "fvtank_x" };
local m_ScionSecondLurker = { "fvsent_x", "fvtank_x", "fvarch_x" };

-- Mission important variables.
local Mission =
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "ispilo_sx",
    -- Specific to mission.
    m_PlayerShipODF = "ivtank_x",

    m_Recycler = nil,
    m_Scavenger = nil,
    m_Scavenger2 = nil,
    m_Scavenger3 = nil,
    m_Constructor = nil,
    m_Power1 = nil,
    m_Power2 = nil,
    m_Factory = nil,
    m_Bunker = nil,
    m_GunTower = nil,
    m_GunTower2 = nil,
    m_Shabayev = nil,
    m_ShabayevPilot = nil,
    m_Dropship = nil,
    m_Manson = nil,
    m_Blue1 = nil,
    m_Blue2 = nil,
    m_Teleportal = nil,
    m_Enemy1 = nil,
    m_Enemy2 = nil,
    m_Enemy3 = nil,
    m_Enemy4 = nil,
    m_Nav1 = nil,
    m_Nav2 = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_SentRecycler = false,
    m_SentScavenger = false,
    m_DropshipTakeoff = false,
    m_RevokeConstructor = false,
    m_ScionBrainActive = false,
    m_BaseBrainActive = false,

    m_PlayFirstCutscene = false,
    m_ConstructorBuildOrderGiven = false,
    m_ConstructorDropoffGiven = false,
    m_HandleTurretWarning = false,
    m_MansonWaiting = true,
    m_MansonGunTowerMessage = false,
    m_SpawnedFirstLurker = false,
    m_SpawnedSecondLurker = false,
    m_MansonRetreating = false,
    m_PlayCanopyMessage = false,
    m_ShabAttacking = false,

    m_FirstCutsceneTime = 0,
    m_ConstructorCommandDelay = 0,
    m_ScionAttackDelay = 0,
    m_MortarBikeTime = 0,
    m_ConstructorMovieTime = 0,
    m_MansonDelayTime = 0,
    m_MansonNagTime = 0,
    m_MissionGunTowerTimer = 0,
    m_DeployedScavCounter = 0,
    m_RevokeConstructorTimer = 0,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    -- Steps for each section.

    m_MissionStartStage = 0,
    m_MissionConstructionStage = 0,
    m_MissionScionAttackStage = 0,
    m_MissionScavengerStage = 0,
    m_MissionMansonStage = 0,

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
    -- Grab the ODF name.
    local team = GetTeamNum(h);

    -- Grab the class of the handle.
    local class = GetClassLabel(h);

    -- Handle unit skill for enemy.
    if (team == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);
    elseif (team < Mission.m_AlliedTeam and team > 0) then
        -- Always max out player units.
        SetSkill(h, 3);

        if (class == "CLASS_CONSTRUCTIONRIG") then
            -- A bit of time between buildings.
            Mission.m_ConstructorCommandDelay = Mission.m_MissionTime + SecondsToTurns(8);

            -- Incase it dies.
            Mission.m_RevokeConstructor = false;

            -- Wait for the AIP to return it.
            Mission.m_RevokeConstructorTimer = Mission.m_MissionTime + SecondsToTurns(1);

            -- Assign it.
            Mission.m_Constructor = h;
        elseif (class == "CLASS_TURRET") then
            -- Make sure we keep track of each Gun Tower.
            if (not IsAround(Mission.m_GunTower)) then
                Mission.m_GunTower = h;
            elseif (not IsAround(Mission.m_GunTower2)) then
                Mission.m_GunTower2 = h;
            end

            -- A bit of time between buildings.
            Mission.m_ConstructorCommandDelay = Mission.m_MissionTime +
                SecondsToTurns(m_ConstructorBuildDelay[Mission.m_MissionDifficulty]);

            Mission.m_ConstructorBuildOrderGiven = false;
            Mission.m_ConstructorDropoffGiven = false;
        elseif (class == "CLASS_PLANT") then
            if (not IsAround(Mission.m_Power1)) then
                Mission.m_Power1 = h;
            else
                Mission.m_Power2 = h;
            end

            -- A bit of time between buildings.
            Mission.m_ConstructorCommandDelay = Mission.m_MissionTime +
                SecondsToTurns(m_ConstructorBuildDelay[Mission.m_MissionDifficulty]);
            Mission.m_ConstructorBuildOrderGiven = false;
            Mission.m_ConstructorDropoffGiven = false;
        elseif (class == "CLASS_COMMBUNKER") then
            Mission.m_Bunker = h;

            -- A bit of time between buildings.
            Mission.m_ConstructorCommandDelay = Mission.m_MissionTime +
                SecondsToTurns(m_ConstructorBuildDelay[Mission.m_MissionDifficulty]);
            Mission.m_ConstructorBuildOrderGiven = false;
            Mission.m_ConstructorDropoffGiven = false;
        elseif (class == "CLASS_EXTRACTOR") then
            Mission.m_DeployedScavCounter = Mission.m_DeployedScavCounter + 1;
        end
    end

    -- Check to see if the Satchel has been placed.
    if (Mission.m_MissionState >= 16 and class == "CLASS_SATCHELCHARGE" and not Mission.m_MansonRetreating) then
        -- Change the team so it can die.
        SetTeamNum(Mission.m_Teleportal, Mission.m_EnemyTeam);

        -- Max health of the teleportal.
        SetMaxHealth(Mission.m_Teleportal, 1500);
        SetCurHealth(Mission.m_Teleportal, 1500);

        -- Retreat!
        SetIndependence(Mission.m_Manson, 0);
        SetIndependence(Mission.m_Blue1, 0);
        SetIndependence(Mission.m_Blue2, 0);

        -- Go to the previous path.
        Retreat(Mission.m_Manson, "manson_path1", 1);
        Retreat(Mission.m_Blue1, "manson_path1", 1);
        Retreat(Mission.m_Blue2, "manson_path1", 1);

        -- Play our audio.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0542.wav");

        -- So we don't loop.
        Mission.m_MansonRetreating = true;
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
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            if (Mission.m_BaseBrainActive) then
                BaseBrain();
            end

            if (Mission.m_ScionBrainActive) then
                ScionBrain();
            end

            -- For failures.
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
    if (IsPlayer(ShooterHandle) and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (IsAlive(Mission.m_Shabayev) and VictimHandle == Mission.m_Shabayev) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("ff01.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        end

        if (IsAlive(Mission.m_Manson) and VictimHandle == Mission.m_Manson) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0555.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Allied team is Squad Blue.
    SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);

    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- There are some neutral Scavengers near the teleport.
    Mission.m_Scavenger2 = GetHandle("ivscav1");
    Mission.m_Scavenger3 = GetHandle("ivscav2");

    -- Stop them from collecting any loose.
    KillPilot(Mission.m_Scavenger2);
    KillPilot(Mission.m_Scavenger3);

    -- Grab the "Excavator"
    Mission.m_Teleportal = GetHandle("unnamed_ibtele");

    -- Set it's name.
    SetObjectiveName(Mission.m_Teleportal, TranslateString("Mission0503"));

    -- Create Shabayev.
    Mission.m_Shabayev = BuildObject("ivtank_x", Mission.m_HostTeam, "shab_start");

    -- Give Shab her name.
    SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");

    -- Do not allow control of Shabayev.
    Stop(Mission.m_Shabayev, 1);

    -- Highlight Shabayev.
    SetObjectiveOn(Mission.m_Shabayev);

    -- Give her the correct pilot.
    SetPilotClass(Mission.m_Shabayev, "isshab_p");

    -- Make sure she has good skill.
    SetSkill(Mission.m_Shabayev, 3);

    -- Give Shabayev Infinifte Health
    SetMaxHealth(Mission.m_Shabayev, 0);

    -- Create Recycler.
    Mission.m_Recycler = BuildObject("ivrec5_fix", Mission.m_HostTeam, "recy_start");

    -- Do not allow control of the Recycler.
    Stop(Mission.m_Recycler, 1);

    -- Create first Scavenger.
    Mission.m_Scavenger = GetHandle("scav3");

    -- Send it to the first pool.
    Goto(Mission.m_Scavenger, GetHandle("poolx"), 1);

    -- Get the Dropship.
    Mission.m_Dropship = GetHandle("unnamed_ivpdrop_x");

    -- Make it immortal.
    SetMaxHealth(Mission.m_Dropship, 0);

    -- Build Manson and his squad.
    Mission.m_Manson = BuildObject("ivtank_x", Mission.m_AlliedTeam, "manson_start");
    Mission.m_Blue1 = BuildObject("ivtank_x", Mission.m_AlliedTeam, "manson_escort1");
    Mission.m_Blue2 = BuildObject("ivtank_x", Mission.m_AlliedTeam, "manson_escort2");

    -- Name them.
    SetObjectiveName(Mission.m_Manson, "Maj. Manson");
    SetObjectiveName(Mission.m_Blue1, "Sgt. Zdarko");
    SetObjectiveName(Mission.m_Blue2, "Sgt. Masiker");

    -- Give Blue Team max health.
    SetMaxHealth(Mission.m_Manson, 0);
    SetMaxHealth(Mission.m_Blue1, 0);
    SetMaxHealth(Mission.m_Blue2, 0);

    -- Give the player some scrap.
    SetScrap(Mission.m_HostTeam, 40);

    -- Prepare Recycler for Deployment.
    Deploy(Mission.m_Recycler);

    -- Have Shabayev follow it.
    Defend2(Mission.m_Shabayev, Mission.m_Recycler, 1);

    -- Have the Dropship leave.
    SetAnimation(Mission.m_Dropship, "takeoff", 1);

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Manson: "You're a few hundred meters off target..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0500.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(15.5);

        -- Send the Recycler off to Deploy.
        Dropoff(Mission.m_Recycler, "recy_deploy", 1);

        -- Dropship sound.
        StartSoundEffect("dropleav.wav", Mission.m_Dropship);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "Copy Major, Cooke take my wing...";
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0501.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Remove the Dropship.
        RemoveObject(Mission.m_Dropship);

        -- Get Shabayev to Patrol when she tells Cooke to follow.
        Patrol(Mission.m_Shabayev, "patrol1", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    if (GetDistance(Mission.m_Recycler, "recy_deploy") < 25) then
        -- Show objective.
        AddObjectiveOverride("isdf0501.otf", WHITE, 10, true);

        -- If we are a coop game, don't run the cutscene.
        if (Mission.m_IsCooperativeMode) then
            -- Advance to check the Recycler is deployed.
            Mission.m_MissionState = 6;
        else
            -- Get the Camera ready for the cutscene.
            CameraReady();

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[5] = function()
    -- Play the movie.
    Mission.m_PlayFirstCutscene = PlayMovie("isdf0501.cin");

    if (not Mission.m_PlayFirstCutscene) then
        -- Start the cutscene.
        CameraFinish();

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    if (IsBuilding(Mission.m_Recycler)) then
        -- Set an AIP here for team 1 to build the constructor.
        SetAIP("isdf0501_x.aip", Mission.m_HostTeam);

        -- Send a couple of enemies to attack.
        Mission.m_Enemy1 = BuildObjectAtSafePath("fvsent_x", Mission.m_EnemyTeam, "raid1", "raid3",
            _Cooperative.GetTotalPlayers());
        Mission.m_Enemy2 = BuildObjectAtSafePath("fvscout_x", Mission.m_EnemyTeam, "raid2", "raid4",
            _Cooperative.GetTotalPlayers());
        Mission.m_Enemy3 = BuildObjectAtSafePath("fvscout_x", Mission.m_EnemyTeam, "raid3", "raid1",
            _Cooperative.GetTotalPlayers());

        -- Send enemies to attack.
        Goto(Mission.m_Enemy1, "recy_deploy", 1);
        Goto(Mission.m_Enemy2, "recy_deploy", 1);
        Goto(Mission.m_Enemy3, "recy_deploy", 1);

        -- Start the base building and Scion attack steps.
        Mission.m_BaseBrainActive = true;
        Mission.m_ScionBrainActive = true;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (IsAround(Mission.m_GunTower2)) then
        -- Stop the attacks.
        Mission.m_ScionBrainActive = false;

        -- Tell player about the pool.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0507.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Allow the canopy message to be played.
        Mission.m_PlayCanopyMessage = true;

        -- Check the amount of scavs that are on the map already.
        if (Mission.m_DeployedScavCounter < 2) then
            Mission.m_Nav1 = BuildObject("ibnav", 1, "scrap_field1");
        else
            Mission.m_Nav2 = BuildObject("ibnav", 1, "scrap_field3");
        end

        -- Change the objective name.
        SetObjectiveName(Mission.m_Nav1, TranslateString("Mission0501"));

        -- Highlight the nav.
        SetObjectiveOn(Mission.m_Nav1);

        -- Remove beacon from Shab.
        SetObjectiveOff(Mission.m_Shabayev);

        -- Send some spice attack.
        Attack(
            BuildObjectAtSafePath(m_ScionPlayerAttacker[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "spawn1",
                "raid3",
                _Cooperative.GetTotalPlayers()), GetPlayerHandle(1), 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (Mission.m_PlayCanopyMessage) then
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            -- Run a check to have Shab say she can't see and is returning to base.
            if (CountUnitsNearObject(pool1, 75, 1, nil)) then
                -- Shab: "I can't see..."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0508.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

                -- Let's send a Sentry to the Scrap Pool that has been marked.
                Goto(
                    BuildObjectAtSafePath(m_ScionFirstPoolGuard[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
                        "lurker1",
                        "lurker2", _Cooperative.GetTotalPlayers()), "scrap_field1", 1);

                -- Don't loop.
                Mission.m_PlayCanopyMessage = false;
            end
        end
    end

    if (Mission.m_DeployedScavCounter >= 2) then
        if (IsAround(Mission.m_Nav1)) then
            -- Remove the highlight from first nav.
            SetObjectiveOff(Mission.m_Nav1);

            -- Second pool objective.
            AddObjectiveOverride("isdf0508.otf", "WHITE", 10, true);

            -- Shab: "Good work..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0509.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- Build a nav.
            Mission.m_Nav2 = BuildObject("ibnav", 1, "scrap_field3");

            -- Change the objective name.
            SetObjectiveName(Mission.m_Nav2, TranslateString("Mission0502"));

            -- Highlight the nav.
            SetObjectiveOn(Mission.m_Nav2);
        end

        -- Build the enemy.
        BuildObject(m_ScionFirstLurker[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "lurker1");
        BuildObject(m_ScionSecondLurker[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "lurker2");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    local checker = nil;
    local sturretCount = 6;
    local dist = 175;

    -- Check if any turrets are alive before doing this portion.
    for m = 1, sturretCount do
        local handle = GetHandle("sturret" .. m);

        if (IsAlive(handle)) then
            -- Store this to use for later.
            checker = handle;

            -- So we don't run the rest of the code.
            break;
        end
    end

    -- No turrets found, have Shab build the Factory without waiting.
    if (not IsAlive(checker)) then
        -- Use path is no turrets are found.
        checker = "scrap_field3"

        -- Increase the distance so we don't get too close.
        dist = dist + 75;
    end

    -- Run a check to see if this enemy is any of the players.
    if (IsPlayerWithinDistance(checker, dist, _Cooperative.GetTotalPlayers())) then
        if (checker ~= "scrap_field3") then
            -- Make sure we play the warning audio.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0512.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);
        end

        -- Set the Mortar Bike delay time.
        Mission.m_MortarBikeTime = Mission.m_MissionTime + SecondsToTurns(15);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[10] = function()
    if (Mission.m_MortarBikeTime < Mission.m_MissionTime and GetScrap(Mission.m_HostTeam) > 55) then
        -- Shab: Cooke, I'm building a factory...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0527.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Get the camera ready.
        if (not Mission.m_IsCooperativeMode) then
            CameraReady();
        end

        -- Set the Constructor movie timer.
        Mission.m_ConstructorMovieTime = Mission.m_MissionTime + SecondsToTurns(1.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    -- Set the constructor to do what it needs to do.
    Mission.m_MissionConstructionStage = 2;

    -- Follow the Constructor.
    if (not Mission.m_IsCooperativeMode) then
        CameraObject(Mission.m_Constructor, 1, 15, 25, Mission.m_Constructor);
    end

    -- Make sure Shab has finished talking and we've exceeded our timer.
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and Mission.m_ConstructorMovieTime < Mission.m_MissionTime) then
        -- Give command back to the player.
        if (not Mission.m_IsCooperativeMode) then
            CameraFinish();
        end

        -- Add Objective.
        AddObjectiveOverride("isdf0516.otf", WHITE, 10, true);

        -- Send Shabayev back to Patrol.
        if (IsAlive(Mission.m_Shabayev)) then
            Patrol(Mission.m_Shabayev, "patrol1", 1);
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    -- This is where we should check to see if the turrets are dead.
    if (Mission.m_DeployedScavCounter == 3) then
        -- Manson: "You're showing a lot of promise..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0514.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- New Objective.
        AddObjectiveOverride("isdf0512.otf", "WHITE", 10, true);

        -- Get them following in formation.
        Follow(Mission.m_Blue1, Mission.m_Manson, 1);
        Follow(Mission.m_Blue2, Mission.m_Blue1, 1);

        -- Delay 5 seconds before ordering player to follow.
        Mission.m_MansonDelayTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and Mission.m_MansonDelayTime < Mission.m_MissionTime) then
        -- Remove the beacon from this Nav.
        SetObjectiveOff(Mission.m_Nav2);

        -- Set Manson's beacon as active.
        SetObjectiveOn(Mission.m_Manson);

        -- New Objective.
        AddObjectiveOverride("isdf0518.otf", "WHITE", 10, true);

        -- Manson: "Follow me, Cooke".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0515.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Set a nag timer just incase the player takes too long.
        Mission.m_MansonNagTime = Mission.m_MissionTime + SecondsToTurns(45);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    -- Nag if we're taking too long.
    if (Mission.m_MansonNagTime < Mission.m_MissionTime) then
        -- Manson: "Hurry up Cooke...";
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0528.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Reset the nag timer.
        Mission.m_MansonNagTime = Mission.m_MissionTime + SecondsToTurns(45);
    end

    -- If player is within distance of Manson, advance.
    if (IsPlayerWithinDistance(Mission.m_Manson, 50, _Cooperative.GetTotalPlayers())) then
        -- Manson: "Intelligence has discovered a structure..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0539a.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- AI has no control here >:)
        SetIndependence(Mission.m_Manson, 0);
        SetAvoidType(Mission.m_Manson, 0);

        SetIndependence(Mission.m_Blue1, 0);
        SetAvoidType(Mission.m_Blue1, 0);

        SetIndependence(Mission.m_Blue2, 0);
        SetAvoidType(Mission.m_Blue2, 0);

        -- Objectives.
        AddObjectiveOverride("isdf0513.otf", "WHITE", 10, true);

        -- Send Manson on his way.
        Goto(Mission.m_Manson, "manson_path1");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[15] = function()
    -- Do a check to see if the player is too far from Manson before powering to the next path.
    if (Mission.m_MansonWaiting and IsPlayerWithinDistance(Mission.m_Manson, 100, _Cooperative.GetTotalPlayers()) and GetDistance(Mission.m_Manson, "manson_path1", 23) < 100) then
        -- Send Manson on his way to the next path.
        Goto(Mission.m_Manson, "manson_path2");

        -- So we don't loop.
        Mission.m_MansonWaiting = false;
    end

    -- Run a check here and advance to the next state when Manson plays his message about the Spires.
    if (not Mission.m_MansonGunTowerMessage and GetDistance(Mission.m_Manson, "guntower1") < 200) then
        -- Manson: "There are a lot more of these puppies ahead"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0516.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Objectives.
        AddObjectiveOverride("isdf0514.otf", "WHITE", 10, true);

        -- So we don't loop.
        Mission.m_MansonGunTowerMessage = true;
    end

    -- Carry on with the rest of the logic once this has been done.
    if (Mission.m_MansonGunTowerMessage) then
        -- Increment a timer for Manson's message.
        Mission.m_MissionGunTowerTimer = Mission.m_MissionGunTowerTimer + 1;

        -- Couple of audio clips for his nagging.
        if (Mission.m_MissionGunTowerTimer == SecondsToTurns(30)) then
            -- Nag for the first time.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0528.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        elseif (Mission.m_MissionGunTowerTimer > SecondsToTurns(45)) then
            -- Nag for the last time, player took too long.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0529.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        end

        -- Run some logic here to check that the player is near the teleport.
        if (IsPlayerWithinDistance(Mission.m_Teleportal, 100, _Cooperative.GetTotalPlayers())) then
            -- "This looks like one of ours..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0173.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[16] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Get Manson to yell at you.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0517.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(15.5);

        -- Turn his beacon off.
        SetObjectiveOff(Mission.m_Manson);

        -- Set the AI up so they can do things again.
        SetIndependence(Mission.m_Manson, 1);
        SetIndependence(Mission.m_Blue1, 1);
        SetIndependence(Mission.m_Blue2, 1);

        -- Activate teleporter beacon.
        SetObjectiveOn(Mission.m_Teleportal);

        -- Objectives.
        AddObjectiveOverride("isdf0515.otf", "WHITE", 10, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[17] = function()
    -- Do a check to make sure the teleportal is dead from the blast of the Satchel.
    if (not IsAround(Mission.m_Teleportal)) then
        -- Manson: "Great balls of fire Cooke!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0518.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Complete the game and move on so we don't loop.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(10);
        else
            SucceedMission(GetTime() + 10, "isdf05w1.txt");
        end

        -- Halt the mission.
        Mission.m_MissionOver = true;
    end
end

function HandleFailureConditions()
    -- Recycler is dead, mission failed.
    if (not IsAround(Mission.m_Recycler) and not Mission.m_MissionOver) then
        -- Objectives.
        AddObjectiveOverride("isdf0523.otf", "RED", 10, true);

        -- Mission failed.
        Mission.m_MissionOver = true;

        -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("You lost the Recycler!");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf04l2.txt");
        end
    end
end

function BaseBrain()
    -- Shouldn't need to worry about stages for this as she should attack right away.
    if (GetDistance(Mission.m_Enemy1, Mission.m_Recycler) < 300 and not Mission.m_ShabAttacking) then
        -- Send Shab to attack.
        Attack(Mission.m_Shabayev, Mission.m_Enemy1, 1);

        -- So we don't spam this order.
        Mission.m_ShabAttacking = true;
    end

    -- Make sure the player can't control the constructor.
    if (Mission.m_RevokeConstructorTimer < Mission.m_MissionTime and IsAround(Mission.m_Constructor) and Mission.m_RevokeConstructor == false) then
        -- Stop the constructor.
        Stop(Mission.m_Constructor, 1);

        -- So we don't loolp.
        Mission.m_RevokeConstructor = true;
    end

    if (Mission.m_MissionConstructionStage == 0) then
        -- Proceed to build the base once both enemies are dead.
        if (IsAliveAndEnemy(Mission.m_Enemy1, Mission.m_EnemyTeam) == false and IsAliveAndEnemy(Mission.m_Enemy2, Mission.m_EnemyTeam) == false and IsAliveAndEnemy(Mission.m_Enemy3, Mission.m_EnemyTeam) == false) then
            -- Shab: "Cooke, defend the perimeter..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0543.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Show objective.
            AddObjectiveOverride("isdf0517.otf", WHITE, 10, true);

            -- Have Shab defend the Constructor.
            Defend2(Mission.m_Shabayev, Mission.m_Constructor, 1);

            -- Give the constructor a bit of a delay.
            Mission.m_ConstructorCommandDelay = Mission.m_MissionTime + SecondsToTurns(8);

            -- Advance the mission step.
            Mission.m_MissionConstructionStage = Mission.m_MissionConstructionStage + 1;
        end
    elseif (Mission.m_MissionConstructionStage == 1) then
        if (Mission.m_ConstructorCommandDelay < Mission.m_MissionTime) then
            if (not IsAlive(Mission.m_Power1) and GetScrap(Mission.m_HostTeam) >= 30) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibpgen_x", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "pgen1", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorDropoffGiven = true;
                end
            elseif (IsAlive(Mission.m_Power1) and not IsAlive(Mission.m_Power2) and GetScrap(Mission.m_HostTeam) >= 30) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibpgen_x", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "pgen2", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorDropoffGiven = true;
                end
            elseif (IsAlive(Mission.m_Power2) and not IsAlive(Mission.m_Bunker) and GetScrap(Mission.m_HostTeam) >= 50) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibcbun_x", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "rbunker1", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorDropoffGiven = true;
                end
            elseif (IsAlive(Mission.m_Bunker) and not IsAlive(Mission.m_GunTower) and GetScrap(Mission.m_HostTeam) >= 50) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibgtow_x", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "gtow1", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorDropoffGiven = true;
                end
            elseif (IsAlive(Mission.m_GunTower) and not IsAlive(Mission.m_GunTower2) and GetScrap(Mission.m_HostTeam) >= 50) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibgtow_x", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "gtow2", 1);
                    -- So we don't loop.
                    Mission.m_ConstructorDropoffGiven = true;
                end
            end
        end
    elseif (Mission.m_MissionConstructionStage == 2) then
        if (not IsAlive(Mission.m_Factory)) then
            if (not Mission.m_ConstructorBuildOrderGiven) then
                -- Give orders to construct the first Power.
                Build(Mission.m_Constructor, "ibfact5", 1);
                -- So we don't loop.
                Mission.m_ConstructorBuildOrderGiven = true;
            elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                -- Do the dropoff
                Dropoff(Mission.m_Constructor, "fact", 1);
                -- So we don't loop.
                Mission.m_ConstructorDropoffGiven = true;
                -- Deactivate the Constructor.
                Mission.m_BaseBrainActive = false;
            end
        end
    end
end

function ScionBrain()
    if (Mission.m_ScionAttackDelay < Mission.m_MissionTime) then
        -- Check to see if the first power plant is alive.
        if (IsAround(Mission.m_Power1)) then
            local check1 = IsAliveAndEnemy(Mission.m_Enemy1, Mission.m_EnemyTeam);
            local check2 = IsAliveAndEnemy(Mission.m_Enemy1, Mission.m_EnemyTeam);
            local check3 = IsAliveAndEnemy(Mission.m_Enemy1, Mission.m_EnemyTeam);
            local check4 = IsAliveAndEnemy(Mission.m_Enemy1, Mission.m_EnemyTeam);

            if (check1 == false and check2 == false and check3 == false and check4 == false) then
                -- Make sure to spawn each unit.
                Mission.m_Enemy1 = BuildObjectAtSafePath("fvsent_x", Mission.m_EnemyTeam, "raid1", "raid3",
                    _Cooperative.GetTotalPlayers());
                Mission.m_Enemy2 = BuildObjectAtSafePath("fvtank_x", Mission.m_EnemyTeam, "raid2", "raid4",
                    _Cooperative.GetTotalPlayers());

                -- Send the enemies to the perimeter.
                Goto(Mission.m_Enemy1, "recy_deploy", 1);
                Goto(Mission.m_Enemy2, "recy_deploy", 1);

                if (Mission.m_MissionDifficulty > 1) then
                    Mission.m_Enemy3 = BuildObjectAtSafePath("fvarch_x", Mission.m_EnemyTeam, "raid3", "raid4",
                        _Cooperative.GetTotalPlayers());

                    Goto(Mission.m_Enemy3, "recy_deploy", 1);

                    if (Mission.m_MissionDifficulty > 2) then
                        Mission.m_Enemy4 = BuildObjectAtSafePath("fvtank_x", Mission.m_EnemyTeam, "raid4", "raid1",
                            _Cooperative.GetTotalPlayers());

                        Goto(Mission.m_Enemy4, "recy_deploy", 1);
                    end
                end

                -- Update the timer.
                Mission.m_ScionAttackDelay = Mission.m_MissionTime + SecondsToTurns(45);
            end
        end
    end
end
