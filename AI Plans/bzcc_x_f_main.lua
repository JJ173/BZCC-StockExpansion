function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

-- Function to make sure the CPU has enough Scavengers to do the job.
function CheckActiveScavengerCount(team, time)
    return (CheckRecyclerExists(team, time) and CountScavengers(team, time) < 2);
end

-- Utility functions to help keep track of important objects.
function CheckRecyclerExists(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLER", 'sameteam', true);
end

function CountScavengers(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", 'sameteam', true);
end