-- This isn't an actual database. This is a mock of a concept to store data at runtime to assist with
-- data manipulation and function execution. We will follow the basic CRUD principles (Create, Read, Update, Delete).

BZCCDatabase = {
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
    DropshipRequestItemTimeToDelete = {
        5 * 60,
        7.5 * 60,
        10 * 60
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
}

return BZCCDatabase;
