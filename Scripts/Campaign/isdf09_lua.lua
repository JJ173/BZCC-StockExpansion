--[[ 
    BZCC ISDF09 Lua Mission Script
    Written by AI_Unit
    Version 1.0 15-12-2023
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
    m_Manson = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionOver = false,
   
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
    print("Welcome to ISDF09 (Lua)");
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
    local PlayerEntryH = GetPlayerHandle(1);

	if (PlayerEntryH ~= nil) then
		RemoveObject(PlayerEntryH);
	end

    -- Get Team Number.
    local LocalTeamNum = GetLocalPlayerTeamNumber();

    -- Create the player for the server.
    local PlayerH = _Cooperative.SetupPlayer(LocalTeamNum, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF);

    -- Make sure we give the player control of their ship.
    SetAsUser(PlayerH, LocalTeamNum);

    -- Grab all of our pre-placed handles.
    Mission.m_Manson = GetHandle("manson");

    -- Set Manson's team to blue.
    SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);

    -- Place the player's old base from the previous mission.
    PlacePlayerBase();

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
        end
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF);
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
    if (IsPlayer(ShooterHandle) and OrdnanceTeam == Mission.m_HostTeam and (Mission.m_Audioclip == nil or IsAudioMessageDone(Mission.m_Audioclip))) then
        if (IsAlive(Mission.m_Manson) and VictimHandle == Mission.m_Manson) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0555.wav");
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()

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