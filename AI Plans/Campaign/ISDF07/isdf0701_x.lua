function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

function CollectPoolCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local extractorCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'sameteam', true);

    if (recyclerExists and extractorCount < 2) then
        return true, "Manson is collecting a pool...";
    else
        return false, "Manson has enough extractors...";
    end
end

function ConstructorCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local consCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", 'sameteam', true);

    if (recyclerExists and consCount < 2) then
        return true, "Manson is building a constructor...";
    else
        return false, "Manson has enough constructors...";
    end
end

function ScoutCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local consCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", 'sameteam', true);

    if (recyclerExists and consCount > 1) then
        return true, "Manson is building Scouts...";
    else
        return false, "Manson has enough Scouts...";
    end
end

function TankCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local bunkerExists = DoesCommBunkerExist(team, time);

    if (recyclerExists and bunkerExists) then
        return true, "Manson is building Tanks...";
    else
        return false, "Manson has enough Tanks...";
    end
end

function Power1Condition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local powerExists = DoesPowerExist(team, time);
    local pathExists = AIPUtil.PathExists("manson_pgen1");

    if (consExists and not powerExists and pathExists) then
        return true, "Manson is building Power 1...";
    else
        return false, "Manson can't build Power 1...";
    end
end

function Power2Condition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local powerCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_POWERPLANT", 'sameteam', true);
    local pathExists = AIPUtil.PathExists("manson_pgen2");

    if (consExists and powerCount < 2 and pathExists) then
        return true, "Manson is building Power 2...";
    else
        return false, "Manson can't build Power 2...";
    end
end

function Power3Condition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local powerCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_POWERPLANT", 'sameteam', true);
    local pathExists = AIPUtil.PathExists("manson_pgen3");

    if (consExists and powerCount < 3 and pathExists) then
        return true, "Manson is building Power 3...";
    else
        return false, "Manson can't build Power 3...";
    end
end

function FactoryCondition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local factoryExists = DoesFactoryExist(team, time);
    local powerExists = DoesPowerExist(team, time);
    local pathExists = AIPUtil.PathExists("manson_fact");
    local powerCount = AIPUtil.GetPower(team, false);

    if (consExists and not factoryExists and pathExists and powerCount > 0) then
        return true, "Manson is building a factory";
    else
        return false, "Manson can't build a factory...";
    end
end

function Bunker1Condition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local pathExists = AIPUtil.PathExists("manson_cbun1");
    local powerCount = AIPUtil.GetPower(team, false);

    if (consExists and pathExists and powerCount > 0) then
        return true, "Manson is building Bunker 1";
    else
        return false, "Manson can't build Bunker 1...";
    end
end

function Bunker2Condition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local pathExists = AIPUtil.PathExists("manson_cbun2");
    local powerCount = AIPUtil.GetPower(team, false);

    if (consExists and pathExists and powerCount > 0) then
        return true, "Manson is building Bunker 2";
    else
        return false, "Manson can't build Bunker 2...";
    end
end

function ServiceBayCondition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local sbayExists = DoesServiceBayExist(team, time);
    local powerExists = DoesPowerExist(team, time);
    local pathExists = AIPUtil.PathExists("manson_sbay");
    local powerCount = AIPUtil.GetPower(team, false);

    if (consExists and not sbayExists and pathExists and powerCount > 0) then
        return true, "Manson is building a Service Bay";
    else
        return false, "Manson can't build a Service Bay...";
    end
end

function ServiceTruckCondition(team, time)
    local recyclerExists = DoesRecyclerExist(team, time);
    local serviceBayExists = DoesServiceBayExist(team, time);

    if (recyclerExists and serviceBayExists) then
        return true, "Manson is building Service Trucks...";
    else
        return false, "Manson has enough Service Trucks...";
    end
end

function GunTower1Condition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local pathExists = AIPUtil.PathExists("manson_gtow1");
    local commBunkerExists = DoesCommBunkerExist(team, time);
    local powerCount = AIPUtil.GetPower(team, false);

    if (consExists and pathExists and powerCount > 0 and commBunkerExists) then
        return true, "Manson is building Gun Tower 1";
    else
        return false, "Manson can't build Gun Tower 1...";
    end
end

function GunTower2Condition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local pathExists = AIPUtil.PathExists("manson_gtow2");
    local commBunkerExists = DoesCommBunkerExist(team, time);
    local powerCount = AIPUtil.GetPower(team, false);

    if (consExists and pathExists and powerCount > 0 and commBunkerExists) then
        return true, "Manson is building Gun Tower 2";
    else
        return false, "Manson can't build Gun Tower 2...";
    end
end

function GunTower3Condition(team, time)
    local consExists = DoesConstructorExist(team, time);
    local pathExists = AIPUtil.PathExists("manson_gtow3");
    local commBunkerExists = DoesCommBunkerExist(team, time);
    local powerCount = AIPUtil.GetPower(team, false);

    if (consExists and pathExists and powerCount > 0 and commBunkerExists) then
        return true, "Manson is building Gun Tower 3";
    else
        return false, "Manson can't build Gun Tower 3...";
    end
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", 'sameteam', true) > 0;
end

function DoesConstructorExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", 'sameteam', true) > 0;
end

function DoesFactoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FACTORY", 'sameteam', true) > 0;
end

function DoesPowerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_POWERPLANT", 'sameteam', true) > 0;
end

function DoesServiceBayExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SUPPLYDEPOT", 'sameteam', true) > 0;
end

function DoesCommBunkerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_COMMBUNKER", 'sameteam', true) > 0;
end