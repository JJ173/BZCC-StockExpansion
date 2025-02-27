-- CONST VARIABLES FOR SCRAP COST OF UNITS.
local ANTENNA_SCRAP_COST = 60;
local ARCHER_SCRAP_COST = 33;
local CONST_SCRAP_COST = 20;
local FORGE_SCRAP_COST = 60;
local GUN_SPIRE_COST = 75;
local KILN_SCRAP_COST = 60;
local OVERSEER_SCRAP_COST = 80;
local SCAV_SCRAP_COST = 10;
local SENTRY_SCRAP_COST = 25;
local SCOUT_SCRAP_COST = 23;
local TURRET_SCRAP_COST = 20;
local WARRIOR_SCRAP_COST = 28;

function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua Conditions for Scion AIP bzcc_x_f0");
end

-- MAP CONDITIONS.
function CollectFieldCondition(team, time)
    if (ScavengerCount(team, time) <= 0) then
        return false, "I don't have any Scavengers.";
    end

    if (DoesLooseScrapExist(team, time) == false) then
        return false, "I cannot find any available loose scrap.";
    end

    return true, "Tasking a Scavenger to collect loose scrap.";
end

function CollectPoolCondition(team, time)
    if (ScavengerCount(team, time) <= 0) then
        return false, "I don't have any Scavengers.";
    end

    if (DoesScrapPoolExist(team, time) == false) then
        return false, "I cannot find any available scrap pools.";
    end

    return true, "Tasking a Scavenger to collect a pool.";
end

function DoesLooseScrapExist(team, time)
    return AIPUtil.CountUnits(team, "resource", "friendly", true) > 0;
end

function DoesScrapPoolExist(team, time)
    return AIPUtil.CountUnits(team, "biometal", "friendly", true) > 0;
end

-- BUILD PLAN CONDITIONS [UNITS]
function BuildScavengerCondition(team, time)
    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (ScavengerCount(team, time) >= 3) then
        return false, "I already have enough Scavengers.";
    end

    if (AIPUtil.GetScrap(team, false) < SCAV_SCRAP_COST) then
        return false, "I don't have enough scrap for a Scavenger.";
    end

    return true, "Tasking Recycler to build a Scavenger.";
end

function BuildConstructorCondition(team, time)
    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (AIPUtil.GetScrap(team, false) < CONST_SCRAP_COST) then
        return false, "I don't have enough scrap for a Constructor.";
    end

    return true, "Tasking Recycler to build a Constructor.";
end

function BuildTurretCondition(team, time)
    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (AIPUtil.GetScrap(team, false) < TURRET_SCRAP_COST) then
        return false, "I don't have enough scrap for a Turret.";
    end

    return true, "Tasking Recycler to build a Turret.";
end

function BuildScoutCondition(team, time)
    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time)) then
        return false, "I have a Factory so I can build better Patrol/Defender unit.";
    end

    if (AIPUtil.GetScrap(team, false) < SCOUT_SCRAP_COST) then
        return false, "I don't have enough scrap for a Scout.";
    end

    return true, "Tasking Recycler to build a Scout."
end

function BuildSentryCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.GetScrap(team, false) < SENTRY_SCRAP_COST) then
        return false, "I don't have enough scrap for a Sentry.";
    end

    return true, "Tasking Kiln/Forge to build a Sentry."
end

function BuildTankCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesForgeExist(team, time) == false) then
        return false, "I don't have a Forge so I can't build any Warriors.";
    end

    if (AIPUtil.GetScrap(team, false) < WARRIOR_SCRAP_COST) then
        return false, "I don't have enough scrap for a Warrior.";
    end

    return true, "Tasking Factory to build a Warrior.";
end

function BuildScoutCommander(team, time)
    if (IsCommanderOptionEnabled(team, time) == false) then
        return false, "Commander option is disabled for this game.";
    end

    if (DoesRecyclerExist(team, time) == false) then
        return false, "I don't have a Recycler yet.";
    end

    if (DoesFactoryExist(team, time) and DoesRelayBunkerExist(team, time)) then
        return false, "I have a Factory so I can build a better Commander unit.";
    end

    return true, "I can replace the Commander in a Scout unit. Tasking Recycler to build.";
end

function BuildTankCommander(team, time)
    if (IsCommanderOptionEnabled(team, time) == false) then
        return false, "Commander option is disabled for this game.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Factory yet.";
    end

    if (DoesRelayBunkerExist(team, time) == false) then
        return false, "I don't have a Relay Bunker yet.";
    end

    return true, "I can replace the Commander in a Tank unit. Tasking Factory to build.";
end

function BuildArcherCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (DoesForgeExist(team, time) == false) then
        return false, "I don't have a Forge so I can't build any Archers.";
    end

    if (DoesOverseerExist(team, time) == false) then
        return false, "I don't have an Overseer so I can't build any Archers.";
    end

    if (AIPUtil.GetScrap(team, false) < ARCHER_SCRAP_COST) then
        return false, "I don't have enough scrap for an Archer.";
    end

    return true, "Tasking Factory to build an Archer.";
end

-- UPGRADE CONDITIONS
function UpgradeKilnCondition(team, time)
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (AIPUtil.GetScrap(team, false) < FORGE_SCRAP_COST) then
        return false, "I don't have enough scrap to upgrade the Kiln.";
    end

    return true, "Tasking Constructor to upgrade the Kiln.";
end

function UpgradeAntennaCondition(team, time)
    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Antenna yet.";
    end

    if (ExtractorCount(team, time) <= 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (AIPUtil.GetScrap(team, false) < OVERSEER_SCRAP_COST) then
        return false, "I don't have enough scrap to upgrade the Antenna.";
    end

    return true, "Tasking Constructor to upgrade the Antenna.";
end

-- BUILD PLAN CONDITIONS [BUILDINGS]
function BuildKiln(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (IsPathAvailable("F_Forge") == false) then
        return false, "F_Forge is unavailable, or a building already exists on it."
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < KILN_SCRAP_COST) then
        return false, "I don't have enough scrap for a Kiln.";
    end

    return true, "Tasking a Constructor to build a Kiln...";
end

function BuildAntenna(team, time)
    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Kiln yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (IsPathAvailable("F_Overseer") == false) then
        return false, "F_Overseer is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ANTENNA_SCRAP_COST) then
        return false, "I don't have enough scrap for an Antenna.";
    end

    return true, "Tasking a Constructor to build an Antenna...";
end

function BuildDower(team, time)
    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Kiln yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (IsPathAvailable("F_Overseer") == false) then
        return false, "F_Overseer is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ANTENNA_SCRAP_COST) then
        return false, "I don't have enough scrap for an Antenna.";
    end

    return true, "Tasking a Constructor to build an Antenna...";
end

function BuildGunSpire1(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (IsPathAvailable("F_BaseSpire_1") == false) then
        return false, "F_BaseSpire_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < GUN_SPIRE_COST) then
        return false, "I don't have enough scrap for a Gun Spire.";
    end

    return true, "Tasking a Constructor to build a Gun Spire at F_BaseSpire_1...";
end

function BuildGunSpire2(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesConstructorExist(team, time) == false) then
        return false, "I don't have a Constructor yet.";
    end

    if (IsPathAvailable("F_BaseSpire_2") == false) then
        return false, "F_BaseSpire_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < GUN_SPIRE_COST) then
        return false, "I don't have enough scrap for a Gun Spire.";
    end

    return true, "Tasking a Constructor to build a Gun Spire at F_BaseSpire_2...";
end

-- COUNT FUNCTIONS TO CHECK IF A NUMBER OF GAME OBJECT EXISTS.
function ScavengerCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", "sameteam", true);
end

function ExtractorCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", "sameteam", true);
end

-- ATTACKER PLAN CONDITIONS.
function Attack1Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) > 0) then
        return false, "Enemy defenses are too strong.";
    end

    return true, "First attack is being sent.";
end

function Attack2Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Kiln/Forge yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) > 0) then
        return false, "Enemy defenses are too strong.";
    end

    return true, "Second attack is being sent.";
end

function Attack3Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (DoesFactoryExist(team, time) == false) then
        return false, "I don't have a Kiln/Forge yet.";
    end

    if (DoesAntennaExist(team, time) == false) then
        return false, "I don't have an Antenna yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) <= 0 and AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", 'enemy', true) <= 0) then
        return false, "Enemy doesn't have any defenses to target.";
    end

    return true, "Enemies has Gun Towers / Turrets. I'll send some Lancers to attack.";
end

-- BOOLEAN FUNCTIONS TO CHECK IF A SINGULAR GAME OBJECT EXISTS.
function IsCommanderOptionEnabled(team, time)
    return AIPUtil.GetVarItemInt("options.instant.bool2") == 1;
end

function IsPathAvailable(pathName)
    if (AIPUtil.PathExists(pathName) == false) then
        return false;
    elseif (AIPUtil.PathBuildingExists(pathName)) then
        return false;
    end

    return true;
end

function DoesConstructorExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", "sameteam", true) > 0;
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", "sameteam", true) > 0;
end

function DoesFactoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FACTORY", "sameteam", true) > 0;
end

function DoesForgeExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FORGE", "sameteam", true) > 0;
end

function DoesAntennaExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_ANTENNA_MOUND", "sameteam", true) > 0;
end

function DoesOverseerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_OVERSEER_ARRAY", "sameteam", true) > 0;
end
