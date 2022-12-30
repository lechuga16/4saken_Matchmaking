#pragma semicolon 1
#pragma newdecls required

#include <forsaken>
#include <colors>
#include <json>
#include <Regex>
#include <sourcemod>
#include <system2>

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION	"0.1"
#define MAX_PLAYER_TEAM 4
#define PREFIX "[{olive}4saken{default}]"

ConVar
	g_cvarDebug;

PlayerInfo
	g_PlayersTA[MAX_PLAYER_TEAM],
	g_PlayersTB[MAX_PLAYER_TEAM];

char
	g_sURL[256],
	g_sIPv4[32],
	g_sPatchIP[64],
	g_sMapName[32] = "c5m1_waterfront_sndscape";

int
	g_iQueueID = 0,
	g_iPort;

TypeMatch
	g_TypeMatch = invalid;

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

	CreateNative("fkn_log", Native_Log);
	CreateNative("fkn_TypeMatch", Native_TypeMatch);
	CreateNative("fkn_QueueID", Native_QueueID);
	CreateNative("fkn_SteamIDTA", Native_SteamIDTA);
	CreateNative("fkn_SteamIDTB", Native_SteamIDTB);
	CreateNative("fkn_NameTA", Native_NameTA);
	CreateNative("fkn_NameTB", Native_NameTB);
	CreateNative("fkn_GetIPv4", Native_GetIPv4);
	CreateNative("fkn_MapName", Native_MapName);
	RegPluginLibrary("forsaken");
	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart()
{
	CreateConVar("sm_fkn_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug = CreateConVar("sm_fkn_debug", "0", "Debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_fkn_showip", Cmd_ShowIP, "Get ip and port server");
	RegAdminCmd("sm_fkn_playersinfo", Cmd_PlayersInfo, ADMFLAG_GENERIC, "Shows the name and SteamID of the players");
	
	AutoExecConfig(true, "forsaken");

	g_iPort = FindConVar("hostport").IntValue;
	BuildPath(Path_SM, g_sPatchIP, sizeof(g_sPatchIP), DIR_IP);
	JSON_Check();
	GetMatch();
	GetIPv4();
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
		PREFIX, g_PlayersTB[0].name, g_PlayersTA[0].steamid, g_PlayersTB[1].name, g_PlayersTA[1].steamid, g_PlayersTB[2].name, g_PlayersTA[2].steamid, g_PlayersTB[3].name, g_PlayersTA[3].steamid);
	
	CReplyToCommand(iClient, "%s TeamB:\n({blue}%s{default}:%s) ({blue}%s{default}:%s)\n({blue}%s{default}:%s) ({blue}%s{default}:%s)",
		PREFIX, g_PlayersTB[0].name, g_PlayersTB[0].steamid, g_PlayersTB[1].name, g_PlayersTB[1].steamid, g_PlayersTB[2].name, g_PlayersTB[2].steamid, g_PlayersTB[3].name, g_PlayersTB[3].steamid);

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
	char output[32];

	JSON_Object JoIp = new JSON_Object();
	JoIp.SetString("IP", "0.0.0.0");
	JoIp.Encode(output, sizeof(output));

	if(!FileExists(g_sPatchIP))
	{
		fkn_log("Error: %s Invalid file path", DIR_IP);
		return;
	}

	json_write_to_file(JoIp, g_sPatchIP, JSON_ENCODE_PRETTY);

	if (g_cvarDebug.BoolValue)
		fkn_log("%s Created !", DIR_IP);

	json_cleanup_and_delete(JoIp);
}