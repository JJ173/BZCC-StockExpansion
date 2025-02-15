-- Return this to whatever file calls it.
Condor =
{
    -- Handle for generic use.
    Handle = 0,

    -- Team so we know what to print.
    Team = 0,

    -- Checks to see if this unit already has a unit defending it.
    Type = "",

    -- Checks to see if this unit already has a unit servicing it.
    LandingPad = 0,

    -- Flags so we don't double logic.
    CondorBuilt = false,
    CondorReplaced = false,
    CondorUnitsBuilt = false,
    CondorDoorsOpen = false,

    -- So we know we can delete it from other scripts.
    ReadyToDelete = false,

    -- Delays for animations and such.
    DelayTime = 0
}

-- These ar etables of units that are built depending on the type.
local ScavReinforcements = {};
local TurretReinforcements = {};
local LightReinforcements = {};
local ScrapReinforcements = {};

-- Testing
local units = nil;

function Condor:New(Handle, Team, Type, LandingPad)
    local o = {}

    o.Handle = Handle or 0;
    o.Team = Team or 0;
    o.Type = Type or "";
    o.LandingPad = LandingPad or 0;

    setmetatable(o, { __index = self });

    return o;
end

function Condor:Run(missionTurnCount)
    -- Do some safety checks first. Do not run this if the Landing Pad is missing.
    if (self.LandingPad == 0) then
        return print(
            "Warning: A Condor was sent to land but the landing pad for team " ..
            self.Team .. " could not be found on the map. If you see this, please report this as a bug. Thank you.");
    end

    if (self.Type == "") then
        return print(
            "Warning: A Condor was sent with an invalid type for team " ..
            self.Team .. " If you see this, please report this as a bug. Thank you.");
    end

    -- Spawn the Condor at the Landing Pad.
    if (self.DelayTime < missionTurnCount) then
        if (self.CondorBuilt == false) then
            local landingPos = GetPosition(self.LandingPad);
            landingPos.y = landingPos.y + 2;
            self.Handle = BuildObject("ivdrop_land_x", self.Team, BuildDirectionalMatrix(landingPos));

            -- Show the engine FX.
            StartEmitter(self.Handle, 1);
            StartEmitter(self.Handle, 2);

            -- Have it land.
            SetAnimation(self.Handle, "land", 1);

            -- For replacement in the brain function so it can open doors.
            self.DelayTime = missionTurnCount + SecondsToTurns(14);

            -- So we don't loop.
            self.CondorBuilt = true;
        elseif (self.CondorReplaced == false) then
            self.Handle = ReplaceObject(self.Handle, "ivpdrop_x");

            -- Tiny delay before building units.
            self.DelayTime = missionTurnCount + SecondsToTurns(2);

            self.CondorReplaced = true;
        elseif (self.CondorUnitsBuilt == false) then
            MaskEmitter(self.Handle, 0);
            SetAnimation(self.Handle, "deploy", 1);

            -- Handle what units are built.

            -- Just for debugging.
            local pos = GetPosition(self.LandingPad);
            pos.y = pos.y + 5;
            units = BuildObject("ivscav_x", self.Team, BuildDirectionalMatrix(pos));

            -- Small delay for sound.
            self.DelayTime = missionTurnCount + SecondsToTurns(2.5);

            self.CondorUnitsBuilt = true;
        elseif (self.CondorDoorsOpen == false) then
            -- Calculate the drop-off for the units to move to.
            local dropOff = GetPosition(self.LandingPad) + (GetFront(self.LandingPad) * 75);

            -- Build a nav just so we can see where it's going.
            local testNav = BuildObject("ibnav", 1, dropOff);
            SetObjectiveName(testNav, "Drop-off");
            SetObjectiveOn(testNav);
        
            Goto(units, dropOff, 0);

            -- Play the door sound effect.
            StartSoundEffect("dropdoor.wav", self.Handle);
            self.CondorDoorsOpen = true;
        end
    end
end

return Condor;
