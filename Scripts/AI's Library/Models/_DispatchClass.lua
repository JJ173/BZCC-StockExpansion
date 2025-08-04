DispatchClass =
{
    MissionTime = 0,

    --- @type Handle
    DispatchObject = nil,

    CurrTeam = 0,
    DispatchType = 0,
    DispatchState = 0,

    IdleTime = 0
}

local DISPATCH_STATE_NONE = 0
local DISPATCH_STATE_GOTO = 1

function DispatchClass:New(DispatchObject, CurrTeam, DispatchType, IdleTime, MissionTime)
    local o = {}

    o.DispatchObject = DispatchObject or nil
    o.CurrTeam = CurrTeam or 0
    o.DispatchType = DispatchType or 0
    o.IdleTime = IdleTime or 0
    o.MissionTime = MissionTime or 0

    setmetatable(o, { __index = self })

    return o;
end

function DispatchClass:UpdateTurn(MissionTime)
    self.MissionTime = MissionTime
end

function DispatchClass:MoveTo(path)
    self.DispatchState = DISPATCH_STATE_GOTO
    Goto(self.DispatchObject, path, 0);
end

function DispatchClass:IsIdle()
    return self.DispatchState == DISPATCH_STATE_NONE and self.MissionTime < self.IdleTime
end

return DispatchClass;
