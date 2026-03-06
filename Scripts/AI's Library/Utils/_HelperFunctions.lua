local _HelperFunctions = {};

function AddObjectiveOverride(objective, colour, time, clearExisting, isCoop)
    if (clearExisting) then
        ClearObjectives();
    end

    if (isCoop) then
        AddToMessagesBox(TranslateString(objective), colour);
    else
        AddObjective(objective, colour, time);
    end
end

function BuildObjectAtSafePath(handle, team, path, alternativePath, totalPlayers)
    -- Mark if the path is safe for spawn use.
    local isSafe = true;

    -- No player should see anything spawn.
    if (IsPlayerWithinDistance(path, 250, totalPlayers)) then
        isSafe = false;
    end

    -- If we're not safe, don't spawn on the first path.
    if (isSafe == false) then
        return BuildObject(handle, team, GetPositionNear(alternativePath, 20, 20));
    else
        return BuildObject(handle, team, GetPositionNear(path, 20, 20));
    end
end

function FindInTable(table, value)
    for i, v in ipairs(table) do
        if (v == value) then
            return i;
        end
    end
end

function GetRandomInt(Min, Max)
    local retVal = GetRandomFloat(Min, Max + 1);

    if (retVal > Max) then
        return Max;
    end

    return math.floor(retVal);
end

function IsAliveAndEnemy(handle, enemyTeam)
    return (IsAlive(handle) and GetTeamNum(handle) == enemyTeam);
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

function ReplaceCharacter(pos, str, r)
    return table.concat { str:sub(1, pos - 1), r, str:sub(pos + 1) }
end

---@param table DispatchClass[] | AssaultClass[]
---@param obj DispatchClass | AssaultClass
---@return DispatchClass[] | AssaultClass[]
function SquelchDispatchTable(table, obj)
    if (not table or not obj) then
        return null
    end

    local newTable = {}

    for _, v in ipairs(table) do
        if (v.Handle ~= obj.Handle) then
            newTable[#newTable + 1] = v
        end
    end

    return newTable
end

---@return userdata[]
function TableRemoveByHandle(table, handle)
    local length = #table;

    if (table[length] == handle) then
        table[length] = nil;
        return
    end

    for i = 1, length - 1 do
        if (table[i] == handle) then
            table[i] = table[length]
            table[length] = nil
            return
        end
    end
end

function Teleport(h, dest, offset)
    if (not IsAround(h)) then
        return false;
    end

    BuildObject("teleportin", 0, GetPosition(h));

    local pos = nil;

    if (type(dest) == "string") then
        pos = BuildDirectionalMatrix(GetPosition(dest), nil);
    elseif (IsAround(dest)) then
        pos = GetTransform(dest);
    else
        return nil;
    end

    pos.posit = pos.posit + pos.front * offset;
    pos.posit.y = pos.posit.y + 5;

    BuildObject("teleportout", 0, pos);

    SetTransform(h, pos);
    SetVelocity(h, Length(GetVelocity(h)) * pos.front);

    if (h == GetPlayerHandle(1)) then
        SetColorFade(1.0, 1.0, 32767);
        StartSoundEffect("teleport.wav", nil);
    end

    return true;
end

function TeleportIn(odf, team, dest)
    local pos = GetPosition(dest);

    local randPos = GetPositionNear(pos, 3, 5)
    randPos.y = pos.y + 10;

    BuildObject("teleportin", 0, randPos);
    return BuildObject(odf, team, randPos);
end

function TeleportOut(h)
    BuildObject("teleportout", 0, BuildDirectionalMatrix(GetPosition(h)));
    RemoveObject(h);
end

return _HelperFunctions;
