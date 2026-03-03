-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()

-- Required Globals.
require("_GlobalVariables")

-- Required helper functions.
require("_HelperFunctions")

-- Required Skins Logic.
require("_Skins")

-- Database.
local _BZCCDatabase = require("_BZCCDatabase")

-- Discord
-- local _Discord = require("_Discord")

-- Managers
local _SaveLoad = require("_SaveLoad")
local _VoiceManager = require('_VoiceManager')

-- Shared Logic.
local _InstantCommon = require("_InstantCommon")

local _Session = {
    m_GameTPS = GetTPS(),

    -- Local to Instant Action (Non Multiplayer).
    m_CanRespawn = 1
}

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function InitialSetup()
    _InstantCommon.InitialSetup()
end

function Save()
    return _SaveLoad.Save(), _Session
end

function Load(ModuleData, SessionData)
    if (SessionData) then
        for k, v in pairs(SessionData) do
            _Session[k] = v
        end
    end

    if (ModuleData) then
        _SaveLoad.Load(ModuleData)
    else
        print("WARNING: No ModuleData provided to _SaveLoad.Load()")
    end
end

function AddObject(handle)
    _InstantCommon.AddObject(handle)
end

function DeleteObject(handle)
    _InstantCommon.DeleteObject(handle)
end

function Start()
    _InstantCommon.Start()

    _Session.m_CanRespawn = IFace_GetInteger(_BZCCDatabase.ShellVariables.CAN_RESPAWN)

    -- Start up Discord RPC.
    -- _Discord.Start("Instant Action 2.0", _Session.m_MapName)
end

function Update()
    _InstantCommon.Update()
    -- Update Discord.
    -- _Discord.Update()
end

function PlayerEjected(DeadObjectHandle)
    return DoEjectPilot
end

function PlayerDied(DeadObjectHandle, bSniped)
    if (IsPerson(DeadObjectHandle) == false and bSniped == false) then
        return DoEjectPilot
    end

    if (_Session.m_CanRespawn == 1 and IsAlive(_InstantCommon.GetPlayerRecycler())) then
        RespawnPlayer(false)
    else
        FailMission(GetTime() + 3.0)
    end

    return DLLHandled
end

function ObjectKilled(DeadObjectHandle, KillersHandle)
    if (not IsPlayer(DeadObjectHandle)) then
        local bWasDeadPilot = IsPerson(DeadObjectHandle)

        if (bWasDeadPilot == false) then
            return DoEjectPilot
        end

        return DLLHandled
    end

    DoTaunt(_BZCCDatabase.TauntTypes.TAUNTS_HumanShipDestroyed)

    return PlayerDied(DeadObjectHandle, false)
end

function ObjectSniped(DeadObjectHandle, KillersHandle)
    if (not IsPlayer(DeadObjectHandle)) then
        return DLLHandled
    end

    return PlayerDied(DeadObjectHandle, true)
end

function PreGetIn(cutWorld, pilotHandle, emptyCraftHandle)
    -- Apply a skin to the unit if it is a player.
    if (IsPlayer(pilotHandle)) then
        ApplySkinToHandle(GetPlayerName(pilotHandle), emptyCraftHandle, GetTeamNum(pilotHandle))
    end

    -- Run our replacement script logic.
    _VoiceManager.SwitchVehicleVoices(emptyCraftHandle, pilotHandle)

    -- Always allow the entry
    return PREGETIN_ALLOW
end

function PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
    _InstantCommon.RegisterHandleShot(ShooterHandle, VictimHandle, OrdnanceTeam)
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function RespawnPlayer(isGameStart)
    local recyclerPosition = GetPosition(_InstantCommon.GetPlayerRecycler())
    local respawnPosition = GetPositionNear(recyclerPosition, 10, 50)

    -- Prevent spawning within stuff.
    local PlayerODF = ""

    if (isGameStart) then
        PlayerODF = _InstantCommon.GetHumanTeamRace() .. "vscout_x"
    else
        respawnPosition.y = respawnPosition.y + 50
        PlayerODF = _InstantCommon.GetHumanTeamRace() .. "spilo_x"
    end

    local PlayerH = BuildObject(PlayerODF, InstantCommon.GetHumanTeam(), respawnPosition)
    SetAsUser(PlayerH, _InstantCommon.GetHumanTeam())
    AddPilotByHandle(PlayerH)
end