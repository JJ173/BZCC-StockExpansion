-- Return this to whatever file calls it.
AIUnit =
{
    -- Handle for generic use.
    Handle = 0,

    -- To help us work out which unit type this is.
    State = '',

    -- Keep track of the turn that the unit is built on.
    BuiltTime = 0,

    -- Store a delay for the unit (in turns), to avoid any units being sent on the same turn that they are in the world.
    DispatchDelay = 0,
}

function AIUnit:New(Handle, MissionTurn)
    local o = {}

    o.Handle = Handle or 0;
    o.BuiltTime = MissionTurn or 0;
    o.DispatchDelay = (MissionTurn + SecondsToTurns(5)) or 0;
    o.State = 'IDLE';

    setmetatable(o, { __index = self });

    return o;
end

return AIUnit;