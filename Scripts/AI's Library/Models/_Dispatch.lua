-- Return this to whatever file calls it.
Dispatch =
{
    -- Handle for generic use.
    Handle = 0,

    -- To help us work out which unit type this is.
    Base = '',

    -- Keep track of the turn that the unit is built on.
    BuiltTime = 0,

    -- Store a delay for the unit (in turns), to avoid any units being sent on the same turn that they are in the world.
    DispatchDelay = 0,
}

function Dispatch:New(Handle, MissionTurn, objBase)
    local o = {}

    o.Handle = Handle or 0;
    o.BuiltTime = MissionTurn or 0;
    o.DispatchDelay = (MissionTurn + SecondsToTurns(2)) or 0;
    o.Base = objBase or '';

    setmetatable(o, { __index = self });

    return o;
end

return Dispatch;