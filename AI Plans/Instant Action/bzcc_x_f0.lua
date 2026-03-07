-- CONST VARIABLES FOR SCRAP COST OF UNITS.
local ANTENNA_SCRAP_COST = 60;
local ARCHER_SCRAP_COST = 33;
local ARTILLERY_SCRAP_COST = 80;
local ASSAULT_SPIRE_COST = 95;
local CONST_SCRAP_COST = 20;
local DOWER_SCRAP_COST = 50;
local FORGE_SCRAP_COST = 60;
local GUN_SPIRE_COST = 75;
local JAMMER_COST = 50;
local KILN_SCRAP_COST = 60;
local LANDING_PAD_COST = 60;
local OVERSEER_SCRAP_COST = 80;
local ROCKET_SPIRE_COST = 75;
local SCAV_SCRAP_COST = 10;
local SENTRY_SCRAP_COST = 25;
local SERV_SCRAP_COST = 25;
local SCOUT_SCRAP_COST = 23;
local STRONGHOLD_SCRAP_COST = 70;
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

    if (not DoesLooseScrapExist(team, time)) then
        return false, "I cannot find any available loose scrap.";
    end

    return true, "Tasking a Scavenger to collect loose scrap.";
end

function CollectPoolCondition(team, time)
    if (ScavengerCount(team, time) <= 0) then
        return false, "I don't have any Scavengers.";
    end

    if (not DoesScrapPoolExist(team, time)) then
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
    if (not DoesRecyclerExist(team, time)) then
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
    if (not DoesRecyclerExist(team, time)) then
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
    if (not DoesRecyclerExist(team, time)) then
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
    if (not DoesRecyclerExist(team, time)) then
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

    if (not DoesFactoryExist(team, time)) then
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

    if (not DoesForgeExist(team, time)) then
        return false, "I don't have a Forge so I can't build any Warriors.";
    end

    if (AIPUtil.GetScrap(team, false) < WARRIOR_SCRAP_COST) then
        return false, "I don't have enough scrap for a Warrior.";
    end

    return true, "Tasking Factory to build a Warrior.";
end

function BuildScoutCommander(team, time)
    if (not IsCommanderOptionEnabled(team, time)) then
        return false, "Commander option is disabled for this game.";
    end

    if (not DoesRecyclerExist(team, time)) then
        return false, "I don't have a Recycler yet.";
    end

    if (DoesForgeExist(team, time)) then
        return false, "I have a Forge so I can build a better Commander unit.";
    end

    return true, "I can replace the Commander in a Scout unit. Tasking Recycler to build.";
end

function BuildScoutLt(team, time)
    if (not IsCommanderOptionEnabled(team, time)) then
        return false, "Commander option is disabled for this game.";
    end

    local playerCount = GetPlayerCount(team, time)

    if (playerCount == nil or playerCount <= 1) then
        return false, "Not enough players to counter attack.";
    end

    if (LtUnitCount(team, time) >= playerCount - 1) then
        return false, "I have enough Lieutenant units to counter players for now.";
    end

    return true, "Attempting to counter a player with a Lieutenant craft.";
end

function BuildTankCommander(team, time)
    if (not IsCommanderOptionEnabled(team, time)) then
        return false, "Commander option is disabled for this game.";
    end

    if (not DoesForgeExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    return true, "I can replace the Commander in a Tank unit. Tasking Factory to build.";
end

function BuildArcherCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (not DoesForgeExist(team, time)) then
        return false, "I don't have a Forge so I can't build any Archers.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer so I can't build any Archers.";
    end

    if (AIPUtil.GetScrap(team, false) < ARCHER_SCRAP_COST) then
        return false, "I don't have enough scrap for an Archer.";
    end

    return true, "Tasking Factory to build an Archer.";
end

function BuildServiceTrucks(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (not DoesDowerExist(team, time)) then
        return false, "I don't have a Service Bay yet.";
    end

    if (not DoesRecyclerExist(team, time)) then
        return false, "I don't have a Recycler yet.";
    end

    if (AIPUtil.GetScrap(team, false) < SERV_SCRAP_COST) then
        return false, "I don't have enough scrap for a Service Truck.";
    end

    return true, "Tasking Recycler to build Service Trucks...";
end

function BuildAssaultDefenders(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory so I can't build any Sentries.";
    end

    local assaultCount = AssaultUnitCount(team, time);

    if (assaultCount <= 0) then
        return false, "I don't have any assault units yet.";
    end

    if (DefenderUnitCount(team, time) >= assaultCount) then
        return false, "I have enough defenders for my Assault Units for now.";
    end

    return true, "Building units to defend assault units.";
end

function BuildAssaultServicers(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (not DoesDowerExist(team, time)) then
        return false, "I don't have a Factory so I can't build any Tanks.";
    end

    local assaultCount = AssaultUnitCount(team, time);

    if (assaultCount <= 0) then
        return false, "I don't have any assault units yet.";
    end

    if (AssaultServiceUnitCount(team, time) >= assaultCount) then
        return false, "I have enough servicers for my Assault Units for now.";
    end

    return true, "Building units to service assault units.";
end

-- UPGRADE CONDITIONS
function UpgradeKilnCondition(team, time)
    if (not DoesConstructorExist(team, time)) then
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
    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
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

    if (not IsPathAvailable("F_Forge")) then
        return false, "F_Forge is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < KILN_SCRAP_COST) then
        return false, "I don't have enough scrap for a Kiln.";
    end

    return true, "Tasking a Constructor to build a Kiln...";
end

function BuildAntenna(team, time)
    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Kiln yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("F_Overseer")) then
        return false, "F_Overseer is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ANTENNA_SCRAP_COST) then
        return false, "I don't have enough scrap for an Antenna.";
    end

    return true, "Tasking a Constructor to build an Antenna...";
end

function BuildDower(team, time)
    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Kiln yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("F_Dower")) then
        return false, "F_Dower is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < DOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Dower.";
    end

    return true, "Tasking a Constructor to build a Dower...";
end

function BuildStronghold(team, time)
    if (not DoesForgeExist(team, time)) then
        return false, "I don't have a Forge yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("F_Stronghold")) then
        return false, "F_Stronghold is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < STRONGHOLD_SCRAP_COST) then
        return false, "I don't have enough scrap for a Stronghold.";
    end

    return true, "Tasking a Constructor to build a Stronghold...";
end

function BuildGunSpire1(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_BaseSpire_1")) then
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

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_BaseSpire_2")) then
        return false, "F_BaseSpire_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < GUN_SPIRE_COST) then
        return false, "I don't have enough scrap for a Gun Spire.";
    end

    return true, "Tasking a Constructor to build a Gun Spire at F_BaseSpire_2...";
end

function BuildGunSpire3(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_BaseSpire_3")) then
        return false, "F_BaseSpire_3 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < GUN_SPIRE_COST) then
        return false, "I don't have enough scrap for a Gun Spire.";
    end

    return true, "Tasking a Constructor to build a Gun Spire at F_BaseSpire_3...";
end

function BuildBaseAntiAir1(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Base_AntiAir_1")) then
        return false, "F_Base_AntiAir_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ROCKET_SPIRE_COST) then
        return false, "I don't have enough scrap for a Rocket Spire.";
    end

    return true, "Tasking a Constructor to build a Rocket Spire at F_Base_AntiAir_1...";
end

function BuildBaseAntiAir2(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Base_AntiAir_2")) then
        return false, "F_Base_AntiAir_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ROCKET_SPIRE_COST) then
        return false, "I don't have enough scrap for a Rocket Spire.";
    end

    return true, "Tasking a Constructor to build a Rocket Spire at F_Base_AntiAir_2...";
end

function BuildBaseAntiAir3(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Base_AntiAir_3")) then
        return false, "F_Base_AntiAir_3 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ROCKET_SPIRE_COST) then
        return false, "I don't have enough scrap for a Rocket Spire.";
    end

    return true, "Tasking a Constructor to build a Rocket Spire at F_Base_AntiAir_3...";
end

function BuildBaseAssaultSpire1(team, time)
    if (ExtractorCount(team, time) < 3) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Base_AssaultSpire_1")) then
        return false, "F_Base_AssaultSpire_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ASSAULT_SPIRE_COST) then
        return false, "I don't have enough scrap for an Assault Spire.";
    end

    return true, "Tasking a Constructor to build an Assault Spire at F_Base_AssaultSpire_1...";
end

function BuildBaseAssaultSpire2(team, time)
    if (ExtractorCount(team, time) < 3) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Base_AssaultSpire_2")) then
        return false, "F_Base_AssaultSpire_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ASSAULT_SPIRE_COST) then
        return false, "I don't have enough scrap for an Assault Spire.";
    end

    return true, "Tasking a Constructor to build an Assault Spire at F_Base_AssaultSpire_2...";
end

function BuildBaseAssaultSpire3(team, time)
    if (ExtractorCount(team, time) < 3) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Base_AssaultSpire_3")) then
        return false, "F_Base_AssaultSpire_3 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ASSAULT_SPIRE_COST) then
        return false, "I don't have enough scrap for an Assault Spire.";
    end

    return true, "Tasking a Constructor to build an Assault Spire at F_Base_AssaultSpire_3...";
end

function BuildFieldAssaultSpire1(team, time)
    if (ExtractorCount(team, time) < 3) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Field_AssaultSpire_1")) then
        return false, "F_Field_AssaultSpire_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ASSAULT_SPIRE_COST) then
        return false, "I don't have enough scrap for an Assault Spire.";
    end

    return true, "Tasking a Constructor to build an Assault Spire at F_Field_AssaultSpire_1...";
end

function BuildFieldAssaultSpire2(team, time)
    if (ExtractorCount(team, time) < 3) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Field_AssaultSpire_2")) then
        return false, "F_Field_AssaultSpire_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ASSAULT_SPIRE_COST) then
        return false, "I don't have enough scrap for an Assault Spire.";
    end

    return true, "Tasking a Constructor to build an Assault Spire at F_Field_AssaultSpire_2...";
end

function BuildFieldAssaultSpire3(team, time)
    if (ExtractorCount(team, time) < 3) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Field_AssaultSpire_3")) then
        return false, "F_Field_AssaultSpire_3 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ASSAULT_SPIRE_COST) then
        return false, "I don't have enough scrap for an Assault Spire.";
    end

    return true, "Tasking a Constructor to build an Assault Spire at F_Field_AssaultSpire_3...";
end

function BuildFieldAssaultSpire4(team, time)
    if (ExtractorCount(team, time) < 3) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not IsPathAvailable("F_Field_AssaultSpire_4")) then
        return false, "F_Field_AssaultSpire_4 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ASSAULT_SPIRE_COST) then
        return false, "I don't have enough scrap for an Assault Spire.";
    end

    return true, "Tasking a Constructor to build an Assault Spire at F_Field_AssaultSpire_4...";
end

function BuildLandingPad(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (DoesLandingPadExist(team, time)) then
        return false, "I already have a Landing Pad.";
    end

    if (not IsPathAvailable("i_LandingPad")) then
        return false, "i_LandingPad is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesForgeExist(team, time)) then
        return false, "I should prioritise the Forge first.";
    end

    if (AIPUtil.GetScrap(team, false) < LANDING_PAD_COST) then
        return false, "I don't have enough scrap for a Landing Pad.";
    end

    return true, "Tasking a Constructor to build a Landing Pad...";
end

function BuildJammer1(team, time)
    if (GetDifficultyLevel() < 2) then
        return false, "Jammers are only built on Medium and Hard difficulties.";
    end

    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not IsPathAvailable("F_BaseJammer_1")) then
        return false, "F_BaseJammer_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < JAMMER_COST) then
        return false, "I don't have enough scrap for a Jammer.";
    end

    return true, "Tasking a Constructor to build a Jammer at F_BaseJammer_1...";
end

function BuildJammer2(team, time)
    if (GetDifficultyLevel() < 2) then
        return false, "Jammers are only built on Medium and Hard difficulties.";
    end

    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not IsPathAvailable("F_BaseJammer_2")) then
        return false, "F_BaseJammer_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < JAMMER_COST) then
        return false, "I don't have enough scrap for a Jammer.";
    end

    return true, "Tasking a Constructor to build a Jammer at F_BaseJammer_2...";
end

function BuildBaseArtillery1(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not IsPathAvailable("F_Base_Artillery_1")) then
        return false, "F_Base_Artillery_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ARTILLERY_SCRAP_COST) then
        return false, "I don't have enough scrap for an Artillery Building.";
    end

    return true, "Tasking a Constructor to build an Artillery Building at F_Base_Artillery_1...";
end

function BuildBaseArtillery2(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not IsPathAvailable("F_Base_Artillery_2")) then
        return false, "F_Base_Artillery_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ARTILLERY_SCRAP_COST) then
        return false, "I don't have enough scrap for an Artillery Building.";
    end

    return true, "Tasking a Constructor to build an Artillery Building at F_Base_Artillery_2...";
end

function BuildFieldRocketTower1(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not IsPathAvailable("F_Field_RocketTower_1")) then
        return false, "F_Field_RocketTower_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ROCKET_SPIRE_COST) then
        return false, "I don't have enough scrap for a Rocket Spire.";
    end

    return true, "Tasking a Constructor to build a Rocket Spire at F_Field_RocketTower_1...";
end

function BuildFieldRocketTower2(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not IsPathAvailable("F_Field_RocketTower_2")) then
        return false, "F_Field_RocketTower_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ROCKET_SPIRE_COST) then
        return false, "I don't have enough scrap for a Rocket Spire.";
    end

    return true, "Tasking a Constructor to build a Rocket Spire at F_Field_RocketTower_2...";
end

function BuildFieldRocketTower3(team, time)
    if (ExtractorCount(team, time) < 2) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not IsPathAvailable("F_Field_RocketTower_3")) then
        return false, "F_Field_RocketTower_3 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetScrap(team, false) < ROCKET_SPIRE_COST) then
        return false, "I don't have enough scrap for a Rocket Spire.";
    end

    return true, "Tasking a Constructor to build a Rocket Spire at F_Field_RocketTower_3...";
end

-- COUNT FUNCTIONS TO CHECK IF A NUMBER OF GAME OBJECT EXISTS.
function ScavengerCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", "sameteam", true);
end

function ExtractorCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", "sameteam", true);
end

function AssaultUnitCount(team, time)
    return AIPUtil.CountUnits(team, "assault", "sameteam", true);
end

function DefenderUnitCount(team, time)
    return AIPUtil.CountUnits(team, "AssaultDefender", "sameteam", true);
end

function AssaultServiceUnitCount(team, time)
    return AIPUtil.CountUnits(team, "AssaultServicer", "sameteam", true);
end

function LtUnitCount(team, time)
    return AIPUtil.CountUnits(team, "Lieutenant", "sameteam", true);
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

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Kiln/Forge yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) > 0) then
        return false, "Enemy defenses are too strong.";
    end

    return true, "Second attack is being sent.";
end

function LancerAttackCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Kiln/Forge yet.";
    end

    if (not DoesAntennaExist(team, time)) then
        return false, "I don't have an Antenna yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) <= 0 and AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", 'enemy', true) <= 0) then
        return false, "Enemy doesn't have any defenses to target.";
    end

    return true, "Enemies has Gun Towers / Turrets. I'll send some Lancers to attack.";
end

function ArcherAttackCondition(team, time)
    if (not BuildArcherCondition(team, time)) then
        return false;
    end

    return true, "Tasking Archers to clear assault and defenders.";
end

function Attack5Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesForgeExist(team, time)) then
        return false, "I don't have a Forge yet.";
    end

    return true, "Fifth attack is being sent.";
end

function Attack6Condition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesForgeExist(team, time)) then
        return false, "I don't have a Forge yet.";
    end

    if (not DoesDowerExist(team, time)) then
        return false, "I don't have a Dower yet.";
    end

    if (not DoesStrongholdExist(team, time)) then
        return false, "I don't have a Stronghold yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) <= 3) then
        return false, "Enemy doesn't have enough Gun Towers to target.";
    end

    return true, "Sending Maulers to attack Gun Towers.";
end

function LateAttackCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesForgeExist(team, time)) then
        return false, "I don't have a Forge yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not DoesStrongholdExist(team, time)) then
        return false, "I don't have a Stronghold yet.";
    end

    return true, "Seventh attack is being sent.";
end

function FuryAttackCondition(team, time)
    if (time < 900) then
        return false, "We haven't been playing for 15 minutes. I can't build a Fury yet.";
    end

    if (not DoesForgeExist(team, time)) then
        return false, "I don't have a Forge yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not DoesStrongholdExist(team, time)) then
        return false, "I don't have a Stronghold yet.";
    end

    return true, "Sending a Fury to attack.";
end

function FurySecondAttackCondition(team, time)
    if (time < 1200) then
        return false, "We haven't been playing for 20 minutes. I can't build a second Fury yet.";
    end

    if (not DoesForgeExist(team, time)) then
        return false, "I don't have a Forge yet.";
    end

    if (not DoesOverseerExist(team, time)) then
        return false, "I don't have an Overseer yet.";
    end

    if (not DoesStrongholdExist(team, time)) then
        return false, "I don't have a Stronghold yet.";
    end

    return true, "Sending a Fury to attack.";
end

-- BOOLEAN FUNCTIONS TO CHECK IF A SINGULAR GAME OBJECT EXISTS.
function IsCommanderOptionEnabled(team, time)
    return AIPUtil.GetVarItemInt("options.instant.aiCommander") == 1 or AIPUtil.GetVarItemInt("network.session.ivar124") == 1;
end

function GetPlayerCount(team, time)
    return AIPUtil.GetVarItemInt("network.session.ivar64");
end

function GetDifficultyLevel(team, time)
    return AIPUtil.GetVarItemInt("options.instant.difficulty");
end

function IsPathAvailable(pathName)
    if (not AIPUtil.PathExists(pathName)) then
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

function DoesStrongholdExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_ARMORY", "sameteam", true) > 0;
end

function DoesDowerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SUPPLYDEPOT", "sameteam", true) > 0;
end

function DoesLandingPadExist(team, time)
    return AIPUtil.CountUnits(team, "LandingPad", "sameteam", true) > 0;
end