require("_VoiceManager");

function PreGetIn(cutWorld, pilotHandle, emptyCraftHandle)
    -- Run our replacement script logic.
    local handle = _VoiceManager.SwitchVehicleVoices(emptyCraftHandle, pilotHandle);

    SetObjectiveOn(handle);

    -- Always allow the entry
    return 1;
end