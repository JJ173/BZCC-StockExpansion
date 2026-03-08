-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()

-- Required Globals.
require("_GlobalVariables")

-- Required helper functions.
require("_HelperFunctions")

-- Database.
local _BZCCDatabase = require("_BZCCDatabase")

-- Managers
local _AnimalManager = require("_AnimalManager")
local _CarrierManager = require("_CarrierManager")
local _CPUManager = require("_CPUManager")
local _TauntManager = require("_TauntManager")

-- Utilities
local _SaveLoad = require("_SaveLoad")
local _DLLUtils = require("_DLLUtils")
local _Multiplayer = require("_Multiplayer")

-- Subtitles
local _Subtitles = require("_Subtitles")

InstantCommon = {
    m_GameTPS                       = GetTPS(),

    m_CPUTeamRace                   = '',
    m_HumanTeamRace                 = '',

    m_CPUTeamObj                    = nil,

    -- Keep track of player count.
    m_PlayerCount                   = 0,
    m_TeamIsSetUp                   = { false, false, false, false },
    m_TeamPos                       = {},

    -- This is constantly 1.
    m_PlayerTeam                    = 1,
    -- This may change if 1.2 features "Like Pilot" are enabled.
    -- If 1.2 is enabled, m_StratTeam will be set to 3.
    m_StratTeam                     = 1,
    m_CompTeam                      = 6,
    m_TurnCounter                   = 0,
    m_Difficulty                    = 0,

    m_CPUScrapDelay                 = 0,
    m_CPUScrapAmount                = 0,
    m_NextCPUScrapTime              = 0,
    m_VSRTauntEasterEggTime         = 0,

    m_IntroForcePlayerTeleportDelay = 0,
    m_IntroState                    = 1,
    m_IntroDelay                    = 0,
    m_IntroAudio                    = 0,
    m_IntroMusic                    = 0,
    m_IntroMusicVolume              = 1,
    m_SetIntroMusicVolume           = false,
    m_IntroEnemiesSpawned           = false,
    m_IntroEnemy1                   = nil,
    m_IntroEnemy2                   = nil,
    m_IntroEnemy3                   = nil,

    m_IntroMatriarchTeleported      = false,
    m_IntroTurret1Teleported        = false,
    m_IntroTurret2Teleported        = false,

    m_CustomAIPStr                  = nil,
    m_MapName                       = nil,

    m_EnemyRecycler                 = nil,
    m_Recycler                      = nil,

    m_IntroShip1                    = nil,
    m_IntroShip2                    = nil,
    m_IntroShip3                    = nil,

    m_IntroScionTurret1             = nil,
    m_IntroScionTurret2             = nil,
    m_ScionIntroHangar              = nil,
    m_ScionIntroMatriarch           = nil,

    m_IntroTurret1                  = nil,
    m_IntroTurret2                  = nil,

    m_PlayerTurret1                 = nil,
    m_PlayerTurret2                 = nil,

    m_DropshipTakeOffDialogPlayed   = false,
    m_DropshipTakeoffCheck          = false,

    m_Dropship1Takeoff              = false,
    m_Dropship1Remove               = false,
    m_Dropship1Time                 = 0,

    m_Dropship2Takeoff              = false,
    m_Dropship2Remove               = false,
    m_Dropship2Time                 = 0,

    m_Dropship3Takeoff              = false,
    m_Dropship3Remove               = false,
    m_Dropship3Time                 = 0,

    m_IntroDone                     = false,
    m_StartDone                     = false,
    m_GameOver                      = false,
    m_IntroCutsceneEnabled          = false,
    m_WildlifeEnabled               = false,
    m_SnipeableEnemies              = false,
    m_CanRespawn                    = false,
    m_IsMPI                         = false,
}

-- Functions Table
local ISDFIntroFunctions = {}
local ScionIntroFunctions = {}

-- Constants.
local MAX_PLAYERS = 4

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
    "fbark2holo",
    "bcrhino",
    "mcjak01",
    "mcwing01"
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

-- Register Save/Load for saveload system
_SaveLoad.RegisterSave("InstantCommon", function()
    return InstantCommon
end)

_SaveLoad.RegisterLoad("InstantCommon", function(InstantData)
    if (InstantData ~= nil) then
        for k, v in pairs(InstantData) do
            InstantCommon[k] = v
        end
    else
        PrintConsoleMessage("[IA 2.0]: WARNING: InstantCommon Load called with nil data.")
    end
end)

---------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- Getters and Setters ---------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

---@return Handle
function InstantCommon.GetPlayerRecycler()
    return InstantCommon.m_Recycler
end

---@return string
function InstantCommon.GetHumanTeamRace()
    return InstantCommon.m_HumanTeamRace
end

---@return integer
function InstantCommon.GetHumanTeam()
    return InstantCommon.m_PlayerTeam
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Local Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

local function BuildStartingVehicle(aTeam, aRace, ODF1, ODF2, Where)
    local TempODF = ReplaceCharacter(1, ODF1, aRace)

    if (DoesODFExist(TempODF) == false) then
        TempODF = ReplaceCharacter(1, ODF2, aRace)
    end

    local h = BuildObject(TempODF, aTeam, Where)

    if (aTeam == InstantCommon.m_PlayerTeam) then
        SetBestGroup(h)
    end

    return h
end

local function RemoveISDFIntroUnits()
    RemoveObject(InstantCommon.m_IntroShip1)
    RemoveObject(InstantCommon.m_IntroShip2)
    RemoveObject(InstantCommon.m_IntroShip3)
    RemoveObject(InstantCommon.m_IntroTurret1)
    RemoveObject(InstantCommon.m_IntroTurret2)

    for i = 1, MAX_PLAYERS do
        RemoveObject(GetHandle("player_spawn_i_" .. i))
    end
end

local function RemoveScionIntroUnits()
    RemoveObject(InstantCommon.m_ScionIntroHangar)
    RemoveObject(InstantCommon.m_ScionIntroMatriarch)
    RemoveObject(InstantCommon.m_ScionIntroTurret1)
    RemoveObject(InstantCommon.m_ScionIntroTurret2)

    for i = 1, MAX_PLAYERS do
        RemoveObject(GetHandle("player_spawn_f_" .. i))
    end
end

local function DisableIntro()
    RemoveScionIntroUnits()
    RemoveISDFIntroUnits()
    InstantCommon.m_IntroDone = true
end

local function GameConditions()
    if (InstantCommon.m_GameOver == false) then
        if (IsAlive(InstantCommon.m_EnemyRecycler) == false) then
            local DLLHandle = GetObjectByTeamSlot(InstantCommon.m_CompTeam, DLL_TEAM_SLOT_RECYCLER)

            if (IsAround(DLLHandle)) then
                InstantCommon.m_EnemyRecycler = DLLHandle
            else
                if (not InstantCommon.m_IsMPI) then
                    SucceedMission(GetTime() + 5, "instantw.txt.txt")
                else
                    local WinningTeamgroup = WhichTeamGroup(InstantCommon.m_StratTeam)
                    NoteGameoverByLastTeamWithBase(WinningTeamgroup)
                end

                _CPUManager.SendChatMessage(InstantCommon.m_CPUTeamObj, _BZCCDatabase.TauntTypes.TAUNTS_CPURecyDestroyed)
                InstantCommon.m_GameOver = true
            end
        elseif (IsAlive(InstantCommon.m_Recycler) == false) then
            local DLLHandle = GetObjectByTeamSlot(InstantCommon.m_StratTeam, DLL_TEAM_SLOT_RECYCLER)

            if (IsAround(DLLHandle)) then
                InstantCommon.m_Recycler = DLLHandle
            else
                if (not InstantCommon.m_IsMPI) then
                    FailMission(GetTime() + 5, "instantl.txt")
                else
                    local WinningTeamgroup = WhichTeamGroup(InstantCommon.m_CompTeam)
                    NoteGameoverByLastTeamWithBase(WinningTeamgroup)
                end

                _CPUManager.SendChatMessage(InstantCommon.m_CPUTeamObj,
                    _BZCCDatabase.TauntTypes.TAUNTS_HumanRecyDestroyed)
                InstantCommon.m_GameOver = true
            end
        end
    end
end

local function BuildCarriers()
    _CarrierManager.SetupCarrier(InstantCommon.m_PlayerTeam, InstantCommon.m_HumanTeamRace)
    _CarrierManager.SetupCarrier(InstantCommon.m_CompTeam, InstantCommon.m_CPUTeamRace)
end

local function CheckIntroEnemiesKilled()
    if (InstantCommon.m_IntroEnemiesSpawned == false) then
        for i = 1, InstantCommon.m_Difficulty + 1 do
            local enemy = BuildObject(InstantCommon.m_CPUTeamRace .. "vscout_c", InstantCommon.m_CompTeam,
                "intro_attacker_" .. i)

            SetSkill(enemy, InstantCommon.m_Difficulty)

            local randPlayerNum = GetRandomInt(1, InstantCommon.m_PlayerCount)

            if (i == 1) then
                InstantCommon.m_IntroEnemy1 = enemy
                Attack(enemy, GetPlayerHandle(randPlayerNum), 1)
            elseif (i == 2) then
                InstantCommon.m_IntroEnemy2 = enemy
                Attack(enemy, InstantCommon.m_Recycler, 1)
            elseif (i == 3) then
                InstantCommon.m_IntroEnemy3 = enemy
                Attack(enemy, GetPlayerHandle(randPlayerNum), 1)
            end
        end

        InstantCommon.m_IntroEnemiesSpawned = true
    end

    local check1 = IsAliveAndEnemy(InstantCommon.m_IntroEnemy1, InstantCommon.m_CompTeam)
    local check2 = IsAliveAndEnemy(InstantCommon.m_IntroEnemy2, InstantCommon.m_CompTeam)
    local check3 = IsAliveAndEnemy(InstantCommon.m_IntroEnemy3, InstantCommon.m_CompTeam)

    if (check1 == false and check2 == false and check3 == false) then
        InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(3)
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

local function BuildPlayerRecycler(pos)
    local customHumanRecycler

    if (InstantCommon.m_IsMPI) then
        customHumanRecycler = _DLLUtils.GetCheckedNetworkSvar(5, _BZCCDatabase.NetlistVars.NETLIST_Recyclers)
    else
        customHumanRecycler = IFace_GetString("options.instant.string1")
    end

    if (customHumanRecycler ~= nil) then
        InstantCommon.m_Recycler = BuildStartingVehicle(InstantCommon.m_StratTeam, InstantCommon.m_HumanTeamRace,
            customHumanRecycler,
            "*vrecy", pos)
    else
        InstantCommon.m_Recycler = BuildStartingVehicle(InstantCommon.m_StratTeam, InstantCommon.m_HumanTeamRace,
            "*vrecy", "*vrecy",
            pos)
    end

    SetScrap(InstantCommon.m_StratTeam, 40)
end

local function CleanSpawns()
    for i = 1, MAX_PLAYERS do
        if (i > InstantCommon.m_PlayerCount) then
            local spawn_handle = GetHandle("player_spawn_" .. InstantCommon.m_HumanTeamRace .. "_" .. i)
            RemoveObject(spawn_handle)
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function InstantCommon.InitialSetup()
    -- This is to stop music for the intro.
    AllowRandomTracks(true)

    -- Do not auto group units.
    SetAutoGroupUnits(false)

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages()

    -- Preload ODFs to save time when they spawn.
    for i = 1, #PreloadODFs do
        PreloadODF(PreloadODFs[i])
    end

    -- Preload Audio handles here as well.
    for i = 1, #PreloadAudios do
        PreloadAudioMessage(PreloadAudios[i])
    end
end

function InstantCommon.Start()
    -- Ally all the necessary teams to simulate "DefaultTeams".
    for i = 2, 5 do
        Ally(InstantCommon.m_PlayerTeam, i)
    end

    _TauntManager.SetupTaunts()

    InstantCommon.m_IsMPI = IsNetworkOn()
    InstantCommon.m_GameTPS = GetTPS()
    InstantCommon.m_TurnCounter = 0
    InstantCommon.m_StartDone = false
    InstantCommon.m_GameOver = false
    InstantCommon.m_CompTeam = 6
    InstantCommon.m_StratTeam = 1
    InstantCommon.m_MapName = GetMapTRNFilename()

    if (InstantCommon.m_IsMPI) then
        InstantCommon.m_IntroCutsceneEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.MPI_INTRO_SCENE_ENABLED) > 0
        InstantCommon.m_WildlifeEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.MPI_WILDLIFE_ENABLED) > 0
        InstantCommon.m_CPUTeamRace = string.char(IFace_GetInteger(_BZCCDatabase.ShellVariables.MPI_CPU_TEAM_RACE))
        InstantCommon.m_HumanTeamRace = GetRaceOfTeam(InstantCommon.m_PlayerTeam)
        InstantCommon.m_SnipeableEnemies = IFace_GetInteger(_BZCCDatabase.ShellVariables.MPI_SNIPEABLE_ENEMIES) > 0
        InstantCommon.m_Difficulty = IFace_GetInteger(_BZCCDatabase.ShellVariables.MPI_DIFFICULTY) + 1
    else
        InstantCommon.m_IntroCutsceneEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.INTRO_SCENE_ENABLED) > 0
        InstantCommon.m_WildlifeEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.WILDLIFE_ENABLED) > 0
        InstantCommon.m_CPUTeamRace = string.char(IFace_GetInteger(_BZCCDatabase.ShellVariables.HIS_RACE))
        InstantCommon.m_HumanTeamRace = string.char(IFace_GetInteger(_BZCCDatabase.ShellVariables.MY_RACE))
        InstantCommon.m_Difficulty = IFace_GetInteger(_BZCCDatabase.ShellVariables.DIFFICULTY) + 1
        InstantCommon.m_CanRespawn = IFace_GetInteger(_BZCCDatabase.ShellVariables.CAN_RESPAWN) > 0
    end

    InstantCommon.m_VSRTauntEasterEggTime = InstantCommon.m_TurnCounter + SecondsToTurns(600)
    InstantCommon.m_CPUScrapAmount = InstantCommon.m_Difficulty

    if (InstantCommon.m_IsMPI) then
        InstantCommon.m_CPUScrapDelay = ((4 - InstantCommon.m_Difficulty) * 2) / CountPlayers()
    else
        InstantCommon.m_CPUScrapDelay = ((4 - InstantCommon.m_Difficulty) * 2)
    end

    local PlayerEntryH = GetPlayerHandle(1)

    if (PlayerEntryH ~= nil) then
        RemoveObject(PlayerEntryH)
    end

    local LocalTeamNum = GetLocalPlayerTeamNumber();
    local PlayerH = InstantCommon.SetupPlayer(LocalTeamNum)
    SetAsUser(PlayerH, LocalTeamNum)

    PrintConsoleMessage("[IA 2.0]: Loading Instant Action 2.0. Welcome! Chosen Difficulty: " ..
        InstantCommon.m_Difficulty .. ".")
end

function InstantCommon.Update()
    -- Keep track of our turn counter.
    InstantCommon.m_TurnCounter = InstantCommon.m_TurnCounter + 1

    -- Subtitles.
    _Subtitles.Run()

    -- Update Game Time.
    _Multiplayer.UpdateGameTime(InstantCommon.m_GameTPS)

    if (InstantCommon.m_StartDone == false) then
        local customCPURecycler = IFace_GetString("options.instant.string2")

        if (customCPURecycler ~= nil) then
            InstantCommon.m_EnemyRecycler = BuildStartingVehicle(InstantCommon.m_CompTeam, InstantCommon.m_CPUTeamRace,
                customCPURecycler, "*vrecy", "RecyclerEnemy")
        else
            InstantCommon.m_EnemyRecycler = BuildStartingVehicle(InstantCommon.m_CompTeam, InstantCommon.m_CPUTeamRace,
                "*vrecy_x", "*vrecy", "RecyclerEnemy")
        end

        -- Spawn CPU vehicles.
        BuildStartingVehicle(InstantCommon.m_CompTeam, InstantCommon.m_CPUTeamRace, "*vturr_x", "*vturr_c",
            "TurretEnemy1")
        BuildStartingVehicle(InstantCommon.m_CompTeam, InstantCommon.m_CPUTeamRace, "*vturr_x", "*vturr_c",
            "TurretEnemy2")

        -- No team colours for MP. Don't care for them.
        ClearTeamColors()

        -- Checks for team colour differences.
        if (InstantCommon.m_CPUTeamRace == _BZCCDatabase.Factions.ISDF and InstantCommon.m_HumanTeamRace == _BZCCDatabase.Factions.ISDF) then
            SetTeamColor(InstantCommon.m_CompTeam, 0, 127, 255) -- Blue like in the campaign.
        elseif (InstantCommon.m_CPUTeamRace == _BZCCDatabase.Factions.SCION and InstantCommon.m_HumanTeamRace == _BZCCDatabase.Factions.SCION) then
            SetTeamColor(InstantCommon.m_CompTeam, 85, 255, 85) -- Green (Rebels) like in the campaign.
        end

        -- Setup the animal herd controller.
        if (InstantCommon.m_WildlifeEnabled) then
            -- If we're a Mire map, set up some birds and Jaks with no special behaviour.
            if (FindInTable(_BZCCDatabase.MireMaps, InstantCommon.m_MapName)) then
                _AnimalManager.SetupMireMapHerds()
            else
                -- Determine which ODFs to use for the mother and baby animals.
                local motherODF = 'bcrhino'
                local babyODF = 'bcrhino'

                -- Only use Rhinos for Bane maps, except for Dunes, that's a special case.
                if (InstantCommon.m_MapName == "dunesi.trn") then
                    motherODF = motherODF .. "_s"
                    babyODF = babyODF .. "_s_b"
                elseif (FindInTable(_BZCCDatabase.BaneMaps, InstantCommon.m_MapName)) then
                    motherODF = motherODF .. "_x"
                    babyODF = babyODF .. "_x_b"
                end

                _AnimalManager.SetupMapHerds(motherODF, babyODF)
            end
        end

        -- Register the CPU team with the new manager.
        InstantCommon.m_CPUTeamObj = _CPUManager.NewTeam(InstantCommon.m_CompTeam, InstantCommon.m_CPUTeamRace,
            "RecyclerEnemy", false)

        -- Grab dropship handles for the intro.
        InstantCommon.m_IntroShip1 = GetHandle("intro_drop_1")
        InstantCommon.m_IntroShip2 = GetHandle("intro_drop_2")
        InstantCommon.m_IntroShip3 = GetHandle("intro_drop_3")

        -- Grab all Scion intro units.
        InstantCommon.m_ScionIntroHangar = GetHandle("scion_intro_hangar")
        InstantCommon.m_ScionIntroMatriarch = GetHandle("intro_matriarch")
        InstantCommon.m_ScionIntroTurret1 = GetHandle("intro_turret_1_scion")
        InstantCommon.m_ScionIntroTurret2 = GetHandle("intro_turret_2_scion")

        -- Grab the turrets.
        InstantCommon.m_IntroTurret1 = GetHandle("turret1")
        InstantCommon.m_IntroTurret2 = GetHandle("turret2")

        -- Stop them so they can't be commanded for now.
        Stop(InstantCommon.m_IntroTurret1, 1)
        Stop(InstantCommon.m_IntroTurret2, 1)

        -- If we are doing anything like RTS mode, or the intro scene is off, don't let the intro scene play.
        -- Instead, just spawn stuff normally.
        if (not InstantCommon.m_IntroCutsceneEnabled) then
            -- Do not allow the intro to play.
            DisableIntro()

            -- Create the Recycler.
            BuildPlayerRecycler("Recycler")

            -- Grab the position of the Recycler for spawning more units.
            local recPos = GetPosition(InstantCommon.m_Recycler)

            -- Create a couple of turrets.
            BuildStartingVehicle(InstantCommon.m_PlayerTeam, InstantCommon.m_HumanTeamRace, "*vturr_xm", "*vturr",
                GetPositionNear(recPos, 40.0, 60.0))
            BuildStartingVehicle(InstantCommon.m_PlayerTeam, InstantCommon.m_HumanTeamRace, "*vturr_xm", "*vturr",
                GetPositionNear(recPos, 40.0, 60.0))

            -- Give reinforcements to the player based on difficulty.
            if (InstantCommon.m_Difficulty < _BZCCDatabase.Difficulty.DIFFICULTY_HARD) then
                local tank1 = BuildStartingVehicle(InstantCommon.m_PlayerTeam, InstantCommon.m_HumanTeamRace, "*vtank_x",
                    "*vtank",
                    GetPositionNear(recPos, 10, 10))
                local tank2 = BuildStartingVehicle(InstantCommon.m_PlayerTeam, InstantCommon.m_HumanTeamRace, "*vtank_x",
                    "*vtank",
                    GetPositionNear(recPos, 10, 10))

                SetRandomHeadingAngle(tank1)
                SetRandomHeadingAngle(tank2)
                SetBestGroup(tank1)
                SetBestGroup(tank2)

                if (InstantCommon.m_Difficulty < _BZCCDatabase.Difficulty.DIFFICULTY_MEDIUM) then
                    if (InstantCommon.m_HumanTeamRace == _BZCCDatabase.Factions.ISDF) then
                        GiveWeapon(tank1, "gspstab_c")
                        GiveWeapon(tank2, "gspstab_c")
                    elseif (InstantCommon.m_HumanTeamRace == _BZCCDatabase.Factions.SCION) then
                        GiveWeapon(tank1, "garc_c")
                        GiveWeapon(tank2, "garc_c")
                        GiveWeapon(tank1, "gabsorb")
                        GiveWeapon(tank2, "gabsorb")
                    end

                    local truck1 = BuildStartingVehicle(InstantCommon.m_PlayerTeam, InstantCommon.m_HumanTeamRace,
                        "*vserv_x",
                        "*vserv", GetPositionNear(recPos, 10, 10))
                    SetRandomHeadingAngle(truck1)
                    SetBestGroup(truck1)
                end
            end

            -- Create carriers.
            BuildCarriers()
        end

        InstantCommon.m_StartDone = true
        return
    end

    if (InstantCommon.m_IntroCutsceneEnabled and not InstantCommon.m_IntroDone) then
        if (InstantCommon.m_HumanTeamRace == _BZCCDatabase.Factions.ISDF) then
            ISDFIntroFunctions[InstantCommon.m_IntroState]()

            -- Check to see that the dropship is clear.
            if (InstantCommon.m_DropshipTakeoffCheck) then
                if (not InstantCommon.m_Dropship1Takeoff) then
                    -- Run a few checks to see if anything is near.
                    local distCheck1 = GetDistance(InstantCommon.m_IntroTurret1, InstantCommon.m_IntroShip1) > 30
                    local distCheck2 = GetDistance(InstantCommon.m_IntroTurret2, InstantCommon.m_IntroShip1) > 30
                    local distCheck3 = not IsPlayerWithinDistance(InstantCommon.m_IntroShip1, 30,
                        InstantCommon.m_PlayerCount)

                    if (distCheck1 and distCheck2 and distCheck3) then
                        -- Start the take-off sequence.
                        SetAnimation(InstantCommon.m_IntroShip1, "takeoff", 1)

                        -- Engine sound.
                        local engineSound = StartAudio3D("dropleav.wav", InstantCommon.m_IntroShip1)
                        SetVolume(engineSound, 0.3)

                        -- Set the timer for when we remove the dropship.
                        InstantCommon.m_Dropship1Time = InstantCommon.m_TurnCounter + SecondsToTurns(15)

                        -- So we don't loop.
                        InstantCommon.m_Dropship1Takeoff = true
                    end
                elseif (not InstantCommon.m_Dropship1Remove and InstantCommon.m_Dropship1Time < InstantCommon.m_TurnCounter) then
                    -- Remove the Dropship.
                    RemoveObject(InstantCommon.m_IntroShip1)

                    -- Mark this as done.
                    InstantCommon.m_Dropship1Remove = true
                end

                if (not InstantCommon.m_Dropship2Takeoff) then
                    local distCheck = not IsPlayerWithinDistance(InstantCommon.m_IntroShip2, 30,
                        InstantCommon.m_PlayerCount)

                    if (distCheck) then
                        -- Start the take-off sequence.
                        SetAnimation(InstantCommon.m_IntroShip2, "takeoff", 1)

                        -- Engine sound.
                        local engineSound = StartAudio3D("dropleav.wav", InstantCommon.m_IntroShip2)
                        SetVolume(engineSound, 0.3)

                        -- Set the timer for when we remove the dropship.
                        InstantCommon.m_Dropship2Time = InstantCommon.m_TurnCounter + SecondsToTurns(15)

                        -- So we don't loop.
                        InstantCommon.m_Dropship2Takeoff = true
                    end
                elseif (not InstantCommon.m_Dropship2Remove and InstantCommon.m_Dropship2Time < InstantCommon.m_TurnCounter) then
                    -- Remove the Dropship.
                    RemoveObject(InstantCommon.m_IntroShip2)

                    -- Mark this as done.
                    InstantCommon.m_Dropship2Remove = true
                end

                if (not InstantCommon.m_Dropship3Takeoff) then
                    local distCheck = not IsPlayerWithinDistance(InstantCommon.m_IntroShip3, 30,
                        InstantCommon.m_PlayerCount)

                    if (distCheck) then
                        -- Start the take-off sequence.
                        SetAnimation(InstantCommon.m_IntroShip3, "takeoff", 1)

                        -- Engine sound.
                        local engineSound = StartAudio3D("dropleav.wav", InstantCommon.m_IntroShip3)
                        SetVolume(engineSound, 0.3)

                        -- Set the timer for when we remove the dropship.
                        InstantCommon.m_Dropship3Time = InstantCommon.m_TurnCounter + SecondsToTurns(15)

                        -- So we don't loop.
                        InstantCommon.m_Dropship3Takeoff = true
                    end
                elseif (not InstantCommon.m_Dropship3Remove and InstantCommon.m_Dropship3Time < InstantCommon.m_TurnCounter) then
                    -- Remove the Dropship.
                    RemoveObject(InstantCommon.m_IntroShip3)

                    -- Mark this as done.
                    InstantCommon.m_Dropship3Remove = true
                end

                if (not InstantCommon.m_DropshipTakeOffDialogPlayed and InstantCommon.m_Dropship1Takeoff and InstantCommon.m_Dropship2Takeoff and InstantCommon.m_Dropship3Takeoff) then
                    -- "Condor": "We are returning to base."
                    InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_4.wav")

                    -- So we don't loop.
                    InstantCommon.m_DropshipTakeOffDialogPlayed = true
                end

                -- This means this method is no longer needed.
                if (InstantCommon.m_Dropship1Remove and InstantCommon.m_Dropship2Remove and InstantCommon.m_Dropship3Remove) then
                    InstantCommon.m_DropshipTakeoffCheck = false
                end
            end
        elseif (InstantCommon.m_HumanTeamRace == _BZCCDatabase.Factions.SCION) then
            ScionIntroFunctions[InstantCommon.m_IntroState]()
        end
    end

    -- Managers
    _AnimalManager.Run(InstantCommon.m_TurnCounter)
    _CarrierManager.Run(InstantCommon.m_TurnCounter)
    _CPUManager.Run(InstantCommon.m_TurnCounter)

    if (InstantCommon.m_StartDone and InstantCommon.m_IntroDone) then
        -- Game conditions to see if either Recycler has been destroyed.
        GameConditions()

        -- Start running the scrap cheat for the CPU.
        if (InstantCommon.m_NextCPUScrapTime <= InstantCommon.m_TurnCounter) then
            InstantCommon.m_NextCPUScrapTime = InstantCommon.m_TurnCounter +
                SecondsToTurns(InstantCommon.m_CPUScrapDelay)
            AddScrap(InstantCommon.m_CompTeam, InstantCommon.m_CPUScrapAmount)
        end
    end
end

---@param handle Handle
function InstantCommon.AddObject(handle)
    if (InstantCommon.m_IntroDone == false) then
        if (GetCfg(handle) == "fbportb_ark") then
            InstantCommon.m_ScionIntroPortal = handle
            return
        end
    end

    local classLabel = GetClassLabel(handle)

    if (classLabel == "CLASS_DEPOSIT") then
        _CPUManager.AddPool(handle)
        return
    end

    if (classLabel == "CLASS_SCRAP") then
        _CPUManager.AddScrap(handle)
        return
    end

    local AICraftType = GetODFString(handle, "GameObjectClass", "AIUnitType", nil)
    local isRecyclerVehicle = (classLabel == "CLASS_RECYCLERVEHICLE" or classLabel == "CLASS_RECYCLERVEHICLEH")
    local teamNum = GetTeamNum(handle)

    if (AICraftType == _BZCCDatabase.AIUnitTypes.LANDING_PAD) then
        _CarrierManager.RegisterLandingPad(handle, teamNum)
        return
    end

    if (AICraftType == _BZCCDatabase.AIUnitTypes.DROPSHIP_REQUEST) then
        _CarrierManager.RegisterDropshipRequest(handle, teamNum,
            InstantCommon.m_TurnCounter +
            SecondsToTurns(_BZCCDatabase.DropshipRequestItemTimeToDelete[InstantCommon.m_Difficulty]))
        return
    end

    if (teamNum == InstantCommon.m_CompTeam) then
        SetSkill(handle, InstantCommon.m_Difficulty)

        if (isRecyclerVehicle) then
            InstantCommon.m_EnemyRecycler = handle
            return
        end

        if (InstantCommon.m_IsMPI and not InstantCommon.m_SnipeableEnemies) then
            SetCanSnipe(handle, 0)
        end

        _CPUManager.AddTeamObject(handle, InstantCommon.m_TurnCounter, teamNum)
        return
    end

    if (teamNum == InstantCommon.m_StratTeam) then
        -- Max out skills.
        SetSkill(handle, 3)

        if (isRecyclerVehicle) then
            InstantCommon.m_Recycler = handle
            return
        end

        return
    end
end

---@param handle Handle
function InstantCommon.DeleteObject(handle)
    local teamNum = GetTeamNum(handle)
    local classLabel = GetClassLabel(handle)

    if (classLabel == "CLASS_SCRAP") then
        _CPUManager.AddScrap(handle)
        return
    end

    if (teamNum == InstantCommon.m_CompTeam) then
        _CPUManager.RemoveTeamObject(handle, teamNum)
        return
    end
end

---@param id integer
---@param Team integer
---@param IsNewPlayer boolean
function InstantCommon.AddPlayer(id, Team, IsNewPlayer)
    if (IsNewPlayer) then
        local PlayerH = InstantCommon.SetupPlayer(Team)
        SetAsUser(PlayerH, Team)
        AddPilotByHandle(PlayerH)

        _CPUManager.SendChatMessage(InstantCommon.m_CPUTeamObj, _BZCCDatabase.TauntTypes.TAUNTS_NewHuman)
    end

    return true
end

---@param id integer
function InstantCommon.DeletePlayer(id)
    InstantCommon.m_PlayerCount = InstantCommon.m_PlayerCount - 1
    IFace_SetInteger(_BZCCDatabase.ShellVariables.MPI_PLAYER_COUNT, tostring(InstantCommon.m_PlayerCount))
    PrintConsoleMessage("[IA 2.0]: Registering New Player Count: " .. InstantCommon.m_PlayerCount)
    _CPUManager.SendChatMessage(InstantCommon.m_CPUTeamObj, _BZCCDatabase.TauntTypes.TAUNTS_LeftHuman)

    return true
end

---@param Team integer
function InstantCommon.SetupPlayer(Team)
    InstantCommon.m_PlayerCount = InstantCommon.m_PlayerCount + 1
    IFace_SetInteger(_BZCCDatabase.ShellVariables.MPI_PLAYER_COUNT, tostring(InstantCommon.m_PlayerCount))
    PrintConsoleMessage("[IA 2.0]: Registering New Player Count: " .. InstantCommon.m_PlayerCount)

    if (IsTeamplayOn()) then
        local cmdTeam = GetCommanderTeam(Team)

        if (not InstantCommon.m_TeamIsSetUp[cmdTeam]) then
            SetMPTeamRace(WhichTeamGroup(cmdTeam), GetRaceOfTeam(cmdTeam))
            InstantCommon.m_TeamIsSetUp[cmdTeam] = true
        end
    end

    local spawnpointPosition = GetPositionNear("Recycler", 25, 50)
    InstantCommon.m_TeamPos[Team] = spawnpointPosition

    local PlayerH

    if (InstantCommon.m_IntroCutsceneEnabled) then
        if (InstantCommon.m_IsMPI) then
            local spawnLabel = "player_spawn_" .. GetRaceOfTeam(Team) .. "_" .. Team
            PrintConsoleMessage("[IA 2.0]: Attempting to find a handle with the following label: " .. spawnLabel)
            PlayerH = GetHandle(spawnLabel)
        else
            PlayerH = GetHandle("player_spawn_" .. InstantCommon.m_HumanTeamRace .. "_" .. Team)
        end
    end

    if (PlayerH == nil) then
        PrintConsoleMessage("[IA 2.0]: No pre-placed spawns found for team: " .. Team .. ". Spawning a new ship.")

        local curFloor = TerrainFindFloor(spawnpointPosition.x, spawnpointPosition.z) + 2.5

        if (spawnpointPosition.y < curFloor) then
            spawnpointPosition.y = curFloor
        end

        -- Build a new ODF if no spawns are found.
        if (InstantCommon.m_IsMPI) then
            PlayerH = BuildObject(GetPlayerODF(Team), Team, spawnpointPosition)
        else
            PlayerH = BuildObject(InstantCommon.m_HumanTeamRace .. "vscout_x", Team, spawnpointPosition)
        end

        SetRandomHeadingAngle(PlayerH)
    end

    local TempODFName

    if (InstantCommon.m_IsMPI) then
        TempODFName = GetRaceOfTeam(Team) .. "spilo_x"
    else
        TempODFName = InstantCommon.m_HumanTeamRace .. "spilo_x"
    end

    SetPilotClass(PlayerH, TempODFName)
    AddPilotByHandle(PlayerH)

    InstantCommon.m_TeamIsSetUp[Team] = true
    return PlayerH
end

---@param DeadObjectHandle Handle
function InstantCommon.PlayerEjected(DeadObjectHandle)
    local deadObjectTeam = GetTeamNum(DeadObjectHandle)

    if (deadObjectTeam == 0) then
        return _BZCCDatabase.EventReturnCodes.DLLHandled
    end

    if (IsPlayer(DeadObjectHandle)) then
        AddScore(DeadObjectHandle, -GetActualScrapCost(DeadObjectHandle))
    end

    return _BZCCDatabase.EventReturnCodes.DoEjectPilot
end

---@param DeadObjectHandle Handle
---@param KillersHandle Handle
function InstantCommon.ObjectKilled(DeadObjectHandle, KillersHandle)
    if (GetCurWorld() ~= 0) then
        return _BZCCDatabase.EventReturnCodes.DoEjectPilot
    end

    local isDeadAI = not IsPlayer(DeadObjectHandle)
    local isDeadPerson = IsPerson(DeadObjectHandle)

    -- Someone on neutral team always gets default behavior
    local deadObjectTeam = GetTeamNum(DeadObjectHandle)

    if (deadObjectTeam == 0) then
        return _BZCCDatabase.EventReturnCodes.DoEjectPilot
    end

    return InstantCommon.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI)
end

---@param DeadObjectHandle Handle
---@param KillersHandle Handle
function InstantCommon.ObjectSniped(DeadObjectHandle, KillersHandle)
    if (GetCurWorld() ~= 0) then
        return _BZCCDatabase.EventReturnCodes.DoEjectPilot
    end

    return InstantCommon.DeadObject(DeadObjectHandle, KillersHandle, true, not IsPlayer(DeadObjectHandle))
end

---@param DeadObjectHandle Handle
---@param Team integer
function InstantCommon.RespawnPilot(DeadObjectHandle, Team)
    if (not IsNetworkOn() and not InstantCommon.m_CanRespawn) then
        return
    end

    local spawnpointPosition = SetVector(0, 0, 0)
    local RespawnDistanceAwayXZRange = 32.0

    if (Team < 1 or Team >= MAX_TEAMS) then
        spawnpointPosition = GetSafestspawnpoint()
    else
        spawnpointPosition = InstantCommon.m_TeamPos[Team]
    end

    spawnpointPosition.x = spawnpointPosition.x + (GetRandomFloat(1.0) - 0.5) * (2.0 * RespawnDistanceAwayXZRange)
    spawnpointPosition.z = spawnpointPosition.z + (GetRandomFloat(1.0) - 0.5) * (2.0 * RespawnDistanceAwayXZRange)

    local curFloor = TerrainFindFloor(spawnpointPosition.x, spawnpointPosition.z) + 2.5

    if (spawnpointPosition.y < curFloor) then
        spawnpointPosition.y = curFloor
    end

    spawnpointPosition.y = spawnpointPosition.y + 200.0
    spawnpointPosition.y = spawnpointPosition.y + GetRandomFloat(1.0) * 8.0

    local NewPilot = BuildObject(_Multiplayer.GetInitialPlayerPilotODF(GetRaceOfTeam(Team)), Team, spawnpointPosition)
    SetAsUser(NewPilot, Team)
    AddPilotByHandle(NewPilot)
    SetRandomHeadingAngle(NewPilot)

    if (Team == 0) then
        MakeInert(NewPilot)
    end

    return _BZCCDatabase.EventReturnCodes.DLLHandled
end

---@param DeadObjectHandle Handle
---@param KillersHandle Handle
---@param isDeadPerson boolean
---@param isDeadAI boolean
function InstantCommon.DeadObject(DeadObjectHandle, KillersHandle, isDeadPerson, isDeadAI)
    local deadObjectTeam = GetTeamNum(DeadObjectHandle)
    local deadObjectIsPlayer = IsPlayer(DeadObjectHandle)
    local killerObjectIsPlayer = IsPlayer(KillersHandle)
    local relationship = GetTeamRelationship(DeadObjectHandle, KillersHandle)
    local deadObjectScrapCost = GetActualScrapCost(DeadObjectHandle)

    if (deadObjectTeam == 0) then
        return _BZCCDatabase.EventReturnCodes.DoEjectPilot
    end

    if (deadObjectIsPlayer) then
        local killerTeam = GetTeamNum(KillersHandle)

        if (killerTeam == InstantCommon.m_CompTeam) then
            _CPUManager.SendChatMessage(InstantCommon.m_CPUTeamObj, _BZCCDatabase.TauntTypes.TAUNTS_HumanShipDestroyed)
        end

        AddScore(DeadObjectHandle, -deadObjectScrapCost)

        if (isDeadPerson) then
            AddDeaths(DeadObjectHandle, 1)
        end
    else
        AddDeaths(DeadObjectHandle, 1)
        AddScore(DeadObjectHandle, -deadObjectScrapCost)
    end

    if (killerObjectIsPlayer) then
        if (relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_SAMETEAM or relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_ALLIEDTEAM) then
            AddKills(KillersHandle, -1)
            AddScore(KillersHandle, -deadObjectScrapCost)
        else
            AddKills(KillersHandle, 1)
            AddScore(KillersHandle, deadObjectScrapCost)
        end
    else
        if (relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_SAMETEAM or relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_ALLIEDTEAM) then
            AddKills(KillersHandle, -1)
            AddScore(KillersHandle, -deadObjectScrapCost)
        else
            AddKills(KillersHandle, 1)
            AddScore(KillersHandle, deadObjectScrapCost)
        end
    end

    if (isDeadAI) then
        if (isDeadPerson) then
            return _BZCCDatabase.EventReturnCodes.DLLHandled
        else
            return _BZCCDatabase.EventReturnCodes.DoEjectPilot
        end
    else
        if (isDeadPerson) then
            return InstantCommon.RespawnPilot(DeadObjectHandle, deadObjectTeam)
        else
            return _BZCCDatabase.EventReturnCodes.DoEjectPilot
        end
    end
end

---@param curWorld integer
---@param shooterHandle Handle
---@param victimHandle Handle
---@param ordnanceTeam integer
---@param pOrdnanceODF string
function InstantCommon.PreSnipe(curWorld, shooterHandle, victimHandle, ordnanceTeam, pOrdnanceODF)
    if (curWorld ~= 0) then
        return
    end

    local relationship = GetTeamRelationship(shooterHandle, victimHandle)

    if (relationship == _BZCCDatabase.TeamRelationships.TEAMRELATIONSHIP_ALLIEDTEAM) then
        if (IsPlayer(victimHandle) or (GetTeamNum(victimHandle) ~= 0)) then
            return _BZCCDatabase.EventReturnCodes.PRESNIPE_ONLYBULLETHIT
        end
    end

    SetPerceivedTeam(victimHandle, 0)

    return _BZCCDatabase.EventReturnCodes.PRESNIPE_KILLPILOT
end

---@param curWorld integer
---@param pilotHandle Handle
---@param emptyCraftHandle Handle
function InstantCommon.PreGetIn(curWorld, pilotHandle, emptyCraftHandle)
    if (curWorld ~= 0) then
        return
    end

    _VoiceManager.SwitchVehicleVoices(emptyCraftHandle, pilotHandle)

    return _BZCCDatabase.EventReturnCodes.PREGETIN_ALLOW
end

---@param ShooterHandle Handle
---@param VictimHandle Handle
---@param OrdnanceTeam integer
---@param OrdnanceODF Handle
function InstantCommon.PreOrdnanceHit(ShooterHandle, VictimHandle, OrdnanceTeam, OrdnanceODF)
    if (GetClassSig(VictimHandle) == "CLASS_ID_ANIMAL") then
        _AnimalManager.AnimalShot(InstantCommon.m_TurnCounter, VictimHandle, ShooterHandle)
    end

    if (OrdnanceTeam ~= InstantCommon.m_CompTeam) then
        if (GetTeamNum(VictimHandle) == InstantCommon.m_CompTeam) then
            local objClass = GetClassLabel(VictimHandle)

            if (objClass == "CLASS_TURRETTANK") then
                if (GetCurrentCommand(VictimHandle) ~= _BZCCDatabase.AICommands.CMD_DEFEND) then
                    Defend(VictimHandle, 0)
                end
            elseif (objClass == "CLASS_SCAVENGER" or objClass == "CLASS_SCAVENGERH") then
                if (IsIdle(VictimHandle)) then
                    Goto(VictimHandle, GetPositionNear("RecyclerEnemy", 40, 60), 0)
                end
            end
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- Intro Related Logic ---------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

ISDFIntroFunctions[1] = function()
    RemoveScionIntroUnits()

    if (InstantCommon.m_PlayerCount < 2) then
        RemoveObject(InstantCommon.m_IntroShip3)
        InstantCommon.m_Dropship3Takeoff = true
        InstantCommon.m_Dropship3Remove = true
    end

    -- Remove any left-over spawns on the map.
    CleanSpawns()

    SetColorFade(1, 0.5, Make_RGBA(0, 0, 0, 255))
    StartEarthQuake(5)

    InstantCommon.m_MusicOptionValue = GetVarItemInt("options.audio.music")
    IFace_SetInteger("options.audio.music", 0)

    SetAnimation(InstantCommon.m_IntroShip2, "deploy", 1)

    InstantCommon.m_IntroMusic = StartSoundEffect("IA_Intro.wav")
    InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(4)
    InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
end

ISDFIntroFunctions[2] = function()
    if (InstantCommon.m_SetIntroMusicVolume == false) then
        SetVolume(InstantCommon.m_IntroMusic, InstantCommon.m_IntroMusicVolume)
        InstantCommon.m_SetIntroMusicVolume = true
    end

    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_1.wav")
        InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(10)
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ISDFIntroFunctions[3] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(0.2)
        UpdateEarthQuake(30)
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ISDFIntroFunctions[4] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        StopEarthQuake()
        InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(4)
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ISDFIntroFunctions[5] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_2.wav")
        InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(6)
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ISDFIntroFunctions[6] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        SetAnimation(InstantCommon.m_IntroShip1, "deploy", 1)

        if (IsAround(InstantCommon.m_IntroShip3)) then
            SetAnimation(InstantCommon.m_IntroShip3, "deploy", 1)
        end

        BuildPlayerRecycler(GetTransform(InstantCommon.m_IntroShip2))
        SetPosition(InstantCommon.m_Recycler, GetPosition("Recycler"))

        -- Give reinforcements to the player based on difficulty.
        if (InstantCommon.m_Difficulty < _BZCCDatabase.Difficulty.DIFFICULTY_HARD) then
            local recyclerPos = GetPosition(InstantCommon.m_Recycler)

            local tank1 = BuildObject("ivtank_x", InstantCommon.m_PlayerTeam, GetPositionNear(recyclerPos, 10, 10))
            local tank2 = BuildObject("ivtank_x", InstantCommon.m_PlayerTeam, GetPositionNear(recyclerPos, 10, 10))

            SetBestGroup(tank1)
            SetBestGroup(tank2)

            Defend2(tank1, InstantCommon.m_Recycler, 0)
            Defend2(tank2, InstantCommon.m_Recycler, 0)

            if (InstantCommon.m_Difficulty < _BZCCDatabase.Difficulty.DIFFICULTY_MEDIUM) then
                GiveWeapon(tank1, "gspstab_c")
                GiveWeapon(tank2, "gspstab_c")

                local truck1 = BuildObject("ivserv_x", InstantCommon.m_PlayerTeam, GetPositionNear(recyclerPos, 10, 10))
                SetBestGroup(truck1)
                Follow(truck1, InstantCommon.m_Recycler, 0)
            end
        end

        InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(2.5)

        Goto(InstantCommon.m_Recycler, "recycler_go", 0)
        Goto(InstantCommon.m_IntroTurret1, "turret_1_go", 1)
        Goto(InstantCommon.m_IntroTurret2, "turret_2_go", 1)

        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ISDFIntroFunctions[7] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        StartSoundEffect("dropdoor.wav", InstantCommon.m_IntroShip1)

        InstantCommon.m_DropshipTakeoffCheck = true
        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_3.wav")
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ISDFIntroFunctions[8] = function()
    CheckIntroEnemiesKilled()
end

ISDFIntroFunctions[9] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        SetBestGroup(InstantCommon.m_IntroTurret1)
        SetBestGroup(InstantCommon.m_IntroTurret2)
        Defend(InstantCommon.m_IntroTurret1, 0)
        Defend(InstantCommon.m_IntroTurret2, 0)

        BuildCarriers()

        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Carrier_1.wav")
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ISDFIntroFunctions[10] = function()
    if (IsAudioMessageDone(InstantCommon.m_IntroAudio)) then
        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Carrier_2.wav")
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ISDFIntroFunctions[11] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        InstantCommon.m_IntroMusicVolume = InstantCommon.m_IntroMusicVolume - 0.02

        SetVolume(InstantCommon.m_IntroMusic, InstantCommon.m_IntroMusicVolume)

        InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(0.3)

        if (InstantCommon.m_IntroMusicVolume <= 0) then
            StopAudio(InstantCommon.m_IntroMusic)
            IFace_SetInteger("options.audio.music", InstantCommon.m_MusicOptionValue)
            InstantCommon.m_IntroDone = true
        end
    end
end

ScionIntroFunctions[1] = function()
    RemoveISDFIntroUnits()

    -- Start a small earthquake.
    StartEarthQuake(5)

    -- Temp so the player can't control the intro units.
    Stop(InstantCommon.m_ScionIntroMatriarch, 1)
    Stop(InstantCommon.m_ScionIntroTurret1, 1)
    Stop(InstantCommon.m_ScionIntroTurret2, 1)

    -- Attempt to mask the emitters on the portal.
    MaskEmitter(InstantCommon.m_ScionIntroPortal, 0)
    SetColorFade(1, 0.5, Make_RGBA(0, 0, 0, 255))

    InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(4)
    InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
end

ScionIntroFunctions[2] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_1.wav")
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ScionIntroFunctions[3] = function()
    if (IsAudioMessageDone(InstantCommon.m_IntroAudio)) then
        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_2.wav")
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ScionIntroFunctions[4] = function()
    if (IsAudioMessageDone(InstantCommon.m_IntroAudio)) then
        if (FindInTable(_BZCCDatabase.MireMaps, InstantCommon.m_MapName)) then
            InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_3B.wav")
        elseif (FindInTable(_BZCCDatabase.BaneMaps, InstantCommon.m_MapName)) then
            InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_3A.wav")
        end

        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ScionIntroFunctions[5] = function()
    if (IsAudioMessageDone(InstantCommon.m_IntroAudio)) then
        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_3.wav")
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ScionIntroFunctions[6] = function()
    if (IsAudioMessageDone(InstantCommon.m_IntroAudio)) then
        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Tech_4.wav")
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ScionIntroFunctions[7] = function()
    StartEmitter(InstantCommon.m_ScionIntroPortal, 1)

    InstantCommon.m_IntroDelay = InstantCommon.m_TurnCounter + SecondsToTurns(1)
    InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
end

ScionIntroFunctions[8] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        Follow(InstantCommon.m_ScionIntroMatriarch, InstantCommon.m_ScionIntroPortal, 1)
        Follow(InstantCommon.m_ScionIntroTurret1, InstantCommon.m_ScionIntroPortal, 1)
        Follow(InstantCommon.m_ScionIntroTurret2, InstantCommon.m_ScionIntroPortal, 1)

        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ScionIntroFunctions[9] = function()
    if (GetDistance(InstantCommon.m_ScionIntroMatriarch, InstantCommon.m_ScionIntroPortal) < 25 and InstantCommon.m_IntroMatriarchTeleported == false) then
        local recyOdf = nil

        if (InstantCommon.m_IsMPI) then
            recyOdf = _DLLUtils.GetCheckedNetworkSvar(5, _BZCCDatabase.NetlistVars.NETLIST_Recyclers)
        else
            recyOdf = IFace_GetString("options.instant.string1")
        end

        if (recyOdf == nil) then
            recyOdf = "ivrecy"
        end

        recyOdf = ReplaceCharacter(1, recyOdf, "f")
        TeleportOut(InstantCommon.m_ScionIntroMatriarch)

        InstantCommon.m_PlayerRecycler = TeleportIn(recyOdf, InstantCommon.m_StratTeam, "Recycler")
        SetBestGroup(InstantCommon.m_PlayerRecycler)
        SetScrap(InstantCommon.m_StratTeam, 40)

        -- Give reinforcements to the player based on difficulty.
        if (InstantCommon.m_Difficulty < _BZCCDatabase.Difficulty.DIFFICULTY_HARD) then
            local recyclerPos = GetPosition(InstantCommon.m_Recycler)

            local tank1 = BuildObject("fvtank_x", InstantCommon.m_PlayerTeam, GetPositionNear(recyclerPos, 10, 10))
            local tank2 = BuildObject("fvtank_x", InstantCommon.m_PlayerTeam, GetPositionNear(recyclerPos, 10, 10))

            SetBestGroup(tank1)
            SetBestGroup(tank2)

            if (InstantCommon.m_Difficulty < _BZCCDatabase.Difficulty.DIFFICULTY_MEDIUM) then
                GiveWeapon(tank1, "garc_c")
                GiveWeapon(tank2, "garc_c")
                GiveWeapon(tank1, "gabsorb")
                GiveWeapon(tank2, "gabsorb")

                local truck1 = BuildObject("fvserv_x", InstantCommon.m_PlayerTeam, GetPositionNear(recyclerPos, 10, 10))
                SetBestGroup(truck1)
                SetRandomHeadingAngle(truck1)
            end
        end

        InstantCommon.m_IntroMatriarchTeleported = true
    end

    if (GetDistance(InstantCommon.m_ScionIntroTurret1, InstantCommon.m_ScionIntroPortal) < 30 and InstantCommon.m_IntroTurret1Teleported == false) then
        TeleportOut(InstantCommon.m_ScionIntroTurret1)
        SetBestGroup(TeleportIn("fvturr_x", InstantCommon.m_StratTeam, "Recycler"))
        InstantCommon.m_IntroTurret1Teleported = true
    end

    if (GetDistance(InstantCommon.m_ScionIntroTurret2, InstantCommon.m_ScionIntroPortal) < 30 and InstantCommon.m_IntroTurret2Teleported == false) then
        TeleportOut(InstantCommon.m_ScionIntroTurret2)
        SetBestGroup(TeleportIn("fvturr_x", InstantCommon.m_StratTeam, "Recycler"))
        InstantCommon.m_IntroTurret2Teleported = true
    end

    if (InstantCommon.m_IntroMatriarchTeleported == true and InstantCommon.m_IntroTurret1Teleported == true and InstantCommon.m_IntroTurret2Teleported == true) then
        InstantCommon.m_IntroForcePlayerTeleportDelay = InstantCommon.m_TurnCounter + SecondsToTurns(25)
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ScionIntroFunctions[10] = function()
    -- For all players in the lobby.
    for i = 1, InstantCommon.m_PlayerCount do
        local pHandle = GetPlayerHandle(i)

        -- Teleport the player to the Recycler.
        if (InstantCommon.m_IntroForcePlayerTeleportDelay < InstantCommon.m_TurnCounter or GetDistance(pHandle, InstantCommon.m_ScionIntroPortal) < 25) then
            -- Teleport the player to the Recycler.
            Teleport(pHandle, "Recycler", 50)

            -- Remove the intro stuff.
            RemoveObject(InstantCommon.m_ScionIntroHangar)

            -- Stop the earthquake.
            StopEarthQuake()

            -- Advance to the next state.
            InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
        end
    end
end

ScionIntroFunctions[11] = function()
    -- Spawn and check if the enemies are dead.
    CheckIntroEnemiesKilled()
end

ScionIntroFunctions[12] = function()
    if (InstantCommon.m_IntroDelay < InstantCommon.m_TurnCounter) then
        BuildCarriers()

        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Carrier_1.wav")
        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
    end
end

ScionIntroFunctions[13] = function()
    if (IsAudioMessageDone(InstantCommon.m_IntroAudio)) then
        InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Scion_Carrier_2.wav")
        InstantCommon.m_IntroDone = true
    end
end

return InstantCommon
