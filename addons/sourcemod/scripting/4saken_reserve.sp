#pragma semicolon 1
#pragma newdecls required

#include <4saken>
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
	g_sIp[128];

public Plugin myinfo =
{
	name        = "Manage Reserved Servers",
	author      = "lechuga",
	description = "Functions that help in booking servers for matchmaking",
	version     = PLUGIN_VERSION,
	url         = "N/A"

}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("4saken_reserve.phrases");
	CreateConVar("sm_4saken_reserve_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug = CreateConVar("sm_4saken_reserve_debug", "0", "Turn on debug messages", 0, true, 0.0, true, 1.0);
	RegAdminCmd("sm_4saken_reserved", IsReserved, ADMFLAG_GENERIC);

	AutoExecConfig(true, "4saken_reserve");
}

void LoadTranslation(char[] sTranslation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", sTranslation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file %s.txt", sTranslation);
	}
	LoadTranslations(sTranslation);
}

public void OnClientPutInServer(int iClient)
{
	GetStatus();
}

void GetStatus()
{
	_4saken_KvGet("server", "ip", g_sIp, sizeof(g_sIp));
	g_iPort = FindConVar("hostport").IntValue;
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

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			switch (view_as<bool>(iStatus))
			{
				case false:
				{
					KickClient(i, "%T", "KickMsg", LANG_SERVER);
					if (g_cvarDebug.BoolValue)
						_4saken_log("%N was kicked, server without unreserved.", i);
				}
				case true:
				{
					if (g_cvarDebug.BoolValue)
						_4saken_log("%N was allowed in, the server was reserved.", i);
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
