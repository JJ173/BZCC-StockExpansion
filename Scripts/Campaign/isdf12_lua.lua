--[[ 
    BZCC ISDF12 Lua Mission Script
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

    m_Manson = nil,
    m_PoolNav1 = nil,
    m_PoolNav2 = nil,
    m_PoolNav3 = nil,
    m_BaseScav = nil,
    m_EmptyScav1 = nil,
    m_EmptyScav2 = nil,
    m_BasePool = nil,
    m_Dead1 = nil,
    m_Dead2 = nil,
    m_Dead3 = nil,
    m_GunTower1 = nil,
    m_GunTower2 = nil,
    m_GunTower3 = nil,
    m_CommBunker1 = nil,
    m_Armory = nil,
    m_Factory = nil,
    m_ServiceBay = nil,
    m_Training = nil,
    m_Scav1 = nil,
    m_Tank1 = nil,
    m_Tank2 = nil,
    m_Scout1 = nil,
    m_Scout2 = nil,
    m_Rocket1 = nil,
    m_Alchemator = nil,
    m_KeyDevice = nil,
    m_Tug = nil,
    m_Constructor = nil,
    m_Power1 = nil,
    m_Power2 = nil,

    m_StartingWave = {},

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionStartDone = false,
    m_MissionOver = false,
    m_IntroDialogPlayed = false,
    m_IntroObjectivesDisplayed = false,
    m_BasePoweredDialogPlayed = false,
    m_TrainingDialogPlayed = false,
    m_MansonExplainsObjectiveDialogPlayed = false,
    
    m_Audioclip = nil,

    m_IntroAudioDelay = 0,
    m_PlayerPowerCount = 0,

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
    PreloadODF("ivtank_x");
    PreloadODF("fvsent_x");
    PreloadODF("fvtank_x");
    PreloadODF("fbrecy_x");
    PreloadODF("ibfact_x");
    PreloadODF("fvturr_x");
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
    local teamNum = GetTeamNum(h);

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);
        
        -- Pilots are forbidden in this mission.
        if (not IsBuilding(h)) then
            SetEjectRatio(h, 0);
        end
    elseif (teamNum == Mission.m_HostTeam) then
        if (Mission.m_IntroObjectivesDisplayed) then
            -- If we have enough scrap when an Extractor is deployed, show objectives.
            local class = GetClassLabel(h);

            -- If we have 3 extractors deployed, show this.
            if (class == "CLASS_EXTRACTOR" and GetMaxScrap(Mission.m_HostTeam) == 60) then
                RefreshObjectives();
            end

            -- If we are in positive power, show this.
            if (class == "CLASS_PLANT" and Mission.m_PlayerPowerCount >= 0) then
                RefreshObjectives();
            end
        end
    end
end

function DeleteObject(h)
    local teamNum = GetTeamNum(h);

    if (teamNum == Mission.m_HostTeam) then
        if (Mission.m_IntroObjectivesDisplayed) then
            -- If we have enough scrap when an Extractor is deployed, show objectives.
            local class = GetClassLabel(h);

            -- If we have 2 extractors deployed, show this.
            if (class == "CLASS_EXTRACTOR" and GetMaxScrap(Mission.m_HostTeam) < 60) then
                RefreshObjectives();
            end

            -- If we are in negative power, show this.
            if (class == "CLASS_PLANT" and Mission.m_PlayerPowerCount < 0) then
                RefreshObjectives();
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

    -- Few prints to console.
    print("Welcome to ISDF12 (Lua)");
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
    local PlayerH = _Cooperative.SetupPlayer(LocalTeamNum, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, true, 100);

    -- Make sure we give the player control of their ship.
    SetAsUser(PlayerH, LocalTeamNum);

    -- Grab all of our pre-placed handles.
    Mission.m_Manson = GetHandle("manson");
    Mission.m_Alchemator = GetHandle("bigass_machine");
    Mission.m_PoolNav1 = GetHandle("pool1_nav");
    Mission.m_PoolNav2 = GetHandle("pool2_nav");
    Mission.m_PoolNav3 = GetHandle("pool3_nav");
    Mission.m_BaseScav = GetHandle("base_scav");
    Mission.m_BasePool = GetHandle("base_pool");
    Mission.m_Dead1 = GetHandle("dead1");
    Mission.m_Dead2 = GetHandle("dead2");
    Mission.m_Dead3 = GetHandle("dead3");
    Mission.m_Scav1 = GetHandle("scav1");
    Mission.m_Tank1 = GetHandle("tank1");
    Mission.m_Tank2 = GetHandle("tank2");
    Mission.m_ServiceBay = GetHandle("service");
    Mission.m_Factory = GetHandle("factory");
    Mission.m_Armory = GetHandle("armory");
    Mission.m_Training = GetHandle("training");
    Mission.m_CommBunker1 = GetHandle("commbunk1");
    Mission.m_GunTower1 = GetHandle("guntower1");
    Mission.m_GunTower2 = GetHandle("guntower2");
    Mission.m_GunTower3 = GetHandle("guntower3");
    Mission.m_EmptyScav1 = GetHandle("empty_scav1");
    Mission.m_EmptyScav2 = GetHandle("empty_scav2");
    Mission.m_KeyDevice = GetHandle("key_device");
    Mission.m_Constructor = GetHandle("constructor");
    Mission.m_Tug = GetHandle("tug");
    Mission.m_Power1 = GetHandle("power1");
    Mission.m_Power2 = GetHandle("power2");

    -- Kill pilots of these ships.
    RemovePilot(Mission.m_Dead1);
    RemovePilot(Mission.m_Dead2);
    RemovePilot(Mission.m_Dead3);
    RemovePilot(Mission.m_EmptyScav1);
    RemovePilot(Mission.m_EmptyScav2);

    -- Set names where needed
    SetObjectiveName(Mission.m_PoolNav1, "Biometal Pool");
    SetObjectiveName(Mission.m_PoolNav2, "Biometal Pool");
    SetObjectiveName(Mission.m_PoolNav3, "Biometal Pool");

    -- Send the base scav straight to the base pool.
    Goto(Mission.m_BaseScav, Mission.m_BasePool, 1);

    -- Stop the Scavenger.
    Defend(Mission.m_Scav1, 0);

    if (Mission.m_MissionDifficulty == 1) then
        SetGroup(BuildObject("ivcons_x", Mission.m_HostTeam, "train_point"), 4);
    end

    -- Damage each base building.
    SetCurHealth(Mission.m_Armory, 1500);
    SetCurHealth(Mission.m_CommBunker1, 1500);
    SetCurHealth(Mission.m_Factory, 5000);
    SetCurHealth(Mission.m_ServiceBay, 5000);

    -- Keep the Alchemator and it's power source alive.
    SetMaxHealth(Mission.m_Alchemator, 0);
    SetMaxHealth(Mission.m_KeyDevice, 0);

    -- Manson should be kept alive.
    SetMaxHealth(Mission.m_Manson, 0);

    -- Set Manson's skill to 3.
    SetSkill(Mission.m_Manson, 3);

    -- Set Manson's team to blue.
    SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);

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

            -- This keeps track of the players power count.
            Mission.m_PlayerPowerCount = GetPower(Mission.m_HostTeam);

            -- Play a one-off dialog if the base's power is restored.
            if (not Mission.m_BasePoweredDialogPlayed and Mission.m_PlayerPowerCount >= 0) then
                if (IsAudioMessageDone(Mission.m_Audioclip)) then
                    if (GetMaxScrap(Mission.m_HostTeam) < 60) then
                        -- Pilot: Nice thinking sir.
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1206.wav");
                    else
                        -- Manson: Power has been restored. Good job.
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1205.wav");
                    end

                    RefreshObjectives();

                    -- So we don't loop.
                    Mission.m_BasePoweredDialogPlayed = true;
                end
            end

            -- Check for any failure conditions.
            HandleFailureConditions();
        end
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF, true, 100);
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
    -- Create a delay before the first dialog is played.
    Mission.m_IntroAudioDelay = Mission.m_MissionTime + SecondsToTurns(3);

    -- Show objectives.
    AddObjective("isdf1201.otf", "WHITE");

    -- Spawn the first attackers.
    for i = 1, 5 do
        -- For the first 2 attackers, use the sentry spawns.
        local path = nil;
        local unit = nil;

        -- Anything above 2, use warrior spawns.
        if (i < 3) then
            path = "sent" .. i .. "_spawn"
            unit = BuildObject("fvsent_x", Mission.m_EnemyTeam, path);
        else
            path = "war" .. (i - 2) .. "_spawn";
            unit = BuildObject("fvtank_x", Mission.m_EnemyTeam, path);
        end

        -- So they all don't face the same direction.
        SetRandomHeadingAngle(unit);

        -- Add the unit to a table that we use to check and make sure all units are dead.
        Mission.m_StartingWave[#Mission.m_StartingWave + 1] = unit;
    end

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (not Mission.m_IntroDialogPlayed) then
        if (Mission.m_IntroAudioDelay < Mission.m_MissionTime) then
            -- Pilot: Glad you could drop in sir!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1201.wav");

            -- Destroy the third Gun Tower.
            Damage(Mission.m_GunTower3, 5001);

            -- So we don't loop.
            Mission.m_IntroDialogPlayed = true;
        end
    elseif (not Mission.m_IntroObjectivesDisplayed) then
        if (IsAudioMessageDone(Mission.m_Audioclip)) then
            -- Show objectives.
            AddObjective("isdf1202.otf", "WHITE");

            -- So we don't loop.
            Mission.m_IntroObjectivesDisplayed = true;
        end
    end

    -- Empty tanks took some damage.
    SetCurHealth(Mission.m_Dead1, 1100);
    SetCurHealth(Mission.m_Dead2, 900);
    SetCurHealth(Mission.m_Dead3, 1250);

    -- Gun Towers took some damage.
    SetCurHealth(Mission.m_GunTower1, 1200);
    SetCurHealth(Mission.m_GunTower2, 1500);

    -- This keeps stuff alive during this attack.
    if (GetCurHealth(Mission.m_Constructor) < 500) then
        SetCurHealth(Mission.m_Constructor, 500);
    end

    if (GetCurHealth(Mission.m_Tug) < 500) then
        SetCurHealth(Mission.m_Tug, 500);
    end

    if (GetCurHealth(Mission.m_Factory) < 1000) then
        SetCurHealth(Mission.m_Factory, 1000);
    end

    if (GetCurHealth(Mission.m_ServiceBay) < 1000) then
        SetCurHealth(Mission.m_ServiceBay, 1000);
    end

    if (GetCurHealth(Mission.m_Armory) < 1000) then
        SetCurHealth(Mission.m_Armory, 1000);
    end

    if (GetCurHealth(Mission.m_Training) < 1000) then
        SetCurHealth(Mission.m_Training, 1000);
    end

    if (GetCurHealth(Mission.m_CommBunker1) < 1000) then
        SetCurHealth(Mission.m_CommBunker1, 1000);
    end

    if (GetCurHealth(Mission.m_Power1) < 1000) then
        SetCurHealth(Mission.m_Power1, 1000);
    end

    if (GetCurHealth(Mission.m_Power2) < 1000) then
        SetCurHealth(Mission.m_Power2, 1000);
    end

    if (GetCurHealth(Mission.m_GunTower1) < 1000) then
        SetCurHealth(Mission.m_GunTower1, 1000);
    end

    if (GetCurHealth(Mission.m_GunTower2) < 1000) then
        SetCurHealth(Mission.m_GunTower2, 1000);
    end

    -- This checks to make sure all spawned attackers are dead.
    for i = 1, #Mission.m_StartingWave do
        if (IsAlive(Mission.m_StartingWave[i])) then
            return;
        end
    end

    -- Otherwise we can safely advance to the next part of the mission.
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[3] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Manson: They just keep coming!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1202.wav");

        -- Have Manson look at the main player when he talks.
        LookAt(Mission.m_Manson, GetPlayerHandle(1), 1);

        -- Highlight Manson.
        SetObjectiveOn(Mission.m_Manson);

        -- Show Objectives.
        AddObjectiveOverride("isdf1201.otf", "GREEN", 10, true); 
        AddObjective("isdf1202.otf", "WHITE");

        -- Set up the AIP here.
        SetAIP("isdf120" .. Mission.m_MissionDifficulty .. "_x.aip", Mission.m_EnemyTeam);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Name the key power source
        SetObjectiveName(Mission.m_KeyDevice, "Power Source");

        -- Send Manson to patrol
        Patrol(Mission.m_Manson, "manson_patrol", 1);

        -- Highlight it
        SetObjectiveOn(Mission.m_KeyDevice);

        -- Show Objectives.
        RefreshObjectives();

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- Check just incase the "Power Restored" dialog is playing.
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- If the player goes near the empty Scavs, Manson will get them to tow them.
        if (not Mission.m_TrainingDialogPlayed) then
            local check1 = IsPlayerWithinDistance(Mission.m_EmptyScav1, 70, _Cooperative.m_TotalPlayerCount);
            local check2 = IsPlayerWithinDistance(Mission.m_EmptyScav2, 70, _Cooperative.m_TotalPlayerCount);
            local check3 = GetDistance(Mission.m_Tug, Mission.m_EmptyScav1) < 70;
            local check4 = GetDistance(Mission.m_Tug, Mission.m_EmptyScav2) < 70;

            if (check1 or check2 or check3 or check4) then
                if (Mission.m_BasePoweredDialogPlayed) then
                    -- Manson: We can get pilots into those Scavs.
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1207.wav");
                else
                    -- Manson: We can get pilots into those Scavs when the base is powered up..
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1208.wav");
                end

                -- Show Objectives.
                AddObjective("isdf1205.otf", "WHITE");

                -- So we don't loop.
                Mission.m_TrainingDialogPlayed = true;
            end
        end

        if (not Mission.m_MansonExplainsObjectiveDialogPlayed) then
            if (Mission.m_BasePoweredDialogPlayed) then
                -- Manson: Okay Cooke, here's what we need to do...
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1220.wav");

                -- So we don't loop.
                Mission.m_MansonExplainsObjectiveDialogPlayed = true;
            end
        end

        -- Mission is a success.
        if (not Mission.m_MissionOver) then
            if (IsAlive(Mission.m_KeyDevice) and IsAlive(Mission.m_Tug)) then
                -- Check to see what is carrying the power source.
                local tugger = GetTug(Mission.m_KeyDevice);

                if (GetTeamNum(tugger) == Mission.m_HostTeam or tugger == Mission.m_Tug) then
                    -- Manson: Well done. You've successfully shut down the weapon.
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1203.wav");

                    if (Mission.m_IsCooperativeMode) then
                        NoteGameoverWithCustomMessage("Mission Accomplished.");
                        DoGameover(7);
                    else
                        SucceedMission(GetTime() + 7, "isdf12w1.txt");
                    end
        
                    -- So we don't loop.
                    Mission.m_MissionOver = true; 
                end
            end
        end
    end
end

function RefreshObjectives()
    local maxScrap = GetMaxScrap(Mission.m_HostTeam);

    -- Clear the panel to start again.
    ClearObjectives(); 

    AddObjective("isdf1203.otf", "WHITE");
    AddObjective("isdf1204.otf", "WHITE");
    AddObjective("isdf1206.otf", "WHITE");

    if (GetMaxScrap(Mission.m_HostTeam) < 60) then
        AddObjective("isdf1207.otf", "WHITE");
    else
        AddObjective("isdf1207.otf", "GREEN");
    end
    

    if (Mission.m_PlayerPowerCount < 0) then
        AddObjective("isdf1202.otf", "WHITE");
    else
        AddObjective("isdf1202.otf", "GREEN");
    end

    if (Mission.m_TrainingDialogPlayed) then
        AddObjective("isdf1205.otf", "WHITE");
    end
end

function HandleFailureConditions()
    -- Recycler is dead, mission failed.
    if (not IsAround(Mission.m_Tug) and not Mission.m_MissionOver) then
        -- Objectives.
        AddObjectiveOverride("isdf0408.otf", "RED", 10, true);

        -- Just incase anything is playing.
        StopAudioMessage(Mission.m_Audioclip);

        -- Have Manson say the tug is dead.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1204.wav");

        -- Mission failed.
        Mission.m_MissionOver = true;

        -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("You lost the Tug!");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf12l1.txt");
        end
    end
end