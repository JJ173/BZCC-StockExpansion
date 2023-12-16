--[[ 
    BZCC ISDF04 Lua Mission Script
    Written by AI_Unit
    Version 1.0 23-11-2023
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

-- Attacks based on difficulty
local attack1 = {
    {"fvscout_x", "fvscout_x"},
    {"fvscout_x", "fvsent_x"},
    {"fvsent_x", "fvsent_x"}
}

local attack2 = {
    {"fvscout_x", "fvscout_x", "fvscout_x"},
    {"fvsent_x", "fvscout_x", "fvscout_x"},
    {"fvsent_x", "fvsent_x", "fvscout_x"}
}

local attackWaves = {
    {{"fvscout_x", "fvscout_x", "fvsent_x"}, {"fvsent_x", "fvsent_x", "fvscout_x"}, {"fvscout_x", "fvtank_x", "fvsent_x"}}, -- Wave 1
    {{"fvsent_x", "fvsent_x", "fvscout_x"}, {"fvsent_x", "fvsent_x", "fvsent_x", "fvscout_x"}, {"fvsent_x", "fvsent_x", "fvtank_x", "fvtank_x"}}, -- Wave 2
    {{"fvsent_x", "fvsent_x", "fvscout_x", "fvscout_x"}, {"fvsent_x", "fvsent_x", "fvtank_x", "fvtank_x"}, {"fvtank_x", "fvtank_x", "fvtank_x", "fvtank_x"}}, -- Wave 3
    {{"fvsent_x", "fvsent_x", "fvsent_x", "fvsent_x"}, {"fvsent_x", "fvtank_x", "fvtank_x", "fvtank_x", "fvsent_x"}, {"fvtank_x", "fvtank_x", "fvtank_x", "fvtank_x", "fvsent_x", "fvsent_x"}} -- Wave 4
}

local attackWaveCooldown = {"105", "90", "75"};

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
    m_PlayerShipODF = "ivtank_x";

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionStartDone = false,
    m_MissionOver = false,
    m_TugPickup = false,
    m_Tug1Move = false,
    m_Tug2Move = false,
    m_Tug1Board = false,
    m_Tug2Board = false,
    m_CloseTugDropshipDoors = false,
    m_TugDropshipTakeoff = false,
    m_RecyDropshipTakeoff = false,
    m_RecyDropshipRemoved = false,
    m_TugBrainDone = false,
    m_ShabRecyDeployMessageDone = false,
    m_BuildingStarted = false,
    m_FirstTurretBuilt = false,
    m_BunkerWarningActive = false,
    m_MansonSentryWarningPlayed = false,
    m_ConvoyHalted = false,
    m_CliffCrumble = false,
    m_CliffCrumbleImpact = false,
    m_SucceedMission = false,
    m_ScavengerConditionActive = false,
    m_TurretFollowing = false,
    m_ScavengerReminderActive = false,

    m_MainPlayer = nil,
    m_Shabayev = nil,
    m_Recycler = nil,
    m_Manson = nil,
    m_Blue1 = nil,
    m_Blue2 = nil,
    m_Friend1 = nil,
    m_Friend2 = nil,
    m_Tug1 = nil,
    m_Tug2 = nil,
    m_Relic1 = nil,
    m_Relic2 = nil,
    m_ScionDropship = nil,
    m_RecyDropship = nil,
    m_TugDropship = nil,
    m_Scavenger = nil,
    m_Turret = nil,
    m_Nav1 = nil,
    m_Nav2 = nil,
    m_Scion1 = nil,
    m_Scion2 = nil,
    m_PowerUp = nil,
    m_FieldBunker = nil,
    m_SnipeScion1 = nil,
    m_SnipeScion2 = nil,
    m_SnipeScion3 = nil,
    m_SnipeScion4 = nil,
    m_SnipeScion5 = nil,
    m_SnipedShip = nil,
    m_Cliff = nil,

    m_PlayerUnits = {},
    m_ScionFinalWaveUnits = {},
    
    m_Audioclip = nil,
    
    m_TugCheckTime = 0,
    m_MessageDeployTime = 0,
    m_RecyclerMoveTime = 0,
    m_MissionDelayTime = 0,
    m_ScavengerReminderTime = 0,
    m_RelayBunkerWarningTime = 0,
    m_ScionWaveCount = 1,
    m_ScionWaveCooldown = 0,
    m_RelayBunkerWarningCount = 0,

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
    PreloadODF("ivrecy_x");
    PreloadODF("ivtank_x");
    PreloadODF("ivscav_x");
    PreloadODF("ivturr_x");
    PreloadODF("ibscav_x");
    PreloadODF("fvsent_x");
    PreloadODF("fvscout_x");
    PreloadODF("fvtank_x");
    PreloadODF("isuser_mx");
    PreloadODF("ivtank4");
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
    -- Check the team of the handle.
    local teamNum = GetTeamNum(h);

    -- Test to make the power-up invincible.
    if (IsOdf(h, "apsnip_x")) then
        SetMaxHealth(h, 0);
    end

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);

        -- Pilots are forbidden in this mission.
        if (not IsBuilding(h)) then
            SetEjectRatio(h, 0);
        end
    elseif (teamNum == Mission.m_HostTeam) then
        -- Check the class.
        local class = GetClassLabel(h);

        -- If it's a Scavenger, set variables.
        if (class == "CLASS_SCAVENGER") then
            Mission.m_Scavenger = h;

            -- Start checking that this stays alive.
            Mission.m_ScavengerConditionActive = true;
        elseif (class == "CLASS_TURRETTANK" and not Mission.m_FirstTurretBuilt) then
            -- Assign the first turret.
            Mission.m_Turret = h;
            -- Only do it once.
            Mission.m_FirstTurretBuilt = true;
        end

        -- Run a check to add units to a table after a certain point in the mission.
        -- These units will be taken away from the player after they pick up the Sniper.
        if (Mission.m_MissionState > 22 and Mission.m_MissionState < 40) then
            -- Add these units to a table.
            Mission.m_PlayerUnits[#Mission.m_PlayerUnits + 1] = h;
        end
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
    print("Welcome to ISDF04 (Lua)");
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

    -- We're going to hijack Team 15 for Green Squad here, so we need to ally all teams.
    for i = 1, 5 do
        Ally(i, 15);
        Ally(15, i);
    end

    -- Get Team Number.
    local LocalTeamNum = GetLocalPlayerTeamNumber();

    -- Create the player for the server.
    local PlayerH = _Cooperative.SetupPlayer(LocalTeamNum, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF);

    -- Make sure we give the player control of their ship.
    SetAsUser(PlayerH, LocalTeamNum);
    
    -- Grab all of our pre-placed handles.
    Mission.m_Recycler = GetHandle("recycler");
    Mission.m_Manson = GetHandle("manson");
    Mission.m_Blue1 = GetHandle("wing1");
    Mission.m_Blue2 = GetHandle("wing2");
    Mission.m_Shabayev = GetHandle("shabayev");
    Mission.m_Recycler = GetHandle("recycler");
    Mission.m_Tug1 = GetHandle("tug1");
    Mission.m_Tug2 = GetHandle("tug2");
    Mission.m_Relic1 = GetHandle("relic1");
    Mission.m_Relic2 = GetHandle("relic2");
    Mission.m_TugDropship = GetHandle("tug_drop");
    Mission.m_RecyDropship = GetHandle("recy_drop");
    Mission.m_Wing1 = GetHandle("wing1");
    Mission.m_Wing2 = GetHandle("wing2");
    Mission.m_Nav1 = GetHandle("nav1");
    Mission.m_Pool = GetHandle("pool");
    Mission.m_FieldBunker = GetHandle("field_cbunk");
    Mission.m_ScionDropship = GetHandle("scion_drop");
    Mission.m_Cliff = GetHandle("crumble_cliff");
    Mission.m_ScionDropshipGuard = GetHandle("stode_sent");

    -- FIX: Change pre-placed dropship on the correct team.
    SetTeamNum(Mission.m_ScionDropship, Mission.m_EnemyTeam);
    
    -- So the nav isn't blank when we start the mission.
    SetObjectiveName(Mission.m_Nav1, "Scrap Pool");

    -- Give Shab her name.
    SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
    -- Do not allow control of Shabayev.
    Stop(Mission.m_Shabayev, 1);
    -- Highlight Shabayev.
    SetObjectiveOn(Mission.m_Shabayev);
    -- Give her the correct pilot.
    SetPilotClass(Mission.m_Shabayev, "isshab_p");
    -- So she always ejects.
    SetEjectRatio(Mission.m_Shabayev, 1);
    -- Make sure she has good skill.
    SetSkill(Mission.m_Shabayev, 3);

    -- Set Manson's team to blue.
    SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);
    -- Set Green team to green
    SetTeamColor(15, 127, 255, 127);

    -- Set custom names for our characters.
    SetObjectiveName(Mission.m_Manson, "Maj. Manson");
    SetObjectiveName(Mission.m_Blue1, "Sgt. Zdarko");
    SetObjectiveName(Mission.m_Blue2, "Sgt. Masiker");

    -- Highlight Manson.
    SetObjectiveOn(Mission.m_Manson);

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
            -- If the mission has advanced enough, start setting scrap so we can't build any more units.
            if (Mission.m_MissionState >= 39) then
                SetScrap(Mission.m_HostTeam, 38);
            end

            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Brain for each tug.
            if (not Mission.m_TugBrainDone) then
                TugBrain();
            end

            -- We need them later in the mission.
            if (Mission.m_MissionState < 43) then
                -- Brain for Blue Squad.
                if (IsAlive(Mission.m_Manson)) then
                    MansonBrain();
                end

                -- Brain for Shabayev.
                if (IsAlive(Mission.m_Shabayev)) then
                    ShabayevBrain();
                end
            end

            -- Check for any failure conditions.
            HandleFailureConditions();
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
        if (IsAlive(Mission.m_Shabayev) and VictimHandle == Mission.m_Shabayev) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("ff01.wav");
        end

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
    -- Some AI stuff.
    SetAvoidType(Mission.m_Manson, 0);
    SetAvoidType(Mission.m_Wing1, 0);
    SetAvoidType(Mission.m_Wing2, 0);

    -- Get everyone looking at each other.
    LookAt(Mission.m_Shabayev, Mission.m_Manson);
    LookAt(Mission.m_Manson, Mission.m_Shabayev);

    LookAt(Mission.m_Wing1, Mission.m_Manson);
    LookAt(Mission.m_Wing2, Mission.m_Manson);

    -- Replace the Recycler to use our new variant.
    Mission.m_Recycler = ReplaceObject(Mission.m_Recycler, "ivrecy4_x");

    -- Do not allow control of the Recycler.
    Stop(Mission.m_Recycler, 1);

    -- Open the dropship doors for the tugs.
    SetAnimation(Mission.m_TugDropship, "deploy", 1);

    -- Mask the dropship emmitters.
    MaskEmitter(Mission.m_TugDropship, 0);
    MaskEmitter(Mission.m_RecyDropship, 0);

    -- Set a delay before the first delay.
    Mission.m_MessageDeployTime = Mission.m_MissionTime + SecondsToTurns(5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MessageDeployTime < Mission.m_MissionTime) then
        -- Braddock: "Manson, move out."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0401.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Manson: Roger that, blue two and three, move out.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0439.wav");

        -- Remove Manson's highlight.
        SetObjectiveOff(Mission.m_Manson);

        -- Have Manson move out.
        Goto(Mission.m_Manson, "man_out_path");

        -- Have Blue Squad form up on Manson.
        Follow(Mission.m_Wing1, Mission.m_Manson);
        Follow(Mission.m_Wing2, Mission.m_Wing1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Braddock: Deploy the Recycler.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0420.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Have Shabayev look at the Recycler.
        LookAt(Mission.m_Shabayev, Mission.m_Recycler, 1);

        -- Shab: Roger that. Recycler one, move out of the dropship.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0440a.wav");

        -- Open the Dropship doors.
        SetAnimation(Mission.m_RecyDropship, "deploy", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Play a sound.
        StartSoundEffect("dropdoor.wav", Mission.m_RecyDropship);

        -- Have Shabayev look at the player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Some AI stuff..
        SetAvoidType(Mission.m_Recycler, 0);

        -- Move the Recycler out.
        Goto(Mission.m_Recycler, "recycler_path", 1);

        -- Shab: I'm ordering the Recycler to deploy...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0402.wav");

        -- Add some delay before the next Recycler event.
        Mission.m_RecyclerMoveTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Shab: Your Recycler is your pivotal production unit.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0421.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (GetDistance(Mission.m_Recycler, "deploy_point") < 20) then
        -- Check our delay.
        if (Mission.m_RecyclerMoveTime < Mission.m_MissionTime) then
            if (IsPlayerWithinDistance("recy_drop_point", 20, _Cooperative.m_TotalPlayerCount)) then
                if (IsAudioMessageDone(Mission.m_Audioclip)) then
                    -- Pilot: "Please clear the dropship".
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0444.wav");

                    -- Wait 10 seconds before running again.
                    Mission.m_RecyclerMoveTime = Mission.m_MissionTime + SecondsToTurns(10);
                end
            else
                -- Order the Recycler to deploy...
                Dropoff(Mission.m_Recycler, "new_drop2");

                -- Set the dropship to take off.
                SetAnimation(Mission.m_RecyDropship, "takeoff", 1);

                -- Sound effects.
                StartSoundEffect("dropdoor.wav", Mission.m_RecyDropship);

                -- Wait 3 seconds before running again.
                Mission.m_RecyclerMoveTime = Mission.m_MissionTime + SecondsToTurns(3);

                -- Advance the mission state...
                Mission.m_MissionState = Mission.m_MissionState + 1;
            end
        end
    end
end

Functions[9] = function()
    -- Handle removing the dropship.
    if (Mission.m_RecyclerMoveTime < Mission.m_MissionTime) then
        if (not Mission.m_RecyDropshipTakeoff) then
            -- Sound effects.
            StartSoundEffect("dropleav.wav", Mission.m_RecyDropship);

            -- Emitters..
            StartEmitter(Mission.m_RecyDropship, 1);
            StartEmitter(Mission.m_RecyDropship, 2);

            -- Wait 8 seconds before running again.
            Mission.m_RecyclerMoveTime = Mission.m_MissionTime + SecondsToTurns(8);

            -- So we don't loop.
            Mission.m_RecyDropshipTakeoff = true;
        elseif (not Mission.m_RecyDropshipRemoved) then
            -- Remove the dropship
            RemoveObject(Mission.m_RecyDropship);

            -- So we don't loop.
            Mission.m_RecyDropshipRemoved = true;

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end

    if (not Mission.m_ShabRecyDeployMessageDone and IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Have Shabayev look at the Recycler.
        LookAt(Mission.m_Shabayev, Mission.m_Recycler);

        -- Shab: Close enough Recy 1, deploy.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0403.wav");

        -- So we don't loop.
        Mission.m_ShabRecyDeployMessageDone = true;
    end
end

Functions[10] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Recycler: "Roger that Commander"...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0404.wav");

        -- Move Shabayev to the drop-off point.
        Goto(Mission.m_Shabayev, "start_build_point");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    if (GetDistance(Mission.m_Shabayev, "start_build_point") < 5) then
        -- Have Shabayev look at the Recycler.
        LookAt(Mission.m_Shabayev, Mission.m_Recycler, 1);

        -- Set Scrap here.
        SetScrap(Mission.m_HostTeam, 35);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    if (IsOdf(Mission.m_Recycler, "ibrecy4_x")) then
        -- Have Shabayev look at the player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Shab: The first thing you usually build is a Scav...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0405.wav");

        -- Delay some time.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Have Shabayev look at the Recycler.
        LookAt(Mission.m_Shabayev, Mission.m_Recycler);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    -- This checks if the player cancels the building process of the Scavenger.
    if (not IsAlive(Mission.m_Scavenger)) then
        if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
            if (not Mission.m_BuildingStarted) then
                -- Set the AIP.
                SetAIP("isdf0401_x.aip", Mission.m_HostTeam);

                -- Tiny delay.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

                -- So we don't loop.
                Mission.m_BuildingStarted = true;
            elseif (not IsBusy(Mission.m_Recycler)) then
                -- Shab: Don't stop the building process John.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0443.wav");

                -- Delay some time.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5);

                -- So we don't constantly loop.
                Mission.m_BuildingStarted = false;
            end
        end
    else
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[15] = function()
    -- Replace the Recycler so we can't build another Scavenger.
    Mission.m_Recycler = ReplaceObject(Mission.m_Recycler, "ibrecy4a_x");

    -- Get Shabayev to look at the player.
    LookAt(Mission.m_Shabayev, Mission.m_MainPlayer);

    -- Add Objectives.
    AddObjective("isdf0401.otf", "WHITE");

    -- Shab: Let's see if you're ready to handle it John.
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0406.wav");

    -- Highlight the Nav.
    SetObjectiveOn(Mission.m_Nav1);

    -- Set the AIP.
    SetAIP("isdf0402_x.aip", Mission.m_HostTeam);

    -- Set Scrap here.
    SetScrap(Mission.m_HostTeam, 15);

    -- Move the Scavenger as it gives control to the player.
    Goto(Mission.m_Scavenger, "recy_drop_point", 0);

    -- Add a small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;  
end

Functions[16] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Have Shab look at the nav.
        LookAt(Mission.m_Shabayev, Mission.m_Pool, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[17] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Get Shabayev to look at the player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;  
    end
end

Functions[18] = function()
    -- Check to see if a player or the Scav is near the pool.
    if (IsPlayerWithinDistance(Mission.m_Pool, 60, _Cooperative.m_TotalPlayerCount) or GetDistance(Mission.m_Scavenger, Mission.m_Pool) < 60) then
        -- Show objectives.
        AddObjectiveOverride("isdf0402.otf", "WHITE", 10, true);
        AddObjective("isdf0403.otf", "WHITE");

        -- So we can warn the player if they take too long.
        Mission.m_ScavengerReminderActive = true;

        -- Shab: There it is cowboy...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0407.wav");

        -- Small delay to remind the player to hurry.
        Mission.m_ScavengerReminderTime = Mission.m_MissionTime + SecondsToTurns(60);

        -- Spawn and attack.
        local chosenAttack = attack1[Mission.m_MissionDifficulty];

        -- Loop through difficulty table.
        for i = 1, #chosenAttack do
            local unit = BuildObject(chosenAttack[i], Mission.m_EnemyTeam, "path_"..i)

            if (i == 1) then
                Mission.m_Scion1 = unit;
            else
                Mission.m_Scion2 = unit;
            end
        end

        -- Advance the mission state...
        if (not Mission.m_IsCooperativeMode) then
            Mission.m_MissionState = Mission.m_MissionState + 1; 
        else
            Mission.m_MissionState = 20;
        end
    end
end

Functions[19] = function()
    if (IsSelected(Mission.m_Scavenger)) then
        -- Interrupt Shab.
        StopAudioMessage(Mission.m_Audioclip);

        -- Objectives.
        AddObjectiveOverride("isdf0402.otf", "WHITE", 10, true);
        AddObjective("isdf0403.otf", "GREEN");
        AddObjective("isdf0404.otf", "WHITE");

        -- Start the new message.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0408.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    elseif (IsOdf(Mission.m_Scavenger, "ibscav_x")) then 
        -- This is if they player instantly deploys the Scavenger before this step.
        Mission.m_MissionState = 21;  
    end
end

Functions[20] = function()
    if (IsOdf(Mission.m_Scavenger, "ibscav_x")) then
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[21] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Remove the warning.
        Mission.m_ScavengerReminderActive = false;

        -- This is where we send Scion attacks at the player.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0410.wav");

        -- Attack
        Attack(Mission.m_Scion1, Mission.m_Scavenger);
        Attack(Mission.m_Scion2, Mission.m_Scavenger);

        -- Show objectives.
        AddObjectiveOverride("isdf0402.otf", "GREEN", 10, true);
        AddObjective("isdf0405.otf", "WHITE");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;  
    end
end

Functions[22] = function()
    if (IsAlive(Mission.m_Scion1)) then
        if (GetDistance(Mission.m_Scion1, Mission.m_Scavenger) < 200 or IsPlayerWithinDistance(Mission.m_Scion1, 200, _Cooperative.m_TotalPlayerCount)) then
            -- Shab: More of them again!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0411.wav");
            
            -- Scrap cheat to help speed up the game.
            SetScrap(Mission.m_HostTeam, 35);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    elseif (IsAlive(Mission.m_Scion2)) then
        if (GetDistance(Mission.m_Scion2, Mission.m_Scavenger) < 200 or IsPlayerWithinDistance(Mission.m_Scion2, 200, _Cooperative.m_TotalPlayerCount)) then
            -- Shab: More of them again!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0411.wav");
            
            -- Scrap cheat to help speed up the game.
            SetScrap(Mission.m_HostTeam, 35);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    else
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[23] = function()
    if (not IsAlive(Mission.m_Scion1) and not IsAlive(Mission.m_Scion2)) then
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[24] = function()
    -- When the turret has been built...
    if (IsAlive(Mission.m_Turret)) then
        -- Add a small delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1.25);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[25] = function()
    if (not Mission.m_TurretFollowing) then
        if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
            -- Shab: A turret is on the way cowboy.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0412.wav");

            -- Get it to follow the main player.
            Follow(Mission.m_Turret, Mission.m_MainPlayer, 0);

            -- So we don't loop.
            Mission.m_TurretFollowing = true;
        end
    end

    if (GetDistance(Mission.m_Turret, Mission.m_MainPlayer) < 60) then
        -- Shab: Deploy the turret.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0413.wav");

        -- Show objectives.
        AddObjectiveOverride("isdf0402.otf", "GREEN", 10, true);
        AddObjective("isdf0405.otf", "GREEN");
        AddObjective("isdf0406.otf", "WHITE");

        -- Spawn and attack.
        local chosenAttack = attack2[Mission.m_MissionDifficulty];

        -- Loop through difficulty table.
        for i = 1, #chosenAttack do
            local unit = BuildObject(chosenAttack[i], Mission.m_EnemyTeam, "path_"..i)

            if (i == 1) then
                Mission.m_Scion1 = unit;
                Attack(unit, Mission.m_Scavenger, 1);
            elseif (i == 2) then
                Mission.m_Scion2 = unit;
                Attack(unit, Mission.m_Scavenger, 1);
            else
                Mission.m_Scion3 = unit;
                Attack(unit, Mission.m_MainPlayer, 1);
            end
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[26] = function()
    if (not IsAlive(Mission.m_Scion1) and not IsAlive(Mission.m_Scion2) and not IsAlive(Mission.m_Scion3)) then
        -- Small delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[27] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Manson: General, your plan is failing...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0414.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[28] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Braddock: Carry on Major, I'll have to improvise.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0422.wav");

        -- Have Shab look at the player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Show Objectives.
        AddObjectiveOverride("isdf0407.otf", "WHITE", 10, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[29] = function()
    if (IsPlayerWithinDistance(Mission.m_Recycler, 60, _Cooperative.m_TotalPlayerCount)) then
        -- Braddock: Commander, meet Blue Squad in Sector 12.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0441.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[30] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Shabayev: This area is not secure!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0423.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[31] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Braddock: I am aware, you heard my orders.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0424.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[32] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Shabayev: Yes sir....
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0415.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[33] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Tell Shabayev to retreat.
        Retreat(Mission.m_Shabayev, "man_out_path");

        -- Change her to look like the enemy.
        SetPerceivedTeam(Mission.m_Shabayev, Mission.m_EnemyTeam);

        -- Spawn a couple of enemies to attack.
        Attack(BuildObject("fvsent_x", Mission.m_EnemyTeam, "path_1"), Mission.m_Recycler, 1);
        Attack(BuildObject("fvsent_x", Mission.m_EnemyTeam, "path_2"), Mission.m_Recycler, 1);

        -- Remove her highlight
        SetObjectiveOff(Mission.m_Shabayev);

        -- Braddock: Cooke, I'm placing that Recycler into a production loop.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0416.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[34] = function()
    -- Show Objectives...
    AddObjectiveOverride("isdf0407.otf", "GREEN", 10, true);
    AddObjective("isdf0408.otf", "WHITE");

    -- Set the AI helper.
    SetAIP("isdf0403_x.aip", 1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[35] = function()
    -- Send some quick attacks.
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Just to probe the base.
        Mission.m_Scion1 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "path1");
        Mission.m_Scion2 = BuildObject("fvscout_x", Mission.m_EnemyTeam, "path2");

        -- Attack
        Attack(Mission.m_Scion1, Mission.m_Recycler, 1);
        Attack(Mission.m_Scion2, Mission.m_Recycler, 1);

        -- Set a delay based on time.
        Mission.m_ScionWaveCooldown = Mission.m_MissionTime + SecondsToTurns(attackWaveCooldown[Mission.m_MissionDifficulty]);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[36] = function()
    -- This method handles the waves.
    if (Mission.m_ScionWaveCooldown < Mission.m_MissionTime) then
        -- Loop through the attack table and spawn them.
        local attackTable = attackWaves[Mission.m_ScionWaveCount];
        local attacks = attackTable[Mission.m_MissionDifficulty];

        for i = 1, #attacks do
            -- Just so we don't use spawns that don't exist.
            local spawn = GetPositionNear("path_"..i, 15, 15);

            -- Anything over 4, use spawn one.
            if (i > 3) then
                spawn = GetPositionNear("enemy"..(i - 2), 15, 15);
            end

            -- Spawn each unit at a safe path.
            local unit =  BuildObject(attacks[i], Mission.m_EnemyTeam, spawn);
            
            -- Some special logic when the 4th wave is spawned.
            if (Mission.m_ScionWaveCount == 4) then
                Mission.m_ScionFinalWaveUnits[#Mission.m_ScionFinalWaveUnits + 1] = unit;
            end

            if (i < 3) then
                Attack(unit, Mission.m_Recycler, 1);
            else
                Attack(unit, Mission.m_Scavenger, 1);
            end
        end

        -- Set a delay based on time.
        Mission.m_ScionWaveCooldown = Mission.m_MissionTime + SecondsToTurns(attackWaveCooldown[Mission.m_MissionDifficulty]);

        -- Advance the attacks.
        Mission.m_ScionWaveCount = Mission.m_ScionWaveCount + 1;
    end

    -- Move on to the next method when we reach maximum spawns.
    if (Mission.m_ScionWaveCount >= 5) then
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[37] = function()
    -- If any of these units are alive, return early.
    for i = 1, #Mission.m_ScionFinalWaveUnits do
        if (IsAlive(Mission.m_ScionFinalWaveUnits[i])) then
            return;
        end
    end

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[38] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Manson: Shepherds are in place.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0418.wav");

        -- Remove the highlight from the Scrap Pool nav.
        SetObjectiveOff(Mission.m_Nav1);

        -- Show Objectives.
        AddObjectiveOverride("isdf0409.otf", "WHITE", 10, true);

        -- Create the sniper.
        Mission.m_PowerUp = BuildObject("apsnip_x", Mission.m_HostTeam, "gun_spawn");

        -- Change the name.
        SetObjectiveName(Mission.m_PowerUp, "Sniper Tracer");

        -- Highlight it.
        SetObjectiveOn(Mission.m_PowerUp);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[39] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Braddock: Get to the Armory.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0417.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[40] = function()
    -- This is Braddock telling the player to get out of the ship.
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Braddock: Hop out of your ship.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0445.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[41] = function()
    -- This is where we stop all units and launch the next phase of the mission.
    if (not IsAround(Mission.m_PowerUp)) then
        -- Stop Braddock from talking.
        StopAudioMessage(Mission.m_Audioclip);

        -- Braddock: Good job, now go to the Relay Bunker.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0419.wav");

        -- Steal control of any unit from the player.
        for i = 1, #Mission.m_PlayerUnits do
            Stop(Mission.m_PlayerUnits[i], 1);
        end

        -- Create the new nav at the bunker.
        Mission.m_Nav2 = BuildObject("ibnav", Mission.m_HostTeam, "bunk_nav_spawn");

        -- Set the name.
        SetObjectiveName(Mission.m_Nav2, "Relay Bunker");

        -- Highlight the nav.
        SetObjectiveOn(Mission.m_Nav2);

        -- Add Objectives.
        AddObjectiveOverride("isdf0409.otf", "GREEN", 10, true);
        AddObjective("isdf0410.otf", "WHITE");

        -- Activate the warning logic.
        Mission.m_BunkerWarningActive = true;

        -- Set up a warning.
        Mission.m_RelayBunkerWarningTime = Mission.m_MissionTime + SecondsToTurns(75);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[42] = function()
    if (IsPlayerWithinDistance(Mission.m_FieldBunker, 200, _Cooperative.m_TotalPlayerCount)) then
        -- Manson: The flock is moving General
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0427.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[43] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip) and IsPlayerWithinDistance(Mission.m_FieldBunker, 50, _Cooperative.m_TotalPlayerCount)) then
        -- Braddock: Get inside that bunker now, move!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0428.wav");

        -- Spawn the enemy.
        Mission.m_SnipeScion1 = BuildObject("fvpsnt4", Mission.m_EnemyTeam, "scion1_spawn");
        Mission.m_SnipeScion2 = BuildObject("fvpsnt4", Mission.m_EnemyTeam, "scion2_spawn");
        Mission.m_SnipeScion3 = BuildObject("fvpsnt4", Mission.m_EnemyTeam, "scion3_spawn");
        Mission.m_SnipeScion4 = BuildObject("fvpsnt4", Mission.m_EnemyTeam, "scion4_spawn");
        Mission.m_SnipeScion5 = BuildObject("fvpsnt4", Mission.m_EnemyTeam, "scion5_spawn");

        -- Have them stop.
        Stop(Mission.m_SnipeScion1);
        Stop(Mission.m_SnipeScion2);
        Stop(Mission.m_SnipeScion3);
        Stop(Mission.m_SnipeScion4);
        Stop(Mission.m_SnipeScion5);

        -- Some AI Stuff..
        SetAvoidType(Mission.m_SnipeScion1, 0);
        SetAvoidType(Mission.m_SnipeScion2, 0);
        SetAvoidType(Mission.m_SnipeScion3, 0);
        SetAvoidType(Mission.m_SnipeScion4, 0);
        SetAvoidType(Mission.m_SnipeScion5, 0);

        -- Add Objectives.
        AddObjectiveOverride("isdf0410.otf", "GREEN", 10, true);

        -- Remove the highlight from the bunker nav.
        SetObjectiveOff(Mission.m_Nav2);

        -- Remove the warning so we don't fail.
        Mission.m_BunkerWarningActive = false;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[44] = function()
    -- Check to see if one of our players is in the bunker.
    if (IsPlayerInBuilding(_Cooperative.m_TotalPlayerCount)) then
        -- Braddock: Okay Cooke... you've just become a key part of this op.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0430b.wav", true);

        -- Add Objectives.
        AddObjectiveOverride("isdf0411.otf", "WHITE", 10, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[45] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Move the Sentries to the sniping point.
        Retreat(Mission.m_SnipeScion1, "escape_path1");

        -- Have the rest follow.
        Follow(Mission.m_SnipeScion2, Mission.m_SnipeScion1);
        Follow(Mission.m_SnipeScion3, Mission.m_SnipeScion2);
        Follow(Mission.m_SnipeScion4, Mission.m_SnipeScion3);
        Follow(Mission.m_SnipeScion5, Mission.m_SnipeScion4);

        -- So the enemy doesn't fire at the bunker.
        SetPerceivedTeam(Mission.m_FieldBunker, Mission.m_EnemyTeam);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[46] = function()
    if (not Mission.m_MansonSentryWarningPlayed and GetDistance(Mission.m_SnipeScion1, "hold_point") < 150) then
        -- Manson: Here they come.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0429.wav");

        
        -- So we don't loop.
        Mission.m_MansonSentryWarningPlayed = true;
    elseif (not Mission.m_ConvoyHalted and GetDistance(Mission.m_SnipeScion1, "hold_point") < 20) then
        -- Have the leader look at the last unit.
        LookAt(Mission.m_SnipeScion1, Mission.m_SnipeScion5);

        -- Add Objectives.
        AddObjectiveOverride("isdf0411.otf", "GREEN", 10, true);
        AddObjective("isdf0412.otf", "WHITE");

        -- So we don't loop.
        Mission.m_ConvoyHalted = true;
    end

    -- Run some specific logic here for when the enemy is sniped.
    local check1 = IsAround(Mission.m_SnipeScion1) and not IsAlive(Mission.m_SnipeScion1);
    local check2 = IsAround(Mission.m_SnipeScion2) and not IsAlive(Mission.m_SnipeScion2);
    local check3 = IsAround(Mission.m_SnipeScion3) and not IsAlive(Mission.m_SnipeScion3);
    local check4 = IsAround(Mission.m_SnipeScion4) and not IsAlive(Mission.m_SnipeScion4);
    local check5 = IsAround(Mission.m_SnipeScion5) and not IsAlive(Mission.m_SnipeScion5);

    -- However, so we can allow some fun in coop, mark any of the 5 ships as tagged.
    if (check1) then
        -- Replace the object.
        Mission.m_SnipeScion1 = ReplaceObject(Mission.m_SnipeScion1, "fvsentx", Mission.m_HostTeam);

        -- Update it accordingly.
        UpdateTaggedScionShip(Mission.m_SnipeScion1);
    elseif (check2) then
        -- Replace the object.
        Mission.m_SnipeScion2 = ReplaceObject(Mission.m_SnipeScion2, "fvsentx", Mission.m_HostTeam);

        -- Update it accordingly.
        UpdateTaggedScionShip(Mission.m_SnipeScion2);
    elseif (check3) then
        -- Replace the object.
        Mission.m_SnipeScion3 = ReplaceObject(Mission.m_SnipeScion3, "fvsentx", Mission.m_HostTeam);

        -- Update it accordingly.
        UpdateTaggedScionShip(Mission.m_SnipeScion3);
    elseif (check4) then
        -- Replace the object.
        Mission.m_SnipeScion4 = ReplaceObject(Mission.m_SnipeScion4, "fvsentx", Mission.m_HostTeam);

        -- Update it accordingly.
        UpdateTaggedScionShip(Mission.m_SnipeScion4);
    elseif (check5) then
        -- Replace the object.
        Mission.m_SnipeScion5 = ReplaceObject(Mission.m_SnipeScion5, "fvsentx", Mission.m_HostTeam);

        -- Update it accordingly.
        UpdateTaggedScionShip(Mission.m_SnipeScion5);
    end

    -- This part needs to check when a ship has been sniped so we can move on.
    if (Mission.m_ShipSniped) then
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[47] = function()
    -- Braddock: Nice shot Cooke
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0431a.wav");

    AddObjectiveOverride("isdf0412.otf", "GREEN", 10, true);
    AddObjective("isdf0413.otf", "WHITE");

    -- Rebuild Manson and Green Squad
    Mission.m_Manson = BuildObject("ivtank4", Mission.m_AlliedTeam, "friend1");
    Mission.m_Blue1 = BuildObject("ivtank4", Mission.m_AlliedTeam, "friend2");
    Mission.m_Blue2 = BuildObject("ivtank4", Mission.m_AlliedTeam, "friend3");
    Mission.m_Friend1 = BuildObject("ivtank4", 15, "friend4");
    Mission.m_Friend2 = BuildObject("ivtank4", 15, "friend5");

    -- Make each friend invincible.
    SetMaxHealth(Mission.m_Manson, 0);
    SetMaxHealth(Mission.m_Blue1, 0);
    SetMaxHealth(Mission.m_Blue2, 0);
    SetMaxHealth(Mission.m_Friend1, 0);
    SetMaxHealth(Mission.m_Friend2, 0);

    -- Move them to the bunker.
    Goto(Mission.m_Manson, "bunk_nav_spawn", 1);
    Goto(Mission.m_Blue1, "bunk_nav_spawn", 1);
    Goto(Mission.m_Blue2, "bunk_nav_spawn", 1);
    Goto(Mission.m_Friend1, "bunk_nav_spawn", 1);
    Goto(Mission.m_Friend2, "bunk_nav_spawn", 1);

    -- Remove their avoidance.
    SetAvoidType(Mission.m_Manson, 0);
    SetAvoidType(Mission.m_Blue1, 0);
    SetAvoidType(Mission.m_Blue2, 0);
    SetAvoidType(Mission.m_Friend1, 0);
    SetAvoidType(Mission.m_Friend2, 0);

    -- Add names to each unit.
    SetObjectiveName(Mission.m_Manson, "Maj. Manson");
    SetObjectiveName(Mission.m_Blue1, "Sgt. Zdarko");
    SetObjectiveName(Mission.m_Blue2, "Sgt. Masiker");
    SetObjectiveName(Mission.m_Friend1, "Lt. Brambley");
    SetObjectiveName(Mission.m_Friend2, "Lt. Smith");

    -- Make them fire on it again.
    SetPerceivedTeam(Mission.m_FieldBunker, Mission.m_HostTeam);

    -- Delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(20);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[48] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Scions are forced to retreat.
        if (IsAround(Mission.m_SnipeScion1)) then
            Retreat(Mission.m_SnipeScion1, "cattle_spot");
        end

        if (IsAround(Mission.m_SnipeScion2)) then
            Retreat(Mission.m_SnipeScion2, "cattle_spot");
        end

        if (IsAround(Mission.m_SnipeScion3)) then
            Retreat(Mission.m_SnipeScion3, "cattle_spot");
        end

        if (IsAround(Mission.m_SnipeScion4)) then
            Retreat(Mission.m_SnipeScion4, "cattle_spot");
        end

        if (IsAround(Mission.m_SnipeScion5)) then
            Retreat(Mission.m_SnipeScion5, "cattle_spot");
        end

        -- Delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(8);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[49] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Manson: They're moving General...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0435.wav");

        -- Scions are forced to retreat...again.
        if (IsAround(Mission.m_SnipeScion1)) then
            Retreat(Mission.m_SnipeScion1, "epath1");
        end

        if (IsAround(Mission.m_SnipeScion2)) then
            Retreat(Mission.m_SnipeScion2, "epath2");
        end

        if (IsAround(Mission.m_SnipeScion3)) then
            Retreat(Mission.m_SnipeScion3, "epath3");
        end

        if (IsAround(Mission.m_SnipeScion4)) then
            Retreat(Mission.m_SnipeScion4, "epath4");
        end

        if (IsAround(Mission.m_SnipeScion5)) then
            Retreat(Mission.m_SnipeScion5, "epath1");
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[50] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Braddock: Stay with them!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0436.wav");

        -- Add Objectives.
        AddObjectiveOverride("isdf0414.otf", "WHITE", 10, true);

        -- Send Manson and Green Squad after them.
        Goto(Mission.m_Manson, "epath1");
        Follow(Mission.m_Blue1, Mission.m_Manson, 1);
        Follow(Mission.m_Blue2, Mission.m_Blue1, 1);

        Goto(Mission.m_Friend1, "epath1");
        Follow(Mission.m_Friend2, Mission.m_Friend1, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[51] = function()
    -- Play the cliff crumble animation when we are near it.
    if (not Mission.m_CliffCrumble) then
        if (IsPlayerWithinDistance("cliff_point", 30, _Cooperative.m_TotalPlayerCount)) then
            -- Set the cliff to fall.
            SetAnimation(Mission.m_Cliff, "crumble", 1);

            -- Added sound like in ISDF01.
            StartSoundEffect("pecrack.wav", Mission.m_Cliff);

            -- Tiny delay.
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1.25);

            -- So we don't loop.
            Mission.m_CliffCrumble = true;
        end
    end

    -- Add a beefier impact sound to the cliff when it crumbles.
    if (Mission.m_CliffCrumble and not Mission.m_CliffCrumbleImpact) then
       if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
            -- Added extra sound to make the impact more beefy.
            StartSoundEffect("xcollapse.wav", Mission.m_Cliff);

            -- So we don't loop.
            Mission.m_CliffCrumbleImpact = true;
       end
    end

    -- This triggers the final cutscene.
    local check1 = GetDistance(Mission.m_SnipeScion1, "show_time_point") < 30;
    local check2 = GetDistance(Mission.m_SnipeScion2, "show_time_point") < 30;
    local check3 = GetDistance(Mission.m_SnipeScion3, "show_time_point") < 30;
    local check4 = GetDistance(Mission.m_SnipeScion4, "show_time_point") < 30;
    local check5 = GetDistance(Mission.m_SnipeScion5, "show_time_point") < 30;

    if (check1 or check2 or check3 or check4 or check5) then
        -- When the enemy reaches the end. Start a timer so we don't wait on the player.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(60);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[52] = function()
    if (IsPlayerWithinDistance("show_time_point", 120, _Cooperative.m_TotalPlayerCount) or Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Manson: They're leaving General.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0437.wav");

        -- Start the Dropship animation.
        SetAnimation(Mission.m_ScionDropship, "takeoff", 1);

        -- Start the camera if we are not in coop mode.
        if (not Mission.m_IsCooperativeMode) then
            -- Prepare Camera for Cutscene
            CameraReady();

            -- Remove all ships.
            RemoveObject(Mission.m_SnipeScion1);
            RemoveObject(Mission.m_SnipeScion2);
            RemoveObject(Mission.m_SnipeScion3);
            RemoveObject(Mission.m_SnipeScion4);
            RemoveObject(Mission.m_SnipeScion5);
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[53] = function()
    -- Show the Scion Dropship taking off.
    if (not Mission.m_IsCooperativeMode) then
        CameraPath("camera1_point", 180, 0, Mission.m_ScionDropship);
    end

    -- Final Braddock Dialog
    if (not Mission.m_FinalDialogPlayed) then
        if (IsAudioMessageDone(Mission.m_Audioclip)) then
            -- Objectives.
            AddObjectiveOverride("isdf0414.otf", "GREEN", 10, true);

            -- I've got it Major.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0438.wav");

            -- So we don't loop.
            Mission.m_FinalDialogPlayed = true;
        end
    end

    -- Mission is a success.
    if (not Mission.m_SucceedMission) then
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(7);
        else
            SucceedMission(GetTime() + 7, "isdf04w1.txt");
        end

        -- So we don't loop.
        Mission.m_SucceedMission = true;
    end
end

function UpdateTaggedScionShip(h)
    -- Give it a pilot.
    AddPilotByHandle(h);

    -- Make sure this unit isn't shot by the enemy.
    SetPerceivedTeam(Mission.m_SnipeScion5, Mission.m_EnemyTeam);

    -- Remove it's avoidance.
    SetAvoidType(h, 0);

    -- Hold it in place.
    Stop(h, 1);

    -- Highlight it
    SetObjectiveOn(h);

    -- Name it "Tagged"
    SetObjectiveName(h, "Tagged");

    -- If this is the first sniped ship, keep tracking it.
    if (not Mission.m_ShipSniped) then
        -- First ship that is sniped needs to be tracked.
        Mission.m_SnipedShip = h;
        
        -- Don't do this again.
        Mission.m_ShipSniped = true;
    end
end

function TugBrain()
    if (not Mission.m_TugPickup) then
        -- Set the Tugs to pick up each relic.
        SetAvoidType(Mission.m_Tug1, 0);
        SetAvoidType(Mission.m_Tug2, 0);

        Pickup(Mission.m_Tug1, Mission.m_Relic1);
        Pickup(Mission.m_Tug2, Mission.m_Relic2);

        -- So we don't loop.
        Mission.m_TugPickup = true;
    end

    -- Check to see if each tug has it's cargo. If it does, move it to the dropship.
    if (not Mission.m_Tug1Move and HasCargo(Mission.m_Tug1)) then
        -- Move the tug to the dropship.
        Goto(Mission.m_Tug1, "tug_path1");

        -- So we don't loop.
        Mission.m_Tug1Move = true;
    end

    if (not Mission.m_Tug2Move and HasCargo(Mission.m_Tug2)) then
        -- Move the tug to the dropship.
        Goto(Mission.m_Tug2, "tug_path2");

        -- So we don't loop.
        Mission.m_Tug2Move = true;
    end

    -- When each tug is on the dropship, stop them.
    if (not Mission.m_Tug1Board and Mission.m_Tug1Move and GetDistance(Mission.m_Tug1, "load_point1") < 20) then
        -- Stop!
        Stop(Mission.m_Tug1);

        -- So we don't loop.
        Mission.m_Tug1Board = true;
    end

    if (not Mission.m_Tug2Board and Mission.m_Tug2Move and GetDistance(Mission.m_Tug2, "load_point2") < 20) then
        -- Stop!
        Stop(Mission.m_Tug2);

        -- So we don't loop.
        Mission.m_Tug2Board = true;
    end

    -- Run a check to make sure the player is not near a tug.
    if (not Mission.m_CloseTugDropshipDoors and Mission.m_Tug1Board and Mission.m_Tug2Board and Mission.m_TugCheckTime < Mission.m_MissionTime) then
        if (IsPlayerWithinDistance(Mission.m_Tug1, 40, _Cooperative.m_TotalPlayerCount)) then
            if (IsAudioMessageDone(Mission.m_Audioclip)) then 
                -- Pilot: "Please clear the dropship".
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0444.wav");

                -- Wait 10 seconds before running again.
                Mission.m_TugCheckTime = Mission.m_MissionTime + SecondsToTurns(10);
            end
        else
            -- Set the dropship to take off.
            SetAnimation(Mission.m_TugDropship, "takeoff", 1);

            -- Sound effects.
            StartSoundEffect("dropleav.wav", Mission.m_TugDropship);

            -- Wait 3 seconds before running again.
            Mission.m_TugCheckTime = Mission.m_MissionTime + SecondsToTurns(3);

            -- So we don't loop.
            Mission.m_CloseTugDropshipDoors = true;
        end
    end

    -- If we've closed the doors and the time has run out.
    if (not Mission.m_TugDropshipTakeoff and Mission.m_CloseTugDropshipDoors and Mission.m_TugCheckTime < Mission.m_MissionTime) then
        -- Sound effects.
        StartSoundEffect("dropdoor.wav", Mission.m_TugDropship);

        -- Emitters..
        StartEmitter(Mission.m_TugDropship, 1);
        StartEmitter(Mission.m_TugDropship, 2);

        -- Remove the tugs.
        RemoveObject(Mission.m_Tug1);
        RemoveObject(Mission.m_Tug2);

        -- Remove the relics.
        RemoveObject(Mission.m_Relic1);
        RemoveObject(Mission.m_Relic2);

        -- Wait 10 seconds before running again.
        Mission.m_TugCheckTime = Mission.m_MissionTime + SecondsToTurns(10);

        -- So we don't loop.
        Mission.m_TugDropshipTakeoff = true;
    end

    -- Remove the dropship and mark this part as done.
    if (not Mission.m_TugBrainDone and Mission.m_TugDropshipTakeoff and Mission.m_TugCheckTime < Mission.m_MissionTime) then
        -- Remove the dropship.
        RemoveObject(Mission.m_TugDropship);

        -- We're finished with the brain.
        Mission.m_TugBrainDone = true;
    end
end

function MansonBrain()
    -- So we can safely remove Manson when he's away from the player.
    local check1 = GetDistance(Mission.m_Manson, "kill_unit") < 100;
    local check2 = GetDistance(Mission.m_Blue1, "kill_unit") < 100;
    local check3 = GetDistance(Mission.m_Blue2, "kill_unit") < 100;

    -- Safely remove Blue Squad.
    if (check1 and check2 and check3) then
        RemoveObject(Mission.m_Manson);
        RemoveObject(Mission.m_Blue1);
        RemoveObject(Mission.m_Blue2);
    end
end

function ShabayevBrain()
    if (GetDistance(Mission.m_Shabayev, "kill_unit") < 100) then
        RemoveObject(Mission.m_Shabayev);
    end
end

function HandleFailureConditions()
    -- This is Shabayev shouting if we take too long.
    if (Mission.m_ScavengerReminderActive) then
        if (Mission.m_ScavengerReminderTime < Mission.m_MissionTime) then
            -- Shab: Hurry up.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0409.wav");

            -- Reshow the objectives.
            AddObjectiveOverride("isdf0402.otf", "WHITE", 10, true);

            -- Small delay to remind the player to hurry.
            Mission.m_ScavengerReminderTime = Mission.m_MissionTime + SecondsToTurns(45);
        end
    end

    -- If the player takes too long to reach the bunker.
    if (Mission.m_BunkerWarningActive) then
        if (Mission.m_RelayBunkerWarningTime < Mission.m_MissionTime) then
            if (Mission.m_RelayBunkerWarningCount == 0) then
                -- Braddock: Cooke, get moving!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0425.wav");

                -- Reshow the objectives.
                AddObjectiveOverride("isdf0410.otf", "WHITE", 10, true);

                -- Increase the warning count.
                Mission.m_RelayBunkerWarningCount = Mission.m_RelayBunkerWarningCount + 1;

                -- Set up a warning.
                Mission.m_RelayBunkerWarningTime = Mission.m_MissionTime + SecondsToTurns(60);
            else
                -- Braddock: Cooke, you are relieved!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0426.wav");
                
                -- Fail the mission.
                Mission.m_MissionOver = true;

                -- Game over.
                if (Mission.m_IsCooperativeMode) then
                    NoteGameoverWithCustomMessage("You failed to follow General Braddock's orders!");
                    DoGameover(10);
                else
                    FailMission(GetTime() + 10, "isdf04l3.txt");
                end
            end
        end 
    end

    -- Scavenger died, mission failed.
    if (Mission.m_ScavengerConditionActive and not IsAround(Mission.m_Scavenger) and not Mission.m_MissionOver) then
        -- Objectives.
        AddObjectiveOverride("isdf0405.otf", "RED", 10, true);

        -- Mission failed.
        Mission.m_MissionOver = true;

        -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("You lost the Scavenger!");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf04l1.txt");
        end
    end

    -- Recycler is dead, mission failed.
    if (not IsAround(Mission.m_Recycler) and not Mission.m_MissionOver) then
        -- Objectives.
        AddObjectiveOverride("isdf0408.otf", "RED", 10, true);

        -- Mission failed.
        Mission.m_MissionOver = true;

        -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("You lost the Recycler!");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf04l2.txt");
        end
    end
end
