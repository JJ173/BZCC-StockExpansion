local _Animal = require("_Animal");
local _BZCCDatabase = require("_BZCCDatabase");

AnimalHerd =
{
    HerdTeam = 0, -- Neutral team

    MotherODF = "",
    BabyODF = "",

    ---@type Animal
    Mother = nil,

    ---@type Animal[]
    Babies = {},

    -- Timer used to track the duration of the mother's attack state.
    -- Once this timer expires, the mother will return to normal behavior.
    MotherAttackTime = 0,

    -- If the mother of the herd dies, the babies need to flee somewhere.
    -- Distance the babies will flee from the mother's death location.
    -- If the babies are shot, they will flee this distance away from the threat.
    BabyFleeDistance = 100,

    -- State variables to track the behavior of the herd.
    State = "Idle", -- Possible states: Idle, Attacking, Fleeing
}

function AnimalHerd:New(motherODF, babyODF, path, index)
    local newHerd = {};

    newHerd.MotherODF = motherODF;
    newHerd.BabyODF = babyODF;
    newHerd.Mother = nil;
    newHerd.Babies = {};

    -- Animals are neutral unless attacked.
    local motherPosition = GetPosition(path);
    motherPosition.y = GetTerrainHeightAndNormal(motherPosition.x, motherPosition.z) + 3;
    newHerd.Mother = _Animal:CreateNewAnimal(BuildObject(newHerd.MotherODF, 0, motherPosition),
        _BZCCDatabase.AnimalStates.GRAZING);

    -- Set the label of the mother and the babies so we can easily identify the herd later.
    SetLabel(newHerd.Mother.Handle, index);

    -- Generate a random number of babies for this herd.
    local babyCount = GetRandomInt(2, 5);

    for i = 1, babyCount do
        local babyPosition = GetPositionNear(path, 40, 60);
        babyPosition.y = GetTerrainHeightAndNormal(babyPosition.x, babyPosition.z) + 3;

        local baby = _Animal:CreateNewAnimal(BuildObject(newHerd.BabyODF, 0, babyPosition),
            _BZCCDatabase.AnimalStates.FOLLOWING);

        SetLabel(baby.Handle, index);
        newHerd.Babies[#newHerd.Babies + 1] = baby;
    end

    -- Have the babies follow the mother.
    for _, baby in ipairs(newHerd.Babies) do
        Follow(baby.Handle, newHerd.Mother.Handle);
    end

    setmetatable(newHerd, { __index = self });
    return newHerd;
end

function AnimalHerd:Brain(missionTurn)
    -- Implement herd behavior based on the current state.
    if (self.State == _BZCCDatabase.AnimalStates.ATTACKING) then
        -- If the mother is attacking, check if the attack timer has expired.
        if (missionTurn > self.MotherAttackTime) then
            -- Return to neutral state.
            self.State = _BZCCDatabase.AnimalStates.GRAZING;
            self.HerdTeam = 0; -- Neutral team
            SetTeamNum(self.Mother.Handle, self.HerdTeam);
            Stop(self.Mother.Handle);

            for _, baby in ipairs(self.Babies) do
                if (baby == nil) then
                    break;
                end

                if (not IsAround(baby.Handle)) then
                    break;
                end

                SetTeamNum(baby.Handle, self.HerdTeam);
                Follow(baby.Handle, self.Mother.Handle);

                -- Clear the flee path.
                baby.FleePath = "";
            end

            return;
        end

        -- Babies need to flee to at least 100 meters away, but stay within 100 meters of the mother.
        for _, baby in ipairs(self.Babies) do
            if (baby == nil) then
                break;
            end

            if (not IsAround(baby.Handle)) then
                break;
            end

            -- Check the state of the baby. If it's fleeing, check the distance and have it return to following if far enough away.
            if (baby.State == _BZCCDatabase.AnimalStates.FLEEING) then
                -- If there's no flee path, generate one.
                if (baby.FleePath == "") then
                    local fleePosition = GetPositionNear(GetPosition(self.Mother.Handle), self.BabyFleeDistance + 20,
                        self.BabyFleeDistance + 50);
                    baby.FleePath = fleePosition;
                end

                local distance = GetDistance(self.Mother.Handle, baby.Handle);

                if (distance >= self.BabyFleeDistance) then
                    baby.State = _BZCCDatabase.AnimalStates.FOLLOWING;
                    Follow(baby.Handle, self.Mother.Handle);
                else
                    Retreat(baby.Handle, baby.FleePath);
                end
            elseif (baby.State == _BZCCDatabase.AnimalStates.FOLLOWING) then
                -- If we are within the flee distance, continue fleeing.
                local distance = GetDistance(self.Mother.Handle, baby.Handle);

                if (distance < self.BabyFleeDistance) then
                    baby.State = _BZCCDatabase.AnimalStates.FLEEING;
                    Goto(baby.Handle, baby.FleePath);
                end
            end
        end
    end
end

function AnimalHerd:AnimalShot(shotTurn, threat)
    -- If the mother is around, change the herd team to 15.
    if (IsAround(self.Mother.Handle)) then
        if (self.State == _BZCCDatabase.AnimalStates.ATTACKING) then
            self:UpdateAttackTime(shotTurn);
            return; -- Already attacking
        end

        -- Change the state to attacking.
        self.State = _BZCCDatabase.AnimalStates.ATTACKING;

        -- Change the mother to the "Attack" ODF.
        -- This will make her move faster and be more aggressive.
        -- Mother will also scream.
        StartSoundEffect("rhin08.wav", self.Mother.Handle);
        self.HerdTeam = 15; -- Hostile team
        SetTeamNum(self.Mother.Handle, self.HerdTeam);

        for _, baby in ipairs(self.Babies) do
            if (baby ~= nil and IsAround(baby.Handle)) then
                SetTeamNum(baby.Handle, self.HerdTeam);
            end
        end

        Attack(self.Mother.Handle, threat);

        -- Set the attack timer (e.g., 30 seconds).
        self:UpdateAttackTime(shotTurn);
    else
        -- Mother is dead, have the babies flee.
        for _, baby in ipairs(self.Babies) do
            if (baby ~= nil and IsAround(baby.Handle)) then
                baby.State = _BZCCDatabase.AnimalStates.FLEEING;
                local fleePosition = GetPositionNear(GetPosition(threat), self.BabyFleeDistance + 60,
                    self.BabyFleeDistance + 100);
                baby.FleePath = fleePosition;
                Retreat(baby.Handle, baby.FleePath);
            end
        end
    end
end

function AnimalHerd:UpdateAttackTime(shotTurn)
    self.MotherAttackTime = shotTurn + SecondsToTurns(30);
end

return AnimalHerd;
