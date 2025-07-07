--[[
    BZCC ISDF13 Lua Mission Script
    Written by AI_Unit
    Version 2.0 24-01-2024
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
local m_MissionName = "ISDF13: Payback";

local m_ShieldChance = 0.2;
local m_WeaponChance = 0.25;

local m_WeaponTable = {
    -- Table for Cannons (1)
    m_Cannons = { "gquill_c", "gsonic_c", "garc_c" },

    -- Table for Guns (2)
    m_Guns = { "glock_c", "ggauss_c", },

    -- Table for Missiles (3)
    m_Missiles = { "gmlock_c" },

    -- Table for Sheilds (4)
    m_Shields = { "gabsorb", "gdeflect", "gshield" }
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
    m_PlayerPilotODF = "ispilo_x",
    -- Specific to mission.
    m_PlayerShipODF = "ivtank_x",

    m_Recycler = nil,
    m_Manson = nil,
    m_Burns = nil,
    m_Tank2 = nil,
    m_Tank3 = nil,
    m_BurnsCondor = nil,
    m_KeyDevice = nil,
    m_Show1 = nil,
    m_Show2 = nil,
    m_Titan1 = nil,
    m_Titan2 = nil,
    m_Builder1 = nil,
    m_GuardA = nil,
    m_GuardB = nil,
    m_Forge = nil,
    m_Spire1 = nil,
    m_Spire2 = nil,
    m_Spire3 = nil,
    m_Spire4 = nil,
    m_War1 = nil,
    m_Sent1 = nil,
    m_Sent2 = nil,
    m_Walker1 = nil,
    m_Walker2 = nil,
    m_Carrier = nil,
    m_LookProp = nil,
    m_Nav1 = nil,
    m_Guardian1 = nil,
    m_Guardian2 = nil,
    m_Guardian3 = nil,
    m_Guardian4 = nil,

    m_ScionVehicles = {},

    m_IsCooperativeMode = false,
    m_StartDone = false,
    m_MissionOver = false,
    m_ScionBrainActive = false,
    m_PropBrainActive = false,
    m_WarriorActive = false,
    m_WarriorFirstLook = false,
    m_MoveTitan1 = false,
    m_MoveBurns = false,
    m_BurnsAtCondor = false,
    m_BurnsInCondor = false,
    m_RemoveBurns = false,
    m_Guardian1Sent = false,
    m_Guardian2Sent = false,
    m_Guardian3Sent = false,
    m_Guardian4Sent = false,
    m_Hell = false,
    m_MansonWarning = false,
    m_TurretDispatcherActive = false,

    m_Audioclip = nil,
    m_AudioTimer = 0,

    m_MissionDelayTime = 0,
    m_IntroDialogueCount = 0,
    m_MoveBurnsTime = 0,
    m_BurnsTime = 0,
    m_WarriorTime = 0,
    m_ParadeTime = 0,
    m_WarriorState = 0,
    m_CarrierTime = 0,
    m_MovieTime = 0,
    m_ExplosionTime = 0,
    m_QuakeTime = 0,
    m_PanicTime = 0,
    m_TurretDistpacherTimer = 0,
    m_WarningTimer = 0,

    m_ScionPlayerCount = 0,
    m_ScionPath = '',
    m_ScionRandomChance = 0,

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
    -- Grab the ODF name.
    local team = GetTeamNum(h);

    -- Handle unit skill for enemy.
    if (team == Mission.m_EnemyTeam) then
        -- Grab the ODF.
        local odf = GetCfg(h);

        -- Set skill based on difficulty.
        SetSkill(h, Mission.m_MissionDifficulty);

        if (IsBuilding(h) == false and GetClassLabel(h) ~= "CLASS_TURRET") then
            Mission.m_ScionVehicles[#Mission.m_ScionVehicles + 1] = h;
        end

        if (odf == "fvatank_r") then
            GiveWeapon(h, "gsonic_c");
        end

        -- Check to see if the unit needs a weapon upgrade.
        if (Mission.m_StartDone) then
            if (odf == "fvtank_r" or odf == "fvarch_r" or odf == "fvsent_r" or odf == "fvscout_r") then
                -- Run a random chance to see if they are allowed a weapon.
                local chance = GetRandomFloat(0, 1);
                local shieldChance = m_ShieldChance * Mission.m_MissionDifficulty;
                local weaponChance = m_WeaponChance * Mission.m_MissionDifficulty;

                -- Run some checks to see if they pass.
                if (chance > shieldChance) then
                    -- Give it to the unit.
                    GiveWeapon(h, m_WeaponTable.m_Shields[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Shields))]);
                end

                if (chance > weaponChance) then
                    if (odf == "fvtank_r" or odf == "fvscout_r") then
                        GiveWeapon(h, m_WeaponTable.m_Cannons[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Cannons))]);
                    elseif (odf == "fvsent_r") then
                        GiveWeapon(h, m_WeaponTable.m_Guns[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Guns))]);
                    elseif (odf == "fvarch_r") then
                        GiveWeapon(h, m_WeaponTable.m_Missiles[math.ceil(GetRandomFloat(0, #m_WeaponTable.m_Missiles))]);
                    end
                end
            end
        end

        -- Don't check this until the first state is complete. That way, we won't use pre-placed turrets.
        if (odf == "fvturr_r") then
            -- Try and prevent the AIP from using it.
            SetIndependence(h, 1);

            -- Check to see if the turrets are on Team 7 before assigning them to a handle.
            if (Mission.m_Guardian1 == nil) then
                Mission.m_Guardian1 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_Guardian1Sent = false;
            elseif (Mission.m_Guardian2 == nil) then
                Mission.m_Guardian2 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_Guardian2Sent = false;
            elseif (Mission.m_Guardian3 == nil) then
                Mission.m_Guardian3 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_Guardian3Sent = false;
            elseif (Mission.m_Guardian4 == nil) then
                Mission.m_Guardian4 = h;

                -- This will tell the Scion brain to send the turret back to the right path.
                Mission.m_Guardian4Sent = false;
            end
        end
    elseif (team < Mission.m_AlliedTeam and team > 0) then
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

            -- Run each function for the mission.
            Functions[Mission.m_MissionState]();

            -- Run the Scion Brain.
            if (Mission.m_ScionBrainActive) then
                ScionBrain();
            end

            -- Run the brain for the main prop that all Scion units should look at.
            if (Mission.m_PropBrainActive) then
                PropBrain();
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
    if (IsPlayer(ShooterHandle) and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        if (IsAlive(Mission.m_Manson) and VictimHandle == Mission.m_Manson) then
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
    -- Team names for stats.
    SetTeamNameForStat(Mission.m_EnemyTeam, "Scion");
    SetTeamNameForStat(Mission.m_AlliedTeam, "ISDF");

    -- Ally teams to be sure.
    for i = 2, 5 do
        Ally(Mission.m_HostTeam, i);
        Ally(i, Mission.m_EnemyTeam);
    end

    -- Unique for this mission.
    Ally(Mission.m_HostTeam, Mission.m_EnemyTeam);

    -- Allied team is Squad Blue.
    SetTeamColor(Mission.m_AlliedTeam, 0, 127, 255);

    -- Grab our pre-placed handles.
    Mission.m_Burns = GetHandle("burns");
    Mission.m_Recycler = GetHandle("recycler");
    Mission.m_Manson = GetHandle("tank1");
    Mission.m_Tank2 = GetHandle("tank2");
    Mission.m_Tank3 = GetHandle("tank3");
    Mission.m_BurnsCondor = GetHandle("dropship");
    Mission.m_KeyDevice = GetHandle("key_device");
    Mission.m_Titan1 = GetHandle("titan1");
    Mission.m_Titan2 = GetHandle("titan2");
    Mission.m_Show1 = GetHandle("show1");
    Mission.m_Show2 = GetHandle("show2");
    Mission.m_GuardA = GetHandle("guarda");
    Mission.m_GuardB = GetHandle("guardb");
    Mission.m_Forge = GetHandle("forge");
    Mission.m_Spire1 = GetHandle("spire1");
    Mission.m_Spire2 = GetHandle("spire1");
    Mission.m_Spire3 = GetHandle("spire1");
    Mission.m_Spire4 = GetHandle("spire4");
    Mission.m_Sent1 = GetHandle("sent1");
    Mission.m_Sent2 = GetHandle("sent2");
    Mission.m_Builder1 = GetHandle("builder1");

    -- Remove flame emitter from carrier(?)
    MaskEmitter(Mission.m_Show2, 1);

    -- Give the player some scrap.
    SetScrap(Mission.m_HostTeam, 40);

    -- Do the fade in if we are not in coop mode.
    if (not Mission.m_IsCooperativeMode) then
        SetColorFade(1, 0.5, Make_RGB(0, 0, 0, 255));
    end

    -- Make Manson and other tanks uncontrollabe.
    LookAt(Mission.m_Manson, Mission.m_Forge, 1);
    LookAt(Mission.m_Tank2, Mission.m_Forge, 1);
    LookAt(Mission.m_Tank3, Mission.m_Forge, 1);

    -- Set Manson's Name.
    SetObjectiveName(Mission.m_Manson, "Maj. Manson");
    SetObjectiveOn(Mission.m_Manson);

    -- Mask the emitter for the first Condor.
    MaskEmitter(Mission.m_BurnsCondor, 0);

    -- Open the Dropship.
    SetAnimation(Mission.m_BurnsCondor, "deploy", 1);

    -- Move the Scion builder for the sake of the cutscene.
    Goto(Mission.m_Builder1, "builder_point");

    -- Build the first warrior.
    Mission.m_War1 = BuildObject("fvtank_r", Mission.m_EnemyTeam, "b_point1");

    -- Build the walkers.
    Mission.m_Walker1 = BuildObject("ivwalk_x", Mission.m_AlliedTeam, "walker1_spawn");
    Mission.m_Walker2 = BuildObject("ivwalk_x", Mission.m_AlliedTeam, "walker2_spawn");

    -- Have them look at "Spire4".
    LookAt(Mission.m_Walker1, Mission.m_Spire4);
    LookAt(Mission.m_Walker2, Mission.m_Spire4);

    -- So the player can't control the Recycler.
    Stop(Mission.m_Recycler, 1);

    -- Set avoid types.
    SetAvoidType(Mission.m_Burns, 0);
    SetAvoidType(Mission.m_Titan1, 0);
    SetAvoidType(Mission.m_Titan2, 0);
    SetAvoidType(Mission.m_Sent1, 0);
    SetAvoidType(Mission.m_Sent2, 0);

    -- Send patrols.
    Patrol(Mission.m_Sent1, "patrol_path1", 0);
    Patrol(Mission.m_Sent2, "patrol_path1a", 0);

    MaskEmitter(Mission.m_Show2, 0);

    StartEmitter(Mission.m_Show2, 1);
    StartEmitter(Mission.m_Show2, 2);

    -- Clean up any player spawns that haven't been taken by the player.
    _Cooperative.CleanSpawns();

    -- Small delay.
    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

    -- Advance the mission state.
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime) then 
        -- Kossieh: "Remember men..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1301.wav");

        -- Timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(13.5);

        -- Show objectives.
        AddObjectiveOverride("isdf1301.otf", "WHITE", 10, true);

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[3] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Run some logic based on the amount of dialogues played.
        if (Mission.m_IntroDialogueCount == 0) then
            -- Pilot: "This Scion base gives me the creeps..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1302.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Set the timer to move the first Titan.
            Mission.m_MoveBurnsTime = Mission.m_MissionTime + SecondsToTurns(3.5);

            -- Activate the brain to move the Scion units around.
            Mission.m_ScionBrainActive = true;
        elseif (Mission.m_IntroDialogueCount == 1) then
            -- Pilot: "It's definitely outside my comfort zone..."
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1303.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);
        elseif (Mission.m_IntroDialogueCount == 2) then
            -- Braddock: "Cut the chatter!"
            Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1304.wav");

            -- Timer for this audio clip.
            Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

            -- Advance the mission state.
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end

        -- Next sequence.
        Mission.m_IntroDialogueCount = Mission.m_IntroDialogueCount + 1;
    end
end

Functions[4] = function()
    if (Mission.m_MoveBurns and Mission.m_ParadeTime < Mission.m_MissionTime) then
        -- Highlight Burns, have everyone look at him.
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1305.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Change the objective name.
        SetObjectiveName(Mission.m_Burns, TranslateString("Mission1301"));

        -- Highlight Burns.
        SetObjectiveOn(Mission.m_Burns);

        -- Have everyone look.
        LookAt(Mission.m_Walker1, Mission.m_Burns);
        LookAt(Mission.m_Walker2, Mission.m_Burns);
        LookAt(Mission.m_Manson, Mission.m_Burns);
        LookAt(Mission.m_Tank2, Mission.m_Burns);
        LookAt(Mission.m_Tank3, Mission.m_Burns);

        -- Have the first titan look at the player.
        LookAt(Mission.m_Titan1, GetPlayerHandle(1));

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- This will remove Burns' dropship and start the cutscene process.
    if (Mission.m_RemoveBurns and Mission.m_CarrierTime < Mission.m_MissionTime) then
        -- Remove Burns' Condor.
        RemoveObject(Mission.m_BurnsCondor);

        -- Get the Camera Ready.
        if (Mission.m_IsCooperativeMode == false) then
            -- Prep Everything.
            CameraReady();

            -- Movie time.
            Mission.m_MovieTime = Mission.m_MissionTime + SecondsToTurns(15);

            -- Set the animations.
            SetAnimation(Mission.m_Show1, "cinteractive", 1);
            SetAnimation(Mission.m_Show2, "cinteractive", 1);

            -- Start a sound.
            StartSoundEffect("droppass.wav");

            -- Advance the mission state.
            Mission.m_MissionState = Mission.m_MissionState + 1;
        else
            -- Skip the cutscene.
            Mission.m_MissionState = 6;
        end
    end
end

Functions[6] = function()
    local curFrame = GetAnimationFrame(Mission.m_Show2, "cinteractive");

    -- Check the frames to do effects and sounds.
    if (curFrame > 109) then
        -- 110 frame, do explosion.
        if (curFrame == 110) then
            StartSoundEffect("xfire1.wav");

            -- Emit fire.
            for i = 0, 6 do
                StartEmitter(Mission.m_Show2, i);
            end
        end
    end

    -- Play our movie.
    PlayMovie("dropship2");

    -- This will advance once we are done.
    if (Mission.m_MovieTime < Mission.m_MissionTime) then
        -- Give the Camera back.
        CameraFinish();

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[7] = function()
    -- Start the carrier crashing process.
    StartEarthQuake(30);

    -- Build our Carrier.
    Mission.m_Carrier = BuildObject("ivcarr", 0, "carrier_spawn");

    -- Build the look prop at the height of the carrier.
    Mission.m_LookProp = BuildObject("ibnav", 14, Mission.m_Carrier);

    -- Activate the Prop Brain.
    Mission.m_PropBrainActive = true;

    -- Remove the show objects.
    RemoveObject(Mission.m_Show1);
    RemoveObject(Mission.m_Show2);

    -- Quick Quake Time.
    Mission.m_QuakeTime = Mission.m_MissionTime + SecondsToTurns(0.5);

    -- To stop our failure conditions from triggering.
    Mission.m_Hell = true;

    -- Advance the mission state.
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[8] = function()
    if (Mission.m_QuakeTime < Mission.m_MissionTime) then
        -- Update the Earthquake.
        UpdateEarthQuake(5.0);

        -- Carrier needs the Crashing animation.
        SetAnimation(Mission.m_Carrier, "crash", 1);

        -- Stop unique warrior behavior
        Mission.m_WarriorActive = false;

        -- Get all the Scion units to look as well.
        for i = 1, #Mission.m_ScionVehicles do
            LookAt(Mission.m_ScionVehicles[i], Mission.m_LookProp, 0);
        end

        -- Have the tanks look at Manson.
        LookAt(Mission.m_Tank2, Mission.m_Manson, 1);
        LookAt(Mission.m_Tank3, Mission.m_Manson, 1);
        LookAt(Mission.m_Walker1, Mission.m_Manson, 1);
        LookAt(Mission.m_Walker2, Mission.m_Manson, 1);

        -- Set the panic time.
        Mission.m_PanicTime = Mission.m_MissionTime + SecondsToTurns(6);

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[9] = function()
    if (Mission.m_PanicTime < Mission.m_MissionTime) then
        -- Manson: "The carrier has been blown out of the sky!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1307.wav");

        -- Timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Get Manson to track the carrier.
        LookAt(Mission.m_Manson, Mission.m_LookProp, 1);

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[10] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Manson: "Sky 1, come in, Sky 1!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1308.wav");

        -- Timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(3.5);

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[11] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Pilot: "What do we do?!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1309.wav");

        -- Timer for this clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(2.5);

        -- Have Manson look at the Pilot who is talking.
        LookAt(Mission.m_Manson, Mission.m_Tank2, 1);

        -- Delay the mission by 5 seconds.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(5);

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[12] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock: "Get your asses immediately to the south."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1310a.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(9.5);

        -- Stop the Earth Quake.
        StopEarthQuake();

        -- Remove the Look Prop.
        RemoveObject(Mission.m_LookProp);

        -- Remove the Prop Brain.
        Mission.m_PropBrainActive = false;

        -- Highlight the Recycler.
        SetObjectiveOn(Mission.m_Recycler);

        -- Stop the walkers.
        if (IsAlive(Mission.m_Walker1)) then
            -- To stop it from randomly smoking.
            SetMaxHealth(Mission.m_Walker1, 2000);
            SetCurHealth(Mission.m_Walker1, 2000);

            -- Stop it.
            Stop(Mission.m_Walker1, 1);
        end

        if (IsAlive(Mission.m_Walker2)) then
            -- To stop it from randomly smoking.
            SetMaxHealth(Mission.m_Walker2, 2000);
            SetCurHealth(Mission.m_Walker2, 2000);

            -- Stop it.
            Stop(Mission.m_Walker2, 1);
        end

        -- Stop the builder and give it back to the AIP.
        if (IsAliveAndEnemy(Mission.m_Builder1, Mission.m_EnemyTeam)) then
            Stop(Mission.m_Builder1, 0);
        end

        -- Carnage.
        for i = 1, 5 do
            UnAlly(i, Mission.m_EnemyTeam);
        end

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[13] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Manson: "Do not copy, General, repeat!"
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1311.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

        -- Set all of the other units to health 1.
        if (IsAlive(Mission.m_Manson)) then
            SetCurHealth(Mission.m_Manson, 1);
        end

        if (IsAlive(Mission.m_Tank2)) then
            SetCurHealth(Mission.m_Tank2, 1);
        end

        if (IsAlive(Mission.m_Tank3)) then
            SetCurHealth(Mission.m_Tank3, 1);
        end

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[14] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Braddock: "Cooke, head to the south-east..."
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1312.wav");

        -- Kill the Carrier.
        RemoveObject(Mission.m_Carrier);

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(8.5);

        -- Show Objectives.
        AddObjectiveOverride("isdf1302.otf", "WHITE", 10, true);

        -- Delay checks for a second to avoid checks happening every frame.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[15] = function()
    if (Mission.m_MissionDelayTime < Mission.m_MissionTime and IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode)) then
        -- Delay checks for a second to avoid checks happening every frame.
        Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(1);

        -- Run a check to see if a player has escaped.
        for i = 1, _Cooperative.GetTotalPlayers() do
            local p = GetPlayerHandle(i);

            if (GetDistance(p, "war_point2") > 750) then
                -- You're clear Cooke!
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1315.wav");

                -- Set new plan here...
                SetAIP("isdf1301_x.aip", Mission.m_EnemyTeam);

                -- Timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(12.5);

                -- Have the first 2 titans patrol the base.
                Patrol(Mission.m_Titan1, "patrol_path1", 1);
                Patrol(Mission.m_Titan2, "patrol_path1a", 1);

                -- Show objectives.
                AddObjectiveOverride("isdf1302.otf", "GREEN", 10, true);
                AddObjective("isdf1303.otf", "WHITE");

                -- Advance the mission state.
                Mission.m_MissionState = Mission.m_MissionState + 1;
            end
        end
    end
end

Functions[16] = function()
    if (IsAudioMessageFinished(Mission.m_Audioclip, Mission.m_AudioTimer, Mission.m_MissionTime, Mission.m_IsCooperativeMode) and IsPlayerWithinDistance(Mission.m_Recycler, 150, _Cooperative.GetTotalPlayers())) then
        -- Give the Recycler to the player.
        SetGroup(Mission.m_Recycler, 0);

        -- Have it hold os the player is ready.
        Stop(Mission.m_Recycler, 0);

        -- Give our team some scrap
        AddScrap(Mission.m_HostTeam, 40);

        -- Remove the highlight from it.
        SetObjectiveOff(Mission.m_Recycler);

        -- Highlight the power source.
        SetObjectiveName(Mission.m_KeyDevice, TranslateString("Mission1202"));
        SetObjectiveOn(Mission.m_KeyDevice);

        -- Add Objectives.
        AddObjectiveOverride("isdf1303.otf", "GREEN", 10, true);
        AddObjective("isdf1304.otf", "WHITE")

        -- Highlight the second nav.
        Mission.m_Nav1 = BuildObject("ibnav", Mission.m_HostTeam, "nav2_spawn");

        -- Change the name.
        SetObjectiveName(Mission.m_Nav1, TranslateString("Mission1303"));

        -- Show a beacon.
        SetObjectiveOn(Mission.m_Nav1);

        -- Braddock: "Well done. I'm afraid this is all the support you're getting for now.".
        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1316.wav");

        -- Timer for this audio clip.
        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(16.5);

        -- Send the enemies to their guard points if they are alive.
        if (IsAliveAndEnemy(Mission.m_War1, Mission.m_EnemyTeam)) then
            Goto(Mission.m_War1, "guard_point1", 0);
        end

        if (IsAliveAndEnemy(Mission.m_Sent1, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Sent1, "guard_point2", 0);
        end

        if (IsAliveAndEnemy(Mission.m_Sent2, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Sent2, "guard_point3", 0);
        end

        -- Let the AI send turrets to points.
        Mission.m_TurretDispatcherActive = true;

        -- Advance the mission state.
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[17] = function()
    -- Here, we can just check that the tug has grabbed the power core.
    if (not Mission.m_MissionOver) then
        if (IsAlive(Mission.m_KeyDevice)) then
            -- Check to see what is carrying the power source.
            local tugger = GetTug(Mission.m_KeyDevice);

            if (GetTeamNum(tugger) == Mission.m_HostTeam) then
                -- Manson: Well done. You've successfully shut down the weapon.
                Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1313.wav");

                -- Set the timer for this audio clip.
                Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                if (Mission.m_IsCooperativeMode) then
                    NoteGameoverWithCustomMessage("Mission Accomplished.");
                    DoGameover(10);
                else
                    SucceedMission(GetTime() + 10, "isdf13w1.txt");
                end

                -- So we don't loop.
                Mission.m_MissionOver = true;
            end
        end
    end
end

function HandleFailureConditions()
    if (Mission.m_Hell == false) then
        -- Run a check on all players here, make sure they don't shoot or run away.
        if (Mission.m_WarningTimer < Mission.m_MissionTime) then
            -- Just so we don't do this every frame.
            Mission.m_WarningTimer = Mission.m_MissionTime + SecondsToTurns(1);

            for i = 1, _Cooperative.GetTotalPlayers() do
                -- Grab the player handle.
                local p = GetPlayerHandle(i);
                local maxAmmo = GetMaxAmmo(p);
                local curAmmo = GetCurAmmo(p);

                -- Check if they are within distance of Manson.
                if (GetDistance(p, "manson_start") > 60) then
                    -- Stop all audio.
                    StopAudioMessage(Mission.m_Audioclip);

                    -- Make sure the timer is reset.
                    Mission.m_AudioTimer = 0;

                    -- Check here if we have already done Manson's warning.
                    if (Mission.m_MansonWarning == false) then
                        -- Show new objective.
                        AddObjectiveOverride("isdf1301.otf", "RED", 10, true);

                        -- Manson: "Cooke you were ordered to stay with me!".
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1306.wav");

                        -- Timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(4.5);

                        -- Give the player a chance to come back.
                        Mission.m_WarningTimer = Mission.m_MissionTime + SecondsToTurns(6);

                        -- So we can fail.
                        Mission.m_MansonWarning = true;
                    else
                        -- Carnage.
                        for i = 1, 5 do
                            UnAlly(i, Mission.m_EnemyTeam);
                        end

                        -- Kossieh: "You messed up the peace talks."
                        Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1314.wav");

                        -- Timer for this audio clip.
                        Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(7.5);

                        -- Game over.
                        if (Mission.m_IsCooperativeMode) then
                            NoteGameoverWithCustomMessage("You sabotaged the peace talks!");
                            DoGameover(10);
                        else
                            FailMission(GetTime() + 10, "isdf13l1.txt");
                        end

                        -- Mission failed.
                        Mission.m_MissionOver = true;
                    end
                end

                -- Check to see if the player has fired their weapons.
                if (curAmmo < maxAmmo) then
                    -- Stop all audio.
                    StopAudioMessage(Mission.m_Audioclip);

                    -- Make sure the timer is reset.
                    Mission.m_AudioTimer = 0;

                    -- Carnage.
                    for i = 1, 5 do
                        UnAlly(i, Mission.m_EnemyTeam);
                    end

                    -- Kossieh: "You messed up the peace talks."
                    Mission.m_Audioclip = _Subtitles.AudioWithSubtitles("isdf1317.wav");

                    -- Timer for this audio clip.
                    Mission.m_AudioTimer = Mission.m_MissionTime + SecondsToTurns(6.5);

                    -- Game over.
                    if (Mission.m_IsCooperativeMode) then
                        NoteGameoverWithCustomMessage("You sabotaged the peace talks!");
                        DoGameover(10);
                    else
                        FailMission(GetTime() + 10, "isdf13l1.txt");
                    end

                    -- Mission failed.
                    Mission.m_MissionOver = true;
                end
            end
        end
    end

    if (IsAlive(Mission.m_Recycler) == false) then
        -- Stop the mission.
        Mission.m_MissionOver = true;

        -- Failure.
        if (Mission.m_IsCooperativeMode) then
            NoteGameoverWithCustomMessage("Your Recycler was destroyed.");
            DoGameover(10);
        else
            FailMission(GetTime() + 10, "isdf10l1.txt");
        end
    end
end

function ScionBrain()
    -- Use this to dispatch the turrets.
    if (Mission.m_TurretDispatcherActive and Mission.m_TurretDistpacherTimer < Mission.m_MissionTime) then
        if (Mission.m_Guardian1Sent == false and IsAliveAndEnemy(Mission.m_Guardian1, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian1, "guard_point1", 1);

            -- So we don't loop.
            Mission.m_Guardian1Sent = true;
        end

        if (Mission.m_Guardian2Sent == false and IsAliveAndEnemy(Mission.m_Guardian2, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian2, "guard_point2", 1);

            -- So we don't loop.
            Mission.m_Guardian2Sent = true;
        end

        if (Mission.m_Guardian3Sent == false and IsAliveAndEnemy(Mission.m_Guardian3, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian3, "guard_point3", 1);

            -- So we don't loop.
            Mission.m_Guardian3Sent = true;
        end

        if (Mission.m_Guardian4Sent == false and IsAliveAndEnemy(Mission.m_Guardian4, Mission.m_EnemyTeam)) then
            Goto(Mission.m_Guardian4, "guard_point4", 1);

            -- So we don't loop.
            Mission.m_Guardian4Sent = true;
        end

        -- To delay loops.
        Mission.m_TurretDistpacherTimer = Mission.m_MissionTime + SecondsToTurns(1.5);
    end

    -- Run the brain for the warrior to randomly look at players.
    if (Mission.m_WarriorActive) then
        -- This will check to see if the Warrior has reached it's path.
        if (Mission.m_WarriorState == 2) then
            if (GetDistance(Mission.m_War1, Mission.m_ScionPath) < 10) then
                -- Depending on the number, have it look at one of the players, or an AI.
                if (Mission.m_ScionRandomChance > Mission.m_ScionPlayerCount) then
                    -- Work out which AI to view.
                    local aiNum = Mission.m_ScionRandomChance - Mission.m_ScionPlayerCount;

                    if (aiNum == 1) then
                        LookAt(Mission.m_War1, Mission.m_Manson);
                    elseif (aiNum == 2) then
                        LookAt(Mission.m_War1, Mission.m_Tank2);
                    elseif (aiNum == 3) then
                        LookAt(Mission.m_War1, Mission.m_Tank3);
                    end
                else
                    LookAt(Mission.m_War1, GetPlayerHandle(Mission.m_ScionRandomChance));
                end

                -- So we can delay the time.
                Mission.m_WarriorTime = Mission.m_MissionTime + SecondsToTurns(4);

                -- Set it back to look state.
                Mission.m_WarriorState = 1;
            end
        elseif (Mission.m_WarriorTime < Mission.m_MissionTime) then
            if (Mission.m_WarriorFirstLook == false) then
                local p1Handle = GetPlayerHandle(1);

                -- Run a check to see if the Warrior has met the first player yet.
                if (GetDistance(Mission.m_War1, p1Handle) < 50) then
                    -- Look at the first player.
                    LookAt(Mission.m_War1, p1Handle);

                    -- Set the look timer.
                    Mission.m_WarriorTime = Mission.m_MissionTime + SecondsToTurns(7);

                    -- So we don't loop.
                    Mission.m_WarriorFirstLook = true;

                    -- Return early until this logic is fulfilled.
                    return;
                end
            else
                -- Just for this part.
                Mission.m_ScionPlayerCount = _Cooperative.GetTotalPlayers();

                -- This will always generate a number for the warrior to look at a random unit.
                Mission.m_ScionRandomChance = math.ceil(GetRandomFloat(0, Mission.m_ScionPlayerCount + 3));

                -- This will run if the randChange is equal to or below the number of total players.
                if (Mission.m_ScionRandomChance <= Mission.m_ScionPlayerCount) then
                    -- If the random count is between 2-4 then have it move to point 3.
                    if (Mission.m_ScionPlayerCount > 1) then
                        Mission.m_ScionPath = 'war_point3';
                    else
                        Mission.m_ScionPath = 'war_point2';
                    end
                elseif (Mission.m_ScionRandomChance > Mission.m_ScionPlayerCount) then
                    -- Have it look at the AI friendies.
                    Mission.m_ScionPath = 'war_point2';
                end

                -- Move the warrior.
                Goto(Mission.m_War1, Mission.m_ScionPath);

                -- Set it to GO state.
                Mission.m_WarriorState = 2;
            end
        end
    end

    -- Send the first Titan.
    if (Mission.m_RemoveBurns == false and Mission.m_MoveBurnsTime < Mission.m_MissionTime) then
        if (Mission.m_MoveTitan1 == false) then
            -- Send the Titan.
            Goto(Mission.m_Titan1, "titan1_path3");

            -- Send the Warrior.
            Goto(Mission.m_War1, GetPlayerHandle(1));

            -- Update the time for Burns.
            Mission.m_MoveBurnsTime = Mission.m_MissionTime + SecondsToTurns(6);

            -- Activate the Warrior.
            Mission.m_WarriorActive = true;

            -- So we don't loop.
            Mission.m_MoveTitan1 = true;
        elseif (Mission.m_MoveBurns == false) then
            -- Send Burns.
            Retreat(Mission.m_Burns, "burns_path3");

            -- Have the second Titan follow Burns.
            Follow(Mission.m_Titan2, Mission.m_Burns, 1);

            -- Set our timers.
            Mission.m_BurnsTime = Mission.m_MissionTime + SecondsToTurns(1);
            Mission.m_WarriorTime = Mission.m_MissionTime + SecondsToTurns(1);
            Mission.m_ParadeTime = Mission.m_MissionTime + SecondsToTurns(20);

            -- So we don't loop.
            Mission.m_MoveBurns = true;
        elseif (Mission.m_BurnsAtCondor == false) then
            -- Run a check to see if Burns has reached the Checkpoint.
            if (GetDistance(Mission.m_Burns, "convoycheck_point") < 40) then
                -- Move Burns to the dropship.
                Goto(Mission.m_Burns, "enter_drop_path");

                -- So we don't loop.
                Mission.m_BurnsAtCondor = true;
            end
        elseif (Mission.m_BurnsInCondor == false) then
            -- Run a check to see if Burns has reached the Dropship.
            if (GetDistance(Mission.m_Burns, "in_drop_point") < 25) then
                -- Stop Burns.
                Stop(Mission.m_Burns, 1);

                -- Remove his objective.
                SetObjectiveOff(Mission.m_Burns);

                -- Stop the second Titan.
                Stop(Mission.m_Titan2, 0);

                -- Give the Condor a sound.
                StartSoundEffect("dropleav.wav", Mission.m_BurnsCondor);

                -- Start the animations.
                SetAnimation(Mission.m_BurnsCondor, "takeoff", 1);

                -- Start up the emitters.
                StartEmitter(Mission.m_BurnsCondor, 1);
                StartEmitter(Mission.m_BurnsCondor, 2);

                -- Next timer.
                Mission.m_MoveBurnsTime = Mission.m_MissionTime + SecondsToTurns(4);

                -- So we don't loop.
                Mission.m_BurnsInCondor = true;
            end
        elseif (Mission.m_RemoveBurns == false) then
            -- Remove Burns.
            RemoveObject(Mission.m_Burns);

            -- Set the timer for the Carrier.
            if (Mission.m_IsCooperativeMode == false) then
                Mission.m_CarrierTime = Mission.m_MissionTime + SecondsToTurns(6);
            else
                Mission.m_CarrierTime = Mission.m_MissionTime + SecondsToTurns(12);
            end

            -- This will remove burns when he has reached the dropship.
            Mission.m_RemoveBurns = true;
        end
    end
end

function PropBrain()
    -- Calculate the position of the prop.
    local curPos = GetPosition(Mission.m_LookProp);

    -- Update our current matrix.
    curPos.y = 225;
    curPos.z = curPos.z + (20 / m_GameTPS);

    SetPosition(Mission.m_LookProp, curPos);
end