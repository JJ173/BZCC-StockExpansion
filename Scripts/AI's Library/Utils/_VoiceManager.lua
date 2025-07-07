_VoiceManager = {}

function _VoiceManager.SwitchVehicleVoices(handle, pilotHandle)
    -- Don't process this if the handle that is being passed is a player.
    if (IsPlayer(pilotHandle)) then return end;

    -- Get these here for now, but move them down if we need to.
    local handleOdf = GetCfg(handle);
    local pilotRace = GetRace(pilotHandle);
    local handleRace = GetRace(handle);

    -- First we need to check if the pilot race is the same as the craft race.
    local odfName;

    if (pilotRace == handleRace) then
        -- Crack open the current ODF that the pilot got into.
        odfName = GetODFString(handle, 'GameObjectClass', 'classLabel');
    else
        odfName = handleOdf .. '_' .. pilotRace;
    end

    -- For extra debugging.
    print("Attempting to replace " .. handleOdf .. " with ", odfName);

    -- Abort early if the ODF that we need doesn't exist.
    if (DoesODFExist(odfName) == false) then return end;

    -- ODF Exists, so let's replace it based on the pilot race that entered the craft.
    local newOdf = ReplaceObject(handle, odfName);

    -- Just for safety.
    AddPilotByHandle(newOdf);

    -- So it's Commandable.
    SetBestGroup(newOdf);

    -- Return the result to the caller in the event we need to store this in a variable.
    return newOdf;
end

return _VoiceManager;
