--[[
    BZCC ISDF17 Lua Mission Script
    Written by AI_Unit
--]]

-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()

require("_GlobalVariables")
require("_HelperFunctions")

local _BZCCDatabase = require("_BZCCDatabase");
local _Cooperative = require("_Cooperative")
local _Subtitles = require('_Subtitles')

-- =========================
-- Variables
-- =========================

local m_GameTPS = GetTPS()
local m_MissionName = _BZCCDatabase.Missions.ISDF17

local Mission = {
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
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
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty)
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        SetSkill(h, 3)
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