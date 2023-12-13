--[[ 
    BZCC ISDF02 Lua Mission Script
    Written by AI_Unit
    Version 1.0 29-10-2023
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

-- Difficulty tables for times and spawns.
local m_FirstScionWave1 = {"fvscout_x", "fvscout_x", "fvsent_x"};
local m_FirstScionWave2 = {"fvscout_x", "fvsent_x", "fvsent_x"};
local m_SecondScionWave1 = {"fvsent_x", "fvsent_x", "fvsent_x"};
local m_SecondScionWave2 = {"fvscout_x", "fvsent_x", "fvsent_x"};
local m_SecondScionWave3 = {"fvscout_x", "fvscout_x", "fvtank_x"};
local m_ThirdScionWave1 = {"fvsent_x", "fvsent_x", "fvtank_x"};
local m_ThirdScionWave2 = {"fvscout_x", "fvscout_x", "fvsent_x"};
local m_ThirdScionWave3 = {"fvscout_x", "fvsent_x", "fvscout_x"};

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

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionFailed = false,
    m_ShabInShip = false,
    m_LookAtPlayer = false,
    m_FirstAttackWaveSent = false,
    m_ScrambledMessage = false,
    m_CheckpointDone = false,
    m_SecondAttackWaveSpawned = false,
    m_ShabayevReturningToBase = false,
    m_ThirdAttackWaveSent = false,
    m_CompanyMessagePlayed = false,
    m_BuildKilledPrematurely = false,
    m_ShabBuilderDeadMessagePlayed = false,
    m_RedirectShabayev = false,
    m_PlayerLost = false,
    m_FirstWarning = false,
    m_SecondWarning = false,
    m_ServiceTruckWarning = false,
    m_RepairsNeeded = false,
    m_TruckFollowing = false,
    m_TruckMessage = false,

    -- Builder Brain Variables.
    m_BuilderRun = false,
    m_BuilderRunCheck = 0,
    m_BuilderRunTime = 0,
    m_BuilderSecondRetreatDone = false,
    -- End Builder Brain Variables.

    m_MainPlayer = nil,
    m_Shabayev = nil,
    m_Ship1 = nil,
    m_Ship2 = nil,
    m_Ship3 = nil,
    m_Ship4 = nil,
    m_Truck = nil,
    m_BasePower = nil,
    m_Builder1 = nil,
    m_DeadScav1 = nil,
    m_DeadScav2 = nil,
    m_DeadPower1 = nil,
    m_DeadPower2 = nil,
    m_DeadPower3 = nil,
    m_Cons = nil,
    m_Pole3 = nil,
    m_Pole4 = nil,
    m_Pole5 = nil,
    m_Pole6 = nil,
    m_Pole7 = nil,
    m_Pole8 = nil,
    m_Pole9 = nil,
    m_Pole10 = nil,
    m_Pole11 = nil,
    m_LookPole = nil,
    m_LastTurret1 = nil,
    m_LastTurret2 = nil,
    m_Scion1 = nil,
    m_Scion2 = nil,
    m_Scion3 = nil,
    m_Jammer = nil,
    m_Jammer2 = nil,

    m_Audioclip = nil,

    m_JammerMessageTime = 0,
    m_DeadJammerMessageTime = 999999,
    m_TruckCheckTime = 0,
    m_ServiceMessageTime = 0,
    m_BuilderFollowTime = 0,
    m_ShabGarbledMessageTime = 0,
    m_OnToBaseTime = 0,
    m_ShabConWaitTime = 0,
    m_SafeSpawnCheckTime = 0,
    m_PlayerLostTime = 0,
    m_PlayerCheckTime = 0,
    m_PlayerTruckWarningTime = 0,
    m_GetTruckTime = 0,

    -- Pole timers for final cutscene.
    m_Pole3Time = 0,
    m_Pole4Time = 0,
    m_Pole5Time = 0,
    m_Pole6Time = 0,
    m_Pole7Time = 0,
    m_Pole8Time = 0,
    m_Pole9Time = 0,
    m_Pole10Time = 0,
    m_Pole11Time = 0,

    -- Keep track of which functions are running.
    m_MissionState = 1,
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
    PreloadODF("ivscout");
    PreloadODF("ispilo");
    PreloadODF("ivserv");
    PreloadODF("fvpcon_x");
    PreloadODF("ivcons2");
    PreloadODF("ivpcon");
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
    local ODFName = GetCfg(h);

    -- Handle unit skill for enemy.
    if (GetTeamNum(h) == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty); 

        -- For this mission, we don't have intel on enemy units, so set all of their names to "Unknown".
        SetObjectiveName(h, "Unknown");

        -- Check that the Jammer has been built.
        if (Mission.m_Jammer == nil and ODFName == "fbpjam") then
            Mission.m_Jammer = h;
        end

        -- Pilots are forbidden in this mission.
        if (not IsBuilding(h)) then
            SetEjectRatio(h, 0);
        end
    elseif (GetTeamNum(h) == Mission.m_HostTeam) then
        -- We need to grab Shabayev when she jumps out of the Scout.
        if (Mission.m_MissionState >= 44) then
            if (ODFName == "isshab_p") then
                Mission.m_Shabayev = h;
                SetObjectiveName(h, "Cmd. Shabayev");
            elseif (ODFName == "ibpgn1") then
                Mission.m_BasePower = h;
            end
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
    print("Welcome to ISDF02 (Lua)");
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

    -- Remove the player ODF that is saved as part of the BZN. For this mission, only do this for coop.
    local PlayerEntryH = GetPlayerHandle(1);

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
    Mission.m_Shabayev = GetHandle("shab");
    Mission.m_Ship1 = GetHandle("ship1");
    Mission.m_Ship2 = GetHandle("ship2");
    Mission.m_Ship3 = GetHandle("ship3");
    Mission.m_Ship4 = GetHandle("ship4");
    Mission.m_Truck = GetHandle("truck");
    Mission.m_DeadScav1 = GetHandle("dead_scav1");
    Mission.m_DeadScav2 = GetHandle("dead_scav2");
    Mission.m_DeadPower1 = GetHandle("dead_power1");
    Mission.m_DeadPower2 = GetHandle("dead_power2");
    Mission.m_DeadPower3 = GetHandle("dead_power3");
    Mission.m_Pole3 = GetHandle("pole3");
    Mission.m_Pole4 = GetHandle("pole4");
    Mission.m_Pole5 = GetHandle("pole5");
    Mission.m_Pole6 = GetHandle("pole6");
    Mission.m_Pole7 = GetHandle("pole7");
    Mission.m_Pole8 = GetHandle("pole8");
    Mission.m_Pole9 = GetHandle("pole9");
    Mission.m_Pole10 = GetHandle("pole10");
    Mission.m_Pole11 = GetHandle("pole11");
    Mission.m_LookPole = GetHandle("look_pole");
    Mission.m_LastTurret1 = GetHandle("last_turret1");
    Mission.m_LastTurret2 = GetHandle("last_turret2");

    -- Spawn the Scion Builder at the right spot.
    Mission.m_Builder1 = BuildObject("fvpcon_x", Mission.m_EnemyTeam, "thai_spawn");
    -- Spawn the inactive Constructor for Shabayev to pilot later on.
    Mission.m_Cons = BuildObject("ivcons2", 0, "con_spawn");

    -- Replace Shabayev's pilot with our custom ODF.
    if (IsAlive(Mission.m_Shabayev)) then
        Mission.m_Shabayev = ReplaceObject(Mission.m_Shabayev, "isshab_p");

        -- Rename and highlight.
        SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
        SetObjectiveOn(Mission.m_Shabayev);
    end

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
    if (not Mission.m_MissionFailed) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Run specific functions.
            if (IsAlive(Mission.m_Builder1)) then
                HandleScionBuilder();
            end

            HandleShabayevGarbledDialogue();
            HandlePlayerDisobeyingOrders();
            HandleScionAttackWaves();
            HandleFailureConditions();

            -- So we don't cause a large amount of time for Shabayev's repair.
            if (IsOdf(Mission.m_Shabayev, "ivpscou") and GetCurHealth(Mission.m_Shabayev) < 1300) then
                -- Otherwise the Service Sequence is too long.
                SetCurHealth(Mission.m_Shabayev, 1300);
            end

            -- The builder needs to be kept alive for the first part of the mission.
            if (IsAlive(Mission.m_Builder1) and GetCurHealth(Mission.m_Builder1) < 900 and not Mission.m_CheckpointDone) then
                -- Need to keep it alive for a bit of time to avoid mission stall as per stock behaviour.
                SetCurHealth(Mission.m_Builder1, 1000);
            elseif (not IsAlive(Mission.m_Builder1) and Mission.m_CheckpointDone and Mission.m_MissionState <= 27 and not Mission.m_ShabBuilderDeadMessagePlayed) then
                -- Shab: Whatever that was, it's dead now.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0232.wav");

                -- Get Shabayev to look at the player.
                LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

                -- Set the mission state so we retreat.
                Mission.m_MissionState = 27;

                -- To avoid looping.
                Mission.m_ShabBuilderDeadMessagePlayed = true;
            end
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
    -- Unique to this mission.
    if (pilotHandle == Mission.m_Shabayev and not Mission.m_ShabInShip) then
        -- Set Shabayev to the ship so she's not dead.
        Mission.m_Shabayev = emptyCraftHandle;

        -- Highlight her ship.
        SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
        SetObjectiveOn(Mission.m_Shabayev);

        -- Have her look at the "main" player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer);

        -- Prevent a loop.
        Mission.m_ShabInShip = true;
    end

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
        elseif (VictimHandle == Mission.m_Truck) then
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("ff02.wav");
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Clean up any player spawns that haven't been taken by the player.
    CleanSpawns();

    -- Small amount of damage for the Truck to repair.
    Damage(Mission.m_Ship4, 1000);

    -- This unit should not be controlled by the player.
    Stop(Mission.m_Truck, 1);

    -- Show objective.
    AddObjectiveOverride("to_ship.otf", "WHITE", 10, true);

    -- So we don't engage.
    SetPerceivedTeam(Mission.m_Builder1, Mission.m_HostTeam);

    -- Order the builder to construct the first Jammer.
    Build(Mission.m_Builder1, "fbpjam");

    -- Shab: "Okay Cooke, follow me..."
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0263.wav");

    -- Tell Shab to Move...
    Retreat(Mission.m_Shabayev, "shab_run_path2");

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    -- Check if the main player is in a scout so we can continue.
    if (IsOdf(Mission.m_MainPlayer, "ivplysct") and Mission.m_ShabInShip) then
        -- Give command of the Service Truck to the player.
        SetBestGroup(Mission.m_Truck);

        -- Replace Shabayev with a normal scout.
        Mission.m_Shabayev = ReplaceObject(Mission.m_Shabayev, "ivpscou");

        -- Set her skill to max.
        SetSkill(Mission.m_Shabayev, 3);

        -- Highlight the Service Truck.
        SetObjectiveOn(Mission.m_Truck);

        -- Highlight her ship.
        SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
        SetObjectiveOn(Mission.m_Shabayev);

        -- Have the Builder look at the player as per Stock.
        LookAt(Mission.m_Builder1, Mission.m_MainPlayer, 1);

        -- Move it.
        Goto(Mission.m_Truck, "truck_move", 0);

        -- Some AI stuff...
        SetAvoidType(Mission.m_Truck, 0);

        -- Move shabayev
        Retreat(Mission.m_Shabayev, "oldbase_center");

        -- Have her talk about having the truck follow on.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0226.wav");

        -- New objectives
        AddObjectiveOverride("to_ship.otf", "GREEN", 10, true);
        AddObjective("truck_follow.otf", "WHITE", 10);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    -- Check that Shabayev is in the base centre. If she is, have her stop and look at the first player.
    if (GetDistance(Mission.m_Shabayev, "oldbase_center") < 25) then
        -- Face the player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Set a warning time for the truck.
        Mission.m_PlayerTruckWarningTime = Mission.m_MissionTime + SecondsToTurns(40);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    -- We can't use IsSelected for COOP as it's not MP friendly, so we'll need to code a work around.
    if (not Mission.m_IsCooperativeMode) then
        if (IsSelected(Mission.m_Truck)) then
            -- Interrupt Shabayev...
            StopAudioMessage(Mission.m_Audioclip);

            -- Shab: Good, now have it follow you.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0227.wav");

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    else 
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    if (Mission.m_TruckFollowing) then
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    elseif (not Mission.m_ServiceTruckWarning and Mission.m_PlayerTruckWarningTime < Mission.m_MissionTime) then
        -- Shab: I'm still waiting!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0203.wav");

        -- If they don't have it follow within 15 seconds, fail.
        Mission.m_PlayerTruckWarningTime = Mission.m_MissionTime + SecondsToTurns(15);

        -- So we don't loop.
        Mission.m_ServiceTruckWarning = true;
    end
end

Functions[6] = function()
    -- Interrupt Shabayev...
    StopAudioMessage(Mission.m_Audioclip);

    -- Shab: Good, let's go.
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0202.wav");

    AddObjectiveOverride("truck.otf", "GREEN", 10, true);
    AddObjective("follow_shab.otf", "WHITE", 10);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[7] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Move out and end this part of the mission.
        if (GetCurrentCommand(Mission.m_Shabayev) ~= CMD_GO) then
            Goto(Mission.m_Shabayev, "truckwait_path", 1);
        end

        if (GetDistance(Mission.m_Shabayev, "truckwait_point") < 20) then
            -- Look at the Player.
            LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);
    
            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[8] = function()
    -- Mark the player as lost.
    if (not IsPlayerWithinDistance(Mission.m_Shabayev, 200, _Cooperative.m_TotalPlayerCount)) then
        -- So she starts yelling at the player.
        Mission.m_PlayerLost = true;
    elseif (IsPlayerWithinDistance(Mission.m_Shabayev, 50, _Cooperative.m_TotalPlayerCount) and Mission.m_TruckFollowing) then
        -- Face the Truck.
        LookAt(Mission.m_Shabayev, Mission.m_Truck, 1);

        -- Shab: Sometimes you have to wait for slower vehicles...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0210.wav");

        -- Set to 2 seconds again.
        Mission.m_TruckCheckTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    elseif (not Mission.m_TruckMessage) then
        -- To remind about the truck.
        Mission.m_GetTruckTime = Mission.m_MissionTime + SecondsToTurns(2);
        Mission.m_TruckMessage = true;
    end
end

Functions[9] = function()
    if (Mission.m_TruckCheckTime < Mission.m_MissionTime) then
        -- Set to 2 seconds again.
        Mission.m_TruckCheckTime = Mission.m_MissionTime + SecondsToTurns(2);

        if (Mission.m_TruckFollowing) then
            -- Truck is near, let's move out.
            if (IsPlayerWithinDistance(Mission.m_Truck, 70, _Cooperative.m_TotalPlayerCount) and IsAudioMessageDone(Mission.m_Audioclip)) then
                -- Shab: Okay, follow me...
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0209.wav");

                -- Look at the main player.
                LookAt(Mission.m_Shabayev, Mission.m_MainPlayer);

                -- Advance the mission state...
                Mission.m_MissionState = Mission.m_MissionState + 1;
            end
        elseif (not Mission.m_TruckMessage) then
            -- To remind about the truck.
            Mission.m_GetTruckTime = Mission.m_MissionTime + SecondsToTurns(2);
            Mission.m_TruckMessage = true;
        end
    end
end

Functions[10] = function()
    if (IsAlive(Mission.m_Builder1) and IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Move Shabayev to the next point after she has finished talking.
        Goto(Mission.m_Shabayev, "shab_path1");

        -- Shab: I'm detecting something...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0211.wav");

        -- Set it back to Team 6.
        SetPerceivedTeam(Mission.m_Builder1, Mission.m_EnemyTeam);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    -- When Shabayev reaches near the first checkpoint, send her to stop the Jammer.
    if (GetDistance(Mission.m_Shabayev, "checkpoint1") < 40) then
        -- Send Shabayev to stop the Jammer.
        Goto(Mission.m_Shabayev, "shabstop_jammer", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    -- When Shabayev reaches near the first checkpoint, send her to stop the Jammer.
    if (GetDistance(Mission.m_Shabayev, "shabstop_jammer") < 20) then
        -- Shab: What the hell is that?
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0212.wav");

        -- Look at it!
        LookAt(Mission.m_Shabayev, Mission.m_Builder1, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    -- Check that one of the players are now near the Builder and start performing our Jammer build.
    if (IsAlive(Mission.m_Builder1) and (IsPlayerWithinDistance(Mission.m_Builder1, GetDistance(Mission.m_Builder1, "dist_check"), _Cooperative.m_TotalPlayerCount))) then
        -- Build that Jammer!
        Dropoff(Mission.m_Builder1, "jammer_spawn", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    -- Once the Jammer is built, queue attacks and make the builder run away.
    if (IsAlive(Mission.m_Jammer)) then
        -- Spawn our first attack wave.
        Mission.m_Scion1 = BuildObjectAtSafePath(m_FirstScionWave1[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "espawn1_jammer", "espawn3_jammer", _Cooperative.m_TotalPlayerCount);
        Mission.m_Scion2 = BuildObjectAtSafePath(m_FirstScionWave2[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "espawn2_jammer", "espawn4_jammer", _Cooperative.m_TotalPlayerCount);

        -- Set skill based on difficulty.
        SetSkill(Mission.m_Scion1, Mission.m_MissionDifficulty);
        SetSkill(Mission.m_Scion2, Mission.m_MissionDifficulty);
        
        -- Small delay before the builder runs away.
        Mission.m_BuilderRunTime = Mission.m_MissionTime + SecondsToTurns(0.2);

        -- So we don't immediately attack.
        Mission.m_JammerMessageTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[15] = function()
    if (Mission.m_JammerMessageTime < Mission.m_MissionTime) then
        -- Have Shabyev attack the Jammer.
        Attack(Mission.m_Shabayev, Mission.m_Jammer, 1);
        
        -- Highlight the Jammer.
        SetObjectiveOn(Mission.m_Jammer);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[16] = function()
    if (not IsAlive(Mission.m_Jammer)) then
        -- Cut Shabayev's dialog if the jammer dies.
        StopAudioMessage(Mission.m_Audioclip);

        -- Shab: "That's what was jamming our comms"!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0228.wav");

        -- Set the dead jammer message timer.
        Mission.m_DeadJammerMessageTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Look at player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[17] = function()
    if (Mission.m_DeadJammerMessageTime < Mission.m_MissionTime) then            
        if (IsAlive(Mission.m_Scion1) or IsAlive(Mission.m_Scion2)) then
           -- Set "defend truck" objective.
            AddObjectiveOverride("defend_truck.otf", "WHITE", 10, true);

            -- Send Scions and Shabayev to attack things.
            if (IsAlive(Mission.m_Scion1)) then
                -- Send Shabayev to attack the Scions.
                Attack(Mission.m_Shabayev, Mission.m_Scion1);
                -- Send after the truck.
                Attack(Mission.m_Scion1, Mission.m_Shabayev);
            elseif (IsAlive(Mission.m_Scion2)) then
                -- Send Shabayev to attack the Scions.
                Attack(Mission.m_Shabayev, Mission.m_Scion2);
                -- Send after the player.
                Attack(Mission.m_Scion2, Mission.m_MainPlayer);
            end

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        else 
            -- Shab: "That's what was jamming our comms"!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0214.wav");

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[18] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        if (not Mission.m_RedirectShabayev) then
            if (IsAlive(Mission.m_Scion1) and not IsAlive(Mission.m_Scion2)) then
                -- Shab: "Good job, now help me with this other one."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0247.wav");

                -- Highlight the target
                SetObjectiveOn(Mission.m_Scion1);

                -- Have Shabayev attack it.
                Attack(Mission.m_Shabayev, Mission.m_Scion1, 1);

                -- Show objectives.
                AddObjectiveOverride("defend_truck.otf", "GREEN", 10, true);
                AddObjective("assist_shab.otf", "WHITE");

                -- Stop the loop.
                Mission.m_RedirectShabayev = true;
            elseif (IsAlive(Mission.m_Scion2) and not IsAlive(Mission.m_Scion1)) then
                -- Shab: "Good job, now help me with this other one."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0247.wav");

                -- Highlight the target
                SetObjectiveOn(Mission.m_Scion2);

                -- Have Shabayev attack it.
                Attack(Mission.m_Shabayev, Mission.m_Scion2, 1);

                -- Show objectives.
                AddObjectiveOverride("defend_truck.otf", "GREEN", 10, true);
                AddObjective("assist_shab.otf", "WHITE");

                -- Stop the loop.
                Mission.m_RedirectShabayev = true;
            end
        else
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[19] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip) and (not IsAlive(Mission.m_Scion1) and not IsAlive(Mission.m_Scion2))) then
        Retreat(Mission.m_Shabayev, "super_rendezvous");

        -- Shab: Nice Job, now come to me.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0230.wav");

        -- Show objectives.
        AddObjectiveOverride("rendezvous.otf", "WHITE", 10, true);

        if (GetCurrentCommand(Mission.m_Truck) ~= CMD_FOLLOW) then
            AddObjective("truck.otf", "WHITE");
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[20] = function()
    if (GetDistance(Mission.m_Shabayev, "super_rendezvous") < 40) then
        if (not IsPlayerWithinDistance(Mission.m_Shabayev, 25, _Cooperative.m_TotalPlayerCount)) then
            -- Have her look at the player.
            LookAt(Mission.m_Shabayev, Mission.m_MainPlayer);

            -- Mark the player as lost.
            if (not IsPlayerWithinDistance(Mission.m_Shabayev, 300, _Cooperative.m_TotalPlayerCount)) then
                -- So she starts yelling at the player.
                Mission.m_PlayerLost = true;
            end     
        elseif (GetCurHealth(Mission.m_Shabayev) < 1700) then
            -- Have the truck repair Shabayev.
            Service(Mission.m_Truck, Mission.m_Shabayev, 1);

            -- Shab: "Truck will repair me".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0248.wav");

            -- Have her look at the player incase the first one is missed.
            LookAt(Mission.m_Shabayev, Mission.m_MainPlayer);

            -- For the failure conditions.
            Mission.m_RepairsNeeded = true;

            -- Set a timer for the next message.
            Mission.m_ServiceMessageTime = Mission.m_MissionTime + SecondsToTurns(8);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        else
            -- Advance the mission state...
            Mission.m_MissionState = 22;
        end
    end
end

Functions[21] = function()
    if (Mission.m_ServiceMessageTime < Mission.m_MissionTime) then
        -- Shab: "You can get close to it.".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0261.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[22] = function()
    if (GetCurHealth(Mission.m_Shabayev) > 1700 and IsAudioMessageDone(Mission.m_Audioclip)) then
        if (GetCurrentCommand(Mission.m_Truck) ~= CMD_FOLLOW) then
            -- Give command back to the main player.
            Follow(Mission.m_Truck, Mission.m_MainPlayer, 0);
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[23] = function()
    if (IsAlive(Mission.m_Builder1)) then
        -- Next stage is chasing the builder.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0222.wav");

        -- Check if the truck is following...
        if (not Mission.m_TruckFollowing) then
            -- Time before the message.
            Mission.m_GetTruckTime = Mission.m_MissionTime + SecondsToTurns(5);
            -- To do the message if it's not following.
            Mission.m_TruckMessage = true;
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[24] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip) and Mission.m_TruckFollowing) then
        -- Move the Commander to her next path.
        Goto(Mission.m_Shabayev, "shab_path2");

        -- So we can process the next phase of the mission.
        Mission.m_CheckpointDone = true;
        -- For the failure conditions.
        Mission.m_RepairsNeeded = false;

        -- Show objectives.
        AddObjectiveOverride("follow_shab.otf", "WHITE", 10, true);

        -- Shab: Okay, follow me...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0209.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[25] = function()
    if (Mission.m_CheckpointDone and IsPlayerWithinDistance(Mission.m_Builder1, 175, _Cooperative.m_TotalPlayerCount) and IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Shab: It's getting away, follow it!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0241.wav");

        -- Wait a second before Shabayev questions what it is
        Mission.m_BuilderFollowTime = Mission.m_MissionTime + SecondsToTurns(1);

        -- Tell Shabayev to Follow the builder.
        Follow(Mission.m_Shabayev, Mission.m_Builder1, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[26] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip) and Mission.m_BuilderFollowTime < Mission.m_MissionTime) then
        -- Shab: What is that thing?
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0223.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[27] = function()
    if (not IsAlive(Mission.m_Builder1) and not Mission.m_BuildKilledPrematurely and Mission.m_ShabBuilderDeadMessagePlayed and IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Tell Shabayev to retreat here after her dialogue.
        Retreat(Mission.m_Shabayev, "shab_path2a");

        -- For the failure conditions.
        Mission.m_RepairsNeeded = false;

        -- So we don't loop.
        Mission.m_BuildKilledPrematurely = true;
    end

    -- Distance checks to launch the second attack.
    if (GetDistance(Mission.m_Shabayev, "jam2_spawn") < 150 or IsPlayerWithinDistance("jam2_spawn", 150, _Cooperative.m_TotalPlayerCount)) then
        -- Highlight the next  Jammer.
        SetObjectiveOn(Mission.m_Jammer2);

        -- Have each Scion unit defend the Jammer.
        Defend2(Mission.m_Scion1, Mission.m_Jammer2, 1);
        Defend2(Mission.m_Scion2, Mission.m_Jammer2, 1);
        Defend2(Mission.m_Scion3, Mission.m_Jammer2, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[28] = function()
    -- Give Shabayev a target.
    if (GetCurrentCommand(Mission.m_Shabayev) ~= CMD_ATTACK) then
        if (IsAlive(Mission.m_Scion1)) then
            Attack(Mission.m_Shabayev, Mission.m_Scion1, 1);
        elseif (IsAlive(Mission.m_Scion2)) then
            Attack(Mission.m_Shabayev, Mission.m_Scion2, 1);
        elseif (IsAlive(Mission.m_Scion3)) then
            Attack(Mission.m_Shabayev, Mission.m_Scion3, 1);
        else
            Attack(Mission.m_Shabayev, Mission.m_Jammer2, 1);
        end
    end

    if (IsAlive(Mission.m_Jammer2) and Mission.m_ShabGarbledMessageTime < Mission.m_MissionTime and IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Repeat this process every 8 seconds until the Jammer is destroyed.
        Mission.m_ShabGarbledMessageTime = Mission.m_MissionTime + SecondsToTurns(8);

        -- Shab: *STATIC*
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0213a.wav");
    elseif (not IsAlive(Mission.m_Jammer2) and not IsAlive(Mission.m_Scion1) and not IsAlive(Mission.m_Scion2) and not IsAlive(Mission.m_Scion3)) then
        -- Destroy the Builder.
        if (IsAlive(Mission.m_Builder1)) then
            Damage(Mission.m_Builder1, 2500);
        end

        -- Stop any garbbled messages.
        StopAudioMessage(Mission.m_Audioclip);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[29] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        if (IsAlive(Mission.m_Builder1)) then
            EjectPilot(Mission.m_Builder1);
        end

        Retreat(Mission.m_Shabayev, "jam2_spawn");

        -- Shab: Nice Job, now come to me.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0230.wav");

        -- Show objectives.
        AddObjectiveOverride("rendezvous.otf", "WHITE", 10, true);

        if (GetCurrentCommand(Mission.m_Truck) ~= CMD_FOLLOW) then
            AddObjective("truck.otf", "WHITE");
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[30] = function()
    if (GetDistance(Mission.m_Shabayev, "jam2_spawn") < 40) then
        if (not IsPlayerWithinDistance(Mission.m_Shabayev, 25, _Cooperative.m_TotalPlayerCount)) then
            -- Have her look at the player.
            LookAt(Mission.m_Shabayev, Mission.m_MainPlayer);

            -- Mark the player as lost.
            if (not IsPlayerWithinDistance(Mission.m_Shabayev, 300, _Cooperative.m_TotalPlayerCount)) then
                -- So she starts yelling at the player.
                Mission.m_PlayerLost = true;
            end
        else
            -- Shab: "This place is hotter than hell!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0233.wav");

            -- Check if the truck is following...
            if (not Mission.m_TruckFollowing) then
                -- Time before the message.
                Mission.m_GetTruckTime = Mission.m_MissionTime + SecondsToTurns(5);
                -- To do the message if it's not following.
                Mission.m_TruckMessage = true;
            end

            -- Mark this chapter as done, we can move on.
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[31] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip) and Mission.m_TruckFollowing) then
        -- Move to the next location.
        Retreat(Mission.m_Shabayev, "shab_path3", 1);

        -- Shab: Let's press on.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0234.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[32] = function()
    if (GetDistance(Mission.m_Shabayev, "scav_point") < 40) then
        -- Look at the dead Scavenger.
        LookAt(Mission.m_Shabayev, Mission.m_DeadScav1, 1);

        -- Shab: Scavengers, these guys didn't have a chance...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0235.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[33] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Make her retreat.
        Retreat(Mission.m_Shabayev, "sue_path", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[34] = function()
    if (GetDistance(Mission.m_Shabayev, "sue_point") < 40) then
        -- Shab: This must be the base. Let's move.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0238.wav");

        -- Set this timer to 4 seconds.
        Mission.m_OnToBaseTime = Mission.m_MissionTime + SecondsToTurns(4);

        -- Check if the truck is following...
        if (not Mission.m_TruckFollowing) then
            -- Time before the message.
            Mission.m_GetTruckTime = Mission.m_MissionTime + SecondsToTurns(5);
            -- To do the message if it's not following.
            Mission.m_TruckMessage = true;
        end

        -- Have Shab look at the player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[35] = function()
    if (Mission.m_OnToBaseTime < Mission.m_MissionTime and Mission.m_TruckFollowing) then
        -- Cooldown time.
        Mission.m_OnToBaseTime = Mission.m_MissionTime + SecondsToTurns(0.5);

        -- Move in to the base when the player is within distance.
        if (IsPlayerWithinDistance(Mission.m_Shabayev, 100, _Cooperative.m_TotalPlayerCount)) then
            -- Move Shabayev to the base.
            Goto(Mission.m_Shabayev, "base_center");

            -- Move turrets if they are alive
            if (IsAlive(Mission.m_LastTurret1)) then
                -- AI Stuff...
                SetAvoidType(Mission.m_LastTurret1, 0);
                -- Move turrets to encounter.
                Retreat(Mission.m_LastTurret1, "last_turret_path");
            end

            if (IsAlive(Mission.m_LastTurret2)) then
                -- AI Stuff...
                SetAvoidType(Mission.m_LastTurret2, 0);
                -- Move turrets to encounter.
                Retreat(Mission.m_LastTurret2, "last_turret_path");
            end

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[36] = function()
    if (GetDistance(Mission.m_Shabayev, "base_center") < GetDistance(Mission.m_Shabayev, "sue_point") and IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Shab: This place was hit hard...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0239.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[37] = function()
    -- Have the turrets stop if they are close to the base center.
    if (IsAlive(Mission.m_LastTurret1)) then
        if (GetDistance(Mission.m_LastTurret1, "base_center") < 20) then
            -- Have the turrets attack
            Attack(Mission.m_LastTurret1, Mission.m_Shabayev, 1);

            -- If the second turret is alive, have it attack the player.
            if (IsAlive(Mission.m_LastTurret2)) then
                -- Have the turrets attack
                Attack(Mission.m_LastTurret2, Mission.m_MainPlayer, 1);
            end

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    elseif (IsAlive(Mission.m_LastTurret2)) then
        if (GetDistance(Mission.m_LastTurret1, "base_center") < 20) then
            -- Have the turrets attack
            Attack(Mission.m_LastTurret2, Mission.m_MainPlayer, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[38] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        if (IsAlive(Mission.m_LastTurret1) or IsAlive(Mission.m_LastTurret2)) then
            -- Shab: "We've got company!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0264.wav");
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[39] = function()
    if (GetCurrentCommand(Mission.m_Shabayev) ~= CMD_ATTACK) then
        if (IsAlive(Mission.m_LastTurret1)) then
            -- Have Shabayev attack the first turret.
            Attack(Mission.m_Shabayev, Mission.m_LastTurret1, 1);
        elseif (IsAlive(Mission.m_LastTurret2)) then
            -- Have Shabayev attack the first turret.
            Attack(Mission.m_Shabayev, Mission.m_LastTurret2, 1);
        end
    end

    if (not IsAlive(Mission.m_LastTurret1) and not IsAlive(Mission.m_LastTurret2)) then
        -- Move Shabayev to the center of the base.
        Goto(Mission.m_Shabayev, "base_center");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[40] = function()
    if (GetDistance(Mission.m_Shabayev, "base_center") < 30) then
        -- Shab: This place is crawling, we've got to get power back online...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0257a.wav");

        -- Make her look at the player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Make a delay..
        Mission.m_OnToBaseTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[41] = function()
    if (Mission.m_OnToBaseTime < Mission.m_MissionTime) then
        -- Have Shab look at one of the dead power buildings.
        if (IsAround(Mission.m_DeadPower1)) then
            LookAt(Mission.m_Shabayev, Mission.m_DeadPower1);
        elseif (IsAround(Mission.m_DeadPower2)) then
            LookAt(Mission.m_Shabayev, Mission.m_DeadPower2);
        elseif (IsAround(Mission.m_DeadPower3)) then
            LookAt(Mission.m_Shabayev, Mission.m_DeadPower3);
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[42] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Move shab to the constructor
        Goto(Mission.m_Shabayev, "to_builder_path");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[43] = function()
    if (GetDistance(Mission.m_Shabayev, Mission.m_Cons) < 30) then
        -- Get her to look at the constructor for 5 seconds.
        LookAt(Mission.m_Shabayev, Mission.m_Cons, 1);

        -- Add the 5 second delay.
        Mission.m_ShabConWaitTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[44] = function()
    if (Mission.m_ShabConWaitTime < Mission.m_MissionTime) then
        -- Add a delay to keep checking when the player is within enough distance.
        Mission.m_ShabConWaitTime = Mission.m_MissionTime + SecondsToTurns(.5);

        -- Run a distance check on the player.
        if (IsPlayerWithinDistance(Mission.m_Shabayev, 70, _Cooperative.m_TotalPlayerCount)) then
            -- Remove the objective from the Shab scout.
            SetObjectiveOff(Mission.m_Shabayev);
            SetObjectiveName(Mission.m_Shabayev, "Scout");

            -- Have her hop out.
            HopOut(Mission.m_Shabayev);

            -- Next state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[45] = function()
    -- Move Shabayev's pilot to the constructor.
    if (IsAlive(Mission.m_Shabayev) and IsOdf(Mission.m_Shabayev, "isshab_p")) then
        -- Order Shab to the Constructor
        Goto(Mission.m_Shabayev, "con_spawn", 1);

        -- Next state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[46] = function()
    -- We need to run a distance check here to make sure she enters the constructor.
    if (IsAlive(Mission.m_Shabayev) and IsAlive(Mission.m_Cons)) then
        if (GetDistance(Mission.m_Shabayev, Mission.m_Cons) < 10) then
            -- Remove Shabayev.
            RemoveObject(Mission.m_Shabayev);

            -- Change Shabayev to the Constructor.
            Mission.m_Shabayev = Mission.m_Cons;

            -- Change the Constructor to the right team.
            SetTeamNum(Mission.m_Shabayev, Mission.m_HostTeam);

            -- Play the startup animation.
            SetAnimation(Mission.m_Shabayev, "startup", 1);

            -- Set her name and objective beacon.
            SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
            SetObjectiveOn(Mission.m_Shabayev);

            -- Add a delay
            Mission.m_ShabConWaitTime = Mission.m_MissionTime + SecondsToTurns(3);

            -- Next state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[47] = function()
    if (Mission.m_ShabConWaitTime < Mission.m_MissionTime) then
        -- Shab: Ugh, it's been a while...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0258a.wav");

        -- Add a delay
        Mission.m_ShabConWaitTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- Next state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[48] = function()
    -- Replace the placeholder constructor with a new one.
    Mission.m_Shabayev = ReplaceObject(Mission.m_Shabayev, "ivpcon");

    -- Have her stop.
    Stop(Mission.m_Shabayev, 1);

    -- Some AI stuff..
    SetAvoidType(Mission.m_Shabayev, 0);

    -- Set her name and objective beacon.
    SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
    SetObjectiveOn(Mission.m_Shabayev);

    -- Small delay for the next part.
    Mission.m_ShabConWaitTime = Mission.m_MissionTime + SecondsToTurns(1);

    -- Next state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[49] = function()
    if (Mission.m_ShabConWaitTime < Mission.m_MissionTime) then
        -- Prep Shabayev to build the power plant.
        Build(Mission.m_Shabayev, "ibpgn1");

        -- Add a small delay.
        Mission.m_ShabConWaitTime = Mission.m_MissionTime + SecondsToTurns(0.2);

        -- Move to the next state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[50] = function()
    if (Mission.m_ShabConWaitTime < Mission.m_MissionTime) then
        -- So we can launch third Scion attack.
        Mission.m_ShabayevReturningToBase = true;

        -- So we wait 2 seconds per check.
        Mission.m_SafeSpawnCheckTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Move Shabayev to the base.
        Goto(Mission.m_Shabayev, "to_power_path2");

        -- Move to the next state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[51] = function()
    -- Run a check to get the third Scion to attack when Shabayev isn't too far from her destination.
    if (IsAlive(Mission.m_Scion3) and GetCurrentCommand(Mission.m_Scion3) ~= CMD_ATTACK) then
        -- Run a distance check.
        if (GetDistance(Mission.m_Shabayev, "back_at_base") < 175) then
            -- Send the Scion to attack.
            Attack(Mission.m_Scion3, Mission.m_Shabayev, 1);
        end
    end

    if (GetDistance(Mission.m_Shabayev, "back_at_base") < 20) then
        -- Starts the building procedure.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0262.wav");

        -- Make Shabayev deploy to build the Power Generator.
        Dropoff(Mission.m_Shabayev, "power_point", 1);

        -- Move to the next state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[52] = function()
    if (IsAlive(Mission.m_BasePower)) then
        -- Shab: "Power's back online boys. Good work."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("cin0201.wav");

        -- Set the pole times.
        Mission.m_Pole3Time = Mission.m_MissionTime + SecondsToTurns(2);
        Mission.m_Pole4Time = Mission.m_MissionTime + SecondsToTurns(3.5);
        Mission.m_Pole5Time = Mission.m_MissionTime + SecondsToTurns(5);
        Mission.m_Pole6Time = Mission.m_MissionTime + SecondsToTurns(6.5);
        Mission.m_Pole7Time = Mission.m_MissionTime + SecondsToTurns(8);
        Mission.m_Pole8Time = Mission.m_MissionTime + SecondsToTurns(9.5);
        Mission.m_Pole9Time = Mission.m_MissionTime + SecondsToTurns(11);
        Mission.m_Pole10Time = Mission.m_MissionTime + SecondsToTurns(12.5);
        Mission.m_Pole11Time = Mission.m_MissionTime + SecondsToTurns(14.0);

        -- Move to the next state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[53] = function()
    -- Prep the camera.
    CameraReady();

    -- Move to the next state.
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[54] = function()
    -- Get the Camera to look at the right path.
    CameraPath("camera_point2", 700, 0, Mission.m_LookPole);

    -- Move to the next state.
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[55] = function()
    -- Gradually replace each pole.
    if (not IsOdf(Mission.m_Pole3, "pbtele01") and Mission.m_Pole3Time < Mission.m_MissionTime) then
        Mission.m_Pole3 = ReplaceObject(Mission.m_Pole3, "pbtele01");
    end

    if (not IsOdf(Mission.m_Pole4, "pbtele01") and Mission.m_Pole4Time < Mission.m_MissionTime) then
        Mission.m_Pole4 = ReplaceObject(Mission.m_Pole4, "pbtele01");
    end

    if (not IsOdf(Mission.m_Pole5, "pbtele01") and Mission.m_Pole5Time < Mission.m_MissionTime) then
        Mission.m_Pole5 = ReplaceObject(Mission.m_Pole5, "pbtele01");
    end

    if (not IsOdf(Mission.m_Pole6, "pbtele01") and Mission.m_Pole6Time < Mission.m_MissionTime) then
        Mission.m_Pole6 = ReplaceObject(Mission.m_Pole6, "pbtele01");
    end

    if (not IsOdf(Mission.m_Pole7, "pbtele01") and Mission.m_Pole7Time < Mission.m_MissionTime) then
        Mission.m_Pole7 = ReplaceObject(Mission.m_Pole7, "pbtele01");
    end

    if (not IsOdf(Mission.m_Pole8, "pbtele01") and Mission.m_Pole8Time < Mission.m_MissionTime) then
        Mission.m_Pole8 = ReplaceObject(Mission.m_Pole8, "pbtele01");
    end

    if (not IsOdf(Mission.m_Pole9, "pbtele01") and Mission.m_Pole9Time < Mission.m_MissionTime) then
        Mission.m_Pole9 = ReplaceObject(Mission.m_Pole9, "pbtele01");
    end

    if (not IsOdf(Mission.m_Pole10, "pbtele01") and Mission.m_Pole10Time < Mission.m_MissionTime) then
        Mission.m_Pole10 = ReplaceObject(Mission.m_Pole10, "pbtele01");
    end

    if (not IsOdf(Mission.m_Pole11, "pbtele01") and Mission.m_Pole11Time < Mission.m_MissionTime) then
        Mission.m_Pole11 = ReplaceObject(Mission.m_Pole11, "pbtele01");

        -- Move to the next state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[56] = function()
    if (Mission.m_IsCooperativeMode) then
        NoteGameoverWithCustomMessage("Mission Accomplished.");
        DoGameover(2.1);
    else
        SucceedMission(GetTime() + 2.1, "isdf02w1.txt");
    end
end

-- This function handles dispatching all spawned Scion attackers during the mission runtime.
function HandleScionAttackWaves() 
    -- For the first attack, we need to send the enemy attackers if the Jammer is built, or the build is under 50% health.
    if (not Mission.m_FirstAttackWaveSent and (IsAlive(Mission.m_Jammer) or (IsAlive(Mission.m_Builder1) and GetHealth(Mission.m_Builder1) < 0.5) or (not IsAlive(Mission.m_Builder1)))) then
        -- Check if the wave attackers are alive and move them to the right position.
        if (IsAlive(Mission.m_Scion1)) then
            Goto(Mission.m_Scion1, "jammer_spawn", 1);
        end

        if (IsAlive(Mission.m_Scion2)) then
            Goto(Mission.m_Scion2, "jammer_spawn", 1);
        end

        -- Mark this event as done so we don't loop logic.
        Mission.m_FirstAttackWaveSent = true;
    elseif (Mission.m_FirstAttackWaveSent and Mission.m_CheckpointDone and not Mission.m_SecondAttackWaveSpawned) then
        -- Spawn the second Scion units.
        Mission.m_Scion1 = BuildObject(m_SecondScionWave1[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "morph2_point1");
        Mission.m_Scion2 = BuildObject(m_SecondScionWave2[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "morph2_point2");
        Mission.m_Scion3 = BuildObject(m_SecondScionWave3[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "morph2_point3");

        -- Set their skills.
        SetSkill(Mission.m_Scion1, Mission.m_MissionDifficulty);
        SetSkill(Mission.m_Scion2, Mission.m_MissionDifficulty);
        SetSkill(Mission.m_Scion3, Mission.m_MissionDifficulty);

        -- So they don't sit idle, get them to defend the Jammer.
        Patrol(Mission.m_Scion1, "patrol2_a");
        Patrol(Mission.m_Scion2, "patrol2_b");
        Defend(Mission.m_Scion3, Mission.m_Jammer2);

        -- Second Jammer.
        Mission.m_Jammer2 = BuildObject("fbpjam", Mission.m_EnemyTeam, "jam2_spawn");

        -- So we don't loop.
        Mission.m_SecondAttackWaveSpawned = true;
    elseif (Mission.m_SecondAttackWaveSpawned and Mission.m_ShabayevReturningToBase and not Mission.m_ThirdAttackWaveSent) then
        if (Mission.m_SafeSpawnCheckTime < Mission.m_MissionTime) then
            -- Add a delay between each loop
            Mission.m_SafeSpawnCheckTime = Mission.m_MissionTime + SecondsToTurns(2);

            -- Run checks
            if (not IsPlayerWithinDistance("base_epsawn2", 200, _Cooperative.m_TotalPlayerCount)) then
                -- Build and send enemy units.
                Mission.m_Scion1 = BuildObject(m_ThirdScionWave1[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "base_espawn1");
                Mission.m_Scion2 = BuildObject(m_ThirdScionWave2[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "base_espawn2");
                Mission.m_Scion3 = BuildObject(m_ThirdScionWave3[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "base_espawn3");

                -- Have them attack.
                Attack(Mission.m_Scion1, Mission.m_Shabayev, 1);
                Attack(Mission.m_Scion2, Mission.m_Truck, 1);

                -- Have a lurker in the base.
                Goto(Mission.m_Scion3, "base_center");

                -- So we don't loop.
                Mission.m_ThirdAttackWaveSent = true;
            end
        end
    elseif (Mission.m_ThirdAttackWaveSent and not Mission.m_CompanyMessagePlayed) then
        if ((GetDistance(Mission.m_Scion1, Mission.m_Shabayev) < 100 or IsPlayerWithinDistance(Mission.m_Scion1, 70, _Cooperative.m_TotalPlayerCount)) or 
            (GetDistance(Mission.m_Scion2, Mission.m_Shabayev) < 100 or IsPlayerWithinDistance(Mission.m_Scion2, 70, _Cooperative.m_TotalPlayerCount))) then
            -- Shab: We've got company!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0259.wav");  

            -- So we don't loop.
            Mission.m_CompanyMessagePlayed = true;
        end
    end
end

-- This function handles playing Shabayev's garbbled dialogue when a Jammer is present and near the player.
function HandleShabayevGarbledDialogue()
    if (IsAlive(Mission.m_Jammer) and Mission.m_JammerMessageTime < Mission.m_MissionTime) then
        if (not Mission.m_ScrambledMessage) then
            -- Shab: *STATIC* Destroy that object!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0213.wav");

            -- Set the Jammer message time so it doesn't constantly loop over.
            Mission.m_JammerMessageTime = Mission.m_MissionTime + SecondsToTurns(15);

            -- So we can alternate between dialogue.
            Mission.m_ScrambledMessage = true;
        else
            -- Shab: *STATIC*
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0229.wav");

            -- Set the Jammer message time so it doesn't constantly loop over.
            Mission.m_JammerMessageTime = Mission.m_MissionTime + SecondsToTurns(25);

            -- So we can alternate between dialogue.
            Mission.m_ScrambledMessage = false;
        end
    end
end

-- This function is the `brain` of the Scion builder.
function HandleScionBuilder()
    -- STEP 1: The Scion Builder needs to flee the area after correctly constructing the Jammer.
    if (not Mission.m_BuilderRun and IsAlive(Mission.m_Jammer) and Mission.m_BuilderRunTime < Mission.m_MissionTime) then
        -- Some AI stuff...
        SetAvoidType(Mission.m_Builder1, 0);

        -- Builder has to retreat.
        Retreat(Mission.m_Builder1, "builder_goto_path", 1);

        -- Add 3 seconds so the builder goes the correct path.
        Mission.m_BuilderRunCheck = Mission.m_MissionTime + SecondsToTurns(8);

        -- Mark this portion as done.
        Mission.m_BuilderRun = true;
    -- STEP 2: This part pauses the Builder so the player and Shabayev can catch up and chase it. 
    elseif (Mission.m_BuilderRun and Mission.m_BuilderRunCheck < Mission.m_MissionTime and not Mission.m_BuilderSecondRetreatDone) then
        -- Keep looping and adding to the time we check until we stop.
        Mission.m_BuilderRunCheck = Mission.m_MissionTime + SecondsToTurns(2);

        -- Run a check to see if we need to stop or not.
        if (GetDistance(Mission.m_Builder1, "morph_point1") < 50 and (GetDistance(Mission.m_Builder1, Mission.m_Shabayev) > 150 and IsPlayerWithinDistance(Mission.m_Builder1, 150, _Cooperative.m_TotalPlayerCount))) then
            -- Halt!
            Stop(Mission.m_Builder1, 1);
        else
            -- Retreat down the second path to the second Jammer site.
            Retreat(Mission.m_Builder1, "drone_path");
            -- So we don't loop.
            Mission.m_BuilderSecondRetreatDone = true;
        end
    end
end

-- TODO: Add function to handle Service Truck responsibilities. 
-- Yell at the player if they take too long ordering the truck.
function HandlePlayerDisobeyingOrders()
    if (Mission.m_PlayerLost) then
        if (not Mission.m_FirstWarning) then
            -- Shab: Do you want to join me?
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0206.wav");

            -- Set a delay between loops.
            Mission.m_PlayerCheckTime = Mission.m_MissionTime + SecondsToTurns(1.5);

            -- Wait a duration before the next warning.
            Mission.m_PlayerLostTime = Mission.m_MissionTime + SecondsToTurns(25);

            -- To advance to the next warning.
            Mission.m_SecondWarning = false;

            -- So we don't loop.
            Mission.m_FirstWarning = true;
        elseif (not Mission.m_SecondWarning) then
            if (Mission.m_PlayerLostTime < Mission.m_MissionTime) then
                -- Shab: Last warning John!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0208.wav");

                -- Set a delay between loops.
                Mission.m_PlayerCheckTime = Mission.m_MissionTime + SecondsToTurns(3);

                -- Wait a duration before the next warning.
                Mission.m_PlayerLostTime = Mission.m_MissionTime + SecondsToTurns(40);

                -- So we don't loop.
                Mission.m_SecondWarning = true;
            end
        end

        -- Reset if the player is within Distance.
        if (not Mission.m_MissionFailed and Mission.m_PlayerCheckTime < Mission.m_MissionTime) then
            -- Set a delay between loops.
            Mission.m_PlayerCheckTime = Mission.m_MissionTime + SecondsToTurns(1.5);

            if (IsPlayerWithinDistance(Mission.m_Shabayev, 100, _Cooperative.m_TotalPlayerCount)) then
                -- Run a reset if the player returns.
                Mission.m_FirstWarning = false;
                Mission.m_SecondWarning = false;

                -- No longer lost.
                Mission.m_PlayerLost = false;
            end
        end
    elseif (IsAlive(Mission.m_Truck) and not Mission.m_RepairsNeeded) then
        -- Check to see if the truck is following a player, or Shabayev.
        if (GetCurrentCommand(Mission.m_Truck) == CMD_FOLLOW) then
            -- If it is following, but it's not the player...Run the reminder.
            local leader = GetCurrentWho(Mission.m_Truck);

            -- Check if the truck is following the player or Shabayev.
            Mission.m_TruckFollowing = (IsPlayer(leader) or leader == Mission.m_Shabayev);

            -- If it's following the players, or Shab, turn the reminder off.
            if (Mission.m_TruckFollowing) then
                Mission.m_TruckMessage = false;
            end
        else 
            -- Truck is not following.
            Mission.m_TruckFollowing = false;

            -- To start the reminder.
            Mission.m_TruckMessage = true;
        end
    end

    -- Reminder to have the truck to follow.
    if (Mission.m_TruckMessage and Mission.m_GetTruckTime < Mission.m_MissionTime and Mission.m_MissionState >= 9) then
        -- Delay between loops.
        Mission.m_GetTruckTime = Mission.m_MissionTime + SecondsToTurns(20);

        -- Show objectives.
        AddObjectiveOverride("truck.otf", "WHITE", 10, true);

        -- Shab: Make sure the Service Truck is following you.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0204.wav");
    end
end

function HandleFailureConditions()
    -- If the truck died...
    if (not IsAlive(Mission.m_Truck)) then
        -- Halt the mission.
        Mission.m_MissionFailed = true;

        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Shab: You let the truck die!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0244.wav");

        -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("You lost the Service Truck!");
            DoGameover(7);
        else
            FailMission(GetTime() + 7);
        end
    -- Check if the Constructor is dead.
    elseif (not IsAlive(Mission.m_Cons) and not IsOdf(Mission.m_Shabayev, "ivpcon")) then
        -- Halt the mission.
        Mission.m_MissionFailed = true;

        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Shab: I needed that Constructor!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0260.wav");

        -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("You lost the Constructor!");
            DoGameover(7);
        else
            FailMission(GetTime() + 7, "isdf02l1.txt");
        end
    -- If Shabayev died...
    elseif (IsOdf(Mission.m_Shabayev, "isshab_p") and not IsAlive(Mission.m_Shabayev)) then
        -- Halt the mission.
        Mission.m_MissionFailed = true;

        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Truck: Shabayev is dead!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0243.wav");

        -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Shabayev is KIA!");
            DoGameover(7);
        else
            FailMission(GetTime() + 7);
        end
    -- If the player refuses to stay with Shabayev...
    elseif ((Mission.m_ServiceTruckWarning and Mission.m_PlayerTruckWarningTime < Mission.m_MissionTime) or (Mission.m_SecondWarning and Mission.m_PlayerLostTime < Mission.m_MissionTime)) then
        -- Halt the mission.
        Mission.m_MissionFailed = true;

        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Truck: Shabayev is dead!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0242.wav");

        -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("You failed to follow the orders of your commanding officer!");
            DoGameover(7);
        else
            FailMission(GetTime() + 7);
        end
    end
end