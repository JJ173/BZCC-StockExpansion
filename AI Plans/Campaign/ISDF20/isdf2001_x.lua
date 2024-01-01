function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

function ConstructorCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local consCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", 'sameteam', true);

    if (recyclerExists and consCount < 1) then
        return true, "Manson is building a constructor...";
    else
        return false, "Manson has enough constructors...";
    end
end

function Attack1Condition(team, time)
    -- Check if we have enough pools.
    local extractorCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'sameteam', true);

    if (extractorCount == 3) then
        return true, "Manson is sending tanks at the player...";
    else
        return false, "Manson doesn't have 3 pools...";
    end
end

function Attack2Condition(team, time)
    -- Check if we have enough pools.
    local extractorCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'sameteam', true);

    if (extractorCount == 2) then
        return true, "Manson is sending mortars and a tank at the player...";
    else
        return false, "Manson doesn't have 2 pools...";
    end
end

function Attack3Condition(team, time)
    -- Check if we have enough pools.
    local extractorCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'sameteam', true);

    if (extractorCount == 1) then
        return true, "Manson is sending scouts at the player...";
    else
        return false, "Manson doesn't have any pools...";
    end
end

function TurretCondition(team, time)
    -- Check if we have enough pools.
    local extractorCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'sameteam', true);

    if (extractorCount == 1) then
        return true, "Manson is building a turret...";
    else
        return false, "Manson doesn't have any pools...";
    end
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", 'sameteam', true) > 0;
end