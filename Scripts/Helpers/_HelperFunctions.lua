local _HelperFunctions = {};

function BuildObjectAtSafePath(handle, team, path, alternativePath, totalPlayers)
    -- Mark if the path is safe for spawn use.
    local isSafe = true;

    -- No player should see anything spawn.
    if (IsPlayerWithinDistance(path, 250, totalPlayers)) then
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

        if (IsAlive(p) and GetDistance(p, handleOrPath) < distance) then
            return true;
        end
    end

    return false;
end

function IsPlayerInBuilding(totalPlayers)
    for i = 1, totalPlayers do
        local p = GetPlayerHandle(i);

        if (InBuilding(p)) then
            return true;
        else
            return false;
        end
    end
end

-- Credit to Rhade for this.
function TableRemoveByHandle(table, handle)
	local length = #table;

    -- Return early if the last handle is what we need to remove.
	if (table[length] == handle) then
		table[length] = nil;
		return
	end

	-- Check the rest of the table.
	for i = 1, length - 1 do
		if (table[i] == handle) then
			table[i] = table[length];
			table[length] = nil;
			return;
		end
	end
end

function IsAudioMessageFinished(audioClip, audioDelayTime, missionTime, isCoop)
    if (audioClip == nil) then
        return true;
    end

    if (isCoop) then
        return audioDelayTime < missionTime;
    else
        return IsAudioMessageDone(audioClip);
    end
end

function ReplaceCharacter(pos, str, r)
    return table.concat{str:sub(1,pos-1), r, str:sub(pos+1)}
end

return _HelperFunctions;