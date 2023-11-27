--[[ 
    BZCC ISDF06 Lua Mission Script
    Written by AI_Unit
    Version 1.0 21-10-2022
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
local m_Breacher1Ship = {"fvscout", "fvsent", "fvarch"};
local m_Breacher2Ship = {"fvsent", "fvtank", "fvtank"};
local m_Breacher3Ship = {"fvscout", "fvsent", "fvarch"};
local m_Breacher4Ship = {"fvsent", "fvarch", "fvtank"};

local m_PoolAttack1Ship = {"fvscout", "fvsent", "fvarch"};
local m_PoolAttack2Ship = {"fvsent", "fvsent", "fvtank"};
local m_PoolAttack3Ship = {"fvscout", "fvtank", "fvtank"};

local m_ScionPlayerAttackCooldown = {45, 35, 25};

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
    m_PlayerShipODF = "ivmisl";

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionStartDone = false,
    m_MissionFailed = false,
    m_GreenSquadRemoved = false,
    m_ServiceBayMessagePlayed = false,
    m_ScrapPoolPartActive = false,
    m_PoolBunkerBuilt = false,
    m_FinalPartActive = false,
    m_SentGreenPlatoon1 = false,
    m_SentGreenPlatoon2 = false,

    m_Audioclip = nil,

    m_Bomber = nil,
    m_Constructor = nil,
    m_Green1 = nil,
    m_Green2 = nil,
    m_Green3 = nil,
    m_Green4 = nil,
    m_Green5 = nil,
    m_Attacker1 = nil,
    m_Attacker2 = nil,
    m_Attacker3 = nil,
    m_Attacker4 = nil,
    m_Attacker5 = nil,
    m_Attacker6 = nil,
    m_Breacher1 = nil,
    m_Breacher2 = nil,
    m_Breacher3 = nil,
    m_Breacher4 = nil,
    m_ScionScav = nil,
    m_ScionRecy = nil,
    m_ScionForge = nil,
    m_ReserveScav = nil,

    m_ScionAttackCount = 0,
    m_ScionAttackCooldown = 0,
    m_PoolTowerCount = 0,

    -- Steps for each section.
    m_MissionStartStage = 0,
    m_ScrapPoolPartStage = 0,
    m_FinalPartStage = 0
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
    PreloadODF("ivturr");
    PreloadODF("ivbomb");
    PreloadODF("ivcon6_fix");
    PreloadODF("fbrecy");
    PreloadODF("fbforg");
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

    -- Handle unit skill for enemy.
    if (GetTeamNum(h) == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);       
    end

    -- Give ivmisl the shadower.
    if (ODFName == "ivmisl") then
        GiveWeapon(h, "gshadow_c");
    end

    -- Check the Relay Bunker and Gun Towers
    if (ODFName == "ibcbun") then
        if (GetDistance(h, "pool") < 100) then
            Mission.m_PoolBunkerBuilt = true;

            AddObjectiveOverride("isdf0604.otf", "WHITE", 10, true);
            AddObjectiveOverride("isdf0605.otf", "GREEN", 10);
            AddObjectiveOverride("isdf0606.otf", "WHITE", 10);
        end
    elseif (ODFName == "ibgtow") then
        if (GetDistance(h, "pool") < 100) then
            Mission.m_PoolTowerCount = Mission.m_PoolTowerCount + 1;
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
    print("Welcome to ISDF06 (Lua)");
    print("Written by AI_Unit");
    
    if (Mission.m_IsCooperativeMode) then
        print("Cooperative mode enabled: Yes");
    else
        print("Cooperative mode enabled: No");
    end

    print("Chosen difficulty: " .. Mission.m_MissionDifficulty);
    print("Good luck and have fun :)");

    -- Allied team is Squad Green.
    SetTeamColor(Mission.m_AlliedTeam, 127, 255, 127);

    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "Green Squad");

    -- Ally teams to be sure.
    Ally(Mission.m_HostTeam, Mission.m_AlliedTeam);

    -- Grab the bomber.
    Mission.m_Bomber = GetHandle("unnamed_ivbomb");
    -- Stop it so the player doesn't have control
    Stop(Mission.m_Bomber, 1);
    
    -- Grab the constructor.
    Mission.m_Constructor = GetHandle("cons");
    -- Stop it so the player doesn't have control
    Stop(Mission.m_Constructor, 1);

    -- Add some turrets to the base.
    Stop(BuildObject("ivturr", Mission.m_HostTeam, "turret1"), 1);
    Stop(BuildObject("ivturr", Mission.m_HostTeam, "turret2"), 1);

    -- Spawn Scion Patrols in their base.
    Patrol(BuildObject("fvsent", Mission.m_EnemyTeam, GetPositionNear("patrol_spawn2", 20, 20)), "patrol", 1);
    Patrol(BuildObject("fvtank", Mission.m_EnemyTeam, GetPositionNear("patrol_spawn2", 20, 20)), "patrol", 1);
    Patrol(BuildObject("fvtank", Mission.m_EnemyTeam, GetPositionNear("patrol_spawn2", 20, 20)), "patrol", 1);
    Patrol(BuildObject("fvarch", Mission.m_EnemyTeam, GetPositionNear("patrol_spawn2", 20, 20)), "patrol", 1);

    -- Grab Green Squad.
    Mission.m_Green1 = GetHandle("green1");
    Mission.m_Green2 = GetHandle("green2");
    Mission.m_Green3 = GetHandle("green3");
    Mission.m_Green4 = GetHandle("green4");
    Mission.m_Green5 = GetHandle("green5");

    -- Assume formation.
    Follow(Mission.m_Green3, Mission.m_Green1);
    Follow(Mission.m_Green4, Mission.m_Green2);
    Follow(Mission.m_Green5, Mission.m_Green4);

    -- Give them good skill.
    SetSkill(Mission.m_Green1, 3);
    SetSkill(Mission.m_Green2, 3);
    SetSkill(Mission.m_Green3, 3);
    SetSkill(Mission.m_Green4, 3);
    SetSkill(Mission.m_Green5, 3);

    -- Grab the important Scion buildings.
    Mission.m_ScionRecy = GetHandle("frecy");
    Mission.m_ScionForge = GetHandle("fforg");
    Mission.m_ScionScav = GetHandle("fscav2");

    -- We have a Scavenger on reserve for the pool collection.
    Mission.m_ReserveScav = GetHandle("reserve_scav");

    -- Don't let the AI have fun with it.
    SetIndependence(Mission.m_ReserveScav, 0);

    -- So we don't have command of it.
    Stop(Mission.m_ReserveScav, 1);

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

    -- Make sure the handle has a pilot so the player can hop out.
    AddPilotByHandle(PlayerH);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;

    -- Start the first stage.
    Mission.m_FirstStageActive = true;
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

---------------------------
-- Mission Related Logic
---------------------------
function HandleMissionLogic()
    if (not Mission.m_MissionFailed) then
        if (not Mission.m_MissionStartDone) then
            HandleMissionStart();
        end

        if (Mission.m_ScrapPoolPartActive) then
            HandleScrapPoolPart();
        end

        if (Mission.m_FinalPartActive) then
            HandleFinalPart();
        end

        if (not Mission.m_GreenSquadRemoved) then
            RemoveGreenSquad();
        end

        if (Mission.m_ScrapPoolPartStage > 3 and not Mission.m_FinalPartActive) then
            SpawnAndSendScionPoolAttacks();
        end

        HandleFailureConditions();
    end
end

function HandleFailureConditions()
    -- Recycler is dead, mission failed.
    if (not IsAround(Mission.m_Constructor) and not Mission.m_MissionFailed) then
        -- Manson: "That constructor was vital!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0607.wav");

        -- Mission failed.
        Mission.m_MissionFailed = true;

         -- Game over.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Because you lost the Constructor, the mission could not be completed.");
            DoGameover(Mission.m_MissionTime + SecondsToTurns(10));
        else
            FailMission(Mission.m_MissionTime + SecondsToTurns(10), "isdf06l2.txt");
        end
    end
end

function HandleMissionStart()
    if (Mission.m_MissionStartStage == 0) then
        -- Manson: "Okay orange squad..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0601.wav");

        -- Advance a step.
        Mission.m_MissionStartStage = Mission.m_MissionStartStage + 1;
    elseif (Mission.m_MissionStartStage == 1) then
        if (IsAudioMessageDone(Mission.m_Audioclip)) then
            -- Send green squad to their doom!
            Goto(Mission.m_Green1, "green_removal", 1);
            Goto(Mission.m_Green2, "green_removal", 1);

            -- Show objective.
			AddObjectiveOverride("isdf0604.otf", "WHITE", 10, true);
            AddObjectiveOverride("isdf0601.otf", "WHITE", 10);

            -- Advance a step.
            Mission.m_MissionStartStage = Mission.m_MissionStartStage + 1;
        end
    elseif (Mission.m_MissionStartStage == 2) then
        if (Mission.m_ScionAttackCooldown < Mission.m_MissionTime 
            and not IsAliveAndEnemy(Mission.m_Attacker1, Mission.m_EnemyTeam) 
            and not IsAliveAndEnemy(Mission.m_Attacker2, Mission.m_EnemyTeam) 
            and not IsAliveAndEnemy(Mission.m_Attacker3, Mission.m_EnemyTeam) 
            and not IsAliveAndEnemy(Mission.m_Attacker4, Mission.m_EnemyTeam)
            and not IsAliveAndEnemy(Mission.m_Attacker5, Mission.m_EnemyTeam)
            and not IsAliveAndEnemy(Mission.m_Attacker6, Mission.m_EnemyTeam)) then

            -- Build the attackers and send them on their way.
            Mission.m_Attacker1 = BuildObject("fvtank", Mission.m_EnemyTeam, GetPositionNear("attack_start1", 20, 20));
            Mission.m_Attacker2 = BuildObject("fvarch", Mission.m_EnemyTeam, GetPositionNear("attack_start1", 20, 20));
            Mission.m_Attacker3 = BuildObject("fvsent", Mission.m_EnemyTeam, GetPositionNear("attack_start1", 20, 20));
            Mission.m_Attacker4 = BuildObject("fvsent", Mission.m_EnemyTeam, GetPositionNear("attack_start2", 20, 20));
            Mission.m_Attacker5 = BuildObject("fvarch", Mission.m_EnemyTeam, GetPositionNear("attack_start2", 20, 20));
            Mission.m_Attacker6 = BuildObject("fvtank", Mission.m_EnemyTeam, GetPositionNear("attack_start2", 20, 20));

            -- Send them to attack the player base.
            Goto(Mission.m_Attacker1, "attack_path1", 1);
            Goto(Mission.m_Attacker2, "attack_path1", 1);
            Goto(Mission.m_Attacker3, "attack_path1", 1);
            Goto(Mission.m_Attacker4, "attack_path2", 1);
            Goto(Mission.m_Attacker5, "attack_path2", 1);
            Goto(Mission.m_Attacker6, "attack_path2", 1);

            -- Give these guys max skill so they don't cower form Gun Towers.
            SetSkill(Mission.m_Attacker1, 3);
            SetSkill(Mission.m_Attacker2, 3);
            SetSkill(Mission.m_Attacker3, 3);
            SetSkill(Mission.m_Attacker4, 3);
            SetSkill(Mission.m_Attacker5, 3);
            SetSkill(Mission.m_Attacker6, 3);

            -- Push to the next stage so we can check if they have been killed.
            Mission.m_MissionStartStage = Mission.m_MissionStartStage + 1;
        end
    elseif (Mission.m_MissionStartStage == 3) then
        -- Check if the enemy attackers have been killed.
        if (not IsAliveAndEnemy(Mission.m_Attacker1, Mission.m_EnemyTeam) 
            and not IsAliveAndEnemy(Mission.m_Attacker2, Mission.m_EnemyTeam) 
            and not IsAliveAndEnemy(Mission.m_Attacker3, Mission.m_EnemyTeam) 
            and not IsAliveAndEnemy(Mission.m_Attacker4, Mission.m_EnemyTeam)
            and not IsAliveAndEnemy(Mission.m_Attacker5, Mission.m_EnemyTeam)
            and not IsAliveAndEnemy(Mission.m_Attacker6, Mission.m_EnemyTeam)) then

            -- They have been killed. Set a cooldown.
            Mission.m_ScionAttackCooldown = Mission.m_MissionTime + SecondsToTurns(20);

            -- Increment the amount of attacks and loop if needed.
            Mission.m_ScionAttackCount = Mission.m_ScionAttackCount + 1;

            -- If they haven't attacked enough, do a loop.
            if (Mission.m_ScionAttackCount == 1) then
                -- Run a check to get Shabayev to inform the player about the Service Bay.
                if (not Mission.m_ServiceBayMessagePlayed) then
                    -- Shab: "Take advantage of the break between attacks..."
                    _Subtitles.AudioWithSubtitles("isdf0612.wav");

                    -- So we don't loop.
                    Mission.m_ServiceBayMessagePlayed = true;
                end

                -- Loop back to spawn more attackers.
                Mission.m_MissionStartStage = 2;
            elseif (Mission.m_ScionAttackCount == 2) then
                -- Breached perimeter time.
                _Subtitles.AudioWithSubtitles("isdf0614.wav");

                -- Spawn attackers.
                Mission.m_Breacher1 = BuildObject(m_Breacher1Ship[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, GetPositionNear("back1", 20, 20));
                Mission.m_Breacher2 = BuildObject(m_Breacher2Ship[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, GetPositionNear("back2", 20, 20));
                Mission.m_Breacher3 = BuildObject(m_Breacher3Ship[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, GetPositionNear("back3", 20, 20));
                Mission.m_Breacher4 = BuildObject(m_Breacher4Ship[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, GetPositionNear("back3", 20, 20));
                
                -- Send them to attack the base.
                Goto(Mission.m_Breacher1, "back_door", 1);
                Goto(Mission.m_Breacher2, "back_door", 1);
                Goto(Mission.m_Breacher3, "back_door", 1);
                Goto(Mission.m_Breacher4, "back_door", 1);

                -- Make players aware of their location.
                SetObjectiveOn(Mission.m_Breacher1);
                SetObjectiveOn(Mission.m_Breacher2);
                SetObjectiveOn(Mission.m_Breacher3);
                SetObjectiveOn(Mission.m_Breacher4);

                -- Loop back to spawn more attackers.
                Mission.m_MissionStartStage = 2;
            elseif (Mission.m_ScionAttackCount == 3) then
                if (not IsAliveAndEnemy(Mission.m_Breacher1, Mission.m_EnemyTeam)
                    and not IsAliveAndEnemy(Mission.m_Breacher2, Mission.m_EnemyTeam)
                    and not IsAliveAndEnemy(Mission.m_Breacher3, Mission.m_EnemyTeam)
                    and not IsAliveAndEnemy(Mission.m_Breacher4, Mission.m_EnemyTeam)) then
                    -- Kill this state as it's no longer needed.
                    Mission.m_MissionStartDone = true;
        
                    -- Make the Scion Scavenger State active.
                    Mission.m_ScrapPoolPartActive = true;
                end
            end
        end
    end
end

function HandleScrapPoolPart()
    if (Mission.m_ScrapPoolPartStage == 0) then
        -- Manson: "Green 2 has located a Scion Scav..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0603.wav");

        -- Set beacon on the Scav.
        SetObjectiveOn(Mission.m_ScionScav);

        -- Advance a step.
        Mission.m_ScrapPoolPartStage = Mission.m_ScrapPoolPartStage + 1;
    elseif (Mission.m_ScrapPoolPartStage == 1) then
        if (IsAudioMessageDone(Mission.m_Audioclip)) then
            -- Shab: "Alright Cooke, take it out"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0604.wav");

            -- Show objective.
			AddObjectiveOverride("isdf0604.otf", WHITE, 10, true);
            AddObjectiveOverride("isdf0602.otf", WHITE, 10);

            -- Advance a step.
            Mission.m_ScrapPoolPartStage = Mission.m_ScrapPoolPartStage + 1;
        end
    elseif (Mission.m_ScrapPoolPartStage == 2) then
        if (IsPlayerWithinDistance(Mission.m_ScionScav, 225, _Cooperative.m_TotalPlayerCount)) then
            -- Shab: "The time looks right for an attack."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0605.wav");

            -- Move the constructor closer to the player to avoid delay.
            Goto(Mission.m_Constructor, "constructor_spawn", 1);

            -- Advance a step.
            Mission.m_ScrapPoolPartStage = Mission.m_ScrapPoolPartStage + 1;
        end
    elseif (Mission.m_ScrapPoolPartStage == 3) then
        if (not IsAliveAndEnemy(Mission.m_ScionScav, Mission.m_EnemyTeam)) then
            -- Get the Service Bay for Green Squad.
            local bay = GetHandle("unnamed_ibsbay");

            -- Manson: "I'm sending a Constructor to help you out..."
            _Subtitles.AudioWithSubtitles("isdf0606.wav");

            -- Send the Constructor to the Scrap Pool and give control to the player.
            Goto(Mission.m_Constructor, "pool", 0);

            -- Rebuild Green Squad and damage them.
            Mission.m_Green1 = BuildObject("ivtank", Mission.m_AlliedTeam, GetPositionNear("green_removal", 20, 20));
            Mission.m_Green2 = BuildObject("ivtank", Mission.m_AlliedTeam, GetPositionNear("green_removal", 20, 20));
            Mission.m_Green3 = BuildObject("ivscout", Mission.m_AlliedTeam, GetPositionNear("green_removal", 20, 20));
            Mission.m_Green4 = BuildObject("ivmbike", Mission.m_AlliedTeam, GetPositionNear("green_removal", 20, 20));
            Mission.m_Green5 = BuildObject("ivmbike", Mission.m_AlliedTeam, GetPositionNear("green_removal", 20, 20));

            -- Give them good skill.
            SetSkill(Mission.m_Green1, 3);
            SetSkill(Mission.m_Green2, 3);
            SetSkill(Mission.m_Green3, 3);
            SetSkill(Mission.m_Green4, 3);
            SetSkill(Mission.m_Green5, 3);

            -- Give damage to show signs of a fight.
            Damage(Mission.m_Green1, GetMaxHealth(Mission.m_Green1) - 1000);
            Damage(Mission.m_Green2, GetMaxHealth(Mission.m_Green2) - 800);
            Damage(Mission.m_Green3, GetMaxHealth(Mission.m_Green3) - 950);
            Damage(Mission.m_Green4, GetMaxHealth(Mission.m_Green4) - 500);
            Damage(Mission.m_Green5, GetMaxHealth(Mission.m_Green5) - 800);
 
            -- Assume formation.
            Defend2(Mission.m_Green2, Mission.m_Green1, 1);
            Defend2(Mission.m_Green3, Mission.m_Green1, 1);
            Defend2(Mission.m_Green4, Mission.m_Green2, 1);
            Defend2(Mission.m_Green5, Mission.m_Green4, 1);

            -- Get them to go to the Service Bay for repairs.
            Goto(Mission.m_Green1, GetPosition(bay), 1);

            -- Advance a step.
            Mission.m_ScrapPoolPartStage = Mission.m_ScrapPoolPartStage + 1;
        end
    elseif (Mission.m_ScrapPoolPartStage == 4) then
        if (GetDistance(Mission.m_Constructor, "pool") < 75) then
            -- Manson: "Build a Relay Bunker first..."
            _Subtitles.AudioWithSubtitles("isdf0611.wav");

            -- Objectives.
            AddObjectiveOverride("isdf0604.otf", "WHITE", 10, true);
            AddObjectiveOverride("isdf0605.otf", "WHITE", 10);
            AddObjectiveOverride("isdf0606.otf", "WHITE", 10);
            
            -- Advance a step.
            Mission.m_ScrapPoolPartStage = Mission.m_ScrapPoolPartStage + 1;
        end
    elseif (Mission.m_ScrapPoolPartStage == 5) then
        if (Mission.m_PoolBunkerBuilt and Mission.m_PoolTowerCount == 2) then
            -- Objectives.
            AddObjectiveOverride("isdf0604.otf", "WHITE", 10, true);
            AddObjectiveOverride("isdf0605.otf", "GREEN", 10);
            AddObjectiveOverride("isdf0606.otf", "GREEN", 10);

            -- Manson: "These Gun Tower's should lock up that area..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0608.wav");

            -- Send the Reserve Scavenger to the Scrap Pool.
            Goto(Mission.m_ReserveScav, GetHandle("goal1"), 1);

            -- Deactivate this step
            Mission.m_ScrapPoolPartActive = false;

            -- Activate the final part.
            Mission.m_FinalPartActive = true;
        end
    end
end

function HandleFinalPart()
    if (Mission.m_FinalPartStage == 0) then
        if (IsAudioMessageDone(Mission.m_Audioclip)) then
            -- Manson: "It's time we finished them off."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0609.wav");

            -- Advance a step.
            Mission.m_FinalPartStage = Mission.m_FinalPartStage + 1;
        end
    elseif (Mission.m_FinalPartStage == 1) then
        if (IsAudioMessageDone(Mission.m_Audioclip)) then
            -- Manson: "Cooke, take command of the Bomber Bay!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf0613.wav");

            -- Objectives.
            AddObjectiveOverride("isdf0608.otf", "WHITE", 10, true);

            -- Give command of the Bomber to the player.
            Stop(Mission.m_Bomber, 0);

            -- Send Green Squad to attack.
            Goto(Mission.m_Green1, "attack_start1", 1);
            Goto(Mission.m_Green2, "attack_start1", 1);

            -- Highlight the key buildings.
            SetObjectiveOn(Mission.m_ScionRecy);
            SetObjectiveOn(Mission.m_ScionForge);

            -- Advance a step.
            Mission.m_FinalPartStage = Mission.m_FinalPartStage + 1;
        end
    elseif (Mission.m_FinalPartStage == 2) then
        -- If the Green Tanks are killed, send their troops so they don't sit still.
        if (not IsAlive(Mission.Green1) and not Mission.m_SentGreenPlatoon1) then
            -- Go to attack the Scion base.
            Goto(Mission.m_Green3, "attack_start1", 1);

            -- So we don't loop.
            Mission.m_SentGreenPlatoon1 = true;
        end

        if (not IsAlive(Mission.Green2) and not Mission.m_SentGreenPlatoon2) then
            -- Go to attack the Scion base.
            Goto(Mission.m_Green4, "attack_start1", 1);
            Goto(Mission.m_Green5, "attack_start1", 1);

            -- So we don't loop.
            Mission.m_SentGreenPlatoon2 = true;
        end

        if (not IsAround(Mission.m_ScionRecy) and not IsAround(Mission.m_ScionForge)) then
            -- Objectives.
            AddObjectiveOverride("isdf0609.otf", "GREEN", 10, true);

            -- Game over.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("Mission Accomplished.");
                DoGameover(Mission.m_MissionTime + SecondsToTurns(10));
            else
                SucceedMission(Mission.m_MissionTime + SecondsToTurns(10), "isdf06w1.txt");
            end

            -- Advance a step.
            Mission.m_FinalPartStage = Mission.m_FinalPartStage + 1;
        end
    end
end

function SpawnAndSendScionPoolAttacks()
    -- Send attacks while things are progressing.
    if (Mission.m_ScionAttackCooldown < Mission.m_MissionTime and not IsAliveAndEnemy(Mission.m_Attacker1, Mission.m_EnemyTeam) and not IsAliveAndEnemy(Mission.m_Attacker2, Mission.m_EnemyTeam) and not IsAliveAndEnemy(Mission.m_Attacker3, Mission.m_EnemyTeam)) then
        -- Wait a period of time before attacking again.
        Mission.m_ScionAttackCooldown = Mission.m_MissionTime + SecondsToTurns(m_ScionPlayerAttackCooldown[Mission.m_MissionDifficulty]); 
        
        -- Send enemies to attack.
        Mission.m_Attacker1 = BuildObject(m_PoolAttack1Ship[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, GetPositionNear("attack_start1", 20, 20));
        Mission.m_Attacker2 = BuildObject(m_PoolAttack2Ship[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, GetPositionNear("attack_start1", 20, 20));
        Mission.m_Attacker3 = BuildObject(m_PoolAttack3Ship[Mission.m_MissionDifficulty], Mission.m_EnemyTeam, GetPositionNear("attack_start1", 20, 20));

        -- Send two to attack the player, and the other one to the constructor.
        Goto(Mission.m_Attacker1, "pool", 1);
        Goto(Mission.m_Attacker2, "pool", 1);
        Attack(Mission.m_Attacker3, Mission.m_Constructor, 1);
    end
end

function RemoveGreenSquad()
    if (IsAlive(Mission.m_Green1)) then
        if (GetDistance(Mission.m_Green1, "green_removal") < 50) then
            RemoveObject(Mission.m_Green1);
            RemoveObject(Mission.m_Green3);
        end
    end

    if (IsAlive(Mission.m_Green2)) then
        if (GetDistance(Mission.m_Green2, "green_removal") < 50) then
            RemoveObject(Mission.m_Green2);
            RemoveObject(Mission.m_Green4);
            RemoveObject(Mission.m_Green5);
        end
    end
    
    if (not IsAlive(Mission.m_Green1) and not IsAlive(Mission.m_Green2) and not IsAlive(Mission.m_Green3) and not IsAlive(Mission.m_Green4) and not IsAlive(Mission.m_Green5)) then
        Mission.m_GreenSquadRemoved = true;
    end
end