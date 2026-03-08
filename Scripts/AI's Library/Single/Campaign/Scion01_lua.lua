--[[
    BZCC Scion01 Lua Mission Script
    Written by AI_Unit
--]]

-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()

require("_GlobalVariables")
require("_HelperFunctions")

local _BZCCDatabase = require("_BZCCDatabase")
local _Cooperative = require("_Cooperative")
local _SaveLoad = require("_SaveLoad")
local _Subtitles = require('_Subtitles')

local _CPUManager = require("_CPUManager")

-- =========================
-- Variables
-- =========================

local m_GameTPS = GetTPS()
local m_MissionName = _BZCCDatabase.Missions.SCION01

local MissionPhase = {
    INTRO = 1,
    TUTORIAL = 2,
    BASE = 3
}

local IntroState = {
    SETUP = 1,
    CAMERA1 = 2,
    CAMERA2 = 3,
    CAMERA3 = 4,
    CAMERA4 = 5,
    PILOT_WALK = 6,
    YELENA_IN_SHIP = 7,
    FINISH = 8
}

local BaseState = {
    BASE_DIALOGUE = 1,
    BASE_OBJECTIVE = 2,
    ALPHA_START_DEATH = 3,
    ALPHA_SPEECH = 4,
    ALPHA_DEATH = 5,
    MAIN_OBJECTIVE = 6,
    POWER_DISTANCE_CHECK = 7,
    END_MISSION = 8
}

local TutorialState = {
    PRE_TUTORIAL = 1,
    START = 2,
    POWER_TUTORIAL = 3,
    WAIT_FOR_POWER = 4,
    MORPH_TUTORIAL = 5,
    WAIT_FOR_MORPH = 6,
    FINISH = 7
}

local YelenaState = {
    PATROL = 1,
    WATCH_FOR_ATTACKER = 2,
    WAIT_FOR_ATTACK_TO_END = 3,
}

local ISDFState = {
    WaveOne = 1,
    WaveTwo = 2,
    TugState = 3
}

local PlayerDistanceState = {
    CHECK_DISTANCE = 1,
    BAD_PLAYER = 2
}

local Mission = {
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    m_PlayerPilotODF = "fspilo_x",
    m_PlayerShipODF = "fvsent_x",

    m_Audioclip = nil,
    m_AudioTimer = 0,
    m_CutsceneAudioClip = nil,
    m_PowerClip = nil,
    m_MorphClip = nil,

    m_PlayersRecy = nil,
    m_Kiln = nil,
    m_Cons = nil,
    m_Power = nil,
    m_PowerTug = nil,

    m_PlayerPilo1 = nil,
    m_ShabPilo = nil,
    m_ShabPilo3 = nil,

    m_IntroShot2Look = nil,
    m_PilotsLook1 = nil,

    m_Yelena = nil,
    m_YelenaTarget = nil,
    m_YelenaState = YelenaState.PATROL,

    m_PlayerSentry1 = nil,
    m_PlayerSentry2 = nil,
    m_PlayerSentry3 = nil,
    m_PlayerSentry4 = nil,

    m_Alpha1 = nil,
    m_Alpha2 = nil,
    m_AlphaSpotted = false,

    m_PilotMoveTime = 0,
    m_PilotsMoved = false,
    m_IntroCutsceneDone = false,

    m_ShabRelook = false,
    m_ShabInShip = false,
    m_YelenaHandlersActive = false,
    m_YelenaUnderFire = false,
    m_YelenaPraise = false,
    m_YelenaPraiseDelay = 0,

    m_PowerObjectivesShown = false,
    m_MorphObjectivesShown = false,
    m_TugObjectiveShown = false,

    m_TriggerAlphaDeath = false,
    m_AlphaDeathStep = 0,

    m_PreTutorialStep = 0,

    m_PowerLunchTookTooLongTime = 0,
    m_PowerLungWarningActive = false,
    m_MorphTookTooLongTime = 0,
    m_MorphWarningActive = false,
    m_MorphTookTooLongWarningCount = 0,
    m_PlayerTookTooLongMorphing = false,

    m_Misl1 = nil,
    m_Misl2 = nil,

    m_Rocket1 = nil,
    m_Rocket2 = nil,
    m_Rocket3 = nil,
    m_Rocket4 = nil,
    m_Rocket5 = nil,
    m_Rocket6 = nil,
    m_Rocket7 = nil,

    m_ISDFWaveDelay = 0,
    m_ISDFHandlersActive = false,
    m_ISDFWaveSpawned = false,
    m_ISDFWeaponUpgradeChance = 0.15,

    m_ISDFAttacker1 = nil,
    m_ISDFAttacker2 = nil,
    m_ISDFAttacker3 = nil,
    m_ISDFAttacker4 = nil,
    m_ISDFTank1 = nil,
    m_ISDFTank2 = nil,
    m_ISDFTank3 = nil,
    m_ISDFTugTimer = 0,

    m_EnemyRecycler = nil,
    m_EnemyBaseDestroyed = false,
    m_EnemyBaseDestroyedDialoguePlayed = false,
    m_EnemyHasArmory = false,

    m_PlayerDistanceCheckerActive = true,
    m_PlayerDistanceWarningCount = 0,
    m_PlayerDistanceCheckerDelay = 0,

    m_PunishDelay = 0,
    m_PunishRocketTanksSent = false,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_MissionSuccess = false,
    m_CanFail = false,
    m_MissionPaused = false,

    m_MissionDelayTime = 0,

    m_CurrentPhase = MissionPhase.INTRO,
    m_IntroState = IntroState.SETUP,
    m_TutorialState = TutorialState.PRE_TUTORIAL,
    m_BaseState = BaseState.BASE_DIALOGUE,
    m_ISDFState = ISDFState.WaveOne,
    m_PlayerDistanceState = PlayerDistanceState.CHECK_DISTANCE
}

-- =========================
-- Helper Functions
-- =========================

local function playAudioWithDelay(clip, delay)
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles(clip)
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(delay)
end

local function createShab3Pilot()
    Mission.m_ShabPilo3 = BuildObject("fspilo_r", Mission.m_HostTeam, "shab_spawn2")
    SetMaxHealth(Mission.m_ShabPilo3, 0)
    SetCurHealth(Mission.m_ShabPilo3, 0)
    SetCanSnipe(Mission.m_ShabPilo3, 0)
    Retreat(Mission.m_ShabPilo3, Mission.m_Yelena)
end

local function handleFailureConditions()
    if (Mission.m_PowerLungWarningActive) then
        if (Mission.m_MissionTime > Mission.m_PowerLunchTookTooLongTime) then
            AddObjectiveOverride("scion0113_new.otf", "RED", 10, true, Mission.m_IsCooperativeMode)
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0136.wav")

            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("You must follow Yelena's orders and build a Lung on your Kiln.")
                DoGameover(10)
            else
                FailMission(GetTime() + 10, "scion01L6.txt")
            end

            Mission.m_MissionOver = true
        end
    end

    if (Mission.m_MissionTime > Mission.m_MorphTookTooLongTime) then
        if (Mission.m_MorphWarningActive) then
            if (Mission.m_MorphTookTooLongWarningCount == 0) then
                playAudioWithDelay("scion0104.wav", 5.5)
                Mission.m_MorphTookTooLongTime = Mission.m_MissionTime + SecondsToTurns(20)
                Mission.m_MorphTookTooLongWarningCount = Mission.m_MorphTookTooLongWarningCount + 1
            elseif (Mission.m_MorphTookTooLongWarningCount == 1) then
                Mission.m_PlayerTookTooLongMorphing = true
                Mission.m_MorphWarningActive = false
            end
        end
    end

    if (not IsAround(Mission.m_Power)) then
        playAudioWithDelay("scion0125.wav", 8.5)
        AddObjectiveOverride("scion0302.otf", "RED", 10, true, Mission.m_IsCooperativeMode)

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The Power Crystal was destroyed.")
            DoGameover(10)
        else
            FailMission(GetTime() + 10, "scion01L4.txt")
        end

        Mission.m_MissionOver = true
    end

    if (not IsAround(Mission.m_PlayersRecy)) then
        playAudioWithDelay("scion0399.wav", 3.5)
        AddObjectiveOverride("scion0305.otf", "RED", 10, true, Mission.m_IsCooperativeMode)

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The Matriarch was destroyed.")
            DoGameover(10)
        else
            FailMission(GetTime() + 10, "scion03L3.txt")
        end

        Mission.m_MissionOver = true
    end

    -- If the enemy tug has managed to escape with the Power Crystal.
    if (GetTug(Mission.m_Power) == Mission.m_PowerTug and GetDistance(Mission.m_Power, "tug_fail") < 75) then
        AddObjectiveOverride("scion0114_new.otf", "RED", 10, true, Mission.m_IsCooperativeMode)

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The ISDF escaped with the Power Crystal.")
            DoGameover(10)
        else
            FailMission(GetTime() + 10, "The ISDF escaped with the Power Crystal.")
        end

        Mission.m_MissionOver = true
    end
end

---@param targetHandle Handle
local function sendRocketTanksToTarget(targetHandle)
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

-- =========================
-- Phase-based State Machine
-- =========================

local IntroHandlers = {
    [IntroState.SETUP] = function()
        SetTeamNameForStat(Mission.m_AlliedTeam, "Scion")
        SetTeamNameForStat(Mission.m_EnemyTeam, "ISDF")

        for i = 2, 5 do
            Ally(Mission.m_HostTeam, i)
        end

        Mission.m_PlayersRecy = GetHandle("playersrecy")
        Mission.m_Kiln = GetHandle("playerskiln")
        Mission.m_Cons = GetHandle("playerbuilder")

        Mission.m_PlayerPilo1 = GetHandle("player_pilo1")
        Mission.m_ShabPilo = GetHandle("shab_pilo")

        Mission.m_IntroShot2Look = GetHandle("intro_shot2look")
        Mission.m_PilotsLook1 = GetHandle("pilots_look1")

        Mission.m_Alpha1 = GetHandle("alpha1")
        Mission.m_Alpha2 = GetHandle("alpha2")
        SetCanSnipe(Mission.m_Alpha1, 0)
        SetCanSnipe(Mission.m_Alpha2, 0)

        Mission.m_Misl1 = GetHandle("misl1")
        Mission.m_Misl2 = GetHandle("misl2")

        Stop(Mission.m_Alpha1, 1)
        Stop(Mission.m_Alpha2, 1)

        Patrol(Mission.m_Misl1, "misl1_patrol")
        Patrol(Mission.m_Misl2, "misl2_patrol")

        Mission.m_Yelena = GetHandle("unnamed_fvyelena_s")

        Mission.m_PlayerSentry1 = GetHandle("player_sentry_1")
        Mission.m_PlayerSentry2 = GetHandle("player_sentry_2")
        Mission.m_PlayerSentry3 = GetHandle("player_sentry_3")
        Mission.m_PlayerSentry4 = GetHandle("player_sentry_4")

        Mission.m_Rocket1 = GetHandle("ivrckt1")
        Mission.m_Rocket2 = GetHandle("ivrckt2")
        Mission.m_Rocket3 = GetHandle("ivrckt3")
        Mission.m_Rocket4 = GetHandle("ivrckt4")
        Mission.m_Rocket5 = GetHandle("ivrckt5")
        Mission.m_Rocket6 = GetHandle("ivrckt6")
        Mission.m_Rocket7 = GetHandle("ivrckt7")

        Mission.m_Power = GetHandle("power")
        Mission.m_PowerTug = GetHandle("power_tug")

        Mission.m_EnemyFactory = GetHandle("unnamed_ibfact_x")
        Mission.m_EnemyRecycler = GetHandle("recy1")
        Mission.m_CanFail = true

        -- Spawn some birds.
        for i = 1, 3 do
            SpawnBirds(i, GetRandomInt(3, 6), "mcwing01", 0, "birds_" .. i)
        end

        -- No need to store the Jaks that are moving around, they are just temporary.
        local Jak1 = BuildObject("mcjak01", 0, "jak_1")
        local Jak2 = BuildObject("mcjak01", 0, "jak_2")

        Patrol(Jak1, "jak_1_2_path")
        Follow(Jak2, Jak1)

        local Jak3 = BuildObject("mcjak01", 0, "jak_3")
        Patrol(Jak3, "jak_3_path")

        local Jak4 = BuildObject("mcjak01", 0, "jak_4")
        Patrol(Jak4, "jak_4_path")

        local Jak5 = BuildObject("mcjak01", 0, "jak_5")
        Patrol(Jak5, "jak_5_path")

        local Jak6 = BuildObject("mcjak01", 0, "jak_6")
        local Jak7 = BuildObject("mcjak01", 0, "jak_7")

        Patrol(Jak6, "jak_6_7_path")
        Follow(Jak7, Jak6)

        SetAIP("scion0101_x.aip", Mission.m_EnemyTeam)
        Pickup(Mission.m_PowerTug, Mission.m_Power)

        if (_Cooperative.m_TotalPlayerCount < 4) then
            if (Mission.m_PlayerSentry4) then RemoveObject(Mission.m_PlayerSentry4) end

            if (_Cooperative.m_TotalPlayerCount < 3) then
                if (Mission.m_PlayerSentry3) then RemoveObject(Mission.m_PlayerSentry3) end

                if (_Cooperative.m_TotalPlayerCount < 2) then
                    if (Mission.m_PlayerSentry2) then RemoveObject(Mission.m_PlayerSentry2) end
                end
            end
        end

        -- Small enhancement for enemy weapons on higher difficulties.
        Mission.m_ISDFWeaponUpgradeChance = 0.15 * Mission.m_MissionDifficulty

        _CPUManager.NewTeam(Mission.m_EnemyTeam, _BZCCDatabase.Factions.ISDF, "airecy", true)
        _Cooperative.CleanSpawns()

        if (Mission.m_IsCooperativeMode) then
            if (Mission.m_PlayerPilo1) then RemoveObject(Mission.m_PlayerPilo1) end
            if (Mission.m_ShabPilo) then RemoveObject(Mission.m_ShabPilo) end
            Mission.m_IntroState = IntroState.FINISH
        else
            if (Mission.m_PlayerPilo1) then LookAt(Mission.m_PlayerPilo1, Mission.m_ShabPilo) end
            if (Mission.m_ShabPilo) then LookAt(Mission.m_ShabPilo, Mission.m_PlayerPilo1) end
            Mission.m_IntroState = IntroState.CAMERA1
        end
    end,
    [IntroState.CAMERA1] = function()
        if (Mission.m_Cons) then Goto(Mission.m_Cons, "builder_path1", 1) end

        CameraReady()
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(17)
        Mission.m_IntroState = IntroState.CAMERA2
    end,
    [IntroState.CAMERA2] = function()
        CameraPath("intro_shot1_path", 500, 1000, Mission.m_ShabPilo)

        if (Mission.m_MissionTime < Mission.m_MissionDelayTime) then
            return
        end

        if (Mission.m_PlayerPilo1) then Retreat(Mission.m_PlayerPilo1, "player_pilo_path") end
        if (Mission.m_ShabPilo) then Retreat(Mission.m_ShabPilo, "shab_pilo_path") end
        if (Mission.m_Cons) then Goto(Mission.m_Cons, "builder_path2", 1) end

        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5)
        Mission.m_IntroState = IntroState.CAMERA3
    end,
    [IntroState.CAMERA3] = function()
        CameraPath("intro_shot2_path", 500, 0, Mission.m_IntroShot2Look)

        if (Mission.m_MissionTime < Mission.m_MissionDelayTime) then
            return
        end

        RemoveObject(Mission.m_PlayerPilo1)
        RemoveObject(Mission.m_ShabPilo)

        Mission.m_CutsceneAudioClip = _Subtitles.AudioWithSubtitles("cutsc0101.wav",
            _BZCCDatabase.SubtitlePanelSizes.SubtitlesPanelMedium)
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(28)
        Mission.m_IntroState = IntroState.CAMERA4
    end,
    [IntroState.CAMERA4] = function()
        CameraPath("intro_shot3_path", 1500, 100, Mission.m_Kiln)

        if (Mission.m_MissionTime < Mission.m_MissionDelayTime) then
            return
        end

        Mission.m_PlayerPilo1 = BuildObject("fspilo_xs01", 0, "player_pilo_spawn")
        Mission.m_ShabPilo = BuildObject("fspilo_rs01", 0, "shab_pilo_spawn")

        LookAt(Mission.m_PlayerPilo1, Mission.m_PilotsLook1)
        LookAt(Mission.m_ShabPilo, Mission.m_PilotsLook1)

        Mission.m_PilotMoveTime = Mission.m_MissionTime + SecondsToTurns(5)
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(18)
        Mission.m_IntroState = IntroState.PILOT_WALK
    end,
    [IntroState.PILOT_WALK] = function()
        CameraPath("intro_shot4_path", 200, 0, Mission.m_PlayerPilo1)

        if (not Mission.m_PilotsMoved and Mission.m_MissionTime > Mission.m_PilotMoveTime) then
            Retreat(Mission.m_PlayerPilo1, "player_move")
            Retreat(Mission.m_ShabPilo, "shab_move")
            Mission.m_PilotsMoved = true
        end

        if (Mission.m_MissionTime < Mission.m_MissionDelayTime) then
            return
        end

        CameraFinish()
        createShab3Pilot()

        RemoveObject(Mission.m_PlayerPilo1)
        RemoveObject(Mission.m_ShabPilo)
        SetScrap(Mission.m_HostTeam, 0)
        Mission.m_IntroCutsceneDone = true
        Mission.m_IntroState = IntroState.YELENA_IN_SHIP
    end,
    [IntroState.YELENA_IN_SHIP] = function()
        if (Mission.m_ShabInShip) then
            SetObjectiveName(Mission.m_Yelena, "Yelena")
            SetObjectiveOn(Mission.m_Yelena)
            SetCanSnipe(Mission.m_Yelena, 0)
            SetSkill(Mission.m_Yelena, 3)

            LookAt(Mission.m_Yelena, Mission.m_MainPlayer)
            LookAt(Mission.m_Alpha1, Mission.m_Yelena)
            LookAt(Mission.m_Alpha2, Mission.m_Yelena)

            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3)
            Mission.m_IntroState = IntroState.FINISH
        end
    end,
    [IntroState.FINISH] = function()
        Mission.m_CurrentPhase = MissionPhase.TUTORIAL
    end
}

local TutorialHandlers = {
    [TutorialState.PRE_TUTORIAL] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

        if (Mission.m_PreTutorialStep == 0) then
            playAudioWithDelay("scion0101_new.wav", 11.5)
            Mission.m_PreTutorialStep = Mission.m_PreTutorialStep + 1
        elseif (Mission.m_PreTutorialStep == 1) then
            LookAt(Mission.m_Yelena, Mission.m_Alpha1)
            playAudioWithDelay("scion0307.wav", 2.5)
            Mission.m_PreTutorialStep = Mission.m_PreTutorialStep + 1
        elseif (Mission.m_PreTutorialStep == 2) then
            playAudioWithDelay("scion0308.wav", 7.5)
            Mission.m_PreTutorialStep = Mission.m_PreTutorialStep + 1
        elseif (Mission.m_PreTutorialStep == 3) then
            playAudioWithDelay("scion0309.wav", 1.5)
            Mission.m_PreTutorialStep = Mission.m_PreTutorialStep + 1
        else
            SetPerceivedTeam(Mission.m_Alpha1, Mission.m_EnemyTeam)
            SetPerceivedTeam(Mission.m_Alpha2, Mission.m_EnemyTeam)
            SetIndependence(Mission.m_Alpha2, 0)
            Retreat(Mission.m_Alpha1, "alphapath")
            Follow(Mission.m_Alpha2, Mission.m_Alpha1)
            Mission.m_TutorialState = TutorialState.START
        end
    end,
    [TutorialState.START] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end

        LookAt(Mission.m_Yelena, Mission.m_MainPlayer)
        Mission.m_TutorialState = TutorialState.POWER_TUTORIAL
    end,
    [TutorialState.POWER_TUTORIAL] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

        Stop(Mission.m_Cons, 0)
        SetBestGroup(Mission.m_Cons)
        Mission.m_PowerClip = _Subtitles.AudioWithSubtitles("scion0106.wav",
            _BZCCDatabase.SubtitlePanelSizes.SubtitlesPanelMedium)
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(26.5)
        Mission.m_TutorialState = TutorialState.WAIT_FOR_POWER
    end,
    [TutorialState.WAIT_FOR_POWER] = function()
        if (IsPowered(Mission.m_Kiln)) then
            StopAudioMessage(Mission.m_PowerClip)
            AddObjectiveOverride("scion0113_new.otf", "GREEN", 10, true, Mission.m_IsCooperativeMode)

            Mission.m_PowerLungWarningActive = false
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2)
            Mission.m_TutorialState = TutorialState.MORPH_TUTORIAL
            return
        end

        if (not Mission.m_PowerObjectivesShown) then
            if (IsAudioMessageFinished(Mission.m_PowerClip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                AddObjectiveOverride("scion0113_new.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
                Mission.m_PowerLungWarningActive = true
                Mission.m_PowerLunchTookTooLongTime = Mission.m_MissionTime + SecondsToTurns(90)
                Mission.m_PowerObjectivesShown = true
            end
        end
    end,
    [TutorialState.MORPH_TUTORIAL] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        Mission.m_MorphClip = _Subtitles.AudioWithSubtitles("scion0102.wav")
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(13.5)
        Mission.m_TutorialState = TutorialState.WAIT_FOR_MORPH
    end,
    [TutorialState.WAIT_FOR_MORPH] = function()
        local isPlayerDeployed = false

        if (not Mission.m_MorphObjectivesShown) then
            if (IsAudioMessageFinished(Mission.m_MorphClip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                AddObjectiveOverride("scion0110_new.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
                Mission.m_MorphWarningActive = true
                Mission.m_MorphTookTooLongTime = Mission.m_MissionTime + SecondsToTurns(40)
                Mission.m_MorphObjectivesShown = true
            end
        end

        for i = 1, _Cooperative.m_TotalPlayerCount do
            local playerHandle = GetPlayerHandle(i)
            if (IsDeployed(playerHandle)) then
                isPlayerDeployed = true
                break
            end
        end

        if (isPlayerDeployed or Mission.m_PlayerTookTooLongMorphing) then
            if (isPlayerDeployed) then
                StopAudioMessage(Mission.m_MorphClip)
                AddObjectiveOverride("scion0110_new.otf", "GREEN", 10, true, Mission.m_IsCooperativeMode)
                playAudioWithDelay("scion0103.wav", 17.5)
                Mission.m_MorphWarningActive = false
            else
                playAudioWithDelay("scion0118.wav", 9.5)
            end

            Mission.m_TutorialState = TutorialState.FINISH
        end
    end,
    [TutorialState.FINISH] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end
        Mission.m_CurrentPhase = MissionPhase.BASE
    end
}

local BaseHandlers = {
    [BaseState.BASE_DIALOGUE] = function()
        playAudioWithDelay("scion0310.wav", 6.5)
        Mission.m_BaseState = BaseState.BASE_OBJECTIVE
    end,
    [BaseState.BASE_OBJECTIVE] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

        AddObjectiveOverride("scion0304.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)

        Mission.m_ISDFWaveDelay = Mission.m_MissionTime + SecondsToTurns(10)
        Mission.m_YelenaHandlersActive = true
        Mission.m_ISDFHandlersActive = true
        Mission.m_BaseState = BaseState.ALPHA_START_DEATH
    end,
    [BaseState.ALPHA_START_DEATH] = function()
        if (not Mission.m_TriggerAlphaDeath) then return end
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end

        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3)

        SetPerceivedTeam(Mission.m_Alpha1, 1)
        SetPerceivedTeam(Mission.m_Alpha2, 1)

        SetIndependence(Mission.m_Alpha1, 1)
        SetIndependence(Mission.m_Alpha2, 1)

        Goto(Mission.m_Alpha1, "enemybase")
        Goto(Mission.m_Alpha2, "enemybase")

        Attack(Mission.m_Misl1, Mission.m_Alpha1)
        Attack(Mission.m_Misl2, Mission.m_Alpha2)

        Mission.m_PlayerDistanceCheckerActive = false
        Mission.m_AlphaSpotted = true
        Mission.m_BaseState = BaseState.ALPHA_SPEECH
    end,
    [BaseState.ALPHA_SPEECH] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        playAudioWithDelay("scion0311.wav", 7.5)
        Mission.m_BaseState = BaseState.ALPHA_DEATH
    end,
    [BaseState.ALPHA_DEATH] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

        if (Mission.m_AlphaDeathStep == 0) then
            LookAt(Mission.m_Yelena, Mission.m_Alpha1)
            playAudioWithDelay("scion0312.wav", 4.5)

            Mission.m_YelenaHandlersActive = false
            Mission.m_AlphaDeathStep = Mission.m_AlphaDeathStep + 1
        elseif (Mission.m_AlphaDeathStep == 1) then
            playAudioWithDelay("scion0313.wav", 5.5)
            Mission.m_AlphaDeathStep = Mission.m_AlphaDeathStep + 1
        elseif (Mission.m_AlphaDeathStep == 2) then
            if (not IsAlive(Mission.m_Alpha1) and not IsAlive(Mission.m_Alpha2)) then
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(6);

                SetAIP("scion0102_x.aip", Mission.m_EnemyTeam)
                Patrol(Mission.m_Misl1, "misl1_patrol")
                Patrol(Mission.m_Misl2, "misl2_patrol")

                Mission.m_AlphaDeathStep = Mission.m_AlphaDeathStep + 1
            end
        elseif (Mission.m_AlphaDeathStep == 3) then
            playAudioWithDelay("scion0314.wav", 5.5)

            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(10)
            Mission.m_AlphaDeathStep = Mission.m_AlphaDeathStep + 1
        elseif (Mission.m_AlphaDeathStep == 4) then
            LookAt(Mission.m_Yelena, Mission.m_MainPlayer)

            playAudioWithDelay("scion0301.wav", 20.5)
            Mission.m_AlphaDeathStep = Mission.m_AlphaDeathStep + 1
        elseif (Mission.m_AlphaDeathStep == 5) then
            AddObjectiveOverride("scion0301.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)

            Mission.m_Nav1 = BuildObject("ibnav", Mission.m_HostTeam, "nav1")
            SetObjectiveName(Mission.m_Nav1, TranslateString("MissionS0301"))
            SetObjectiveOn(Mission.m_Nav1)
            SetObjectiveOn(Mission.m_Power)

            Mission.m_YelenaState = YelenaState.PATROL
            Mission.m_YelenaHandlersActive = true
            Mission.m_BaseState = BaseState.MAIN_OBJECTIVE
        end
    end,
    [BaseState.MAIN_OBJECTIVE] = function()
        if (Mission.m_MissionTime % SecondsToTurns(0.5) ~= 0) then
            return
        end

        if (not IsAround(Mission.m_EnemyRecycler) and not Mission.m_EnemyBaseDestroyed) then
            Mission.m_EnemyBaseDestroyed = true
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2)
        elseif (Mission.m_EnemyBaseDestroyed and not Mission.m_EnemyBaseDestroyedDialoguePlayed) then
            if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
            playAudioWithDelay("scion0303.wav", 5.5)

            if (IsAliveAndEnemy(Mission.m_PowerTug, Mission.m_EnemyTeam)) then
                AddObjective("scion0114_new.otf", "WHITE", 10)
                Mission.m_TugObjectiveShown = true
            end

            Mission.m_EnemyBaseDestroyedDialoguePlayed = true
        end

        local powerTug = GetTug(Mission.m_Power)

        if (powerTug == nil) then
            return
        end

        if (not IsAlive(powerTug)) then
            return
        end

        local tugTeam = GetTeamNum(powerTug)

        -- Ensure that the tug is either on team 1, 2, 3, or 4.
        -- If it's on team 5 (allied) or 6 (enemy), it means the tug is currently not being controlled by a player and we shouldn't trigger the dialogue.
        if (tugTeam >= Mission.m_HostTeam and tugTeam < Mission.m_AlliedTeam) then
            playAudioWithDelay("scion0302.wav", 5.5)
            SetObjectiveOff(Mission.m_Nav1)
            sendRocketTanksToTarget(powerTug)
            Mission.m_BaseState = BaseState.POWER_DISTANCE_CHECK
        end
    end,
    [BaseState.POWER_DISTANCE_CHECK] = function()
        if (Mission.m_MissionTime % SecondsToTurns(0.5) ~= 0) then
            return
        end

        if (GetDistance(Mission.m_Power, Mission.m_PlayersRecy) < 125) then
            playAudioWithDelay("scion0135.wav", 3.5)
            Mission.m_BaseState = BaseState.END_MISSION
        end
    end,
    [BaseState.END_MISSION] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            return
        end

        AddObjectiveOverride("scion0303.otf", "GREEN", 10, true, Mission.m_IsCooperativeMode)

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.")
            DoGameover(6);
        else
            SucceedMission(GetTime() + 6, "scion03w1.txt")
        end

        Mission.m_MissionOver = true
    end
}

-- =========================
-- CPU Brain Handlers
-- =========================

local YelenaHandlers = {
    [YelenaState.PATROL] = function()
        Patrol(Mission.m_Yelena, "shab_patrol")
        Mission.m_YelenaState = YelenaState.WATCH_FOR_ATTACKER
    end,
    [YelenaState.WATCH_FOR_ATTACKER] = function()
        if (not Mission.m_YelenaPraise and Mission.m_YelenaUnderFire and Mission.m_YelenaPraiseDelay < Mission.m_MissionTime) then
            playAudioWithDelay("scion0108.wav", 3.5)
            Mission.m_YelenaPraise = true
        end

        Mission.m_YelenaTarget = GetNearestEnemy(Mission.m_Yelena, true, true, 125)

        if (IsAlive(Mission.m_YelenaTarget)) then
            Attack(Mission.m_Yelena, Mission.m_YelenaTarget)
            Mission.m_YelenaState = YelenaState.WAIT_FOR_ATTACK_TO_END
        end
    end,
    [YelenaState.WAIT_FOR_ATTACK_TO_END] = function()
        if (not Mission.m_YelenaUnderFire) then
            playAudioWithDelay("scion0107.wav", 3.5)
            Mission.m_YelenaUnderFire = true
        end

        -- If she's too far chasing a target, reset and return to base.
        if (GetDistance(Mission.m_Yelena, Mission.m_PlayersRecy) > 400) then
            Mission.m_YelenaState = YelenaState.PATROL
            Mission.m_YelenaTarget = nil
            return
        end

        if (not IsAlive(Mission.m_YelenaTarget)) then
            Mission.m_YelenaTarget = GetNearestEnemy(Mission.m_Yelena, true, true, 125)

            if (IsAlive(Mission.m_YelenaTarget)) then
                Attack(Mission.m_Yelena, Mission.m_YelenaTarget)
            else
                if (not Mission.m_YelenaPraise) then
                    Mission.m_YelenaPraiseDelay = Mission.m_MissionTime + SecondsToTurns(1.3)
                end

                Mission.m_YelenaState = YelenaState.PATROL
            end
        end
    end
}

local ISDFHandlers = {
    [ISDFState.WaveOne] = function()
        if (Mission.m_ISDFWaveDelay > Mission.m_MissionTime) then return end

        if (not Mission.m_ISDFWaveSpawned) then
            local Wave1Unit_A = { "ivscout_x", "ivmisl_x", "ivtank_x" }
            local Wave1Unit_B = { "ivscout_x", "ivscout_x", "ivmisl_x" }

            Mission.m_ISDFAttacker1 = BuildObject(Wave1Unit_A[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
                GetPositionNear("enemybase", 15, 35))
            Mission.m_ISDFAttacker2 = BuildObject(Wave1Unit_B[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
                GetPositionNear("enemybase", 15, 35))
            Goto(Mission.m_ISDFAttacker1, "attack1_path")
            Goto(Mission.m_ISDFAttacker2, "attack2_path")

            if (Mission.m_MissionDifficulty > _BZCCDatabase.Difficulty.DIFFICULTY_EASY) then
                Mission.m_ISDFAttacker3 = BuildObject("ivscout_x", Mission.m_EnemyTeam,
                    GetPositionNear("enemybase", 15, 35))
                Goto(Mission.m_ISDFAttacker3, "attack1_path")

                if (Mission.m_MissionDifficulty > _BZCCDatabase.Difficulty.DIFFICULTY_MEDIUM) then
                    GiveWeapon(Mission.m_ISDFAttacker3, "gchain_c")

                    Mission.m_ISDFAttacker4 = BuildObject("ivmbike_x", Mission.m_EnemyTeam,
                        GetPositionNear("enemybase", 15, 35))
                    Goto(Mission.m_ISDFAttacker4, "attack2_path")
                end
            end

            Mission.m_ISDFWaveSpawned = true
        elseif (not IsAliveAndEnemy(Mission.m_ISDFAttacker1, Mission.m_EnemyTeam)
                and not IsAliveAndEnemy(Mission.m_ISDFAttacker2, Mission.m_EnemyTeam)
                and not IsAliveAndEnemy(Mission.m_ISDFAttacker3, Mission.m_EnemyTeam)
                and not IsAliveAndEnemy(Mission.m_ISDFAttacker4, Mission.m_EnemyTeam)) then
            Mission.m_ISDFWaveDelay = Mission.m_MissionTime + SecondsToTurns(60)
            Mission.m_ISDFWaveSpawned = false
            Mission.m_ISDFState = ISDFState.WaveTwo
        end
    end,
    [ISDFState.WaveTwo] = function()
        if (Mission.m_ISDFWaveDelay > Mission.m_MissionTime) then return end

        if (not Mission.m_ISDFWaveSpawned) then
            local Wave2Unit_A = { "ivmisl_x", "ivtank_x", "ivtank_x" }
            local Wave2Unit_B = { "ivscout_x", "ivmisl_x", "ivtank_x" }

            Mission.m_ISDFAttacker1 = BuildObject(Wave2Unit_A[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
                GetPositionNear("enemybase", 15, 35))
            Mission.m_ISDFAttacker2 = BuildObject(Wave2Unit_B[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
                GetPositionNear("enemybase", 15, 35))
            Goto(Mission.m_ISDFAttacker1, "attack1_path")
            Goto(Mission.m_ISDFAttacker2, "attack2_path")

            if (Mission.m_MissionDifficulty > _BZCCDatabase.Difficulty.DIFFICULTY_EASY) then
                Mission.m_ISDFAttacker3 = BuildObject("ivscout_x", Mission.m_EnemyTeam,
                    GetPositionNear("enemybase", 15, 35))
                Goto(Mission.m_ISDFAttacker3, "attack1_path")

                if (Mission.m_MissionDifficulty > _BZCCDatabase.Difficulty.DIFFICULTY_MEDIUM) then
                    GiveWeapon(Mission.m_ISDFAttacker3, "gchain_c")

                    Mission.m_ISDFAttacker4 = BuildObject("ivmbike_x", Mission.m_EnemyTeam,
                        GetPositionNear("enemybase", 15, 35))
                    Goto(Mission.m_ISDFAttacker4, "attack2_path")
                end
            end

            Mission.m_ISDFWaveSpawned = true
        elseif (not IsAliveAndEnemy(Mission.m_ISDFAttacker1, Mission.m_EnemyTeam)
                and not IsAliveAndEnemy(Mission.m_ISDFAttacker2, Mission.m_EnemyTeam)
                and not IsAliveAndEnemy(Mission.m_ISDFAttacker3, Mission.m_EnemyTeam)
                and not IsAliveAndEnemy(Mission.m_ISDFAttacker4, Mission.m_EnemyTeam)) then
            Mission.m_ISDFState = ISDFState.TugState
            Mission.m_TriggerAlphaDeath = true
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(8)
        end
    end,
    [ISDFState.TugState] = function()
        -- Shut this down if the tug dies.
        if (not IsAlive(Mission.m_PowerTug)) then
            Mission.m_ISDFHandlersActive = false
            return
        end

        -- Abort if on easy, we aren't running anywhere.
        if (Mission.m_MissionDifficulty < _BZCCDatabase.Difficulty.DIFFICULTY_MEDIUM) then
            return
        end

        -- Abort if the tug timer is in effect.
        if (Mission.m_ISDFTugTimer > Mission.m_MissionTime) then
            return
        end

        -- Repeat every 2 seconds.
        Mission.m_ISDFTugTimer = Mission.m_MissionTime + SecondsToTurns(2)

        -- Check if the Tug has the Power Crystal every so often.
        local crystalTug = GetTug(Mission.m_Power)

        -- Check if the tug is null first.
        if (crystalTug == nil) then
            Pickup(Mission.m_PowerTug, Mission.m_Power)
            return
        end

        if (crystalTug == Mission.m_PowerTug and not IsAround(Mission.m_EnemyRecycler)) then
            Retreat(Mission.m_PowerTug, "tug_run")
            return
        end
    end
}

local PlayerDistanceHandlers = {
    [PlayerDistanceState.CHECK_DISTANCE] = function()
        if (Mission.m_MissionTime % SecondsToTurns(0.5) ~= 0) then
            return
        end

        for i = 1, _Cooperative.m_TotalPlayerCount do
            local handle = GetPlayerHandle(i)

            if (not IsAlive(handle)) then
                Mission.m_BadPlayer = nil
                Mission.m_MissionPaused = false
            else
                if (Mission.m_MissionPaused and handle == Mission.m_BadPlayer) then
                    if (GetDistance(handle, Mission.m_PlayersRecy) < 500) then
                        Mission.m_BadPlayer = nil
                        Mission.m_MissionPaused = false
                    end
                end

                if (GetDistance(handle, Mission.m_PlayersRecy) >= 500) then
                    Mission.m_MissionPaused = true
                    Mission.m_BadPlayer = handle

                    if (Mission.m_PlayerDistanceCheckerDelay < Mission.m_MissionTime) then
                        StopAudioMessage(Mission.m_Audioclip)
                        Mission.m_AudioTimer = 0

                        if (Mission.m_PlayerDistanceWarningCount == 0) then
                            Mission.m_PlayerDistanceCheckerDelay = Mission.m_MissionTime + SecondsToTurns(20)
                            playAudioWithDelay("scion0315.wav", 7.5)
                        elseif (Mission.m_PlayerDistanceWarningCount == 1) then
                            Mission.m_PlayerDistanceCheckerDelay = Mission.m_MissionTime + SecondsToTurns(25)
                            playAudioWithDelay("scion0316.wav", 5.5)
                        else
                            Mission.m_PlayerDistanceState = PlayerDistanceState.BAD_PLAYER
                        end

                        Mission.m_PlayerDistanceWarningCount = Mission.m_PlayerDistanceWarningCount + 1
                    end
                end
            end
        end
    end,
    [PlayerDistanceState.BAD_PLAYER] = function()
        if (not Mission.m_PunishRocketTanksSent) then
            sendRocketTanksToTarget(Mission.m_PlayersRecy)
            Mission.m_PunishRocketTanksSent = true
        end

        if (Mission.m_PunishDelay < Mission.m_MissionTime) then
            for i = 1, 12 do
                local handle = nil

                if (i % 2 == 0) then
                    handle = BuildObjectAtSafePath("ivtank_x", Mission.m_EnemyTeam, "punish_2", "spawn2",
                        _Cooperative.m_TotalPlayerCount)
                else
                    handle = BuildObjectAtSafePath("ivtank_x", Mission.m_EnemyTeam, "punish_1", "spawn1",
                        _Cooperative.m_TotalPlayerCount)
                end

                GiveWeapon(handle, "gspstab_c")
                Attack(handle, Mission.m_PlayersRecy, 1)
            end

            Mission.m_PunishDelay = Mission.m_MissionTime + SecondsToTurns(20)
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

    -- Set difficulty based on whether it's coop or not.
    if (Mission.m_IsCooperativeMode) then
        Mission.m_MissionDifficulty = GetVarItemInt("network.session.ivar102") + 1;
    else
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1;
    end
end

function Save()
    return _SaveLoad.Save(), Mission
end

function Load(ModuleData, MissionData)
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();

    if (MissionData) then
        for k, v in pairs(MissionData) do
            Mission[k] = v
        end
    end

    if (ModuleData) then
		_SaveLoad.Load(ModuleData)
	else
		print("WARNING: No ModuleData provided to _SaveLoad.Load()")
	end
end

function AddObject(handle)
    local teamNum = GetTeamNum(handle)

    if (teamNum == Mission.m_EnemyTeam) then
        if (GetClassLabel(handle) == "CLASS_ARMORY") then
            Mission.m_EnemyHasArmory = true
        end

        if (Mission.m_EnemyHasArmory and GetRandomFloat(1) < Mission.m_ISDFWeaponUpgradeChance) then
            local cfg = GetCfg(handle)

            if (cfg == "ivtank_x" or cfg == "ivtank_d") then
                PrintConsoleMessage("Lottery winner! ISDF unit has won a weapon upgrade.")
                GiveWeapon(handle, "gspstab_c")
            elseif (cfg == "ivscout_x") then
                PrintConsoleMessage("Lottery winner! ISDF unit has won a weapon upgrade.")
                GiveWeapon(handle, "gchain_c")
            elseif (cfg == "ivmisl_x") then
                PrintConsoleMessage("Lottery winner! ISDF unit has won a weapon upgrade.")
                GiveWeapon(handle, "gshadow_c")
            end
        end

        if (Mission.m_MissionTime > 2) then
            _CPUManager.AddTeamObject(handle, Mission.m_MissionTime, teamNum)
        end
        SetSkill(handle, Mission.m_MissionDifficulty)
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        SetSkill(handle, 3)
    end
end

function DeleteObject(handle)
    local teamNum = GetTeamNum(handle)

    if (handle == Mission.m_PowerTug) then
        if (Mission.m_TugObjectiveShown) then
            AddObjectiveOverride("scion0301.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
            AddObjective("scion0114_new.otf", "GREEN", 10)
        end
    end

    if (teamNum == Mission.m_EnemyTeam) then
        if (GetClassLabel(handle) == "CLASS_ARMORY") then
            Mission.m_EnemyHasArmory = false
        end

        _CPUManager.RemoveTeamObject(handle, teamNum)
    end
end

function Start()
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

    if (not Mission.m_MissionOver) then
        if (Mission.m_StartDone and not Mission.m_MissionPaused) then
            if (Mission.m_CurrentPhase == MissionPhase.INTRO) then
                IntroHandlers[Mission.m_IntroState]()
            elseif (Mission.m_CurrentPhase == MissionPhase.TUTORIAL) then
                TutorialHandlers[Mission.m_TutorialState]()
            elseif (Mission.m_CurrentPhase == MissionPhase.BASE) then
                BaseHandlers[Mission.m_BaseState]()
            end
        end

        _CPUManager.Run(Mission.m_MissionTime)

        if (Mission.m_PlayerDistanceCheckerActive) then PlayerDistanceHandlers[Mission.m_PlayerDistanceState]() end
        if (Mission.m_YelenaHandlersActive) then YelenaHandlers[Mission.m_YelenaState]() end
        if (Mission.m_ISDFHandlersActive) then ISDFHandlers[Mission.m_ISDFState]() end
        if (Mission.m_CanFail) then handleFailureConditions() end
    end

    if (not Mission.m_IsCooperativeMode and not Mission.m_IntroCutsceneDone) then
        if (CameraCancelled()) then
            Mission.m_IntroCutsceneDone = true

            if (IsAround(Mission.m_PlayerPilo1)) then RemoveObject(Mission.m_PlayerPilo1) end
            if (IsAround(Mission.m_ShabPilo)) then RemoveObject(Mission.m_ShabPilo) end
            if (IsAround(Mission.m_ShabPilo3)) then RemoveObject(Mission.m_ShabPilo3) end
            if (IsAround(Mission.m_Cons)) then Goto(Mission.m_Cons, "builder_path2", 0) end

            if (not IsAudioMessageDone(Mission.m_CutsceneAudioClip)) then
                StopAudioMessage(Mission.m_CutsceneAudioClip)
            end

            CameraFinish()
            createShab3Pilot()
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
    if (not Mission.m_ShabInShip) then
        if (pilotHandle == Mission.m_ShabPilo3 and emptyCraftHandle == Mission.m_Yelena) then
            Mission.m_ShabInShip = true
        end
    elseif (not Mission.m_ShabRelook) then
        if (emptyCraftHandle == Mission.m_PlayerSentry1 or emptyCraftHandle == Mission.m_PlayerSentry2 or emptyCraftHandle == Mission.m_PlayerSentry3 or emptyCraftHandle == Mission.m_PlayerSentry4) then
            if (Mission.m_Yelena) then LookAt(Mission.m_Yelena, emptyCraftHandle) end
            Mission.m_ShabRelook = true
        end
    end

    return _Cooperative.PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
end

function RespawnPilot(DeadObjectHandle, Team)
    return _Cooperative.RespawnPilot(DeadObjectHandle, Team, Mission.m_PlayerPilotODF);
end

function DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI)
    return _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI, Mission.m_PlayerPilotODF);
end

function PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
    -- Check to see if this unit is engaging Yelena. If it is, switch targets as she's unkillable.
    if (OrdnanceTeam ~= Mission.m_EnemyTeam and GetTeamNum(VictimHandle) == Mission.m_EnemyTeam) then
        -- If it's Yelena triggering this, stop.
        if (ShooterHandle == Mission.m_Yelena) then
            return
        end

        -- Grab our current target.
        local currentTarget = GetTarget(VictimHandle)

        -- If it's alive (just to be sure).
        if (not IsAlive(currentTarget)) then
            return
        end

        -- If we are currently targeting Yelena, switch.
        if (currentTarget == Mission.m_Yelena) then
            -- Switch to another target.
            Attack(VictimHandle, ShooterHandle)
        end
    end

    if (IsPlayer(ShooterHandle) and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (IsAlive(Mission.m_Yelena) and VictimHandle == Mission.m_Yelena) then
            playAudioWithDelay("scngen30.wav", 3.5)
        end

        if (not Mission.m_AlphaSpotted) then
            if (VictimHandle == Mission.m_Alpha1 or VictimHandle == Mission.m_Alpha2) then
                if (GetCurrentHealth(VictimHandle) < 150) then
                    -- Stop the mission.
                    Mission.m_MissionOver = true

                    -- Mission failed.
                    playAudioWithDelay("scngen08.wav", 3.5)

                    -- Objectives.
                    AddObjectiveOverride("scion0306.otf", "RED", 15, true)

                    -- Failure.
                    if (Mission.m_IsCooperativeMode) then
                        NoteGameoverWithCustomMessage("Friendly fire will not be tolerated.")
                        DoGameover(15)
                    else
                        FailMission(GetTime() + 15, "scion03L1.txt")
                    end
                end
            end
        end
    end
end
