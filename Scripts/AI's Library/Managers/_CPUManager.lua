---@class CPUTeam
---@field Name string
---@field Team number
---@field Faction string
---@field Pools PoolClass[]
---@field AIPString string
---@field CommanderEnabled boolean
---@field Commander Handle | nil
---@field DispatchList DispatchClass[]

local _BZCCDatabase = require("_BZCCDatabase")
local _DispatchClass = require("_DispatchClass")

CPUManager = {
    ---@type CPUTeam[]
    CPUTeams = {}
}

---@param a PoolClass
---@param b PoolClass
---@return boolean
local function Compare(a, b)
    return a.DistanceFromCPURecycler < b.DistanceFromCPURecycler;
end

---@return table
function CPUManager.Save()
    return CPUManager
end

---@param CPUData table
function CPUManager.Load(CPUData)
    for k, v in pairs(CPUData) do
        PrintConsoleMessage("Loading CPUManager. Field: " .. k .. " Value: " .. v)
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
        DispatchList = {}
    }

    if (newTeam.CommanderEnabled) then
        newTeam.Commander = BuildObject(faction .. "vcmdr_s", team, GetPositionNear(spawnPath, 30, 60))
        SetObjectiveName(newTeam.Commander, newTeam.Name)
    end

    SetScrap(team, 40)
    DoTaunt(TAUNTS_GameStart)
end

---@param missionTurnCount integer
function CPUManager.Run(missionTurnCount)

end

---@param type integer
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

---@param handle Handle
---@param missionTurnCount integer
---@param teamNum integer
---@param aiCraftType string
function CPUManager.AddUnit(handle, missionTurnCount, teamNum, aiCraftType)
    if (AICraftType == nil) then
        return
    end
end

---@param handle Handle
function CPUManager.RemoveUnit(handle)

end

return CPUManager
