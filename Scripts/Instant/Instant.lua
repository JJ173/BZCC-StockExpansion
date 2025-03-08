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

    m_IntroState = 1,
    m_IntroDelay = 0,
    m_IntroAudio = 0,
    m_IntroMusic = 0,
    m_IntroMusicVolume = 1,

    m_IntroEnemiesSpawned = false,
    m_IntroEnemy1 = nil,
    m_IntroEnemy2 = nil,
    m_IntroEnemy3 = nil,

    m_CustomAIPStr = nil,

    m_EnemyRecycler = nil,
    m_Recycler = nil,
    m_Player = nil,

    m_IntroShip1 = nil,
    m_IntroShip2 = nil,

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

    m_CarrierObjectCheckDelay = 0
}

-- Potential Supporter Names for CPU.
local _CPUNames =
{
    "SIR BRAMBLEY",
    "GrizzlyOne95",
    "BlackDragon",
    "Spymaster",
    "Autarch Katherlyn",
    "blue_banana",
    "Zorn",
    "Gravey",
    "VTrider",
    "Ultraken",
    "Darkvale",
    "Econchump",
    "Sev"
}

-- Functions Table
local IntroFunctions = {};

-- Debug only.
local debug = true;
local debug_base = false;
local debug_base_built = false;
local debug_stop_script = true;

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
    "ivpdrop_x"
}

-- Audio to Preload.
local PreloadAudios = {
    "IA_Intro.wav",
    "IA_Pilot_1.wav",
    "IA_Pilot_2.wav",
    "IA_Pilot_3.wav",
    "IA_Carrier_1.wav",
    "IA_Carrier_2.wav",
    "dropdoor.wav"
}

-- Debugging. This will control the enemy base for testing layouts.
local ISDFBaseLayout =
{
    { "ivrecy_c",       "RecyclerEnemy" },
    { "ibfact_c",       "i_Factory" },

    { "ibpgen_c3",      "i_Power_1" },
    { "ibpgen_c3",      "i_Power_2" },
    { "ibpgen_c3",      "i_Power_3" },

    { "ibcbun_c",       "i_Bunker" },
    { "ibcbun_c",       "i_Base_Bunker_1" },
    { "ibcbun_c",       "i_Base_Bunker_2" },
    { "ibcbun_c",       "i_Base_Bunker_3" },

    { "ibsbay_c",       "i_ServiceBay" },
    { "ibarmo_c",       "i_Armory" },
    { "ibtcen_c",       "i_Tech" },
    { "ibtrain_c",      "i_Training" },
    { "ibbomb_c",       "i_BomberBay" },
    { "iblandingpad_c", "i_LandingPad" },

    { "ibplate_c",      "i_Plate_1" },
    { "ibplate_c",      "i_Plate_2" },
    { "ibplate_c",      "i_Plate_3" },
    { "ibplate_c",      "i_Plate_4" },
    { "ibplate_c",      "i_Plate_5" },
    { "ibplate_c",      "i_Plate_6" },
    { "ibplate_c",      "i_Plate_7" },
    { "ibplate_c",      "i_Plate_8" },

    { "ibgtow_c",       "i_GunTower_1" },
    { "ibgtow_c",       "i_GunTower_2" },
    { "ibgtow_c",       "i_GunTower_3" },
    { "ibgtow_c",       "i_GunTower_4" },

    { "ibhrtow_b_c",    "i_Base_AntiAir_1" },
    { "ibhrtow_b_c",    "i_Base_AntiAir_2" },

    { "ibatow_c_a2",    "i_Base_AssaultTower_1" },
    { "ibatow_c_a2",    "i_Base_AssaultTower_2" },

    { "ibartl_c_b",     "i_Base_Artillery_1" },
    { "ibartl_c_b",     "i_Base_Artillery_2" },

    { "ibcbun_c",       "i_Field_Bunker_1" },
    { "ibcbun_c",       "i_Field_Bunker_2" },

    { "ibgtow_c",       "i_Field_GunTower_1" },
    { "ibgtow_c",       "i_Field_GunTower_2" },

    { "ibatow_c_b2",    "i_Field_AssualtTower_1_A" },
    { "ibatow_c_b2",    "i_Field_AssualtTower_1_B" },
    { "ibatow_c_b2",    "i_Field_AssualtTower_2_A" },
    { "ibatow_c_b2",    "i_Field_AssualtTower_2_B" },

    { "ibrtow_b_c",     "i_Field_RocketTower_1" },
    { "ibrtow_b_c",     "i_Field_RocketTower_2" },

    { "ibsbay_c_a2",    "i_Assault_Depot" }
}

local ScionBaseLayout =
{
    { "fvrecy_c",   "RecyclerEnemy" },

    { "fbforg_c",   "F_Forge" },
    { "fbover_c",   "F_Overseer" },
    { "fbdowe_c",   "F_Dower" },
    { "fbstro_c",   "F_Stronghold" },

    { "fbjamm_c",   "F_BaseJammer_1" },
    { "fbjamm_c",   "F_BaseJammer_2" },

    { "fbspir_c",   "F_BaseSpire_1" },
    { "fbspir_c",   "F_BaseSpire_2" },
    { "fbspir_c",   "F_BaseSpire_3" },

    { "fbrspir_c",  "F_Base_AntiAir_1" },
    { "fbrspir_c",  "F_Base_AntiAir_2" },
    { "fbrspir_c",  "F_Base_AntiAir_3" },

    { "fbartl_c_b", "F_Base_Artillery_1" },
    { "fbartl_c_b", "F_Base_Artillery_2" },

    { "fbaspir_c",  "F_Base_AssaultSpire_1" },
    { "fbaspir_c",  "F_Base_AssaultSpire_2" },
    { "fbaspir_c",  "F_Base_AssaultSpire_3" },

    { "fbaspir_c",  "F_Field_AssaultSpire_1" },
    { "fbaspir_c",  "F_Field_AssaultSpire_2" },
    { "fbaspir_c",  "F_Field_AssaultSpire_3" },
    { "fbaspir_c",  "F_Field_AssaultSpire_4" },

    { "fbrspir_c",  "F_Field_RocketTower_1" },
    { "fbrspir_c",  "F_Field_RocketTower_2" },
    { "fbrspir_c",  "F_Field_RocketTower_3" }
}

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function InitialSetup()
    -- This is to stop music for the intro.
    AllowRandomTracks(false);

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
        -- Grab the distance between this pool and the enemy position.
        local dist = GetDistance(handle, "RecyclerEnemy");
        -- Grab the position so we can store it in the model.
        local pos = GetPosition(handle);
        -- Create a new model for this pool.
        local newPoolModel = _Pool:New(handle, pos, dist);
        -- Grab the position vector and store it.
        _Session.m_Pools[#_Session.m_Pools + 1] = newPoolModel;
    end

    -- Max out skills.
    SetSkill(handle, 3);

    if (teamNum == _Session.m_CompTeam) then
        if (isRecyclerVehicle) then
            _Session.m_EnemyRecycler = handle;
        end


        if (objCfg == _Session.m_CPUTeamRace .. "blandingpad_xm") then
            _Session.m_CPULandingPad = handle;
        end

        -- Add the objects to the AI Controller.
        if (_Session.m_AIController ~= nil) then
            _Session.m_AIController:AddObject(handle, classLabel, objCfg, objBase, _Session.m_TurnCounter);
        end
    elseif (teamNum == _Session.m_StratTeam) then
        if (isRecyclerVehicle) then
            _Session.m_Recycler = handle;
        end

        if (objCfg == _Session.m_HumanTeamRace .. "blandingpad_xm") then
            _Session.m_PlayerLandingPad = handle;
        end

        if (objBase == "TurretDropship" or objBase == "LightDropship" or objBase == "ScavengerDropship" or objBase == "ScrapDropship") then
            -- Create an object to track the time of deletion.
            local dropshipRequestItem =
            {
                ItemHandle = handle,
                TimeToDelete = _Session.m_TurnCounter + SecondsToTurns(600),
            };

            -- Add this to the queue.
            _Session.m_CarrierItemsToRemove[#_Session.m_CarrierItemsToRemove + 1] = dropshipRequestItem;

            local condorModel;

            if (objBase == "ScrapDropship") then
                condorModel = _Condor:New(handle, teamNum, objBase, _Session.m_PlayerLandingPad, 2);
            else
                condorModel = _Condor:New(handle, teamNum, objBase, _Session.m_PlayerLandingPad, 3);
            end

            -- For deletion later on.
            if (condorModel ~= nil) then
                _Session.m_Condors[#_Session.m_Condors + 1] = condorModel;
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

            -- To deploy the CPU Recycler so I can see where the base will face.
            SetAIP('debug.aip', 0);

            -- So we don't spawn infinite bases.
            debug_base_built = true;
        end

        return;
    end

    -- Subtitles.
    _Subtitles.Run();

    -- Keep track of our player.
    _Session.m_Player = GetPlayerHandle(1);

    -- Keep track of our turn counter.
    _Session.m_TurnCounter = _Session.m_TurnCounter + 1;

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

        local cRACE_ISDF = string.char(RACE_ISDF);
        local cRACE_SCION = string.char(RACE_SCION);

        -- Checks for team colour differences.
        if (_Session.m_CPUTeamRace == cRACE_ISDF and _Session.m_HumanTeamRace == cRACE_ISDF) then
            SetTeamColor(_Session.m_CompTeam, 0, 127, 255); -- Blue like in the campaign.
        elseif (_Session.m_CPUTeamRace == cRACE_SCION and _Session.m_HumanTeamRace == cRACE_SCION) then
            SetTeamColor(_Session.m_CompTeam, 85, 255, 85); -- Green (Rebels) like in the campaign.
        end

        -- Pick a random name for the CPU.
        local chosenCPUName = _CPUNames[math.ceil(GetRandomInt(1, #_CPUNames))];

        -- Set the CPU Taunt Name.
        SetTauntCPUTeamName(chosenCPUName, _Session.m_TurnCounter);

        -- Create the CPU team model to keep track of what's in the world.
        _Session.m_AIController = _AIController:New(_Session.m_CompTeam, _Session.m_CPUTeamRace, _Session.m_Pools,
            chosenCPUName);

        -- Setup the AI Controller.
        _Session.m_AIController:Setup(_Session.m_CompTeam);

        -- Random taunt from the AI on game start.
        DoTaunt(TAUNTS_GameStart);

        -- Grab dropship handles for the intro.
        _Session.m_IntroShip1 = GetHandle("intro_drop_1");
        _Session.m_IntroShip2 = GetHandle("intro_drop_2");

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

            -- Remove the dropships.
            RemoveObject(_Session.m_IntroShip1);
            RemoveObject(_Session.m_IntroShip2);

            RemoveObject(_Session.m_IntroTurret1);
            RemoveObject(_Session.m_IntroTurret2);

            -- Create the Recycler.
            BuildPlayerRecycler("Recycler");

            -- Grab the position of the Recycler for spawning more units.
            local recPos = GetPosition(_Session.m_Recycler);

            -- Create a couple of turrets.
            BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr_x", "*vturr",
                GetPositionNear(recPos, 40.0, 60.0));
            BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr_x", "*vturr",
                GetPositionNear(recPos, 40.0, 60.0));

            -- Grab the position of the Carrier path for spawning.
            local carrierPath = GetPosition("Carrier");
            local carrierEnemyPath = GetPosition("CarrierEnemy");

            -- Spawn Carriers for both teams.
            BuildObject(_Session.m_HumanTeamRace .. "bcarrier_xm", _Session.m_PlayerTeam,
                SetVector(carrierPath.x, 800, carrierPath.z));
            BuildObject(_Session.m_CPUTeamRace .. "bcarrier_xm", _Session.m_CompTeam,
                SetVector(carrierEnemyPath.x, 800, carrierEnemyPath.z));

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
    end

    if (_Session.m_StartDone) then
        if (_Session.m_RTSModeEnabled == 1) then
            -- Basically force the player into a deployed state.
            if (IsDeployed(_Session.m_Player) == false and _Session.m_TurnCounter % SecondsToTurns(0.2) == 0) then
                Deploy(_Session.m_Player);
            end
        elseif (_Session.m_IntroCutsceneEnabled == 1 and _Session.m_IntroDone == false) then
            IntroFunctions[_Session.m_IntroState]();

            -- Check to see that the dropship is clear.
            if (_Session.m_DropshipTakeoffCheck) then
                if (_Session.m_Dropship1Takeoff == false) then
                    local distCheck1 = CountUnitsNearObject(_Session.m_IntroShip1, 30, _Session.m_PlayerTeam, nil);

                    if (distCheck1 == 1) then
                        -- Start the take-off sequence.
                        SetAnimation(_Session.m_IntroShip1, "takeoff", 1);

                        -- Engine sound.
                        StartSoundEffect("dropleav.wav", _Session.m_IntroShip1);

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
                        StartSoundEffect("dropleav.wav", _Session.m_IntroShip2);

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
                    _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_4.wav", false);

                    -- So we don't loop.
                    _Session.m_DropshipTakeOffDialogPlayed = true;
                end

                -- This means this method is no longer needed.
                if (_Session.m_Dropship1Remove and _Session.m_Dropship2Remove) then
                    _Session.m_DropshipTakeoffCheck = false;
                end
            end
        end
    end

    if (_Session.m_IntroDone) then
        -- Game conditions to see if either Recycler has been destroyed.
        GameConditions();

        -- Checks to see if we have any dropships that need sending.
        if (#_Session.m_CarrierItemsToRemove > 0 and _Session.m_CarrierObjectCheckDelay < _Session.m_TurnCounter) then
            CarrierCleaner();
        end

        -- This will take care of the dropships landing on the map.
        if (#_Session.m_Condors > 0) then
            for i = 1, #_Session.m_Condors do
                local condor = _Session.m_Condors[i];

                -- If it's not nil, run the logic.
                if (condor ~= nil) then
                    if (condor.ReadyToDelete == false) then
                        condor:Run(_Session.m_TurnCounter);
                    else
                        _Session.m_Condors[i] = nil;
                    end
                end
            end
        end

        -- Run the AI Controller instance for the CPU team.
        _Session.m_AIController:Run(_Session.m_TurnCounter);
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

-- function PreGetIn(cutWorld, pilotHandle, emptyCraftHandle)
--     if (IsPlayer(pilotHandle)) then
--         -- Check their name.
--         local name = GetPlayerName(pilotHandle);

--         -- Just for testing.
--         print(name);

--         -- Apply the skin to the unit.
--         ApplySkinToHandle(name, emptyCraftHandle);
--     end

--     return PREGETIN_ALLOW;
-- end

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

---------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- Carrier Brain Logic ---------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
function CarrierCleaner()
    -- Check all objects that are in the Carrier Object table, if their deletion time is over the session time, delete them.
    for i = 1, #_Session.m_CarrierItemsToRemove do
        local condorObj = _Session.m_CarrierItemsToRemove[i];

        -- Check the time.
        if (condorObj.TimeToDelete <= _Session.m_TurnCounter) then
            -- Clean-up.
            RemoveObject(condorObj.ItemHandle);

            -- Remove it from the table so it's no longer valid.
            _Session.m_CarrierItemsToRemove[i] = nil;
        end
    end

    -- Set a small timer to delay this function so we don't run each framae.
    _Session.m_CarrierObjectCheckDelay = _Session.m_TurnCounter + SecondsToTurns(1);
end

---------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- Intro Related Logic ---------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

IntroFunctions[1] = function()
    -- Stop the music before we play the new intro music.
    _Session.m_MusicOptionValue = GetVarItemInt("options.audio.music");
    IFace_SetInteger("options.audio.music", 0);

    -- Start our Earthquake.
    StartEarthQuake(1);

    -- This dropship for the Recycler can already be open.
    SetAnimation(_Session.m_IntroShip2, "deploy", 1);

    -- Start the music.
    _Session.m_IntroMusic = StartSoundEffect("IA_Intro.wav");

    -- Intro sequence.
    SetColorFade(1, 0.5, Make_RGB(0, 0, 0, 255));

    -- Tiny delay before the next part.
    _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(4);

    -- Advance the mission state...
    _Session.m_IntroState = _Session.m_IntroState + 1;
end

IntroFunctions[2] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        -- "Condor": "We are approaching the dropzone..."
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_1.wav", false);

        -- Wait 4 seconds.
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(10);

        -- Advance the mission state...
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

IntroFunctions[3] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        -- Wait 0.4 seconds.
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(0.2);

        -- "Hit the ground".
        UpdateEarthQuake(30);

        -- Advance the mission state...
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

IntroFunctions[4] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        -- Stop the Earthquake.
        StopEarthQuake();

        -- Wait 3 seconds.
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(4);

        -- Advance the mission state...
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

IntroFunctions[5] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        -- "Condor": "Wait for the green light..."
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_2.wav", false);

        -- Wait 4 seconds.
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(5);

        -- Advance the mission state...
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

IntroFunctions[6] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        -- Start the animation.
        SetAnimation(_Session.m_IntroShip1, "deploy", 1);

        -- Dropship 2 matrix.
        local dropship2Vector = GetTransform(_Session.m_IntroShip2);

        -- Build the Recycler, make it go to where it should.
        BuildPlayerRecycler(dropship2Vector);

        -- So it appears like it's driving from the dropship.
        SetPosition(_Session.m_Recycler, GetPosition("Recycler"));

        -- Delay for the sound.
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(2.5);

        -- Move the Recycler away from the dropship.
        Goto(_Session.m_Recycler, "recycler_go", 0);

        -- Get the turrets to move off the ship.
        Goto(_Session.m_IntroTurret1, "turret_1_go", 1);
        Goto(_Session.m_IntroTurret2, "turret_2_go", 1);

        -- Advance the mission state...
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

IntroFunctions[7] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        -- Open the door with sound.
        StartSoundEffect("dropdoor.wav", _Session.m_IntroShip1);

        -- Enable checks for dropship take-off.
        _Session.m_DropshipTakeoffCheck = true;

        -- Pilot tells the crew to go.
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_3.wav", false);

        -- Advance the mission state...
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

IntroFunctions[8] = function()
    if (_Session.m_IntroEnemiesSpawned == false) then
        -- Difficulty Check
        for i = 1, _Session.m_Difficulty + 1 do
            local enemy = BuildObject(_Session.m_CPUTeamRace .. "vscout_c", _Session.m_CompTeam, "intro_attacker_" .. i);

            -- So they don't retreat.
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

        -- So we don't loop spawn,
        _Session.m_IntroEnemiesSpawned = true;
    end

    -- Check if they are alive.
    local check1 = IsAliveAndEnemy(_Session.m_IntroEnemy1, _Session.m_CompTeam);
    local check2 = IsAliveAndEnemy(_Session.m_IntroEnemy2, _Session.m_CompTeam);
    local check3 = IsAliveAndEnemy(_Session.m_IntroEnemy3, _Session.m_CompTeam);

    -- Intro is done.
    if (check1 == false and check2 == false and check3 == false) then
        -- Small delay before audio from Sky One.
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(3);

        -- Advance the mission state...
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

IntroFunctions[9] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        -- Sky One "Commander this is Sky One..."
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Carrier_1.wav", false);

        -- Advance the mission state...
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

IntroFunctions[10] = function()
    if (IsAudioMessageDone(_Session.m_IntroAudio)) then
        -- Sky One "Commander this is Sky One..."
        _Session.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Carrier_2.wav", false);

        -- Advance the mission state...
        _Session.m_IntroState = _Session.m_IntroState + 1;
    end
end

IntroFunctions[11] = function()
    if (_Session.m_IntroDelay < _Session.m_TurnCounter) then
        -- Decrease the volume of the sound effect.
        _Session.m_IntroMusicVolume = _Session.m_IntroMusicVolume - 0.02;

        -- This adjusts the volume of the music.
        SetVolume(_Session.m_IntroMusic, _Session.m_IntroMusicVolume, false);

        -- Fade out slowly.
        _Session.m_IntroDelay = _Session.m_TurnCounter + SecondsToTurns(0.3);

        if (_Session.m_IntroMusicVolume <= 0) then
            StopAudio(_Session.m_IntroMusic);

            -- Restore normal options.
            IFace_SetInteger("options.audio.music", _Session.m_MusicOptionValue);

            -- Intro is done.
            _Session.m_IntroDone = true;
        end
    end
end
