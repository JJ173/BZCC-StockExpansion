DispatchClass = {}

---@class DispatchClass
---@field Handle Handle
---@field MissionTurn number
---@field Team number
---@field Class string
---@field DispatchDelay number
---@field Command number

---Creates and returns a new dispatch class with the intention of being dispatched by a script.
---@param Handle Handle
---@param MissionTurn number
---@param Team number
---@param objClass string
---@return DispatchClass
function DispatchClass.New(Handle, MissionTurn, Team, objClass)
    return {
        Handle = Handle,
        MissionTurn = MissionTurn,
        Team = Team,
        Class = objClass,
        DispatchDelay = MissionTurn + SecondsToTurns(5),
        Command = CMD_NONE
    }
end

---Returns true/false if the dispatch object is available for use.
---@param dispatchObject DispatchClass
---@param MissionTurn number
function DispatchClass.IsAvailable(dispatchObject, MissionTurn)
    return dispatchObject == nil or dispatchObject.DispatchDelay > MissionTurn or dispatchObject.Command == CMD_NONE
end

return DispatchClass;