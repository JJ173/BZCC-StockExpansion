--[[
    BZCC Scion01 Lua Mission Script
    Written by AI_Unit
    Version 1.0 18-05-2025

    Mission Flow:
    - Handles intro cutscene, player/AI setup, and a multi-phase escort/defense mission.
    - Uses a state machine (Functions[n]) for mission progression.
    - Key events: player morphing, base defense, ISDF attack waves, escorting a hauler, ambush, and a rockslide event.
    - Cooperative and single-player supported.
    - See constants and helper functions for tuning and repeated logic.
--]]

require("_GlobalVariables")
require("_HelperFunctions")

local _Cooperative = require("_Cooperative")
local _Subtitles = require('_Subtitles')

-- =========================
-- Variables
-- =========================

local m_GameTPS = GetTPS()
local m_MissionName = "Scion01: Transformation"
local m_WaveCooldowns = { 45, 60, 75, 90 }

local m_WaveAttackers = {
    { { "ivscout_x", "ivscout_x" },            { "ivmisl_x", "ivscout_x" },             { "ivtank_x", "ivscout_x" } },                        -- Attack 1
    { { "ivscout_x", "ivmisl_x" },             { "ivmisl_x", "ivtank_x" },              { "ivtank_x", "ivscout_x", "ivmbike_x" } },           -- Attack 2
    { { "ivtank_x", "ivmisl_x" },              { "ivtank_x", "ivtank_x", "ivscout_x" }, { "ivtank_x", "ivtank_x", "ivrckt_x", "ivmisl_x" } }, -- Attack 3
    { { "ivtank_x", "ivscout_x", "ivmisl_x" }, { "ivtank_x", "ivtank_x", "ivrckt_x" },  { "ivrckt_x", "ivtank_x", "ivatank_x", "ivtank_x" } } -- Attack 4
}

local m_Ambush1 = {
    { "ivscout_x", "ivscout_x", "ivtank_x" },
    { "ivscout_x", "ivmisl_x",  "ivtank_x" },
    { "ivmbike_x", "ivtank_x",  "ivtank_x" }
}

local m_Ambush2 = {
    { "ivtank_x", "ivscout_x", "ivmisl_x", "ivscout_x" },
    { "ivtank_x", "ivmbike_x", "ivtank_x", "ivmbike_x" },
    { "ivtank_x", "ivtank_x",  "ivtank_x", "ivtank_x" }
}

local MissionPhase = {
    INTRO = 1,
    POWERUP = 2,
    DEFENSE = 3,
    ESCORT = 4,
    PLAYER_ESCORT = 5,
    ROCKSLIDE = 6,
    END = 7
}

local IntroState = {
    SETUP = 1,
    CAMERA1 = 2,
    CAMERA2 = 3,
    CAMERA3 = 4,
    CAMERA4 = 5,
    PILOT_WALK = 6,
    PILOT_MOVE = 7,
    FINISH = 8
}

local PowerupState = {
    START = 1,
    WAIT_FOR_POWER_AUDIO = 2,
    WAIT_FOR_POWER = 3,
    WAIT_FOR_MORPH_AUDIO = 4,
    WAIT_FOR_MORPH = 5,
    FINISH = 6
}

local DefenseState = {
    START = 1,
    WAIT_FOR_AUDIO = 2,
    WAIT_FOR_OBJECTIVE = 3,
    FINISH = 4
}

local EscortState = {
    SPAWN_DELTA = 1,
    PICKUP_CRYSTAL = 2,
    DELTA_FORMATION = 3,
    ESCORT_TO_RONDEVOUZ = 4,
    MEET_AT_RONDEVOUZ = 5,
    YELENA_CONFIRM = 6,
    AMBUSH_ATTACK = 7,
    AMBUSH_DEFEATED = 8,
    DELTA_RETREAT = 9,
    PLAYER_ESCORT = 10,
    FINISH = 11
}

local PlayerEscortState = {
    ESCORT = 1,
    FINISH = 2
}

local RockslideState = {
    WAIT_FOR_TRIGGER = 1,
    LANDSLIDE_ANIMATION = 2,
    CAMERA1 = 3,
    CAMERA2 = 4,
    CAMERA3 = 5,
    POST_ROCKSLIDE = 6,
    AUDIO = 7,
    AMBUSH = 8,
    YELENA_AUDIO = 9,
    PLAYER_INVESTIGATE_ROCKSLIDE = 10,
    PLAYER_INVESTIGATE_ROCKSLIDE_SETUP = 11,
    PLAYER_INVESTIGATE_ROCKSLIDE_CAMERA1 = 12,
    PLAYER_INVESTIGATE_ROCKSLIDE_CAMERA2 = 13,
    PLAYER_INVESTIGATE_ROCKSLIDE_CAMERA3 = 14,
    PLAYER_INVESTIGATE_ROCKSLIDE_FINISH = 15,
    FINISH = 16
}

local YelenaState = {
    PATROL = 1,
    WATCH_FOR_ATTACKER = 2,
    WAIT_FOR_ATTACK_TO_END = 3,
}

local Mission = {
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    m_PlayerPilotODF = "fspilo_x",
    m_PlayerShipODF = "fvtank_x",

    m_MainPlayer = nil,
    m_Yelena = nil,

    m_Cons = nil,
    m_Kiln = nil,
    m_PlayersRecy = nil,
    m_Escort2A = nil,
    m_Escort2B = nil,

    m_PlayerSentry1 = nil,
    m_PlayerSentry2 = nil,
    m_PlayerSentry3 = nil,
    m_PlayerSentry4 = nil,

    m_OldPlayerTank = nil,

    m_Landslide = nil,
    m_Jak1 = nil,
    m_Jak2 = nil,
    m_Jak3 = nil,
    m_Jak4 = nil,
    m_Jak5 = nil,
    m_Jak6 = nil,
    m_Jak7 = nil,
    m_Jak8 = nil,
    m_Jak9 = nil,
    m_Jak10 = nil,

    m_JakStay1 = nil,
    m_JakStay2 = nil,

    m_CamLook1 = nil,
    m_CamLook2 = nil,
    m_IntroShot2Look = nil,
    m_PilotsLook1 = nil,
    m_DropshipCam1Look = nil,

    m_RockslideShotTime = nil,

    m_ISDFAttacker1 = nil,
    m_ISDFAttacker2 = nil,
    m_ISDFAttacker3 = nil,
    m_ISDFAttacker4 = nil,

    m_ISDFAmbusher1 = nil,
    m_ISDFAmbusher2 = nil,
    m_ISDFAmbusher3 = nil,
    m_ISDFAmbusher4 = nil,

    m_ISDFRouteAttacker1A = nil,
    m_ISDFRouteAttacker1B = nil,
    m_ISDFRouteAttacker1C = nil,
    m_ISDFRouteAttacker2A = nil,
    m_ISDFRouteAttacker2B = nil,
    m_ISDFRouteAttacker4A = nil,
    m_ISDFRouteAttacker4B = nil,

    m_RockslideMine1 = nil,
    m_RockslideMine2 = nil,
    m_RockslideMine3 = nil,

    m_PlayerPilo1 = nil,
    m_ShabPilo = nil,
    m_ShabPilo3 = nil,

    m_DeltaSquad1 = nil,
    m_DeltaSquad2 = nil,
    m_Hauler = nil,
    m_PowerCrystal = nil,

    m_Nav1 = nil,
    m_Nav2 = nil,

    m_Amini = nil,
    m_PlayerOnFoot = nil,
    m_PlayerPilotRetreat = nil,

    m_YelenaTarget = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_PilotsMoved = false,
    m_ConstructorMoved = false,
    m_IntroCutsceneDone = false,
    m_ShabInShip = false,
    m_ShabRelook = false,
    m_PlayerTookTooLongMorphing = false,
    m_PowerObjectivesShown = false,
    m_MorphObjectivesShown = false,
    m_ISDFWaveSpawned = false,
    m_YelenaUnderFire = false,
    m_YelenaPraise = false,
    m_YelenaReturnToPatrol = false,
    m_SpawnDeltaSquad = false,
    m_PowerCrystalDestroyed = false,
    m_RecyclerDestroyed = false,

    m_PowerLungWarningActive = false,
    m_MorphWarningActive = false,
    m_EnableAnimals = false,
    m_EnableISDF = false,
    m_EnableISDFWaves = false,
    m_MeetDeltaWarningActive = false,
    m_DeltaBrainActive = false,
    m_YelenaBrainActive = false,

    m_AmbushAttacking = false,
    m_AmbushDefeated = false,
    m_Ambush2Attacking = false,

    m_Escort1Close = false,
    m_Escort1Far = false,
    m_EscortAlerted = false,
    m_Escort1Look = false,
    m_Escort2Look = false,
    m_EscortRetreat = false,
    m_EscortReturnToBase = false,

    m_ISDFRoute1Attack = false,
    m_ISDFRoute2Attack = false,
    m_ISDFRoute3Attack = false,

    m_JakStop1 = false,
    m_JakStop2 = false,
    m_Jak12Spawned = false,

    m_RockslideFinished = false,
    m_PlayerInvestigateRockslideOnFoot = false,
    m_ShowRockslideObjective = false,
    m_PlayerPilotMove = false,
    m_AminiMove = false,

    m_PlayerEscortTug = false,

    m_CutsceneAudioClip = nil,
    m_Audioclip = nil,
    m_PowerClip = nil,
    m_MorphClip = nil,
    m_AudioTimer = 0,

    m_JakGoTime2 = 0,
    m_Jak12SpawnTime = 0,
    m_Jak910SpawnTime = 0,

    m_PowerCrystalDestroyedTime = 0,
    m_RecyclerDestroyedTime = 0,
    m_DeltaSquadSpawnTime = 0,
    m_PilotMoveTime = 0,
    m_MissionDelayTime = 0,
    m_PowerLunchTookTooLongTime = 0,
    m_MorphTookTooLongTime = 0,
    m_MorphTookTooLongWarningCount = 0,
    m_ISDFWaveTime = 0,
    m_ISDFWaveCount = 1,
    m_DeltaWarningCount = 0,
    m_ISDFRouteDelay = 0,
    m_AminiGoTime = 0,

    m_CurrentPhase = MissionPhase.INTRO,
    m_IntroState = IntroState.SETUP,
    m_DefenseState = DefenseState.START,
    m_PowerupState = PowerupState.START,
    m_EscortState = EscortState.SPAWN_DELTA,
    m_PlayerEscortState = PlayerEscortState.ESCORT,
    m_RockslideState = RockslideState.WAIT_FOR_TRIGGER,
    m_YelenaState = YelenaState.PATROL
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
        SetTeamNameForStat(Mission.m_EnemyTeam, "ISDF")
        SetTeamNameForStat(7, "Scion Rebels")
        SetTeamColor(7, 85, 255, 85)

        for i = 2, 5 do
            Ally(Mission.m_HostTeam, i)
        end

        Mission.m_Yelena = GetHandle("shab")
        Mission.m_Cons = GetHandle("fvcons1")
        Mission.m_Kiln = GetHandle("kiln")
        Mission.m_PlayersRecy = GetHandle("playersrecy")
        Mission.m_PlayerSentry1 = GetHandle("player_sentry_1")
        Mission.m_PlayerSentry2 = GetHandle("player_sentry_2")
        Mission.m_PlayerSentry3 = GetHandle("player_sentry_3")
        Mission.m_PlayerSentry4 = GetHandle("player_sentry_4")
        Mission.m_JakStay1 = GetHandle("jakstay1")
        Mission.m_JakStay2 = GetHandle("jakstay2")
        Mission.m_Jak3 = GetHandle("jak3")
        Mission.m_Jak4 = GetHandle("jak4")
        Mission.m_Jak5 = GetHandle("jak5")
        Mission.m_Jak7 = GetHandle("jak7")
        Mission.m_Jak8 = GetHandle("jak8")
        Mission.m_Escort2A = GetHandle("escort2a")
        Mission.m_Escort2B = GetHandle("escort2b")
        Mission.m_Landslide = GetHandle("landslide")
        Mission.m_CamLook1 = GetHandle("camlook1")
        Mission.m_CamLook2 = GetHandle("camlook2")
        Mission.m_IntroShot2Look = GetHandle("intro_shot2look")
        Mission.m_PilotsLook1 = GetHandle("pilots_look1")
        Mission.m_DropshipCam1Look = GetHandle("dropship_cam1look")
        Mission.m_PlayerPilo1 = GetHandle("player_pilo1")
        Mission.m_ShabPilo = GetHandle("shab_pilo")
        Mission.m_OldPlayerTank = GetHandle("player_old_tank")

        if (_Cooperative.m_TotalPlayerCount < 4) then
            if (Mission.m_PlayerSentry4) then RemoveObject(Mission.m_PlayerSentry4) end

            if (_Cooperative.m_TotalPlayerCount < 3) then
                if (Mission.m_PlayerSentry3) then RemoveObject(Mission.m_PlayerSentry3) end

                if (_Cooperative.m_TotalPlayerCount < 2) then
                    if (Mission.m_PlayerSentry2) then RemoveObject(Mission.m_PlayerSentry2) end
                end
            end
        end

        _Cooperative.CleanSpawns()

        Mission.m_ISDFRouteAttacker1A = BuildObject("ivscout_x", Mission.m_EnemyTeam, "routeattack1a")
        Mission.m_ISDFRouteAttacker1B = BuildObject("ivscout_x", Mission.m_EnemyTeam, "routeattack1b")
        Mission.m_ISDFRouteAttacker1C = BuildObject("ivscout_x", Mission.m_EnemyTeam, "routeattack1c")
        Mission.m_ISDFRouteAttacker2A = BuildObject("ivscout_x", Mission.m_EnemyTeam, "routeattack2a")
        Mission.m_ISDFRouteAttacker2B = BuildObject("ivtank_x", Mission.m_EnemyTeam, "routeattack2b")
        Mission.m_ISDFRouteAttacker4A = BuildObject("ivscout_x", Mission.m_EnemyTeam, "routeattack4a")
        Mission.m_ISDFRouteAttacker4B = BuildObject("ivatank_x", Mission.m_EnemyTeam, "routeattack4b")

        if (Mission.m_ISDFRouteAttacker1A) then LookAt(Mission.m_ISDFRouteAttacker1A, Mission.m_MainPlayer) end
        if (Mission.m_ISDFRouteAttacker1B) then LookAt(Mission.m_ISDFRouteAttacker1B, Mission.m_MainPlayer) end
        if (Mission.m_ISDFRouteAttacker1C) then LookAt(Mission.m_ISDFRouteAttacker1C, Mission.m_MainPlayer) end
        if (Mission.m_ISDFRouteAttacker2A) then LookAt(Mission.m_ISDFRouteAttacker2A, Mission.m_MainPlayer) end
        if (Mission.m_ISDFRouteAttacker2B) then LookAt(Mission.m_ISDFRouteAttacker2B, Mission.m_MainPlayer) end
        if (Mission.m_ISDFRouteAttacker4A) then LookAt(Mission.m_ISDFRouteAttacker4A, Mission.m_MainPlayer) end
        if (Mission.m_ISDFRouteAttacker4B) then LookAt(Mission.m_ISDFRouteAttacker4B, Mission.m_MainPlayer) end

        if (Mission.m_IsCooperativeMode) then
            if (Mission.m_PlayerPilo1) then RemoveObject(Mission.m_PlayerPilo1) end
            if (Mission.m_ShabPilo) then RemoveObject(Mission.m_ShabPilo) end
            Mission.m_IntroState = IntroState.FINISH
        else
            Mission.m_IntroState = IntroState.CAMERA1
        end
    end,
    [IntroState.CAMERA1] = function()
        if (Mission.m_Cons) then Goto(Mission.m_Cons, "builder_path1") end

        CameraReady()
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(17)
        Mission.m_IntroState = IntroState.CAMERA2
    end,
    [IntroState.CAMERA2] = function()
        CameraPath("shot1_path1", 500, 1000, Mission.m_ShabPilo)

        if (Mission.m_MissionTime > Mission.m_MissionDelayTime) then
            if (Mission.m_PlayerPilo1) then Retreat(Mission.m_PlayerPilo1, "player_pilo1_path1") end
            if (Mission.m_ShabPilo) then Retreat(Mission.m_ShabPilo, "shab_pilo_path1") end
            if (Mission.m_Cons) then Goto(Mission.m_Cons, "builder_path2", 0) end

            Mission.m_ConstructorMoved = true
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5)
            Mission.m_IntroState = IntroState.CAMERA3
        end
    end,
    [IntroState.CAMERA3] = function()
        CameraPath("intro_shot2path", 500, 0, Mission.m_IntroShot2Look)

        if (Mission.m_MissionTime > Mission.m_MissionDelayTime) then
            RemoveObject(Mission.m_PlayerPilo1)
            RemoveObject(Mission.m_ShabPilo)
            Mission.m_CutsceneAudioClip = _Subtitles.AudioWithSubtitles("cutsc0101.wav",
                SUBTITLE_PANEL_SIZES["SubtitlesPanel_Medium"])
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(28)
            Mission.m_IntroState = IntroState.CAMERA4
        end
    end,
    [IntroState.CAMERA4] = function()
        CameraPath("intro_shot3path", 1500, 100, Mission.m_Kiln)

        if (Mission.m_MissionTime > Mission.m_MissionDelayTime) then
            Mission.m_PlayerPilo1 = BuildObject("fspilo_xs01", 0, "player_pilo1_spawn")
            Mission.m_ShabPilo = BuildObject("fspilo_rs01", 0, "shab_pilo_spawn")
            LookAt(Mission.m_PlayerPilo1, Mission.m_PilotsLook1)
            LookAt(Mission.m_ShabPilo, Mission.m_PilotsLook1)
            Mission.m_PilotMoveTime = Mission.m_MissionTime + SecondsToTurns(5)
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(18)
            Mission.m_IntroState = IntroState.PILOT_WALK
        end
    end,
    [IntroState.PILOT_WALK] = function()
        CameraPath("intro_shot4path", 200, 0, Mission.m_PlayerPilo1)

        if (not Mission.m_PilotsMoved and Mission.m_MissionTime > Mission.m_PilotMoveTime) then
            Retreat(Mission.m_PlayerPilo1, "player_path")
            Retreat(Mission.m_ShabPilo, "shab_path")
            Mission.m_PilotsMoved = true
        end

        if (Mission.m_MissionTime > Mission.m_MissionDelayTime) then
            RemoveObject(Mission.m_PlayerPilo1)
            RemoveObject(Mission.m_ShabPilo)
            CameraFinish()
            CreateShab3Pilot()
            SetScrap(Mission.m_HostTeam, 0)
            Mission.m_IntroCutsceneDone = true
            Mission.m_IntroState = IntroState.PILOT_MOVE
        end
    end,
    [IntroState.PILOT_MOVE] = function()
        if (Mission.m_ShabInShip) then
            SetObjectiveName(Mission.m_Yelena, "Yelena")
            SetObjectiveOn(Mission.m_Yelena)
            LookAt(Mission.m_Yelena, Mission.m_MainPlayer)
            SetCanSnipe(Mission.m_Yelena, 0)
            SetMaxHealth(Mission.m_Yelena, 0)
            SetCurHealth(Mission.m_Yelena, 0)
            SetSkill(Mission.m_Yelena, 3)
            Patrol(Mission.m_Jak3, "jak_3_4_path")
            Follow(Mission.m_Jak4, Mission.m_Jak3)
            Patrol(Mission.m_Jak5, "jak_5_path")
            Patrol(Mission.m_Jak6, "jak_6_path")
            Patrol(Mission.m_Jak7, "jak_7_8_path")
            Follow(Mission.m_Jak8, Mission.m_Jak7)
            Stop(Mission.m_JakStay1)
            Stop(Mission.m_JakStay2)
            Mission.m_Jak910SpawnTime = Mission.m_MissionTime + SecondsToTurns(3)
            Mission.m_EnableAnimals = true
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3)
            Mission.m_IntroState = IntroState.FINISH
        end
    end,
    [IntroState.FINISH] = function()
        Mission.m_CurrentPhase = MissionPhase.POWERUP
        Mission.m_PowerupState = PowerupState.START
    end
}

local PowerupHandlers = {
    [PowerupState.START] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        playAudioWithDelay("scion0101.wav", 20.5)
        Mission.m_PowerupState = PowerupState.WAIT_FOR_POWER_AUDIO
    end,
    [PowerupState.WAIT_FOR_POWER_AUDIO] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end
        Mission.m_PowerClip = _Subtitles.AudioWithSubtitles("scion0106.wav",
            SUBTITLE_PANEL_SIZES["SubtitlesPanel_Medium"])
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(26.5)
        Mission.m_PowerupState = PowerupState.WAIT_FOR_POWER
    end,
    [PowerupState.WAIT_FOR_POWER] = function()
        if (IsPowered(Mission.m_Kiln)) then
            StopAudioMessage(Mission.m_PowerClip)
            Mission.m_PowerLungWarningActive = false
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2)
            Mission.m_PowerupState = PowerupState.WAIT_FOR_MORPH_AUDIO
            return
        end

        if (not Mission.m_PowerObjectivesShown) then
            if (IsAudioMessageFinished(Mission.m_PowerClip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                AddObjectiveOverride("scion0113.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
                Mission.m_PowerLungWarningActive = true
                Mission.m_PowerLunchTookTooLongTime = Mission.m_MissionTime + SecondsToTurns(90)
                Mission.m_PowerObjectivesShown = true
            end
        end
    end,
    [PowerupState.WAIT_FOR_MORPH_AUDIO] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        Mission.m_MorphClip = _Subtitles.AudioWithSubtitles("scion0102.wav")
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(13.5)
        Mission.m_PowerupState = PowerupState.WAIT_FOR_MORPH
    end,
    [PowerupState.WAIT_FOR_MORPH] = function()
        local isPlayerDeployed = false

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
                playAudioWithDelay("scion0103.wav", 17.5)
                Mission.m_MorphWarningActive = false
            else
                playAudioWithDelay("scion0118.wav", 9.5)
            end

            Mission.m_PowerupState = PowerupState.FINISH

            return
        end

        if (not Mission.m_MorphObjectivesShown) then
            if (IsAudioMessageFinished(Mission.m_MorphClip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                AddObjectiveOverride("scion0110.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
                Mission.m_MorphWarningActive = true
                Mission.m_MorphTookTooLongTime = Mission.m_MissionTime + SecondsToTurns(40)
                Mission.m_MorphObjectivesShown = true
            end
        end
    end,
    [PowerupState.FINISH] = function()
        Mission.m_CurrentPhase = MissionPhase.DEFENSE
        Mission.m_DefenseState = DefenseState.START
    end
}

local DefenseHandlers = {
    [DefenseState.START] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2)
        Mission.m_DefenseState = DefenseState.WAIT_FOR_AUDIO
    end,
    [DefenseState.WAIT_FOR_AUDIO] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        playAudioWithDelay("scion0134.wav", 9.5)
        Mission.m_DefenseState = DefenseState.WAIT_FOR_OBJECTIVE
    end,
    [DefenseState.WAIT_FOR_OBJECTIVE] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end
        AddObjectiveOverride("scion0101.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
        Mission.m_YelenaBrainActive = true
        Mission.m_EnableISDF = true
        Mission.m_EnableISDFWaves = true
        Mission.m_ISDFWaveTime = Mission.m_MissionTime + SecondsToTurns(m_WaveCooldowns[Mission.m_ISDFWaveCount])
        Patrol(Mission.m_Yelena, "shab_patrol")
        Mission.m_DefenseState = DefenseState.FINISH
    end,
    [DefenseState.FINISH] = function()
        Mission.m_CurrentPhase = MissionPhase.ESCORT
        Mission.m_EscortState = EscortState.SPAWN_DELTA
    end
}

local EscortHandlers = {
    [EscortState.SPAWN_DELTA] = function()
        if (Mission.m_SpawnDeltaSquad and Mission.m_DeltaSquadSpawnTime < Mission.m_MissionTime) then
            Mission.m_DeltaSquad1 = BuildObject("fvscout_x", Mission.m_HostTeam, "escort1a")
            Mission.m_DeltaSquad2 = BuildObject("fvscout_x", Mission.m_HostTeam, "escort1b")
            Mission.m_Hauler = BuildObject("fvtug", Mission.m_HostTeam, "tug1")
            Mission.m_PowerCrystal = BuildObject("cotran01", Mission.m_HostTeam, "power")
            Stop(Mission.m_DeltaSquad1)
            Stop(Mission.m_DeltaSquad2)
            Stop(Mission.m_Hauler)
            SetObjectiveName(Mission.m_DeltaSquad1, "Delta 1")
            SetObjectiveName(Mission.m_DeltaSquad2, "Delta 2")
            SetMaxHealth(Mission.m_PowerCrystal, 5000)
            SetCurHealth(Mission.m_PowerCrystal, 5000)
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3)
            playAudioWithDelay("scion0109.wav", 8.5)
            Mission.m_EscortState = EscortState.PICKUP_CRYSTAL
        end
    end,
    [EscortState.PICKUP_CRYSTAL] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        Pickup(Mission.m_Hauler, Mission.m_PowerCrystal)
        Mission.m_EscortState = EscortState.DELTA_FORMATION
    end,
    [EscortState.DELTA_FORMATION] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end
        Retreat(Mission.m_DeltaSquad1, "rondevous1")
        Retreat(Mission.m_Hauler, "rondevous1")
        Follow(Mission.m_DeltaSquad2, Mission.m_PowerCrystal)
        Mission.m_DeltaBrainActive = true
        playAudioWithDelay("scion0110.wav", 6.5)
        Mission.m_EscortState = EscortState.ESCORT_TO_RONDEVOUZ
    end,
    [EscortState.ESCORT_TO_RONDEVOUZ] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end
        Mission.m_Nav1 = BuildObject("ibnav", Mission.m_HostTeam, "nav1")
        SetObjectiveName(Mission.m_Nav1, TranslateString("MissionS0101"))
        SetObjectiveOn(Mission.m_Nav1)
        SetObjectiveOff(Mission.m_Yelena)
        AddObjectiveOverride("scion0102.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
        Mission.m_MeetDeltaWarningTime = Mission.m_MissionTime + SecondsToTurns(60)
        Mission.m_MeetDeltaWarningActive = true
        Mission.m_EscortState = EscortState.MEET_AT_RONDEVOUZ
    end,
    [EscortState.MEET_AT_RONDEVOUZ] = function()
        if (GetDistance(Mission.m_Hauler, "rondevous1") < 125 and IsPlayerWithinDistance(Mission.m_Hauler, 125, _Cooperative.m_TotalPlayerCount)) then
            playAudioWithDelay("scion0113.wav", 6.5)
            Stop(Mission.m_DeltaSquad1)
            SetObjectiveOff(Mission.m_Nav1)
            Mission.m_MeetDeltaWarningActive = false
            local chosenAmbushSet = m_Ambush1[Mission.m_MissionDifficulty]
            Mission.m_ISDFAmbusher1 = BuildObject(chosenAmbushSet[1], Mission.m_EnemyTeam, "spawn_1_b")
            Mission.m_ISDFAmbusher2 = BuildObject(chosenAmbushSet[2], Mission.m_EnemyTeam,
                GetPositionNear("spawn_2_b", 30, 30))
            Mission.m_ISDFAmbusher3 = BuildObject(chosenAmbushSet[3], Mission.m_EnemyTeam,
                GetPositionNear("spawn_2_b", 30, 30))
            Retreat(Mission.m_ISDFAmbusher1, "rondevous1")
            Retreat(Mission.m_ISDFAmbusher2, "rondevous1")
            Retreat(Mission.m_ISDFAmbusher3, "rondevous1")
            Mission.m_EscortState = EscortState.YELENA_CONFIRM
        end
    end,
    [EscortState.YELENA_CONFIRM] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end
        playAudioWithDelay("scion0123.wav", 2.5)
        Mission.m_EscortState = EscortState.AMBUSH_ATTACK
    end,
    [EscortState.AMBUSH_ATTACK] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

        local distCheck1 = GetDistance(Mission.m_ISDFAmbusher1, "rondevous1") < 150
        local distCheck2 = GetDistance(Mission.m_ISDFAmbusher2, "rondevous1") < 150
        local distCheck3 = GetDistance(Mission.m_ISDFAmbusher3, "rondevous1") < 150

        if (not Mission.m_AmbushAttacking and (distCheck1 or distCheck2 or distCheck3)) then
            playAudioWithDelay("scion0114.wav", 3.5)

            Attack(Mission.m_ISDFAmbusher1, Mission.m_DeltaSquad1)
            Attack(Mission.m_ISDFAmbusher2, Mission.m_PowerCrystal)
            Attack(Mission.m_ISDFAmbusher3, GetTug(Mission.m_PowerCrystal))

            Attack(Mission.m_DeltaSquad1, Mission.m_ISDFAmbusher1)
            Attack(Mission.m_DeltaSquad2, Mission.m_ISDFAmbusher2)

            Mission.m_AmbushAttacking = true
        end

        local check1 = IsAliveAndEnemy(Mission.m_ISDFAmbusher1, Mission.m_EnemyTeam)
        local check2 = IsAliveAndEnemy(Mission.m_ISDFAmbusher2, Mission.m_EnemyTeam)
        local check3 = IsAliveAndEnemy(Mission.m_ISDFAmbusher3, Mission.m_EnemyTeam)

        if (not check1 and not check2 and not check3) then
            Mission.m_AmbushDefeated = true
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5)
            Mission.m_EscortState = EscortState.AMBUSH_DEFEATED
        end
    end,
    [EscortState.AMBUSH_DEFEATED] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        playAudioWithDelay("scion0115.wav", 4.5)
        Mission.m_EscortState = EscortState.DELTA_RETREAT
    end,
    [EscortState.DELTA_RETREAT] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end
        Patrol(Mission.m_DeltaSquad1, "shab_patrol")
        Follow(Mission.m_DeltaSquad2, Mission.m_DeltaSquad1)
        Mission.m_Nav2 = BuildObject("ibnav", 1, "nav2")
        SetObjectiveOn(Mission.m_Nav2)
        SetObjectiveName(Mission.m_Nav2, TranslateString("MissionS0102"))
        AddObjectiveOverride("scion0103.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
        Mission.m_DeltaBrainActive = false
        Mission.m_YelenaBrainActive = false
        playAudioWithDelay("scion0116.wav", 7.5)
        Mission.m_MissionDelayTime = Mission.m_MissionDelayTime + SecondsToTurns(8)
        Mission.m_EscortState = EscortState.PLAYER_ESCORT
    end,
    [EscortState.PLAYER_ESCORT] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

        if (IsAlive(Mission.m_Hauler)) then
            Stop(Mission.m_Hauler, 0);
            SetBestGroup(Mission.m_Hauler);
        end

        SetObjectiveOn(Mission.m_PowerCrystal)
        Mission.m_PlayerEscortTug = true
        Mission.m_EscortState = EscortState.FINISH
    end,
    [EscortState.FINISH] = function()
        Mission.m_CurrentPhase = MissionPhase.PLAYER_ESCORT
        Mission.m_RockslideState = RockslideState.WAIT_FOR_TRIGGER
    end
}

local PlayerEscortHandlers = {
    [PlayerEscortState.ESCORT] = function()

    end
}

local RockslideHandlers = {
    [RockslideState.WAIT_FOR_TRIGGER] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end

        local check1 = GetDistance(Mission.m_PowerCrystal, "trig_rockslide") < 40
        local check2 = IsPlayerWithinDistance("trig_rockslide", 70, _Cooperative.m_TotalPlayerCount)

        if (check1 or check2) then
            for i = 1, 12 do
                BuildObject("flshbng" .. i, 0, GetPosition(GetHandle("explode" .. i)))
            end
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1.1)
            Mission.m_RockslideState = RockslideState.LANDSLIDE_ANIMATION
            return
        end

        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1.5)
    end,
    [RockslideState.LANDSLIDE_ANIMATION] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end

        SetAnimation(Mission.m_Landslide, "landslide", 1)
        StartEarthQuake(10)

        if (Mission.m_IsCooperativeMode) then
            Mission.m_RockslideState = RockslideState.POST_ROCKSLIDE
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(11)
            return
        end

        CameraReady()

        Mission.m_RockslideShotTime = Mission.m_MissionTime + SecondsToTurns(4)
        Mission.m_RockslideState = RockslideState.CAMERA1
    end,
    [RockslideState.CAMERA1] = function()
        CameraPath("campath1", 2500, 0, Mission.m_CamLook1)

        if (Mission.m_RockslideShotTime < Mission.m_MissionTime) then
            Mission.m_RockslideShotTime = Mission.m_MissionTime + SecondsToTurns(3)
            Mission.m_RockslideState = RockslideState.CAMERA2
        end
    end,
    [RockslideState.CAMERA2] = function()
        CameraPath("campath2", 1500, 0, Mission.m_CamLook2)

        if (Mission.m_RockslideShotTime < Mission.m_MissionTime) then
            Mission.m_RockslideShotTime = Mission.m_MissionTime + SecondsToTurns(4)
            Mission.m_RockslideState = RockslideState.CAMERA3
        end
    end,
    [RockslideState.CAMERA3] = function()
        CameraPath("campath1", 2500, 0, Mission.m_CamLook1)

        if (Mission.m_RockslideShotTime < Mission.m_MissionTime) then
            Mission.m_RockslideState = RockslideState.POST_ROCKSLIDE
        end
    end,
    [RockslideState.POST_ROCKSLIDE] = function()
        if (not Mission.m_IsCooperativeMode) then
            CameraFinish()
        elseif (Mission.m_MissionDelayTime > Mission.m_MissionTime) then
            return
        end

        local chosenAmbushSet = m_Ambush2[Mission.m_MissionDifficulty];

        Mission.m_ISDFAmbusher1 = BuildObject(chosenAmbushSet[1], Mission.m_EnemyTeam, "rockslide_ambush_1")
        Mission.m_ISDFAmbusher2 = BuildObject(chosenAmbushSet[2], Mission.m_EnemyTeam, "rockslide_ambush_2")
        Mission.m_ISDFAmbusher3 = BuildObject(chosenAmbushSet[3], Mission.m_EnemyTeam, "rockslide_ambush_3")
        Mission.m_ISDFAmbusher4 = BuildObject(chosenAmbushSet[4], Mission.m_EnemyTeam, "rockslide_ambush_4")

        Goto(Mission.m_ISDFAmbusher1, Mission.m_MainPlayer)
        Goto(Mission.m_ISDFAmbusher2, Mission.m_PowerCrystal)
        Goto(Mission.m_ISDFAmbusher3, Mission.m_MainPlayer)
        Goto(Mission.m_ISDFAmbusher4, Mission.m_PowerCrystal)

        StopEarthQuake()
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1)
        Mission.m_RockslideState = RockslideState.AUDIO
    end,
    [RockslideState.AUDIO] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        playAudioWithDelay("scion0119.wav", 4.5)
        Mission.m_RockslideState = RockslideState.AMBUSH
    end,
    [RockslideState.AMBUSH] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

        local distCheck1 = GetDistance(Mission.m_ISDFAmbusher1, Mission.m_MainPlayer) < 150
        local distCheck2 = GetDistance(Mission.m_ISDFAmbusher2, Mission.m_PowerCrystal) < 150
        local distCheck3 = GetDistance(Mission.m_ISDFAmbusher3, Mission.m_MainPlayer) < 150
        local distCheck4 = GetDistance(Mission.m_ISDFAmbusher4, Mission.m_PowerCrystal) < 150

        if (not Mission.m_Ambush2Attacking and (distCheck1 or distCheck2 or distCheck3 or distCheck4)) then
            playAudioWithDelay("scion0129.wav", 2.5)

            Attack(Mission.m_ISDFAmbusher1, Mission.m_MainPlayer)
            Attack(Mission.m_ISDFAmbusher2, Mission.m_PowerCrystal)
            Attack(Mission.m_ISDFAmbusher3, Mission.m_MainPlayer)
            Attack(Mission.m_ISDFAmbusher4, Mission.m_PowerCrystal)

            Mission.m_Ambush2Attacking = true
        end

        local check1 = IsAliveAndEnemy(Mission.m_ISDFAmbusher1, Mission.m_EnemyTeam)
        local check2 = IsAliveAndEnemy(Mission.m_ISDFAmbusher2, Mission.m_EnemyTeam)
        local check3 = IsAliveAndEnemy(Mission.m_ISDFAmbusher3, Mission.m_EnemyTeam)
        local check4 = IsAliveAndEnemy(Mission.m_ISDFAmbusher4, Mission.m_EnemyTeam)

        if (not check1 and not check2 and not check3 and not check4) then
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3)

            -- We'll need to skip this part if we are in coop.
            if (not Mission.m_IsCooperativeMode) then
                Mission.m_RockslideState = RockslideState.YELENA_AUDIO
            else
                Mission.m_RockslideState = RockslideState.FINISH
            end

            return
        end
    end,
    [RockslideState.YELENA_AUDIO] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        playAudioWithDelay("scion0120.wav", 16.5)
        Mission.m_RockslideState = RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE
    end,
    [RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE] = function()
        if (not Mission.m_ShowRockslideObjective and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            AddObjectiveOverride("scion0109.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
            Mission.m_ShowRockslideObjective = true
        end

        if (GetDistance(Mission.m_MainPlayer, "trig_rockslide") < 125 and IsPerson(Mission.m_MainPlayer)) then
            StopAudioMessage(Mission.m_Audioclip);
            Mission.m_RockslideState = RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE_CAMERA1;
        end
    end,
    [RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE_SETUP] = function()
        Mission.m_Amini = BuildObject("fvsent_x", 7, "amini_spawn")
        Mission.m_PlayerOnFoot = BuildObject("fspilo_x", 0, "pilo_on_foot_spawn")

        SetIndependent(Mission.m_Amini, 0)
        CameraReady()
    end,
    [RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE_CAMERA1] = function()
        CameraObject(Mission.m_PlayerOnFoot, 0, -1, -3, Mission.m_PlayerOnFoot)

        if (not Mission.m_PlayerPilotMove) then
            Retreat(Mission.m_PlayerOnFoot, "pilo_on_foot_path1")
            LookAt(Mission.m_Amini, Mission.m_Landslide)
            Mission.m_PlayerPilotMove = true
        end

        if (GetDistance(Mission.m_PlayerOnFoot, "pilo_on_foot_endpath1") < 5) then
            Stop(Mission.m_PlayerOnFoot);
            LookAt(Mission.m_PlayerOnFoot, Mission.m_Amini);

            Mission.m_AminiGoTime = Mission.m_MissionTime + SecondsToTurns(5)
            Mission.m_RockslideState = RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE_CAMERA2
        end
    end,
    [RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE_CAMERA2] = function()
        CameraPath("behind_pilo", 10, 0, Mission.m_Amini)

        if (not Mission.m_AminiMove and Mission.m_AminiGoTime < Mission.m_MissionTime) then
            Retreat(Mission.m_Amini, "amini_path1")
            playAudioWithDelay("cutsc0206.wav", 4.5)

            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(12)
            Mission.m_AminiMove = true
            Mission.m_RockslideState = RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE_CAMERA3
        end
    end,
    [RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE_CAMERA3] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end

        CameraPath("on_foot_campath1", 200, 0, Mission.m_PlayerOnFoot)

        if (not Mission.m_PlayerPilotRetreat) then
            Retreat(Mission.m_PlayerOnFoot, "pilo_on_foot_path2")
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(6)
            Mission.m_PlayerPilotRetreat = true
            Mission.m_RockslideState = RockslideState.FINISH
        end
    end,
    [RockslideState.PLAYER_INVESTIGATE_ROCKSLIDE_FINISH] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end

        RemoveObject(Mission.m_Amini)
        RemoveObject(Mission.m_PlayerOnFoot)
        CameraFinish()

        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5)
    end,
    [RockslideState.FINISH] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end
        playAudioWithDelay("scion0122.wav", 17.5)
        Mission.m_RockslideFinished = true
    end
}

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

        if (Mission.m_ISDFAttacker1 and GetDistance(Mission.m_ISDFAttacker1, Mission.m_Yelena) < 125) then
            Mission.m_YelenaTarget = Mission.m_ISDFAttacker1
        elseif (Mission.m_ISDFAttacker2 and GetDistance(Mission.m_ISDFAttacker2, Mission.m_Yelena) < 125) then
            Mission.m_YelenaTarget = Mission.m_ISDFAttacker2
        elseif (Mission.m_ISDFAttacker3 and GetDistance(Mission.m_ISDFAttacker3, Mission.m_Yelena) < 125) then
            Mission.m_YelenaTarget = Mission.m_ISDFAttacker3
        elseif (Mission.m_ISDFAttacker4 and GetDistance(Mission.m_ISDFAttacker4, Mission.m_Yelena) < 125) then
            Mission.m_YelenaTarget = Mission.m_ISDFAttacker4
        end

        if (Mission.m_YelenaTarget ~= nil) then
            Attack(Mission.m_Yelena, Mission.m_YelenaTarget)
            Mission.m_YelenaState = YelenaState.WAIT_FOR_ATTACK_TO_END
        end
    end,
    [YelenaState.WAIT_FOR_ATTACK_TO_END] = function()
        if (not Mission.m_YelenaUnderFire) then
            playAudioWithDelay("scion0107.wav", 3.5)
            Mission.m_YelenaUnderFire = true
        end

        if (Mission.m_YelenaTarget == nil) then
            if (IsAliveAndEnemy(Mission.m_ISDFAttacker1, Mission.m_EnemyTeam)) then
                Attack(Mission.m_Yelena, Mission.m_ISDFAttacker1)
                Mission.m_YelenaTarget = Mission.m_ISDFAttacker1
            elseif (IsAliveAndEnemy(Mission.m_ISDFAttacker2, Mission.m_EnemyTeam)) then
                Attack(Mission.m_Yelena, Mission.m_ISDFAttacker2)
                Mission.m_YelenaTarget = Mission.m_ISDFAttacker2
            elseif (IsAliveAndEnemy(Mission.m_ISDFAttacker3, Mission.m_EnemyTeam)) then
                Attack(Mission.m_Yelena, Mission.m_ISDFAttacker3)
                Mission.m_YelenaTarget = Mission.m_ISDFAttacker3
            elseif (IsAliveAndEnemy(Mission.m_ISDFAttacker4, Mission.m_EnemyTeam)) then
                Attack(Mission.m_Yelena, Mission.m_ISDFAttacker4)
                Mission.m_YelenaTarget = Mission.m_ISDFAttacker4
            else
                if (not Mission.m_YelenaPraise) then
                    Mission.m_YelenaPraiseDelay = Mission.m_MissionTime + SecondsToTurns(1.3)
                end

                Mission.m_YelenaState = YelenaState.PATROL
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
    PreloadODF("fvtug")
    PreloadODF("fvsent_x")
    PreloadODF("fspilo_x")
    PreloadODF("fvscout_x")
    PreloadODF("ispilo_x")
    PreloadODF("ivscout_x")
    PreloadODF("ivmisl_x")
    PreloadODF("ivtank_x")
    PreloadODF("ivmbike_x")
    PreloadODF("ivrckt_x")
    PreloadODF("ivatank_x")
    PreloadODF("cotran01")
    for i = 1, 12 do
        PreloadODF("flshbng" .. i)
    end
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
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty)
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        SetSkill(h, 3)
    end
end

function DeleteObject(h)
    local teamNum = GetTeamNum(h)

    if (teamNum == 0) then
        if (h == Mission.m_Jak1) then
            Mission.m_Jak1 = nil
        elseif (h == Mission.m_Jak2) then
            Mission.m_Jak2 = nil
        elseif (h == Mission.m_Jak3) then
            Mission.m_Jak3 = nil
        elseif (h == Mission.m_Jak4) then
            Mission.m_Jak4 = nil
        elseif (h == Mission.m_Jak5) then
            Mission.m_Jak5 = nil
        elseif (h == Mission.m_Jak6) then
            Mission.m_Jak6 = nil
        elseif (h == Mission.m_Jak7) then
            Mission.m_Jak7 = nil
        elseif (h == Mission.m_Jak8) then
            Mission.m_Jak8 = nil
        elseif (h == Mission.m_Jak9) then
            Mission.m_Jak9 = nil
        elseif (h == Mission.m_Jak10) then
            Mission.m_Jak10 = nil
        elseif (h == Mission.m_JakStay1) then
            Mission.m_JakStay1 = nil
        elseif (h == Mission.m_JakStay2) then
            Mission.m_JakStay2 = nil
        end
    elseif (teamNum == Mission.m_HostTeam) then
        if (h == Mission.m_PowerCrystal) then
            Mission.m_PowerCrystalDestroyedTime = Mission.m_MissionTime + SecondsToTurns(2.5)
            Mission.m_PowerCrystalDestroyed = true
        elseif (h == Mission.m_PlayersRecy) then
            Mission.m_RecyclerDestroyedTime = Mission.m_MissionTime + SecondsToTurns(3)
            Mission.m_RecyclerDestroyed = true
        end
    end

    if (Mission.m_EnableISDFWaves and Mission.m_ISDFWaveSpawned) then
        if (GetTeamNum(h) ~= Mission.m_EnemyTeam) then return end

        if (h == Mission.m_ISDFAttacker1) then
            Mission.m_ISDFAttacker1 = nil
            Mission.m_YelenaTarget = nil
        elseif (h == Mission.m_ISDFAttacker2) then
            Mission.m_ISDFAttacker2 = nil
            Mission.m_YelenaTarget = nil
        elseif (h == Mission.m_ISDFAttacker3) then
            Mission.m_ISDFAttacker3 = nil
            Mission.m_YelenaTarget = nil
        elseif (h == Mission.m_ISDFAttacker4) then
            Mission.m_ISDFAttacker4 = nil
            Mission.m_YelenaTarget = nil
        end

        CheckWaveAttackersDefeated()
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

    if (not Mission.m_MissionOver) then
        if (Mission.m_StartDone) then
            -- PHASE-BASED STATE MACHINE
            if Mission.m_CurrentPhase == MissionPhase.INTRO then
                IntroHandlers[Mission.m_IntroState]()
            elseif Mission.m_CurrentPhase == MissionPhase.POWERUP then
                PowerupHandlers[Mission.m_PowerupState]()
            elseif Mission.m_CurrentPhase == MissionPhase.DEFENSE then
                DefenseHandlers[Mission.m_DefenseState]()
            elseif Mission.m_CurrentPhase == MissionPhase.ESCORT then
                EscortHandlers[Mission.m_EscortState]()
            elseif Mission.m_CurrentPhase == MissionPhase.PLAYER_ESCORT then
                PlayerEscortHandlers[Mission.m_PlayerEscortState]()

                if (not Mission.m_RockslideFinished) then
                    RockslideHandlers[Mission.m_RockslideState]()
                end
            end

            HandleFailureConditions()

            if (Mission.m_EnableAnimals) then HandleMireAnimals() end
            if (Mission.m_EnableISDF) then HandleISDF() end
            if (Mission.m_DeltaBrainActive) then HandleDeltaBrain() end
            if (Mission.m_YelenaBrainActive) then YelenaHandlers[Mission.m_YelenaState]() end

            if (Mission.m_IsCooperativeMode == false and Mission.m_IntroCutsceneDone == false) then
                if (CameraCancelled()) then
                    Mission.m_IntroCutsceneDone = true

                    if (IsAround(Mission.m_PlayerPilo1)) then RemoveObject(Mission.m_PlayerPilo1) end
                    if (IsAround(Mission.m_ShabPilo)) then RemoveObject(Mission.m_ShabPilo) end
                    if (IsAround(Mission.m_ShabPilo3)) then RemoveObject(Mission.m_ShabPilo3) end

                    if (Mission.m_ConstructorMoved == false) then
                        if Mission.m_Cons then Goto(Mission.m_Cons, "builder_path2", 0) end
                        Mission.m_ConstructorMoved = true
                    end

                    if (not IsAudioMessageDone(Mission.m_CutsceneAudioClip)) then
                        StopAudioMessage(Mission.m_CutsceneAudioClip)
                    end

                    CameraFinish()
                    CreateShab3Pilot()
                end
            end
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
    if (Mission.m_EnableISDFWaves and Mission.m_ISDFWaveSpawned) then
        if (GetTeamNum(victimHandle) ~= Mission.m_EnemyTeam) then return end

        if (victimHandle == Mission.m_ISDFAttacker1) then
            Mission.m_ISDFAttacker1 = nil
        elseif (victimHandle == Mission.m_ISDFAttacker2) then
            Mission.m_ISDFAttacker2 = nil
        elseif (victimHandle == Mission.m_ISDFAttacker3) then
            Mission.m_ISDFAttacker3 = nil
        elseif (victimHandle == Mission.m_ISDFAttacker4) then
            Mission.m_ISDFAttacker4 = nil
        end

        CheckWaveAttackersDefeated()
    end

    return _Cooperative.PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF)
end

function PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
    if (pilotHandle == Mission.m_ShabPilo3 and emptyCraftHandle == Mission.m_Yelena and not Mission.m_ShabInShip) then
        Mission.m_ShabInShip = true
    end

    if (not Mission.m_ShabRelook and Mission.m_ShabInShip and (emptyCraftHandle == Mission.m_PlayerSentry1 or emptyCraftHandle == Mission.m_PlayerSentry2 or emptyCraftHandle == Mission.m_PlayerSentry3 or emptyCraftHandle == Mission.m_PlayerSentry4)) then
        if (Mission.m_Yelena) then LookAt(Mission.m_Yelena, emptyCraftHandle) end
        Mission.m_ShabRelook = true
    end

    return _Cooperative.PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
end

function RespawnPilot(DeadObjectHandle, Team)
    return _Cooperative.RespawnPilot(DeadObjectHandle, Team, Mission.m_PlayerPilotODF)
end

function DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI)
    return _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI, Mission.m_PlayerPilotODF)
end

function PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
    if (IsPlayer(ShooterHandle) and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (IsAlive(Mission.m_Yelena) and VictimHandle == Mission.m_Yelena) then
            playAudioWithDelay("scngen30.wav", 3.5)
        end
    end
end

-- =========================
-- Related Mission Logic
-- =========================

function HandleFailureConditions()
    if (Mission.m_PowerLungWarningActive) then
        if (Mission.m_MissionTime > Mission.m_PowerLunchTookTooLongTime) then
            ClearObjectives()
            AddObjective("scion0113b.otf", "RED")
            AddObjective("scion0113c.otf", "RED")

            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0136.wav")

            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("You must follow Shabayev's orders and build a Lung on your Kiln.")
                DoGameover(10)
            else
                FailMission(GetTime() + 10, "scion01L6.txt")
            end

            Mission.m_MissionOver = true
        end
    end

    if (Mission.m_MorphWarningActive) then
        if (Mission.m_MissionTime > Mission.m_MorphTookTooLongTime) then
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

    if (Mission.m_SpawnDeltaSquad) then
        if (Mission.m_MeetDeltaWarningActive) then
            if (Mission.m_MissionTime > Mission.m_MeetDeltaWarningTime) then
                if (Mission.m_DeltaWarningCount == 0) then
                    playAudioWithDelay("scion0112.wav", 4.5)
                    Mission.m_MeetDeltaWarningTime = Mission.m_MissionTime + SecondsToTurns(45)
                    Mission.m_DeltaWarningCount = Mission.m_DeltaWarningCount + 1
                elseif (Mission.m_DeltaWarningCount == 1) then
                    playAudioWithDelay("scion0111.wav", 4.5)
                    Mission.m_MeetDeltaWarningTime = Mission.m_MissionTime + SecondsToTurns(30)
                    Mission.m_DeltaWarningCount = Mission.m_DeltaWarningCount + 1
                elseif (Mission.m_DeltaWarningCount == 2) then
                    playAudioWithDelay("scion0124.wav", 8.5)
                    Mission.m_DeltaWarningCount = Mission.m_DeltaWarningCount + 1
                elseif (Mission.m_DeltaWarningCount == 3 and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                    Mission.m_MeetDeltaWarningActive = false
                    AddObjectiveOverride("scion0102.otf", "RED", 10, true, Mission.m_IsCooperativeMode)

                    if (Mission.m_IsCooperativeMode) then
                        NoteGameoverWithCustomMessage(
                            "By leaving Delta Wing alone at Nav 1, you failed to follow orders and left the Power Crystal vulnerable.")
                        DoGameover(6)
                    else
                        FailMission(GetTime() + 6, "scion01L1.txt")
                    end

                    Mission.m_MissionOver = true
                end
            end
        end

        if (Mission.m_PowerCrystalDestroyed and Mission.m_PowerCrystalDestroyedTime < Mission.m_MissionTime) then
            playAudioWithDelay("scion0125.wav", 8.5)
            AddObjectiveOverride("scion0111.otf", "RED", 10, true, Mission.m_IsCooperativeMode)

            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("The Power Crystal was destroyed.")
                DoGameover(10)
            else
                FailMission(GetTime() + 10, "scion01L4.txt")
            end

            Mission.m_MissionOver = true
        end
    end

    if (Mission.m_RecyclerDestroyed and Mission.m_RecyclerDestroyedTime < Mission.m_MissionTime) then
        playAudioWithDelay("scion0131.wav", 5.5)
        AddObjectiveOverride("scion0112.otf", "RED", 10, true, Mission.m_IsCooperativeMode)

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The Matriarch was destroyed.")
            DoGameover(10)
        else
            FailMission(GetTime() + 10, "scion01L5.txt")
        end

        Mission.m_MissionOver = true
    end
end

function HandleMireAnimals()
    if (not Mission.m_Jak12Spawned and Mission.m_Jak12SpawnTime < Mission.m_MissionTime) then
        Mission.m_Jak1 = BuildObject("mcjak01", 0, "jak1spawn")
        Mission.m_Jak2 = BuildObject("mcjak01", 0, "jak2spawn")
        Goto(Mission.m_Jak1, "jakstop1")
        Follow(Mission.m_Jak2, Mission.m_Jak1)
        Mission.m_Jak12Spawned = true
    elseif (Mission.m_Jak12Spawned) then
        if (not Mission.m_JakStop1 and GetDistance(Mission.m_Jak1, "jakstop1") < 15) then
            if (IsAlive(Mission.m_Jak1)) then
                LookAt(Mission.m_Jak1, Mission.m_PlayersRecy)
            end

            if (IsAlive(Mission.m_Jak2)) then
                LookAt(Mission.m_Jak2, Mission.m_PlayersRecy)
            end

            Mission.m_JakGoTime2 = Mission.m_MissionTime + SecondsToTurns(10)
            Mission.m_JakStop1 = true
        elseif (not Mission.m_JakStop2 and Mission.m_JakGoTime2 < Mission.m_MissionTime) then
            if (IsAlive(Mission.m_Jak1)) then
                Goto(Mission.m_Jak1, "jakstop2")

                if (IsAlive(Mission.m_Jak2)) then
                    Follow(Mission.m_Jak2, Mission.m_Jak1)
                end
            end
            Mission.m_JakStop2 = true
        end
    end

    if (Mission.m_Jak910SpawnTime < Mission.m_MissionTime) then
        Mission.m_Jak9 = BuildObject("mcjak01", 0, "jak9spawn")
        Mission.m_Jak10 = BuildObject("mcjak01", 0, "jak10spawn")
        Goto(Mission.m_Jak9, "jak_go1")
        Goto(Mission.m_Jak10, "jak_go1")
        Mission.m_Jak910SpawnTime = Mission.m_MissionTime + SecondsToTurns(300)
    end
end

function HandleISDF()
    if (Mission.m_EnableISDFWaves) then
        if (Mission.m_ISDFWaveSpawned) then return end
        if (Mission.m_ISDFWaveTime > Mission.m_MissionTime) then return end

        local waveAttack = m_WaveAttackers[Mission.m_ISDFWaveCount][Mission.m_MissionDifficulty]

        for i = 1, #waveAttack do
            local attackerODF = waveAttack[i]
            local spawnPoint = ""
            local safePoint = ""

            if (i % 2 == 0) then
                spawnPoint = "spawn_2_a"
                safePoint = "spawn_2_b"
            else
                spawnPoint = "spawn_1_a"
                safePoint = "spawn_1_b"
            end

            local attackerHandle = BuildObjectAtSafePath(attackerODF, Mission.m_EnemyTeam, spawnPoint, safePoint,
                _Cooperative.m_TotalPlayerCount)

            if (i == 1) then
                Mission.m_ISDFAttacker1 = attackerHandle
            elseif (i == 2) then
                Mission.m_ISDFAttacker2 = attackerHandle
            elseif (i == 3) then
                Mission.m_ISDFAttacker3 = attackerHandle
            elseif (i == 4) then
                Mission.m_ISDFAttacker4 = attackerHandle
            end
        end

        if (Mission.m_ISDFWaveCount == 1) then
            Attack(Mission.m_ISDFAttacker1, Mission.m_Yelena)
            Attack(Mission.m_ISDFAttacker2, Mission.m_MainPlayer)
        elseif (Mission.m_ISDFWaveCount == 2) then
            Attack(Mission.m_ISDFAttacker1, Mission.m_MainPlayer)
            Attack(Mission.m_ISDFAttacker2, Mission.m_Kiln)

            if (Mission.m_ISDFAttacker3) then
                Attack(Mission.m_ISDFAttacker3, Mission.m_PlayersRecy)
            end
        elseif (Mission.m_ISDFWaveCount == 3) then
            Attack(Mission.m_ISDFAttacker1, Mission.m_Kiln)
            Attack(Mission.m_ISDFAttacker2, Mission.m_MainPlayer)

            if (Mission.m_ISDFAttacker3) then
                Attack(Mission.m_ISDFAttacker3, Mission.m_Cons)
            end

            if (Mission.m_ISDFAttacker4) then
                Attack(Mission.m_ISDFAttacker4, Mission.m_PlayersRecy)
            end
        elseif (Mission.m_ISDFWaveCount == 4) then
            Attack(Mission.m_ISDFAttacker1, Mission.m_MainPlayer)
            Attack(Mission.m_ISDFAttacker2, Mission.m_Yelena)
            Attack(Mission.m_ISDFAttacker3, Mission.m_Cons)

            if (Mission.m_ISDFAttacker4) then
                Attack(Mission.m_ISDFAttacker4, Mission.m_PlayersRecy)
            end
        end

        Mission.m_ISDFWaveSpawned = true
    elseif (Mission.m_PlayerEscortTug) then
        if (Mission.m_ISDFRouteDelay > Mission.m_MissionTime) then return end

        if (not Mission.m_ISDFRoute1Attack) then
            local check1 = GetDistance(Mission.m_PowerCrystal, "trig_routeattack1") < 40
            local check2 = IsPlayerWithinDistance("trig_routeattack1", 100, _Cooperative.m_TotalPlayerCount)

            if (check1 or check2) then
                Attack(Mission.m_ISDFRouteAttacker1A, Mission.m_PowerCrystal)
                Attack(Mission.m_ISDFRouteAttacker1B, GetTug(Mission.m_PowerCrystal))
                Defend2(Mission.m_ISDFRouteAttacker1C, Mission.m_ISDFRouteAttacker1B)
                Mission.m_ISDFRoute1Attack = true
            end
        end

        if (not Mission.m_ISDFRoute2Attack) then
            local check1 = GetDistance(Mission.m_PowerCrystal, "trig_routeattack2") < 40
            local check2 = IsPlayerWithinDistance("trig_routeattack2", 100, _Cooperative.m_TotalPlayerCount)

            if (check1 or check2) then
                Attack(Mission.m_ISDFRouteAttacker2A, Mission.m_PowerCrystal)
                Attack(Mission.m_ISDFRouteAttacker2B, GetTug(Mission.m_PowerCrystal))
                Mission.m_ISDFRoute2Attack = true
            end
        end

        Mission.m_ISDFRouteDelay = Mission.m_MissionTime + SecondsToTurns(1.5)
    end
end

function HandleDeltaBrain()
    if (not Mission.m_EscortComplete) then
        if (not Mission.m_Escort1Far and GetDistance(Mission.m_DeltaSquad1, Mission.m_Hauler) > 55) then
            LookAt(Mission.m_DeltaSquad1, Mission.m_Hauler, 1)
            Mission.m_Escort1Far = true
            Mission.m_Escort1Close = false
        elseif (not Mission.m_Escort1Close and GetDistance(Mission.m_DeltaSquad1, Mission.m_Hauler) < 40) then
            Retreat(Mission.m_DeltaSquad1, "rondevous1", 1)
            Mission.m_Escort1Close = true
            Mission.m_Escort1Far = false
        end
    end

    if (Mission.m_AmbushDefeated) then
        if (not Mission.m_EscortRetreat) then
            Retreat(Mission.m_DeltaSquad1, "escort1a_go1")
            Retreat(Mission.m_DeltaSquad2, "escort1b_go1")
            Mission.m_EscortRetreat = true
        else
            if (not Mission.m_Escort1Look and GetDistance(Mission.m_DeltaSquad1, "escort1a_go1") < 20) then
                LookAt(Mission.m_DeltaSquad1, Mission.m_MainPlayer, 1)
                Mission.m_Escort1Look = true
            end

            if (not Mission.m_Escort2Look and GetDistance(Mission.m_DeltaSquad2, "escort1b_go1") < 20) then
                LookAt(Mission.m_DeltaSquad2, Mission.m_MainPlayer, 1)
                Mission.m_Escort2Look = true
            end
        end
    end
end

function CreateShab3Pilot()
    Mission.m_ShabPilo3 = BuildObject("fspilo_r", Mission.m_HostTeam, "shab_spawn2")
    SetMaxHealth(Mission.m_ShabPilo3, 0)
    SetCurHealth(Mission.m_ShabPilo3, 0)
    SetCanSnipe(Mission.m_ShabPilo3, 0)
    Retreat(Mission.m_ShabPilo3, Mission.m_Yelena)
end

function CheckWaveAttackersDefeated()
    if (Mission.m_ISDFAttacker1 == nil and Mission.m_ISDFAttacker2 == nil and Mission.m_ISDFAttacker3 == nil and Mission.m_ISDFAttacker4 == nil) then
        Mission.m_ISDFWaveCount = Mission.m_ISDFWaveCount + 1

        if (Mission.m_ISDFWaveCount > #m_WaveAttackers) then
            Mission.m_EnableISDFWaves = false
            Mission.m_DeltaSquadSpawnTime = Mission.m_MissionTime + SecondsToTurns(30)
            Mission.m_SpawnDeltaSquad = true
        else
            Mission.m_ISDFWaveTime = Mission.m_MissionTime + SecondsToTurns(m_WaveCooldowns[Mission.m_ISDFWaveCount])
            Mission.m_ISDFWaveSpawned = false
        end
    end
end
