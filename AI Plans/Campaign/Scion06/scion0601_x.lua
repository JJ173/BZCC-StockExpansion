function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

function CollectPoolCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local poolExists = DoesScrapPoolExist(team, time);

    if (recyclerExists and poolExists) then
        return true, "Braddock is collecting a pool...";
    else
        return false, "Braddock cannot find a pool...";
    end
end

function CollectFieldCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local fieldExists = DoesLooseScrapExist(team, time);

    if (recyclerExists and fieldExists) then
        return true, "Braddock is collecting scrap...";
    else
        return false, "Braddock cannot find scrap...";
    end
end

function ScavengerCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local scavengerCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", 'sameteam', true);

    if (recyclerExists and scavengerCount < 2) then
        return true, "Braddock is building a Scavenger...";
    else
        return false, "Braddock has enough Scavengers...";
    end
end

function ConstructorCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local consCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", 'sameteam', true);

    if (recyclerExists and consCount < 1) then
        return true, "Braddock is building a constructor...";
    else
        return false, "Braddock has enough constructors...";
    end
end

function TurretCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local turretCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", 'sameteam', true);

    if (recyclerExists and turretCount < 4) then
        return true, "Braddock is building a turret...";
    else
        return false, "Braddock has enough turrets...";
    end
end

function ServiceTruckCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local serviceTruckCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SERVICETRUCK", 'sameteam', true);

    if (recyclerExists and serviceTruckCount < 3) then
        return true, "Braddock is building a turret...";
    else
        return false, "Braddock has enough turrets...";
    end
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", 'sameteam', true) > 0;
end

function DoesServiceBayExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SUPPLYDEPOT", "sameteam", true) > 0;
end

function DoesScrapPoolExist(team, time)
    return AIPUtil.CountUnits(team, "biometal", "friendly", true) > 0;
end

function DoesLooseScrapExist(team, time)
    return AIPUtil.CountUnits(team, "resource", "friendly", true) > 0;
end
