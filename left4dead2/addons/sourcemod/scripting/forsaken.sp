#pragma semicolon 1
#pragma newdecls required

#include <forsaken>
#include <colors>
#include <json>
#include <Regex>
#include <sourcemod>
#include <system2>
#undef REQUIRE_PLUGIN
#include <confogl>
#define REQUIRE_PLUGIN

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION	"0.1"
#define MAX_PLAYER_TEAM 4
#define PREFIX			"[{olive}4saken{default}]"

ConVar
	g_cvarDebug,
	g_cvarEnable;

PlayerBasic g_Players[ForsakenTeam][MAX_PLAYER_TEAM];

char
	g_sURL[256],
	g_sIPv4[32],
	g_sPatchIP[64],
	g_sMapName[32] = "c5m1_waterfront_sndscape";

int
	g_iQueueID = 0,
	g_iPort;

bool g_bGetMatch = true;

// TypeMatch g_TypeMatch = invalid;

/*****************************************************************
			L I B R A R Y   I N C L U D E S
*****************************************************************/

#include "forsaken/forsaken_native.sp"
#include "forsaken/forsaken_web.sp"

/*****************************************************************
			P L U G I N   I N F O
*****************************************************************/
public Plugin myinfo =
{
	name		= "Forsaken Core",
	author		= "lechuga",
	description = "Core for forsaken plugins, distributes relevant information",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/lechuga16/4saken_Matchmaking"


}

public APLRes
	AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
		return APLRes_Failure;
	}

	//CreateNative("fkn_log", Native_Log);
	// CreateNative("fkn_TypeMatch", Native_TypeMatch);
	// CreateNative("fkn_QueueID", Native_QueueID);
	// CreateNative("fkn_SteamIDTA", Native_SteamIDTA);
	// CreateNative("fkn_SteamIDTB", Native_SteamIDTB);
	CreateNative("fkn_NameTA", Native_NameTA);
	CreateNative("fkn_NameTB", Native_NameTB);
	//CreateNative("fkn_GetIPv4", Native_GetIPv4);
	//CreateNative("fkn_MapName", Native_MapName);
	RegPluginLibrary("forsaken");
	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public void OnPluginStart()
{
	CreateConVar("sm_fkn_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug	 = CreateConVar("sm_fkn_debug", "0", "Debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarEnable = CreateConVar("sm_fkn_enable", "1", "Activate forsaken", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_fkn_showip", Cmd_ShowIP, "Get ip and port server");
	RegAdminCmd("sm_fkn_playersinfo", Cmd_PlayersInfo, ADMFLAG_GENERIC, "Shows the name and SteamID of the players");
	RegAdminCmd("sm_fkn_downloadCache", Cmd_DownloadCache, ADMFLAG_GENERIC, "Download cache match");
	RegAdminCmd("sm_fkn_deleteCache", Cmd_DeleteCache, ADMFLAG_GENERIC, "Delete cache match");
	RegAdminCmd("sm_fkn_updatecache", Cmd_UpdateCache, ADMFLAG_GENERIC, "Update cache match");

	AutoExecConfig(true, "forsaken");

	g_iPort = FindConVar("hostport").IntValue;
	BuildPath(Path_SM, g_sPatchIP, sizeof(g_sPatchIP), DIR_IP);
	JSON_Check();
	GetIPv4();
}

public void OnPluginEnd()
{
	/*
	if (!g_cvarEnable.BoolValue)
		return;

	char
		sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_CACHEMATCH);

	if(FileExists(sPatch))
		DeleteFile(sPatch);
		*/
}

public void OnMapStart()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (g_bGetMatch)
	{
		g_bGetMatch = !g_bGetMatch;
		GetMatch();
	}
}

public void OnMapEnd()
{
	if (!g_cvarEnable.BoolValue || !LGO_IsMatchModeLoaded())
		return;

	char
		sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_CACHEMATCH);

	/*
	if(FileExists(sPatch))
		DeleteFile(sPatch);
		*/
}

public void OnClientPutInServer(int iClient)
{
	if (!g_cvarEnable.BoolValue || LGO_IsMatchModeLoaded())
		return;

	if (IsFakeClient(iClient))
		return;

	CreateTimer(2.0, Timer_GetMatch, iClient);
	if (g_bGetMatch)
	{
		g_bGetMatch = !g_bGetMatch;
		GetMatch();
	}
}

public Action Timer_GetMatch(Handle timer, int iClient)
{
	if (!g_bGetMatch)
		g_bGetMatch = !g_bGetMatch;
	return Plugin_Stop;
}

public Action Cmd_ShowIP(int iClient, int iArgs)
{
	if (iArgs != 0)
		CReplyToCommand(iClient, "Usage: sm_fkn_showip");

	char sIp[64];
	sIp = fkn_GetIP();

	CReplyToCommand(iClient, "%s ServerIP: {green}%s{default}:{green}%d{default}", PREFIX, sIp, g_iPort);
	CReplyToCommand(iClient, "%s ServerIPv4: {green}%s{default}:{green}%d{default}", PREFIX, g_sIPv4, g_iPort);
	return Plugin_Handled;
}

public Action Cmd_PlayersInfo(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_fkn_playersinfo");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%s QueueID: {green}%d{default}", PREFIX, g_iQueueID);
	CReplyToCommand(iClient, "%s MapName: {green}%s{default}", PREFIX, g_sMapName);

	CReplyToCommand(iClient, "%s TeamA:\n({blue}%s{default}:%s) ({blue}%s{default}:%s)\n({blue}%s{default}:%s) ({blue}%s{default}:%s)",
					PREFIX, g_Players[TeamA][0].name, g_Players[TeamA][0].steamid,
					g_Players[TeamA][1].name, g_Players[TeamA][1].steamid,
					g_Players[TeamA][2].name, g_Players[TeamA][2].steamid,
					g_Players[TeamA][3].name, g_Players[TeamA][3].steamid);

	CReplyToCommand(iClient, "%s TeamB:\n({blue}%s{default}:%s) ({blue}%s{default}:%s)\n({blue}%s{default}:%s) ({blue}%s{default}:%s)",
					PREFIX, g_Players[TeamB][0].name, g_Players[TeamB][0].steamid,
					g_Players[TeamB][1].name, g_Players[TeamB][1].steamid,
					g_Players[TeamB][2].name, g_Players[TeamB][2].steamid,
					g_Players[TeamB][3].name, g_Players[TeamB][3].steamid);

	return Plugin_Handled;
}

public Action Cmd_DownloadCache(int iClient, int iArgs)
{
	GetMatch();
	CReplyToCommand(iClient, "%s Downloading cache match...", PREFIX);
	return Plugin_Handled;
}

public Action Cmd_DeleteCache(int iClient, int iArgs)
{
	char
		sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_CACHEMATCH);

	if(FileExists(sPatch))
		DeleteFile(sPatch);

	CReplyToCommand(iClient, "%s Cache match deleted", PREFIX);
	return Plugin_Handled;
}

public Action Cmd_UpdateCache(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_fkn_updatecache");
		return Plugin_Handled;
	}

	if (g_bGetMatch)
	{
		CReplyToCommand(iClient, "%s Cache match is already updating", PREFIX);
		return Plugin_Handled;
	}

	g_bGetMatch = !g_bGetMatch;
	GetMatch();
	CReplyToCommand(iClient, "%s Cache match updated", PREFIX);
	return Plugin_Handled;
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief checks for the existence of the "configs/forsaken/IP.json" file.
 *     if it does not exist, it creates it.
 *
 * @noreturn
 */
public void JSON_Check()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (FileExists(g_sPatchIP))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("%s Not found", DIR_IP);

	JSON_Create();
}

/**
 * @brief creates the "configs/forsaken/IP.json" file.
 *
 * @noreturn
 */
public void JSON_Create()
{
	char		output[32];

	JSON_Object JoIp = new JSON_Object();
	JoIp.SetString("IP", "0.0.0.0");
	JoIp.Encode(output, sizeof(output));

	if (!FileExists(g_sPatchIP))
	{
		fkn_log("Error: %s Invalid file path", DIR_IP);
		return;
	}

	json_write_to_file(JoIp, g_sPatchIP, JSON_ENCODE_PRETTY);

	if (g_cvarDebug.BoolValue)
		fkn_log("%s Created !", DIR_IP);

	json_cleanup_and_delete(JoIp);
}