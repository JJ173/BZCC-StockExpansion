local _Skins = {};

local skinData = {
    {
        "GrizzlyOne95",      -- User Steam Name
        "ivtank",            -- Units to replace
        "ivtank_grizzlyone_" -- Skin to use.
    }
}

function ApplySkinToHandle(playerName, emptyCraftHandle, team)
    -- Do a loop to find which table has the correct Steam ID.
    for i = 1, #skinData do
        -- Check to see if the steam ID matches.
        local skinDataSubset = skinData[i];

        -- Check to make sure the subset is not null.
        if (skinDataSubset ~= nil) then
            local name = skinDataSubset[1];

            -- Checks to see if the Steam IDs match.
            if (playerName == name) then
                local unitODF = skinDataSubset[2];
                local skin = skinDataSubset[3];
                local ODF = GetCfg(emptyCraftHandle);

                if (ODF:find(unitODF)) then
                    -- Check to see if this is the ST variant or not.
                    local lastCharacter = string.sub(unitODF, string.len(unitODF));
                    local unit = nil;

                    -- Used for the ST variant as the values may be different between this and the normal units.
                    if (lastCharacter == "s") then
                        unit = ReplaceObject(emptyCraftHandle, skin .. "s");
                    else
                        unit = ReplaceObject(emptyCraftHandle, skin .. "x");
                    end

                    SetAsUser(unit, team);
                    AddPilotByHandle(unit);
                end
            end
        end
    end
end

return _Skins;
