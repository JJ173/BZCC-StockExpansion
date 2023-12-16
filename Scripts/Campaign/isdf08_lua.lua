--[[ 
    BZCC ISDF08 Lua Mission Script
    Written by AI_Unit
    Version 1.0 28-11-2023
--]]

-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")),"_requirefix.lua"))();

-- Required Globals.
require("_GlobalVariables");

-- Required helper functions.
require("_HelperFunctions");

-- Cooperative.
local _Cooperative = require("_Cooperative");

-- Subtitles.
local _Subtitles = require('_Subtitles');

-- Game TPS.
local m_GameTPS = 20;

-- Name of file.
local fileName = "BZX_BASE_SAVE.txt";

-- Mission important variables.
local Mission = 
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "ispilo_x";
    -- Specific to mission.
    m_PlayerShipODF = "ivtank_x";

    m_Shabayev = nil,
    m_Nav = nil,
    m_Jak1 = nil,
    m_Jak2 = nil,
    m_Jak3 = nil,
    m_Jak4 = nil,
    m_Jak5 = nil,
    m_Gun1 = nil,
    m_Gun2 = nil,
    m_Start1 = nil,
    m_Start2 = nil,
    m_Start3 = nil,
    m_Scout1 = nil,
    m_Scout2 = nil,
    m_Unit1 = nil,
    m_Unit2 = nil,
    m_Unit3 = nil,
    m_Unit4 = nil,
    m_Unit5 = nil,
    m_Manson = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionOver = false,
    m_Gun1Attack = false,
    m_Gun1Idle = false,
    m_Gun2Attack = false,
    m_Gun2Idle = false,
    m_Played0804 = false,
    m_Played0805 = false,
    m_Played0806 = false,
    m_Played0807 = false,
    m_Played0808 = false,
    m_Played0809 = false,
    m_Jak1Attack = false,
    m_Jak2Attack = false,
    m_Jak3Attack = false,
    m_Jak4Attack = false,
    m_Jak5Attack = false,
    m_TriggerAttack = false,
    m_AttackMansonUnits = false,

    m_Audioclip = nil,

    -- Keep track of which functions are running.
    m_MissionState = 1
}

-- Functions Table
local Functions = {};

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
function InitialSetup()
    -- Check if we are cooperative mode.
    Mission.m_IsCooperativeMode = IsNetworkOn();

    -- Enable high TPS.
    m_GameTPS = EnableHighTPS();

    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    if (Mission.m_IsCooperativeMode) then
        WantBotKillMessages();
    end

    -- Preload to save load times.
    PreloadODF("ivrecy_x");
    PreloadODF("fvrecy_x");
end

function Save() 
    return Mission;
end

function Load(MissionData)
    -- Enable high TPS.
    m_GameTPS = EnableHighTPS();

    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- Load mission data.
	Mission = MissionData;
end

function AddObject(h)
    -- Handle unit skill for enemy.
    if (GetTeamNum(h) == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);       
    end
end

function Start()
    -- Set difficulty based on whether it's coop or not.
    if (Mission.m_IsCooperativeMode) then
        Mission.m_MissionDifficulty = GetVarItemInt("network.session.ivar102") + 1;
    else
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1;
    end

    -- Few prints to console.
    print("Welcome to ISDF08 (Lua)");
    print("Written by AI_Unit");
    
    if (Mission.m_IsCooperativeMode) then
        print("Cooperative mode enabled: Yes");
    else
        print("Cooperative mode enabled: No");
    end

    print("Chosen difficulty: " .. Mission.m_MissionDifficulty);
    print("Good luck and have fun :)");

    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Ally teams to be sure.
    Ally(Mission.m_HostTeam, Mission.m_AlliedTeam);

    -- Remove the player ODF that is saved as part of the BZN.
    local PlayerEntryH = GetPlayerHandle();

	if (PlayerEntryH ~= nil) then
		RemoveObject(PlayerEntryH);
	end

    -- Get Team Number.
    local LocalTeamNum = GetLocalPlayerTeamNumber();

    -- Create the player for the server.
    local PlayerH = _Cooperative.SetupPlayer(LocalTeamNum, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, true, 0.2);

    -- Make sure we give the player control of their ship.
    SetAsUser(PlayerH, LocalTeamNum);

    -- Grab all of our pre-placed handles.
    Mission.m_Shabayev = GetHandle("shabayev");
    Mission.m_Gun1 = GetHandle("gun1");
    Mission.m_Gun2 = GetHandle("gun2");
    Mission.m_Unit1 = GetHandle("unit1");
    Mission.m_Unit2 = GetHandle("unit2");
    Mission.m_Unit3 = GetHandle("unit3");
    Mission.m_Unit4 = GetHandle("unit4");
    Mission.m_Unit5 = GetHandle("unit5");
    Mission.m_Manson = GetHandle("manson");

    -- Set Manson's team to blue.
    SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;
end

function Update()
    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Start mission logic.
    if (not Mission.m_MissionOver) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Brain for the Scion team.
            ScionBrain();
            JakBrain();
        end
    end

    -- Need to keep checking if the player is out of their ship and give them the satchel.
    for i = 1, _Cooperative.m_TotalPlayerCount do
        local p = GetPlayerHandle(i);

        if (IsPerson(p) and GetWeaponODF(p, 2) ~= "igsatc.odf") then
            GiveWeapon(p, "igsatc");
        end
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, true, 0.2);
end

function PlayerEjected(DeadObjectHandle)
    return _Cooperative.PlayerEjected(DeadObjectHandle);
end

function ObjectKilled(DeadObjectHandle, KillersHandle)
    return _Cooperative.ObjectKilled(DeadObjectHandle, KillersHandle, Mission.m_PlayerPilotODF);
end

function ObjectSniped(DeadObjectHandle, KillersHandle)
    return _Cooperative.ObjectSniped(DeadObjectHandle, KillersHandle, Mission.m_PlayerPilotODF);
end

function PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF)
    return _Cooperative.PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF);
end

function PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
	return _Cooperative.PreGetIn(curWorld, pilotHandle, emptyCraftHandle);
end

function RespawnPilot(DeadObjectHandle, Team)
    return _Cooperative.RespawnPilot(DeadObjectHandle, Team, Mission.m_PlayerPilotODF);
end

function DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI)
    return _Cooperative.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI, Mission.m_PlayerPilotODF);
end

function PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
    if (IsPlayer(ShooterHandle) and OrdnanceTeam == Mission.m_HostTeam) then
        if (VictimHandle == Mission.m_Start1) then
            Attack(Mission.m_Start1, ShooterHandle);
        elseif (VictimHandle == Mission.m_Start2) then
            Attack(Mission.m_Start2, ShooterHandle);
        elseif (VictimHandle == Mission.m_Start3) then
            Attack(Mission.m_Start3, ShooterHandle);
        elseif (VictimHandle == Mission.m_Scout1) then
            Attack(Mission.m_Scout1, ShooterHandle);
        elseif (VictimHandle == Mission.m_Scout2) then
            Attack(Mission.m_Scout2, ShooterHandle);
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Place the player's old base from the previous mission.
    PlacePlayerBase();

    -- Clean up any player spawns that haven't been taken by the player.
    CleanSpawns();

    -- Create our first nav.
    Mission.m_Nav = BuildObject("ibnav", Mission.m_HostTeam, "manson_base");

    -- Name the nav
    SetObjectiveName(Mission.m_Nav, "West Base");

    -- Inhabit the swamp with Jaks
    Mission.m_Jak1 = BuildObject("mcjak01", 0, "jak_1");
    Mission.m_Jak2 = BuildObject("mcjak01", 0, "jak_2");
    Mission.m_Jak3 = BuildObject("mcjak01", 0, "jak_3");

    -- Make them smart.
    SetIndependence(Mission.m_Jak1, 1);
    SetIndependence(Mission.m_Jak2, 1);
    SetIndependence(Mission.m_Jak3, 1);

    -- Have them patrol.
    Patrol(Mission.m_Jak1, "jak_1_patrol", 1);
    Patrol(Mission.m_Jak2, "jak_2_patrol", 1);
    Patrol(Mission.m_Jak3, "jak_3_patrol", 1);

    -- Inhabit ruins with Jaks
    Mission.m_Jak4 = BuildObject("mcjak01", 0, "jak_4");
    Mission.m_Jak5 = BuildObject("mcjak01", 0, "jak_5");

    -- Make them smart.
    SetIndependence(Mission.m_Jak4, 1);
    SetIndependence(Mission.m_Jak5, 1);

    -- Create starting Scion swarm units.
    Mission.m_Start1 = BuildObject("fvtank_x", Mission.m_EnemyTeam, "start_1");
    Mission.m_Start2 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "start_2");
    Mission.m_Start3 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "start_3");

    -- Make them dumb.
    SetIndependence(Mission.m_Start1, 0);
    SetIndependence(Mission.m_Start2, 0);
    SetIndependence(Mission.m_Start3, 0);

    -- Have them move along their paths.
    Goto(Mission.m_Start1, "move_1");
    Goto(Mission.m_Start2, "move_3");
    Goto(Mission.m_Start3, "move_3");

    -- Build the patrols
    Mission.m_Scout1 = BuildObject("fvtank_x", Mission.m_EnemyTeam, "scout1");
    Mission.m_Scout2 = BuildObject("fvtank_x", Mission.m_EnemyTeam, "scout2");

    -- Get them to patrol.
    Patrol(Mission.m_Scout1, "patrol_1");
    Patrol(Mission.m_Scout2, "patrol_2");

    -- Build some turrets around the choke point.
    BuildObject("fvturr_x", Mission.m_EnemyTeam, "turret_1");
    BuildObject("fvturr_x", Mission.m_EnemyTeam, "turret_2");

    -- Start with Shabayev's audio
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("mes0801.wav", true);

    -- Have her animate.
    SetAnimation(Mission.m_Shabayev, "speak");

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Stop the animation.
        SetAnimation(Mission.m_Shabayev, "speak", 1);

        -- Set our objectives.
        AddObjective("isdf0801.otf", "WHITE", 15);

        -- Highlight our objective nav.
        SetObjectiveOn(Mission.m_Nav);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    -- Persistent checks to see if the player is in any of the swamps.
    for i = 1, _Cooperative.m_TotalPlayerCount do
        local p = GetPlayerHandle(i);

        local check1 = GetDistance(p, "swamp_1") < 50;
        local check2 = GetDistance(p, "swamp_2") < 50;
        local check3 = GetDistance(p, "swamp_3") < 50;
        local check4 = GetDistance(p, "swamp_4") < 50;
        local check5 = GetDistance(p, "swamp_5") < 50;
        local check6 = GetDistance(p, "swamp_6") < 50;
        local check7 = GetDistance(p, "swamp_7") < 50;

        -- This makes sure the patrols ignore the player when they are underwater.
        if (check1 or check2 or check3 or check4 or check5 or check6 or check7) then
            -- Change this player to the enemy team.
            SetPerceivedTeam(p, Mission.m_EnemyTeam);   
            
            -- Have the scouts become a bit stupid.
            SetIndependence(Mission.m_Scout1, 0);

            -- Have the scouts become a bit stupid.
            SetIndependence(Mission.m_Scout2, 0);
        else
            -- Change this player to the enemy team.
            SetPerceivedTeam(p, Mission.m_HostTeam);   
            
            -- Have the scouts become a bit stupid.
            SetIndependence(Mission.m_Scout1, 0);

            -- Have the scouts become a bit stupid.
            SetIndependence(Mission.m_Scout2, 0);
        end

        if (not Mission.m_TriggerAttack and (GetDistance(p, "exit_ruins_1") < 200 or GetDistance(p, "exit_ruins_2") < 200)) then
            -- Shab: "Three Scion Vehicles are coming...".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0808.wav");     

            -- Send units to attack.
            Attack(Mission.m_Start1, p);
            Attack(Mission.m_Start2, p);
            Attack(Mission.m_Start3, p);

            -- So we don't loop.
            Mission.m_TriggerAttack = true;
        end

        if (Mission.m_TriggerAttack) then
            if (not Mission.m_Played0809 and (GetDistance(Mission.m_Start1, p) < 300 or GetDistance(Mission.m_Start2, p) < 300 or GetDistance(Mission.m_Start3, p) < 300)) then
                -- Shab: "They're 300 meters from you!"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0809.wav");

                -- So we don't loop.
                Mission.m_Played0809 = true;
            end
        end
    end

    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- This will be mostly distance checks.
        if (not Mission.m_Played0804 and IsPlayerWithinDistance("play_0804", 80, _Cooperative.m_TotalPlayerCount)) then
            -- Shab: "The patrols won't be searching for you".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0804.wav");

            -- So we don't loop.
            Mission.m_Played0804 = true;
        end

        if (not Mission.m_Played0805 and IsPlayerWithinDistance("play_0805", 80, _Cooperative.m_TotalPlayerCount)) then
            -- Shab: "Use the swamp to your advantage...".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0805.wav");

            -- So we don't loop.
            Mission.m_Played0805 = true;
        end

        if (not Mission.m_Played0805 and IsPlayerWithinDistance("alchemator", 100, _Cooperative.m_TotalPlayerCount)) then
            -- Shab: "Use the swamp to your advantage...".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0807.wav");

            -- So we don't loop.
            Mission.m_Played0805 = true;
        end

        if (not Mission.m_Played0806 and IsPlayerWithinDistance("turret_1", 150, _Cooperative.m_TotalPlayerCount)) then
            -- Shab: "What are you doing? Head West".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0806.wav");

            -- So we don't loop.
            Mission.m_Played0806 = true;
        end

        -- This is to advance the mission state.
        if (IsPlayerWithinDistance("enterbase_1", 100, _Cooperative.m_TotalPlayerCount) or IsPlayerWithinDistance("enterbase_2", 100, _Cooperative.m_TotalPlayerCount) or IsPlayerWithinDistance("enterbase_3", 100, _Cooperative.m_TotalPlayerCount)) then            
            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[4] = function()
    -- Send a rescue team to attack.
    if (GetCurrentCommand(Mission.m_Unit1) == CMD_NONE) then
        if (IsAlive(Mission.m_Start1)) then
            Attack(Mission.m_Unit1, Mission.m_Start1);
        elseif (IsAlive(Mission.m_Start2)) then
            Attack(Mission.m_Unit1, Mission.m_Start2);
        elseif (IsAlive(Mission.m_Start3)) then
            Attack(Mission.m_Unit1, Mission.m_Start3);
        end
    end

    if (GetCurrentCommand(Mission.m_Unit2) == CMD_NONE) then
        if (IsAlive(Mission.m_Start1)) then
            Attack(Mission.m_Unit2, Mission.m_Start1);
        elseif (IsAlive(Mission.m_Start2)) then
            Attack(Mission.m_Unit2, Mission.m_Start2);
        elseif (IsAlive(Mission.m_Start3)) then
            Attack(Mission.m_Unit2, Mission.m_Start3);
        end
    end

    if (GetCurrentCommand(Mission.m_Unit3) == CMD_NONE) then
        if (IsAlive(Mission.m_Start1)) then
            Attack(Mission.m_Unit3, Mission.m_Start1);
        elseif (IsAlive(Mission.m_Start2)) then
            Attack(Mission.m_Unit3, Mission.m_Start2);
        elseif (IsAlive(Mission.m_Start3)) then
            Attack(Mission.m_Unit3, Mission.m_Start3);
        end
    end

    if (GetCurrentCommand(Mission.m_Unit4) == CMD_NONE) then
        if (IsAlive(Mission.m_Start1)) then
            Attack(Mission.m_Unit4, Mission.m_Start1);
        elseif (IsAlive(Mission.m_Start2)) then
            Attack(Mission.m_Unit4, Mission.m_Start2);
        elseif (IsAlive(Mission.m_Start3)) then
            Attack(Mission.m_Unit4, Mission.m_Start3);
        end
    end

    -- This does a check to make sure the player is in the base.
    if (IsPlayerWithinDistance(Mission.m_Nav, 150, _Cooperative.m_TotalPlayerCount)) then
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    if (not IsAlive(Mission.m_Start1) and not IsAlive(Mission.m_Start2) and not IsAlive(Mission.m_Start3)) then
        -- Manson: You're showing a lot of promise.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0514.wav");

        -- Set our objectives.
        AddObjectiveOverride("isdf0801.otf", "GREEN", 15, true);

        -- Have Manson look at the main player.
        LookAt(Mission.m_Manson, GetPlayerHandle(1));

        -- Succeess.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(10);
        else
            SucceedMission(GetTime() + 10, "isdf08w1.txt");
        end

        -- Stop the mission.
        Mission.m_MissionOver = true;
    end
end

function PlacePlayerBase()
    -- Read the player file
    local file = LoadFile(fileName);

    if (file ~= nil) then
        print("Found file, building base...");

        -- Testing
        local lines = {};

        -- This adds each line to a table.
        for s in file:gmatch("[^\r\n]+") do
            -- Add line to table for later.
            lines[#lines + 1] = s;
        end

        -- Once each line has been added, we need to go through each one, get the ODF and the position, and use it to build.
        for i = 1, #lines do
            if (i > 1) then
                -- Grab the line as a variable to use.
                local line = lines[i];
                local odf, pos = line:match("([^.]*)-(.*)");
                local vectorValues = {}

                -- Need to try and create a Vector based on the position.
                for string in pos:gmatch("(%-*%d*%.%d*)") do
                    vectorValues[#vectorValues + 1] = string;
                end

                local cleanODF = odf:gsub("%s+", "");
                local vector = SetVector(vectorValues[1], TerrainFindFloor(vectorValues[1], vectorValues[3]), vectorValues[3]);
                local obj = BuildObject(cleanODF, 0, vector);

                -- If we are a Power Generator, or a Gun Tower, we should replace it with the destroyed version.s
                if (cleanODF == "ibpgen_x") then
                    obj = ReplaceObject(obj, "ibpgen01");
                elseif (cleanODF == "ibgtow_x") then
                    obj = ReplaceObject(obj, "ibgtow01");

                    -- Spawn some lurkers around the ruins.
                    local lurker1 = BuildObject("fvsent_x", Mission.m_EnemyTeam, GetPositionNear(obj, 40, 40));

                    -- So they look randomly
                    SetRandomHeadingAngle(lurker1);
                else
                    if (cleanODF == "ibrecy_x") then
                        -- Spawn some lurkers around the ruins.
                        local lurker1 = BuildObject("fvwalk_x", Mission.m_EnemyTeam, GetPositionNear(obj, 20, 20));
    
                        -- So they look randomly
                        SetRandomHeadingAngle(lurker1);
                    elseif (cleanODF == "ibcbun_x") then
                        -- Spawn some lurkers around the ruins.
                        local lurker1 = BuildObject("fvtank_x", Mission.m_EnemyTeam, GetPositionNear(obj, 40, 40));

                        -- So they look randomly
                        SetRandomHeadingAngle(lurker1);
                    end

                    -- To leave scrap and scorch marks, we'll destroy the rest.
                    Damage(obj, GetMaxHealth(obj) + 1);
                end
            end
        end
    else
        print("Base file not found.");
    end
end

function ScionBrain()
    for i = 1, _Cooperative.m_TotalPlayerCount do
        local p = GetPlayerHandle(i);

        if (IsAlive(Mission.m_Gun1)) then
            if (not Mission.m_Gun1Attack and GetDistance(Mission.m_Gun1, p) < 50) then
                -- Attack the closest player.
                Attack(Mission.m_Gun1, p);

                -- So we don't loop.
                Mission.m_Gun1Attack = true;
                Mission.m_Gun1Idle = false;
            elseif (not Mission.m_Gun1Idle and GetDistance(Mission.m_Gun1, p) > 50) then
                -- Attack the closest player.
                Defend(Mission.m_Gun1);

                -- So we don't loop.
                Mission.m_Gun1Idle = true;
                Mission.m_Gun1Attack = false;
            end
        end

        if (IsAlive(Mission.m_Gun2)) then
            if (not Mission.m_Gun2Attack and GetDistance(Mission.m_Gun2, p) < 50) then
                -- Attack the closest player.
                Attack(Mission.m_Gun2, p);

                -- So we don't loop.
                Mission.m_Gun2Attack = true;
                Mission.m_Gun2Idle = false;
            elseif (not Mission.m_Gun2Idle and GetDistance(Mission.m_Gun2, p) > 50) then
                -- Attack the closest player.
                Defend(Mission.m_Gun2);

                -- So we don't loop.
                Mission.m_Gun2Idle = true;
                Mission.m_Gun2Attack = false;
            end
        end
    end

    -- Checks
    if (not Mission.m_AttackMansonUnits) then
        local check1 = GetDistance(Mission.m_Unit1, Mission.m_Start1) < 50;
        local check2 = GetDistance(Mission.m_Unit2, Mission.m_Start1) < 50;
        local check3 = GetDistance(Mission.m_Unit3, Mission.m_Start1) < 50;
        local check4 = GetDistance(Mission.m_Unit4, Mission.m_Start1) < 50;

        local check5 = GetDistance(Mission.m_Unit1, Mission.m_Start2) < 50;
        local check6 = GetDistance(Mission.m_Unit2, Mission.m_Start2) < 50;
        local check7 = GetDistance(Mission.m_Unit3, Mission.m_Start2) < 50;
        local check8 = GetDistance(Mission.m_Unit4, Mission.m_Start2) < 50;

        local check9 = GetDistance(Mission.m_Unit1, Mission.m_Start3) < 50;
        local check10 = GetDistance(Mission.m_Unit2, Mission.m_Start3) < 50;
        local check11 = GetDistance(Mission.m_Unit3, Mission.m_Start3) < 50;
        local check12 = GetDistance(Mission.m_Unit4, Mission.m_Start3) < 50;

        -- This tells the enemy units to attack based on distance.
        if (check1 or check2 or check3 or check4 or check5 or check6 or check7 or check8 or check9 or check10 or check11 or check12) then
            Attack(Mission.m_Start1, Mission.m_Unit1);
            Attack(Mission.m_Start2, Mission.m_Unit2);
            Attack(Mission.m_Start3, Mission.m_Unit3);

            -- So we don't loop.
            Mission.m_AttackMansonUnits = true;
        end
    end
end

function JakBrain()
    for i = 1, _Cooperative.m_TotalPlayerCount do
        local p = GetPlayerHandle(i);

        if (not Mission.m_Jak1Attack and IsAlive(Mission.m_Jak1) and GetDistance(p, Mission.m_Jak1) < 50) then
            -- Stop the JAK.
            Stop(Mission.m_Jak1);

            -- So we don't loop.
            Mission.m_Jak1Attack = true;
        end

        if (not Mission.m_Jak2Attack and IsAlive(Mission.m_Jak2) and GetDistance(p, Mission.m_Jak2) < 50) then
            -- Stop the JAK.
            Stop(Mission.m_Jak2);

            -- So we don't loop.
            Mission.m_Jak2Attack = true;
        end

        if (not Mission.m_Jak3Attack and IsAlive(Mission.m_Jak3) and GetDistance(p, Mission.m_Jak3) < 50) then
            -- Stop the JAK.
            Stop(Mission.m_Jak3);

            -- So we don't loop.
            Mission.m_Jak3Attack = true;
        end

        if (not Mission.m_Jak4Attack and IsAlive(Mission.m_Jak4) and GetDistance(p, Mission.m_Jak4) < 50) then
            -- Stop the JAK.
            Stop(Mission.m_Jak4);

            -- So we don't loop.
            Mission.m_Jak4Attack = true;
        end

        if (not Mission.m_Jak5Attack and IsAlive(Mission.m_Jak5) and GetDistance(p, Mission.m_Jak5) < 50) then
            -- Stop the JAK.
            Stop(Mission.m_Jak5);

            -- So we don't loop.
            Mission.m_Jak5Attack = true;
        end
    end
end