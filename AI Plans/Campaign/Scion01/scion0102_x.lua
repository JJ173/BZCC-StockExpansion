-- CONST VARIABLES FOR SCRAP COST OF UNITS.
local ARMORY_SCRAP_COST = 60;
local APC_SCRAP_COST = 50;
local BUNKER_SCRAP_COST = 50;
local CONST_SCRAP_COST = 40;
local FACTORY_SCRAP_COST = 55;
local GUNTOWER_SCRAP_COST = 50;
local POWER_SCRAP_COST = 30;
local SBAY_SCRAP_COST = 50;
local SCAV_SCRAP_COST = 20;
local SERV_SCRAP_COST = 50;

-- Timers for attack periods.
local EARLY_ATTACK_WINDOW = (25 * 60)

function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

-- MAP CONDITIONS.
function CollectFieldCondition(team, time)
    if (not DoesLooseScrapExist(team, time)) then
        return false, "I cannot find any available loose scrap.";
    end

    return true, "Tasking a Scavenger to collect loose scrap.";
end

function CollectPoolCondition(team, time)
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

function BuildServiceTrucks(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (not DoesServiceBayExist(team, time)) then
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
        return false, "I don't have a Factory so I can't build any Tanks.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker so I can't build any Tanks.";
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

function BuildAPCPatrol(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any deployed Scavengers yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory so I can't build an APC.";
    end

    if (not DoesTrainingExist(team, time)) then
        return false, "I don't have a Training Facility so I can't build an APC.";
    end

    if (AIPUtil.GetScrap(team, false) < APC_SCRAP_COST) then
        return false, "I don't have enough scrap for an APC.";
    end

    return true, "Build APCs to patrol the map...";
end

-- BUILD PLAN CONDITIONS [BUILDINGS]

function BuildPower1(team, time)
    if (not IsPathAvailable("aipgen1")) then
        return false, "aipgen1 is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildPower2(team, time)
    if (not IsPathAvailable("aipgen2")) then
        return false, "aipgen2 is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    if (PowerPlantCount(team, time) <= 0) then
        return false, "I haven't built the first Power Plant yet.";
    end

    if (AIPUtil.GetPower(team, false) > 0) then
        return false, "I have enough Power for now.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildPower3(team, time)
    if (not IsPathAvailable("aipgen3")) then
        return false, "aipgen3 is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    if (PowerPlantCount(team, time) < 2) then
        return false, "I haven't built the first or second Power Plant yet.";
    end

    if (AIPUtil.GetPower(team, false) > 0) then
        return false, "I have enough Power for now.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildPower4(team, time)
    if (not IsPathAvailable("aipgen4")) then
        return false, "aipgen4 is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < POWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Power Plant.";
    end

    if (PowerPlantCount(team, time) < 3) then
        return false, "I haven't built the first, second, or third Power Plant yet.";
    end

    if (AIPUtil.GetPower(team, false) > 0) then
        return false, "I have enough Power for now.";
    end

    return true, "Tasking a Constructor to build a Power Plant...";
end

function BuildRelayBunker(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("aicbun")) then
        return false, "aicbun is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < BUNKER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Relay Bunker.";
    end

    return true, "Tasking a Constructor to build a Relay Bunker at main base...";
end

function BuildGunTower1(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (IsPathAvailable("aigtow1") == false) then
        return false, "aigtow1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at aigtow1...";
end

function BuildGunTower2(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (IsPathAvailable("aigtow2") == false) then
        return false, "aigtow2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at aigtow2...";
end

function BuildGunTower3(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (IsPathAvailable("aigtow3") == false) then
        return false, "aigtow3 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at aigtow3...";
end

function BuildFactory(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("aifact")) then
        return false, "aifact is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < FACTORY_SCRAP_COST) then
        return false, "I don't have enough scrap for a Factory.";
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough power for a Factory.";
    end

    return true, "Tasking a Constructor to build a Factory...";
end

function BuildArmory(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("aiarmo")) then
        return false, "aiarmo is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.GetScrap(team, false) < ARMORY_SCRAP_COST) then
        return false, "I don't have enough scrap for an Armory.";
    end

    return true, "Tasking a Constructor to build an Armory...";
end

function BuildServiceBay(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("aisbay")) then
        return false, "aisbay is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (AIPUtil.GetScrap(team, false) < SBAY_SCRAP_COST) then
        return false, "I don't have enough scrap for a Service Bay.";
    end

    return true, "Tasking a Constructor to build a Service Bay...";
end

function BuildFieldBunker(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not IsPathAvailable("field_bunker")) then
        return false, "field_bunker is unavailable, or a building already exists on it."
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (AIPUtil.GetScrap(team, false) < BUNKER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Relay Bunker.";
    end

    return true, "Tasking a Constructor to build a Relay Bunker at field_bunker...";
end

function BuildFieldTower1(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (not AIPUtil.PathBuildingExists("field_bunker")) then
        return false, "I haven't build the Field Bunker yet."
    end

    if (not IsPathAvailable("field_tower_1")) then
        return false, "field_tower_1 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at field_tower_1...";
end

function BuildFieldTower2(team, time)
    if (ExtractorCount(team, time) < 1) then
        return false, "I don't have enough deployed Scavengers yet.";
    end

    if (not DoesConstructorExist(team, time)) then
        return false, "I don't have a Constructor yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have a Relay Bunker yet.";
    end

    if (not AIPUtil.PathBuildingExists("field_bunker")) then
        return false, "I haven't build the Field Bunker yet."
    end

    if (not IsPathAvailable("field_tower_2")) then
        return false, "field_tower_2 is unavailable, or a building already exists on it."
    end

    if (AIPUtil.GetPower(team, false) <= 0) then
        return false, "I don't have enough Power for a Gun Tower.";
    end

    if (AIPUtil.GetScrap(team, false) < GUNTOWER_SCRAP_COST) then
        return false, "I don't have enough scrap for a Gun Tower.";
    end

    return true, "Tasking a Constructor to build a Gun Tower at field_tower_2...";
end

-- COUNT FUNCTIONS TO CHECK IF A NUMBER OF GAME OBJECT EXISTS.

function ScavengerCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", "sameteam", true);
end

function ExtractorCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", "sameteam", true);
end

function PowerPlantCount(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_POWERPLANT", "sameteam", true);
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

-- ATTACKER PLAN CONDITIONS.

function ShouldSendEarlyAttacks(team, time)
    if (time > EARLY_ATTACK_WINDOW) then
        return false, "Mission has progressed. Need to send heavier attacks."
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_OVERSEER_ARRAY", 'enemy', true) > 0) then
        return false, "Enemy has good tech. Resort to heavier attacks."
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) > 3) then
        return false, "Enemy has too many defenses. Resort to heavier attacks..";
    end

    return true, "I can send some early attacks."
end

function EarlyScavengerAttackCondition(team, time)
    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    return true, "Send Scouts to harass enemy Scavengers early.";
end

function EarlyTurretAttackCondition(team, time)
    if (not ShouldSendEarlyAttacks(team, time)) then
        return false, "Mission has progressed. Need to send heavier attacks."
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesArmoryExist(team, time)) then
        return false, "I don't have an Armory yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", 'enemy', true) <= 0) then
        return false, "Enemy doesn't have any defenses to target.";
    end

    return true, "Enemies has Turrets. I'll send some Mortar Bikes to attack.";
end

function EarlyGunSpireAttackCondition(team, time)
    if (not ShouldSendEarlyAttacks(team, time)) then
        return false, "Mission has progressed. Need to send heavier attacks."
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have an Armory yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) <= 0) then
        return false, "Enemy doesn't have any defenses to target.";
    end

    return true, "Enemies has Gun Towers. I'll send some Tanks to attack.";
end

function EarlyGunSpireAssaultAttackCondition(team, time)
    if (not ShouldSendEarlyAttacks(team, time)) then
        return false, "Mission has progressed. Need to send heavier attacks."
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have an Armory yet.";
    end

    if (not DoesServiceBayExist(team, time)) then
        return false, "I don't have a Service Bay yet.";
    end

    if (AIPUtil.CountUnits(team, "VIRTUAL_CLASS_GUNTOWER", 'enemy', true) <= 0) then
        return false, "Enemy doesn't have any defenses to target.";
    end

    return true, "Enemies has Gun Towers. I'll send some Assault Tanks to attack.";
end

function EarlyAPCAttackCondition(team, time)
    if (not ShouldSendEarlyAttacks(team, time)) then
        return false, "Mission has progressed. Need to send heavier attacks."
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesTrainingExist(team, time)) then
        return false, "I don't have a Training Facility yet.";
    end

    return true, "Send APC to probe enemy base to keep things interesting.";
end

function LateAssaultTankAttackCondition(team, time)
    if (ShouldSendEarlyAttacks(team, time)) then
        return false, "Too early in the mission for this attack.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have an Armory yet.";
    end

    if (not DoesServiceBayExist(team, time)) then
        return false, "I don't have a Service Bay yet.";
    end

    return true, "It's Late. I'll send some Assault Tanks to attack.";
end

function LateAPCAttackCondition(team, time)
    if (ShouldSendEarlyAttacks(team, time)) then
        return false, "Too early in the mission for this attack.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesTrainingExist(team, time)) then
        return false, "I don't have a Training Facility yet.";
    end

    return true, "It's Late. I'll send APCs to probe enemy base to keep things interesting.";
end

function LateTankAttackCondition(team, time)
    if (ShouldSendEarlyAttacks(team, time)) then
        return false, "Too early in the mission for this attack.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have an Armory yet.";
    end

    if (AIPUtil.CountUnits(team, "DefendUnit", 'enemy', true) <= 0) then
        return false, "Enemy doesn't have any units to target.";
    end

    return true, "Sending late tank attacks to thin out enemy forces.";
end

function LateAssaultAirCounterCondition(team, time)
    if (ShouldSendEarlyAttacks(team, time)) then
        return false, "Too early in the mission for this attack.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesTrainingExist(team, time)) then
        return false, "I don't have a Training Facility yet.";
    end

    if (AIPUtil.CountUnits(team, "assault", 'enemy', true) <= 0) then
        return false, "Enemy doesn't have any units to target.";
    end

    return true, "It's Late. I'll send APCs to probe enemy assault units to keep things interesting.";
end

function LateAssaultHeavyCounterCondition(team, time)
    if (ShouldSendEarlyAttacks(team, time)) then
        return false, "Too early in the mission for this attack.";
    end

    if (ExtractorCount(team, time) <= 0) then
        return false, "I don't have any Extractors yet.";
    end

    if (not DoesFactoryExist(team, time)) then
        return false, "I don't have a Factory yet.";
    end

    if (not DoesRelayBunkerExist(team, time)) then
        return false, "I don't have an Armory yet.";
    end

    if (not DoesArmoryExist(team, time)) then
        return false, "I don't have an Armory yet.";
    end

    if (not DoesServiceBayExist(team, time)) then
        return false, "I don't have a Service Bay yet.";
    end

    if (AIPUtil.CountUnits(team, "assault", 'enemy', true) <= 0) then
        return false, "Enemy doesn't have any units to target.";
    end

    return true, "Sending late anti-assault attacks to thin out enemy forces.";
end

-- BOOLEAN FUNCTIONS TO CHECK IF A SINGULAR GAME OBJECT EXISTS.

function IsPathAvailable(pathName)
    if (not AIPUtil.PathExists(pathName)) then
        return false;
    elseif (AIPUtil.PathBuildingExists(pathName)) then
        return false;
    end

    return true;
end

function DoesRecyclerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLERBUILDING", "sameteam", true) > 0;
end

function DoesFactoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FACTORY", "sameteam", true) > 0;
end

function DoesArmoryExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_ARMORY", "sameteam", true) > 0;
end

function DoesRelayBunkerExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_COMMBUNKER", "sameteam", true) > 0;
end

function DoesServiceBayExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SUPPLYDEPOT", "sameteam", true) > 0;
end

function DoesConstructorExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_CONSTRUCTIONRIG", "sameteam", true) > 0;
end

function DoesTrainingExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_BARRACKS", "sameteam", true) > 0;
end