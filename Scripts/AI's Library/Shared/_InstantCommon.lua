-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()

-- Required Globals.
require("_GlobalVariables")

-- Required helper functions.
require("_HelperFunctions")

-- Required Skins Logic.
require("_Skins")

-- Database.
local _BZCCDatabase = require("_BZCCDatabase")

InstantCommon = {
    m_GameTPS = GetTPS(),

    m_CPUTeamRace = '',
    m_HumanTeamRace = '',

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

    m_CPUScrapDelay = 0,
    m_CPUScrapAmount = 0,
    m_NextCPUScrapTime = 0,
    m_VSRTauntEasterEggTime = 0,

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
    m_MapName = nil,

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
    m_GameOver = false,
    m_IntroCutsceneEnabled = false,
    m_WildlifeEnabled = false
}

-- Functions Table
local ISDFIntroFunctions = {}
local ScionIntroFunctions = {}

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

---------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- Getters and Setters ---------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

---@return Handle
function InstantCommon.GetPlayerRecycler()
    return InstantCommon.m_PlayerRecycler
end

---@return string
function InstantCommon.GetHumanTeamRace()
    return InstantCommon.m_HumanTeamRace
end

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
    RemoveObject(InstantCommon.m_IntroTurret1)
    RemoveObject(InstantCommon.m_IntroTurret2)
end

local function RemoveScionIntroUnits()
    RemoveObject(InstantCommon.m_ScionIntroHangar)
    RemoveObject(InstantCommon.m_ScionIntroMatriarch)
    RemoveObject(InstantCommon.m_ScionIntroPlayer)
    RemoveObject(InstantCommon.m_ScionIntroTurret1)
    RemoveObject(InstantCommon.m_ScionIntroTurret2)
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
                DoTaunt(_BZCCDatabase.TauntTypes.TAUNTS_CPURecyDestroyed)
                SucceedMission(GetTime() + 5, "instantw.txt")
                InstantCommon.m_GameOver = true
            end
        elseif (IsAlive(InstantCommon.m_Recycler) == false) then
            local DLLHandle = GetObjectByTeamSlot(InstantCommon.m_StratTeam, DLL_TEAM_SLOT_RECYCLER)

            if (IsAround(DLLHandle)) then
                InstantCommon.m_Recycler = DLLHandle
            else
                if (InstantCommon.m_TurnCounter < InstantCommon.m_VSRTauntEasterEggTime) then
                    DoTaunt(_BZCCDatabase.TauntTypes.TAUNTS_VSR_EasterEgg)
                else
                    DoTaunt(_BZCCDatabase.TauntTypes.TAUNTS_HumanRecyDestroyed)
                end

                SucceedMission(GetTime() + 5, "instantl.txt")
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
            local enemy = BuildObject(InstantCommon.m_CPUTeamRace .. "vscout_c", InstantCommon.m_CompTeam, "intro_attacker_" .. i)

            SetSkill(enemy, InstantCommon.m_Difficulty)

            if (i == 1) then
                InstantCommon.m_IntroEnemy1 = enemy
                Attack(enemy, InstantCommon.m_Player, 1)
            elseif (i == 2) then
                InstantCommon.m_IntroEnemy2 = enemy
                Attack(enemy, InstantCommon.m_Recycler, 1)
            elseif (i == 3) then
                InstantCommon.m_IntroEnemy3 = enemy
                Attack(enemy, InstantCommon.m_Player, 1)
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
    local customHumanRecycler = IFace_GetString("options.instant.string1")

    if (customHumanRecycler ~= nil) then
        InstantCommon.m_Recycler = BuildStartingVehicle(InstantCommon.m_StratTeam, InstantCommon.m_HumanTeamRace, customHumanRecycler,
            "*vrecy", pos)
    else
        InstantCommon.m_Recycler = BuildStartingVehicle(InstantCommon.m_StratTeam, InstantCommon.m_HumanTeamRace, "*vrecy", "*vrecy",
            pos)
    end

    SetScrap(InstantCommon.m_StratTeam, 40)
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

function InstantCommon.Update()
    -- Keep track of our turn counter.
    InstantCommon.m_TurnCounter = InstantCommon.m_TurnCounter + 1

    -- Subtitles.
    _Subtitles.Run()

    -- Keep track of our player.
    InstantCommon.m_Player = GetPlayerHandle(1)

    if (InstantCommon.m_StartDone == false) then
        InstantCommon.m_StartDone = true

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

        -- Checks for team colour differences.
        if (InstantCommon.m_CPUTeamRace == _BZCCDatabase.Factions.ISDF and InstantCommon.m_HumanTeamRace == _BZCCDatabase.Factions.ISDF) then
            SetTeamColor(InstantCommon.m_CompTeam, 0, 127, 255) -- Blue like in the campaign.
        elseif (InstantCommon.m_CPUTeamRace == _BZCCDatabase.Factions.SCION and InstantCommon.m_HumanTeamRace == _BZCCDatabase.Factions.SCION) then
            SetTeamColor(InstantCommon.m_CompTeam, 85, 255, 85) -- Green (Rebels) like in the campaign.
        end

        -- Setup the animal herd controller.
        if (InstantCommon.m_WildlifeEnabled == 1) then
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
        _CPUManager.NewTeam(InstantCommon.m_CompTeam, InstantCommon.m_CPUTeamRace, "RecyclerEnemy", false)

        -- Grab dropship handles for the intro.
        InstantCommon.m_IntroShip1 = GetHandle("intro_drop_1")
        InstantCommon.m_IntroShip2 = GetHandle("intro_drop_2")

        -- Grab all Scion intro units.
        InstantCommon.m_ScionIntroHangar = GetHandle("scion_intro_hangar")
        InstantCommon.m_ScionIntroMatriarch = GetHandle("intro_matriarch")
        InstantCommon.m_ScionIntroPlayer = GetHandle("scion_player_scout")
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
        if (InstantCommon.m_IntroCutsceneEnabled == 0) then
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

            -- Remove any pre-placed player handles on the map.
            RemoveObject(InstantCommon.m_Player)

            -- Respawn the player.
            RespawnPlayer(true)
        end

        return
    end

    if (InstantCommon.m_IntroCutsceneEnabled == 1 and InstantCommon.m_IntroDone == false) then
        if (InstantCommon.m_HumanTeamRace == _BZCCDatabase.Factions.ISDF) then
            ISDFIntroFunctions[InstantCommon.m_IntroState]()

            -- Check to see that the dropship is clear.
            if (InstantCommon.m_DropshipTakeoffCheck) then
                if (InstantCommon.m_Dropship1Takeoff == false) then
                    local distCheck1 = CountUnitsNearObject(InstantCommon.m_IntroShip1, 30, InstantCommon.m_PlayerTeam,
                        nil)

                    if (distCheck1 == 1) then
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
                elseif (InstantCommon.m_Dropship1Remove == false and InstantCommon.m_Dropship1Time < InstantCommon.m_TurnCounter) then
                    -- Remove the Dropship.
                    RemoveObject(InstantCommon.m_IntroShip1)

                    -- Mark this as done.
                    InstantCommon.m_Dropship1Remove = true
                end

                if (InstantCommon.m_Dropship2Takeoff == false) then
                    local distCheck2 = CountUnitsNearObject(InstantCommon.m_IntroShip2, 30, InstantCommon.m_PlayerTeam,
                        nil)

                    if (distCheck2 == 1) then
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
                elseif (InstantCommon.m_Dropship2Remove == false and InstantCommon.m_Dropship2Time < InstantCommon.m_TurnCounter) then
                    -- Remove the Dropship.
                    RemoveObject(InstantCommon.m_IntroShip2)

                    -- Mark this as done.
                    InstantCommon.m_Dropship2Remove = true
                end

                if (InstantCommon.m_DropshipTakeOffDialogPlayed == false and InstantCommon.m_Dropship1Takeoff and InstantCommon.m_Dropship2Takeoff) then
                    -- "Condor": "We are returning to base."
                    InstantCommon.m_IntroAudio = _Subtitles.AudioWithSubtitles("IA_Pilot_4.wav")

                    -- So we don't loop.
                    InstantCommon.m_DropshipTakeOffDialogPlayed = true
                end

                -- This means this method is no longer needed.
                if (InstantCommon.m_Dropship1Remove and InstantCommon.m_Dropship2Remove) then
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

    if (InstantCommon.m_IntroDone) then
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

---@param isMpi boolean
function InstantCommon.Start(isMpi)
    -- TODO: Add a check to see if we're an MPI session for these as the variables will be different.
    InstantCommon.m_GameTPS = GetTPS()
    InstantCommon.m_TurnCounter = 0
    InstantCommon.m_StartDone = false
    InstantCommon.m_GameOver = false
    InstantCommon.m_CompTeam = 6
    InstantCommon.m_StratTeam = 1
    InstantCommon.m_MapName = GetMapTRNFilename()

    InstantCommon.m_IntroCutsceneEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.INTRO_SCENE_ENABLED)
    InstantCommon.m_WildlifeEnabled = IFace_GetInteger(_BZCCDatabase.ShellVariables.WILDLIFE_ENABLED)

    InstantCommon.m_CPUTeamRace = string.char(IFace_GetInteger(_BZCCDatabase.ShellVariables.HIS_RACE))
    InstantCommon.m_HumanTeamRace = string.char(IFace_GetInteger(_BZCCDatabase.ShellVariables.MY_RACE))
    InstantCommon.m_Difficulty = IFace_GetInteger(_BZCCDatabase.ShellVariables.DIFFICULTY) + 1
    InstantCommon.m_VSRTauntEasterEggTime = InstantCommon.m_TurnCounter + SecondsToTurns(600)

    InstantCommon.m_CPUScrapAmount = InstantCommon.m_Difficulty
    InstantCommon.m_CPUScrapDelay = ((4 - InstantCommon.m_Difficulty) * 2)

    PrintConsoleMessage("Loading Instant Action 2.0. Welcome! Chosen Difficulty: " .. InstantCommon.m_Difficulty)
end

---@param ShooterHandle Handle
---@param VictimHandle Handle
---@param OrdnanceTeam number
function InstantCommon.RegisterHandleShot(ShooterHandle, VictimHandle, OrdnanceTeam)
    if (GetClassSig(VictimHandle) == "CLASS_ID_ANIMAL") then
        _AnimalManager.AnimalShot(InstantCommon.m_TurnCounter, VictimHandle, ShooterHandle)
    end

    if (OrdnanceTeam ~= InstantCommon.m_CompTeam) then
        if (GetTeamNum(VictimHandle) == InstantCommon.m_CompTeam) then
            local objClass = GetClassLabel(VictimHandle)

            if (objClass == "CLASS_TURRETTANK") then
                if (GetCurrentCommand(VictimHandle) ~= _BZCCDatabase.AICommands.CMD_DEFEND) then
                    Stop(VictimHandle, 0)
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

        SetVerbose(InstantCommon.m_Recycler, false)
        Goto(InstantCommon.m_Recycler, "recycler_go", 0)
        SetVerbose(InstantCommon.m_Recycler, true)
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
    StartEarthQuake(1)

    -- Temp so the player can't control the intro units.
    Stop(InstantCommon.m_ScionIntroMatriarch, 1)
    Stop(InstantCommon.m_ScionIntroTurret1, 1)
    Stop(InstantCommon.m_ScionIntroTurret2, 1)

    -- Attempt to mask the emitters on the portal.
    MaskEmitter(InstantCommon.m_ScionIntroPortal, 0)

    RemoveObject(InstantCommon.m_Player)
    SetColorFade(1, 0.5, Make_RGB(0, 0, 0, 255))
    SetAsUser(InstantCommon.m_ScionIntroPlayer, InstantCommon.m_PlayerTeam)

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
        local customHumanRecycler = IFace_GetString("options.instant.string1")

        if (customHumanRecycler ~= nil) then
            recyOdf = ReplaceCharacter(1, customHumanRecycler, "f")
        else
            recyOdf = ReplaceCharacter(1, "vrecy", "f")
        end

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
    -- Teleport the player to the Recycler.
    if (InstantCommon.m_IntroForcePlayerTeleportDelay < InstantCommon.m_TurnCounter or GetDistance(InstantCommon.m_Player, InstantCommon.m_ScionIntroPortal) < 25) then
        Teleport(InstantCommon.m_Player, "Recycler", 50)

        -- Remove the intro stuff.
        RemoveObject(InstantCommon.m_ScionIntroHangar)

        -- Stop the earthquake.
        StopEarthQuake()

        InstantCommon.m_IntroState = InstantCommon.m_IntroState + 1
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
