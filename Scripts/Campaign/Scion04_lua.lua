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

    m_Attack1 = false,

    m_PlayerAttackedRebels = false,
    m_PlayerAmbushed = false,
    m_RebelAttacksPlayer = false,
    m_PlayerCaughtUp = false,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,

    m_RebelWarningCount = 0,
    m_RebelWarningTimer = 0,

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

    -- Handle unit skill for enemy.
    if (teamNum == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);
    elseif (teamNum < Mission.m_AlliedTeam and teamNum > 0) then
        -- Always max our player units.
        SetSkill(h, 3);
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

            -- Check failure conditions...
            HandleFailureConditions();

            -- Attack Brains.
            AttacksBrain();
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

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_AlliedTeam, "Scion");
    SetTeamNameForStat(7, "Scion Rebels");
    SetTeamNameForStat(Mission.m_EnemyTeam, "ISDF");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
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

    Mission.m_Evil1 = GetHandle("evil1");
    Mission.m_Evil2 = GetHandle("evil2");
    Mission.m_Evil3 = GetHandle("evil3");

    Mission.m_Ambusher1 = GetHandle("ambusher1");
    Mission.m_Ambusher2 = GetHandle("ambusher1");
    Mission.m_Ambusher3 = GetHandle("ambusher1");
    Mission.m_Ambusher4 = GetHandle("ambusher1");
    Mission.m_Ambusher5 = GetHandle("ambusher1");
    Mission.m_Ambusher6 = GetHandle("ambusher1");

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

    -- Don't let the dropships die.
    SetMaxHealth(Mission.m_Dropship1, 0);
    SetMaxHealth(Mission.m_Dropship2, 0);

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
    -- This handles the Rebels meeting the player.
    if (Mission.m_MissionTime % SecondsToTurns(0.5) == 0) then
        -- Unique loop here so we know which player to look at when we meet the Rebels.
        for i = 1, _Cooperative.m_TotalPlayerCount do
            -- Grab the player handle.
            local pHandle = GetPlayerHandle(i);

            -- Check the distance from the player to the ship of interest.
            if (GetDistance(pHandle, Mission.m_Evil1) < 85) then
                -- Have the Rebels look at the nearest player.
                LookAt(Mission.m_Evil1, pHandle);
                LookAt(Mission.m_Evil2, pHandle);
                LookAt(Mission.m_Evil3, pHandle);

                -- Cooke stop! The way ahead is very dangerous, a massive ISDF blockade is entrenched in the canyon.  Follow us we know a safe way through the pass!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0402.wav", false);

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

                -- Advance the mission state...
                Mission.m_MissionState = Mission.m_MissionState + 1;
            end
        end
    end
end

Functions[5] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Move the Rebels down the path of retreat.
        Retreat(Mission.m_Evil1, "evilpath");

        -- Have the other Scouts follow.
        Follow(Mission.m_Evil2, Mission.m_Evil1, 1);
        Follow(Mission.m_Evil3, Mission.m_Evil2, 1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    -- These are the Rebel warnings.
    if (Mission.m_MissionTime % SecondsToTurns(0.5) == 0) then
        -- Check to see if the Rebels have been attacked first.
        if (Mission.m_PlayerAttackedRebels == false and Mission.m_RebelAttacksPlayer == false) then
            -- This'll check if we can "Resume" the paths.
            if (Mission.m_PlayerCaughtUp == false and Mission.m_RebelWarningCount > 0) then
                -- Check to see if a player has caught up with the Rebels.
                if (IsPlayerWithinDistance(Mission.m_Evil1, 100, _Cooperative.m_TotalPlayerCount)) then
                    -- Tell the Rebels to retreat again.
                    Retreat(Mission.m_Evil1, "evilpath");

                    -- Have the other Scouts follow.
                    Follow(Mission.m_Evil2, Mission.m_Evil1, 1);
                    Follow(Mission.m_Evil3, Mission.m_Evil2, 1);

                    -- So we don't loop.
                    Mission.m_PlayerCaughtUp = true;
                end
            end

            -- The Rebels are moving, let's check to see if a player is still near them.
            if (Mission.m_RebelWarningTimer < Mission.m_MissionTime and IsPlayerWithinDistance(Mission.m_Evil1, 110, _Cooperative.m_TotalPlayerCount) == false) then
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

                    -- This is everything else. The Rebels will attack the player if they are sick of waiting.
                    SetTeamNum(Mission.m_Evil1, 7);
                    SetTeamNum(Mission.m_Evil2, 7);
                    SetTeamNum(Mission.m_Evil3, 7);

                    -- Have them attack the player.
                    Attack(Mission.m_Evil1, Mission.m_MainPlayer, 1);
                    Attack(Mission.m_Evil2, Mission.m_MainPlayer, 1);
                    Attack(Mission.m_Evil3, Mission.m_MainPlayer, 1);

                    -- So we don't loop, and we can move to the next part of the mission.
                    Mission.m_RebelAttacksPlayer = true;
                end
            end
        end

        if (Mission.m_RebelAttacksPlayer or Mission.m_PlayerAttackedRebels) then
            -- Check to see if the Rebels are dead.
            if (IsAliveAndEnemy(Mission.m_Evil1, 7) == false and IsAliveAndEnemy(Mission.m_Evil2, 7) == false and IsAliveAndEnemy(Mission.m_Evil3, 7) == false) then
                -- Only play this voice from Burns if the player didn't fall for the trap.
                if (Mission.m_PlayerAmbushed == false) then
                    -- You did the right thing, John,  Those were the rebels!
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0408.wav", false);

                    -- Set the timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
                end

                -- Advance the mission state...
                Mission.m_MissionState = Mission.m_MissionState + 1;
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
                    Goto(Mission.m_RTAttack2, pHandle, 1);
                    Goto(Mission.m_RTAttack3, pHandle, 1);

                    Mission.m_Attack1 = true;
                end
            end
        end
    end
end

-- Checks for failure conditions.
function HandleFailureConditions()

end
