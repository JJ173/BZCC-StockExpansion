AssaultClass = {}

---@class AssaultClass
---@field Handle Handle
---@field Team number
---@field DefenderCount integer
---@field ServiceTruckCount integer

---Creates and returns a new assault class with the intention of it being managed by a script
---@param handle Handle
---@param team number
---@return AssaultClass
function AssaultClass.New(handle, team)
    ---@type AssaultClass
    return {
        Handle = handle,
        Team = team,
        DefenderCount = 0,
        ServiceTruckCount = 0
    }
end

return AssaultClass