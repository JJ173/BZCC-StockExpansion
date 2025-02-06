local _Dispatch = require("_Dispatch");

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

    -- Store dispatched units here to perform idle checks. If they are idle, we can redistribute them.
    IdleQueue = {},

    -- Store units to dispatch here.
    TurretsToDispatch = {},
    PatrolsToDispatch = {},
    AntiAirToDispatch = {},
    MinionsToDispatch = {},
    ServiceTrucksToDispatch = {},

    Carrier = nil,
    LandingPad = nil,

    -- Name that's picked from a random list for the team.
    Name = "",

    -- Specific count for anti-air units so we know which paths to send them to.
    AntiAirCount = 0,

    -- Cooldowns for different functions so we don't run them per frame.
    TauntCooldown = 0,

    IdleQueueCooldown = 0,
    DispatchCooldown = 0,
};

-- States for the AI Commander.
local CMDR_IDLE = 0;
local CMDR_ATTACK = 1;
local CMDR_DEFEND = 2;
local CMDR_RETREAT = 3;

function AIController:New(Team, Race, Pools, Name)
    local o = {}

    o.Team = Team or 0;
    o.Race = Race or nil;
    o.Pools = Pools or {};

    o.AIPString = "";
    o.AICommanderEnabled = false;
    o.Recycler = nil;
    o.Commander = nil;
    o.AssaultUnits = {};
    o.TurretsToDispatch = {};
    o.PatrolsToDispatch = {};
    o.AntiAirToDispatch = {};
    o.MinionsToDispatch = {};
    o.IdleQueue = {};
    o.RecyclerDeployed = false;
    o.HasArmory = false;
    o.Name = Name or "";

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
    -- Keep track of the team number.
    self.Team = CPUTeamNumber;

    -- For the pool positions, we need to work out which one is the base pool for the CPU and the Human, and remove them.
    table.sort(self.Pools, Compare);

    -- Check any options.
    self.AIPString = IFace_GetString("options.instant.string0");
    self.AICommanderEnabled = IFace_GetInteger("options.instant.bool2");

    -- If the Commander is enabled, build one.
    if (self.AICommanderEnabled == 1) then
        self.Commander = BuildObject(self.Race .. "vcmdr_s", self.Team, GetPositionNear("RecyclerEnemy", 30, 60));
        SetObjectiveName(self.Commander, self.Name);
    end

    -- Give them scrap.
    SetScrap(CPUTeamNumber, 40);

    -- Start the plans.
    self:SetPlan(AIPType0);
end

function AIController:Run(missionTurnCount)
    -- Handle the taunts from the CPU Team here.
    if (self.TauntCooldown < missionTurnCount) then
        -- Run a random taunt.
        DoTaunt(TAUNTS_Random);

        -- Cooldown so we don't call this every frame.
        self.TauntCooldown = missionTurnCount + SecondsToTurns(90);
    end

    -- Only do this when the Recycler is deployed.
    if (self.RecyclerDeployed) then
        -- Check to see if any units are idle and redistribute them as necessary.
        if (self.IdleQueueCooldown < missionTurnCount) then
            self.IdleQueueCooldown = missionTurnCount + SecondsToTurns(2);
        end
        if (#self.IdleQueue > 0) then
            self:ProcessIdleUnits(missionTurnCount);
        end

        -- Run each dispatcher.
        if (self.DispatchCooldown < missionTurnCount) then
            if (#self.TurretsToDispatch > 0) then
                self:DispatchTurrets(missionTurnCount);
            end

            if (#self.PatrolsToDispatch > 0) then
                self:DispatchPatrols(missionTurnCount);
            end

            if (#self.AntiAirToDispatch > 0) then
                self:DispatchAntiAir(missionTurnCount);
            end

            if (#self.MinionsToDispatch > 0) then
                self:DispatchMinions(missionTurnCount);
            end

            self.DispatchCooldown = missionTurnCount + SecondsToTurns(1.5);
        end

        -- Handle the Commander.
        self:CommanderBrain();
    end
end

function AIController:AddObject(handle, objClass, objCfg, objBase, missionTurnCount)
    if (objCfg == self.Race .. "vcmdr_s" or objCfg == self.Race .. "vcmdr_t") then
        self.Commander = handle;
        SetObjectiveName(self.Commander, self.Name);
    elseif (self.RecyclerDeployed == false and objClass == "CLASS_RECYCLER") then
        self.RecyclerDeployed = true;
    elseif (objCfg == self.Race .. "bcarrier_xm") then
        self.Carrier = handle;
    elseif (objClass == "CLASS_TURRETTANK") then
        self.TurretsToDispatch[#self.TurretsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount, objBase);
    elseif (objBase == "Patrol") then
        self.PatrolsToDispatch[#self.PatrolsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount, objBase);
    elseif (objBase == "AntiAir") then
        self.AntiAirCount = self.AntiAirCount + 1;
        self.AntiAirToDispatch[#self.AntiAirToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount, objBase);
    elseif (objBase == "Minion" or objBase == "AssaultService") then
        self.MinionsToDispatch[#self.MinionsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount, objBase);
    elseif (objClass == "CLASS_ASSAULTTANK" or objClass == "CLASS_WALKER") then
        self.AssaultUnits[#self.AssaultUnits + 1] = handle;
    elseif (objClass == "CLASS_ARMORY") then
        self.HasArmory = true;
    elseif (objClass == "CLASS_SUPPLYDEPOT") then
        self.HasServiceBay = true;
    elseif (objClass == "CLASS_TECHCENTER") then
        self.HasTechCenter = true;
    end
end

function AIController:DeleteObject(handle, objClass, objCfg, objBase)
    if (objCfg == self.Race .. "vcmdr_s" or objCfg == self.Race .. "vcmdr_t") then
        self.Commander = nil;
    elseif (objClass == "CLASS_TURRETTANK") then
        TableRemoveByHandle(self.TurretsToDispatch, handle);
    elseif (objBase == "Patrol") then
        TableRemoveByHandle(self.PatrolsToDispatch, handle);
    elseif (objBase == "AntiAir") then
        self.AntiAirCount = self.AntiAirCount - 1;
        TableRemoveByHandle(self.AntiAirToDispatch, handle);
    elseif (objBase == "Minion" or objBase == "AssaultService") then
        TableRemoveByHandle(self.MinionsToDispatch, handle);
    elseif (objClass == "CLASS_ASSAULTTANK" or objClass == "CLASS_WALKER") then
        TableRemoveByHandle(self.AssaultUnits, handle);
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

    -- First pass, try to find an AIP that is designed to use Provides for enemy team, thus it only cares about CPU Race. This makes adding races much easier.
    local AIPFile = AIPString .. self.Race .. type;

    -- Run the plans.
    SetAIP(AIPFile .. '.aip', self.Team);

    -- Leave this for now, but it might be fun to turn this to a timed thing like G66 (Thanks Natty, forever the inspiration).
    DoTaunt(TAUNTS_Random);
end

function AIController:DispatchTurrets(missionTurnCount)
    -- For any turrets that need dispatching, let's send them around the map.
    for i = 1, #self.TurretsToDispatch do
        -- Grab the turret.
        local dispatch = self.TurretsToDispatch[i];

        -- Common function to check if the unit is available.
        if (IsDispatchUnitAvailable(dispatch, missionTurnCount) == false) then
            break;
        end

        -- Check to see if we have a target before we move the turret as it could be engaging after being shot.
        if (GetTarget(dispatch.Handle) ~= nil) then
            break;
        end

        -- Get a random pool, but don't use the first or last in the list as these are likely base pools.
        local poolOfChoice = self.Pools[GetRandomInt(2, #self.Pools - 1)].Position;

        -- Send the unit to defend near the pool.
        Goto(dispatch.Handle, GetPositionNear(poolOfChoice, 40, 60));

        -- Remove the turret from the  list of units to be dispatched.
        TableRemoveByHandle(self.TurretsToDispatch, dispatch);
    end
end

function AIController:DispatchPatrols(missionTurnCount)
    for i = 1, #self.PatrolsToDispatch do
        -- Grab the Patrol unit.
        local dispatch = self.PatrolsToDispatch[i];

        -- Common function to check if the unit is available.
        if (IsDispatchUnitAvailable(dispatch, missionTurnCount) == false) then
            break;
        end

        -- Add this unit to the Idle Queue.
        self.IdleQueue[#self.IdleQueue + 1] = dispatch;

        -- Grab a random path.
        local path = "patrol_" .. GetRandomInt(1, 2);

        -- Send the unit to Patrol.
        Patrol(dispatch.Handle, path);

        -- Remove the patrol unit from the list of units to be dispatched.
        TableRemoveByHandle(self.PatrolsToDispatch, dispatch);
    end
end

function AIController:DispatchAntiAir(missionTurnCount)
    -- Send the anti-air to the right path.
    for i = 1, #self.AntiAirToDispatch do
        -- Grab the anti-air.
        local dispatch = self.AntiAirToDispatch[i];

        -- Common function to check if the unit is available.
        if (IsDispatchUnitAvailable(dispatch, missionTurnCount) == false) then
            break;
        end

        -- Send the Anti-Air to the path based on the increment.
        local path = "anti-air_" .. self.AntiAirCount;

        -- Send the unit to Patrol.
        Patrol(dispatch.Handle, path);

        -- Remove the patrol unit from the list of units to be dispatched.
        TableRemoveByHandle(self.AntiAirToDispatch, dispatch);
    end
end

function AIController:DispatchMinions(missionTurnCount)
    -- For any turrets that need dispatching, let's send them around the map.
    for i = 1, #self.MinionsToDispatch do
        -- Grab the minion.
        local dispatch = self.MinionsToDispatch[i];

        -- Common function to check if the unit is available.
        if (IsDispatchUnitAvailable(dispatch, missionTurnCount) == false) then
            break;
        end

        -- Check to see if any assault units exist yet, otherwise don't dispatch.
        if (#self.AssaultUnits <= 0) then
            break;
        end

        -- Add this unit to the Idle Queue.
        self.IdleQueue[#self.IdleQueue + 1] = dispatch;

        -- Get a random assault unit to defend.
        local assaultUnitToDefend = self.AssaultUnits[GetRandomInt(1, #self.AssaultUnits)];

        -- If this minion is a Service Truck, send it to follow. Else, send a tank to defend.
        if (dispatch.Base == "Minion") then
            Defend2(dispatch.Handle, assaultUnitToDefend);

            -- Remove the minion from the right table.
            TableRemoveByHandle(self.MinionsToDispatch, dispatch);
        elseif (dispatch.Base == "AssaultService") then
            Follow(dispatch.Handle, assaultUnitToDefend);

            -- Remove the service truck from the right table.
            TableRemoveByHandle(self.ServiceTrucksToDispatch, dispatch);
        end
    end
end

function AIController:ProcessIdleUnits(missionTurnCount)
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
        TableRemoveByHandle(self.MinionsToDispatch, idleUnit);
    end
end

function AIController:CarrierBrain()

end

function AIController:CommanderBrain()

end

function AIController:TurretShot(handle, missionTurnCount)
    if (GetCurrentCommand(handle) ~= CMD_DEFEND) then
        -- Grab the vector that the turret was moving to so we can check later if it needs to be repositioned.
        local commandVector = GetCurrentCommandWhere(handle);

        -- Have the unit stop.
        Stop(handle, 0);

        -- Check to see how far the turret was from the original path it was going to.
        if (commandVector == nil or GetDistance(handle, commandVector) < 40) then
            return;
        end

        -- Re-add the turret to the dispatch list.
        self.TurretsToDispatch[#self.TurretsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount);
    end
end

function AIController:ScavengerShot(handle)
    if (IsIdle(handle)) then
        -- Make the Scavenger retreat.
        Goto(handle, GetPositionNear("RecyclerEnemy", 40, 60), 0);
    end
end

function AIController:AssignWeapons(handle)

end

-- Local utilities.
function Compare(a, b)
    return a["DistanceFromCPURecycler"] < b["DistanceFromCPURecycler"];
end

function CreateDispatchUnit(handle, missionTurn, objBase)
    return _Dispatch:New(handle, missionTurn, objBase);
end

function IsDispatchUnitAvailable(dispatchUnit, missionTurnCount)
    -- If the unit is not idle, ignore it.
    if (IsIdle(dispatchUnit.Handle) == false) then
        return false;
    end

    -- Don't process this unit if it's built in the same turn.
    if (dispatchUnit.BuiltTime == missionTurnCount) then
        return false;
    end

    -- Check to see if the dispatch cooldown has passed.
    if (dispatchUnit.DispatchDelay >= missionTurnCount) then
        return false;
    end

    return true;
end

function ReturnIdleUnitToBase(idleUnit)
    -- If this unit is outside of the base perimeter, send it back to the base and prepare for redispatch.
    if (GetDistance(idleUnit.Handle, "RecyclerEnemy") > 400) then
        -- Grab a vector position near the base.
        local returnPos = GetPositionNear("RecyclerEnemy", 60, 80);

        -- Return to base.
        Goto(idleUnit.Handle, returnPos);
    end
end

-- Return to caller.
return AIController;