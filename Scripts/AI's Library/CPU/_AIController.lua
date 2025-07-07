local _Dispatch = require("_Dispatch");
local _AssaultUnit = require("_AssaultUnit");

AIController =
{
    AIPString = "",
    AICommanderEnabled = false,

    Team = 0,
    Race = "", -- Set to ISDF by default as a fallback.

    Pools = {},

    Commander = nil,

    -- Check Recycler Deployment. Once done, we can start our dispatch.
    RecyclerDeployed = false,

    -- Check to see if we have an Armory.
    HasArmory = false,
    HasServiceBay = false,
    HasTechCenter = false,

    -- Split down the models for the CPU so we don't have to iterate through huge lists.
    AssaultUnits = {},
    IdleQueue = {},

    -- Store units to dispatch here.
    TurretsToDispatch = {},
    PatrolsToDispatch = {},
    AntiAirToDispatch = {},
    MinionsToDispatch = {},

    -- This should handle weapons for the AI.
    Cannons = {},
    Missiles = {},
    Guns = {},
    Mines = {},
    Specials = {},
    Shields = {},

    Carrier = nil,
    LandingPad = nil,

    -- Name that's picked from a random list for the team.
    Name = "",

    -- Specific count for anti-air units so we know which paths to send them to.
    AntiAirCount = 0,
    BasePatrolCount = 0,

    -- Cooldowns for different functions so we don't run them per frame.
    TauntCooldown = 0,
    DispatchCooldown = 0,
    IdleQueueCooldown = 0
};

-- States for the AI Commander.
local CMDR_IDLE = 0;
local CMDR_ATTACK = 1;
local CMDR_DEFEND = 2;
local CMDR_RETREAT = 3;

-- Potential Supporter Names for CPU.
local _CPUNames =
{
    "SIR BRAMBLEY",
    "GrizzlyOne95",
    "BlackDragon",
    "Spymaster",
    "Autarch Katherlyn",
    "blue_banana",
    "Zorn",
    "Gravey",
    "VTrider",
    "Ultraken",
    "Darkvale",
    "Econchump",
    "Sev"
}

function AIController:New(Team, Race, Pools)
    local o = {}

    o.AIPString = "";
    o.AICommanderEnabled = false;
    o.Team = Team or 0;
    o.Race = Race or nil;
    o.Pools = Pools or {};
    o.Commander = nil;
    o.RecyclerDeployed = false;

    o.HasArmory = false;
    o.HasServiceBay = false;
    o.HasTechCenter = false;

    o.AssaultUnits = {};
    o.IdleQueue = {};

    o.TurretsToDispatch = {};
    o.PatrolsToDispatch = {};
    o.AntiAirToDispatch = {};
    o.MinionsToDispatch = {};

    o.Cannons = {};
    o.Missiles = {};
    o.Guns = {};
    o.Mines = {};
    o.Specials = {};
    o.Shields = {};

    o.Carrier = nil;
    o.LandingPad = nil;

    o.Name = Name or "";

    o.AntiAirCount = 0;
    o.BasePatrolCount = 0;
    o.TauntCooldown = 0;
    o.DispatchCooldown = 0;
    o.IdleQueueCooldown = 0;

    setmetatable(o, { __index = self });

    return o;
end

function AIController:Save()
    return AIController;
end

function AIController:Load(aiController)
    AIController = aiController;
end

function AIController:Setup(CPUTeamNumber)
    self.Team = CPUTeamNumber;

    table.sort(self.Pools, Compare);

    local chosenCPUName = _CPUNames[math.ceil(GetRandomInt(1, #_CPUNames))];
    SetTauntCPUTeamName(chosenCPUName);

    self.AIPString = IFace_GetString("options.instant.string0");
    self.AICommanderEnabled = IFace_GetInteger("options.instant.bool2");
    self.Name = chosenCPUName;

    if (self.AICommanderEnabled == 1) then
        self.Commander = BuildObject(self.Race .. "vcmdr_s", self.Team, GetPositionNear("RecyclerEnemy", 30, 60));
        SetObjectiveName(self.Commander, self.Name);
    end

    SetScrap(CPUTeamNumber, 40);
    DoTaunt(TAUNTS_GameStart);

    self:SetPlan(AIPType0);
end

function AIController:Run(missionTurnCount)
    if not missionTurnCount then
        print("ERROR: missionTurnCount is nil in AIController:Run")
        return
    end

    local success, err = pcall(function()
        if (self.TauntCooldown < missionTurnCount) then
            DoTaunt(TAUNTS_Random)
            self.TauntCooldown = missionTurnCount + SecondsToTurns(90)
        end

        
        if (self.RecyclerDeployed) then
            if (self.IdleQueueCooldown < missionTurnCount) then
                if (#self.IdleQueue > 0) then
                    self:ProcessIdleUnits();
                end

                self.IdleQueueCooldown = missionTurnCount + SecondsToTurns(2);
            end

            if (self.DispatchCooldown < missionTurnCount) then
                self:DispatchTurrets(missionTurnCount);
                self:DispatchPatrols(missionTurnCount);
                self:DispatchAntiAir(missionTurnCount);
                self:DispatchMinions(missionTurnCount);

                self.DispatchCooldown = missionTurnCount + SecondsToTurns(1.5)
            end

            self:CommanderBrain();
        end
    end)

    if not success then
        print("ERROR in AIController:Run: " .. tostring(err))
    end
end

function AIController:AddObject(handle, objClass, objCfg, objBase, missionTurnCount)
    -- print('Running AIController:AddObject ', objClass .. ' ', objCfg .. ' ', objBase .. ' ', missionTurnCount);

    if (objCfg == self.Race .. "vcmdr_s" or objCfg == self.Race .. "vcmdr_t") then
        self.Commander = handle;
        SetObjectiveName(self.Commander, self.Name);
    elseif (self.RecyclerDeployed == false and objClass == "CLASS_RECYCLER") then
        self.RecyclerDeployed = true;
    elseif (objCfg == self.Race .. "bcarrier_xm") then
        self.Carrier = handle;
    elseif (objClass == "CLASS_TURRETTANK") then
        self.TurretsToDispatch[#self.TurretsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount, objBase);
    elseif (objBase == "Patrol" or objBase == "BasePatrol") then
        if (objBase == "BasePatrol") then
            self.BasePatrolCount = self.BasePatrolCount + 1;
        end

        self.PatrolsToDispatch[#self.PatrolsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount, objBase);
    elseif (objBase == "AntiAir") then
        self.AntiAirCount = self.AntiAirCount + 1;
        self.AntiAirToDispatch[#self.AntiAirToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount, objBase);
    elseif (objBase == "Minion" or objBase == "AssaultService") then
        self.MinionsToDispatch[#self.MinionsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount, objBase);
    elseif (objClass == "CLASS_ASSAULTTANK" or objClass == "CLASS_WALKER") then
        self.AssaultUnits[#self.AssaultUnits + 1] = CreateAssaultUnit(handle);
    elseif (objClass == "CLASS_ARMORY") then
        self.HasArmory = true;
    elseif (objClass == "CLASS_SUPPLYDEPOT") then
        self.HasServiceBay = true;
    elseif (objClass == "CLASS_TECHCENTER") then
        self.HasTechCenter = true;
    end
end

function AIController:DeleteObject(handle, objClass, objCfg, objBase)
    -- print('Running AIController:DeleteObject ', objClass .. ' ', objCfg .. ' ', objBase);

    if (objCfg == self.Race .. "vcmdr_s" or objCfg == self.Race .. "vcmdr_t") then
        self.Commander = nil;
    elseif (objClass == "CLASS_TURRETTANK") then
        RemoveDispatchFromTable(self.TurretsToDispatch, handle);
    elseif (objBase == "Patrol" or objBase == "BasePatrol") then
        if (objBase == "BasePatrol") then
            self.BasePatrolCount = self.BasePatrolCount - 1;
        end

        RemoveDispatchFromTable(self.PatrolsToDispatch, handle);
    elseif (objBase == "AntiAir") then
        self.AntiAirCount = self.AntiAirCount - 1;
        RemoveDispatchFromTable(self.AntiAirToDispatch, handle);
    elseif (objBase == "Minion" or objBase == "AssaultService") then
        RemoveDispatchFromTable(self.MinionsToDispatch, handle);
    elseif (objClass == "CLASS_ASSAULTTANK" or objClass == "CLASS_WALKER") then
        RemoveDispatchFromTable(self.AssaultUnits, handle);
    elseif (objClass == "CLASS_ARMORY") then
        self.HasArmory = false;
    elseif (objClass == "CLASS_SUPPLYDEPOT") then
        self.HasServiceBay = false;
    elseif (objClass == "CLASS_TECHCENTER") then
        self.HasTechCenter = false;
    end
end

function AIController:SetPlan(type)
    if (type < AIPType0 or type >= MAX_AIP_TYPE) then
        type = AIPType3;
    end

    local AIPString;

    if (self.AIPString ~= nil) then
        AIPString = self.AIPString;
    else
        AIPString = StockAIPNameBase;
    end

    local AIPFile = AIPString .. self.Race .. type;

    SetAIP(AIPFile .. '.aip', self.Team);
    DoTaunt(TAUNTS_Random);
end

function AIController:DispatchTurrets(missionTurnCount)
    --  print("Dispatching turrets");

    -- Input validation
    if (not missionTurnCount) then
        print("ERROR: missionTurnCount is nil in DispatchTurrets");
        return;
    end

    -- Early exit if no turrets to dispatch
    if (#self.TurretsToDispatch == 0) then
        --print("WARNING: No turrets to dispatch");
        return;
    end

    -- Cache table length to avoid repeated calculations
    local numTurrets = #self.TurretsToDispatch;

    for i = 1, numTurrets do
        local dispatch = self.TurretsToDispatch[i];

        -- Validate dispatch object
        if (not dispatch) then
            print("WARNING: Turret dispatch object at index " .. i .. " is nil");
            break;
        end

        -- Check if unit is available for dispatch
        if (not IsDispatchUnitAvailable(dispatch, missionTurnCount)) then
            --print("WARNING: Turret dispatch object at index " .. i .. " is not available");
            break;
        end

        -- Check if unit already has a target
        if (GetTarget(dispatch.Handle) ~= nil) then
            --print("WARNING: Turret dispatch object at index " .. i .. " already has a target");
            break;
        end

        -- Select a random pool (avoiding first and last pool)
        local poolIndex = GetRandomInt(2, #self.Pools - 1);
        local selectedPool = self.Pools[poolIndex];

        -- Validate selected pool
        if (not selectedPool or not selectedPool.Position) then
            print("WARNING: Invalid pool selected for turret dispatch");
            break;
        end

        -- Calculate target position
        local targetPos = GetPositionNear(selectedPool.Position, 40, 60);

        -- Send turret to position
        Goto(dispatch.Handle, targetPos);

        -- Remove from dispatch table
        RemoveDispatchFromTable(self.TurretsToDispatch, dispatch.Handle);
    end
end

function AIController:DispatchPatrols(missionTurnCount)
    -- print("Dispatching patrols");

    -- Input validation
    if (not missionTurnCount) then
        print("ERROR: missionTurnCount is nil in DispatchPatrols");
        return;
    end

    -- Early exit if no patrols to dispatch
    if (#self.PatrolsToDispatch == 0) then
        --print("WARNING: No patrols to dispatch");
        return;
    end

    -- Cache table length to avoid repeated calculations
    local numPatrols = #self.PatrolsToDispatch;

    for i = 1, numPatrols do
        local dispatch = self.PatrolsToDispatch[i];

        -- Validate dispatch object
        if (not dispatch) then
            print("WARNING: Patrol dispatch object at index " .. i .. " is nil");
            break;
        end

        -- Check if unit is available for dispatch
        if (not IsDispatchUnitAvailable(dispatch, missionTurnCount)) then
            -- print("WARNING: Patrol dispatch object at index " .. i .. " is not available");
            break;
        end

        -- Determine patrol path based on unit type
        local path = (dispatch.Base == "BasePatrol")
            and "BasePatrol" .. self.BasePatrolCount
            or "patrol_" .. GetRandomInt(1, 2);

        -- Send unit on patrol
        Patrol(dispatch.Handle, path);

        -- Add to idle queue for future processing
        self.IdleQueue[#self.IdleQueue + 1] = dispatch;

        -- Remove from dispatch table
        RemoveDispatchFromTable(self.PatrolsToDispatch, dispatch.Handle);
    end
end

function AIController:DispatchAntiAir(missionTurnCount)
    -- print("Dispatching anti-air");

    -- Input validation
    if (not missionTurnCount) then
        print("ERROR: missionTurnCount is nil in DispatchAntiAir");
        return;
    end

    -- Early exit if no anti-air units to dispatch
    if (#self.AntiAirToDispatch == 0) then
        return;
    end

    -- Cache table length to avoid repeated calculations
    local numAntiAir = #self.AntiAirToDispatch;

    for i = 1, numAntiAir do
        local dispatch = self.AntiAirToDispatch[i];

        -- Validate dispatch object
        if (not dispatch) then
            print("WARNING: Anti-air dispatch object at index " .. i .. " is nil");
            break;
        end

        -- Check if unit is available for dispatch
        if (not IsDispatchUnitAvailable(dispatch, missionTurnCount)) then
            break;
        end

        -- Determine patrol path
        local path = "anti-air_" .. self.AntiAirCount;

        -- Send unit to position based on race
        if (self.Race == 'i') then
            Patrol(dispatch.Handle, path);
        else
            Goto(dispatch.Handle, path);
        end

        -- Remove from dispatch table
        RemoveDispatchFromTable(self.AntiAirToDispatch, dispatch.Handle);
    end
end

function AIController:DispatchMinions(missionTurnCount)
    -- print("Dispatching minions");

    -- Input validation
    if (not missionTurnCount) then
        print("ERROR: missionTurnCount is nil in DispatchMinions");
        return;
    end

    -- Early exit if no minions to dispatch or no assault units to support
    if (#self.MinionsToDispatch == 0 or #self.AssaultUnits == 0) then
        return;
    end

    -- Cache table length to avoid repeated calculations
    local numMinions = #self.MinionsToDispatch;

    for i = 1, numMinions do
        local dispatch = self.MinionsToDispatch[i];

        -- Validate dispatch object
        if (not dispatch) then
            print("WARNING: Minion dispatch object at index " .. i .. " is nil");
            break;
        end

        -- Check if unit is available for dispatch
        if (not IsDispatchUnitAvailable(dispatch, missionTurnCount)) then
            break;
        end

        -- Collect units that need support
        local assaultUnitToDefend = {};
        local assaultUnitsToService = {};

        for k, v in pairs(self.AssaultUnits) do
            if (v.DefenderHandle == 0) then
                assaultUnitToDefend[#assaultUnitToDefend + 1] = v;
            end

            if (v.HealerHandle == 0) then
                assaultUnitsToService[#assaultUnitsToService + 1] = v;
            end
        end

        -- Add to idle queue for future processing
        self.IdleQueue[#self.IdleQueue + 1] = dispatch;

        -- Handle minion assignment based on type
        if (dispatch.Base == "Minion" and #assaultUnitToDefend > 0) then
            local unitToDefend = assaultUnitToDefend[GetRandomInt(1, #assaultUnitToDefend)];
            unitToDefend.DefenderHandle = dispatch.Handle;
            Defend2(dispatch.Handle, unitToDefend.Handle);
            RemoveDispatchFromTable(self.MinionsToDispatch, dispatch.Handle);
        elseif (dispatch.Base == "AssaultService" and #assaultUnitsToService > 0) then
            local unitToService = assaultUnitsToService[GetRandomInt(1, #assaultUnitsToService)];
            unitToService.HealerHandle = dispatch.Handle;
            Follow(dispatch.Handle, unitToService.Handle);
            RemoveDispatchFromTable(self.MinionsToDispatch, dispatch.Handle);
        end
    end
end

function AIController:CarrierBrain()
    if not self.Carrier then return end

    -- if not self.Carrier then return end

    -- -- Basic carrier behavior
    -- if IsIdle(self.Carrier) then
    --     -- If carrier is idle, have it patrol between resource points
    --     local pool = self.Pools[GetRandomInt(1, #self.Pools)]
    --     if pool then
    --         Goto(self.Carrier, GetPositionNear(pool.Position, 30, 50))
    --     end
    -- end
end

function AIController:CommanderBrain()
    if (not self.Commander or not self.AICommanderEnabled) then return end

    -- Basic commander behavior
    if (GetCurrentCommand(self.Commander) == CMD_NONE) then
        -- Check for nearby threats
        local nearestEnemy = GetNearestEnemy(self.Commander, true, false, 200);
        if (nearestEnemy) then
            -- If enemy is nearby, engage or retreat based on health
            local health = GetHealth(self.Commander);
            if (health < 0.3) then
                -- Retreat if low health
                local retreatPos = GetPositionNear("RecyclerEnemy", 40, 60);
                Goto(self.Commander, retreatPos);
            else
                -- Engage if healthy
                Attack(self.Commander, nearestEnemy);
            end
        else
            -- Patrol if no immediate threats. Don't patrol into the enemy base.
            local patrolPoint = self.Pools[GetRandomInt(1, #self.Pools - 1)];
            if (patrolPoint) then
                Goto(self.Commander, GetPositionNear(patrolPoint.Position, 30, 50));
            end
        end
    end
end

function AIController:TurretShot(handle, missionTurnCount)
    if (GetCurrentCommand(handle) ~= CMD_DEFEND) then
        local commandVector = GetCurrentCommandWhere(handle);

        Stop(handle, 0);

        if (commandVector == nil or GetDistance(handle, commandVector) < 40) then
            return;
        end

        self.TurretsToDispatch[#self.TurretsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount);
    end
end

function AIController:ProcessIdleUnits()
    -- print("Processing idle units");

    for i = 1, #self.IdleQueue do
        -- Grab the idle unit.
        local idleUnit = self.IdleQueue[i];

        -- Let's first check that this unit is indeed idle.
        if (IsIdle(idleUnit.Handle) == false) then
            return false;
        end

        -- Check the base of the unit to see where it needs to be added.
        if (idleUnit.Base == "Minion" or idleUnit.Base == "AssaultService") then
            ReturnIdleUnitToBase(idleUnit);
            self.MinionsToDispatch[#self.MinionsToDispatch + 1] = idleUnit;
        elseif (idleUnit.Base == "Patrol") then
            self.PatrolsToDispatch[#self.PatrolsToDispatch + 1] = idleUnit;
        end

        -- Remove the idle unit from the idle table.
        RemoveDispatchFromTable(self.IdleQueue, idleUnit.Handle);
    end
end

function AIController:ScavengerShot(handle)
    if (IsIdle(handle)) then
        Goto(handle, GetPositionNear("RecyclerEnemy", 40, 60), 0);
    end
end

function AIController:AssignWeapons(handle)
    if (not handle) then return end

    local objClass = GetClassLabel(handle);
    if (not objClass) then return end

    -- Assign appropriate weapons based on unit class
    if (objClass == "CLASS_ASSAULTTANK") then
        -- Assign primary weapon
        if (self.Cannons[1]) then
            SetWeapon(handle, 0, self.Cannons[1]);
        end
        -- Assign secondary weapon if available
        if (self.Missiles[1]) then
            SetWeapon(handle, 1, self.Missiles[1]);
        end
    elseif (objClass == "CLASS_WALKER") then
        -- Assign walker-specific weapons
        if (self.Guns[1]) then
            SetWeapon(handle, 0, self.Guns[1]);
        end
        if (self.Specials[1]) then
            SetWeapon(handle, 1, self.Specials[1]);
        end
    end
end

-- Local utilities.
function Compare(a, b)
    return a["DistanceFromCPURecycler"] < b["DistanceFromCPURecycler"];
end

function CreateDispatchUnit(handle, missionTurn, objBase)
    return _Dispatch:New(handle, missionTurn, objBase);
end

function CreateAssaultUnit(handle)
    return _AssaultUnit:New(handle);
end

function RemoveDispatchFromTable(dispatchTable, dispatchUnit)
    -- Input validation
    if (not dispatchTable or not dispatchUnit) then
        return false;
    end

    -- Use ipairs for better performance with sequential arrays
    for i, v in ipairs(dispatchTable) do
        if (v.Handle == dispatchUnit) then
            -- Move the last element to the current position and remove the last element
            -- This is more efficient than table.remove() and maintains array integrity
            dispatchTable[i] = dispatchTable[#dispatchTable];
            dispatchTable[#dispatchTable] = nil;
            return true;
        end
    end

    return false;
end

function IsDispatchUnitAvailable(dispatchUnit, missionTurnCount)
    if (IsIdle(dispatchUnit.Handle) == false) then
        return false;
    end

    if (dispatchUnit.BuiltTime == missionTurnCount) then
        return false;
    end

    if (dispatchUnit.DispatchDelay >= missionTurnCount) then
        return false;
    end

    return true;
end

function ReturnIdleUnitToBase(idleUnit)
    if (GetDistance(idleUnit.Handle, "RecyclerEnemy") > 400) then
        local returnPos = GetPositionNear("RecyclerEnemy", 60, 80);
        Goto(idleUnit.Handle, returnPos);
    end
end

-- Return to caller.
return AIController;
