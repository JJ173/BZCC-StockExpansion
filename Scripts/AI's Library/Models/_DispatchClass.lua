DispatchClass = {}

---@class DispatchClass
---@field Handle Handle
---@field MissionTurn number
---@field Team number
---@field Class string
---@field DispatchDelay number
---@field MaxHealth? integer
---@field MaxAmmo? integer
---@field AssaultTarget? AssaultClass
---@field DispatchTarget? DispatchClass
---@field DispatchSpot? Vector

---Creates and returns a new dispatch class with the intention of being dispatched by a script.
---@param handle Handle
---@param missionTurn number
---@param team number
---@param objClass string
---@return DispatchClass
function DispatchClass.New(handle, missionTurn, team, objClass)
    ---@type DispatchClass
    return {
        Handle = handle,
        MissionTurn = missionTurn,
        Team = team,
        Class = objClass,
        DispatchDelay = missionTurn + SecondsToTurns(10),
        Command = CMD_NONE,
        MaxHealth = GetMaxHealth(handle),
        MaxAmmo = GetMaxAmmo(handle)
    }
end

---Returns true/false if the dispatch object is available for use.
---@param dispatchObject DispatchClass
---@param MissionTurn number
function DispatchClass.IsAvailable(dispatchObject, MissionTurn)
    if (dispatchObject == nil) then
        return false
    end

    if (dispatchObject.DispatchDelay > MissionTurn) then
        return false
    end

    if (not IsIdle(dispatchObject.Handle)) then
        return false
    end

    return true
end

return DispatchClass;
