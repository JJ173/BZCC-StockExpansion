function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

function TurretCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local turretCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", 'sameteam', true);

    if (recyclerExists and turretCount < 2) then
        return true, "Yelena is building a turret...";
    else
        return false, "Yelena has enough turrets...";
    end
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", 'sameteam', true) > 0;
end