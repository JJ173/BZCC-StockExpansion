local _BZCCDatabase = require("_BZCCDatabase")

---@class TeamLoadout
---@field TeamNumber number
---@field Cannons table
---@field Guns table
---@field Missiles table
---@field Shields table
---@field Mortars table
---@field Faction string
---@field HasArmory boolean

local WeaponManager = {
    ---@type TeamLoadout[]
    Loadouts = {}
}

-- Constants
local MAX_WEAPON_SLOTS = 5
local WEAPON_TYPES = {
    CANNON  = "CANNON",
    GUN     = "GUN",
    ROCKET  = "ROCKET",
    MORTAR  = "MORTAR",
    SPECIAL = "SPECIAL"
}

-- Variables for chance of weapons for units.
local m_ShieldChance = 0.2;
local m_WeaponChance = 0.25;

function WeaponManager.SetupTeam(teamNum, faction)
    print("Setting up loadout for team: ", teamNum)

    WeaponManager.Loadouts[#WeaponManager.Loadouts + 1] = {
        TeamNumber = teamNum,
        Cannons = {},
        Guns = {},
        Missiles = {},
        Shields = {},
        Mortars = {},
        Faction = faction,
        HasArmory = false,
    }
end

function WeaponManager.GiveWeapons(unitHandle, teamNum)
    local activeLoadout;

    for i = 1, #WeaponManager.Loadouts do
        local loadout = WeaponManager.Loadouts[i]

        if (loadout.TeamNumber == teamNum) then
            activeLoadout = loadout
        end
    end

    if (activeLoadout == nil) then
        return
    end

    -- if (not activeLoadout.HasArmory) then
    --     return
    -- end

    if (GetCategoryType(unitHandle) ~= _BZCCDatabase.Categories.TEAM_SLOT_OFFENSE) then
        return
    end

    -- Check all active weapon slots for the vehicle that is passed in and customize it. Currently, 5 is the maxiumum amount of weapons a unit can use.
    print("Printing slots for ... ", GetCfg(unitHandle))

    for i = 1, MAX_WEAPON_SLOTS do
        -- For each slot, get the type.
        local slot = GetODFString(unitHandle, "GameObjectClass", "weaponType" .. i)

        if (slot ~= nil) then
            -- Run logic based on the slot.
            if (slot == WEAPON_TYPES.CANNON) then

            end
        end
    end
end

function WeaponManager.BuildingAdded(buildingHandle, teamNum)
    -- Run through each loadout and find the one relevant to this team.
    for i = 1, #WeaponManager.Loadouts do
        local loadout = WeaponManager.Loadouts[i]

        if (loadout == teamNum) then
            -- Check which building was added to the team so we can populate the table correctly.
            local class = GetClassLabel(buildingHandle)

            if (class == "CLASS_ARMORY") then
                loadout.HasArmory = true
            end
        end
    end
end

function WeaponManager.BuildingRemoved(buildingHandle, teamNum)

end

function WeaponManager.GetWeaponSlots(unitHandle)

end

return WeaponManager
