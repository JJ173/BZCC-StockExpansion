local _HelperFunctions = {};

function BuildObjectAtSafePath(handle, team, path, alternativePath, totalPlayers)
    -- Mark if the path is safe for spawn use.
    local isSafe = true;

    -- No player should see anything spawn.
    if (IsPlayerWithinDistance(path, 200, totalPlayers)) then
        isSafe = false;
    end

    -- If we're not safe, don't spawn on the first path.
    if (not isSafe) then
        return BuildObject(handle, team, GetPositionNear(alternativePath, 20, 20));
    else
        return BuildObject(handle, team, GetPositionNear(path, 20, 20));
    end
end

function AddObjectiveOverride(objective, colour, time, clearExisting)
    if (clearExisting) then
        ClearObjectives();
    end

    AddObjective(objective, colour, time);
end

function IsAliveAndEnemy(handle, enemyTeam)
    return (IsAlive(handle) and GetTeamNum(handle) == enemyTeam);
end

function IsPlayerWithinDistance(handleOrPath, distance, totalPlayers)
    for i = 1, totalPlayers do
        local p = GetPlayerHandle(i);

        if (IsAround(p) and GetDistance(p, handleOrPath) < distance) then
            return true;
        else
            return false;
        end
    end
end

return _HelperFunctions;