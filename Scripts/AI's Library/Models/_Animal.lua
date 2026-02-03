---@class AnimalClass
---@field Handle userdata | nil
---@field State string -- Possible states: Grazing, Attacking, Fleeing, Following
---@field FleePath string -- Path to flee to

Animal = {}

---Creates and returns a new animal class.
---@param handle Handle
---@param state string
---@return AnimalClass
function Animal.CreateNewAnimal(handle, state)
    return {
        Handle = handle,
        State = state,
        FleePath = ''
    }
end

return Animal
