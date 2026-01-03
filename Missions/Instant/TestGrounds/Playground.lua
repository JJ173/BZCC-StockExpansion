local _Discord = require("_Discord")
local _VoiceManager = require("_VoiceManager")

local DiscordStarted = false

function Start()
    local mode = "Instant Action"
    local mapTrn = GetMissionFilename()

    _Discord:Start(mode, mapTrn)
    DiscordStarted = true
end

function Update()
    if DiscordStarted then
        _Discord:Update()
    end
end

function PreGetIn(cutWorld, pilotHandle, emptyCraftHandle)
    -- Apply a skin to the unit if it is a player.
    if (IsPlayer(pilotHandle)) then
        ApplySkinToHandle(GetPlayerName(pilotHandle), emptyCraftHandle, GetTeamNum(pilotHandle));
    end

    -- Run our replacement script logic.
    _VoiceManager.SwitchVehicleVoices(emptyCraftHandle, pilotHandle);

    -- Always allow the entry
    return PREGETIN_ALLOW;
end