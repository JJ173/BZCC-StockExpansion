---@class PoolClass
---@field Handle Handle
---@field Position Vector
---@field DistanceFromCPURecycler integer

Pool = {}

function Pool.New(handle, position)
    return {
        Handle = handle,
        Position = position,
        DistanceFromCPURecycler = 0
    }
end

return Pool
