#pragma semicolon 1
#pragma newdecls required

#include <4saken>
#include <colors>
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <l4d2_skill_detect>
#define PLUGIN_VERSION "0.1"

/*****************************************************************
            G L O B A L   V A R S
*****************************************************************/
ConVar
	g_cvarDebug,
	g_cvarEnable,
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
	g_Database;

char sTFormat[9][] = {
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

char sTFormat2[3][] = {
	"skeethurt",
	"skeetmeleehurt",
	"skeetsniperhurt"
};

char sTFormatAll[13][] = {
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

char L4D2ZombieClassname[9][] = {
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
	"witch",
	"tank",
	"error_bad_L4D2ZombieClassType"
};

/*****************************************************************
            P L U G I N   I N F O
*****************************************************************/
public Plugin myinfo =
{
	name        = "4saken Skills",
	author      = "lechuga",
	description = "-",
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

public void OnPluginStart()
{
	Database.Connect(OnSQLConnect, "4sakenskill");
	CreateConVar("sm_4saken_skills_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug             = CreateConVar("sm_4saken_skills_debug", "0", "Debug messages.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarEnable            = CreateConVar("sm_4saken_skills_enable", "1", "Enable 4saken_skills.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeet             = CreateConVar("sm_4saken_skills_skeet", "1", "Enable Skeet.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetMelee        = CreateConVar("sm_4saken_skills_skeetmelee", "1", "Enable Skeet-Melee.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetGL           = CreateConVar("sm_4saken_skills_skeetgl", "1", "Enable Skeet-GrenadeLauncher.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetSniper       = CreateConVar("sm_4saken_skills_skeetsniper", "1", "Enable Skeet-Sniper.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarChargerLevel      = CreateConVar("sm_4saken_skills_chargerlevel", "1", "Enable Charger Level.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarHunterDeadstop    = CreateConVar("sm_4saken_skills_hunterdeadstop", "1", "Enable Hunter DeadStop.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarWitchCrown        = CreateConVar("sm_4saken_skills_witchcrown", "1", "Enable Witch Crown.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarTongueCut         = CreateConVar("sm_4saken_skills_tonguecut", "1", "Enable Tongue Cut.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarTankRockSkeeted   = CreateConVar("sm_4saken_skills_rockskeeted", "1", "Enable Skeet-Rock.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarTankRockEaten     = CreateConVar("sm_4saken_skills_tankrockeaten", "1", "Enable Skeet-Rock Eaten.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetHurt         = CreateConVar("sm_4saken_skills_skeethurt", "1", "Enable Skeet-Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetMeleeHurt    = CreateConVar("sm_4saken_skills_skeetmeleehurt", "1", "Enable Skeet-Melee Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetSniperHurt   = CreateConVar("sm_4saken_skills_skeetsniperhurt", "1", "Enable Skeet-Sniper Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarChargerLevelHurt  = CreateConVar("sm_4saken_skills_chargerlevelhurt", "1", "Enable Charger-Level Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarWitchCrown        = CreateConVar("sm_4saken_skills_witchcrown", "1", "Enable Witch-Crown.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarWitchCrownHurt    = CreateConVar("sm_4saken_skills_witchcrownhurt", "1", "Enable Witch-Crown Hurt.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSmokerSelfClear   = CreateConVar("sm_4saken_skills_smokerselfclear", "1", "Enable Smoker SelfClear.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarJockeyHighPounce  = CreateConVar("sm_4saken_skills_jockeyhighpounce", "1", "Enable Jockey HighPounce.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarDeathCharge       = CreateConVar("sm_4saken_skills_deathcharger", "1", "Enable Death-Charger.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarBoomerVomitLanded = CreateConVar("sm_4saken_skills_boomervomitlanded", "1", "Enable Boomer VomitLanded.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSpecialShoved     = CreateConVar("sm_4saken_skills_specialshoved", "1", "Enable Special Shoved.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarBunnyHopStreak    = CreateConVar("sm_4saken_skills_bunnyhopstreak", "1", "Enable Bunny HopStreak.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarCarAlarmTriggered = CreateConVar("sm_4saken_skills_caralarmtriggered", "1", "Enable CarAlarm Triggered.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarBoomerPop         = CreateConVar("sm_4saken_skills_boomerpop", "1", "Enable Boomer Pop.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSpecialClear      = CreateConVar("sm_4saken_skills_specialclear", "1", "Enable Special Clear.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarHunterHighPounce  = CreateConVar("sm_4saken_skills_hunterhighpounce", "1", "Enable Hunter HighPounce.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig(false, "4saken");
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

	g_Database = db;
	if (g_cvarDebug.BoolValue)
		_4saken_log("Connected to database successfully.");

	SQLTablesFormat();
	SQLTablesFormat2();
	SQLTablesFormatAll();
}

public void OnCreateTable(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while creating table: %s", error);
}

/*****************************************************************
            L I B R A R Y   I N C L U D E S
*****************************************************************/
#include "4saken/Skill_TablesFormat.sp"
#include "4saken/Skill_TablesFormat2.sp"
#include "4saken/Skill_TablesFormatAll.sp"

/*****************************************************************
            P L U G I N   F U N C T I O N S
*****************************************************************/
public void OnUpdateTable(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error OnUpdateTable: %s", error);
}
