--[[
    BZCC ISDF17 Lua Mission Script
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

-- =========================
-- Variables
-- =========================

local m_GameTPS = GetTPS()
local m_MissionName = _BZCCDatabase.Missions.ISDF17

-- Time between "Supplies" for difficulty.
local SupplyDropCooldown = { 20, 30, 40 }

local MissionPhase = {
    FIND_CORE = 1,
    BOSS = 2,
    RETREAT = 3
}

local FindCoreState = {
    INTRO = 1,
    INTRO_MESSAGE = 2,
    SHIELD_PHASE = 3
}

local Mission = {
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "ispilo_x",
    -- Specific to mission.
    m_PlayerShipODF = "ivtank_x",

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_Core = nil,
    m_BigDaddy = nil,

    m_ShieldA = nil,
    m_ShieldB = nil,
    m_ShieldC = nil,
    m_ShieldD = nil,
    m_ShieldE = nil,
    m_ShieldF = nil,

    m_TriggerA = nil,
    m_TriggerB = nil,
    m_TriggerC = nil,
    m_TriggerD = nil,
    m_TriggerE = nil,
    m_TriggerF = nil,

    m_HolderA = nil,
    m_HolderB = nil,
    m_HolderC = nil,
    m_HolderD = nil,
    m_HolderE = nil,
    m_HolderF = nil,

    m_CollapseA = nil,
    m_CollapseB = nil,
    m_CollapseC = nil,

    m_Turret1 = nil,
    m_Turret2 = nil,
    m_Turret3 = nil,

    m_Dropper1 = nil,
    m_Dropper1b = nil,
    m_Dropper2 = nil,
    m_Dropper2b = nil,
    m_Dropper3 = nil,
    m_Dropper4 = nil,
    m_Dropper5 = nil,
    m_Dropper6 = nil,
    m_Dropper7 = nil,
    m_Dropper8 = nil,
    m_Dropper9 = nil,
    m_Dropper10 = nil,
    m_Dropper11 = nil,

    m_Noz1 = nil,
    m_Noz2 = nil,
    m_Noz3 = nil,
    m_Noz4 = nil,

    m_Spawner1 = nil,
    m_Spawner2 = nil,
    m_Spawner3 = nil,
    m_Spawner4 = nil,
    m_Spawner5 = nil,

    m_SoundShieldA = nil,
    m_SoundShieldB = nil,
    m_SoundShieldC = nil,
    m_SoundShieldD = nil,
    m_SoundShieldE = nil,
    m_SoundShieldF = nil,

    m_SoundPoleA = nil,
    m_SoundPoleB = nil,
    m_SoundPoleD = nil,
    m_SoundPoleC = nil,
    m_SoundPoleE = nil,
    m_SoundPoleF = nil,

    m_SupplyTransport = nil,

    m_FirstObjectiveSet = false,
    m_RobotMessagePlayed = false,
    m_ShieldDoorsPlayed = false,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_SupplyTransportDelayTime = 0,
    m_MissionDelayTime = 0,

    m_CurrentPhase = MissionPhase.FIND_CORE,
    m_FindCorePhase = FindCoreState.INTRO
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

local FindCoreHandlers = {
    [FindCoreState.INTRO] = function()
        SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF")
        SetTeamNameForStat(Mission.m_EnemyTeam, "Scion")

        for i = 2, 5 do
            Ally(Mission.m_HostTeam, i)
        end

        Mission.m_Core = GetHandle("core")
        Mission.m_BigDaddy = GetHandle("big_daddy")

        -- Set the bigger crystal to spin.
        SetAnimation(Mission.m_BigDaddy, "spin", 0)

        -- Give all of our players the right weapon.
        for i = 1, _Cooperative.m_TotalPlayerCount do
            local pHandle = GetPlayerHandle(i)
            GiveWeapon(pHandle, "gspstab_c")
        end

        Mission.m_ShieldA = GetHandle("shielda")
        Mission.m_ShieldB = GetHandle("shieldb")
        Mission.m_ShieldC = GetHandle("shieldc")
        Mission.m_ShieldD = GetHandle("shieldd")
        Mission.m_ShieldE = GetHandle("shielde")
        Mission.m_ShieldF = GetHandle("shieldf")

        Mission.m_TriggerA = GetHandle("triggera")
        Mission.m_TriggerB = GetHandle("triggerb")
        Mission.m_TriggerC = GetHandle("triggerc")
        Mission.m_TriggerD = GetHandle("triggerd")
        Mission.m_TriggerE = GetHandle("triggere")
        Mission.m_TriggerF = GetHandle("triggerf")

        Mission.m_HolderA = GetHandle("holdera")
        Mission.m_HolderB = GetHandle("holderb")
        Mission.m_HolderC = GetHandle("holderc")
        Mission.m_HolderD = GetHandle("holderd")
        Mission.m_HolderE = GetHandle("holdere")
        Mission.m_HolderF = GetHandle("holderf")

        Mission.m_CollapseA = GetHandle("collapsea")
        Mission.m_CollapseB = GetHandle("collapseb")
        Mission.m_CollapseC = GetHandle("collapsec")

        Mission.m_Turret1 = GetHandle("turret1")
        Mission.m_Turret2 = GetHandle("turret2")
        Mission.m_Turret3 = GetHandle("turret3")

        Mission.m_Dropper1 = GetHandle("dropper1")
        Mission.m_Dropper1b = GetHandle("dropper1b")
        Mission.m_Dropper2 = GetHandle("dropper2")
        Mission.m_Dropper2b = GetHandle("dropper2b")
        Mission.m_Dropper3 = GetHandle("dropper3")
        Mission.m_Dropper4 = GetHandle("dropper4")
        Mission.m_Dropper5 = GetHandle("dropper5")
        Mission.m_Dropper6 = GetHandle("dropper6")
        Mission.m_Dropper7 = GetHandle("dropper7")
        Mission.m_Dropper8 = GetHandle("dropper8")
        Mission.m_Dropper9 = GetHandle("dropper9")
        Mission.m_Dropper10 = GetHandle("dropper10")
        Mission.m_Dropper11 = GetHandle("dropper11")

        Mission.m_Noz1 = GetHandle("noz1")
        Mission.m_Noz2 = GetHandle("noz2")
        Mission.m_Noz3 = GetHandle("noz3")
        Mission.m_Noz4 = GetHandle("noz4")

        Mission.m_Spawner1 = GetHandle("spawner1")
        Mission.m_Spawner2 = GetHandle("spawner2")
        Mission.m_Spawner3 = GetHandle("spawner3")
        Mission.m_Spawner4 = GetHandle("spawner4")
        Mission.m_Spawner5 = GetHandle("spawner5")

        Mission.m_SoundShieldA = GetHandle("sound_shielda")
        Mission.m_SoundShieldB = GetHandle("sound_shieldb")
        Mission.m_SoundShieldC = GetHandle("sound_shieldc")
        Mission.m_SoundShieldD = GetHandle("sound_shieldd")
        Mission.m_SoundShieldE = GetHandle("sound_shielde")
        Mission.m_SoundShieldF = GetHandle("sound_shieldf")

        Mission.m_SoundPoleA = GetHandle("sound_polea")
        Mission.m_SoundPoleB = GetHandle("sound_poleb")
        Mission.m_SoundPoleD = GetHandle("sound_polec")
        Mission.m_SoundPoleC = GetHandle("sound_poled")
        Mission.m_SoundPoleE = GetHandle("sound_polee")
        Mission.m_SoundPoleF = GetHandle("sound_polef")

        Mission.m_SupplyTransport = GetHandle("SupplyTransport")

        Mission.m_SupplyTransportDelayTime = Mission.m_MissionTime + SecondsToTurns(SupplyDropCooldown[Mission.m_MissionDifficulty])
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2)
        Mission.m_FindCorePhase = FindCoreState.INTRO_MESSAGE
    end,
    [FindCoreState.INTRO_MESSAGE] = function()
        if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end

        playAudioWithDelay("isdf1701.wav", 13.5)
        Mission.m_FindCorePhase = FindCoreState.SHIELD_PHASE
    end,
    [FindCoreState.SHIELD_PHASE] = function()
        if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then return end

        if (not Mission.m_FirstObjectiveSet) then
            AddObjectiveOverride("isdf1701.otf", "WHITE", 10, true, Mission.m_IsCooperativeMode)
            Mission.m_FirstObjectiveSet = true
        end

        if (not Mission.m_RobotMessagePlayed and IsPlayerWithinDistance("end_mission", 30, _Cooperative.GetTotalPlayers())) then
            playAudioWithDelay("isdf1703.wav", 5.5)
            Mission.m_RobotMessagePlayed = true
        end

        if (not Mission.m_ShieldDoorsPlayed) then
            local check1 = IsPlayerWithinDistance(Mission.m_ShieldA, 50, _Cooperative.GetTotalPlayers())
            local check2 = IsPlayerWithinDistance(Mission.m_ShieldB, 50, _Cooperative.GetTotalPlayers())

            if (check1 or check2) then
                playAudioWithDelay("isdf1706.wav", 3.5)
                Mission.m_ShieldDoorsPlayed = true
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

    -- Set difficulty based on whether it's coop or not.
    if (Mission.m_IsCooperativeMode) then
        Mission.m_MissionDifficulty = GetVarItemInt("network.session.ivar102") + 1
    else
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1
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

function AddObject(h)
    local teamNum = GetTeamNum(h)
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty)
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        SetSkill(h, 3)
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
        if (Mission.m_StartDone) then
            if (Mission.m_CurrentPhase == MissionPhase.FIND_CORE) then
                FindCoreHandlers[Mission.m_FindCorePhase]()
            end

            -- Drop Service Pods from the Supply Transport every 20 seconds for a player.
            -- Mimics a forgotten feature from the Demo DLL :)
            if (IsAlive(Mission.m_SupplyTransport) and Mission.m_SupplyTransportDelayTime < Mission.m_MissionTime) then
                -- Reset this based on difficulty.
                Mission.m_SupplyTransportDelayTime = Mission.m_MissionTime + SecondsToTurns(SupplyDropCooldown[Mission.m_MissionDifficulty])

                -- For each player that's around, spawn a Service Pod. 
                for i = 1, _Cooperative.m_TotalPlayerCount do
                    local pos = GetPosition(Mission.m_SupplyTransport)
                    local offset = (-8 * i)
                    pos.x = offset
                    StartSoundEffect("iapc04.wav", Mission.m_SupplyTransport)
                    BuildObject("apserv", Mission.m_HostTeam, pos)
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
    return _Cooperative.PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF)
end

function PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
    return _Cooperative.PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
end

-- =========================
-- Related Mission Logic
-- =========================
