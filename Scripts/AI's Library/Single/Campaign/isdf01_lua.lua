--[[
    BZCC ISDF01 Lua Mission Script
    Written by AI_Unit
    Version 1.0 09-12-2023
--]]

-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))();

-- Required Globals.
require("_GlobalVariables");

-- Required helper functions.
require("_HelperFunctions");

-- Cooperative.
local _Cooperative = require("_Cooperative");

-- Subtitles.
local _Subtitles = require('_Subtitles');

-- Game TPS.
local m_GameTPS = GetTPS();

-- Mission Name
local m_MissionName = "ISDF01: This is Not a Drill";

-- Mission important variables.
local Mission =
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "isuser_mx",
    -- Specific to mission.
    m_PlayerShipODF = "ivplysct_x",

    m_Holders = {},
    m_Condor1 = nil,
    m_Condor2 = nil,
    m_Condor3 = nil,
    m_Shabayev = nil,
    m_Simms = nil,
    m_Red1 = nil,
    m_Red2 = nil,
    m_Red3 = nil,
    m_LookThing = nil,
    m_ScionTurret = nil,
    m_Cliff = nil,
    m_CommBuilding = nil,
    m_DeadTank = nil,
    m_Manson = nil,
    m_Movie1 = nil,
    m_Movie2 = nil,
    m_Scion1 = nil,
    m_Scion2 = nil,
    m_Scion3 = nil,
    m_MagicCrate = nil,
    m_Truck = nil,
    m_StorageBay = nil,
    m_LostPlayer = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionStartDone = false,
    m_MissionOver = false,
    m_PlayCliffCrumble = false,
    m_CliffCrumble = false,
    m_CliffCrumbleImpact = false,
    m_WaitForSimms = false,
    m_TurretShotShabayev = false,
    m_CommWarningActive = false,
    m_PlayerInCommBuilding = false,
    m_CinematicFirstFrameDone = false,
    m_CinematicReframeCamera = false,
    m_ReturnToShipWarningActive = false,
    m_LeaveShipWarningActive = false,
    m_GiveHandDialogPlayed = false,
    m_ReturnToBaseDialogPlayed = false,
    m_Red1HelpWarningActive = false,
    m_TruckHelpWarningActive = false,
    m_RedSquadAroundWarningActive = false,
    m_PlayerLostCheckActive = false,
    m_PlayerLost = false,
    m_PlayerLostFirstTime = false,
    m_PlayerLostFirstDialog = false,

    -- Shabayev's Brain Variables.
    m_ShabHoldForPlayer = false,
    m_ShabLookLogicEnabled = false,
    m_ShabLookAtPlayer = false,
    m_ShabLookSwitchTime = 0,
    m_ShabCommReminderCount = 0,
    m_ShabReturnToShipWarningCount = 0,
    m_ShabStorageBayCheckActive = false,
    m_ShabStorageBayCheckDialogPlayed = false,
    m_ShabMoveToStorageBay = false,
    m_ShabMoveToStorageBayDelay = 0,
    m_ShabMoveToBaseCentre = false,
    m_ShabLeftBase = false,

    -- Simms Brain Variables.
    m_SimmsHold = false,
    m_SimmsLookAtRed1 = false,
    m_SimmsLookAtRed1Time = 0,
    m_SimmsLookAtCommBuilding = false,
    m_SimmsLookAtCommBuildingTime = 0,
    m_SimmsLookAtTurret = false,
    m_SimmsLookAtPlayer = false,
    m_SimmsAtBluffFirst = false,

    -- Red Squad Brain Variables.
    m_RedSquadStart = false,
    m_RedSquadStartWait = 0,
    m_Red1Stop = false,
    m_Red2Stop = false,
    m_Red3Stop = false,
    m_RedSquadWaiting = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_Condor1RemoveTime = 0,
    m_Condor2RemoveTime = 0,
    m_Condor3RemoveTime = 0,
    m_ClearShipWarningTime = 0,
    m_CommWarningTime = 0,
    m_LeaveShipWarningTime = 0,
    m_ReturnToShipWarningTime = 0,
    m_Red1HelpWarningTime = 0,
    m_Red1HelpWarningCount = 0,
    m_TruckHelpWarningTime = 0,
    m_CinematicAudioCount = 1,
    m_PlayerLostTime = 0,
    m_PlayerLostWarningCount = 0,

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

    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();
end

function Save()
    return _Cooperative.Save(), Mission;
end

function Load(CoopData, MissionData)
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();

    -- Load Coop.
    _Cooperative.Load(CoopData);

    -- Load mission data.
    Mission = MissionData;
end

function AddObject(h)
    local teamNum = GetTeamNum(h);

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);

        -- For this mission, we don't have intel on enemy units, so set all of their names to "Unknown".
        SetObjectiveName(h, "Unknown");
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        -- Always max our player units.
        SetSkill(h, 3);
    end
end

function Start()
    -- Set difficulty based on whether it's coop or not.
    if (Mission.m_IsCooperativeMode) then
        Mission.m_MissionDifficulty = GetVarItemInt("network.session.ivar102") + 1;
    else
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1;
    end

    -- Call generic start logic in coop.
    _Cooperative.Start(m_MissionName, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, Mission.m_IsCooperativeMode);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;
end

function Update()
    -- This checks to see if the game is ready.
    if (Mission.m_IsCooperativeMode) then
        _Cooperative.Update(m_GameTPS);
    end

    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Start mission logic.
    if (Mission.m_MissionOver == false) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            if (not Mission.m_PlayerLost) then
                Functions[Mission.m_MissionState]();
            end

            -- Run the brains of each character.
            ShabayevBrain();
            DropshipBrain();
            SimmsBrain();
            RedSquadBrain();

            -- Check for any failure conditions.
            HandleFailureConditions();

            -- Play the cliff crumble animation when we are near it.
            if (Mission.m_PlayCliffCrumble) then
                if (not Mission.m_CliffCrumble) then
                    -- Set the cliff to fall.
                    SetAnimation(Mission.m_Cliff, "crumble", 1);

                    -- Added sound like in ISDF01.
                    StartSoundEffect("pecrack.wav", Mission.m_Cliff);

                    -- Tiny delay.
                    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1.25);

                    -- So we don't loop.
                    Mission.m_CliffCrumble = true;
                end

                -- Add a beefier impact sound to the cliff when it crumbles.
                if (Mission.m_CliffCrumble and not Mission.m_CliffCrumbleImpact) then
                    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                        -- Added extra sound to make the impact more beefy.
                        StartSoundEffect("xcollapse.wav", Mission.m_Cliff);

                        -- So we don't loop.
                        Mission.m_CliffCrumbleImpact = true;

                        -- Break out of the main loop
                        Mission.m_PlayCliffCrumble = false;
                    end
                end
            end
        end
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, false, 0);
end

function DeletePlayer(id)
    return _Cooperative.DeletePlayer(id);
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
    -- Unique to this mission. This will help us determine that the turret has shot Shabayev for the first time.
    if (not Mission.m_TurretShotShabayev and ShooterHandle == Mission.m_ScionTurret and VictimHandle == Mission.m_Shabayev) then
        -- So we don't loop, but also helps for the shooting part of the mission.
        Mission.m_TurretShotShabayev = true;
    end

    if (IsPlayer(ShooterHandle) and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (VictimHandle == Mission.m_Shabayev) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("ff01.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        elseif (VictimHandle == Mission.m_Simms) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("ff02.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Grab all of our pre-placed handles.
    Mission.m_Shabayev = GetHandle("shabayev");
    Mission.m_Simms = GetHandle("wingman");
    Mission.m_Condor1 = GetHandle("condor1");
    Mission.m_Condor2 = GetHandle("condor2");
    Mission.m_Condor3 = GetHandle("condor3");
    Mission.m_LookThing = GetHandle("look_thing");
    Mission.m_ScionTurret = GetHandle("turret");
    Mission.m_Cliff = GetHandle("crumble_cliff");
    Mission.m_CommBuilding = GetHandle("comm_building");
    Mission.m_DeadTank = GetHandle("dead_tank");
    Mission.m_Manson = GetHandle("manson");
    Mission.m_MagicCrate = GetHandle("magic_crate");
    Mission.m_StorageBay = GetHandle("storage_bay");

    -- This removes the crates and replaces them with health and ammo as per the original.
    local crate1 = GetHandle("crate1");
    local crate2 = GetHandle("crate2");
    local crate3 = GetHandle("crate3");
    local crate4 = GetHandle("crate4");
    local crate5 = GetHandle("crate5");
    local crate6 = GetHandle("crate6");
    local last_crate = GetHandle("last_crate");

    -- Build the power-ups.
    BuildObject("apammo", 0, crate1);
    BuildObject("aprepa", 0, crate2);
    BuildObject("apammo", 0, crate3);
    BuildObject("aprepa", 0, crate4);
    BuildObject("apammo", 0, crate5);
    BuildObject("aprepa", 0, crate6);
    BuildObject("apammo", 0, last_crate);

    -- Remove the crates.
    RemoveObject(crate1);
    RemoveObject(crate2);
    RemoveObject(crate3);
    RemoveObject(crate4);
    RemoveObject(crate5);
    RemoveObject(crate6);
    RemoveObject(last_crate);

    -- This is for Red Squad.
    SetTeamColor(Mission.m_AlliedTeam, 255, 50, 50);

    -- Start our Earthquake.
    StartEarthQuake(1); -- Reset to 5 when advised by devs. 5 is way too loud and not at all friendly to the ears.

    -- If there's only one player, remove the third dropship.
    if (Mission.m_TotalPlayerCount == 1) then
        RemoveObject(Mission.m_Condor3);
    end

    -- Do the fade in if we are not in coop mode.
    if (not Mission.m_IsCooperativeMode) then
        SetColorFade(1, 0.5, Make_RGB(0, 0, 0, 255));
    end

    -- Create our holding objects.
    local holder1 = BuildObject("stayput", 0, Mission.m_Shabayev);
    local holder2 = BuildObject("stayput", 0, Mission.m_Simms);

    -- Insert the holders into a table.
    Mission.m_Holders[#Mission.m_Holders + 1] = holder1;
    Mission.m_Holders[#Mission.m_Holders + 1] = holder2;

    -- Do the same for each player.
    for i = 1, _Cooperative.GetTotalPlayers() do
        -- Grab the player...
        local p = GetPlayerHandle(i);

        -- Build a holder on them...
        local holder = BuildObject("stayput", 0, p);

        -- Push holder to the table.
        Mission.m_Holders[#Mission.m_Holders + 1] = holder;
    end

    -- Mask the emitters on all dropships.
    MaskEmitter(Mission.m_Condor1, 0);
    MaskEmitter(Mission.m_Condor2, 0);

    if (IsAround(Mission.m_Condor3)) then
        MaskEmitter(Mission.m_Condor3, 0);
    end

    -- Open the dropship doors.
    SetAnimation(Mission.m_Condor2, "deploy", 1);

    -- Set the relevant team numbers.
    SetTeamNum(Mission.m_Shabayev, 1);
    SetTeamNum(Mission.m_Simms, 1);

    -- Have them look forward.
    LookAt(Mission.m_Shabayev, Mission.m_LookThing);
    LookAt(Mission.m_Simms, Mission.m_LookThing);

    -- Make sure our names are correct.
    SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
    SetObjectiveName(Mission.m_Simms, "Lt. Simms");

    -- Clean up any player spawns that haven't been taken by the player.
    _Cooperative.CleanSpawns();

    -- Tiny delay before the next part.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Show Objectives.
        AddObjective("isdf0101a.otf", "WHITE");

        -- Pilot: "Crossing 12 hundred."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0163a.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Pilot "Roget that"...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0164b.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Prepares the update for the quake.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(12);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Small delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.4);

        -- Update the EarthQuake to simulate landing.
        UpdateEarthQuake(30);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- Stop the EarthQuake.
    StopEarthQuake();

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[6] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Pilot: "We are on the ground.."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0164c.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Highlight Shabayev.
        SetObjectiveOn(Mission.m_Shabayev);

        -- Shabayev: "Okay, follow me off the ship".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0165.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Small delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(8);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- This builds Red Squad.
        Mission.m_Red1 = BuildObject("p1scout", Mission.m_AlliedTeam, "a_spawn");
        Mission.m_Red2 = BuildObject("p1scout", Mission.m_AlliedTeam, "b_spawn");
        Mission.m_Red3 = BuildObject("p1scout", Mission.m_AlliedTeam, "c_spawn");

        -- So we fail the mission if the player kills Red Squad.
        Mission.m_RedSquadAroundWarningActive = true;

        -- We'll have Red Squad assume formation.
        Follow(Mission.m_Red2, Mission.m_Red1);
        Follow(Mission.m_Red3, Mission.m_Red2);

        -- Some AI stuff.
        SetAvoidType(Mission.m_Red1, 0);
        SetAvoidType(Mission.m_Red2, 0);
        SetAvoidType(Mission.m_Red3, 0);

        -- Open the dropship doors.
        SetAnimation(Mission.m_Condor1, "deploy", 1);

        -- For Coop.
        if (IsAround(Mission.m_Condor3)) then
            SetAnimation(Mission.m_Condor3, "deploy", 1);
        end

        -- Small delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Starts the sound effect for the doors.
        StartSoundEffect("dropdoor.wav");

        -- Remove the holders from Simms and Shabayev
        RemoveObject(Mission.m_Holders[1]);
        RemoveObject(Mission.m_Holders[2]);

        -- Tiny delay again.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[10] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Removes the object that we set our team to stare at when we are in the dropship.
        RemoveObject(Mission.m_LookThing);

        -- This cleans up some stuff and gets the units off of the ship.
        SetPerceivedTeam(Mission.m_ScionTurret, 1);

        -- Some AI stuff.
        SetAvoidType(Mission.m_Shabayev, 0);
        SetAvoidType(Mission.m_Simms, 0);

        -- Have them move off of the ship.
        Goto(Mission.m_Shabayev, "shab_firststoppoint", 1);
        Goto(Mission.m_Simms, "wingoffdrop_path", 1);

        -- Tiny delay again.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0101.otf", "WHITE", 10, true);

        -- Remove all holders from the players.
        for i = 1, #Mission.m_Holders do
            RemoveObject(Mission.m_Holders[i]);
        end

        -- This will set a timer to tell the player to leave the ship.
        Mission.m_ClearShipWarningTime = Mission.m_MissionTime + SecondsToTurns(15);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    -- This part will check that all players have safely exited the dropships.
    if (Mission.m_ShabHoldForPlayer) then
        -- This will remind the player to leave the ship every 30 seconds.
        if (Mission.m_ClearShipWarningTime < Mission.m_MissionTime) then
            -- Shab: "Clear the ship!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0166.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- Resets the warning timer.
            Mission.m_ClearShipWarningTime = Mission.m_MissionTime + SecondsToTurns(30);
        end

        -- Make sure every player is in formation.
        for i = 1, _Cooperative.GetTotalPlayers() do
            local p = GetPlayerHandle(i);

            if (GetDistance(p, Mission.m_Shabayev) > 30) then
                -- Do not proceed if a player is too far away.
                return;
            end
        end

        -- This makes Red Squad wait for 5 seconds before leaving.
        Mission.m_RedSquadStartWait = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    -- This will make the other dropships leave.
    SetAnimation(Mission.m_Condor1, "takeoff", 1);
    StartSoundEffect("dropleav.wav", Mission.m_Condor1);

    -- Timer for removing the ships.
    Mission.m_Condor1RemoveTime = Mission.m_MissionTime + SecondsToTurns(15);

    -- Show the emitters for takeoff.
    StartEmitter(Mission.m_Condor1, 1);
    StartEmitter(Mission.m_Condor1, 2);

    -- For coop players.
    if (IsAround(Mission.m_Condor3)) then
        SetAnimation(Mission.m_Condor3, "takeoff", 1);
        StartSoundEffect("dropleav.wav", Mission.m_Condor3);

        Mission.m_Condor3RemoveTime = Mission.m_MissionTime + SecondsToTurns(15);

        -- Show the emitters for takeoff.
        StartEmitter(Mission.m_Condor3, 1);
        StartEmitter(Mission.m_Condor3, 2);
    end

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[14] = function()
    -- This is Shabayev's first message.
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0101.wav");

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(17.5);

    -- Show Objectives.
    AddObjectiveOverride("isdf0101.otf", "GREEN", 10, true);

    -- This does a delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(20);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[15] = function()
    -- This makes sure all squads are ready to move.
    if (Mission.m_RedSquadStart and Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0102.otf", "WHITE", 10, true);

        -- So we don't look at stuff.
        Mission.m_ShabLookLogicEnabled = false;

        -- Simms will follow.
        Follow(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- Shab: "Let's move out".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0102.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Move Shabayev.
        Goto(Mission.m_Shabayev, "shab_path1", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[16] = function()
    -- Check if Shabayev is near the end of her path for the next part.
    if (GetDistance(Mission.m_Shabayev, "shab_point1") < 30) then
        -- Have Shabayev look at Red 1.
        LookAt(Mission.m_Shabayev, Mission.m_Red1, 1);

        -- Shab: "Hold up here men..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0162.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[17] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Red 1: "Just waiting for your slow ass..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0139.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Highlight Red 1.
        SetObjectiveName(Mission.m_Red1, "Red 1");

        -- Highlight her.
        SetObjectiveOn(Mission.m_Red1);

        -- Do this again just incase each unit isn't looking at their intended target. That way, they won't get stopped when they move on.
        Mission.m_RedSquadWaiting = true;

        -- Have Simms look at Red 1.
        LookAt(Mission.m_Simms, Mission.m_Red1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[18] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- This sends Red Squad on their way and has Shabayev comment about taking the high road.
        Goto(Mission.m_Red1, "squad1_point2", 1);

        -- Have the others follow.
        Follow(Mission.m_Red2, Mission.m_Red1, 1);
        Follow(Mission.m_Red3, Mission.m_Red2, 1);

        -- Remove Red 1's highlight.
        SetObjectiveOff(Mission.m_Red1);

        -- Have Shabayev look at Simms.
        LookAt(Mission.m_Shabayev, Mission.m_Simms, 1);

        -- Re-enable the brain.
        Mission.m_ShabLookAtPlayer = false;
        Mission.m_ShabLookSwitchTime = Mission.m_MissionTime + SecondsToTurns(3);
        Mission.m_ShabLookLogicEnabled = true;

        -- Shab: "We'll take the high road..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0103.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Do the player lost check here.
        Mission.m_PlayerLostCheckActive = true;

        -- Do a small delay before we press on to the next portion.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[19] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            -- Remove the look brain again.
            Mission.m_ShabLookLogicEnabled = false;

            -- Remove the player lost check.
            Mission.m_PlayerLostCheckActive = false;

            -- Have Shabayev move out.
            Goto(Mission.m_Shabayev, "shab_path2");

            -- Have Simms follow.
            Follow(Mission.m_Simms, Mission.m_Shabayev, 1);

            -- Show our Objectives.
            AddObjectiveOverride("isdf0102.otf", "WHITE", 10, true);

            -- Shab: "Okay, let's move out"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0104.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[20] = function()
    -- This is checking to see if Shabayev is ear the cliff.
    if (GetDistance(Mission.m_Shabayev, "cliff_point") < 20) then
        -- Do a small delay for the cliff to collapse.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[21] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Start the crumble sequence.
        Mission.m_PlayCliffCrumble = true;

        -- Shab: "Woah! Watch out for the unstable terrain."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0105.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Move Simms to a safe location.
        Goto(Mission.m_Simms, "out_of_way", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[22] = function()
    -- Check to see if Simms is ready before we move on.
    if (GetDistance(Mission.m_Simms, "out_of_way") < 30 and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Just a quick check to have Simms apologise for getting lost.
        if (Mission.m_WaitForSimms) then
            -- Simms: "sorry commander..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0160.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);
        end

        -- Have both Shab and Simms look at each other.
        LookAt(Mission.m_Shabayev, Mission.m_Simms, 1);
        LookAt(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- Do the player lost check here.
        Mission.m_PlayerLostCheckActive = true;

        -- Do a tiny delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    elseif (not Mission.m_WaitForSimms and GetDistance(Mission.m_Shabayev, Mission.m_Simms) > 150) then
        -- This is Shab telling Simms to hurry.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0159.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- She'll look at him while we wait.
        LookAt(Mission.m_Shabayev, Mission.m_Simms, 1);

        -- So we don't loop.
        Mission.m_WaitForSimms = true;
    end
end

Functions[23] = function()
    -- Check incase any audio is played from Simms getting lost.
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "Simms, take the pass to the east".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0106.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- She'll look at him while we wait.
        LookAt(Mission.m_Shabayev, Mission.m_Simms, 1);

        -- Remove the player lost check.
        Mission.m_PlayerLostCheckActive = false;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[24] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Send Simms off.
        Goto(Mission.m_Simms, "explore_path1", 1);

        -- Simms: Yes sir, heading out.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0112.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[25] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Have shabayev look at the main player.
        LookAt(Mission.m_Shabayev, GetPlayerHandle(1), 1);

        -- Shab: "Cooke, you're with me".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0161.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Add Objectives.
        AddObjectiveOverride("isdf0102.otf", "WHITE", 10, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[26] = function()
    -- Make Shabayev move.
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- To the next point.
        Goto(Mission.m_Shabayev, "jump_path2");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[27] = function()
    if (IsAlive(Mission.m_ScionTurret)) then
        -- This is Simms detecting the turret.
        if (GetDistance(Mission.m_Simms, Mission.m_ScionTurret) < 200) then
            -- Simms: "I'm picking up something strange..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0167.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Just to make sure that these units don't attack this turret on their own.
            SetIndependence(Mission.m_Shabayev, 0);
            SetIndependence(Mission.m_Simms, 0);

            -- Have the turret retreat.
            Retreat(Mission.m_ScionTurret, "turret_path", 1);

            -- Have Simms follow it.
            Follow(Mission.m_Simms, Mission.m_ScionTurret, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    else
        -- Advance the mission state...
        Mission.m_MissionState = 29;
    end
end

Functions[28] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "Stay on it Simms."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0168.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[29] = function()
    -- Once we are at the point of cutting off the turret, have Shabayev stop and do her thing.
    if (GetDistance(Mission.m_Shabayev, "shab_point3") < 30) then
        -- On the off chance that the turret is dead, we can skip the next part.
        if (IsAlive(Mission.m_ScionTurret)) then
            -- Have Shabayev look at the turret.
            LookAt(Mission.m_Shabayev, Mission.m_ScionTurret, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        else
            -- Have Shabayev look at the player.
            LookAt(Mission.m_Shabayev, GetPlayerHandle(1), 1);

            -- Do the player lost check here.
            Mission.m_PlayerLostCheckActive = true;

            -- Skip the next few steps about the turret.
            Mission.m_MissionState = 35;
        end
    end
end

Functions[30] = function()
    if (not IsAlive(Mission.m_ScionTurret)) then
        -- Skip the next few steps about the turret.
        Mission.m_MissionState = 33;
    else
        -- This checks if the turret is near the point of attacking.
        if (GetDistance(Mission.m_ScionTurret, "shab_point3") < 35) then
            -- Have the turret deploy to attack Shabayev.
            Attack(Mission.m_ScionTurret, Mission.m_Shabayev, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[31] = function()
    if (not IsAlive(Mission.m_ScionTurret)) then
        -- Skip the next few steps about the turret.
        Mission.m_MissionState = 33;
    else
        -- This checks if the turret is deployed so Simms can comment.
        if (IsDeployed(Mission.m_ScionTurret)) then
            -- Simms: "It's doing something..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0174.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[32] = function()
    if (not IsAlive(Mission.m_ScionTurret)) then
        -- Skip the next few steps about the turret.
        Mission.m_MissionState = 33;
    else
        if (Mission.m_TurretShotShabayev and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            -- Shab "Open fire!".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0169.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- Tell Shab and Simms to attack.
            Attack(Mission.m_Shabayev, Mission.m_ScionTurret, 1);
            Attack(Mission.m_Simms, Mission.m_ScionTurret, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[33] = function()
    -- Check if the turret has been killed.
    if (not IsAlive(Mission.m_ScionTurret)) then
        -- Simms: "What was that thing?"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0171.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Have him form up with Shabayev again.
        Follow(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[34] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "I don't know".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0172.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

        -- Do the player lost check here.
        Mission.m_PlayerLostCheckActive = true;

        -- Have Shab and Simms look at each other.
        LookAt(Mission.m_Simms, Mission.m_Shabayev, 1);
        LookAt(Mission.m_Shabayev, Mission.m_Simms, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[35] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "I'm detecting the base...".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0107.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

        -- So Simms doesn't stop
        Mission.m_SimmsAtBluffFirst = true;

        -- Remove the player lost check.
        Mission.m_PlayerLostCheckActive = false;

        -- Have Shabayev look at the Comm Bunker.
        LookAt(Mission.m_Shabayev, Mission.m_CommBuilding, 1);

        -- So that Simms looks at the comm bunker as well.
        Mission.m_SimmsLookAtCommBuildingTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- We can reset the AI for our friends.
        SetIndependence(Mission.m_Shabayev, 1);
        SetIndependence(Mission.m_Simms, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[36] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Have Simms look at Shabayev.
        LookAt(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- Have Shabayev look at the main player.
        LookAt(Mission.m_Shabayev, GetPlayerHandle(1), 1);

        -- Shab: "SkyEye, do you copy?"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0170.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[37] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Show objectives.
        AddObjectiveOverride("isdf0102.otf", "WHITE", 10, true);

        -- Have Simms follow Shabayev
        Follow(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- Move Shabayev to the next path.
        Goto(Mission.m_Shabayev, "tight_path2");

        -- Add a minor delay as per the original.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(10);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[38] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime and (GetDistance(Mission.m_Shabayev, "atbase_point") < 200 or IsPlayerWithinDistance("atbase_point", 200, _Cooperative.GetTotalPlayers()))) then
        -- Shab: "The outpost is coming into range..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0108.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[39] = function()
    if (GetDistance(Mission.m_Shabayev, "atbase_point") < 30) then
        -- Have Shabayev look at the main player.
        LookAt(Mission.m_Shabayev, GetPlayerHandle(1), 1);

        -- Do the player lost check here.
        Mission.m_PlayerLostCheckActive = true;

        -- Small delay again.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[40] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- This is Simms commenting on the destroyed APC.
        if (IsAround(Mission.m_DeadTank)) then
            -- Have Shabayev look at it.
            LookAt(Mission.m_Shabayev, Mission.m_DeadTank, 1);

            if (GetDistance(Mission.m_Simms, Mission.m_DeadTank) < 50) then
                -- Have Simms look at the dead tank.
                LookAt(Mission.m_Simms, Mission.m_DeadTank, 1);
            end

            -- Remove the player lost check.
            Mission.m_PlayerLostCheckActive = false;

            -- Have Simms make his comment.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0173.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);
        end

        -- Add a delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[41] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Show objectives.
        AddObjectiveOverride("isdf0102.otf", "WHITE", 10, true);
        AddObjective("isdf0103.otf", "WHITE");

        -- If Simms isn't following, make him.
        Follow(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- Move Shabayev to the base centre.
        Goto(Mission.m_Shabayev, "base_center", 1);

        -- Shab: "Okay, let's move inside".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0109.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[42] = function()
    if (GetDistance(Mission.m_Shabayev, "base_center") < 30) then
        -- This has Shabayev look at the main player again.
        LookAt(Mission.m_Shabayev, GetPlayerHandle(1), 1);

        -- This checks to see if Shabayev is sent to the base centre so we can do warning checks.
        Mission.m_ShabMoveToBaseCentre = true;

        -- Do the player lost check here.
        Mission.m_PlayerLostCheckActive = true;

        -- Simms: "For a scout outpost.."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0110.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[43] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Have Shab and Simms look at each other.
        LookAt(Mission.m_Simms, Mission.m_Shabayev, 1);
        LookAt(Mission.m_Shabayev, Mission.m_Simms, 1);

        -- Shab: "Hold the commentary, Simms".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0111.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[44] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Simms: "Yes sir, heading out".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0112.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Send Simms off to do his sweep.
        Goto(Mission.m_Simms, "combat1a");

        -- This'll make Simms a bit silly, but it's necessary.
        SetIndependence(Mission.m_Simms, 0);

        -- Minor delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[45] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Shab: "Cooke, I need you to search for the communication station..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0113.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(14.5);

        -- Activate the warning.
        Mission.m_CommWarningActive = true;
        Mission.m_CommWarningTime = Mission.m_MissionTime + SecondsToTurns(60);

        -- Have her look at the player.
        LookAt(Mission.m_Shabayev, GetPlayerHandle(1), 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[46] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Show objectives.
        AddObjectiveOverride("isdf0103.otf", "GREEN", 10, true);
        AddObjective("isdf0104.otf", "WHITE");

        -- Leave a note for the player if we are in coop mode.
        if (Mission.m_IsCooperativeMode) then
            AddObjective("NOTE: Use the 'T' key to locate the communication station in cooperative mode.", "YELLOW");
        end

        -- Send Shabayev off to patrol.
        Patrol(Mission.m_Shabayev, "around_path2");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[47] = function()
    -- Use a couple of checks to trigger this event if we are in cooperative mode.
    local check1 = Mission.m_IsCooperativeMode == false and IsInfo("pbcomm");
    local check2 = false;

    if (Mission.m_IsCooperativeMode) then
        -- Run a check against each player to see if one of them is targeting the comm station.
        for i = 1, _Cooperative.GetTotalPlayers() do
            if (GetUserTarget(i) == Mission.m_CommBuilding) then
                check2 = true;
            end
        end
    end

    -- TODO: IsInfo is not MP friendly, so need to find an alternative method for coop.
    if (check1 or check2) then
        -- Show objectives.
        AddObjectiveOverride("isdf0104.otf", "GREEN", 10, true);

        -- Stop the warning.
        Mission.m_CommWarningActive = false;

        -- Shab: "Good job Cooke."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0114.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Move Shabayev to the comm bunker.
        Goto(Mission.m_Shabayev, "comm_point", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[48] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (GetDistance(Mission.m_Shabayev, "comm_point") < 35) then
            -- This will activate the warning for hopping out.
            Mission.m_LeaveShipWarningActive = true;
            Mission.m_LeaveShipWarningTime = Mission.m_MissionTime + SecondsToTurns(30);

            for i = 1, _Cooperative.GetTotalPlayers() do
                local p = GetPlayerHandle(i);

                if (InBuilding(p)) then
                    Mission.m_PlayerInCommBuilding = true;
                end
            end

            -- Don't play this part if they are already in.
            if (not Mission.m_PlayerInCommBuilding) then
                -- Show Objectives.
                AddObjectiveOverride("isdf0105.otf", "WHITE", 10, true);

                -- Shab: "I'm getting a strange reading...".
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0116.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);
            end

            -- Have Shabayev look at the main player.
            LookAt(Mission.m_Shabayev, GetPlayerHandle(1), 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[49] = function()
    -- Run a check as to whether this should be active.
    for i = 1, _Cooperative.GetTotalPlayers() do
        local p = GetPlayerHandle(i);

        if (IsOdf(p, Mission.m_PlayerPilotODF)) then
            Mission.m_LeaveShipWarningActive = false;
        else
            Mission.m_LeaveShipWarningActive = true;
        end
    end

    if (IsPlayerWithinDistance(Mission.m_Manson, 4, _Cooperative.GetTotalPlayers())) then
        -- This is prepping the cinematic for non-coop mode.
        if (not Mission.m_IsCooperativeMode) then
            CameraReady();
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[50] = function()
    -- Start our movies if we are not in coop mode.
    if (not Mission.m_IsCooperativeMode and not Mission.m_CinematicFirstFrameDone) then
        -- Play the movie.
        PlayMovie("manson1");
    end

    if (Mission.m_CinematicAudioCount == 5) then
        -- Pan to Shabayev's ship.
        if (not Mission.m_IsCooperativeMode) then
            -- Stop the Manson portion.
            Mission.m_CinematicFirstFrameDone = true;

            -- Pan the Shabayev.
            CameraObject(Mission.m_Shabayev, 0, 1, 5, Mission.m_Shabayev);
        end
    elseif (Mission.m_CinematicAudioCount == 6) then
        -- Play the next movie.
        if (not Mission.m_IsCooperativeMode) then
            if (not Mission.m_CinematicReframeCamera) then
                -- Reframe.
                CameraReady();

                -- So we don't loop.
                Mission.m_CinematicReframeCamera = true;
            end

            -- Play the first movie.
            Mission.m_Movie1 = PlayMovie("base_look");
        end
    elseif (Mission.m_CinematicAudioCount == 7) then
        -- Play the next movie.
        if (not Mission.m_IsCooperativeMode) then
            if (not Mission.m_CinematicReframeCamera) then
                -- Reframe.
                CameraReady();

                -- So we don't loop.
                Mission.m_CinematicReframeCamera = true;
            end

            -- Play the first movie.
            Mission.m_Movie2 = PlayMovie("manson2");
        end
    end

    -- This plays through each cinematic dialog.
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        local clip = "cut020" .. Mission.m_CinematicAudioCount .. ".wav";

        -- Play the right dialog here.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles(clip);

        -- Set the timer based on the clip that is playing.
        if (clip == "cut0201.wav" or clip == "cut0202.wav") then
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        elseif (clip == "cut0203.wav" or clip == "cut0207.wav" or clip == "cut0208.wav") then
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
        elseif (clip == "cut0204.wav" or clip == "cut0206.wav") then
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);
        elseif (clip == "cut0205.wav") then
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);
        elseif (clip == "cut0209.wav") then
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);
        end

        -- This will play Manson's animation on clip 3.
        if (Mission.m_CinematicAudioCount == 3) then
            -- Give Manson his animation.
            SetAnimation(Mission.m_Manson, "line1", 1);
        elseif (Mission.m_CinematicAudioCount == 5) then
            -- Stop the movie and camera so we can play the next part.
            if (not Mission.m_IsCooperativeMode) then
                StopMovie();
                CameraFinish();
            end
        elseif (Mission.m_CinematicAudioCount == 7) then
            -- Give Manson his second animation.
            SetAnimation(Mission.m_Manson, "line2", 1);
        elseif (Mission.m_CinematicAudioCount == 8) then
            -- Finish the Camera sequence.
            CameraFinish();

            -- Highlight Simms.
            SetObjectiveOn(Mission.m_Simms);

            -- Move Shabayev to the comm bunker if she's too far away.
            if (GetDistance(Mission.m_Shabayev, "comm_point") > 50) then
                Goto(Mission.m_Shabayev, "comm_point", 1);
            end
        elseif (Mission.m_CinematicAudioCount == 9) then
            -- Show Objecitves.
            AddObjectiveOverride("isdf0106.otf", "WHITE", 10, true);

            -- Activate the warning for returning to the ship.
            Mission.m_ReturnToShipWarningActive = true;
            Mission.m_ReturnToShipWarningTime = Mission.m_MissionTime + SecondsToTurns(30);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end

        -- Iterate through each cutscene dialog and perform actions based on this count.
        Mission.m_CinematicAudioCount = Mission.m_CinematicAudioCount + 1;
    end
end

Functions[51] = function()
    -- This will check that the player has returned to their ship.
    for i = 1, _Cooperative.GetTotalPlayers() do
        local p = GetPlayerHandle(h);

        if (IsOdf(p, Mission.m_PlayerPilotODF)) then
            return;
        end
    end

    -- Remove the warning
    Mission.m_ReturnToShipWarningActive = false;

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[52] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0106.otf", "GREEN", 10, true);
        AddObjective("isdf0102.otf", "WHITE");

        -- Get Shabayev to go to Simms.
        Goto(Mission.m_Shabayev, "shab_attack_path");

        -- For our warnings
        Mission.m_ShabLeftBase = true;

        -- Remove the player lost check.
        Mission.m_PlayerLostCheckActive = false;

        -- Stop Simms from being attacked.
        SetPerceivedTeam(Mission.m_Simms, Mission.m_EnemyTeam);

        -- Shab: "Let's go Cooke."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0120.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[53] = function()
    -- This happens when we are closing in on Simms.
    if (GetDistance(Mission.m_Shabayev, "combat1a") < 500) then
        -- Simms: "I've got a visual!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0121.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Build the Scion units surrounding Simms.
        Mission.m_Scion1 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "combat1c");
        Mission.m_Scion2 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "combat1b");

        -- Make them invincible for now.
        SetMaxHealth(Mission.m_Scion1, 0);
        SetMaxHealth(Mission.m_Scion2, 0);

        -- Stop them from attacking Simms.
        SetIndependence(Mission.m_Scion1, 0);
        SetIndependence(Mission.m_Scion2, 0);

        -- Make them patrol.
        Patrol(Mission.m_Scion1, "circle_path", 1);
        Patrol(Mission.m_Scion2, "circle_path", 1);

        -- Make Simms look at one of the Scion units.
        LookAt(Mission.m_Simms, Mission.m_Scion1, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[54] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        local proceed = false;

        if (IsAlive(Mission.m_Scion1) and GetDistance(Mission.m_Shabayev, Mission.m_Scion1) < 400) then
            proceed = true;
        elseif (IsAlive(Mission.m_Scion2) and GetDistance(Mission.m_Shabayev, Mission.m_Scion2) < 400) then
            proceed = true;
        end

        -- Just so we don't repeat ourselves.
        if (proceed) then
            -- Shab: "I've got them on radar."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0122.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- Puts Simms back to our team.
            SetPerceivedTeam(Mission.m_Simms, 1);

            -- Restore all independence.
            SetIndependence(Mission.m_Simms, 1);
            SetIndependence(Mission.m_Scion1, 1);
            SetIndependence(Mission.m_Scion2, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[55] = function()
    local proceed = false;

    -- This checks if the player or Shabayev is in range of the two hostiles.
    if (IsAlive(Mission.m_Scion1) and (GetDistance(Mission.m_Shabayev, Mission.m_Scion1) < 150 or IsPlayerWithinDistance(Mission.m_Scion1, 150, _Cooperative.GetTotalPlayers()))) then
        proceed = true;
    elseif (IsAlive(Mission.m_Scion2) and (GetDistance(Mission.m_Shabayev, Mission.m_Scion2) < 150 or IsPlayerWithinDistance(Mission.m_Scion2, 150, _Cooperative.GetTotalPlayers()))) then
        proceed = true;
    end

    -- So we don't repeat ourselves.
    if (proceed) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0107.otf", "WHITE", 10, true);

        -- Shab: "Attack this target".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0123.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Remove objective from Simms.
        SetObjectiveOff(Mission.m_Simms);

        -- This determines our target.
        if (IsAlive(Mission.m_Scion1)) then
            -- Highlight the target.
            SetObjectiveOn(Mission.m_Scion1);

            -- Have this target attack our player.
            Attack(Mission.m_Scion1, GetPlayerHandle(1), 1);

            -- Check to see if the second Scion is around first.
            if (IsAlive(Mission.m_Scion2)) then
                Attack(Mission.m_Shabayev, Mission.m_Scion2);
            else
                Attack(Mission.m_Shabayev, Mission.m_Scion1);
            end
        elseif (IsAlive(Mission.m_Scion2)) then
            -- Highlight the target.
            SetObjectiveOn(Mission.m_Scion2);

            -- Have this target attack our player.
            Attack(Mission.m_Scion2, GetPlayerHandle(1), 1);

            -- Check to see if the second Scion is around first.
            if (IsAlive(Mission.m_Scion1)) then
                Attack(Mission.m_Shabayev, Mission.m_Scion1);
            else
                Attack(Mission.m_Shabayev, Mission.m_Scion2);
            end
        end

        -- Make the enemies killable.
        SetMaxHealth(Mission.m_Scion1, 2000);
        SetMaxHealth(Mission.m_Scion2, 2000);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[56] = function()
    local check1 = IsAlive(Mission.m_Scion1);
    local check2 = IsAlive(Mission.m_Scion2);

    -- Plays the "Give us a hand" dialog.
    if (not Mission.m_GiveHandDialogPlayed) then
        if (not check1 and check2) then
            -- Show Objectives.
            AddObjectiveOverride("isdf0107.otf", "WHITE", 10, true);

            -- Shab: "Good work. Help us here".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0141.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- This will make Shabayev and Simms attack the Scion if they were attacking the other one.
            Attack(Mission.m_Shabayev, Mission.m_Scion2, 1);
            Attack(Mission.m_Simms, Mission.m_Scion2, 1);

            -- Highlight next target.
            SetObjectiveOn(Mission.m_Scion2);

            -- So we don't loop.
            Mission.m_GiveHandDialogPlayed = true;
        elseif (check1 and not check2) then
            -- Show Objectives.
            AddObjectiveOverride("isdf0107.otf", "WHITE", 10, true);

            -- Shab: "Good work. Help us here".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0141.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- This will make Shabayev and Simms attack the Scion if they were attacking the other one.
            Attack(Mission.m_Shabayev, Mission.m_Scion1, 1);
            Attack(Mission.m_Simms, Mission.m_Scion1, 1);

            -- Highlight next target.
            SetObjectiveOn(Mission.m_Scion1);

            -- So we don't loop.
            Mission.m_GiveHandDialogPlayed = true;
        end
    end

    -- If both are dead.
    if (not check1 and not check2) then
        -- Tiny delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[57] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0107.otf", "GREEN", 10, true);

        -- Simms: "What the hell were those things?!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0125.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Have Shabayev look at the main player.
        LookAt(Mission.m_Shabayev, GetPlayerHandle(1), 1);

        -- Have Simms follow Shabayev.
        Follow(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[58] = function()
    -- This is a quick check to see if the player is within range.
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (not IsPlayerWithinDistance(Mission.m_Shabayev, 150, _Cooperative.GetTotalPlayers())) then
            -- Show objectives.
            AddObjectiveOverride("isdf0107.otf", "GREEN", 10, true);
            AddObjective("isdf0108.otf", "WHITE");

            -- Shab: "Cooke, come to me."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0125a.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- Do the player lost check here.
            Mission.m_PlayerLostCheckActive = true;
            Mission.m_PlayerLostFirstDialog = true;
            Mission.m_PlayerLostTime = Mission.m_MissionTime + SecondsToTurns(25);
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[59] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Have Shab and Simms look at each other.
        LookAt(Mission.m_Simms, Mission.m_Shabayev, 1);
        LookAt(Mission.m_Shabayev, Mission.m_Simms, 1);

        -- Shab: "We've got company!".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0142.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Remove the player lost check.
        Mission.m_PlayerLostCheckActive = false;
        Mission.m_PlayerLostFirstDialog = false;
        Mission.m_PlayerLost = false;

        -- Spawns more enemies.
        Mission.m_Scion1 = BuildObject("fvscout_x", Mission.m_EnemyTeam, "bad_spawn1");
        Mission.m_Scion2 = BuildObject("fvscout_x", Mission.m_EnemyTeam, "bad_spawn2");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[60] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0108.otf", "GREEN", 10, true);
        AddObjective("isdf0102.otf", "WHITE");

        -- Simms to follow Shabayev
        Follow(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- Move Shabayev back to the base.
        Goto(Mission.m_Shabayev, "return_path2", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[61] = function()
    -- This has Shabayev detect the next wave.
    if (IsAlive(Mission.m_Scion1) or IsAlive(Mission.m_Scion2)) then
        if (GetDistance(Mission.m_Shabayev, "bad_detected") < 40) then
            -- Show Objectives.
            AddObjectiveOverride("isdf0109.otf", "WHITE", 10, true);

            -- Highlight both enemies.
            SetObjectiveOn(Mission.m_Scion1);
            SetObjectiveOn(Mission.m_Scion2);

            -- Have them move.
            Goto(Mission.m_Scion1, Mission.m_MagicCrate, 1);
            Goto(Mission.m_Scion2, Mission.m_MagicCrate, 1);

            -- Have Shabayev talk about it.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0126.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    else
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[62] = function()
    if (IsAlive(Mission.m_Scion1) or IsAlive(Mission.m_Scion2)) then
        local check1 = GetDistance(Mission.m_Shabayev, "base_center") < 60 and
            IsPlayerWithinDistance(Mission.m_Shabayev, 70, _Cooperative.GetTotalPlayers());
        local check2 = IsPlayerWithinDistance(Mission.m_Scion1, 200, _Cooperative.GetTotalPlayers()) or
            IsPlayerWithinDistance(Mission.m_Scion2, 200, _Cooperative.GetTotalPlayers());

        -- This checks to see if the player has ignored the order to attack.
        if (check1 or check2) then
            if (GetCurrentCommand(Mission.m_Scion1) ~= AiCommand.CMD_ATTACK) then
                Attack(Mission.m_Scion1, GetPlayerHandle(i), 1);
            end

            if (GetCurrentCommand(Mission.m_Scion2) ~= AiCommand.CMD_ATTACK) then
                Attack(Mission.m_Scion2, GetPlayerHandle(i), 1);
            end
        end
    else
        -- Add a small delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(4);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[63] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Red 1: "Mayday!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0127.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[64] = function()
    -- Do another distance check just incase Shabayev isn't at the base yet.
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and GetDistance(Mission.m_Shabayev, "base_center") < 60) then
        -- Check to see if the player has returned to Shabayev.
        if (IsPlayerWithinDistance(Mission.m_Shabayev, 100, _Cooperative.GetTotalPlayers())) then
            -- Show objectives.
            AddObjectiveOverride("isdf0108.otf", "GREEN", 10, true);

            -- Move Simms to his last point.
            Goto(Mission.m_Simms, "simms_last_point");

            -- Shab: "Copy Red 1, can you send your location?"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0128.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- Remove the player lost check.
            Mission.m_PlayerLostFirstTime = true;
            Mission.m_PlayerLost = false;
            Mission.m_PlayerLostCheckActive = false;
            Mission.m_PlayerLostFirstDialog = false;

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        elseif (not Mission.m_ReturnToBaseDialogPlayed) then
            -- Show objectives.
            AddObjectiveOverride("isdf0109.otf", "GREEN", 10, true);
            AddObjective("isdf0108.otf", "WHITE");

            -- Shab: "Copy Red 1, Cooke, come to me."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0143.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Do the player lost check here.
            Mission.m_PlayerLostCheckActive = true;
            Mission.m_PlayerLostFirstDialog = true;
            Mission.m_PlayerLostTime = Mission.m_MissionTime + SecondsToTurns(25);

            -- So we don't loop.
            Mission.m_ReturnToBaseDialogPlayed = true;
        end
    end
end

Functions[65] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- First player.
        local p = GetPlayerHandle(1);

        -- Shab: Got it Red 1, on our way.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0129.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Build Red 1, enemies, and the Truck.
        Mission.m_Scion1 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "combat2c");
        Mission.m_Scion2 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "combat2d");
        Mission.m_Scion3 = BuildObject("fvscout_x", Mission.m_EnemyTeam, "combat2c");
        Mission.m_Red1 = BuildObject("p1scout", Mission.m_AlliedTeam, "combat2a");
        Mission.m_Red2 = BuildObject("p1scout", Mission.m_AlliedTeam, "combat2b");
        Mission.m_Red3 = BuildObject("p1scout", Mission.m_AlliedTeam, "combat2e");

        -- Spawn the truck in the crater.
        Mission.m_Truck = BuildObject("ivserv_x", Mission.m_HostTeam, "truck_spawn");

        -- Don't allow command of the Truck yet.
        Stop(Mission.m_Truck, 1);

        -- Remove the independence of these units so they don't fight.
        SetIndependence(Mission.m_Scion1, 0);
        SetIndependence(Mission.m_Scion2, 0);
        SetIndependence(Mission.m_Scion3, 0);
        SetIndependence(Mission.m_Red1, 0);
        SetIndependence(Mission.m_Red2, 0);
        SetIndependence(Mission.m_Red3, 0);

        -- Damage Red Squad slightly.
        SetCurHealth(Mission.m_Red1, 1800);
        SetCurHealth(Mission.m_Red2, 1500);
        SetCurHealth(Mission.m_Red3, 900);

        -- This stops the Scions.
        Stop(Mission.m_Scion1, 1);
        Stop(Mission.m_Scion2, 1);
        Stop(Mission.m_Scion3, 1);

        -- Have everyone look at the player.
        LookAt(Mission.m_Red1, p, 1);
        LookAt(Mission.m_Red2, p, 1);
        LookAt(Mission.m_Red3, p, 1);
        LookAt(Mission.m_Truck, p, 1);

        -- Change Red 1's name.
        SetObjectiveName(Mission.m_Red1, "Red 1");
        SetObjectiveOn(Mission.m_Red1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[66] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Simms: "I'm banged up pretty bad here."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0130.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Same logic if Red Squad dies.
        Mission.m_RedSquadAroundWarningActive = true;

        -- Have Simms look at Shabayev
        LookAt(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[67] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "Alright Lt Simms, stay here".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0145.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[68] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0102.otf", "WHITE", 10, true);

        -- Move Simms to the base centre.
        Goto(Mission.m_Simms, "base_center", 1);

        -- Have Shabayev move.
        Goto(Mission.m_Shabayev, "goal_one_path", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[69] = function()
    if (GetDistance(Mission.m_Shabayev, "goalone_point") < 30) then
        -- Have Shab look at the player.
        LookAt(Mission.m_Shabayev, GetPlayerHandle(1));

        -- Shab: "This area is too hot"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0146.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Small delay before Shabayev looks at Red 1.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(6);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[70] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Have her look at Red 1.
        LookAt(Mission.m_Shabayev, Mission.m_Red1);

        -- Activate the storage dialog.
        Mission.m_ShabStorageBayCheckActive = true;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[71] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- If Shabayev is near the ammo depot, do a check to make sure all of the players are stocked up before we leave.
        if (GetDistance(Mission.m_Shabayev, "getammo_point") < 30) then
            for i = 1, _Cooperative.GetTotalPlayers() do
                -- Check to see if this player needs supplies.
                local p = GetPlayerHandle(i);

                -- Return if the player is still in need of supply.
                if (GetCurHealth(p) < 1800 or GetCurAmmo(p) < 750) then
                    return;
                end
            end
        end

        -- Show Objectives
        AddObjectiveOverride("isdf0110.otf", "WHITE", 10, true);

        -- Shab: "Alright Cooke, move out!".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0148.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Have her look at the main player.
        LookAt(Mission.m_Shabayev, GetPlayerHandle(1));

        -- TODO, Warning if the player takes too long.
        Mission.m_Red1HelpWarningActive = true;
        Mission.m_Red1HelpWarningTime = Mission.m_MissionTime + SecondsToTurns(60);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[72] = function()
    if (IsPlayerWithinDistance(Mission.m_Red1, 250, _Cooperative.GetTotalPlayers())) then
        -- Send Shab to the base centre.
        Goto(Mission.m_Shabayev, "base_center", 1);

        -- Remove her highlight
        SetObjectiveOff(Mission.m_Shabayev);

        -- We don't need these anymore.
        Mission.m_Red1HelpWarningActive = false;
        Mission.m_ShabStorageBayCheckActive = false;

        -- This kicks off the attacks.
        Attack(Mission.m_Scion1, Mission.m_Red3);
        Attack(Mission.m_Scion2, Mission.m_Red2);
        Attack(Mission.m_Scion3, Mission.m_Red3);

        -- Regain independence so they attack nearby hostiles.
        SetIndependence(Mission.m_Scion1, 1);
        SetIndependence(Mission.m_Scion2, 1);
        SetIndependence(Mission.m_Scion3, 1);
        SetIndependence(Mission.m_Red1, 1);
        SetIndependence(Mission.m_Red2, 1);
        SetIndependence(Mission.m_Red3, 1);

        -- Get Red Squad to attack.
        Attack(Mission.m_Red3, Mission.m_Scion1);
        Attack(Mission.m_Red2, Mission.m_Scion2);
        Attack(Mission.m_Red1, Mission.m_Scion3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[73] = function()
    if (not IsAlive(Mission.m_Scion1) and not IsAlive(Mission.m_Scion2) and not IsAlive(Mission.m_Scion3)) then
        -- Have Red Squad regroup after the panic, if they are still alive.
        if (IsAlive(Mission.m_Red3)) then
            if (IsAlive(Mission.m_Red2)) then
                Follow(Mission.m_Red3, Mission.m_Red2);
            else
                Follow(Mission.m_Red3, Mission.m_Red1);
            end
        end

        if (IsAlive(Mission.m_Red2)) then
            Follow(Mission.m_Red2, Mission.m_Red1);
        end

        -- Have Red 1 move to the player.
        Goto(Mission.m_Red1, GetPlayerHandle(1));

        -- Add Objectives.
        AddObjectiveOverride("isdf0110.otf", "GREEN", 10, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[74] = function()
    -- Checks to see if Red 1 is near the player.
    if (GetDistance(Mission.m_Red1, GetPlayerHandle(1)) < 60) then
        -- Have her look at the main player.
        LookAt(Mission.m_Red1, GetPlayerHandle(1));

        -- Red 1: "Good shooting Cooke..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0133.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

        -- Do a tiny delay before highlighting the truck.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[75] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Have her look at the truck.
        LookAt(Mission.m_Red1, Mission.m_Truck, 1);

        -- Highlight the truck.
        SetObjectiveOn(Mission.m_Truck);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[76] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Add Objectives.
        AddObjectiveOverride("isdf0111.otf", "WHITE", 10, true);

        -- Remove the highlight from Red 1.
        SetObjectiveOff(Mission.m_Red1);

        -- Send Red 1 back to the base.
        Goto(Mission.m_Red1, "truck_home_point", 1);

        -- Add the warning for the player to go the truck.
        Mission.m_TruckHelpWarningActive = true;
        Mission.m_TruckHelpWarningTime = Mission.m_MissionTime + SecondsToTurns(45);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[77] = function()
    -- Checks to see if a player is near the truck.
    if (IsPlayerWithinDistance(Mission.m_Truck, 100, _Cooperative.GetTotalPlayers())) then
        -- Stop the warning.
        Mission.m_TruckHelpWarningActive = false;

        -- Add Objectives.
        AddObjectiveOverride("isdf0111.otf", "GREEN", 10, true);

        -- Truck: "Thank god, get me out of here!".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0135.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[78] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Highlight Shabayev again.
        SetObjectiveOn(Mission.m_Shabayev);

        -- Shab: "Cooke will get you out of there"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0136.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[79] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Truck: "Roger, moving".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0137.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Move the truck to Shabayev.
        Goto(Mission.m_Truck, "truck_path", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[80] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Add Objectives.
        AddObjectiveOverride("isdf0112.otf", "WHITE", 10, true);

        -- Shab: "Protect that truck!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0138.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Spawn the next Scion attackers.
        local one = { "fvscout_x", "fvsent_x", "fvsent_x" };
        local two = { "fvscout_x", "fvscout_x", "fvsent_x" };

        -- Seems a bit harsh to set both on the truck, so I'll get one to attack the player as well.
        Mission.m_Scion1 = BuildObject(one[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "espawn_truck");
        Mission.m_Scion2 = BuildObject(two[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "espawn1_combat2");

        -- Have each one do their job.
        Attack(Mission.m_Scion1, Mission.m_Truck, 1);
        Attack(Mission.m_Scion2, GetPlayerHandle(1), 1);

        -- Add a small delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[81] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- This checks to see if the Scion attackers are near, dispatch Shabayev.
        local check1 = IsAlive(Mission.m_Scion1) and
            IsPlayerWithinDistance(Mission.m_Scion1, 450, _Cooperative.GetTotalPlayers());
        local check2 = IsAlive(Mission.m_Scion2) and
            IsPlayerWithinDistance(Mission.m_Scion2, 450, _Cooperative.GetTotalPlayers());
        local check3 = not IsAlive(Mission.m_Scion1) and not IsAlive(Mission.m_Scion2);

        -- This will dispatch Shabayev.
        if (check1 or check2) then
            -- Shab: "I'm picking up two more hostiles!".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0149.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- Have Shabayev defend the truck.
            Follow(Mission.m_Shabayev, Mission.m_Truck, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        elseif (check3) then
            -- Advance the mission state...
            Mission.m_MissionState = 84;
        end
    end
end

Functions[82] = function()
    local check1 = not IsAlive(Mission.m_Scion1) and not IsAlive(Mission.m_Scion2);

    -- This will get Shabayev to attack when she is near.
    if (not check1) then
        if (GetDistance(Mission.m_Shabayev, Mission.m_Truck) < 100) then
            if (GetCurrentCommand(Mission.m_Shabayev) ~= AiCommand.CMD_ATTACK) then
                if (IsAlive(Mission.m_Scion1)) then
                    -- Have her attack.
                    Attack(Mission.m_Shabayev, Mission.m_Scion1, 1);
                elseif (IsAlive(Mission.m_Scion2)) then
                    -- Have her attack.
                    Attack(Mission.m_Shabayev, Mission.m_Scion2, 1);
                end
            end
        end
    else
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[83] = function()
    if (GetDistance(Mission.m_Truck, "base_center") > 100) then
        -- Bring Shabayev to the truck.
        Follow(Mission.m_Shabayev, Mission.m_Truck, 1);

        -- Shab: "Good Job, follow it back".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0158.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[84] = function()
    if (GetDistance(Mission.m_Truck, "truck_home_point") < 100) then
        -- Shab: "Well done John".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0157.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Show Objectives.
        AddObjectiveOverride("isdf0112.otf", "GREEN", 10, true);

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(10);
        else
            SucceedMission(GetTime() + 10, "isdf01w1.txt");
        end

        -- Mission is over.
        Mission.m_MissionOver = true;
    end
end

function ShabayevBrain()
    -- This is the "mini-brain" for Shabayev switching her perspective between player and Simms.
    if (Mission.m_ShabLookLogicEnabled) then
        if (Mission.m_ShabLookSwitchTime < Mission.m_MissionTime) then
            if (not Mission.m_ShabLookAtPlayer) then
                -- Let's have her look at random players for fun.
                local randChance = math.ceil(GetRandomFloat(0, _Cooperative.GetTotalPlayers()));

                -- Have her look at the main player.
                LookAt(Mission.m_Shabayev, GetPlayerHandle(randChance), 1);

                -- Small cooldown for her to switch.
                Mission.m_ShabLookSwitchTime = Mission.m_MissionTime + SecondsToTurns(15);

                -- So we switch targets correctly.
                Mission.m_ShabLookAtPlayer = true;
            else
                -- Have her look at the main Simms.
                LookAt(Mission.m_Shabayev, Mission.m_Simms, 1);

                -- Small cooldown for her to switch.
                Mission.m_ShabLookSwitchTime = Mission.m_MissionTime + SecondsToTurns(9);

                -- So we switch targets correctly.
                Mission.m_ShabLookAtPlayer = false;
            end
        end
    end

    -- This checks for when she is off the dropship and needs to wait for the player.
    if (not Mission.m_ShabHoldForPlayer) then
        -- Do a distance check before she looks.
        if (GetDistance(Mission.m_Shabayev, "shab_firststoppoint") < 20) then
            -- Have her look at the first player.
            LookAt(Mission.m_Shabayev, GetPlayerHandle(1), 1);

            -- Just for the look brain.
            Mission.m_ShabLookLogicEnabled = true;
            Mission.m_ShabLookSwitchTime = Mission.m_MissionTime + SecondsToTurns(6);
            Mission.m_ShabLookAtPlayer = true;

            -- This will also remove the dropship for Red Squad.
            SetAnimation(Mission.m_Condor2, "takeoff", 1);

            -- Show the emitters for takeoff.
            StartEmitter(Mission.m_Condor2, 1);
            StartEmitter(Mission.m_Condor2, 2);

            -- Nice sounds.
            StartSoundEffect("dropleav.wav", Mission.m_Condor2);

            -- Add the time it takes to remove the dropship.
            Mission.m_Condor2RemoveTime = Mission.m_MissionTime + SecondsToTurns(15);

            -- So we don't loop.
            Mission.m_ShabHoldForPlayer = true;
        end
    end

    -- This checks to see if the player has found the communication station. If they don't do it in time, we can move Shabayev to find it herself.
    if (Mission.m_CommWarningActive and Mission.m_CommWarningTime < Mission.m_MissionTime) then
        if (Mission.m_ShabCommReminderCount == 0) then
            -- Show objectives.
            AddObjectiveOverride("isdf0104.otf", "WHITE", 10, true);

            -- Shab: "Cooke, I need that building found, now."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0113v2.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

            -- Before the next warning.
            Mission.m_CommWarningTime = Mission.m_MissionTime + SecondsToTurns(40);

            -- Increase the warning count for the next stage.
            Mission.m_ShabCommReminderCount = Mission.m_ShabCommReminderCount + 1;
        else
            -- This will move Shabayev to the communication station on her own.
            Mission.m_CommWarningActive = false;

            -- Move her to the communication station.
            Goto(Mission.m_Shabayev, "comm_point", 1);

            -- Move the mission state to where she tells the player to enter the building.
            Mission.m_MissionState = 48;
        end
    end

    -- This checks to see if the player is out of their ship.
    if (Mission.m_LeaveShipWarningActive and Mission.m_LeaveShipWarningTime < Mission.m_MissionTime) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0105.otf", "WHITE", 10, true);

        -- Shab: "Get out of your ship!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0140.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Time between each loop.
        Mission.m_LeaveShipWarningTime = Mission.m_MissionTime + SecondsToTurns(25);
    end

    -- This checks to see if the player has hopped back into their ship or not.
    if (Mission.m_ReturnToShipWarningActive and Mission.m_ReturnToShipWarningTime < Mission.m_MissionTime) then
        if (Mission.m_ShabReturnToShipWarningCount == 0) then
            -- Show objectives.
            AddObjectiveOverride("isdf0106.otf", "WHITE", 10, true);

            -- Shab: "Cooke, get back to your ship!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0119.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- Before the next warning.
            Mission.m_ReturnToShipWarningTime = Mission.m_MissionTime + SecondsToTurns(20);

            -- Increase the warning count for the next stage.
            Mission.m_ShabReturnToShipWarningCount = Mission.m_ShabCommReminderCount + 1;
        else
            -- Show objectives.
            AddObjectiveOverride("isdf0106.otf", "RED", 10, true);

            -- Shab: "I'm moving on without you!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("return03.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Mission is over.
            Mission.m_MissionOver = true;

            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("You failed to follow the orders of your commanding officer!");
                DoGameover(10);
            else
                FailMission(GetTime() + 10, "isdf01l2.txt");
            end
        end
    end

    -- If a player is low on ammo or health.
    if (Mission.m_ShabStorageBayCheckActive) then
        if (not Mission.m_ShabStorageBayCheckDialogPlayed) then
            for i = 1, _Cooperative.GetTotalPlayers() do
                -- Check to see if this player needs supplies.
                local p = GetPlayerHandle(i);

                if (GetCurHealth(p) < 1800 or GetCurAmmo(p) < 750) then
                    -- Do the talk.
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0147.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

                    -- Have her look at the storage bay.
                    LookAt(Mission.m_Shabayev, Mission.m_StorageBay, 1);

                    -- Turn this off.
                    Mission.m_ShabStorageBayCheckDialogPlayed = true;

                    -- Do a delay before she moves to the storage bay.
                    Mission.m_ShabMoveToStorageBayDelay = Mission.m_MissionTime + SecondsToTurns(5);
                end
            end
        elseif (Mission.m_ShabMoveToStorageBayDelay < Mission.m_MissionTime) then
            -- This sends Shabayev to the ammo depot.
            Goto(Mission.m_Shabayev, "getammo_point");

            -- Do a tiny delay before we check again.
            Mission.m_ShabMoveToStorageBayDelay = Mission.m_MissionTime + SecondsToTurns(1);

            if (GetDistance(Mission.m_Shabayev, "getammo_point") < 30) then
                -- Have her look at the main player, and mark this part as done.
                LookAt(Mission.m_Shabayev, GetPlayerHandle(1));

                -- Mark this part as done.
                Mission.m_ShabStorageBayCheckActive = false;
            end
        end
    end

    -- This checks to see if the player is taking too long to help Red 1.
    if (Mission.m_Red1HelpWarningActive and Mission.m_Red1HelpWarningTime < Mission.m_MissionTime) then
        if (Mission.m_Red1HelpWarningCount == 0) then
            -- Show Objectives.
            AddObjectiveOverride("isdf0110.otf", "WHITE", 10, true);

            -- Shab: "What's the hold up Cooke?"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0132.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- Add a new time.
            Mission.m_Red1HelpWarningTime = Mission.m_MissionTime + SecondsToTurns(45);

            -- Increase the warning count.
            Mission.m_Red1HelpWarningCount = Mission.m_Red1HelpWarningCount + 1;
        elseif (Mission.m_Red1HelpWarningCount == 1) then
            -- Show Objectives.
            AddObjectiveOverride("isdf0110.otf", "RED", 10, true);

            -- Shab: "Red 1 is lost"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0155.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- Destroy everything.
            Damage(Mission.m_Red1, 3000);
            Damage(Mission.m_Red2, 3000);
            Damage(Mission.m_Red3, 3000);

            -- Increase the warning count.
            Mission.m_Red1HelpWarningCount = Mission.m_Red1HelpWarningCount + 1;
        end
    end

    -- This checks to see if the player is taking too long to reach the Service Truck.
    if (Mission.m_TruckHelpWarningActive and Mission.m_TruckHelpWarningTime < Mission.m_MissionTime) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0111.otf", "WHITE", 10, true);

        -- Shab: "Go to that truck!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0134.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Highlight the truck again.
        SetObjectiveOn(Mission.m_Truck);

        -- Add a new time.
        Mission.m_TruckHelpWarningTime = Mission.m_MissionTime + SecondsToTurns(45);
    end
end

function SimmsBrain()
    -- This keeps Simms alive.
    if (GetCurHealth(Mission.m_Simms) < 400) then
        SetCurHealth(Mission.m_Simms, 400);
    end

    -- This checks to see if Simms reaches the bluff first if the turret is dead.
    if (not Mission.m_SimmsAtBluffFirst and not IsAlive(Mission.m_ScionTurret) and GetDistance(Mission.m_Simms, "shab_point3") < 30) then
        -- Have Simms look at Shabayev.
        LookAt(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- So we don't loop.
        Mission.m_SimmsAtBluffFirst = true;
    end

    -- This stops Simms when he reaches the first point when exiting the dropship.
    if (not Mission.m_SimmsHold and GetDistance(Mission.m_Simms, "wing_first_point") < 20) then
        -- Have Simms look at Shabayev.
        LookAt(Mission.m_Simms, Mission.m_Shabayev, 1);

        -- So we don't loop.
        Mission.m_SimmsHold = true;
    end

    -- This checks to make sure Simms look at Red Squad.
    if (Mission.m_RedSquadStart and Mission.m_SimmsLookAtRed1Time and not Mission.m_SimmsLookAtRed1) then
        -- Have Simms look at Red 1 as they pass.
        LookAt(Mission.m_Simms, Mission.m_Red1, 1);

        -- So we don't loop.
        Mission.m_SimmsLookAtRed1 = true;
    end

    -- This checks to see if Simms should look at the turret or not.
    if (not Mission.m_SimmsLookAtTurret and GetCurrentCommand(Mission.m_ScionTurret) == AiCommand.CMD_ATTACK and GetDistance(Mission.m_Simms, Mission.m_ScionTurret) < 50) then
        -- Have him look at the turret.
        LookAt(Mission.m_Simms, Mission.m_Turret, 1);

        -- So we don't loop.
        Mission.m_SimmsLookAtTurret = true;
    end

    -- This checks to get Simms to look at the comm building.
    if (not Mission.m_SimmsLookAtCommBuilding and Mission.m_MissionState > 35 and Mission.m_SimmsLookAtCommBuildingTime < Mission.m_MissionTime) then
        -- Have Simms look at the comm bunker.
        LookAt(Mission.m_Simms, Mission.m_CommBuilding, 1);

        -- So we don't loop.
        Mission.m_SimmsLookAtCommBuilding = true;
    end

    -- This will get simms to stop and look at the player when he arrives at this path.
    if (not Mission.m_SimmsLookAtPlayer and GetDistance(Mission.m_Simms, "combat1a") < 50) then
        -- Have him look and standby for the next sequence.
        LookAt(Mission.m_Simms, GetPlayerHandle(1), 1);

        -- So we don't loop.
        Mission.m_SimmsLookAtPlayer = true;
    end
end

function DropshipBrain()
    local c1Check = IsAround(Mission.m_Condor1);
    local c2Check = IsAround(Mission.m_Condor2);
    local c3Check = IsAround(Mission.m_Condor3);

    -- This is where we first remove the Red Squad Condor.
    if (c2Check and Mission.m_ShabHoldForPlayer and Mission.m_Condor2RemoveTime < Mission.m_MissionTime) then
        -- Safely remove the second Condor.
        RemoveObject(Mission.m_Condor2);
    end

    -- This is for the other condors.
    if ((c1Check or c3Check) and Mission.m_MissionState > 13) then
        if (c1Check and Mission.m_Condor1RemoveTime < Mission.m_MissionTime) then
            -- Safely remove the first Condor.
            RemoveObject(Mission.m_Condor1);
        end

        if (c3Check and Mission.m_Condor3RemoveTime < Mission.m_MissionTime) then
            -- Safely remove the first Condor.
            RemoveObject(Mission.m_Condor3);
        end
    end
end

function RedSquadBrain()
    -- This makes Red Squad move to their path after a few seconds.
    if (not Mission.m_RedSquadStart and Mission.m_MissionState > 12 and Mission.m_RedSquadStartWait < Mission.m_MissionTime) then
        -- Have Red Squad move to their path.
        Goto(Mission.m_Red1, "ok_path1", 1);

        -- This sets a small delay so Simms looks at Red Squad.
        Mission.m_SimmsLookAtRed1Time = Mission.m_MissionTime + SecondsToTurns(3);

        -- So we don't loop.
        Mission.m_RedSquadStart = true;
    end

    -- This does a check the make sure Red Squad waits for the rest before advancing.
    if (not Mission.m_RedSquadWaiting and Mission.m_RedSquadStart) then
        if (not Mission.m_Red1Stop and GetDistance(Mission.m_Red1, "squad1_point1") < 20) then
            -- Have them look at everyone.
            LookAt(Mission.m_Red1, Mission.m_Shabayev, 1);

            -- So we don't loop.
            Mission.m_Red1Stop = true;
        end

        if (not Mission.m_Red2Stop and GetDistance(Mission.m_Red2, "squad1_point1") < 35) then
            -- Have them look at everyone.
            LookAt(Mission.m_Red2, Mission.m_Simms, 1);

            -- So we don't loop.
            Mission.m_Red2Stop = true;
        end

        if (not Mission.m_Red3Stop and GetDistance(Mission.m_Red3, "squad1_point1") < 55) then
            -- Have them look at everyone.
            LookAt(Mission.m_Red3, GetPlayerHandle(1), 1);

            -- So we don't loop.
            Mission.m_Red3Stop = true;
        end

        if (Mission.m_Red1Stop and Mission.m_Red2Stop and Mission.m_Red3Stop) then
            -- Break this loop.
            Mission.m_RedSquadWaiting = true;
        end
    end

    -- This checks to see if Red Squad has left the map so we can remove them.
    if (GetDistance(Mission.m_Red1, "squad1_point2") < 30) then
        -- Turn the warning off so we don't fail if they are removed.
        Mission.m_RedSquadAroundWarningActive = false;

        -- Remove Red Squad for now.
        RemoveObject(Mission.m_Red1);
        RemoveObject(Mission.m_Red2);
        RemoveObject(Mission.m_Red3);
    end
end

function HandleFailureConditions()
    -- This checks to see if any of the players are lost if the check is active.
    if (Mission.m_PlayerLostCheckActive) then
        if (not Mission.m_PlayerLost) then
            for i = 1, _Cooperative.GetTotalPlayers() do
                local p = GetPlayerHandle(i);

                local check1 = ((not Mission.m_ShabMoveToBaseCentre or (Mission.m_ShabMoveToBaseCentre and Mission.m_ShabLeftBase)) and GetDistance(p, Mission.m_Shabayev) > 150);
                local check2 = (Mission.m_ShabMoveToBaseCentre and not Mission.m_ShabLeftBase and GetDistance(p, "base_center") > 250);

                if (check1) then
                    print("check1 true");
                end

                if (check2) then
                    print("check2 true");
                end

                if (check1 or check2) then
                    -- Set the lost player handle so Shabayev yells.
                    Mission.m_LostPlayer = p;

                    -- Set a timer to fail if they player is lost for too long.
                    Mission.m_PlayerLostTime = Mission.m_MissionTime + SecondsToTurns(20);

                    -- Mark the player as lost.
                    Mission.m_PlayerLost = true;
                end
            end
        else
            if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                if (not Mission.m_PlayerLostFirstDialog) then
                    local check1 = not Mission.m_ShabMoveToBaseCentre or
                        (Mission.m_ShabMoveToBaseCentre and Mission.m_ShabLeftBase);
                    local check2 = Mission.m_ShabMoveToBaseCentre and not Mission.m_ShabLeftBase;

                    -- Have Shabayev look at the lost player.
                    LookAt(Mission.m_Shabayev, Mission.m_LostPlayer, 1);

                    -- Show Objectives.
                    AddObjectiveOverride("isdf0102.otf", "RED", 10, true);

                    if (check1) then
                        -- This plays a message depending on the point of the mission.
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("return01.wav");

                        -- Set the timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);
                    elseif (check2) then
                        -- Increase the warning count.
                        Mission.m_PlayerLostWarningCount = Mission.m_PlayerLostWarningCount + 1;

                        -- This plays a message depending on the point of the mission.
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0150.wav");

                        -- Set the timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
                    end

                    -- So we don't loop.
                    Mission.m_PlayerLostFirstDialog = true;
                end

                -- Run a check against this timer.
                if (Mission.m_PlayerLostFirstTime) then
                    if (Mission.m_PlayerLostTime < Mission.m_MissionTime) then
                        -- Play our audio
                        if (not Mission.m_ShabMoveToBaseCentre or (Mission.m_ShabMoveToBaseCentre and Mission.m_ShabLeftBase)) then
                            if (Mission.m_PlayerLostWarningCount == 0) then
                                -- Shab: "Cooke, use your radar."
                                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("return04.wav");

                                -- Set the timer for this audio clip.
                                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

                                -- Set a timer to fail if they player is lost for too long.
                                Mission.m_PlayerLostTime = Mission.m_MissionTime + SecondsToTurns(30);

                                -- Increase the warning count.
                                Mission.m_PlayerLostWarningCount = Mission.m_PlayerLostWarningCount + 1;
                            elseif (Mission.m_PlayerLostWarningCount == 1) then
                                -- Shab: "Cooke, return to me, now!"
                                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("return02.wav");

                                -- Set the timer for this audio clip.
                                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

                                -- Set a timer to fail if they player is lost for too long.
                                Mission.m_PlayerLostTime = Mission.m_MissionTime + SecondsToTurns(20);

                                -- Increase the warning count.
                                Mission.m_PlayerLostWarningCount = Mission.m_PlayerLostWarningCount + 1;
                            end
                        elseif (Mission.m_ShabMoveToBaseCentre and not Mission.m_ShabLeftBase) then
                            -- Shab: "Cooke, return to base."
                            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0151.wav");

                            -- Set the timer for this audio clip.
                            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                            -- Set a timer to fail if they player is lost for too long.
                            Mission.m_PlayerLostTime = Mission.m_MissionTime + SecondsToTurns(20);

                            -- Increase the warning count.
                            Mission.m_PlayerLostWarningCount = Mission.m_PlayerLostWarningCount + 1;
                        end
                    end
                end

                -- First, check if the lost player returns to Shabayev.
                local check1 = ((not Mission.m_ShabMoveToBaseCentre or (Mission.m_ShabMoveToBaseCentre and Mission.m_ShabLeftBase)) and GetDistance(Mission.m_LostPlayer, Mission.m_Shabayev) < 50);
                local check2 = (Mission.m_ShabMoveToBaseCentre and not Mission.m_ShabLeftBase and GetDistance(Mission.m_LostPlayer, "base_center") < 250);

                if (check1 or check2) then
                    -- Reset stuff.
                    Mission.m_PlayerLost = false;
                    Mission.m_LostPlayer = nil;
                    Mission.m_PlayerLostWarningCount = 0;
                    Mission.m_PlayerLostTime = 0;
                    Mission.m_PlayerLostFirstDialog = false;

                    -- If this is the first time they've been lost, encourage them.
                    if (not Mission.m_PlayerLostFirstTime) then
                        -- Play audio.
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("return05.wav");

                        -- Set the timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

                        -- So we don't loop.
                        Mission.m_PlayerLostFirstTime = true;
                    end
                end
            end
        end
    end

    -- If the player is lost.
    if (Mission.m_PlayerLostWarningCount == 2 and Mission.m_PlayerLostTime < Mission.m_MissionTime) then
        -- Do some checks for each audio.
        if (Mission.m_ShabMoveToBaseCentre and not Mission.m_ShabLeftBase) then
            -- Shab: "Have fun out there Cooke."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0152.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
        elseif (Mission.m_ShabMoveToBaseCentre and Mission.m_ShabLeftBase) then
            -- Shab: "I'm moving on without you!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("return03.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);
        else
            -- Shab: "I'm moving on without you!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("return03.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);
        end

        -- Mission is over.
        Mission.m_MissionOver = true;

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("You failed to follow the orders of your commanding officer!");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf01l2.txt");
        end
    end

    -- If Red Squad is destroyed.
    if (Mission.m_RedSquadAroundWarningActive and not IsAlive(Mission.m_Red1) and not IsAlive(Mission.m_Red2) and not IsAlive(Mission.m_Red3)) then
        -- Mission is over.
        Mission.m_MissionOver = true;

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Red Squad is KIA.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf01l1.txt");
        end
    end

    -- If the Comm Station is destroyed.
    if (not IsAround(Mission.m_CommBuilding)) then
        -- Mission is over.
        Mission.m_MissionOver = true;

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The Communication Station was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf01l3.txt");
        end
    end

    -- If Shabayev is killed.
    if (not IsAlive(Mission.m_Shabayev)) then
        -- Mission is over.
        Mission.m_MissionOver = true;

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Shabayev is KIA!");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf01l4.txt");
        end
    end

    -- If the truck is killed.
    if (Mission.m_MissionState > 65 and not IsAround(Mission.m_Truck)) then
        -- Mission is over.
        Mission.m_MissionOver = true;

        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The Service Truck was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf01l7.txt");
        end
    end
end
