--[[
    This file contains all of the common functions for multiplayer.
    Written by AI_Unit.
--]]

_Multiplayer = {
    m_ElapsedGameTime = 0,
};

-------------------------------------------------------------------------------
-- Requirements
-------------------------------------------------------------------------------

local _VoiceManager = require('_VoiceManager');

-------------------------------------------------------------------------------
-- Types
-------------------------------------------------------------------------------

--- A handle to a game object. This is a unique identifier for the object in the game world.
--- @class Handle

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

--- ### This is the primary function that runs every game turn. This is where most mission logic will run.
--- #### Note: In C++ side, this is called Execute().
function _Multiplayer.Update(m_GameTPS)

end

--- ### This function is called at the End of the mission, shortly before game returns to the Shell UI.
function _Multiplayer.PostRun()

end

--- ### This function is called when a player joins the game.
--- @param id integer: This is the DPID number for this player.
--- @param team integer: This is the Team number for this player.
--- @param isNewPlayer boolean: This bool tells if it is a new player or not.
function _Multiplayer.AddPlayer(id, team, isNewPlayer)

end

--- ### This function is called when a Player Leaves the game.
--- @param id integer: This is the DPID number for this player.
function _Multiplayer.DeletePlayer(id)

end

--- ### This function is called when a Player Ejects.
--- #### Note: Must return a valid value from EjectKillRetCodes table.
--- #### Note: For this to function on Non Player craft, WantBotKillMessages() must be enabled.
--- @param deadObjectHandle Handle: This is the Handle ID for the now Dead object that was ejected out of.
function _Multiplayer.PlayerEjected(deadObjectHandle)

end

--- ### This function is called when a GameObject is Killed by another object.
--- @param deadObjectHandle Handle: This is the Handle ID for the now Dead object that was just blown up.
--- @param killersHandle Handle: This is the Handle ID for the object that killed this object, if present.
--- #### Note: Must return a valid value from EjectKillRetCodes table.
--- #### Note: For this to function on Non Player craft, WantBotKillMessages() must be enabled.
function _Multiplayer.ObjectKilled(deadObjectHandle, killersHandle)

end

--- ### This function is called when a GameObject is Sniped by another object.
--- @param deadObjectHandle Handle: This is the Handle ID for the now Dead object that was just sniped.
--- @param killersHandle Handle: This is the Handle ID for the object that killed this object, if present.
--- #### Note: Must return a valid value from EjectKillRetCodes table.
--- #### Note: For this to function on Non Player craft, WantBotKillMessages() must be enabled.
function _Multiplayer.ObjectSniped(deadObjectHandle, killersHandle)

end

--- ### This function is called when an Ordnance hits an Object.
--- @param shooterHandle Handle: This is the Handle ID of the Shooter.
--- @param victimHandle Handle: This is the Handle ID of the object hit.
--- @param ordnanceTeam integer: This is the Team number of the Ordnance, if applicable.
--- @param ordnanceODF string: This is the .ODF file of the Ordnance that hit the VictimHandle.
function _Multiplayer.PreOrdnanceHit(shooterHandle, victimHandle, ordnanceTeam, ordnanceODF)

end

--- ### This function is called when a Pilot attempts to enter an Empty craft.
--- @param curWorld integer: The current MP World. If you do anything that effects the world, ensure curWorld is 0 to avoid MP Resyncs.
--- @param pilotHandle Handle: Handle ID of the Pilot.
--- @oaram emptyCraftHandle Handle: Handle ID of the Empty craft.
--- #### Note: Must return a valid value from PreGetInReturnCodes table.
function _Multiplayer.PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
    -- Safety, do not do this if we are not in the lockstep world.
    if (curWorld ~= 0) then return end;
end

--- ### This function is called when a SniperShell Ordnance hits an Object and would successfully trigger a Snipe.
--- @param curWorld integer: The current MP World. If you do anything that effects the world, ensure curWorld is 0 to avoid MP Resyncs.
--- @param shooterHandle Handle: This is the Handle ID of the Shooter.
--- @param victimHandle Handle: This is the Handle ID of the object hit.
--- @param ordnanceTeam integer: This is the Team number of the Ordnance, if applicable.
--- @param ordnanceODF string: This is the .ODF file of the Ordnance that hit the VictimHandle.
--- #### Note: Must return a valid value from PreSnipeReturnCodes table.
function _Multiplayer.PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, ordnanceODF)
    -- Safety, do not do this if we are not in the lockstep world.
    if (curWorld ~= 0) then return end;
end

--- ### This function is called when a Powerup is attempted to be Picked Up.
--- @param curWorld integer: The current MP World. If you do anything that effects the world, ensure curWorld is 0 to avoid MP Resyncs.
--- @param me Handle: This is the Handle ID of the object picking up the Powerup.
--- @param powerUpHandle Handle: This is the Handle ID of the powerup object.
--- #### Note: Must return a valid value from PrePickupPowerupReturnCodes table.
function _Multiplayer.PrePickupPowerup(curWorld, me, powerUpHandle)
    -- Safety, do not do this if we are not in the lockstep world.
    if (curWorld ~= 0) then return end;
end

--- ### This function is called when an object changes Targets.
--- @param craft Handle: The object that just changed Targets.
--- @param previousTarget Handle: This is the Handle ID of the previous Target.
--- @param currentTarget Handle: This is the Handle ID of the new Target.
function _Multiplayer.PostTargetChangedCallback(craft, previousTarget, currentTarget)

end

--- ### This function returns the specified team's next respawn ODF.
--- @param team integer: This is the Team number specified for filtering.
function _Multiplayer.GetNextRandomVehicleODF(team)

end

--- ### Processes a Command as an input from the user.
--- @param CRC integer
function _Multiplayer.ProcessCommand(CRC)

end

--- ### Sets the Random Seed generator to a specific value.
--- @param seed integer: This is the random seed to use.
function _Multiplayer.SetRandomSeed(seed)

end

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

--- Called from Execute, m_GameTPS of a second has elapsed. Update everything.
function _Multiplayer.UpdateGameTime(m_GameTPS)
    _Multiplayer.m_ElapsedGameTime = _Multiplayer.m_ElapsedGameTime + 1;

    if (_Multiplayer.m_ElapsedGameTime % m_GameTPS == 0) then
        local seconds = _Multiplayer.m_ElapsedGameTime / m_GameTPS;
        local minutes = seconds / 60;
        local hours = minutes / 60;
        local msgString = '';

        seconds = seconds % 60;
        minutes = minutes % 60;

        if (hours > 0) then
            msgString = TranslateString("mission", ("Mission Time %d:%02d:%02d"):format(hours, minutes, seconds));
        else
            msgString = TranslateString("mission", ("Mission Time %d:%02d"):format(minutes, seconds));
        end

        SetTimerBox(msgString);
    end
end

return _Multiplayer;
