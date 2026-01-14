-- This isn't an actual database. This is a mock of a concept to store data at runtime to assist with
-- data manipulation and function execution. We will follow the basic CRUD principles (Create, Read, Update, Delete).

BZCCDatabase = {
    AIUnitTypes =
    {
        COMMANDER = "Commander",
        CARRIER = "Carrier",
        TURRET = "Turret",
        PATROL = "Patrol",
        BASE_PATROL = "BasePatrol",
        ANTI_AIR = "AntiAir",
        MINION = "Minion",
        ASSAULT_SERVICE = "AssaultService"
    },
    AnimalStates =
    {
        GRAZING = "Grazing",
        ATTACKING = "Attacking",
        FLEEING = "Fleeing",
        FOLLOWING = "Following",
    },
    BaneMaps =
    {
        "dunesi.trn",
        "chill.trn",
        "ground4.trn",
        "ground0.trn",
        "MPIIsland.trn",
        "sea_battle.trn"
    },
    CPUNames =
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
    },
    DropshipRequestItemTimeToDelete =
    {
        5 * 60,
        7.5 * 60,
        10 * 60
    },
    MireMaps =
    {
        "bridges.trn",
        "mpicanyons.trn",
        "iacirclebzcc.trn",
        "iadustbzcc.trn",
        "iaentrapbzcc.trn",
        "iafirebzcc.trn",
        "iafortbzcc.trn",
        "iaghzonebzcc.trn"
    },
    ShellVariables =
    {
        CAN_RESPAWN = "options.instant.bool0",
        INTRO_SCENE_ENABLED = "options.instant.introScene",
        RTS_MODE_ENABLED = "options.instant.rtsMode",
        WILDLIFE_ENABLED = "options.instant.wildlife",
        HIS_RACE = "options.instant.hisrace",
        MY_RACE = "options.instant.myrace",
        DIFFICULTY = "options.instant.difficulty",
        AIP_STRING = "options.instant.string0",
        COMMANDER_ENABLED = "options.instant.aiCommander"
    }
}

return BZCCDatabase;
