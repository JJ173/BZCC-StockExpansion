-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))();

-- Required Globals.
require("_GlobalVariables");

-- Required helper functions.
require("_HelperFunctions");

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

    m_DropshipTakeOffDialogPlayed = false,

    m_DropshipTakeoffCheck = false,
    m_Dropship1Takeoff = false,
    m_Dropship1Remove = false,
    m_Dropship1Time = 0,

    m_Dropship2Takeoff = false,
    m_Dropship2Remove = false,
    m_Dropship2Time = 0,

    m_IntroDone = false,
    m_StartDone = false,
    m_CanRespawn = false,
    m_PastAIP0 = false,
    m_LateGame = false,
    m_HaveArmory = false,
    m_GameOver = false,
    m_IntroCutsceneEnabled = false,
    m_AICommanderEnabled = false,
    m_RTSModeEnabled = false,
}

-- Functions Table
local IntroFunctions = {};

-- Debug only.
local debug = false;

---------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- Utility Functions ---------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function ReplaceCharacter(pos, str, r)
    return str:sub(1, pos - 1) .. r .. str:sub(pos + 1)
end

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

    PreloadODF("ivrecy");
    PreloadODF("fvrecy");
    PreloadODF("ivrecycpu");
    PreloadODF("fvrecycpu");
end

function Save()
    return _Session;
end

function Load(Session)
    _Session = Session;
end

function AddObject(handle)
    local ODFName = GetCfg(handle);
    local ObjClass = GetClassLabel(handle);
    local teamNum = GetTeamNum(handle);
    local isRecyclerVehicle = (ObjClass == "CLASS_RECYCLERVEHICLE" or ObjClass == "CLASS_RECYCLERVEHICLEH");

    if (teamNum == _Session.m_CompTeam) then
        if (isRecyclerVehicle) then
            _Session.m_EnemyRecycler = handle;
        end

        SetSkill(handle, _Session.m_Difficulty + 1);

        if (ObjClass == "CLASS_ARMORY") then
            _Session.m_HaveArmory = true;
        end

        if (_Session.m_HaveArmory) then
            if (string.sub(ODFName, 1, 6) == "ivtank") then
                GiveWeapon(handle, "gspstab_c");
            elseif (string.sub(ODFName, 1, 6) == "fvtank") then
                GiveWeapon(handle, "garc_c");
            end

            if (string.sub(ODFName, 1, 2) == "fv") then
                local randomNumber = GetRandomFloat(1.0);

                if (randomNumber < 0.3) then
                    GiveWeapon(handle, "gshield");
                elseif (randomNumber < 0.6) then
                    GiveWeapon(handle, "gabsorb");
                elseif (randomNumber < 0.9) then
                    GiveWeapon(handle, "gdeflect");
                end
            end
        end
    elseif (teamNum == _Session.m_StratTeam) then
        if (isRecyclerVehicle) then
            _Session.m_Recycler = handle;
        end

        if (_Session.m_MyGoal == 0) then
            if (ObjClass == "CLASS_WINGMAN" or ObjClass == "CLASS_MORPHTANK" or ObjClass == "CLASS_ASSAULTTANK" or ObjClass == "CLASS_SERVICE" or ObjClass == "CLASS_WALKER") then
                SetTeamNum(handle, _Session.m_PlayerTeam);
                SetBestGroup(handle);
            end
        end

        if (ObjClass == "CLASS_ARTILLERY" or ObjClass == "CLASS_BOMBER") then
            if (_Session.m_LateGame == false) then
                _Session.m_LateGame = true;
                SetCPUAIPlan(AIPTypeL);
            end
        end

        SetSkill(handle, 3 - _Session.m_Difficulty);

        if (ObjClass == "CLASS_RECYCLER") then
            if (_Session.m_PastAIP0 == false) then
                _Session.m_PastAIP0 = true;

                local stratChoice = _Session.m_TurnCounter % 2;

                if (_Session.m_CPUTeamRace == RACE_SCION) then
                    if (stratChoice == 0) then
                        SetCPUAIPlan(AIPType1);
                    elseif (stratChoice == 1) then
                        SetCPUAIPlan(AIPType3);
                    elseif (stratChoice == 2) then
                        SetCPUAIPlan(AIPType2);
                    end
                else
                    local modifiedStratChoice = stratChoice % 2;

                    if (modifiedStratChoice == 0) then
                        SetCPUAIPlan(AIPType1);
                    elseif (modifiedStratChoice == 1) then
                        SetCPUAIPlan(AIPType3);
                    end
                end
            end
        end
    elseif (_Session.m_AwareV13 == 0 and teamNum == _Session.m_PlayerTeam) then
        -- This block should never happen in normal IA mode, but if for some reason the player has a Scavenger in Pilot mode,
        -- we should switch the extractor to the right team when it's deployed to prevent breaking.
        if (ObjClass == "CLASS_EXTRACTOR") then
            SetTeamNum(handle, _Session.m_StratTeam);
        end
    end

    if (_Session.m_PastAIP0 == false and (_Session.m_TurnCounter > (180 * _Session.m_GameTPS))) then
        _Session.m_PastAIP0 = true;

        local stratChoice = _Session.m_TurnCounter % 2;

        if (_Session.m_CPUTeamRace == RACE_SCION) then
            if (stratChoice == 0) then
                SetCPUAIPlan(AIPType1);
            elseif (stratChoice == 1) then
                SetCPUAIPlan(AIPType3);
            elseif (stratChoice == 2) then
                SetCPUAIPlan(AIPType2);
            end
        else
            local modifiedStratChoice = stratChoice % 2;

            if (modifiedStratChoice == 0) then
                SetCPUAIPlan(AIPType1);
            elseif (modifiedStratChoice == 1) then
                SetCPUAIPlan(AIPType3);
            end
        end
    end
end

function DeleteObject(handle)
    local ObjClass = GetClassLabel(handle);

    if (GetTeamNum(handle) == _Session.m_CompTeam) then
        if (ObjClass == "CLASS_ARMORY") then
            _Session.m_HaveArmory = false;
        end
    end
end

function Start()
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- Grab the TPS.
    _Session.m_GameTPS = GetTPS();

    _Session.m_StartDone = false;
    _Session.m_GameOver = false;
    _Session.m_CompTeam = 6;
    _Session.m_StratTeam = 1;

    _Session.m_TurnCounter = 0;

    _Session.m_LateGame = false;
    _Session.m_HaveArmory = false;

    DoTaunt(TAUNTS_GameStart);

    if (debug) then
        BuildObject("ibrecy_x", 0, "RecyclerEnemy");
    end
end

function Update()
    if (debug) then
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

        _Session.m_CanRespawn = IFace_GetInteger("options.instant.bool0");
        _Session.m_IntroCutsceneEnabled = IFace_GetInteger("options.instant.bool1");
        _Session.m_AICommanderEnabled = IFace_GetInteger("options.instant.bool2");
        _Session.m_RTSModeEnabled = IFace_GetInteger("options.instant.bool3");

        -- Set our name for the CPU.
        SetTauntCPUTeamName("CPU");

        _Session.m_CustomAIPStr = IFace_GetString("options.instant.string0");
        _Session.m_CPUTeamRace = string.char(IFace_GetInteger("options.instant.hisrace"));
        _Session.m_HumanTeamRace = string.char(IFace_GetInteger("options.instant.myrace"));
        _Session.m_Difficulty = GetInstantDifficulty();

        SetupExtraVehicles();

        local customCPURecycler = IFace_GetString("options.instant.string2");

        if (customCPURecycler ~= nil) then
            _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, customCPURecycler, "*vrecy", "RecyclerEnemy");
        else
            _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vrecy_x", "*vrecy", "RecyclerEnemy");
        end

        local RecPos = GetPosition(_Session.m_EnemyRecycler);

        -- Spawn CPU vehicles.
        BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vscav_x", "*vscav_x", GetPositionNear(RecPos, 20.0, 40.0));
        BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr_x", "*vturr_x", GetPositionNear(RecPos, 20.0, 40.0));
        BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr_x", "*vturr_x", GetPositionNear(RecPos, 20.0, 40.0));

        if (_Session.m_PastAIP0 == false) then
            SetCPUAIPlan(AIPType0);
        end

        local cRACE_ISDF = string.char(RACE_ISDF);
        local cRACE_SCION = string.char(RACE_SCION);

        -- Checks for team colour differences.
        if (_Session.m_CPUTeamRace == cRACE_ISDF and _Session.m_HumanTeamRace == cRACE_ISDF) then
            SetTeamColor(_Session.m_CompTeam, 0, 127, 255);
        end

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
            BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr", "*vturr", GetPositionNear(recPos, 20.0, 40.0));
            BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr", "*vturr", GetPositionNear(recPos, 20.0, 40.0));

            -- Reset the player and give them the RTS Vehicle.
            RemoveObject(_Session.m_Player);

            SetScrap(_Session.m_CompTeam, 40);

            if (_Session.m_RTSModeEnabled == 1) then
                -- Build the RTS vehicle.
                local PlayerH = BuildObject("iv_rts_vehicle", _Session.m_PlayerTeam, GetPositionNear(recPos, 20.0, 40.0));
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

    -- Keep track of games.
    if (_Session.m_IntroDone) then
        GameConditions();
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

        if (bWasDeadPilot) then
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

function SetCPUAIPlan(type)
    if (type < AIPType0 or type >= MAX_AIP_TYPE) then
        type = AIPType3;
    end

    local AIPFile;
    local AIPString;

    if (_Session.m_CustomAIPStr ~= nil) then
        AIPString = _Session.m_CustomAIPStr;
    else
        AIPString = StockAIPNameBase;
    end

    -- First pass, try to find an AIP that is designed to use Provides for enemy team, thus it only cares about CPU Race. This makes adding races much easier.
    AIPFile = AIPString .. _Session.m_CPUTeamRace .. string.sub(AIPTypeExtensions, type, type);

    -- Fallback to old method if none exists.
    if (DoesFileExist(AIPFile) == false) then
        AIPFile = AIPString .. _Session.m_CPUTeamRace .. _Session.m_HumanTeamRace .. string.sub(AIPTypeExtensions, type, type);
    end

    SetAIP(AIPFile .. '.aip', _Session.m_CompTeam);

    if (_Session.m_PastAIP0) then
        DoTaunt(TAUNTS_Random);
    end
end

function SetupExtraVehicles()
    local AIPaths = GetAiPaths();

    for key, value in pairs(AIPaths) do
        local normalizedString = string.lower(value);

        -- Check if the path starts with MPI and then process it.
        if (string.sub(normalizedString, 1, 3) == "mpi") then
            -- Used for ODFs.
            local ODF1;
            local ODF2;

            -- Find the index of the first underscore.
            local underscore = string.find(normalizedString, "_");

            -- Misformat! No _ found! Bail!
            if (underscore == nil) then
                return;
            end

            local underscore2 = string.find(normalizedString, "_", underscore + 1);

            if (underscore2 == nil) then
                ODF1 = string.sub(normalizedString, underscore + 1);
            else
                ODF1 = string.sub(normalizedString, underscore + 1, underscore2 - 1);
                ODF2 = string.sub(normalizedString, underscore2 + 1);
            end

            -- Check the first 4 letters for what team this should be spawned for.
            local teamDiscrim = string.sub(normalizedString, 1, 4);

            if (teamDiscrim == "mpic") then
                if (ODF1 ~= nil) then
                    ODF1 = ReplaceCharacter(1, ODF1, _Session.m_CPUTeamRace);
                    BuildObject(ODF1, _Session.m_CompTeam, normalizedString);
                elseif (ODF2 ~= nil) then
                    ODF2 = ReplaceCharacter(1, ODF2, _Session.m_CPUTeamRace);
                    BuildObject(ODF2, _Session.m_CompTeam, normalizedString);
                end
            elseif (teamDiscrim == "mpih") then
                if (ODF1 ~= nil) then
                    ODF1 = ReplaceCharacter(1, ODF1, _Session.m_HumanTeamRace);
                    SetBestGroup(BuildObject(ODF1, _Session.m_StratTeam, normalizedString));
                elseif (ODF2 ~= nil) then
                    ODF2 = ReplaceCharacter(1, ODF2, _Session.m_HumanTeamRace);
                    SetBestGroup(BuildObject(ODF2, _Session.m_StratTeam, normalizedString));
                end
            end
        end
    end
end

function BuildPlayerRecycler(pos)
    local customHumanRecycler = IFace_GetString("options.instant.string1");

    if (customHumanRecycler ~= nil) then
        _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, customHumanRecycler, "*vrecy", pos);
    else
        _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, "*vrecy", "*vrecy", pos);
    end

    SetScrap(_Session.m_StratTeam, 40);
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
            local enemy = BuildObject(_Session.m_CPUTeamRace .. "vscout_x", _Session.m_CompTeam, "intro_attacker_" .. i);

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
