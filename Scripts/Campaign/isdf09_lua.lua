--[[
    BZCC ISDF09 Lua Mission Script
    Written by AI_Unit
    Version 1.0 15-12-2023
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
local m_GameTPS = 20;

-- Name of file.
local fileName = "BZX_BASE_SAVE.txt";

-- Mission Name
local m_MissionName = "ISDF09: Rumble in the Jungle";

-- This will handle the Shabayev sequence based on difficulty.
local m_Shab1Timer = { 240, 180, 120 };
local m_Shab2Timer = { 180, 120, 60 };
local m_Shab3Timer = { 120, 105, 90 };

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

    m_Shabayev = nil,
    m_Manson = nil,
    m_Nav = nil,
    m_Machine = nil,
    m_Crystal = nil,
    m_MainAPC = nil,
    m_Objective = nil,
    m_Ruin = nil,
    m_APCs = {},
    m_ShabAttacker1 = nil,
    m_ShabAttacker2 = nil,
    m_Guardian1 = nil,
    m_Guardian2 = nil,
    m_Guardian3 = nil,
    m_Guardian4 = nil,
    m_Guardian5 = nil,
    m_Guardian6 = nil,

    m_KeyScionUnits = {},

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_BaseFound = false,
    m_MansonNag = false,
    m_APCPilotMsgPlayed = false,
    m_ShabRescued = false,
    m_BotchedRescue = false,
    m_APCPilotIntroPlayed = false,
    m_MansonBaseMsgPlayed = false,
    m_Guardian1Sent = false,
    m_Guardian2Sent = false,
    m_Guardian3Sent = false,
    m_Guardian4Sent = false,
    m_Guardian5Sent = false,
    m_Guardian6Sent = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_MansonIntroSequenceStage = 0,
    m_MansonNagTimer = 0,
    m_ShabTimer = 0,
    m_ShabState = 0,
    m_RuinCam = 0,
    m_TurretDistpacherTimer = 0,

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
    local team = GetTeamNum(h);

    -- Handle unit skill for enemy.
    if (team == Mission.m_EnemyTeam) then
        -- Grab the config.
        local class = GetClassLabel(h);

        SetSkill(h, Mission.m_MissionDifficulty);

        if (class == "CLASS_TURRETTANK" and Mission.m_MissionState > 1) then
            -- Try and prevent the AIP from using it.
            SetIndependence(h, 1);

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
            elseif (Mission.m_Guardian6 == nil) then
                Mission.m_Guardian6 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_Guardian6Sent = false;
            end
        end

        -- This will add units to our Scion tracker. These need to be destroyed.
        if (class == "CLASS_RECYCLER" or class == "CLASS_FACTORY" or class == "CLASS_TURRET" or class == "CLASS_COMMTOWER") then
            Mission.m_KeyScionUnits[#Mission.m_KeyScionUnits + 1] = h;
        end
    elseif (team < Mission.m_AlliedTeam and team > 0) then
        SetSkill(h, 3);

        -- If they are the APC, give them to manson.
        if (Mission.m_BaseFound == false and GetClassLabel(h) == "CLASS_APC") then
            if (IsAlive(Mission.m_MainAPC) == false) then
                Mission.m_MainAPC = h;
            end

            -- Put them on Manson's team for now.
            SetTeamNum(h, Mission.m_AlliedTeam);

            -- Put them in a table.
            Mission.m_APCs[#Mission.m_APCs + 1] = h;
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
    elseif (h == Mission.m_Guardian6) then
        Mission.m_Guardian6 = nil;
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
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            ScionTurretDispatcher();

            -- For the rescue sequence.
            if (Mission.m_ShabRescued == false) then
                ShabayevBrain();
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
        if (GetCfg(VictimHandle) == "fvturr_x" and (OrdnanceTeam ~= Mission.m_EnemyTeam)) then
            if (GetCurrentCommand(VictimHandle) ~= CMD_DEFEND) then
                Defend(VictimHandle);
            end
        end
    end

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
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Grab all of our pre-placed handles.
    Mission.m_Manson = GetHandle("manson");
    Mission.m_Machine = GetHandle("unnamed_mbdata00");
    Mission.m_Crystal = GetHandle("power_crystal");
    Mission.m_Objective = GetHandle("unnamed_fbrecy_x");
    Mission.m_Ruin = GetHandle("ruins");
    Mission.m_Guardian1 = GetHandle("guardian_1");
    Mission.m_Guardian2 = GetHandle("guardian_2");
    Mission.m_Guardian3 = GetHandle("guardian_3");
    Mission.m_Guardian4 = GetHandle("guardian_4");
    Mission.m_Guardian5 = GetHandle("guardian_5");
    Mission.m_Guardian6 = GetHandle("guardian_6");

    -- Build the Nav for Shabayev
    Mission.m_Nav = BuildObject("ibnav", Mission.m_HostTeam, "shab_def_spawn");

    -- Rename the nav to "Shabayev"
    SetObjectiveName(Mission.m_Nav, "Shabayev");

    -- Build Shabayev's pilot.
    Mission.m_Shabayev = BuildObject("isshab_p", Mission.m_HostTeam, "shab_stay");

    -- Highlight Manson.
    SetObjectiveOn(Mission.m_Manson);

    -- This will hold her.
    Patrol(Mission.m_Shabayev, "shab_stay");

    -- Set Manson's team to blue.
    SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);

    -- Show objectives.
    AddObjectiveOverride("isdf0901.otf", "WHITE", 10, true);
    AddObjective("isdf0902.otf", "WHITE");
    AddObjective("isdf0903.otf", "WHITE");

    -- Place the player's old base from the previous mission.
    if (not Mission.m_IsCooperativeMode) then
        PlacePlayerBase();
    end

    -- Give the player some scrap.
    SetScrap(Mission.m_HostTeam, 60);

    -- Defense units.
    BuildObject("fvtank_x", Mission.m_EnemyTeam, "defend1");

    -- Build some patrols.
    Patrol(BuildObject("fvsent_x", Mission.m_EnemyTeam, "defend1"), "defend_patrol");

    Patrol(BuildObject("fvsent_x", Mission.m_EnemyTeam, "fury_patrol1"), "fury_patrol1");
    Patrol(BuildObject("fvsent_x", Mission.m_EnemyTeam, "fury_patrol2"), "fury_patrol2");

    -- Move units to the right position.
    Goto(BuildObject("fvtank_x", Mission.m_EnemyTeam, GetPositionNear("defend1", 25, 25)), "strike2");
    Goto(BuildObject("fvtank_x", Mission.m_EnemyTeam, GetPositionNear("defend1", 25, 25)), "strike2");

    -- Inhabit the swamp with Jaks
    BuildObject("mcjak01", 0, "creature1");
    BuildObject("mcjak01", 0, "creature2");
    BuildObject("mcjak01", 0, "creature3");
    BuildObject("mcjak01", 0, "creature4");
    BuildObject("mcjak01", 0, "creature5");

    SpawnBirds(1, 5, "mcwing01", 0, "birds1");
    SpawnBirds(2, 4, "mcwing01", 0, "birds2");
    SpawnBirds(3, 6, "mcwing01", 0, "birds3");

    -- Have Manson look at the main player.
    LookAt(Mission.m_Manson, GetPlayerHandle(1));

    -- If the player takes 3 minutes, have Manson nag.
    Mission.m_MansonNagTimer = Mission.m_MissionTime + SecondsToTurns(180);

    -- Timer for the Shabayev Sequence.
    Mission.m_ShabTimer = Mission.m_MissionTime + SecondsToTurns(95);

    -- Don't let Manson die.
    SetMaxHealth(Mission.m_Manson, 0);

    -- Set a plan here for the enemy.
    SetAIP("isdf0901_x.aip", Mission.m_EnemyTeam);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Do each of Manson's intro dialogues here.
        if (Mission.m_MansonIntroSequenceStage == 0) then
            -- Manson: "That was very impressive Cooke..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0904.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

            -- Advance the sequence.
            Mission.m_MansonIntroSequenceStage = Mission.m_MansonIntroSequenceStage + 1;
        elseif (Mission.m_MansonIntroSequenceStage == 1) then
            -- Manson: "Cooke has found the base."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0905.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(15.5);

            -- Advance the sequence.
            Mission.m_MansonIntroSequenceStage = Mission.m_MansonIntroSequenceStage + 1;
        elseif (Mission.m_MansonIntroSequenceStage == 2) then
            -- Manson: "Cooke, take a small force..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0906.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(15.5);

            -- Advance the sequence.
            Mission.m_MansonIntroSequenceStage = Mission.m_MansonIntroSequenceStage + 1;
        else
            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[3] = function()
    -- This will check if the player is taking too long.
    if (Mission.m_MansonNag == false and Mission.m_MansonNagTimer < Mission.m_MissionTime) then
        -- Manson: "I thought you knew the position of this base..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0907.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- So we don't loop.
        Mission.m_MansonNag = true;
    end

    -- This will advance the mission state.
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and IsPlayerWithinDistance(Mission.m_Objective, 250, _Cooperative.GetTotalPlayers())) then
        -- Manson: "That's our objective, send in the APCs."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0908.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Grab the first empty group of the player.
        local grp = GetFirstEmptyGroup(Mission.m_HostTeam);
        local team = Mission.m_HostTeam;

        if (grp == nil) then
            -- Check to see if any of the players have a spare group to use instead.
            if (Mission.m_IsCooperativeMode and _Cooperative.GetTotalPlayers() > 1) then
                -- Run a check on each player to see if they have a free group.
                for i = 2, _Cooperative.GetTotalPlayers() do
                    grp = GetFirstEmptyGroup(i);

                    if (grp ~= nil) then
                        -- Set the team for the APCs.
                        team = i;

                        -- Dead.
                        break;
                    end
                end
            end
        end

        print("APC Count: ", #Mission.m_APCs);

        -- Give the APCs to the team.
        for i = 1, #Mission.m_APCs do
            -- Grab the APC.
            local apc = Mission.m_APCs[i];

            print("APC: ", apc);

            -- Safely check if this is populated.
            if (IsAround(apc)) then
                -- Debug
                print("Assigning APC to Team: ", team);
                print("Assigning APC to Group: ", grp);

                -- Set the APC to the right team.
                SetTeamNum(apc, team);

                -- Set the APC to the right group.
                SetGroup(apc, grp);
            end
        end

        -- So we don't loop.
        Mission.m_BaseFound = true;

        -- Show objectives.
        AddObjectiveOverride("isdf0901.otf", "WHITE", 10, true);
        AddObjective("isdf0902.otf", "GREEN");
        AddObjective("isdf0903.otf", "WHITE");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    -- This will do the APC intro.
    if (Mission.m_APCPilotIntroPlayed == false and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Pilot: "This is APC leader..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0910.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- So we don't loop.
        Mission.m_APCPilotIntroPlayed = true;
    end

    -- This will check if the main APC is near the base.
    if (Mission.m_APCPilotMsgPlayed == false and GetDistance(Mission.m_MainAPC, Mission.m_Objective) < 250) then
        -- Pilot: "Cue the band".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0911.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- So we don't loop.
        Mission.m_APCPilotMsgPlayed = true;
    end

    if (IsAround(Mission.m_Objective) == false) then
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    if (Mission.m_MansonBaseMsgPlayed == false and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Manson: "Good work Cooke, clean up that base..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0914.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

        -- Show objectives.
        AddObjectiveOverride("isdf0901.otf", "WHITE", 10, true);
        AddObjective("isdf0902.otf", "GREEN");
        AddObjective("isdf0903.otf", "GREEN");

        -- So we don't loop.
        Mission.m_MansonBaseMsgPlayed = true;
    end

    -- Check that key units are dead before moving on.
    for i = 1, #Mission.m_KeyScionUnits do
        local unit = Mission.m_KeyScionUnits[i];

        -- Unit is alive, return early..
        if (IsAliveAndEnemy(unit, Mission.m_EnemyTeam)) then
            return;
        end
    end

    -- Lastly, check if turrets are dead.
    if (IsAliveAndEnemy(Mission.m_Turret1, Mission.m_EnemyTeam) == false
            and IsAliveAndEnemy(Mission.m_Turret2, Mission.m_EnemyTeam) == false
            and IsAliveAndEnemy(Mission.m_Turret3, Mission.m_EnemyTeam) == false
            and IsAliveAndEnemy(Mission.m_Turret4, Mission.m_EnemyTeam) == false) then
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    if (Mission.m_ShabRescued and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- This is Braddock's big speech.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("cin0601.wav", true);

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(45.5);

        -- Prep the camera if we are not coop.
        if (Mission.m_IsCooperativeMode == false) then
            CameraReady();
        end

        -- Timer.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(20);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (Mission.m_MissionTime < Mission.m_MissionDelayTime) then
        -- So we run the camera.
        if (Mission.m_IsCooperativeMode == false) then
            CameraPath("end_camera_path", 50, 250, Mission.m_Machine);
        end
    else
        -- Timer.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(12);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (Mission.m_MissionTime < Mission.m_MissionDelayTime) then
        -- So we run the camera.
        if (Mission.m_IsCooperativeMode == false) then
            CameraPath("crystal_camera", 400, 0, Mission.m_Crystal);
        end
    else
        -- Give the Camera back.
        if (Mission.m_IsCooperativeMode == false) then
            CameraFinish();
        end

        -- Succeess.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(20);
        else
            SucceedMission(GetTime() + 20, "isdf09w1.txt");
        end

        -- Stop the mission.
        Mission.m_MissionOver = true;
    end
end

function ShabayevBrain()
    -- This checks if a player reaches Shabayev in time.
    if (Mission.m_ShabState < 7 and Mission.m_BotchedRescue == false) then
        -- Run a distance check on each player, see if they are a pilot.
        for i = 1, _Cooperative.GetTotalPlayers() do
            local p = GetPlayerHandle(i);

            if (GetDistance(p, Mission.m_Ruin) < 200) then
                -- Check if they are a person.
                if (IsPerson(p)) then
                    -- Messed up rescue.
                    Mission.m_ShabAttacker1 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "shab_attack");

                    -- Have the enemy attack.
                    Attack(Mission.m_ShabAttacker1, Mission.m_Shabayev, 1);

                    -- Set the state.
                    Mission.m_ShabState = 5;

                    -- So we don't loop.
                    Mission.m_BotchedRescue = true;
                else
                    -- Shab: "Cooke, is that you?"
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0909.wav");

                    -- Timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

                    -- For the rescue part.
                    Mission.m_ShabState = 7;
                end
            end
        end
    end

    if (Mission.m_ShabState == 0) then
        -- For the main player, check if they are clear of enemy forces.
        local temp = GetNearestEnemy(GetPlayerHandle(1), true, true, 100);

        if (temp == nil and Mission.m_ShabTimer < Mission.m_MissionTime) then
            -- "Shab: I need rescuing".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0730.wav");

            -- Put the nav on.
            SetObjectiveOn(Mission.m_Nav);

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

            -- Set the timer for the next part.
            Mission.m_ShabTimer = Mission.m_MissionTime + SecondsToTurns(m_Shab1Timer[Mission.m_MissionDifficulty]);

            -- Get the camera ready.
            if (Mission.m_IsCooperativeMode == false) then
                CameraReady();
            end

            -- Advance the mission state.
            Mission.m_ShabState = Mission.m_ShabState + 1;
        end
    elseif (Mission.m_ShabState == 1) then
        -- Do the camera if we are not in coop.
        if (Mission.m_IsCooperativeMode == false) then
            if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                CameraFinish();

                -- Advance the mission state.
                Mission.m_ShabState = Mission.m_ShabState + 1;
            else
                CameraObject(Mission.m_Shabayev, 25, 2, 8, Mission.m_Shabayev);
            end
        end
    elseif (Mission.m_ShabState == 2) then
        -- Do the next part.
        if (Mission.m_ShabTimer < Mission.m_MissionTime) then
            -- "Shab: Cooke, where are you?".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0903.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- Set the timer for the next part.
            Mission.m_ShabTimer = Mission.m_MissionTime + SecondsToTurns(m_Shab2Timer[Mission.m_MissionDifficulty]);

            -- Advance the mission state.
            Mission.m_ShabState = Mission.m_ShabState + 1;
        end
    elseif (Mission.m_ShabState == 3) then
        if (Mission.m_ShabTimer < Mission.m_MissionTime) then
            -- "Shab: All units! Please assist!".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0733a.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

            -- Set the timer for the next part.
            Mission.m_ShabTimer = Mission.m_MissionTime + SecondsToTurns(m_Shab3Timer[Mission.m_MissionDifficulty]);

            -- Advance the mission state.
            Mission.m_ShabState = Mission.m_ShabState + 1;
        end
    elseif (Mission.m_ShabState == 4) then
        if (Mission.m_ShabTimer < Mission.m_MissionTime) then
            -- Desperate.
            SetTeamNum(Mission.m_Ruin, Mission.m_HostTeam);

            -- Set health.
            SetCurHealth(Mission.m_Ruin, (0.1 * GetMaxHealth(Mission.m_Ruin)));

            -- Build a couple of sentries to attack her.
            Mission.m_ShabAttacker1 = BuildObject("fvsent_x", Mission.m_EnemyTeam, GetPositionNear("shab_attack", 25, 25));
            Mission.m_ShabAttacker2 = BuildObject("fvsent_x", Mission.m_EnemyTeam, GetPositionNear("shab_attack", 25, 25));

            -- Have them attack Shabayev.
            Attack(Mission.m_ShabAttacker1, Mission.m_Shabayev, 1);
            Attack(Mission.m_ShabAttacker2, Mission.m_Shabayev, 1);

            -- Advance the mission state.
            Mission.m_ShabState = Mission.m_ShabState + 1;
        end
    elseif (Mission.m_ShabState == 5) then
        -- Check to see if the enemy is within distance of shabayev.
        if (Mission.m_RuinCam == 0 and GetDistance(Mission.m_ShabAttacker1, Mission.m_Shabayev) < 75 or GetDistance(Mission.m_ShabAttacker2, Mission.m_Shabayev) < 75) then
            -- Shab: "I've been found!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0912.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- Prep the camera if we are not in coop mode.
            if (Mission.m_IsCooperativeMode == false) then
                CameraReady();
            end

            -- Start the Camera timer.
            Mission.m_RuinCam = 1;
        end

        -- Play the camera.
        if (Mission.m_RuinCam > 0) then
            -- Make sure we are not in coop mode.
            if (Mission.m_IsCooperativeMode == false) then
                -- Show Shabayev.
                CameraObject(Mission.m_Shabayev, 20, 6, 12, Mission.m_Shabayev);
            end

            -- Advance the camera.
            Mission.m_RuinCam = Mission.m_RuinCam + 1;

            -- If we reach 75, advance the mission state.
            if (Mission.m_RuinCam == 75) then
                -- Give the camera back if we are not in coop mode.
                if (Mission.m_IsCooperativeMode == false) then
                    CameraFinish();
                end

                -- Advance the mission state.
                Mission.m_ShabState = Mission.m_ShabState + 1;
            end
        end
    elseif (Mission.m_ShabState == 6) then
        -- If Shabayev died.
        if (IsAlive(Mission.m_Shabayev) == false) then
            -- Shab: "They are all over me!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0913.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Fail the mission.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("Shabayev was killed.");
                DoGameover(5);
            else
                FailMission(GetTime() + 5, "isdf09l1.txt");
            end

            -- Just so we don't loop.
            Mission.m_MissionOver = true;
        end
    elseif (Mission.m_ShabState == 7) then
        if (IsPlayerWithinDistance(Mission.m_Shabayev, 30, _Cooperative.GetTotalPlayers())) then
            -- Shab: "We've got to stop meeting like this..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0915.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Remove her and the rescue nav.
            RemoveObject(Mission.m_Shabayev);
            RemoveObject(Mission.m_Nav);

            -- She's rescued.
            Mission.m_ShabRescued = true;
        end
    end
end

function ScionTurretDispatcher()
    -- Use this to dispatch the turrets.
    if (Mission.m_TurretDistpacherTimer < Mission.m_MissionTime) then
        if (Mission.m_Guardian1Sent == false and IsAliveAndEnemy(Mission.m_Guardian1, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian1, "turret1", 1);

            -- So we don't loop.
            Mission.m_Guardian1Sent = true;
        end

        if (Mission.m_Guardian2Sent == false and IsAliveAndEnemy(Mission.m_Guardian2, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian2, "turret2", 1);

            -- So we don't loop.
            Mission.m_Guardian2Sent = true;
        end

        if (Mission.m_Guardian3Sent == false and IsAliveAndEnemy(Mission.m_Guardian3, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian3, "turret3", 1);

            -- So we don't loop.
            Mission.m_Guardian3Sent = true;
        end

        if (Mission.m_Guardian4Sent == false and IsAliveAndEnemy(Mission.m_Guardian4, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian4, "turret4", 1);

            -- So we don't loop.
            Mission.m_Guardian4Sent = true;
        end

        if (Mission.m_Guardian5Sent == false and IsAliveAndEnemy(Mission.m_Guardian5, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian5, "turret5", 1);

            -- So we don't loop.
            Mission.m_Guardian5Sent = true;
        end

        if (Mission.m_Guardian6Sent == false and IsAliveAndEnemy(Mission.m_Guardian6, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian6, "turret6", 1);

            -- So we don't loop.
            Mission.m_Guardian6Sent = true;
        end

        -- To delay loops.
        Mission.m_TurretDistpacherTimer = Mission.m_MissionTime + SecondsToTurns(1.5);
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
                local vector = SetVector(vectorValues[1], TerrainFindFloor(vectorValues[1], vectorValues[3]),
                    vectorValues[3]);
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
