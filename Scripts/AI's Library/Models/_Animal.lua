---@class Animal
---@field Handle userdata | nil
---@field State string -- Possible states: Grazing, Attacking, Fleeing, Following
---@field FleePath string -- Path to flee to
Animal = {
    Handle = nil,
    State = "", -- Possible states: Grazing, Attacking, Fleeing, Following
    FleePath = "" -- Path to flee to
}

function Animal:CreateNewAnimal(handle, state)
    local newModel = {};
    setmetatable(newModel, { __index = Animal });

    newModel.Handle = handle;
    newModel.State = state;

    return newModel;
end

return Animal;
