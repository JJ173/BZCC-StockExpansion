---@class AIUnit
---@field Handle Handle
---@field State string
---@field TimeBuilt integer
---@field DispatchDelay integer

AIUnit = {}

function AIUnit.New(Handle, MissionTurn)
    return {
        Handle = Handle,
        State = '',
        TimeBuilt = MissionTurn,
        DispatchDelay = (MissionTurn + SecondsToTurns(10))
    }
end

return AIUnit;