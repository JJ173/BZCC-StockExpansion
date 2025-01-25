-- Return this to whatever file calls it.
Dispatch =
{
    -- Handle for generic use.
    Handle = 0,

    -- Store a delay for the unit (in turns), to avoid any units being sent on the same turn that they are in the world.
    DispatchDelay = 0,
}

function Dispatch:New(Handle, DispatchDelay)
    local o = {}

    o.Handle = Handle or 0;
    o.DispatchDelay = DispatchDelay or 0;

    setmetatable(o, { __index = self });

    return o;
end

return Dispatch;