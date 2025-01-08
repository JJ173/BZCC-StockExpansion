local _Pool = require("_Pool");

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

    -- Split down the models for the CPU so we don't have to iterate through huge lists.
    Scavengers = {},
    Constructors = {},
    Turrets = {},
    Patrols = {},
    Defenders = {}
}

function AIController:New(Team, Race, Pools, Recycler, Factory, Armory, Commander)
    local o = {}

    o.Team = Team or 0;
    o.Race = Race or nil;
    o.Pools = Pools or {};
    o.Recycler = Recycler or nil;
    o.Factory = Factory or nil;
    o.Armory = Armory or nil;
    o.Commander = Commander or nil;

    setmetatable(o, { __index = self });

    return o;
end

function AIController:Setup(CPUTeamNumber)
    -- Keep track of the team number.
    self.Team = CPUTeamNumber;

    -- For the pool positions, we need to work out which one is the base pool for the CPU and the Human, and remove them.
    table.sort(self.Pools, Compare);

    -- Check any options.
    AIController.AIPString = IFace_GetString("options.instant.string0");
    AIController.AICommanderEnabled = IFace_GetInteger("options.instant.bool2");

    -- Give them scrap.
    SetScrap(CPUTeamNumber, 40);

    -- Start the plans.
    self:SetPlan(AIPType0);
end

function AIController:Run()
    -- Handle the taunts from the CPU Team here.
end

function AIController:CarrierLogic()

end

function AIController:AddObject(handle, objClass)

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

function AIController:DispatchScavengers()
end

function AIController:DispatchTurrets()
end

-- Local utilities.
function Compare(a, b)
    return a["DistanceFromCPURecycler"] < b["DistanceFromCPURecycler"];
end

-- Return to caller.
return AIController;
