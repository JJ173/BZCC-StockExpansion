-- Return this to whatever file calls it.
Pool =
{
    -- Handle for generic use.
    Handle = 0,

    -- This is for the CPU, so we can tell which pools need defending.
    Guard = 0,

    -- So we don't need to call GetPosition() multiple times, we can just store it.
    Position = 0,

    -- Another CPU only variable. We want this so we can calculate the distance between the pool and the CPU Recycler for priority use.
    DistanceFromCPURecycler = 0,

    -- Check to see if this is locked. 
    isLocked = false,
}

function Pool:New(Handle, Guard, Position, DistanceFromCPURecycler, isLocked)
    local o = {}

    setmetatable(o, { __index = self });

    o.Handle = Handle or 0;
    o.Guard = Guard or 0;
    o.Position = Position or 0;
    o.DistanceFromCPURecycler = DistanceFromCPURecycler or 0;
    o.isLocked = isLocked or false;

    return o;
end

return Pool;