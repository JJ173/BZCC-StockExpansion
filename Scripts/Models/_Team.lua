local _Unit = require("_Unit");
local _Building = require("_Building");
local _Pool = require("_Pool");

-- Return this to whatever file calls it.
Team =
{
    isSetup = false,

    Team = 0,
    Pools = {},

    Race = 102, -- Set to ISDF by default as a fallback.

    Recycler = nil,
    Factory = nil,
    Armory = nil,
    ServiceBay = nil,

    Buildings = {},
    Units = {},

    TurnCount = 0,

    -- CPU specific variables.
    Commander = nil,
    AICommanderEnabled = 0,

    -- Split down the models for the CPU so we don't have to iterate through huge lists.
    Turrets = {},
    Patrols = {},
    Defenders = {},
    Utilities = {}
};

function Team:New(Team, Race, Pools, Recycler, Factory, Armory, Commander)
    local o = {}

    setmetatable(o, { __index = self });

    o.Team = Team or 0;
    o.Race = Race or 102;
    o.Pools = Pools or {};
    o.Recycler = Recycler or nil;
    o.Factory = Factory or nil;
    o.Armory = Armory or nil;
    o.Commander = Commander or nil;

    return o;
end

function Team:Setup(isCPU)
    if (isCPU) then
        -- My race.
        self.Race = string.char(IFace_GetInteger("options.instant.myrace"));

        -- Create Recyclers based on settings.
        local customRecyclerOption = IFace_GetString("options.instant.string2");

        -- We need to replace the first character of the string to match a selected race.
        customRecyclerOption = ReplaceCharacter(1, customRecyclerOption, self.Race);

        -- Check if the ODF exists. If it doesn't, then let's default to the CPU Recycler.
        if (DoesODFExist(customRecyclerOption)) then
            self.Recycler = BuildObject(customRecyclerOption, self.Team, "RecyclerEnemy");
        else
            -- This needs to check if a CPU variant exists just incase it's a custom faction.
            local checkODF = self.Race .. "vrecycpu";

            if (DoesODFExist(checkODF)) then
                self.Recycler = BuildObject(checkODF, self.Team, "RecyclerEnemy");
            else
                self.Recycler = BuildObject(self.Race .. "vrecy", self.Team, "RecyclerEnemy");
            end
        end

        -- For the pool positions, we need to work out which one is the base pool for the CPU and the Human, and remove them.
        table.sort(self.Pools, Compare);

        -- Remove the first and last entries as they are sorted, so the closest is the base pool for the CPU, and the last is the Player pool.
        table.remove(self.Pools, 1);
        table.remove(self.Pools, #self.Pools);

        -- Build turrets at paths that are on the map.
        for i = 1, 3 do
            local turretObject = _Unit:New(self.Team, BuildObject(self.Race .. "vturr_c", self.Team, "Turret_" .. i),
                CMD_DEFEND);
            self.Units[#self.Units + 1] = turretObject;
        end
    else
        -- Grab the races for each team.
        self.Race = string.char(IFace_GetInteger("options.instant.hisrace"));

        -- Check the Human Recycler ODF next.
        local customRecyclerOption = IFace_GetString("options.instant.string1");

        -- We need to replace the first character of the string to match a selected race.
        customRecyclerOption = ReplaceCharacter(1, customRecyclerOption, self.Race);

        -- Same procedure, except this needs to check for a player vehicle instead.
        if (DoesODFExist(customRecyclerOption)) then
            self.Recycler = BuildObject(customRecyclerOption, self.Team, "Recycler");
        else
            self.Recycler = BuildObject(self.Race .. "vrecy", self.Team, "Recycler");
        end

        -- Make sure the player Recycler is commandable.
        SetBestGroup(self.Recycler);

        -- Testing
        SetObjectiveName(self.Recycler,  "%n");

        -- Replace the player handle with a new one based on the faction they have chosen.
        local PlayerEntryH = GetPlayerHandle(self.Team);

        if (PlayerEntryH ~= nil) then
            RemoveObject(PlayerEntryH);
        end

        -- Create the player for the server.
        local PlayerH = BuildObject(self.Race .. "vscout_x", self.Team,
            GetPositionNear(GetPosition(self.Recycler), 30, 30));

        -- Make sure we give the player control of their ship.
        SetAsUser(PlayerH, self.Team);
    end

    -- Give me some scrap.
    SetScrap(self.Team, 40);

    -- So we can run new functions.
    self.isSetup = true;

    -- Enables the AI Commander.
    if (isCPU) then
        -- Check if the "AI Commander" option has been checked.
        self.AICommanderEnabled = IFace_GetInteger("options.instant.bool2");

        if (self.AICommanderEnabled == 1) then
            BuildObject(self.Race .. "vcmdr_s", self.Team, GetPositionNear(GetPosition(self.Recycler), 30, 30));
        end
    end
end

function Team:AddObject(handle, classLabel, ODFName, baseName)
    if (self.isSetup) then
        -- Check to see if this is a building.
        if (IsBuilding(handle) or classLabel == "CLASS_TURRET") then
            -- See if this works for a model.
            local buildingModel = _Building:New(self.Team, handle);

            -- Check to see if we need to assign any special buildings.
            if (classLabel == "CLASS_FACTORY") then
                self.Factory = buildingModel;
            elseif (classLabel == "CLASS_ARMORY") then
                self.Armory = buildingModel;
            end

            -- Add this to the Mission Table.
            self.Buildings[#self.Buildings + 1] = buildingModel;
        else
            -- Create a substring of the ODF name so we don't do it twice when checking the commander.
            local ODFSubString = string.sub(ODFName, 2, 8);

            -- Set other units to a generic model for control if needed.
            local unitModel = _Unit:New(self.Team, handle, CMD_NONE);

            -- This'll check to see if this is the Commander.
            local isCmdr = (ODFSubString == 'vcmdr_s' or ODFSubString == 'vcmdr_t' or ODFSubString == 'scmdr_p');

            if (isCmdr) then
                -- Set the commander to a unique variable.
                self.Commander = unitModel;
                -- Max out the skill.
                SetSkill(handle, 3);
            else
                -- Check to see if this unit is a turret.
                if (classLabel == "CLASS_TURRETTANK") then
                    self.Turrets[#self.Turrets + 1] = unitModel;
                elseif (baseName == "Patrol") then
                    self.Patrols[#self.Patrols + 1] = unitModel;
                elseif (baseName == "Defender") then
                    self.Defenders[#self.Defenders + 1] = unitModel;
                elseif (classLabel == "CLASS_SCAVENGER" or classLabel == "CLASS_CONSTRUCTIONRIG" or classLabel == "CLASS_SERVICE") then
                    self.Utilities[#self.Utilities + 1] = unitModel;
                else
                    self.Units[#self.Units + 1] = unitModel;
                end
            end
        end
    end
end

function Team:DeleteObject(handle)

end

function Team:Run()
    -- For timers, so we can dispatch turrets every X seconds.
    self.TurnCount = self.TurnCount + 1;

    -- This will mainly handle telling the Commander what to do, and some other things.
    if (self.AICommanderEnabled == 1) then
        self:CommanderBrain();
    end

    -- This will dispatch turrets around the map.
    self:TurretBrain();

    -- This will dispatch patrols around the map.
    self:PatrolBrain();

    -- This will dispatch defenders for the CPU team.
    self:DefenderBrain();
end

-- CPU Functions.
function Team:GiveWeapons(h, ODFName, m_UseStockAIPLogic)
    if (self.Armory ~= nil) then
        local trimmedODF = string.sub(ODFName, 1, 6);

        if (m_UseStockAIPLogic) then
            if (trimmedODF == "ivtank") then
                GiveWeapon(h, "gspstab_c");
            elseif (trimmedODF == "fvtank") then
                GiveWeapon(h, "garc_c");
            end

            local chance = GetRandomFloat(1.0);

            if (trimmedODF == "fvtank" or trimmedODF == "fvsent" or trimmedODF == "fvarch" or trimmedODF == "fvscou") then
                if (chance < 0.3) then
                    GiveWeapon(h, "gshield");
                elseif (chance < 0.6) then
                    GiveWeapon(h, "gabsorb");
                elseif (chance < 0.9) then
                    GiveWeapon(h, "gdeflect");
                end
            end
        else
            -- ISDF weapons.
            -- If we only have an armory and nothing else, default to SP Stabber and Chain Gun.
            if (trimmedODF == "ivtank") then
                GiveWeapon(h, "gspstab_c");
                GiveWeapon(h, "gchain_c");
            elseif (trimmedODF == "ivscou") then
                GiveWeapon(h, "gchain_c");
                GiveWeapon(h, "gshadow_c");
                GiveWeapon(h, "gproxmin");
            elseif (trimmedODF == "ivmisl") then
                -- I think we should only have a 50/50 on giving the missile scout a Shadower, due to Phantom.
                if (GetRandomFloat(1.0) < 0.5) then
                    GiveWeapon(h, "gshadow_c");
                end
                GiveWeapon(h, "gproxmin");
            end
        end
    end
end

function Team:CommanderBrain()
    -- Start by defending the Recycler. Wait until it has deployed.
    if (self.Commander["Command"] == CMD_NONE and IsBuilding(self.Recycler) == false) then
        self.Commander:Defend(self.Recycler);
    end
end

function Team:TurretBrain()
    if (self.TurnCount % SecondsToTurns(2) == 0) then
        -- Are any of our turrets idle without a command?
        for i = 1, #self.Turrets do
            -- Grab the unit.
            local unit = self.Turrets[i];

            -- Check to see if it's a turret, if not, bail.
            if (unit["Command"] == CMD_NONE) then
                -- Find a pool without a guard.
                for j = 1, #self.Pools do
                    -- Grab the pool.
                    local pool = self.Pools[j];
                    -- Do we already have a guard?
                    if (pool["Guard"] == 0) then
                        -- Update the pool's Guard handle.
                        pool["Guard"] = unit;

                        -- Calculate a position for the unit to go to.
                        local pos = GetPositionNear(pool["Position"], 20, 20);

                        -- Send the turret.
                        unit:GoTo(pos);

                        -- We're done if we reach here.
                        break;
                    end
                end
            end
        end
    end
end

function Team:PatrolBrain()
    if (self.TurnCount % SecondsToTurns(3) == 0) then
        -- Are any of the patrol units idle without a command?
        for i = 1, #self.Patrols do
            -- Grab the unit.
            local unit = self.Patrols[i];

            if (unit["Command"] == CMD_NONE) then
                -- Select a random path to send this unit to patrol around.
                local chance = math.ceil(GetRandomFloat(3));
                local path = "patrol_" .. chance;

                -- Send the unit to patrol.
                unit:Patrol(path);
            end
        end
    end
end

function Team:DefenderBrain()
    if (self.TurnCount % SecondsToTurns(3) == 0) then
        -- Are any of the defend units idle without a command?
        for i = 1, #self.Defenders do
            -- Grab the unit.
            local unit = self.Defenders[i];

            if (unit["Command"] == CMD_NONE) then
                -- Find a unit in the utility table to defend.
                local randomUtil = self.Utilities[math.ceil(GetRandomFloat(#self.Utilities))];

                -- Send this unit to defend.
                unit:Defend(randomUtil.Handle);
            end
        end
    end
end

-- Local utilities.
function Compare(a, b)
    return a["DistanceFromCPURecycler"] < b["DistanceFromCPURecycler"];
end

return Team;
