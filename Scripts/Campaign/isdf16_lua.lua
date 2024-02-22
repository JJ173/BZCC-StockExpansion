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

    m_MapPatrolBots = {},

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

    m_Audioclip = nil,
    m_AudioTimer = 0,
    m_Condor1Time = 0,
    m_Condor2Time = 0,
    m_CondorRemoveTime = 15,

    m_ArteryBotDelayTime = 0,
    m_ArteryBotIterator = 0,

    m_TurretDistpacherTimer = 0,
    m_HealerCheckTimer = 0,
    m_MaulerTime = 0,

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
    -- Grab the ODF that's entered the world.
    local ODFName = GetCfg(h);
    -- Check the team of the handle.
    local teamNum = GetTeamNum(h);

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam or teamNum == 7) then
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
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        -- Always max our player units.
        SetSkill(h, 3);

        -- Testing.
        SetAvoidType(h, 1);
    end
end

function DeleteObject(h)
    if (h == Mission.m_Turret1) then
        Mission.m_Turret1 = nil;
    elseif (h == Mission.m_Turret2) then
        Mission.m_Turret2 = nil;
    elseif (h == Mission.m_Turret3) then
        Mission.m_Turret3 = nil;
    elseif (h == Mission.m_Turret4) then
        Mission.m_Turret4 = nil;
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
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1601.wav", false);

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
        local botCount = Mission.m_MissionDifficulty;

        -- Run a loop, spawn the bots, get them in formation, start patrol.
        for i = 1, botCount do
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
        -- Start up the attacks.
        Attack(Mission.m_Attack1, Mission.m_Recycler, 1);
        Attack(Mission.m_Attack2, Mission.m_Recycler, 1);
        Attack(Mission.m_Attack3, Mission.m_Recycler, 1);
        Attack(Mission.m_Attack4, Mission.m_Recycler, 1);
        Attack(Mission.m_Attack5, Mission.m_Recycler, 1);
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
                Goto(Mission.m_Healer1, "ScoutEnemy2", 1);
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
                Goto(Mission.m_Healer2, "ScoutEnemy2", 1);
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
