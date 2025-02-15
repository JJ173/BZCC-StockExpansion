-- Return this to whatever file calls it.
Condor =
{
    -- Handle for generic use.
    Handle = 0,

    -- Team so we know what to print.
    Team = 0,

    -- Checks to see if this unit already has a unit defending it.
    Type = "",

    -- Total of units we should spawn depending on type.
    UnitTotal = 0,

    -- Checks to see if this unit already has a unit servicing it.
    LandingPad = 0,

    -- Flags so we don't double logic.
    CondorState = 0,

    -- So we know we can delete it from other scripts.
    ReadyToDelete = false,

    -- Delays for animations and such.
    DelayTime = 0
}

-- Store the units here so we know when to move them.
local CondorUnits = {};

function Condor:New(Handle, Team, Type, LandingPad, UnitTotal)
    local o = {}

    o.Handle = Handle or 0;
    o.Team = Team or 0;
    o.Type = Type or "";
    o.LandingPad = LandingPad or 0;
    o.UnitTotal = UnitTotal or 0;

    setmetatable(o, { __index = self });

    return o;
end

function Condor:Run(missionTurnCount)
    -- So we don't run once we've complete.
    if (self.ReadyToDelete) then
        return;
    end

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
        if (self.CondorState == 0) then
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
            self.CondorState = self.CondorState + 1;
        elseif (self.CondorState == 1) then
            self.Handle = ReplaceObject(self.Handle, "ivpdrop");

            -- Tiny delay before building units.
            self.DelayTime = missionTurnCount + SecondsToTurns(2);

            -- So we don't loop.
            self.CondorState = self.CondorState + 1;
        elseif (self.CondorState == 2) then
            MaskEmitter(self.Handle, 0);
            SetAnimation(self.Handle, "deploy", 1);

            -- Starting point for spawns
            local posXDiscrim = 8;
            local posZDiscrim = 5;

            local pos = GetPosition(self.LandingPad);
            pos.y = pos.y + 5;
            local originalPos = pos;

            -- Handle what units are built.
            for i = 1, self.UnitTotal do
                if (i == 2) then
                    pos.z = pos.z - posZDiscrim;
                    pos.x = pos.x + posXDiscrim;
                elseif (i == 3) then
                    pos.z = pos.z - posZDiscrim;
                    pos.x = pos.x - posXDiscrim;
                end


                if (self.Type == "TurretDropship") then
                    CondorUnits[#CondorUnits + 1] = BuildObject("ivturr_xm", self.Team, BuildDirectionalMatrix(pos));
                elseif (self.Type == "LightDropship") then
                    if (i == 1) then
                        CondorUnits[#CondorUnits + 1] = BuildObject("ivscout_xm", self.Team, BuildDirectionalMatrix(pos));
                    else
                        CondorUnits[#CondorUnits + 1] = BuildObject("ivmisl_xm", self.Team, BuildDirectionalMatrix(pos));
                    end
                elseif (self.Type == "ScrapDropship") then
                    CondorUnits[#CondorUnits + 1] = BuildObject("ivscrap_c", self.Team, BuildDirectionalMatrix(pos));
                elseif (self.Type == "Scavenger") then
                    CondorUnits[#CondorUnits + 1] = BuildObject("ivscav_xm", self.Team, BuildDirectionalMatrix(pos));
                end

                pos = originalPos;
            end

            -- Small delay for sound.
            self.DelayTime = missionTurnCount + SecondsToTurns(2.5);

            -- So we don't loop.
            self.CondorState = self.CondorState + 1;
        elseif (self.CondorState == 3) then
            -- Calculate the drop-off for the units to move to.
            local dropOff = GetPosition(self.LandingPad) + (GetFront(self.LandingPad) * 75);

            -- Send the units out of the dropship.
            if (#CondorUnits > 0) then
                for i = 1, #CondorUnits do
                    local unit = CondorUnits[i];

                    if (i == 1) then
                        Goto(unit, dropOff, 0);
                    else
                        Follow(unit, CondorUnits[1], 0);
                    end
                end
            end

            -- Play the door sound effect.
            StartSoundEffect("dropdoor.wav", self.Handle);

            -- So we don't loop.
            self.CondorState = self.CondorState + 1;
        elseif (self.CondorState == 4) then
            -- Check to make sure that all of the units are clear of the dropship.
            local distCheck = CountUnitsNearObject(self.Handle, 20, self.Team, nil);

            -- This should only include the dropship and the landing pad.
            if (distCheck == 2) then
                -- Start the take-off sequence.
                SetAnimation(self.Handle, "takeoff", 1);

                -- Show the engine FX.
                StartEmitter(self.Handle, 1);
                StartEmitter(self.Handle, 2);

                -- Engine sound.
                StartSoundEffect("dropleav.wav", self.Handle);

                -- Tiny delay before building units.
                self.DelayTime = missionTurnCount + SecondsToTurns(15);

                -- So we don't loop.
                self.CondorState = self.CondorState + 1;
            end
        elseif (self.CondorState == 5) then
            -- Remove the Dropship.
            RemoveObject(self.Handle);

            -- Script is complete. Ready to delete.
            self.ReadyToDelete = true;
        end
    end
end

return Condor;
