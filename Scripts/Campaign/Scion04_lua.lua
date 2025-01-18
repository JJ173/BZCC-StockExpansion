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

    m_Evil1Check = false,
    m_Evil2Check = false,
    m_Evil3Check = false,
    m_EvilsDead = false,

    m_Attack1 = false,

    m_RebelRetreat = false,
    m_RebelsTurnEvil = false,

    m_StartBigSpawn = false,

    m_PlayerMetRebels = false,
    m_PlayerAmbushed = false,
    m_PlayerCaughtUp = false,

    m_BurnsRebelDialogPlayed = false,
    m_BurnsAmbushDialogPlayed = false,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_RebelWarningCount = 0,
    m_RebelWarningTimer = 0,
    m_BurnsAmbushTimer = 0,

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

        -- Prevent other logic from running.
        Mission.m_Attack1 = true;
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
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0404.wav", false);

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

    -- Make sure the enemy doesn't attack the Team 5 units for now.
    if (Mission.m_IsCooperativeMode == false) then
        for i = 2, 5 do
            Ally(Mission.m_HostTeam, i);
        end

        Ally(Mission.m_AlliedTeam, Mission.m_EnemyTeam);
        Ally(Mission.m_EnemyTeam, 7);
    end

    -- Put the Rebel colour on teams 5 and 7 for coop.
    SetTeamColor(Mission.m_AlliedTeam, 85, 255, 85);
    SetTeamColor(7, 85, 255, 85);

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

    Mission.m_Bossman = BuildObject("fvwalk_x", 7, "bossman_spawn");

    -- Stop the AI from acting.
    SetIndependence(Mission.m_Bossman, 0);

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
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0401.wav", false);

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
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0408.wav", false);

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- So this doesn't loop.
            Mission.m_BurnsRebelDialogPlayed = true;
        end
    end

    if (Mission.m_PlayerAmbushed and Mission.m_EvilsDead == false and Mission.m_BurnsAmbushDialogPlayed == false and Mission.m_BurnsAmbushTimer < Mission.m_MissionTime) then
        if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            -- John, you fell right into a trap...those were the rebels!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0412.wav", false);

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

            -- So this doesn't loop.
            Mission.m_BurnsAmbushDialogPlayed = true;
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
        -- Unique loop here so we know which player to attack.
        for i = 1, _Cooperative.m_TotalPlayerCount do
            -- Check the first attackers.
            if (Mission.m_Attack1 == false) then
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
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0402.wav", false);

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
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0403.wav", false);

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
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0405.wav", false);

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
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0407.wav", false);

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
    if (IsAround(Mission.m_Power) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- The Power Crystal has been destroyed.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0409.wav", false);

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
    if (Mission.m_StartBigSpawn == false and IsAlive(Mission.m_Tug1) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Dammit the Hauler has been destroyed!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0415.wav", false);

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
