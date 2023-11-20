function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

function CollectPoolCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local extractorCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'sameteam', true);

    if (recyclerExists and extractorCount < 2) then
        return true, "AAN base is collecting a pool...";
    else
        return false, "AAN base has enough extractors...";
    end
end

function CollectFieldCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local fieldExists = DoesLooseScrapExist(team, time);

    if (recyclerExists and fieldExists) then
        return true, "AAN base is collecting scrap...";
    else
        return false, "AAN base cannot find scrap...";
    end
end

function ConstructorCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local consCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", 'sameteam', true);

    if (recyclerExists and consCount < 1) then
        return true, "AAN base is building a constructor...";
    else
        return false, "AAN base has enough constructors...";
    end
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", 'sameteam', true) > 0;
end

function DoesLooseScrapExist(team, time)
    return AIPUtil.CountUnits(team, "resource", "friendly", true) > 0;
end