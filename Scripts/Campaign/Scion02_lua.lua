--[[
    BZCC Scion02 Lua Mission Script
    Written by AI_Unit
    Version 1.0 05-11-2023
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
local m_MissionName = "Scion02: Ambush";

-- Difficulty tables
local m_ScoutCooldownTimeTable = { 60, 45, 30 };

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
    m_PlayerRecycler = nil,
    m_AmbushJammer = nil,
    m_PlayerArchers = {},
    m_PlayerJammers = {},
    m_PlayerBuilders = {},
    m_EnemyRecycler = nil,
    m_EnemyPower1 = nil,
    m_EnemyPower2 = nil,
    m_EnemyCons = nil,
    m_EnemyTurret1 = nil,
    m_EnemyTurret2 = nil,
    m_EnemyTurret3 = nil,
    m_EnemyScout1 = nil,
    m_EnemyBaseUnit1 = nil,
    m_EnemyBaseUnit2 = nil,
    m_EnemyBaseUnit3 = nil,
    m_EnemyBaseUnit4 = nil,
    m_EnemyPatrol1 = nil,
    m_EnemyPatrol2 = nil,
    m_EnemyPatrol3 = nil,
    m_EnemyPatrol4 = nil,
    m_AmbushNav = nil,
    m_ArcherNav = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_ScoutRetreating = false,
    m_PlayerHasArcher = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_TurretDistpacherTimer = 0,
    m_ScoutDispatchCooldown = 0,

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
    local ODFName = GetCfg(h);
    local class = GetClassLabel(h);

    -- Handle unit skill for enemy.
    if (GetTeamNum(h) == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);

        if (ODFName == "ivturr_x") then
            -- Try and prevent the AIP from using it.
            SetIndependence(h, 1);

            -- Turret dispatcher needs to know of any turrets that are built.
            if (not IsAlive(Mission.m_EnemyTurret1)) then
                Mission.m_EnemyTurret1 = h;
            elseif (not IsAlive(Mission.m_EnemyTurret2)) then
                Mission.m_EnemyTurret2 = h;
            elseif (not IsAlive(Mission.m_EnemyTurret3)) then
                Mission.m_EnemyTurret3 = h;
            end
        elseif (ODFName == "ivscout_x") then
            -- Try and prevent the AIP from using it.
            SetIndependence(h, 1);

            -- So we can send it down a patrol path.
            Mission.m_EnemyScout1 = h;

            -- Repeat the retreat process.
            Mission.m_ScoutRetreating = false;

            -- Set a timer for dispatch.
            Mission.m_ScoutDispatchCooldown = Mission.m_MissionTime +
            SecondsToTurns(m_ScoutCooldownTimeTable[Mission.m_MissionDifficulty]);
        elseif (ODFName == "ibpgen_x" and Mission.m_MissionState > 9) then
            if (not IsAlive(Mission.m_EnemyPower1)) then
                -- Reassign the power variables for the last objective.
                Mission.m_EnemyPower1 = h;

                -- Highlight them as they need to be destroyed.
                SetObjectiveOn(h);
            elseif (not IsAlive(Mission.m_EnemyPower2)) then
                -- Reassign the power variables for the last objective.
                Mission.m_EnemyPower2 = h;

                -- Highlight them as they need to be destroyed.
                SetObjectiveOn(h);
            end
        end
    elseif (GetTeamNum(h) == Mission.m_HostTeam) then
        if (class == "CLASS_JAMMER") then
            -- Add to a table to keep track.
            Mission.m_PlayerJammers[#Mission.m_PlayerJammers + 1] = h;

            if (GetDistance(h, Mission.m_AmbushNav) < 100) then
                Mission.m_AmbushJammer = h;
            end
        elseif (class == "CLASS_ARTILLERY") then
            -- So that we know the player has an Archer.
            Mission.m_PlayerHasArcher = true;

            -- So we can keep track of all of them.
            Mission.m_PlayerArchers[#Mission.m_PlayerArchers + 1] = h;
        elseif (class == "CLASS_CONSTRUCTIONRIG") then
            -- So we can keep track of all of them.
            Mission.m_PlayerBuilders[#Mission.m_PlayerBuilders + 1] = h;
        end
    end
end

function DeleteObject(h)
    local ODFName = GetCfg(h);
    local class = GetClassLabel(h);

    if (GetTeamNum(h) == Mission.m_EnemyTeam) then
        -- Free up these variables for new turrets to use.
        if (ODFName == "ivturr_x") then
            if (h == Mission.m_EnemyTurret1) then
                Mission.m_EnemyTurret1 = nil;
            elseif (h == Mission.m_EnemyTurret2) then
                Mission.m_EnemyTurret2 = nil;
            elseif (h == Mission.m_EnemyTurret3) then
                Mission.m_EnemyTurret3 = nil;
            end
        elseif (ODFName == "ivscout_x") then
            Mission.m_EnemyScout1 = nil;
        elseif (ODFName == "ibpgen_x") then
            if (h == Mission.m_EnemyPower1) then
                Mission.m_EnemyPower1 = nil;
            elseif (h == Mission.m_EnemyPower2) then
                Mission.m_EnemyPower2 = nil;
            end
        end
    elseif (GetTeamNum(h) == Mission.m_HostTeam) then
        if (class == "CLASS_JAMMER") then
            TableRemoveByHandle(Mission.m_PlayerArchers, h);
        elseif (class == "CLASS_ARTILLERY") then
            TableRemoveByHandle(Mission.m_PlayerJammers, h);
        elseif (class == "CLASS_CONSTRUCTIONRIG") then
            TableRemoveByHandle(Mission.m_PlayerBuilders, h);
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
    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Get the main player
    Mission.m_MainPlayer = GetPlayerHandle(1);

    -- Start mission logic.
    if (not Mission.m_MissionOver) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Check failure conditions...
            HandleFailureConditions();

            -- Set the scouts up.
            if (Mission.m_MissionState <= 4) then
                -- Set the turrets up.
                ISDFTurretDispatcher();
                ISDFScoutDistpatcher();
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
    if (Mission.m_MissionDifficulty > 1) then
        if (GetCfg(VictimHandle) == "ivturr_x" and OrdnanceTeam ~= Mission.m_EnemyTeam) then
            if (GetCurrentCommand(VictimHandle) ~= CMD_DEFEND) then
                Defend(VictimHandle);
            end
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

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Grab any important pre-placed objects.
    Mission.m_EnemyPower1 = GetHandle("power1");
    Mission.m_EnemyPower2 = GetHandle("power2");
    Mission.m_EnemyRecycler = GetHandle("EnemyRecycler");
    Mission.m_PlayerRecycler = GetHandle("unnamed_fvrecy_x");
    Mission.m_EnemyCons = GetHandle("unnamed_ivcons_x");

    -- Prep the base defenders.
    Mission.m_EnemyBaseUnit1 = BuildObject("ivtas2_x", Mission.m_EnemyTeam, "defend1");
    Mission.m_EnemyBaseUnit2 = BuildObject("ivmisl_x", Mission.m_EnemyTeam, "defend1");
    Mission.m_EnemyBaseUnit3 = BuildObject("ivtas2_x", Mission.m_EnemyTeam, "defend1");
    Mission.m_EnemyBaseUnit4 = BuildObject("ivscos2_x", Mission.m_EnemyTeam, "defend1");

    -- Prep the patrols
    Mission.m_EnemyPatrol1 = BuildObject("ivtas2_x", Mission.m_EnemyTeam, "patrol_1_spawn");
    Mission.m_EnemyPatrol2 = BuildObject("ivscos2_x", Mission.m_EnemyTeam, "patrol_2_spawn");
    Mission.m_EnemyPatrol3 = BuildObject("ivtas2_x", Mission.m_EnemyTeam, "patrol_3_spawn");
    Mission.m_EnemyPatrol4 = BuildObject("ivscos2_x", Mission.m_EnemyTeam, "patrol_4_spawn");

    -- Give the player some scrap.
    SetScrap(Mission.m_HostTeam, 40);

    -- Give the enemy some scrap.
    SetScrap(Mission.m_EnemyTeam, 40);

    -- Spawn starting units for the player.
    if (Mission.m_MissionDifficulty <= 3) then
        -- Give 1 Scavenger and 1 turret
        SetBestGroup(BuildObject("fvscav_x", Mission.m_HostTeam, "scav_1"));
        SetBestGroup(BuildObject("fvturr_x", Mission.m_HostTeam, "turret_1"));

        -- For medium, give another turret and a warrior.
        if (Mission.m_MissionDifficulty <= 2) then
            SetBestGroup(BuildObject("fvturr_x", Mission.m_HostTeam, "turret_2"));
            SetBestGroup(BuildObject("fvtank_x", Mission.m_HostTeam, "tank_1"));

            -- For easy, give the rest of the expected units.
            if (Mission.m_MissionDifficulty <= 1) then
                SetBestGroup(BuildObject("fvscav_x", Mission.m_HostTeam, "scav_2"));
                SetBestGroup(BuildObject("fvtank_x", Mission.m_HostTeam, "tank_2"));
            end
        end
    end

    -- Set the enemy AIP plan.
    SetAIP("scion0201.aip", Mission.m_EnemyTeam);

    -- Assign orders of enemy units.
    Patrol(Mission.m_EnemyPatrol1, "isdf_patrol1", 1);
    Patrol(Mission.m_EnemyPatrol2, "isdf_patrol1", 1);
    Patrol(Mission.m_EnemyPatrol3, "isdf_patrol2", 1);
    Patrol(Mission.m_EnemyPatrol4, "isdf_patrol2", 1);

    -- Set up the base defences.
    Patrol(Mission.m_EnemyBaseUnit1, "defend_patrol", 1);
    Follow(Mission.m_EnemyBaseUnit2, Mission.m_EnemyBaseUnit1, 1);
    Defend2(Mission.m_EnemyBaseUnit3, Mission.m_EnemyCons, 1);

    -- Set up the ambush nav.
    Mission.m_AmbushNav = BuildObject("ibnav", Mission.m_HostTeam, "Ambush");

    -- Set the name of the nav.
    SetObjectiveName(Mission.m_AmbushNav, "Ambush");

    -- Shab: "The ISDF have built a base..."
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0201.wav");

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(18.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "The ISDF have built a base..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0202.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

        -- Objectives.
        AddObjectiveOverride("scion0201.otf", "WHITE", 10, true);

        -- Highlight
        SetObjectiveOn(Mission.m_AmbushNav);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (IsPlayerWithinDistance("Ambush", 75, _Cooperative.m_TotalPlayerCount) and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: This is the ambush site.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0203.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Objectives.
        AddObjectiveOverride("scion0202.otf", "WHITE", 10, true);
        AddObjective("scion0203.otf", "WHITE");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    -- Need to run a check to see if any of the units near is a builder from the player.
    for i = 1, #Mission.m_PlayerBuilders do
        local builder = Mission.m_PlayerBuilders[i];
        local dist = GetDistance(builder, Mission.m_AmbushNav);

        if (IsAlive(builder) and dist < 75) then
            -- Shab: Good job. Now build the Jammer.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0204.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(12.5);

            -- Show objectives.
            AddObjectiveOverride("scion0202.otf", "GREEN", 5, true);
            AddObjective("scion0203.otf", "WHITE");

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[5] = function()
    if (IsAlive(Mission.m_AmbushJammer)) then
        -- Shab: Now comes the tricky part...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0205.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

        -- Show objectives.
        AddObjectiveOverride("scion0204.otf", "WHITE", 5, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    -- Run a set of distance checks for the player.
    local check1 = IsPlayerWithinDistance(Mission.m_EnemyBaseUnit1, 200, _Cooperative.m_TotalPlayerCount);
    local check2 = IsPlayerWithinDistance(Mission.m_EnemyBaseUnit2, 200, _Cooperative.m_TotalPlayerCount);
    local check3 = IsPlayerWithinDistance(Mission.m_EnemyBaseUnit3, 200, _Cooperative.m_TotalPlayerCount);
    local check4 = IsPlayerWithinDistance(Mission.m_EnemyBaseUnit4, 200, _Cooperative.m_TotalPlayerCount);
    local check5 = IsPlayerWithinDistance(Mission.m_EnemyPatrol1, 75, _Cooperative.m_TotalPlayerCount);
    local check6 = IsPlayerWithinDistance(Mission.m_EnemyPatrol2, 75, _Cooperative.m_TotalPlayerCount);

    -- If the player is within any of the distances provided, advance the mission state.
    if ((check1 or check2 or check3 or check4) or (check5 or check6)) then
        -- Shab: They have you in pursuit.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0206.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Send all units to attack.
        Goto(Mission.m_EnemyBaseUnit1, "Ambush", 1);
        Goto(Mission.m_EnemyBaseUnit2, "Ambush", 1);
        Goto(Mission.m_EnemyBaseUnit3, "Ambush", 1);
        Goto(Mission.m_EnemyBaseUnit4, "Ambush", 1);
        Attack(Mission.m_EnemyPatrol1, Mission.m_MainPlayer, 1);
        Attack(Mission.m_EnemyPatrol2, Mission.m_MainPlayer, 1);

        -- Set the base to full alert.
        SetAIP("scion0202.aip", Mission.m_EnemyTeam);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    -- If all base patrols have been eliminated.
    if (not IsAlive(Mission.m_EnemyBaseUnit1) and not IsAlive(Mission.m_EnemyBaseUnit2) and not IsAlive(Mission.m_EnemyBaseUnit3) and not IsAlive(Mission.m_EnemyBaseUnit4)) then
        -- Shab: Now we are going to use artillery.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0207.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- Remove the highlight from the Ambush nav.
        SetObjectiveOff(Mission.m_AmbushNav);

        -- Add Archer Objective.
        AddObjectiveOverride("scion0205.otf", "WHITE", 10, true);

        -- Create a nav point for the objective.
        Mission.m_ArcherNav = BuildObject("ibnav", Mission.m_HostTeam, "archer_point");

        -- Name and highlight.
        SetObjectiveName(Mission.m_ArcherNav, "Artillery");
        SetObjectiveOn(Mission.m_ArcherNav);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (Mission.m_PlayerHasArcher) then
        -- Shab: Now that you have your Artillery...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0208.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Mark the last objective as done.
        AddObjectiveOverride("scion0205.otf", "GREEN", 10, true);
        AddObjective("scion0209.otf", "WHITE");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    -- If at least 1 Archer has been moved to the nav, mark this function as done.
    for i = 1, #Mission.m_PlayerArchers do
        if (GetDistance(Mission.m_PlayerArchers[i], Mission.m_ArcherNav) < 50) then
            -- Mark the last objective as done.
            AddObjectiveOverride("scion0206.otf", "WHITE", 10, true);

            -- Shab: Attack the enemy power, be prepared to defend.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0209.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

            -- Mark the enemy Power Supply.
            SetObjectiveOn(Mission.m_EnemyPower1);
            SetObjectiveOn(Mission.m_EnemyPower2);

            -- Mark enemy constructor as well
            SetObjectiveOn(Mission.m_EnemyCons);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[10] = function()
    -- Player has destroyed the power generators.
    if (not IsAlive(Mission.m_EnemyPower1) and not IsAlive(Mission.m_EnemyPower2) and not IsAlive(Mission.m_EnemyCons)) then
        -- Shab: Gun Towers are down.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0210.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    -- If the player is in the base, then we have captured it.
    if (IsPlayerWithinDistance(Mission.m_EnemyRecycler, 75, _Cooperative.m_TotalPlayerCount)) then
        -- Shab: The base is ours!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0211.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    -- Game over.
    if (Mission.m_IsCooperativeMode) then
        NoteGameoverWithCustomMessage("Mission Accomplished.");
        DoGameover(10);
    else
        SucceedMission(GetTime() + 10, "scion02w1.txt");
    end
end

-- This function will dispatch enemy turrets around the map. If a turret
-- is destroyed, we will replenish it with another.
function ISDFTurretDispatcher()
    if (Mission.m_TurretDistpacherTimer < Mission.m_MissionTime) then
        if (IsAliveAndEnemy(Mission.m_EnemyTurret1, Mission.m_EnemyTeam) and GetDistance(Mission.m_EnemyTurret1, "TurretEnemy1") > 30 and GetCurrentCommand(Mission.m_EnemyTurret1) ~= CMD_DEFEND) then
            Goto(Mission.m_EnemyTurret1, "TurretEnemy1", 1);
        end

        if (IsAliveAndEnemy(Mission.m_EnemyTurret2, Mission.m_EnemyTeam) and GetDistance(Mission.m_EnemyTurret2, "TurretEnemy2") > 30 and GetCurrentCommand(Mission.m_EnemyTurret2) ~= CMD_DEFEND) then
            Goto(Mission.m_EnemyTurret2, "TurretEnemy2", 1);
        end

        if (IsAliveAndEnemy(Mission.m_EnemyTurret3, Mission.m_EnemyTeam) and GetDistance(Mission.m_EnemyTurret3, "TurretEnemy3") > 30 and GetCurrentCommand(Mission.m_EnemyTurret3) ~= CMD_DEFEND) then
            Goto(Mission.m_EnemyTurret3, "TurretEnemy3", 1);
        end

        -- To delay loops.
        Mission.m_TurretDistpacherTimer = Mission.m_MissionTime + SecondsToTurns(1.5);
    end
end

-- Handles the path choosing and scout logic for the ISDF.
function ISDFScoutDistpatcher()
    if (IsAlive(Mission.m_EnemyScout1) and Mission.m_ScoutDispatchCooldown < Mission.m_MissionTime) then
        if (not Mission.m_ScoutRetreating) then
            -- Check if the Scout gets shot
            local unitWhoShotTeam = GetTeamNum(GetWhoShotMe(Mission.m_EnemyScout1));

            if (GetCurrentCommand(Mission.m_EnemyScout1) == CMD_NONE) then
                -- Send the scout out to do it's job.
                local rand = math.ceil(GetRandomFloat(0, 2));
                local chosenPath = "route" .. rand;

                -- Send the Scout down one of the 2 paths.
                Goto(Mission.m_EnemyScout1, chosenPath, 1);
            elseif (GetDistance(Mission.m_EnemyScout1, "tank_1") < 175 or (unitWhoShotTeam > 0 and unitWhoShotTeam < Mission.m_EnemyTeam)) then
                if (DoesBaseJammerExist()) then
                    -- Tell it to retreat.
                    Retreat(Mission.m_EnemyScout1, GetPosition(Mission.m_EnemyRecycler), 1);

                    -- Highlight it.
                    SetObjectiveOn(Mission.m_EnemyScout1);

                    -- Shab: An ISDF scout has found our base.
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0212.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

                    -- Set it to retreat to the base
                    Mission.m_ScoutRetreating = true;
                else
                    PlayerDetected();
                end
            end
        elseif (GetDistance(Mission.m_EnemyScout1, Mission.m_EnemyRecycler) < 75) then
            PlayerDetected();
        end
    end
end

-- Run this to fail the mission if the player is detected.
function PlayerDetected()
    -- Mission failed.
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0220.wav");

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

    -- Stop the mission.
    Mission.m_MissionOver = true;

    -- Failure.
    if (Mission.m_IsCooperativeMode) then
        NoteGameoverWithCustomMessage("You were discovered!");
        DoGameover(10);
    else
        FailMission(GetTime() + 10);
    end
end

-- Run a distance check to make sure a Jammer exists near the player Recycler
function DoesBaseJammerExist()
    for i = 1, #Mission.m_PlayerJammers do
        if (GetDistance(Mission.m_PlayerJammers[i], Mission.m_PlayerRecycler) < 300) then
            return true;
        end
    end

    -- If the loop doesn't find any, return false.
    return false;
end

-- Checks for failure conditions.
function HandleFailureConditions()
    -- Player goes into ISDF base before Jammer is ready, fail.
    if (Mission.m_MissionState <= 4) then
        local dist1 = IsPlayerWithinDistance(Mission.m_EnemyRecycler, 200, _Cooperative.m_TotalPlayerCount);
        local dist2 = IsPlayerWithinDistance(Mission.m_EnemyPatrol1, 75, _Cooperative.m_TotalPlayerCount);
        local dist3 = IsPlayerWithinDistance(Mission.m_EnemyPatrol2, 75, _Cooperative.m_TotalPlayerCount);
        local dist4 = IsPlayerWithinDistance(Mission.m_EnemyPatrol3, 75, _Cooperative.m_TotalPlayerCount);
        local dist5 = IsPlayerWithinDistance(Mission.m_EnemyPatrol4, 75, _Cooperative.m_TotalPlayerCount);

        -- Player shouldn't be near any of these until later.
        if (dist1 or dist2 or dist3 or dist4 or dist5) then
            PlayerDetected();
        end
    end

    if (not IsAlive(Mission.m_EnemyRecycler)) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Show failure objective.
        AddObjectiveOverride("scion02l2.txt", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Enemy Recycler was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "scion02l2.txt");
        end
    end

    if (not IsAlive(Mission.m_PlayerRecycler)) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Show failure objective.
        AddObjectiveOverride("scion02l1.txt", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Matriarch was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "scion02l1.txt");
        end
    end
end
