local _BZCCDatabase = require("_BZCCDatabase")

local _AssaultClass = require("_AssaultClass")
local _DispatchClass = require("_DispatchClass")
local _SaveLoad = require("_SaveLoad")
local _WorldManager = require("_WorldManager")
local _DLLUtils = require("_DLLUtils")

---@class CPUTeam
---@field Name string
---@field Team number
---@field Faction string
---@field AIPString string | nil
---@field CommanderEnabled boolean
---@field AssaultUnits AssaultClass[]
---@field DispatchList DispatchClass[]
---@field TauntCooldown integer
---@field TauntSetupDone boolean
---@field isCampaign boolean
---@field spawnPath string
---@field Commander? Handle
---@field Recycler? Handle
---@field Factory? Handle
---@field Armory? Handle
---@field ServiceBay? Handle
---@field GunTowers Handle[]
---@field Lieutenants Handle[]
---@field LieutenantNames string[]

CPUManager = {
    ---@type CPUTeam[]
    CPUTeams = {},
    ---@type Handle[]
    Pools = {},
    ---@type Handle[]
    Scrap = {}
}

-- Register Save/Load for saveload system
_SaveLoad.RegisterSave("_CPUManager", function()
    return CPUManager
end)

_SaveLoad.RegisterLoad("_CPUManager", function(CPUManagerData)
    if (CPUManagerData ~= nil) then
        for k, v in pairs(CPUManagerData) do
            CPUManager[k] = v
        end
    else
        print("WARNING: _CPUManager Load called with nil data")
    end
end)

local TurretDispatchMode = {
    POOL = 1,
    SCRAP = 2
}

local TurretDispatchMethod = {
    CLOSEST = 1,
    RANDOM = 2,
    FURTHEST = 3
}

local MAX_ASSAULT_DEFENDER_COUNT = 1
local MAX_ASSAULT_SERVICE_COUNT = 2

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

---@param cpuTeam CPUTeam
---@param handle Handle
---@return DispatchClass?
local function GetDistpachUnit(cpuTeam, handle)
    for _, dispatch in pairs(cpuTeam.DispatchList) do
        if (dispatch.Handle == handle) then
            return dispatch
        end
    end

    return nil
end

---@param cpuTeam CPUTeam
---@param handle Handle
---@return AssaultClass?
local function GetAssaultUnit(cpuTeam, handle)
    for _, assault in pairs(cpuTeam.AssaultUnits) do
        if (assault.Handle == handle) then
            return assault
        end
    end

    return nil
end

---@param cpuTeam CPUTeam
---@return AssaultClass
local function GetRandomAssaultUnit(cpuTeam)
    return cpuTeam.AssaultUnits[GetRandomInt(1, #cpuTeam.AssaultUnits)]
end

---@param type integer
---@param cpuTeam CPUTeam
local function SetCPUPlan(type, cpuTeam)
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

---@param dispatch DispatchClass
---@param spawnPath string
local function ReturnUnitToBaseIfTooFar(dispatch, spawnPath)
    -- Start by checking our position on the map. If we are idle and too far away from the base,
    -- we should move back towards it to defend.
    local tooFar = GetDistance(dispatch.Handle, spawnPath) > 450

    if (not tooFar) then
        return
    end

    -- Find a position hear the base to return to. We want to stay on the edges of the base to be more likely to intercept incoming player units.
    local returnPosition = GetPositionNear(spawnPath, 50, 75)
    Goto(dispatch.Handle, returnPosition, 0)
end

---@param cpuTeam CPUTeam
---@param turretUnit DispatchClass
local function HandleTurret(cpuTeam, turretUnit)
    --[[
    Idea here is to process turrets and send them out into
    the world to start claiming key points or pools.

    Good inspiration here from BlackDragon's dispatcher.
    So credit to him for this idea.

    Resource guarding is a good strategy here, so start
    with a random chance of going to a pool or piece of scrap.
    ]]

    local dispatchMode = GetRandomInt(TurretDispatchMode.POOL, TurretDispatchMode.SCRAP)
    local dispatchMethod = GetRandomInt(TurretDispatchMethod.CLOSEST, TurretDispatchMethod.FURTHEST)

    --[[
        Choose a resource based on the dispatch method.
        1 = Closest
        2 = Random
        3 = Furthest.
    ]]

    if (dispatchMode == TurretDispatchMode.POOL) then -- Start with pools.
        -- Driving into the player base is stupid. Skip the last pool in the list.
        local maxPoolRange = #CPUManager.Pools - 1

        if (dispatchMethod == TurretDispatchMethod.CLOSEST) then
            local tempDist = _BZCCDatabase.MAX_FLOAT

            -- Check the pool range.
            for i = 1, maxPoolRange do
                -- Get the pool from the table of pools based on index.
                local poolPos = GetPosition(CPUManager.Pools[i])

                -- Check the distance of the pool and compare it to the tempDist to see which is closer.
                local dist = GetDistance(turretUnit.Handle, poolPos)

                -- Are we closer than the last position recorded?
                if (dist < tempDist) then
                    turretUnit.DispatchSpot = GetPositionNear(poolPos, 15, 35)
                    tempDist = dist
                end
            end
        elseif (dispatchMethod == TurretDispatchMethod.RANDOM) then
            local chosenPool = CPUManager.Pools[GetRandomInt(1, maxPoolRange)]
            turretUnit.DispatchSpot = GetPositionNear(GetPosition(chosenPool), 15, 35)
        elseif (dispatchMethod == TurretDispatchMethod.FURTHEST) then
            local tempDist = 0

            -- Check the pool range.
            for i = 1, maxPoolRange do
                -- Get the pool from the table of pools based on index.
                local poolPos = GetPosition(CPUManager.Pools[i])

                -- Check the distance of the pool and compare it to the tempDist to see which is closer.
                local dist = GetDistance(turretUnit.Handle, poolPos)

                -- Are we further away than the last position recorded?
                if (dist > tempDist) then
                    turretUnit.DispatchSpot = GetPositionNear(poolPos, 15, 35)
                    tempDist = dist
                end
            end
        end
    elseif (dispatchMode == TurretDispatchMode.SCRAP) then
        if (dispatchMethod == TurretDispatchMethod.CLOSEST) then
            local tempDist = _BZCCDatabase.MAX_FLOAT

            for _, scrapPiece in pairs(CPUManager.Scrap) do
                -- Check the distance of the scrap piece and compare it to the tempDist to see which is closer.
                local dist = GetDistance(turretUnit.Handle, scrapPiece)

                -- Are we closer than the last position recorded?
                if (dist < tempDist) then
                    turretUnit.DispatchSpot = GetPositionNear(scrapPiece, 15, 35)
                    tempDist = dist
                end
            end
        elseif (dispatchMethod == TurretDispatchMethod.RANDOM) then
            turretUnit.DispatchSpot = GetPositionNear(CPUManager.Scrap[GetRandomInt(1, #CPUManager.Scrap)], 15, 35)
        elseif (dispatchMethod == TurretDispatchMethod.FURTHEST) then
            local tempDist = 0

            for _, scrapPiece in pairs(CPUManager.Scrap) do
                -- Check the distance of the scrap piece and compare it to the tempDist to see which is further.
                local dist = GetDistance(turretUnit.Handle, scrapPiece)

                -- Are we further away than the last position recorded?
                if (dist > tempDist) then
                    turretUnit.DispatchSpot = GetPositionNear(scrapPiece, 15, 35)
                    tempDist = dist
                end
            end
        end
    end

    PrintConsoleMessage("Dispatching turret unit: "
        .. tostring(turretUnit.Handle)
        .. " to target: " .. tostring(turretUnit.DispatchTarget)
        .. " at spot: " .. tostring(turretUnit.DispatchSpot)
        .. " using mode: " .. dispatchMode
        .. " and method: " .. dispatchMethod)

    -- Pool found. Send the turret off to defend.
    Goto(turretUnit.Handle, turretUnit.DispatchSpot, 1)
end

---@param cpuTeam CPUTeam
---@param patrolUnit DispatchClass
---@param patrolPath string
local function HandlePatrol(cpuTeam, patrolUnit, patrolPath)
    -- Grab a random path.
    local concatPath = patrolPath .. GetRandomInt(1, 2)

    -- Send the Patrol unit out into the field.
    Patrol(patrolUnit.Handle, concatPath, 0)
end

---@param cpuTeam CPUTeam
---@param apcUnit DispatchClass
---@param missionTurnCount integer
local function HandleAPCPatrol(cpuTeam, apcUnit, missionTurnCount)
    -- Before moving, we need to make sure we're clear of enemies within a certain radius.
    local nearestEnemy = GetNearestEnemy(apcUnit.Handle, true, false, 200)

    if (IsAlive(nearestEnemy)) then
        Attack(apcUnit.Handle, nearestEnemy)
        return
    end

    -- APCs will conduct a "slow patrol" where they move to a point, wait a bit, then move to another point, etc.
    -- This is to keep them active and moving around the map to be more likely to engage with the player.
    -- Each APC will move after 60 seconds (or so) to a new random location on the map.
    local patrolPoint = _WorldManager.GetRandomPathNearMapCenter()

    -- Set the dispatch path of this unit for later checks.
    apcUnit.DispatchSpot = patrolPoint

    -- Send the APC unit out into the field.
    Goto(apcUnit.Handle, patrolPoint, 0)

    -- Note: We could add some randomization to the patrol point change timer if desired, to make it less predictable.
    apcUnit.DispatchDelay = missionTurnCount + SecondsToTurns(GetRandomInt(30, 90))
end

---@param cpuTeam CPUTeam
---@param defenderUnit DispatchClass
---@param spawnPath string
local function HandleAssaultDefender(cpuTeam, defenderUnit, spawnPath)
    -- Sanity check first, is our unit too far out?
    ReturnUnitToBaseIfTooFar(defenderUnit, spawnPath)

    -- If the chosen defender has little health or ammo, move them to a pod or Service Bay for repairs, then send them out later.
    if (IsAround(cpuTeam.ServiceBay) and (GetHealth(defenderUnit.Handle) < 0.4 or GetAmmo(defenderUnit.Handle) < 0.3)) then
        Service(defenderUnit.Handle, cpuTeam.ServiceBay, 0)
        return
    end

    if (#cpuTeam.AssaultUnits > 0) then
        -- Choose a unit from the assault table to guard. We want to pick a unit that is still alive and idle.
        local randomAssaultUnit = GetRandomAssaultUnit(cpuTeam)

        -- Bail if we don't have any assault units to guard.
        if (randomAssaultUnit == nil or randomAssaultUnit.DefenderCount >= MAX_ASSAULT_DEFENDER_COUNT) then
            return
        end

        -- If we have a valid random assault unit, set it as the defender's target.
        defenderUnit.AssaultTarget = randomAssaultUnit

        -- Go defend the assault unit.
        Defend2(defenderUnit.Handle, randomAssaultUnit.Handle, 0)

        -- Keep track of the defender count.
        randomAssaultUnit.DefenderCount = randomAssaultUnit.DefenderCount + 1

        -- Stop any other logic from running.
        return
    end

    -- If there are no Assault Units to defend, don't sit idle. Keep an eye out for targets near the base and engage.
    local targetToDefend = defenderUnit.Handle

    if (cpuTeam.Recycler ~= nil and IsAround(cpuTeam.Recycler)) then
        targetToDefend = cpuTeam.Recycler
    elseif (cpuTeam.Factory ~= nil and IsAround(cpuTeam.Factory)) then
        targetToDefend = cpuTeam.Factory
    elseif (cpuTeam.Armory ~= nil and IsAround(cpuTeam.Armory)) then
        targetToDefend = cpuTeam.Armory
    end

    -- Find a valid target.
    local nearestTarget = GetNearestEnemy(targetToDefend, true, false, 200)

    -- Target found? Cool, engage.
    if (IsAlive(nearestTarget)) then
        Attack(defenderUnit.Handle, nearestTarget, 0)
    end
end

---@param cpuTeam CPUTeam
---@param servicerUnit DispatchClass
---@param spawnPath string
local function HandleAssaultServicer(cpuTeam, servicerUnit, spawnPath)
    -- Sanity check first, is our unit too far out?
    ReturnUnitToBaseIfTooFar(servicerUnit, spawnPath)

    if (#cpuTeam.AssaultUnits > 0) then
        -- Choose a unit from the assault table to guard. We want to pick a unit that is still alive and idle.
        local randomAssaultUnit = GetRandomAssaultUnit(cpuTeam)

        -- Bail if we don't have any assault units to guard.
        if (randomAssaultUnit == nil or randomAssaultUnit.ServiceTruckCount >= MAX_ASSAULT_SERVICE_COUNT) then
            return
        end

        -- If we have a valid random assault unit, set it as the defender's target.
        servicerUnit.AssaultTarget = randomAssaultUnit

        -- Go defend the assault unit.
        Follow(servicerUnit.Handle, randomAssaultUnit.Handle, 0)

        -- Keep track of the servicer count.
        randomAssaultUnit.ServiceTruckCount = randomAssaultUnit.ServiceTruckCount + 1

        -- Stop any other logic from running.
        return
    end

    -- If we're not in the field, we should consider keeping the base defenses repaired.
    -- Loop through all known Gun Towers and start healing them if they are damaged.
    for _, tower in pairs(cpuTeam.GunTowers) do
        -- Make sure the Tower in question is within a reasonable distance so we don't abandon duties to Assault Units.
        local dist = GetDistance(servicerUnit.Handle, tower)

        if (dist < 300) then
            -- Monitor the health of the Tower. Perhaps if it has a target, or is < a certain % of health, we should tend to it.
            -- Health first, as that's the most important part.
            local health = GetHealth(tower)

            if (health < 0.7) then
                -- Send me to Service the Tower.
                Service(servicerUnit.Handle, tower, 0)

                -- Bail, we're now occupied.
                return
            end
        end
    end

    -- If all Gun Towers are in good shape, let's focus on the main producers.
    if (IsAround(cpuTeam.Recycler) and GetHealth(cpuTeam.Recycler) < 0.8) then
        -- Heal the Recycler.
        Service(servicerUnit.Handle, cpuTeam.Recycler)

        -- Bail, we're now occupied.
        return
    end

    -- Factory is considered a secondary interest. Check that next.
    if (IsAround(cpuTeam.Factory) and GetHealth(cpuTeam.Factory) < 0.8) then
        -- Heal the Factory.
        Service(servicerUnit.Handle, cpuTeam.Factory)

        -- Bail, we're now occupied.
        return
    end

    -- Armory is considered a tertiary interest. Check that last.
    if (IsAround(cpuTeam.Armory) and GetHealth(cpuTeam.Armory) < 0.8) then
        -- Heal the Factory.
        Service(servicerUnit.Handle, cpuTeam.Armory)

        -- Bail, we're now occupied.
        return
    end
end

---@param commander Handle
---@param spawnPath string
local function HandleCommander(commander, spawnPath)
    if (not IsIdle(commander)) then
        return
    end

    -- Check for nearby threats
    local nearestEnemy = GetNearestEnemy(commander, true, false, 200)
    if (nearestEnemy) then
        -- If enemy is nearby, engage or retreat based on health
        local health = GetHealth(commander)
        if (health < 0.3) then
            -- Retreat if low health
            local retreatPos = GetPositionNear(spawnPath, 40, 60);
            Goto(commander, retreatPos, 0)
        else
            -- Engage if healthy
            Attack(commander, nearestEnemy, 0)
        end

        return
    end

    -- Patrol if no immediate threats. Don't patrol into the enemy base.
    local patrolPoint = CPUManager.Pools[GetRandomInt(1, #CPUManager.Pools - 1)]
    if (patrolPoint) then
        local pos = GetPosition(patrolPoint)
        Goto(commander, GetPositionNear(pos, 30, 50), 0)
    end
end

---@param lieutenant Handle
---@param spawnPath string
---@param commander Handle
local function HandleLieutenant(lieutenant, spawnPath, commander)
    if (not IsIdle(lieutenant)) then
        return
    end

    -- Check for nearby threats
    local nearestEnemy = GetNearestEnemy(lieutenant, true, false, 200)
    if (nearestEnemy) then
        local health = GetHealth(lieutenant)
        if (health < 0.3) then
            -- Retreat if low health
            local retreatPos = GetPositionNear(spawnPath, 40, 60);
            Goto(lieutenant, retreatPos, 0)
        else
            -- Engage if healthy
            Attack(lieutenant, nearestEnemy, 0)
        end

        return
    end

    -- Run a check to see if there's a chance we should follow the commander, else patrol the map, or defend something.
    if (IsAlive(commander)) then
        local followChance = GetRandomFloat(1)
        if (followChance < 0.25) then
            Defend2(lieutenant, commander, 0)
            return
        end
    end

    local patrolPoint = CPUManager.Pools[GetRandomInt(1, #CPUManager.Pools - 1)]
    if (patrolPoint) then
        local pos = GetPosition(patrolPoint)
        Goto(lieutenant, GetPositionNear(pos, 30, 50), 0)
    end
end

---@param cpuTeam CPUTeam
---@param antiAirUnit DispatchClass
local function HandleAntiAir(cpuTeam, antiAirUnit)
    -- Determine patrol path
    local path = "anti-air_" .. GetRandomInt(1, 2);

    -- Send unit to position based on race
    if (cpuTeam.Faction == 'i') then
        Patrol(antiAirUnit.Handle, path);
    else
        Goto(antiAirUnit.Handle, path);
    end
end

---Creates a new CPU Team object.
---@param team number
---@param faction string
---@param spawnPath string
---@param isCampaign? boolean
function CPUManager.NewTeam(team, faction, spawnPath, isCampaign)
    ---@type CPUTeam
    local newTeam = {
        Name = _BZCCDatabase.CPUNames[GetRandomInt(1, #_BZCCDatabase.CPUNames)],
        Team = team,
        Faction = faction,
        AIPString = '',
        CommanderEnabled = false,
        Commander = nil,
        AssaultUnits = {},
        DispatchList = {},
        TauntCooldown = 0,
        TauntSetupDone = false,
        isCampaign = isCampaign or false,
        spawnPath = spawnPath,
        Recycler = nil,
        Factory = nil,
        Armory = nil,
        ServiceBay = nil,
        GunTowers = {},
        Lieutenants = {},
        LieutenantNames = {}
    }

    CPUManager.CPUTeams[#CPUManager.CPUTeams + 1] = newTeam

    if (not newTeam.isCampaign) then
        if (IsNetworkOn()) then
            newTeam.AIPString = _DLLUtils.GetCheckedNetworkSvar(3, _BZCCDatabase.NetlistVars.NETLIST_AIPs)
            newTeam.CommanderEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.MPI_COMMANDER_ENABLED) == 1
        else
            newTeam.AIPString = IFace_GetString(_BZCCDatabase.ShellVariables.AIP_STRING)
            newTeam.CommanderEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.COMMANDER_ENABLED) == 1
        end

        PrintConsoleMessage("New CPU Team created with values: " ..
            "Name: " .. newTeam.Name .. ", " ..
            "Team: " .. newTeam.Team .. ", " ..
            "Faction: " .. newTeam.Faction .. ", " ..
            "AIPString: " .. newTeam.AIPString .. ", " ..
            "CommanderEnabled: " .. tostring(newTeam.CommanderEnabled))

        if (newTeam.CommanderEnabled) then
            BuildObject(faction .. "vcmdr_s", team, GetPositionNear(spawnPath, 30, 60))

            -- Spawn Lts based on number of players in the game.
            for i = 2, IFace_GetInteger(_BZCCDatabase.ShellVariables.MPI_PLAYER_COUNT) do
                BuildObject(faction .. "vlt_c", team, GetPositionNear(spawnPath, 30, 60))
            end
        end

        SetCPUPlan(_BZCCDatabase.AIPTypes.AIPType0, newTeam)
    end

    SetScrap(team, 40)
end

---@param missionTurnCount integer
function CPUManager.Run(missionTurnCount)
    if (#CPUManager.CPUTeams <= 0) then
        return -- Abort. Nothing to do.
    end

    -- Process teams.
    for _, cpuTeam in pairs(CPUManager.CPUTeams) do
        -- Handle taunts for this team if it's not a campaign team.
        if (not cpuTeam.isCampaign) then
            if (not cpuTeam.TauntSetupDone) then
                if (missionTurnCount == 2) then
                    SetTauntCPUTeamName(cpuTeam.Name)
                elseif (missionTurnCount == 4) then
                    DoTaunt(_BZCCDatabase.TauntTypes.TAUNTS_GameStart)
                    cpuTeam.TauntSetupDone = true
                end
            else
                if (cpuTeam.TauntCooldown < missionTurnCount) then
                    DoTaunt(_BZCCDatabase.TauntTypes.TAUNTS_Random)
                    cpuTeam.TauntCooldown = missionTurnCount + SecondsToTurns(90)
                end
            end

            if (cpuTeam.CommanderEnabled) then
                if (IsAlive(cpuTeam.Commander)) then
                    HandleCommander(cpuTeam.Commander, cpuTeam.spawnPath)
                end

                if (#cpuTeam.Lieutenants > 0) then
                    for _, lt in pairs(cpuTeam.Lieutenants) do
                        HandleLieutenant(lt, cpuTeam.spawnPath, cpuTeam.Commander)
                    end
                end
            end
        end

        -- Start processing each dispatch unit if the cooldown for it has elapsed.
        for _, dispatchUnit in pairs(cpuTeam.DispatchList) do
            if (_DispatchClass.IsAvailable(dispatchUnit, missionTurnCount)) then
                -- Switch the type of unit and handle it appropriately.
                if (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.TURRET) then
                    HandleTurret(cpuTeam, dispatchUnit)
                elseif (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.PATROL) then
                    HandlePatrol(cpuTeam, dispatchUnit, "patrol_")
                elseif (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.BASE_PATROL) then
                    HandlePatrol(cpuTeam, dispatchUnit, "BasePatrol")
                elseif (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.APC_PATROL) then
                    HandleAPCPatrol(cpuTeam, dispatchUnit, missionTurnCount)
                elseif (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.ASSAULT_DEFENDER) then
                    HandleAssaultDefender(cpuTeam, dispatchUnit, cpuTeam.spawnPath)
                elseif (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.ASSAULT_SERVICE) then
                    HandleAssaultServicer(cpuTeam, dispatchUnit, cpuTeam.spawnPath)
                elseif (dispatchUnit.Class == _BZCCDatabase.AIUnitTypes.ANTI_AIR) then
                    HandleAntiAir(cpuTeam, dispatchUnit)
                end
            end
        end
    end
end

---@param handle Handle
---@param missionTurnCount integer
---@param teamNum integer
function CPUManager.AddTeamObject(handle, missionTurnCount, teamNum)
    local cpuTeam = GetCPUTeam(teamNum)

    if (cpuTeam == nil) then
        PrintConsoleMessage("CPUManager.AddTeamObject: Unable to find a CPUTeam object for team: " .. teamNum)
        return
    end

    if (GetClassLabel(handle) == "CLASS_TURRET") then
        cpuTeam.GunTowers[#cpuTeam.GunTowers + 1] = handle
        return
    end

    if (IsBuilding(handle)) then
        local buildingClass = GetClassLabel(handle)

        if (buildingClass == "CLASS_RECYCLER") then
            cpuTeam.Recycler = handle
            return
        end

        if (buildingClass == "CLASS_FACTORY") then
            cpuTeam.Factory = handle
            return
        end

        if (buildingClass == "CLASS_ARMORY") then
            cpuTeam.Armory = handle
            return
        end

        if (buildingClass == "CLASS_SUPPLYDEPOT") then
            cpuTeam.ServiceBay = handle
            return
        end

        -- We are a building, but not sure which type, so just stop.
        return
    end

    local AICraftType = GetODFString(handle, "GameObjectClass", "AIUnitType", nil)

    if (AICraftType == nil or AICraftType == _BZCCDatabase.AIUnitTypes.CARRIER) then
        return -- Don't process any units that don't have an appropriate type.
    end

    if (AICraftType == _BZCCDatabase.AIUnitTypes.COMMANDER) then
        cpuTeam.Commander = handle
        SetObjectiveName(cpuTeam.Commander, "Cmd. " .. cpuTeam.Name)
        return
    end

    if (AICraftType == _BZCCDatabase.AIUnitTypes.LIEUTENANT) then
        cpuTeam.Lieutenants[#cpuTeam.Lieutenants + 1] = handle

        -- Grab a name from the list that doesn't include the "cpuTeam.Name" value or already used lieutenant names.
        local lieutenantNames = {}
        local usedNames = {}

        for _, used in pairs(cpuTeam.LieutenantNames) do
            usedNames[used] = true
        end

        usedNames[cpuTeam.Name] = true -- Also exclude the team name

        for _, name in pairs(_BZCCDatabase.CPUNames) do
            if (not usedNames[name]) then
                lieutenantNames[#lieutenantNames + 1] = name
            end
        end

        local chosenName = lieutenantNames[GetRandomInt(1, #lieutenantNames)]
        SetLabel(handle, chosenName)
        SetObjectiveName(handle, "Lt. " .. chosenName)

        -- Throw the name in the list of used names to avoid renaming.
        cpuTeam.LieutenantNames[#cpuTeam.LieutenantNames + 1] = chosenName
        return
    end

    if (AICraftType == _BZCCDatabase.AIUnitTypes.ASSAULT) then
        cpuTeam.AssaultUnits[#cpuTeam.AssaultUnits + 1] = _AssaultClass.New(handle, team)
    else
        cpuTeam.DispatchList[#cpuTeam.DispatchList + 1] = _DispatchClass.New(handle, missionTurnCount, teamNum,
            AICraftType)
    end
end

---@param handle Handle
---@param teamNum integer
function CPUManager.RemoveTeamObject(handle, teamNum)
    -- Check for a team.
    local cpuTeam = GetCPUTeam(teamNum)

    -- No team? Bail.
    if (cpuTeam == nil) then
        PrintConsoleMessage("CPUManager.RemoveTeamObject: Unable to find a CPUTeam object for team: " .. teamNum)
        return
    end

    if (GetClassLabel(handle) == "CLASS_TURRET") then
        TableRemoveByHandle(cpuTeam.GunTowers, handle)
        return
    end

    if (IsBuilding(handle)) then
        local buildingClass = GetClassLabel(handle)

        if (buildingClass == "CLASS_RECYCLER") then
            cpuTeam.Recycler = nil
            return
        end

        if (buildingClass == "CLASS_FACTORY") then
            cpuTeam.Factory = nil
            return
        end

        if (buildingClass == "CLASS_ARMORY") then
            cpuTeam.Armory = nil
            return
        end

        if (buildingClass == "CLASS_SUPPLYDEPOT") then
            cpuTeam.ServiceBay = nil
            return
        end

        -- We are a building, but not sure which type, so just stop.
        return
    end


    local dispatchUnit = GetDistpachUnit(cpuTeam, handle)

    if (dispatchUnit == nil) then
        return
    end

    local AICraftType = GetODFString(handle, "GameObjectClass", "AIUnitType", nil)

    if (AICraftType == nil or AICraftType == _BZCCDatabase.AIUnitTypes.CARRIER) then
        return -- Don't process any units that don't have an appropriate type.
    end

    if (AICraftType == _BZCCDatabase.AIUnitTypes.COMMANDER) then
        cpuTeam.Commander = nil
        return
    end

    if (AICraftType == _BZCCDatabase.AIUnitTypes.LIEUTENANT) then
        cpuTeam.Lieutenants = TableRemoveByHandle(cpuTeam.Lieutenants, handle)

        -- Also grab the label of the ship so we can remove the name from the list of already used names.
        local shipName = GetLabel(handle)

        -- Run through the list of names and remove the name.
        if (shipName ~= nil and cpuTeam.LieutenantNames[shipName]) then
            cpuTeam.LieutenantNames[shipName] = nil
        end

        return
    end

    if (AICraftType == _BZCCDatabase.AIUnitTypes.ASSAULT) then
        local assaultUnit = GetAssaultUnit(cpuTeam, handle)

        if (assaultUnit == nil) then
            return
        end

        cpuTeam.AssaultUnits = SquelchDispatchTable(cpuTeam.AssaultUnits, assaultUnit)
        return
    end

    if (dispatchUnit.AssaultTarget ~= nil) then
        if (AICraftType == _BZCCDatabase.AIUnitTypes.ASSAULT_DEFENDER) then
            dispatchUnit.AssaultTarget.DefenderCount = dispatchUnit.AssaultTarget.DefenderCount - 1
        elseif (AICraftType == _BZCCDatabase.AIUnitTypes.ASSAULT_SERVICE) then
            dispatchUnit.AssaultTarget.ServiceTruckCount = dispatchUnit.AssaultTarget.ServiceTruckCount - 1
        end
    end

    cpuTeam.DispatchList = SquelchDispatchTable(cpuTeam.DispatchList, dispatchUnit)
end

---@param scrapHandle Handle
function CPUManager.AddScrap(scrapHandle)
    CPUManager.Scrap[#CPUManager.Scrap + 1] = scrapHandle
end

---@param scrapHandle Handle
function CPUManager.RemoveScrap(scrapHandle)
    TableRemoveByHandle(CPUManager.Scrap, scrapHandle)
end

---@param poolHandle Handle
function CPUManager.AddPool(poolHandle)
    CPUManager.Pools[#CPUManager.Pools + 1] = poolHandle
end

return CPUManager
