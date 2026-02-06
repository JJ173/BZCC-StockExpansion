---@class CPUTeam
---@field Name string
---@field Team number
---@field Faction string
---@field Pools PoolClass[]
---@field AIPString string
---@field CommanderEnabled boolean
---@field Commander Handle | nil
---@field Carrier Handle | nil
---@field LandingPad Handle | nil
---@field DispatchList DispatchClass[]

local _BZCCDatabase = require("_BZCCDatabase")
local _DispatchClass = require("_DispatchClass")

CPUManager = {
    CPUTeams = {}
}

function CPUManager.Save()
    return CPUManager
end

function CPUManager.Load(CPUTeamData)
    for k, v in pairs(CPUTeamData) do
        CPUManager[k] = v
    end
end

---Creates a new CPU Team object.
---@param team number
---@param faction string
---@param pools PoolClass[]
---@param spawnPath string
function CPUManager.NewTeam(team, faction, pools, spawnPath)
    -- Fill in the distance of the pools from the Recycler spawn point.
    for i = 1, #pools do
        local pool = pool[i]
        pool.DistanceFromCPURecycler = GetDistance(pool, spawnPath)
    end

    -- Sort pools that are given by distance of Recycler.
    table.sort(pools, Compare)

    ---@type CPUTeam
    local newTeam = {
        Name = _BZCCDatabase.CPUNames[GetRandomInt(1, #_BZCCDatabase.CPUNames)],
        Team = team,
        Faction = faction,
        Pools = pools,
        AIPString = IFace_GetString(_BZCCDatabase.ShellVariables.AIP_STRING),
        CommanderEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.COMMANDER_ENABLED) == 1,
        Commander = nil,
        Carrier = nil,
        LandingPad = nil,
        DispatchList = {}
    }

    if (newTeam.CommanderEnabled) then
        newTeam.Commander = BuildObject(faction .. "vcmdr_s", team, GetPositionNear(spawnPath, 30, 60))
        SetObjectiveName(newTeam.Commander, newTeam.Name)
    end

    SetScrap(team, 40)
    DoTaunt(TAUNTS_GameStart)
end

---comment
---@param missionTurnCount any
function CPUManager.Run(missionTurnCount)

end

function CPUManager.SetPlan(type)
    if (type < AIPType0 or type >= MAX_AIP_TYPE) then
        type = AIPType3
    end

    local AIPString

    if (self.AIPString ~= nil) then
        AIPString = self.AIPString;
    else
        AIPString = StockAIPNameBase;
    end

    local AIPFile = AIPString .. self.Race .. type

    SetAIP(AIPFile .. '.aip', self.Team)
    DoTaunt(TAUNTS_Random)
end


function CPUManager.AddObject(handle, missionTurnCount)

end

function CPUManager.DeleteObject(handle)

end

---comment
---@param a PoolClass
---@param b PoolClass
---@return boolean
function Compare(a, b)
    return a.DistanceFromCPURecycler < b.DistanceFromCPURecycler;
end

return CPUManager