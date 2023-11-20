function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

function RebuildFirstPowerCondition(team, time)
    local power1exists = AIPUtil.PathExists("power_1");
    local powerCount = AIPUtil.CountUnits(team, "ibpgen_x", 'sameteam', true);
    local hasCons = AIPUtil.CountUnits(team, "ivcons_x", 'sameteam', true) >= 1;

    if (power1exists and powerCount < 1 and hasCons) then
        return true, "Rebuild the first power generator...";
    else
        return false, "Already have the power generators."
    end
end

function RebuildSecondPowerCondition(team, time)
    local power2exists = AIPUtil.PathExists("power_2");
    local powerCount = AIPUtil.CountUnits(team, "ibpgen_x", 'sameteam', true);
    local hasCons = AIPUtil.CountUnits(team, "ivcons_x", 'sameteam', true) >= 1;

    if (power2exists and powerCount < 2 and hasCons) then
        return true, "Rebuild the second power generator...";
    else
        return false, "Already have the power generators."
    end
end

function AttackArtilleryCondition(team, time)
    local powerCount = AIPUtil.CountUnits(team, "ibpgen_x", 'sameteam', true);
    local hasCons = AIPUtil.CountUnits(team, "ivcons_x", 'sameteam', true) >= 1;
    local enemyHasArty = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_ARTILLERY", 'enemy', true);

    if (powerCount >= 1 and enemyHasArty >= 1 and hasCons) then
        return true, "I can attack the enemy artillery";
    else
        return false, "I can't attack the enemy artillery";
    end
end

function AttackVehiclesCondition(team, time)
    local powerCount = AIPUtil.CountUnits(team, "ibpgen_x", 'sameteam', true);
    local hasCons = AIPUtil.CountUnits(team, "ivcons_x", 'sameteam', true) >= 1;
    local enemyHasDefendUnit = AIPUtil.CountUnits(team, "DefendUnit", 'enemy', true);

    if (powerCount >= 1 and enemyHasDefendUnit >= 1 and hasCons) then
        return true, "I can attack the enemy defendunits";
    else
        return false, "I can't attack the enemy defendunits";
    end
end

function AttackGunTowersCondition(team, time)
    local powerCount = AIPUtil.CountUnits(team, "ibpgen_x", 'sameteam', true);
    local hasCons = AIPUtil.CountUnits(team, "ivcons_x", 'sameteam', true) >= 1;
    local enemyHasGunTower = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true);

    if (powerCount >= 1 and enemyHasGunTower >= 1 and hasCons) then
        return true, "I can attack the enemy gun towers";
    else
        return false, "I can't attack the enemy gun towers";
    end
end