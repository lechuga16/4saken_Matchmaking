#pragma semicolon 1
#pragma newdecls required

#include <forsaken_stocks>
#include <colors>
#include <sourcemod>
#include <system2>
#undef REQUIRE_PLUGIN
#include <confogl>
#define REQUIRE_PLUGIN

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION "0.1"

ConVar
	g_cvarDebug,
	g_cvarEnable;
int
	g_iPort;

bool
	g_bReserve = false;
char
	g_sURL[256],
	g_sIp[64];

GlobalForward g_gfMap;

/*****************************************************************
			P L U G I N   I N F O
*****************************************************************/
public Plugin myinfo =
{
	name		= "Forsaken Reserved",
	author		= "lechuga",
	description = "Functions that help in booking servers for matchmaking",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/lechuga16/4saken_Matchmaking"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
	}

	if (StrEqual(fkn_GetIP(), "0.0.0.0", false))
	{
		strcopy(error, err_max, "ERROR: The server ip was not configured");
		return APLRes_Failure;
	}

	g_gfMap = CreateGlobalForward("OnMapDownload", ET_Ignore, Param_String);
	RegPluginLibrary("forsaken_reserved");
	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public void OnPluginStart()
{
	LoadTranslation("forsaken_reserved.phrases");
	CreateConVar("sm_reserved_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug	 = CreateConVar("sm_reserved_debug", "0", "Debug messages", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarEnable = CreateConVar("sm_reserved_enable", "1", "Activate the reservation", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_reserved", Cmd_Reserved, "Check if the server is reserved");

	g_iPort = FindConVar("hostport").IntValue;
	g_sIp	= fkn_GetIP();
	AutoExecConfig(true, "forsaken_reserved");
}

public Action Cmd_Reserved(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_reserved");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "% %t", "Tag", "CmdReserved", g_bReserve ? "Reserved" : "Unreserved");
	return Plugin_Handled;
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Create an http request and retrieve if the server is reserved.
 *
 * @noreturn
 */
public void OCPIS_Reserved(int iClient)
{
	Format(g_sURL, sizeof(g_sURL), "%s?ip=%s&port=%d", URL_STATUSV2, g_sIp, g_iPort);
	if (g_cvarDebug.BoolValue)
		fkn_log("URL: %s", g_sURL);

	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpReserve, g_sURL);
	httpRequest.SetHeader("Content-Type", "application/json");
	httpRequest.Timeout = 5;
	httpRequest.Any		= iClient;
	if (g_cvarDebug.BoolValue)
		httpRequest.SetProgressCallback(HttpProgressReserved);
	httpRequest.GET();
	delete httpRequest;
}

public void HttpProgressReserved(System2HTTPRequest request, int dlTotal, int dlNow, int ulTotal, int ulNow)
{
	PrintToServer("[forsaken_reserve] Reserved progress %d of %d bytes", dlNow, dlTotal);
	fkn_log("Reserved progress %d of %d bytes", dlNow, dlTotal);
}

public void HttpReserve(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		sUrl[256],
		sContent[128];

	request.GetURL(sUrl, sizeof(sUrl));

	if (!success)
	{
		fkn_log("ERROR: Couldn't retrieve URL %s. Error: %s", sUrl, error);
		return;
	}

	response.GetContent(sContent, sizeof(sContent));

	if (g_cvarDebug.BoolValue)
		fkn_log("GET request: %s", sContent);

	JSON_Object joInfo = json_decode(sContent);

	if (joInfo == null)
	{
		fkn_log("Error: HttpReserve() - (joInfo == null)");
		return;
	}

	g_bReserve = view_as<bool>(joInfo.GetInt("status"));

	fkn_log("GET status: %s", g_bReserve ? "Reserved" : "Unreserved");

	if (!g_bReserve)
	{
		if (g_cvarDebug.BoolValue)
			fkn_log("%N was kicked, server without unreserved.", request.Any);
		KickClient(request.Any, "%t", "KickMsg");
		return;
	}

	char sMap[32];
	joInfo.GetString("map", sMap, sizeof(sMap));

	Call_StartForward(g_gfMap);
	Call_PushString(sMap);
	Call_Finish();
}