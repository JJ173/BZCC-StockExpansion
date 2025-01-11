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
    Turrets = {},
    Patrols = {},
    Defenders = {},

    -- Cooldowns for different functions so we don't run them per frame.
    TauntCooldown = 0
}

function AIController:New(Team, Race, Pools)
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
    o.Turrets = {};
    o.Patrols = {};
    o.Defenders = {};
    o.RecyclerDeployed = false;

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
    if (self.AICommanderEnabled) then
        self.Commander = BuildObject(self.Race .. "vcmdr_s", self.Team, GetPositionNear("RecyclerEnemy", 30, 60));
    end

    -- Give them scrap.
    SetScrap(CPUTeamNumber, 40);

    -- Start the plans.
    self:SetPlan(AIPType0);
end

function AIController:Run(MissionTurnCount)
    -- Handle the taunts from the CPU Team here.
    if (self.TauntCooldown < MissionTurnCount) then
        -- Run a random taunt.
        DoTaunt(TAUNTS_Random);

        -- Cooldown so we don't call this every frame.
        self.TauntCooldown = MissionTurnCount + SecondsToTurns(30);
    end

    -- Only do this when the Recycler is deployed.
    if (self.RecyclerDeployed) then
        -- Run each dispatcher.
    end
end

function AIController:CarrierLogic()

end

function AIController:AddObject(handle, objClass)
    -- Indicates the Recycler has been deployed at the start of the match.
    if (self.RecyclerDeployed == false and objClass == "CLASS_RECYCLER") then
        self.RecyclerDeployed = true;
    end
end

function AIController:DeleteObject(handle)

end

function AIController:SetPlan(type)
    if (type < AIPType0 or type >= MAX_AIP_TYPE) then
        type = AIPType3;
    end

    local AIPFile;
    local AIPString;

    if (self.AIPString ~= nil) then
        AIPString = self.AIPString;
    else
        AIPString = StockAIPNameBase;
    end

    -- First pass, try to find an AIP that is designed to use Provides for enemy team, thus it only cares about CPU Race. This makes adding races much easier.
    AIPFile = AIPString .. self.Race .. type;

    -- Run the plans.
    SetAIP(AIPFile .. '.aip', self.Team);

    -- Leave this for now, but it might be fun to turn this to a timed thing like G66 (Thanks Natty, forever the inspiration).
    DoTaunt(TAUNTS_Random);
end

function AIController:DispatchTurrets()
end

-- Local utilities.
function Compare(a, b)
    return a["DistanceFromCPURecycler"] < b["DistanceFromCPURecycler"];
end

-- Return to caller.
return AIController;
