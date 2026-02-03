-- This isn't an actual database. This is a mock of a concept to store data at runtime to assist with
-- data manipulation and function execution. We will follow the basic CRUD principles (Create, Read, Update, Delete).

BZCCDatabase = {
    AICommands = {
        CMD_NONE = 0,
        CMD_SELECT = 1,
        CMD_STOP = 2,
        CMD_GO = 3,
        CMD_ATTACK = 4,
        CMD_FOLLOW = 5,
        CMD_FORMATION = 6, -- not used anywhere in code.
        CMD_PICKUP = 7,
        CMD_DROPOFF = 8,
        CMD_UNDEPLOY = 9,
        CMD_DEPLOY = 10,
        CMD_NO_DEPLOY = 11, -- Used by crigs, deploybuildings to indicate they can't do that there
        CMD_GET_REPAIR = 12,
        CMD_GET_RELOAD = 13,
        CMD_GET_WEAPON = 14,
        CMD_GET_CAMERA = 15, -- Human players only.
        CMD_GET_BOMB = 16,
        CMD_DEFEND = 17,
        CMD_RESCUE = 18,
        CMD_RECYCLE = 19,
        CMD_SCAVENGE = 20,
        CMD_HUNT = 21,
        CMD_BUILD = 22,
        CMD_PATROL = 23,
        CMD_STAGE = 24,
        CMD_SEND = 25,
        CMD_GET_IN = 26,
        CMD_LAY_MINES = 27,
        CMD_LOOK_AT = 28,
        CMD_SERVICE = 29,
        CMD_UPGRADE = 30,
        CMD_DEMOLISH = 31,
        CMD_POWER = 32,
        CMD_BACK = 33,
        CMD_DONE = 34,
        CMD_CANCEL = 35,
        CMD_SET_GROUP = 36,
        CMD_SET_TEAM = 37,
        CMD_SEND_GROUP = 38,
        CMD_TARGET = 39,
        CMD_INSPECT = 40,
        CMD_SWITCHTEAM = 41,
        CMD_INTERFACE = 42,
        CMD_LOGOFF = 43,
        CMD_AUTOPILOT = 44,
        CMD_MESSAGE = 45,
        CMD_CLOSE = 46,
        CMD_MORPH_SETDEPLOYED = 47,   -- For morphtanks
        CMD_MORPH_SETUNDEPLOYED = 48, -- For morphtanks
        CMD_MORPH_UNLOCK = 49,        -- For morphtanks
        CMD_BAILOUT = 50,
        CMD_BUILD_ROTATE = 51,        -- Update building rotations by 90 degrees.
        CMD_CMDPANEL_SELECT = 52,
        CMD_CMDPANEL_DESELECT = 53
    },
    AIUnitTypes = {
        COMMANDER = "Commander",
        CARRIER = "Carrier",
        TURRET = "Turret",
        PATROL = "Patrol",
        BASE_PATROL = "BasePatrol",
        ANTI_AIR = "AntiAir",
        MINION = "Minion",
        ASSAULT_SERVICE = "AssaultService"
    },
    AnimalStates = {
        GRAZING = "Grazing",
        ATTACKING = "Attacking",
        FLEEING = "Fleeing",
        FOLLOWING = "Following",
    },
    BaneMaps = {
        "dunesi.trn",
        "chill.trn",
        "ground4.trn",
        "ground0.trn",
        "MPIIsland.trn",
        "sea_battle.trn"
    },
    Categories = {
        TEAM_SLOT_RECYCLER = 1,
        TEAM_SLOT_FACTORY = 2,
        TEAM_SLOT_ARMORY = 3,
        TEAM_SLOT_PRODUCER4 = 4,
        TEAM_SLOT_PRODUCER5 = 5,
        TEAM_SLOT_PRODUCER6 = 6,
        TEAM_SLOT_PRODUCER7 = 7,
        TEAM_SLOT_PRODUCER8 = 8,
        TEAM_SLOT_PRODUCER9 = 9,
        TEAM_SLOT_TRAINING = 10,
        TEAM_SLOT_BOMBERBAY = 11,
        TEAM_SLOT_SERVICE = 12,
        TEAM_SLOT_TECHCENTER = 13,
        TEAM_SLOT_COMMTOWER = 14,
        TEAM_SLOT_POWER = 15,
        TEAM_SLOT_COMM = 16,
        TEAM_SLOT_EXTRACTOR = 17,
        TEAM_SLOT_JAMMER = 18,
        TEAM_SLOT_SENSOR = 19,
        TEAM_SLOT_GUNTOWER = 20,
        TEAM_SLOT_SHIELDTOWER = 21,
        TEAM_SLOT_OFFENSE = 22,
        TEAM_SLOT_DEFENSE = 23,
        TEAM_SLOT_UTILITY = 24,
        TEAM_SLOT_SCAVENGER = 25,
        TEAM_SLOT_CONSTRUCT = 26,
        TEAM_SLOT_BOMBER = 27
    },
    CPUNames = {
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
    },
    Difficulty = {
        DIFFICULTY_EASY = 1,
        DIFFICULTY_MEDIUM = 2,
        DIFFICULTY_HARD = 3
    },
    DropshipRequestItemTimeToDelete = {
        5 * 60,
        7.5 * 60,
        10 * 60
    },
    EventReturnCodes = {
        DoEjectPilot = 0,           -- Do 'standard' eject
        DoRespawnSafest = 1,        -- Respawn a 'PLAYER' at safest spawnpoint
        DLLHandled = 2,             -- DLL handled actions. Do nothing ingame
        DoGameOver = 3,             -- Game over, man.
        PREGETIN_DENY = 0,          -- Deny the pilot entry to the craft
        PREGETIN_ALLOW = 1,         -- Allow the pilot entry
        PREPICKUPPOWERUP_DENY = 0,  -- Deny the powerup from being picked up
        PREPICKUPPOWERUP_ALLOW = 1, -- Allow the powerup to be picked up
        PRESNIPE_KILLPILOT = 0,     -- Kill the pilot (1.0-1.3.6.4 default). Does still pass this to bullet hit code, where damage might also be applied
        PRESNIPE_ONLYBULLETHIT = 1, -- Do not kill the pilot. Does still pass this to bullet hit code, where damage might also be applied
    },
    Factions = {
        ISDF = 'i',
        SCION = 'f'
    },
    ISDFWeaponTable = {
        -- Cannons
        ATStabber = 'gatstab_c',
        PLStabber = 'gplstab_c',
        SPStabber = 'gspstab_c',
        Plasma = 'gplasma_c',
        Blast = 'gblast_c',
        -- Guns
        Minigun = 'gminigun_c',
        Pummel = 'gpummel_c',
        Laser = 'glaser_c',
        Chain = 'gchain_c',
        -- Missiles
        FAF = 'gfafmsl_c',
        Shadower = 'gshadow_c',
        Tag = 'gtaggun_c',
        -- Mortars
        Mortar = 'gmortar',
        Splinter = 'gsplint',
        MDM = 'gmdmgun'
    },
    MireMaps = {
        "bridges.trn",
        "mpicanyons.trn",
        "iacirclebzcc.trn",
        "iadustbzcc.trn",
        "iaentrapbzcc.trn",
        "iafirebzcc.trn",
        "iafortbzcc.trn",
        "iaghzonebzcc.trn"
    },
    Missions = {
        ISDF01 = "This is Not a Drill",
        ISDF02 = "A Simple S & R",
        ISDF03 = "We Have Hostiles",
        ISDF04 = "Too Hot",
        ISDF05 = "The Dark Planet",
        ISDF06 = "The Wormhole",
        ISDF07 = "Through the Looking Glass",
        ISDF08 = "Get Help",
        ISDF09 = "Rumble in the Jungle",
        ISDF10 = "Snow Blind",
        ISDF11 = "On Thin Ice",
        ISDF12 = "Counterattack",
        ISDF13 = "Payback",
        ISDF14 = "Fanning the Fire",
        ISDF15 = "A Traitor's Fate",
        ISDF16 = "Hole in One",
        ISDF17 = "Core",
        SCION01 = "Transformation",
        SCION02 = "Ambush",
        SCION03 = "Crystals",
        SCION04 = "Escort",
        SCION05 = "An Unlikely Rescue",
        SCION06 = "The AAN",
        SCION07 = "Braddock"
    },
    ScionWeaponTable = {
        -- Cannons
        Plasma = 'gsplasma_c',
        Quill = 'gquill_c',
        Sonic = 'gsonic_c',
        Arc = 'garc_c',
        -- Guns
        Ion = 'giongn_c',
        EMP = 'glock_c',
        Gauss = 'ggauss_c',
        -- Missiles
        Stinger = 'stinger_c',
        Multilock = 'gmlock_c',
        -- Shield
        Absorb = 'gabsorb',
        Deflect = 'gdeflect',
        Stasis = 'gshield'
    },
    ShellVariables = {
        CAN_RESPAWN = "options.instant.bool0",
        INTRO_SCENE_ENABLED = "options.instant.introScene",
        RTS_MODE_ENABLED = "options.instant.rtsMode",
        WILDLIFE_ENABLED = "options.instant.wildlife",
        HIS_RACE = "options.instant.hisrace",
        MY_RACE = "options.instant.myrace",
        DIFFICULTY = "options.instant.difficulty",
        AIP_STRING = "options.instant.string0",
        COMMANDER_ENABLED = "options.instant.aiCommander"
    },
    SubtitlePanelSizes = {
        SubtitlesPanel = 0,
        SubtitlesPanelMedium = 1,
        SubtitlesPanelLarge = 2
    },
    TeamRelationships = {
        TEAMRELATIONSHIP_INVALIDHANDLE = 0, -- One or both handles is invalid
        TEAMRELATIONSHIP_SAMETEAM = 1,      -- Team # for both items is the same
        TEAMRELATIONSHIP_ALLIEDTEAM = 2,    -- Team # isn't identical, but teams are allied
        TEAMRELATIONSHIP_ENEMYTEAM = 3      --Team # isn't identical, and teams are enemies
    }
}

return BZCCDatabase;
