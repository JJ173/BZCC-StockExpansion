AnimalHerd = {}

local _Animal = require("_Animal")
local _BZCCDatabase = require("_BZCCDatabase")

---@class AnimalHerdClass
---@field Team integer
---@field MotherODF string
---@field BabyODF string
---@field Mother Handle
---@field Babies AnimalClass[]
---@field MotherAttackTime integer
---@field BabyFleeDistance integer
---@field State string

function AnimalHerd.New(motherODF, babyODF, path, index)
    -- Animals are neutral unless attacked.
    local spawnPosition = GetPosition(path)
    spawnPosition.y = GetTerrainHeightAndNormal(spawnPosition.x, spawnPosition.z) + 3

    ---@type AnimalHerdClass
    local newHerd = {
        Team = 0,
        MotherODF = motherODF,
        BabyODF = babyODF,
        Mother = BuildObject(motherODF, 0, spawnPosition),
        Babies = {},
        MotherAttackTime = 0,
        BabyFleeDistance = 100,
        State = _BZCCDatabase.AnimalStates.GRAZING
    }

    -- Set the label of the mother and the babies so we can easily identify the herd later.
    SetLabel(newHerd.Mother, index)

    -- Generate a random number of babies for this herd.
    for i = 1, GetRandomInt(2, 5) do
        local babyPosition = GetPositionNear(spawnPosition, 40, 60)
        babyPosition.y = GetTerrainHeightAndNormal(babyPosition.x, babyPosition.z) + 3

        local baby = _Animal.CreateNewAnimal(BuildObject(newHerd.BabyODF, 0, babyPosition),
            _BZCCDatabase.AnimalStates.FOLLOWING)
        SetLabel(baby.Handle, index)
        newHerd.Babies[#newHerd.Babies + 1] = baby
    end

    -- Have the babies follow the mother.
    for _, baby in ipairs(newHerd.Babies) do
        Follow(baby.Handle, newHerd.Mother)
    end

    return newHerd
end

---Runs the brain for each herd that's passed in.
---@param herd AnimalHerdClass
---@param missionTurn integer
function AnimalHerd.Brain(herd, missionTurn)
    -- Implement herd behavior based on the current state.
    if (herd.State == _BZCCDatabase.AnimalStates.ATTACKING) then
        -- If the mother is attacking, check if the attack timer has expired.
        if (missionTurn > herd.MotherAttackTime) then
            -- Return to neutral state.
            herd.State = _BZCCDatabase.AnimalStates.GRAZING
            herd.Team = 0 -- Neutral team

            SetTeamNum(herd.Mother, herd.Team)
            Stop(herd.Mother)

            for _, baby in ipairs(herd.Babies) do
                if (baby ~= nil and IsAround(baby.Handle)) then
                    SetTeamNum(baby.Handle, herd.Team)
                    Follow(baby.Handle, herd.Mother)
                end
            end

            return
        end

        -- Babies need to flee to at least 100 meters away, but stay within 100 meters of the mother.
        for _, baby in ipairs(herd.Babies) do
            if (baby ~= nil and IsAround(baby.Handle)) then
                -- Check the state of the baby. If it's fleeing, check the distance and have it return to following if far enough away.
                if (baby.State == _BZCCDatabase.AnimalStates.FOLLOWING) then
                    if (GetDistance(herd.Mother, baby.Handle) < herd.BabyFleeDistance) then
                        -- If there's no flee path, generate one.
                        if (baby.FleePath == "") then
                            local fleePosition = GetPositionNear(GetPosition(herd.Mother), herd.BabyFleeDistance + 20, herd.BabyFleeDistance + 50)
                            baby.FleePath = fleePosition
                        end

                        baby.State = _BZCCDatabase.AnimalStates.FLEEING
                        Retreat(baby.Handle, baby.FleePath)
                    end
                elseif (baby.State == _BZCCDatabase.AnimalStates.FLEEING) then
                    if (GetDistance(herd.Mother, baby.Handle) >= (herd.BabyFleeDistance + 10)) then
                        baby.State = _BZCCDatabase.AnimalStates.FOLLOWING
                        Follow(baby.Handle, herd.Mother)
                    end
                end
            end
        end
    end
end

---Handles state changes for animals that are shot.
---@param herd AnimalHerdClass
---@param shotTurn integer
---@param threat Handle
function AnimalHerd.AnimalShot(herd, shotTurn, threat)
    -- If the mother is around, change the herd team to 15.
    if (IsAround(herd.Mother)) then
        if (herd.State == _BZCCDatabase.AnimalStates.ATTACKING) then
            AnimalHerd.UpdateAttackTime(herd, shotTurn)
            return -- Already attacking
        end

        -- Change the state to attacking.
        herd.State = _BZCCDatabase.AnimalStates.ATTACKING

        -- Change the mother to the "Attack" ODF.
        -- This will make her move faster and be more aggressive.
        -- Mother will also scream.
        StartSoundEffect("rhin08.wav", herd.Mother)
        herd.Team = 15 -- Hostile team
        SetTeamNum(herd.Mother, herd.Team)

        for _, baby in ipairs(herd.Babies) do
            if (baby ~= nil and IsAround(baby.Handle)) then
                SetTeamNum(baby.Handle, herd.Team)
            end
        end

        Attack(herd.Mother, threat)

        -- Set the attack timer (e.g., 30 seconds).
        AnimalHerd.UpdateAttackTime(herd, shotTurn)
    else
        -- Mother is dead, have the babies flee.
        for _, baby in ipairs(herd.Babies) do
            if (baby ~= nil and IsAround(baby.Handle)) then
                baby.State = _BZCCDatabase.AnimalStates.FLEEING
                baby.FleePath = GetPositionNear(GetPosition(threat), herd.BabyFleeDistance + 60,
                    herd.BabyFleeDistance + 100)
                Retreat(baby.Handle, baby.FleePath)
            end
        end
    end
end

---Updates the attack time for the mother of the animal herd.
---@param herd AnimalHerdClass
---@param shotTurn integer
function AnimalHerd.UpdateAttackTime(herd, shotTurn)
    herd.MotherAttackTime = shotTurn + SecondsToTurns(30)
end

return AnimalHerd
