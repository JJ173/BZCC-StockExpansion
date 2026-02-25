local _BZCCDatabase = require("_BZCCDatabase")
local _Multiplayer = require("_Multiplayer")

local _WorldManager = require("_WorldManager")
local _VoiceManager = require("_VoiceManager")

_Cooperative =
{
    m_TotalPlayerCount = 0,
    m_TeamIsSetUp      = { false, false, false, false },
}

local m_DifficultyMap = {
    'Easy',
    'Medium',
    'Hard'
}

local m_BaneMissions = {
    _BZCCDatabase.Missions.ISDF10,
    _BZCCDatabase.Missions.ISDF11,
    _BZCCDatabase.Missions.ISDF12,
    _BZCCDatabase.Missions.SCION05,
    _BZCCDatabase.Missions.SCION06
}

function _Cooperative.Load(CoopData, WorldManagerData)
    for k, v in pairs(CoopData) do
        PrintConsoleMessage("Loading CoopData. Field: " .. k .. " Value: " .. v)
        _Cooperative[k] = v
    end

    _WorldManager.Load(WorldManagerData)
end

function _Cooperative.Save()
    return _Cooperative, _WorldManager.Save()
end

function _Cooperative.Start(MissionName, PlayerShipODF, PlayerPilotODF, IsCoop, SpawnPilotOnly, HeightOffset)
    local difficulty

    if (IsCoop) then
        difficulty = GetVarItemInt("network.session.ivar102") + 1
    else
        difficulty = IFace_GetInteger("options.play.difficulty") + 1
    end

    AddToMessagesBox("[WELCOME]")
    AddToMessagesBox("Mission: " .. MissionName)
    AddToMessagesBox("Author: AI_Unit")

    if (IsCoop) then
        AddToMessagesBox("Cooperative: Yes")
    else
        AddToMessagesBox("Cooperative: No")
    end

    AddToMessagesBox("Difficulty: " .. m_DifficultyMap[difficulty])
    AddToMessagesBox("Good luck and have fun :)")

    ClearTeamColors()
    SetTeamNameForStat(0, "Neutral")

    local PlayerEntryH = GetPlayerHandle(1)

    if (PlayerEntryH ~= nil) then
        RemoveObject(PlayerEntryH)
    end

    local LocalTeamNum = GetLocalPlayerTeamNumber()
    local PlayerH = _Cooperative.SetupPlayer(LocalTeamNum, PlayerShipODF, PlayerPilotODF, SpawnPilotOnly, HeightOffset)
    SetAsUser(PlayerH, LocalTeamNum)

    local isBaneMission = false

    for i = 1, #m_BaneMissions do
        isBaneMission = MissionName == m_BaneMissions[i]

        if (isBaneMission) then
            break
        end
    end

    _WorldManager.Setup(isBaneMission, _Cooperative.m_TotalPlayerCount)
end

function _Cooperative.Update(m_GameTPS)
    _WorldManager.Run()
    _Multiplayer.UpdateGameTime(m_GameTPS)
end

function _Cooperative.AddPlayer(id, Team, IsNewPlayer, MissionShipODF, MissionPilotODF, SpawnPilotOnly, HeightOffset)
    if (IsNewPlayer) then
        local PlayerH = _Cooperative.SetupPlayer(Team, MissionShipODF, MissionPilotODF, SpawnPilotOnly, HeightOffset)
        SetAsUser(PlayerH, Team)
        AddPilotByHandle(PlayerH)
    end

    return true
end

function _Cooperative.DeletePlayer(id)
    _Cooperative.m_TotalPlayerCount = _Cooperative.m_TotalPlayerCount - 1
    _WorldManager.UpdatePlayerTotal(_Cooperative.m_TotalPlayerCount)
    return true
end

function _Cooperative.PlayerEjected(DeadObjectHandle)
    local deadObjectTeam = GetTeamNum(DeadObjectHandle)

    if (deadObjectTeam == 0) then
        return _BZCCDatabase.EventReturnCodes.DLLHandled
    end

    if (IsPlayer(DeadObjectHandle)) then
        AddScore(DeadObjectHandle, -GetActualScrapCost(DeadObjectHandle))
    end

    return _BZCCDatabase.EventReturnCodes.DoEjectPilot
end

function _Cooperative.ObjectKilled(DeadObjectHandle, KillersHandle, MissionPilotODF)
    if (GetCurWorld() ~= 0) then
        return _BZCCDatabase.EventReturnCodes.DoEjectPilot
    end

    local isDeadAI = not IsPlayer(DeadObjectHandle)
    local isDeadPerson = IsPerson(DeadObjectHandle)

    -- Someone on neutral team always gets default behavior
    local deadObjectTeam = GetTeamNum(DeadObjectHandle)

    if (deadObjectTeam == 0) then
        print("Returning DoEjectPilot: ", _BZCCDatabase.EventReturnCodes.DoEjectPilot)
        return _BZCCDatabase.EventReturnCodes.DoEjectPilot
    end

    return _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI, MissionPilotODF)
end

function _Cooperative.ObjectSniped(DeadObjectHandle, KillersHandle, MissionPilotODF)
    -- Sanity check for multiworld
    if (GetCurWorld() ~= 0) then
        return _BZCCDatabase.EventReturnCodes.DoEjectPilot
    end

    local isDeadAI = not IsPlayer(DeadObjectHandle)

    return _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, true, isDeadAI, MissionPilotODF)
end

function _Cooperative.PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF)
    if (curWorld ~= 0) then
        return
    end

    local relationship = GetTeamRelationship(shooterHandle, victimHandle)

    if (relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_ALLIEDTEAM) then
        if (IsPlayer(victimHandle) or (GetTeamNum(victimHandle) ~= 0)) then
            return _BZCCDatabase.EventReturnCodes.PRESNIPE_ONLYBULLETHIT
        end
    end

    SetPerceivedTeam(victimHandle, 0)

    return _BZCCDatabase.EventReturnCodes.PRESNIPE_KILLPILOT
end

function _Cooperative.PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
    if (curWorld ~= 0) then
        return
    end

    _VoiceManager.SwitchVehicleVoices(emptyCraftHandle, pilotHandle)

    return _BZCCDatabase.EventReturnCodes.PREGETIN_ALLOW
end

function _Cooperative.RespawnPilot(DeadObjectHandle, Team, MissionPilotODF)
    local spawnpointPosition = SetVector(0, 0, 0)
    local RespawnDistanceAwayXZRange = 32.0

    if (Team < 1 or Team >= MAX_TEAMS) then
        spawnpointPosition = GetSafestspawnpoint()
    else
        spawnpointPosition = GetPosition("player_start")
    end

    local respawnHeight = 200.0
    spawnpointPosition.x = spawnpointPosition.x + (GetRandomFloat(1.0) - 0.5) * (2.0 * RespawnDistanceAwayXZRange)
    spawnpointPosition.z = spawnpointPosition.z + (GetRandomFloat(1.0) - 0.5) * (2.0 * RespawnDistanceAwayXZRange)

    local curFloor = TerrainFindFloor(spawnpointPosition.x, spawnpointPosition.z) + 2.5

    if (spawnpointPosition.y < curFloor) then
        spawnpointPosition.y = curFloor
    end

    spawnpointPosition.y = spawnpointPosition.y + respawnHeight
    spawnpointPosition.y = spawnpointPosition.y + GetRandomFloat(1.0) * 8.0

    local NewPilot = BuildObject(MissionPilotODF, Team, spawnpointPosition)
    SetAsUser(NewPilot, Team)
    AddPilotByHandle(NewPilot)
    SetRandomHeadingAngle(NewPilot)

    if (Team == 0) then
        MakeInert(NewPilot)
    end

    return _BZCCDatabase.EventReturnCodes.DLLHandled
end

function _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI, MissionPilotODF)
    local deadObjectTeam = GetTeamNum(DeadObjectHandle)
    local deadObjectIsPlayer = IsPlayer(DeadObjectHandle)
    local killerObjectIsPlayer = IsPlayer(KillersHandle)
    local relationship = GetTeamRelationship(DeadObjectHandle, KillersHandle)
    local deadObjectScrapCost = GetActualScrapCost(DeadObjectHandle)

    if (deadObjectTeam == 0) then
        return _BZCCDatabase.EventReturnCodes.DoEjectPilot
    end

    if (deadObjectIsPlayer) then
        AddScore(DeadObjectHandle, -deadObjectScrapCost)

        if (isDeadPerson) then
            AddDeaths(DeadObjectHandle, 1)
        end
    else
        AddDeaths(DeadObjectHandle, 1)
        AddScore(DeadObjectHandle, -deadObjectScrapCost)
    end

    if (killerObjectIsPlayer) then
        if (relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_SAMETEAM or relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_ALLIEDTEAM) then
            AddKills(KillersHandle, -1)
            AddScore(KillersHandle, -deadObjectScrapCost)
        else
            AddKills(KillersHandle, 1)
            AddScore(KillersHandle, deadObjectScrapCost)
        end
    else
        if (relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_SAMETEAM or relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_ALLIEDTEAM) then
            AddKills(KillersHandle, -1)
            AddScore(KillersHandle, -deadObjectScrapCost)
        else
            AddKills(KillersHandle, 1)
            AddScore(KillersHandle, deadObjectScrapCost)
        end
    end

    if (isDeadAI) then
        if (isDeadPerson) then
            return _BZCCDatabase.EventReturnCodes.DLLHandled
        else
            return _BZCCDatabase.EventReturnCodes.DoEjectPilot
        end
    else
        if (isDeadPerson) then
            return _Cooperative.RespawnPilot(DeadObjectHandle, deadObjectTeam, MissionPilotODF)
        else
            return _BZCCDatabase.EventReturnCodes.DoEjectPilot
        end
    end
end

function _Cooperative.SetupPlayer(Team, MissionShipODF, MissionPilotODF, SpawnPilotOnly, HeightOffset)
    _Cooperative.m_TotalPlayerCount = _Cooperative.m_TotalPlayerCount + 1

    _WorldManager.UpdatePlayerTotal(_Cooperative.m_TotalPlayerCount)

    if (IsTeamplayOn()) then
        local cmdTeam = GetCommanderTeam(Team)

        if (_Cooperative.m_TeamIsSetUp[cmdTeam] == false) then
            local TeamRace = GetRaceOfTeam(cmdTeam)

            SetMPTeamRace(WhichTeamGroup(cmdTeam), TeamRace)

            _Cooperative.m_TeamIsSetUp[cmdTeam] = true
        end
    end

    local PlayerH = GetHandle("player_spawn_" .. _Cooperative.m_TotalPlayerCount)

    if (PlayerH == nil) then
        local spawnPos = GetPositionNear("player_start", 25, 25)

        if (HeightOffset == nil or HeightOffset == 0) then
            local curFloor = TerrainFindFloor(spawnPos.x, spawnPos.z) + 2.5

            if (spawnPos.y < curFloor) then
                spawnPos.y = curFloor
            end
        else
            spawnPos.y = spawnPos.y + HeightOffset
            spawnPos.y = spawnPos.y + GetRandomFloat(1.0) * 8.0
        end

        if (SpawnPilotOnly) then
            PlayerH = BuildObject(MissionPilotODF, Team, spawnPos)
        else
            PlayerH = BuildObject(MissionShipODF, Team, spawnPos)
        end
    end

    SetPilotClass(PlayerH, MissionPilotODF)
    AddPilotByHandle(PlayerH)

    _Cooperative.m_TeamIsSetUp[Team] = true

    return PlayerH
end

function _Cooperative.CleanSpawns()
    for i = 1, 4 do
        if (i > _Cooperative.m_TotalPlayerCount) then
            local spawn_handle = GetHandle("player_spawn_" .. i)
            RemoveObject(spawn_handle)
        end
    end
end

function _Cooperative.GetTotalPlayers()
    return _Cooperative.m_TotalPlayerCount
end

return _Cooperative
