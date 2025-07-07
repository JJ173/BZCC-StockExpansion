--[[
    BZCC ISDF11 Lua Mission Script
    Written by AI_Unit
    Version 1.0 03-01-2024
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
local m_MissionName = "ISDF11: On Thin Ice";

local m_IceAttacker1 = { "fvscout_x", "fvsent_x", "fvtank_x" };
local m_IceAttacker2 = { "fvscout_x", "fvscout_x", "fvsent_x" };

-- Time before AIP switches to harder AIP.
local m_AIPSwitchTime = { 120, 60, 0 };

-- Mission important variables.
local Mission =
{
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_HostTeam = 1,
    m_AlliedTeam = 5,
    m_EnemyTeam = 6,

    -- Specific to mission.
    m_PlayerPilotODF = "ispilo_sx",
    -- Specific to mission.
    m_PlayerShipODF = "ivtank_x",

    m_Recycler = nil,
    m_Turret = nil,
    m_SRecycler = nil,
    m_Wingman = nil,
    m_CrashShip1 = nil,
    m_CrashShip2 = nil,
    m_Nav1 = nil,
    m_Nav2 = nil,
    m_Transport = nil,
    m_CrashTank = nil,
    m_CrashScout = nil,
    m_OpenDropship = nil,
    m_Dropship = nil,
    m_DropshipA = nil,
    m_DropshipB = nil,
    m_StandIn = nil,
    m_BlockTurret1 = nil,
    m_BlockTurret2 = nil,
    m_BlockTurret3 = nil,
    m_BlockTurret4 = nil,
    m_Holders = {},
    m_Rhino1 = nil,
    m_Rhino2 = nil,
    m_Rhino3 = nil,
    m_Rhino4 = nil,
    m_Scion1 = nil,
    m_Scion2 = nil,
    m_Scion3 = nil,
    m_Scion4 = nil,
    m_ScionPatrol1 = nil,
    m_ScionPatrol2 = nil,
    m_StopGuard1 = nil,
    m_StopGuard2 = nil,
    m_CheatTank1 = nil,
    m_CheatTank2 = nil,
    m_CheatTank3 = nil,
    m_CheatTank4 = nil,
    m_CheatTank5 = nil,
    m_ScionScav = nil,
    m_IceCap1S = nil,
    m_IceCap2S = nil,
    m_IceCap1 = nil,
    m_IceCap2 = nil,
    m_IceCap3 = nil,
    m_IceCap4 = nil,
    m_IceCap5 = nil,
    m_IceCap6 = nil,
    m_IceAttacker1 = nil,
    m_IceAttacker2 = nil,
    m_WingmanTarget = nil,
    m_DeadTank = nil,

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_StartIceAttackers = false,
    m_StartPatrol1 = false,
    m_StartPatrol2 = false,
    m_Patrol1Dead = false,
    m_Patrol2Dead = false,
    m_Discover1 = false,
    m_Discover2 = false,
    m_WingmanBrainActive = false,
    m_FreeWingman = false,
    m_CoverTracksMessagePlayed = false,
    m_DestroyHintMessagePlayed = false,
    m_CrawlingMessagePlayed = false,
    m_RecyclerDetectedMessagePlayed = false,
    m_RecyclerFirstMessagePlayed = false,
    m_FreeRecycler = false,
    m_IceCapsGone = false,
    m_ScionBaseMessagePlayed = false,
    m_RecyclerUnderway = false,
    m_CapsGoneMessagePlayed = false,
    m_RecyclerWhySelectMsgPlayed = false,
    m_RecyclerMadeItMsgPlayed = false,
    m_RecyclerUnderwayCanceled = false,
    m_RecyclerCapsGoneMsgPlayed = false,
    m_RecyclerMoveThroughIce = false,
    m_Rhino1Drowned = false,
    m_Rhino2Drowned = false,
    m_Rhino3Drowned = false,
    m_Rhino4Drowned = false,
    m_Rhino1Charge = false,
    m_Rhino2Charge = false,
    m_Rhino3Charge = false,
    m_Rhino4Charge = false,
    m_Rhino1Behave = false,
    m_Rhino2Behave = false,
    m_Rhino3Behave = false,
    m_Rhino4Behave = false,
    m_IceCap1SGone = false,
    m_IceCap2SGone = false,
    m_IceCap1Gone = false,
    m_IceCap2Gone = false,
    m_IceCap3Gone = false,
    m_IceCap4Gone = false,
    m_IceCap5Gone = false,
    m_IceCap6Gone = false,
    m_WingmanAttackCondor = false,
    m_WingmanIceRhinoMsgPlayed = false,
    m_CameraFinished = false,
    m_ShabFound = false,
    m_StopGuard1Sent = false,
    m_StopGuard2Sent = false,
    m_BlockGuard1Sent = false,
    m_BlockGuard2Sent = false,
    m_BlockGuard3Sent = false,
    m_BlockGuard4Sent = false,
    m_CheckForTurrets = false,
    m_LandSecureMsgPlayed = false,
    m_DropshipsLanding = false,
    m_DropshipsLanded = false,
    m_DropshipsFirstLanded = false,
    m_DropshipBLanded = false,
    m_DropshipDoorSoundPlayed = false,
    m_DropshipsInAir = true,
    m_DropshipsTakeOff = false,
    m_TransportMessagePlayed = false,
    m_PartTwo = false,
    m_ScionPatrolSent = false,
    m_PlayerHasFactory = false,
    m_AIPSwitched = false,
    m_CrashOneAround = true,
    m_CrashTwoAround = true,
    m_RecyclerBrainActive = false,
    m_SetupDropship = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_Patrol1Time = 0,
    m_Patrol2Time = 0,
    m_WingmanTime = 0,
    m_IceAttackerTime = 0,
    m_RecyclerMazeCheckpointCount = 0,
    m_CameraTime = 0,
    m_WaterCheckCounter = 0,
    m_TurretDistpacherTimer = 0,
    m_LandTimer = 0,
    m_DropshipDoorSoundTimer = 0,
    m_DropshipShotCounter = 0,
    m_DropshipSoundTimer = 0,
    m_TransportEscapeTimer = 0,
    m_AIPSwitchTimer = 0,

    -- This will house an array for each ice cap that breaks. First value will be the handle, second is the time it started the animation.
    -- [1] = Rhino Handle
    -- [2] = Ice Handle
    -- [3] = Time before ice cap is removed
    -- [4] = Time before Rhino plays fall animation.
    -- Ex: {Mission.m_Rhino1, Mission.m_IceCap1S, Mission.m_MissionTime + SecondsToTurns(6), Mission.m_MissionTime + SecondsToTurns(0.4)}
    m_IceCrackTracker = {},

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

    -- Grab the ODF of the object that has been added.
    local odf = GetCfg(h);

    -- Handle unit skill for enemy.
    if (team == Mission.m_EnemyTeam) then
        SetSkill(h, Mission.m_MissionDifficulty);

        -- This will add turrets for the dispatcher to send to guard points.
        if (odf == "fvturr_x") then
            -- Try and prevent the AIP from using it.
            SetIndependence(h, 1);

            if (Mission.m_StopGuard1 == nil) then
                Mission.m_StopGuard1 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_StopGuard1Sent = false;
            elseif (Mission.m_StopGuard2 == nil) then
                Mission.m_StopGuard2 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_StopGuard2Sent = false;
            elseif (Mission.m_BlockTurret1 == nil) then
                Mission.m_BlockTurret1 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_BlockGuard1Sent = false;
            elseif (Mission.m_BlockTurret2 == nil) then
                Mission.m_BlockTurret2 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_BlockGuard2Sent = false;
            elseif (Mission.m_BlockTurret3 == nil) then
                Mission.m_BlockTurret3 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_BlockGuard3Sent = false;
            elseif (Mission.m_BlockTurret4 == nil) then
                Mission.m_BlockTurret4 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_BlockGuard4Sent = false;
            end
        end

        --  This is only relevant for the second part of the mission.
        if (Mission.m_PartTwo) then
            if (odf == "fvsent_x") then
                -- Try and prevent the AIP from using it.
                SetIndependence(h, 1);

                -- Check to see if our two Scions are alive.
                if (Mission.m_ScionPatrol1 == nil) then
                    -- For patrols.
                    Mission.m_ScionPatrol1 = h;

                    -- This will tell the Scion brain to make this unit patrol.
                    Mission.m_ScionPatrolSent = false;
                elseif (Mission.m_ScionPatrol2 == nil) then
                    -- For patrols.
                    Mission.m_ScionPatrol2 = h;
                end
            end
        end
    elseif (team < Mission.m_AlliedTeam and team > 0) then
        SetSkill(h, 3);

        -- Check to see if it's a factory that has been built.
        if (odf == "ibfact_x") then
            -- Set timer and stuff.
            Mission.m_PlayerHasFactory = true;

            -- Easy, wait 2 minutes. Medium, wait 1 minutes. Hard, switch instantly.
            Mission.m_AIPSwitchTimer = Mission.m_MissionTime +
                SecondsToTurns(m_AIPSwitchTime[Mission.m_MissionDifficulty]);
        elseif (odf == "satchel1") then
            -- Perform a check to see if it has been placed near one of the dropships.
            if (Mission.m_CrashOneAround and GetDistance(h, Mission.m_CrashShip1) < 60) then
                -- Let the satchel do the job.
                SetMaxHealth(Mission.m_CrashShip1, 1500);
                SetCurHealth(Mission.m_CrashShip1, 1500);
                SetMaxHealth(Mission.m_DeadTank, 1500);
                SetCurHealth(Mission.m_DeadTank, 1500);
            elseif (Mission.m_CrashTwoAround and GetDistance(h, Mission.m_CrashShip2) < 60) then
                -- Let the satchel do the job.
                SetMaxHealth(Mission.m_CrashShip2, 1500);
                SetCurHealth(Mission.m_CrashShip2, 1500);
            end
        end
    end
end

function DeleteObject(h)
    -- Remove the wingman brain if he dies.
    if (h == Mission.m_Wingman) then
        Mission.m_WingmanBrainActive = false;
    elseif (h == Mission.m_StopGuard1) then
        Mission.m_StopGuard1 = nil;
    elseif (h == Mission.m_StopGuard2) then
        Mission.m_StopGuard2 = nil;
    elseif (h == Mission.m_BlockTurret1) then
        Mission.m_BlockTurret1 = nil;
    elseif (h == Mission.m_BlockTurret2) then
        Mission.m_BlockTurret2 = nil;
    elseif (h == Mission.m_BlockTurret3) then
        Mission.m_BlockTurret3 = nil;
    elseif (h == Mission.m_BlockTurret4) then
        Mission.m_BlockTurret4 = nil;
    elseif (h == Mission.m_ScionPatrol1) then
        Mission.m_ScionPatrol1 = nil;
    elseif (h == Mission.m_ScionPatrol2) then
        Mission.m_ScionPatrol2 = nil;
    elseif (h == Mission.m_CrashShip1) then
        -- Damage these too.
        Damage(Mission.m_DeadTank, 5000);
        Mission.m_CrashOneAround = false;
    elseif (h == Mission.m_CrashShip2) then
        Mission.m_CrashTwoAround = false;
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
        _Cooperative.Update(m_GameTPS);
    end

    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Start mission logic.
    if (Mission.m_MissionOver == false) then
        if (Mission.m_StartDone) then
            -- Check failure conditions over everything else.
            if (Mission.m_MissionState > 1) then
                HandleFailureConditions();
            end

            -- BZCC introduced a hypothermia mechanic here. Replicate it.
            Mission.m_WaterCheckCounter = Mission.m_WaterCheckCounter + 1;

            -- For each player in the mission, check their location and if they are under water.
            for i = 1, _Cooperative.GetTotalPlayers() do
                -- Grab the player handle.
                local p = GetPlayerHandle(i);

                -- Check the timer.
                if (Mission.m_WaterCheckCounter % SecondsToTurns(0.5) == 0 and IsPerson(p)) then
                    -- Grab the position of the player.
                    local pos = GetPosition(p);

                    -- Check if the terrain is water.
                    if (TerrainIsWater(pos)) then
                        -- Testing, not sure if Lua will like this.
                        local waterHeight = 0;

                        -- Check to see if this assigns the right variables.
                        waterHeight = GetTerrainHeightAndNormal(pos, true);

                        -- Grab the height of the terrain.
                        local terrainHeight = TerrainFindFloor(pos.x, pos.z);

                        -- Check if the player is under water.
                        if (waterHeight > terrainHeight and pos.y < (waterHeight - 15)) then
                            -- Kill the player.
                            SelfDamage(p, 20);
                        end
                    end
                end
            end

            -- Run a check to see if any player is near Shab's downed dropship.
            if (Mission.m_ShabFound == false and Mission.m_MissionState > 12) then
                -- Do a distance check.
                if (IsPlayerWithinDistance(Mission.m_CrashShip2, 90, _Cooperative.GetTotalPlayers())) then
                    -- Have the Sentries attack.
                    if (IsAliveAndEnemy(Mission.m_CheatTank1, Mission.m_EnemyTeam)) then
                        Attack(Mission.m_CheatTank1, GetPlayerHandle(1));
                    end

                    if (IsAliveAndEnemy(Mission.m_CheatTank2, Mission.m_EnemyTeam)) then
                        Attack(Mission.m_CheatTank1, Mission.m_Transport);
                    end

                    if (IsAliveAndEnemy(Mission.m_CheatTank3, Mission.m_EnemyTeam)) then
                        Attack(Mission.m_CheatTank1, Mission.m_Recycler);
                    end

                    -- "She's not in there? It doesn't look good..."
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1016.wav");

                    -- Set the timer for this dialog.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

                    -- So we don't loop.
                    Mission.m_ShabFound = true;
                end
            end

            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Brains for each faction or character.
            ScionBrain();
            RhinoBrain();
            IceBrain();
            DropshipBrain();
            TransportBrain();

            if (Mission.m_RecyclerBrainActive) then
                RecyclerBrain();
            end

            if (Mission.m_IsCooperativeMode == false) then
                CameraBrain();
            end

            if (Mission.m_WingmanBrainActive) then
                WingmanBrain();
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
    -- This is unique. Checks to see if a player has killed an Ice Rhino, and then plays a dialog.
    if (Mission.m_WingmanIceRhinoMsgPlayed == false) then
        -- Check to see if a player killed the Rhino.
        if (IsPlayer(KillersHandle) and (DeadObjectHandle == Mission.m_Rhino1 or DeadObjectHandle == Mission.m_Rhino2 or DeadObjectHandle == Mission.m_Rhino3 or DeadObjectHandle == Mission.m_Rhino4)) then
            if (Mission.m_WingmanBrainActive) then
                -- Play that here.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1034.wav");

                -- Set the timer for this dialog.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);
            end

            -- So we don't loop.
            Mission.m_WingmanIceRhinoMsgPlayed = true;
        end
    end

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
    if (Mission.m_WingmanAttackCondor == false and IsPlayer(ShooterHandle) and VictimHandle == Mission.m_CrashShip1) then
        -- Have the Wingman attack it.
        Attack(Mission.m_Wingman, Mission.m_WingmanTarget, 0);

        -- So we don't loop.
        Mission.m_WingmanAttackCondor = true;
    end

    -- Run a check to see if the Rhinos get shot.
    if (VictimHandle == Mission.m_Rhino1 or VictimHandle == Mission.m_Rhino2 or VictimHandle == Mission.m_Rhino3 or VictimHandle == Mission.m_Rhino4) then
        -- Have it attack the aggressor.
        Attack(VictimHandle, ShooterHandle);

        -- Determine which Rhino is now charging.
        if (Mission.m_Rhino1Charge == false and VictimHandle == Mission.m_Rhino1) then
            -- Have the Rhino play a sound of anger!
            StartSoundEffect("rhin08.wav", VictimHandle);

            Mission.m_Rhino1Charge = true;
        elseif (Mission.m_Rhino2Charge == false and VictimHandle == Mission.m_Rhino2) then
            -- Have the Rhino play a sound of anger!
            StartSoundEffect("rhin08.wav", VictimHandle);

            Mission.m_Rhino2Charge = true;
        elseif (Mission.m_Rhino3Charge == false and VictimHandle == Mission.m_Rhino3) then
            -- Have the Rhino play a sound of anger!
            StartSoundEffect("rhin08.wav", VictimHandle);

            Mission.m_Rhino3Charge = true;
        elseif (Mission.m_Rhino4Charge == false and VictimHandle == Mission.m_Rhino4) then
            -- Have the Rhino play a sound of anger!
            StartSoundEffect("rhin08.wav", VictimHandle);

            Mission.m_Rhino4Charge = true;
        end
    end

    -- Run a check to see if the dropships have been shot by Scion forces.
    if (VictimHandle == Mission.m_DropshipA or VictimHandle == Mission.m_DropshipB and OrdnanceTeam > Mission.m_AlliedTeam) then
        -- Set the counter based on how many times this is shot.
        Mission.m_DropshipShotCounter = Mission.m_DropshipShotCounter + 1;
    end

    -- This will make the turrets stop if they are shot.
    if (Mission.m_MissionDifficulty > 1) then
        if (GetCfg(VictimHandle) == "fvturr_x" and OrdnanceTeam ~= Mission.m_EnemyTeam) then
            if (GetCurrentCommand(VictimHandle) ~= AiCommand.CMD_DEFEND) then
                Defend(VictimHandle);
            end
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

    -- Grab our pre-placed handles.
    Mission.m_Recycler = GetHandle("recycler");
    Mission.m_SRecycler = GetHandle("srecycler");
    Mission.m_Wingman = GetHandle("wingman");
    Mission.m_CrashShip1 = GetHandle("crash_ship1");
    Mission.m_CrashShip2 = GetHandle("crash_ship2");
    Mission.m_Nav1 = GetHandle("nav1");
    Mission.m_Transport = GetHandle("transport");
    Mission.m_CrashScout = GetHandle("crash_scout");
    Mission.m_CrashTank = GetHandle("crash_tank");
    Mission.m_StandIn = GetHandle("standin");
    Mission.m_BlockTurret1 = GetHandle("block_turret1");
    Mission.m_BlockTurret2 = GetHandle("block_turret2");
    Mission.m_BlockTurret3 = GetHandle("block_turret3");
    Mission.m_BlockTurret4 = GetHandle("block_turret4");
    Mission.m_StopGuard1 = GetHandle("stop_guard1");
    Mission.m_StopGuard2 = GetHandle("stop_guard2");
    Mission.m_Turret = GetHandle("turret");
    Mission.m_OpenDropship = GetHandle("open_drop");
    Mission.m_Scion1 = GetHandle("scion1");
    Mission.m_Scion2 = GetHandle("scion2");
    Mission.m_Scion3 = GetHandle("scion3");
    Mission.m_Scion4 = GetHandle("scion4");
    Mission.m_ScionScav = GetHandle("sscav2");
    Mission.m_IceCap1S = GetHandle("scap1");
    Mission.m_IceCap2S = GetHandle("scap2");
    Mission.m_IceCap1 = GetHandle("mcap1");
    Mission.m_IceCap2 = GetHandle("mcap2");
    Mission.m_IceCap3 = GetHandle("mcap3");
    Mission.m_IceCap4 = GetHandle("mcap4");
    Mission.m_IceCap5 = GetHandle("mcap5");
    Mission.m_IceCap6 = GetHandle("mcap6");
    Mission.m_WingmanTarget = GetHandle("wingman_target");
    Mission.m_DeadTank = GetHandle("dead_tank2");

    -- Have the block turrets defend their paths.
    Defend(Mission.m_BlockTurret1, 1);
    Defend(Mission.m_BlockTurret2, 1);
    Defend(Mission.m_BlockTurret3, 1);
    Defend(Mission.m_BlockTurret4, 1);

    -- Have the friendly scout look at the temporary player tank.
    LookAt(Mission.m_Wingman, GetPlayerHandle(1), 1);

    -- Create our nav names.
    SetObjectiveName(Mission.m_Nav1, "Drop Zone");

    -- Name the transport.
    SetObjectiveName(Mission.m_Transport, "Personnel Transport");

    -- Remove control of the current units in our dropship.
    Stop(Mission.m_CrashScout, 1);
    Stop(Mission.m_CrashTank, 1);

    -- Don't allow control over the Recycler, transport, or turret.
    Stop(Mission.m_Recycler, 1);
    Follow(Mission.m_Transport, Mission.m_Recycler, 1);
    Follow(Mission.m_Turret, Mission.m_Recycler, 1);

    -- Clean up any player spawns that haven't been taken by the player.
    _Cooperative.CleanSpawns();

    -- If we are in coop, jump right to the destroyed dropship.
    if (Mission.m_IsCooperativeMode) then
        -- Skip the intro cinematic, go right to the crash.
        Mission.m_MissionState = 8;
    else
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[2] = function()
    if (Mission.m_SetupDropship == false) then
        -- Create our holders to keep people in place.
        Mission.m_Holders[#Mission.m_Holders + 1] = BuildObject("stayput", 0, Mission.m_CrashScout);
        Mission.m_Holders[#Mission.m_Holders + 1] = BuildObject("stayput", 0, Mission.m_CrashTank);

        -- For all of our coop players...
        for i = 1, _Cooperative.GetTotalPlayers() do
            Mission.m_Holders[#Mission.m_Holders + 1] = BuildObject("stayput", 0, GetPlayerHandle(i));
        end

        -- Start our Earthquake.
        StartEarthQuake(1); -- Reset to 5 when advised by devs. 5 is way too loud and not at all friendly to the ears.

        -- Do the fade in if we are not in coop mode.
        if (not Mission.m_IsCooperativeMode) then
            SetColorFade(1, 0.5, Make_RGB(0, 0, 0, 255));
        end

        -- Allow a couple of seconds before advancing the mission.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- So we don't loop.
        Mission.m_SetupDropship = true;
    end

    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- "Condor 4, take the pipe..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1030.wav");

        -- Set the timer for this dialog.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- "Why thank you C3..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1031.wav");

        -- Set the timer for this dialog.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

        -- Delay the mission...
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(10);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[4] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- "Boom!"
        StartSoundEffect("xemt2.wav");

        -- EQ needs to get more intense.
        UpdateEarthQuake(40);

        -- Delay the mission...
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Start the dropship falling sound.
        StartSoundEffect("dropfall.wav");

        -- Delay the mission...
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[6] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- "Something's wrong..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1032.wav");

        -- Set the timer for this dialog.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Delay the mission...
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(10);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Start the dropship falling sound.
        StartSoundEffect("dropcrsh.wav");

        -- Do the fade in if we are not in coop mode.
        if (not Mission.m_IsCooperativeMode) then
            SetColorFade(4, 0.2, Make_RGB(0, 0, 0, 255));
        end

        -- Delay the mission...
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(0.2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- Another boom sound.
        StartSoundEffect("xms2.wav");

        -- Replace the stand-in tank with the player.
        local pos = GetPosition(Mission.m_StandIn);

        -- Remove the stand-in tank.
        RemoveObject(Mission.m_StandIn);

        -- Place the player in that position.
        SetPosition(GetPlayerHandle(1), pos);

        -- Remove all tanks, holders, etc..
        RemoveObject(Mission.m_CrashTank);
        RemoveObject(Mission.m_CrashScout);
        RemoveObject(Mission.m_OpenDropship);

        for i = 1, #Mission.m_Holders do
            RemoveObject(Mission.m_Holders[i]);
        end

        -- Stop the Earthquake.
        StopEarthQuake();

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    -- Build some Rhinos on the map.
    Mission.m_Rhino1 = BuildObject("bcrhino", 12, "rhino1_point");
    Mission.m_Rhino2 = BuildObject("bcrhino", 12, "rhino2_point");
    Mission.m_Rhino3 = BuildObject("bcrhino", 12, "rhino3_point");
    Mission.m_Rhino4 = BuildObject("bcrhino", 12, "rhino4_point");

    -- Set new plan here...
    SetAIP("isdf1101_x.aip", Mission.m_EnemyTeam);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[10] = function()
    if (IsPlayerWithinDistance(Mission.m_Wingman, 65, _Cooperative.GetTotalPlayers())) then
        -- Highlight our new nav.
        SetObjectiveOn(Mission.m_Nav1);

        -- "Sir, are you in there?"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1001.wav");

        -- Set the timer for this dialog.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(12.5);

        -- Give control back to the player.
        LookAt(Mission.m_Wingman, GetPlayerHandle(1), 0);

        -- Activate the wingman brain.
        Mission.m_WingmanBrainActive = true;

        -- This is to set the objectives.
        Mission.m_WingmanTime = Mission.m_MissionTime + SecondsToTurns(18);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    -- Run a check to see if the player is near the Recycler.
    if (Mission.m_FreeRecycler == false and IsPlayerWithinDistance(Mission.m_Recycler, 150, _Cooperative.GetTotalPlayers())) then
        -- Give control of the Recycler, transport, and turret to the player.
        Stop(Mission.m_Recycler, 0);
        Follow(Mission.m_Transport, Mission.m_Recycler, 0);
        Stop(Mission.m_Turret, 0);

        -- Set the brain as active for the ice during the part.
        Mission.m_RecyclerBrainActive = true;

        -- This does a check to see if the player has already cleared the ice before they meet with the Recycler.
        if (Mission.m_RecyclerFirstMessagePlayed == false) then
            if (Mission.m_IceCapsGone) then
                -- "It's good to see you alive, thanks for clearing the ice."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1006.wav");

                -- Set the timer for this dialog.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(11.5);

                -- Move the Recycler along the safe path.
                Goto(Mission.m_Recycler, "safe_path", 1);

                -- This determines if the Recycler is already moving.
                Mission.m_RecyclerUnderway = true;
            else
                -- "It's good to see you alive, I need help clearing this ice."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1007.wav");

                -- Set the timer for this dialog.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(15.5);
            end
        end

        -- Change the name of the Recycler back to normal.
        SetObjectiveName(Mission.m_Recycler, "Recycler");

        -- Show objectives.
        AddObjectiveOverride("nav1.otf", "WHITE", 10, true);
        AddObjective("recycler.otf", "WHITE");

        -- So we don't loop.
        Mission.m_FreeRecycler = true;
    elseif (Mission.m_FreeRecycler) then
        local recySafePath = "";

        -- This is checking to see if the Recycler has made it to the nav point.
        if (GetDistance(Mission.m_Recycler, Mission.m_Nav1) < 70) then
            -- Advance the mission state...
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end

        -- This will cancel any deployment orders on the Recycler before the nav.
        if (GetCurrentCommand(Mission.m_Recycler) == AiCommand.CMD_DEPLOY) then
            Stop(Mission.m_Recycler, 0);
        end

        -- This is checking to see if the player does stuff while the Recycler is "underway".
        if (Mission.m_RecyclerUnderway and Mission.m_RecyclerUnderwayCanceled == false and Mission.m_RecyclerMadeItMsgPlayed == false and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and IsAlive(Mission.m_Recycler)) then
            -- This will play some dialogue based on player options.
            if (Mission.m_RecyclerWhySelectMsgPlayed == false and IsSelected(Mission.m_Recycler)) then
                -- "I'm trying to navigate here sir..."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1008.wav");

                -- Set the timer for this dialog.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

                -- So we don't loop.
                Mission.m_RecyclerWhySelectMsgPlayed = true;
            elseif (Mission.m_RecyclerUnderwayCanceled == false and Mission.m_RecyclerMadeItMsgPlayed == false and Mission.m_RecyclerWhySelectMsgPlayed) then
                if (GetCurrentCommand(Mission.m_Recycler) ~= AiCommand.CMD_GO) then
                    -- "You've got to get me to the drop site!"
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1010.wav");

                    -- Set the timer for this dialog.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                    -- So we don't loop.
                    Mission.m_RecyclerUnderwayCanceled = true;
                end
            end

            -- This checks to see if the Recycler has moved through the maze.
            if (Mission.m_RecyclerMadeItMsgPlayed == false and Mission.m_RecyclerMazeCheckpointCount == 5) then
                -- "I'm through sir, take me to the landing site."
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1009.wav");

                -- Give control back to the player.
                Stop(Mission.m_Recycler, 0);

                -- Set the timer for this dialog.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

                -- So we don't loop.
                Mission.m_RecyclerMadeItMsgPlayed = true;
            end
        end

        -- This is performing various checks to see if the Recycler makes it through the maze.
        if (Mission.m_RecyclerMazeCheckpointCount == 0) then
            if (Mission.m_IceCapsGone) then
                -- Set the right path.
                recySafePath = "safe_path";

                -- So we do the self-move logic.
                Mission.m_RecyclerMoveThroughIce = true;
            end

            if (GetDistance(Mission.m_Recycler, "maze_point1") < 50) then
                -- Increase the checkpoint count.
                Mission.m_RecyclerMazeCheckpointCount = Mission.m_RecyclerMazeCheckpointCount + 1;
                -- Marks the recycler as "Underway".
                Mission.m_RecyclerUnderway = true;
            end
        elseif (Mission.m_RecyclerMazeCheckpointCount == 1) then
            if (Mission.m_IceCap3Gone and Mission.m_IceCap4Gone and Mission.m_IceCap5Gone) then
                -- Set the right path.
                recySafePath = "safe_path1";

                -- So we do the self-move logic.
                Mission.m_RecyclerMoveThroughIce = true;
            end

            if (GetDistance(Mission.m_Recycler, "maze_point2") < 50) then
                -- Increase the checkpoint count.
                Mission.m_RecyclerMazeCheckpointCount = Mission.m_RecyclerMazeCheckpointCount + 1;
            end
        elseif (Mission.m_RecyclerMazeCheckpointCount == 2) then
            if (Mission.m_IceCap3Gone and Mission.m_IceCap5Gone) then
                -- Set the right path.
                recySafePath = "safe_path2";

                -- So we do the self-move logic.
                Mission.m_RecyclerMoveThroughIce = true;
            end

            if (GetDistance(Mission.m_Recycler, "maze_point3") < 50) then
                -- Increase the checkpoint count.
                Mission.m_RecyclerMazeCheckpointCount = Mission.m_RecyclerMazeCheckpointCount + 1;
            end
        elseif (Mission.m_RecyclerMazeCheckpointCount == 3) then
            if (Mission.m_IceCap5Gone) then
                -- Set the right path.
                recySafePath = "safe_path3";

                -- So we do the self-move logic.
                Mission.m_RecyclerMoveThroughIce = true;
            end

            if (GetDistance(Mission.m_Recycler, "maze_point4") < 50) then
                -- Increase the checkpoint count.
                Mission.m_RecyclerMazeCheckpointCount = Mission.m_RecyclerMazeCheckpointCount + 1;
            end
        elseif (Mission.m_RecyclerMazeCheckpointCount == 4) then
            if (Mission.m_IceCap5Gone) then
                -- Set the right path.
                recySafePath = "safe_path4";

                -- So we do the self-move logic.
                Mission.m_RecyclerMoveThroughIce = true;
            end

            if (GetDistance(Mission.m_Recycler, "madeit_point") < 50) then
                -- Increase the checkpoint count.
                Mission.m_RecyclerMazeCheckpointCount = Mission.m_RecyclerMazeCheckpointCount + 1;
            end
        end

        -- This will check if enough ice caps are broken for the Recycler to move on it's own.
        if (Mission.m_CapsGoneMessagePlayed == false and Mission.m_RecyclerMoveThroughIce) then
            -- "I have a pretty good line of sight now."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1011.wav");

            -- Set the timer for this dialog.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

            -- So we do the self-move logic.
            Mission.m_RecyclerUnderway = true;

            -- Move the Recycler to our path.
            Goto(Mission.m_Recycler, recySafePath, 1);

            -- So we don't loop.
            Mission.m_CapsGoneMessagePlayed = true;
        end
    end
end

Functions[12] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- "We have survivors... do you copy down there?"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1012a.wav");

        -- Don't need this anymore.
        Mission.m_RecyclerBrainActive = false;

        -- Build some Sentries.
        Mission.m_CheatTank1 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "cheat_spawn4");
        Mission.m_CheatTank2 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "cheat_spawn5");
        Mission.m_CheatTank3 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "cheat_spawn6");

        -- This is the second part of the mission.
        Mission.m_PartTwo = true;

        -- Remove the highlight from the first nav.
        SetObjectiveOff(Mission.m_Nav1);

        -- Apply scrap the player team.
        SetScrap(Mission.m_HostTeam, 40);

        -- Set the timer for this dialog.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Show Objectives...
        AddObjectiveOverride("nav1.otf", "GREEN", 10, true);
        AddObjective("recycler.otf", "GREEN");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- "Affirmative, we need evac!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1013.wav");

        -- Set the timer for this dialog.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- "Roger that Recycler..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1014.wav");

        -- Set the timer for this dialog.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(12.5);

        -- Prep the camera for non-coop gameplay.
        if (Mission.m_IsCooperativeMode == false) then
            CameraReady();

            -- Vector for the matrix position of the dropship.
            local vectorPos = SetVector(-1265.5, 282.5, 75.5);
            local vectorDir = SetVector(1, 0, 0);

            -- Build the Dropship.
            Mission.m_Dropship = BuildObject("ivdrop_fly_x", 0, BuildDirectionalMatrix(vectorPos, vectorDir));

            -- Set the emitters to burn.
            StartEmitter(Mission.m_Dropship, 1);
            StartEmitter(Mission.m_Dropship, 2);

            -- Change the dropship animation.
            SetAnimation(Mission.m_Dropship, "fly", 0);

            -- Set the Camera time...
            Mission.m_CameraTime = Mission.m_MissionTime + SecondsToTurns(7);
        end

        -- This will govern the dropship message about the dust off site.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(120);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[15] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- "Copy Condor 1...We need to by some time."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1023.wav");

        -- Set the timer for this dialog.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

        -- Show Objectives.
        AddObjectiveOverride("search.otf", "WHITE", 10, true);
        AddObjective("transport.otf", "WHITE");

        -- Highlight the transport.
        SetObjectiveOn(Mission.m_Transport);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[16] = function()
    if ((Mission.m_MissionDelayTime < Mission.m_MissionTime or Mission.m_ShabFound) and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- "I've located a dust-off site."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1026.wav");

        -- Set the timer for this dialog.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(10.5);

        -- Create our new nav.
        Mission.m_Nav2 = BuildObject("ibnav", Mission.m_HostTeam, "nav2_point");

        -- Change the name..
        SetObjectiveName(Mission.m_Nav2, "Dust Off");

        -- Highlight it.
        SetObjectiveOn(Mission.m_Nav2);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[17] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Show objectives based on whether we have found Shabayev or not.
        if (Mission.m_ShabFound) then
            AddObjectiveOverride("search.otf", "GREEN", 10, true);
        else
            AddObjectiveOverride("search.otf", "WHITE", 10, true);
        end

        -- This will start up a check to see if enemy turrets are near the dust off site.
        Mission.m_CheckForTurrets = true;

        -- Set new plan here...
        SetAIP("isdf1102_x.aip", Mission.m_EnemyTeam);

        -- Show the rest of the objectives.
        AddObjective("turret.otf", "WHITE");
        AddObjective("transport.otf", "WHITE");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[18] = function()
    -- This'll check to see if the dropships are ready to take the transport away.
    if (Mission.m_DropshipsLanded) then
        -- Check to see if the dropship has made it to the drop zone.
        if (GetDistance(Mission.m_Transport, "nav2_point") < 125) then
            -- Prepare the Camera if we're not in coop.
            if (Mission.m_IsCooperativeMode == false) then
                CameraReady();
            end

            -- So we don't get shot at.
            SetPerceivedTeam(Mission.m_Transport, Mission.m_EnemyTeam);

            -- Have the transport retreat to the dropship.
            Retreat(Mission.m_Transport, "into_drop_path", 1);

            -- Advance the mission state.
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end
    end
end

Functions[19] = function()
    -- Wait to see if it's in the dropship.
    if (GetDistance(Mission.m_Transport, "drop_point1") < 10) then
        -- Stop the transport.
        Stop(Mission.m_Transport, 1);

        -- Start the dropship engines.
        StartEmitter(Mission.m_DropshipA, 1);
        StartEmitter(Mission.m_DropshipA, 2);

        -- Start the animation.
        SetAnimation(Mission.m_DropshipA, "takeoff", 1);

        -- Play our sound.
        StartSoundEffect("dropleav.wav", Mission.m_DropshipA);

        -- Small delay.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[20] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then
        -- So we don't loop.
        Mission.m_MissionOver = true;

        -- Kill the transport.
        RemoveObject(Mission.m_Transport);

        -- Succeed.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Mission Accomplished.");
            DoGameover(10);
        else
            SucceedMission(GetTime() + 5, "isdf10w1.txt");
        end
    end
end

function HandleFailureConditions()
    if (Mission.m_FreeRecycler and IsAlive(Mission.m_Recycler) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Reset the timer.
        Mission.m_AudioTimer = 0;

        -- If the wingman is alive, play this.
        if (Mission.m_PartTwo == false and Mission.m_WingmanBrainActive) then
            -- "The Recycler's down!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1017.wav");
        else
            -- "The Recycler's been destroyed!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1018.wav");
        end

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Recycler was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf10l1.txt");
        end
    end

    -- This checks to see if the Transport is dead.
    if (IsAlive(Mission.m_Transport) == false) then
        -- Stop all audio.
        StopAudioMessage(Mission.m_Audioclip);

        -- Reset the timer.
        Mission.m_AudioTimer = 0;

        -- "The Transport has been destroyed!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1025.wav");

        -- Show objectives.
        AddObjectiveOverride("transport.otf", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Transport was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf10l2.txt");
        end
    end
end

function TransportBrain()
    if (Mission.m_PartTwo and IsAlive(Mission.m_Transport)) then
        if (Mission.m_TransportMessagePlayed == false and Mission.m_DropshipsFirstLanded and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
            -- "You've got to get my transport to the drop site!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1022.wav");

            -- Set the timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

            -- So we don't loop.
            Mission.m_TransportMessagePlayed = true;
        end
    end
end

function CameraBrain()
    if (Mission.m_MissionState > 18) then
        -- Follow the transport.
        CameraPath("shot1_point", 2000, 0, Mission.m_Transport);
    end

    -- This will do the camera work.
    if (Mission.m_CameraFinished == false and Mission.m_MissionState > 14) then
        -- Run this part of the camera.
        local curPos = GetPosition(Mission.m_Dropship);

        -- Update our current matrix.
        curPos.x = curPos.x + (20 / m_GameTPS);

        -- More.
        Move(Mission.m_Dropship, 0, 30, SetVector(-curPos.x, 282, 75));

        -- Follow it with the Camera.
        CameraObject(Mission.m_Dropship, 40, 60, 30, Mission.m_Dropship);

        if (Mission.m_CameraTime < Mission.m_MissionTime) then
            -- Return the camera to the player.
            CameraFinish();

            -- Kill the dropship.
            RemoveObject(Mission.m_Dropship);

            -- So we don't loop.
            Mission.m_CameraFinished = true;
        end
    end
end

function WingmanBrain()
    -- This shows the objectives after a certain time.
    if (Mission.m_FreeWingman == false and Mission.m_WingmanTime < Mission.m_MissionTime) then
        -- This adds our objectives.
        AddObjectiveOverride("nav1.otf", "WHITE", 10, true);

        -- So we don't loop.
        Mission.m_FreeWingman = true;
    end

    -- This runs if the crashed dropship is around.
    if (IsAround(Mission.m_CrashShip1) and (Mission.m_DestroyHintMessagePlayed == false)) then
        -- Check to see if the scout has been ordered to follow a player.
        if (GetCurrentCommand(Mission.m_Wingman) == AiCommand.CMD_FOLLOW) then
            -- This adds our objectives.
            AddObjectiveOverride("nav1.otf", "WHITE", 10, true);

            -- So we don't loop.
            Mission.m_FreeWingman = true;

            -- Stop any speech.
            StopAudioMessage(Mission.m_Audioclip);

            -- Reset the timer
            Mission.m_AudioTimer = 0;

            -- Wingman: "What about that crashed ship sir?"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1002.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Set the team number of the crashed ship to an enemy.
            SetTeamNum(Mission.m_CrashShip1, Mission.m_EnemyTeam);

            -- So we don't loop this part.
            Mission.m_DestroyHintMessagePlayed = true;
        end
    end

    -- This checks to see if the dropship has been destroyed.
    if (IsAround(Mission.m_CrashShip1) == false and Mission.m_CoverTracksMessagePlayed == false and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Wingman: "That'll cover our tracks..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1004.wav");

        -- Kill the pilot target.
        RemoveObject(Mission.m_WingmanTarget);

        -- Set him back to follow.
        Follow(Mission.m_Wingman, GetPlayerHandle(1), 0);

        -- Timer for this audio.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- So we don't loop this part.
        Mission.m_CoverTracksMessagePlayed = true;
    end

    -- Originally cut content. Re-added.
    if (Mission.m_CoverTracksMessagePlayed == false and Mission.m_CrawlingMessagePlayed == false and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Checks to see if an enemy is within radar range.
        local nearestEnemy = GetNearestEnemy(Mission.m_Wingman, true, true, 450);

        -- Checks to see if a valid enemy is near.
        if (IsAliveAndEnemy(nearestEnemy, Mission.m_EnemyTeam)) then
            -- Wingman: "This place is crawling with Scions..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1003.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- Just so we don't loop.
            Mission.m_CrawlingMessagePlayed = true;
        end
    end

    -- This checks to see if we are near the Recycler.
    if (Mission.m_RecyclerDetectedMessagePlayed == false and GetDistance(Mission.m_Wingman, Mission.m_Recycler) < 450) then
        -- Wingman: "I've got a big green radar hit!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1005.wav");

        -- Timer for this audio.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

        -- Update the Recycler's name.
        SetObjectiveName(Mission.m_Recycler, "Radar Contact");

        -- Highlight the Recycler.
        SetObjectiveOn(Mission.m_Recycler);

        -- So we don't loop.
        Mission.m_RecyclerDetectedMessagePlayed = true;
    end

    -- This is checking to see if the Scion base warning has been played.
    if (Mission.m_ScionBaseMessagePlayed == false) then
        -- Checks to see if the player is near the choke path so we avoid this warning.
        if (IsPlayerWithinDistance("choke_point1", 100, _Cooperative.GetTotalPlayers())) then
            -- So we don't play this message.
            Mission.m_ScionBaseMessagePlayed = true;
        elseif (IsPlayerWithinDistance(Mission.m_ScionScav, 140, _Cooperative.GetTotalPlayers()) or IsPlayerWithinDistance("antenna_point", 140, _Cooperative.GetTotalPlayers())) then
            -- That's the scion base!
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1033.wav");

            -- Timer for this audio.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

            -- So we don't play this message again.
            Mission.m_ScionBaseMessagePlayed = true;
        end
    end
end

function RecyclerBrain()
    -- This checks to see if the Recycler is on the ice.
    if (Mission.m_IceCap1Gone == false) then
        -- Distance check on the Rhino.
        if (GetDistance(Mission.m_Recycler, "mcap1_point") < 55) then
            -- Store the Rhino and Ice in our tracker.
            StoreObjectFallingData(Mission.m_Recycler, Mission.m_IceCap1);

            -- So we don't loop.
            Mission.m_RecyclerBrainActive = false;
        end
    end

    if (Mission.m_IceCap2Gone == false) then
        -- Distance check on the Rhino.
        if (GetDistance(Mission.m_Recycler, "mcap2_pointa") < 55 or GetDistance(Mission.m_Recycler, "mcap2_pointb") < 55) then
            -- Store the Rhino and Ice in our tracker.
            StoreObjectFallingData(Mission.m_Recycler, Mission.m_IceCap2);

            -- So we don't loop.
            Mission.m_RecyclerBrainActive = false;
        end
    end

    if (Mission.m_IceCap3Gone == false) then
        -- Distance check on the Rhino.
        if (GetDistance(Mission.m_Rhino3, "mcap3_point") < 55) then
            -- Store the Rhino and Ice in our tracker.
            StoreObjectFallingData(Mission.m_Recycler, Mission.m_IceCap3);

            -- So we don't loop.
            Mission.m_RecyclerBrainActive = false;
        end
    end

    if (Mission.m_IceCap4Gone == false) then
        -- Distance check on the Rhino.
        if (GetDistance(Mission.m_Recycler, "mcap4_pointa") < 55 or GetDistance(Mission.m_Recycler, "mcap4_pointb") < 55) then
            -- Store the Rhino and Ice in our tracker.
            StoreObjectFallingData(Mission.m_Recycler, Mission.m_IceCap4);

            -- So we don't loop.
            Mission.m_RecyclerBrainActive = false;
        end
    end

    if (Mission.m_IceCap5Gone == false) then
        -- Distance check on the Rhino.
        if (GetDistance(Mission.m_Recycler, "mcap5_pointa") < 55 or GetDistance(Mission.m_Recycler, "mcap5_pointb") < 55) then
            -- Store the Rhino and Ice in our tracker.
            StoreObjectFallingData(Mission.m_Recycler, Mission.m_IceCap5);

            -- So we don't loop.
            Mission.m_RecyclerBrainActive = false;
        end
    end
end

function ScionBrain()
    -- This is a check to see if the player has destroyed the crashed dropship.
    -- If not, send the Scion units to attack.
    if (Mission.m_CoverTracksMessagePlayed == false) then
        if (Mission.m_Patrol1Dead == false) then
            -- Check distance of the first unit and send it to the Recycler if it's near a path.
            if (Mission.m_Discover1 == false and GetDistance(Mission.m_Scion1, "wingman_point") < 60) then
                -- Move the scout to the Recycler.
                Goto(Mission.m_Scion1, Mission.m_Recycler, 1);

                -- So we don't loop.
                Mission.m_Discover1 = true;
            end
        end

        if (Mission.m_Patrol2Dead == false) then
            -- Check distance of the first unit and send it to the Recycler if it's near a path.
            if (Mission.m_Discover2 == false and GetDistance(Mission.m_Scion3, "wingman_point") < 60) then
                -- Move the scout to the Recycler.
                Goto(Mission.m_Scion3, Mission.m_Recycler, 1);

                -- So we don't loop.
                Mission.m_Discover2 = true;
            end
        end
    end

    -- Don't spawn any units if the player has advanced to the second phase of the mission.
    if (Mission.m_PartTwo == false) then
        -- When the Recycler reaches the first checkpoint, we can start sending some ships to attack the player.
        -- Only do this before the Recycler reaches the first nav point.
        if (Mission.m_MissionState == 11 and Mission.m_RecyclerMazeCheckpointCount >= 1) then
            -- Check to see if the ice attackers have spawned...
            if (Mission.m_StartIceAttackers == false and Mission.m_IceAttackerTime < Mission.m_MissionTime) then
                -- Build units to attack.
                Mission.m_IceAttacker1 = BuildObject(m_IceAttacker1[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
                    "cheat_spawn4");
                Mission.m_IceAttacker2 = BuildObject(m_IceAttacker2[Mission.m_MissionDifficulty], Mission.m_EnemyTeam,
                    "cheat_spawn5");

                -- Formation!
                Follow(Mission.m_IceAttacker2, Mission.m_IceAttacker1, 1);
                Attack(Mission.m_IceAttacker1, Mission.m_Recycler, 1);

                -- So we don't loop.
                Mission.m_StartIceAttackers = true;
            elseif (Mission.m_StartIceAttackers) then
                -- This checks to see if they are alive.
                if (IsAliveAndEnemy(Mission.m_IceAttacker1, Mission.m_EnemyTeam) == false and IsAliveAndEnemy(Mission.m_IceAttacker2, Mission.m_EnemyTeam) == false) then
                    -- Set a timer.
                    Mission.m_IceAttackerTime = Mission.m_MissionTime + SecondsToTurns(20);

                    -- So we can respawn.
                    Mission.m_StartIceAttackers = false;
                end
            end
        end

        -- This checks to see if the patrol logic should run.
        if (Mission.m_StartPatrol1) then
            -- This runs when the patrol has been killed.
            if (IsAliveAndEnemy(Mission.m_Scion1, Mission.m_EnemyTeam) == false and IsAliveAndEnemy(Mission.m_Scion2, Mission.m_EnemyTeam) == false and Mission.m_Patrol1Dead == false) then
                -- Increase the patrol time so we wait a minute before it happens again.
                Mission.m_Patrol1Time = Mission.m_MissionTime + SecondsToTurns(60);

                -- Stops the discovery logic for now...
                Mission.m_Discover1 = false;

                -- So we don't loop.
                Mission.m_Patrol1Dead = true;
            elseif (Mission.m_Patrol1Dead and Mission.m_Patrol1Time < Mission.m_MissionTime) then
                -- Build the new scout patrols.
                Mission.m_Scion1 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "sspawn1");
                Mission.m_Scion2 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "sspawn2");

                -- Formation!
                Patrol(Mission.m_Scion1, "patrol_path1a", 1);
                Follow(Mission.m_Scion2, Mission.m_Scion1);

                -- Reset the loop.
                Mission.m_Patrol1Dead = false;
            end
        elseif (Mission.m_MissionState == 9) then
            -- Formation!
            Patrol(Mission.m_Scion1, "patrol_path1a", 1);
            Follow(Mission.m_Scion2, Mission.m_Scion1);

            -- Don't send the second patrol straight away.
            Mission.m_Patrol2Time = Mission.m_MissionTime + SecondsToTurns(60);

            -- So we don't loop.
            Mission.m_StartPatrol1 = true;
        end

        if (Mission.m_StartPatrol2) then
            -- This runs when the patrol has been killed.
            if (IsAliveAndEnemy(Mission.m_Scion3, Mission.m_EnemyTeam) == false and IsAliveAndEnemy(Mission.m_Scion4, Mission.m_EnemyTeam) == false and Mission.m_Patrol2Dead == false) then
                -- Increase the patrol time so we wait a minute before it happens again.
                Mission.m_Patrol2Time = Mission.m_MissionTime + SecondsToTurns(60);

                -- Stops the discovery logic for now...
                Mission.m_Discover2 = false;

                -- So we don't loop.
                Mission.m_Patrol2Dead = true;
            elseif (Mission.m_Patrol2Dead and Mission.m_Patrol2Time < Mission.m_MissionTime) then
                -- Build the new scout patrols.
                Mission.m_Scion3 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "sspawn1");
                Mission.m_Scion4 = BuildObject("fvsent_x", Mission.m_EnemyTeam, "sspawn2");

                -- Formation!
                Patrol(Mission.m_Scion3, "patrol_path1a", 1);
                Follow(Mission.m_Scion4, Mission.m_Scion3);

                -- Reset the loop.
                Mission.m_Patrol2Dead = false;
            end
        elseif (Mission.m_Patrol2Time < Mission.m_MissionTime and Mission.m_MissionState > 8) then
            -- Formation!
            Patrol(Mission.m_Scion3, "patrol_path1a", 1);
            Follow(Mission.m_Scion4, Mission.m_Scion3);

            -- So we don't loop.
            Mission.m_StartPatrol2 = true;
        end
    end

    -- This will handle the turrets and placing them around the passage between the player and the dropsite.
    if (Mission.m_TurretDistpacherTimer < Mission.m_MissionTime) then
        if (Mission.m_PartTwo) then
            -- Check to see if the AIP switch timer has passed.
            if (Mission.m_AIPSwitched == false) then
                if (Mission.m_PlayerHasFactory and Mission.m_AIPSwitchTimer < Mission.m_MissionTime) then
                    -- Set new plan here...
                    SetAIP("isdf1103_x.aip", Mission.m_EnemyTeam);

                    -- So we don't loop.
                    Mission.m_AIPSwitched = true;
                end
            end

            -- Check to see if the patrol units are alive.
            if (Mission.m_ScionPatrolSent == false and IsAliveAndEnemy(Mission.m_ScionPatrol1, Mission.m_EnemyTeam) and IsAliveAndEnemy(Mission.m_ScionPatrol2, Mission.m_EnemyTeam)) then
                -- Send them off to do stuff.
                Patrol(Mission.m_ScionPatrol1, "patrol_path2");
                Follow(Mission.m_ScionPatrol2, Mission.m_ScionPatrol1);

                -- So we don't loop.
                Mission.m_ScionPatrolSent = true;
            end
        end

        if (Mission.m_StopGuard1Sent == false and IsAliveAndEnemy(Mission.m_StopGuard1, Mission.m_EnemyTeam)) then
            -- Move the guard to his post.
            Goto(Mission.m_StopGuard1, "guard_point1", 1);

            -- So we don't loop.
            Mission.m_StopGuard1Sent = true;
        end

        if (Mission.m_StopGuard2Sent == false and IsAliveAndEnemy(Mission.m_StopGuard2, Mission.m_EnemyTeam)) then
            -- Move the guard to his post.
            Goto(Mission.m_StopGuard2, "guard_point2", 1);

            -- So we don't loop.
            Mission.m_StopGuard2Sent = true;
        end

        if (Mission.m_BlockGuard1Sent == false and IsAliveAndEnemy(Mission.m_BlockTurret1, Mission.m_EnemyTeam)) then
            -- Move the guard to his post.
            Goto(Mission.m_BlockTurret1, "block_turret1_post", 1);

            -- So we don't loop.
            Mission.m_BlockGuard1Sent = true;
        end

        if (Mission.m_BlockGuard2Sent == false and IsAliveAndEnemy(Mission.m_BlockTurret2, Mission.m_EnemyTeam)) then
            -- Move the guard to his post.
            Goto(Mission.m_BlockTurret2, "block_turret2_post", 1);

            -- So we don't loop.
            Mission.m_BlockGuard2Sent = true;
        end

        if (Mission.m_BlockGuard3Sent == false and IsAliveAndEnemy(Mission.m_BlockTurret3, Mission.m_EnemyTeam)) then
            -- Move the guard to his post.
            Goto(Mission.m_BlockTurret3, "block_turret3_post", 1);

            -- So we don't loop.
            Mission.m_BlockGuard3Sent = true;
        end

        if (Mission.m_BlockGuard4Sent == false and IsAliveAndEnemy(Mission.m_BlockTurret4, Mission.m_EnemyTeam)) then
            -- Move the guard to his post.
            Goto(Mission.m_BlockTurret4, "block_turret4_post", 1);

            -- So we don't loop.
            Mission.m_BlockGuard4Sent = true;
        end

        -- To delay loops.
        Mission.m_TurretDistpacherTimer = Mission.m_MissionTime + SecondsToTurns(1.5);
    end
end

function RhinoBrain()
    -- This keeps all Rhinos in the right place.
    if (IsAlive(Mission.m_Rhino1)) then
        if (Mission.m_Rhino1Charge == false) then
            -- If the Rhino strays too far from it's path. Make it go back.
            if (Mission.m_Rhino1Behave == false) then
                if (GetDistance(Mission.m_Rhino1, "rhino1_point") > 50) then
                    -- Make it return to it's point.
                    Goto(Mission.m_Rhino1, "rhino1_point", 1);

                    -- So we don't loop.
                    Mission.m_Rhino1Behave = true;
                end
            elseif (GetDistance(Mission.m_Rhino1, "rhino1_point") < 30) then
                -- So we don't loop.
                Mission.m_Rhino1Behave = false;
            end
        elseif (Mission.m_Rhino1Drowned == false) then
            -- This checks to see if the Rhino is charging a target and breaks the ice if they move onto it.
            if (Mission.m_IceCap1SGone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino1, "scap1_point") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino1 = ReplaceObject(Mission.m_Rhino1, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino1, Mission.m_IceCap1S);

                    -- So we don't loop.
                    Mission.m_Rhino1Drowned = true;
                end
            end

            if (Mission.m_IceCap2SGone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino2, "scap2_point") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino1 = ReplaceObject(Mission.m_Rhino1, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino1, Mission.m_IceCap2S);

                    -- So we don't loop.
                    Mission.m_Rhino1Drowned = true;
                end
            end
        end
    end

    if (IsAlive(Mission.m_Rhino2)) then
        if (Mission.m_Rhino2Charge == false) then
            -- This will attack the Recycler when they are at the second checkpoint.
            if (Mission.m_RecyclerMazeCheckpointCount == 2) then
                -- Make this attack.
                Attack(Mission.m_Rhino2, Mission.m_Recycler, 1);

                -- So we don't loop.
                Mission.m_Rhino2Charge = true;
            end

            -- If the Rhino strays too far from it's path. Make it go back.
            if (Mission.m_Rhino2Behave == false) then
                if (GetDistance(Mission.m_Rhino2, "rhino2_point") > 50) then
                    -- Make it return to it's point.
                    Goto(Mission.m_Rhino2, "rhino2_point", 1);

                    -- So we don't loop.
                    Mission.m_Rhino2Behave = true;
                end
            elseif (GetDistance(Mission.m_Rhino2, "rhino2_point") < 30) then
                -- So we don't loop.
                Mission.m_Rhino2Behave = false;
            end
        elseif (Mission.m_Rhino2Drowned == false) then
            -- This checks to see if the Rhino is charging a target and breaks the ice if they move onto it.
            if (Mission.m_IceCap1Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino2, "mcap1_point") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino2 = ReplaceObject(Mission.m_Rhino2, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino2, Mission.m_IceCap1);

                    -- So we don't loop.
                    Mission.m_Rhino2Drowned = true;
                end
            end

            if (Mission.m_IceCap2Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino2, "mcap2_pointa") < 35 or GetDistance(Mission.m_Rhino2, "mcap2_pointb") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino2 = ReplaceObject(Mission.m_Rhino2, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino2, Mission.m_IceCap2);

                    -- So we don't loop.
                    Mission.m_Rhino2Drowned = true;
                end
            end

            if (Mission.m_IceCap3Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino2, "mcap3_point") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino2 = ReplaceObject(Mission.m_Rhino2, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino2, Mission.m_IceCap3);

                    -- So we don't loop.
                    Mission.m_Rhino2Drowned = true;
                end
            end

            if (Mission.m_IceCap4Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino2, "mcap4_pointa") < 35 or GetDistance(Mission.m_Rhino2, "mcap4_pointb") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino2 = ReplaceObject(Mission.m_Rhino2, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino2, Mission.m_IceCap4);

                    -- So we don't loop.
                    Mission.m_Rhino2Drowned = true;
                end
            end

            if (Mission.m_IceCap5Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino2, "mcap5_pointa") < 35 or GetDistance(Mission.m_Rhino2, "mcap5_pointb") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino2 = ReplaceObject(Mission.m_Rhino2, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino2, Mission.m_IceCap5);

                    -- So we don't loop.
                    Mission.m_Rhino2Drowned = true;
                end
            end
        end
    end

    if (IsAlive(Mission.m_Rhino3)) then
        if (Mission.m_Rhino3Charge == false) then
            -- This will attack the Recycler when they are at the third checkpoint.
            if (Mission.m_RecyclerMazeCheckpointCount == 3) then
                -- Make this attack.
                Attack(Mission.m_Rhino3, Mission.m_Recycler, 1);

                -- So we don't loop.
                Mission.m_Rhino3Charge = true;
            end

            -- If the Rhino strays too far from it's path. Make it go back.
            if (Mission.m_Rhino3Behave == false) then
                if (GetDistance(Mission.m_Rhino3, "rhino3_point") > 50) then
                    -- Make it return to it's point.
                    Goto(Mission.m_Rhino3, "rhino3_point", 1);

                    -- So we don't loop.
                    Mission.m_Rhino3Behave = true;
                end
            elseif (GetDistance(Mission.m_Rhino3, "rhino3_point") < 30) then
                -- So we don't loop.
                Mission.m_Rhino3Behave = false;
            end
        elseif (Mission.m_Rhino3Drowned == false) then
            -- This checks to see if the Rhino is charging a target and breaks the ice if they move onto it.
            if (Mission.m_IceCap1Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino3, "mcap1_point") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino3 = ReplaceObject(Mission.m_Rhino3, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino3, Mission.m_IceCap1);

                    -- So we don't loop.
                    Mission.m_Rhino3Drowned = true;
                end
            end

            if (Mission.m_IceCap2Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino3, "mcap2_pointa") < 35 or GetDistance(Mission.m_Rhino3, "mcap2_pointb") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino3 = ReplaceObject(Mission.m_Rhino3, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino3, Mission.m_IceCap2);

                    -- So we don't loop.
                    Mission.m_Rhino3Drowned = true;
                end
            end

            if (Mission.m_IceCap3Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino3, "mcap3_point") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino3 = ReplaceObject(Mission.m_Rhino3, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino3, Mission.m_IceCap3);

                    -- So we don't loop.
                    Mission.m_Rhino3Drowned = true;
                end
            end

            if (Mission.m_IceCap4Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino3, "mcap4_pointa") < 35 or GetDistance(Mission.m_Rhino3, "mcap4_pointb") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino3 = ReplaceObject(Mission.m_Rhino3, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino3, Mission.m_IceCap4);

                    -- So we don't loop.
                    Mission.m_Rhino3Drowned = true;
                end
            end

            if (Mission.m_IceCap5Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino3, "mcap5_pointa") < 35 or GetDistance(Mission.m_Rhino3, "mcap5_pointb") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino3 = ReplaceObject(Mission.m_Rhino3, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino3, Mission.m_IceCap5);

                    -- So we don't loop.
                    Mission.m_Rhino3Drowned = true;
                end
            end
        end
    end

    if (IsAlive(Mission.m_Rhino4)) then
        if (Mission.m_Rhino4Charge == false) then
            -- This will attack the Recycler when they are at the third checkpoint.
            if (Mission.m_RecyclerMazeCheckpointCount == 4) then
                -- Make this attack.
                Attack(Mission.m_Rhino4, Mission.m_Recycler, 1);

                -- So we don't loop.
                Mission.m_Rhino4Charge = true;
            end

            -- If the Rhino strays too far from it's path. Make it go back.
            if (Mission.m_Rhino4Behave == false) then
                if (GetDistance(Mission.m_Rhino4, "rhino4_point") > 50) then
                    -- Make it return to it's point.
                    Goto(Mission.m_Rhino4, "rhino4_point", 1);

                    -- So we don't loop.
                    Mission.m_Rhino4Behave = true;
                end
            elseif (GetDistance(Mission.m_Rhino4, "rhino4_point") < 30) then
                -- So we don't loop.
                Mission.m_Rhino4Behave = false;
            end
        elseif (Mission.m_Rhino4Drowned == false) then
            -- This checks to see if the Rhino is charging a target and breaks the ice if they move onto it.
            if (Mission.m_IceCap1Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino4, "mcap1_point") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino4 = ReplaceObject(Mission.m_Rhino4, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino4, Mission.m_IceCap1);

                    -- So we don't loop.
                    Mission.m_Rhino4Drowned = true;
                end
            end

            if (Mission.m_IceCap2Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino4, "mcap2_pointa") < 35 or GetDistance(Mission.m_Rhino4, "mcap2_pointb") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino4 = ReplaceObject(Mission.m_Rhino4, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino4, Mission.m_IceCap2);

                    -- So we don't loop.
                    Mission.m_Rhino4Drowned = true;
                end
            end

            if (Mission.m_IceCap3Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino4, "mcap3_point") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino4 = ReplaceObject(Mission.m_Rhino4, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino4, Mission.m_IceCap3);

                    -- So we don't loop.
                    Mission.m_Rhino4Drowned = true;
                end
            end

            if (Mission.m_IceCap4Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino4, "mcap4_pointa") < 35 or GetDistance(Mission.m_Rhino4, "mcap4_pointb") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino4 = ReplaceObject(Mission.m_Rhino4, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino4, Mission.m_IceCap4);

                    -- So we don't loop.
                    Mission.m_Rhino4Drowned = true;
                end
            end

            if (Mission.m_IceCap5Gone == false) then
                -- Distance check on the Rhino.
                if (GetDistance(Mission.m_Rhino4, "mcap5_pointa") < 35 or GetDistance(Mission.m_Rhino4, "mcap5_pointb") < 35) then
                    -- Replace the Rhino.
                    Mission.m_Rhino4 = ReplaceObject(Mission.m_Rhino4, "bcrhinof");

                    -- Store the Rhino and Ice in our tracker.
                    StoreObjectFallingData(Mission.m_Rhino4, Mission.m_IceCap5);

                    -- So we don't loop.
                    Mission.m_Rhino4Drowned = true;
                end
            end
        end
    end
end

function IceBrain()
    -- This will check to see if the ice cap array is populated and remove any ice caps that are in.
    if (#Mission.m_IceCrackTracker > 0) then
        for i = 1, #Mission.m_IceCrackTracker do
            local tracker = Mission.m_IceCrackTracker[i];

            if (tracker ~= nil) then
                local handle = tracker[1];
                local iceHandle = tracker[2];
                local iceRemoveTime = tracker[3];
                local rhinoAnimationTime = tracker[4];
                local handleCfg = GetCfg(handle);

                if (handleCfg == "bcrhinof") then
                    if (rhinoAnimationTime < Mission.m_MissionTime) then
                        -- Play the Rhino animation.
                        SetAnimation(handle, "fall", 1);

                        -- Make him cry.
                        StartSoundEffect("rhinocry.wav", handle);

                        -- This will stop it from looping without the crude need for booleans.
                        Mission.m_IceCrackTracker[i][4] = Mission.m_MissionTime + SecondsToTurns(9999999999999);
                    end
                end

                if (iceRemoveTime < Mission.m_MissionTime) then
                    -- Remove the ice cap. Remove the Rhino, and remove this from the table.
                    RemoveObject(iceHandle);

                    if (handleCfg == "bcrhinof") then
                        RemoveObject(handle);
                    end

                    -- Stop this from being processed again.
                    Mission.m_IceCrackTracker[i] = nil;
                end
            end
        end
    end

    -- Check to see if each ice cap still exists.
    if (Mission.m_IceCap1SGone == false and IsAround(Mission.m_IceCap1S) == false) then
        -- So we don't constantly loop on `IsAround` checks.
        Mission.m_IceCap1SGone = true;
    end

    if (Mission.m_IceCap2SGone == false and IsAround(Mission.m_IceCap2S) == false) then
        -- So we don't constantly loop on `IsAround` checks.
        Mission.m_IceCap2SGone = true;
    end

    if (Mission.m_IceCap1Gone == false and IsAround(Mission.m_IceCap1) == false) then
        -- So we don't constantly loop on `IsAround` checks.
        Mission.m_IceCap1Gone = true;
    end

    if (Mission.m_IceCap2Gone == false and IsAround(Mission.m_IceCap2) == false) then
        -- So we don't constantly loop on `IsAround` checks.
        Mission.m_IceCap2Gone = true;
    end

    if (Mission.m_IceCap3Gone == false and IsAround(Mission.m_IceCap3) == false) then
        -- So we don't constantly loop on `IsAround` checks.
        Mission.m_IceCap3Gone = true;
    end

    if (Mission.m_IceCap4Gone == false and IsAround(Mission.m_IceCap4) == false) then
        -- So we don't constantly loop on `IsAround` checks.
        Mission.m_IceCap4Gone = true;
    end

    if (Mission.m_IceCap5Gone == false and IsAround(Mission.m_IceCap5) == false) then
        -- So we don't constantly loop on `IsAround` checks.
        Mission.m_IceCap5Gone = true;
    end

    if (Mission.m_IceCap6Gone == false and IsAround(Mission.m_IceCap6) == false) then
        -- So we don't constantly loop on `IsAround` checks.
        Mission.m_IceCap6Gone = true;
    end

    -- This is checking to see if the Ice Caps are alive.
    if (Mission.m_IceCapsGone == false and Mission.m_IceCap2Gone and Mission.m_IceCap3Gone and Mission.m_IceCap5Gone) then
        -- The caps are dead!
        Mission.m_IceCapsGone = true;
    end
end

function DropshipBrain()
    -- We need to register that the Scion turrets aren't endangering the drop site.
    if (Mission.m_CheckForTurrets) then
        -- Do a check to see if any turrets are within 150 meters of the nav. If it is, the dropships won't land.
        local tooHot = false;

        -- Checks to see if turrets are within the radius of a path.
        if (GetDistance(Mission.m_BlockTurret1, "nav2_point") < 150) then
            tooHot = true;
        elseif (GetDistance(Mission.m_BlockTurret2, "nav2_point") < 150) then
            tooHot = true;
        elseif (GetDistance(Mission.m_BlockTurret3, "nav2_point") < 150) then
            tooHot = true;
        elseif (GetDistance(Mission.m_BlockTurret4, "nav2_point") < 150) then
            tooHot = true;
        end

        -- Check to see if the area is too hot, otherwise we can do a landing sequence.
        if (tooHot == false) then
            if (Mission.m_DropshipsInAir) then
                -- This checks to see if this is the first time that the area is clear.
                if (Mission.m_LandSecureMsgPlayed == false) then
                    -- "Nice job, the site is clear, we'll land in 15."
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1027.wav");

                    -- Audio timer for this clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

                    -- Set a timer for landing.
                    Mission.m_LandTimer = Mission.m_MissionTime + SecondsToTurns(15);

                    -- So we don't loop.
                    Mission.m_LandSecureMsgPlayed = true;
                end

                if (Mission.m_LandTimer < Mission.m_MissionTime) then
                    -- This will spawn the dropships and make them land.
                    if (Mission.m_DropshipsLanding == false) then
                        -- Create the dropships, and have them land.
                        Mission.m_DropshipA = BuildObject("ivdrop_land_x", Mission.m_HostTeam, "drop_point1");
                        Mission.m_DropshipB = BuildObject("ivdrop_land_x", Mission.m_HostTeam, "drop_point2");

                        -- Make sure the engines are going.
                        StartEmitter(Mission.m_DropshipA, 1);
                        StartEmitter(Mission.m_DropshipA, 2);
                        StartEmitter(Mission.m_DropshipB, 1);
                        StartEmitter(Mission.m_DropshipB, 2);

                        -- Make sure they can't be killed.
                        SetMaxHealth(Mission.m_DropshipA, 0);
                        SetMaxHealth(Mission.m_DropshipB, 0);

                        -- This lands the first dropship.
                        SetAnimation(Mission.m_DropshipA, "land", 1);

                        -- This checks to see if they've landed already.
                        if (Mission.m_DropshipsFirstLanded == false) then
                            -- "Your Chariots are here"!
                            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1019.wav");

                            -- Audio timer for this clip.
                            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(5.5);

                            -- So we don't loop.
                            Mission.m_DropshipsFirstLanded = true;
                        else
                            -- "We're going to try another landing...."
                            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1020.wav");

                            -- Audio timer for this clip.
                            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
                        end

                        -- Show Objectives.
                        AddObjectiveOverride("dropship.otf", "WHITE", 10, true);

                        -- Check to see if we've found Shabayev's ship.
                        if (Mission.m_ShabFound) then
                            AddObjective("search.otf", "GREEN");
                        else
                            AddObjective("search.otf", "RED");
                        end

                        AddObjective("transport.otf", "WHITE");

                        -- Set a timer delay before the second dropship lands.
                        Mission.m_LandTimer = Mission.m_MissionTime + SecondsToTurns(3);

                        -- We have landed.
                        Mission.m_DropshipsLanding = true;
                    elseif (Mission.m_DropshipsLanded == false) then
                        -- This makes the second dropship land.
                        if (Mission.m_DropshipBLanded == false) then
                            -- This lands the second dropship.
                            SetAnimation(Mission.m_DropshipB, "land", 1);

                            -- Delay for the animation.
                            Mission.m_LandTimer = Mission.m_MissionTime + SecondsToTurns(15);

                            -- So we don't loop.
                            Mission.m_DropshipBLanded = true;
                        else
                            -- Start by replacing the dropships.
                            Mission.m_DropshipA = ReplaceObject(Mission.m_DropshipA, "ivpdrop_x");
                            Mission.m_DropshipB = ReplaceObject(Mission.m_DropshipB, "ivpdrop_x");

                            -- Open the doors.
                            SetAnimation(Mission.m_DropshipA, "deploy", 1);
                            SetAnimation(Mission.m_DropshipB, "deploy", 1);

                            -- Sound time.
                            Mission.m_DropshipSoundTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

                            -- Remove the engine sounds.
                            MaskEmitter(Mission.m_DropshipA, 0);
                            MaskEmitter(Mission.m_DropshipB, 0);

                            -- Make sure they can't be killed.
                            SetMaxHealth(Mission.m_DropshipA, 0);
                            SetMaxHealth(Mission.m_DropshipB, 0);

                            -- So we don't remove the dropships.
                            Mission.m_DropshipsInAir = false;

                            -- So they can take off again if they are shot.
                            Mission.m_DropshipsTakeOff = false;

                            -- So we don't loop.
                            Mission.m_DropshipsLanded = true;
                        end
                    end
                end
            elseif (Mission.m_DropshipDoorSoundPlayed == false and Mission.m_DropshipSoundTimer < Mission.m_MissionTime) then
                -- Play the sounds.
                StartSoundEffect("dropdoor.wav", Mission.m_DropshipA);
                StartSoundEffect("dropdoor.wav", Mission.m_DropshipB);

                -- Just so we don't play it again.
                Mission.m_DropshipDoorSoundPlayed = true;
            end
        elseif (Mission.m_DropshipsTakeOff == false) then
            -- This'll track the shot count.
            if (Mission.m_DropshipShotCounter > 16) then
                -- "This area is too hot!"
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1021.wav");

                -- Have them take off.
                SetAnimation(Mission.m_DropshipA, "takeoff", 1);
                SetAnimation(Mission.m_DropshipB, "takeoff", 1);

                -- Make sure the engines are going.
                StartEmitter(Mission.m_DropshipA, 1);
                StartEmitter(Mission.m_DropshipA, 2);
                StartEmitter(Mission.m_DropshipB, 1);
                StartEmitter(Mission.m_DropshipB, 2);

                -- Play the sounds.
                StartSoundEffect("dropleav.wav", Mission.m_DropshipA);
                StartSoundEffect("dropleav.wav", Mission.m_DropshipB);

                -- Show objectives.
                AddObjectiveOverride("dropship.otf", "RED", 10, true);

                -- Check to see if we've found Shabayev's ship.
                if (Mission.m_ShabFound) then
                    AddObjective("search.otf", "GREEN");
                else
                    AddObjective("search.otf", "RED");
                end

                AddObjective("transport.otf", "WHITE");

                -- Wait a bit before removing the dropships.
                Mission.m_LandTimer = Mission.m_MissionTime + SecondsToTurns(13);

                Mission.m_DropshipsTakeOff = true;
                Mission.m_DropshipsInAir = true;
            end
        elseif (Mission.m_DropshipsTakeOff and Mission.m_LandTimer < Mission.m_MissionTime) then
            -- Remove the Dropships.
            RemoveObject(Mission.m_DropshipA);
            RemoveObject(Mission.m_DropshipB);

            -- Reset this.
            Mission.m_DropshipShotCounter = 0;

            -- So we don't loop.
            Mission.m_DropshipBLanded = false;
            Mission.m_DropshipsLanded = false;
            Mission.m_DropshipsLanding = false;
            Mission.m_DropshipDoorSoundPlayed = false;

            -- Set a cooldown.
            Mission.m_LandTimer = Mission.m_MissionTime + SecondsToTurns(15);
        end
    end
end

function StoreObjectFallingData(object, ice)
    -- To insert into the ice crack tracker.
    local storage = {};

    -- Bye bye :(
    SetAnimation(ice, "break", 1);

    -- Stop it.
    Stop(object, 1);

    -- Play a sound effect
    StartSoundEffect("icecrck1.wav", ice);

    -- So AI doesn't fire on the new Rhino.
    SetPerceivedTeam(object, 0);

    -- Animation time for the crack.
    storage[1] = object;
    storage[2] = ice;
    storage[3] = Mission.m_MissionTime + SecondsToTurns(6);
    storage[4] = Mission.m_MissionTime + SecondsToTurns(0.4);

    -- Push it to the main tracker.
    Mission.m_IceCrackTracker[#Mission.m_IceCrackTracker + 1] = storage;
end
