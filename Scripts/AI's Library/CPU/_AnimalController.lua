local _AnimalHerd = require("_AnimalHerd");

local MAX_HERD_COUNT = 5;

AnimalController = {
    AnimalHerds = {},
    EnableHerdLogic = false
}

function AnimalController:New()
    local newController = {};
    newController.AnimalHerds = {};
    newController.EnableHerdLogic = false;

    setmetatable(newController, { __index = self });
    return newController;
end

function AnimalController:Save()
    return AnimalController;
end

function AnimalController:Load(data)
    AnimalController = data;
end

function AnimalController:SetupMapHerds(motherODF, babyODF)
    for i = 1, MAX_HERD_COUNT do
        local herdPath = "AnimalHerd" .. i;

        if (not VerifyAnimalPath(herdPath)) then
            break;
        end

        local newHerd = _AnimalHerd:New(motherODF, babyODF, herdPath, i);

        if (newHerd == nil) then
            break;
        end

        self.AnimalHerds[#self.AnimalHerds + 1] = newHerd;
    end

    self.EnableHerdLogic = true;
end

function AnimalController:SetupMireMapHerds()
    for i = 1, MAX_HERD_COUNT do
        local herdPath = "AnimalHerd" .. i;

        if (not VerifyAnimalPath(herdPath)) then
            break;
        end

        -- Spawn some Jaks and birds around the path. These guys don't need to be stored as they don't need a brain to help them.
        local jakCount = GetRandomInt(3, 6);

        for j = 1, jakCount do
            local position = GetPositionNear(herdPath, 20, 40);
            position.y = GetTerrainHeightAndNormal(position.x, position.y) + 3;
            BuildObject("mcjak01", 0, position);
        end

        -- Do some birds too.
        SpawnBirds(i, GetRandomInt(3, 6), "mcwing01", 0, herdPath);
    end
end

function AnimalController:Run(missionTurn)
    if (not self.EnableHerdLogic) then
        return;
    end

    for _, herd in pairs(self.AnimalHerds) do
        herd:Brain(missionTurn);
    end
end

function AnimalController:AnimalShot(shotTurn, animalHandle, threat)
    local herdIndex = GetLabel(animalHandle);

    if (herdIndex == nil) then
        return;
    end

    local herd = self.AnimalHerds[tonumber(herdIndex)];

    if (herd == nil) then
        return;
    end

    herd:AnimalShot(shotTurn, threat);
end

function VerifyAnimalPath(path)
    local testObj = BuildObject("npscrx", 0, path);

    if (not IsAround(testObj)) then
        return false;
    end

    RemoveObject(testObj);

    return true;
end

return AnimalController;
