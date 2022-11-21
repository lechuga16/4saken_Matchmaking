#pragma semicolon 1
#pragma newdecls required

#include <4saken>
#include <colors>
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <l4d2_skill_detect>
#define PLUGIN_VERSION "0.1"

static const char sTFormat[][] = {
	"skeet",
	"skeetmelee",
	"skeetgl",
	"skeetsniper",
	"chargerlevel",
	"hunterdeadstop",
	"witchcrown",
	"tonguecut",
	"tankrockskeeted",
	"tankrockeaten"
};

static const char sTFormat2[][] = {
	"skeethurt",
	"skeetmeleehurt",
	"skeetsniperhurt"
};

static const char sTFormatAll[][] = {
	"chargerlevelhurt",
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

ConVar
	g_cvarDebug,
	g_cvarEnable,
	g_cvarSkeet,
	g_cvarSkeetMelee,
	g_cvarSkeetGL,
	g_cvarSkeetSniper;
Database
	g_Database;

public Plugin myinfo =
{
	name        = "4saken Skills",
	author      = "lechuga",
	description = "-",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lechuga16/4saken_Matchmaking"


}

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
	g_cvarDebug       = CreateConVar("sm_4saken_skills_debug", "0", "Debug messages", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarEnable      = CreateConVar("sm_4saken_skills_enable", "1", "Enable 4saken_skills", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeet       = CreateConVar("sm_4saken_skills_skeet", "1", "Enable skeet.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetMelee  = CreateConVar("sm_4saken_skills_skeetmelee", "1", "Enable skeet-melee.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetGL     = CreateConVar("sm_4saken_skills_skeetgl", "1", "Enable skeet-grenadelauncher.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSkeetSniper = CreateConVar("sm_4saken_skills_skeetsniper", "1", "Enable skeet-sniper.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(false, "4saken");
}

public void OnSQLConnect(Database db, const char[] error, any data)
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (db == null)
		ThrowError("Error while connecting to database: %s", error);

	g_Database = db;
	if (g_cvarDebug.BoolValue)
		_4saken_log("Connected to database successfully.");

	for (int i = 0; i < sizeof(sTFormat); i++)
	{
		char sQuery[250];
		g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormat[i]);
		g_Database.Query(OnCreateTable, sQuery);
	}
	for (int i = 0; i < sizeof(sTFormat2); i++)
	{
		char sQuery[300];
		g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `chip` INT NOT NULL, `overkill` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormat2[i]);
		g_Database.Query(OnCreateTable, sQuery);
	}
	for (int i = 0; i < sizeof(sTFormatAll); i++)
	{
		char sQuery[500];
		switch (i)
		{
			case 0:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `chargerlevelhurt` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `damage` INT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 1:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `witchcrownhurt` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `damage` INT NOT NULL, `chip` INT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 2:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `smokerselfclear` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `withShove` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 3:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `jockeyhighpounce` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `height` FLOAT NOT NULL, `reportedHigh` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 4:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `deathcharge` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `height` FLOAT NOT NULL, `distance` FLOAT NOT NULL, `wasCarried` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 5:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `boomervomitlanded` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `infected` VARCHAR(64) NOT NULL, `amount` INT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 6:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `specialshoved` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `zombieclass` VARCHAR(64) NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 7:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `bunnyhopstreak` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `streak` INT NOT NULL, `maxvelocity` FLOAT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 8:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `caralarmtriggered` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `CarAlarmTriggerReason` VARCHAR(64) NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 9:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `boomerpop` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `shoveCount` INT NOT NULL, `timeAlive` FLOAT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 10:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `specialclear` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `clearer` VARCHAR(64) NOT NULL, `pinner` VARCHAR(64) NOT NULL, `pinvictim` VARCHAR(64) NOT NULL, `zombieclass` VARCHAR(64) NOT NULL, `timeA` FLOAT NOT NULL, `timeB` FLOAT NOT NULL, `withShove` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
			case 11:
			{
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `hunterhighpounce` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `actualDamage` INT NOT NULL, `calculatedDamage` FLOAT NOT NULL, `height` FLOAT NOT NULL, `reportedHigh` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;");
			}
		}
		g_Database.Query(OnCreateTable, sQuery);
	}
}

public void OnCreateTable(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while creating table: %s", error);
}

public void OnSkeet(int survivor, int hunter)
{
	if (!g_cvarSkeet.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		_4saken_log("Skill detected | OnSkeet | Survivor:%N hunter:%N", survivor, hunter);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (!GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
		StrCat(sSteamID, sizeof(sSteamID), "BOT");

	if (!GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2)))
		StrCat(sSteamID2, sizeof(sSteamID2), "BOT");

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(sTFormat[0], sSteamID, sSteamID2, sMapName);
}

public void OnSkeetMelee(int survivor, int hunter)
{
	if (!g_cvarSkeetMelee.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		_4saken_log("Skill detected | OnSkeetMelee | Survivor:%N hunter:%N", survivor, hunter);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (!GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
		StrCat(sSteamID, sizeof(sSteamID), "BOT");

	if (!GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2)))
		StrCat(sSteamID2, sizeof(sSteamID2), "BOT");

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(sTFormat[1], sSteamID, sSteamID2, sMapName);
}

public void OnSkeetGL(int survivor, int hunter)
{
	if (!g_cvarSkeetGL.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		_4saken_log("Skill detected | OnSkeetGL | Survivor:%N hunter:%N", survivor, hunter);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (!GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
		StrCat(sSteamID, sizeof(sSteamID), "BOT");

	if (!GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2)))
		StrCat(sSteamID2, sizeof(sSteamID2), "BOT");

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(sTFormat[1], sSteamID, sSteamID2, sMapName);
}

public void OnSkeetSniper(int survivor, int hunter)
{
	if (!g_cvarSkeetSniper.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		_4saken_log("Skill detected | OnSkeetSniper | Survivor:%N hunter:%N", survivor, hunter);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (!GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
		StrCat(sSteamID, sizeof(sSteamID), "BOT");

	if (!GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2)))
		StrCat(sSteamID2, sizeof(sSteamID2), "BOT");

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(sTFormat[1], sSteamID, sSteamID2, sMapName);
}

void QueryFormat(const char[] sTable, const char[] sSteamID, const char[] sSteamID2, const char[] sMapName)
{
	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected) VALUES ('%s', '%s', '%s');", sTable, sMapName, sSteamID, sSteamID2);
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnUpdateTable(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error OnUpdateTable: %s", error);
}

/*
QueryFormat - 10
- void OnSkeet(int survivor, int hunter)
- void OnSkeetMelee(int survivor, int hunter)
- void OnSkeetGL(int survivor, int hunter)
- void OnSkeetSniper(int survivor, int hunter)
void OnChargerLevel(int survivor, int charger)
void OnHunterDeadstop(int survivor, int hunter)
void OnWitchCrown(int survivor, int damage)
void OnTongueCut(int survivor, int smoker)
void OnTankRockSkeeted(int survivor, int tank)
void OnTankRockEaten(int tank, int survivor)

QueryFormat2 - 2
void OnSkeetHurt(int survivor, int hunter, int damage, bool isOverkill)
void OnSkeetMeleeHurt(int survivor, int hunter, int damage, bool isOverkill)
void OnSkeetSniperHurt(int survivor, int hunter, int damage, bool isOverkill)

QueryFormatAll
void OnChargerLevelHurt(int survivor, int charger, int damage)
void OnWitchCrownHurt(int survivor, int damage, int chipdamage)
void OnSmokerSelfClear(int survivor, int smoker, bool withShove)
void OnJockeyHighPounce(int jockey, int victim, float height, bool reportedHigh)
void OnDeathCharge(int charger, int survivor, float height, float distance, bool wasCarried)
void OnBoomerVomitLanded(int boomer, int amount)
void OnSpecialShoved(int survivor, int infected, int zombieClass)
void OnBunnyHopStreak(int survivor, int streak, float maxVelocity)
void OnCarAlarmTriggered(int survivor, int infected, CarAlarmTriggerReason reason)
void OnBoomerPop(int survivor, int boomer, int shoveCount, float timeAlive)
void OnSpecialClear(int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove)
void OnHunterHighPounce(int hunter, int survivor, int actualDamage, float calculatedDamage, float height, bool reportedHigh)
*/