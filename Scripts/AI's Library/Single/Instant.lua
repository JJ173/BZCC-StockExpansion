-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))();

-- Required Globals.
require("_GlobalVariables");

-- Required helper functions.
require("_HelperFunctions");

-- Required Skins Logic.
require("_Skins");

-- Required AI Command Vars.
require("_AICmd");

-- Models
local _AIController = require("_AIController");
local _Pool = require("_Pool");
local _Condor = require("_Condor");
local _Portal = require("_Portal");

-- Subtitles.
local _Subtitles = require('_Subtitles');

local _Session = {
    m_GameTPS = 20,

    m_CPUTeamRace = 0,
    m_HumanTeamRace = 0,

    m_MusicOptionValue = 0,

    -- This is constantly 1.
    m_PlayerTeam = 1,
    -- This may change if 1.2 features "Like Pilot" are enabled.
    -- If 1.2 is enabled, m_StratTeam will be set to 3.
    m_StratTeam = 1,
    m_CompTeam = 6,
    m_TurnCounter = 0,
    m_MyGoal = 0,
    m_AwareV13 = 0,
    m_MyForce = 0,
    m_CompForce = 0,
    m_Difficulty = 0,

    m_IntroForcePlayerTeleportDelay = 0,
    m_IntroState = 1,
    m_IntroDelay = 0,
    m_IntroAudio = 0,
    m_IntroMusic = 0,
    m_IntroMusicVolume = 1,
    m_SetIntroMusicVolume = false,
    m_IntroEnemiesSpawned = false,
    m_IntroEnemy1 = nil,
    m_IntroEnemy2 = nil,
    m_IntroEnemy3 = nil,

    m_IntroMatriarchTeleported = false,
    m_IntroTurret1Teleported = false,
    m_IntroTurret2Teleported = false,

    m_CustomAIPStr = nil,

    m_EnemyRecycler = nil,
    m_Recycler = nil,
    m_Player = nil,

    m_IntroShip1 = nil,
    m_IntroShip2 = nil,

    m_IntroScionTurret1 = nil,
    m_IntroScionTurret2 = nil,
    m_ScionIntroHangar = nil,
    m_ScionIntroMatriarch = nil,
    m_ScionIntroPlayer = nil,

    m_IntroTurret1 = nil,
    m_IntroTurret2 = nil,

    m_PlayerTurret1 = nil,
    m_PlayerTurret2 = nil,

    m_PlayerCarrier = nil,
    m_CPUCarrier = nil,

    m_PlayerLandingPad = nil,
    m_CPULandingPad = nil,

    m_PlayerDropship = nil,
    m_CPUDropship = nil,

    m_DropshipTakeOffDialogPlayed = false,
    m_DropshipTakeoffCheck = false,
    m_Dropship1Takeoff = false,
    m_Dropship1Remove = false,
    m_Dropship1Time = 0,

    m_Dropship2Takeoff = false,
    m_Dropship2Remove = false,
    m_Dropship2Time = 0,

    m_TauntTimer = 0,

    m_IntroDone = false,
    m_StartDone = false,
    m_CanRespawn = false,
    m_GameOver = false,
    m_IntroCutsceneEnabled = false,
    m_AICommanderEnabled = false,
    m_RTSModeEnabled = false,

    m_AIController = nil,

    m_Pools = {},

    -- This keeps track of how long it has been since the player built a carrier object.
    -- Idea is to remove them after 10 minutes.
    m_Condors = {},
    m_CarrierItemsToRemove = {},
    m_Portals = {},

    m_CarrierObjectCheckDelay = 0
}

local CHAR_RACE_ISDF = 'i';
local CHAR_RACE_SCION = 'f';

-- Functions Table
local ISDFIntroFunctions = {};
local ScionIntroFunctions = {};

-- Debug only.
local debug = false;
local debug_base = false;
local debug_base_built = false;
local debug_contoller = false;
local debug_stop_script = false;

-- ODFs to Preload.
local PreloadODFs = {
    "ivrecy",
    "fvrecy",
    "ivrecycpu",
    "fvrecycpu",
    "ivrecy_x",
    "fvrecy_x",
    "ivrecy_c",
    "fvrecy_c",
    "ibcarrier_xm",
    "fbcarrier_xm",
    "ivpdrop_x",
    "fbhangar",
    "fbportb_ARK",
    "fbstro_ARK",
    "fbark2holo"
}

-- Audio to Preload.
local PreloadAudios = {
    "IA_Intro.wav",
    "IA_Pilot_1.wav",
    "IA_Pilot_2.wav",
    "IA_Pilot_3.wav",
    "IA_Pilot_4.wav",
    "IA_Carrier_1.wav",
    "IA_Carrier_2.wav",
    "IA_Scion_Carrier_1.wav",
    "IA_Scion_Carrier_2.wav",
    "IA_Scion_Tech_1.wav",
    "IA_Scion_Tech_2.wav",
    "IA_Scion_Tech_3.wav",
    "IA_Scion_Tech_3A.wav",
    "IA_Scion_Tech_3B.wav",
    "IA_Scion_Tech_4.wav",
    "dropdoor.wav"
}

-- Debugging. This will control the enemy base for testing layouts.
local ISDFBaseLayout =
{
    { "ivrecy_c", "RecyclerEnemy" },
    -- { "ibfact_c",       "i_Factory" },

    -- { "ibpgen_c3",      "i_Power_1" },
    -- { "ibpgen_c3",      "i_Power_2" },
    -- { "ibpgen_c3",      "i_Power_3" },

    -- { "ibcbun_c",       "i_Bunker" },
    -- { "ibcbun_c",       "i_Base_Bunker_1" },
    -- { "ibcbun_c",       "i_Base_Bunker_2" },
    -- { "ibcbun_c",       "i_Base_Bunker_3" },

    -- { "ibsbay_c",       "i_ServiceBay" },
    -- { "ibarmo_c",       "i_Armory" },
    -- { "ibtcen_c",       "i_Tech" },
    -- { "ibtrain_c",      "i_Training" },
    -- { "ibbomb_c",       "i_BomberBay" },
    -- { "iblandingpad_c", "i_LandingPad" },

    -- { "ibplate_c",      "i_Plate_1" },
    -- { "ibplate_c",      "i_Plate_2" },
    -- { "ibplate_c",      "i_Plate_3" },
    -- { "ibplate_c",      "i_Plate_4" },
    -- { "ibplate_c",      "i_Plate_5" },
    -- { "ibplate_c",      "i_Plate_6" },
    -- { "ibplate_c",      "i_Plate_7" },
    -- { "ibplate_c",      "i_Plate_8" },

    -- { "ibgtow_c",       "i_GunTower_1" },
    -- { "ibgtow_c",       "i_GunTower_2" },
    -- { "ibgtow_c",       "i_GunTower_3" },
    -- { "ibgtow_c",       "i_GunTower_4" },

    -- { "ibhrtow_b_c",    "i_Base_AntiAir_1" },
    -- { "ibhrtow_b_c",    "i_Base_AntiAir_2" },

    -- { "ibatow_c_a2",    "i_Base_AssaultTower_1" },
    -- { "ibatow_c_a2",    "i_Base_AssaultTower_2" },

    -- { "ibartl_c_b",     "i_Base_Artillery_1" },
    -- { "ibartl_c_b",     "i_Base_Artillery_2" },

    -- { "ibcbun_c",       "i_Field_Bunker_1" },
    -- { "ibcbun_c",       "i_Field_Bunker_2" },

    -- { "ibgtow_c",       "i_Field_GunTower_1" },
    -- { "ibgtow_c",       "i_Field_GunTower_2" },

    -- { "ibatow_c_b2",    "i_Field_AssualtTower_1_A" },
    -- { "ibatow_c_b2",    "i_Field_AssualtTower_1_B" },
    -- { "ibatow_c_b2",    "i_Field_AssualtTower_2_A" },
    -- { "ibatow_c_b2",    "i_Field_AssualtTower_2_B" },

    -- { "ibrtow_b_c",     "i_Field_RocketTower_1" },
    -- { "ibrtow_b_c",     "i_Field_RocketTower_2" },

    -- { "ibsbay_c_a2",    "i_Assault_Depot" }
}

local ScionBaseLayout =
{
    { "fvrecy_c", "RecyclerEnemy" },

    -- { "fbforg_c",   "F_Forge" },
    -- { "fbover_c",   "F_Overseer" },
    -- { "fbdowe_c",   "F_Dower" },
    -- { "fbstro_c",   "F_Stronghold" },

    -- { "fbjamm_c",   "F_BaseJammer_1" },
    -- { "fbjamm_c",   "F_BaseJammer_2" },

    -- { "fbspir_c",   "F_BaseSpire_1" },
    -- { "fbspir_c",   "F_BaseSpire_2" },
    -- { "fbspir_c",   "F_BaseSpire_3" },

    -- { "fbrspir_c",  "F_Base_AntiAir_1" },
    -- { "fbrspir_c",  "F_Base_AntiAir_2" },
    -- { "fbrspir_c",  "F_Base_AntiAir_3" },

    -- { "fbartl_c_b", "F_Base_Artillery_1" },
    -- { "fbartl_c_b", "F_Base_Artillery_2" },

    -- { "fbaspir_c",  "F_Base_AssaultSpire_1" },
    -- { "fbaspir_c",  "F_Base_AssaultSpire_2" },
    -- { "fbaspir_c",  "F_Base_AssaultSpire_3" },

    -- { "fbaspir_c",  "F_Field_AssaultSpire_1" },
    -- { "fbaspir_c",  "F_Field_AssaultSpire_2" },
    -- { "fbaspir_c",  "F_Field_AssaultSpire_3" },
    -- { "fbaspir_c",  "F_Field_AssaultSpire_4" },

    -- { "fbrspir_c",  "F_Field_RocketTower_1" },
    -- { "fbrspir_c",  "F_Field_RocketTower_2" },
    -- { "fbrspir_c",  "F_Field_RocketTower_3" }
}

-- Planet assortment for different map names.
local MireMaps = {
    "bridges.trn",
    "mpicanyons.trn",
    "iacirclebzcc.trn",
    "iadustbzcc.trn",
    "iaentrapbzcc.trn",
    "iafirebzcc.trn",
    "iafortbzcc.trn",
    "iaghzonebzcc.trn"
}

local BaneMaps = {
    "dunesi.trn",
    "chill.trn",
    "ground4.trn",
    "ground0.trn",
    "MPIIsland.trn",
    "sea_battle.trn"
}

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function InitialSetup()
    -- This is to stop music for the intro.
    AllowRandomTracks(true);

    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();

    -- Preload ODFs to save time when they spawn.
    for i = 1, #PreloadODFs do
        PreloadODF(PreloadODFs[i]);
    end

    -- Preload Audio handles here as well.
    for i = 1, #PreloadAudios do
        PreloadAudioMessage(PreloadAudios[i]);
    end
end

function Save()
    return _Session, _AIController:Save();
end

function Load(Session, AIController)
    _Session = Session;

    if (_Session.m_AIController ~= nil) then
        _Session.m_AIController:Load(AIController);
    end
end

function AddObject(handle)
    local classLabel = GetClassLabel(handle);
    local teamNum = GetTeamNum(handle);
    local isRecyclerVehicle = (classLabel == "CLASS_RECYCLERVEHICLE" or classLabel == "CLASS_RECYCLERVEHICLEH");
    local objCfg = GetCfg(handle);
    local objBase = GetBase(handle);

    if (classLabel == "CLASS_DEPOSIT") then
        _Session.m_Pools[#_Session.m_Pools + 1] = _Pool:New(handle, GetPosition(handle),
            GetDistance(handle, "RecyclerEnemy"));
    end

    if (_Session.m_IntroDone == false) then
        if (objCfg == "fbportb_ark") then
            _Session.m_ScionIntroPortal = handle;
        end
    end

    -- Max out skills.
    SetSkill(handle, 3);

    if (teamNum == _Session.m_CompTeam) then
        if (isRecyclerVehicle) then
            _Session.m_EnemyRecycler = handle;
        elseif (objCfg == _Session.m_CPUTeamRace .. "blandingpad_xm" or objCfg == _Session.m_CPUTeamRace .. "bport_xm") then
            _Session.m_CPULandingPad = handle;
        end

        -- Add the objects to the AI Controller.
        if (_Session.m_AIController ~= nil) then
            _Session.m_AIController:AddObject(handle, classLabel, objCfg, objBase, _Session.m_TurnCounter);
        end
    elseif (teamNum == _Session.m_StratTeam) then
        if (isRecyclerVehicle) then
            _Session.m_Recycler = handle;
        elseif (objCfg == _Session.m_HumanTeamRace .. "blandingpad_xm" or objCfg == _Session.m_HumanTeamRace .. "bport_xm") then
            _Session.m_PlayerLandingPad = handle;
        elseif (objBase == "TurretDropship" or objBase == "LightDropship" or objBase == "ScavengerDropship" or objBase == "ScrapDropship") then
            local dropshipRequestItem =
            {
                ItemHandle = handle,
                TimeToDelete = _Session.m_TurnCounter + SecondsToTurns(600),
            };

            _Session.m_CarrierItemsToRemove[#_Session.m_CarrierItemsToRemove + 1] = dropshipRequestItem;

            if (_Session.m_HumanTeamRace == CHAR_RACE_ISDF) then
                local condorModel;

                if (objBase == "ScrapDropship") then
                    condorModel = _Condor:New(handle, teamNum, objBase, _Session.m_PlayerLandingPad, 2);
                else
                    condorModel = _Condor:New(handle, teamNum, objBase, _Session.m_PlayerLandingPad, 3);
                end

                if (condorModel ~= nil) then
                    _Session.m_Condors[#_Session.m_Condors + 1] = condorModel;
                end
            elseif (_Session.m_HumanTeamRace == CHAR_RACE_SCION) then
                local portalModel;

                if (objBase == "ScrapDropship") then
                    portalModel = _Portal:New(teamNum, objBase, _Session.m_PlayerLandingPad, 2);
                else
                    portalModel = _Portal:New(teamNum, objBase, _Session.m_PlayerLandingPad, 3);
                end

                if (portalModel ~= nil) then
                    _Session.m_Portals[#_Session.m_Portals + 1] = portalModel;
                end
            end
        end

        if (_Session.m_MyGoal == 0) then
            if (classLabel == "CLASS_WINGMAN" or classLabel == "CLASS_MORPHTANK" or classLabel == "CLASS_ASSAULTTANK" or classLabel == "CLASS_SERVICE" or classLabel == "CLASS_WALKER") then
                SetTeamNum(handle, _Session.m_PlayerTeam);
                SetBestGroup(handle);
            end
        end
    elseif (_Session.m_AwareV13 == 0 and teamNum == _Session.m_PlayerTeam) then
        -- This block should never happen in normal IA mode, but if for some reason the player has a Scavenger in Pilot mode,
        -- we should switch the extractor to the right team when it's deployed to prevent breaking.
        if (classLabel == "CLASS_EXTRACTOR") then
            SetTeamNum(handle, _Session.m_StratTeam);
        end
    end
end

function DeleteObject(handle)
    if (GetTeamNum(handle) == _Session.m_CompTeam) then
        -- Remove the objects from the AI Controller.
        if (_Session.m_AIController ~= nil) then
            _Session.m_AIController:DeleteObject(handle, GetClassLabel(handle), GetCfg(handle), GetBase(handle));
        end
    end
end

function Start()
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- Grab the TPS.
    _Session.m_GameTPS = GetTPS();

    -- Reset the turn counter.
    _Session.m_TurnCounter = 0;

    _Session.m_StartDone = false;
    _Session.m_GameOver = false;
    _Session.m_CompTeam = 6;
    _Session.m_StratTeam = 1;

    _Session.m_CanRespawn = IFace_GetInteger("options.instant.bool0");
    _Session.m_IntroCutsceneEnabled = IFace_GetInteger("options.instant.bool1");
    _Session.m_RTSModeEnabled = IFace_GetInteger("options.instant.bool3");

    _Session.m_CPUTeamRace = string.char(IFace_GetInteger("options.instant.hisrace"));
    _Session.m_HumanTeamRace = string.char(IFace_GetInteger("options.instant.myrace"));
    _Session.m_Difficulty = GetInstantDifficulty();
end

function Update()
    -- Keep track of our turn counter.
    _Session.m_TurnCounter = _Session.m_TurnCounter + 1;

    if (debug_stop_script) then
        if (debug_base and debug_base_built == false) then
            if (_Session.m_CPUTeamRace == 'i') then
                for i = 1, #ISDFBaseLayout do
                    -- Grab each table line.
                    local baseBuilding = ISDFBaseLayout[i];
                    BuildObject(baseBuilding[1], 0, baseBuilding[2]);
                end
            elseif (_Session.m_CPUTeamRace == 'f') then
                for i = 1, #ScionBaseLayout do
                    -- Grab each table line.
                    local baseBuilding = ScionBaseLayout[i];
                    BuildObject(baseBuilding[1], 0, baseBuilding[2]);
                end
            end

            -- If we are in debug mode, set the CPU Team to 0.
            _Session.m_CompTeam = 0;

            -- To deploy the CPU Recycler so I can see where the base will face.
            SetAIP('debug.aip', _Session.m_CompTeam);

            if (debug_contoller) then
                -- Create the CPU team model to keep track of what's in the world.
                _Session.m_AIController = _AIController:New(_Session.m_CompTeam, _Session.m_CPUTeamRace, _Session
                    .m_Pools);

                -- Setup the AI Controller.
                _Session.m_AIController:Setup(_Session.m_CompTeam);
            end

            -- So we don't spawn infinite bases.
            debug_base_built = true;
        end

        return;
    end

    -- Subtitles.
    _Subtitles.Run();

    -- Keep track of our player.
    _Session.m_Player = GetPlayerHandle(1);

    if (_Session.m_StartDone == false) then
        _Session.m_StartDone = true;

        -- If we are in debug mode, launch cheats.
        if (debug) then
            IFace_ConsoleCmd("game.cheat bzbody");
            IFace_ConsoleCmd("game.cheat bztnt");
            IFace_ConsoleCmd("game.cheat bzradar");
            IFace_ConsoleCmd("game.cheat bzfree");
        end

        local customCPURecycler = IFace_GetString("options.instant.string2");

        if (customCPURecycler ~= nil) then
            _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace,
                customCPURecycler, "*vrecy", "RecyclerEnemy");
        else
            _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vrecy_x",
                "*vrecy", "RecyclerEnemy");
        end

        -- Spawn CPU vehicles.
        BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr_x", "*vturr_c", "TurretEnemy1");
        BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr_x", "*vturr_c", "TurretEnemy2");

        CHAR_RACE_ISDF = string.char(RACE_ISDF);
        CHAR_RACE_SCION = string.char(RACE_SCION);

        -- Checks for team colour differences.
        if (_Session.m_CPUTeamRace == CHAR_RACE_ISDF and _Session.m_HumanTeamRace == CHAR_RACE_ISDF) then
            SetTeamColor(_Session.m_CompTeam, 0, 127, 255); -- Blue like in the campaign.
        elseif (_Session.m_CPUTeamRace == CHAR_RACE_SCION and _Session.m_HumanTeamRace == CHAR_RACE_SCION) then
            SetTeamColor(_Session.m_CompTeam, 85, 255, 85); -- Green (Rebels) like in the campaign.
        end

        -- Create the CPU team model to keep track of what's in the world.
        _Session.m_AIController = _AIController:New(_Session.m_CompTeam, _Session.m_CPUTeamRace, _Session.m_Pools);

        -- Setup the AI Controller.
        _Session.m_AIController:Setup(_Session.m_CompTeam);

        -- Grab dropship handles for the intro.
        _Session.m_IntroShip1 = GetHandle("intro_drop_1");
        _Session.m_IntroShip2 = GetHandle("intro_drop_2");

        -- Grab all Scion intro units.
        _Session.m_ScionIntroHangar = GetHandle("scion_intro_hangar");
        _Session.m_ScionIntroMatriarch = GetHandle("intro_matriarch");
        _Session.m_ScionIntroPlayer = GetHandle("scion_player_scout");
        _Session.m_ScionIntroTurret1 = GetHandle("intro_turret_1_scion");
        _Session.m_ScionIntroTurret2 = GetHandle("intro_turret_2_scion");

        -- Grab the turrets.
        _Session.m_IntroTurret1 = GetHandle("turret1");
        _Session.m_IntroTurret2 = GetHandle("turret2");

        -- Stop them so they can't be commanded for now.
        Stop(_Session.m_IntroTurret1, 1);
        Stop(_Session.m_IntroTurret2, 1);

        -- If we are doing anything like RTS mode, or the intro scene is off, don't let the intro scene play.
        -- Instead, just spawn stuff normally.
        if (_Session.m_RTSModeEnabled == 1 or _Session.m_IntroCutsceneEnabled == 0) then
            -- Do not allow the intro to play.
            DisableIntro();

            -- Create the Recycler.
            BuildPlayerRecycler("Recycler");

            -- Grab the position of the Recycler for spawning more units.
            local recPos = GetPosition(_Session.m_Recycler);

            -- Create a couple of turrets.
            BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr_xm", "*vturr",
                GetPositionNear(recPos, 40.0, 60.0));
            BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr_xm", "*vturr",
                GetPositionNear(recPos, 40.0, 60.0));

            BuildCarriers();

            -- Reset the player and give them the RTS Vehicle.
            RemoveObject(_Session.m_Player);

            if (_Session.m_RTSModeEnabled == 1) then
                -- Build the RTS vehicle.
                local PlayerH = BuildObject("iv_rts_vehicle", _Session.m_PlayerTeam, GetPositionNear(recPos, 40.0, 60.0));
                SetAsUser(PlayerH, _Session.m_PlayerTeam);
                AddPilotByHandle(PlayerH);
            else
                RespawnPlayer(true);
            end
        end
    else
        if (_Session.m_RTSModeEnabled == 1) then
            -- Basically force the player into a deployed state.
            if (IsDeployed(_Session.m_Player) == false and _Session.m_TurnCounter % SecondsToTurns(0.2) == 0) then
                Deploy(_Session.m_Player);
            end
        elseif (_Session.m_IntroCutsceneEnabled == 1 and _Session.m_IntroDone == false) then
            if (_Session.m_HumanTeamRace == CHAR_RACE_ISDF) then
                ISDFIntroFunctions[_Session.m_IntroState]();

                -- Check to see that the dropship is clear.
                if (_Session.m_DropshipTakeoffCheck) then
                    if (_Session.m_Dropship1Takeoff == false) then
                        local distCheck1 = CountUnitsNearObject(_Session.m_IntroShip1, 30, _Session.m_PlayerTeam, nil);

                        if (distCheck1 == 1) then
                            -- Start the take-off sequence.
                            SetAnimation(_Session.m_IntroShip1, "takeoff", 1);

                            -- Engine sound.
                            local engineSound = StartAudio3D("dropleav.wav", _Session.m_IntroShip1);
                            SetVolume(engineSound, 0.3);

                            -- Set the timer for when we remove the dropship.
                            _Session.m_Dropship1Time = _Session.m_TurnCounter + SecondsToTurns(15);

                            -- So we don't loop.
                            _Session.m_Dropship1Takeoff = true;
                        end
                    elseif (_Session.m_Dropship1Remove == false and _Session.m_Dropship1Time < _Session.m_TurnCounter) then
                        -- Remove the Dropship.
                        RemoveObject(_Session.m_IntroShip1);

                        -- Mark this as done.
                        _Session.m_Dropship1Remove = true;
                    end

                    if (_Session.m_Dropship2Takeoff == false) then
                        local distCheck2 = CountUnitsNearObject(_Session.m_IntroShip2, 30, _Session.m_PlayerTeam, nil);

                        if (distCheck2 == 1) then
                            -- Start the take-off sequence.
                            SetAnimation(_Session.m_IntroShip2, "takeoff", 1);

                            -- Engine sound.
                            local engineSound = StartAudio3D("dropleav.wav", _Session.m_IntroShip2);
                            SetVolume(engineSound, 0.3);

                            -- Set the timer for when we remove the dropship.
                            _Session.m_Dropship2Time = _Session.m_TurnCounter + SecondsToTurns(15);

                            -- So we don't loop.
                            _Session.m_Dropship2Takeoff = true;
                        end
                    elseif (_Session.m_Dropship2Remove == false and _Session.m_Dropship2Time < _Session.m_TurnCounter) then
                        -- Remove the Dropship.
                        RemoveObject(_Session.m_IntroShip2);

                        -- Mark this as done.
                        _Session.m_Dropship2Remove = true;
                    end

                    if (_Session.m_DropshipTakeOffDialogPlayed == false and _Session.m_Dropship1Takeoff and _Session.m_Dropship2Takeoff) then
                        -- "Condor": "We are returning to base."
                        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_4.wav");

                        -- So we don't loop.
                        _Session.m_DropshipTakeOffDialogPlayed = true;
                    end

                    -- This means this method is no longer needed.
                    if (_Session.m_Dropship1Remove and _Session.m_Dropship2Remove) then
                        _Session.m_DropshipTakeoffCheck = false;
                    end
                end
            elseif (_Session.m_HumanTeamRace == CHAR_RACE_SCION) then
                ScionIntroFunctions[_Session.m_IntroState]();
            end
        end
    end

    if (_Session.m_AIController ~= nil) then
        _Session.m_AIController:Run(_Session.m_TurnCounter);
    end

    if (_Session.m_IntroDone) then
        -- Game conditions to see if either Recycler has been destroyed.
        GameConditions();

        if (#_Session.m_CarrierItemsToRemove > 0 and _Session.m_CarrierObjectCheckDelay < _Session.m_TurnCounter) then
            local condorObj = _Session.m_CarrierItemsToRemove[1];

            if (condorObj.TimeToDelete < _Session.m_TurnCounter) then
                RemoveObject(condorObj.ItemHandle);
                table.remove(_Session.m_CarrierItemsToRemove, 1);
            end

            _Session.m_CarrierObjectCheckDelay = _Session.m_TurnCounter + SecondsToTurns(1);
        end

        -- Checks to see if we have any dropships that need sending.
        if (_Session.m_HumanTeamRace == CHAR_RACE_ISDF) then
            if (#_Session.m_Condors > 0) then
                if (_Session.m_PlayerCondor == nil) then
                    _Session.m_PlayerCondor = _Session.m_Condors[1];
                else
                    if (_Session.m_PlayerCondor.ReadyToDelete == false) then
                        _Session.m_PlayerCondor:Run(_Session.m_TurnCounter);
                    else
                        table.remove(_Session.m_Condors, 1);
                        _Session.m_PlayerCondor = nil;
                    end
                end
            end
        elseif (_Session.m_HumanTeamRace == CHAR_RACE_SCION) then
            if (#_Session.m_Portals > 0) then
                if (_Session.m_PlayerPortal == nil) then
                    _Session.m_PlayerPortal = _Session.m_Portals[1];
                else
                    if (_Session.m_PlayerPortal.ReadyToDelete == false) then
                        _Session.m_PlayerPortal:Run(_Session.m_TurnCounter);
                    else
                        table.remove(_Session.m_Portals, 1);
                        _Session.m_PlayerPortal = nil;
                    end
                end
            end
        end
    end
end

function PlayerEjected(DeadObjectHandle)
    return DoEjectPilot;
end

function PlayerDied(DeadObjectHandle, bSniped)
    if (IsPerson(DeadObjectHandle) == false and bSniped == false) then
        return DoEjectPilot;
    end

    if (_Session.m_CanRespawn == 1 and IsAlive(_Session.m_Recycler)) then
        RespawnPlayer(false);
    else
        FailMission(GetTime() + 3.0);
    end

    return DLLHandled;
end

function ObjectKilled(DeadObjectHandle, KillersHandle)
    if (IsPlayer(DeadObjectHandle) == false) then
        local bWasDeadPilot = IsPerson(DeadObjectHandle);

        if (bWasDeadPilot == false) then
            return DoEjectPilot;
        end

        return DLLHandled;
    end

    return PlayerDied(DeadObjectHandle, false);
end

function ObjectSniped(DeadObjectHandle, KillersHandle)
    if (IsPlayer(DeadObjectHandle) == false) then
        return DLLHandled;
    end

    return PlayerDied(DeadObjectHandle, true);
end

function PreGetIn(cutWorld, pilotHandle, emptyCraftHandle)
    -- Apply a skin to the unit if it is a player.
    if (IsPlayer(pilotHandle)) then
        ApplySkinToHandle(GetPlayerName(pilotHandle), emptyCraftHandle, GetTeamNum(pilotHandle));
    end

    -- Run our replacement script logic.
    _VoiceManager.SwitchVehicleVoices(emptyCraftHandle, pilotHandle);

    -- Always allow the entry
    return PREGETIN_ALLOW;
end

function PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
    if (OrdnanceTeam ~= _Session.m_CompTeam) then
        if (GetTeamNum(VictimHandle) == _Session.m_CompTeam) then
            local objClass = GetClassLabel(VictimHandle);

            if (objClass == "CLASS_TURRETTANK") then
                _AIController:TurretShot(VictimHandle, _Session.m_TurnCounter);
            elseif (objClass == "CLASS_SCAVENGER" or objClass == "CLASS_SCAVENGERH") then
                _AIController:ScavengerShot(VictimHandle);
            end
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function DisableIntro()
    RemoveScionIntroUnits();
    RemoveISDFIntroUnits();
    _Session.m_IntroDone = true;
end

function RespawnPlayer(isGameStart)
    local recyclerPosition = GetPosition(_Session.m_Recycler);
    local respawnPosition = GetPositionNear(recyclerPosition, 10, 50);

    -- Prevent spawning within stuff.
    local PlayerODF = "";

    if (isGameStart) then
        PlayerODF = _Session.m_HumanTeamRace .. "vscout";
    else
        respawnPosition.y = respawnPosition.y + 50;
        PlayerODF = _Session.m_HumanTeamRace .. "spilo";
    end

    local PlayerH = BuildObject(PlayerODF, _Session.m_PlayerTeam, respawnPosition);
    SetAsUser(PlayerH, _Session.m_PlayerTeam);
    AddPilotByHandle(PlayerH);

    -- Taunt.
    if (isGameStart == false) then
        DoTaunt(TAUNTS_HumanShipDestroyed);
    end
end

function BuildStartingVehicle(aTeam, aRace, ODF1, ODF2, Where)
    local TempODF = ReplaceCharacter(1, ODF1, aRace);

    if (DoesODFExist(TempODF) == false) then
        TempODF = ReplaceCharacter(1, ODF2, aRace);
    end

    local h = BuildObject(TempODF, aTeam, Where);

    if (aTeam == _Session.m_PlayerTeam) then
        SetBestGroup(h);
    end

    return h;
end

function GameConditions()
    if (_Session.m_GameOver == false) then
        if (IsAlive(_Session.m_EnemyRecycler) == false) then
            -- Check to see if the DLL Team slot is filled first.
            local DLLHandle = GetObjectByTeamSlot(_Session.m_CompTeam, DLL_TEAM_SLOT_RECYCLER);

            if (IsAround(DLLHandle)) then
                _Session.m_EnemyRecycler = DLLHandle;
            else
                -- Taunt for game over.
                DoTaunt(TAUNTS_CPURecyDestroyed);
                SucceedMission(GetTime() + 5, "instantw.txt");
                _Session.m_GameOver = true;
            end
        elseif (IsAlive(_Session.m_Recycler) == false) then
            -- Check to see if the DLL Team slot is filled first.
            local DLLHandle = GetObjectByTeamSlot(_Session.m_StratTeam, DLL_TEAM_SLOT_RECYCLER);

            if (IsAround(DLLHandle)) then
                _Session.m_Recycler = DLLHandle;
            else
                -- Taunt for game over.
                DoTaunt(TAUNTS_HumanRecyDestroyed);
                SucceedMission(GetTime() + 5, "instantl.txt");
                _Session.m_GameOver = true;
            end
        end
    end
end

function BuildPlayerRecycler(pos)
    local customHumanRecycler = IFace_GetString("options.instant.string1");

    if (customHumanRecycler ~= nil) then
        _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, customHumanRecycler,
            "*vrecy", pos);
    else
        _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, "*vrecy", "*vrecy",
            pos);
    end

    SetScrap(_Session.m_StratTeam, 40);
end

function BuildCarriers()
    -- Grab the position of the Carrier path for spawning.
    local carrierPath = GetPosition("Carrier");
    local carrierEnemyPath = GetPosition("CarrierEnemy");

    -- Spawn Carriers for both teams.
    BuildObject(_Session.m_HumanTeamRace .. "bcarrier_xm", _Session.m_PlayerTeam,
        SetVector(carrierPath.x, 800, carrierPath.z));
    BuildObject(_Session.m_CPUTeamRace .. "bcarrier_xm", _Session.m_CompTeam,
        SetVector(carrierEnemyPath.x, 800, carrierEnemyPath.z));
end

function RemoveISDFIntroUnits()
    RemoveObject(_Session.m_IntroShip1);
    RemoveObject(_Session.m_IntroShip2);
    RemoveObject(_Session.m_IntroTurret1);
    RemoveObject(_Session.m_IntroTurret2);
end

function RemoveScionIntroUnits()
    RemoveObject(_Session.m_ScionIntroHangar);
    RemoveObject(_Session.m_ScionIntroMatriarch);
    RemoveObject(_Session.m_ScionIntroPlayer);
    RemoveObject(_Session.m_ScionIntroTurret1);
    RemoveObject(_Session.m_ScionIntroTurret2);
end

---------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- Intro Related Logic ---------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

ISDFIntroFunctions[1] = function()
    RemoveScionIntroUnits();

    SetColorFade(1, 0.5, Make_RGB(0, 0, 0, 255));
    StartEarthQuake(5);

    _Session.m_MusicOptionValue = GetVarItemInt("options.audio.music");
    IFace_SetInteger("options.audio.music", 0);

    SetAnimation(_Session.m_IntroShip2, "deploy", 1);

    _Session.m_IntroMusic = StartSoundEffect("IA_Intro.wav");
    _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(4);
    _Session.m_IntroState = _Session.m_IntroState + 1;
end

ISDFIntroFunctions[2] = function()
    if (_Session.m_SetIntroMusicVolume == false) then
        SetVolume(_Session.m_IntroMusic, _Session.m_IntroMusicVolume);
        _Session.m_SetIntroMusicVolume = true;
    end

    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_1.wav");
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(10);
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ISDFIntroFunctions[3] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(0.2);

        UpdateEarthQuake(30);

        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ISDFIntroFunctions[4] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        StopEarthQuake();

        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(4);
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ISDFIntroFunctions[5] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_2.wav");
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(6);
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ISDFIntroFunctions[6] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        SetAnimation(_Session.m_IntroShip1, "deploy", 1);

        local dropship2Vector = GetTransform(_Session.m_IntroShip2);

        BuildPlayerRecycler(dropship2Vector);

        SetPosition(_Session.m_Recycler, GetPosition("Recycler"));

        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(2.5);

        SetVerbose(_Session.m_Recycler, false);
        Goto(_Session.m_Recycler, "recycler_go", 0);
        SetVerbose(_Session.m_Recycler, true);
        Goto(_Session.m_IntroTurret1, "turret_1_go", 1);
        Goto(_Session.m_IntroTurret2, "turret_2_go", 1);

        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ISDFIntroFunctions[7] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        StartSoundEffect("dropdoor.wav", _Session.m_IntroShip1);

        _Session.m_DropshipTakeoffCheck = true;
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_3.wav");

        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ISDFIntroFunctions[8] = function()
    CheckIntroEnemiesKilled();
end

ISDFIntroFunctions[9] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        SetGroup(_Session.m_IntroTurret1, 1);
        SetGroup(_Session.m_IntroTurret2, 1);
        Defend(_Session.m_IntroTurret1, 0);
        Defend(_Session.m_IntroTurret2, 0);

        BuildCarriers();

        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Carrier_1.wav");
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ISDFIntroFunctions[10] = function()
    if (IsAudioMessageDone(_Session.m_IntroAudio)) then
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Carrier_2.wav");
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ISDFIntroFunctions[11] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        _Session.m_IntroMusicVolume = _Session.m_IntroMusicVolume - 0.02;

        SetVolume(_Session.m_IntroMusic, _Session.m_IntroMusicVolume);

        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(0.3);

        if (_Session.m_IntroMusicVolume <= 0) then
            StopAudio(_Session.m_IntroMusic);

            IFace_SetInteger("options.audio.music", _Session.m_MusicOptionValue);

            _Session.m_IntroDone = true;
        end
    end
end

ScionIntroFunctions[1] = function()
    RemoveISDFIntroUnits();

    -- Start a small earthquake.
    StartEarthQuake(1);

    -- Temp so the player can't control the intro units.
    Stop(_Session.m_ScionIntroMatriarch, 1);
    Stop(_Session.m_ScionIntroTurret1, 1);
    Stop(_Session.m_ScionIntroTurret2, 1);

    -- Attempt to mask the emitters on the portal.
    MaskEmitter(_Session.m_ScionIntroPortal, 0);

    RemoveObject(_Session.m_Player);
    SetColorFade(1, 0.5, Make_RGB(0, 0, 0, 255));
    SetAsUser(_Session.m_ScionIntroPlayer, _Session.m_PlayerTeam);

    _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(4);
    _Session.m_IntroState = _Session.m_IntroState + 1;
end

ScionIntroFunctions[2] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_1.wav");
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ScionIntroFunctions[3] = function()
    if (IsAudioMessageDone(_Session.m_IntroAudio)) then
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_2.wav");
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ScionIntroFunctions[4] = function()
    if (IsAudioMessageDone(_Session.m_IntroAudio)) then
        local mapName = GetMapTRNFilename();

        if (FindInTable(MireMaps, mapName)) then
            _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_3B.wav");
        elseif (FindInTable(BaneMaps, mapName)) then
            _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_3A.wav");
        end

        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ScionIntroFunctions[5] = function()
    if (IsAudioMessageDone(_Session.m_IntroAudio)) then
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_3.wav");
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ScionIntroFunctions[6] = function()
    if (IsAudioMessageDone(_Session.m_IntroAudio)) then
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_4.wav");
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ScionIntroFunctions[7] = function()
    StartEmitter(_Session.m_ScionIntroPortal, 1);

    _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(1);
    _Session.m_IntroState = _Session.m_IntroState + 1;
end

ScionIntroFunctions[8] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        Follow(_Session.m_ScionIntroMatriarch, _Session.m_ScionIntroPortal, 1);
        Follow(_Session.m_ScionIntroTurret1, _Session.m_ScionIntroPortal, 1);
        Follow(_Session.m_ScionIntroTurret2, _Session.m_ScionIntroPortal, 1);

        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ScionIntroFunctions[9] = function()
    if (GetDistance(_Session.m_ScionIntroMatriarch, _Session.m_ScionIntroPortal) < 25 and _Session.m_IntroMatriarchTeleported == false) then
        local recyOdf = nil;
        local customHumanRecycler = IFace_GetString("options.instant.string1");

        if (customHumanRecycler ~= nil) then
            recyOdf = ReplaceCharacter(1, customHumanRecycler, "f");
        else
            recyOdf = ReplaceCharacter(1, "vrecy", "f");
        end

        TeleportOut(_Session.m_ScionIntroMatriarch);

        _Session.m_PlayerRecycler = TeleportIn(recyOdf, _Session.m_StratTeam, "Recycler");
        SetBestGroup(_Session.m_PlayerRecycler);
        SetScrap(_Session.m_StratTeam, 40);

        _Session.m_IntroMatriarchTeleported = true;
    end

    if (GetDistance(_Session.m_ScionIntroTurret1, _Session.m_ScionIntroPortal) < 30 and _Session.m_IntroTurret1Teleported == false) then
        TeleportOut(_Session.m_ScionIntroTurret1);
        SetBestGroup(TeleportIn("fvturr_x", _Session.m_StratTeam, "Recycler"));
        _Session.m_IntroTurret1Teleported = true;
    end

    if (GetDistance(_Session.m_ScionIntroTurret2, _Session.m_ScionIntroPortal) < 30 and _Session.m_IntroTurret2Teleported == false) then
        TeleportOut(_Session.m_ScionIntroTurret2);
        SetBestGroup(TeleportIn("fvturr_x", _Session.m_StratTeam, "Recycler"));
        _Session.m_IntroTurret2Teleported = true;
    end

    if (_Session.m_IntroMatriarchTeleported == true and _Session.m_IntroTurret1Teleported == true and _Session.m_IntroTurret2Teleported == true) then
        _Session.m_IntroForcePlayerTeleportDelay = _Session.m_TurnCounter + SecondsToTurns(25);
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ScionIntroFunctions[10] = function()
    -- Teleport the player to the Recycler.
    if (_Session.m_IntroForcePlayerTeleportDelay < _Session.m_TurnCounter or GetDistance(_Session.m_Player, _Session.m_ScionIntroPortal) < 25) then
        Teleport(_Session.m_Player, "Recycler", 50);

        -- Remove the intro stuff.
        RemoveObject(_Session.m_ScionIntroHangar);

        -- Stop the earthquake.
        StopEarthQuake();

        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ScionIntroFunctions[11] = function()
    -- Spawn and check if the enemies are dead.
    CheckIntroEnemiesKilled();
end

ScionIntroFunctions[12] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        BuildCarriers();

        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Carrier_1.wav");
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

ScionIntroFunctions[13] = function()
    if (IsAudioMessageDone(_Session.m_IntroAudio)) then
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Carrier_2.wav");
        _Session.m_IntroDone = true;
    end
end

function CheckIntroEnemiesKilled()
    if (_Session.m_IntroEnemiesSpawned == false) then
        for i = 1, _Session.m_Difficulty + 1 do
            local enemy = BuildObject(_Session.m_CPUTeamRace .. "vscout_c", _Session.m_CompTeam, "intro_attacker_" .. i);

            SetSkill(enemy, 3);

            if (i == 1) then
                _Session.m_IntroEnemy1 = enemy;
                Attack(enemy, _Session.m_Player, 1);
            elseif (i == 2) then
                _Session.m_IntroEnemy2 = enemy;
                Attack(enemy, _Session.m_Recycler, 1);
            elseif (i == 3) then
                _Session.m_IntroEnemy3 = enemy;
                Attack(enemy, _Session.m_Player, 1);
            end
        end

        _Session.m_IntroEnemiesSpawned = true;
    end

    local check1 = IsAliveAndEnemy(_Session.m_IntroEnemy1, _Session.m_CompTeam);
    local check2 = IsAliveAndEnemy(_Session.m_IntroEnemy2, _Session.m_CompTeam);
    local check3 = IsAliveAndEnemy(_Session.m_IntroEnemy3, _Session.m_CompTeam);

    if (check1 == false and check2 == false and check3 == false) then
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(3);
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end
