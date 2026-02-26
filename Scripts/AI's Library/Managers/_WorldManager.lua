local _SaveLoad = require("_SaveLoad")

WorldManager = {
    EnableHypothermia = false,
    HypothermiaCounter = 0,
    PlayerTotal = 0,

    MetersPerGrid = 8,
    HeightGranularity = 0.1,
    MinX = -2048,
    MinZ = -2048,
    Width = 4096,
    Depth = 4096,
    Height = 100
}

-- Register Save/Load for saveload system
_SaveLoad.RegisterSave("_WorldManager", function()
    return WorldManager
end)

_SaveLoad.RegisterLoad("_WorldManager", function(WorldManagerData)
    if (WorldManagerData ~= nil) then
        for k, v in pairs(WorldManagerData) do
            WorldManager[k] = v
        end
    else
        print("WARNING: _WorldManager Load called with nil data")
    end
end)

local function Hypothermia()
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

---@param isBaneMission boolean
---@param playerTotal integer
function WorldManager.Setup(isBaneMission, playerTotal)
    WorldManager.EnableHypothermia = isBaneMission
    WorldManager.PlayerTotal = playerTotal

    local mapTrnFile = GetMapTRNFilename()

    -- Attempt to pull information from the map TRN file, if it exists.
    local MetersPerGrid = GetODFFloat(mapTrnFile, "Size", "MetersPerGrid", 8)
    local HeightGranularity = GetODFFloat(mapTrnFile, "Size", "HeightGranularity", 0.1)
    local MinX = GetODFFloat(mapTrnFile, "Size", "MinX", -2048)
    local MinZ = GetODFFloat(mapTrnFile, "Size", "MinZ", -2048)
    local Width = GetODFFloat(mapTrnFile, "Size", "Width", 4096)
    local Depth = GetODFFloat(mapTrnFile, "Size", "Depth", 4096)
    local Height = GetODFFloat(mapTrnFile, "Size", "Height", 100)

    PrintConsoleMessage(string.format(
        "Registering Map Info: %s - MetersPerGrid: %f, HeightGranularity: %f, MinX: %f, MinZ: %f, Width: %f, Depth: %f, Height: %f",
        mapTrnFile, MetersPerGrid, HeightGranularity, MinX, MinZ, Width, Depth, Height))

    WorldManager.MetersPerGrid = MetersPerGrid
    WorldManager.HeightGranularity = HeightGranularity
    WorldManager.MinX = MinX
    WorldManager.MinZ = MinZ
    WorldManager.Width = Width
    WorldManager.Depth = Depth
    WorldManager.Height = Height
end

function WorldManager.Run()
    if (WorldManager.EnableHypothermia) then
        WorldManager.HypothermiaCounter = WorldManager.HypothermiaCounter + 1
        Hypothermia()
    end
end

function WorldManager.UpdatePlayerTotal(newPlayerTotal)
    WorldManager.PlayerTotal = newPlayerTotal
end

function WorldManager.GetRandomPathNearMapCenter()
    -- Search for a path that marks the ideal patrol area near the center of the map. 
    -- If it doesn't exist, we'll just use the center of the map as a reference point for random path generation.
    local mapCentrePath = GetPosition("MapCentrePath")
    local mapPos = SetVector(0, 0, 0)

    if (not IsNullVector(mapCentrePath)) then
        mapPos = mapCentrePath
    end

    return GetPositionNear(mapPos, 0, WorldManager.Width / 4)
end

return WorldManager
