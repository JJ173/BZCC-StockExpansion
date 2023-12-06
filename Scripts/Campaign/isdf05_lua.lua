--[[ 
    BZCC ISDF05 Lua Mission Script
    Written by AI_Unit
    Version 1.0 16-10-2022
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
local m_ConstructorBuildDelay = {15, 20, 30};
local m_ScionAttackCount = {2, 3, 4};
local m_ScionPlayerAttacker = {"fvscout", "fvsent", "fvtank"};
local m_ScionFirstPoolGuard = {"fvsent", "fvtank", "fvarch"};
local m_ScionFirstLurker = {"fvscout", "fvsent", "fvtank"};
local m_ScionSecondLurker = {"fvsent", "fvtank", "fvarch"};

-- Mission important variables.
local Mission = 
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "ispilo";
    -- Specific to mission.
    m_PlayerShipODF = "ivtank";

    m_Recycler = nil,
    m_Scavenger = nil,
    m_Scavenger2 = nil,
    m_Scavenger3 = nil,
    m_Constructor = nil,
    m_Power1 = nil,
    m_Power2 = nil,
    m_Factory = nil,
    m_Bunker = nil,
    m_GunTower = nil,
    m_GunTower2 = nil,
    m_Shabayev = nil,
    m_ShabayevPilot = nil,
    m_Dropship = nil,
    m_Audioclip = nil,
    m_Manson = nil,
    m_Blue1 = nil,
    m_Blue2 = nil,
    m_Teleportal = nil,
    m_Enemy1 = nil,
    m_Enemy2 = nil,
    m_Enemy3 = nil,
    m_Enemy4 = nil,
    m_Nav1 = nil,
    m_Nav2 = nil,
    m_RescueScout = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_SentRecycler = false,
    m_SentScavenger = false,
    m_DropshipTakeoff = false,

    m_MissionStartDone = false,
    m_MissionConstructionStateActive = false,
    m_MissionScionAttackStateActive = false,
    m_MissionScavengerStateActive = false,
    m_MissionMansonStateActive = false,

    m_PlayFirstCutscene = false,
    m_ExpectingRescueScout = false,
    m_ConstructorBuildOrderGiven = false,
    m_ConstructorDropoffGiven = false,
    m_RecyclerBuildingConstructor = false,
    m_RecyclerBuildingRescueScout = false,
    m_HandleTurretWarning = false,
    m_ShabAttacking = false,
    m_MansonWaiting = true,
    m_MansonGunTowerMessage = false,
    m_SpawnedFirstLurker = false,
    m_SpawnedSecondLurker = false,
    m_MansonRetreating = false,
    m_PlayCanopyMessage = false,

    m_FirstCutsceneTime = 0,
    m_FirstPowerAttackTime = 0,
    m_ConstructorCommandDelay = 0,
    m_ConstructorBuildTime = 0,
    m_ScionAttackDelay = 0,
    m_MortarBikeTime = 0,
    m_ConstructorMovieTime = 0,
    m_MansonDelayTime = 0,
    m_MansonNagTime = 0,
    m_MissionGunTowerTimer = 0,
    m_DeployedScavCounter = 0,
    m_ScionAttackCounter = 0,

    m_ShabayevState = SHAB_OKAY,

    -- Steps for each section.
    m_MissionStartStage = 0,
    m_MissionConstructionStage = 0,
    m_MissionScionAttackStage = 0,
    m_MissionScavengerStage = 0,
    m_MissionMansonStage = 0,
}

---------------------------
-- Event Driven Functions
---------------------------
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
    PreloadODF("ivrec5");
    PreloadODF("ivtank");
    PreloadODF("fbspir");
    PreloadODF("fvturr");
    PreloadODF("ivscav");
    PreloadODF("ivpdrop2");
    PreloadODF("fvsent");
    PreloadODF("fvscout");
    PreloadODF("fvtank");
    PreloadODF("fvarch");
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
    -- Grab the ODF name.
    local ODFName = GetCfg(h);
    local class = GetClassLabel(h);

    -- Handle unit skill for enemy.
    if (GetTeamNum(h) == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);       
    end

    -- Pre-placed Scion objects are set on Team 2. We should move them to Team 6.
    if (ODFName == "fvturr" or ODFName == "fbspir" or ODFName == "fblung") then
        SetTeamNum(h, Mission.m_EnemyTeam);
    elseif (ODFName == "ivcon5_fix") then
        Mission.m_RecyclerBuildingConstructor = false;
        Mission.m_ConstructorCommandDelay = Mission.m_MissionTime + SecondsToTurns(8);
        Mission.m_Constructor = h;
    elseif (ODFName == "ibgtow") then
        -- Make sure we keep track of each Gun Tower.
        if (not IsAround(Mission.m_GunTower)) then
            Mission.m_GunTower = h;
        elseif (not IsAround(Mission.m_GunTower2)) then
            Mission.m_GunTower2 = h;
        end

        -- A bit of time between buildings.
        Mission.m_ConstructorCommandDelay = Mission.m_MissionTime + SecondsToTurns(m_ConstructorBuildDelay[Mission.m_MissionDifficulty]);

        Mission.m_ConstructorBuildOrderGiven = false;
        Mission.m_ConstructorDropoffGiven = false;
    elseif (ODFName == "ibpge5_fix") then
        if (not IsAround(Mission.m_Power1)) then
            Mission.m_FirstPowerAttackTime = Mission.m_MissionTime + SecondsToTurns(20);
            Mission.m_Power1 = h;
        else 
            Mission.m_Power2 = h;
        end

        -- A bit of time between buildings.
        Mission.m_ConstructorCommandDelay = Mission.m_MissionTime + SecondsToTurns(m_ConstructorBuildDelay[Mission.m_MissionDifficulty]);

        Mission.m_ConstructorBuildOrderGiven = false;
        Mission.m_ConstructorDropoffGiven = false;
    elseif (ODFName == "ibcbu5") then
        -- A bit of time between buildings.
        Mission.m_ConstructorCommandDelay = Mission.m_MissionTime + SecondsToTurns(m_ConstructorBuildDelay[Mission.m_MissionDifficulty]);

        Mission.m_Bunker = h;
        Mission.m_ConstructorBuildOrderGiven = false;
        Mission.m_ConstructorDropoffGiven = false;
    elseif (ODFName == "isshab_p") then
        -- Keep track of her pilot.
        Mission.m_ShabayevPilot = h;
    elseif (ODFName == "ivscout") then
        if (Mission.m_ExpectingRescueScout) then
            Mission.m_RecyclerBuildingRescueScout = false;
            Mission.m_RescueScout = h;
        end
    elseif (ODFName == "ibscav") then
        Mission.m_DeployedScavCounter = Mission.m_DeployedScavCounter + 1;
    end

    -- Check to see if the Satchel has been placed.
    if (Mission.m_MissionMansonStage >= 5 and class == "CLASS_SATCHELCHARGE" and not Mission.m_MansonRetreating) then
        -- Retreat!
        SetIndependence(Mission.m_Manson, 0);
        SetIndependence(Mission.m_Blue1, 0);
        SetIndependence(Mission.m_Blue2, 0);

        -- Go to the previous path.
        Retreat(Mission.m_Manson, "manson_path1", 1);
        Retreat(Mission.m_Blue1, "manson_path1", 1);
        Retreat(Mission.m_Blue2, "manson_path1", 1);

        -- Play our audio.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0542.wav");

        -- So we don't loop.
        Mission.m_MansonRetreating = true;
    end
end

function DeleteObject(h)
    -- Run a check here to see if the Satchel has been placed within range of the Teleportal.
    local class = GetClassLabel(h);

    -- If the satchel was placed within 50 meters, destroy the teleportal.
    if (class == "CLASS_SATCHELCHARGE" and IsAround(Mission.m_Teleportal)) then
        if (GetDistance(h, Mission.m_Teleportal) <= 75) then
            -- Kill it.
            Damage(Mission.m_Teleportal, 99999);
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
    print("Welcome to ISDF05 (Lua)");
    print("Written by AI_Unit");
    
    if (Mission.m_IsCooperativeMode) then
        print("Cooperative mode enabled: Yes");
    else
        print("Cooperative mode enabled: No");
    end

    print("Chosen difficulty: " .. Mission.m_MissionDifficulty);
    print("Good luck and have fun :)");

    -- Allied team is Squad Blue.
    SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);

    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "Blue Squad");

    -- Ally teams to be sure.
    Ally(Mission.m_HostTeam, Mission.m_AlliedTeam);

    -- There are some neutral Scavengers near the teleport.
    Mission.m_Scavenger2 = GetHandle("ivscav1");
    Mission.m_Scavenger3 = GetHandle("ivscav2");

    -- Stop them from collecting any loose.
    KillPilot(Mission.m_Scavenger2);
    KillPilot(Mission.m_Scavenger3);

    -- Grab the "Excavator"
    Mission.m_Teleportal = GetHandle("unnamed_ibtele");
    -- Set it's name.
    SetObjectiveName(Mission.m_Teleportal, TranslateString("Mission0503"));

    -- Create Shabayev.
    Mission.m_Shabayev = BuildObject("ivtank", Mission.m_HostTeam, "shab_start");
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

    -- Create Recycler.
    Mission.m_Recycler = BuildObject("ivrec5_fix", Mission.m_HostTeam, "recy_start");
    -- Do not allow control of the Recycler.
    Stop(Mission.m_Recycler, 1);

    -- Create first Scavenger.
    Mission.m_Scavenger = GetHandle("scav3");
    -- Send it to the first pool.
    Goto(Mission.m_Scavenger, GetHandle("poolx"), 1);

    -- Get the Dropship.
    Mission.m_Dropship = GetHandle("unnamed_ivpdrop2");
    -- Make it immortal.
    SetMaxHealth(Mission.m_Dropship, 0);

    -- Build Manson and his squad.
    Mission.m_Manson = BuildObject("ivtank", Mission.m_AlliedTeam, "manson_start");
    Mission.m_Blue1 = BuildObject("ivtank", Mission.m_AlliedTeam, "manson_escort1");
    Mission.m_Blue2 = BuildObject("ivtank", Mission.m_AlliedTeam, "manson_escort2");

    -- Name them.
    SetObjectiveName(Mission.m_Manson, "Maj. Manson");
    SetObjectiveName(Mission.m_Blue1, "Sgt. Zdarko");
    SetObjectiveName(Mission.m_Blue2, "Sgt. Masiker");

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

    -- Give the player some scrap.
    SetScrap(Mission.m_HostTeam, 40);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;
end

function Update()
    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Start mission logic.
    if (Mission.m_StartDone) then
        HandleMissionLogic();
    end
end

function AddPlayer(id, Team, IsNewPlayer)
    return _Cooperative.AddPlayer(id, Team, IsNewPlayer, Mission.m_PlayerShipODF, Mission.m_PlayerPilotODF);
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
    -- Handle Shabayev getting into the rescue Scout.
    if (emptyCraftHandle == Mission.m_RescueScout) then
        -- Reset this variable for future use.
        Mission.m_RescueScout = nil;

        if (pilotHandle == Mission.m_ShabayevPilot) then
            -- Set Shabayev's variable to the new ship.
            Mission.m_Shabayev = emptyCraftHandle;

            -- Reset the team back to 1.
            SetTeamNum(emptyCraftHandle, Mission.m_HostTeam);

            -- Rename the Scout.
            SetObjectiveName(emptyCraftHandle, "Cmd. Shabayev");
            SetObjectiveOn(emptyCraftHandle);
            SetSkill(emptyCraftHandle, 3);

            -- Resume previous order of defending Constructor.
            Defend2(emptyCraftHandle, Mission.m_Constructor, 1);

            -- Make sure Shabayev is set back to her good state.
            Mission.m_ShabayevState = SHAB_OKAY;
        end
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

---------------------------
-- Mission Related Logic
---------------------------
function HandleMissionLogic()
    if (not Mission.m_MissionOver) then
        if (not Mission.m_MissionStartDone) then
            HandleMissionStart();
        end

        if (Mission.m_MissionConstructionStateActive) then
            HandleBaseBuildingState();
        end

        if (Mission.m_MissionScionAttackStateActive) then
            HandleScionAttackState();
        end

        if (Mission.m_MissionScavengerStateActive) then
            HandleScavengerState();
        end

        if (Mission.m_MissionMansonStateActive) then
            HandleMansonState();
        end

        -- Handle Shabayev.
        HandleShabayevLogic();
        -- For failures.
        HandleFailureConditions();
        -- Fix bug where aborting constructor build will break mission.
        MonitorRecyclerConstructorProduction();

        -- Need to keep checking if the player is out of their ship and give them the satchel.
        for i = 1, _Cooperative.m_TotalPlayerCount do
            if (IsPerson(GetPlayerHandle(i))) then
                GiveWeapon(GetPlayerHandle(i), "igsatc");
            end
        end
    end
end

function HandleFailureConditions()
    -- Recycler is dead, mission failed.
    if (not IsAround(Mission.m_Recycler) and not Mission.m_MissionOver) then
        -- Objectives.
        AddObjectiveOverride("isdf0523.otf", "RED", 10, true);

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

function HandleMissionStart()
    if (Mission.m_MissionStartStage == 0) then
        -- Manson: "You're a few hundred meters off target..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0500.wav");

        -- Prepare Recycler for Deployment.
        Deploy(Mission.m_Recycler);

        -- Have Shabayev follow it.
        Defend2(Mission.m_Shabayev, Mission.m_Recycler, 1);

        -- Have the Dropship leave.
        SetAnimation(Mission.m_Dropship, "takeoff", 1);
        StartEmitter(Mission.m_Dropship, 1);
		StartEmitter(Mission.m_Dropship, 2);

        -- Dropship sound.
        StartSoundEffect("dropleav.wav", Mission.m_Dropship);

        -- Advance a step.
        Mission.m_MissionStartStage = Mission.m_MissionStartStage + 1;
    elseif (Mission.m_MissionStartStage == 1) then
        -- Send the Recycler off to Deploy.
        Dropoff(Mission.m_Recycler, "recy_deploy", 1);

        -- Advance a step.
        Mission.m_MissionStartStage = Mission.m_MissionStartStage + 1;
    elseif (Mission.m_MissionStartStage == 2) then
        if (IsAudioMessageDone(Mission.m_Audioclip)) then
            -- Shab: "Copy Major, Cooke take my wing...";
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0501.wav");

            -- Remove the Dropship.
            RemoveObject(Mission.m_Dropship);

            -- Get Shabayev to Patrol when she tells Cooke to follow.
            Patrol(Mission.m_Shabayev, "patrol1", 1);

            -- Advance the mission step.
            Mission.m_MissionStartStage = Mission.m_MissionStartStage + 1;
        end
    elseif (Mission.m_MissionStartStage == 3) then
        if (GetDistance(Mission.m_Recycler, "recy_deploy") <= 25) then
            -- Show objective.
			AddObjectiveOverride("isdf0501.otf", WHITE, 10, true);

            -- If we are a coop game, don't run the cutscene.
            if (Mission.m_IsCooperativeMode) then
                -- Advance to check the Recycler is deployed.
                Mission.m_MissionStartStage = 5
            else
                -- Get the Camera ready for the cutscene.
                CameraReady();

                -- Play the movie.
                Mission.m_PlayFirstCutscene = PlayMovie("isdf0501.cin");

                -- Advance the mission step.
                Mission.m_MissionStartStage = Mission.m_MissionStartStage + 1;
            end
        end
    elseif (Mission.m_MissionStartStage == 4) then
        -- Play the movie.
        Mission.m_PlayFirstCutscene = PlayMovie("isdf0501.cin");

        if (not Mission.m_PlayFirstCutscene) then
            -- Start the cutscene.
            CameraFinish();

            -- Advance the mission step.
            Mission.m_MissionStartStage = Mission.m_MissionStartStage + 1;
        end
    elseif (Mission.m_MissionStartStage == 5) then
        if (IsBuilding(Mission.m_Recycler)) then
            -- Send a couple of enemies to attack.
            Mission.m_Enemy1 = BuildObjectAtSafePath("fvsent", Mission.m_EnemyTeam, "raid1", "raid3", _Cooperative.m_TotalPlayerCount);
            Mission.m_Enemy2 = BuildObjectAtSafePath("fvscout", Mission.m_EnemyTeam, "raid2", "raid4", _Cooperative.m_TotalPlayerCount);

            -- Send enemies to attack.
            Goto(Mission.m_Enemy1, "recy_deploy", 1);
            Goto(Mission.m_Enemy2, "recy_deploy", 1);

            -- Mark this state as done.
            Mission.m_MissionStartDone = true;

            -- Start the base building and Scion attack steps.
            Mission.m_MissionConstructionStateActive = true;
            Mission.m_MissionScionAttackStateActive = true;

            -- Advance the mission step.
            Mission.m_MissionStartStage = Mission.m_MissionStartStage + 1;
        end
    end
end

function HandleBaseBuildingState() 
    -- Shouldn't need to worry about stages for this as she should attack right away.
    if (GetDistance(Mission.m_Enemy1, Mission.m_Recycler) < 300 and not Mission.m_ShabAttacking) then
        -- Send Shab to attack.
        Attack(Mission.m_Shabayev, Mission.m_Enemy1, 1);

        -- So we don't spam this order.
        Mission.m_ShabAttacking = true;
    end

    if (Mission.m_MissionConstructionStage == 0) then
        if (IsAlive(Mission.m_Constructor)) then
            -- Take control of the Constructor away from the player.
            Goto(Mission.m_Constructor, GetPosition(GetHandle("autonav")), 1);

            -- Advance the mission step.
            Mission.m_MissionConstructionStage = Mission.m_MissionConstructionStage + 1;
        end
    elseif (Mission.m_MissionConstructionStage == 1) then
        -- Proceed to build the base once both enemies are dead.
        if (not IsAliveAndEnemy(Mission.m_Enemy1, Mission.m_EnemyTeam) and not IsAliveAndEnemy(Mission.m_Enemy2, Mission.m_EnemyTeam)) then
            -- Shab: "Cooke, defend the perimeter..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0543.wav");

            -- Show objective.
            AddObjectiveOverride("isdf0517.otf", WHITE, 10, true);

            -- Have Shab defend the Constructor.
            Defend2(Mission.m_Shabayev, Mission.m_Constructor, 1);

            -- Give the constructor a bit of a delay.
            Mission.m_ConstructorCommandDelay = Mission.m_MissionTime + SecondsToTurns(8);

            -- Advance the mission step.
            Mission.m_MissionConstructionStage = Mission.m_MissionConstructionStage + 1;
        end
    elseif (Mission.m_MissionConstructionStage == 2) then
        if (Mission.m_ConstructorCommandDelay < Mission.m_MissionTime) then
            if (not IsAlive(Mission.m_Power1) and GetScrap(Mission.m_HostTeam) >= 30) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibpge5_fix", 1);
                    -- So we don't loop. 
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "pgen1", 1);              
                    -- So we don't loop. 
                    Mission.m_ConstructorDropoffGiven = true;
                end
            elseif (IsAlive(Mission.m_Power1) and not IsAlive(Mission.m_Power2) and GetScrap(Mission.m_HostTeam) >= 30) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibpge5_fix", 1);
                    -- So we don't loop. 
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "pgen2", 1);
                    -- So we don't loop. 
                    Mission.m_ConstructorDropoffGiven = true;
                end
            elseif (IsAlive(Mission.m_Power2) and not IsAlive(Mission.m_Bunker) and GetScrap(Mission.m_HostTeam) >= 50) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibcbu5", 1);
                    -- So we don't loop. 
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "rbunker1", 1);
                    -- So we don't loop. 
                    Mission.m_ConstructorDropoffGiven = true;
                end
            elseif (IsAlive(Mission.m_Bunker) and not IsAlive(Mission.m_GunTower) and GetScrap(Mission.m_HostTeam) >= 50) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibgtow", 1);
                    -- So we don't loop. 
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "gtow1", 1);
                    -- So we don't loop. 
                    Mission.m_ConstructorDropoffGiven = true;
                end
            elseif (IsAlive(Mission.m_GunTower) and not IsAlive(Mission.m_GunTower2) and GetScrap(Mission.m_HostTeam) >= 50) then
                if (not Mission.m_ConstructorBuildOrderGiven) then
                    -- Give orders to construct the first Power.
                    Build(Mission.m_Constructor, "ibgtow", 1);
                    -- So we don't loop. 
                    Mission.m_ConstructorBuildOrderGiven = true;
                elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                    -- Do the dropoff
                    Dropoff(Mission.m_Constructor, "gtow2", 1);
                    -- So we don't loop. 
                    Mission.m_ConstructorDropoffGiven = true;
                end
            end
        end
    elseif (Mission.m_MissionConstructionStage == 3) then
        if (not IsAlive(Mission.m_Factory)) then
            if (not Mission.m_ConstructorBuildOrderGiven) then
                -- Give orders to construct the first Power.
                Build(Mission.m_Constructor, "ibfact5", 1);
                -- So we don't loop. 
                Mission.m_ConstructorBuildOrderGiven = true;
            elseif (Mission.m_ConstructorBuildOrderGiven and not Mission.m_ConstructorDropoffGiven) then
                -- Do the dropoff
                Dropoff(Mission.m_Constructor, "fact", 1);
                -- So we don't loop. 
                Mission.m_ConstructorDropoffGiven = true;
                -- Deactivate the Constructor.
                Mission.m_MissionConstructionStateActive = false;
            end
        end
    end
end

function HandleScionAttackState() 
    if (Mission.m_ScionAttackDelay < Mission.m_MissionTime) then
        if (Mission.m_MissionScionAttackStage == 0) then
            if (IsAlive(Mission.m_Power1) and Mission.m_FirstPowerAttackTime < Mission.m_MissionTime) then
                -- Spawn enemies.
                Mission.m_Enemy1 = BuildObjectAtSafePath("fvtank", Mission.m_EnemyTeam, "raid1", "raid3", _Cooperative.m_TotalPlayerCount);
                Mission.m_Enemy2 = BuildObjectAtSafePath("fvsent", Mission.m_EnemyTeam, "raid4", "raid2", _Cooperative.m_TotalPlayerCount);

                -- Send the enemies to the perimeter.
                Goto(Mission.m_Enemy1, "recy_deploy", 1);
                Goto(Mission.m_Enemy2, "recy_deploy", 1);

                if (Mission.m_MissionDifficulty > 1) then
                    Mission.m_Enemy3 = BuildObjectAtSafePath("fvscout", Mission.m_EnemyTeam, "raid1", "raid3", _Cooperative.m_TotalPlayerCount), Mission.m_Constructor, 1;
                    Goto(Mission.m_Enemy3, "recy_deploy", 1);

                    if (Mission.m_MissionDifficulty > 2) then
                        Mission.m_Enemy4 = BuildObjectAtSafePath("fvarch", Mission.m_EnemyTeam, "raid4", "raid2", _Cooperative.m_TotalPlayerCount);
                        Goto(Mission.m_Enemy4,"recy_deploy", 1)
                    end
                end

                -- Advance the mission step. 
                Mission.m_MissionScionAttackStage = Mission.m_MissionScionAttackStage + 1;
            end
        elseif (Mission.m_MissionScionAttackStage == 1) then
            -- We want to make sure the raiders have spawned okay. Player's will stall the mission if they camp the spawn paths so we will wait.
            if (IsAliveAndEnemy(Mission.m_Enemy1, Mission.m_EnemyTeam) and IsAliveAndEnemy(Mission.m_Enemy2, Mission.m_EnemyTeam)) then
                Mission.m_MissionScionAttackStage = Mission.m_MissionScionAttackStage + 1;
            else
                -- Loop back to the start if this is blocked due to unsafe path spawning.
                Mission.m_MissionScionAttackStage = 0;
            end
        elseif (Mission.m_MissionScionAttackStage == 2) then
            if (not IsAliveAndEnemy(Mission.m_Enemy1, Mission.m_EnemyTeam) and not IsAliveAndEnemy(Mission.m_Enemy2, Mission.m_EnemyTeam) and not IsAliveAndEnemy(Mission.m_Enemy3, Mission.m_EnemyTeam) and not IsAliveAndEnemy(Mission.m_Enemy4, Mission.m_EnemyTeam)) then
                -- Put a delay on so we don't spawn immediately.
                Mission.m_ScionAttackDelay = Mission.m_MissionTime + SecondsToTurns(20);

                -- Chalk up the attack counter.
                Mission.m_ScionAttackCounter = Mission.m_ScionAttackCounter + 1;

                if (Mission.m_ScionAttackCounter < m_ScionAttackCount[Mission.m_MissionDifficulty]) then
                    -- Loop back to the start if this is blocked due to unsafe path spawning.
                    Mission.m_MissionScionAttackStage = 0;
                elseif (IsAround(Mission.m_GunTower) and IsAround(Mission.m_GunTower2)) then
                    -- Stop the attacks.
                    Mission.m_MissionScionAttackStateActive = false;
                    -- Start the Scavenger objectives.
                    Mission.m_MissionScavengerStateActive = true;
                end
            end
        end
    end
end

function HandleScavengerState()
    if (Mission.m_PlayCanopyMessage) then
        if (IsAudioMessageDone(Mission.m_Audioclip)) then
            -- Run a check to have Shab say she can't see and is returning to base.
            if (CountUnitsNearObject(pool1, 75, 1, NULL)) then
                -- Shab: "I can't see..."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0508.wav");

                -- Let's send a Sentry to the Scrap Pool that has been marked.
                Goto(BuildObjectAtSafePath(m_ScionFirstPoolGuard[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "lurker1", "lurker2", _Cooperative.m_TotalPlayerCount), "scrap_field1", 1);

                -- Don't loop.
                Mission.m_PlayCanopyMessage = false;
            end
        end
    end

    if (Mission.m_MissionScavengerStage == 0) then
        -- Check to see if a scav has already been deployed.
        if (Mission.m_DeployedScavCounter == 2) then
            -- Advance Scavenger State.
            Mission.m_MissionScavengerStage = Mission.m_MissionScavengerStage + 1

            -- Don't need to run the rest of the code.
            return;
        end

        -- Build a nav.
        Mission.m_Nav1 = BuildObject("ibnav", 1, "scrap_field1");
        SetObjectiveName(Mission.m_Nav1, TranslateString("Mission0501"));
        SetObjectiveOn(Mission.m_Nav1);

        -- Set Objective.
        AddObjectiveOverride("isdf0507.otf", "WHITE", 5, true);

        -- Remove beacon from Shab.
        SetObjectiveOff(Mission.m_Shabayev);

        -- Send some spice attack.
        Attack(BuildObjectAtSafePath(m_ScionPlayerAttacker[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "spawn1", "raid3", _Cooperative.m_TotalPlayerCount), GetPlayerHandle(1), 1);

        -- Tell player about the pool.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0507.wav");

        -- Allow the canopy message to be played.
        Mission.m_PlayCanopyMessage = true;

        -- Advance Scavenger State.
        Mission.m_MissionScavengerStage = Mission.m_MissionScavengerStage + 1
    elseif (Mission.m_MissionScavengerStage == 1) then
        if (Mission.m_DeployedScavCounter == 2) then
            -- Set Objective.
            if (IsAround(Mission.m_Nav1)) then
                -- Remove the highlight from first nav.
                SetObjectiveOff(Mission.m_Nav1);
                -- Second pool objective.
                AddObjectiveOverride("isdf0508.otf", "WHITE", 10, true);
                -- Shab: "Good work..."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0509.wav");
            else
                -- Tell player about the pool.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0507.wav");
                -- Set Objective.
                AddObjectiveOverride("isdf0507.otf", "WHITE", 5, true);
                -- Remove beacon from Shab.
                SetObjectiveOff(Mission.m_Shabayev);
                -- Allow the canopy message to be played.
                Mission.m_PlayCanopyMessage = true;
            end
            
            -- Build a nav.
            Mission.m_Nav2 = BuildObject("ibnav", 1, "scrap_field3");
            SetObjectiveName(Mission.m_Nav2, TranslateString("Mission0502"));
            SetObjectiveOn(Mission.m_Nav2);

            -- Advance Scavenger State.
            Mission.m_MissionScavengerStage = Mission.m_MissionScavengerStage + 1;
        end
    elseif (Mission.m_MissionScavengerStage == 2) then
        -- Handle logic for the fact the turrets are alive.
        if (not Mission.m_HandleTurretWarning) then
            -- Spawn the lurkers!
            if (not Mission.m_SpawnedFirstLurker and IsPlayerWithinDistance("lurker1", 250, _Cooperative.m_TotalPlayerCount)) then
                -- Build the enemy.
                BuildObject(m_ScionFirstLurker[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "lurker1");
                -- Only do this once.
                Mission.m_SpawnedFirstLurker = true;
            end

            if (not Mission.m_SpawnedSecondLurker and IsPlayerWithinDistance("lurker2", 250, _Cooperative.m_TotalPlayerCount)) then
                -- Build the enemy.
                BuildObject(m_ScionSecondLurker[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, "lurker2");
                -- Only do this once.
                Mission.m_SpawnedSecondLurker = true;
            end

            local checker = nil;
            local sturretCount = 6;
            local dist = 175;

            -- Check if any turrets are alive before doing this portion.
            for m = 1, sturretCount do
                local handle = GetHandle("sturret" .. m);

                if (IsAlive(handle)) then
                    -- Store this to use for later.
                    checker = handle;

                    -- So we don't run the rest of the code.
                    break;
                end
            end
            
            -- No turrets found, have Shab build the Factory without waiting.
            if (not IsAlive(checker)) then
                -- Use path is no turrets are found.
                checker = "scrap_field3"

                -- Increase the distance so we don't get too close.
                dist = dist + 75;
            end

            -- Run a check to see if this enemy is any of the players.
            if (IsPlayerWithinDistance(checker, dist, _Cooperative.m_TotalPlayerCount)) then
                if (checker ~= "scrap_field3") then
                    -- Make sure we play the warning audio.
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0512.wav");
                end

                -- Set the warning audio as played.
                Mission.m_HandleTurretWarning = true;

                -- Set the Mortar Bike delay time.
                Mission.m_MortarBikeTime = Mission.m_MissionTime + SecondsToTurns(15);
            end
        elseif (Mission.m_MortarBikeTime < Mission.m_MissionTime and GetScrap(Mission.m_HostTeam) > 55) then
            -- Shab: Cooke, I'm building a factory...
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0527.wav");

            -- Get the camera ready.
            if (not Mission.m_IsCooperativeMode) then
                CameraReady();
            end

            -- Set the Constructor movie timer.
            Mission.m_ConstructorMovieTime = Mission.m_MissionTime + SecondsToTurns(1.5);

            -- Move to the next state.
            Mission.m_MissionScavengerStage = Mission.m_MissionScavengerStage + 1;
        end
    elseif (Mission.m_MissionScavengerStage == 3) then
        -- Set the constructor to do what it needs to do.
        Mission.m_MissionConstructionStage = 3;

        -- Follow the Constructor.
        if (not Mission.m_IsCooperativeMode) then
            CameraObject(Mission.m_Constructor, 1, 15, 25, Mission.m_Constructor);
        end

        -- Make sure Shab has finished talking and we've exceeded our timer.
        if (IsAudioMessageDone(Mission.m_Audioclip) and Mission.m_ConstructorMovieTime < Mission.m_MissionTime) then
            -- Give command back to the player.
            if (not Mission.m_IsCooperativeMode) then
                CameraFinish();
            end

            -- Add Objective.
            AddObjectiveOverride("isdf0516.otf", WHITE, 10, true);

            -- Send Shabayev back to Patrol.
            if (IsAlive(Mission.m_Shabayev)) then
                Patrol(Mission.m_Shabayev, "patrol1", 1);
            end

            -- Move to next state.
            Mission.m_MissionScavengerStage = Mission.m_MissionScavengerStage + 1;
        end
    elseif (Mission.m_MissionScavengerStage == 4) then
        -- This is where we should check to see if the turrets are dead.
        if (Mission.m_DeployedScavCounter == 3) then
            -- Deactivate this state, we are finished.
            Mission.m_MissionScavengerStateActive = false;
            -- Start Manson's state.
            Mission.m_MissionMansonStateActive = true;
        end
    end
end

function HandleMansonState()
    if (Mission.m_MissionMansonStage == 0) then
        -- Manson: "You're showing a lot of promise..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0514.wav");

        -- New Objective.
        AddObjectiveOverride("isdf0512.otf", "WHITE", 10, true);

        -- Get them following in formation.
        Follow(Mission.m_Blue1, Mission.m_Manson, 1);
        Follow(Mission.m_Blue2, Mission.m_Blue1, 1);

        -- Delay 7 seconds before ordering player to follow.
        Mission.m_MansonDelayTime = Mission.m_MissionTime + SecondsToTurns(7);

        -- Advance this stage.
        Mission.m_MissionMansonStage = Mission.m_MissionMansonStage + 1;
    elseif (Mission.m_MissionMansonStage == 1) then
        if (IsAudioMessageDone(Mission.m_Audioclip) and Mission.m_MansonDelayTime < Mission.m_MissionTime) then
            -- Remove the beacon from this Nav.
            SetObjectiveOff(Mission.m_Nav2);

            -- Set Manson's beacon as active.
            SetObjectiveOn(Mission.m_Manson);

            -- New Objective.
            AddObjectiveOverride("isdf0518.otf", "WHITE", 10, true);

            -- Manson: "Follow me, Cooke".
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0515.wav");

            -- Set a nag timer just incase the player takes too long.
            Mission.m_MansonNagTime = Mission.m_MissionTime + SecondsToTurns(45);

            -- Advance this stage.
            Mission.m_MissionMansonStage = Mission.m_MissionMansonStage + 1;
        end
    elseif (Mission.m_MissionMansonStage == 2) then
        -- If player is within distance of Manson, advance.
        if (IsPlayerWithinDistance(Mission.m_Manson, 50, _Cooperative.m_TotalPlayerCount)) then
            -- Manson: "Intelligence has discovered a structure..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0539a.wav");

            -- AI has no control here >:)
            SetIndependence(Mission.m_Manson, 0);
            SetAvoidType(Mission.m_Manson, 0);

            SetIndependence(Mission.m_Blue1, 0);
            SetAvoidType(Mission.m_Blue1, 0);

            SetIndependence(Mission.m_Blue2, 0);
            SetAvoidType(Mission.m_Blue2, 0);

            -- Objectives.
            AddObjectiveOverride("isdf0513.otf", "WHITE", 10, true);

            -- Send Manson on his way.
            Goto(Mission.m_Manson, "manson_path1");

            -- Advance this stage.
            Mission.m_MissionMansonStage = Mission.m_MissionMansonStage + 1;
        end

        -- Nag if we're taking too long.
        if (Mission.m_MansonNagTime < Mission.m_MissionTime) then
            -- Manson: "Hurry up Cooke...";
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0528.wav");

            -- Reset the nag timer.
            Mission.m_MansonNagTime = Mission.m_MissionTime + SecondsToTurns(45);
        end
    elseif (Mission.m_MissionMansonStage == 3) then
        -- Manson has been granted the power of immortality.
        AddHealth(Mission.m_Manson, 100);
        AddHealth(Mission.m_Blue1, 100);
        AddHealth(Mission.m_Blue2, 100);

        -- Do a check to see if the player is too far from Manson before powering to the next path.
        if (Mission.m_MansonWaiting and IsPlayerWithinDistance(Mission.m_Manson, 100, _Cooperative.m_TotalPlayerCount) and GetDistance(Mission.m_Manson, "manson_path1", 23) < 100) then
            -- Send Manson on his way to the next path.
            Goto(Mission.m_Manson, "manson_path2");

            -- So we don't loop.
            Mission.m_MansonWaiting = false;
        end

        -- Run a check here and advance to the next state when Manson plays his message about the Spires.
        if (not Mission.m_MansonGunTowerMessage and GetDistance(Mission.m_Manson, "guntower1") < 200) then
            -- Manson: "There are a lot more of these puppies ahead"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0516.wav");

            -- Objectives.
            AddObjectiveOverride("isdf0514.otf", "WHITE", 10, true);

            -- So we don't loop.
            Mission.m_MansonGunTowerMessage = true;
        end

        -- Carry on with the rest of the logic once this has been done.
        if (Mission.m_MansonGunTowerMessage) then
            -- Increment a timer for Manson's message.
            Mission.m_MissionGunTowerTimer = Mission.m_MissionGunTowerTimer + 1;

            -- Couple of audio clips for his nagging.
            if (Mission.m_MissionGunTowerTimer == SecondsToTurns(30)) then
                -- Nag for the first time.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0528.wav");
            elseif (Mission.m_MissionGunTowerTimer > SecondsToTurns(45)) then
                -- Nag for the last time, player took too long.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0529.wav");
                -- Took too long, kill Manson and his Minions.
            end

            -- Run some logic here to check that the player is near the teleport.
            if (IsPlayerWithinDistance(Mission.m_Teleportal, 100, _Cooperative.m_TotalPlayerCount)) then
                -- "This looks like one of ours..."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0173.wav");

                -- Advance this stage.
                Mission.m_MissionMansonStage = Mission.m_MissionMansonStage + 1;
            end
        end
    elseif (Mission.m_MissionMansonStage == 4) then
        if (IsAudioMessageDone(Mission.m_Audioclip)) then
            -- Get Manson to yell at you.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0517.wav");

            -- Turn his beacon off.
            SetObjectiveOff(Mission.m_Manson);

            -- Set the AI up so they can do things again.
            SetIndependence(Mission.m_Manson, 1);
            SetIndependence(Mission.m_Blue1, 1);
            SetIndependence(Mission.m_Blue2, 1);

            -- Activate teleporter beacon.
            SetObjectiveOn(Mission.m_Teleportal);

            -- Remove it's immortality.
            SetMaxHealth(Mission.m_Teleportal, 5000);
            SetCurHealth(Mission.m_Teleportal, 5000);

            -- Objectives.
            AddObjectiveOverride("isdf0515.otf", "WHITE", 10, true);

            -- Advance this stage.
            Mission.m_MissionMansonStage = Mission.m_MissionMansonStage + 1;
        end
    elseif (Mission.m_MissionMansonStage == 5) then
        -- Manson has been granted the power of immortality.
        AddHealth(Mission.m_Manson, 100);
        AddHealth(Mission.m_Blue1, 100);
        AddHealth(Mission.m_Blue2, 100);

        -- Do a check to make sure the teleportal is dead from the blast of the Satchel.
        if (not IsAround(Mission.m_Teleportal)) then
            -- Manson: "Great balls of fire Cooke!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0518.wav");

            -- Complete the game and move on so we don't loop.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("Mission Accomplished.");
                DoGameover(10);
            else
                SucceedMission(GetTime() + 10, "isdf05w1.txt");
            end

            -- Advance this stage.
            Mission.m_MissionMansonStage = Mission.m_MissionMansonStage + 1;
        end
    end
end

function HandleShabayevLogic()
    -- This will make Shabayev behave in a way where she is more "Human".
    if (Mission.m_ShabayevState == SHAB_OKAY and not IsAround(Mission.m_Shabayev)) then
        -- Check that she is on foot.
        if (IsAround(Mission.m_ShabayevPilot)) then
            -- Prepare to take control of the rescue scout.
            Mission.m_ExpectingRescueScout = true;

            -- Stop her from Recycling.
            SetTeamNum(Mission.m_ShabayevPilot, Mission.m_AlliedTeam);

            -- Inform the player of the cost so they aren't stopping her.
            AddObjectiveOverride("Shabayev has lost her ship, she will build a Scout to rescue her.", "YELLOW", 10, false);

            -- Set her name so we know it's her.
            SetObjectiveName(Mission.m_ShabayevPilot, "Cmd. Shabayev");

            -- Highlight her pilot.
            if (not Mission.m_MissionScavengerStateActive) then
                SetObjectiveOn(Mission.m_ShabayevPilot);
            end

            -- Have her retreat to the Recycler.
            Goto(Mission.m_ShabayevPilot, GetPosition(GetHandle("autonav")), 1);

            -- Set Shabayev's state so she is on foot.
            Mission.m_ShabayevState = SHAB_ONFOOT;
        end
    elseif (Mission.m_ShabayevState == SHAB_ONFOOT) then
        -- Get the Recycler to build a Scout to rescue her.
        if (not IsAround(Mission.m_RescueScout) and GetScrap(Mission.m_HostTeam) >= 50 and not IsBusy(Mission.m_Recycler)) then
            if (not Mission.m_RecyclerBuildingRescueScout) then
                -- Recycler will now build the Scout.
                Build(Mission.m_Recycler, "ivscout", 1);
                
                -- So we don't loop.
                Mission.m_RecyclerBuildingRescueScout = true;
            else
                -- To force the Recycler to build.
                SetCommand(Mission.m_Recycler, CMD_DONE, 0);
            end
        elseif (IsAround(Mission.m_RescueScout)) then
            -- So Shabayev can take over.
            HopOut(Mission.m_RescueScout);

            -- Order her to get in.
            GetIn(Mission.m_ShabayevPilot, Mission.m_RescueScout);

            -- Set the state so we don't loop.
            Mission.m_ShabayevState = SHAB_TOSCOUT;
        end
    end
end

function MonitorRecyclerConstructorProduction()
    --[[ 
        It's possible to abort the Recycler's construction queue when it's building
        a constructor. To fix mission stall, we'll need a constant check to make sure
        that the constructor is alive, and the Recycler is not building. If the constructor
        has been aborted, this should fix that issue and progress the mission.
    ]]
    if (IsBuilding(Mission.m_Recycler) and not IsAlive(Mission.m_Constructor) and GetScrap(Mission.m_HostTeam) >= 40 and not IsBusy(Mission.m_Recycler) and Mission.m_ConstructorBuildTime < Mission.m_MissionTime) then
        local consOdf = "ivcon5_fix";

        if (not Mission.m_RecyclerBuildingConstructor) then
            -- Build our constructor.
            Build(Mission.m_Recycler, consOdf, 1);
            -- So we don't loop.
            Mission.m_RecyclerBuildingConstructor = true;
        else
            -- Set the command to done.
            SetCommand(Mission.m_Recycler, CMD_DONE);

            -- Grab the time it takes to build this object from the ODF.
            local buildTime = GetODFDouble(consOdf .. ".odf", "GameObjectClass", "buildTime", 10);
            
            -- See if we can grab the time it takes to build this.
            Mission.m_ConstructorBuildTime = Mission.m_MissionTime + SecondsToTurns(buildTime + 1);

            -- So we can reset.
            Mission.m_RecyclerBuildingConstructor = false;
        end
    end
end