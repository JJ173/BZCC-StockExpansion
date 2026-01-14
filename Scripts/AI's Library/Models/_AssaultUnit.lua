AssaultUnit =
{
    Handle = 0,
    DefenderHandle = 0,
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