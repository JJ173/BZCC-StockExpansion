--[[
    BZCC ISDF10 Lua Mission Script
    Written by AI_Unit
    Version 1.0 12-01-2024
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

-- Timers for difficulty.
local m_ConvoyTime = { 180, 120, 60 };

-- Mission Name
local m_MissionName = "ISDF10: Snow Blind";

-- Mission important variables.
local Mission =
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "ispilo_x",
    -- Specific to mission.
    m_PlayerShipODF = "ivtank_x",

    m_Holders = {},
    m_Condor1 = nil,
    m_Condor2 = nil,
    m_Condor3 = nil,
    m_Condor4 = nil,
    m_Cave = nil,
    m_Transmitter = nil,
    m_Recycler = nil,
    m_sRecycler = nil,
    m_ConvoyScav1 = nil,
    m_ConvoyScav2 = nil,
    m_ConvoySent1 = nil,
    m_ConvoySent2 = nil,
    m_ConvoyWar1 = nil,
    m_ConvoyWar2 = nil,
    m_Turret1 = nil,
    m_Turret2 = nil,
    m_CPool1 = nil,
    m_CPool2 = nil,
    m_Guardian1 = nil,
    m_Guardian2 = nil,
    m_Guardian3 = nil,
    m_Guardian4 = nil,
    m_Guardian5 = nil,
    m_Scout1 = nil,
    m_Scout2 = nil,
    m_Scout3 = nil,
    m_Scout4 = nil,
    m_Nav1 = nil,
    m_Nav2 = nil,
    m_BomberBay = nil,
    m_Bomber = nil,
    m_Ruin1 = nil,
    m_Ruin2 = nil,
    m_Ruin3 = nil,
    m_Ruin4 = nil,
    m_CenterRuin = nil,
    m_WarriorTarget = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_DropshipBrainActive = false,
    m_ScionBrainActive = false,
    m_PlayerClear = false,
    m_Condor1Away = false,
    m_Condor2Away = false,
    m_Condor3Away = false,
    m_Condor4Landed = false,
    m_Condor1Removed = false,
    m_Condor2Removed = false,
    m_Condor3Removed = false,
    m_ScionRecyclerFound = false,
    m_ScionRecyclerKeepMoving = false,
    m_ScionRecyclerMessagePlayed = false,
    m_CaveFirst = false,
    m_ConvoyDone = false,
    m_Guardian1Sent = false,
    m_Guardian2Sent = false,
    m_Guardian3Sent = false,
    m_Guardian4Sent = false,
    m_Guardian5Sent = false,
    m_BomberBayBuilt = false,
    m_PlayerThroughCave = false,
    m_ReturnMessagePlayed = false,
    m_WarriorsAttack = false,
    m_SignalWarningActive = false,
    m_CityWarningActive = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_ConvoyTime = 0,
    m_Condor1Time = 0,
    m_Condor2Time = 0,
    m_Condor3Time = 0,
    m_Condor4Time = 0,
    m_TurretDistpacherTimer = 0,
    m_PlayerCaveCheckTimer = 0,
    m_ReturnTimer = 0,
    m_WaterCheckCounter = 0,
    m_TransmissionSearchMessageCounter = 0,
    m_CondorRemoveTime = 15,
    m_WarningCount = 0,
    m_WarningTimer = 0,

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
    -- Grab the team of the object.
    local team = GetTeamNum(h);
    local odf = GetCfg(h);

    -- Handle unit skill for enemy.
    if (team == Mission.m_EnemyTeam or team == 7) then
        SetSkill(h, Mission.m_MissionDifficulty);

        -- Don't check this until the first state is complete. That way, we won't use pre-placed turrets.
        if (odf == "fvturr_x" and Mission.m_MissionState > 1) then
            -- Try and prevent the AIP from using it.
            SetIndependence(h, 1);

            -- Check to see if the turrets are on Team 7 before assigning them to a handle.
            if (team == 7) then
                if (Mission.m_Guardian1 == nil) then
                    Mission.m_Guardian1 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_Guardian1Sent = false;
                elseif (Mission.m_Guardian2 == nil) then
                    Mission.m_Guardian2 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_Guardian2Sent = false;
                elseif (Mission.m_Guardian3 == nil) then
                    Mission.m_Guardian3 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_Guardian3Sent = false;
                elseif (Mission.m_Guardian4 == nil) then
                    Mission.m_Guardian4 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_Guardian4Sent = false;
                elseif (Mission.m_Guardian5 == nil) then
                    Mission.m_Guardian5 = h;

                    -- This will tell the Scion brain to send the turret back to the right path.
                    Mission.m_Guardian5Sent = false;
                end
            end
        end
    elseif (team < Mission.m_AlliedTeam and team > 0) then
        SetSkill(h, 3);

        -- Check to see if the bomber bay has been built.
        if (Mission.m_BomberBayBuilt == false) then
            if (odf == "ibbomb_x") then
                -- Make it unkillable.
                SetMaxHealth(h, 0);

                -- So we can advance on the mission.
                Mission.m_BomberBayBuilt = true;

                -- Store the handle.
                Mission.m_BomberBay = h;
            end
        end

        -- Assign our bomber to this.
        if (odf == "ivbomb_x") then
            -- Make it unkillable.
            SetMaxHealth(h, 0);

            -- Store the handle.
            Mission.m_Bomber = h;
        end
    end
end

function DeleteObject(h)
    if (h == Mission.m_Guardian1) then
        Mission.m_Guardian1 = nil;
    elseif (h == Mission.m_Guardian2) then
        Mission.m_Guardian2 = nil;
    elseif (h == Mission.m_Guardian3) then
        Mission.m_Guardian3 = nil;
    elseif (h == Mission.m_Guardian4) then
        Mission.m_Guardian4 = nil;
    elseif (h == Mission.m_Guardian5) then
        Mission.m_Guardian5 = nil;
    end

    -- Just for testing.
    if (GetTeamNum(h) == Mission.m_EnemyTeam) then
        local cfg = GetCfg(h);

        if (cfg == "bbruin05") then
            -- Damage any nearby ruins with the bomb blast.
            if (IsAround(Mission.m_Ruin1)) then
                Damage(Mission.m_Ruin1, 6000);
            end

            if (IsAround(Mission.m_Ruin2)) then
                Damage(Mission.m_Ruin2, 6000);
            end

            if (IsAround(Mission.m_Ruin3)) then
                Damage(Mission.m_Ruin3, 6000);
            end

            if (IsAround(Mission.m_Ruin4)) then
                Damage(Mission.m_Ruin4, 6000);
            end
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

    -- Call generic start logic in coop.
    _Cooperative.Start(m_MissionName, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, Mission.m_IsCooperativeMode);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;
end

function Update()
    -- This checks to see if the game is ready.
    if (Mission.m_IsCooperativeMode) then
        _Cooperative.Update();
    end

    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Start mission logic.
    if (not Mission.m_MissionOver and (Mission.m_IsCooperativeMode == false or _Cooperative.GetGameReadyStatus())) then
        if (Mission.m_StartDone) then
            -- BZCC introduced a hypothermia mechanic here. Replicate it.
            Mission.m_WaterCheckCounter = Mission.m_WaterCheckCounter + 1;

            -- For each player in the mission, check their location and if they are under water.
            for i = 1, _Cooperative.GetTotalPlayers() do
                -- Grab the player handle.
                local p = GetPlayerHandle(i);

                -- Check the timer.
                if (Mission.m_WaterCheckCounter % SecondsToTurns(0.5) == 0 and IsPerson(p)) then
                    -- Grab the position of the player.
                    local pos = GetPosition(p);

                    -- Check if the terrain is water.
                    if (TerrainIsWater(pos)) then
                        -- Testing, not sure if Lua will like this.
                        local waterHeight = 0;

                        -- Check to see if this assigns the right variables.
                        waterHeight = GetTerrainHeightAndNormal(pos, true);

                        -- Grab the height of the terrain.
                        local terrainHeight = TerrainFindFloor(pos.x, pos.z);

                        -- Check if the player is under water.
                        if (waterHeight > terrainHeight and pos.y < (waterHeight - 10)) then
                            -- Kill the player.
                            SelfDamage(p, 20);
                        end
                    end
                end
            end

            -- Check failure conditions over everything else.
            if (Mission.m_MissionState > 1) then
                HandleFailureConditions();
            end

            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Dropship Brain.
            if (Mission.m_DropshipBrainActive) then
                DropshipBrain();
            end

            -- Convoy brain.
            if (Mission.m_ScionBrainActive) then
                ScionBrain();
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
    if (Mission.m_MissionDifficulty > 1) then
        if (GetCfg(VictimHandle) == "fvturr_x" and (OrdnanceTeam ~= Mission.m_EnemyTeam and OrdnanceTeam ~= 7)) then
            if (GetCurrentCommand(VictimHandle) ~= AiCommand.CMD_DEFEND) then
                Defend(VictimHandle);
            end
        end
    end

    -- Check to see if the Matriarch has been shot, target the attacker.
    if (Mission.m_WarriorsAttack == false and VictimHandle == Mission.m_sRecycler) then
        -- Set the handle to a target.
        Mission.m_WarriorTarget = ShooterHandle;

        -- Send the Warriors after it.
        Attack(Mission.m_ConvoyWar1, ShooterHandle);
        Attack(Mission.m_ConvoyWar2, ShooterHandle);

        -- So we can activate a part of the brain that redirects the Warriors after they have attacked the target.
        Mission.m_WarriorsAttack = true;
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(7, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Unique to this mission. We want two Scion Recyclers, so we are allying Teams 6 and 7.
    Ally(Mission.m_EnemyTeam, 7);

    -- Clean up any player spawns that haven't been taken by the player.
    _Cooperative.CleanSpawns();

    -- Grab all of our pre-placed handles.
    Mission.m_Condor1 = GetHandle("condor1");
    Mission.m_Condor2 = GetHandle("condor2");
    Mission.m_Condor3 = GetHandle("condor3");
    Mission.m_Recycler = GetHandle("recycler");
    Mission.m_sRecycler = GetHandle("srecycler");
    Mission.m_ConvoySent1 = GetHandle("sent1");
    Mission.m_ConvoySent2 = GetHandle("sent2");
    Mission.m_ConvoyWar1 = GetHandle("war1");
    Mission.m_ConvoyWar2 = GetHandle("war2");
    Mission.m_ConvoyScav1 = GetHandle("convoy_scav1");
    Mission.m_ConvoyScav2 = GetHandle("convoy_scav2");
    Mission.m_Cave = GetHandle("cave");
    Mission.m_Transmitter = GetHandle("transmitter");
    Mission.m_Turret1 = GetHandle("ivturr1");
    Mission.m_Turret2 = GetHandle("ivturr2");
    Mission.m_CPool1 = GetHandle("cpool1");
    Mission.m_CPool2 = GetHandle("cpool2");
    Mission.m_Scout1 = GetHandle("start_scout1");
    Mission.m_Scout2 = GetHandle("start_scout2");
    Mission.m_Scout3 = GetHandle("start_scout3");
    Mission.m_Scout4 = GetHandle("start_scout4");
    Mission.m_CenterRuin = GetHandle("center_ruin");
    Mission.m_Ruin1 = GetHandle("ruin1");
    Mission.m_Ruin2 = GetHandle("ruin2");
    Mission.m_Ruin3 = GetHandle("ruin3");
    Mission.m_Ruin4 = GetHandle("ruin4");

    -- Give scrap to all teams that need it.
    AddScrap(Mission.m_HostTeam, 40);
    AddScrap(Mission.m_EnemyTeam, 40);
    AddScrap(7, 40);

    -- For all of our coop players...
    for i = 1, _Cooperative.GetTotalPlayers() do
        Mission.m_Holders[#Mission.m_Holders + 1] = BuildObject("stayput", 0, GetPlayerHandle(i));
    end

    -- Give the first AI some stuff to do.
    SetAIP("isdf1001_x.aip", Mission.m_EnemyTeam);

    -- Let's have the convoy get ready in formation.
    Follow(Mission.m_ConvoyScav1, Mission.m_sRecycler);
    Follow(Mission.m_ConvoyScav2, Mission.m_ConvoyScav1);

    -- Start Engines for Condor 2.
    StartEmitter(Mission.m_Condor2, 1);
    StartEmitter(Mission.m_Condor2, 2);

    -- Mask the emitter for Condor 1 and 3.
    MaskEmitter(Mission.m_Condor1, 0);

    -- Start the animations.
    SetAnimation(Mission.m_Condor1, "deploy", 1);
    SetAnimation(Mission.m_Condor2, "takeoff", 1);

    -- So we can remove it after it's time.
    Mission.m_Condor2Away = true;

    -- Kill the third dropship if we are not in coop mode.
    if (_Cooperative.GetTotalPlayers() < 2) then
        -- Remove it safely.
        RemoveObject(Mission.m_Condor3);
        -- So we don't run the logic for the third Condor in the brain function.
        Mission.m_Condor3Away = true;
        Mission.m_Condor3Removed = true;
    else
        MaskEmitter(Mission.m_Condor3, 0);
        SetAnimation(Mission.m_Condor3, "deploy", 1);
    end

    -- Give the Condor a sound.
    StartSoundEffect("dropleav.wav", Mission.m_Condor2);

    -- Do the fade in if we are not in coop mode.
    if (not Mission.m_IsCooperativeMode) then
        SetColorFade(1, 0.5, Make_RGB(0, 0, 0, 255));
    end

    -- Don't let the cave die.
    SetMaxHealth(Mission.m_Cave, 0);

    -- Don't let the transmitter die.
    SetMaxHealth(Mission.m_Transmitter, 0);

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2.5);

    -- Timer for the convoy:
    Mission.m_ConvoyTime = Mission.m_MissionTime + SecondsToTurns(m_ConvoyTime[Mission.m_MissionDifficulty]);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    -- This will remove the holders from the players.
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Remove all holders from the players.
        for i = 1, #Mission.m_Holders do
            RemoveObject(Mission.m_Holders[i]);
        end

        StartSoundEffect("dropdoor.wav", Mission.m_Condor1);

        if (_Cooperative.GetTotalPlayers() > 1) then
            StartSoundEffect("dropdoor.wav", Mission.m_Condor3);
        end

        -- Have the turrets follow the first player.
        Goto(Mission.m_Turret1, "turret_1_go", 0);
        Goto(Mission.m_Turret2, "turret_2_go", 0);

        -- Set the timer for when we remove the dropship.
        Mission.m_Condor2Time = Mission.m_MissionTime + SecondsToTurns(Mission.m_CondorRemoveTime);

        -- Activate the dropship brain.
        Mission.m_DropshipBrainActive = true;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    -- This will monitor the convoy.
    if (Mission.m_ScionBrainActive == false and Mission.m_ConvoyTime < Mission.m_MissionTime) then
        -- Send the Matriarch on it's way.
        Retreat(Mission.m_sRecycler, "convoy_path");

        -- Have the guards follow.
        Defend2(Mission.m_ConvoySent1, Mission.m_sRecycler);
        Defend2(Mission.m_ConvoySent2, Mission.m_ConvoySent1);
        Defend2(Mission.m_ConvoyWar1, Mission.m_sRecycler);
        Defend2(Mission.m_ConvoyWar2, Mission.m_ConvoyWar1);

        -- Activate the brain for the convoy.
        Mission.m_ScionBrainActive = true;
    end

    -- This will check to see if the player goes to the cave before the convoy reaches it.
    if (Mission.m_CaveFirst == false and IsPlayerWithinDistance(Mission.m_Cave, 150, _Cooperative.GetTotalPlayers())) then
        -- Shabayev: "That looks like the cave."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1109.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- So we don't loop.
        Mission.m_CaveFirst = true;
    elseif (Mission.m_ScionRecyclerMessagePlayed and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "Alright Cooke, check it out!";
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1142.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    -- This checks to see if the Scion Recycler has been killed.
    if (IsAround(Mission.m_sRecycler) == false) then
        -- Braddock: "Good work. Get a bomber built and await orders..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1141.wav");

        -- Set the audio timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

        -- We can remove the highlight from the nav.
        if (IsAround(Mission.m_Nav2)) then
            SetObjectiveOff(Mission.m_Nav2);
        end

        -- Show objectives for bomber bay.
        AddObjectiveOverride("isdf1105.otf", "WHITE", 10, true);
        AddObjective("isdf1102.otf", "WHITE");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- This will advance the mission once the bomber has been built.
    if (Mission.m_BomberBayBuilt and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Show objectives for bomber bay.
        AddObjectiveOverride("isdf1105.otf", "GREEN", 10, true);
        AddObjective("isdf1102.otf", "WHITE");

        -- Shabayev: "Good work Cooke."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1120.wav");

        -- Set the audio timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shabayev: "Can you hear me Cooke? General?"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1121.wav");

        -- Set the audio timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock: "Cooke. I need you to find that signal."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1122.wav");

        -- Set the audio timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shabayev: "You'll need to go through the cave to get to it."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1123.wav");

        -- AI will stop building and attacking.
        SetAIP("isdf1003_x.aip", Mission.m_EnemyTeam);

        -- Set the audio timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (Mission.m_TransmissionSearchMessageCounter == 0 and IsPlayerWithinDistance(Mission.m_CenterRuin, 600, _Cooperative.GetTotalPlayers())) then
            -- Shabayev: "You're close..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1117.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- Highlight the building.
            SetObjectiveName(Mission.m_CenterRuin, "Signal Source");

            -- Highlight it.
            SetObjectiveOn(Mission.m_CenterRuin);

            -- Advance the state.
            Mission.m_TransmissionSearchMessageCounter = Mission.m_TransmissionSearchMessageCounter + 1;
        elseif (Mission.m_TransmissionSearchMessageCounter == 1 and IsPlayerWithinDistance(Mission.m_CenterRuin, 500, _Cooperative.GetTotalPlayers())) then
            -- Shabayev: "You're coming up on the signal"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1125.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- Advance the state.
            Mission.m_TransmissionSearchMessageCounter = Mission.m_TransmissionSearchMessageCounter + 1;
        elseif (Mission.m_TransmissionSearchMessageCounter == 2 and IsPlayerWithinDistance(Mission.m_CenterRuin, 400, _Cooperative.GetTotalPlayers())) then
            -- Shabayev: "What?... Proceed with caution!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1126.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Activate the warning.
            Mission.m_CityWarningActive = true;

            -- Set a timer so the player is scolded.
            Mission.m_WarningTimer = Mission.m_MissionTime + SecondsToTurns(30);

            -- Advance the state.
            Mission.m_TransmissionSearchMessageCounter = Mission.m_TransmissionSearchMessageCounter + 1;
        elseif (Mission.m_TransmissionSearchMessageCounter == 3 and IsPlayerWithinDistance(Mission.m_CenterRuin, 200, _Cooperative.GetTotalPlayers())) then
            -- Shabayev: "Looks like a big fight has already happened..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1108.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Advance the state.
            Mission.m_TransmissionSearchMessageCounter = Mission.m_TransmissionSearchMessageCounter + 1;
        elseif (Mission.m_TransmissionSearchMessageCounter == 4 and IsPlayerWithinDistance(Mission.m_CenterRuin, 100, _Cooperative.GetTotalPlayers())) then
            -- Braddock: "The source of that transmission is in the center!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1129.wav");

            -- Reset the warning counter for the next one.
            Mission.m_WarningCount = 0;
            Mission.m_SignalWarningActive = true;
            Mission.m_CityWarningActive = false;

            -- Set a timer so the player is scolded.
            Mission.m_WarningTimer = Mission.m_MissionTime + SecondsToTurns(30);

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Advance the state.
            Mission.m_TransmissionSearchMessageCounter = Mission.m_TransmissionSearchMessageCounter + 1;
        elseif (Mission.m_TransmissionSearchMessageCounter == 5 and IsPlayerWithinDistance(Mission.m_Transmitter, 40, _Cooperative.GetTotalPlayers())) then
            -- Shabayev: "You're over the signal!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1132.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- De-activate the warning.
            Mission.m_SignalWarningActive = false;

            -- Remove the highlight.
            SetObjectiveOff(Mission.m_CenterRuin);

            -- Send the bomber pre-maturely.
            Goto(Mission.m_Bomber, Mission.m_CenterRuin, 1);

            -- Advance the state.
            Mission.m_TransmissionSearchMessageCounter = Mission.m_TransmissionSearchMessageCounter + 1;
        elseif (Mission.m_TransmissionSearchMessageCounter == 6) then
            -- Braddock: "We've seen enough. Liberator 1, bomb that building."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1133.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

            -- Advance the state.
            Mission.m_TransmissionSearchMessageCounter = Mission.m_TransmissionSearchMessageCounter + 1;
        elseif (Mission.m_TransmissionSearchMessageCounter == 7) then
            -- Bomber: "Roger that sir."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1134.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Set the number of the building to the enemy team.
            SetTeamNum(Mission.m_CenterRuin, Mission.m_EnemyTeam);

            -- Send the Bomber to attack it.
            Attack(Mission.m_Bomber, Mission.m_CenterRuin);

            -- Advance the state.
            Mission.m_TransmissionSearchMessageCounter = Mission.m_TransmissionSearchMessageCounter + 1;
        elseif (Mission.m_TransmissionSearchMessageCounter == 8) then
            -- Braddock: "I would relocate if I were you Cooke."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1135.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Small delay before Shabayev goes crazy.
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5);

            -- Advance the state.
            Mission.m_TransmissionSearchMessageCounter = Mission.m_TransmissionSearchMessageCounter + 1;
        elseif (Mission.m_TransmissionSearchMessageCounter == 9) then
            -- Shabayev: "General, what are you doing?"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1136.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

            -- Show objectives.
            AddObjectiveOverride("isdf1109.otf", "WHITE", 10, true);

            -- Allow the transmitter to die.
            SetMaxHealth(Mission.m_Transmitter, 100);
            SetCurHealth(Mission.m_Transmitter, 100);

            -- Rename the Recycler.
            SetObjectiveName(Mission.m_Recycler, "Base");

            -- Highlight it.
            SetObjectiveOn(Mission.m_Recycler);

            -- Advance the state.
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[10] = function()
    -- This handles the cave collapsing.
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Small delay so we don't check the distance each frame.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

        if (IsPlayerWithinDistance("bridge_center", 250, _Cooperative.GetTotalPlayers())) then
            -- Replace the cave with the variant that falls.
            Mission.m_Cave = ReplaceObject(Mission.m_Cave, "betunna0");

            -- Shab: "Get back, that cave is unstable!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1137.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Earthquake!
            StartEarthQuake(15);

            -- Do the animation.
            SetAnimation(Mission.m_Cave, "crumble", 1);

            -- Added extra sound to make the impact more beefy.
            StartSoundEffect("xcollapse.wav", Mission.m_Cave);

            -- This sets a timer for the next voice.
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(10);

            -- Advance the state.
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[11] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Shab: "General, your actions have left my man stranded..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1138.wav");

        -- Set the audio timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- So we are not constantly playing it.
        StopEarthQuake();

        -- Remove the highlight of the Recycler.
        SetObjectiveOff(Mission.m_Recycler);

        -- Advance the state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock: "Stand down, I know what I'm doing..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1139.wav");

        -- Set the audio timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- Show objectives.
        AddObjectiveOverride("isdf1110.otf", "WHITE", 10, true);

        -- Create a nav at the dust-off site.
        Mission.m_Nav1 = BuildObject("ibnav", Mission.m_HostTeam, "last_nav_point");

        -- Set the name.
        SetObjectiveName(Mission.m_Nav1, "Dust Site");

        -- Highlight it.
        SetObjectiveOn(Mission.m_Nav1);

        -- Activate the dropship brain.
        Mission.m_DropshipBrainActive = true;

        -- This is just so we spawn the Dropship in the right direction.
        local vectorPos = GetPosition("condor_spawn");
        local vectorDir = SetVector(0, 0, -1);

        -- Create a Dropship so it will land.
        Mission.m_Condor4 = BuildObject("ivdrop_land_x", Mission.m_HostTeam, BuildDirectionalMatrix(vectorPos, vectorDir));

        -- Show the engine FX.
        StartEmitter(Mission.m_Condor4, 1);
        StartEmitter(Mission.m_Condor4, 2);

        -- Have it land.
        SetAnimation(Mission.m_Condor4, "land", 1);

        -- For replacement in the brain function so it can open doors.
        Mission.m_Condor4Time = Mission.m_MissionTime + SecondsToTurns(14);

        -- Advance the state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    if (IsPlayerWithinDistance(Mission.m_Nav1, 60, _Cooperative.GetTotalPlayers())) then
        -- Braddock: "Good work solider."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1106.wav");

        -- Set the audio timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Show objectives.
        AddObjectiveOverride("isdf1110.otf", "GREEN", 10, true);

        -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(5);
        else
            SucceedMission(GetTime() + 5, "isdf11w1.txt");
        end

        -- So we don't loop.
        Mission.m_MissionOver = true;
    end
end

function HandleFailureConditions()
    -- If the player goes through the cave before the bomber is built, warn them.
    if (Mission.m_BomberBayBuilt == false) then
        if (Mission.m_PlayerCaveCheckTimer < Mission.m_MissionTime) then
            -- So we don't do this every turn as it can be expensive.
            Mission.m_PlayerCaveCheckTimer = Mission.m_MissionTime + SecondsToTurns(1);

            -- This could be expensive...
            for i = 1, _Cooperative.GetTotalPlayers() do
                local p = GetPlayerHandle(i);

                -- Distance to see if this player is naughty.
                Mission.m_PlayerThroughCave = (GetDistance(p, "cave_2") < GetDistance(p, "cave_1"));

                -- We can reset these values for the next iteration.
                if (Mission.m_PlayerThroughCave == false) then
                    Mission.m_ReturnMessagePlayed = false;
                end
            end
        end

        -- This will have Braddock yell if a player has gone through the cave too early.
        if (Mission.m_PlayerThroughCave) then
            if (Mission.m_ReturnMessagePlayed == false and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                -- Braddock: "Get your ass back to base!".
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1107.wav");

                -- Timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

                -- So we can time the player if they are still being a problem.
                Mission.m_ReturnTimer = Mission.m_MissionTime + SecondsToTurns(120);

                -- So we don't loop.
                Mission.m_ReturnMessagePlayed = true;
            elseif (Mission.m_ReturnMessagePlayed and Mission.m_ReturnTimer < Mission.m_MissionTime) then
                -- Stop the mission.
                Mission.m_MissionOver = true;

                -- Stop all audio.
                StopAudioMessage(Mission.m_Audioclip);

                -- Reset the timer.
                Mission.m_AudioTimer = 0;

                -- Shab: "You're dismissed."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1110.wav");

                -- Failure.
                if (Mission.m_IsCooperativeMode) then
                    NoteGameoverWithCustomMessage("You failed to follow the orders of your commanding officer!");
                    DoGameover(10);
                else
                    FailMission(GetTime() + 10, "isdf01l2.txt");
                end
            end
        end
    end

    -- This is if the player takes too long to scan for the signal source.
    if ((Mission.m_CityWarningActive or Mission.m_SignalWarningActive) and Mission.m_WarningTimer < Mission.m_MissionTime) then
        -- Set a timer so the player is scolded.
        Mission.m_WarningTimer = Mission.m_MissionTime + SecondsToTurns(30);

        -- Check the amount of warnings.
        if (Mission.m_WarningCount == 0) then
            -- Braddock: "Get the lead out son, I want that city searched!"
            if (Mission.m_CityWarningActive) then
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1127.wav");
            elseif (Mission.m_SignalWarningActive) then
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1130.wav");
            end

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);
        elseif (Mission.m_WarningCount == 1) then
            -- Braddock: "This is your last warning..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1131.wav");

            -- Set the audio timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
        else
            -- Stop the mission.
            Mission.m_MissionOver = true;

            -- Stop all audio.
            StopAudioMessage(Mission.m_Audioclip);

            -- Reset the timer.
            Mission.m_AudioTimer = 0;

            -- Shab: "You're dismissed."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1110.wav");

            -- Failure.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("You failed to follow the orders of your commanding officer!");
                DoGameover(10);
            else
                FailMission(GetTime() + 10, "isdf01l2.txt");
            end
        end

        -- Advance the warning count.
        Mission.m_WarningCount = Mission.m_WarningCount + 1;
    end

    if (IsAlive(Mission.m_Recycler) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Recycler was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf10l1.txt");
        end
    end
end

function DropshipBrain()
    -- Stop the brain once all starting Condors are gone.
    if (Mission.m_Condor1Removed and Mission.m_Condor2Removed and Mission.m_Condor3Removed and Mission.m_MissionState < 12) then
        Mission.m_DropshipBrainActive = false;
    end

    -- This checks to remove the dropships.
    if (Mission.m_Condor1Away and Mission.m_Condor1Time < Mission.m_MissionTime) then
        -- Remove the Dropship.
        RemoveObject(Mission.m_Condor1);

        -- Mark this as done.
        Mission.m_Condor1Removed = true;
    end

    if (Mission.m_Condor2Away and Mission.m_Condor2Time < Mission.m_MissionTime) then
        -- Remove the Dropship.
        RemoveObject(Mission.m_Condor2);

        -- Mark this as done.
        Mission.m_Condor2Removed = true;
    end

    if (Mission.m_Condor3Away and Mission.m_Condor3Time < Mission.m_MissionTime) then
        -- Remove the Dropship.
        RemoveObject(Mission.m_Condor3);

        -- Mark this as done.
        Mission.m_Condor3Removed = true;
    end

    -- Check and make sure all players are clear of the dropships so we can fly away.
    if (Mission.m_Condor1Away == false) then
        if (Mission.m_PlayerClear == false) then
            if (IsPlayerWithinDistance(Mission.m_Condor1, 40, _Cooperative.GetTotalPlayers()) == false) then
                -- This will play Shabayev's first dialog.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1101.wav");

                -- Timer for this audio.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

                -- Send our scouts to attack if they are still alive.
                if (IsAliveAndEnemy(Mission.m_Scout1, Mission.m_EnemyTeam)) then
                    Goto(Mission.m_Scout1, "attack_path1")
                end

                if (IsAliveAndEnemy(Mission.m_Scout2, Mission.m_EnemyTeam)) then
                    Goto(Mission.m_Scout2, "attack_path1")
                end

                -- Show objectives.
                AddObjective("isdf1101.otf", "WHITE");
                AddObjective("isdf1102.otf", "WHITE");

                -- We are clear.
                Mission.m_PlayerClear = true;
            end
        elseif (GetDistance(Mission.m_Turret1, "condor_center") > 20 and GetDistance(Mission.m_Turret2, "condor_center") > 20) then
            -- Start the take-off sequence.
            SetAnimation(Mission.m_Condor1, "takeoff", 1);

            -- Engine sound.
            StartSoundEffect("dropleav.wav", Mission.m_Condor1);

            -- Start the emitters.
            StartEmitter(Mission.m_Condor1, 1);
            StartEmitter(Mission.m_Condor1, 2);

            -- Set the timer for when we remove the dropship.
            Mission.m_Condor1Time = Mission.m_MissionTime + SecondsToTurns(Mission.m_CondorRemoveTime);

            -- So we don't loop.
            Mission.m_Condor1Away = true;
        end
    end

    if (Mission.m_Condor3Away == false) then
        if (IsPlayerWithinDistance(Mission.m_Condor3, 40, _Cooperative.GetTotalPlayers()) == false) then
            -- Start the take-off sequence.
            SetAnimation(Mission.m_Condor3, "takeoff", 1);

            -- Engine sound.
            StartSoundEffect("dropleav.wav", Mission.m_Condor3);

            -- Start the emitters.
            StartEmitter(Mission.m_Condor3, 1);
            StartEmitter(Mission.m_Condor3, 2);

            -- Set the timer for when we remove the dropship.
            Mission.m_Condor3Time = Mission.m_MissionTime + SecondsToTurns(Mission.m_CondorRemoveTime);

            -- So we don't loop.
            Mission.m_Condor3Away = true;
        end
    end

    -- This will replace the last dropship with the correct one.
    if (Mission.m_Condor4Time < Mission.m_MissionTime and Mission.m_MissionState > 12) then
        if (Mission.m_Condor4Landed == false) then
            -- Replace it and open the doors.
            Mission.m_Condor4 = ReplaceObject(Mission.m_Condor4, "ivpdrop_x");

            -- Mask the emitter for Condor 4.
            MaskEmitter(Mission.m_Condor4, 0);

            -- Open the doors.
            SetAnimation(Mission.m_Condor4, "deploy", 1);

            -- Slight delay for the sound.
            Mission.m_Condor4Time = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- So we don't loop.
            Mission.m_Condor4Landed = true;
        else
            -- Play the door sound effect.
            StartSoundEffect("dropdoor.wav", Mission.m_Condor4);

            -- So we don't run anymore.
            Mission.m_DropshipBrainActive = false;
        end
    end
end

function ScionBrain()
    -- Use this to dispatch the turrets.
    if (Mission.m_TurretDistpacherTimer < Mission.m_MissionTime) then
        if (Mission.m_Guardian1Sent == false and IsAliveAndEnemy(Mission.m_Guardian1, 7)) then
            Goto(Mission.m_Guardian1, "sturret_point1", 1);

            -- So we don't loop.
            Mission.m_Guardian1Sent = true;
        end

        if (Mission.m_Guardian2Sent == false and IsAliveAndEnemy(Mission.m_Guardian2, 7)) then
            Goto(Mission.m_Guardian2, "sturret_point2", 1);

            -- So we don't loop.
            Mission.m_Guardian2Sent = true;
        end

        if (Mission.m_Guardian3Sent == false and IsAliveAndEnemy(Mission.m_Guardian3, 7)) then
            Goto(Mission.m_Guardian3, "sturret_point3", 1);

            -- So we don't loop.
            Mission.m_Guardian3Sent = true;
        end

        if (Mission.m_Guardian4Sent == false and IsAliveAndEnemy(Mission.m_Guardian4, 7)) then
            Goto(Mission.m_Guardian4, "sturret_point4", 1);

            -- So we don't loop.
            Mission.m_Guardian4Sent = true;
        end

        if (Mission.m_Guardian5Sent == false and IsAliveAndEnemy(Mission.m_Guardian5, 7)) then
            Goto(Mission.m_Guardian5, "forward_guard", 1);

            -- So we don't loop.
            Mission.m_Guardian5Sent = true;
        end

        -- To delay loops.
        Mission.m_TurretDistpacherTimer = Mission.m_MissionTime + SecondsToTurns(1.5);
    end

    -- Redirect the convoy Warriors once they have destroyed their target.
    if (Mission.m_WarriorsAttack and IsAlive(Mission.m_WarriorTarget) == false) then
        -- Rinse and repeat.
        if (IsAround(Mission.m_sRecycler)) then
            Defend2(Mission.m_ConvoyWar1, Mission.m_sRecycler);
            Defend2(Mission.m_ConvoyWar2, Mission.m_sRecycler);
        else
            Attack(Mission.m_ConvoyWar1, Mission.m_Recycler);
            Attack(Mission.m_ConvoyWar2, Mission.m_Recycler);
        end

        -- If the Matriarch is still alive, we can go and defend again. If not, go to the Recycler instead.
        Mission.m_WarriorsAttack = false;
    end

    if (Mission.m_ConvoyDone == false and Mission.m_ConvoyTime < Mission.m_MissionTime) then
        -- As per the 1.3 DLL, check this every 3 turns.
        Mission.m_ConvoyTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Check to see when the convoy has reached the cave.
        if (Mission.m_ScionRecyclerMessagePlayed == false and GetDistance(Mission.m_sRecycler, "bridge_center") < 100) then
            -- Objectives.
            AddObjectiveOverride("isdf1103.otf", "WHITE", 10, true);
            AddObjective("isdf1102.otf", "WHITE");

            if (IsPlayerWithinDistance(Mission.m_sRecycler, 150, _Cooperative.GetTotalPlayers()) == false) then
                -- This checks to see if the player has found the cave before the convoy.
                if (Mission.m_CaveFirst) then
                    -- Braddock: "Detecting a Scion Recycler moving into the cave."
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1102.wav");

                    -- Timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);
                else
                    -- Braddock: "Detecting a Scion Recycler moving into your sector through a cave in the east."
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1103.wav");

                    -- Timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);
                end
            end

            -- Highlight the Scion Recycler.
            SetObjectiveName(Mission.m_sRecycler, "Convoy");

            -- Show it.
            SetObjectiveOn(Mission.m_sRecycler);

            -- So we don't loop.
            Mission.m_ScionRecyclerMessagePlayed = true;
        elseif (Mission.m_ScionRecyclerFound == false) then
            if (IsAliveAndEnemy(Mission.m_Scout3, Mission.m_EnemyTeam)) then
                Goto(Mission.m_Scout3, "attack_path2")
            end

            if (IsAliveAndEnemy(Mission.m_Scout4, Mission.m_EnemyTeam)) then
                Goto(Mission.m_Scout4, "attack_path2")
            end

            if (IsPlayerWithinDistance(Mission.m_sRecycler, 200, _Cooperative.GetTotalPlayers())) then
                -- Remove the highlight from the Scion Recycler.
                SetObjectiveOff(Mission.m_sRecycler);

                -- Show objectives.
                AddObjectiveOverride("isdf1103.otf", "GREEN", 10, true);
                AddObjective("isdf1104.otf", "WHITE");
                AddObjective("isdf1102.otf", "WHITE");

                -- So we don't loop.
                Mission.m_ScionRecyclerFound = true;
            elseif (GetDistance(Mission.m_sRecycler, "deploy_point") < 300) then
                -- Remove the highlight from the Scion Recycler.
                SetObjectiveOff(Mission.m_sRecycler);

                -- Show objectives.
                AddObjectiveOverride("isdf1103.otf", "RED", 10, true);
                AddObjective("isdf1104.otf", "WHITE");
                AddObjective("isdf1102.otf", "WHITE");

                -- So we don't loop.
                Mission.m_ScionRecyclerFound = true;
            end
        elseif (Mission.m_ScionRecyclerKeepMoving == false) then
            -- Have the Scion Recycler carry on down it's path.
            Retreat(Mission.m_sRecycler, "deploy_point");

            -- So we don't loop.
            Mission.m_ScionRecyclerKeepMoving = true;
        elseif (GetDistance(Mission.m_sRecycler, "deploy_point") < 50) then
            -- Stop the brain. Set an AIP for the team.
            SetAIP("isdf1002_x.aip", 7);

            -- This is Braddock saying that they've lost the vehicles.
            if (IsPlayerWithinDistance(Mission.m_sRecycler, 200, _Cooperative.GetTotalPlayers()) == false) then
                -- Braddock: "We've lost the vehicles."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1105.wav");

                -- Timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);
            end

            -- Show objectives.
            AddObjectiveOverride("isdf1104.otf", "WHITE", 10, true);
            AddObjective("isdf1102.otf", "WHITE");

            -- Builds our nav point.
            Mission.m_Nav2 = BuildObject("ibnav", Mission.m_HostTeam, "nav2_point");

            -- Name it "Convoy.
            SetObjectiveName(Mission.m_Nav2, "Convoy");

            -- Highlight it.
            SetObjectiveOn(Mission.m_Nav2);

            -- Stop the convoy escort.
            if (IsAliveAndEnemy(Mission.m_ConvoySent1, 7)) then
                Defend2(Mission.m_ConvoySent1, Mission.m_ConvoyScav1);
            end

            if (IsAliveAndEnemy(Mission.m_ConvoySent2, 7)) then
                Defend2(Mission.m_ConvoySent2, Mission.m_ConvoyScav2);
            end

            if (IsAliveAndEnemy(Mission.m_ConvoyWar1, 7)) then
                Defend(Mission.m_ConvoyWar1);
            end

            if (IsAliveAndEnemy(Mission.m_ConvoyWar2, 7)) then
                Defend(Mission.m_ConvoyWar2);
            end

            -- Send the Scavs to deploy on the pools so we're a bit smarter.
            Goto(Mission.m_ConvoyScav1, Mission.m_CPool1, 1);
            Goto(Mission.m_ConvoyScav2, Mission.m_CPool2, 1);

            -- Stop the brain. Don't need it.
            Mission.m_ConvoyDone = true;
        end
    end
end
