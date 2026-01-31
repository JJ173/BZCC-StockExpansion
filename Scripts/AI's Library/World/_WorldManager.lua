WorldManager = {
    -- If enabled, it will apply damage to player pilots under water.
    EnableHypothermia = false,
    -- Time in turns to compare with for frequency of damage.
    HypothermiaCounter = 0,
    -- Tracks the amount of active players to apply effects to.
    PlayerTotal = 0
}

function WorldManager.Setup(enableHypothermia, playerTotal)
    WorldManager.EnableHypothermia = enableHypothermia
    WorldManager.PlayerTotal = playerTotal
end

function WorldManager.Run()
    if (WorldManager.EnableHypothermia) then
        WorldManager.HypothermiaCounter = WorldManager.HypothermiaCounter + 1
        WorldManager.Hypothermia()
    end
end

function WorldManager.Hypothermia()
    if (WorldManager.PlayerTotal <= 0) then return end

    for i = 1, WorldManager.PlayerTotal do
        local p = GetPlayerHandle(i)

        if (WorldManager.HypothermiaCounter % SecondsToTurns(0.5) == 0 and IsPerson(p)) then
            local pos = GetPosition(p)

            if (TerrainIsWater(pos)) then
                local waterHeight = GetTerrainHeightAndNormal(pos, true)
                local terrainHeight = TerrainFindFloor(pos.x, pos.z)

                if (waterHeight > terrainHeight and pos.y < (waterHeight - 15)) then
                    SelfDamage(p, 20)
                end
            end
        end
    end
end

function WorldManager.UpdatePlayerTotal(newPlayerTotal)
    WorldManager.PlayerTotal = newPlayerTotal
end

return WorldManager
