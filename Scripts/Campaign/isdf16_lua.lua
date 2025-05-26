--[[
    BZCC ISDF16 Lua Mission Script
    Written by AI_Unit
    Version 1.0 22-02-2023
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
local m_MissionName = "ISDF16: Hole in One";

-- Chance for the Scion units to get upgrades.
local m_ShieldChance = 0.2;
local m_WeaponChance = 0.25;

local m_WeaponTable = {
    -- Table for Cannons (1)
    m_Cannons = { "gquill_c", "gsonic_c", "garc_c" },

    -- Table for Guns (2)
    m_Guns = { "glock_c", "ggauss_c", },

    -- Table for Missiles (3)
    m_Missiles = { "gmlock_c" },

    -- Table for Sheilds (4)
    m_Shields = { "gabsorb", "gdeflect", "gshield" }
}

-- Timers for difficulty.
local m_MaulerDifficultyTime = { 90, 60, 40 };

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

    m_Recycler = nil,
    m_Dropship = nil,
    m_Dropship2 = nil,

    m_Attack1 = nil,
    m_Attack2 = nil,
    m_Attack3 = nil,
    m_Attack4 = nil,
    m_Attack5 = nil,
    m_Healer1 = nil,
    m_Healer2 = nil,

    m_ConvoyTug = nil,
    m_Titan1 = nil,
    m_Titan2 = nil,
    m_Sentry1 = nil,
    m_Sentry2 = nil,

    m_Attack2_1 = nil,
    m_Attack2_2 = nil,
    m_Attack2_3 = nil,
    m_Attack2_4 = nil,
    m_Attack2_5 = nil,
    m_Attack2_6 = nil,

    m_Turret1 = nil,
    m_Turret2 = nil,
    m_Turret3 = nil,
    m_Turret4 = nil,

    m_BomberGuard1 = nil,
    m_BomberGuard2 = nil,
    m_BomberGuard3 = nil,

    m_BomberGuard4 = nil,
    m_BomberGuard5 = nil,
    m_BomberGuard6 = nil,

    m_Goal1 = nil,
    m_Goal2 = nil,
    m_Goal3 = nil,
    m_Goal4 = nil,

    m_MapPatrolBots = {},
    m_MapAttackBots = {},

    -- Specific targets for spawned attacks.
    m_TargetPower = nil,
    m_TargetGunTower = nil,
    m_TargetFactory = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_DropshipBrainActive = false,
    m_RobotBrainActive = false,
    m_ScionBrainActive = false,
    m_PlayerClear = false,
    m_Condor1Away = false,
    m_Condor2Away = false,
    m_Condor1Removed = false,
    m_Condor2Removed = false,
    m_ArteryBotsSpawned = false,
    m_MaulersSent = false,
    m_BraddockRobotMessagePlayed = false,
    m_PowerSurgeActivated = false,

    m_Turret1Sent = false,
    m_Turret2Sent = false,
    m_Turret3Sent = false,
    m_Turret4Sent = false,

    m_BomberGuard1Sent = false,
    m_BomberGuard2Sent = false,
    m_BomberGuard3Sent = false,
    m_BomberGuard4Sent = false,
    m_BomberGuard5Sent = false,
    m_BomberGuard6Sent = false,

    -- Braddock is telling us about enemy units.
    m_BraddockWarningPlayed = false,
    m_BraddockHighlightMessagePlayed = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,
    m_Condor1Time = 0,
    m_Condor2Time = 0,
    m_CondorRemoveTime = 15,

    m_AttackBotTimer = 0,

    m_ArteryBotDelayTime = 0,
    m_ArteryBotIterator = 0,

    m_PlayerArteryCheckTime = 0,

    m_PatrolBotCheckTime = 0,
    m_PatrolBotSpawnTime = 0,
    m_PatrolBotCount = 0,

    m_TurretDistpacherTimer = 0,
    m_HealerCheckTimer = 0,
    m_MaulerTime = 0,

    m_ConvoyTime = 0,

    m_MissionDelayTime = 0,

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

    -- So we don't lag when the Recyclers spawn.
    PreloadODF("fvrecy_r");
    PreloadODF("ivrecy_x");
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
    -- Check the team of the handle.
    local teamNum = GetTeamNum(h);

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam or teamNum == 7) then
        -- Grab the ODF that's entered the world.
        local ODFName = GetCfg(h);

        SetSkill(h, Mission.m_MissionDifficulty);

        if (ODFName == "fvturr_r") then
            -- Max these guys out to detect bombers.
            SetSkill(h, 3);

            -- Try and prevent the AIP from using it.
            SetIndependence(h, 1);

            if (teamNum == Mission.m_EnemyTeam) then
                -- Turret dispatcher needs to know of any turrets that are built.
                if (not IsAliveAndEnemy(Mission.m_Turret1, Mission.m_EnemyTeam)) then
                    Mission.m_Turret1 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_Turret1Sent = false;
                elseif (not IsAliveAndEnemy(Mission.m_Turret2, Mission.m_EnemyTeam)) then
                    Mission.m_Turret2 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_Turret2Sent = false;
                elseif (not IsAliveAndEnemy(Mission.m_BomberGuard1, Mission.m_EnemyTeam)) then
                    Mission.m_BomberGuard1 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_BomberGuard1Sent = false;
                elseif (not IsAliveAndEnemy(Mission.m_BomberGuard2, Mission.m_EnemyTeam)) then
                    Mission.m_BomberGuard2 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_BomberGuard2Sent = false;
                elseif (not IsAliveAndEnemy(Mission.m_BomberGuard3, Mission.m_EnemyTeam)) then
                    Mission.m_BomberGuard3 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_BomberGuard3Sent = false;
                end
            elseif (teamNum == 7) then
                -- Turret dispatcher needs to know of any turrets that are built.
                if (not IsAliveAndEnemy(Mission.m_Turret3, 7)) then
                    Mission.m_Turret3 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_Turret3Sent = false;
                elseif (not IsAliveAndEnemy(Mission.m_Turret4, 7)) then
                    Mission.m_Turret4 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_Turret4Sent = false;
                elseif (not IsAliveAndEnemy(Mission.m_BomberGuard4, 7)) then
                    Mission.m_BomberGuard4 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_BomberGuard4Sent = false;
                elseif (not IsAliveAndEnemy(Mission.m_BomberGuard5, 7)) then
                    Mission.m_BomberGuard5 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_BomberGuard5Sent = false;
                elseif (not IsAliveAndEnemy(Mission.m_BomberGuard6, 7)) then
                    Mission.m_BomberGuard6 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_BomberGuard6Sent = false;
                end
            end
        end

        -- Check to see if the unit needs a weapon upgrade.
        if (Mission.m_StartDone) then
            if (ODFName == "fvtank_r" or ODFName == "fvarch_r" or ODFName == "fvsent_r" or ODFName == "fvscout_r") then
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
                    if (ODFName == "fvtank_r" or ODFName == "fvscout_r") then
                        GiveWeapon(h, m_WeaponTable.m_Cannons[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Cannons))]);
                    elseif (ODFName == "fvsent_r") then
                        GiveWeapon(h, m_WeaponTable.m_Guns[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Guns))]);
                    elseif (ODFName == "fvarch_r") then
                        GiveWeapon(h, m_WeaponTable.m_Missiles[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Missiles))]);
                    end
                end
            end
        end
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        -- Always max our player units.
        SetSkill(h, 3);

        -- Testing.
        SetAvoidType(h, 1);
    end
end

function DeleteObject(h)
    -- Grab the ODF.
    local odf = GetCfg(h);

    if (h == Mission.m_Turret1) then
        Mission.m_Turret1 = nil;
    elseif (h == Mission.m_Turret2) then
        Mission.m_Turret2 = nil;
    elseif (h == Mission.m_Turret3) then
        Mission.m_Turret3 = nil;
    elseif (h == Mission.m_Turret4) then
        Mission.m_Turret4 = nil;
    end

    -- Check if the bot is part of Mission.m_MapPatrolBots
    if (odf == "fc111100") then
        -- If it's part of the table, call this.
        TableRemoveByHandle(Mission.m_MapPatrolBots, h);
        -- If it's part of the table, call this.
        TableRemoveByHandle(Mission.m_MapAttackBots, h);
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

            -- Robot Brain.
            if (Mission.m_RobotBrainActive) then
                RobotBrain();
            end

            -- Scion Brain.
            if (Mission.m_ScionBrainActive) then
                ScionBrain();
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

function PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
    if (Mission.m_PowerSurgeActivated == false) then
        -- If the Power Surge hasn't occured yet, use this to play the alert and show the objective to the player.
        local shooterODF = GetCfg(ShooterHandle);
        local victimODF = GetCfg(VictimHandle);

        -- This will start the attacks.
        if (shooterODF == "fc111100" or victimODF == "fc111100" or shooterODF == "cbturr02" or victimODF == "cbturr02") then
            -- Set up our timers for the attacks.
            Mission.m_AttackBotTimer = Mission.m_MissionTime + SecondsToTurns(80);

            -- So we don't loop.
            Mission.m_PowerSurgeActivated = true;
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Unique to this mission. We want two Scion Recyclers, so we are allying Teams 6 and 7.
    Ally(Mission.m_EnemyTeam, 7);

    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(7, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Grab our pre-placed handles.
    Mission.m_Recycler = GetHandle("unnamed_ivrecy_x");
    Mission.m_Dropship = GetHandle("dropship");
    Mission.m_Dropship2 = GetHandle("dropship2");

    -- Build attacking units.
    Mission.m_Attack1 = BuildObject("fvarch_r", Mission.m_EnemyTeam, "attack1");
    Mission.m_Attack2 = BuildObject("fvarch_r", Mission.m_EnemyTeam, "attack2");
    Mission.m_Attack3 = BuildObject("fvarch_r", Mission.m_EnemyTeam, "attack3");
    Mission.m_Attack4 = BuildObject("fvatank_r", Mission.m_EnemyTeam, "convoy1");
    Mission.m_Attack5 = BuildObject("fvatank_r", Mission.m_EnemyTeam, "convoy2");

    -- Build healers to accompany the Titans.
    Mission.m_Healer1 = BuildObject("fvserv_r", Mission.m_EnemyTeam, GetPositionNear("convoy3", 25, 25));
    Mission.m_Healer2 = BuildObject("fvserv_r", Mission.m_EnemyTeam, GetPositionNear("convoy3", 25, 25));

    -- Make the Healers follow the Titans.
    Follow(Mission.m_Healer1, Mission.m_Attack4);
    Follow(Mission.m_Healer2, Mission.m_Attack5);

    -- Build Guardians around the map.
    Mission.m_Turret1 = BuildObject("fvturr_r", Mission.m_EnemyTeam, "turret1");
    Mission.m_Turret2 = BuildObject("fvturr_r", Mission.m_EnemyTeam, "turret2");
    Mission.m_Turret3 = BuildObject("fvturr_r", 7, "turret3");
    Mission.m_Turret4 = BuildObject("fvturr_r", 7, "turret4");

    -- The goals that the player needs to reach.
    Mission.m_Goal1 = GetHandle("goal1");
    Mission.m_Goal2 = GetHandle("goal2");
    Mission.m_Goal3 = GetHandle("goal3");
    Mission.m_Goal4 = GetHandle("goal4");

    -- Enemy Recyclers.
    BuildObject("fvrecy_r", Mission.m_EnemyTeam, "RecyclerEnemy");
    BuildObject("fvrecy_r", 7, "base2");

    -- Give scrap to all teams that need it.
    AddScrap(Mission.m_HostTeam, 40);
    AddScrap(Mission.m_EnemyTeam, 40);
    AddScrap(7, 40);

    -- Dropships shouldn't die.
    SetMaxHealth(Mission.m_Dropship, 0);
    SetMaxHealth(Mission.m_Dropship2, 0);

    -- Play the animations for each dropship.
    SetAnimation(Mission.m_Dropship, "deploy", 1);
    SetAnimation(Mission.m_Dropship2, "takeoff", 1);

    -- Safely play the sound for the second dropship.
    StartSoundEffect("dropleave.wav", Mission.m_Dropship2);

    -- So we can remove it after it's time.
    Mission.m_Condor2Away = true;

    -- Set the timer for when we remove the dropship.
    Mission.m_Condor2Time = Mission.m_MissionTime + SecondsToTurns(Mission.m_CondorRemoveTime);

    -- Activate the dropship brain.
    Mission.m_DropshipBrainActive = true;

    -- The amount of "patrol" bots that should be on the map.
    Mission.m_PatrolBotCount = 2 * Mission.m_MissionDifficulty;

    -- Clean up any player spawns that haven't been taken by the player.
    _Cooperative.CleanSpawns();

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Give Braddock his message.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1601.wav");

        -- The timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(21.5);

        -- Prepare the Healers.
        Mission.m_HealerCheckTimer = Mission.m_MissionTime + SecondsToTurns(2);

        -- Start the Robots.
        Mission.m_RobotBrainActive = true;

        -- Allow the Scion brain to think
        Mission.m_ScionBrainActive = true;

        -- This will set the Maulers to attack.
        Mission.m_MaulerTime = Mission.m_MissionTime +
            SecondsToTurns(m_MaulerDifficultyTime[Mission.m_MissionDifficulty]);

        -- Play the door sound effect for the player dropship.
        StartSoundEffect("dropdoor.wav", Mission.m_Dropship);

        -- Show the objectives.
        AddObjectiveOverride("isdf1601.otf", "WHITE", 10, true);

        -- AIPs for the enemy.
        SetAIP("isdf1601_x.aip", Mission.m_EnemyTeam);
        SetAIP("isdf1602_x.aip", 7);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    -- This will be Braddock telling the player about the enemy units.
    if (Mission.m_BraddockWarningPlayed == false and (IsPlayerWithinDistance("turret1", 200, _Cooperative.GetTotalPlayers()) or IsPlayerWithinDistance("turret4", 200, _Cooperative.GetTotalPlayers()))) then
        -- Braddock: "Recon is showing heavy enemy units on your path".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1603.wav");

        -- Set the audio timer for this clip just in case we need to check if it's done.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- So we don't loop.
        Mission.m_BraddockWarningPlayed = true;
    end

    -- This will play if the player reaches the artery.
    if (Mission.m_PlayerArteryCheckTime < Mission.m_MissionTime) then
        -- Run some checks to see if the player has reached the goals.
        local check1 = IsPlayerWithinDistance(Mission.m_Goal1, 200, _Cooperative.GetTotalPlayers());
        local check2 = IsPlayerWithinDistance(Mission.m_Goal2, 200, _Cooperative.GetTotalPlayers());
        local check3 = IsPlayerWithinDistance(Mission.m_Goal3, 200, _Cooperative.GetTotalPlayers());
        local check4 = IsPlayerWithinDistance(Mission.m_Goal4, 200, _Cooperative.GetTotalPlayers());

        -- Play Braddock's message about fighting to the artery.
        if (check1 or check2 or check3 or check4) then
            -- Braddock: "That's it! We need to fight our way to that hull."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1602.wav");

            -- Length of this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Spawn the Convoy.
            Mission.m_Titan1 = BuildObject("fvatank_r", Mission.m_EnemyTeam, "convoy1");

            -- Send the Titan along the path.
            Goto(Mission.m_Titan1, "convoy_path", 1);

            -- Build the convoy tug.
            Mission.m_ConvoyTug = BuildObject("fvtug_r", Mission.m_EnemyTeam, "convoy2");

            -- Tell it to follow the first Titan.
            Follow(Mission.m_ConvoyTug, Mission.m_Titan1, 1);

            -- Spawn the second Titan.
            Mission.m_Titan2 = BuildObject("fvatank_r", Mission.m_EnemyTeam, "convoy3");

            -- Have it follow the tug.
            Follow(Mission.m_Titan2, Mission.m_ConvoyTug, 1);

            -- Spawn the first Sentry.
            Mission.m_Sentry1 = BuildObject("fvsent_r", Mission.m_EnemyTeam, "convoy4");

            -- Have it follow the second Titan.
            Follow(Mission.m_Sentry1, Mission.m_Titan2, 1);

            -- Spawn the second Sentry.
            Mission.m_Sentry2 = BuildObject("fvsent_r", Mission.m_EnemyTeam, "convoy5");

            -- Have it follow the Tug.
            Follow(Mission.m_Sentry2, Mission.m_ConvoyTug, 1);

            -- Spawn the first Healer.
            Mission.m_Healer1 = BuildObject("fvserv_r", Mission.m_EnemyTeam, "convoy4");

            -- Have it follow the First Titan.
            Follow(Mission.m_Healer1, Mission.m_Titan1, 1);

            -- Spawn the second Healer.
            Mission.m_Healer2 = BuildObject("fvserv_r", Mission.m_EnemyTeam, "convoy5");

            -- Have it follow the Tug.
            Follow(Mission.m_Healer2, Mission.m_ConvoyTug, 1);

            -- Set the Convoy Timer here.
            Mission.m_ConvoyTime = Mission.m_MissionTime + SecondsToTurns(20);

            -- Switch off the Scion brain, and the Robot brain so they no longer attack.
            Mission.m_ScionBrainActive = false;
            Mission.m_RobotBrainActive = false;

            -- Let's safely advance to the next mission stage for checking the health of the Scion bases.
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end

        -- Delay this check so we're not doing it each frame.
        Mission.m_PlayerArteryCheckTime = Mission.m_MissionTime + SecondsToTurns(2);
    end
end

Functions[4] = function()
    if (Mission.m_ConvoyTime < Mission.m_MissionTime) then
        -- Braddock: "The Scions are retreating underground."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1603a.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

        -- Highlight the Tug.
        SetObjectiveName(Mission.m_ConvoyTug, TranslateString("Mission1101"));
        SetObjectiveOn(Mission.m_ConvoyTug);

        -- New Objective.
        AddObjectiveOverride("isdf1603.otf", "WHITE", 10, true);

        -- Move to the next state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    if (Mission.m_BraddockHighlightMessagePlayed == false and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock: "I've highlighted the Convoy".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1604.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- So we don't loop.
        Mission.m_BraddockHighlightMessagePlayed = true;
    end

    -- This is where we check if the Convoy has been killed, or whether it has reached its destination.
    if (IsAliveAndEnemy(Mission.m_ConvoyTug, Mission.m_EnemyTeam) == false) then
        -- Show objectives.
        AddObjectiveOverride("isdf1604.otf", "WHITE", 5, true);

        -- Mission was successful.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(10);
        else
            SucceedMission(GetTime() + 10, "isdf16w1.txt");
        end

        -- Braddock: "Good work Major!".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1605.wav");

        -- Audio timer for this message.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Mission is finished.
        Mission.m_MissionOver = true;
    elseif (GetDistance(Mission.m_ConvoyTug, "gtow3") < 50) then
        -- Show objectives.
        AddObjectiveOverride("isdf1603.otf", "RED", 5, true);

        -- Mission failed.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The Convoy escaped.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf16l2.txt");
        end

        -- Mission is finished.
        Mission.m_MissionOver = true;
    end
end

function DropshipBrain()
    -- Stop the brain once all starting Condors are gone.
    if (Mission.m_Condor1Removed and Mission.m_Condor2Removed) then
        Mission.m_DropshipBrainActive = false;
    end

    -- This checks to remove the dropships.
    if (Mission.m_Condor1Away and Mission.m_Condor1Time < Mission.m_MissionTime) then
        -- Remove the Dropship.
        RemoveObject(Mission.m_Dropship);

        -- Mark this as done.
        Mission.m_Condor1Removed = true;
    end

    if (Mission.m_Condor2Away and Mission.m_Condor2Time < Mission.m_MissionTime) then
        -- Remove the Dropship.
        RemoveObject(Mission.m_Dropship2);

        -- Mark this as done.
        Mission.m_Condor2Removed = true;
    end

    -- Check and make sure all players are clear of the dropships so we can fly away.
    if (Mission.m_Condor1Away == false) then
        if (IsPlayerWithinDistance(Mission.m_Dropship, 40, _Cooperative.GetTotalPlayers()) == false) then
            -- Start the take-off sequence.
            SetAnimation(Mission.m_Dropship, "takeoff", 1);

            -- Start the emitters.
            StartEmitter(Mission.m_Dropship, 1);
            StartEmitter(Mission.m_Dropship, 2);

            -- Engine sound.
            StartSoundEffect("dropleav.wav", Mission.m_Dropship);

            -- Set the timer for when we remove the dropship.
            Mission.m_Condor1Time = Mission.m_MissionTime + SecondsToTurns(Mission.m_CondorRemoveTime);

            -- So we don't loop.
            Mission.m_Condor1Away = true;
        end
    end
end

function RobotBrain()
    --[[
        Based on the chosen difficulty, we should spawn a good amount of robots
        to patrol the tunnel artery, and the map.
    ]]
       --

    if (Mission.m_ArteryBotsSpawned == false and Mission.m_ArteryBotDelayTime < Mission.m_MissionTime) then
        local botPlatoon = {};

        -- Run a loop, spawn the bots, get them in formation, start patrol.
        for i = 1, Mission.m_MissionDifficulty do
            -- Build the bot.
            local bot = BuildObject("fc111100", Mission.m_EnemyTeam, GetPositionNear("artery_bots", 25, 25));

            -- Place the bot in the platoon.
            botPlatoon[#botPlatoon + 1] = bot;
        end

        -- First bot, patrol, second and third, follow close.
        if (IsAlive(botPlatoon[1])) then
            Patrol(botPlatoon[1], "bot_patrol_1", 1);
        end

        if (IsAlive(botPlatoon[2])) then
            Follow(botPlatoon[2], botPlatoon[1], 1);
        end

        if (IsAlive(botPlatoon[3])) then
            Follow(botPlatoon[3], botPlatoon[2], 1);
        end

        -- Increase the iterator.
        Mission.m_ArteryBotIterator = Mission.m_ArteryBotIterator + 1;

        if (Mission.m_ArteryBotIterator >= Mission.m_MissionDifficulty) then
            -- No more bots.
            Mission.m_ArteryBotsSpawned = true;
        else
            -- Delay this function.
            Mission.m_ArteryBotDelayTime = Mission.m_MissionTime + SecondsToTurns(15);
        end
    end

    -- We'll also send patrols around the map. If the player has encountered a drone, we'll get Braddock to play a message.
    if (#Mission.m_MapPatrolBots % 2 == 0 and #Mission.m_MapPatrolBots < 6 and Mission.m_PatrolBotSpawnTime < Mission.m_MissionTime) then
        -- Spawn 2 more based on whether 2 have died.
        for i = 1, 2 do
            -- Build a bot.
            local bot = BuildObject("fc111100", Mission.m_EnemyTeam, GetPositionNear("attack" .. i, 25, 25));

            -- Send a bot to patrol.
            Patrol(bot, "robot_patrol_a", 1);

            -- Add the bot to our table.
            Mission.m_MapPatrolBots[#Mission.m_MapPatrolBots + 1] = bot;
        end

        -- Delay the loop by X seconds.
        Mission.m_PatrolBotSpawnTime = Mission.m_MissionTime + SecondsToTurns(15);
    end

    -- Run a check here to see if the player is within distance of a bot.
    if (Mission.m_BraddockRobotMessagePlayed == false and #Mission.m_MapPatrolBots > 0 and Mission.m_PatrolBotCheckTime < Mission.m_MissionTime) then
        -- So we don't do this each frame. Less expensive...
        for i = 1, #Mission.m_MapPatrolBots do
            if (IsPlayerWithinDistance(Mission.m_MapPatrolBots[i], 200, _Cooperative.GetTotalPlayers())) then
                -- Braddock: "Are you picking up those robot signals?"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1703.wav");

                -- So we don't loop.
                Mission.m_BraddockRobotMessagePlayed = true;

                -- So we don't carry on.
                break;
            end
        end

        -- Do this every couple of seconds.
        Mission.m_PatrolBotCheckTime = Mission.m_MissionTime + SecondsToTurns(2);
    end

    -- If the power surge has occured, start attacking with bots from different angles.
    if (Mission.m_PowerSurgeActivated and Mission.m_AttackBotTimer < Mission.m_MissionTime) then
        -- Check how many bots are currently active and spawn the right amount.
        local botCount = 3 * Mission.m_MissionDifficulty;
        local activeBotCount = #Mission.m_MapAttackBots;

        if (activeBotCount < botCount) then
            local diff = botCount - activeBotCount;
            local pos = GetPosition(Mission.m_Recycler);

            for i = 1, diff do
                local chance = GetRandomFloat(0, 1);
                local path = nil;

                if (chance > 0.5) then
                    path = 'convoy' .. i;
                else
                    if (i < 4) then
                        path = 'attack' .. i;
                    else 
                        path = 'attack3';
                    end
                end

                -- Create a bot around the chosen path.
                local bot = BuildObject("fc111100", Mission.m_EnemyTeam, GetPositionNear(path, 25, 25));
                
                -- Store this in our table.
                Mission.m_MapAttackBots[#Mission.m_MapAttackBots + 1] = bot;

                -- Send the bot to the Recycler.
                Goto(bot, pos, 1);
            end
        end

        -- Reset the timer so we don't do this each frame.
        Mission.m_AttackBotTimer = Mission.m_MissionTime + SecondsToTurns(80);
    end
end

function ScionBrain()
    -- Use this to dispatch the turrets.
    if (Mission.m_TurretDistpacherTimer < Mission.m_MissionTime) then
        if (Mission.m_Turret1Sent == false and IsAliveAndEnemy(Mission.m_Turret1, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Turret1, "turret1", 1);

            -- So we don't loop.
            Mission.m_Turret1Sent = true;
        end

        if (Mission.m_Turret2Sent == false and IsAliveAndEnemy(Mission.m_Turret2, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Turret2, "turret2", 1);

            -- So we don't loop.
            Mission.m_Turret2Sent = true;
        end

        if (Mission.m_Turret3Sent == false and IsAliveAndEnemy(Mission.m_Turret3, 7)) then
            Goto(Mission.m_Turret3, "turret3", 1);

            -- So we don't loop.
            Mission.m_Turret3Sent = true;
        end

        if (Mission.m_Turret4Sent == false and IsAliveAndEnemy(Mission.m_Turret4, 7)) then
            Goto(Mission.m_Turret4, "turret4", 1);

            -- So we don't loop.
            Mission.m_Turret4Sent = true;
        end

        if (Mission.m_BomberGuard1Sent == false and IsAliveAndEnemy(Mission.m_BomberGuard1, Mission.m_EnemyTeam)) then
            Goto(Mission.m_BomberGuard1, "bomber_guard_6_1", 1);

            -- So we don't loop.
            Mission.m_BomberGuard1Sent = true;
        end

        if (Mission.m_BomberGuard2Sent == false and IsAliveAndEnemy(Mission.m_BomberGuard2, Mission.m_EnemyTeam)) then
            Goto(Mission.m_BomberGuard2, "bomber_guard_6_2", 1);

            -- So we don't loop.
            Mission.m_BomberGuard2Sent = true;
        end

        if (Mission.m_BomberGuard3Sent == false and IsAliveAndEnemy(Mission.m_BomberGuard3, Mission.m_EnemyTeam)) then
            Goto(Mission.m_BomberGuard3, "bomber_guard_6_3", 1);

            -- So we don't loop.
            Mission.m_BomberGuard3Sent = true;
        end

        if (Mission.m_BomberGuard4Sent == false and IsAliveAndEnemy(Mission.m_BomberGuard4, 7)) then
            Goto(Mission.m_BomberGuard4, "bomber_guard_7_1", 1);

            -- So we don't loop.
            Mission.m_BomberGuard4Sent = true;
        end

        if (Mission.m_BomberGuard5Sent == false and IsAliveAndEnemy(Mission.m_BomberGuard5, 7)) then
            Goto(Mission.m_BomberGuard5, "bomber_guard_7_2", 1);

            -- So we don't loop.
            Mission.m_BomberGuard5Sent = true;
        end

        if (Mission.m_BomberGuard6Sent == false and IsAliveAndEnemy(Mission.m_BomberGuard6, 7)) then
            Goto(Mission.m_BomberGuard6, "bomber_guard_7_3", 1);

            -- So we don't loop.
            Mission.m_BomberGuard6Sent = true;
        end

        -- To delay loops.
        Mission.m_TurretDistpacherTimer = Mission.m_MissionTime + SecondsToTurns(1.5);
    end

    -- This handles the assassin Maulers.
    if (Mission.m_MaulersSent == false and Mission.m_MaulerTime < Mission.m_MissionTime) then
        -- Braddock: "Maulers are coming to get you."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1640.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- As per difficulty, send some units to attack.
        for i = 1, Mission.m_MissionDifficulty do
            local mauler = BuildObject("fvwalk_r", Mission.m_EnemyTeam, GetPositionNear("spawn_mauler" .. i));
            local sentry = BuildObject("fvsent_r", Mission.m_EnemyTeam, GetPositionNear("spawn_mauler" .. i));

            -- Give the sentry the EMP lock.
            GiveWeapon(sentry, "glock_c");

            -- Give the sentry a shield.
            GiveWeapon(sentry, "gshield");

            -- Have the sentry defend the Mauler.
            Defend2(sentry, mauler, 1);

            -- Send the Mauler after the player.
            Attack(mauler, GetPlayerHandle(1));
        end

        -- So we don't loop.
        Mission.m_MaulersSent = true;
    end

    -- This will run every 3 minutes.
    if (Mission.m_MissionTime % SecondsToTurns(180) == 0) then
        -- Grab the position of the player Recycler and send these units there.
        -- This will stop the chance of a unit stalling if their target is dead.
        local pos = GetPosition(Mission.m_Recycler);

        -- Rebuild the units as required, if they are not alive.
        if (IsAliveAndEnemy(Mission.m_Attack1, Mission.m_EnemyTeam) == false) then
            Mission.m_Attack1 = BuildObject("fvwalk_r", Mission.m_EnemyTeam, "attack1");

            -- Spawn a sentry to attack with the Maulers.
            local sentry = BuildObject("fvsent_r", Mission.m_EnemyTeam, GetPositionNear("attack1"));

            -- Give the sentry the EMP lock.
            GiveWeapon(sentry, "glock_c");

            -- Have the sentry defend the Mauler.
            Defend2(sentry, Mission.m_Attack1, 1);
        end

        if (IsAliveAndEnemy(Mission.m_Attack2, Mission.m_EnemyTeam) == false) then
            Mission.m_Attack2 = BuildObject("fvwalk_r", Mission.m_EnemyTeam, "attack2");

            -- Spawn a sentry to attack with the Maulers.
            local sentry = BuildObject("fvsent_r", Mission.m_EnemyTeam, GetPositionNear("attack2"));

            -- Give the sentry the EMP lock.
            GiveWeapon(sentry, "glock_c");

            -- Have the sentry defend the Mauler.
            Defend2(sentry, Mission.m_Attack2, 1);
        end

        if (IsAliveAndEnemy(Mission.m_Attack3, Mission.m_EnemyTeam) == false) then
            Mission.m_Attack3 = BuildObject("fvwalk_r", Mission.m_EnemyTeam, "attack3");

            -- Spawn a sentry to attack with the Maulers.
            local sentry = BuildObject("fvsent_r", Mission.m_EnemyTeam, GetPositionNear("attack3"));

            -- Give the sentry the EMP lock.
            GiveWeapon(sentry, "glock_c");

            -- Have the sentry defend the Mauler.
            Defend2(sentry, Mission.m_Attack3, 1);
        end

        if (IsAliveAndEnemy(Mission.m_Attack4, Mission.m_EnemyTeam) == false) then
            Mission.m_Attack4 = BuildObject("fvatank_r", Mission.m_EnemyTeam, "convoy1");
        end

        if (IsAliveAndEnemy(Mission.m_Attack5, Mission.m_EnemyTeam) == false) then
            Mission.m_Attack5 = BuildObject("fvatank_r", Mission.m_EnemyTeam, "convoy2");
        end

        if (IsAliveAndEnemy(Mission.m_Healer1, Mission.m_EnemyTeam) == false) then
            Mission.m_Healer1 = BuildObject("fvserv_r", Mission.m_EnemyTeam, GetPositionNear("convoy3", 25, 25));
        end

        if (IsAliveAndEnemy(Mission.m_Healer2, Mission.m_EnemyTeam) == false) then
            Mission.m_Healer2 = BuildObject("fvserv_r", Mission.m_EnemyTeam, GetPositionNear("convoy3", 25, 25));
        end

        -- Start up the attacks.
        Goto(Mission.m_Attack1, pos, 1);
        Goto(Mission.m_Attack2, pos, 1);
        Goto(Mission.m_Attack3, pos, 1);
        Goto(Mission.m_Attack4, pos, 1);
        Goto(Mission.m_Attack5, pos, 1);
    elseif (Mission.m_MissionTime % SecondsToTurns(300) == 0) then
        -- Grab the position of the player Recycler and send these units there.
        -- This will stop the chance of a unit stalling if their target is dead.
        local pos = GetPosition(Mission.m_Recycler);

        -- Send some scouts with arc and shield to attack as well.
        if (IsAliveAndEnemy(Mission.m_Attack2_1, Mission.m_EnemyTeam) == false) then
            -- Build the scout.
            Mission.m_Attack2_1 = BuildObject("fvscout_r", Mission.m_EnemyTeam, "attack1");

            -- Attack the player.
            Goto(Mission.m_Attack2_1, pos, 1);
        end

        if (IsAliveAndEnemy(Mission.m_Attack2_2, Mission.m_EnemyTeam) == false) then
            -- Build the scout.
            Mission.m_Attack2_2 = BuildObject("fvscout_r", Mission.m_EnemyTeam, "attack2");

            -- Attack the player.
            Goto(Mission.m_Attack2_2, pos, 1);
        end

        if (IsAliveAndEnemy(Mission.m_Attack2_3, Mission.m_EnemyTeam) == false) then
            -- Build the scout.
            Mission.m_Attack2_3 = BuildObject("fvscout_r", Mission.m_EnemyTeam, "attack3");

            -- Attack the player.
            Goto(Mission.m_Attack2_3, pos, 1);
        end

        -- Send some Lancers.
        if (IsAliveAndEnemy(Mission.m_Attack2_4, Mission.m_EnemyTeam) == false) then
            -- Build the scout.
            Mission.m_Attack2_4 = BuildObject("fvarch_r", Mission.m_EnemyTeam, "convoy1");

            -- Attack the player.
            Goto(Mission.m_Attack2_4, pos, 1);
        end

        if (IsAliveAndEnemy(Mission.m_Attack2_5, Mission.m_EnemyTeam) == false) then
            -- Build the scout.
            Mission.m_Attack2_5 = BuildObject("fvarch_r", Mission.m_EnemyTeam, "convoy2");

            -- Attack the player.
            Goto(Mission.m_Attack2_5, pos, 1);
        end

        if (IsAliveAndEnemy(Mission.m_Attack2_6, Mission.m_EnemyTeam) == false) then
            -- Build the scout.
            Mission.m_Attack2_6 = BuildObject("fvarch_r", Mission.m_EnemyTeam, "convoy3");

            -- Attack the player.
            Goto(Mission.m_Attack2_6, pos, 1);
        end
    end

    -- This will run for each healer.
    if (Mission.m_HealerCheckTimer < Mission.m_MissionTime) then
        if (IsAlive(Mission.m_Healer1)) then
            -- Check to see if the Titans are around.
            if (IsAliveAndEnemy(Mission.m_Attack4, Mission.m_EnemyTeam)) then
                Follow(Mission.m_Healer1, Mission.m_Attack4, 1);
            elseif (IsAliveAndEnemy(Mission.m_Attack5, Mission.m_EnemyTeam)) then
                Follow(Mission.m_Healer1, Mission.m_Attack5, 1);
            else
                -- Flee!!!!!!
                Goto(Mission.m_Healer1, "convoy3", 1);
            end
        end

        if (IsAlive(Mission.m_Healer2)) then
            -- Check to see if the Titans are around.
            if (IsAliveAndEnemy(Mission.m_Attack5, Mission.m_EnemyTeam)) then
                Follow(Mission.m_Healer2, Mission.m_Attack5, 1);
            elseif (IsAliveAndEnemy(Mission.m_Attack4, Mission.m_EnemyTeam)) then
                Follow(Mission.m_Healer2, Mission.m_Attack4, 1);
            else
                -- Flee!!!!!!
                Goto(Mission.m_Healer2, "convoy3", 1);
            end
        end

        -- Prepare the Healers.
        Mission.m_HealerCheckTimer = Mission.m_MissionTime + SecondsToTurns(2);
    end
end

function HandleFailureConditions()
    if (IsAlive(Mission.m_Recycler) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Show objectives.
        AddObjectiveOverride("isdf1605.otf", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Recycler was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf16l1.txt");
        end
    end
end
