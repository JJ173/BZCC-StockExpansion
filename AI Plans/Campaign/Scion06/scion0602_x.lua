function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team)
end

function CollectPoolCondition(team, time)
    local extractorCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'sameteam', true)

    if (extractorCount >= 2) then
        return false, "I already have enough pools. We can't disrupt the player..."
    end

    return true, "I need a first or second pool..."
end

function TurretCondition(team, time)
    local turretCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", 'friendly', true)

    if (DoesRecyclerExist(team, time) and turretCount < 2) then
        return true, "Yelena is building a turret..."
    else
        return false, "Yelena has enough turrets..."
    end
end

function PlayerSentryCondition(team, time)
    local sentryCondition = AIPUtil.CountUnits(team, "fvsent_r06", 'friendly', true)

    if (DoesFactoryExist(team, time) and sentryCondition < 2) then
        return true, "Yelena is building a Sentry to send to the player..."
    else
        return false, "Yelena has enough Sentries..."
    end
end

function BuildKiln(team, time)
    if (not IsPathAvailable("yelena_forge")) then
        return false, "yelena_forge is unavailable, or a building already exists on it..."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet..."
    end

    return true, "Tasking a Constructor to build a Kiln..."
end

function BuildAntenna(team, time)
    if (not DoesFactoryExist(team, time)) then
        return false, "Yelena doesn't have a Kiln/Forge yet..."
    end

    if (not IsPathAvailable("yelena_overseer")) then
        return false, "yelena_overseer is unavailable, or a building already exists on it..."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet..."
    end

    return true, "Tasking a Constructor to build a Antenna..."
end

function BuildStronghold(team, time)
    if (not DoesFactoryExist(team, time)) then
        return false, "Yelena doesn't have a Kiln/Forge yet..."
    end

    if (not IsPathAvailable("yelena_stronghold")) then
        return false, "yelena_stronghold is unavailable, or a building already exists on it..."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet..."
    end

    return true, "Tasking a Constructor to build a Stronghold..."
end

function BuildDower(team, time)
    if (not DoesFactoryExist(team, time)) then
        return false, "Yelena doesn't have a Kiln/Forge yet..."
    end

    if (not IsPathAvailable("yelena_dower")) then
        return false, "yelena_dower is unavailable, or a building already exists on it..."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet..."
    end

    return true, "Tasking a Constructor to build a Dower..."
end

function BuildSpire1(team, time)
    if (not IsPathAvailable("yelena_spire_1")) then
        return false, "yelena_spire_1 is unavailable, or a building already exists on it..."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet...";
    end

    return true, "Tasking a Constructor to build a Gun Spire..."
end

function BuildSpire2(team, time)
    if (not IsPathAvailable("yelena_spire_2")) then
        return false, "yelena_spire_2 is unavailable, or a building already exists on it..."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet...";
    end

    return true, "Tasking a Constructor to build a Gun Spire..."
end

function BuildSpire3(team, time)
    if (not IsPathAvailable("yelena_spire_3")) then
        return false, "yelena_spire_3 is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    return true, "Tasking a Constructor to build a Gun Spire...";
end

function DoesConstructorExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", "sameteam", true) > 0
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", 'sameteam', true) > 0
end

function DoesFactoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FACTORY", "sameteam", true) > 0
end

function IsPathAvailable(pathName)
    if (not AIPUtil.PathExists(pathName)) then
        return false
    elseif (AIPUtil.PathBuildingExists(pathName)) then
        return false
    end

    return true
end