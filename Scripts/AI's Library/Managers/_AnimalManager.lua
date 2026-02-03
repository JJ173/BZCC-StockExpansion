local _AnimalHerd = require("_AnimalHerd")

local MAX_HERD_COUNT = 5

AnimalManager = {
    AnimalHerds = {},
    EnableHerdLogic = false
}

function AnimalManager.Save()
    return AnimalManager
end

function AnimalManager.Load(animalData)
    for k, v in pairs(animalData) do
        AnimalManager[k] = v
    end
end

function AnimalManager.SetupMapHerds(motherODF, babyODF)
    for i = 1, MAX_HERD_COUNT do
        local herdPath = "AnimalHerd" .. i

        if (not VerifyAnimalPath(herdPath)) then
            break
        end

        local newHerd = _AnimalHerd.New(motherODF, babyODF, herdPath, i)

        if (newHerd == nil) then
            break
        end

        AnimalManager.AnimalHerds[#AnimalManager.AnimalHerds + 1] = newHerd
    end

    AnimalManager.EnableHerdLogic = true
end

function AnimalManager.SetupMireMapHerds()
    for i = 1, MAX_HERD_COUNT do
        local herdPath = "AnimalHerd" .. i

        if (not VerifyAnimalPath(herdPath)) then
            break
        end

        -- Spawn some Jaks and birds around the path. These guys don't need to be stored as they don't need a brain to help them.
        local jakCount = GetRandomInt(3, 6)

        for j = 1, jakCount do
            local position = GetPositionNear(herdPath, 20, 40)
            position.y = GetTerrainHeightAndNormal(position.x, position.y) + 3
            BuildObject("mcjak01", 0, position)
        end

        -- Do some birds too.
        SpawnBirds(i, GetRandomInt(3, 6), "mcwing01", 0, herdPath)
    end
end

function AnimalManager.Run(missionTurn)
    if (not AnimalManager.EnableHerdLogic) then
        return
    end

    for _, herd in pairs(AnimalManager.AnimalHerds) do
        _AnimalHerd.Brain(herd, missionTurn)
    end
end

function AnimalManager.AnimalShot(shotTurn, animalHandle, threat)
    local herdIndex = GetLabel(animalHandle)

    if (herdIndex == nil) then
        return
    end

    local herd = AnimalManager.AnimalHerds[tonumber(herdIndex)]

    if (herd == nil) then
        return
    end

    _AnimalHerd.AnimalShot(herd, shotTurn, threat)
end

function VerifyAnimalPath(path)
    local testObj = BuildObject("npscrx", 0, path)

    if (not IsAround(testObj)) then
        return false
    end

    RemoveObject(testObj)

    return true
end

return AnimalManager
