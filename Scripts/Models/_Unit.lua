-- Return this to whatever file calls it.
Unit =
{
    Team = 0,
    Handle = 0,
    Command = 0
};

function Unit:New(Team, Handle, Command)
    local o = {}

    setmetatable(o, { __index = self });

    o.Team = Team or 0;
    o.Handle = Handle or 0;
    o.Command = Command or 0;

    return o;
end

function Unit:Patrol(path)
    -- Set the unit to patrol along a given path.
    Patrol(self.Handle, path, 1);

    -- We should track the command of this unit before setting it. That way, if a unit fails to execute, we will know.
    -- Is not "CMD_PATROL"?
    if (GetCurrentCommand(self.Handle) == CMD_GO) then
        -- Update the command so it's not used in any future checks.
        self.Command = CMD_GO;
    end
end

function Unit:Attack(target)
    -- Have this guy attack.
    Attack(self.Handle, target, 1);

    -- We should track the command of this unit before setting it. That way, if a unit fails to execute, we will know.
    if (GetCurrentCommand(self.Handle) == CMD_ATTACK) then
        -- Update the command so it's not used in any future checks.
        self.Command = CMD_ATTACK;
    end
end

function Unit:GoTo(path)
    -- Have this guy move to a given vector.
    Goto(self.Handle, path, 1);

    -- We should track the command of this unit before setting it. That way, if a unit fails to execute, we will know.
    if (GetCurrentCommand(self.Handle) == CMD_GO) then
        -- Update the command so it's not used in any future checks.
        self.Command = CMD_GO;
    end
end

function Unit:Defend(target)
    -- Have this guy defend a target.
    Defend2(self.Handle, target, 1);

    -- We should track the command of this unit before setting it. That way, if a unit fails to execute, we will know.
    if (GetCurrentCommand(self.Handle) == CMD_DEFEND) then
        -- Update the command so it's not used in any future checks.
        self.Command = CMD_DEFEND;
    end
end

return Unit;
