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
};

-- States for the AI Commander.
local CMDR_IDLE = 0;
local CMDR_ATTACK = 1;
local CMDR_DEFEND = 2;
local CMDR_RETREAT = 3;

function AIController:New(Team, Race, Pools, Name)
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

    self.AIPString = IFace_GetString("options.instant.string0");
    self.AICommanderEnabled = IFace_GetInteger("options.instant.bool2");

    if (self.AICommanderEnabled == 1) then
        self.Commander = BuildObject(self.Race .. "vcmdr_s", self.Team, GetPositionNear("RecyclerEnemy", 30, 60));
        SetObjectiveName(self.Commander, self.Name);
    end

    SetScrap(CPUTeamNumber, 40);

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
            if (self.DispatchCooldown < missionTurnCount) then
                if (#self.TurretsToDispatch > 0) then
                    self:DispatchTurrets(missionTurnCount)
                end

                if (#self.PatrolsToDispatch > 0) then
                    self:DispatchPatrols(missionTurnCount)
                end

                if (#self.AntiAirToDispatch > 0) then
                    self:DispatchAntiAir(missionTurnCount)
                end

                if (#self.MinionsToDispatch > 0) then
                    self:DispatchMinions(missionTurnCount)
                end

                self.DispatchCooldown = missionTurnCount + SecondsToTurns(1.5)
            end

            self:CommanderBrain()
        end
    end)

    if not success then
        print("ERROR in AIController:Run: " .. tostring(err))
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
    for i = 1, #self.TurretsToDispatch do
        local dispatch = self.TurretsToDispatch[i];

        if (dispatch == nil) then
            print("WARNING, TURRET DISPATCH OBJECT AT INDEX " .. i .. " IS EMPTY! FIX!");
            break;
        end

        if (IsDispatchUnitAvailable(dispatch, missionTurnCount) == false) then
            break;
        end

        if (GetTarget(dispatch.Handle) ~= nil) then
            break;
        end

        local poolOfChoice = self.Pools[GetRandomInt(2, #self.Pools - 1)].Position;

        Goto(dispatch.Handle, GetPositionNear(poolOfChoice, 40, 60));

        RemoveDispatchFromTable(self.TurretsToDispatch, dispatch.Handle);
    end
end

function AIController:DispatchPatrols(missionTurnCount)
    for i = 1, #self.PatrolsToDispatch do
        local dispatch = self.PatrolsToDispatch[i];

        if (dispatch == nil) then
            print("WARNING, PATROL DISPATCH OBJECT AT INDEX " .. i .. " IS EMPTY! FIX!");
            break;
        end

        if (IsDispatchUnitAvailable(dispatch, missionTurnCount) == false) then
            break;
        end

        local path = '';

        if (dispatch.Base == "BasePatrol") then
            path = "BasePatrol" .. self.BasePatrolCount;
        else
            path = "patrol_" .. GetRandomInt(1, 2);
        end

        Patrol(dispatch.Handle, path);

        RemoveDispatchFromTable(self.PatrolsToDispatch, dispatch.Handle);
    end
end

function AIController:DispatchAntiAir(missionTurnCount)
    for i = 1, #self.AntiAirToDispatch do
        local dispatch = self.AntiAirToDispatch[i];

        if (dispatch == nil) then
            print("WARNING, ANTI-AIR DISPATCH OBJECT AT INDEX " .. i .. " IS EMPTY! FIX!");
            break;
        end

        if (IsDispatchUnitAvailable(dispatch, missionTurnCount) == false) then
            break;
        end

        local path = "anti-air_" .. self.AntiAirCount;

        if (self.Race == 'i') then
            Patrol(dispatch.Handle, path);
        else
            Goto(dispatch.Handle, path);
        end

        RemoveDispatchFromTable(self.AntiAirToDispatch, dispatch.Handle);
    end
end

function AIController:DispatchMinions(missionTurnCount)
    for i = 1, #self.MinionsToDispatch do
        local dispatch = self.MinionsToDispatch[i];

        if (dispatch == nil) then
            print("WARNING, MINION DISPATCH OBJECT AT INDEX " .. i .. " IS EMPTY! FIX!");
            break;
        end

        if (IsDispatchUnitAvailable(dispatch, missionTurnCount) == false) then
            break;
        end

        if (#self.AssaultUnits <= 0) then
            break;
        end

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
    if (IsIdle(self.Commander)) then
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

function RemoveDispatchFromTable(table, dispatchUnit)
    for i, v in pairs(table) do
        if (v.Handle == dispatchUnit) then
            table[i] = nil;
            break;
        end
    end
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
