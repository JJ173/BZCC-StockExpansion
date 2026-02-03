_VoiceManager = {}

function _VoiceManager.SwitchVehicleVoices(handle, pilotHandle)
    -- Don't process this if the handle that is being passed is a player.
    if (IsPlayer(pilotHandle)) then return end;

    -- Get these here for now, but move them down if we need to.
    local pilotRace = GetRace(pilotHandle);
    local handleRace = GetRace(handle);

    if (pilotRace == handleRace) then
        return
    end

    local handleOdf = GetCfg(handle);
    local odfName = handleOdf .. '_' .. pilotRace;

    -- Abort early if the ODF that we need doesn't exist.
    if (DoesODFExist(odfName) == false) then return end;

    -- ODF Exists, so let's replace it based on the pilot race that entered the craft.
    local newOdf = ReplaceObject(handle, odfName, GetTeamNum(pilotHandle));

    -- Just for safety.
    AddPilotByHandle(newOdf);

    -- So it's Commandable.
    SetBestGroup(newOdf);

    -- Return the result to the caller in the event we need to store this in a variable.
    return newOdf;
end

return _VoiceManager;
