-- Return this to whatever file calls it.
Building =
{
    Team = 0,
    Handle = 0,
};

function Building:New(Team, Handle)
    local o = {}

    setmetatable(o, {__index = self});

    o.Team = Team or 0;
    o.Handle = Handle or 0;

    return o;
end

return Building;