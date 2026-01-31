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

function RocketTankCondition(team, time)
    if (not DoesFactoryExist(team, time)) then
        return false, "Braddock doesn't have a Factory and can't build any Rocket Tanks.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "Braddock doesn't have a Relay Bunker and can't build any Rocket Tanks.";
    end

    if (not DoesArmoryExist(team, time)) then
        return false, "Braddock doesn't have an Armory and can't build any Rocket Tanks.";
    end

    return true, "Tasking Factory to build a Rocket Tank..";
end

function ServiceTruckCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time)

    if (recyclerExists) then
        return true, "Braddock is building a Service Truck..."
    else
        return false, "Braddock has enough Service Truck..."
    end
end

function ProbeAttackCondition(team, time)
    -- Special case: If the player has an ISDF Gun Tower, do not attack the base. 
    -- We need to exclude Yelena's base from these checks.
    -- TODO: Add a custom provide for ISDF / Scion Gun Towers?
    local gunTowerExists = AIPUtil.CountUnits(team, "ibgtow_x", 'enemy', true) > 0;

    if (gunTowerExists) then
        return false, "Braddock is not attacking the base...";
    end

    if (not DoesRecyclerExist(team, time)) then
        return false, "Braddock is not attacking the base...";
    end

    return true, "Braddock is attacking the base...";
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", 'sameteam', true) > 0;
end

function DoesFactoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FACTORY", "sameteam", true) > 0;
end

function DoesRelayBunkerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_COMMBUNKER", "sameteam", true) > 0;
end

function DoesArmoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_ARMORY", "sameteam", true) > 0;
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