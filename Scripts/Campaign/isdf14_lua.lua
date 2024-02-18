--[[
    BZCC ISDF14 Lua Mission Script
    Written by AI_Unit
    Version 2.0 02-02-2024
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
local m_MissionName = "ISDF14: Fanning the Fire";

local m_ShieldChance = 0.2;
local m_WeaponChance = 0.25;

local m_WeaponTable = {
    -- Table for Cannons (1)
    m_Cannons = { "gquill_c", "gsonic_c", "garc_c" },

    -- Table for Guns (2)
    m_Guns = { "lockdown_c", "ggauss_c", },

    -- Table for Missiles (3)
    m_Missiles = { "gmlock_c" },

    -- Table for Sheilds (4)
    m_Shields = { "gabsorb", "gdeflect", "gshield" }
}

local m_CrashSiteWarningDifficultyTime = { 330, 280, 230 };
local m_HaulerCooldownTime = { 60, 45, 30 };

local m_CrashInvUnit1 = { "fvscout_r", "fvsent_r", "fvtank_r" };
local m_CrashInvUnit2 = { "fvsent_r", "fvtank_r", "fvarch_r" };

-- Mission important variables.
local Mission =
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "ispilo_x",
    -- Specific to mission.
    m_PlayerShipODF = "ivtank_x",

    m_Holders = {},
    m_PlayerVehicles = {},

    m_Recycler = nil,
    m_Factory = nil,
    m_Armory = nil,
    m_Burns = nil,
    m_BurnsShip = nil,
    m_Condor1 = nil,
    m_Condor2 = nil,
    m_Condor3 = nil,
    m_Nav1 = nil,
    m_Tank = nil,
    m_Scout = nil,
    m_Hauler = nil,
    m_Cave = nil,
    m_Road = nil,
    m_InvUnit1 = nil,
    m_InvUnit2 = nil,
    m_SRecycler = nil,
    m_Yelena = nil,
    m_Tugger = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_DropshipBrainActive = false,
    m_BurnsBrainActive = false,
    m_PlayerClear = false,
    m_Condor1Away = false,
    m_Condor2Away = false,
    m_Condor3Away = false,
    m_Condor1Removed = false,
    m_Condor2Removed = false,
    m_Condor3Removed = false,
    m_NearCrash = false,
    m_BurnsCommentPlayed = false,
    m_FireyDeath = false,
    m_UnitsSent = false,
    m_HaulerSent = false,
    m_DecisionMade = false,

    m_ShabStartMovie = false,
    m_ShabToCave = false,
    m_ShabRaiseRoad = false,
    m_ShabRaiseCave = false,
    m_ShabAtCave = false,
    m_ShabGoToCave = false,

    m_HaulerFound = false,
    m_HaulerMove = false,
    m_HaulerPickup = false,
    m_HaulerRetreat = false,

    m_BurnsRecovered = false,
    m_BurnsFree = false,
    m_ScionHasBurns = false,
    m_PlayerHasBurns = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_Condor1Time = 0,
    m_Condor2Time = 0,
    m_Condor3Time = 0,
    m_CondorRemoveTime = 15,
    m_CrashSiteWarningTime = 0,
    m_CrashSiteWarningCount = 0,
    m_LavaCheckTimer = 0,
    m_HaulerCooldownTimer = 0,
    m_HaulerCheckTimer = 0,
    m_HaulerMoveTimer = 0,
    m_MeetingMessageCounter = 0,
    m_RoadTime = 0,

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

    -- Handle unit skill for enemy.
    if (team == Mission.m_EnemyTeam) then
        -- Grab the ODF.
        local odf = GetCfg(h);

        -- Set skill based on difficulty.
        SetSkill(h, Mission.m_MissionDifficulty);

        -- Check to see if the unit needs a weapon upgrade.
        if (Mission.m_StartDone) then
            if (odf == "fvtank_r" or odf == "fvarch_r" or odf == "fvsent_r" or odf == "fvscout_r") then
                -- Run a random chance to see if they are allowed a weapon.
                local chance = GetRandomFloat(0, 1);
                local shieldChance = m_ShieldChance * Mission.m_MissionDifficulty;
                local weaponChance = m_WeaponChance * Mission.m_MissionDifficulty;

                -- Run some checks to see if they pass.
                if (chance > shieldChance) then
                    -- Give it to the unit.
                    GiveWeapon(h, m_WeaponTable.m_Shields[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Shields))]);
                end

                if (chance > weaponChance) then
                    if (odf == "fvtank_r" or odf == "fvscout_r") then
                        GiveWeapon(h, m_WeaponTable.m_Cannons[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Cannons))]);
                    elseif (odf == "fvsent_r") then
                        GiveWeapon(h, m_WeaponTable.m_Guns[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Guns))]);
                    elseif (odf == "fvarch_r") then
                        GiveWeapon(h, m_WeaponTable.m_Missiles[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Missiles))]);
                    end
                end
            elseif (odf == "fvtug_r") then
                Mission.m_Hauler = h;

                -- Reset these when a new Hauler is added to the world.
                Mission.m_HaulerPickup = false;
                Mission.m_HaulerRetreat = false;
                Mission.m_HaulerMove = false;

                -- This will delay telling the Hauler to move to the individual Hauler drop-off.
                Mission.m_HaulerMoveTimer = Mission.m_MissionTime + SecondsToTurns(1.5);
            end
        end
    elseif (team > 0 and team < Mission.m_EnemyTeam) then
        -- Always max our player units.
        SetSkill(h, 3);

        -- So all players lose control of their AI vehicles when the decision is made.
        if (IsBuilding(h) == false and GetClassLabel(h) ~= "CLASS_TURRET") then
            Mission.m_PlayerVehicles[#Mission.m_PlayerVehicles + 1] = h;
        end

        -- Check to see if the Factory and Armory are built.
        local class = GetClassLabel(h);

        if (class == "CLASS_FACTORY") then
            Mission.m_Factory = h;
        elseif (class == "CLASS_ARMORY") then
            Mission.m_Armory = h;
        end
    end
end

function DeleteObject(h)
    if (Mission.m_Hauler == h) then
        if (Mission.m_HaulerFound and Mission.m_BurnsCommentPlayed == false) then
            -- Braddock: "Well done Major."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1406.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

            -- Show Objectives.
            AddObjectiveOverride("isdf1402.otf", "GREEN", 10, true);
            AddObjective("isdf1403.otf", "WHITE");

            -- Give Burns a highlight.
            SetObjectiveName(Mission.m_Burns, TranslateString("Mission1402"));

            -- Show him.
            SetObjectiveOn(Mission.m_Burns);

            -- So this doesn't play again.
            Mission.m_BurnsCommentPlayed = true;
        end

        -- So the Hauler doesn't immediately go back after Burns when it dies.
        Mission.m_HaulerCooldownTimer = Mission.m_MissionTime +
            SecondsToTurns(m_HaulerCooldownTime[Mission.m_MissionDifficulty]);
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
            -- Check failure conditions over everything else.
            if (Mission.m_MissionState > 1) then
                HandleFailureConditions();
            end

            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Dropship Brain.
            if (Mission.m_DropshipBrainActive) then
                DropshipBrain();
            end

            -- Burns Brain.
            if (Mission.m_BurnsBrainActive) then
                BurnsBrain();
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
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
        Ally(i, Mission.m_EnemyTeam);
    end

    -- Clean up any player spawns that haven't been taken by the player.
    _Cooperative.CleanSpawns();

    -- Grab all of our pre-placed handles.
    Mission.m_Recycler = GetHandle("recycler");
    Mission.m_Condor1 = GetHandle("condor1");
    Mission.m_Condor2 = GetHandle("condor2");
    Mission.m_Condor3 = GetHandle("condor3");
    Mission.m_Nav1 = GetHandle("nav1");
    Mission.m_Tank = GetHandle("tank");
    Mission.m_Scout = GetHandle("scout");
    Mission.m_Burns = GetHandle("burns");
    Mission.m_Cave = GetHandle("cave");
    Mission.m_Road = GetHandle("road");
    Mission.m_BurnsShip = GetHandle("unnamed_burns_ship");
    Mission.m_SRecycler = GetHandle("srecycler");

    -- For all of our coop players...
    for i = 1, _Cooperative.GetTotalPlayers() do
        Mission.m_Holders[#Mission.m_Holders + 1] = BuildObject("stayput", 0, GetPlayerHandle(i));
    end

    -- Start Engines for Condor 2.
    StartEmitter(Mission.m_Condor2, 1);
    StartEmitter(Mission.m_Condor2, 2);

    -- Mask the emitter for Condor 1 and 3.
    MaskEmitter(Mission.m_Condor1, 0);

    -- Start the animations.
    SetAnimation(Mission.m_Condor1, "deploy", 1);
    SetAnimation(Mission.m_Condor2, "deploy", 1);

    -- Kill the third dropship if we are not in coop mode.
    if (_Cooperative.GetTotalPlayers() < 2) then
        -- Remove it safely.
        RemoveObject(Mission.m_Condor3);

        -- So we don't run the logic for the third Condor in the brain function.
        Mission.m_Condor3Away = true;
        Mission.m_Condor3Removed = true;
    else
        MaskEmitter(Mission.m_Condor3, 0);
        SetAnimation(Mission.m_Condor3, "deploy", 1);
    end

    -- Do the fade in if we are not in coop mode.
    if (not Mission.m_IsCooperativeMode) then
        SetColorFade(1, 0.5, Make_RGB(0, 0, 0, 255));
    end

    -- Spawn the inv units.
    Mission.m_InvUnit1 = BuildObject(m_CrashInvUnit1[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "spawn1");
    Mission.m_InvUnit2 = BuildObject(m_CrashInvUnit2[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "spawn6");

    -- Give them a random heading to look more natural.
    SetRandomHeadingAngle(Mission.m_InvUnit1);
    SetRandomHeadingAngle(Mission.m_InvUnit2);

    -- Stop the AIP from using them.
    Defend(Mission.m_InvUnit1, 1);
    Defend(Mission.m_InvUnit2, 1);

    -- Stop units from firing at Burns.
    SetPerceivedTeam(Mission.m_Burns, 1);

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2.5);

    -- Advance the mission state.
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    -- This will remove the holders from the players.
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Remove all holders from the players.
        for i = 1, #Mission.m_Holders do
            RemoveObject(Mission.m_Holders[i]);
        end

        StartSoundEffect("dropdoor.wav", Mission.m_Condor1);

        if (_Cooperative.GetTotalPlayers() > 1) then
            StartSoundEffect("dropdoor.wav", Mission.m_Condor3);
        end

        -- Make the dropship take off.
        SetAnimation(Mission.m_Condor2, "takeoff", 1);

        -- Engine sound.
        StartSoundEffect("dropleav.wav", Mission.m_Condor2);

        -- So we can remove it after it's time.
        Mission.m_Condor2Away = true;

        -- Set the timer for when we remove the dropship.
        Mission.m_Condor2Time = Mission.m_MissionTime + SecondsToTurns(Mission.m_CondorRemoveTime);

        -- Activate the dropship brain.
        Mission.m_DropshipBrainActive = true;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (Mission.m_Condor1Away and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Change the objective name.
        SetObjectiveName(Mission.m_Nav1, TranslateString("Mission1401"));

        -- Highlight Nav 1.
        SetObjectiveOn(Mission.m_Nav1);

        -- Give the player some scrap.
        SetScrap(Mission.m_HostTeam, 40);

        -- Give the enemy some scrap.
        SetScrap(Mission.m_EnemyTeam, 40);

        -- Add 5 minutes to the warning counter.
        Mission.m_CrashSiteWarningTime = Mission.m_MissionTime +
            SecondsToTurns(m_CrashSiteWarningDifficultyTime[Mission.m_MissionDifficulty]);

        -- Activate the Scion brain.
        Mission.m_BurnsBrainActive = true;

        -- Set the AIP here.
        SetAIP("isdf1401_x.aip", Mission.m_EnemyTeam);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    -- Run a check to see if we are near the crash site.
    if (Mission.m_NearCrash == false) then
        -- Small delay so we don't do this every turn.
        if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
            -- Check to see if a player is near the crash site.
            if (IsPlayerWithinDistance(Mission.m_Nav1, 200, _Cooperative.GetTotalPlayers())) then
                -- Mark this as done.
                Mission.m_NearCrash = true;
            end
        end

        -- Do the warnings if the player is taking too long.
        if (Mission.m_CrashSiteWarningCount < 2 and Mission.m_CrashSiteWarningTime < Mission.m_MissionTime) then
            if (Mission.m_CrashSiteWarningCount == 0) then
                if (Mission.m_UnitsSent == false) then
                    -- Send Scion units to the crash site.
                    Defend2(Mission.m_InvUnit1, Mission.m_Burns, 1);
                    Defend2(Mission.m_InvUnit2, Mission.m_BurnsShip, 1);

                    -- So we don't loop.
                    Mission.m_UnitsSent = true;
                elseif (GetDistance(Mission.m_InvUnit1, Mission.m_Burns) < 75 and GetDistance(Mission.m_InvUnit2, Mission.m_BurnsShip)) then
                    -- Braddock: "Major, we're picking up activity at the crash site"
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1402.wav");

                    -- Timer for this audio.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

                    -- Show Objectives.
                    AddObjectiveOverride("isdf1401.otf", "WHITE", 10, true);

                    -- Add 5 minutes to the warning counter.
                    Mission.m_CrashSiteWarningTime = Mission.m_MissionTime +
                        SecondsToTurns(m_CrashSiteWarningDifficultyTime[Mission.m_MissionDifficulty]);

                    -- Highlight the two units.
                    SetObjectiveOn(Mission.m_InvUnit1);
                    SetObjectiveOn(Mission.m_InvUnit2);

                    -- Advance the warnings.
                    Mission.m_CrashSiteWarningCount = Mission.m_CrashSiteWarningCount + 1;
                end
            elseif (Mission.m_CrashSiteWarningCount == 1) then
                if (Mission.m_HaulerSent == false and IsAlive(Mission.m_Hauler)) then
                    -- Tell the Hauler to go to Burns.
                    Follow(Mission.m_Hauler, Mission.m_Burns, 1);

                    -- So we don't loop.
                    Mission.m_HaulerSent = true;
                elseif (GetDistance(Mission.m_Hauler, Mission.m_Burns) < 100) then
                    -- Braddock: "Major, Radar is picking up a Scion Hauler..."
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1403.wav");

                    -- Timer for this audio.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

                    -- Show Objectives.
                    AddObjectiveOverride("isdf1401.otf", "RED", 10, true);

                    -- Advance the warnings.
                    Mission.m_CrashSiteWarningCount = Mission.m_CrashSiteWarningCount + 1;
                end
            end
        end
    else
        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Reset the timer.
        Mission.m_AudioTimer = 0;

        -- If the two units are alive that are sent to the crash site, remove their highlight.
        if (IsAliveAndEnemy(Mission.m_InvUnit1, Mission.m_EnemyTeam)) then
            SetObjectiveOff(Mission.m_InvUnit1);
        end

        if (IsAliveAndEnemy(Mission.m_InvUnit2, Mission.m_EnemyTeam)) then
            SetObjectiveOff(Mission.m_InvUnit2);
        end

        -- Remove the nav highlight.
        SetObjectiveOff(Mission.m_Nav1);

        -- This will play audio based on whether the player is close to the site, or whether they have taken too long.
        if (Mission.m_CrashSiteWarningCount >= 2) then
            -- Show Objectives.
            SetObjectiveOn(Mission.m_Hauler);

            -- Show Objectives.
            AddObjectiveOverride("isdf1401.otf", "RED", 10, true);
            AddObjective("isdf1402.otf", "WHITE");

            -- Have both units follow the Hauler.
            if (IsAliveAndEnemy(Mission.m_InvUnit1, Mission.m_EnemyTeam)) then
                Defend2(Mission.m_InvUnit1, Mission.m_Hauler, 1);
            end

            if (IsAliveAndEnemy(Mission.m_InvUnit2, Mission.m_EnemyTeam)) then
                Defend2(Mission.m_InvUnit2, Mission.m_Hauler, 1);
            end

            -- Braddock: "Stop that Hauler at all costs!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1404.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- So we don't do the logic in Scion Brain.
            Mission.m_HaulerFound = true;
        else
            -- Show Objectives.
            AddObjectiveOverride("isdf1401.otf", "GREEN", 10, true);

            -- Braddock: "Alright Major, search for survivors."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1405.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- This will check to see if the Hauler has Burns or not. If not, don't highlight it. If it does, then highlight it.
    if (Mission.m_HaulerFound == false and Mission.m_ScionHasBurns and IsPlayerWithinDistance(Mission.m_Hauler, 100, _Cooperative.GetTotalPlayers())) then
        -- Braddock: "Stop that Hauler at all costs!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1404.wav");

        -- Timer for this audio.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Highlight the Hauler.
        SetObjectiveOn(Mission.m_Hauler);

        -- Show Objectives.
        AddObjectiveOverride("isdf1401.otf", "GREEN", 10, true);
        AddObjective("isdf1402.otf", "WHITE");

        -- Mark the Hauler as "Found"
        Mission.m_HaulerFound = true;
    elseif (Mission.m_BurnsFree and IsPlayerWithinDistance(Mission.m_Burns, 100, _Cooperative.GetTotalPlayers())) then
        if (Mission.m_BurnsCommentPlayed == false) then
            -- Braddock: "Well done Major."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1406.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

            -- So this doesn't play again.
            Mission.m_BurnsCommentPlayed = true;
        end

        -- Show Objectives.
        AddObjectiveOverride("isdf1402.otf", "GREEN", 10, true);
        AddObjective("isdf1403.otf", "WHITE");

        -- Give Burns a highlight.
        SetObjectiveName(Mission.m_Burns, TranslateString("Mission1402"));

        -- Show him.
        SetObjectiveOn(Mission.m_Burns);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    -- This is running for Yelena's appearance.
    if (Mission.m_PlayerHasBurns) then
        -- Run a check to see if Burns is near any of the relevant path points.
        if (Mission.m_HaulerCheckTimer < Mission.m_MissionTime) then
            -- So we don't do this every frame.
            Mission.m_HaulerCheckTimer = Mission.m_MissionTime + SecondsToTurns(1);

            -- Run a loop to see if we are near any of these paths.
            for i = 1, 6 do
                if (GetDistance(Mission.m_Burns, "shab_check" .. i) < 70) then
                    -- Advance the mission state...
                    Mission.m_MissionState = Mission.m_MissionState + 1;
                end
            end

            if (GetDistance(Mission.m_Burns, "shab_checknew") < 80) then
                -- Advance the mission state...
                Mission.m_MissionState = Mission.m_MissionState + 1;
            end

            -- If none of the above are true, check to see if he is near the Recycler.
            if (GetDistance(Mission.m_Burns, Mission.m_Recycler) < 200) then
                -- Advance the mission state...
                Mission.m_MissionState = Mission.m_MissionState + 1;
            end
        end
    end
end

Functions[7] = function()
    -- Ally teams to be sure.
    for i = 1, 5 do
        Ally(i, Mission.m_EnemyTeam);
    end

    -- Set the AIP here.
    SetAIP("isdf1402_x.aip", Mission.m_EnemyTeam);

    -- Shab: "John, this is Shabayev..."
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1407.wav");

    -- Timer for this audio.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

    -- Build Yelena.
    Mission.m_Yelena = BuildObject("fvtank_x", Mission.m_HostTeam, "end_point");

    -- Don't allow her to be sniped.
    SetCanSnipe(Mission.m_Yelena, 0);

    -- Don't allow her to die... yet.
    SetMaxHealth(Mission.m_Yelena, 0);

    -- Don't allow the Tug to die... yet.
    SetMaxHealth(Mission.m_Tugger, 0);

    -- Have her follow the main player.
    Follow(Mission.m_Yelena, GetPlayerHandle(1));

    -- Get the Tug to stop.
    Stop(Mission.m_Tugger, 1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[8] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Pilot: "Ah sir, they've stopped fighting!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1408.wav");

        -- Timer for this audio.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "John, stop, it's me, Yelena!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1409.wav");

        -- Timer for this audio.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Highlight her.
        SetObjectiveName(Mission.m_Yelena, "???");

        -- Show her beacon.
        SetObjectiveOn(Mission.m_Yelena);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[10] = function()
    -- This checks to see if Yelena reaches John.
    local p = GetPlayerHandle(1);

    if (GetDistance(Mission.m_Yelena, p) < 50) then
        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Reset the timer.
        Mission.m_AudioTimer = 0;

        -- Have her look at the main player.
        LookAt(Mission.m_Yelena, p, 1);

        -- Shab: "I found out the truth, John."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1410.wav");

        -- Timer for this audio.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(15.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Check to see if the meeting messages have been played.
        if (Mission.m_MeetingMessageCounter == 0) then
            -- Braddock: "Do not believe that creature Major..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1411.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

            -- Advance the meeting step.
            Mission.m_MeetingMessageCounter = Mission.m_MeetingMessageCounter + 1;
        elseif (Mission.m_MeetingMessageCounter == 1) then
            -- Shab: "You have to believe me John!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1412.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

            -- Advance the meeting step.
            Mission.m_MeetingMessageCounter = Mission.m_MeetingMessageCounter + 1;
        elseif (Mission.m_MeetingMessageCounter == 2) then
            -- Shab: "If you believe me..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1414.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

            -- Give the Tug back to the player.
            Stop(Mission.m_Tugger, 0);

            -- Restore her health for the decision.
            SetMaxHealth(Mission.m_Yelena, 3500);

            -- Advance the meeting step.
            Mission.m_MeetingMessageCounter = Mission.m_MeetingMessageCounter + 1;
        elseif (Mission.m_MeetingMessageCounter == 3) then
            -- Braddock: "Follow my orders!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1415.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

            -- Advance the meeting step.
            Mission.m_MeetingMessageCounter = Mission.m_MeetingMessageCounter + 1;
        end
    end

    -- This will determine the decision of the player.
    if (Mission.m_DecisionMade == false and Mission.m_MeetingMessageCounter >= 2) then
        if (IsAlive(Mission.m_Yelena) == false) then
            -- Carnage.
            for i = 1, 5 do
                UnAlly(i, Mission.m_EnemyTeam);
            end

            -- Set the AIP here.
            SetAIP("isdf1401_x.aip", Mission.m_EnemyTeam);

            -- Restore the health of the Tug.
            SetMaxHealth(Mission.m_Tugger, 2500);

            -- Braddock: "Well done Major, I knew you'd see through their trickery."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1418.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

            -- Go to the ISDF decision path.
            Mission.m_MissionState = 13;

            -- Decision has been made.
            Mission.m_DecisionMade = true;
        end

        -- Otherwise, check to see if the tugger has been told to follow Yelena.
        if (GetCurrentCommand(Mission.m_Tugger) == CMD_FOLLOW) then
            -- Chekc to see if the Leader is Yelena.
            local leader = GetCurrentWho(Mission.m_Tugger);

            if (IsAlive(Mission.m_Yelena) and leader == Mission.m_Yelena) then
                -- To track health of each object.
                local health = 0;

                -- Make all player vehicles look at the main player.
                for i = 1, #Mission.m_PlayerVehicles do
                    LookAt(Mission.m_PlayerVehicles[i], GetPlayerHandle(1), 1);
                end

                -- Replace all buildings.
                if (IsAround(Mission.m_Recycler)) then
                    -- Store the health of the Recycler.
                    health = GetCurHealth(Mission.m_Recycler);

                    -- Replace the Recycler.
                    Mission.m_Recycler = ReplaceObject(Mission.m_Recycler, "ibrecy_x", 0);

                    -- Restore the health.
                    SetCurHealth(Mission.m_Recycler, health);
                end

                if (IsAround(Mission.m_Factory)) then
                    -- Store the health of the Factory.
                    health = GetCurHealth(Mission.m_Factory);

                    -- Replace the Factory.
                    Mission.m_Factory = ReplaceObject(Mission.m_Factory, "ibfact_x", 0);

                    -- Restore the health.
                    SetCurHealth(Mission.m_Factory, health);
                end

                if (IsAround(Mission.m_Armory)) then
                    -- Store the health of the Armory.
                    health = GetCurHealth(Mission.m_Armory);

                    -- Replace the Factory.
                    Mission.m_Armory = ReplaceObject(Mission.m_Armory, "ibarmo_x", 0);

                    -- Restore the health.
                    SetCurHealth(Mission.m_Armory, health);
                end

                -- Store the health of Yelena.
                health = GetCurHealth(Mission.m_Yelena);

                -- Replace Yelena's handle.
                Mission.m_Yelena = ReplaceObject(Mission.m_Yelena, "fvtank14x", 0);

                -- Restore the health.
                SetCurHealth(Mission.m_Yelena, health);

                -- Just incase her highlighting changes.
                SetObjectiveName(Mission.m_Yelena, "???");

                -- Highlight her again.
                SetObjectiveOn(Mission.m_Yelena);

                -- Don't allow her to be sniped.
                SetCanSnipe(Mission.m_Yelena, 0);

                -- Have the Tug follow Yelena.
                Follow(Mission.m_Tugger, Mission.m_Yelena, 1);

                -- Shab: "Good John, now follow me."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1419.wav");

                -- Timer for this audio.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

                -- Have her retreat to the cave.
                Retreat(Mission.m_Yelena, "end_point", 1);

                -- Go to the Scion decision path.
                Mission.m_MissionState = 12;

                -- Decision has been made.
                Mission.m_DecisionMade = true;
            end
        end
    end
end

Functions[12] = function()
    local closestPlayer = nil;

    -- This will monitor the closest player to Shabayev.
    for i = 1, _Cooperative.GetTotalPlayers() do
        local p = GetPlayerHandle(i);

        if (closestPlayer == nil and GetDistance(p, Mission.m_Yelena) < 30) then
            closestPlayer = p;
        end
    end

    -- This will handle the Scion decision.
    if (Mission.m_ShabStartMovie == false and GetDistance(Mission.m_Yelena, "end_point") < 40 and IsPlayerWithinDistance(Mission.m_Yelena, 30, _Cooperative.GetTotalPlayers())) then
        Mission.m_ShabStartMovie = true;
    end

    -- This will raise the road.
    if (Mission.m_ShabStartMovie and Mission.m_RoadTime < Mission.m_MissionTime) then
        if (Mission.m_ShabRaiseRoad == false) then
            -- Start the animation.
            SetAnimation(Mission.m_Road, "raise", 1);

            -- Start an Earthquake.
            StartEarthQuake(5);

            -- Delay for 5 seconds.
            Mission.m_RoadTime = Mission.m_MissionTime + SecondsToTurns(5);

            -- We have done this part.
            Mission.m_ShabRaiseRoad = true;
        elseif (Mission.m_ShabGoToCave == false) then
            -- Send Yelena down the road.
            Goto(Mission.m_Yelena, "road_path", 1);

            -- Stop the Earthquake
            StopEarthQuake();

            -- Delay for 2 seconds.
            Mission.m_RoadTime = Mission.m_MissionTime + SecondsToTurns(2);

            -- We have done this part.
            Mission.m_ShabGoToCave = true;
        elseif (Mission.m_ShabAtCave == false) then
            if (GetCurrentCommand(Mission.m_Yelena) == CMD_NONE) then
                if (IsAlive(closestPlayer)) then
                    LookAt(Mission.m_Yelena, closestPlayer);
                else
                    LookAt(Mission.m_Yelena, GetPlayerHandle(1));
                end

                -- We have done this part.
                Mission.m_ShabAtCave = true;
            end
        elseif (Mission.m_ShabRaiseCave == false) then
            if (IsAlive(closestPlayer)) then
                -- Have her look at the Cave.
                LookAt(Mission.m_Yelena, Mission.m_Cave, 1);

                -- Start the animation.
                SetAnimation(Mission.m_Cave, "open", 1);

                -- Start an Earthquake.
                StartEarthQuake(5);

                -- Delay for 5 seconds.
                Mission.m_RoadTime = Mission.m_MissionTime + SecondsToTurns(5);

                -- We have done this part.
                Mission.m_ShabRaiseCave = true;
            end
        elseif (Mission.m_ShabToCave == false) then
            -- Stop the Earthquake
            StopEarthQuake();

            -- Send Yelena into the cave.
            Goto(Mission.m_Yelena, "into_cave_path", 1);

            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("Mission Accomplished.");
                DoGameover(10);
            else
                SucceedMission(GetTime() + 6, "isdf14w2.txt");
                ChangeSide();
            end

            -- So we don't loop.
            Mission.m_MissionOver = true;
        end
    end
end

Functions[13] = function()
    -- This will handle the ISDF decision.
    if (GetDistance(Mission.m_Burns, Mission.m_Recycler) < 100) then
        -- Shab: "If you believe me..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1430.wav");

        -- Timer for this audio.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(10);
        else
            SucceedMission(GetTime() + 10, "isdf14w1.txt");
        end

        -- So we don't loop.
        Mission.m_MissionOver = true;
    end
end

function HandleFailureConditions()
    if (Mission.m_FireyDeath) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Reset the timer.
        Mission.m_AudioTimer = 0;

        -- Braddock: "You should've known better than to take Burns over the lava.."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1421.wav");

        -- Show objectives.
        AddObjectiveOverride("isdf1405.otf", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Burns was burnt to death.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf14l3.txt");
        end
    elseif (Mission.m_BurnsRecovered) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Reset the timer.
        Mission.m_AudioTimer = 0;

        -- Braddock: "The Scions have recovered their leader..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1420.wav");

        -- Show objectives.
        AddObjectiveOverride("isdf1403.otf", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Burns was recovered by the Scions.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf14l2.txt");
        end
    elseif (IsAlive(Mission.m_Burns) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Show objectives.
        AddObjectiveOverride("isdf1405.otf", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Burns was killed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf14l4.txt");
        end
    elseif (IsAlive(Mission.m_Recycler) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Show objectives.
        AddObjectiveOverride("isdf1404.otf", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Recycler was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf14l1.txt");
        end
    end
end

function DropshipBrain()
    -- Stop the brain once all starting Condors are gone.
    if (Mission.m_Condor1Removed and Mission.m_Condor2Removed and Mission.m_Condor3Removed and Mission.m_MissionState < 12) then
        Mission.m_DropshipBrainActive = false;
    end

    -- This checks to remove the dropships.
    if (Mission.m_Condor1Away and Mission.m_Condor1Time < Mission.m_MissionTime) then
        -- Remove the Dropship.
        RemoveObject(Mission.m_Condor1);

        -- Mark this as done.
        Mission.m_Condor1Removed = true;
    end

    if (Mission.m_Condor2Away and Mission.m_Condor2Time < Mission.m_MissionTime) then
        -- Remove the Dropship.
        RemoveObject(Mission.m_Condor2);

        -- Mark this as done.
        Mission.m_Condor2Removed = true;
    end

    if (Mission.m_Condor3Away and Mission.m_Condor3Time < Mission.m_MissionTime) then
        -- Remove the Dropship.
        RemoveObject(Mission.m_Condor3);

        -- Mark this as done.
        Mission.m_Condor3Removed = true;
    end

    -- Check and make sure all players are clear of the dropships so we can fly away.
    if (Mission.m_Condor1Away == false) then
        if (Mission.m_PlayerClear == false) then
            if (IsPlayerWithinDistance(Mission.m_Condor1, 40, _Cooperative.GetTotalPlayers()) == false) then
                -- Move player units out of the dropship.
                Goto(Mission.m_Tank, "player_start", 0);
                Goto(Mission.m_Scout, "player_start", 0);

                -- We are clear.
                Mission.m_PlayerClear = true;
            end
        elseif (GetDistance(Mission.m_Tank, Mission.m_Condor1) > 30 and GetDistance(Mission.m_Scout, Mission.m_Condor1) > 30) then
            -- Braddock: "Alright Major. Set up a base."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1401.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

            -- Show Objectives.
            AddObjective("isdf1401.otf", "WHITE");

            -- Start the take-off sequence.
            SetAnimation(Mission.m_Condor1, "takeoff", 1);

            -- Engine sound.
            StartSoundEffect("dropleav.wav", Mission.m_Condor1);

            -- Start the emitters.
            StartEmitter(Mission.m_Condor1, 1);
            StartEmitter(Mission.m_Condor1, 2);

            -- Set the timer for when we remove the dropship.
            Mission.m_Condor1Time = Mission.m_MissionTime + SecondsToTurns(Mission.m_CondorRemoveTime);

            -- So we don't loop.
            Mission.m_Condor1Away = true;
        end
    end

    if (Mission.m_Condor3Away == false) then
        if (IsPlayerWithinDistance(Mission.m_Condor3, 40, _Cooperative.GetTotalPlayers()) == false) then
            -- Start the take-off sequence.
            SetAnimation(Mission.m_Condor3, "takeoff", 1);

            -- Engine sound.
            StartSoundEffect("dropleav.wav", Mission.m_Condor3);

            -- Start the emitters.
            StartEmitter(Mission.m_Condor3, 1);
            StartEmitter(Mission.m_Condor3, 2);

            -- Set the timer for when we remove the dropship.
            Mission.m_Condor3Time = Mission.m_MissionTime + SecondsToTurns(Mission.m_CondorRemoveTime);

            -- So we don't loop.
            Mission.m_Condor3Away = true;
        end
    end
end

function BurnsBrain()
    -- This will move the Hauler out of the hills so it doesn't get stuck.
    if (IsAliveAndEnemy(Mission.m_Hauler, Mission.m_EnemyTeam)) then
        if (Mission.m_HaulerMove == false and Mission.m_HaulerMoveTimer < Mission.m_MissionTime) then
            -- This will place the Hauler in a spot where it can't get stuck.
            Retreat(Mission.m_Hauler, "hauler_dropoff", 1);

            -- So we don't loop.
            Mission.m_HaulerMove = true;
        end

        -- Tell the Hauler to pick up Burns.
        if (Mission.m_BurnsFree and Mission.m_HaulerCooldownTimer < Mission.m_MissionTime and Mission.m_HaulerPickup == false) then
            if (Mission.m_NearCrash) then
                -- Pick him up!
                Pickup(Mission.m_Hauler, Mission.m_Burns);

                -- Mark this as true.
                Mission.m_HaulerPickup = true;
            end
        end
    end

    -- Grab the tugger from burns.
    Mission.m_Tugger = GetTug(Mission.m_Burns);

    -- We will run a check to see if burns is free here.
    if (Mission.m_BurnsFree == false) then
        if (Mission.m_Tugger == nil) then
            -- Reset all necessary variables.
            Mission.m_ScionHasBurns = false;
            Mission.m_PlayerHasBurns = false;
            Mission.m_HaulerPickup = false;
            Mission.m_HaulerRetreat = false;
            Mission.m_HaulerMove = false;

            -- So this doesn't loop.
            Mission.m_BurnsFree = true;
        end

        -- This will handle if the player takes Burns over the lava.
        if (Mission.m_PlayerHasBurns) then
            -- Stop the Scion Hauler.
            if (IsAliveAndEnemy(Mission.m_Hauler, Mission.m_EnemyTeam)) then
                Stop(Mission.m_Hauler, 0);
            end

            if (Mission.m_FireyDeath == false and Mission.m_LavaCheckTimer < Mission.m_MissionTime) then
                -- So we don't do this each frame.
                Mission.m_LavaCheckTimer = Mission.m_MissionTime + SecondsToTurns(2);

                -- See if the player takes burns to any of the lava points.
                for i = 1, 4 do
                    local dist = GetDistance(Mission.m_Tugger, "lava_point" .. i);

                    if (dist < 175) then
                        -- Burns is singed.
                        Mission.m_FireyDeath = true;

                        -- Eject Burns.
                        Damage(Mission.m_Burns, GetMaxHealth(Mission.m_Burns) + 1);
                    end
                end
            end
        elseif (Mission.m_ScionHasBurns) then
            -- This will check the state of Burns if he hasn't been recovered yet.
            if (Mission.m_BurnsRecovered == false) then
                -- Check to see if the Recovery state has triggered.
                if (Mission.m_HaulerRetreat == false) then
                    -- Check to see if the first comment has been played, and that the player is far away.
                    if (Mission.m_BurnsCommentPlayed and IsPlayerWithinDistance(Mission.m_Burns, 100, _Cooperative.GetTotalPlayers()) == false) then
                        -- Braddock: "The Scions have the creature again!"
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1422.wav");

                        -- Timer for this audio.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
                    end

                    -- Send the Hauler back to the Scion base.
                    Retreat(Mission.m_Hauler, "scion_base");

                    -- So we don't loop.
                    Mission.m_HaulerRetreat = true;
                elseif (Mission.m_HaulerCheckTimer < Mission.m_MissionTime) then
                    -- So we don't do this every frame.
                    Mission.m_HaulerCheckTimer = Mission.m_MissionTime + SecondsToTurns(2);

                    -- Check to see if the Hauler is back at the Matriarch.
                    if (GetDistance(Mission.m_Burns, Mission.m_SRecycler) < 40) then
                        -- Burns has been recovered.
                        Mission.m_BurnsRecovered = true;
                    end
                end
            end
        end
    elseif (IsAlive(Mission.m_Burns) and Mission.m_Tugger ~= nil) then
        -- Grab the team number of the tug that has Burns.
        local tugTeam = GetTeamNum(Mission.m_Tugger);

        -- Check to see if the tug is on the player team.
        if (tugTeam > 0 and tugTeam < 5) then
            Mission.m_PlayerHasBurns = true;
        elseif (tugTeam == Mission.m_EnemyTeam) then
            Mission.m_ScionHasBurns = true;
        end

        -- He's no longer free.
        Mission.m_BurnsFree = false;
    end
end
