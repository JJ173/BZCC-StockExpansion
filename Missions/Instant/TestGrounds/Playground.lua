local _Discord = require("_Discord")

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
