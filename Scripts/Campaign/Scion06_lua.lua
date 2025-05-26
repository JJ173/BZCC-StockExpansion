--[[
    BZCC Scion06 Lua Mission Script
    Written by AI_Unit
    Version 1.0 21-04-2025
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
local m_MissionName = "Scion06: Ambush";

-- Timer for repairs based on difficulty.
local m_RepairTimeTable = { 600, 450, 300 };

-- Mission important variables.
local Mission =
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "fspilo_r",
    -- Specific to mission.
    m_PlayerShipODF = "fvtank_r",

    m_MainPlayer = nil,
    m_Yelena = nil,
    m_Manson = nil,

    m_BraddockTurret1 = nil,
    m_BraddockTurret2 = nil,
    m_BraddockTurret3 = nil,
    m_BraddockTurret4 = nil,

    m_BraddockBasePatrol1 = nil,
    m_BraddockBasePatrol2 = nil,
    m_BraddockBasePatrol3 = nil,

    m_BraddockRecycler = nil,

    m_YelenaTurret1 = nil,
    m_YelenaTurret2 = nil,

    m_PlayerRecycler = nil,
    m_PlayerPower1 = nil,
    m_PlayerPower2 = nil,
    m_PlayerFactory = nil,

    m_ConvoyTug = nil,
    m_ConvoyScout1 = nil,
    m_ConvoyScout2 = nil,
    m_ConvoySent1 = nil,
    m_ConvoySent2 = nil,
    m_PowerCrystal = nil,

    m_Nav1 = nil,

    m_YelenaPowerDialogPlayed = false,

    m_RepairsWarningActive = false,
    m_RepairsStarted = false,
    m_RepairsComplete = false,

    m_YelenaTurret1Sent = false,
    m_YelenaTurret2Sent = false,

    m_ConvoyEscortClose = false,
    m_ConvoyEscortTooFar = false,
    m_ConvoyEnroute = false,
    m_ConvoyActive = false,
    m_ConvoyFleeing = false,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_UnitDispatcherTime = 0,
    m_RepairWarningTime = 0,
    m_RepairWarningCount = 0,
    m_ConvoyBrainDelayTime = 0,

    -- Steps for each section.
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
    local objClass = GetClassLabel(h);

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);

        if (objClass == "CLASS_TURRETTANK") then
            if (IsAliveAndEnemy(Mission.m_BraddockTurret1, Mission.m_EnemyTeam) == false) then
                Mission.m_BraddockTurret1 = h;
            elseif (IsAliveAndEnemy(Mission.m_BraddockTurret2, Mission.m_EnemyTeam) == false) then
                Mission.m_BraddockTurret2 = h;
            elseif (IsAliveAndEnemy(Mission.m_BraddockTurret3, Mission.m_EnemyTeam) == false) then
                Mission.m_BraddockTurret3 = h;
            elseif (IsAliveAndEnemy(Mission.m_BraddockTurret4, Mission.m_EnemyTeam) == false) then
                Mission.m_BraddockTurret4 = h;
            end
        end
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        -- Always max our player units.
        SetSkill(h, 3);

        -- If the player has rebuilt the Power Plants or Factory, we can just let them go for it.
        if (teamNum == Mission.m_HostTeam) then
            if (Mission.m_RepairsComplete == false) then
                if (objClass == "CLASS_PLANT") then
                    if (IsAround(Mission.m_PlayerPower1) == false) then
                        Mission.m_PlayerPower1 = h;
                    elseif (IsAround(Mission.m_PlayerPower2) == false) then
                        Mission.m_PlayerPower2 = h;
                    end
                elseif (objClass == "CLASS_FACTORY") then
                    if (IsAround(Mission.m_PlayerFactory) == false) then
                        Mission.m_PlayerFactory = h;
                    end
                end
            end
        end
    elseif (teamNum == Mission.m_AlliedTeam) then
        if (objClass == "CLASS_TURRETTANK") then
            SetIndependence(h, 1);

            if (IsAlive(Mission.m_YelenaTurret1) == false) then
                Mission.m_YelenaTurret1 = h;
                Mission.m_YelenaTurret1Sent = false;
            elseif (IsAlive(Mission.m_YelenaTurret2) == false) then
                Mission.m_YelenaTurret2 = h;
                Mission.m_YelenaTurret2Sent = false;
            end
        end
    end
end

function DeleteObject(h)
    if (h == Mission.m_YelenaTurret1) then
        Mission.m_YelenaTurret1 = nil;
    elseif (h == Mission.m_YelenaTurret2) then
        Mission.m_YelenaTurret2 = nil;
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

    -- Get the main player
    Mission.m_MainPlayer = GetPlayerHandle(1);

    -- Start mission logic.
    if (not Mission.m_MissionOver and (Mission.m_IsCooperativeMode == false or _Cooperative.GetGameReadyStatus())) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            if (Mission.m_ConvoyActive) then
                ConvoyBrain();
            end

            -- Make sure Yelena sends turrets.
            YelenaBrain();

            -- Check failure conditions...
            HandleFailureConditions();
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
    if (IsPlayer(ShooterHandle) and OrdnanceTeam == Mission.m_HostTeam and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (IsAlive(Mission.m_Manson) and VictimHandle == Mission.m_Manson) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0555.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        end

        if (IsAlive(Mission.m_Yelena) and VictimHandle == Mission.m_Yelena) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scngen30.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_AlliedTeam, "Scion");
    SetTeamNameForStat(Mission.m_EnemyTeam, "New Regime");
    SetTeamNameForStat(7, "Rebel Scions");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Unique to this mission. The Rebel Scions are allying with the New Regime.
    Ally(Mission.m_EnemyTeam, 7);

    -- Since the player is using the AAN, we need to set the team colour to blue.
    SetTeamColor(Mission.m_HostTeam, 0, 127, 255);

    -- Grab all of our pre-placed handles.
    Mission.m_Yelena = GetHandle("yelena");
    Mission.m_Manson = GetHandle("manson");

    Mission.m_BraddockRecycler = GetHandle("enemyrecy");

    Mission.m_PlayerPower1 = GetHandle("playerspgen1");
    Mission.m_PlayerPower2 = GetHandle("playerspgen2");
    Mission.m_PlayerFactory = GetHandle("playersfact");

    Mission.m_ConvoyScout1 = GetHandle("convoy_scout1");
    Mission.m_ConvoyScout2 = GetHandle("convoy_scout2");
    Mission.m_ConvoySent1 = GetHandle("convoy_sent1");
    Mission.m_ConvoySent2 = GetHandle("convoy_sent2");

    Mission.m_ConvoyTug = GetHandle("convoy_tug1");
    Mission.m_PowerCrystal = GetHandle("power");

    -- Have Manson and Yelena patrol their base.
    Patrol(Mission.m_Manson, "manson_patrol", 1);
    Patrol(Mission.m_Yelena, "yelena_patrol", 1);

    -- Make sure Yelena and Manson can't die.
    SetMaxHealth(Mission.m_Manson, 0);
    SetMaxHealth(Mission.m_Yelena, 0);

    -- Give all relevant teams scrap.
    SetScrap(Mission.m_HostTeam, 40);
    SetScrap(Mission.m_EnemyTeam, 40);
    SetScrap(Mission.m_AlliedTeam, 40);

    -- Damage the player buildings to force the repair objectives.
    SetCurHealth(Mission.m_PlayerFactory, 2200);
    SetCurHealth(Mission.m_PlayerPower1, 1500);
    SetCurHealth(Mission.m_PlayerPower2, 1800);

    -- Give the Power Crystal substantial health.
    SetMaxHealth(Mission.m_PowerCrystal, 10000);
    SetCurHealth(Mission.m_PowerCrystal, 10000);

    -- Set Braddock's AIP.
    SetAIP("scion0601_x.aip", Mission.m_EnemyTeam);

    -- Spawn some units in Braddock's base.
    BuildObject("ivatank_x", Mission.m_EnemyTeam, "ass1");
    BuildObject("ivatank_x", Mission.m_EnemyTeam, "ass2");

    -- Spawn some turrets in Braddock's base.
    Mission.m_BraddockTurret1 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret1");
    Mission.m_BraddockTurret2 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret2");
    Mission.m_BraddockTurret3 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret3");
    Mission.m_BraddockTurret4 = BuildObject("ivturr_x", Mission.m_EnemyTeam, "brad_turret4");

    -- Spawn some patrols in Braddock's base.
    Mission.m_BraddockBasePatrol1 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank1");
    Mission.m_BraddockBasePatrol2 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank2");
    Mission.m_BraddockBasePatrol3 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "basetank3");

    -- Patrol the base.
    Patrol(Mission.m_BraddockBasePatrol1, "basetank1", 1);
    Patrol(Mission.m_BraddockBasePatrol2, "basetank2", 1);
    Patrol(Mission.m_BraddockBasePatrol3, "basetank3", 1);

    -- Set Yelena's AIP.
    SetAIP("scion0602_x.aip", Mission.m_AlliedTeam);

    -- Rebel Tug should pick up the Power Crystal.
    Pickup(Mission.m_ConvoyTug, Mission.m_PowerCrystal);

    -- Small delay before we prompt the player to start repairs.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end;

    -- Yelena: First we must work on getting this base in shape...
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0601.wav");

    -- Delay for the audio.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[3] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Yelena: Build a service truck and fix the factory and power generators.
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0601a.wav");

    -- Delay for the audio.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[4] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Show Objectives.
    AddObjectiveOverride("scion0601.otf", "WHITE", 10, true);

    -- Grab the right timer so we can perform some math to divide it for the timer.
    local chosenTimer = m_RepairTimeTable[Mission.m_MissionDifficulty];

    -- Show a timer to the player for base repairs.
    StartCockpitTimer(chosenTimer, chosenTimer / 2, chosenTimer / 4);

    -- Send a couple of units to harass the player.
    local unit_a_choice = { "ivscout_x", "ivmisl_x", "ivtank_x" };
    local unit_b_choice = { "ivscout_x", "ivscout_x", "ivmisl_x" };

    local unit_a = BuildObject(unit_a_choice[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "braddock_script_1");
    local unit_b = BuildObject(unit_b_choice[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "braddock_script_2");

    Goto(unit_a, "playerbase");
    Goto(unit_b, "playerbase");

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[5] = function()
    -- This function can handle the main repair logic.
    if (Mission.m_RepairsComplete == false) then
        if (IsAround(Mission.m_PlayerFactory) == false) then return end;
        if (IsAround(Mission.m_PlayerPower1) == false) then return end;
        if (IsAround(Mission.m_PlayerPower2) == false) then return end;

        local factHealth = GetCurHealth(Mission.m_PlayerFactory);
        local pgen1Health = GetCurHealth(Mission.m_PlayerPower1);
        local pgen2Health = GetCurHealth(Mission.m_PlayerPower2);

        -- Check the health of everything first so we don't play the below audio if the player just decides to rebuild.
        if (factHealth > 5900 and pgen1Health > 2900 and pgen2Health > 2900) then
            -- Small delay before the next voice line.
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

            -- Stop the timer.
            StopCockpitTimer();
            HideCockpitTimer();

            -- Skip the below section if this is done first.
            Mission.m_RepairsStarted = true;

            -- Repairs are complete.
            Mission.m_RepairsComplete = true;

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end

        -- Check the health of each building to see if they are being repaired.
        if (Mission.m_RepairsStarted == false) then
            if (factHealth > 2250 or pgen1Health > 1550 or pgen2Health > 1850) then
                -- Yelena: Good.  Continue to build up your forces while waiting for the repairs.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0602.wav");

                -- Timer for this clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                -- So we don't loop this sequence.
                Mission.m_RepairsStarted = true;
            end
        end
    end
end

Functions[6] = function()
    if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end;
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Yelena: Ok the repairs are complete.  Now we should be in good shape for the base assault.  Continue to build your forces, and take out that base!	
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0603.wav");

    -- Timer for this clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[7] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Show Objectives.
    AddObjectiveOverride("scion0601.otf", "WHITE", 10, true);

    -- Build and rename a nav for Braddock's bases.
    Mission.m_Nav1 = BuildObject("ibnav", Mission.m_HostTeam, "enemybase");
    SetObjectiveName(Mission.m_Nav1, TranslateString("MissionS0601"));
    SetObjectiveOn(Mission.m_Nav1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[8] = function()
    if (Mission.m_YelenaPowerDialogPlayed == false) then
        if (IsPlayerWithinDistance("enemybase", 220, _Cooperative.m_TotalPlayerCount)) then
            -- Yelena: Cooke go for the power generators, that will buy you some time to take out those gun towers.	
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0604.wav");

            -- Timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- So we don't loop.
            Mission.m_YelenaPowerDialogPlayed = true;
        end
    end

    if (IsAround(Mission.m_BraddockRecycler) == false) then
        -- Small delay before the next state.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(4);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    if (Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end;

    -- Yelena: Good job, you've knocked the base out of commission.
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0606.wav");

    -- Timer for this clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[10] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Start up the convoy.
    Retreat(Mission.m_ConvoyScout1, "convoypath");
    Follow(Mission.m_ConvoyScout2, Mission.m_ConvoyScout1);

    Retreat(Mission.m_ConvoyTug, "convoypath");
    Follow(Mission.m_ConvoySent1, Mission.m_ConvoyTug);
    Follow(Mission.m_ConvoySent2, Mission.m_ConvoySent1);

    Mission.m_ConvoyEnroute = true;
    Mission.m_ConvoyActive = true;

    -- Burns: It looks like we took out that base just in time, we've just picked up the Evil Scion convoy on radar and they are nearing the base!  Move as many forces to the destroyed base as you can, we must take out that convoy. Remember, do not damage the power source.
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0607.wav");

    -- Timer for this clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(16.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[11] = function()
    if (Mission.m_ConvoyFleeing == false or Mission.m_MissionDelayTime >= Mission.m_MissionTime) then return end;
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) == false) then return end;

    -- Yelena: Cooke, the tug is retreating, do not let it get away!!
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0609.wav");

    -- Show Objectives.
    AddObjectiveOverride("scion0604.otf", "WHITE", 10, true);

    -- Timer for this clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[12] = function()

end

function YelenaBrain()
    if (Mission.m_UnitDispatcherTime < Mission.m_MissionTime) then
        if (Mission.m_YelenaTurret1Sent == false) then
            -- Pick a random path for this turret to move to.
            local rand = GetRandomFloat(1);
            local path;

            if (rand < 0.5) then
                path = "yelena_turret_path_1";
            else
                path = "yelena_turret_path_3";
            end

            Goto(Mission.m_YelenaTurret1, path);

            Mission.m_YelenaTurret1Sent = true;
        end

        if (Mission.m_YelenaTurret2Sent == false) then
            -- Pick a random path for this turret to move to.
            local rand = GetRandomFloat(1);
            local path;

            if (rand < 0.5) then
                path = "yelena_turret_path_2";
            else
                path = "yelena_turret_path_4";
            end

            Goto(Mission.m_YelenaTurret2, path);

            Mission.m_YelenaTurret2Sent = true;
        end

        -- To delay loops.
        Mission.m_UnitDispatcherTime = Mission.m_MissionTime + SecondsToTurns(1.5);
    end
end

function ConvoyBrain()
    -- If we have a delay, don't run this.
    if (Mission.m_ConvoyBrainDelayTime > Mission.m_MissionTime) then return end;

    -- Handle the Convoy movement to Braddock's base.
    if (Mission.m_ConvoyEnroute) then
        local convoy1Distance = GetDistance(Mission.m_ConvoyScout1, Mission.m_ConvoyTug);

        if (Mission.m_ConvoyEscortTooFar == false and convoy1Distance > 100) then
            -- Stop the Convoy Scouts if they get too far ahead.
            Stop(Mission.m_ConvoyScout1);
            Stop(Mission.m_ConvoyScout2);

            -- Switch these around.
            Mission.m_ConvoyEscortClose = false;
            Mission.m_ConvoyEscortTooFar = true;
        elseif (Mission.m_ConvoyEscortClose == false and convoy1Distance < 90) then
            -- Move the Scouts down the convoypath again.
            Retreat(Mission.m_ConvoyScout1, "convoypath");
            Follow(Mission.m_ConvoyScout2, Mission.m_ConvoyScout1);

            -- Switch these around.
            Mission.m_ConvoyEscortClose = true;
            Mission.m_ConvoyEscortTooFar = false;
        end

        -- Double check the distance between the player and the convoy tug, or the forward scout.
        for i = 1, _Cooperative.m_TotalPlayerCount do
            local playerHandle = GetPlayerHandle(i);

            if (GetDistance(playerHandle, Mission.m_ConvoyScout1) < 200 or GetDistance(playerHandle, Mission.m_ConvoyTug) < 200) then
                -- Have both front scouts attack the nearest player.
                Attack(Mission.m_ConvoyScout1, playerHandle);
                Attack(Mission.m_ConvoyScout2, playerHandle);

                -- Tell the Scion tug to retreat out of the map.
                Retreat(Missison.m_ConvoyTug, "tugretreatpath");

                -- EVIL CONVOY:  Squad alpha here, we have the package. Hey wait a minute, those aren't Braddock's forces!  Destroy them!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0608.wav");

                -- Timer for this clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

                -- Delay to let the player know that the convoy is fleeing.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(15);

                -- So we can track if the Tug escapes.
                Mission.m_ConvoyFleeing = true;

                -- Stop the escort logic.
                Mission.m_ConvoyEnroute = false;
            end
        end
    elseif (Mission.m_ConvoyFleeing) then
        -- Use this to track the enemy guards.

        -- Small delay so we don't constantly check the state of the Scion Convoy each turn.
        Mission.m_ConvoyBrainDelayTime = Mission.m_MissionTime + SecondsToTurns(3);
    end
end

-- Checks for failure conditions.
function HandleFailureConditions()
    if (Mission.m_RepairsWarningActive) then
        if (Mission.m_RepairWarningTime >= Mission.m_MissionTime) then return end;

        if (Mission.m_RepairWarningCount == 0) then
            -- Yelena: Those repairs should have been finished by now,  What's going on?
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0603.wav");

            -- Timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);
        elseif (Mission.m_RepairWarningCount == 1) then
            -- Yelena: The base STILL is not fully repaired.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0616.wav");

            -- Timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
        elseif (Mission.m_RepairWarningCount == 2) then
            -- Yelena: That's it... I'm pissed now, mission over.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0617.wav");

            -- Timer for this clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
        end

        -- Advance the warning count.
        Mission.m_RepairWarningCount = Mission.m_RepairWarningCount + 1;

        if (Mission.m_RepairWarningCount < 3) then
            -- Add more time for the warning.
            Mission.m_RepairWarningTime = m_RepairTimeTable[Mission.m_MissionDifficulty] / 4;
        else
            StopCockpitTimer();
            HideCockpitTimer();

            -- Show Objectives.
            AddObjectiveOverride("scion0607.otf", "RED", 10, true);

            -- Fail the mission.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("The base wasn't repaired in time.");
                DoGameover(10);
            else
                FailMission(GetTime() + 10, "scion06L1.txt");
            end

            -- Just so we don't loop.
            Mission.m_MissionOver = true;
        end
    end

    if (Mission.m_ConvoyFleeing) then
        if (GetDistance(Mission.m_ConvoyTug, "tug_end_missison") < 75) then
            -- Show Objectives.
            AddObjectiveOverride("scion0604.otf", "RED", 10, true);

            -- Fail the mission.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("The Hauler escaped.");
                DoGameover(10);
            else
                FailMission(GetTime() + 10, "The Hauler escaped.");
            end

            -- Just so we don't loop.
            Mission.m_MissionOver = true;
        end
    end
end
