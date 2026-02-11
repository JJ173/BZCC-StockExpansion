---@class CPUTeam
---@field Name string
---@field Team number
---@field Faction string
---@field AIPString string
---@field CommanderEnabled boolean
---@field Commander Handle | nil
---@field DispatchList DispatchClass[]
---@field TauntCooldown integer
---@field TauntSetupDone boolean

-- Database
local _BZCCDatabase = require("_BZCCDatabase")

-- Models
local _DispatchClass = require("_DispatchClass")

CPUManager = {
    ---@type CPUTeam[]
    CPUTeams = {},
    ---@type Handle[]
    Pools = {},
    ---@type Handle[]
    Scrap = {}
}

---@param team integer
---@return CPUTeam | nil
local function GetCPUTeam(team)
    for i = 1, #CPUManager.CPUTeams do
        local cpuTeam = CPUManager.CPUTeams[i]

        if (cpuTeam == nil or cpuTeam.Team ~= team) then
            PrintConsoleMessage("CPUTeam not found for team: " .. team)
            return nil
        end

        return cpuTeam
    end
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
---@param spawnPath string
function CPUManager.NewTeam(team, faction, spawnPath)
    ---@type CPUTeam
    local newTeam = {
        Name = _BZCCDatabase.CPUNames[GetRandomInt(1, #_BZCCDatabase.CPUNames)],
        Team = team,
        Faction = faction,
        Scrap = {},
        AIPString = IFace_GetString(_BZCCDatabase.ShellVariables.AIP_STRING),
        CommanderEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.COMMANDER_ENABLED) == 1,
        Commander = nil,
        DispatchList = {},
        TauntCooldown = 0,
        TauntSetupDone = false
    }

    CPUManager.CPUTeams[#CPUManager.CPUTeams + 1] = newTeam

    if (newTeam.CommanderEnabled) then
        newTeam.Commander = BuildObject(faction .. "vcmdr_s", team, GetPositionNear(spawnPath, 30, 60))
        SetObjectiveName(newTeam.Commander, "Cmd. " .. newTeam.Name)
    end

    SetScrap(team, 40)

    CPUManager.SetPlan(_BZCCDatabase.AIPTypes.AIPType0, newTeam)
    PrintConsoleMessage("Setting up CPUManager for team: " .. team)
end

---@param missionTurnCount integer
function CPUManager.Run(missionTurnCount)
    if (#CPUManager.CPUTeams <= 0) then
        return -- Abort. Nothing to do.
    end

    -- Process teams.
    for _, cpuTeam in pairs(CPUManager.CPUTeams) do
        if (not cpuTeam.TauntSetupDone) then
            if (missionTurnCount == 2) then
                SetTauntCPUTeamName(cpuTeam.Name)
            elseif (missionTurnCount == 3) then
                DoTaunt(_BZCCDatabase.TauntTypes.TAUNTS_GameStart)
                cpuTeam.TauntSetupDone = true
            end
        end

        if (cpuTeam.TauntCooldown < missionTurnCount) then
            DoTaunt(_BZCCDatabase.TauntTypes.TAUNTS_Random)
            cpuTeam.TauntCooldown = missionTurnCount + SecondsToTurns(90)
        end

        -- Start processing each dispatch unit if the cooldown for it has elapsed.
        for _, dispatchUnit in pairs(cpuTeam.DispatchList) do
            if (_DispatchClass.IsAvailable(dispatchUnit, missionTurnCount)) then
                -- Switch the type of unit and handle it appropriately.
                if (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.TURRET) then
                    CPUManager.HandleTurret(dispatchUnit)
                elseif (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.PATROL) then
                    CPUManager.HandlePatrol(dispatchUnit, "patrol_")
                elseif (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.BASE_PATROL) then
                    CPUManager.HandlePatrol(dispatchUnit, "BasePatrol")
                end
            end
        end
    end
end

---@param type integer
---@param cpuTeam CPUTeam
function CPUManager.SetPlan(type, cpuTeam)
    if (type < AIPType0 or type >= MAX_AIP_TYPE) then
        type = AIPType3
    end

    local AIPString

    if (cpuTeam.AIPString ~= nil) then
        AIPString = cpuTeam.AIPString;
    else
        AIPString = StockAIPNameBase;
    end

    local AIPFile = AIPString .. cpuTeam.Faction .. type
    SetAIP(AIPFile .. '.aip', cpuTeam.Team)
end

---@param scrapHandle Handle
function CPUManager.AddScrap(scrapHandle)
    CPUManager.Scrap[#CPUManager.Scrap + 1] = scrapHandle
end

---@param poolHandle Handle
function CPUManager.AddPool(poolHandle)
    CPUManager.Pools[#CPUManager.Pools + 1] = poolHandle
end

---@param handle Handle
---@param missionTurnCount integer
---@param teamNum integer
---@param aiCraftType string
function CPUManager.AddUnit(handle, missionTurnCount, teamNum, aiCraftType)
    -- Don't process any units that don't have an appropriate type.
    if (aiCraftType == nil or aiCraftType == _BZCCDatabase.AIUnitTypes.CARRIER) then
        return
    end

    PrintConsoleMessage("Registering call to CPUManager.AddUnit with values: " ..
        missionTurnCount .. ", " .. teamNum .. ", " .. aiCraftType)

    -- Check for a team.
    local cpuTeam = GetCPUTeam(teamNum)

    -- No team? Bail.
    if (cpuTeam == nil) then
        PrintConsoleMessage("Unable to find a CPUTeam object for team: " .. teamNum)
        return
    end

    -- For logging.
    PrintConsoleMessage("Adding new handle to CPU Team: " ..
        teamNum .. " at turn: " .. missionTurnCount .. " of type: " .. aiCraftType)

    -- Add the new dispatch object to the right CPU team.
    cpuTeam.DispatchList[#cpuTeam.DispatchList + 1] = _DispatchClass.New(handle, missionTurnCount, teamNum, aiCraftType)
end

---@param handle Handle
function CPUManager.RemoveUnit(handle)

end

---@param turretUnit DispatchClass
function CPUManager.HandleTurret(turretUnit)
    --[[
    Idea here is to process turrets and send them out into
    the world to start claiming key points or pools.

    Good inspiration here from BlackDragon's dispatcher.
    So credit to him for this idea.

    Resource guarding is a good strategy here, so start
    with a random chance of going to a pool or piece of scrap.
    ]]

    local dispatchMode = GetRandomInt(1, 2)
    local dispatchMethod = GetRandomInt(1, 3)

    --[[
        Choose a resource based on the dispatch method.
        1 = Closest
        2 = Random
        3 = Furthest.
    ]]

    if (dispatchMode == 1) then -- Start with pools.
        local tempDist = _BZCCDatabase.MAX_FLOAT
        -- Driving into the player base is stupid. Skip the last pool in the list.
        local maxPoolRange = #CPUManager.Pools - 1

        if (dispatchMethod == 1) then -- Closest.
            -- Check the pool range.
            for i = 1, maxPoolRange do
                -- Get the pool from the table of pools based on index.
                local pool = CPUManager.Pools[i]

                -- Check the distance of the pool and compare it to the tempDist to see which is closer.
                local dist = GetDistance(turretUnit.Handle, pool)

                -- Are we closer than the last position recorded?
                if (dist < tempDist) then
                    turretUnit.DispatchTarget = pool
                    tempDist = dist
                end
            end
        elseif (dispatchMethod == 2) then -- Random
            turretUnit.DispatchTarget = CPUManager.Pools[GetRandomInt(1, maxPoolRange)]
        elseif (dispatchMethod == 3) then -- Furthest.
            -- Check the pool range.
            for i = 1, maxPoolRange do
                -- Get the pool from the table of pools based on index.
                local pool = CPUManager.Pools[i]

                -- Check the distance of the pool and compare it to the tempDist to see which is closer.
                local dist = GetDistance(turretUnit.Handle, pool)

                -- Are we further away than the last position recorded?
                if (dist > tempDist) then
                    turretUnit.DispatchTarget = pool
                    tempDist = dist
                end
            end
        end
    elseif (dispatchMode == 2) then
        local tempDist = _BZCCDatabase.MAX_FLOAT

        if (dispatchMethod == 1) then
            for _, scrapPiece in pairs(CPUManager.Scrap) do
                -- Check the distance of the pool and compare it to the tempDist to see which is closer.
                local dist = GetDistance(turretUnit.Handle, scrapPiece)

                -- Are we closer than the last position recorded?
                if (dist < tempDist) then
                    turretUnit.DispatchTarget = scrapPiece
                    tempDist = dist
                end
            end
        elseif (dispatchMethod == 2) then
            turretUnit.DispatchTarget = CPUManager.Scrap[GetRandomInt(1, #CPUManager.Scrap)]
        elseif (dispatchMethod == 3) then
            for _, scrapPiece in pairs(CPUManager.Scrap) do
                -- Check the distance of the pool and compare it to the tempDist to see which is closer.
                local dist = GetDistance(turretUnit.Handle, scrapPiece)

                -- Are we closer than the last position recorded?
                if (dist > tempDist) then
                    turretUnit.DispatchTarget = scrapPiece
                    tempDist = dist
                end
            end
        end
    end

    -- Make sure we have a valid target before we progress, otherwise bail and try again.
    if (turretUnit.DispatchTarget == nil) then
        return
    end

    -- Generate a random position around the pool for the turret to sit.
    turretUnit.DispatchSpot = GetPositionNear(turretUnit.DispatchTarget, 15, 35)

    -- Pool found. Send the turret off to defend.
    Goto(turretUnit.Handle, turretUnit.DispatchSpot)
end

---@param patrolUnit DispatchClass
function CPUManager.HandlePatrol(patrolUnit, patrolPath)
    -- Grab a random path.
    local concatPath = patrolPath .. GetRandomInt(1, 2)

    -- Set the dispatch path of this unit for later checks.
    patrolUnit.DispatchPath = concatPath

    -- Send the Patrol unit out into the field.
    Patrol(patrolUnit.Handle, concatPath)
end

---@param minionUnit DispatchClass
function CPUManager.HandleMinion(minionUnit)

end

---@param commanderUnit DispatchClass
function CPUManager.HandleCommander(commanderUnit)

end

---@param antiAirUnit DispatchClass
function CPUManager.HandleAntiAir(antiAirUnit)

end

function CPUManager.HandleCarrier()

end

return CPUManager
