---@class Carrier
---@field Carrier Handle
---@field Team integer
---@field Faction string
---@field LandingPad Handle | nil
---@field DropshipRequestItems DropshipRequestItem[]
---@field Condors Condor[]
---@field Teleporters Teleporter[]
---@field ActiveCondor Condor | nil
---@field ActiveTeleporter Teleporter | nil

---@class DropshipRequestItem
---@field Handle Handle
---@field Team integer
---@field TimeToDelete integer
---@field Type string

---@class Condor
---@field Handle Handle | nil
---@field Team integer
---@field Type string
---@field UnitTotal integer
---@field State integer
---@field ReadyToDelete boolean
---@field DelayTime integer
---@field Units Handle[]

---@class Teleporter
---@field Handle Handle | nil
---@field Team integer
---@field Type string
---@field UnitTotal integer
---@field DelayTime integer
---@field TeleportedUnitCount integer
---@field ReadyToDelete boolean

local _BZCCDatabase = require("_BZCCDatabase")

CarrierManager = {
    ---@type Carrier[]
    Carriers = {},
}

---@param team integer
---@return Carrier | nil
local function GetTeamCarrier(team)
    for i = 1, #CarrierManager.Carriers do
        local carrier = CarrierManager.Carriers[i]

        if (carrier == nil or carrier.Team ~= team) then
            PrintConsoleMessage("Carrier not found for team: " .. team)
            return nil
        end

        return carrier
    end
end

---@param condor Condor
---@param landingPad Handle
---@param missionTurnCount integer
local function HandleCondor(condor, landingPad, missionTurnCount)
    if (not IsAround(landingPad)) then
        return
    end

    if (condor.DelayTime > missionTurnCount) then
        return
    end

    if (condor.State == _BZCCDatabase.DropshipStates.CONDOR_LANDING) then
        -- Build the model before landing so it doesn't just sit in the sky when waiting.
        local landingPos = GetPosition(landingPad)
        landingPos.y = landingPos.y + 2
        condor.Handle = BuildObject("ivdrop_land_x", condor.Team, BuildDirectionalMatrix(landingPos))

        -- Show the engine FX.
        StartEmitter(condor.Handle, 1)
        StartEmitter(condor.Handle, 2)

        -- Have it land.
        SetAnimation(condor.Handle, "land", 1)

        -- Delay before opening the doors after landing.
        condor.DelayTime = missionTurnCount + SecondsToTurns(16)

        -- So we don't loop.
        condor.State = condor.State + 1
    elseif (condor.State == _BZCCDatabase.DropshipStates.CONDOR_REPLACE) then
        -- Replace the object with the proper landing variant.
        condor.Handle = ReplaceObject(condor.Handle, "ivpdrop")

        -- Tiny delay before building units.
        condor.DelayTime = missionTurnCount + SecondsToTurns(2)

        -- So we don't loop.
        condor.State = condor.State + 1
    elseif (condor.State == _BZCCDatabase.DropshipStates.CONDOR_BUILD_UNITS) then
        MaskEmitter(condor.Handle, 0)
        SetAnimation(condor.Handle, "deploy", 1)

        -- Starting point for spawns
        local posXDiscrim = 8
        local posZDiscrim = 5

        local pos = GetPosition(landingPad)
        pos.y = pos.y + 5
        local originalPos = pos

        -- Handle what units are built.
        for i = 1, condor.UnitTotal do
            if (i == 2) then
                pos.z = pos.z - posZDiscrim;
                pos.x = pos.x + posXDiscrim;
            elseif (i == 3) then
                pos.z = pos.z - posZDiscrim;
                pos.x = pos.x - posXDiscrim;
            end

            condor.Units[#condor.Units + 1] = BuildObject(_BZCCDatabase.DropshipUnits[condor.Type], condor.Team,
                BuildDirectionalMatrix(pos))
            pos = originalPos
        end

        -- Small delay for sound.
        condor.DelayTime = missionTurnCount + SecondsToTurns(2.5)

        -- So we don't loop.
        condor.State = condor.State + 1
    elseif (condor.State == _BZCCDatabase.DropshipStates.CONDOR_OFFLOAD_UNITS) then
        -- Calculate the drop-off for the units to move to.
        local dropOff = GetPosition(landingPad) + (GetFront(landingPad) * 75)

        for _, unit in pairs(condor.Units) do
            Goto(unit, dropOff, 0)
        end

        -- Play the door sound effect.
        StartSoundEffect("dropdoor.wav", condor.Handle)

        -- So we don't loop.
        condor.State = condor.State + 1
    elseif (condor.State == _BZCCDatabase.DropshipStates.CONDOR_LEAVE) then
        local clear = false

        -- Instead of a general distance check, just check that the units have left, and the player isn't in the dropship.
        for _, unit in pairs(condor.Units) do
            clear = GetDistance(unit, condor.Handle) > 50
        end

        -- If all units are clear, move to check the player.
        if (clear) then
            clear = GetDistance(GetPlayerHandle(1), condor.Handle) > 50
        end

        if (clear) then
            -- Start the take-off sequence.
            SetAnimation(condor.Handle, "takeoff", 1)

            -- Show the engine FX.
            StartEmitter(condor.Handle, 1)
            StartEmitter(condor.Handle, 2)

            -- Engine sound.
            StartSoundEffect("dropleav.wav", condor.Handle)

            -- Delay before removing the dropship.
            condor.DelayTime = missionTurnCount + SecondsToTurns(20)

            -- So we don't loop.
            condor.State = condor.State + 1
        end
    elseif (condor.State == _BZCCDatabase.DropshipStates.CONDOR_REMOVE) then
        -- Remove the Dropship.
        RemoveObject(condor.Handle)

        -- Script is complete. Ready to delete.
        condor.ReadyToDelete = true
    end
end

---@param portal Teleporter
---@param missionTurnCount integer
local function HandlePortal(portal, missionTurnCount)
    if (not IsAround(portal.Handle)) then
        return
    end

    if (not IsPowered(portal.Handle)) then
        return
    end

    if (portal.DelayTime > missionTurnCount) then
        return
    end

    -- Store the built unit locally.
    local teleportedUnit = nil

    -- Increment the teleported unit count.
    portal.TeleportedUnitCount = portal.TeleportedUnitCount + 1;

    -- Teleport units out of the portal.
    teleportedUnit = TeleportIn(_BZCCDatabase.PortalUnits[portal.Type], portal.Team, portal.Handle)

    -- Calculate the drop-off for the units to move to.
    local dropOff = GetPosition(portal.Handle) + (GetFront(portal.Handle) * 75)

    -- Move the unit to the north of the portal handle.
    Goto(teleportedUnit, dropOff, 0)

    -- Check if the portal is ready to delete.
    if (portal.TeleportedUnitCount >= portal.UnitTotal) then
        portal.ReadyToDelete = true
    end

    -- Create a small delay for the next unit.
    portal.DelayTime = missionTurnCount + SecondsToTurns(1)
end

---@return table
function CarrierManager.Save()
    return CarrierManager
end

---@param CarrierData table
function CarrierManager.Load(CarrierData)
    for k, v in pairs(CarrierData) do
        PrintConsoleMessage("Loading CarrierManager. Field: " .. k .. " Value: " .. v)
        CarrierManager[k] = v
    end
end

---@param missionTurnCount integer
function CarrierManager.Run(missionTurnCount)
    local carrierCount = #CarrierManager.Carriers

    if (carrierCount <= 0) then
        return
    end

    for _, carrier in pairs(CarrierManager.Carriers) do
        if (carrier ~= nil) then
            if (#carrier.DropshipRequestItems > 0) then
                for _, requestItem in pairs(carrier.DropshipRequestItems) do
                    if (requestItem.TimeToDelete < missionTurnCount) then
                        TableRemoveByHandle(carrier.DropshipRequestItems, requestItem.Handle)
                        RemoveObject(requestItem.Handle)
                    end
                end
            end

            if (IsAround(carrier.LandingPad)) then
                if (carrier.Faction == _BZCCDatabase.Factions.ISDF) then
                    if (#carrier.Condors > 0) then
                        -- Process dropships in a queue-like fashion.
                        if (carrier.ActiveCondor == nil) then
                            carrier.ActiveCondor = carrier.Condors[1]
                        elseif (not carrier.ActiveCondor.ReadyToDelete) then
                            HandleCondor(carrier.ActiveCondor, carrier.LandingPad, missionTurnCount)
                        else
                            TableRemoveByHandle(carrier.Condors, carrier.ActiveCondor)
                            carrier.ActiveCondor = nil

                            -- Just for debugging.
                            for k, v in pairs(carrier.Condors) do
                                print(k, v)
                            end
                        end
                    end
                elseif (carrier.Faction == _BZCCDatabase.Factions.SCION) then
                    if (#carrier.Teleporters > 0) then
                        if (carrier.ActiveTeleporter == nil) then
                            carrier.ActiveTeleporter = carrier.Teleporters[1]
                        elseif (not carrier.ActiveTeleporter.ReadyToDelete) then
                            HandlePortal(carrier.ActiveTeleporter, missionTurnCount)
                        else
                            TableRemoveByHandle(carrier.Teleporters, carrier.ActiveTeleporter)
                            carrier.ActiveTeleporter = nil
                        end
                    end
                end
            end
        end
    end
end

---@param team integer
function CarrierManager.SetupCarrier(team, faction)
    local pos = GetPosition("Carrier_" .. team)
    local odf = faction .. "bcarrier_xm"

    PrintConsoleMessage("Setting up carrier for team " .. team .. " at position: Carrier_" .. team)

    CarrierManager.Carriers[#CarrierManager.Carriers + 1] = {
        Carrier = BuildObject(odf, team, SetVector(pos.x, 800, pos.z)),
        Team = team,
        Faction = faction,
        LandingPad = nil,
        DropshipRequestItems = {},
        Condors = {},
        Teleporters = {},
        ActiveCondor = nil,
        ActiveTeleporter = nil
    }
end

---@param handle Handle
---@param team integer
function CarrierManager.RegisterLandingPad(handle, team)
    local carrier = GetTeamCarrier(team)

    if (carrier == nil) then
        return
    end

    PrintConsoleMessage("Registering landing pad for team: " .. team)
    carrier.LandingPad = handle
end

---@param handle Handle
---@param team integer
function CarrierManager.RegisterDropshipRequest(handle, team, timeToDelete)
    local carrier = GetTeamCarrier(team)

    if (carrier == nil) then
        return
    end

    local type = GetBase(handle)

    ---@type DropshipRequestItem
    local newDropshipRequesItem = {
        Handle = handle,
        Team = team,
        TimeToDelete = timeToDelete,
        Type = type
    }

    PrintConsoleMessage("Registering dropship request for team: " ..
        team .. ". Values: " .. " Team: " .. team .. " Time to Delete: " .. timeToDelete .. " Type: " .. type)
    carrier.DropshipRequestItems[#carrier.DropshipRequestItems + 1] = newDropshipRequesItem

    local totalUnits = 3
    if (type == "ScrapDropship" or type == "ScavengerDropship") then
        totalUnits = 2
    end

    if (carrier.Faction == _BZCCDatabase.Factions.ISDF) then
        ---@type Condor
        local newCondor = {
            Handle = nil,
            Team = team,
            Type = type,
            UnitTotal = totalUnits,
            State = _BZCCDatabase.DropshipStates.CONDOR_LANDING,
            ReadyToDelete = false,
            DelayTime = 0,
            Units = {}
        }

        carrier.Condors[#carrier.Condors + 1] = newCondor
        return
    end

    if (carrier.Faction == _BZCCDatabase.Factions.SCION) then
        ---@type Teleporter
        local newPortal = {
            Handle = carrier.LandingPad,
            Team = team,
            Type = type,
            UnitTotal = totalUnits,
            DelayTime = 0,
            TeleportedUnitCount = 0,
            ReadyToDelete = false
        }

        carrier.Teleporters[#carrier.Teleporters + 1] = newPortal
        return
    end
end

return CarrierManager
