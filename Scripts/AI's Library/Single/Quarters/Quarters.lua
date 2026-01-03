local terminalActivated = false
local quarters = nil
local isShellLoaded = false

function InitialSetup()
    AllowRandomTracks(false)
end

function Start()
    quarters = GetHandle("unnamed_quarters")
end

function Update()
    local p = GetPlayerHandle(1)

    if (not terminalActivated and AtTerminal(p) == quarters) then
        -- Set the terminal to activated.
        terminalActivated = true

        FreeCamera()

        if (not isShellLoaded) then
            IFace_Exec("bzshell_single.cfg")
            isShellLoaded = true
        end

        IFace_Activate("ShellSingle")
    end
end