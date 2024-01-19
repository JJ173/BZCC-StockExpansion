--[[
    BZCC ISDF03 Lua Mission Script
    Written by AI_Unit
    Version 1.0 30-11-2023
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

-- Mission Name
local m_MissionName = "ISDF03: We Have Hostiles";

-- Difficulty tables for times and spawns.
local m_ScionGuards = {
    {
        { "fvscout_x", "fvscout_x" },
        { "fvscout_x", "fvscout_x" },
        { "fvscout_x", "fvscout_x" }
    },
    {
        { "fvscout_x", "fvscout_x" },
        { "fvscout_x", "fvsent_x" },
        { "fvsent_x",  "fvsent_x" }
    },
    {
        { "fvscout_x", "fvsent_x" },
        { "fvsent_x",  "fvsent_x" },
        { "fvtank_x",  "fvsent_x" }
    }
};

local m_ScionBaseAttacks = {
    {
        { "fvscout_x", "fvscout_x", "fvscout_x" },
        { "fvscout_x", "fvsent_x",  "fvscout_x" },
        { "fvsent_x",  "fvsent_x",  "fvscout_x" }
    },
    {
        { "fvsent_x", "fvscout_x", "fvscout_x" },
        { "fvsent_x", "fvsent_x",  "fvscout_x" },
        { "fvsent_x", "fvtank_x",  "fvsent_x" }
    },
    {
        { "fvsent_x", "fvsent_x", "fvscout_x" },
        { "fvtank_x", "fvsent_x", "fvsent_x" },
        { "fvtank_x", "fvtank_x", "fvsent_x" }
    }
}

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
    m_PlayerShipODF = "ivscout_x",

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
    m_Power = nil,

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
    m_ScionBrainEnabled = false,
    m_HaulersDead = true,
    m_RelicFailureActive = false,
    m_RelicFailureCamPrep = false,
    m_BaseFailureActive = true,
    m_ShabFailureActive = true,
    m_TruckHelp = false,

    m_Scion3Attack = false,
    m_Scion3Switch = false,

    m_Scion4Attack = false,
    m_Scion4Switch = false,

    m_Scion5Attack = false,
    m_Scion5Switch = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_TunnelWarningTime = 0,
    m_RedSquadLookTime = 0,
    m_ScionWaveTime = 0,
    m_ScionWaveCount = 1,
    m_ArmorySequence = 0,

    -- This checks the state of each hauler.
    m_Hauler1State = 0,
    m_Hauler2State = 0,

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
    -- Handle unit skill for enemy.
    if (GetTeamNum(h) == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);

        -- For this mission, we don't have intel on enemy units, so set all of their names to "Unknown".
        SetObjectiveName(h, "Unknown");
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

            -- This just tells the truck to heal the Power Plant if it gets below health.
            if (not Mission.m_TruckHelp) then
                if (IsAlive(Mission.m_Truck) and IsAround(Mission.m_Power)) then
                    if (GetCurHealth(Mission.m_Power) < 2500) then
                        -- Go heal the Power Plant.
                        Service(Mission.m_Truck, Mission.m_Power, 0);

                        -- So we don't loop.
                        Mission.m_TruckHelp = true;
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
    if (IsPlayer(ShooterHandle) and OrdnanceTeam == Mission.m_HostTeam and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (VictimHandle == Mission.m_Shabayev) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("ff01.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
    end

    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

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
    Mission.m_Power = GetHandle("power1");
    Mission.m_Armory = GetHandle("armory");

    -- Give Shab her name.
    SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");

    -- Highlight Shabayev.
    SetObjectiveOn(Mission.m_Shabayev);

    -- Give her the correct pilot.
    SetPilotClass(Mission.m_Shabayev, "isshab_p");

    -- Make sure she has good skill.
    SetSkill(Mission.m_Shabayev, 3);

    -- Make the relics unkillable.
    SetMaxHealth(Mission.m_Relic1, 0);
    SetMaxHealth(Mission.m_Relic2, 0);

    -- This is for Red Squad.
    SetTeamColor(Mission.m_AlliedTeam, 255, 50, 50);

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

    -- Stop the enemy from attacking the relics.
    SetPerceivedTeam(Mission.m_Relic1, Mission.m_EnemyTeam);
    SetPerceivedTeam(Mission.m_Relic2, Mission.m_EnemyTeam);

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Shab: We're not out of the woods yet..
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0301.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(12.5);

        -- Tiny delay
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
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
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
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

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- So we can start the next part.
            Mission.m_MoveHauler = true;

            -- So we don't loop.
            Mission.m_ShabStrangeBuildingMessage = true;
        elseif (InBuilding(p) and GetDistance(p, "check3") < 12) then
            -- So we can start the next part.
            Mission.m_MoveHauler = true;
        end

        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and Mission.m_MoveHauler) then
            -- Force the Hauler to retreat.
            Retreat(Mission.m_Hauler1, "haulerout_path1");

            -- Remove the warning for checking the tunnels.
            Mission.m_TunnelWarningActive = false;

            -- Show the objectives.
            AddObjectiveOverride("isdf0301.otf", "WHITE", 10, true);
            AddObjective("isdf0302.otf", "WHITE");

            -- Shab: "I'm on my way!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0304.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

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

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);
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
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and GetDistance(Mission.m_Shabayev, Mission.m_Relic1) < 30) then
        -- Have her look at the relic.
        LookAt(Mission.m_Shabayev, Mission.m_Relic1, 1);

        -- Shab: It looks like these aliens are interested in us...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0308.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- This moves Shabayev to the tech building.
        Goto(Mission.m_Shabayev, Mission.m_TechCenter, 1);

        -- Shab: "What is this? I don't recognise this either".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0309a.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

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
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Have Shabayev look at the main player.
        LookAt(Mission.m_Shabayev, Mission.m_MainPlayer, 1);

        -- Play the message from Red 1.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0325b.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "Can you trasmit your location"?
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0326.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Red1: "Negative!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0315.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: "Commander? Damn it!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0316.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
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

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

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

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(12.5);

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
                if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                    -- Stop Shabayev from talking.
                    StopAudioMessage(Mission.m_Audioclip);

                    -- Remove the timer.
                    Mission.m_AudioTimer = 0;

                    -- Do a tiny delay.
                    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
                end

                if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                    -- Have her look at the bunker.
                    LookAt(Mission.m_Shabayev, Mission.m_CommBunker, 1);

                    -- Shab: Head into the bunker.
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0318.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

                    -- So we don't loop.
                    Mission.m_PlayerHoppedOutMessage = true;
                end
            end

            -- This does a check to see if the player is within the bunker.
            if (Mission.m_PlayerHoppedOutMessage and not Mission.m_BuiltRedSquad and InBuilding(p)) then
                -- Stop Shabayev from chatting.
                if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                    -- Stop Shabayev from talking.
                    StopAudioMessage(Mission.m_Audioclip);

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = 0;

                    -- Do a tiny delay.
                    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
                end

                if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                    -- Show Objectives.
                    AddObjectiveOverride("isdf0306.otf", "GREEN", 10, true);
                    AddObjective("isdf0307.otf", "WHITE");

                    -- Shab: "Move to the map terminal".
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0319.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

                    -- Create Red Squad.
                    Mission.m_Miller = BuildObject("ivpscou", Mission.m_AlliedTeam, "miller_spawn1");
                    Mission.m_Simms = BuildObject("ivpscou", Mission.m_AlliedTeam, "simms_spawn1");

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
                if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                    -- Stop Shabayev from talking.
                    StopAudioMessage(Mission.m_Audioclip);

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = 0;

                    -- Do a tiny delay.
                    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
                end

                if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                    -- Shab: "Locate the soliders for me".
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0328.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

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
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: Drop a nav for me.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0330.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(13.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[20] = function()
    -- This does a check to see if the nav is near enough to Red 1.
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and not Mission.m_ShowNavObjective) then
        -- Show objectives.
        AddObjectiveOverride("isdf0310.otf", "WHITE", 10, true);

        -- So we don't loop.
        Mission.m_ShowNavObjective = true;
    end

    -- This does a check to see if the nav is within a good distance of Red 1.
    if (IsAround(Mission.m_RedNav)) then
        if (GetDistance(Mission.m_RedNav, Mission.m_Miller) > 200) then
            -- Stop Shabayev from chatting.
            if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                -- Stop Shabayev from talking.
                StopAudioMessage(Mission.m_Audioclip);

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = 0;

                -- Do a tiny delay.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
            end

            if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                -- Start new audio.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0331.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

                -- Show objectives.
                AddObjectiveOverride("isdf0310.otf", "RED", 10, true);

                -- So we don't loop.
                Mission.m_RedNav = nil;
            end
        else
            -- Stop Shabayev from chatting.
            if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                -- Stop Shabayev from talking.
                StopAudioMessage(Mission.m_Audioclip);

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = 0;

                -- Do a tiny delay.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
            end

            if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                -- Show objectives.
                AddObjectiveOverride("isdf0310.otf", "GREEN", 10, true);

                -- This removes the bunker warning.
                Mission.m_BunkerWarningActive = false;

                -- So we don't fail.
                Mission.m_BaseFailureActive = false;

                -- Remove the objective markers from both Shab and Red 1.
                SetObjectiveOff(Mission.m_Shabayev);
                SetObjectiveOff(Mission.m_Miller);

                -- Shab: I'm on my way.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0320.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

                -- So we don't fail if Shab dies.
                Mission.m_ShabFailureActive = false;

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
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- This sets up our delay for the next part.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(15);

        -- Shab: "You're a good pilot".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0332a.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[22] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Braddock: We've got your situation on radar.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0310.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(25.5);

        -- Set the failure condition for this section as active.
        Mission.m_RelicFailureActive = true;

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
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- New Objectives.
        AddObjectiveOverride("isdf0308a.otf", "WHITE", 10, true);

        -- Enable the Scion brain. This will have them pick up the crates.
        Mission.m_ScionBrainEnabled = true;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[24] = function()
    -- Enemy units are dead, refresh.
    if (Mission.m_HaulersDead and not IsPlayerWithinDistance("base2_espawn1", 300, _Cooperative.m_TotalPlayerCount)) then
        if (Mission.m_ScionWaveTime < Mission.m_MissionTime) then
            -- This creates the Haulers and their guards.
            Mission.m_Hauler1 = BuildObject("fvtug3", Mission.m_EnemyTeam, "base2_espawn3");
            Mission.m_Hauler2 = BuildObject("fvtug3", Mission.m_EnemyTeam, "base2_espawn4");

            -- Set their avoid type.
            SetAvoidType(Mission.m_Hauler1, 0);
            SetAvoidType(Mission.m_Hauler2, 0);

            -- Create the guards.
            Mission.m_Scion1 = BuildObject(m_ScionGuards[Mission.m_MissionDifficulty][Mission.m_ScionWaveCount][1],
                Mission.m_EnemyTeam, "base2_espawn1");
            Mission.m_Scion2 = BuildObject(m_ScionGuards[Mission.m_MissionDifficulty][Mission.m_ScionWaveCount][2],
                Mission.m_EnemyTeam, "base2_espawn2");

            -- Create extra attacks.
            Mission.m_Scion3 = BuildObject(m_ScionBaseAttacks[Mission.m_MissionDifficulty][Mission.m_ScionWaveCount][1],
                Mission.m_EnemyTeam, "simms_spawn2");
            Mission.m_Scion4 = BuildObject(m_ScionBaseAttacks[Mission.m_MissionDifficulty][Mission.m_ScionWaveCount][2],
                Mission.m_EnemyTeam, "miller_spawn2");
            Mission.m_Scion5 = BuildObject(m_ScionBaseAttacks[Mission.m_MissionDifficulty][Mission.m_ScionWaveCount][3],
                Mission.m_EnemyTeam, "attack_1");

            -- Set their avoid type.
            SetAvoidType(Mission.m_Scion1, 0);
            SetAvoidType(Mission.m_Scion2, 0);

            -- Have them follow the Haulers.
            Defend2(Mission.m_Scion1, Mission.m_Hauler1, 1);
            Defend2(Mission.m_Scion2, Mission.m_Hauler2, 1);

            -- Have the Haulers go for the crates.
            Retreat(Mission.m_Hauler1, "haulerin_path1");
            Retreat(Mission.m_Hauler2, "haulerin_path2");

            -- So we can check the reset logic in the Scion Brain function.
            Mission.m_HaulersDead = false;

            -- So the truck heals the power during each attack.
            Mission.m_TruckHelp = false;

            -- Sets the hauler states to the right state.
            Mission.m_Hauler1State = HAULER_MOVING;
            Mission.m_Hauler2State = HAULER_MOVING;

            -- Increase the wave count.
            Mission.m_ScionWaveCount = Mission.m_ScionWaveCount + 1;
        end
    end

    -- This is Shabayev giving helpful information about the armory.
    if (Mission.m_HaulersDead) then
        if (Mission.m_ScionWaveCount == 2) then
            if (Mission.m_ArmorySequence == 0) then
                -- Shab: "Cooke with the Armory back online...";
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0334.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

                -- Advance the sequence.
                Mission.m_ArmorySequence = Mission.m_ArmorySequence + 1;
            elseif (Mission.m_ArmorySequence == 1) then
                if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                    -- Shab: "Select the Armory..."
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0335.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

                    -- Advance the sequence.
                    Mission.m_ArmorySequence = Mission.m_ArmorySequence + 1;
                end
            elseif (Mission.m_ArmorySequence == 2) then
                if (IsSelected(Mission.m_Armory)) then
                    -- Stop Shabayev from chatting.
                    if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                        -- Stop Shabayev from talking.
                        StopAudioMessage(Mission.m_Audioclip);

                        -- Set the timer for this audio clip.
                        Mission.m_AudioTimer = 0;

                        -- Do a tiny delay.
                        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
                    end

                    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                        -- Shab: Now Order The armory..
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0336.wav");

                        -- Set the timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

                        -- Advance the sequence.
                        Mission.m_ArmorySequence = Mission.m_ArmorySequence + 1;
                    end
                end
            end
        elseif (Mission.m_ScionWaveCount == 4) then
            -- Turn off the warning for the relic failure
            Mission.m_RelicFailureActive = false;

            -- Remove logic from the Scion brain.
            Mission.m_ScionBrainEnabled = false;

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[25] = function()
    -- Make sure all Scions are dead.
    local check1 = IsAlive(Mission.m_Scion3);
    local check2 = IsAlive(Mission.m_Scion4);
    local check3 = IsAlive(Mission.m_Scion5)

    if (not check1 and not check2 and not check3) then
        -- Shab: "I've got the two strays and I'm on my way back".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0338.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Build Shabayev and Red Squad.
        Mission.m_Shabayev = BuildObject("ivpscou", Mission.m_HostTeam, "shab_spawn");
        Mission.m_Miller = BuildObject("ivpscou", Mission.m_AlliedTeam, "miller_spawn2");
        Mission.m_Simms = BuildObject("ivpscou", Mission.m_AlliedTeam, "simms_spawn2");

        -- Can't have her eject here, as there's no Recycler to build spare units.
        SetEjectRatio(Mission.m_Shabayev, 0);

        -- Rename Shabayev
        SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");
        SetObjectiveOn(Mission.m_Shabayev);

        -- Change the name of the characters.
        SetObjectiveName(Mission.m_Miller, "Red 1");
        SetObjectiveName(Mission.m_Simms, "Lt. Simms");

        -- AI stuff.
        SetAvoidType(Mission.m_Shabayev, 0);
        SetAvoidType(Mission.m_Miller, 0);
        SetAvoidType(Mission.m_Simms, 0);

        -- Damage the ships.
        Damage(Mission.m_Shabayev, 600);
        Damage(Mission.m_Miller, 1100);
        Damage(Mission.m_Simms, 1300);

        -- Create their formation.
        Goto(Mission.m_Shabayev, "last_path");
        Follow(Mission.m_Miller, Mission.m_Shabayev, 1);
        Follow(Mission.m_Simms, Mission.m_Miller, 1);

        -- Activate failures.
        Mission.m_ShabFailureActive = true;

        -- Show Objectives.
        AddObjectiveOverride("isdf0309.otf", "WHITE", 10, true);

        -- Small delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(10);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[26] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Build the chasing Scion units.
        Mission.m_Scion1 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "miller_spawn2");
        Mission.m_Scion2 = BuildObject("fvscout_x", Mission.m_EnemyTeam, "miller_spawn2");

        -- Formation.
        Follow(Mission.m_Scion2, Mission.m_Scion1);

        -- Have them go to the base.
        Goto(Mission.m_Scion1, "last_path", 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[27] = function()
    -- Final checks.
    if (IsAround(Mission.m_Armory)) then
        if (GetDistance(Mission.m_Shabayev, Mission.m_Armory) < 100) then
            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    else
        if (GetDistance(Mission.m_Shabayev, "base_center") < 100) then
            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[28] = function()
    local check1 = IsAlive(Mission.m_Scion1);
    local check2 = IsAlive(Mission.m_Scion2);

    for i = 1, _Cooperative.m_TotalPlayerCount do
        local p = GetPlayerHandle(i);
        local check3 = GetDistance(p, Mission.m_Shabayev) < 60;

        if (not check1 and not check2 and check3) then
            -- Shab: "I knew you could do it".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0321.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Have her look at the main player.
            LookAt(Mission.m_Shabayev, p, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[29] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock "Condors are inbound"...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0337.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(13.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[30] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Mission failed.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(5);
        else
            SucceedMission(GetTime() + 5, "isdf03w1.txt");
        end

        -- Marks this as done so we don't loop.
        Mission.m_MissionOver = true;
    end
end

function ScionBrain()
    -- This does a check to see when the Haulers need to pick up the crates.
    if (IsAlive(Mission.m_Hauler1)) then
        if (Mission.m_Hauler1State == HAULER_MOVING) then
            -- Run a check to make sure we are in range.
            if (GetDistance(Mission.m_Hauler1, Mission.m_Relic1) < GetDistance(Mission.m_Hauler1, "hauler_check2")) then
                -- Set the hauler to pick up the relic.
                Pickup(Mission.m_Hauler1, Mission.m_Relic1, 1);

                -- Highlight the Hauler.
                SetObjectiveOn(Mission.m_Hauler1);

                -- Set the state so they don't loop.
                Mission.m_Hauler1State = HAULER_PICKUP;
            end
        elseif (Mission.m_Hauler1State == HAULER_PICKUP) then
            -- This checks to see if the Hauler has cargo.
            if (HasCargo(Mission.m_Hauler1)) then
                -- Tell it to retreat.
                if (GetDistance(Mission.m_Hauler1, "hauler_check1") > GetDistance(Mission.m_Hauler1, "hauler_check2")) then
                    Retreat(Mission.m_Hauler1, "haulerout_path2");
                else
                    Retreat(Mission.m_Hauler1, "final_check");
                end

                -- Change the state.
                Mission.m_Hauler1State = HAULER_RETREAT;
            end
        end
    end

    if (IsAlive(Mission.m_Hauler2)) then
        if (Mission.m_Hauler2State == HAULER_MOVING) then
            -- Run a check to make sure we are in range.
            if (GetDistance(Mission.m_Hauler2, Mission.m_Relic2) < GetDistance(Mission.m_Hauler2, "hauler_check2")) then
                -- Set the hauler to pick up the relic.
                Pickup(Mission.m_Hauler2, Mission.m_Relic2, 1);

                -- Highlight the Hauler.
                SetObjectiveOn(Mission.m_Hauler2);

                -- Set the state so they don't loop.
                Mission.m_Hauler2State = HAULER_PICKUP;
            end
        elseif (Mission.m_Hauler2State == HAULER_PICKUP) then
            -- This checks to see if the Hauler has cargo.
            if (HasCargo(Mission.m_Hauler2)) then
                -- Tell it to retreat.
                if (GetDistance(Mission.m_Hauler2, "hauler_check1") > GetDistance(Mission.m_Hauler2, "hauler_check2")) then
                    Retreat(Mission.m_Hauler2, "haulerout_path2");
                else
                    Retreat(Mission.m_Hauler2, "final_check");
                end

                -- Change the state.
                Mission.m_Hauler2State = HAULER_RETREAT;
            end
        end
    end

    -- This is a monitor to see if the Haulers are dead.
    if (not IsAlive(Mission.m_Hauler1) and not IsAlive(Mission.m_Hauler2) and not Mission.m_HaulersDead) then
        -- So it doesn't loop.
        Mission.m_HaulersDead = true;

        -- This sets the time limit.
        Mission.m_ScionWaveTime = Mission.m_MissionTime + SecondsToTurns(90);
    end

    -- This will handle the extra enemies and when they attack.
    if (IsAlive(Mission.m_Scion3)) then
        if (GetCurrentCommand(Mission.m_Scion3) == CMD_NONE) then
            Goto(Mission.m_Scion3, "last_path", 1);
        end

        if (not Mission.m_Scion3Attack and GetDistance(Mission.m_Scion3, Mission.m_Power) < 100) then
            -- Have it attack the Power Plant.
            Attack(Mission.m_Scion3, Mission.m_Power, 1);

            -- Get the guard of this unit to attack the truck.
            if (IsAlive(Mission.m_Scion4)) then
                if (IsAlive(Mission.m_Truck)) then
                    Attack(Mission.m_Scion4, Mission.m_Truck, 1);
                else
                    Attack(Mission.m_Scion4, Mission.m_MainPlayer, 1);
                end

                -- So we don't loop.
                Mission.m_Scion4Attack = true;
            end

            -- So we don't loop.
            Mission.m_Scion3Attack = true;
        end

        -- This does a check on ammo. If we're running low, use it better.
        if (not Mission.m_Scion3Switch and GetCurAmmo(Mission.m_Scion3) < 100) then
            if (IsAlive(Mission.m_Truck)) then
                Attack(Mission.m_Scion3, Mission.m_Truck, 1);
            else
                Attack(Mission.m_Scion3, Mission.m_MainPlayer, 1);
            end

            -- So we don't loop.
            Mission.m_Scion3Switch = true;
        end
    else
        -- Reset for the next unit.
        Mission.m_Scion3Attack = false;
        Mission.m_Scion3Switch = false;
    end

    if (IsAlive(Mission.m_Scion4)) then
        if (GetCurrentCommand(Mission.m_Scion3) == CMD_NONE) then
            if (IsAlive(Mission.m_Scion3)) then
                Follow(Mission.m_Scion4, Mission.m_Scion3, 1);
            else
                Goto(Mission.m_Scion3, "last_path", 1);
            end
        end

        if (not Mission.m_Scion4Attack and GetDistance(Mission.m_Scion4, Mission.m_Power) < 100) then
            -- Have it attack the Power Plant.
            Attack(Mission.m_Scion4, Mission.m_Truck, 1);

            -- So we don't loop.
            Mission.m_Scion4Attack = true;
        end

        -- This does a check on ammo. If we're running low, use it better.
        if (not Mission.m_Scion4Switch and GetCurAmmo(Mission.m_Scion4) < 100) then
            if (IsAlive(Mission.m_Truck)) then
                Attack(Mission.m_Scion4, Mission.m_Truck, 1);
            else
                Attack(Mission.m_Scion4, Mission.m_MainPlayer, 1);
            end

            -- So we don't loop.
            Mission.m_Scion4Switch = true;
        end
    else
        -- Reset for the next unit.
        Mission.m_Scion4Attack = false;
        Mission.m_Scion4Switch = false;
    end

    if (IsAlive(Mission.m_Scion5)) then
        if (not Mission.m_Scion5Attack) then
            -- Have it attack the Player.
            Attack(Mission.m_Scion5, Mission.m_MainPlayer, 1);

            -- So we don't loop.
            Mission.m_Scion5Attack = true;
        end

        -- If the player target is dead.
        if (not Mission.m_Scion5Switch and GetCurrentCommand(Mission.m_Scion5) == CMD_NONE) then
            if (IsAlive(Mission.m_Truck) and GetCurAmmo(Mission.m_Scion5) < 100) then
                Attack(Mission.m_Scion5, Mission.m_Truck, 1);
            else
                Attack(Mission.m_Scion5, Mission.m_Power, 1);
            end

            -- So we don't loop.
            Mission.m_Scion5Switch = true;
        end
    else
        -- Reset for the next unit.
        Mission.m_Scion5Attack = false;
        Mission.m_Scion5Switch = false;
    end
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
        if (IsAlive(Mission.m_Shabayev) and GetDistance(Mission.m_Shabayev, "miller_spawn1") < 15) then
            RemoveObject(Mission.m_Shabayev);
            RemoveObject(Mission.m_Miller);
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

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

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
            if (not IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                -- Stop Shabayev from talking.
                StopAudioMessage(Mission.m_Audioclip);

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = 0;

                -- Do a tiny delay.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);
            end

            if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
                -- Shab: Where are you going?!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0328a.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                -- So we fail.
                Mission.m_BaseFailureActive = true;

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

    -- This checks that the cargo is near the dropship.
    if (Mission.m_RelicFailureActive) then
        -- Check to see if the Haulers are alive and they have the cargo.
        if (Mission.m_Hauler1State == HAULER_RETREAT) then
            -- Do a distance check.
            if (GetDistance(Mission.m_Hauler1, "final_check") < 30 and HasCargo(Mission.m_Hauler1)) then
                -- This first preps the camera.
                if (not Mission.m_RelicFailureCamPrep) then
                    -- Only do the cutscenes in SP mode.
                    if (not Mission.m_IsCooperativeMode) then
                        -- Prep the Camera.
                        CameraReady();
                    end

                    -- Move the relevant hauler.
                    Retreat(Mission.m_Hauler1, "drop_path", 1);

                    -- Braddock: "You allowed them to capture our tech!"
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0324.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                    -- So we don't loop.
                    Mission.m_RelicFailureCamPrep = true;
                else
                    if (not Mission.m_IsCooperativeMode) then
                        -- Prep the Camera.
                        CameraPath("final_check", 40, 0, Mission.m_ScionDropship);
                    end

                    -- Mission failed.
                    if (Mission.m_IsCooperativeMode) then
                        NoteGameoverWithCustomMessage("A relic was captured.");
                        DoGameover(5);
                    else
                        FailMission(GetTime() + 5, "isdf03l1.txt");
                    end

                    -- Marks this as done so we don't loop.
                    Mission.m_MissionOver = true;
                end
            end
        end

        if (Mission.m_Hauler2State == HAULER_RETREAT) then
            -- Do a distance check.
            if (GetDistance(Mission.m_Hauler2, "final_check") < 30 and HasCargo(Mission.m_Hauler2)) then
                -- This first preps the camera.
                if (not Mission.m_RelicFailureCamPrep) then
                    -- Only do the cutscenes in SP mode.
                    if (not Mission.m_IsCooperativeMode) then
                        -- Prep the Camera.
                        CameraReady();
                    end

                    -- Move the relevant hauler.
                    Retreat(Mission.m_Hauler2, "drop_path", 1);

                    -- Braddock: "You allowed them to capture our tech!"
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0324.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                    -- So we don't loop.
                    Mission.m_RelicFailureCamPrep = true;
                else
                    if (not Mission.m_IsCooperativeMode) then
                        -- Prep the Camera.
                        CameraPath("final_check", 40, 0, Mission.m_ScionDropship);
                    end

                    -- Mission failed.
                    if (Mission.m_IsCooperativeMode) then
                        NoteGameoverWithCustomMessage("A relic was captured.");
                        DoGameover(5);
                    else
                        FailMission(GetTime() + 5, "isdf03l1.txt");
                    end

                    -- Marks this as done so we don't loop.
                    Mission.m_MissionOver = true;
                end
            end
        end
    end

    -- This is if the player abandons the base to go to Red Squad.
    if (Mission.m_BaseFailureActive) then
        if (IsAlive(Mission.m_Miller)) then
            if (IsPlayerWithinDistance(Mission.m_Miller, 300, _Cooperative.m_TotalPlayerCount) and not IsPlayerWithinDistance("base_center", 400, _Cooperative.m_TotalPlayerCount)) then
                -- Halt the mission.
                Mission.m_MissionOver = true;

                -- Stop all audio.
                StopAudioMessage(Mission.m_Audioclip);

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = 0;

                -- Shab: "I'll carry on without you..."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0329a.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

                -- Game over.
                if (Mission.m_IsCooperativeMode) then
                    NoteGameoverWithCustomMessage("You failed to follow the orders of your commanding officer!");
                    DoGameover(7);
                else
                    FailMission(GetTime() + 7);
                end
            end
        end
    end

    -- This checks to see if Shabayev is dead.
    if (Mission.m_ShabFailureActive) then
        if (not IsAlive(Mission.m_Shabayev)) then
            -- Stop all audio.
            StopAudioMessage(Mission.m_Audioclip);

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = 0;

            if (IsAlive(Mission.m_Truck)) then
                -- Truck: "The Commander is dead!"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0322.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
            else
                -- Braddock: "The Commander is dead!"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0323.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
            end

            -- Game over.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("Shabayev is KIA!");
                DoGameover(7);
            else
                FailMission(GetTime() + 7);
            end

            -- Halt the mission.
            Mission.m_MissionOver = true;
        end
    end

    -- If the power dies.
    if (not IsAround(Mission.m_Power)) then
        -- Show Objectives.
        AddObjectiveOverride("isdf0308.otf", "RED", 10, true);

        -- Mission failed.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("The Power Plant was destroyed.");
            DoGameover(5);
        else
            FailMission(GetTime() + 5, "isdf03l2.txt");
        end

        -- Marks this as done so we don't loop.
        Mission.m_MissionOver = true;
    end
end
