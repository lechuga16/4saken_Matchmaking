#pragma semicolon 1
#pragma newdecls required

#include <4saken>
#include <4saken_endgame>
#include <colors>
#include <sourcemod>
#include <system2>
#define PLUGIN_VERSION "0.1"
#define URL_4SAKEN     "forsaken-blk.herokuapp.com/queue/matchstatus"

ConVar
	g_cvarDebug;
int
	g_iPort,
	iStatus = 0;
char
	sURL[256],
	g_sIp[64];

public Plugin myinfo =
{
	name        = "4saken Manage Reserved Servers",
	author      = "lechuga",
	description = "Functions that help in booking servers for matchmaking",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lechuga16/4saken_Matchmaking"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");

	}

	g_sIp = _4saken_GetIp();
	if(StrEqual(g_sIp, "0.0.0.0", false))
	{
		strcopy(error, err_max, "ERROR: The server ip was not configured");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("4saken_reserve.phrases");
	CreateConVar("sm_4saken_reserve_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug = CreateConVar("sm_4saken_reserve_debug", "0", "Turn on debug messages", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RegAdminCmd("sm_4saken_reserved", IsReserved, ADMFLAG_GENERIC);

	g_iPort = FindConVar("hostport").IntValue;
	AutoExecConfig(true, "4saken_reserve");
}

public void OnClientPutInServer(int iClient)
{
	GetStatus();
}

void GetStatus()
{
	Format(sURL, sizeof(sURL), "%s?ip=%s&port=%d", URL_4SAKEN, g_sIp, g_iPort);
	if (g_cvarDebug.BoolValue)
		_4saken_log("URL: %s", sURL);

	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, sURL);
	httpRequest.SetHeader("Content-Type", "application/json");
	httpRequest.Timeout = 5;
	httpRequest.GET();
	delete httpRequest;
}

void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		url[256],
		content[128];
	request.GetURL(url, sizeof(url));

	if (!success)
	{
		_4saken_log("ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
		return;
	}

	for (int found = 0; found < response.ContentLength;)
	{
		found += response.GetContent(content, sizeof(content), found);
	}

	iStatus = StringToInt(content, 10);
	if (g_cvarDebug.BoolValue)
	{
		_4saken_log("GET request: %d", iStatus);
	}

	for (int index = 1; index <= MaxClients; index++)
	{
		if (!IsFakeClient(index) && IsClientConnected(index))
		{
			switch (view_as<bool>(iStatus))
			{
				case false:
				{
					KickClient(index, "%t", "KickMsg");
					if (g_cvarDebug.BoolValue)
						_4saken_log("%N was kicked, server without unreserved.", index);
				}
				case true:
				{
					if (g_cvarDebug.BoolValue)
						_4saken_log("%N was allowed in, the server was reserved.", index);
				}
			}
		}
	}
}

public Action IsReserved(int iClient, int iArgs)
{
	if (iArgs != 0)
		return Plugin_Handled;

	if (iClient == CONSOLE)
	{
		Reserved(iClient);
		return Plugin_Continue;
	}
	if (!IsValidClient)
	{
		return Plugin_Handled;
	}
	Reserved(iClient);
	return Plugin_Continue;
}

void Reserved(int iClient)
{
	switch (view_as<bool>(iStatus))
	{
		case true:
		{
			CReplyToCommand(iClient, "%t", "Reserved");
		}
		case false:
		{
			CReplyToCommand(iClient, "%t", "Unreserved");
		}
	}
	if (g_cvarDebug.BoolValue)
		_4saken_log("%N checked if the server is %s", iClient, view_as<bool>(iStatus) ? "reserved" : "unreserved");
}

Database Connect()
{
	char error[255];
	Database db;
	
	if (SQL_CheckConfig("4saken"))
		_4saken_log("The 4saken configuration is not found in databases.cfg");

	db = SQL_Connect("4saken", true, error, sizeof(error));
	
	if (db == null)
		_4saken_log("Could not connect to database: %s", error);
	
	return db;
}

public void OnEndGame()
{
	Database dStatus = Connect();
	char 
		sQuery[256];
	Format(sQuery, sizeof(sQuery), "UPDATE `l4d2_queue_game` SET `status`= 0 WHERE `ip` = '%s:%d' ORDER BY `queueid` DESC LIMIT 1;", g_sIp, g_iPort);

	if (g_cvarDebug.BoolValue)
		_4saken_log("Query: %s", sQuery);

	if (!SQL_FastQuery(dStatus, sQuery))
	{
		char error[255];
		SQL_GetError(dStatus, error, sizeof(error));
		_4saken_log("Failed to query (error: %s)", error);
	}
}
