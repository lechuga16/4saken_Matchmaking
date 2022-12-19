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

ConVar
	g_cvarDebug;

char
	g_sSteamIDTA[MAX_PLAYER_TEAM][MAX_AUTHID_LENGTH],
	g_sSteamIDTB[MAX_PLAYER_TEAM][MAX_AUTHID_LENGTH],
	g_sNameTA[MAX_PLAYER_TEAM][MAX_NAME_LENGTH],
	g_sNameTB[MAX_PLAYER_TEAM][MAX_NAME_LENGTH],
	g_sURL[256],
	g_sIPv4[32],
	g_sPatchIP[64],
	g_sMapName[32];

int
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

	CreateNative("Forsaken_log", Native_Log);
	CreateNative("Forsaken_TypeMatch", Native_TypeMatch);
	CreateNative("Forsaken_TeamA", Native_TeamA);
	CreateNative("Forsaken_TeamB", Native_TeamB);
	CreateNative("Forsaken_NameTA", Native_NameTA);
	CreateNative("Forsaken_NameTB", Native_NameTB);
	CreateNative("Forsaken_GetIPv4", Native_GetIPv4);
	CreateNative("Forsaken_MapName", Native_MapName);
	RegPluginLibrary("forsaken");
	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart()
{
	CreateConVar("sm_forsaken_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug = CreateConVar("sm_forsaken_debug", "0", "Debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_forsaken_showip", Cmd_ShowIP, "Get ip and port server");
	RegConsoleCmd("sm_forsaken_showipv4", Cmd_ShowIPv4, "Get ipv4 and port server");
	RegAdminCmd("sm_forsaken_playersinfo", Cmd_PlayersInfo, ADMFLAG_GENERIC, "Shows the name and SteamID of the players");
	
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
		CReplyToCommand(iClient, "Usage: sm_forsaken_showip");
	
	char sIp[64];
	sIp = Forsaken_GetIP();

	if(g_cvarDebug.BoolValue)
		Forsaken_log("ServerIP: {green}%s{default}:{green}%d{default}", sIp, g_iPort);

	CReplyToCommand(iClient, "ServerIP: {green}%s{default}:{green}%d{default}", sIp, g_iPort);
	return Plugin_Handled;
}

public Action Cmd_ShowIPv4(int iClient, int iArgs)
{
	if (iArgs != 0)
		CReplyToCommand(iClient, "Usage: sm_forsaken_showipv4");
	
	if(g_cvarDebug.BoolValue)
		Forsaken_log("ServerIPv4: {green}%s{default}:{green}%d{default}", g_sIPv4, g_iPort);
	
	CReplyToCommand(iClient, "ServerIPv4: {green}%s{default}:{green}%d{default}", g_sIPv4, g_iPort);
	return Plugin_Handled;
}

public Action Cmd_PlayersInfo(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_forsaken_playersinfo");
		return Plugin_Handled;
	}

	if(g_cvarDebug.BoolValue)
	{
		Forsaken_log("TeamA Name: %s %s %s %s", g_sNameTA[0], g_sNameTA[1], g_sNameTA[2], g_sNameTA[3]);
		Forsaken_log("TeamA Steamid: %s %s %s %s", g_sSteamIDTA[0], g_sSteamIDTA[1], g_sSteamIDTA[2], g_sSteamIDTA[3]);

		Forsaken_log("TeamB Name: %s %s %s %s", g_sNameTB[0], g_sNameTB[1], g_sNameTB[2], g_sNameTB[3]);
		Forsaken_log("TeamB Steamid: %s %s %s %s", g_sSteamIDTB[0], g_sSteamIDTB[1], g_sSteamIDTB[2], g_sSteamIDTB[3]);
	}

	CReplyToCommand(iClient, "TeamA Name: {blue}%s{default} {blue}%s{default} {blue}%s{default} {blue}%s{default}", g_sNameTA[0], g_sNameTA[1], g_sNameTA[2], g_sNameTA[3]);
	CReplyToCommand(iClient, "TeamA Steamid: {green}%s{default} {green}%s{default} {green}%s{default} {green}%s{default}\n", g_sSteamIDTA[0], g_sSteamIDTA[1], g_sSteamIDTA[2], g_sSteamIDTA[3]);

	CReplyToCommand(iClient, "TeamB Name: {red}%s{default} {red}%s{default} {red}%s{default} {red}%s{default}", g_sNameTB[0], g_sNameTB[1], g_sNameTB[2], g_sNameTB[3]);
	CReplyToCommand(iClient, "TeamB Steamid: {green}%s{default} {green}%s{default} {green}%s{default} {green}%s{default}", g_sSteamIDTB[0], g_sSteamIDTB[1], g_sSteamIDTB[2], g_sSteamIDTB[3]);

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
		Forsaken_log("%s Not found", DIR_IP);

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
		Forsaken_log("Error: %s Invalid file path", DIR_IP);
		return;
	}

	json_write_to_file(JoIp, g_sPatchIP, JSON_ENCODE_PRETTY);

	if (g_cvarDebug.BoolValue)
		Forsaken_log("%s Created !", DIR_IP);

	json_cleanup_and_delete(JoIp);
}