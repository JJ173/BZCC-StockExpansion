-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")),"_requirefix.lua"))();

-- Required Logic for Custom Skins.
require("_Skins");

local _Cooperative = 
{
    m_TotalPlayerCount = 1,
    m_TeamIsSetUp = { false, false, false, false, false }
};

function _Cooperative.AddPlayer(id, Team, IsNewPlayer, MissionShipODF, MissionPilotODF, SpawnPilotOnly, HeightOffset)
    if (IsNewPlayer) then
        -- Keep track of how many player are in the game.
        _Cooperative.m_TotalPlayerCount = _Cooperative.m_TotalPlayerCount + 1;

        -- Create the player for the server.
        local PlayerH = _Cooperative.SetupPlayer(Team, MissionShipODF, MissionPilotODF, SpawnPilotOnly, HeightOffset, id);

        -- Make sure we give the player control of their ship.
        SetAsUser(PlayerH, Team);

        -- Make sure the handle has a pilot so the player can hop out.
        AddPilotByHandle(PlayerH);
    end

    return true;
end

function _Cooperative.PlayerEjected(DeadObjectHandle)
    local deadObjectTeam = GetTeamNum(DeadObjectHandle);

    -- Invalid team. Do nothing
    if (deadObjectTeam == 0) then
		return DLLHandled;
	end

    if (IsPlayer(DeadObjectHandle)) then
		AddScore(DeadObjectHandle, -GetActualScrapCost(DeadObjectHandle));
	end

    -- Tell main code to allow the ejection
    return DoEjectPilot;
end

function _Cooperative.ObjectKilled(DeadObjectHandle, KillersHandle, MissionPilotODF)
	local isDeadAI = not IsPlayer(DeadObjectHandle);
	local isDeadPerson = IsPerson(DeadObjectHandle);

    -- Sanity check for multiworld
	if (GetCurWorld() ~= 0) then
		return DoEjectPilot;
	end

    -- Someone on neutral team always gets default behavior
    local deadObjectTeam = GetTeamNum(DeadObjectHandle);

	if (deadObjectTeam == 0) then
		return DoEjectPilot;
	end

    -- If a person died, respawn them, etc
    return _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI, MissionPilotODF);
end

function _Cooperative.ObjectSniped(DeadObjectHandle, KillersHandle, MissionPilotODF)
    local isDeadAI = not IsPlayer(DeadObjectHandle);

	-- Sanity check for multiworld
	if (GetCurWorld() ~= 0) then
		return DoEjectPilot;
	end

    -- Dead person means we must always respawn a new person
	return DeadObject(DeadObjectHandle, KillersHandle, true, isDeadAI, MissionPilotODF);
end

function _Cooperative.PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF)
    -- Never allow friendly fire otherwise we may screw with mission logic.
    local relationship = GetTeamRelationship(shooterHandle, victimHandle);

    if (relationship == TEAMRELATIONSHIP_ALLIEDTEAM) then
        -- Allow snipes of items on team 0/perceived team 0, as long as they're not a local/remote player
        if (IsPlayer(victimHandle) or (GetTeamNum(victimHandle) ~= 0)) then
            return PRESNIPE_ONLYBULLETHIT;
        end
    end

    -- Set its team to 0
    SetPerceivedTeam(victimHandle, 0);

    -- If we make it here, kill the pilot.
    return PRESNIPE_KILLPILOT;
end

function _Cooperative.PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
    local relationship = GetTeamRelationship(pilotHandle, emptyCraftHandle);

    if (relationship == TEAMRELATIONSHIP_ALLIEDTEAM and not IsPlayer(pilotHandle)) then
        SetTeamNum(pilotHandle, GetTeamNum(emptyCraftHandle));
    end

    -- Always allow the entry
	return PREGETIN_ALLOW;
end

function _Cooperative.RespawnPilot(DeadObjectHandle, Team, MissionPilotODF)
    local spawnpointPosition = SetVector(0, 0, 0);
    local RespawnDistanceAwayXZRange = 32.0;

    if (Team < 1 or Team >= MAX_TEAMS) then
        spawnpointPosition = GetSafestspawnpoint();
    else
        -- All players use "player_start" for missions.
        spawnpointPosition = GetPosition("player_start");
    end

    -- Respawn at a set altitude.
    local respawnHeight = 200.0;

    -- Randomize starting position somewhat. This gives a range of +/-
	spawnpointPosition.x = spawnpointPosition.x + (GetRandomFloat(1.0) - 0.5) * (2.0 * RespawnDistanceAwayXZRange);
	spawnpointPosition.z = spawnpointPosition.z + (GetRandomFloat(1.0) - 0.5) * (2.0 * RespawnDistanceAwayXZRange);

    -- Make sure we spawn above ground.
    local curFloor = TerrainFindFloor(spawnpointPosition.x, spawnpointPosition.z) + 2.5;

    -- For safety, if the y axis of the spawn point is underground, correct it to the current height of the floor.
    if (spawnpointPosition.y < curFloor) then
        spawnpointPosition.y = curFloor;
	end

     -- Bounce them in the air to prevent multi-kills
    spawnpointPosition.y = spawnpointPosition.y + respawnHeight;
	spawnpointPosition.y = spawnpointPosition.y + GetRandomFloat(1.0) * 8.0;

    -- Always spawn with pilot.
    local NewPilot = BuildObject(MissionPilotODF, Team, spawnpointPosition);

    -- Give control to the user.
    SetAsUser(NewPilot, Team);

    -- Add Pilot.
    AddPilotByHandle(NewPilot);

    -- Look somewhere.
    SetRandomHeadingAngle(NewPilot);

    -- If we're on Team 0, make inert.
    if (Team == 0) then
        MakeInert(NewPilot);
    end

    -- Return handled.
    return DLLHandled;
end

function _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI, MissionPilotODF)
    -- Get team number of the dead object
	local deadObjectTeam = GetTeamNum(DeadObjectHandle);

    -- Check if the object is a player.
    local deadObjectIsPlayer = IsPlayer(DeadObjectHandle);
	local killerObjectIsPlayer = IsPlayer(KillersHandle);

    -- Grab the relationship between the dead object and the killer.
    local relationship = GetTeamRelationship(DeadObjectHandle, KillersHandle);

    -- Get the scrap cost for score.
    local deadObjectScrapCost = GetActualScrapCost(DeadObjectHandle);

    -- Don't count stats for Team 0.
    if (deadObjectTeam == 0) then
        return DoEjectPilot;
    end

    if (deadObjectIsPlayer) then
        -- Score goes down by the scrap cost of unit that died
        AddScore(DeadObjectHandle, -deadObjectScrapCost);

        -- Scoring: One death for players if they die as a pilot.
        if (isDeadPerson) then
            AddDeaths(DeadObjectHandle, 1);
        end
    else
        -- Add deaths for AI.
        AddDeaths(DeadObjectHandle, 1);
        -- Add score for AI.
        AddScore(DeadObjectHandle, -deadObjectScrapCost);
    end

    -- If the killer was a human (directly, not via their AI units), then they get a kill and some score points.
    if (killerObjectIsPlayer) then
        if (relationship == TEAMRELATIONSHIP_SAMETEAM or relationship == TEAMRELATIONSHIP_ALLIEDTEAM) then
            -- Being a jerk to same or allied team loses a kill
            AddKills(KillersHandle, -1);
            -- And killer loses score
            AddScore(KillersHandle, -deadObjectScrapCost);
        else
            -- Killer gains score.
            AddKills(KillersHandle, 1);
            -- And, bump their score by the scrap cost of what they just killed
            AddScore(KillersHandle, deadObjectScrapCost);
        end
    else
        if (relationship == TEAMRELATIONSHIP_SAMETEAM or relationship == TEAMRELATIONSHIP_ALLIEDTEAM) then
            AddKills(KillersHandle, -1);
            AddScore(KillersHandle, -deadObjectScrapCost);
        else
            AddKills(KillersHandle, 1);
            AddScore(KillersHandle, deadObjectScrapCost);
        end
    end

    if (isDeadAI) then
        if (isDeadPerson) then
            return DLLHandled;
        else 
            return DoEjectPilot;
        end
    else
		if (isDeadPerson) then
			return RespawnPilot(DeadObjectHandle, deadObjectTeam, MissionPilotODF);
		else 
			return DoEjectPilot;
		end
    end
end

function _Cooperative.SetupPlayer(Team, MissionShipODF, MissionPilotODF, SpawnPilotOnly, HeightOffset, SteamID)
    -- Setup the team if it's not set up.
    if (IsTeamplayOn()) then
        local cmdTeam = GetCommanderTeam(Team);

        if (_Cooperative.m_TeamIsSetUp[cmdTeam] == false) then
            -- Get the team race of the commander team.
            local TeamRace = GetRaceOfTeam(cmdTeam);

            -- Set the team race of the entire team.
            SetMPTeamRace(WhichTeamGroup(cmdTeam), TeamRace);

            -- So we don't loop.
            _Cooperative.m_TeamIsSetUp[cmdTeam] = true;
        end
    end

    -- Put the player in ivtank, as that's what the original mission uses.
    local PlayerH = GetHandle("player_spawn_" .. _Cooperative.m_TotalPlayerCount);

    if (PlayerH == nil) then
        -- Handle spawning via a vector.
        local spawnPos = GetPositionNear("player_start", 25, 25);

        -- For safety so we don't spawn in the ground.
        if (HeightOffset == nil or HeightOffset == 0) then
            -- Make sure we spawn above ground.
            local curFloor = TerrainFindFloor(spawnPos.x, spawnPos.z) + 2.5;

            -- For safety, if the y axis of the spawn point is underground, correct it to the current height of the floor.
            if (spawnPos.y < curFloor) then
                spawnPos.y = curFloor;
            end
        else
            spawnPos.y = spawnPos.y + HeightOffset;
            spawnPos.y = spawnPos.y + GetRandomFloat(1.0) * 8.0;
        end

        if (SpawnPilotOnly) then
            PlayerH = BuildObject(MissionPilotODF, Team, spawnPos);
        else
            PlayerH = BuildObject(MissionShipODF, Team, spawnPos);
        end

        -- Look somewhere.
        SetRandomHeadingAngle(PlayerH);
    else
        SetTeamNum(PlayerH, Team);
    end

    -- Replace the unit with a skin for any contributor.
    if (SpawnPilotOnly == nil or SpawnPilotOnly == false) then
        -- Replace the stock unit with the player skin.
        PlayerH = ApplySkinToHandle(SteamID, PlayerH);
    end

    -- Give them a pilot class.
    SetPilotClass(PlayerH, MissionPilotODF);

    -- Make sure the handle has a pilot so the player can hop out.
    AddPilotByHandle(PlayerH);

    -- Return object to caller.
    return PlayerH;
end

return _Cooperative;