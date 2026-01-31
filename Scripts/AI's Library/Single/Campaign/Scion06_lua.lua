--[[
    BZCC Scion06 Lua Mission Script
    Written by AI_Unit
--]]

assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()
require("_GlobalVariables")
require("_HelperFunctions")
require("_AICmd")

local _DispatchClass = require("_DispatchClass")
local _Cooperative = require("_Cooperative")
local _Subtitles = require('_Subtitles')
local _BZCCDatabase = require("_BZCCDatabase")
local _WorldManager = require("_WorldManager")

-- =========================
-- Variables
-- =========================

local m_GameTPS = GetTPS()
local m_MissionName = _BZCCDatabase.Missions.SCION06

local m_RepairTimeTable = { 600, 450, 300 }
local m_WeaponChance = 0.25

local m_WeaponTable = {
    m_Cannons = { _BZCCDatabase.ISDFWeaponTable.SPStabber, _BZCCDatabase.ISDFWeaponTable.PLStabber, _BZCCDatabase.ISDFWeaponTable.Plasma },
    m_Guns = { _BZCCDatabase.ISDFWeaponTable.Pummel, _BZCCDatabase.ISDFWeaponTable.Chain, _BZCCDatabase.ISDFWeaponTable.Laser },
    m_Missiles = { _BZCCDatabase.ISDFWeaponTable.Shadower, _BZCCDatabase.ISDFWeaponTable.FAF },
}

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
    CONVOY_DEAD = 3,
    END_MISSION = 4
}

local CPUState = {
    DISPATCH_UNITS = 1,
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

    m_BraddockBasePatrol1 = nil,
    m_BraddockBasePatrol2 = nil,
    m_BraddockBasePatrol3 = nil,

    m_BraddockRecycler = nil,

    m_YelenaTurret1 = nil,
    m_YelenaTurret2 = nil,

    ---@type DispatchClass[]
    m_YelenaSentries = {},
    ---@type DispatchClass[]
    m_YelenaTurrets = {},
    ---@type DispatchClass[]
    m_BraddockAntiAirUnits = {},
    ---@type DispatchClass[]
    m_BraddockAssaultUnits = {},
    ---@type DispatchClass[]
    m_BraddockAssaultServiceUnits = {},
    ---@type DispatchClass[]
    m_BraddockTurrets = {},
    ---@type DispatchClass[]
    m_BraddockAssaultDefenseUnits = {},

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

    m_RepairsWarningActive = false,
    m_RepairsStarted = false,
    m_RepairsComplete = false,

    m_YelenaPowerDialogPlayed = false,
    m_YelenaBrainActive = true,
    m_BraddockBrainActive = true,

    m_ConvoyEscortClose = false,
    m_ConvoyEscortTooFar = false,
    m_ConvoyEnroute = false,
    m_ConvoyActive = false,
    m_ConvoyFleeing = false,
    m_ConvoyFleeingDialogPlayed = false,

    m_ConvoyHaulderDead = false,
    m_ConvoyEscortsDead = false,

    m_ShowConvoyObjective = false,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_FailuresActive = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_UnitDispatcherTime = 0,
    m_RepairWarningTime = 0,
    m_RepairWarningCount = 0,
    m_ConvoyBrainDelayTime = 0,
    m_YelenaDispatchDelayTime = 0,
    m_BraddockDispatchDelayTime = 0,

    m_CurrentPhase = MissionPhase.INTRO,
    m_IntroState = IntroState.SETUP,
    m_BaseState = BaseState.SETUP,
    m_ConvoyState = ConvoyState.SETUP,
    m_YelenaState = CPUState.DISPATCH_UNITS,
    m_BraddockState = CPUState.DISPATCH_UNITS
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
        _WorldManager.Setup(true, _Cooperative.m_TotalPlayerCount)

        SetTeamNameForStat(Mission.m_AlliedTeam, "Scion")
        SetTeamNameForStat(Mission.m_EnemyTeam, "New Regime")
        SetTeamNameForStat(7, "Rebel Scions")

        for i = 2, 5 do
            Ally(Mission.m_HostTeam, i)
        end

        SetTeamColor(7, 31, 127, 95)
        Ally(Mission.m_EnemyTeam, 7)

        for i = Mission.m_HostTeam, 4 do
            SetTeamColor(i, 0, 127, 255)
        end

        Mission.m_Yelena = GetHandle("yelena")
        Mission.m_Manson = GetHandle("manson")

        Patrol(Mission.m_Manson, "manson_patrol", 1)

        Mission.m_BraddockRecycler = GetHandle("enemyrecy")

        Mission.m_PlayerRecycler = GetHandle("playersrecy")
        Mission.m_PlayerPower1 = GetHandle("playerspgen1")
        Mission.m_PlayerPower2 = GetHandle("playerspgen2")
        Mission.m_PlayerFactory = GetHandle("playersfact")

        Mission.m_ConvoyScout1 = GetHandle("convoy_scout1")
        Mission.m_ConvoyScout2 = GetHandle("convoy_scout2")
        Mission.m_ConvoySent1 = GetHandle("convoy_sent1")
        Mission.m_ConvoySent2 = GetHandle("convoy_sent2")

        Mission.m_ConvoyTug = GetHandle("convoy_tug1")
        Mission.m_PowerCrystal = GetHandle("power")

        SetMaxHealth(Mission.m_Manson, 0)
        SetMaxHealth(Mission.m_Yelena, 0)
        SetCanSnipe(Mission.m_Manson, 0)
        SetCanSnipe(Mission.m_Yelena, 0)

        -- Give the player more scrap based on difficulty.
        local scrapAmount = { 60, 50, 40 }
        SetScrap(Mission.m_HostTeam, scrapAmount[Mission.m_MissionDifficulty])
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

        for i = 1, 4 do
            local h = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret" .. i)
            Mission.m_BraddockTurrets[i] = _DispatchClass.New(h, Mission.m_MissionTime, Mission.m_EnemyTeam,
                GetClassLabel(h))
        end

        Mission.m_BraddockBasePatrol1 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank1")
        Mission.m_BraddockBasePatrol2 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank2")
        Mission.m_BraddockBasePatrol3 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank3")

        Patrol(Mission.m_BraddockBasePatrol1, "basetank1", 1)
        Patrol(Mission.m_BraddockBasePatrol2, "basetank2", 1)
        Patrol(Mission.m_BraddockBasePatrol3, "basetank3", 1)

        SetAIP("scion0602_x.aip", Mission.m_AlliedTeam)
        Pickup(Mission.m_ConvoyTug, Mission.m_PowerCrystal)

        Mission.m_FailuresActive = true
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3)
        Mission.m_IntroState = IntroState.REPAIRS_DIALOG_INTRO
    end,
    [IntroState.REPAIRS_DIALOG_INTRO] = function()
        if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end

        Patrol(Mission.m_Yelena, "yelena_patrol", 1)

        playAudioWithDelay("scion0601.wav", 8.5)
        Mission.m_IntroState = IntroState.REPAIRS_DIALOG_REPAIR_TRUCK
    end,
    [IntroState.REPAIRS_DIALOG_REPAIR_TRUCK] = function()
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end

        playAudioWithDelay("scion0601a.wav", 4.5)
        Mission.m_IntroState = IntroState.REPAIRS_OBJECTIVES
    end,
    [IntroState.REPAIRS_OBJECTIVES] = function()
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end

        AddObjectiveOverride("scion0601.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)

        local chosenTimer = m_RepairTimeTable[Mission.m_MissionDifficulty]
        StartCockpitTimer(chosenTimer, chosenTimer / 2, chosenTimer / 4)

        local unit_a_choice = { "ivscout_x", "ivmisl_x", "ivtank_x" }
        local unit_b_choice = { "ivscout_x", "ivscout_x", "ivmisl_x" }
        local unit_a_weapon = { _BZCCDatabase.ISDFWeaponTable.Chain, _BZCCDatabase.ISDFWeaponTable.Shadower,
            _BZCCDatabase.ISDFWeaponTable.SPStabber }
        local unit_b_weapon = { _BZCCDatabase.ISDFWeaponTable.Chain, _BZCCDatabase.ISDFWeaponTable.Chain, _BZCCDatabase
            .ISDFWeaponTable.Shadower }

        local chosen_unit_a = unit_a_choice[Mission.m_MissionDifficulty]
        local chosen_unit_b = unit_b_choice[Mission.m_MissionDifficulty]

        local unit_a = BuildObject(chosen_unit_a, Mission.m_EnemyTeam, "braddock_script_1")
        local unit_b = BuildObject(chosen_unit_b, Mission.m_EnemyTeam, "braddock_script_2")

        GiveWeapon(unit_a, unit_a_weapon[Mission.m_MissionDifficulty])
        GiveWeapon(unit_b, unit_b_weapon[Mission.m_MissionDifficulty])

        Goto(unit_a, "playerbase")
        Goto(unit_b, "playerbase")

        Mission.m_RepairWarningTime = Mission.m_MissionTime + SecondsToTurns(chosenTimer / 2)
        Mission.m_RepairsWarningActive = true
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

            -- Skip the below section if this is done first.
            Mission.m_RepairsStarted = true
            Mission.m_RepairsWarningActive = false
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
        Mission.m_RepairsComplete = true
        Mission.m_CurrentPhase = MissionPhase.BASE
    end
}

local BaseHandlers = {
    [BaseState.SETUP] = function()
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end

        SetAIP("scion0603_x.aip", Mission.m_EnemyTeam)
        AddObjectiveOverride("scion0602.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
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
        AddObjectiveOverride("scion0602.otf", "GREEN", 10, true, Mission.m_IsCooperativeMode)
        Mission.m_CurrentPhase = MissionPhase.CONVOY
    end
}

local ConvoyHandlers = {
    [ConvoyState.SETUP] = function()
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end

        Retreat(Mission.m_ConvoyScout1, "convoypath")
        Follow(Mission.m_ConvoyScout2, Mission.m_ConvoyScout1)

        Retreat(Mission.m_ConvoyTug, "convoypath")
        Follow(Mission.m_ConvoySent1, Mission.m_PowerCrystal)
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
                local playerHandle = GetPlayerHandle(i)

                if (GetDistance(playerHandle, Mission.m_ConvoyScout1) < 200 or GetDistance(playerHandle, Mission.m_ConvoyTug) < 200) then
                    Attack(Mission.m_ConvoyScout1, playerHandle)
                    Attack(Mission.m_ConvoyScout2, playerHandle)

                    Retreat(Mission.m_ConvoyTug, "tugretreatpath")
                    playAudioWithDelay("scion0608.wav", 9.5)

                    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(15)
                    Mission.m_ConvoyFleeing = true
                    Mission.m_ConvoyEnroute = false
                end
            end
        elseif (Mission.m_ConvoyFleeing) then
            if (not Mission.m_ConvoyFleeingDialogPlayed) then
                if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end
                if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

                AddObjectiveOverride("scion0604.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
                playAudioWithDelay("scion0609.wav", 4.5)
                Mission.m_ConvoyFleeingDialogPlayed = true
            end
        end

        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

        if (not Mission.m_ShowConvoyObjective) then
            AddObjectiveOverride("scion0603.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
            Mission.m_ShowConvoyObjective = true
        end

        -- Check to see if the Rebels have been dealt with.
        if (not Mission.m_ConvoyHaulderDead and not IsAliveAndEnemy(Mission.m_ConvoyTug, 7)) then
            if (not Mission.m_ConvoyEscortsDead) then
                playAudioWithDelay("scion0610.wav", 4.5)
            end

            Mission.m_ConvoyHaulderDead = true
        end

        if (not Mission.m_ConvoyEscortsDead
                and not IsAliveAndEnemy(Mission.m_ConvoyScout1, 7)
                and not IsAliveAndEnemy(Mission.m_ConvoyScout2, 7)
                and not IsAliveAndEnemy(Mission.m_ConvoySent1, 7)
                and not IsAliveAndEnemy(Mission.m_ConvoySent2, 7)) then
            if (not Mission.m_ConvoyHaulderDead) then
                playAudioWithDelay("scion0611.wav", 4.5)
            end

            Mission.m_ConvoyEscortsDead = true
        end

        if (Mission.m_ConvoyHaulderDead and Mission.m_ConvoyEscortsDead) then
            Mission.m_ConvoyState = ConvoyState.CONVOY_DEAD
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(4)
        end
    end,
    [ConvoyState.CONVOY_DEAD] = function()
        if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end
        playAudioWithDelay("scion0612.wav", 4.5)
        Mission.m_ConvoyState = ConvoyState.END_MISSION
    end,
    [ConvoyState.END_MISSION] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end
        AddObjectiveOverride("scion0605.otf", "GREEN", 10, true, Mission.m_IsCooperativeMode)

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.")
            DoGameover(10)
        else
            SucceedMission(GetTime() + 10, "scion06w1.txt")
        end

        Mission.m_MissionOver = true
    end
}

-- =========================
-- CPU Brain Handlers
-- =========================

local YelenaHandlers = {
    [CPUState.DISPATCH_UNITS] = function()
        if (Mission.m_YelenaDispatchDelayTime >= Mission.m_MissionTime) then return end

        for i = 1, #Mission.m_YelenaTurrets do
            local turretObj = Mission.m_YelenaTurrets[i]

            if (not _DispatchClass.IsAvailable(turretObj, Mission.m_MissionTime)) then
                goto continue
            end

            local turretHandle = turretObj.Handle
            local rand = GetRandomFloat(1)
            local path

            if (GetTeamNum(turretHandle) == Mission.m_AlliedTeam) then
                SetTeamNum(turretHandle, Mission.m_HostTeam)
            end

            if (rand < 0.5) then
                path = "yelena_turret_path_" .. i
            else
                path = "yelena_turret_path_" .. i + 2
            end

            Goto(turretHandle, path, 1)
            turretObj.Command = CMD_GO

            ::continue::
        end

        for i = 1, #Mission.m_YelenaSentries do
            local sentryObj = Mission.m_YelenaSentries[i]

            if (not _DispatchClass.IsAvailable(sentryObj, Mission.m_MissionTime)) then
                goto continue
            end

            local sentryHandle = sentryObj.Handle
            local playerBasePath = "yelena_sentry_path"

            if (GetTeamNum(sentryHandle) == Mission.m_AlliedTeam) then
                SetTeamNum(sentryHandle, Mission.m_HostTeam)
            end

            if (GetCurrentCommand(sentryHandle) ~= CMD_NONE) then
                goto continue
            end

            if (GetDistance(sentryHandle, playerBasePath) > 200) then
                Goto(sentryHandle, GetPositionNear(playerBasePath, 25, 50), 1)
                goto continue
            end

            local validTarget = GetNearestEnemy(sentryHandle, true, false, 150)

            if (validTarget) then
                Attack(sentryHandle, validTarget, 1)
                goto continue
            end

            if (Mission.m_MissionDifficulty < 3) then
                validTarget = GetNearestEnemy(Mission.m_PlayerRecycler, true, false, 200)

                if (validTarget) then
                    Attack(sentryHandle, validTarget, 1)
                    goto continue
                end
            end

            ::continue::
        end

        Mission.m_YelenaDispatchDelayTime = Mission.m_MissionTime + SecondsToTurns(1.5)
    end
}

local BraddockHandlers = {
    [CPUState.DISPATCH_UNITS] = function()
        if (Mission.m_BraddockDispatchDelayTime >= Mission.m_MissionTime) then return end

        -- Loop through the Service Units, check if they are idle, if they are, then do a couple of checks.
        -- If they are near the Recycler, assign them to an Assault Unit. If they are too far in the field, return home.
        for i = 1, #Mission.m_BraddockAssaultServiceUnits do
            ProcessAssaultSupportUnit(Mission.m_BraddockAssaultServiceUnits[i])
        end

        -- Do the same with tanks that are built to support Assault Units.
        for i = 1, #Mission.m_BraddockAssaultDefenseUnits do
            ProcessAssaultSupportUnit(Mission.m_BraddockAssaultDefenseUnits[i])
        end

        -- Manage Turrets.
        for i = 1, #Mission.m_BraddockTurrets do
            local turretModel = Mission.m_BraddockTurrets[i]

            if (not _DispatchClass.IsAvailable(turretModel, Mission.m_MissionTime)) then
                goto continue
            end

            Goto(turretModel.Handle, "brad_turret" .. i)
            turretModel.Command = CMD_GO

            ::continue::
        end

        -- Manage Anti-Air
        for i = 1, #Mission.m_BraddockAntiAirUnits do
            local aaModel = Mission.m_BraddockAntiAirUnits[i]

            if (not _DispatchClass.IsAvailable(aaModel, Mission.m_MissionTime)) then
                goto continue
            end

            Goto(aaModel.Handle, "brad_anti-air" .. i)
            aaModel.Command = CMD_GO

            ::continue::
        end

        Mission.m_BraddockDispatchDelayTime = Mission.m_MissionTime + SecondsToTurns(1.5)
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
    local objCfg = GetCfg(h)

    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty)

        if (Mission.m_RepairsComplete) then
            if (objCfg == "ivtank_x" or objCfg == "ivtank_d" or objCfg == "ivmisl_x" or objCfg == "ivscout_x") then
                -- Run a random chance to see if they are allowed a weapon.
                local chance = GetRandomFloat(0, 1)
                local weaponChance = m_WeaponChance * Mission.m_MissionDifficulty

                if (chance > weaponChance) then
                    if (objCfg == "ivtank_x") then
                        GiveWeapon(h, m_WeaponTable.m_Cannons[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Cannons))]);
                    elseif (objCfg == "ivscout_x") then
                        GiveWeapon(h, m_WeaponTable.m_Guns[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Guns))]);
                    elseif (objCfg == "ivmisl_x") then
                        GiveWeapon(h, m_WeaponTable.m_Missiles[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Missiles))]);
                    end
                end
            end
        end

        if (objClass == "CLASS_TURRETTANK") then
            Mission.m_BraddockTurrets[#Mission.m_BraddockTurrets + 1] = _DispatchClass.New(h, Mission.m_MissionTime,
                Mission.m_AlliedTeam, objClass)
        elseif (objCfg == "ivatank_x" or objCfg == "ivwalk_x") then
            Mission.m_BraddockAssaultUnits[#Mission.m_BraddockAssaultUnits + 1] = _DispatchClass.New(h,
                Mission.m_MissionTime, Mission.m_EnemyTeam, objClass)
        end

        -- Read custom properties from the ODF of the object that has been added.
        local AICraftType = GetODFString(h, "GameObjectClass", "AIUnitType")

        if (AICraftType == nil or AICraftType == "") then
            return
        end

        if (AICraftType == _BZCCDatabase.AIUnitTypes.ANTI_AIR) then
            Mission.m_BraddockAntiAirUnits[#Mission.m_BraddockAntiAirUnits + 1] = _DispatchClass.New(h,
                Mission.m_MissionTime, Mission.m_EnemyTeam, objClass)
        elseif (AICraftType == _BZCCDatabase.AIUnitTypes.ASSAULT_SERVICE) then
            Mission.m_BraddockAssaultServiceUnits[#Mission.m_BraddockAssaultServiceUnits + 1] = _DispatchClass.New(h,
                Mission.m_MissionTime, Mission.m_EnemyTeam, objClass)
        elseif (AICraftType == _BZCCDatabase.AIUnitTypes.MINION) then
            Mission.m_BraddockAssaultDefenseUnits[#Mission.m_BraddockAssaultDefenseUnits + 1] = _DispatchClass.New(h,
                Mission.m_MissionTime, Mission.m_EnemyTeam, objClass)
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
        SetSkill(h, 3)

        if (objClass == "CLASS_TURRETTANK") then
            Mission.m_YelenaTurrets[#Mission.m_YelenaTurrets + 1] = _DispatchClass.New(h, Mission.m_MissionTime,
                Mission.m_AlliedTeam, objClass)
            return
        end

        if (objCfg == "fvsent_r06") then
            -- If we're not on the hardest difficulty, then we can give this sentry some boosts.
            if (Mission.m_MissionDifficulty < 3) then
                GiveWeapon(h, _BZCCDatabase.ScionWeaponTable.Absorb)

                if (Mission.m_MissionDifficulty < 2) then
                    GiveWeapon(h, _BZCCDatabase.ScionWeaponTable.Gauss)
                end
            end

            Mission.m_YelenaSentries[#Mission.m_YelenaSentries + 1] = _DispatchClass.New(h, Mission.m_MissionTime,
                Mission.m_AlliedTeam, objCfg)
        end
    end
end

function DeleteObject(h)
    local teamNum = GetTeamNum(h)

    if (teamNum == Mission.m_HostTeam) then
        local objCfg = GetCfg(h)

        if (objCfg == "fvturr_r") then
            for i = 1, #Mission.m_YelenaTurrets do
                local turretObj = Mission.m_YelenaTurrets[i]

                if (turretObj.Handle == h) then
                    Mission.m_YelenaTurrets = SquelchDispatchTable(Mission.m_YelenaTurrets, turretObj)
                    break
                end
            end
        elseif (GetCfg(h) == "fvsent_r06") then
            for i = 1, #Mission.m_YelenaSentries do
                local sentryObj = Mission.m_YelenaSentries[i]

                if (sentryObj.Handle == h) then
                    Mission.m_YelenaSentries = SquelchDispatchTable(Mission.m_YelenaSentries, sentryObj)
                    break
                end
            end
        end
    elseif (teamNum == Mission.m_EnemyTeam) then
        local objClass = GetClassLabel(h)

        if (objClass == "CLASS_TURRETTANK") then
            for i = 1, #Mission.m_BraddockTurrets do
                local turretObj = Mission.m_BraddockTurrets[i]

                if (turretObj.Handle == h) then
                    Mission.m_BraddockTurrets = SquelchDispatchTable(Mission.m_BraddockTurrets, turretObj)
                    break
                end
            end
        elseif (objClass == "CLASS_ASSAULTTANK" or objClass == "CLASS_WALKER") then
            for i = 1, #Mission.m_BraddockAssaultUnits do
                local assaultObj = Mission.m_BraddockAssaultUnits[i]

                if (assaultObj.Handle == h) then
                    Mission.m_BraddockAssaultUnits = SquelchDispatchTable(Mission.m_BraddockAssaultUnits, assaultObj)
                    break
                end
            end
        end

        -- Read custom properties from the ODF of the object that has been added.
        local AICraftType = GetODFString(h, "GameObjectClass", "AIUnitType")

        if (AICraftType == nil or AICraftType == "") then
            return
        end

        if (AICraftType == _BZCCDatabase.AIUnitTypes.ANTI_AIR) then
            for i = 1, #Mission.m_BraddockAntiAirUnits do
                local unitToCheck = Mission.m_BraddockAntiAirUnits[i]

                if (unitToCheck.Handle == h) then
                    Mission.m_BraddockAntiAirUnits = SquelchDispatchTable(Mission.m_BraddockAntiAirUnits, unitToCheck)
                    break
                end
            end
        elseif (AICraftType == _BZCCDatabase.AIUnitTypes.ASSAULT_SERVICE) then
            for i = 1, #Mission.m_BraddockAssaultServiceUnits do
                local unitToCheck = Mission.m_BraddockAssaultServiceUnits[i]

                if (unitToCheck.Handle == h) then
                    Mission.m_BraddockAssaultServiceUnits = SquelchDispatchTable(Mission.m_BraddockAssaultServiceUnits,
                        unitToCheck)
                    break
                end
            end
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
    _WorldManager.Run()

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

            if (Mission.m_FailuresActive) then
                HandleFailureConditions()
            end

            if (Mission.m_YelenaBrainActive) then YelenaHandlers[Mission.m_YelenaState]() end
            if (Mission.m_BraddockBrainActive) then BraddockHandlers[Mission.m_BraddockState]() end
        end
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, false, 0)
end

function DeletePlayer(id)
    return _Cooperative.DeletePlayer(id)
end

function PlayerEjected(DeadObjectHandle)
    return _Cooperative.PlayerEjected(DeadObjectHandle)
end

function ObjectKilled(DeadObjectHandle, KillersHandle)
    return _Cooperative.ObjectKilled(DeadObjectHandle, KillersHandle, Mission.m_PlayerPilotODF)
end

function ObjectSniped(DeadObjectHandle, KillersHandle)
    return _Cooperative.ObjectSniped(DeadObjectHandle, KillersHandle, Mission.m_PlayerPilotODF)
end

function PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF)
    return _Cooperative.PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF)
end

function PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
    return _Cooperative.PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
end

function RespawnPilot(DeadObjectHandle, Team)
    return _Cooperative.RespawnPilot(DeadObjectHandle, Team, Mission.m_PlayerPilotODF)
end

function DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI)
    return _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI, Mission.m_PlayerPilotODF)
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

function HandleFailureConditions()
    if (Mission.m_RepairsWarningActive) then
        if (Mission.m_RepairWarningTime >= Mission.m_MissionTime) then return end

        if (Mission.m_RepairWarningCount == 0) then
            playAudioWithDelay("scion0605.wav", 4.5)
        elseif (Mission.m_RepairWarningCount == 1) then
            playAudioWithDelay("scion0616.wav", 5.5)
        elseif (Mission.m_RepairWarningCount == 2) then
            playAudioWithDelay("scion0617.wav", 5.5)
        end

        Mission.m_RepairWarningCount = Mission.m_RepairWarningCount + 1

        if (Mission.m_RepairWarningCount < 3) then
            Mission.m_RepairWarningTime = Mission.m_MissionTime +
                SecondsToTurns(m_RepairTimeTable[Mission.m_MissionDifficulty] / 4)
        else
            StopCockpitTimer()
            HideCockpitTimer()

            AddObjectiveOverride("scion0607.otf", "RED", 10, true, Mission.m_IsCooperativeMode)

            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("The base wasn't repaired in time.")
                DoGameover(10)
            else
                FailMission(GetTime() + 10, "scion06L1.txt")
            end

            Mission.m_MissionOver = true
        end
    end

    if (not IsAround(Mission.m_PlayerRecycler)) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Show failure objective.
        AddObjectiveOverride("scion0608.otf", "RED", 10, true, Mission.m_IsCooperativeMode);
        playAudioWithDelay("scion0699.wav", 5.5)

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Recycler was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "scion06L3.txt");
        end
    end

    if (Mission.m_ConvoyFleeing) then
        if (GetTug(Mission.m_PowerCrystal) ~= nil and GetDistance(Mission.m_PowerCrystal, "tug_end_missison") < 75) then
            AddObjectiveOverride("scion0604.otf", "RED", 10, true, Mission.m_IsCooperativeMode)

            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("The Hauler escaped.")
                DoGameover(10)
            else
                FailMission(GetTime() + 10, "The Hauler escaped.")
            end

            Mission.m_MissionOver = true
        end
    end
end

---Shared logic for dispatching assault support units
---@param supportUnit DispatchClass
function ProcessAssaultSupportUnit(supportUnit)
    if (not _DispatchClass.IsAvailable(supportUnit, Mission.m_MissionTime)) then
        goto continue
    end

    local unitHandle = supportUnit.Handle

    -- Check if we are idle.
    if (GetCurrentCommand(unitHandle) ~= CMD_NONE) then
        goto continue
    end

    if (GetDistance(unitHandle, Mission.m_BraddockRecycler) > 450) then
        local pos = GetPositionNear(GetPosition(Mission.m_BraddockRecycler), 25, 50)
        Retreat(unitHandle, pos)
        goto continue
    end

    if (#Mission.m_BraddockAssaultUnits > 0) then
        local rand = Mission.m_BraddockAssaultUnits[GetRandomInt(1, #Mission.m_BraddockAssaultUnits)]

        if (IsAliveAndEnemy(rand.Handle, Mission.m_EnemyTeam)) then
            SetIndependence(unitHandle, 1) -- To restore after using Retreat.
            Follow(unitHandle, rand.Handle)
        end
    end

    ::continue::
end
