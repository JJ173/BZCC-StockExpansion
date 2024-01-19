--[[
    BZCC ISDF20 Lua Mission Script
    Written by AI_Unit
    Version 1.0 29-12-2023
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
local m_MissionName = "ISDF20: A Traitor's Fate";

-- Choose a couple of vehilces to attack the player.
local m_MansonUnits = { "ivscout_x", "ivmisl_x", "ivtank_x" };

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
    m_PlayerShipODF = "ivwalk_x",

    m_PGen1 = nil,
    m_PGen2 = nil,
    m_Gun1 = nil,
    m_Gun2 = nil,
    m_Gun3 = nil,
    m_Recycler = nil,
    m_Factory = nil,
    m_Bunker = nil,
    m_Armory = nil,
    m_Unit1 = nil,
    m_Unit2 = nil,
    m_Unit3 = nil,
    m_Unit4 = nil,
    m_MBike1 = nil,
    m_MBike2 = nil,
    m_MBike3 = nil,
    m_PlayerUnit1 = nil,
    m_PlayerUnit2 = nil,
    m_PlayerTruck1 = nil,
    m_PlayerTruck2 = nil,
    m_Nav1 = nil,
    m_Nav2 = nil,
    m_RebelBaseGuard1 = nil,
    m_RebelBaseGuard2 = nil,
    m_Rebel1 = nil,
    m_Rebel2 = nil,
    m_Rebel3 = nil,
    m_Rebel4 = nil,
    m_Rebel5 = nil,
    m_Rebel6 = nil,
    m_Rebel7 = nil,
    m_Rebel8 = nil,
    m_Rebel9 = nil,
    m_Manson = nil,

    m_RebelBrainTracker = {},

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_FactoryDead = false,
    m_Power1Dead = false,
    m_Power2Dead = false,
    m_BunkerDead = false,
    m_ArmoryDead = false,
    m_RecyclerDead = false,
    m_SeenManson = false,
    m_BaseGuardsAttack = false,

    m_BriefingTime = 0,
    m_AmbushDelay = 0,
    m_AmbushNoticeDelay = 0,

    m_Audioclip = nil,
    m_AudioTimer = 0,

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
    local team = GetTeamNum(h);

    -- Handle unit skill for enemy.
    if (team == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);
    elseif (team == Mission.m_AlliedTeam) then
        -- Check if they are pilots. If so, we can order them back to the drop-site.
        if (GetClassLabel(h) == "CLASS_PERSON") then
            -- Remove their AI independence.
            SetIndependence(h, 0);

            -- Move them back to the drop-site.
            Retreat(h, "homebase", 1)
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

    -- Start mission logic.
    if (not Mission.m_MissionOver) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Handle the brain for the rebel units.
            RebelBrain();
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
    if (OrdnanceTeam < 6 and Mission.m_BaseGuardsAttack == false) then
        if (VictimHandle == Mission.m_Factory
                or VictimHandle == Mission.m_PGen1
                or VictimHandle == Mission.m_PGen2
                or VictimHandle == Mission.m_Gun2
                or VictimHandle == Mission.m_Gun3
                or VictimHandle == Mission.m_Bunker
                or VictimHandle == Mission.m_Recycler
                or VictimHandle == Mission.m_Armory) then
            -- Have the base guards attack.
            Attack(Mission.m_RebelBaseGuard1, ShooterHandle, 1);
            Attack(Mission.m_RebelBaseGuard2, ShooterHandle, 1);

            -- So we don't loop.
            Mission.m_BaseGuardsAttack = true;
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Rebels");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Set Manson's team to blue.
    SetTeamColor(Mission.m_EnemyTeam, 0, 127, 255);

    -- Get Manson's base.
    Mission.m_PGen1 = GetHandle("pgen1");
    Mission.m_PGen2 = GetHandle("pgen2");
    Mission.m_Bunker = GetHandle("bunker");
    Mission.m_Factory = GetHandle("factory");
    Mission.m_Gun1 = GetHandle("gun1");
    Mission.m_Gun2 = GetHandle("gun2");
    Mission.m_Gun3 = GetHandle("gun3");
    Mission.m_Recycler = GetHandle("recycler");
    Mission.m_Armory = GetHandle("armory");

    -- Make the Gun Towers do something.
    Stop(Mission.m_Gun1, 0);
    Stop(Mission.m_Gun2, 0);
    Stop(Mission.m_Gun3, 0);

    -- Prepare out units
    Mission.m_MBike1 = BuildObject("ivtank_x", Mission.m_AlliedTeam, "mbike1");
    Mission.m_MBike2 = BuildObject("ivmisl_x", Mission.m_AlliedTeam, "mbike2");
    Mission.m_MBike3 = BuildObject("ivmisl_x", Mission.m_AlliedTeam, "mbike3");

    -- Give them high skill.
    SetSkill(Mission.m_MBike1, 3);
    SetSkill(Mission.m_MBike2, 3);
    SetSkill(Mission.m_MBike3, 3);

    -- Build Player Units.
    Mission.m_PlayerUnit1 = BuildObject("ivatank_x", Mission.m_HostTeam, "tank1");
    Mission.m_PlayerUnit2 = BuildObject("ivrckt_x", Mission.m_HostTeam, "tank2");
    Mission.m_PlayerTruck1 = BuildObject("ivserv_x", Mission.m_HostTeam, "scav1");
    Mission.m_PlayerTruck2 = BuildObject("ivserv_x", Mission.m_HostTeam, "scav2");

    -- Set groups.
    SetGroup(Mission.m_PlayerUnit1, 0);
    SetGroup(Mission.m_PlayerUnit2, 1);
    SetGroup(Mission.m_PlayerTruck1, 2);
    SetGroup(Mission.m_PlayerTruck2, 2);

    -- Build Manson's Patrols.
    Mission.m_Rebel1 = BuildObject("ivmisl_x", Mission.m_EnemyTeam, "esentpath1");
    Mission.m_Rebel2 = BuildObject("ivmisl_x", Mission.m_EnemyTeam, "esentpath1");

    -- Have them patrol.
    Patrol(Mission.m_Rebel1, "esentpath1");
    Follow(Mission.m_Rebel2, Mission.m_Rebel1);

    -- Build the base guards.
    Mission.m_RebelBaseGuard1 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "esent3");
    Mission.m_RebelBaseGuard2 = BuildObject("ivscout_x", Mission.m_EnemyTeam, "esent4");

    -- Set the defenders to hold position so the AIP doesn't nab them.
    Defend(Mission.m_RebelBaseGuard1, 1);
    Defend(Mission.m_RebelBaseGuard2, 1);

    -- Place our nav in the enemy base.
    Mission.m_Nav1 = BuildObject("ibnav", Mission.m_HostTeam, "lung2");

    -- Timer!
    Mission.m_BriefingTime = Mission.m_MissionTime + SecondsToTurns(20);

    -- Name it.
    SetObjectiveName(Mission.m_Nav1, "Rebel Base");

    -- Highlight it.
    SetObjectiveOn(Mission.m_Nav1);

    -- Add objectives.
    AddObjectiveOverride("isdf20a.otf", "WHITE", 10, true);

    -- Prepare the Camera for a cutscene.
    if (Mission.m_IsCooperativeMode == false) then
        CameraReady();
    end

    -- Braddock: "Manson! Stand down!"
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2021.wav");
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_IsCooperativeMode == false) then
        CameraPath("camera1", 800, 200, GetPlayerHandle(1));
    end

    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Manson: "Save it. I was with you for a while..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2022.wav");
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Give Manson some Scrap.
        SetScrap(Mission.m_EnemyTeam, 40);

        -- Give Manson his AIP.
        SetAIP("isdf2001_x.aip", Mission.m_EnemyTeam);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (Mission.m_IsCooperativeMode == false) then
        CameraPath("camera2", 800, 200, Mission.m_Recycler);
    end

    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock "Very well. Cooke, destroy the rebel base."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2001.wav");
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- Remove the cutscene camera.
        if (Mission.m_IsCooperativeMode == false) then
            CameraFinish();
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    if (Mission.m_BriefingTime < Mission.m_MissionTime) then
        -- Move the AI Squad.
        Goto(Mission.m_MBike1, "front_ambush", 1);
        Goto(Mission.m_MBike2, "front_ambush", 1);
        Goto(Mission.m_MBike3, "front_ambush", 1);

        -- Build and send them after the player.
        Mission.m_Rebel3 = BuildObject(m_MansonUnits[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
            GetPositionNear("lung2", 20, 20));
        Mission.m_Rebel4 = BuildObject(m_MansonUnits[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
            GetPositionNear("lung2", 20, 20));

        Attack(Mission.m_Rebel3, GetPlayerHandle(1), 1);
        Attack(Mission.m_Rebel4, GetPlayerHandle(1), 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    local check1 = IsPlayerWithinDistance("front_ambush", 200, _Cooperative.m_TotalPlayerCount);
    local check2 = GetDistance(Mission.m_PlayerUnit1, "front_ambush") < 200;
    local check3 = GetDistance(Mission.m_PlayerUnit2, "front_ambush") < 200;

    -- This checks to see if the player is near the front ambush path.
    if (check1 or check2 or check3) then
        -- Have Squad 2 attack.
        Attack(Mission.m_MBike1, Mission.m_Rebel1);
        Attack(Mission.m_MBike2, Mission.m_Rebel2);
        Attack(Mission.m_MBike3, Mission.m_Rebel1);

        -- Check to see if the first two patrols are dead and then move on.
        if (IsAlive(Mission.m_Rebel1) == false and IsAlive(Mission.m_Rebel2) == false) then
            -- Move the AI squad.
            Goto(Mission.m_MBike1, "front_ambush", 1);
            Goto(Mission.m_MBike2, "front_ambush", 1);
            Goto(Mission.m_MBike3, "front_ambush", 1);

            -- Create a new attacker.
            local unit1 = BuildObject("ivscout_x", Mission.m_EnemyTeam, GetPositionNear("lung2", 25, 25));
            local unit2 = BuildObject("ivscout_x", Mission.m_EnemyTeam, GetPositionNear("lung2", 25, 25));

            if (IsAlive(Mission.m_PlayerTruck1)) then
                Attack(unit1, Mission.m_PlayerTruck1, 1);
            else
                Attack(unit1, GetPlayerHandle(1), 1);
            end

            if (IsAlive(Mission.m_PlayerTruck2)) then
                Attack(unit2, Mission.m_PlayerTruck2, 1);
            else
                Attack(unit2, GetPlayerHandle(1), 1);
            end

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[6] = function()
    local check1 = IsPlayerWithinDistance("front_ambush", 75, _Cooperative.m_TotalPlayerCount);
    local check2 = GetDistance(Mission.m_PlayerUnit1, "front_ambush") < 75;
    local check3 = GetDistance(Mission.m_PlayerUnit2, "front_ambush") < 75;

    -- This checks to see if the player is near the front ambush path.
    if (check1 or check2 or check3) then
        local unit1 = BuildObject(m_MansonUnits[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
            GetPositionNear("lung2", 20, 20));
        local unit2 = BuildObject(m_MansonUnits[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
            GetPositionNear("lung2", 25, 25));

        Attack(unit1, GetPlayerHandle(1), 1);
        Attack(unit2, GetPlayerHandle(1), 1);

        -- Braddock: "Major, use your Assault Tank to kill that Gun Tower".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2002.wav");
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Show objectives.
        AddObjectiveOverride("isdf2002.otf", "WHITE", 10, true);

        -- Highlight the Gun Tower.
        SetObjectiveOn(Mission.m_Gun1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    -- When the Gun Tower is dead, send the AI off-map.
    if (IsAlive(Mission.m_Gun1) == false) then
        -- Move the AI squad.
        Goto(Mission.m_MBike1, "exit1", 1);
        Goto(Mission.m_MBike2, "exit1", 1);
        Goto(Mission.m_MBike3, "exit1", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    local check1 = IsPlayerWithinDistance("exit1", 50, _Cooperative.m_TotalPlayerCount);
    local check2 = GetDistance(Mission.m_PlayerUnit1, "exit1") < 50;
    local check3 = GetDistance(Mission.m_PlayerUnit2, "exit1") < 50;

    if (check1 or check2 or check3) then
        -- Braddock: "Major, use your Assault Tank to kill that Gun Tower".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2003.wav");
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

        -- Show objectives.
        AddObjectiveOverride("isdf2003.otf", "WHITE", 10, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    -- This checks that the enemy Gun Tower is dead before moving on.
    if (IsAlive(Mission.m_Gun2) == false and IsAlive(Mission.m_Gun3) == false) then
        -- Have Squad 2 attack.
        Attack(Mission.m_MBike1, Mission.m_Factory);
        Attack(Mission.m_MBike2, Mission.m_Factory);
        Attack(Mission.m_MBike3, Mission.m_Factory);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[10] = function()
    -- This runs to see when all relevant base components are dead.
    if (IsAlive(Mission.m_Factory) == false and Mission.m_FactoryDead == false) then
        -- Pilot: "Well, this is easy..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2004.wav");
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Have the AI attack the next structure.
        if (IsAlive(Mission.m_PGen1)) then
            Attack(Mission.m_MBike1, Mission.m_PGen1);
            Attack(Mission.m_MBike2, Mission.m_PGen1);
            Attack(Mission.m_MBike3, Mission.m_PGen1);
        elseif (IsAlive(Mission.m_PGen2)) then
            Attack(Mission.m_MBike1, Mission.m_PGen2);
            Attack(Mission.m_MBike2, Mission.m_PGen2);
            Attack(Mission.m_MBike3, Mission.m_PGen2);
        elseif (IsAlive(Mission.m_Bunker)) then
            Attack(Mission.m_MBike1, Mission.m_Bunker);
            Attack(Mission.m_MBike2, Mission.m_Bunker);
            Attack(Mission.m_MBike3, Mission.m_Bunker);
        elseif (IsAlive(Mission.m_Recycler)) then
            Attack(Mission.m_MBike1, Mission.m_Recycler);
            Attack(Mission.m_MBike2, Mission.m_Recycler);
            Attack(Mission.m_MBike3, Mission.m_Recycler);
        elseif (IsAlive(Mission.m_Armory)) then
            Attack(Mission.m_MBike1, Mission.m_Armory);
            Attack(Mission.m_MBike2, Mission.m_Armory);
            Attack(Mission.m_MBike3, Mission.m_Armory);
        end

        -- So we don't loop.
        Mission.m_FactoryDead = true;
    end

    if (IsAlive(Mission.m_PGen1) == false and Mission.m_Power1Dead == false) then
        -- Have the AI attack the next structure.
        if (IsAlive(Mission.m_Factory)) then
            Attack(Mission.m_MBike1, Mission.m_Factory);
            Attack(Mission.m_MBike2, Mission.m_Factory);
            Attack(Mission.m_MBike3, Mission.m_Factory);
        elseif (IsAlive(Mission.m_PGen2)) then
            Attack(Mission.m_MBike1, Mission.m_PGen2);
            Attack(Mission.m_MBike2, Mission.m_PGen2);
            Attack(Mission.m_MBike3, Mission.m_PGen2);
        elseif (IsAlive(Mission.m_Bunker)) then
            Attack(Mission.m_MBike1, Mission.m_Bunker);
            Attack(Mission.m_MBike2, Mission.m_Bunker);
            Attack(Mission.m_MBike3, Mission.m_Bunker);
        elseif (IsAlive(Mission.m_Recycler)) then
            Attack(Mission.m_MBike1, Mission.m_Recycler);
            Attack(Mission.m_MBike2, Mission.m_Recycler);
            Attack(Mission.m_MBike3, Mission.m_Recycler);
        elseif (IsAlive(Mission.m_Armory)) then
            Attack(Mission.m_MBike1, Mission.m_Armory);
            Attack(Mission.m_MBike2, Mission.m_Armory);
            Attack(Mission.m_MBike3, Mission.m_Armory);
        end

        -- So we don't loop.
        Mission.m_Power1Dead = true;
    end

    if (IsAlive(Mission.m_PGen2) == false and Mission.m_Power2Dead == false) then
        -- Have the AI attack the next structure.
        if (IsAlive(Mission.m_Factory)) then
            Attack(Mission.m_MBike1, Mission.m_Factory);
            Attack(Mission.m_MBike2, Mission.m_Factory);
            Attack(Mission.m_MBike3, Mission.m_Factory);
        elseif (IsAlive(Mission.m_PGen1)) then
            Attack(Mission.m_MBike1, Mission.m_PGen1);
            Attack(Mission.m_MBike2, Mission.m_PGen1);
            Attack(Mission.m_MBike3, Mission.m_PGen1);
        elseif (IsAlive(Mission.m_Bunker)) then
            Attack(Mission.m_MBike1, Mission.m_Bunker);
            Attack(Mission.m_MBike2, Mission.m_Bunker);
            Attack(Mission.m_MBike3, Mission.m_Bunker);
        elseif (IsAlive(Mission.m_Recycler)) then
            Attack(Mission.m_MBike1, Mission.m_Recycler);
            Attack(Mission.m_MBike2, Mission.m_Recycler);
            Attack(Mission.m_MBike3, Mission.m_Recycler);
        elseif (IsAlive(Mission.m_Armory)) then
            Attack(Mission.m_MBike1, Mission.m_Armory);
            Attack(Mission.m_MBike2, Mission.m_Armory);
            Attack(Mission.m_MBike3, Mission.m_Armory);
        end

        -- So we don't loop.
        Mission.m_Power2Dead = true;
    end

    if (IsAlive(Mission.m_Bunker) == false and Mission.m_BunkerDead == false) then
        -- Have the AI attack the next structure.
        if (IsAlive(Mission.m_Factory)) then
            Attack(Mission.m_MBike1, Mission.m_Factory);
            Attack(Mission.m_MBike2, Mission.m_Factory);
            Attack(Mission.m_MBike3, Mission.m_Factory);
        elseif (IsAlive(Mission.m_PGen1)) then
            Attack(Mission.m_MBike1, Mission.m_PGen1);
            Attack(Mission.m_MBike2, Mission.m_PGen1);
            Attack(Mission.m_MBike3, Mission.m_PGen1);
        elseif (IsAlive(Mission.m_PGen2)) then
            Attack(Mission.m_MBike1, Mission.m_PGen2);
            Attack(Mission.m_MBike2, Mission.m_PGen2);
            Attack(Mission.m_MBike3, Mission.m_PGen2);
        elseif (IsAlive(Mission.m_Recycler)) then
            Attack(Mission.m_MBike1, Mission.m_Recycler);
            Attack(Mission.m_MBike2, Mission.m_Recycler);
            Attack(Mission.m_MBike3, Mission.m_Recycler);
        elseif (IsAlive(Mission.m_Armory)) then
            Attack(Mission.m_MBike1, Mission.m_Armory);
            Attack(Mission.m_MBike2, Mission.m_Armory);
            Attack(Mission.m_MBike3, Mission.m_Armory);
        end

        -- So we don't loop.
        Mission.m_BunkerDead = true;
    end

    if (IsAlive(Mission.m_Recycler) == false and Mission.m_RecyclerDead == false) then
        -- Have the AI attack the next structure.
        if (IsAlive(Mission.m_Factory)) then
            Attack(Mission.m_MBike1, Mission.m_Factory);
            Attack(Mission.m_MBike2, Mission.m_Factory);
            Attack(Mission.m_MBike3, Mission.m_Factory);
        elseif (IsAlive(Mission.m_PGen1)) then
            Attack(Mission.m_MBike1, Mission.m_PGen1);
            Attack(Mission.m_MBike2, Mission.m_PGen1);
            Attack(Mission.m_MBike3, Mission.m_PGen1);
        elseif (IsAlive(Mission.m_PGen2)) then
            Attack(Mission.m_MBike1, Mission.m_PGen2);
            Attack(Mission.m_MBike2, Mission.m_PGen2);
            Attack(Mission.m_MBike3, Mission.m_PGen2);
        elseif (IsAlive(Mission.m_Bunker)) then
            Attack(Mission.m_MBike1, Mission.m_Bunker);
            Attack(Mission.m_MBike2, Mission.m_Bunker);
            Attack(Mission.m_MBike3, Mission.m_Bunker);
        elseif (IsAlive(Mission.m_Armory)) then
            Attack(Mission.m_MBike1, Mission.m_Armory);
            Attack(Mission.m_MBike2, Mission.m_Armory);
            Attack(Mission.m_MBike3, Mission.m_Armory);
        end

        -- So we don't loop.
        Mission.m_RecyclerDead = true;
    end

    if (IsAlive(Mission.m_Armory) == false and Mission.m_ArmoryDead == false) then
        -- Have the AI attack the next structure.
        if (IsAlive(Mission.m_Factory)) then
            Attack(Mission.m_MBike1, Mission.m_Factory);
            Attack(Mission.m_MBike2, Mission.m_Factory);
            Attack(Mission.m_MBike3, Mission.m_Factory);
        elseif (IsAlive(Mission.m_PGen1)) then
            Attack(Mission.m_MBike1, Mission.m_PGen1);
            Attack(Mission.m_MBike2, Mission.m_PGen1);
            Attack(Mission.m_MBike3, Mission.m_PGen1);
        elseif (IsAlive(Mission.m_PGen2)) then
            Attack(Mission.m_MBike1, Mission.m_PGen2);
            Attack(Mission.m_MBike2, Mission.m_PGen2);
            Attack(Mission.m_MBike3, Mission.m_PGen2);
        elseif (IsAlive(Mission.m_Bunker)) then
            Attack(Mission.m_MBike1, Mission.m_Bunker);
            Attack(Mission.m_MBike2, Mission.m_Bunker);
            Attack(Mission.m_MBike3, Mission.m_Bunker);
        elseif (IsAlive(Mission.m_Recycler)) then
            Attack(Mission.m_MBike1, Mission.m_Recycler);
            Attack(Mission.m_MBike2, Mission.m_Recycler);
            Attack(Mission.m_MBike3, Mission.m_Recycler);
        end

        -- So we don't loop.
        Mission.m_ArmoryDead = true;
    end

    if (Mission.m_FactoryDead and Mission.m_Power1Dead and Mission.m_Power2Dead and Mission.m_BunkerDead and Mission.m_RecyclerDead and Mission.m_ArmoryDead and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Move the AI squad.
        Goto(Mission.m_MBike1, "homebase", 1);
        Goto(Mission.m_MBike2, "homebase", 1);
        Goto(Mission.m_MBike3, "homebase", 1);

        -- Have player AI form up.
        Follow(Mission.m_PlayerUnit1, GetPlayerHandle(1), 0);
        Follow(Mission.m_PlayerUnit2, GetPlayerHandle(1), 0);

        -- Show objectives.
        AddObjectiveOverride("isdf2004.otf", "WHITE", 10, true);

        -- Braddock: "A little too easy...".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2005.wav");
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(13.5);

        -- Remove Nav 1 Highlight.
        SetObjectiveOff(Mission.m_Nav1);

        -- Create a new nav.
        Mission.m_Nav2 = BuildObject("ibnav", Mission.m_HostTeam, "scav2");

        -- Set the name and highlight it.
        SetObjectiveName(Mission.m_Nav2, "Rendezvous");
        SetObjectiveOn(Mission.m_Nav2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    if (IsPlayerWithinDistance("exit1", 125, _Cooperative.m_TotalPlayerCount)) then
        -- Set our delay for the ambush.
        Mission.m_AmbushDelay = Mission.m_MissionTime + SecondsToTurns(15);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    if (Mission.m_AmbushDelay < Mission.m_MissionTime) then
        -- Create the ambush.
        Mission.m_Rebel1 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "eatank1");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Rebel1;

        Mission.m_Rebel2 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "eatank2");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Rebel2;

        Mission.m_Rebel3 = BuildObject("ivmbike_x", Mission.m_EnemyTeam, "eatank3");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Rebel3;

        Mission.m_Rebel4 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "etank1");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Rebel4;

        Mission.m_Rebel5 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "etank2");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Rebel5;

        Mission.m_Rebel6 = BuildObject("ivmbike_x", Mission.m_EnemyTeam, "etank3");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Rebel6;

        Mission.m_Rebel7 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "earch1");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Rebel7;

        Mission.m_Rebel8 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "earch2");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Rebel8;

        Mission.m_Rebel9 = BuildObject("ivmisl_x", Mission.m_EnemyTeam, "earch3");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Rebel9;

        -- Have the ambush attack.
        Attack(Mission.m_Rebel1, GetPlayerHandle(1), 1);
        Attack(Mission.m_Rebel2, GetPlayerHandle(1), 1);
        Attack(Mission.m_Rebel3, GetPlayerHandle(1), 1);
        Attack(Mission.m_Rebel4, GetPlayerHandle(1), 1);
        Attack(Mission.m_Rebel5, GetPlayerHandle(1), 1);
        Attack(Mission.m_Rebel6, GetPlayerHandle(1), 1);
        Attack(Mission.m_Rebel7, GetPlayerHandle(1), 1);
        Attack(Mission.m_Rebel8, GetPlayerHandle(1), 1);
        Attack(Mission.m_Rebel9, GetPlayerHandle(1), 1);

        -- Create Manson
        Mission.m_Manson = BuildObject("ivatank_x", Mission.m_EnemyTeam, "manson");

        -- Add each unit to our table.
        Mission.m_RebelBrainTracker[#Mission.m_RebelBrainTracker + 1] = Mission.m_Manson;

        -- Name Manson.
        SetObjectiveName(Mission.m_Manson, "Manson");

        -- Have Manson also attack.
        Attack(Mission.m_Manson, GetPlayerHandle(1), 1);

        -- Set the timer before we notice the ambush.
        Mission.m_AmbushNoticeDelay = Mission.m_MissionTime + SecondsToTurns(20);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    if (Mission.m_AmbushNoticeDelay < Mission.m_MissionTime) then
        -- Show objectives.
        AddObjectiveOverride("isdf2005.otf", "WHITE", 10, true);

        -- Pilot: "I'm detecting units incoming."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2006.wav");
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Create the APC to attack as well.
        Attack(BuildObject("ivapc_x", Mission.m_EnemyTeam, "lung2"), GetPlayerHandle(1), 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock: "Push on!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2007.wav");
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[15] = function()
    if (Mission.m_SeenManson == false and IsPlayerWithinDistance(Mission.m_Manson, 200, _Cooperative.m_TotalPlayerCount)) then
        -- Highlight Manson when he's near.
        SetObjectiveOn(Mission.m_Manson);

        -- So we don't loop.
        Mission.m_SeenManson = true;
    end

    -- Checking to see if Manson is dead.
    if (IsAlive(Mission.m_Manson) == false) then
        -- Braddock: "Well done Major!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf2010.wav");
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(10);
        else
            SucceedMission(GetTime() + 10, "isdf20w1.txt");
        end

        -- So we don't loop.
        Mission.m_MissionOver = true;
    end
end

function RebelBrain()
    -- This tracks each unit that is spawned for the ambush and pushes them to attack if they lose a target.
    if (Mission.m_MissionState > 12) then
        for i = 1, #Mission.m_RebelBrainTracker do
            local unit = Mission.m_RebelBrainTracker[i];

            -- Check if it's alive. If not, remove it from the table.
            if (IsAliveAndEnemy(unit, Mission.m_EnemyTeam)) then
                -- If it's alive, check it's current command.
                local cmd = GetCurrentCommand(unit);

                -- Give it a target to move towards.
                if (cmd == CMD_NONE) then
                    -- Run a check to see if any of our players are in a ship.
                    for j = 1, _Cooperative.m_TotalPlayerCount do
                        local p = GetPlayerHandle(j);
                        local class = GetClassLabel(p);

                        -- If the player is not a pilot, we can attack them.
                        if (class ~= "CLASS_PERSON") then
                            -- Commence attack.
                            Attack(unit, p);

                            -- Return early as no other target is needed.
                            return;
                        end
                    end

                    -- If the for loop doesn't return early, we can search for some AI units for the enemy to attack.
                    if (IsAlive(Mission.m_PlayerUnit1)) then
                        Attack(unit, Mission.m_PlayerUnit1);
                    elseif (IsAlive(Mission.m_PlayerUnit2)) then
                        Attack(unit, Mission.m_PlayerUnit2);
                    elseif (IsAlive(Mission.m_PlayerTruck1)) then
                        Attack(unit, Mission.m_PlayerTruck1);
                    elseif (IsAlive(Mission.m_PlayerTruck2)) then
                        Attack(unit, Mission.m_PlayerTruck2);
                    end
                end
            else
                TableRemoveByHandle(Mission.m_RebelBrainTracker, unit);
            end
        end
    end
end
