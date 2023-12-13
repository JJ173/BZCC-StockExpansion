local _Skins = {};

local skinData = {
    {
        "76561198104781489", -- User Steam ID
        {
            "ivtank", 
            "ivtank_x", 
            "ivtank_xs"
        }, -- Units to replace
        "ivtank_grizzlyone_" -- Skin to use.
    }
}

function ApplySkinToHandle(steamId, playerHandle)
    -- Do a loop to find which table has the correct Steam ID.
    for i = 1, #skinData do
        -- Check to see if the steam ID matches.
        local skinDataSubset = skinData[i];

        -- Check to make sure the subset is not null.
        if (skinDataSubset ~= nil) then
            local steamID = skinDataSubset[1];
            local units = skinDataSubset[2];
            
            if (units ~= nil) then
                local skin = skinDataSubset[3];

                if (skin ~= nil) then
                    local ODF = GetCfg(playerHandle);

                    for j = 1, #units do
                        local unit = units[j];

                        if (ODF == unit) then
                            -- Check to see if this is the ST variant or not.
                            local lastCharacter = string.sub(unit, string.len(unit));

                            -- Used for the ST variant as the values may be different between this and the normal units.
                            if (lastCharacter == "s") then
                                return ReplaceObject(playerHandle, skin .. "s");
                            else
                                return ReplaceObject(playerHandle, skin .. "x");
                            end
                        end
                    end
                end
            end
        end
    end

    -- By default, return the original handle if necessary.
    return playerHandle;
end

return _Skins;