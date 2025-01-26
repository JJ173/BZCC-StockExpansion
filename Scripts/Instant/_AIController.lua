local _Dispatch = require("_Dispatch");

AIController =
{
    AIPString = "",
    AICommanderEnabled = false,

    Team = 0,
    Race = "", -- Set to ISDF by default as a fallback.

    Recycler = 0,
    Factory = 0,
    Armory = 0,
    ServiceBay = 0,

    Pools = {},

    Commander = nil,

    -- Check Recycler Deployment. Once done, we can start our dispatch.
    RecyclerDeployed = false,

    -- Split down the models for the CPU so we don't have to iterate through huge lists.
    Scavengers = {},
    Constructors = {},

    -- Store units to dispatch here.
    TurretsToDispatch = {},
    PatrolsToDispatch = {},
    DefendersToDispatch = {},

    Carrier = nil,
    LandingPad = nil,

    -- Name that's picked from a random list for the team.
    Name = "";

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

    o.Team = Team or 0;
    o.Race = Race or nil;
    o.Pools = Pools or {};

    o.AIPString = "";
    o.AICommanderEnabled = false;
    o.Recycler = nil;
    o.Factory = nil;
    o.Armory = nil;
    o.ServiceBay = nil;
    o.Commander = nil;
    o.Scavengers = {};
    o.Constructors = {};
    o.TurretsToDispatch = {};
    o.PatrolsToDispatch = {};
    o.DefendersToDispatch = {};
    o.RecyclerDeployed = false;
    o.Name = Name or "";

    setmetatable(o, { __index = self });

    return o;
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
        self.TauntCooldown = missionTurnCount + SecondsToTurns(60);
    end

    -- Only do this when the Recycler is deployed.
    if (self.RecyclerDeployed) then
        -- Run each dispatcher.
        if (self.DispatchCooldown < missionTurnCount) then
            if (#self.TurretsToDispatch > 0) then
                -- self:DispatchTurrets(missionTurnCount);
            end

            if (#self.DefendersToDispatch > 0) then
                self:DispatchDefenders(missionTurnCount);
            end

            if (#self.PatrolsToDispatch > 0) then
                self:DispatchPatrols(missionTurnCount);
            end

            self.DispatchCooldown = missionTurnCount + SecondsToTurns(3);
        end

        -- Handle the Commander.
        self:CommanderBrain();
    end
end

function AIController:CarrierLogic()

end

function AIController:AddObject(handle, objClass, objCfg, objBase, missionTurnCount)
    if (objCfg == self.Race .. "vcmdr_s" or objCfg == self.Race .. "vcmdr_t") then
        self.Commander = handle;
        SetObjectiveName(self.Commander, self.Name);
    elseif (self.RecyclerDeployed == false and objClass == "CLASS_RECYCLER") then
        self.RecyclerDeployed = true;
    elseif (objClass == "CLASS_SCAVENGER") then
        self.Scavengers[#self.Scavengers + 1] =  handle;
    elseif (objClass == "CLASS_CONSTRUCTIONRIG") then
        self.Constructors[#self.Constructors + 1] = handle;
    elseif (objCfg == self.Race .. "bcarrier_xm") then
        self.Carrier = handle;
    elseif (objClass == "CLASS_TURRETTANK") then
        self.TurretsToDispatch[#self.TurretsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount);
    elseif (objBase == "Patrol") then
        self.PatrolsToDispatch[#self.PatrolsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount);
    elseif (objBase == "Defender") then
        self.DefendersToDispatch[#self.DefendersToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount);
    end
end

function AIController:DeleteObject(handle, objClass, objCfg)
    if (objClass == "CLASS_SCAVENGER") then
        TableRemoveByHandle(self.Scavengers, handle);
    elseif (objClass == "CLASS_CONSTRUCTIONRIG") then
        TableRemoveByHandle(self.Constructors, handle);
    elseif (objCfg == self.Race .. "vcmdr_s" or objCfg == self.Race .. "vcmdr_t") then
        self.Commander = nil;
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

        -- Check to see if the dispatch cooldown has passed.
        if (dispatch.DispatchDelay >= missionTurnCount) then
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

        -- Check to see if the dispatch cooldown has passed.
        if (dispatch.DispatchDelay >= missionTurnCount) then
            break;
        end

        -- Grab a random path.
        local path = "patrol_" .. GetRandomInt(1, 2);

        -- Send the unit to Patrol.
        Patrol(dispatch.Handle, path);

        -- Remove the turret from the  list of units to be dispatched.
        TableRemoveByHandle(self.PatrolsToDispatch, dispatch);
    end
end

function AIController:DispatchDefenders(missionTurnCount)

end

function AIController:CommanderBrain()

end

function AIController:TurretShot(handle, destinationVector, missionTurnCount)
    -- Check to see how far the turret was from the original path it was going to.
    if (destinationVector == nil or GetDistance(handle, destinationVector) < 40) then
        return;
    end

    -- Re-add the turret to the dispatch list.
    self.TurretsToDispatch[#self.TurretsToDispatch + 1] = CreateDispatchUnit(handle, missionTurnCount);
end

function AIController:AssignWeapons(handle)

end

-- Local utilities.
function Compare(a, b)
    return a["DistanceFromCPURecycler"] < b["DistanceFromCPURecycler"];
end

function CreateDispatchUnit(handle, missionTurn)
    return _Dispatch:New(handle, missionTurn + SecondsToTurns(2));
end

-- Return to caller.
return AIController;
