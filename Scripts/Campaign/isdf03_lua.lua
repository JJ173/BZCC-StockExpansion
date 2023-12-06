--[[ 
    BZCC ISDF03 Lua Mission Script
    Written by AI_Unit
    Version 1.0 30-11-2023
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

-- Mission important variables.
local Mission = 
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "isuser_mx";
    -- Specific to mission.
    m_PlayerShipODF = "ivscout_x";

    m_MainPlayer = nil,
    m_TerminalPlayer = nil,
    m_Shabayev = nil,
    m_Relic1 = nil,
    m_Relic2 = nil,
    m_Truck = nil,
    m_Armory = nil,
    m_Hauler1 = nil,
    m_Hauler2 = nil,
    m_TechCenter = nil,
    m_CommBunker = nil,
    m_FieldBunker = nil,
    m_Simms = nil,
    m_Miller = nil,
    m_RedNav = nil,
    m_ScionDropship = nil,
    m_Scion1 = nil,
    m_Scion2 = nil,
    m_Scion3 = nil,
    m_Scion4 = nil,
    m_Scion5 = nil,
    m_Scion6 = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionOver = false,
    m_TunnelWarningActive = false,
    m_BunkerWarningActive = false,
    m_BunkerWarningPlayed = false,
    m_ShabThroughTunnel = false,
    m_ShabStrangeBuildingMessage = false,
    m_FixHaulerHealth = false,
    m_MoveHauler = false,
    m_PlayerHoppedOutMessage = false,
    m_BuiltRedSquad = false,
    m_ShowNavObjective = false,
    m_RedSquadLookSequence = false,
    m_RedSquadChangeLook = false,
    m_RedSquadLookAtShab = false,
    m_RedSquadRetreat = false,
    m_ScionBrainEnabled = false;

    m_Audioclip = nil,

    m_MissionDelayTime = 0,
    m_TunnelWarningTime = 0,
    m_RedSquadLookTime = 0,
    m_ScionWaveTime = 0,
    m_ScionWaveCount = 0,

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
    PreloadODF("ivpscou");
    PreloadODF("ivplysct");
    PreloadODF("ivscout_x");
    PreloadODF("ispilo_x");
    PreloadODF("ivserv_x");
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

        -- Pilots are forbidden in this mission.
        if (not IsBuilding(h)) then
            SetEjectRatio(h, 0);
        end
    elseif (GetTeamNum(h) < 5 and GetTeamNum(h) > 0) then
        if (IsOdf(h, "ibnav")) then
            -- Used for the Red 1 objective.
            Mission.m_RedNav = h;
        end
    end
end

function Start()
    -- Set difficulty based on whether it's coop or not.
    if (Mission.m_IsCooperativeMode) then
        -- TODO: introduce new ivar for difficulty?
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1;
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
    Mission.m_Shabayev = GetHandle("shabayev");
    Mission.m_Truck = GetHandle("truck");
    Mission.m_Relic1 = GetHandle("ex_tank1");
    Mission.m_Relic2 = GetHandle("ex_tank2");
    Mission.m_Hauler1 = GetHandle("hauler1");
    Mission.m_TechCenter = GetHandle("tech_center");
    Mission.m_TechHanger = GetHandle("tech_hanger");
    Mission.m_CommBunker = GetHandle("endbase_cbunk");
    Mission.m_FieldBunker = GetHandle("field_cbunk");
    Mission.m_ScionDropship = GetHandle("sdrop");

    -- Give Shab her name.
    SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
    -- Highlight Shabayev.
    SetObjectiveOn(Mission.m_Shabayev);
    -- Give her the correct pilot.
    SetPilotClass(Mission.m_Shabayev, "isshab_p");
    -- So she always ejects.
    SetEjectRatio(Mission.m_Shabayev, 1);
    -- Make sure she has good skill.
    SetSkill(Mission.m_Shabayev, 3);

    -- Make the relics unkillable.
    SetMaxHealth(Mission.m_Relic1, 0);
    SetMaxHealth(Mission.m_Relic2, 0);

    -- This is for Red Squad.
    SetTeamColor(Mission.m_AlliedTeam, 255, 50, 50);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;
end

function Update()
    -- Keep track of the main player.
    Mission.m_MainPlayer = GetPlayerHandle(1);

    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Start mission logic.
    if (not Mission.m_MissionOver) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Run the brains of each character.
            RedSquadBrain();

            if (Mission.m_ScionBrainEnabled) then
                ScionBrain();
            end

            -- For failures.
            HandleFailureConditions();
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
    if (IsPlayer(ShooterHandle) and OrdnanceTeam == Mission.m_HostTeam and (Mission.m_Audioclip == nil or IsAudioMessageDone(Mission.m_Audioclip))) then
        if (VictimHandle == Mission.m_Shabayev) then
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("ff01.wav");
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Have the Hauler pick up the relic.
    Pickup(Mission.m_Hauler1, Mission.m_Relic1);

    -- This sets the Hauler to invulnerable for a short period.
    SetMaxHealth(Mission.m_Hauler1, 0);

    -- Shabayev is looking at our player.
    LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

    -- Make her not care about avoidance.
    SetAvoidType(Mission.m_Shabayev, 0);

    -- This opens up the Scion dropship.
    SetAnimation(Mission.m_ScionDropship, "deploy", 1);

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Shab: We're not out of the woods yet..
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0301.wav");

        -- Tiny delay
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- DEBUG
        Mission.m_MissionState = 18;

        -- Advance the mission state...
        -- Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Shabayev to look towards the tunnels.
        LookAt(Mission.m_Shabayev, Mission.m_TechCenter);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Show the objectives.
        AddObjectiveOverride("isdf0301.otf", "WHITE", 10, true);

        -- Set up a warning.
        Mission.m_TunnelWarningTime = Mission.m_MissionTime + SecondsToTurns(60);

        -- So Shabayev yells for taking too long.
        Mission.m_TunnelWarningActive = true;

        -- Have her move to the "Tall Building".
        Goto(Mission.m_Shabayev, "building_point");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- This does a check to see if players are near the trigger points.
    for i = 1, _Cooperative.m_TotalPlayerCount do
        local p = GetPlayerHandle(i);

        -- Run a check to see if we are next to the "strange" building, or if we are in the tunnels.
        if (not Mission.m_ShabStrangeBuildingMessage and GetDistance(p, Mission.m_TechCenter) < 80) then
            -- Shab: "I've never see that building before."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0305.wav");

            -- So we can start the next part.
            Mission.m_MoveHauler = true;

            -- So we don't loop.
            Mission.m_ShabStrangeBuildingMessage = true;
        elseif (InBuilding(p) and GetDistance(p, "check3") < 12) then
            -- So we can start the next part.
            Mission.m_MoveHauler = true;
        end

        if (IsAudioMessageDone(Mission.m_Audioclip) and Mission.m_MoveHauler) then
            -- Force the Hauler to retreat.
            Retreat(Mission.m_Hauler1, "haulerout_path1");

            -- Remove the warning for checking the tunnels.
            Mission.m_TunnelWarningActive = false;

            -- Show the objectives.
            AddObjectiveOverride("isdf0301.otf", "WHITE", 10, true);
            AddObjective("isdf0302.otf", "WHITE");

            -- Shab: "I'm on my way!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0304.wav");

            -- Send her into the tunnels.
            Follow(Mission.m_Shabayev, Mission.m_Relic1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[6] = function()
    -- The Hauler needs to remain unkillable for the length that it's in the tunnel. I suspect this is to prevent further issue with other Haulers trying to pick up the ISDF crate.
    if (not Mission.m_FixHaulerHealth) then
        if (GetDistance(Mission.m_Hauler1, "shab_check1") < 30) then
            -- Make it killable.
            SetMaxHealth(Mission.m_Hauler1, 2500);

            -- So we don't loop
            Mission.m_FixHaulerHealth = true;
        end
    end

    -- This is to check if Shabayev has made it through the tunnel. Plays the appropriate response based on if she does or doesn't.
    if (not Mission.m_ShabThroughTunnel) then
        if (GetDistance(Mission.m_Shabayev, "shab_check1") < 55 or GetDistance(Mission.m_Hauler1, "hauler_check1") < 90) then
            -- This checks to see if the Hauler is alive.
            if (IsAlive(Mission.m_Hauler1)) then
                -- Show the objectives.
                AddObjectiveOverride("isdf0302.otf", "GREEN", 10, true);
                AddObjective("isdf0303.otf", "WHITE");

                -- Shab: Stop that Hauler!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0306.wav");

                -- Have her attack the Hauler.
                Attack(Mission.m_Shabayev, Mission.m_Hauler1);
            else
                -- Have Shabayev go to the first crate.
                Follow(Mission.m_Shabayev, Mission.m_Relic1, 1);
            end

            -- To stop us from looping.
            Mission.m_ShabThroughTunnel = true;
        end
    end

    if (not IsAlive(Mission.m_Hauler1)) then
        if (not Mission.m_ShabThroughTunnel) then
            -- Shab: "Nice Job, stay there, I'm on my way.""
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0307.wav");
        end

        -- Show Objectives.
        AddObjectiveOverride("isdf0303.otf", "GREEN", 10, true);

        -- Have Shabayev follow the relic.
        Follow(Mission.m_Shabayev, Mission.m_Relic1, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip) and GetDistance(Mission.m_Shabayev, Mission.m_Relic1) < 30) then
        -- Have her look at the relic.
        LookAt(Mission.m_Shabayev, Mission.m_Relic1, 1);

        -- Shab: It looks like these aliens are interested in us...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0308.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- This moves Shabayev to the tech building.
        Goto(Mission.m_Shabayev, Mission.m_TechCenter, 1);

        -- Shab: "What is this? I don't recognise this either".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0309a.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    -- This checks her distance so she looks at the tech centre before going under it.
    if (GetDistance(Mission.m_Shabayev, Mission.m_TechCenter) < 70) then
        -- Have her look at the building.
        LookAt(Mission.m_Shabayev, Mission.m_TechCenter, 1);

        -- Do a small mission delay before Red 1 calls for help.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(10);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[10] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip) and Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Have Shabayev look at the main player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Play the message from Red 1.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0325b.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Shab: "Can you trasmit your location"?
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0326.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Red1: "Negative!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0315.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Shab: "Commander? Damn it!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0316.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0304.otf", "WHITE", 10, true);

        -- Send Shabayev to the Comm Bunker.
        Retreat(Mission.m_Shabayev, "tunnel_pathx", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[15] = function()
    -- This checks to see if Shabayev is near the comm bunker for her next message.
    if (GetDistance(Mission.m_Shabayev, "check_start2") < 40) then
        -- Shab: I hope they haven't taken out the satellites.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0327.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[16] = function()
    -- This checks to see if Shab has exited the tunnels to go to the comm bunker.
    if (GetDistance(Mission.m_Shabayev, "bunker_point1") < 40) then
        -- Have her go to a better position.
        Retreat(Mission.m_Shabayev, "shab_bunker_dest", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[17] = function()
    -- This checks to see if Shab is near the comm bunker.
    if (GetDistance(Mission.m_Shabayev, "shab_bunker_dest") < 10) then
        -- Have Shabayev look at the main player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Show Objectives.
        AddObjectiveOverride("isdf0305.otf", "WHITE", 10, true);

        -- Shab: I'm going to need you to find those men.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0317.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[18] = function()
    -- This runs a check to see if the player has hopped out.
    for i = 1, _Cooperative.m_TotalPlayerCount do
        local p = GetPlayerHandle(i);
        local currentClass = GetClassLabel(p);
        local bunkerDist = GetDistance(p, Mission.m_CommBunker);

        -- Run this if a player has hopped out and is close to the bunker.
        if (currentClass == "CLASS_PERSON" and bunkerDist < 75) then
            -- This is the message for when the player hops out of their vehicle.
            if (not Mission.m_PlayerHoppedOutMessage) then
                -- Stop Shabayev from chatting.
                if (not IsAudioMessageDone(Mission.m_Audioclip)) then
                    -- Stop Shabayev from talking.
                    StopAudioMessage(Mission.m_Audioclip);

                    -- Do a tiny delay.
                    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
                end

                if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                    -- Have her look at the bunker.
                    LookAt(Mission.m_Shabayev, Mission.m_CommBunker, 1);

                    -- Shab: Head into the bunker.
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0318.wav");

                    -- So we don't loop.
                    Mission.m_PlayerHoppedOutMessage = true;
                end
            end

            -- This does a check to see if the player is within the bunker.
            if (Mission.m_PlayerHoppedOutMessage and not Mission.m_BuiltRedSquad and InBuilding(p)) then
                -- Stop Shabayev from chatting.
                if (not IsAudioMessageDone(Mission.m_Audioclip)) then
                    -- Stop Shabayev from talking.
                    StopAudioMessage(Mission.m_Audioclip);

                    -- Do a tiny delay.
                    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
                end

                if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                    -- Show Objectives.
                    AddObjectiveOverride("isdf0306.otf", "GREEN", 10, true);
                    AddObjective("isdf0307.otf", "WHITE");

                    -- Shab: "Move to the map terminal".
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0319.wav");

                    -- Create Red Squad.
                    Mission.m_Miller = BuildObject("ivscout_x", Mission.m_AlliedTeam, "miller_spawn1");
                    Mission.m_Simms = BuildObject("ivscout_x", Mission.m_AlliedTeam, "simms_spawn1");

                    -- Change the name of the characters.
                    SetObjectiveName(Mission.m_Miller, "Red 1");
                    SetObjectiveName(Mission.m_Simms, "Lt. Simms");

                    -- Move them to their destinations.
                    Retreat(Mission.m_Miller, "miller_dest", 1);
                    Retreat(Mission.m_Simms, "simms_dest", 1);

                    -- So the brain function can do what it needs to do.
                    Mission.m_RedSquadLookSequence = true;

                    -- So we don't loop.
                    Mission.m_BuiltRedSquad = true;
                end
            end

            -- This then checks if a player is in a terminal and in overhead view.
            if (Mission.m_PlayerHoppedOutMessage and Mission.m_BuiltRedSquad and AtTerminal(p) == Mission.m_CommBunker) then
                -- Stop Shabayev from chatting.
                if (not IsAudioMessageDone(Mission.m_Audioclip)) then
                    -- Stop Shabayev from talking.
                    StopAudioMessage(Mission.m_Audioclip);

                    -- Do a tiny delay.
                    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
                end

                if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                    -- Shab: "Locate the soliders for me".
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0328.wav");

                    -- Keep track of who is in the terminal.
                    Mission.m_TerminalPlayer = p;

                    -- This removes the bunker warning.
                    Mission.m_BunkerWarningActive = true;

                    -- Show Red 1.
                    if (IsAround(Mission.m_Miller)) then
                        -- Highlight Red 1.
                        SetObjectiveOn(Mission.m_Miller);
                    end

                    -- Advance the mission state...
                    Mission.m_MissionState = Mission.m_MissionState + 1;
                end
            end
        end
    end
end

Functions[19] = function()
    -- Run a check to see if one of the players is using the relay bunker.
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Shab: Drop a nav for me.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0330.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[20] = function()
    -- This does a check to see if the nav is near enough to Red 1.
    if (IsAudioMessageDone(Mission.m_Audioclip) and not Mission.m_ShowNavObjective) then
        -- Show objectives.
        AddObjectiveOverride("isdf0310.otf", "WHITE", 10, true);

        -- So we don't loop.
        Mission.m_ShowNavObjective = true;
    end
    
    -- This does a check to see if the nav is within a good distance of Red 1.
    if (IsAround(Mission.m_RedNav)) then
        if (GetDistance(Mission.m_RedNav, Mission.m_Miller) > 200) then
            -- Stop Shabayev from chatting.
            if (not IsAudioMessageDone(Mission.m_Audioclip)) then
                -- Stop Shabayev from talking.
                StopAudioMessage(Mission.m_Audioclip);

                -- Do a tiny delay.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
            end

            if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                -- Start new audio.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0331.wav");

                -- Show objectives.
                AddObjectiveOverride("isdf0310.otf", "RED", 10, true);

                -- So we don't loop.
                Mission.m_RedNav = nil;
            end
        else
            -- Stop Shabayev from chatting.
            if (not IsAudioMessageDone(Mission.m_Audioclip)) then
                -- Stop Shabayev from talking.
                StopAudioMessage(Mission.m_Audioclip);

                -- Do a tiny delay.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
            end

            if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                -- Show objectives.
                AddObjectiveOverride("isdf0310.otf", "GREEN", 10, true);

                -- This removes the bunker warning.
                Mission.m_BunkerWarningActive = false;

                -- Remove the objective markers from both Shab and Red 1.
                SetObjectiveOff(Mission.m_Shabayev);
                SetObjectiveOff(Mission.m_Miller);

                -- Shab: I'm on my way.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0320.wav");

                -- Tell her to go to the path.
                Retreat(Mission.m_Shabayev, "leave_path");

                -- So enemies ignore her.
                SetPerceivedTeam(Mission.m_Shabayev, Mission.m_EnemyTeam);

                -- Advance the mission state...
                Mission.m_MissionState = Mission.m_MissionState + 1;
            end
        end
    end
end

Functions[21] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- This sets up our delay for the next part.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(15);

        -- Shab: "You're a good pilot".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0332a.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[22] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Braddock: We've got your situation on radar.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0310.wav");

        -- Change the name of each crate to "Hardware".
        SetObjectiveName(Mission.m_Relic1, "Hardware");
        SetObjectiveName(Mission.m_Relic2, "Hardware");

        -- Highlight each "Hardware" crate.
        SetObjectiveOn(Mission.m_Relic1);
        SetObjectiveOn(Mission.m_Relic2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[23] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- New Objectives.
        AddObjectiveOverride("isdf0308a.otf", "WHITE", 10, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[24] = function()
    -- This function will handle the Scion waves.
    local check1 = IsAlive(Mission.m_Hauler1);
    local check2 = IsAlive(Mission.m_Hauler2);
    local check3 = IsPlayerWithinDistance("base2_espawn1", 300, _Cooperative.m_TotalPlayerCount);

    -- Enemy units are dead, refresh.
    if (not check1 and not check2 and not check3) then
        if (Mission.m_ScionWaveTime < Mission.m_MissionTime) then
            -- This creates the Haulers and their guards.
            Mission.m_Hauler1 = BuildObject("fvtug3", Mission.m_EnemyTeam, "base2_espawn3");
            Mission.m_Hauler2 = BuildObject("fvtug3", Mission.m_EnemyTeam, "base2_espawn4");

            -- Set their avoid type.
            SetAvoidType(Mission.m_Hauler1, 0);
            SetAvoidType(Mission.m_Hauler2, 0);

            -- Create the guards.
            Mission.m_Scion1 = BuildObject("fvscout_x", Mission.m_EnemyTeam, "base2_espawn1");
            Mission.m_Scion2 = BuildObject("fvscout_x", Mission.m_EnemyTeam, "base2_espawn2");

            -- Set their avoid type.
            SetAvoidType(Mission.m_Scion1, 0);
            SetAvoidType(Mission.m_Scion2, 0);

            -- Have them follow the Haulers.
            Follow(Mission.m_Scion1, Mission.m_Hauler1, 1);
            Follow(Mission.m_Scion2, Mission.m_Hauler2, 1);

            -- Have the Haulers go for the crates.
            Retreat(Mission.m_Hauler1, "haulerin_path1");
            Retreat(Mission.m_Hauler2, "haulerin_path2");

            -- This sets the time limit.
            Mission.m_ScionWaveTime = Mission.m_MissionTime + SecondsToTurns(180);
        end
    end
end

function ScionBrain()
    -- This does a check to see when the Haulers need to pick up the crates.
    
end

function RedSquadBrain()
    -- This will check to see if they should be doing the look sequence.
    if (Mission.m_RedSquadLookSequence and Mission.m_RedSquadLookTime < Mission.m_MissionTime) then
        if (IsAlive(Mission.m_Miller) and GetDistance(Mission.m_Miller, "miller_dest") < 20) then
            if (not Mission.m_RedSquadChangeLook) then
                LookAt(Mission.m_Miller, Mission.m_MainPlayer);
            else
                LookAt(Mission.m_Miller, Mission.m_FieldBunker);
            end
        end

        if (IsAlive(Mission.m_Simms) and GetDistance(Mission.m_Simms, "simms_dest") < 20) then
            if (not Mission.m_RedSquadChangeLook) then
                LookAt(Mission.m_Simms, Mission.m_FieldBunker);
            else
                LookAt(Mission.m_Simms, Mission.m_MainPlayer);
            end
        end

        -- So we can change.
        Mission.m_RedSquadChangeLook = (not Mission.m_RedSquadChangeLook);

        -- This delays the look sequence.
        Mission.m_RedSquadLookTime = Mission.m_MissionTime + SecondsToTurns(5);
    end

    -- This'll do a check to see if Shabayev is near Red Squad.
    if (not Mission.m_RedSquadLookAtShab and GetDistance(Mission.m_Shabayev, Mission.m_Miller) < 150) then
        -- Stop them randomly looking.
        Mission.m_RedSquadLookSequence = false;

        -- Have both members look at Shabayev.
        LookAt(Mission.m_Miller, Mission.m_Shabayev, 1);
        LookAt(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- So we don't repeat.
        Mission.m_RedSquadLookAtShab = true;
    end

    -- This will have Red Squad and Shabayev move off the map for the time being.
    if (not Mission.m_RedSquadRetreat and Mission.m_RedSquadLookAtShab and GetDistance(Mission.m_Shabayev, Mission.m_Miller) < 50) then
        -- Have them exit the map.
        Follow(Mission.m_Miller, Mission.m_Shabayev, 1);
        Follow(Mission.m_Simms, Mission.m_Miller, 1);

        -- Have Shabayev retreat.
        Retreat(Mission.m_Shabayev, "miller_spawn1", 1);

        -- So we don't repeat.
        Mission.m_RedSquadRetreat = true;
    end

    -- This then checks units to remove them from the game.
    if (Mission.m_RedSquadRetreat) then
        if (IsAlive(Mission.m_Shabayev) and GetDistance(Mission.m_Shabayev, "miller_spawn1") < 25) then
            RemoveObject(Mission.m_Shabayev);
        end

        if (IsAlive(Mission.m_Miller) and GetDistance(Mission.m_Miller, "miller_spawn1") < 35) then
            RemoveObject(Mission.m_Miller);
        end

        if (IsAlive(Mission.m_Simms) and GetDistance(Mission.m_Simms, "miller_spawn1") < 45) then
            RemoveObject(Mission.m_Simms);
        end
    end
end

function HandleFailureConditions()
    -- If the player takes too long to reach the bunker.
    if (Mission.m_TunnelWarningActive) then
        if (Mission.m_TunnelWarningTime < Mission.m_MissionTime) then
            -- Shab: Did you search those tunnels?!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0302.wav");

            -- Reshow the objectives.
            AddObjectiveOverride("isdf0301.otf", "WHITE", 10, true);

            -- Set up a warning.
            Mission.m_TunnelWarningTime = Mission.m_MissionTime + SecondsToTurns(60);
        end 
    end

    -- If the player exits the comm bunker before doing the nav.
    if (Mission.m_BunkerWarningActive) then
        -- This checks to see if the player leaves the overhead view before the nav is placed.
        if (IsAlive(Mission.m_TerminalPlayer) and AtTerminal(Mission.m_TerminalPlayer) == nil and not Mission.m_BunkerWarningPlayed) then
            -- Stop Shabayev from chatting.
            if (not IsAudioMessageDone(Mission.m_Audioclip)) then
                -- Stop Shabayev from talking.
                StopAudioMessage(Mission.m_Audioclip);

                -- Do a tiny delay.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
            end

            if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                -- Shab: Where are you going?!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0328a.wav");

                -- Remove the terminal player.
                Mission.m_TerminalPlayer = nil;

                -- So we don't loop
                Mission.m_BunkerWarningPlayed = true;
            end
        elseif (not IsAlive(Mission.m_TerminalPlayer) and Mission.m_BunkerWarningPlayed) then
            for i = 1, _Cooperative.m_TotalPlayerCount do
                local p = GetPlayerHandle(i);

                -- Reset the values.
                if (AtTerminal(p) == Mission.m_CommBunker) then
                    -- Stops looping.
                    Mission.m_TerminalPlayer = p;

                    -- Ready for disconnect early.
                    Mission.m_BunkerWarningPlayed = false;
                end
            end
        end
    end
end