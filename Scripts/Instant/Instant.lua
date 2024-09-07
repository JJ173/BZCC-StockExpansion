--[[
    BZCC Instant 2.0 Lua Script
    Written by AI_Unit
    Version 1.0 12-05-2024
--]]

-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))();

-- Required Globals.
require("_GlobalVariables");

-- Required helper functions.
require("_HelperFunctions");

-- Models.
local _Team = require("_Team");
local _Pool = require("_Pool");

-- Mission important variables.
local _Mission =
{
    m_TurnCounter = 0,
    m_PlayerTeam = 1,
    m_EnemyTeam = 6,

    m_GameTPS = 0,
    m_Difficulty = 0,
    m_LastCPUPlan = 0,
    m_AssaultCounter = 0,

    m_CanRespawn = false,
    m_StartDone = false,
    m_SetFirstAIP = false,
    m_UseStockAIPLogic = false,
    m_PastAIP0 = false,
    m_Gameover = false,

    m_Player = nil,
    m_HumanTeam = nil,
    m_CPUTeam = nil,

    m_CustomAIPStr = '',

    m_Pools = {},
};

function InitialSetup()
    SetAutoGroupUnits(false);

    -- Preload all of our ODFs.
    PreloadODF("ivrecy");
    PreloadODF("fvrecy");
    PreloadODF("ivrecycpu");
    PreloadODF("fvrecycpu");
    PreloadODF("ivrecy_x");
    PreloadODF("fvrecy_x");
    PreloadODF("ivrecy_c");
    PreloadODF("fvrecy_c");

    -- Make sure our team is named.
    SetTauntCPUTeamName("CPU");
end

function Save()
    return _Mission;
end

function Load(MissionData)
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();

    -- Load mission data.
    Mission = MissionData;
end

function AddObject(h)
    -- Grab the team number for this object.
    local teamNumber = GetTeamNum(h);

    -- Grab the class for this object as well.
    local classLabel = GetClassLabel(h);

    -- Get the ODF name of the handle.
    local ODFName = GetCfg(h);

    -- Get the base name for the handle.
    local BaseName = GetBase(h);

    -- Let's keep track of all pools that are on the map.
    if (classLabel == "CLASS_DEPOSIT") then
        -- Grab the distance between this pool and the enemy position.
        local dist = GetDistance(h, "RecyclerEnemy");
        -- Grab the position so we can store it in the model.
        local pos = GetPosition(h);
        -- Create a new model for this pool.
        local newPoolModel = _Pool:New(h, 0, pos, dist);
        -- Grab the position vector and store it.
        _Mission.m_Pools[#_Mission.m_Pools + 1] = newPoolModel;
    end

    -- Process things that are added to the player team and adapt as per stock behaviour.
    if (_Mission.m_CPUTeam ~= nil and teamNumber == _Mission.m_CPUTeam.Team) then
        -- Set CPU unit skills based on difficulty.
        SetSkill(h, _Mission.m_Difficulty + 1);

        -- Do this as well so we can keep track of objects.
        _Mission.m_CPUTeam:AddObject(h, classLabel, ODFName, BaseName);

        -- This will sort the weapons for the CPU team.
        _Mission.m_CPUTeam:GiveWeapons(h, ODFName, _Mission.m_UseStockAIPLogic);
    elseif (teamNumber == _Mission.m_PlayerTeam) then
        -- Set player unit skills based on difficulty.
        SetSkill(h, 4 - _Mission.m_Difficulty);

        -- Choose an AIP if we are using stock behaviour.
        -- Check to see if the Recycler has been deployed.
        if (_Mission.m_UseStockAIPLogic) then
            if (classLabel == "CLASS_RECYCLER") then
                if (_Mission.m_PastAIP0 == false) then
                    -- So we don't loop.
                    _Mission.m_PastAIP0 = true;

                    -- Pick an AIP.
                    local stratChoice = _Mission.m_TurnCounter % 2;

                    if (_Mission.m_CPURace == 'f') then
                        if (stratChoice == 0) then
                            SetCPUAIPlan(AIPType1);
                        elseif (stratChoice == 1) then
                            SetCPUAIPlan(AIPType3);
                        elseif (stratChoice == 2) then
                            SetCPUAIPlan(AIPType2);
                        end
                    else
                        local newChoice = stratChoice % 2;

                        if (newChoice == 0) then
                            SetCPUAIPlan(AIPType1);
                        elseif (newChoice == 1) then
                            SetCPUAIPlan(AIPType3);
                        end
                    end
                end
            elseif (classLabel == "CLASS_ASSAULTTANK" or classLabel == "CLASS_WALKER") then
                _Mission.m_AssaultCounter = _Mission.m_AssaultCounter + 1;
            end
        end
    end

    -- This is a check in Stock to see if the timer for switching the AIP has elapsed.
    if (_Mission.m_UseStockAIPLogic and _Mission.m_PastAIP0 == false and (_Mission.m_TurnCounter > (180 * _Mission.m_GameTPS))) then
        -- So we don't loop.
        _Mission.m_PastAIP0 = true;

        local stratChoice = _Mission.m_TurnCounter % 2;

        if (stratChoice == 0) then
            SetCPUAIPlan(AIPType1);
        elseif (stratChoice == 1) then
            SetCPUAIPlan(AIPType3);
        end
    end
end

function DeleteObject(h)
    -- Grab the team number for this object.
    local teamNumber = GetTeamNum(h);

    -- Grab the class for this object as well.
    local classLabel = GetClassLabel(h);

    -- Keep track of assault units if we are using stock behaviour.
    if (_Mission.m_UseStockAIPLogic) then
        if (teamNumber == _Mission.m_PlayerTeam) then
            if (classLabel == "CLASS_ASSAULTTANK" or classLabel == "CLASS_WALKER") then
                _Mission.m_AssaultCounter = _Mission.m_AssaultCounter - 1;

                if (_Mission.m_AssaultCounter < 0) then
                    _Mission.m_AssaultCounter = 0;
                end
            end
        end
    end
end

function SetCPUAIPlan(type)
    -- Clamp to legal value if not in range
    if (type < AIPType0 or type >= MAX_AIP_TYPE) then
        type = AIPType3;
    end

    if (type > AIPType3 and _Mission.m_LastCPUPlan <= AIPType3) then
        return;
    end

    -- Check to see if we have a custom AIP file or stock.
    local AIPString = 'stock_';
    local AIPFile = '';

    if (_Mission.m_CustomAIPStr ~= nil) then
        AIPString = _Mission.m_CustomAIPStr;
    end

    -- First pass, try to find an AIP that is designed to use Provides for enemy team, thus it only cares about CPU Race. This makes adding races much easier.
    AIPFile = AIPString .. _Mission.m_CPURace .. type .. '.aip';

    if (DoesFileExist(AIPFile) == false) then
        AIPFile = AIPString .. _Mission.m_CPURace .. _Mission.m_PlayerRace .. type .. '.aip';
    end

    _Mission.m_LastCPUPlan = type;

    if (_Mission.m_SetFirstAIP) then
        DoTaunt(TAUNTS_Random);
    else
        _Mission.m_SetFirstAIP = true;
    end

    SetAIP(AIPFile, _Mission.m_EnemyTeam);
end

function Start()
    -- Get the default TPS which is 20.
    _Mission.m_GameTPS = GetTPS();

    -- Can the player respawn?
    _Mission.m_CanRespawn = IFace_GetInteger("options.instant.bool0");

    -- Grab the difficulty.
    _Mission.m_Difficulty = GetInstantDifficulty();

    -- Create the CPU team model to keep track of what's in the world.
    _Mission.m_CPUTeam = _Team:New(_Mission.m_EnemyTeam, nil, _Mission.m_Pools);

    -- Run the set up for CPU team.
    _Mission.m_CPUTeam:Setup(true);

    -- Create the Human team model.
    _Mission.m_HumanTeam = _Team:New(_Mission.m_PlayerTeam);

    -- Run the set up for Human team.
    _Mission.m_HumanTeam:Setup(false);

    -- Set the AIP depending on the team.
    _Mission.m_CustomAIPStr = IFace_GetString("options.instant.string0");

    -- If this isn't null, use it, else default to stock.
    if (_Mission.m_CustomAIPStr ~= nil and _Mission.m_CustomAIPStr == 'bzcc_x_') then
        -- Use custom logic.
        SetAIP(_Mission.m_CustomAIPStr .. _Mission.m_CPUTeam.Race .. '_main.aip', _Mission.m_CPUTeam.Team);

        -- So we stick to using BZCC_X logic.
        _Mission.m_UseStockAIPLogic = false;
    elseif (_Mission.m_PastAIP0 == false) then
        -- Use "Stock" logic.
        SetCPUAIPlan(AIPType0);

        -- So we stick to using BZCC_X logic.
        _Mission.m_UseStockAIPLogic = true;
    end

    -- Our first taunt.
    DoTaunt(TAUNTS_GameStart);

    -- Mark Start as done.
    _Mission.m_StartDone = true;
end

function Update()
    -- Keep track of our turns.
    _Mission.m_TurnCounter = _Mission.m_TurnCounter + 1;

    -- Keep track of the player handle.
    _Mission.m_Player = GetPlayerHandle(1);

    -- Start running logic for the CPU team if they are set up.
    if (_Mission.m_CPUTeam ~= nil) then
        _Mission.m_CPUTeam:Run();
    end

    -- This will give the CPU a scrap cheat boost based on difficulty.
    local Turns = _Mission.m_GameTPS * (3 - _Mission.m_Difficulty);

    if (_Mission.m_TurnCounter % Turns == 0) then
        AddScrap(_Mission.m_EnemyTeam, 1);
    end

    -- Check to see who wins.
    if (_Mission.m_StartDone and _Mission.m_Gameover == false) then
        -- CheckWinner();
    end
end

function CheckWinner()
    if (IsAlive(_Mission.m_CPUTeam.Recycler) == false) then
        -- Check to see if anything existing in the RECYCLER team slot.
        local tempH = GetObjectByTeamSlot(_Mission.m_EnemyTeam, DLL_TEAM_SLOT_RECYCLER);

        if (tempH ~= 0) then
            _Mission.m_CPUTeam.Recycler = tempH;
        else
            -- Taunt the player after they win.
            DoTaunt(TAUNTS_CPURecyDestroyed);

            -- Success!
            SucceedMission(GetTime() + 5.0, "instantw.txt");

            -- So we don't loop.
            _Mission.m_Gameover = true;
        end
    elseif (IsAlive(_Mission.m_HumanTeam.Recycler) == false) then
        -- Check to see if anything existing in the RECYCLER team slot.
        local tempH = GetObjectByTeamSlot(_Mission.m_PlayerTeam, DLL_TEAM_SLOT_RECYCLER);

        if (tempH ~= 0) then
            _Mission.m_HumanTeam.Recycler = tempH;
        else
            -- Taunt the player after they win.
            DoTaunt(TAUNTS_HumanRecyDestroyed);

            -- Failed!
            FailMission(GetTime() + 5.0, "instantl.txt");

            -- So we don't loop.
            _Mission.m_Gameover = true;
        end
    end
end