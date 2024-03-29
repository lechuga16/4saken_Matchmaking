#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <forsaken>
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <l4d2_skill_detect>
#define REQUIRE_PLUGIN

/*****************************************************************
            G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION "0.1"

ConVar
	g_cvarSkeet,
	g_cvarSkeetMelee,
	g_cvarSkeetGL,
	g_cvarSkeetSniper,
	g_cvarChargerLevel,
	g_cvarHunterDeadstop,
	g_cvarTongueCut,
	g_cvarTankRockSkeeted,
	g_cvarTankRockEaten,
	g_cvarSkeetHurt,
	g_cvarSkeetMeleeHurt,
	g_cvarSkeetSniperHurt,
	g_cvarChargerLevelHurt,
	g_cvarWitchCrown,
	g_cvarWitchCrownHurt,
	g_cvarSmokerSelfClear,
	g_cvarJockeyHighPounce,
	g_cvarDeathCharge,
	g_cvarBoomerVomitLanded,
	g_cvarSpecialShoved,
	g_cvarBunnyHopStreak,
	g_cvarCarAlarmTriggered,
	g_cvarBoomerPop,
	g_cvarSpecialClear,
	g_cvarHunterHighPounce;
	
Database
	g_ForsakenDB;

enum TFormat
{
	skeet           = 0,
	skeetmelee      = 1,
	skeetgl         = 2,
	skeetsniper     = 3,
	chargerlevel    = 4,
	hunterdeadstop  = 5,
	tonguecut       = 6,
	tankrockskeeted = 7,
	tankrockeaten   = 8,

	TFormat_Size = 9
};

enum TFormat2
{
	skeethurt       = 0,
	skeetmeleehurt  = 1,
	skeetsniperhurt = 2,

	TFormat2_Size = 3
};

enum TFormatAll
{
	chargerlevelhurt  = 0,
	witchcrown        = 1,
	witchcrownhurt    = 2,
	smokerselfclear   = 3,
	jockeyhighpounce  = 4,
	deathcharge       = 5,
	boomervomitlanded = 6,
	specialshoved     = 7,
	bunnyhopstreak    = 8,
	caralarmtriggered = 9,
	boomerpop         = 10,
	specialclear      = 11,
	hunterhighpounce  = 12,

	TFormatAll_Size = 13
};

char sTFormat[TFormat_Size][] = {
	"skeet",
	"skeetmelee",
	"skeetgl",
	"skeetsniper",
	"chargerlevel",
	"hunterdeadstop",
	"tonguecut",
	"tankrockskeeted",
	"tankrockeaten"
};

char sTFormat2[TFormat2_Size][] = {
	"skeethurt",
	"skeetmeleehurt",
	"skeetsniperhurt"
};

char sTFormatAll[TFormatAll_Size][] = {
	"chargerlevelhurt",
	"witchcrown",
	"witchcrownhurt",
	"smokerselfclear",
	"jockeyhighpounce",
	"deathcharge",
	"boomervomitlanded",
	"specialshoved",
	"bunnyhopstreak",
	"caralarmtriggered",
	"boomerpop",
	"specialclear",
	"hunterhighpounce"
};

/*****************************************************************
            L I B R A R Y   I N C L U D E S
*****************************************************************/

#include "forsaken/Skill_TablesFormat.sp"
#include "forsaken/Skill_TablesFormat2.sp"
#include "forsaken/Skill_TablesFormatAll.sp"

/*****************************************************************
            P L U G I N   I N F O
*****************************************************************/

public Plugin myinfo =
{
	name        = "Forsaken Skills",
	author      = "lechuga",
	description = "Manages the data generated by l4d2 skill detect",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lechuga16/4saken_Matchmaking"
}

/*****************************************************************
            F O R W A R D   P U B L I C S
*****************************************************************/

public APLRes
	AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
	}

	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart()
{
	Database.Connect(OnSQLConnect, "4sakenskill");
	CreateConVar("sm_skills_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug             = CreateConVar("sm_skills_debug", "0", "Debug messages.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarEnable            = CreateConVar("sm_skills_enable", "1", "Enable 4saken_skills.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeet             = CreateConVar("sm_skills_skeet", "1", "Enable Skeet.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetMelee        = CreateConVar("sm_skills_skeetmelee", "1", "Enable Skeet-Melee.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetGL           = CreateConVar("sm_skills_skeetgl", "1", "Enable Skeet-GrenadeLauncher.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetSniper       = CreateConVar("sm_skills_skeetsniper", "1", "Enable Skeet-Sniper.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarChargerLevel      = CreateConVar("sm_skills_chargerlevel", "1", "Enable Charger Level.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarHunterDeadstop    = CreateConVar("sm_skills_hunterdeadstop", "1", "Enable Hunter DeadStop.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarWitchCrown        = CreateConVar("sm_skills_witchcrown", "1", "Enable Witch Crown.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarTongueCut         = CreateConVar("sm_skills_tonguecut", "1", "Enable Tongue Cut.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarTankRockSkeeted   = CreateConVar("sm_skills_rockskeeted", "1", "Enable Skeet-Rock.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarTankRockEaten     = CreateConVar("sm_skills_tankrockeaten", "1", "Enable Skeet-Rock Eaten.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetHurt         = CreateConVar("sm_skills_skeethurt", "1", "Enable Skeet-Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetMeleeHurt    = CreateConVar("sm_skills_skeetmeleehurt", "1", "Enable Skeet-Melee Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetSniperHurt   = CreateConVar("sm_skills_skeetsniperhurt", "1", "Enable Skeet-Sniper Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarChargerLevelHurt  = CreateConVar("sm_skills_chargerlevelhurt", "1", "Enable Charger-Level Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarWitchCrown        = CreateConVar("sm_skills_witchcrown", "1", "Enable Witch-Crown.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarWitchCrownHurt    = CreateConVar("sm_skills_witchcrownhurt", "1", "Enable Witch-Crown Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSmokerSelfClear   = CreateConVar("sm_skills_smokerselfclear", "1", "Enable Smoker SelfClear.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarJockeyHighPounce  = CreateConVar("sm_skills_jockeyhighpounce", "1", "Enable Jockey HighPounce.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarDeathCharge       = CreateConVar("sm_skills_deathcharger", "1", "Enable Death-Charger.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarBoomerVomitLanded = CreateConVar("sm_skills_boomervomitlanded", "1", "Enable Boomer VomitLanded.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSpecialShoved     = CreateConVar("sm_skills_specialshoved", "1", "Enable Special Shoved.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarBunnyHopStreak    = CreateConVar("sm_skills_bunnyhopstreak", "1", "Enable Bunny HopStreak.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarCarAlarmTriggered = CreateConVar("sm_skills_caralarmtriggered", "1", "Enable CarAlarm Triggered.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarBoomerPop         = CreateConVar("sm_skills_boomerpop", "1", "Enable Boomer Pop.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSpecialClear      = CreateConVar("sm_skills_specialclear", "1", "Enable Special Clear.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarHunterHighPounce  = CreateConVar("sm_skills_hunterhighpounce", "1", "Enable Hunter HighPounce.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegAdminCmd("sm_skill_install", Cmd_Install, ADMFLAG_ROOT, "Create the sql tables.");
	RegConsoleCmd("sm_skill", Command_Skill, "Skill command.");
	AutoExecConfig(true, "forsaken_skills");
}

public Action Command_Skill(int iClient, int iArg)
{
	return Plugin_Handled;
}

public Action Cmd_Install(int iClient, int iArg)
{
	/*
		CREATE VIEW IF NOT EXISTS `view_Skeets` AS
		SELECT
			`sk`.`survivor` AS `skeet`,
			`sk_h`.`survivor` AS `skeethurt`,
			`skm`.`survivor` AS `melee`,
			`skm_h`.`survivor` AS `meleehurt`,
			`skp`.`survivor` AS `sniper`,
			`skp_h`.`survivor` AS `sniperhurt`
		FROM `skeet` AS `sk`
		LEFT OUTER JOIN `skeethurt` AS `sk_h` ON `sk`.`id` LIKE `sk_h`.`id`
		LEFT OUTER JOIN `skeetmelee` AS `skm` ON `sk`.`id` LIKE `skm`.`id`
		LEFT OUTER JOIN `skeetmeleehurt` AS `skm_h` ON `sk`.`id` LIKE `skm_h`.`id`
		LEFT OUTER JOIN `skeetsniper` AS `skp` ON `sk`.`id` LIKE `skp`.`id`
		LEFT OUTER JOIN `skeetsniperhurt` AS `skp_h` ON `sk`.`id` LIKE `skp_h`.`id`
		UNION ALL
		SELECT
			`sk`.`survivor` AS `skeet`,
			`sk_h`.`survivor` AS `skeethurt`,
			`skm`.`survivor` AS `melee`,
			`skm_h`.`survivor` AS `meleehurt`,
			`skp`.`survivor` AS `sniper`,
			`skp_h`.`survivor` AS `sniperhurt`
		FROM `skeet` AS `sk`
		RIGHT OUTER JOIN `skeethurt` AS `sk_h` ON `sk`.`id` LIKE `sk_h`.`id`
		RIGHT OUTER JOIN `skeetmelee` AS `skm` ON `sk`.`id` LIKE `skm`.`id`
		RIGHT OUTER JOIN `skeetmeleehurt` AS `skm_h` ON `sk`.`id` LIKE `skm_h`.`id`
		RIGHT OUTER JOIN `skeetsniper` AS `skp` ON `sk`.`id` LIKE `skp`.`id`
		RIGHT OUTER JOIN `skeetsniperhurt` AS `skp_h` ON `sk`.`id` LIKE `skp_h`.`id`
	*/
	return Plugin_Handled;
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

public void OnSQLConnect(Database db, const char[] error, any data)
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (db == null)
		ThrowError("Error while connecting to database: %s", error);

	g_ForsakenDB = db;

	SQLTablesFormat();
	SQLTablesFormat2();
	SQLTablesFormatAll();
}

public void OnCreateTable(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while creating table: %s", error);
}
