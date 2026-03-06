-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()

-- Managers
local _SaveLoad = require("_SaveLoad")

-- Shared Logic.
local _InstantCommon = require("_InstantCommon")

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function InitialSetup()
    _InstantCommon.InitialSetup()
end

function Save()
    return _SaveLoad.Save()
end

function Load(ModuleData)
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
end

function Update()
    _InstantCommon.Update()
end

function AddPlayer(id, Team, IsNewPlayer)
    return _InstantCommon.AddPlayer(id, Team, IsNewPlayer)
end

function DeletePlayer(id)
    return _InstantCommon.DeletePlayer(id)
end

function PlayerEjected(DeadObjectHandle)
    return InstantCommon.PlayerEjected(DeadObjectHandle)
end

function ObjectKilled(DeadObjectHandle, KillersHandle)
    return InstantCommon.ObjectKilled(DeadObjectHandle, KillersHandle)
end

function ObjectSniped(DeadObjectHandle, KillersHandle)
    return InstantCommon.ObjectSniped(DeadObjectHandle, KillersHandle)
end

function RespawnPilot(DeadObjectHandle, Team)
    return InstantCommon.RespawnPilot(DeadObjectHandle, Team)
end

function PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
    return _InstantCommon.PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
end

function PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
    _InstantCommon.PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
end