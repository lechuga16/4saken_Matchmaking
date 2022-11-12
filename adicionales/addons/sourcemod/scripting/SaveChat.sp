#pragma semicolon 1
#pragma newdecls required

#include <geoip.inc>
#include <sdktools>
#include <sourcemod>
#include <string.inc>

#define PLUGIN_VERSION "SaveChat_2.0"

char
	g_sChatFile[128],
	g_sJoinFile[128];
Handle
	g_hFileHandle = null;
ConVar
	g_cvarDetail,
	g_cvarConect,
	g_cvarDisconnect,
	g_cvarConsole,
	g_cvarFakeClient,
	g_cvarFormat,
	g_cvarJoin,
	g_cvarAuthIdType;

public Plugin myinfo =
{
	name        = "SaveChat",
	author      = "citkabuto & Harry Potter, lechuga",
	description = "Records player chat messages to a file",
	version     = PLUGIN_VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=117116"

}

public void OnPluginStart()
{
	/* Register CVars */
	CreateConVar("sm_savechat_version", PLUGIN_VERSION, "Save Player Chat Messages Plugin", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_REPLICATED);

	g_cvarDetail		= CreateConVar("sm_sc_detail", "0", "Record player Steam ID and IP address", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarConect		= CreateConVar("sm_sc_connect", "1", "Record when a player enters the game", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarDisconnect	= CreateConVar("sm_sc_disconect", "1", "Record when a player disconnects from the match", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarConsole		= CreateConVar("sm_sc_console", "1", "Record console messages", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarFakeClient	= CreateConVar("sm_sc_fakeclient", "1", "Record FakeClient messages", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarFormat		= CreateConVar("sm_sc_format", "%d%m%Y", "File name format (chat_%s.log)", FCVAR_NOTIFY);	
	g_cvarJoin			= CreateConVar("sm_sc_join", "1", "Create an input-only record", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarAuthIdType	= CreateConVar("sm_sc_AuthIdType", "0", "Auth string types. 0:Engine, 1:Steam2, 2:Steam3, 3:SteamID64.", FCVAR_NOTIFY, true, 0.0, true, 3.0);

	/* Say commands */
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);

	char
		ssTime[64],
		sBuffer[64],
		sFormat[24];

	GetConVarString(g_cvarFormat, sFormat, sizeof(sFormat));
	FormatTime(ssTime, sizeof(ssTime), sFormat);
	FormatEx(sBuffer, sizeof(sBuffer), "logs/chats/chat_%s.log", ssTime);
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "logs/chats");
	if (!DirExists(sBuffer))
		CreateDirectory(sBuffer, 511);

	HookEvent("player_disconnect", event_PlayerDisconnect, EventHookMode_Pre);

	// Autoconfig for plugin
	AutoExecConfig(true, "savechat");
}

/*
 * Capture player chat and record to file
 */
public Action Command_Say(int client, int args)
{
	LogChat(client, args, false);
	return Plugin_Continue;
}

/*
 * Capture player team chat and record to file
 */
public Action Command_SayTeam(int client, int args)
{
	LogChat(client, args, true);
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	if (!g_cvarConect.BoolValue)
		return;

	if (IsFakeClient(client))
		return;

	char
		sMsg[2048],
		sJoin[2048],
		sTime[64],
		sSteamID[128],
		sPlayerIP[50],
		sCountry[64];

	GetClientAuthId(client, view_as<AuthIdType>(g_cvarAuthIdType.IntValue), sSteamID, sizeof(sSteamID));
	GetClientIP(client, sPlayerIP, sizeof(sPlayerIP), true);
	if(!GeoipCountry(sPlayerIP, sCountry, sizeof(sCountry)))
	{
		sCountry = "Unknown";
	}
	FormatTime(sTime, sizeof(sTime), NULL_STRING, -1);
	Format(sMsg, sizeof(sMsg), "[%s] (%s | %s) %N has joined", sTime, sPlayerIP, sSteamID, client);
	SaveMessage(sMsg);

	if(g_cvarJoin.BoolValue)
	{
		Format(sJoin, sizeof(sJoin), "[%s] %s | %s | %s | %N", sTime, sPlayerIP, sCountry, sSteamID, client);
		SaveJoin(sJoin);
	}
}

public Action event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvarDisconnect.BoolValue)
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client && !IsFakeClient(client) && !dontBroadcast)
	{
		char
			sMsg[2048],
			sTime[21],
			sSteamID[128],
			sPlayerIP[50];

		GetClientAuthId(client, view_as<AuthIdType>(g_cvarAuthIdType.IntValue), sSteamID, sizeof(sSteamID));
		GetClientIP(client, sPlayerIP, sizeof(sPlayerIP), true);
		FormatTime(sTime, sizeof(sTime), NULL_STRING, -1);
		Format(sMsg, sizeof(sMsg), "[%s] (%s | %s) %N has left", sTime, sSteamID, sPlayerIP, client);

		SaveMessage(sMsg);
	}
	return Plugin_Continue;
}

/*
 * Extract all relevant information and format
 */
public void LogChat(int client, int args, bool teamchat)
{
	char
		sMsg[2048],
		sTime[64],
		sText[1024],
		sPlayerIP[16],
		sTeamName[64],
		sSteamID[128];

	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	FormatTime(sTime, sizeof(sTime), NULL_STRING, -1);

	if (g_cvarConsole.BoolValue && client == 0)
	{
		Format(sMsg, sizeof(sMsg), "[%s] %N : %s", sTime, client, sText);
		SaveMessage(sMsg);
		return;
	}
	if (!IsClientInGame(client))
		return;
	if (g_cvarFakeClient.BoolValue && IsFakeClient(client))
	{
		Format(sMsg, sizeof(sMsg), "[%s] [UserId: %d] FakeClient : %s", sTime, GetClientUserId(client), sText);
		SaveMessage(sMsg);
		return;
	}
	GetClientIP(client, sPlayerIP, sizeof(sPlayerIP), true);
	GetTeamName(GetClientTeam(client), sTeamName, sizeof(sTeamName));
	GetClientAuthId(client, view_as<AuthIdType>(g_cvarAuthIdType.IntValue), sSteamID, sizeof(sSteamID));

	if (g_cvarDetail.BoolValue)
	{
		Format(sMsg, sizeof(sMsg), "[%s] (%s | %-9s) [%s]%s %N : %s", sTime, sSteamID, sPlayerIP, sTeamName, teamchat == true ? "(TEAM)" : "      ", client, sText);
	}
	else
	{
		Format(sMsg, sizeof(sMsg), "[%s] %s [%s]%s %N : %s", sTime, sSteamID, sTeamName, teamchat == true ? "(TEAM)" : "      ", client, sText);
	}

	SaveMessage(sMsg);
}

/*
 * Log a map transition
 */
public void OnMapStart()
{
	char
		map[128],
		sMsg[1024],
		date[21],
		sTime[64],
		logFile[100],
		joinFile[100],
		sFormat[24];

	GetCurrentMap(map, sizeof(map));
	GetConVarString(g_cvarFormat, sFormat, sizeof(sFormat));
	FormatTime(date, sizeof(date), sFormat, -1);
	Format(logFile, sizeof(logFile), "/logs/chats/chat_%s.log", date);
	BuildPath(Path_SM, g_sChatFile, PLATFORM_MAX_PATH, logFile);

	FormatTime(sTime, sizeof(sTime), NULL_STRING, -1);
	Format(sMsg, sizeof(sMsg), "[%s] --- Map: %s ---", sTime, map);

	SaveMessage("--=================================================================--");
	SaveMessage(sMsg);
	SaveMessage("--=================================================================--");

	if(g_cvarJoin.BoolValue)
	{
		Format(joinFile, sizeof(joinFile), "/logs/chats/join.log");
		BuildPath(Path_SM, g_sJoinFile, PLATFORM_MAX_PATH, joinFile);
	}
}

/*
 * Log the message to file
 */
public void SaveMessage(const char[] message)
{
	g_hFileHandle = OpenFile(g_sChatFile, "a"); /* Append */
	if (g_hFileHandle == null)
	{
		char sBuffer[64];
		BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "logs/chats");
		CreateDirectory(sBuffer, 511);
		g_hFileHandle = OpenFile(g_sChatFile, "a");    // open again
	}
	WriteFileLine(g_hFileHandle, message);
	delete g_hFileHandle;
}

/*
 * Log the message to file
 */
public void SaveJoin(const char[] message)
{
	g_hFileHandle = OpenFile(g_sJoinFile, "a"); /* Append */
	if (g_hFileHandle == null)
	{
		char sBuffer[64];
		BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "logs/chats");
		CreateDirectory(sBuffer, 511);
		g_hFileHandle = OpenFile(g_sJoinFile, "a");    // open again
	}
	WriteFileLine(g_hFileHandle, message);
	delete g_hFileHandle;
}