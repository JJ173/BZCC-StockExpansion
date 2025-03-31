Portal =
{
    Handle = 0,
    Team = 0,
    Type = "",
    UnitTotal = 0,
    DelayTime = 0,
    TeleportedUnitCount = 0,
    PortalHandle = 0,
    ReadyToDelete = false,
}

function Portal:New(Handle, Team, Type, PortalHandle, UnitTotal)
    local o = {}

    o.Handle = Handle or 0;
    o.Team = Team or 0;
    o.Type = Type or "";
    o.UnitTotal = UnitTotal or 0;
    o.PortalHandle = PortalHandle or 0;
    o.DelayTime = 0;
    o.TeleportedUnitCount = 0;
    o.ReadyToDelete = false;

    setmetatable(o, { __index = self });

    return o;
end

function Portal:Run(MissionTurnCount)
    -- So we don't run once we've complete.
    if (self.ReadyToDelete) then
        return;
    end

    if (self.DelayTime > MissionTurnCount) then
        return;
    end

    -- Check if the portal is ready to delete.
    if (self.TeleportedUnitCount >= self.UnitTotal) then
        self.ReadyToDelete = true;
    end

    -- Store the built unit locally.
    local teleportedUnit = nil;

    -- Increment the teleported unit count.
    self.TeleportedUnitCount = self.TeleportedUnitCount + 1;

    -- Teleport units out of the portal.
    if (self.Type == "TurretDropship") then
        teleportedUnit = TeleportIn("fvturr_xm", self.Team, self.PortalHandle, 10);
    elseif (self.Type == "LightDropship") then
        if (self.TeleportedUnitCount == 1) then
            teleportedUnit = TeleportIn("fvscout_xm", self.Team, self.PortalHandle, 10);
        else
            teleportedUnit = TeleportIn("fvsent_xm", self.Team, self.PortalHandle, 10);
        end
    elseif (self.Type == "ScrapDropship") then
        teleportedUnit = TeleportIn("fvscrap_c", self.Team, self.PortalHandle, 10);
    elseif (self.Type == "ScavengerDropship") then
        teleportedUnit = TeleportIn("fvscav_xm", self.Team, self.PortalHandle, 10);
    end

    -- Calculate the drop-off for the units to move to.
    local dropOff = GetPosition(self.PortalHandle) + (GetFront(self.PortalHandle) * 75);

    -- Move the unit to the north of the portal handle.
    Goto(teleportedUnit, dropOff, 0);

    -- Create a small delay for the next unit.
    self.DelayTime = MissionTurnCount + SecondsToTurns(1);
end

return Portal;
