--[[
    BZCC Scion06 Lua Mission Script
    Written by AI_Unit
    Version 1.0 21-04-2025
--]]

assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()
require("_GlobalVariables")
require("_HelperFunctions")

local _Cooperative = require("_Cooperative")
local _Subtitles = require('_Subtitles')

-- =========================
-- Variables
-- =========================

local m_GameTPS = GetTPS()
local m_MissionName = "Scion06: The AAN"

local m_RepairTimeTable = { 600, 450, 300 }

local MissionPhase = {
    INTRO = 1,
    BASE = 2,
    CONVOY = 3,
}

local IntroState = {
    SETUP = 1,
    REPAIRS_DIALOG_INTRO = 2,
    REPAIRS_DIALOG_REPAIR_TRUCK = 3,
    REPAIRS_OBJECTIVES = 4,
    TRACK_REPAIRS = 5,
    REPAIRS_COMPLETE = 6,
}

local BaseState = {
    SETUP = 1,
    RECYCLER_TRACKER = 2,
    BASE_DESTROYED = 3,
}

local ConvoyState = {
    SETUP = 1,
    CONVOY_BRAIN = 2,
}

local Mission = {
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    m_PlayerPilotODF = "fspilo_r",
    m_PlayerShipODF = "fvtank_r",

    m_MainPlayer = nil,
    m_Yelena = nil,
    m_Manson = nil,

    m_BraddockTurret1 = nil,
    m_BraddockTurret2 = nil,
    m_BraddockTurret3 = nil,
    m_BraddockTurret4 = nil,

    m_BraddockBasePatrol1 = nil,
    m_BraddockBasePatrol2 = nil,
    m_BraddockBasePatrol3 = nil,

    m_BraddockRecycler = nil,

    m_YelenaTurret1 = nil,
    m_YelenaTurret2 = nil,

    m_PlayerRecycler = nil,
    m_PlayerPower1 = nil,
    m_PlayerPower2 = nil,
    m_PlayerFactory = nil,

    m_ConvoyTug = nil,
    m_ConvoyScout1 = nil,
    m_ConvoyScout2 = nil,
    m_ConvoySent1 = nil,
    m_ConvoySent2 = nil,
    m_PowerCrystal = nil,

    m_Nav1 = nil,

    m_YelenaPowerDialogPlayed = false,

    m_RepairsWarningActive = false,
    m_RepairsStarted = false,
    m_RepairsComplete = false,

    m_YelenaTurret1Sent = false,
    m_YelenaTurret2Sent = false,

    m_ConvoyEscortClose = false,
    m_ConvoyEscortTooFar = false,
    m_ConvoyEnroute = false,
    m_ConvoyActive = false,
    m_ConvoyFleeing = false,
    m_ConvoyFleeingDialogPlayed = false,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_UnitDispatcherTime = 0,
    m_RepairWarningTime = 0,
    m_RepairWarningCount = 0,
    m_ConvoyBrainDelayTime = 0,

    m_CurrentPhase = MissionPhase.INTRO,
    m_IntroState = IntroState.SETUP,
    m_BaseState = BaseState.SETUP,
    m_ConvoyState = ConvoyState.SETUP,
}

-- =========================
-- Helper Functions
-- =========================

local function playAudioWithDelay(clip, delay)
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles(clip)
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(delay)
end

-- =========================
-- Phase-based State Machine
-- =========================

local IntroHandlers = {
    [IntroState.SETUP] = function()
        SetTeamNameForStat(Mission.m_AlliedTeam, "Scion")
        SetTeamNameForStat(Mission.m_EnemyTeam, "New Regime")
        SetTeamNameForStat(7, "Rebel Scions")

        for i = 2, 5 do
            Ally(Mission.m_HostTeam, i);
        end

        Ally(Mission.m_EnemyTeam, 7)
        SetTeamColor(Mission.m_HostTeam, 0, 127, 255)

        Mission.m_Yelena = GetHandle("yelena")
        Mission.m_Manson = GetHandle("manson")

        Mission.m_BraddockRecycler = GetHandle("enemyrecy")

        Mission.m_PlayerPower1 = GetHandle("playerspgen1")
        Mission.m_PlayerPower2 = GetHandle("playerspgen2")
        Mission.m_PlayerFactory = GetHandle("playersfact")

        Mission.m_ConvoyScout1 = GetHandle("convoy_scout1")
        Mission.m_ConvoyScout2 = GetHandle("convoy_scout2")
        Mission.m_ConvoySent1 = GetHandle("convoy_sent1")
        Mission.m_ConvoySent2 = GetHandle("convoy_sent2")

        Mission.m_ConvoyTug = GetHandle("convoy_tug1")
        Mission.m_PowerCrystal = GetHandle("power")

        Patrol(Mission.m_Manson, "manson_patrol", 1)
        Patrol(Mission.m_Yelena, "yelena_patrol", 1)

        SetMaxHealth(Mission.m_Manson, 0)
        SetMaxHealth(Mission.m_Yelena, 0)
        SetCanSnipe(Mission.m_Manson, 0)
        SetCanSnipe(Mission.m_Yelena, 0)

        SetScrap(Mission.m_HostTeam, 40)
        SetScrap(Mission.m_EnemyTeam, 40)
        SetScrap(Mission.m_AlliedTeam, 40)

        SetCurHealth(Mission.m_PlayerFactory, 2200)
        SetCurHealth(Mission.m_PlayerPower1, 1500)
        SetCurHealth(Mission.m_PlayerPower2, 1800)

        SetMaxHealth(Mission.m_PowerCrystal, 10000)
        SetCurHealth(Mission.m_PowerCrystal, 10000)

        SetAIP("scion0601_x.aip", Mission.m_EnemyTeam)

        BuildObject("ivatank_x", Mission.m_EnemyTeam, "ass1")
        BuildObject("ivatank_x", Mission.m_EnemyTeam, "ass2")

        Mission.m_BraddockTurret1 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret1")
        Mission.m_BraddockTurret2 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret2")
        Mission.m_BraddockTurret3 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret3")
        Mission.m_BraddockTurret4 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret4")

        Mission.m_BraddockBasePatrol1 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank1")
        Mission.m_BraddockBasePatrol2 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank2")
        Mission.m_BraddockBasePatrol3 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank3")

        Patrol(Mission.m_BraddockBasePatrol1, "basetank1", 1)
        Patrol(Mission.m_BraddockBasePatrol2, "basetank2", 1)
        Patrol(Mission.m_BraddockBasePatrol3, "basetank3", 1)

        SetAIP("scion0602_x.aip", Mission.m_AlliedTeam)
        Pickup(Mission.m_ConvoyTug, Mission.m_PowerCrystal)

        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3)
        Mission.m_IntroState = IntroState.REPAIRS_DIALOG_INTRO
    end,
    [IntroState.REPAIRS_DIALOG_INTRO] = function()
        if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end

        playAudioWithDelay("scion0601.wav", 8.5)
        Mission.m_IntroState = IntroState.REPAIRS_DIALOG_REPAIR_TRUCK
    end,
    [IntroState.REPAIRS_DIALOG_REPAIR_TRUCK] = function()
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

        playAudioWithDelay("scion0601a.wav", 4.5)
        Mission.m_IntroState = IntroState.REPAIRS_OBJECTIVES
    end,
    [IntroState.REPAIRS_OBJECTIVES] = function()
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

        AddObjectiveOverride("scion0601.otf", "WHITE", 10, true);

        local chosenTimer = m_RepairTimeTable[Mission.m_MissionDifficulty];
        StartCockpitTimer(chosenTimer, chosenTimer / 2, chosenTimer / 4);

        local unit_a_choice = { "ivscout_x", "ivmisl_x", "ivtank_x" };
        local unit_b_choice = { "ivscout_x", "ivscout_x", "ivmisl_x" };

        local unit_a = BuildObject(unit_a_choice[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "braddock_script_1");
        local unit_b = BuildObject(unit_b_choice[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "braddock_script_2");

        Goto(unit_a, "playerbase");
        Goto(unit_b, "playerbase");

        Mission.m_IntroState = IntroState.TRACK_REPAIRS
    end,
    [IntroState.TRACK_REPAIRS] = function()
        if (IsAround(Mission.m_PlayerFactory) == false) then return end
        if (IsAround(Mission.m_PlayerPower1) == false) then return end
        if (IsAround(Mission.m_PlayerPower2) == false) then return end

        local factHealth = GetCurHealth(Mission.m_PlayerFactory)
        local pgen1Health = GetCurHealth(Mission.m_PlayerPower1)
        local pgen2Health = GetCurHealth(Mission.m_PlayerPower2)

        if (factHealth > 5900 and pgen1Health > 2900 and pgen2Health > 2900) then
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2)

            StopCockpitTimer()
            HideCockpitTimer()

            Mission.m_IntroState = IntroState.REPAIRS_COMPLETE
        end

        if (Mission.m_RepairsStarted == false) then
            if (factHealth > 2250 or pgen1Health > 1550 or pgen2Health > 1850) then
                playAudioWithDelay("scion0602.wav", 4.5)
                Mission.m_RepairsStarted = true
            end
        end
    end,
    [IntroState.REPAIRS_COMPLETE] = function()
        if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end

        playAudioWithDelay("scion0603.wav", 9.5)
        Mission.m_CurrentPhase = MissionPhase.BASE
    end
}

local BaseHandlers = {
    [BaseState.SETUP] = function()
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end

        AddObjectiveOverride("scion0601.otf", "WHITE", 10, true)
        Mission.m_Nav1 = BuildObject("ibnav", Mission.m_HostTeam, "enemybase")
        SetObjectiveName(Mission.m_Nav1, TranslateString("MissionS0601"))
        SetObjectiveOn(Mission.m_Nav1)

        Mission.m_BaseState = BaseState.RECYCLER_TRACKER
    end,
    [BaseState.RECYCLER_TRACKER] = function()
        if (not Mission.m_YelenaPowerDialogPlayed and IsPlayerWithinDistance("enemybase", 220, _Cooperative.m_TotalPlayerCount)) then
            playAudioWithDelay("scion0604.wav", 6.5)
            Mission.m_YelenaPowerDialogPlayed = true
        end

        if (not IsAround(Mission.m_BraddockRecycler)) then
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(4)
            Mission.m_BaseState = BaseState.BASE_DESTROYED
        end
    end,
    [BaseState.BASE_DESTROYED] = function()
        if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end

        playAudioWithDelay("scion0606.wav", 3.5)
        Mission.m_CurrentPhase = MissionPhase.CONVOY
    end
}

local ConvoyHandlers = {
    [ConvoyState.SETUP] = function()
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end

        Retreat(Mission.m_ConvoyScout1, "convoypath")
        Follow(Mission.m_ConvoyScout2, Mission.m_ConvoyScout1)

        Retreat(Mission.m_ConvoyTug, "convoypath")
        Follow(Mission.m_ConvoySent1, Mission.m_ConvoyTug)
        Follow(Mission.m_ConvoySent2, Mission.m_ConvoySent1)

        Mission.m_ConvoyEnroute = true
        Mission.m_ConvoyActive = true

        playAudioWithDelay("scion0607.wav", 16.5)

        Mission.m_ConvoyState = ConvoyState.CONVOY_BRAIN
    end,
    [ConvoyState.CONVOY_BRAIN] = function()
        if (Mission.m_ConvoyEnroute) then
            local convoy1Distance = GetDistance(Mission.m_ConvoyScout1, Mission.m_ConvoyTug)

            if (Mission.m_ConvoyEscortTooFar == false and convoy1Distance > 100) then
                Stop(Mission.m_ConvoyScout1)
                Stop(Mission.m_ConvoyScout2)
                Mission.m_ConvoyEscortClose = false
                Mission.m_ConvoyEscortTooFar = true
            elseif (Mission.m_ConvoyEscortClose == false and convoy1Distance < 90) then
                Retreat(Mission.m_ConvoyScout1, "convoypath")
                Follow(Mission.m_ConvoyScout2, Mission.m_ConvoyScout1)
                Mission.m_ConvoyEscortClose = true
                Mission.m_ConvoyEscortTooFar = false
            end

            -- Double check the distance between the player and the convoy tug, or the forward scout.
            for i = 1, _Cooperative.m_TotalPlayerCount do
                local playerHandle = GetPlayerHandle(i);

                if (GetDistance(playerHandle, Mission.m_ConvoyScout1) < 200 or GetDistance(playerHandle, Mission.m_ConvoyTug) < 200) then
                    Attack(Mission.m_ConvoyScout1, playerHandle)
                    Attack(Mission.m_ConvoyScout2, playerHandle)

                    Retreat(Mission.m_ConvoyTug, "tugretreatpath")
                    playAudioWithDelay("scion0608.wav", 9.5)

                    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(15)
                    Mission.m_ConvoyFleeing = true;
                    Mission.m_ConvoyEnroute = false;
                end
            end
        elseif (Mission.m_ConvoyFleeing) then
            if (not Mission.m_ConvoyFleeingDialogPlayed) then
                if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end;
                if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end

                AddObjectiveOverride("scion0604.otf", "WHITE", 10, true)
                playAudioWithDelay("scion0609.wav", 4.5)
                Mission.m_ConvoyFleeingDialogPlayed = true
            end
        end
    end
}

-- =========================
-- Battlezone Event Hooks
-- =========================

function InitialSetup()
    Mission.m_IsCooperativeMode = IsNetworkOn()
    SetAutoGroupUnits(false)
    WantBotKillMessages()
end

function Save()
    return _Cooperative.Save(), Mission
end

function Load(CoopData, MissionData)
    SetAutoGroupUnits(false)
    WantBotKillMessages()
    _Cooperative.Load(CoopData)
    Mission = MissionData
end

function AddObject(h)
    local teamNum = GetTeamNum(h)
    local objClass = GetClassLabel(h)

    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty)

        if (objClass == "CLASS_TURRETTANK") then
            if (IsAliveAndEnemy(Mission.m_BraddockTurret1, Mission.m_EnemyTeam) == false) then
                Mission.m_BraddockTurret1 = h
            elseif (IsAliveAndEnemy(Mission.m_BraddockTurret2, Mission.m_EnemyTeam) == false) then
                Mission.m_BraddockTurret2 = h
            elseif (IsAliveAndEnemy(Mission.m_BraddockTurret3, Mission.m_EnemyTeam) == false) then
                Mission.m_BraddockTurret3 = h
            elseif (IsAliveAndEnemy(Mission.m_BraddockTurret4, Mission.m_EnemyTeam) == false) then
                Mission.m_BraddockTurret4 = h
            end
        end
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        SetSkill(h, 3)

        if (teamNum == Mission.m_HostTeam) then
            if (Mission.m_RepairsComplete == false) then
                if (objClass == "CLASS_PLANT") then
                    if (IsAround(Mission.m_PlayerPower1) == false) then
                        Mission.m_PlayerPower1 = h
                    elseif (IsAround(Mission.m_PlayerPower2) == false) then
                        Mission.m_PlayerPower2 = h
                    end
                elseif (objClass == "CLASS_FACTORY") then
                    if (IsAround(Mission.m_PlayerFactory) == false) then
                        Mission.m_PlayerFactory = h
                    end
                end
            end
        end
    elseif (teamNum == Mission.m_AlliedTeam) then
        if (objClass == "CLASS_TURRETTANK") then
            if (IsAlive(Mission.m_YelenaTurret1) == false) then
                Mission.m_YelenaTurret1 = h
                Mission.m_YelenaTurret1Sent = false
            elseif (IsAlive(Mission.m_YelenaTurret2) == false) then
                Mission.m_YelenaTurret2 = h
                Mission.m_YelenaTurret2Sent = false
            end
        end
    end
end

function DeleteObject(h)
    local teamNum = GetTeamNum(h)

    if (teamNum == Mission.m_AlliedTeam) then
        if (h == Mission.m_YelenaTurret1) then
            Mission.m_YelenaTurret1 = nil
        elseif (h == Mission.m_YelenaTurret2) then
            Mission.m_YelenaTurret2 = nil
        end
    elseif (teamNum == Mission.m_EnemyTeam) then
        if (h == Mission.m_BraddockTurret1) then
            Mission.m_BraddockTurret1 = nil
        elseif (h == Mission.m_BraddockTurret2) then
            Mission.m_BraddockTurret2 = nil
        elseif (h == Mission.m_BraddockTurret3) then
            Mission.m_BraddockTurret3 = nil
        elseif (h == Mission.m_BraddockTurret4) then
            Mission.m_BraddockTurret4 = nil
        end
    end
end

function Start()
    if (Mission.m_IsCooperativeMode) then
        Mission.m_MissionDifficulty = GetVarItemInt("network.session.ivar102") + 1
    else
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1
    end

    _Cooperative.Start(m_MissionName, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, Mission.m_IsCooperativeMode)
    Mission.m_StartDone = true
end

function Update()
    if (Mission.m_IsCooperativeMode) then
        _Cooperative.Update(m_GameTPS)
    end

    _Subtitles.Run()

    Mission.m_MissionTime = Mission.m_MissionTime + 1
    Mission.m_MainPlayer = GetPlayerHandle(1)

    if (Mission.m_MissionOver == false) then
        if (Mission.m_StartDone) then
            -- PHASE-BASED STATE MACHINE
            if (Mission.m_CurrentPhase == MissionPhase.INTRO) then
                IntroHandlers[Mission.m_IntroState]()
            elseif (Mission.m_CurrentPhase == MissionPhase.BASE) then
                BaseHandlers[Mission.m_BaseState]()
            elseif (Mission.m_CurrentPhase == MissionPhase.CONVOY) then
                ConvoyHandlers[Mission.m_ConvoyState]()
            end

            HandleFailureConditions()
            YelenaBrain()
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
    if (IsPlayer(ShooterHandle) and OrdnanceTeam == Mission.m_HostTeam and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (IsAlive(Mission.m_Manson) and VictimHandle == Mission.m_Manson) then
            playAudioWithDelay("isdf0555.wav", 3.5)
        end

        if (IsAlive(Mission.m_Yelena) and VictimHandle == Mission.m_Yelena) then
            playAudioWithDelay("scngen30.wav", 3.5)
        end
    end
end

-- =========================
-- Related Mission Logic
-- =========================

function YelenaBrain()
    if (Mission.m_UnitDispatcherTime < Mission.m_MissionTime) then
        if (Mission.m_YelenaTurret1Sent == false) then
            -- Pick a random path for this turret to move to.
            local rand = GetRandomFloat(1);
            local path;

            if (rand < 0.5) then
                path = "yelena_turret_path_1";
            else
                path = "yelena_turret_path_3";
            end

            Goto(Mission.m_YelenaTurret1, path);

            Mission.m_YelenaTurret1Sent = true;
        end

        if (Mission.m_YelenaTurret2Sent == false) then
            -- Pick a random path for this turret to move to.
            local rand = GetRandomFloat(1);
            local path;

            if (rand < 0.5) then
                path = "yelena_turret_path_2";
            else
                path = "yelena_turret_path_4";
            end

            Goto(Mission.m_YelenaTurret2, path);

            Mission.m_YelenaTurret2Sent = true;
        end

        -- To delay loops.
        Mission.m_UnitDispatcherTime = Mission.m_MissionTime + SecondsToTurns(1.5);
    end
end

function HandleFailureConditions()
    if (Mission.m_RepairsWarningActive) then
        if (Mission.m_RepairWarningTime >= Mission.m_MissionTime) then return end;

        if (Mission.m_RepairWarningCount == 0) then
            -- Yelena: Those repairs should have been finished by now,  What's going on?
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0603.wav");

            -- Timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);
        elseif (Mission.m_RepairWarningCount == 1) then
            -- Yelena: The base STILL is not fully repaired.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0616.wav");

            -- Timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
        elseif (Mission.m_RepairWarningCount == 2) then
            -- Yelena: That's it... I'm pissed now, mission over.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0617.wav");

            -- Timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
        end

        -- Advance the warning count.
        Mission.m_RepairWarningCount = Mission.m_RepairWarningCount + 1;

        if (Mission.m_RepairWarningCount < 3) then
            -- Add more time for the warning.
            Mission.m_RepairWarningTime = m_RepairTimeTable[Mission.m_MissionDifficulty] / 4;
        else
            StopCockpitTimer();
            HideCockpitTimer();

            -- Show Objectives.
            AddObjectiveOverride("scion0607.otf", "RED", 10, true);

            -- Fail the mission.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("The base wasn't repaired in time.");
                DoGameover(10);
            else
                FailMission(GetTime() + 10, "scion06L1.txt");
            end

            -- Just so we don't loop.
            Mission.m_MissionOver = true;
        end
    end

    if (Mission.m_ConvoyFleeing) then
        if (GetDistance(Mission.m_ConvoyTug, "tug_end_missison") < 75) then
            -- Show Objectives.
            AddObjectiveOverride("scion0604.otf", "RED", 10, true);

            -- Fail the mission.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("The Hauler escaped.");
                DoGameover(10);
            else
                FailMission(GetTime() + 10, "The Hauler escaped.");
            end

            -- Just so we don't loop.
            Mission.m_MissionOver = true;
        end
    end
end
