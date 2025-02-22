-- Return this to whatever file calls it.
AssaultUnit =
{
    -- Handle for generic use.
    Handle = 0,

    -- Checks to see if this unit already has a unit defending it.
    DefenderHandle = 0,

    -- Checks to see if this unit already has a unit servicing it.
    HealerHandle = 0,
}

function AssaultUnit:New(Handle, DefenderHandle, HealerHandle)
    local o = {}

    o.Handle = Handle or 0;
    o.HasDefendUnit = DefenderHandle or 0;
    o.HealerHandle = HealerHandle or 0;

    setmetatable(o, { __index = self });

    return o;
end

return AssaultUnit;