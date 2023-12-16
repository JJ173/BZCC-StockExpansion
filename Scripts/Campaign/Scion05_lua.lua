--[[ 
    BZCC Scion05 Lua Mission Script
    Written by AI_Unit
    Version 1.0 08-11-2023
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

-- Groups of New Regime attackers to hit the player.
local delay1 = {105, 90, 75};
local delay2 = {160, 140, 120};

-- Each attack group for the player.
local playerAttacks = 
{
    {{"ivscout_x", "ivscout_x"}, {"ivscout_x", "ivmisl_x"}, {"ivscout_x", "ivtank_x"}}, -- Attack 1
    {{"ivmisl_x", "ivscout_x"}, {"ivmisl_x", "ivmisl_x"}, {"ivtank_x", "ivmisl_x"}}, -- Attack 2
    {{"ivmisl_x", "ivscout_x"}, {"ivmisl_x", "ivmisl_x"}, {"ivtank_x","ivmbike_x", "ivmbike_x"}}, -- Attack 3
    {{"ivscout_x", "ivmisl_x"}, {"ivmisl_x", "ivmbike_x", "ivmbike_x"}, {"ivtank_x", "ivtank_x"}}, -- Attack 4
    {{"ivmisl_x", "ivmisl_x"}, {"ivtank_x", "ivmbike_x", "ivmbike_x"}, {"ivtank_x", "ivmbike_x", "ivmbike_x"}}, -- Attack 5
    {{"ivmbike_x", "ivmbike_x"}, {"ivmisl_x", "ivmbike_x", "ivmbike_x"},{"ivtank_x","ivtank_x","ivmbike_x"}}, -- Attack 6
    {{"ivtank_x", "ivscout_x", "ivscout_x"}, {"ivmbike_x", "ivmbike_x", "ivtank_x"}, {"ivtank_x", "ivtank_x", "ivscout_x"}}, -- Attack 7
    {{"ivtank_x", "ivmbike_x", "ivscout_x"}, {"ivtank_x", "ivmisl_x", "ivmbike_x"}, {"ivrckt_x", "ivtank_x","ivscout_x"}}, -- Attack 8
    {{"ivtank_x", "ivtank_x", "ivscout_x"}, {"ivtank_x", "ivmbike_x", "ivrckt_x"}, {"ivtank_x", "ivrckt_x", "ivatank_x"}}, -- Attack 9
    {{"ivrckt_x", "ivtank_x", "ivscout_x"}, {"ivatank_x", "ivtank_x", "ivmbike_x"}, {"ivatank_x", "ivatank_x", "ivtank_x"}}, -- Attack 10
    {{"ivrckt_x", "ivatank_x", "ivscout_x"}, {"ivatank_x", "ivatank_x", "ivrckt_x"}, {"ivatank_x", "ivwalk_x", "ivatank_x"}}, -- Attack 11
    {{"ivatank_x", "ivrckt_x", "ivrckt_x"}, {"ivatank_x", "ivatank_x", "ivwalk_x"}, {"ivwalk_x", "ivwalk_x", "ivatank_x"}} -- Attack 12
}

-- This is when the player takes too long to destroy the bridge. 
-- Rather than an instant "Game Over", we just increase each attack 
-- from braddock
m_BraddockBridgeAttacks = 
{
    {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivmbike_x", "ivmbike_x"},
    {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivmbike_x", "ivmbike_x", "ivmisl_x", "ivmisl_x"},
    {"ivtank_x", "ivrckt_x", "ivtank_x", "ivrckt_x", "ivmbike_x", "ivmbike_x", "ivmisl_x", "ivmisl_x"},
    {"ivrckt_x", "ivrckt_x", "ivrckt_x", "ivrckt_x", "ivtank_x", "ivtank_x", "ivtank_x"},
    {"ivrckt_x", "ivrckt_x", "ivrckt_x", "ivrckt_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivtank_x", "ivtank_x"},
    {"ivrckt_x", "ivrckt_x", "ivrckt_x", "ivrckt_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivtank_x", "ivtank_x"},
    {"ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivtank_x", "ivtank_x"},
    {"ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivrckt_x", "ivrckt_x", "ivrckt_x"},
    {"ivwalk_x", "ivwalk_x", "ivwalk_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivrckt_x", "ivrckt_x", "ivrckt_x", "ivrckt_x"},
    {"ivwalk_x", "ivwalk_x", "ivwalk_x", "ivwalk_x", "ivwalk_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x", "ivatank_x"},
    {"ivwalk_x", "ivwalk_x", "ivwalk_x", "ivwalk_x", "ivwalk_x", "ivwalk_x", "ivwalk_x", "ivwalk_x", "ivwalk_x", "ivwalk_x"}
}

-- This is when Braddock sends his last attacks to the AAN base. 
-- The final stand for the player.
m_BraddockAANAttacks = 
{
    {{"ivscout_x", "ivscout_x", "ivtank_x"}, {"ivmisl_x", "ivmisl_x", "ivtank_x"}, {"ivtank_x", "ivtank_x", "ivmbike_x", "ivmbike_x"}}, -- Attack 1
    {{"ivmisl_x", "ivscout_x", "ivmisl_x", "ivscout_x"}, {"ivmisl_x", "ivtank_x", "ivmisl_x", "ivtank_x"}, {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x"}}, -- Attack 2
    {{"ivmisl_x", "ivmisl_x", "ivmisl_x", "ivmisl_x"}, {"ivtank_x", "ivtank_x", "ivmbike_x", "ivmbike_x", "ivmbike_x"}, {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x"}}, -- Attack 3
    {{"ivmisl_x", "ivmisl_x", "ivmisl_x", "ivmisl_x", "ivscout_x", "ivscout_x"}, {"ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x"}, {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivapc_x"}}, -- Attack 4
    {{"ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x"}, {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x"}, {"ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x", "ivapc_x", "ivapc_x"}}, -- Attack 5
    {{"ivmisl_x", "ivmisl_x", "ivtank_x", "ivtank_x"}, {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivapc_x"}, {"ivapc_x", "ivapc_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x"}}, -- Attack 6
    {{"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x"}, {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivapc_x", "ivapc_x"}, {"ivapc_x", "ivapc_x", "ivapc_x"}}, -- Attack 7
    {{"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivmbike_x", "ivmbike_x"}, {"ivapc_x", "ivapc_x", "ivapc_x"}, {"ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x", "ivmbike_x", "ivtank_x", "ivtank_x", "ivapc_x"}}, -- Attack 8
    {{"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivmbike_x", "ivmbike_x", "ivapc_x"}, {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivapc_x", "ivapc_x"}, {"ivapc_x", "ivapc_x", "ivapc_x", "ivapc_x"}}, -- Attack 9
    {{"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivapc_x", "ivapc_x"}, {"ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivapc_x", "ivapc_x", "ivapc_x"}, {"ivapc_x", "ivapc_x", "ivapc_x", "ivapc_x", "ivtank_x", "ivtank_x", "ivtank_x", "ivtank_x"}} -- Attack 10
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
    m_PlayerPilotODF = "fspilo_x";
    -- Specific to mission.
    m_PlayerShipODF = "fvtank_x";

    m_PlayerRecy = nil,
    m_AANRecy = nil,
    m_AANCinTank1 = nil,
    m_AANCinTank2 = nil,
    m_AANCinTurr1 = nil,
    m_AANCinTurr2 = nil,
    m_AANCinGTow1 = nil,
    m_AANCinScout1 = nil,
    m_AANFact = nil,
    m_AANSBay = nil,
    m_AANPGen1 = nil,
    m_AANPGen2 = nil,
    m_AANCbun = nil,
    m_AANCons = nil,
    m_AANATank1 = nil,
    m_AANATank2 = nil,
    m_AANTurret1 = nil,
    m_AANTank1 = nil,
    m_AANTank2 = nil,
    m_AANTank3 = nil,
    m_AANBaseNav = nil,
    m_AANBaseSpireNav = nil,
    m_Look = nil,

    m_NRCinRckt1 = nil,
    m_NRMbike1 = nil,
    m_NRMbike2 = nil,
    m_NRTank1 = nil,
    m_NRTank2 = nil,

    m_NRPlayerAttack1 = nil,
    m_NRPlayerAttack2 = nil,
    m_NRPlayerAttack3 = nil,

    m_Manson = nil,
    m_BridgeScout = nil,
    m_BridgeTank = nil,
    m_Rhino1 = nil,
    m_Rhino2 = nil,
    m_Rhino3 = nil,

    m_Bridge1 = nil,
    m_Bridge2 = nil,
    m_Bridge3 = nil,
    m_BridgeStr1 = nil,
    m_BridgeStr2 = nil,

    -- To keep track of the final attackers. Once these are dead, mission succeeds.
    m_BraddockFinalAttackUnits = {},

    m_IsCooperativeMode = false,
    m_StartDone = false,    
    m_MissionOver = false,
    m_CutsceneDialogPlayed = false,
    m_CutsceneRocketAttacking = false,
    m_CutsceneRocketAttackingBunker = false,
    m_BraddockAttackAAN = false,
    m_BraddockAttackPlayer = false,
    m_BraddockFirstWaveSpawned = false,
    m_BraddockPlayerAttacksAlive = false,
    m_BridgeObjectiveAcitve = false,
    m_BridgeAlive = true,
    m_MansonPowerAudioPlayed = false,
    m_MansonGunTowerAudioPlayed = false,
    m_MansonFactoryAudioPlayed = false,
    m_AANGunSpireBuilt = false,
    m_PlayerAtAANBase = false,
    
    m_Audioclip = nil,

    m_RocketAttackTime = 0,
    m_FirstCutsceneDialogTime = 0,
    m_FirstCutsceneTime = 0,
    m_FirstYelenaDialogTime = 0,
    m_BraddockAttackPlayerDelay = 0,
    m_MansonCryForHelpDelay = 0,
    m_AANDispatchCooldown = 0,
    m_BraddockDispatchCooldown = 0,
    m_BraddockDispatchSmallDelay = 0,
    m_MissionPart2Cooldown = 0,
    m_BraddockPlayerAttackCount = 1,
    m_BraddockAANAttackCount = 1,
    m_Bridge1BoomTime = 0,
    m_Bridge2BoomTime = 0,
    m_Bridge3BoomTime = 0,
    m_BridgeStr1BoomTime = 0,
    m_BridgeStr2BoomTime = 0,
    m_AudioDelay = 0,

    -- Steps for each section.
    m_MissionState = 1;
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
    PreloadODF("ibrecy_x");
    PreloadODF("fvrecy_x");
    PreloadODF("ivcons_x");
    PreloadODF("fvcons_x");
    PreloadODF("ivmisl_x");
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
    -- Handle unit skill for enemy.
    if (GetTeamNum(h) == Mission.m_EnemyTeam) then 
        SetSkill(h, Mission.m_MissionDifficulty);
    elseif (GetTeamNum(h) == Mission.m_AlliedTeam) then
        SetSkill(h, 3); -- Manson and his army are well trained!

        -- Get the classes so we can assign them.
        local class = GetClassLabel(h);

        -- So we can micro manage the AAN units.
        if (class == "CLASS_ASSAULTTANK") then
            if (not IsAlive(Mission.m_AANATank1)) then
                Mission.m_AANATank1 = h;
            elseif (not IsAlive(Mission.m_AANATank2)) then
                Mission.m_AANATank2 = h;
            end
        elseif (class == "CLASS_WINGMAN") then
            if (not IsAlive(Mission.m_AANTank1)) then
                Mission.m_AANTank1 = h;
            elseif (not IsAlive(Mission.m_AANTank2)) then
                Mission.m_AANTank2 = h;
            elseif (not IsAlive(Mission.m_AANTank3)) then
                Mission.m_AANTank3 = h;
            end
        end
    elseif (GetTeamNum(h) == Mission.m_HostTeam) then
        -- Need to check to see if a Gun Spire is built.
        if (Mission.m_MissionState == 18) then
            -- Get the classes so we can assign them.
            local class = GetClassLabel(h);

            -- If it's a Gun Tower.
            if (class == "CLASS_TURRET" and GetDistance(h, "spire1site") < 200) then
                -- Set this as built.
                Mission.m_AANGunSpireBuilt = true;
            end
        end
    end
end

function DeleteObject(h)
    if (GetTeamNum(h) == Mission.m_AlliedTeam) then
        -- Get the classes so we can assign them.
        local class = GetClassLabel(h);

        -- Don't do this for the whole mission.
        if (Mission.m_MissionState > 6 and Mission.m_BridgeAlive) then
            if (class == "CLASS_TURRET") then
                if (not Mission.m_MansonGunTowerAudioPlayed) then
                    -- Manson: "We've just lost a Gun Tower!"
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0504.wav");

                    -- So we don't loop.
                    Mission.m_MansonGunTowerAudioPlayed = true;
                end
            elseif (class == "CLASS_PLANT") then
                if (not Mission.m_MansonPowerAudioPlayed) then
                    -- Manson: "We've lost power!"
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0512.wav");

                    -- So we don't loop.
                    Mission.m_MansonPowerAudioPlayed = true;
                end
            elseif (class == "CLASS_FACTORY") then
                if (not Mission.m_MansonFactoryAudioPlayed) then
                    -- Manson: Our factory's been destroyed!
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0511.wav");

                    -- So we don't loop.
                    Mission.m_MansonFactoryAudioPlayed = true;
                end
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
    print("Welcome to Scion05 (Lua)");
    print("Written by AI_Unit");
    
    if (Mission.m_IsCooperativeMode) then
        print("Cooperative mode enabled: Yes");
    else
        print("Cooperative mode enabled: No");
    end

    print("Chosen difficulty: " .. Mission.m_MissionDifficulty);
    print("Good luck and have fun :)");

    -- Team names for stats.
    SetTeamNameForStat(Mission.m_AlliedTeam, "AAN");
    SetTeamNameForStat(Mission.m_EnemyTeam, "New Regime");

    -- Ally teams to be sure.
    Ally(Mission.m_HostTeam, Mission.m_AlliedTeam);

    -- Grab any important pre-placed objects.
    Mission.m_Rhino1 = GetHandle("rhino1");
    Mission.m_Rhino2 = GetHandle("rhino2");
    Mission.m_Rhino3 = GetHandle("rhino3");

    Mission.m_Bridge1 = GetHandle("bseg1");
    Mission.m_Bridge2 = GetHandle("bseg2");
    Mission.m_Bridge3 = GetHandle("bseg3");
    Mission.m_BridgeStr1 = GetHandle("bstr1");
    Mission.m_BridgeStr2 = GetHandle("bstr2");

    Mission.m_BridgeScout = GetHandle("bridgescout");
    Mission.m_BridgeTank = GetHandle("bridgetank");

    Mission.m_PlayerRecy = GetHandle("playersrecy");

    Mission.m_AANRecy = GetHandle("aanrecy");
    Mission.m_AANFact = GetHandle("aan_fact");
    Mission.m_AANPGen1 = GetHandle("aanpgen1");
    Mission.m_AANPGen2 = GetHandle("aanpgen2");
    Mission.m_AANSBay = GetHandle("aansbay");
    Mission.m_AANCbun = GetHandle("aan_cbunk");
    Mission.m_AANCons = GetHandle("aan_cons");
    Mission.m_Manson = GetHandle("manson");

    -- Rename Manson
    SetObjectiveName(Mission.m_Manson, "Maj. Manson");

    Mission.m_AANCinTank1 = GetHandle("aan_cintank1");
    Mission.m_AANCinTank2 = GetHandle("aan_cintank2");
    Mission.m_AANCinScout1 = GetHandle("aan_cinscout1");
    Mission.m_AANCinTurr1 = GetHandle("aan_cinturr1");
    Mission.m_AANCinTurr2 = GetHandle("aan_cinturr2");
    Mission.m_AANCinGTow1 = GetHandle("aan_cingtow1");

    Mission.m_NRCinRckt1 = GetHandle("nr_cinrckt1");
    Mission.m_NRMbike1 = GetHandle("nr_cinmbike1");
    Mission.m_NRMbike2 = GetHandle("nr_cinmbike2");
    Mission.m_NRTank1 = GetHandle("nr_cintank1");
    Mission.m_NRTank2 = GetHandle("nr_cintank2");

    -- Stop any pilots from causing problems.
    SetEjectRatio(Mission.m_NRCinRckt1, 0);
    SetEjectRatio(Mission.m_NRMbike1, 0);
    SetEjectRatio(Mission.m_NRMbike2, 0);
    SetEjectRatio(Mission.m_NRTank1, 0);
    SetEjectRatio(Mission.m_NRTank2, 0);

    Mission.m_Look = GetHandle("look");

    -- Set the Rhinos to do stuff.
    SetMaxHealth(Mission.m_Rhino1, 1000);
    SetCurHealth(Mission.m_Rhino1, 1000);
    SetMaxHealth(Mission.m_Rhino2, 1000);
    SetCurHealth(Mission.m_Rhino2, 1000);
    SetMaxHealth(Mission.m_Rhino3, 1000);
    SetCurHealth(Mission.m_Rhino3, 1000);

    Patrol(Mission.m_Rhino1, "rhino1path");
    Patrol(Mission.m_Rhino2, "rhino2path");
    Patrol(Mission.m_Rhino3, "rhino3path");

    -- Adjust the health for each bridge.
    SetMaxHealth(Mission.m_BridgeStr1, 5000);
    SetCurHealth(Mission.m_BridgeStr1, 5000);
    SetMaxHealth(Mission.m_BridgeStr2, 5000);
    SetCurHealth(Mission.m_BridgeStr2, 5000); 

    -- Set the team colour for Braddock.
    SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);

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

    -- Give the AAN some scrap.
    SetScrap(Mission.m_AlliedTeam, 40);

    -- Mark the set up as done so we can proceed with mission logic.
    Mission.m_StartDone = true;
end

function Update()
    -- Make sure Subtitles is always running.
    _Subtitles.Run();

    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Get the main player
    Mission.m_MainPlayer = GetPlayerHandle(1);

    -- Best that we keep Manson alive for now.
    if (IsOdf(Mission.m_Manson, "ivtank_x") and GetCurHealth(Mission.m_Manson) < 1600) then
        SetCurHealth(Mission.m_Manson, 1600);
    end

    -- Start mission logic.
    if (not Mission.m_MissionOver) then
        if (Mission.m_StartDone) then
            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Run the dispatchers for each team.
            if (Mission.m_MissionState > 2) then
                DispatchAANUnits();
                DispatchBraddockUnits();
                HandleFailureConditions();
            end
        end
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
    -- First intro cinematic about the AAN.
    if (not Mission.m_IsCooperativeMode) then
        -- Prepare the camera.
        CameraReady();

        -- Cutscene will last 35 seconds.
        Mission.m_FirstCutsceneTime = Mission.m_MissionTime + SecondsToTurns(35);

        -- Set the cinematic units to the right team.
        SetTeamNum(Mission.m_NRCinRckt1, Mission.m_EnemyTeam);
        SetTeamNum(Mission.m_NRMbike1, Mission.m_EnemyTeam);
        SetTeamNum(Mission.m_NRMbike2, Mission.m_EnemyTeam);
        SetTeamNum(Mission.m_NRTank1, Mission.m_EnemyTeam);
        SetTeamNum(Mission.m_NRTank2, Mission.m_EnemyTeam);

        -- Do the same with the bridge.
        SetTeamNum(Mission.m_Bridge1, Mission.m_EnemyTeam);
        SetTeamNum(Mission.m_Bridge2, Mission.m_EnemyTeam);
        SetTeamNum(Mission.m_Bridge3, Mission.m_EnemyTeam);
        SetTeamNum(Mission.m_BridgeStr1, Mission.m_EnemyTeam);
        SetTeamNum(Mission.m_BridgeStr2, Mission.m_EnemyTeam);

        -- Some AI stuff...
        SetAvoidType(Mission.m_NRCinRckt1, 0);
        SetAvoidType(Mission.m_NRMbike1, 0);
        SetAvoidType(Mission.m_NRMbike2, 0);
        SetAvoidType(Mission.m_NRTank1, 0);
        SetAvoidType(Mission.m_NRTank2, 0);

        -- Move the cinematic rocket.
        Retreat(Mission.m_NRCinRckt1, "nr_cinrckt1_path");

        -- Attack!
        Attack(Mission.m_NRMbike1, Mission.m_AANCinTurr1, 1);
        Attack(Mission.m_NRMbike2, Mission.m_AANCinTurr2, 1);
        Attack(Mission.m_NRTank1, Mission.m_AANCinTank1, 1);
        Attack(Mission.m_NRTank2, Mission.m_AANCinTank2, 1);
        Attack(Mission.m_Manson, Mission.m_NRCinRckt1);

        -- Small delay before we tell the Rocket Tank to attack the Gun Tower.
        Mission.m_RocketAttackTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- First Dialog Delay
        Mission.m_FirstCutsceneDialogTime = Mission.m_MissionTime + SecondsToTurns(3);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    else
        -- Skip the scene entirely.
        Mission.m_MissionState = 3;
    end
end

Functions[2] = function()
    -- First cutscene dialog from the Padisha.
    if (not Mission.m_CutsceneDialogPlayed and Mission.m_FirstCutsceneDialogTime < Mission.m_MissionTime) then
        -- Burns: Since Braddock made a grab for power...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("cutsc0501.wav");

        -- Don't loop...
        Mission.m_CutsceneDialogPlayed = true;
    end

    -- Get the Rocket Tank to attack.
    if (not Mission.m_CutsceneRocketAttacking and Mission.m_RocketAttackTime < Mission.m_MissionTime) then
        -- Send it to attack the Gun Tower.
        Attack(Mission.m_NRCinRckt1, Mission.m_AANCinGTow1, 1);

        -- Don't loop.
        Mission.m_CutsceneRocketAttacking = true;
    end

    -- If it kills the Gun Tower, have it move on to the bunker.
    if (not IsAlive(Mission.m_AANCinGTow1) and not Mission.m_CutsceneRocketAttackingBunker) then
        -- Send it to attack the Bunker.
        Attack(Mission.m_NRCinRckt1, Mission.m_AANCbun, 1);

        -- Don't loop.
        Mission.m_CutsceneRocketAttackingBunker = true;
    end

    -- Wait here to see if the cutscene finishes naturally, or the player cancels it.
    if (Mission.m_FirstCutsceneTime < Mission.m_MissionTime or CameraCancelled()) then
        -- Give the camera back.
        CameraFinish();

        -- So the attacks on the player don't start straight away.
        Mission.m_BraddockAttackPlayerDelay = Mission.m_MissionTime + SecondsToTurns(delay1[Mission.m_MissionDifficulty]);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end

    -- Send the camera away.
    CameraPath("campath1", 2000, 700, Mission.m_Look);
end

Functions[3] = function()
    -- Remove all cinematic objects.
    RemoveObject(Mission.m_NRMbike1);
    RemoveObject(Mission.m_NRMbike2);
    RemoveObject(Mission.m_NRCinRckt1);
    RemoveObject(Mission.m_NRTank1);
    RemoveObject(Mission.m_NRTank2);

    -- If the audio message from the first cutscene is playing, stop it.
    if (not IsAudioMessageDone(Mission.m_Audioclip)) then
        StopAudioMessage(Mission.m_Audioclip);
    end

    -- Give Manson some stuff.
    SetAIP("scion0501_x.aip", Mission.m_AlliedTeam);

    -- Delay slightly before Yelena talks.
    Mission.m_FirstYelenaDialogTime = Mission.m_MissionTime + SecondsToTurns(3);

    -- Delay Manson
    Mission.m_MansonCryForHelpDelay = Mission.m_MissionTime + SecondsToTurns(60);

    -- Advance the mission state...
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[4] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip) and Mission.m_FirstYelenaDialogTime < Mission.m_MissionTime) then
        -- Yelena: We have no time to waste...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0501.wav");
        
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Show objectives.
        AddObjectiveOverride("scion0501.otf", "WHITE", 10, true);
    
        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;       
    end
end

Functions[6] = function()
    -- Delay Manson's first voice over.
    if (Mission.m_MansonCryForHelpDelay < Mission.m_MissionTime) then
        -- Manson: This is Manson at the AAN base!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0503.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    if (Mission.m_BraddockPlayerAttackCount >= 13) then
        -- Mark the bridge objective as acitve to stop the probing attacks from Braddock.
        Mission.m_BridgeObjectiveAcitve = true;

        -- Delay before the next part.
        Mission.m_MissionPart2Cooldown = Mission.m_MissionTime + SecondsToTurns(70);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[8] = function()
    if (Mission.m_MissionPart2Cooldown < Mission.m_MissionTime) then
        -- Shab: There is a bridge that Braddock is using...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0502.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Show the objectives.
        AddObjectiveOverride("scion0502.otf", "WHITE", 10, true);

        -- Remove the delay.
        Mission.m_BraddockDispatchCooldown = 0;

        -- Set the name of the bridge.
        SetObjectiveName(Mission.m_Bridge2, "ISDF Bridge");

        -- Highlight the bridge.
        SetObjectiveOn(Mission.m_Bridge2);

        -- Highlight the Bridge Guards.
        SetObjectiveOn(Mission.m_BridgeScout);
        SetObjectiveOn(Mission.m_BridgeTank);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[10] = function()
    -- Do different times based on the bridge segment that is destroyed.
    if (not IsAlive(Mission.m_Bridge1)) then
        Mission.m_Bridge2BoomTime = Mission.m_MissionTime + SecondsToTurns(.7);
        Mission.m_BridgeStr2BoomTime = Mission.m_MissionTime + SecondsToTurns(.7);
        Mission.m_Bridge3BoomTime = Mission.m_MissionTime + SecondsToTurns(1.4);
        Mission.m_BridgeStr1BoomTime = Mission.m_MissionTime + SecondsToTurns(2.1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    elseif (not IsAlive(Mission.m_Bridge2)) then
        Mission.m_Bridge1BoomTime = Mission.m_MissionTime + SecondsToTurns(.7);
        Mission.m_BridgeStr2BoomTime = Mission.m_MissionTime + SecondsToTurns(1.4);
        Mission.m_Bridge3BoomTime = Mission.m_MissionTime + SecondsToTurns(.7);
        Mission.m_BridgeStr1BoomTime = Mission.m_MissionTime + SecondsToTurns(1.4);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    elseif (not IsAlive(Mission.m_Bridge3)) then
        Mission.m_Bridge1BoomTime = Mission.m_MissionTime + SecondsToTurns(.7);
        Mission.m_BridgeStr1BoomTime = Mission.m_MissionTime + SecondsToTurns(1.4);
        Mission.m_Bridge2BoomTime = Mission.m_MissionTime + SecondsToTurns(.7);
        Mission.m_BridgeStr2BoomTime = Mission.m_MissionTime + SecondsToTurns(2.1);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    elseif (not IsAlive(Mission.m_BridgeStr1)) then
        Mission.m_Bridge1BoomTime = Mission.m_MissionTime + SecondsToTurns(2.1);
        Mission.m_Bridge2BoomTime = Mission.m_MissionTime + SecondsToTurns(1.4);
        Mission.m_Bridge3BoomTime = Mission.m_MissionTime + SecondsToTurns(.7);
        Mission.m_BridgeStr2BoomTime = Mission.m_MissionTime + SecondsToTurns(2.8);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    elseif (not IsAlive(Mission.m_BridgeStr2)) then
        Mission.m_Bridge1BoomTime = Mission.m_MissionTime + SecondsToTurns(.7);
        Mission.m_Bridge2BoomTime = Mission.m_MissionTime + SecondsToTurns(1.4);
        Mission.m_Bridge3BoomTime = Mission.m_MissionTime + SecondsToTurns(2.1);
        Mission.m_BridgeStr1BoomTime = Mission.m_MissionTime + SecondsToTurns(2.8);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    if (IsAlive(Mission.m_Bridge1) and Mission.m_Bridge1BoomTime < Mission.m_MissionTime) then
        Damage(Mission.m_Bridge1, 6000);
    end

    if (IsAlive(Mission.m_Bridge2) and Mission.m_Bridge2BoomTime < Mission.m_MissionTime) then
        Damage(Mission.m_Bridge2, 6000);
    end

    if (IsAlive(Mission.m_Bridge3) and Mission.m_Bridge3BoomTime < Mission.m_MissionTime) then
        Damage(Mission.m_Bridge3, 6000);
    end

    if (IsAlive(Mission.m_BridgeStr1) and Mission.m_BridgeStr1BoomTime < Mission.m_MissionTime) then
        Damage(Mission.m_BridgeStr1, 6000);
    end

    if (IsAlive(Mission.m_BridgeStr2) and Mission.m_BridgeStr2BoomTime < Mission.m_MissionTime) then
        Damage(Mission.m_BridgeStr2, 6000);
    end

    if (not IsAlive(Mission.m_Bridge1) and not IsAlive(Mission.m_Bridge2) and not IsAlive(Mission.m_Bridge3) and not IsAlive(Mission.m_BridgeStr1) and not IsAlive(Mission.m_BridgeStr2)) then
        -- Stop the Bridge Attacks from Braddock.
        Mission.m_BridgeAlive = false;

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    -- Bridge and the guards are dead.
    if (not IsAlive(Mission.m_BridgeScout) and not IsAlive(Mission.m_BridgeTank)) then
        -- Shab: Good Job Cooke...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0505.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;     
    end 
end

Functions[13] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Show Objectives
        AddObjectiveOverride("scion0503.otf", "WHITE", 10, true);

        -- Build a nav.
        Mission.m_AANBaseNav = BuildObject("ibnav", Mission.m_HostTeam, "aan_base");

        -- Highlight and name it.
        SetObjectiveName(Mission.m_AANBaseNav, "AAN Base");
        SetObjectiveOn(Mission.m_AANBaseNav);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    -- Check to make sure a player is within distance.
    if (IsPlayerWithinDistance(Mission.m_AANBaseNav, 200, _Cooperative.m_TotalPlayerCount)) then
        -- Manson: Cooke? Thank god!
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0506.wav");

        -- For the next set of dispatched units.
        Mission.m_PlayerAtAANBase = true;

        -- Highlight Manson.
        SetObjectiveOn(Mission.m_Manson);

        -- Reset the Braddock AAN counter for the next section.
        Mission.m_BraddockAANAttackCount = 1;

        -- Build some pods.
        SetAIP("scion0502.aip", Mission.m_AlliedTeam);

        -- Remove the highlight from the nav.
        SetObjectiveOff(Mission.m_AANBaseNav);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[15] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Add a small audio delay.
        Mission.m_AudioDelay = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[16] = function()
    if (Mission.m_AudioDelay < Mission.m_MissionTime) then
        -- Shab: John, I need you to bring in a builder...
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0507.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[17] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Build a nav.
        Mission.m_AANBaseSpireNav = BuildObject("ibnav", Mission.m_HostTeam, "spire1site");

        -- Objectives.
        AddObjectiveOverride("scion0504.otf", "WHITE", 10, true);

        -- Set the name of the nav.
        SetObjectiveName(Mission.m_AANBaseSpireNav, "Gun Spire Site");
        SetObjectiveOn(Mission.m_AANBaseSpireNav);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[18] = function()
    -- Wait to see if a Gun Spire has been built near the nav.
    if (Mission.m_AANGunSpireBuilt) then
        -- Good job.. Now try to hold off.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0508.wav");

        -- Set Manson's AIP back to the first one.
        SetAIP("scion0501_x.aip", Mission.m_AlliedTeam);

        -- Remove the highlight.
        SetObjectiveOff(Mission.m_AANBaseSpireNav);

        -- Objectives.
        AddObjectiveOverride("scion0504b.otf", "GREEN", 10, true);
        AddObjective("scion0504a.otf", "WHITE");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[19] = function()
    if (Mission.m_BraddockAANAttackCount >= 11) then
        -- If any of these units are alive, return early.
        for i = 1, #Mission.m_BraddockFinalAttackUnits do
            if (IsAlive(Mission.m_BraddockFinalAttackUnits[i])) then
                return;
            end
        end

        -- If none of the final units are alive...
        Mission.m_AudioDelay = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[20] = function()
    if (Mission.m_AudioDelay < Mission.m_MissionTime) then
        -- Shab: Excellent work John. Braddock is retreating.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0510.wav");

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[21] = function()
    if (IsAudioMessageDone(Mission.m_Audioclip)) then
        -- Mission Accomplished.
        AddObjectiveOverride("scion0506.otf", "WHITE", 10, true);

        -- Advance the mission state...
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[22] = function()
    -- Game over.
    if (Mission.m_IsCooperativeMode) then
        NoteGameoverWithCustomMessage("Mission Accomplished.");
        DoGameover(10);
    else
        SucceedMission(GetTime() + 10, "scion05w1.txt");
    end
end

function DispatchAANUnits()
    if (Mission.m_AANDispatchCooldown < Mission.m_MissionTime) then
        if (IsAlive(Mission.m_Manson) and GetCurrentCommand(Mission.m_Manson) == CMD_NONE) then
            Patrol(Mission.m_Manson, "AAN_Patrol1", 1);
        end

        if (IsAlive(Mission.m_AANTank1) and GetCurrentCommand(Mission.m_Manson) == CMD_NONE) then
            Follow(Mission.m_AANTank1, Mission.m_Manson, 1);
        end

        if (IsAlive(Mission.m_AANTank2) and GetCurrentCommand(Mission.m_AANTank2) == CMD_NONE and GetDistance(Mission.m_AANTank2, "basetank1") > 30) then
            Goto(Mission.m_AANTank2, "basetank1", 1);
        end

        if (IsAlive(Mission.m_AANTank3) and GetCurrentCommand(Mission.m_AANTank3) == CMD_NONE and GetDistance(Mission.m_AANTank3, "basetank3") > 30) then
            Goto(Mission.m_AANTank3, "basetank3", 1);
        end

        if (IsAlive(Mission.m_AANATank1) and GetCurrentCommand(Mission.m_AANATank1) == CMD_NONE and GetDistance(Mission.m_AANATank1, "AANBase_ATank1") > 30) then
            Goto(Mission.m_AANATank1, "AANBase_ATank1", 1);
        end

        if (IsAlive(Mission.m_AANATank2) and GetCurrentCommand(Mission.m_AANATank2) == CMD_NONE and GetDistance(Mission.m_AANATank2, "AANBase_ATank2") > 30) then
            Goto(Mission.m_AANATank2, "AANBase_ATank2", 1);
        end

        -- To delay loops.
        Mission.m_AANDispatchCooldown = Mission.m_AANDispatchCooldown + SecondsToTurns(1.5);
    end
end

function DispatchBraddockUnits()
    -- Only do this while the player is building up his base.
    if (not Mission.m_BridgeObjectiveAcitve) then
        -- This controls off-map units that attack Manson while the player is setting up.
        if (Mission.m_BraddockDispatchCooldown < Mission.m_MissionTime) then
            -- Check that a player isn't nearby so we can spawn units. If they are, the break the loop.
            if (IsPlayerWithinDistance("spawn1", 200, _Cooperative.m_TotalPlayerCount)) then
                return;
            end

            if (not Mission.m_BraddockFirstWaveSpawned) then
                -- Build some units to attack Manson.
                Mission.m_BraddockDispatchSmallDelay = Mission.m_MissionTime + SecondsToTurns(15);

                -- Attackers.
                local tank1 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "spawn1");
                local tank2 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "spawn2");
                local tank3 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "spawn3");
                local tank4 = BuildObject("ivtank_x", Mission.m_EnemyTeam, "spawn4");

                -- Follow in formation.
                Follow(tank2, tank1, 1);
                Follow(tank3, tank2, 1);
                Follow(tank4, tank3, 1);

                -- Move the leader.
                Goto(tank1, "Bridge_Attackers", 1);

                -- Stop a loop while we check for the small delay.
                Mission.m_BraddockFirstWaveSpawned = true;
            end

            -- Spawn a few more units.
            if (Mission.m_BraddockDispatchSmallDelay < Mission.m_MissionTime) then
                -- Attackers.
                local misl1 = BuildObject("ivmisl_x", Mission.m_EnemyTeam, "spawn1");
                local misl2 = BuildObject("ivmisl_x", Mission.m_EnemyTeam, "spawn2");

                -- Follow in formation.
                Follow(misl2, misl1);

                -- Move the leader.
                Goto(misl1, "Bridge_Attackers", 1);

                -- Set a delay so each attack waits.
                Mission.m_BraddockDispatchCooldown = Mission.m_MissionTime + SecondsToTurns(120);

                -- Reset the wave.
                Mission.m_BraddockFirstWaveSpawned = false;
            end
        end

        -- This is the build up of attacks that occur before the bridge objective is activated.
        if (Mission.m_BraddockAttackPlayerDelay < Mission.m_MissionTime) then
            -- Loop through the attack table and spawn them.
            local attackTable = playerAttacks[Mission.m_BraddockPlayerAttackCount];
            local attacks = attackTable[Mission.m_MissionDifficulty];

            for i = 1, #attacks do
                -- Spawn each unit at a safe path.
                local unit =  BuildObjectAtSafePath(attacks[i], Mission.m_EnemyTeam, "pk"..i, "spawn"..i, _Cooperative.m_TotalPlayerCount);

                -- Send the unit to attack the player.
                Goto(unit, "playerbase", 1);
            end
            
            -- So we loop through the table of attacks.
            Mission.m_BraddockPlayerAttackCount = Mission.m_BraddockPlayerAttackCount + 1;

            -- Set the loop timer so we delay.
            Mission.m_BraddockAttackPlayerDelay = Mission.m_MissionTime + SecondsToTurns(delay1[Mission.m_MissionDifficulty]);
        end
    elseif (Mission.m_BridgeAlive) then
        if (Mission.m_BraddockDispatchCooldown < Mission.m_MissionTime) then
            -- Loop through the attack table and spawn them.
            local attackTable = m_BraddockBridgeAttacks[Mission.m_BraddockAANAttackCount];

            for i = 1, #attackTable do
                -- Just so we don't use spawns that don't exist.
                local spawn = GetPositionNear("spawn"..i, 15, 15);

                -- Anything over 4, use spawn one.
                if (i > 4) then
                    spawn = GetPositionNear("spawn1", 15, 15);
                end

                -- Spawn each unit at a safe path.
                local unit =  BuildObject(attackTable[i], Mission.m_EnemyTeam, spawn);

                -- Send the unit to attack the player.
                Goto(unit, "Bridge_Attackers", 1);
            end
            
            -- So we loop through the table of attacks.
            if (Mission.m_BraddockAANAttackCount < 11) then
                Mission.m_BraddockAANAttackCount = Mission.m_BraddockAANAttackCount + 1;
            end

            -- Set the loop timer so we delay.
            Mission.m_BraddockDispatchCooldown = Mission.m_MissionTime + SecondsToTurns(delay2[Mission.m_MissionDifficulty]);
        end
    elseif (Mission.m_PlayerAtAANBase) then
        if (Mission.m_BraddockDispatchCooldown < Mission.m_MissionTime) then
            -- Loop through the attack table and spawn them.
            local attackTable = m_BraddockAANAttacks[Mission.m_BraddockAANAttackCount];
            local attacks = attackTable[Mission.m_MissionDifficulty];

            for i = 1, #attacks do
                -- Just so we don't use spawns that don't exist.
                local spawn = GetPositionNear("spawn"..i, 15, 15);

                -- Anything over 4, use spawn one.
                if (i > 4) then
                    spawn = GetPositionNear("spawn1", 15, 15);
                end

                -- Spawn each unit at a safe path.
                local unit =  BuildObject(attacks[i], Mission.m_EnemyTeam, spawn);
                
                -- Some special logic when the 10th wave is spawned.
                if (Mission.m_BraddockAANAttackCount == 10) then
                    Mission.m_BraddockFinalAttackUnits[#Mission.m_BraddockFinalAttackUnits + 1] = unit;
                end

                -- Send the unit to attack the AAN.
                if (IsOdf(unit, "ivapc_x")) then
                    Attack(unit, Mission.m_AANRecy, 1);
                else
                    Goto(unit, "hoverpath", 1);
                end
            end

            -- So we loop through the table of attacks.
            Mission.m_BraddockAANAttackCount = Mission.m_BraddockAANAttackCount + 1;
            
            -- Set the loop timer so we delay.
            Mission.m_BraddockDispatchCooldown = Mission.m_MissionTime + SecondsToTurns(delay2[Mission.m_MissionDifficulty]);
        end
    end
end

function HandleFailureConditions()
    if (not IsAlive(Mission.m_AANRecy)) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- If anything is playing.
        StopAudioMessage(Mission.m_Audioclip);

        -- Shab: "The AAN Recycler has been destroyed...".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0509.wav");

        -- Show failure objective.
        AddObjectiveOverride("scion05l1.txt", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("AAN Recycler was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "scion05l1.txt");
        end
    end
    
    if (not IsAlive(Mission.m_PlayerRecy)) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- If anything is playing.
        StopAudioMessage(Mission.m_Audioclip);

        -- Shab: "The enemy has taken out our Recycler".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("scion0599.wav");

        -- Show failure objective.
        AddObjectiveOverride("scion05l2.txt", "RED", 10, true);

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Matriarch was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "scion05l2.txt");
        end
    end
end