function InitAIPLua(team, time)
    AIPUtil.print(team, "Starting Lua condition checker for team: " .. team);
end

-- Function to make sure the CPU has enough Scavengers to do the job.
function ScavengerCondition(team, time)
    -- First check if the Recycler exists.
    local doesRecyclerExist = CheckRecyclerExists(team, time);

    if (doesRecyclerExist) then
        -- If we don't have a factory, only maintain 2 Scavs.
        local doesFactoryExist = CheckFactoryExists(team, time);

        -- Scav count.
        local scavCount = 0;

        if (doesFactoryExist == false) then
            scavCount = 2;
        else
            -- Check if an armory exists.
            local doesArmoryExist = CheckArmoryExists(team, time);

            if (doesArmoryExist == false) then
                scavCount = 3;
            else
                scavCount = 4;
            end
        end

        return CountScavengers(team, time) < scavCount;
    end

    -- Recycler doesn't exist, we can't do this.
    return false;
end

-- Function to collect loose.
function CollectFieldCondition(team, time)
    return CountLooseScrap(team, time) > 0;
end

-- Function to build a service pod.
function ServicePodCondition(team, time)
    return (CheckRecyclerExists(team, time) and CheckServiceBayExists(team, time) == false and AIPUtil.CountUnits(team, "apserv", 'sameteam', true) <= 0);
end

-- Function to send a unit if a service pod exists.
function ServicePodRecoverFunction(team, time)
    return (AIPUtil.CountUnits(team, "apserv", 'sameteam', true) > 0);
end

-- Check to make sure we have at least 1 pool before building this.
function BaseConstructorCondition(team, time)
    return CheckRecyclerExists(team, time) and CountExtractors(team, time) > 0;
end

-- Build these after the factory exists so we can start map control.
function GunTowerConstructorCondition(team, time)
    return CheckRecyclerExists(team, time) and CheckFactoryExists(team, time) and CountExtractors(team, time) > 0;
end

-- I think it's fine if the CPU dispatches turrets before it builds a factory, or if the player is limited to 1 pool.
function PoolTurretCondition(team, time)
    -- Start with 2 for now for early game.
    local turretCount = CountTurrets(team, time);

    -- We count 5 as we need to include the paths that spawn turrets as well.
    if (turretCount < 5) then
        -- Obviously we need our Recycler to build these.
        local recyclerExists = CheckRecyclerExists(team, time);

        -- Check how many Extractors we have first. Need at least 1 before doing this.
        local extractorCount = CountExtractors(team, time);

        -- First check to see if we have a factory.
        local factoryExists = CheckFactoryExists(team, time);

        if (recyclerExists and extractorCount > 0) then
            -- Good, we have our Recycler. So let's check the 2 conditions that will allow us to build and dispatch turrets.
            if (factoryExists == false) then
                return true;
            else
                -- Do a quick check to see how many extractors the player has. This will work for late-game, making it more difficult for players to capture stuff.
                local playerExtractorCount = AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'enemy', true);

                if (playerExtractorCount <= 2) then
                    return true;
                end
            end
        end
    end

    -- Default return. If none of the conditions are met, just use this.
    return false;
end

-- Early patrol condition for Scouts to patrol around the map. Don't do this when a factory has been built.
function EarlyScoutCondition(team, time)
    -- Don't do this if the Factory exists.
    local doesFactoryExist = CheckFactoryExists(team, time);

    if (doesFactoryExist) then
        return false;
    else
        return true;
    end
end

-- Send Scouts to attack Scavengers before we have a Factory.
function EarlyScoutAttackCondition(team, time)
    return (CheckRecyclerExists(team, time) and CheckFactoryExists(team, time) == false and (CountEnemyScavengers(team, time) >= 2 or CountEnemyExtractors(team, time) >= 2));
end

-- Send Missile Scouts to patrol when a Factory is built
function MissilePatrolCondition(team, time)
    -- If a factory exists, proceed.
    return CheckFactoryExists(team, time);
end

-- Send Tanks to patrol when a Factory and bunker is built
function TankPatrolCondition(team, time)
    -- If a factory and relay bunker exists, proceed.
    return CheckFactoryExists(team, time) and CheckBunkerExists(team, time);
end

-- Upgrade our first Extractor
function UpgradeBaseExtractorCondition(team, time)
    return (CountExtractors(team, time) >= 1 and CountConstructors(team, time) >= 1 and AIPUtil.GetScrap(team, false) >= 60 and CountUpgradedExtractors(team, time) == 0);
end

-- Condition for the first Power Plant.
function PowerPlantCondition(team, time)
    return (CountConstructors(team, time) > 0 and CountPower(team, time) <= 0);
end

-- Condition for the Factory.
function FactoryCondition(team, time)
    return (CountConstructors(team, time) > 0
        and CheckFactoryExists(team, time) == false
        and CountPower(team, time) > 0);
end

-- Condition for the Armory.
function ArmoryCondition(team, time)
    return (CountConstructors(team, time) > 0
        and CheckFactoryExists(team, time)
        and CheckArmoryExists(team, time) == false
        and CountPower(team, time) > 0);
end

-- Condition for Relay Bunker.
function BunkerCondition(team, time)
    return (CountConstructors(team, time) > 0
        and CheckFactoryExists(team, time)
        and CheckArmoryExists(team, time)
        and CheckBunkerExists(team, time) == false
        and CountPower(team, time) > 0);
end

-- Condition for Service Bay.
function ServiceBayCondition(team, time)
    return (CountConstructors(team, time) > 0
        and CheckArmoryExists(team, time)
        and CheckFactoryExists(team, time)
        and CheckServiceBayExists(team, time) == false
        and CountPower(team, time) > 0);
end

-- Condition for outposts.
function OutpostCondition(team, time)
    return (CountConstructors(team, time) > 0 and CheckFactoryExists(team, time) and CountPower(team, time) > 0);
end

-- Outpost 1 Conditions
function Outpost1GunTower1Condition(team, time)
    -- Check if the Outpost 1 GunTower path exists.
    local pathExists = AIPUtil.PathExists("i_Outpost_1_GunTower_1");
    local outpostExists = AIPUtil.PathBuildingExists("i_Outpost_1");
    local powerCount = CountPower(team, time);
    local consExists = CountConstructors(team, time) > 0;
    local factoryExists = CheckFactoryExists(team, time);

    -- Return true if all of the above are met.
    return (pathExists and outpostExists and powerCount > 0 and consExists and factoryExists);
end

function Outpost1GunTower2Condition(team, time)
    -- Check if the Outpost 1 GunTower path exists.
    local pathExists = AIPUtil.PathExists("i_Outpost_1_GunTower_2");
    local outpostExists = AIPUtil.PathBuildingExists("i_Outpost_1");
    local powerCount = CountPower(team, time);
    local consExists = CountConstructors(team, time) > 0;
    local factoryExists = CheckFactoryExists(team, time);

    -- Return true if all of the above are met.
    return (pathExists and outpostExists and powerCount > 0 and consExists and factoryExists);
end

-- Conditions for Gun Towers.
function GunTowerCondition(team, time)
    return (CountConstructors(team, time) > 0 and CheckBunkerExists(team, time) and CountPower(team, time) > 0);
end

-- Utility functions to help keep track of important objects.
function CheckRecyclerExists(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_RECYCLER", 'sameteam', true) > 0;
end

function CheckFactoryExists(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_FACTORY", 'sameteam', true) > 0;
end

function CheckArmoryExists(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_ARMORY", 'sameteam', true) > 0;
end

function CheckBunkerExists(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_COMMBUNKER", 'sameteam', true) > 0;
end

function CheckServiceBayExists(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SUPPLYDEPOT", 'sameteam', true) > 0;
end

function CountScavengers(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", 'sameteam', true);
end

function CountPower(team, time)
    return AIPUtil.GetPower(team, false);
end

function CountExtractors(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'sameteam', true);
end

function CountUpgradedExtractors(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR_Upgraded", 'sameteam', true);
end

function CountTurrets(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_TURRET", 'sameteam', true);
end

function CountLooseScrap(team, time)
    return AIPUtil.CountUnits(team, "resource", 'friendly', true);
end

function CountConstructors(team, time)
    return AIPUtil.CountUnits(team, 'VIRTUAL_CLASS_CONSTRUCTIONRIG', 'sameteam', true);
end

-- Conditions around human teams.
function CountEnemyScavengers(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SCAVENGER", 'enemy', true);
end

function CountEnemyExtractors(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_EXTRACTOR", 'enemy', true);
end
