--[[
    BZCC Scion04 Lua Mission Script
    Written by AI_Unit
    Version 1.0 04-01-2025
--]]

-- Fix for finding files outside of this script directory.
-- assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))();

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
local m_MissionName = "Scion04: Escort";

-- Mission important variables.
local Mission =
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "fspilo_x",
    -- Specific to mission.
    m_PlayerShipODF = "fvtank_x",

    m_MainPlayer = nil,

    m_Tug1 = nil,
    m_Power = nil,
    m_Machine = nil,

    m_RTAttack1 = nil,
    m_RTAttack2 = nil,
    m_RTAttack3 = nil,

    m_Evil1 = nil,
    m_Evil2 = nil,
    m_Evil3 = nil,

    m_Ambusher1 = nil,
    m_Ambusher2 = nil,
    m_Ambusher3 = nil,
    m_Ambusher4 = nil,
    m_Ambusher5 = nil,
    m_Ambusher6 = nil,

    m_Rckt1 = nil,
    m_Rckt2 = nil,
    m_Rckt3 = nil,
    m_Rckt4 = nil,

    m_Tank1 = nil,
    m_Tank2 = nil,
    m_Tank3 = nil,
    m_Tank4 = nil,

    m_FVTank1 = nil,
    m_FVTank2 = nil,
    m_FVTank3 = nil,
    m_FVSent1 = nil,
    m_FVSent2 = nil,
    m_FVSent3 = nil,
    m_FVServ1 = nil,

    m_FVArch1 = nil,
    m_FVArch2 = nil,

    m_AILook = nil,

    m_BigSpawn_Cam1Look = nil,
    m_BigSpawn_Cam2Look = nil,
    m_BigSpawn_Cam3Look = nil,
    m_BigSpawn_Cam4Look = nil,

    m_Dropship1 = nil,
    m_Dropship2 = nil,

    m_TugShot_Look1 = nil,

    m_Bossman = nil,

    m_StealerWalker1 = nil,
    m_StealerWalker2 = nil,

    m_Stealer1 = nil,
    m_Stealer2 = nil,
    m_Stealer3 = nil,
    m_Stealer4 = nil,
    m_Stealer5 = nil,
    m_Stealer6 = nil,
    m_Stealer7 = nil,
    m_Stealer8 = nil,
    m_Stealer9 = nil,
    m_Stealer10 = nil,
    m_Stealer11 = nil,
    m_Stealer12 = nil,

    m_Faker1 = nil,
    m_Faker2 = nil,
    m_Faker3 = nil,
    m_Faker4 = nil,

    m_Evil1Check = false,
    m_Evil2Check = false,
    m_Evil3Check = false,
    m_EvilsDead = false,

    m_Attack1 = false,

    m_RebelRetreat = false,
    m_RebelsTurnEvil = false,
    m_RebelsAttack = false,
    m_RebelsReserveAttack = false,
    m_RebelsPickTarget = false,
    m_RebelsChasePlayer = false,

    m_StartBigSpawn = false,

    m_SpawnStealerPair1 = false,
    m_SpawnStealerPair2 = false,
    m_SpawnStealerPair3 = false,
    m_SpawnStealerPair4 = false,
    m_SpawnStealerPair5 = false,
    m_SpawnStealerPair6 = false,

    m_Stop1 = false,
    m_Stop2 = false,
    m_Stop3 = false,
    m_Stop4 = false,
    m_Stop5 = false,
    m_Stop6 = false,
    m_Stop7 = false,
    m_Stop8 = false,
    m_Stop9 = false,
    m_Stop10 = false,
    m_Stop11 = false,
    m_Stop12 = false,

    m_Stealer9Relook = false,
    m_Stealer10Relook = false,
    m_Stealer11Relook = false,
    m_Stealer12Relook = false,

    m_Walker1Stop = false,
    m_Walker2Stop = false,
    m_BossmanStop = false,

    m_WalkerMove = false,
    m_BossmanMove = false,

    m_StopTug = false,

    m_CutsceneState = 1,
    m_CutsceneStateDelay = 0,
    m_CutsceneVoiceDelay = 0,

    m_CutsceneVO1Played = false,
    m_CutsceneVO3Played = false,
    m_CutsceneVO4Played = false,
    m_CutsceneVO5Played = false,
    m_CutsceneVO6Played = false,

    m_CutsceneAttackTug = false,
    m_CutsceneTugDead = false,

    m_PlayerMetRebels = false,
    m_PlayerAmbushed = false,
    m_PlayerCaughtUp = false,

    m_BurnsRebelDialogPlayed = false,
    m_BurnsAmbushDialogPlayed = false,

    m_TakeoffDone = false,
    m_TakeoffSoundDone = false,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_PrepCamera1 = false,
    m_PrepCamera2 = false,
    m_PrepCamera3 = false,
    m_PrepCamera4 = false,
    m_PrepCamera5 = false,
    m_PrepCamera6 = false,
    m_PrepCamera7 = false,

    m_PrepFinalCamera = false,

    m_FakersStopAttack = false,

    m_TakeoffTime = 0,
    m_TakeoffSoundTime = 0,

    m_FakersStopAttackTime = 0,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_RebelWarningCount = 0,
    m_RebelWarningTimer = 0,
    m_RebelReserveReleaseTimer = 0,
    m_RebelsChasePlayerTimer = 0,
    m_BurnsAmbushTimer = 0,

    -- Timers to spawn the enemy Warrior pairs on each side of the Alchemator.
    m_StealerPair1Timer = 0,
    m_StealerPair2Timer = 0,
    m_StealerPair3Timer = 0,
    m_StealerPair4Timer = 0,
    m_StealerPair5Timer = 0,
    m_StealerPair6Timer = 0,

    -- Timers for moving the walkers.
    m_WalkerMoveTime = 0,
    m_BossmanMoveTime = 0,

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

    -- Set difficulty based on whether it's coop or not.
    if (Mission.m_IsCooperativeMode) then
        Mission.m_MissionDifficulty = GetVarItemInt("network.session.ivar102") + 1;
    else
        Mission.m_MissionDifficulty = IFace_GetInteger("options.play.difficulty") + 1;
    end

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
    if (teamNum == Mission.m_EnemyTeam or teamNum == 7) then
        SetSkill(h, Mission.m_MissionDifficulty);
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        -- Always max our player units.
        SetSkill(h, 3);
    end
end

function Start()
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

    -- Get the main player
    Mission.m_MainPlayer = GetPlayerHandle(1);

    -- Start mission logic.
    if (Mission.m_MissionOver == false) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Check failure conditions...
            HandleFailureConditions();

            -- Attack Brains.
            AttacksBrain();

            -- Ambush.
            if (Mission.m_PlayerAmbushed == false) then
                AmbushBrain();
            end

            -- Handle the Rebels outside of the main mission logic.
            if (Mission.m_EvilsDead == false) then
                RebelBrain();
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
    -- Unique logic for this mission to check one of the attack pairs has been sniped.
    if (Mission.m_Attack1 == false) then
        if (victimHandle == Mission.m_RTAttack2) then
            Goto(Mission.m_RTAttack3, Mission.m_Tug1, 1);
        elseif (victimHandle == Mission.m_RTAttack3) then
            Goto(Mission.m_RTAttack2, Mission.m_Tug1, 1);
        end
    end

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
    if (Mission.m_RebelsTurnEvil == false) then
        if (IsPlayer(ShooterHandle) and (VictimHandle == Mission.m_Evil1 or VictimHandle == Mission.m_Evil2 or VictimHandle == Mission.m_Evil3)) then
            if (GetCurHealth(VictimHandle) < 750) then
                -- Rebel: He's onto us! Attack!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0404.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                -- He's onto us! Attack!
                RebuildRebels();

                -- Have them attack the user who shot them.
                Attack(Mission.m_Evil1, ShooterHandle);
                Attack(Mission.m_Evil2, ShooterHandle);
                Attack(Mission.m_Evil3, ShooterHandle);
            end
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_AlliedTeam, "Scion");
    SetTeamNameForStat(7, "Scion Rebels");
    SetTeamNameForStat(Mission.m_EnemyTeam, "ISDF");

    -- Put the Rebel colour on teams 5 and 7 for coop.
    SetTeamColor(Mission.m_AlliedTeam, 85, 255, 85);
    SetTeamColor(7, 85, 255, 85);

    -- Make sure the enemy doesn't attack the Team 5 units for now.
    if (Mission.m_IsCooperativeMode == false) then
        for i = 2, 5 do
            Ally(Mission.m_HostTeam, i);
        end

        Ally(Mission.m_AlliedTeam, Mission.m_EnemyTeam);
        Ally(Mission.m_EnemyTeam, 7);
    end

    -- Grab all handles that are placed on the map.
    Mission.m_Tug1 = GetHandle("tug1");
    Mission.m_Power = GetHandle("power");
    Mission.m_Machine = GetHandle("machine");

    Mission.m_RTAttack1 = GetHandle("rtattack1");
    Mission.m_RTAttack2 = GetHandle("rtattack2");
    Mission.m_RTAttack3 = GetHandle("rtattack3");

    -- Get these guys to look at the player so they're not looking in random directions.
    LookAt(Mission.m_RTAttack1, Mission.m_MainPlayer);
    LookAt(Mission.m_RTAttack2, Mission.m_MainPlayer);
    LookAt(Mission.m_RTAttack3, Mission.m_MainPlayer);

    Mission.m_Evil1 = GetHandle("evil1");
    Mission.m_Evil2 = GetHandle("evil2");
    Mission.m_Evil3 = GetHandle("evil3");

    Mission.m_Ambusher1 = GetHandle("ambusher1");
    Mission.m_Ambusher2 = GetHandle("ambusher2");
    Mission.m_Ambusher3 = GetHandle("ambusher3");
    Mission.m_Ambusher4 = GetHandle("ambusher4");
    Mission.m_Ambusher5 = GetHandle("ambusher5");
    Mission.m_Ambusher6 = GetHandle("ambusher6");

    Mission.m_Rckt1 = GetHandle("rckt1");
    Mission.m_Rckt2 = GetHandle("rckt2");
    Mission.m_Rckt3 = GetHandle("rckt3");
    Mission.m_Rckt4 = GetHandle("rckt4");

    Mission.m_Tank1 = GetHandle("tank1");
    Mission.m_Tank2 = GetHandle("tank2");
    Mission.m_Tank3 = GetHandle("tank3");
    Mission.m_Tank4 = GetHandle("tank4");

    Mission.m_FVTank1 = GetHandle("fvtank1");
    Mission.m_FVTank2 = GetHandle("fvtank2");
    Mission.m_FVTank3 = GetHandle("fvtank3");

    Mission.m_FVSent1 = GetHandle("fvsent1");
    Mission.m_FVSent2 = GetHandle("fvsent2");
    Mission.m_FVSent3 = GetHandle("fvsent3");

    Mission.m_FVServ1 = GetHandle("fvserv1");

    Mission.m_FVArch1 = GetHandle("fvarch1");
    Mission.m_FVArch2 = GetHandle("fvarch2");

    Mission.m_AILook = GetHandle("ailook");

    Mission.m_BigSpawn_Cam1Look = GetHandle("bigspawn_cam1look");
    Mission.m_BigSpawn_Cam2Look = GetHandle("bigspawn_cam2look");
    Mission.m_BigSpawn_Cam3Look = GetHandle("bigspawn_camlook3");
    Mission.m_BigSpawn_Cam4Look = GetHandle("bigspawn_cam4look");

    Mission.m_Dropship1 = GetHandle("dropship1");
    Mission.m_Dropship2 = GetHandle("dropship2");

    Mission.m_TugShot_Look1 = GetHandle("tugshot_look1");

    -- Put the existing Rebels onto the allied team.
    SetTeamNum(Mission.m_Evil1, Mission.m_AlliedTeam);
    SetTeamNum(Mission.m_Evil2, Mission.m_AlliedTeam);
    SetTeamNum(Mission.m_Evil3, Mission.m_AlliedTeam);

    -- Remove their independence.
    SetIndependence(Mission.m_Evil1, 0);
    SetIndependence(Mission.m_Evil2, 0);
    SetIndependence(Mission.m_Evil3, 0);

    -- Max out the health of the alchemator to avoid death.
    SetMaxHealth(Mission.m_Machine, 0);
    SetMaxHealth(Mission.m_Dropship1, 0);
    SetMaxHealth(Mission.m_Dropship2, 0);

    -- Force the tug to grab the power.
    Pickup(Mission.m_Tug1, Mission.m_Power, 0);

    -- Adjust the health of the tug.
    SetMaxHealth(Mission.m_Tug1, 8000);
    SetCurHealth(Mission.m_Tug1, 8000);

    -- Send the Rocket Tanks to patrol.
    Patrol(Mission.m_Rckt1, "rckt1path", 1);
    Patrol(Mission.m_Rckt2, "rckt2path", 1);
    Patrol(Mission.m_Rckt3, "rckt3path", 1);
    Patrol(Mission.m_Rckt4, "rckt4path", 1);

    -- Deploy the dropships.
    SetAnimation(Mission.m_Dropship1, "deploy", 1);
    SetAnimation(Mission.m_Dropship2, "deploy", 1);

    -- Remove the independence from the Ambusher units.
    SetIndependence(Mission.m_Ambusher1, 0);
    SetIndependence(Mission.m_Ambusher2, 0);
    SetIndependence(Mission.m_Ambusher3, 0);
    SetIndependence(Mission.m_Ambusher4, 0);
    SetIndependence(Mission.m_Ambusher5, 0);
    SetIndependence(Mission.m_Ambusher6, 0);

    -- Spawn the enemy walkers early for the final cutscene.
    Mission.m_Bossman = BuildObject("fvwalk_x", 7, "bossman_spawn");
    Mission.m_StealerWalker1 = BuildObject("fvwalk_x", 7, "stealer_walk1");
    Mission.m_StealerWalker2 = BuildObject("fvwalk_x", 7, "stealer_walk2");

    -- Stop the AI from acting.
    SetIndependence(Mission.m_Bossman, 0);
    SetIndependence(Mission.m_StealerWalker1, 0);
    SetIndependence(Mission.m_StealerWalker2, 0);

    -- Minor delay before starting the mission.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1.5);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Ok Cooke, we MUST get this power source to the data transfer machine.
        -- We have been unable to locate any scrap veins in the area, so you will have to make due with the units we have available.
        -- Good luck Cooke, the fate of an entire race is in your hands.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0401.wav");

        -- Set the timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Show Objectives.
        AddObjectiveOverride("scion0401.otf", "WHITE", 10, true);

        -- Activate the Rebel brain.
        Mission.m_RebelBrainActive = true;

        -- Change the name of the machine.
        SetObjectiveName(Mission.m_Machine, TranslateString("MissionS0401"));

        -- Highlight the machine.
        SetObjectiveOn(Mission.m_Machine);

        -- Move the first Scout to attack the player.
        Goto(Mission.m_RTAttack1, Mission.m_MainPlayer);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    -- Only play this voice from Burns if the player didn't fall for the trap.
    if (Mission.m_EvilsDead and Mission.m_PlayerAmbushed == false and Mission.m_BurnsRebelDialogPlayed == false) then
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            -- You did the right thing, John,  Those were the rebels!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0408.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- So this doesn't loop.
            Mission.m_BurnsRebelDialogPlayed = true;
        end
    end

    if (Mission.m_PlayerAmbushed and Mission.m_EvilsDead == false and Mission.m_BurnsAmbushDialogPlayed == false and Mission.m_BurnsAmbushTimer < Mission.m_MissionTime) then
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            -- John, you fell right into a trap...those were the rebels!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0412.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- So this doesn't loop.
            Mission.m_BurnsAmbushDialogPlayed = true;
        end
    end

    -- Check to see when the player has reached the Alchemator to start the cutscene.
    if (GetTug(Mission.m_Tug1) == Mission.m_Power and GetDistance(Mission.m_Tug1, Mission.m_Machine) < 200) then
        -- Show complete objective.
        AddObjectiveOverride("scion0401.otf", "GREEN", 10, true);

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- So the objective doesn't fail when we have the Hauler destroyed.
    Mission.m_StartBigSpawn = true;

    -- Move the Tug to the point of death for the cutscene.
    Retreat(Mission.m_Tug1, "tug_die_here", 1);

    -- Set the timers to spawn the Rebel Warriors from the canyons.
    Mission.m_StealerPair1Timer = Mission.m_MissionTime + SecondsToTurns(0);
    Mission.m_StealerPair2Timer = Mission.m_MissionTime + SecondsToTurns(1.5);
    Mission.m_StealerPair3Timer = Mission.m_MissionTime + SecondsToTurns(3);
    Mission.m_StealerPair4Timer = Mission.m_MissionTime + SecondsToTurns(4.5);
    Mission.m_StealerPair5Timer = Mission.m_MissionTime + SecondsToTurns(6);
    Mission.m_StealerPair6Timer = Mission.m_MissionTime + SecondsToTurns(7.5);

    -- Move the player units to their respective paths.
    if (IsPlayer(Mission.m_FVSent1) == false and IsAlive(Mission.m_FVSent1)) then
        SetIndependence(Mission.m_FVSent1, 0);
        Goto(Mission.m_FVSent1, "fvsent1");
    end

    if (IsPlayer(Mission.m_FVSent2) == false and IsAlive(Mission.m_FVSent2)) then
        SetIndependence(Mission.m_FVSent2, 0);
        Goto(Mission.m_FVSent2, "fvsent2");
    end

    if (IsPlayer(Mission.m_FVSent3) == false and IsAlive(Mission.m_FVSent3)) then
        SetIndependence(Mission.m_FVSent3, 0);
        Goto(Mission.m_FVSent3, "fvsent3");
    end

    if (IsPlayer(Mission.m_FVTank1) == false and IsAlive(Mission.m_FVTank1)) then
        SetIndependence(Mission.m_FVTank1, 0);
        Goto(Mission.m_FVTank1, "fvtank1");
    end

    if (IsPlayer(Mission.m_FVTank2) == false and IsAlive(Mission.m_FVTank2)) then
        SetIndependence(Mission.m_FVTank2, 0);
        Goto(Mission.m_FVTank2, "fvtank2");
    end

    if (IsPlayer(Mission.m_FVTank3) == false and IsAlive(Mission.m_FVTank3)) then
        SetIndependence(Mission.m_FVTank3, 0);
        Goto(Mission.m_FVTank3, "fvtank3");
    end

    if (IsPlayer(Mission.m_FVArch1) == false and IsAlive(Mission.m_FVArch1)) then
        SetIndependence(Mission.m_FVArch1, 0);
        Goto(Mission.m_FVArch1, "fvarch1");
    end

    if (IsPlayer(Mission.m_FVArch2) == false and IsAlive(Mission.m_FVArch2)) then
        SetIndependence(Mission.m_FVArch2, 0);
        Goto(Mission.m_FVArch2, "fvarch2");
    end

    if (IsAlive(Mission.m_FVServ1)) then
        SetIndependence(Mission.m_FVServ1, 0);
        Goto(Mission.m_FVServ1, "fvserv1");
    end

    -- Small delay for the next screen.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

    -- Advance the mission state.
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[6] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Cutscene state will manage things.
        if (Mission.m_CutsceneState == 1) then
            -- Prepare the first camera.
            if (Mission.m_PrepCamera1 == false) then
                -- If we are not coop, then start the camera sequence.
                if (Mission.m_IsCooperativeMode == false) then
                    -- Start the camera.
                    CameraReady();
                end

                -- Delay so we don't advance too much.
                Mission.m_CutsceneStateDelay = Mission.m_MissionTime + SecondsToTurns(7);

                -- So we don't loop.
                Mission.m_PrepCamera1 = true;
            end

            -- Again, only if we're not in coop.
            if (Mission.m_IsCooperativeMode == false) then
                CameraPath("bigspawn_campath1", 1000, 0, Mission.m_BigSpawn_Cam1Look);
            end

            -- Advance the state of the cutscenes.
            if (Mission.m_CutsceneStateDelay < Mission.m_MissionTime) then
                Mission.m_CutsceneState = Mission.m_CutsceneState + 1;
            end
        elseif (Mission.m_CutsceneState == 2) then
            -- Prepare the second camera.
            if (Mission.m_PrepCamera2 == false) then
                -- If we are not coop, then start the camera sequence.
                if (Mission.m_IsCooperativeMode == false) then
                    -- Start the camera.
                    CameraReady();
                end

                -- Delay so we don't advance too much.
                Mission.m_CutsceneStateDelay = Mission.m_MissionTime + SecondsToTurns(5);

                -- So we don't loop.
                Mission.m_PrepCamera2 = true;
            end

            -- Again, only if we're not in coop.
            if (Mission.m_IsCooperativeMode == false) then
                CameraPath("bigspawn_campath2", 1000, 0, Mission.m_BigSpawn_Cam2Look);
            end

            -- Advance the state of the cutscenes.
            if (Mission.m_CutsceneStateDelay < Mission.m_MissionTime) then
                Mission.m_CutsceneState = Mission.m_CutsceneState + 1;
            end
        elseif (Mission.m_CutsceneState == 3) then
            -- Prepare the third camera.
            if (Mission.m_PrepCamera3 == false) then
                -- If we are not coop, then start the camera sequence.
                if (Mission.m_IsCooperativeMode == false) then
                    -- Start the camera.
                    CameraReady();
                end

                -- Delay so we don't advance too much.
                Mission.m_CutsceneStateDelay = Mission.m_MissionTime + SecondsToTurns(15);

                -- So we don't loop.
                Mission.m_PrepCamera3 = true;
            end

            -- Again, only if we're not in coop.
            if (Mission.m_IsCooperativeMode == false) then
                CameraPath("bigspawn_campath3", 3000, 1200, Mission.m_BigSpawn_Cam3Look);
            end

            -- Advance the state of the cutscenes.
            if (Mission.m_CutsceneStateDelay < Mission.m_MissionTime) then
                Mission.m_CutsceneState = Mission.m_CutsceneState + 1;
            end
        elseif (Mission.m_CutsceneState == 4) then
            -- Prepare the fourth camera.
            if (Mission.m_PrepCamera4 == false) then
                -- If we are not coop, then start the camera sequence.
                if (Mission.m_IsCooperativeMode == false) then
                    -- Start the camera.
                    CameraReady();
                end

                -- Delay so we don't advance too much.
                Mission.m_CutsceneStateDelay = Mission.m_MissionTime + SecondsToTurns(10);

                -- So we don't loop.
                Mission.m_PrepCamera4 = true;
            end

            -- Again, only if we're not in coop.
            if (Mission.m_IsCooperativeMode == false) then
                CameraPath("bigspawn_campath4", 3000, 100, Mission.m_BigSpawn_Cam4Look);
            end

            -- Advance the state of the cutscenes.
            if (Mission.m_CutsceneStateDelay < Mission.m_MissionTime) then
                Mission.m_CutsceneState = Mission.m_CutsceneState + 1;
            end
        elseif (Mission.m_CutsceneState == 5) then
            -- Prepare the fifth camera.
            if (Mission.m_PrepCamera5 == false) then
                -- If we are not coop, then start the camera sequence.
                if (Mission.m_IsCooperativeMode == false) then
                    -- Start the camera.
                    CameraReady();
                end

                -- Delay so we don't advance too much.
                Mission.m_CutsceneStateDelay = Mission.m_MissionTime + SecondsToTurns(7);

                -- Delay for cutscene voices.
                Mission.m_CutsceneVoiceDelay = Mission.m_MissionTime + SecondsToTurns(2);

                -- So we don't loop.
                Mission.m_PrepCamera5 = true;
            end

            -- Again, only if we're not in coop.
            if (Mission.m_IsCooperativeMode == false) then
                CameraObject(Mission.m_Bossman, 0, -5, 20, Mission.m_Bossman);
            end

            -- First voice over for the missions.
            if (Mission.m_CutsceneVO1Played == false and Mission.m_CutsceneVoiceDelay < Mission.m_MissionTime) then
                -- So...you thought it would be that easy? I think not
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("cutsc0401.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

                -- So we don't loop.
                Mission.m_CutsceneVO1Played = true;
            end

            -- Advance the state of the cutscenes.
            if (Mission.m_CutsceneStateDelay < Mission.m_MissionTime) then
                Mission.m_CutsceneState = Mission.m_CutsceneState + 1;
            end
        elseif (Mission.m_CutsceneState == 6) then
            -- Prepare the sixth camera.
            if (Mission.m_PrepCamera6 == false) then
                -- If we are not coop, then start the camera sequence.
                if (Mission.m_IsCooperativeMode == false) then
                    -- Start the camera.
                    CameraReady();
                end

                -- Set the Hauler to low health.
                SetMaxHealth(Mission.m_Tug1, 775);
                SetCurHealth(Mission.m_Tug1, 775);

                -- Give the AI their independence.
                SetIndependence(Mission.m_Stealer9, 1);
                SetIndependence(Mission.m_Stealer10, 1);
                SetIndependence(Mission.m_Stealer11, 1);
                SetIndependence(Mission.m_Stealer12, 1);

                -- Small delay for the next scene where the warriors attack the Hauler.
                Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.5);

                -- So we don't loop.
                Mission.m_PrepCamera6 = true;
            end

            if (Mission.m_CutsceneAttackTug == false) then
                -- Attack the Hauler.
                Attack(Mission.m_Stealer9, Mission.m_Tug1, 1);
                Attack(Mission.m_Stealer10, Mission.m_Tug1, 1);
                Attack(Mission.m_Stealer11, Mission.m_Tug1, 1);
                Attack(Mission.m_Stealer12, Mission.m_Tug1, 1);

                -- So we don't loop.
                Mission.m_CutsceneAttackTug = true;
            end

            if (Mission.m_CutsceneTugDead == false and IsAround(Mission.m_Tug1) == false) then
                -- Strip the AI of their independence.
                SetIndependence(Mission.m_Stealer9, 0);
                SetIndependence(Mission.m_Stealer10, 0);
                SetIndependence(Mission.m_Stealer11, 0);
                SetIndependence(Mission.m_Stealer12, 0);

                -- Send the Warriors back to their path.
                Retreat(Mission.m_Stealer9, "stealer9");
                Retreat(Mission.m_Stealer10, "stealer10");
                Retreat(Mission.m_Stealer11, "stealer11");
                Retreat(Mission.m_Stealer12, "stealer12");

                -- For the next part of the cutscene.
                Mission.m_CutsceneStateDelay = Mission.m_MissionTime + SecondsToTurns(7.5);

                -- For the next VO time.
                Mission.m_CutsceneVoiceDelay = Mission.m_MissionTime + SecondsToTurns(4);

                -- So we don't loop.
                Mission.m_CutsceneTugDead = true;
            end

            if (Mission.m_CutsceneTugDead and Mission.m_CutsceneVO3Played == false and Mission.m_CutsceneVoiceDelay < Mission.m_MissionTime) then
                -- "Why, why do you betray us?"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("cutsc0403.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                -- So we don't loop.
                Mission.m_CutsceneVO3Played = true;
            end

            if (Mission.m_Stealer9Relook == false and GetDistance(Mission.m_Stealer9, "stealer9") < 8) then
                -- Relook at the target.
                LookAt(Mission.m_Stealer9, Mission.m_AILook);

                -- So we don't loop.
                Mission.m_Stealer9Relook = true;
            end

            if (Mission.m_Stealer10Relook == false and GetDistance(Mission.m_Stealer10, "stealer10") < 8) then
                -- Relook at the target.
                LookAt(Mission.m_Stealer10, Mission.m_AILook);

                -- So we don't loop.
                Mission.m_Stealer10Relook = true;
            end

            if (Mission.m_Stealer11Relook == false and GetDistance(Mission.m_Stealer11, "stealer11") < 8) then
                -- Relook at the target.
                LookAt(Mission.m_Stealer11, Mission.m_AILook);

                -- So we don't loop.
                Mission.m_Stealer11Relook = true;
            end

            if (Mission.m_Stealer12Relook == false and GetDistance(Mission.m_Stealer12, "stealer12") < 8) then
                -- Relook at the target.
                LookAt(Mission.m_Stealer12, Mission.m_AILook);

                -- So we don't loop.
                Mission.m_Stealer12Relook = true;
            end

            -- Again, only if we're not in coop.
            if (Mission.m_IsCooperativeMode == false) then
                CameraPath("tugshot_campath1", 3000, 0, Mission.m_TugShot_Look1);
            end

            -- Advance the state of the cutscenes.
            if (Mission.m_CutsceneTugDead and Mission.m_CutsceneStateDelay < Mission.m_MissionTime) then
                Mission.m_CutsceneState = Mission.m_CutsceneState + 1;
            end
        elseif (Mission.m_CutsceneState == 7) then
            -- Prepare the seventh camera.
            if (Mission.m_PrepCamera7 == false) then
                -- If we are not coop, then start the camera sequence.
                if (Mission.m_IsCooperativeMode == false) then
                    -- Start the camera.
                    CameraReady();
                end

                -- Small delay before the next voice line.
                Mission.m_CutsceneVoiceDelay = Mission.m_MissionTime + SecondsToTurns(0.5);

                -- So we don't loop.
                Mission.m_PrepCamera7 = true;
            end

            if (Mission.m_CutsceneVO4Played == false and Mission.m_CutsceneVoiceDelay < Mission.m_MissionTime) then
                -- "Our home is here, and if our core planet dies, we die with it. We will not return to earth to live among humans"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("cutsc0404.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

                -- So we don't loop.
                Mission.m_CutsceneVO4Played = true;
            end

            if (Mission.m_CutsceneVO5Played == false and Mission.m_CutsceneVO4Played and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                -- "Were WE not once human?"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("cutsc0405.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

                -- So we don't loop.
                Mission.m_CutsceneVO5Played = true;
            end

            if (Mission.m_CutsceneVO6Played == false and Mission.m_CutsceneVO5Played and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                -- "You perhaps. But I am Scion, through and through,"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("cutsc0406.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

                -- So we don't loop.
                Mission.m_CutsceneVO6Played = true;
            end

            if (Mission.m_CutsceneVO6Played and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                Mission.m_CutsceneState = Mission.m_CutsceneState + 1;
            end

            -- Again, only if we're not in coop.
            if (Mission.m_IsCooperativeMode == false) then
                CameraPath("shot7_path1", 500, 120, Mission.m_Bossman);
            end
        elseif (Mission.m_CutsceneState == 8) then
            -- Again, only if we're not in coop.
            if (Mission.m_IsCooperativeMode == false) then
                CameraFinish();
            end

            -- Give the units back to the player.
            if (IsPlayer(Mission.m_FVSent1) == false and IsAlive(Mission.m_FVSent1)) then
                SetIndependence(Mission.m_FVSent1, 1);
            end

            if (IsPlayer(Mission.m_FVSent2) == false and IsAlive(Mission.m_FVSent2)) then
                SetIndependence(Mission.m_FVSent2, 1);
            end

            if (IsPlayer(Mission.m_FVSent3) == false and IsAlive(Mission.m_FVSent3)) then
                SetIndependence(Mission.m_FVSent3, 1);
            end

            if (IsPlayer(Mission.m_FVTank1) == false and IsAlive(Mission.m_FVTank1)) then
                SetIndependence(Mission.m_FVTank1, 1);
            end

            if (IsPlayer(Mission.m_FVTank2) == false and IsAlive(Mission.m_FVTank2)) then
                SetIndependence(Mission.m_FVTank2, 1);
            end

            if (IsPlayer(Mission.m_FVTank3) == false and IsAlive(Mission.m_FVTank3)) then
                SetIndependence(Mission.m_FVTank3, 1);
            end

            if (IsPlayer(Mission.m_FVArch1) == false and IsAlive(Mission.m_FVArch1)) then
                SetIndependence(Mission.m_FVArch1, 1);
            end

            if (IsPlayer(Mission.m_FVArch2) == false and IsAlive(Mission.m_FVArch2)) then
                SetIndependence(Mission.m_FVArch2, 1);
            end

            if (IsAlive(Mission.m_FVServ1)) then
                SetIndependence(Mission.m_FVServ1, 1);
            end

            -- Minor delay before the next mission state.
            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

            -- Move to the next state.
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end

    -- Spawn the "actors".
    if (Mission.m_SpawnStealerPair1 == false and Mission.m_StealerPair1Timer < Mission.m_MissionTime) then
        -- Spawn the first pair.
        Mission.m_Stealer1 = BuildObject("fvtkscn4", 7, "bigspawn1");
        Mission.m_Stealer7 = BuildObject("fvtkscn4", 7, "bigspawn2");

        -- Have them retreat.
        Retreat(Mission.m_Stealer1, "stealer1");
        Retreat(Mission.m_Stealer7, "stealer7");

        -- Tweak their health.
        SetMaxHealth(Mission.m_Stealer1, 6000);
        SetCurHealth(Mission.m_Stealer1, 6000);
        SetMaxHealth(Mission.m_Stealer7, 6000);
        SetCurHealth(Mission.m_Stealer7, 6000);

        SetIndependence(Mission.m_Stealer1, 0);
        SetIndependence(Mission.m_Stealer7, 0);

        -- So we don't loop.
        Mission.m_SpawnStealerPair1 = true;
    end

    if (Mission.m_SpawnStealerPair2 == false and Mission.m_StealerPair2Timer < Mission.m_MissionTime) then
        -- Spawn the first pair.
        Mission.m_Stealer2 = BuildObject("fvtkscn4", 7, "bigspawn1");
        Mission.m_Stealer8 = BuildObject("fvtkscn4", 7, "bigspawn2");

        -- Have them retreat.
        Retreat(Mission.m_Stealer2, "stealer2");
        Retreat(Mission.m_Stealer8, "stealer8");

        -- Tweak their health.
        SetMaxHealth(Mission.m_Stealer2, 6000);
        SetCurHealth(Mission.m_Stealer2, 6000);
        SetMaxHealth(Mission.m_Stealer8, 6000);
        SetCurHealth(Mission.m_Stealer8, 6000);

        SetIndependence(Mission.m_Stealer2, 0);
        SetIndependence(Mission.m_Stealer8, 0);

        -- So we don't loop.
        Mission.m_SpawnStealerPair2 = true;
    end

    if (Mission.m_SpawnStealerPair3 == false and Mission.m_StealerPair3Timer < Mission.m_MissionTime) then
        -- Spawn the first pair.
        Mission.m_Stealer3 = BuildObject("fvtkscn4", 7, "bigspawn1");
        Mission.m_Stealer9 = BuildObject("fvtkscn4", 7, "bigspawn2");

        -- Have them retreat.
        Retreat(Mission.m_Stealer3, "stealer3");
        Retreat(Mission.m_Stealer9, "stealer9");

        -- Tweak their health.
        SetMaxHealth(Mission.m_Stealer3, 6000);
        SetCurHealth(Mission.m_Stealer3, 6000);
        SetMaxHealth(Mission.m_Stealer9, 6000);
        SetCurHealth(Mission.m_Stealer9, 6000);

        SetIndependence(Mission.m_Stealer3, 0);
        SetIndependence(Mission.m_Stealer9, 0);

        -- So we don't loop.
        Mission.m_SpawnStealerPair3 = true;
    end

    if (Mission.m_SpawnStealerPair4 == false and Mission.m_StealerPair4Timer < Mission.m_MissionTime) then
        -- Spawn the first pair.
        Mission.m_Stealer4 = BuildObject("fvtkscn4", 7, "bigspawn1");
        Mission.m_Stealer10 = BuildObject("fvtkscn4", 7, "bigspawn2");

        -- Have them retreat.
        Retreat(Mission.m_Stealer4, "stealer4");
        Retreat(Mission.m_Stealer10, "stealer10");

        -- Tweak their health.
        SetMaxHealth(Mission.m_Stealer4, 6000);
        SetCurHealth(Mission.m_Stealer4, 6000);
        SetMaxHealth(Mission.m_Stealer10, 6000);
        SetCurHealth(Mission.m_Stealer10, 6000);

        SetIndependence(Mission.m_Stealer4, 0);
        SetIndependence(Mission.m_Stealer10, 0);

        -- So we don't loop.
        Mission.m_SpawnStealerPair4 = true;
    end

    if (Mission.m_SpawnStealerPair5 == false and Mission.m_StealerPair5Timer < Mission.m_MissionTime) then
        -- Spawn the first pair.
        Mission.m_Stealer5 = BuildObject("fvtkscn4", 7, "bigspawn1");
        Mission.m_Stealer11 = BuildObject("fvtkscn4", 7, "bigspawn2");

        -- Have them retreat.
        Retreat(Mission.m_Stealer5, "stealer5");
        Retreat(Mission.m_Stealer11, "stealer11");

        -- Tweak their health.
        SetMaxHealth(Mission.m_Stealer5, 6000);
        SetCurHealth(Mission.m_Stealer5, 6000);
        SetMaxHealth(Mission.m_Stealer11, 6000);
        SetCurHealth(Mission.m_Stealer11, 6000);

        SetIndependence(Mission.m_Stealer5, 0);
        SetIndependence(Mission.m_Stealer11, 0);

        -- So we don't loop.
        Mission.m_SpawnStealerPair5 = true;
    end

    if (Mission.m_SpawnStealerPair6 == false and Mission.m_StealerPair6Timer < Mission.m_MissionTime) then
        -- Spawn the first pair.
        Mission.m_Stealer6 = BuildObject("fvtkscn4", 7, "bigspawn1");
        Mission.m_Stealer12 = BuildObject("fvtkscn4", 7, "bigspawn2");

        -- Have them retreat.
        Retreat(Mission.m_Stealer6, "stealer6");
        Retreat(Mission.m_Stealer12, "stealer12");

        -- Tweak their health.
        SetMaxHealth(Mission.m_Stealer6, 6000);
        SetCurHealth(Mission.m_Stealer6, 6000);
        SetMaxHealth(Mission.m_Stealer12, 6000);
        SetCurHealth(Mission.m_Stealer12, 6000);

        SetIndependence(Mission.m_Stealer6, 0);
        SetIndependence(Mission.m_Stealer12, 0);

        -- Small delay before we move the Walkers.
        Mission.m_WalkerMoveTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- So we don't loop.
        Mission.m_SpawnStealerPair6 = true;
    end

    -- Controlling the Warriors.
    if (Mission.m_SpawnStealerPair1) then
        if (Mission.m_Stop1 == false and GetDistance(Mission.m_Stealer1, "stealer1") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer1, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop1 = true;
        end

        if (Mission.m_Stop7 == false and GetDistance(Mission.m_Stealer7, "stealer7") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer7, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop7 = true;
        end
    end

    if (Mission.m_SpawnStealerPair2) then
        if (Mission.m_Stop2 == false and GetDistance(Mission.m_Stealer2, "stealer2") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer2, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop2 = true;
        end

        if (Mission.m_Stop8 == false and GetDistance(Mission.m_Stealer8, "stealer8") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer8, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop8 = true;
        end
    end

    if (Mission.m_SpawnStealerPair3) then
        if (Mission.m_Stop3 == false and GetDistance(Mission.m_Stealer3, "stealer3") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer3, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop3 = true;
        end

        if (Mission.m_Stop9 == false and GetDistance(Mission.m_Stealer9, "stealer9") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer9, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop9 = true;
        end
    end

    if (Mission.m_SpawnStealerPair4) then
        if (Mission.m_Stop4 == false and GetDistance(Mission.m_Stealer4, "stealer4") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer4, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop4 = true;
        end

        if (Mission.m_Stop10 == false and GetDistance(Mission.m_Stealer10, "stealer10") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer10, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop10 = true;
        end
    end

    if (Mission.m_SpawnStealerPair5) then
        if (Mission.m_Stop5 == false and GetDistance(Mission.m_Stealer5, "stealer5") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer5, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop5 = true;
        end

        if (Mission.m_Stop11 == false and GetDistance(Mission.m_Stealer11, "stealer11") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer11, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop11 = true;
        end
    end

    if (Mission.m_SpawnStealerPair6) then
        if (Mission.m_Stop6 == false and GetDistance(Mission.m_Stealer6, "stealer6") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer6, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop6 = true;
        end

        if (Mission.m_Stop12 == false and GetDistance(Mission.m_Stealer12, "stealer12") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Stealer12, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Stop12 = true;
        end
    end

    -- Controlling the Walkers.
    if (Mission.m_SpawnStealerPair6 and Mission.m_WalkerMove == false and Mission.m_WalkerMoveTime < Mission.m_MissionTime) then
        -- Let's move the walkers.
        Retreat(Mission.m_StealerWalker1, "walk1_path");
        Retreat(Mission.m_StealerWalker2, "walk2_path");

        -- Delay for the "Bossman" walker to move.
        Mission.m_BossmanMoveTime = Mission.m_MissionTime + SecondsToTurns(15);

        -- So we don't loop.
        Mission.m_WalkerMove = true;
    end

    if (Mission.m_WalkerMove) then
        if (Mission.m_BossmanMove == false and Mission.m_BossmanMoveTime < Mission.m_MissionTime) then
            -- Have "Bossman" retreat.
            Retreat(Mission.m_Bossman, "bossman");

            -- So we don't loop.
            Mission.m_BossmanMove = true;
        end

        if (Mission.m_Walker1Stop == false and GetDistance(Mission.m_StealerWalker1, "walk1_path_end") < 15) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_StealerWalker1, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Walker1Stop = true;
        end

        if (Mission.m_Walker2Stop == false and GetDistance(Mission.m_StealerWalker2, "walk2_path_end") < 15) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_StealerWalker2, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Walker2Stop = true;
        end

        if (Mission.m_BossmanStop == false and GetDistance(Mission.m_Bossman, "bossman") < 5) then
            -- Have the AI look at the right place.
            LookAt(Mission.m_Bossman, Mission.m_AILook);

            -- So we don't loop.
            Mission.m_Walker2Stop = true;
        end
    end

    -- Controlling the Hauler.
    if (Mission.m_StopTug == false and Mission.m_StartBigSpawn) then
        if (GetDistance(Mission.m_Tug1, "tug_die_here") < 10) then
            -- Have the tug look at the machine.
            LookAt(Mission.m_Tug1, Mission.m_Machine);

            -- So we don't loop.
            Mission.m_StopTug = true;
        end
    end
end

Functions[7] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        if (Mission.m_RebelsAttack == false) then
            -- "John run! Get to the dropship!";
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0410.wav");

            -- Don't let the crystal die.
            SetTeamNum(Mission.m_Power, 0);
            SetMaxHealth(Mission.m_Power, 0);

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- Agro the AI.
            SetIndependence(Mission.m_Stealer1, 1);
            SetIndependence(Mission.m_Stealer2, 1);
            SetIndependence(Mission.m_Stealer3, 1);
            SetIndependence(Mission.m_Stealer4, 1);
            SetIndependence(Mission.m_Stealer5, 1);
            SetIndependence(Mission.m_Stealer6, 1);

            -- Reserves to release in the next 15 seconds.
            SetIndependence(Mission.m_Stealer7, 0);
            SetIndependence(Mission.m_Stealer8, 0);
            SetIndependence(Mission.m_Stealer9, 0);
            SetIndependence(Mission.m_Stealer10, 0);
            SetIndependence(Mission.m_Stealer11, 0);
            SetIndependence(Mission.m_Stealer12, 0);

            -- Give the AI something to attack other than the player so the player can get away.
            if (Mission.m_RebelsPickTarget == false) then
                -- Check to see what units we can attack.
                if (IsPlayer(Mission.m_FVTank1) == false and IsAlive(Mission.m_FVTank1) and GetDistance(Mission.m_FVTank1, Mission.m_Machine) < 600) then
                    Attack(Mission.m_Stealer1, Mission.m_FVTank1);
                    Attack(Mission.m_Stealer2, Mission.m_FVTank1);
                    Attack(Mission.m_Stealer3, Mission.m_FVTank1);
                    Attack(Mission.m_Stealer4, Mission.m_FVTank1);
                    Attack(Mission.m_Stealer5, Mission.m_FVTank1);
                    Attack(Mission.m_Stealer6, Mission.m_FVTank1);

                    -- Found a target, break loop.
                    Mission.m_RebelsPickTarget = true;
                elseif (IsPlayer(Mission.m_FVTank2) == false and IsAlive(Mission.m_FVTank2) and GetDistance(Mission.m_FVTank2, Mission.m_Machine) < 600) then
                    Attack(Mission.m_Stealer1, Mission.m_FVTank2);
                    Attack(Mission.m_Stealer2, Mission.m_FVTank2);
                    Attack(Mission.m_Stealer3, Mission.m_FVTank2);
                    Attack(Mission.m_Stealer4, Mission.m_FVTank2);
                    Attack(Mission.m_Stealer5, Mission.m_FVTank2);
                    Attack(Mission.m_Stealer6, Mission.m_FVTank2);

                    -- Found a target, break loop.
                    Mission.m_RebelsPickTarget = true;
                elseif (IsPlayer(Mission.m_FVTank3) == false and IsAlive(Mission.m_FVTank3) and GetDistance(Mission.m_FVTank3, Mission.m_Machine) < 600) then
                    Attack(Mission.m_Stealer1, Mission.m_FVTank3);
                    Attack(Mission.m_Stealer2, Mission.m_FVTank3);
                    Attack(Mission.m_Stealer3, Mission.m_FVTank3);
                    Attack(Mission.m_Stealer4, Mission.m_FVTank3);
                    Attack(Mission.m_Stealer5, Mission.m_FVTank3);
                    Attack(Mission.m_Stealer6, Mission.m_FVTank3);

                    -- Found a target, break loop.
                    Mission.m_RebelsPickTarget = true;
                elseif (IsPlayer(Mission.m_FVSent1) == false and IsAlive(Mission.m_FVSent1) and GetDistance(Mission.m_FVSent1, Mission.m_Machine) < 600) then
                    Attack(Mission.m_Stealer1, Mission.m_FVSent1);
                    Attack(Mission.m_Stealer2, Mission.m_FVSent1);
                    Attack(Mission.m_Stealer3, Mission.m_FVSent1);
                    Attack(Mission.m_Stealer4, Mission.m_FVSent1);
                    Attack(Mission.m_Stealer5, Mission.m_FVSent1);
                    Attack(Mission.m_Stealer6, Mission.m_FVSent1);

                    -- Found a target, break loop.
                    Mission.m_RebelsPickTarget = true;
                elseif (IsPlayer(Mission.m_FVSent2) == false and IsAlive(Mission.m_FVSent2) and GetDistance(Mission.m_FVSent2, Mission.m_Machine) < 600) then
                    Attack(Mission.m_Stealer1, Mission.m_FVSent2);
                    Attack(Mission.m_Stealer2, Mission.m_FVSent2);
                    Attack(Mission.m_Stealer3, Mission.m_FVSent2);
                    Attack(Mission.m_Stealer4, Mission.m_FVSent2);
                    Attack(Mission.m_Stealer5, Mission.m_FVSent2);
                    Attack(Mission.m_Stealer6, Mission.m_FVSent2);

                    -- Found a target, break loop.
                    Mission.m_RebelsPickTarget = true;
                elseif (IsPlayer(Mission.m_FVSent3) == false and IsAlive(Mission.m_FVSent3) and GetDistance(Mission.m_FVSent3, Mission.m_Machine) < 600) then
                    Attack(Mission.m_Stealer1, Mission.m_FVSent3);
                    Attack(Mission.m_Stealer2, Mission.m_FVSent3);
                    Attack(Mission.m_Stealer3, Mission.m_FVSent3);
                    Attack(Mission.m_Stealer4, Mission.m_FVSent3);
                    Attack(Mission.m_Stealer5, Mission.m_FVSent3);
                    Attack(Mission.m_Stealer6, Mission.m_FVSent3);

                    -- Found a target, break loop.
                    Mission.m_RebelsPickTarget = true;
                end
            end

            -- Small delay before releasing the rest of the Rebels.
            Mission.m_RebelReserveReleaseTimer = Mission.m_MissionTime + SecondsToTurns(15);

            -- Objectives.
            AddObjectiveOverride("scion0406.otf", "WHITE", 10, true);

            -- Remove the highlight from the Alchemator.
            SetObjectiveOff(Mission.m_Machine);

            -- Change the Dropship team number.
            SetTeamNum(Mission.m_Dropship1, Mission.m_HostTeam);

            -- Highlight the dropship.
            SetObjectiveName(Mission.m_Dropship1, TranslateString("Mission1702"));
            SetObjectiveOn(Mission.m_Dropship1);

            -- So we don't loop.
            Mission.m_RebelsAttack = true;
        elseif (Mission.m_RebelsReserveAttack == false and Mission.m_RebelReserveReleaseTimer < Mission.m_MissionTime) then
            -- Agro the AI.
            SetIndependence(Mission.m_Stealer7, 1);
            SetIndependence(Mission.m_Stealer8, 1);
            SetIndependence(Mission.m_Stealer9, 1);
            SetIndependence(Mission.m_Stealer10, 1);
            SetIndependence(Mission.m_Stealer11, 1);
            SetIndependence(Mission.m_Stealer12, 1);

            -- Send them after the player.
            Attack(Mission.m_Stealer7, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer8, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer9, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer10, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer11, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer12, Mission.m_MainPlayer);

            -- Small delay before sending the rest of the Rebels after the player.
            Mission.m_RebelsChasePlayerTimer = Mission.m_MissionTime + SecondsToTurns(10);

            -- So we don't loop.
            Mission.m_RebelsReserveAttack = true;
        elseif (Mission.m_RebelsChasePlayer == false and Mission.m_RebelsChasePlayerTimer < Mission.m_MissionTime) then
            -- Send the rest of the Rebels to chase the player.
            Attack(Mission.m_Stealer1, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer2, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer3, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer4, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer5, Mission.m_MainPlayer);
            Attack(Mission.m_Stealer6, Mission.m_MainPlayer);

            -- Give the Maulers their AI back and send them too.
            SetIndependence(Mission.m_Bossman, 1);
            SetIndependence(Mission.m_StealerWalker1, 1);
            SetIndependence(Mission.m_StealerWalker2, 1);

            Attack(Mission.m_Bossman, Mission.m_MainPlayer, 1);
            Attack(Mission.m_StealerWalker1, Mission.m_MainPlayer, 1);
            Attack(Mission.m_StealerWalker2, Mission.m_MainPlayer, 1);

            -- So we don't loop.
            Mission.m_RebelsChasePlayer = true;
        end
    end

    -- This checks to see if the player has made it to the dropship.
    if (Mission.m_RebelsAttack and IsPlayerWithinDistance(Mission.m_Dropship1, 10, _Cooperative.m_TotalPlayerCount)) then
        -- Clean up the Rebels.
        RemoveObject(Mission.m_Stealer1);
        RemoveObject(Mission.m_Stealer2);
        RemoveObject(Mission.m_Stealer3);
        RemoveObject(Mission.m_Stealer4);
        RemoveObject(Mission.m_Stealer5);
        RemoveObject(Mission.m_Stealer6);
        RemoveObject(Mission.m_Stealer7);
        RemoveObject(Mission.m_Stealer8);
        RemoveObject(Mission.m_Stealer9);
        RemoveObject(Mission.m_Stealer10);
        RemoveObject(Mission.m_Stealer11);
        RemoveObject(Mission.m_Stealer12);

        RemoveObject(Mission.m_Bossman);
        RemoveObject(Mission.m_StealerWalker1);
        RemoveObject(Mission.m_StealerWalker2);

        -- Stop the wingmen so they don't follow the player.
        Stop(Mission.m_FVSent1);
        Stop(Mission.m_FVSent2);
        Stop(Mission.m_FVSent3);
        Stop(Mission.m_FVTank1);
        Stop(Mission.m_FVTank2);
        Stop(Mission.m_FVTank3);
        Stop(Mission.m_FVServ1);
        Stop(Mission.m_FVArch1);
        Stop(Mission.m_FVArch2);

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (Mission.m_IsCooperativeMode) then
        -- So we don't loop.
        Mission.m_MissionOver = true;

        -- Finish the mission.
        NoteGameoverWithCustomMessage("Mission Accomplished.");
        DoGameover(10);
    end

    -- This will handle the cutscene if we are not in Cooperative.
    if (Mission.m_PrepFinalCamera == false) then
        -- Prepare the Camera.
        CameraReady();

        -- Change the cinematic dropship to the right team.
        SetTeamNum(Mission.m_Dropship2, Mission.m_HostTeam);

        -- Build the "Fakers".
        Mission.m_Faker1 = BuildObject("fvtank_x", 7, "faker1");
        Mission.m_Faker2 = BuildObject("fvtank_x", 7, "faker2");
        Mission.m_Faker3 = BuildObject("fvtank_x", 7, "faker3");
        Mission.m_Faker4 = BuildObject("fvtank_x", 7, "faker4");

        -- Have them attack the Dropship.
        Attack(Mission.m_Faker1, Mission.m_Dropship2);
        Attack(Mission.m_Faker2, Mission.m_Dropship2);
        Attack(Mission.m_Faker3, Mission.m_Dropship2);
        Attack(Mission.m_Faker4, Mission.m_Dropship2);

        -- Prepare the Dropship for take-off.
        Mission.m_TakeoffTime = Mission.m_MissionTime + SecondsToTurns(8);

        -- So we don't loop.
        Mission.m_PrepFinalCamera = true;
    end

    -- Start the Camera Path for the final scene.
    CameraPath("takeoff_campath1", 1000, 0, Mission.m_Dropship2);

    if (Mission.m_TakeoffDone == false and Mission.m_TakeoffTime < Mission.m_MissionTime) then
        -- Have the Dropship perform the take-off.
        SetAnimation(Mission.m_Dropship2, "takeoff", 1);

        -- Timer for the "Fakers" to stop attacking the Dropship.
        Mission.m_FakersStopAttackTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Timer for the take-off sound.
        Mission.m_TakeoffSoundTime = Mission.m_MissionTime + SecondsToTurns(4);

        -- So we don't loop.
        Mission.m_TakeoffDone = true;
    end

    -- Check to see when we need to play the dropshop take-off sound.
    if (Mission.m_TakeoffDone) then
        if (Mission.m_TakeoffSoundDone == false and Mission.m_TakeoffSoundTime < Mission.m_MissionTime) then
            -- Play the dropship sound.
            AudioMessage("droptoff.wav");

            -- So we don't loop.
            Mission.m_TakeoffSoundDone = true;
        end

        if (Mission.m_FakersStopAttack == false and Mission.m_FakersStopAttackTime < Mission.m_MissionTime) then
            SetIndependence(Mission.m_Faker1, 0);
			SetIndependence(Mission.m_Faker2, 0);
			SetIndependence(Mission.m_Faker3, 0);
			SetIndependence(Mission.m_Faker4, 0);

            -- Have the fakers go out of shot.
            Patrol(Mission.m_Faker1, "faker_path");
            Patrol(Mission.m_Faker2, "faker_path");
            Patrol(Mission.m_Faker3, "faker_path");
            Patrol(Mission.m_Faker4, "faker_path");

            -- Succeed the mission.
            SucceedMission(GetTime() + 10, "scion04w1.txt");

            -- So we don't loop.
            Mission.m_FakersStopAttack = true;

            -- Mission is done.
            Mission.m_MissionOver = true;
        end
    end
end

function RebuildRebels()
    -- Give them the normal scouts.
    Mission.m_Evil1 = ReplaceObject(Mission.m_Evil1, "fvscout_x");
    Mission.m_Evil2 = ReplaceObject(Mission.m_Evil2, "fvscout_x");
    Mission.m_Evil3 = ReplaceObject(Mission.m_Evil3, "fvscout_x");

    -- This is everything else. The Rebels will attack the player if they are sick of waiting.
    SetTeamNum(Mission.m_Evil1, 7);
    SetTeamNum(Mission.m_Evil2, 7);
    SetTeamNum(Mission.m_Evil3, 7);

    -- Give them their independence back.
    SetIndependence(Mission.m_Evil1, 1);
    SetIndependence(Mission.m_Evil2, 1);
    SetIndependence(Mission.m_Evil3, 1);

    -- So certain logic doesn't retreat.
    Mission.m_RebelsTurnEvil = true;
end

function AmbushBrain()
    if (Mission.m_MissionTime % SecondsToTurns(0.5) == 0) then
        -- This'll handle the ambush.
        for i = 1, _Cooperative.m_TotalPlayerCount do
            local pHandle = GetPlayerHandle(i);

            if (GetDistance(pHandle, "ambush") < 120) then
                -- Ambushers get thier brain back.
                SetIndependence(Mission.m_Ambusher1, 0);
                SetIndependence(Mission.m_Ambusher2, 0);
                SetIndependence(Mission.m_Ambusher3, 0);
                SetIndependence(Mission.m_Ambusher4, 0);
                SetIndependence(Mission.m_Ambusher5, 0);
                SetIndependence(Mission.m_Ambusher6, 0);

                -- Start attacking.
                Attack(Mission.m_Ambusher1, Mission.m_Tug1);
                Attack(Mission.m_Ambusher2, pHandle);
                Attack(Mission.m_Ambusher3, Mission.m_Tug1);
                Attack(Mission.m_Ambusher5, Mission.m_FVServ1);

                Attack(Mission.m_Ambusher4, pHandle);
                Attack(Mission.m_Ambusher6, pHandle);

                -- Rebuild the Rebels.
                RebuildRebels();

                -- Get them to attack the player who fell for the trap.
                Attack(Mission.m_Evil1, pHandle, 1);
                Attack(Mission.m_Evil2, pHandle, 1);
                Attack(Mission.m_Evil3, pHandle, 1);

                -- Little delay before Burns tells the player they fell into a trap.
                Mission.m_BurnsAmbushTimer = Mission.m_MissionTime + SecondsToTurns(2);

                -- So we don't loop.
                Mission.m_PlayerAmbushed = true;
            end
        end
    end
end

function AttacksBrain()
    -- Keep track of the attackers and when they have been sent.
    if (Mission.m_MissionTime % SecondsToTurns(0.5) == 0) then
        -- Check the first attackers.
        if (Mission.m_Attack1 == false) then
            -- Unique loop here so we know which player to attack.
            for i = 1, _Cooperative.m_TotalPlayerCount do
                -- Grab the player handle.
                local pHandle = GetPlayerHandle(i);

                -- Check the distance from the player to the ship of interest.
                if (GetDistance(pHandle, Mission.m_RTAttack2) < 150) then
                    -- Attack.
                    if (IsAliveAndEnemy(Mission.m_RTAttack2, Mission.m_EnemyTeam)) then
                        Goto(Mission.m_RTAttack2, pHandle, 1);
                    end

                    if (IsAliveAndEnemy(Mission.m_RTAttack3, Mission.m_EnemyTeam)) then
                        Goto(Mission.m_RTAttack3, pHandle, 1);
                    end

                    Mission.m_Attack1 = true;
                end
            end
        end
    end
end

function RebelBrain()
    if (Mission.m_MissionTime % SecondsToTurns(0.5) == 0) then
        -- First, check to see if the Player has met with the Rebels.
        if (Mission.m_PlayerMetRebels == false) then
            -- Unique loop here so we know which player to look at when we meet the Rebels.
            for i = 1, _Cooperative.m_TotalPlayerCount do
                -- Grab the player handle.
                local pHandle = GetPlayerHandle(i);

                -- Check the distance from the player to the ship of interest.
                if (GetDistance(pHandle, Mission.m_Evil1) < 110) then
                    -- Have the Rebels look at the nearest player.
                    LookAt(Mission.m_Evil1, pHandle);
                    LookAt(Mission.m_Evil2, pHandle);
                    LookAt(Mission.m_Evil3, pHandle);

                    -- Cooke stop! The way ahead is very dangerous, a massive ISDF blockade is entrenched in the canyon.  Follow us we know a safe way through the pass!
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0402.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

                    -- Make sure we mark this part as done.
                    Mission.m_PlayerMetRebels = true;
                end
            end
        elseif (Mission.m_RebelRetreat == false) then
            -- Wait to see if the Audio Message is done for the Rebels before they retreat.
            if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
                -- Move the Rebels down the path of retreat.
                Retreat(Mission.m_Evil1, "evilpath");

                -- Have the other Scouts follow.
                Follow(Mission.m_Evil2, Mission.m_Evil1, 1);
                Follow(Mission.m_Evil3, Mission.m_Evil2, 1);

                -- Make sure we mark this part as done.
                Mission.m_RebelRetreat = true;
            end
        else
            if (Mission.m_RebelsTurnEvil == false) then
                -- This'll check if we can "Resume" the paths.
                if (Mission.m_PlayerCaughtUp == false and Mission.m_RebelWarningCount > 0) then
                    -- Check to see if a player has caught up with the Rebels.
                    if (IsPlayerWithinDistance(Mission.m_Evil1, 100, _Cooperative.m_TotalPlayerCount)) then
                        -- Tell the Rebels to retreat again.
                        Retreat(Mission.m_Evil1, "evilpath");

                        -- Have the other Scouts follow.
                        Follow(Mission.m_Evil2, Mission.m_Evil1, 1);
                        Follow(Mission.m_Evil3, Mission.m_Evil2, 1);

                        -- Reset the warning timer.
                        Mission.m_RebelWarningTimer = 0;

                        -- So we don't loop.
                        Mission.m_PlayerCaughtUp = true;
                    end
                end

                -- The Rebels are moving, let's check to see if a player is still near them.
                if (Mission.m_RebelWarningTimer < Mission.m_MissionTime and IsPlayerWithinDistance(Mission.m_Evil1, 150, _Cooperative.m_TotalPlayerCount) == false) then
                    -- First warning for the Rebels.
                    if (Mission.m_RebelWarningCount == 0) then
                        -- Start the Rebel voices.
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0403.wav");

                        -- Set the timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

                        -- Give the player some time to catch up.
                        Mission.m_RebelWarningTimer = Mission.m_MissionTime + SecondsToTurns(30);

                        -- Have the Rebels stop and look at the player.
                        LookAt(Mission.m_Evil1, Mission.m_MainPlayer, 1);
                        LookAt(Mission.m_Evil2, Mission.m_MainPlayer, 1);
                        LookAt(Mission.m_Evil3, Mission.m_MainPlayer, 1);

                        -- Advance to the next step.
                        Mission.m_RebelWarningCount = Mission.m_RebelWarningCount + 1;
                    else
                        -- Ok Cooke, I was hoping we could do this the easy way but you are too stubborn! Attack men
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0405.wav");

                        -- Set the timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

                        -- Rebuild the Rebels so they use proper Scout ODFs to attack.
                        RebuildRebels();

                        -- Have them attack the player.
                        Attack(Mission.m_Evil1, Mission.m_MainPlayer, 1);
                        Attack(Mission.m_Evil2, Mission.m_MainPlayer, 1);
                        Attack(Mission.m_Evil3, Mission.m_MainPlayer, 1);
                    end
                end
            else
                -- Check to see if the Rebels are dead.
                if (Mission.m_Evil1Check == false and IsAliveAndEnemy(Mission.m_Evil1, 7) == false) then
                    -- Tell burns we will never return with him to earth!
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0407.wav");

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                    -- So we don't loop.
                    Mission.m_Evil1Check = true;
                end

                if (Mission.m_Evil2Check == false and IsAliveAndEnemy(Mission.m_Evil2, 7) == false) then
                    -- So we don't loop.
                    Mission.m_Evil2Check = true;
                end

                if (Mission.m_Evil3Check == false and IsAliveAndEnemy(Mission.m_Evil3, 7) == false) then
                    -- So we don't loop.
                    Mission.m_Evil3Check = true;
                end

                if (Mission.m_Evil1Check and Mission.m_Evil2Check and Mission.m_Evil3Check) then
                    -- For other functions.
                    Mission.m_EvilsDead = true;

                    -- Advance the mission state...
                    Mission.m_RebelBrainActive = false;
                end
            end
        end
    end
end

-- Checks for failure conditions.
function HandleFailureConditions()
    if (Mission.m_StartBigSpawn == false) then
        if (IsAround(Mission.m_Power) == false) then
            -- Stop the mission.
            Mission.m_MissionOver = true;

            -- The Power Crystal has been destroyed.
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0409.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- Show Objectives.
            AddObjectiveOverride("scion0403.otf", "RED", 10, true);

            -- Failure.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("The Power Crystal was destroyed.");
                DoGameover(10);
            else
                FailMission(GetTime() + 10, "scion04L1.txt");
            end
        end

        -- This checks if the Hauler is still alive before the big cutscene.
        if (IsAlive(Mission.m_Tug1) == false) then
            -- Stop the mission.
            Mission.m_MissionOver = true;

            -- Dammit the Hauler has been destroyed!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0415.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Show Objectives.
            AddObjectiveOverride("scion0404.otf", "RED", 10, true);

            -- Failure.
            if (Mission.m_IsCooperativeMode) then
                NoteGameoverWithCustomMessage("The Hauler was destroyed.");
                DoGameover(10);
            else
                FailMission(GetTime() + 10, "scion04L2.txt");
            end
        end
    end
end
