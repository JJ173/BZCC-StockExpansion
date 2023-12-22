--[[ 
    BZCC ISDF07 Lua Mission Script
    Written by AI_Unit
    Version 1.0 25-11-2023
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
local m_GameTPS = GetTPS();

-- Name of file.
local fileName = "BZX_BASE_SAVE.txt";

-- Each attack group for the player.
local attack1 = {
    {"fvscout_x", "fvsent_x"},
    {"fvsent_x", "fvsent_x"},
    {"fvtank_x", "fvtank_x"}
}

local attack2 = {
    {"fvsent_x", "fvsent_x"},
    {"fvscout_x", "fvsent_x", "fvsent_x"},
    {"fvtank_x", "fvsent_x", "fvscout_x"}
}

local attack3 = {
    {"fvsent_x", "fvtank_x"},
    {"fvsent_x", "fvtank_x", "fvsent_x"},
    {"fvtank_x", "fvsent_x", "fvsent_x"}
}

local attack4 = {
    {"fvartl_x", "fvsent_x", "fvscout_x"},
    {"fvartl_x", "fvsent_x", "fvtank_x"},
    {"fvartl_x", "fvarch_x", "fvtank_x"}
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
    m_PlayerPilotODF = "ispilo_x";
    -- Specific to mission.
    m_PlayerShipODF = "ivtank_x";

    m_Recycler = nil,
    m_Shabayev = nil,
    m_ShabPilot = nil,
    m_Dropship = nil,
    m_Animal1 = nil,
    m_Creature1 = nil,
    m_Creature2 = nil,
    m_Creature3 = nil,
    m_Creature4 = nil,
    m_ChosenShabayevInvestigationObject = nil,
    m_Scion1 = nil,
    m_Scion2 = nil,
    m_Scion3 = nil,
    m_Hunter1 = nil,
    m_Hunter2 = nil,
    m_Hunter3 = nil,
    m_ShabTankLook = nil,
    m_Ruins = nil,
    m_Nav = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionOver = false,
    m_DropshipTakeOff = false,
    m_ShabFollowRecycler = false,
    m_ShabMoving = false,
    m_BraddockScoldsPlayer = false,
    m_PlayerHasOrder = false,
    m_PlayerBuiltScavenger = false,
    m_PlayerDeployedScavenger = false,
    m_PlayerBuiltConstructor = false,
    m_PlayerBuiltPower = false,
    m_PlayerBuiltBunker = false,
    m_PlayerBuiltGunTower = false,
    m_KillersSpawned = false,
    m_StopShabPilot = false,
    m_ShabKillersSpawned = false,
    m_BuildRescueNav = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_PlayerBuildings = {},
    m_ShabayevInvestigationObjects = {
        {"inv1", GetHandle("shab_look_1")},
        {"inv2", GetHandle("shab_look_2")},
        {"inv3", GetHandle("shab_look_3")},
    },

    m_MissionDelayTime = 0,
    m_PlayerDropshipCheckTime = 0,
    m_PlayerHasOrderResetTime = 0,
    m_PlayerExtractorCount = 0,
    m_ShabayevInvestigationSwitchDelay = 0,
    m_ShabayevCallForHelpDelay = 0,
    m_ShabayevCallForHelpCount = 0,

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
    return Mission;
end

function Load(MissionData)
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();

    -- Load mission data.
	Mission = MissionData;
end

function AddObject(h)
    -- Check the team of the handle.
    local teamNum = GetTeamNum(h);

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);       
    elseif (teamNum == Mission.m_HostTeam) then
        -- Check the class.
        local class = GetClassLabel(h);

        -- This checks that Shabayev is out of her ship.
        if (IsOdf(h, "isshab_p")) then
            Mission.m_ShabPilot = h;
        end

        -- For the SavePlayerBaseToFile() function.
        if ((class == "CLASS_TURRET" or IsBuilding(h)) and class ~= "CLASS_BUILDING" and class ~= "CLASS_EXTRACTOR") then
            Mission.m_PlayerBuildings[#Mission.m_PlayerBuildings + 1] = h;
        end

        -- If it's a Scavenger, set variables.
        if (class == "CLASS_SCAVENGER") then
            -- So we can proceed to the next dialog
            Mission.m_PlayerBuiltScavenger = true;
        elseif (class == "CLASS_EXTRACTOR") then
            -- This is used to keep track of the amount of Extractors the player has.
            Mission.m_PlayerExtractorCount = Mission.m_PlayerExtractorCount + 1;
            -- So we can proceed to the next dialog
            Mission.m_PlayerDeployedScavenger = true;
        elseif (class == "CLASS_CONSTRUCTIONRIG") then
            -- So we can proceed to the next dialog
            Mission.m_PlayerBuiltConstructor = true;
        elseif (class == "CLASS_PLANT") then
            -- So we can proceed to the next dialog
            Mission.m_PlayerBuiltPower = true;
        elseif (class == "CLASS_COMMBUNKER") then
            -- So we can proceed to the next dialog
            Mission.m_PlayerBuiltBunker = true;
        elseif (class == "CLASS_TURRET") then
            -- So we can proceed to the next dialog
            Mission.m_PlayerBuiltGunTower = true;
        end
    end
end

function DeleteObject(h)
    -- Check the team of the handle.
    local teamNum = GetTeamNum(h);

    if (teamNum == Mission.m_HostTeam) then
        -- For the SavePlayerBaseToFile() function.
        if ((class == "CLASS_TURRET" or IsBuilding(h)) and class ~= "CLASS_BUILDING" and class ~= "CLASS_EXTRACTOR") then
            TableRemoveByHandle(Mission.m_PlayerBuildings, h);
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
    print("Welcome to ISDF07 (Lua)");
    print("Written by AI_Unit");
    
    if (Mission.m_IsCooperativeMode) then
        print("Cooperative mode enabled: Yes");
    else
        print("Cooperative mode enabled: No");
    end

    print("Chosen difficulty: " .. Mission.m_MissionDifficulty);
    print("Good luck and have fun :)");

    -- Remove the player ODF that is saved as part of the BZN.
    local PlayerEntryH = GetPlayerHandle();

    if (PlayerEntryH ~= nil) then
        RemoveObject(PlayerEntryH);
    end

    -- Get Team Number.
    local LocalTeamNum = GetLocalPlayerTeamNumber();

    -- Create the player for the server.
    local PlayerH = _Cooperative.SetupPlayer(LocalTeamNum, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, false, 0);

    -- Make sure we give the player control of their ship.
    SetAsUser(PlayerH, LocalTeamNum);

    -- To start the mission.
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

            -- Specific logic to send one Jak creature to the player.
            if (not IsAlive(Mission.m_Animal1)) then
                if (not IsPlayerWithinDistance("animal1", 250, _Cooperative.m_TotalPlayerCount)) then
                    -- Build our little pet.
                    Mission.m_Animal1 = BuildObject("mcjak01", 0, "animal1");

                    -- Send it to the Recycler.
                    Goto(Mission.m_Animal1, Mission.m_Recycler, 1);

                    -- Remove it's will the think.
                    SetIndependence(Mission.m_Animal1, 0);
                end
            end

            -- Run the brains for each character.
            if (Mission.m_MissionState < 17) then
                ShabayevBrain();
            end

            -- For failures.
            HandleFailureConditions();

            -- This runs to remind the player that they need to do something.
            if (Mission.m_PlayerHasOrder and Mission.m_PlayerHasOrderResetTime < Mission.m_MissionTime) then
                -- So we can run again.
                Mission.m_PlayerHasOrder = false;
            end
        end
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, false, 0);
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
        elseif (VictimHandle == Mission.m_Manson) then
            -- Fire FF message.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0555.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Ally teams to be sure.
        Ally(Mission.m_HostTeam, Mission.m_AlliedTeam);

        -- Team names for stats.
        SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
        SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

        -- Grab all of our pre-placed handles.
        Mission.m_Recycler = GetHandle("recycler");
        Mission.m_Manson = GetHandle("manson");
        Mission.m_Shabayev = GetHandle("shabayev");
        Mission.m_Dropship = GetHandle("dropship");
        Mission.m_Hunter1 = GetHandle("hunter1");
        Mission.m_Hunter2 = GetHandle("hunter2");
        Mission.m_Hunter3 = GetHandle("hunter3");
        Mission.m_ShabTankLook = GetHandle("shab_tank_look");
        Mission.m_Ruins = GetHandle("ruins");
        
        -- First set of attackers on standby.
        Mission.m_Scion1 = BuildObject(attack1[Mission.m_MissionDifficulty][1], Mission.m_EnemyTeam, "lz_attack_1");
        Mission.m_Scion2 = BuildObject(attack1[Mission.m_MissionDifficulty][2], Mission.m_EnemyTeam, "lz_attack_2");

        Follow(Mission.m_Scion2, Mission.m_Scion1);

        -- Stop the player from having control of the Recycler for now.
        Stop(Mission.m_Recycler, 1);

        -- Give Shab her name.
        SetObjectiveName(Mission.m_Shabayev, "Cmd. Shabayev");

        -- Highlight Shabayev.
        SetObjectiveOn(Mission.m_Shabayev);

        -- Give her the correct pilot.
        SetPilotClass(Mission.m_Shabayev, "isshab_p");

        -- Make sure she has good skill.
        SetSkill(Mission.m_Shabayev, 3);
        
        -- Shabayev gets maximum health for this mission.
        SetMaxHealth(Mission.m_Shabayev, 0);
        
        -- Just to see if she avoids stuff.
        SetAvoidType(Mission.m_Recycler, 1);

        -- Set Manson's team to blue.
        SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);

        -- Set custom names for our characters.
        SetObjectiveName(Mission.m_Manson, "Maj. Manson");

        -- Manson begins work on building his base.
        SetAIP("isdf0701_x.aip", Mission.m_AlliedTeam);

        -- Mask the dropship emmitters.
        MaskEmitter(Mission.m_Dropship, 0);

        -- Give the main team some scrap.
        SetScrap(Mission.m_HostTeam, 40);

        -- We need a file for this base persistance.
        WriteToFile(fileName, "", false);

        -- Spawn Creatures around the map...
        Mission.m_Creature1 = BuildObject("mcjak01", 0, "creature1");
        Mission.m_Creature2 = BuildObject("mcjak01", 0, "creature2");
        Mission.m_Creature3 = BuildObject("mcjak01", 0, "creature3");
        Mission.m_Creature4 = BuildObject("mcjak01", 0, "creature4");

        SpawnBirds(1, 5, "mcwing01", 0, "birds1");
        SpawnBirds(2, 4, "mcwing01", 0, "birds2");
        SpawnBirds(3, 6, "mcwing01", 0, "birds3");

        -- Get Manson to patrol his base perimeter.
        Patrol(Mission.m_Manson, "manson_patrol", 1);

        -- Have Shabayev look at the Recycler at the start.
        LookAt(Mission.m_Shabayev, Mission.m_Recycler, 1);

        -- So this open the dropship doors.
        SetAnimation(Mission.m_Dropship, "deploy", 1);

        -- Small delay before our dropship sound.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Play a sound.
        StartSoundEffect("dropdoor.wav", Mission.m_Dropship);

        -- Small delay before our dropship sound.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Some AI stuff..
        SetAvoidType(Mission.m_Recycler, 0);

        -- Get the Recycler to move to it's path.
        Goto(Mission.m_Recycler, "recycler_path", 0);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    -- Manson: The Landing Zone should be safe...
    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0701.wav");

    -- Set the timer for this audio clip.
    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(16.5);

    -- Send in initial attackers.
    if (IsAlive(Mission.m_Scion1)) then
        Attack(Mission.m_Scion1, Mission.m_Recycler, 1);
    end

    if (not IsAlive(Mission.m_Scion1) and IsAlive(Mission.m_Scion2)) then
        Attack(Mission.m_Scion2, Mission.m_Recycler, 1);
    end

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[5] = function()
    if (Mission.m_PlayerDropshipCheckTime < Mission.m_MissionTime and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (IsPlayerWithinDistance(Mission.m_Dropship, 30, _Cooperative.m_TotalPlayerCount)) then
            -- Pilot: "Please clear the dropship".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0444.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Wait 10 seconds before running again.
            Mission.m_PlayerDropshipCheckTime = Mission.m_MissionTime + SecondsToTurns(10);
        else
            -- Braddock: Major, I need the Commander to conduct a search...
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0740.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(12.5);

            -- Set the dropship to take off.
            SetAnimation(Mission.m_Dropship, "takeoff", 1);

            -- Sound effects.
            StartSoundEffect("dropdoor.wav", Mission.m_Dropship);

            -- Small delay for the dropship takeoff.
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[6] = function()
    if (not Mission.m_DropshipTakeOff and Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Sound effects.
        StartSoundEffect("dropleav.wav", Mission.m_Dropship);

        -- Emitters..
        StartEmitter(Mission.m_Dropship, 1);
        StartEmitter(Mission.m_Dropship, 2);

        -- So we don't loop.
        Mission.m_DropshipTakeOff = true;
    end

    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock: Roger that General.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0702.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Shab: This area is hot, can you provide support Major?
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0703.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);
    
        -- Safely kill the Dropship.
        RemoveObject(Mission.m_Dropship);

        -- Remove Shabayev's Highlight.
        SetObjectiveOff(Mission.m_Shabayev);

        -- Have the enemy ignore her for now.
        SetPerceivedTeam(Mission.m_Shabayev, Mission.m_EnemyTeam);

        -- This is where we send Shabayev to the ruins...
        Goto(Mission.m_Shabayev, "shab_to_ruins");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (not Mission.m_PlayerHasOrder) then
            -- Braddock: "Okay cooke, start by setting up the Recycler".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0704.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Show our objectives.
            AddObjectiveOverride("isdf0701.otf", "WHITE", 10, true);

            -- This sets a reminder for when the player is taking too long.
            Mission.m_PlayerHasOrderResetTime = Mission.m_MissionTime + SecondsToTurns(60);

            -- So we don't loop.
            Mission.m_PlayerHasOrder = true;
        end

        if (IsBuilding(Mission.m_Recycler)) then
            -- Set this back to false for the next part.
            Mission.m_PlayerHasOrder = false;

            -- Probe
            Goto(BuildObjectAtSafePath("fvscout_x", Mission.m_EnemyTeam, "spawn1", "safe1", _Cooperative.m_TotalPlayerCount), Mission.m_Recycler, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[9] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (not Mission.m_PlayerHasOrder) then
            -- Braddock: "Build a Scavenger and deploy it"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0708.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- Show our objectives.
            AddObjectiveOverride("isdf0702.otf", "WHITE", 10, true);

            -- This sets a reminder for when the player is taking too long.
            Mission.m_PlayerHasOrderResetTime = Mission.m_MissionTime + SecondsToTurns(60);

            -- So we don't loop.
            Mission.m_PlayerHasOrder = true;
        end

        if (Mission.m_PlayerBuiltScavenger) then
            -- Set this back to false for the next part.
            Mission.m_PlayerHasOrder = false;

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[10] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (not Mission.m_PlayerHasOrder) then
            -- Braddock: "Deploy that Scavenger"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0707.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- This sets a reminder for when the player is taking too long.
            Mission.m_PlayerHasOrderResetTime = Mission.m_MissionTime + SecondsToTurns(30);

            -- So we don't loop.
            Mission.m_PlayerHasOrder = true;
        end

        -- This checks to see if the Recycler has been deployed so we can move to the next stage.
        if (Mission.m_PlayerDeployedScavenger) then
            -- Set this back to false for the next part.
            Mission.m_PlayerHasOrder = false;

            -- Second attack wave here.
            local attackWave = attack2[Mission.m_MissionDifficulty];

            for i = 1, #attackWave do
                -- Use a Goto instead of a Attack so they can attack random things.
                Goto(BuildObjectAtSafePath(attackWave[i], Mission.m_EnemyTeam, "spawn"..i, "safe"..i, _Cooperative.m_TotalPlayerCount), Mission.m_Recycler, 1);
            end

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[11] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (not Mission.m_PlayerHasOrder) then
            -- Braddock: "Now build a Construction rig..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0710.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Show our objectives.
            AddObjectiveOverride("isdf0703.otf", "WHITE", 10, true);

            -- This sets a reminder for when the player is taking too long.
            Mission.m_PlayerHasOrderResetTime = Mission.m_MissionTime + SecondsToTurns(60);

            -- So we don't loop.
            Mission.m_PlayerHasOrder = true;
        end

        if (Mission.m_PlayerBuiltConstructor) then
            -- Set this back to false for the next part.
            Mission.m_PlayerHasOrder = false;

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[12] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (not Mission.m_PlayerHasOrder) then
            -- Braddock: "Now build your power plant..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0714.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

            -- Show our objectives.
            AddObjectiveOverride("isdf0704.otf", "WHITE", 10, true);

            -- This sets a reminder for when the player is taking too long.
            Mission.m_PlayerHasOrderResetTime = Mission.m_MissionTime + SecondsToTurns(60);

            -- So we don't loop.
            Mission.m_PlayerHasOrder = true;
        end

        if (Mission.m_PlayerBuiltPower) then
            -- Set this back to false for the next part.
            Mission.m_PlayerHasOrder = false;

            -- Probe
            Goto(BuildObjectAtSafePath("fvscout_x", Mission.m_EnemyTeam, "spawn1", "safe1", _Cooperative.m_TotalPlayerCount), Mission.m_Recycler, 1);

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[13] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (not Mission.m_PlayerHasOrder) then
            -- Braddock: "Now build your relay bunker..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0716.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

            -- Show our objectives.
            AddObjectiveOverride("isdf0705.otf", "WHITE", 10, true);

            -- This sets a reminder for when the player is taking too long.
            Mission.m_PlayerHasOrderResetTime = Mission.m_MissionTime + SecondsToTurns(60);

            -- So we don't loop.
            Mission.m_PlayerHasOrder = true;
        end

        if (Mission.m_PlayerBuiltBunker) then
            -- Set this back to false for the next part.
            Mission.m_PlayerHasOrder = false;

            -- Third attack wave here.
            local attackWave = attack3[Mission.m_MissionDifficulty];

            for i = 1, #attackWave do
                -- Use a Goto instead of a Attack so they can attack random things.
                Goto(BuildObjectAtSafePath(attackWave[i], Mission.m_EnemyTeam, "spawn"..i, "safe"..i, _Cooperative.m_TotalPlayerCount), Mission.m_Recycler, 1);
            end

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end

    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- First check to see if we need to scold the player for not deploying enough Extractors.
        if (not Mission.m_BraddockScoldsPlayer and Mission.m_PlayerExtractorCount < 2) then
            -- Braddock: "Pull it together Cooke..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0709.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- Show Objective
            AddObjective("isdf0709.otf", "WHITE");

            -- So we don't loop.
            Mission.m_BraddockScoldsPlayer = true;
        end
    end
end

Functions[14] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (not Mission.m_PlayerHasOrder) then
            -- Braddock: "Now build your Gun Tower..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0719.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

            -- Show our objectives.
            AddObjectiveOverride("isdf0706.otf", "WHITE", 10, true);

            -- This sets a reminder for when the player is taking too long.
            Mission.m_PlayerHasOrderResetTime = Mission.m_MissionTime + SecondsToTurns(60);

            -- So we don't loop.
            Mission.m_PlayerHasOrder = true;
        end

        if (Mission.m_PlayerBuiltGunTower) then
            -- Set this back to false for the next part.
            Mission.m_PlayerHasOrder = false;

            -- Fourth attack wave here.
            local attackWave = attack4[Mission.m_MissionDifficulty];

            for i = 1, #attackWave do
                local unit = attackWave[i];
                local builtUnit = BuildObjectAtSafePath(unit, Mission.m_EnemyTeam, "spawn"..i, "safe"..i, _Cooperative.m_TotalPlayerCount);

                if (IsOdf(builtUnit, "fvartl_x")) then
                    Attack(builtUnit, Mission.m_Recycler, 1);
                else
                    -- Use a Goto instead of a Attack so they can attack random things.
                    Goto(builtUnit, Mission.m_Recycler, 1);
                end
            end

            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[15] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock: "Good job Cooke.."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0723.wav");

        -- Do a small delay before Shabayev's next dialog.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(6);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1; 
    end
end

Functions[16] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Shab: "What the... is this a city?"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0728.wav");

        -- Show Objectives.
        AddObjectiveOverride("isdf0710.otf", "WHITE", 10, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[17] = function()
    -- Give the hunter units the maximum skill.
    SetSkill(Mission.m_Hunter1, 3);
    SetSkill(Mission.m_Hunter2, 3);
    SetSkill(Mission.m_Hunter3, 3);

    -- Move Shabayev to the middle of the ruins to reduce the chance of any units getting stuck
    Goto(Mission.m_Shabayev, "inv1", 1);

    -- This sends the hunter units to attack Shabayev.
    if (IsAlive(Mission.m_Hunter1)) then
        Attack(Mission.m_Hunter1, Mission.m_Shabayev, 1);
    end

    if (IsAlive(Mission.m_Hunter2)) then
        Attack(Mission.m_Hunter2, Mission.m_Shabayev, 1);
    end

    if (IsAlive(Mission.m_Hunter3)) then
        Attack(Mission.m_Hunter3, Mission.m_Shabayev, 1);
    end

    -- Restore Shabayev's health for this scenario.
    SetMaxHealth(Mission.m_Shabayev, 3500);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[18] = function()
    -- Check Shabayev's health. If she's low, have her retreat. If the hunters are also dead, have her retreat.
    if (GetCurHealth(Mission.m_Shabayev) < 900 or (not IsAlive(Mission.m_Hunter1) and not IsAlive(Mission.m_Hunter2) and not IsAlive(Mission.m_Hunter3))) then
        -- Have Shabayev retreat. 
        Retreat(Mission.m_Shabayev, "kill_shab_ship", 1);

        -- Have the hunter units ready to attack the player.
        if (IsAlive(Mission.m_Hunter1)) then
            Retreat(Mission.m_Hunter1, "ambush_retreat", 1);
        end

        if (IsAlive(Mission.m_Hunter2)) then
            Retreat(Mission.m_Hunter2, "ambush_retreat", 1);
        end

        if (IsAlive(Mission.m_Hunter3)) then
            Retreat(Mission.m_Hunter3, "ambush_retreat", 1);
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[19] = function()
    if (GetDistance(Mission.m_Shabayev, "kill_shab_ship") < 10) then
        -- Have stop and look at our invisible object.
        LookAt(Mission.m_Shabayev, Mission.m_ShabTankLook, 1);

        -- Wait a couple of seconds.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[20] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- This will have her hop out of her tank.
        HopOut(Mission.m_Shabayev);

        -- Reminder delay.
        Mission.m_ShabayevCallForHelpDelay = Mission.m_MissionTime + SecondsToTurns(60);

        -- Small delay
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);
        
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[21] = function()
    -- Have her stop.
    Defend(Mission.m_ShabPilot, 1);

    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- This will replace her tank.
        local pos = GetPosition(Mission.m_Shabayev);
        pos.y = TerrainFindFloor(pos.x, pos.z);

        -- Kill off Shabayev's original tank.
        RemoveObject(Mission.m_Shabayev);

        -- Shab: I'm in trouble Cooke...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0725.wav");

        -- Change her AI
        SetAvoidType(Mission.m_ShabPilot, 0);
        SetAvoidType(Mission.m_Ruins, 0);

        -- Build the new tank.
        Mission.m_Shabayev = BuildObject("petank", Mission.m_HostTeam, pos);

        if (not Mission.m_IsCooperativeMode) then
            CameraReady();

            -- Delay by a couple of seconds
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);
        end

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[22] = function()
    if (not Mission.m_BuildRescueNav) then
        if (not Mission.m_IsCooperativeMode) then
            CameraObject(Mission.m_Shabayev, 2, 5, -15, Mission.m_Shabayev);
        end

        if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
            if (not Mission.m_IsCooperativeMode) then
                CameraFinish();
            end

            -- Create a nav.
            Mission.m_Nav = BuildObject("ibnav", Mission.m_HostTeam, "kill_shab_ship");

            -- Set name and highlight
            SetObjectiveName(Mission.m_Nav, "Rescue");
            SetObjectiveOn(Mission.m_Nav);

            -- Show objectives.
            AddObjectiveOverride("isdf0707.otf", "WHITE", 10, true);

            -- So we don't loop.
            Mission.m_BuildRescueNav = true;
        end
    end

    -- Build 5 Warriors to attack.
    if (not Mission.m_KillersSpawned) then
        if (IsPlayerWithinDistance("spawn_killers", 150, _Cooperative.m_TotalPlayerCount)) then
            for i = 1, 5 do
                -- Build units.
                local unit = BuildObject("fvtank_x", Mission.m_EnemyTeam, "killer"..i);

                -- Send them to patrol.
                Patrol(unit, "ruin_patrol", 1);
            end

            -- So we don't loop.
            Mission.m_KillersSpawned = true;
        end
    end

    -- This will do a distance check on the player to make sure they get to Shabayev.
    if (IsPlayerWithinDistance(Mission.m_ShabPilot, 50, _Cooperative.m_TotalPlayerCount)) then
        -- Shabayev: "Cooke, I'm hurt..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0729.wav");

        -- Get any remaining hunters to attack.
        if (IsAlive(Mission.m_Hunter1)) then
            Attack(Mission.m_Hunter1, Mission.m_Shabayev);
        end

        if (IsAlive(Mission.m_Hunter2)) then
            Attack(Mission.m_Hunter2, Mission.m_Shabayev);
        end

        if (IsAlive(Mission.m_Hunter3)) then
            Attack(Mission.m_Hunter3, GetPlayerHandle(1));
        end

        -- Tell Shab to get inside the ruin.
        Retreat(Mission.m_ShabPilot, Mission.m_Ruins, 1);

        -- Set Objectives...
        AddObjectiveOverride("isdf0708.otf", "WHITE", _Cooperative.m_TotalPlayerCount);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    elseif (Mission.m_ShabayevCallForHelpDelay < Mission.m_MissionTime) then
        if (Mission.m_ShabayevCallForHelpCount < 2) then
            -- Shab: I'm in trouble Cooke...
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0725.wav");

            -- Show objectives.
            AddObjectiveOverride("isdf0707.otf", "WHITE", 10, true);

            -- Reminder delay.
            Mission.m_ShabayevCallForHelpDelay = Mission.m_MissionTime + SecondsToTurns(60);

            -- Increase the counter.
            Mission.m_ShabayevCallForHelpCount = Mission.m_ShabayevCallForHelpCount + 1;
        elseif (not Mission.m_ShabKillersSpawned) then
            -- Spawn the killers.
            Attack(BuildObject("fvsent_x", Mission.m_EnemyTeam, "safe1"), Mission.m_ShabPilot, 1);
            Attack(BuildObject("fvsent_x", Mission.m_EnemyTeam, "safe2"), Mission.m_ShabPilot, 1);
            Attack(BuildObject("fvsent_x", Mission.m_EnemyTeam, "safe3"), Mission.m_ShabPilot, 1);

            -- So we don't loop.
            Mission.m_ShabKillersSpawned = true;
        end
    end
end

Functions[23] = function()
    -- This will make Shabayev stop in the ruin.
    if (not Mission.m_StopShabPilot) then
        if (GetDistance(Mission.m_ShabPilot, "shab_stop") < 10) then
            -- Have her stop.
            Defend(Mission.m_ShabPilot, 1);

            -- So we don't loop.
            Mission.m_StopShabPilot = true;
        end
    end

    -- Does a check to make sure we are on foot.
    if (GetDistance(Mission.m_ShabPilot, Mission.m_Ruins) < 30 and IsPlayerWithinDistance(Mission.m_Ruins, 20, _Cooperative.m_TotalPlayerCount)) then
        for i = 1, _Cooperative.m_TotalPlayerCount do
            local class = GetClassLabel(GetPlayerHandle(i));

            if (class ~= "CLASS_PERSON") then
                return;
            else
                -- For use in later missions.
                SavePlayerBaseToFile();

                -- Shab: "It looks like we're trapped".
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0731.wav");

                -- Advance the mission state...
                Mission.m_MissionState = Mission.m_MissionState + 1;
            end
        end
    end
end

Functions[24] = function()
    -- Game over.
    if (Mission.m_IsCooperativeMode) then
        NoteGameoverWithCustomMessage("Mission Accomplished.");
        DoGameover(5);
    else
        SucceedMission(GetTime() + 5, "isdf07w1.txt");
    end

    -- So we don't loop.
    Mission.m_MissionOver = true;
end

function SavePlayerBaseToFile()
    -- This function will save the position of each building from the player. 
    -- The file will be loaded up in ISDF08 and ISDF09 as a ruined base. 
    local body = "PLEASE DO NOT MODIFY! THIS FILE IS AUTO-GENERATED. CHANGING THE VALUES MAY AFFECT YOUR GAMEPLAY EXPERIENCE.";

    -- When a player has built stuff, loop through the table and note it's position.
    for i = 1, #Mission.m_PlayerBuildings do
        -- Start on a new line for each building.
        body = body .. "\n";
        
        -- Get the building from the table.
        local building = Mission.m_PlayerBuildings[i];

        if (building ~= nil) then
            -- Grab the ODF name of the building.
            local odfName = GetCfg(building);

            -- Get the position of the building.
            local pos = tostring(GetPosition(building));

            -- Append both to the body of the file.
            body = body .. odfName .. " - " .. pos;
        end
    end

    -- Write to our file.
    local success = WriteToFile(fileName, body, true);

    -- Test
    if (success) then
        print("Write file succeeded.");
    else
        print("Write file failed.");
    end

    print(success);
end

function ShabayevBrain()
    -- Have Shabayev follow the Recycler at the start of the mission.
    if (not Mission.m_ShabFollowRecycler) then
        if (GetDistance(Mission.m_Recycler, "recycler_stop") < 30) then
            -- Tell her to follow.
            Follow(Mission.m_Shabayev, Mission.m_Recycler, 1); 

            -- So we don't loop.
            Mission.m_ShabFollowRecycler = true;
        end
    end

    -- Do a check to see when Shabayev reaches the ruins.
    if (not Mission.m_ShabInvestigationActive) then
        if (GetDistance(Mission.m_Shabayev, "shab_start_investigation") < 50) then
            -- So we don't loop annd we can start the next section of behaviour.
            Mission.m_ShabInvestigationActive = true;
        end
    end

    -- Shabayev will randomly investigate the ruins before she is injured.
    if (Mission.m_ShabInvestigationActive and not Mission.m_ShabayevHunted) then
        -- Do a delay check to she doesn't randomly switch.
        if (Mission.m_ShabayevInvestigationSwitchDelay < Mission.m_MissionTime) then
            if (not Mission.m_ShabMoving) then
                -- Random chance between 1 and 3.
                local chance = GetRandomFloat(0, 3);

                -- Normalize the float to the highest int.
                local normalizedChance = math.ceil(chance);

                -- Choose the dictionary that she will use for this loop.
                Mission.m_ChosenShabayevInvestigationObject = Mission.m_ShabayevInvestigationObjects[normalizedChance];

                -- Make sure it's not nil.
                if (Mission.m_ChosenShabayevInvestigationObject ~= nil) then
                    -- Send her to the destination.
                    Goto(Mission.m_Shabayev, Mission.m_ChosenShabayevInvestigationObject[1], 1);

                    -- Make sure we set this to true.
                    Mission.m_ShabMoving = true;
                end
            else
                -- Do a distance check to make sure she's moving.
                if (GetDistance(Mission.m_Shabayev, Mission.m_ChosenShabayevInvestigationObject[1]) < 30) then
                    -- Have Shabayev look at the object of interest.
                    LookAt(Mission.m_Shabayev, Mission.m_ChosenShabayevInvestigationObject[2], 1);

                    -- So we go back to the original loop.
                    Mission.m_ShabMoving = false;

                    -- Set a time so she stays idle whilst looking for a while.
                    Mission.m_ShabayevInvestigationSwitchDelay = Mission.m_MissionTime + SecondsToTurns(7);
                end
            end
        end
    end
end

function HandleFailureConditions()   
    if (not IsAlive(Mission.m_Recycler)) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Show objectives.
        AddObjectiveOverride("isdf0523.otf", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Recycler was destroyed.");
            DoGameover(5);
        else
            FailMission(GetTime() + 5, "isdf07l1.txt");
        end
    end

    -- Run a check to see if Shabayev is alive.
    if (Mission.m_MissionState >= 22) then
        if (not IsAlive(Mission.m_ShabPilot)) then
            -- Stop the mission.
            Mission.m_MissionOver = true;

            -- Shab: They're all over me!
            _Subtitles.AudioWithSubtitles("isdf0732.wav");

            -- Show objectives.
            AddObjectiveOverride("isdf05l1.otf", "RED", 10, true);

            -- Failure.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("Shabayev was killed.");
                DoGameover(5);
            else
                FailMission(GetTime() + 5, "isdf05l1.txt");
            end
        end
    end
end