#pragma semicolon 1
#pragma newdecls required

#include <forsaken>
#include <forsaken_endgame>
#include <colors>
#include <sourcemod>
#include <system2>
#undef REQUIRE_PLUGIN
#include <confogl>

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
	g_bReserve;
char
	g_sURL[256],
	g_sIp[64];

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

public APLRes
	AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
	}

	if (StrEqual(Forsaken_GetIP(), "0.0.0.0", false))
	{
		strcopy(error, err_max, "ERROR: The server ip was not configured");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart()
{
	LoadTranslation("forsaken_reserve.phrases");
	CreateConVar("sm_reserve_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug	 = CreateConVar("sm_reserve_debug", "0", "Debug messages", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarEnable = CreateConVar("sm_reserve_enable", "1", "Activate the reservation", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_iPort		 = FindConVar("hostport").IntValue;
	g_sIp		 = Forsaken_GetIP();
	AutoExecConfig(true, "forsaken_reserve");
}

public void OnClientPutInServer(int iClient)
{
	if (!g_cvarEnable.BoolValue || LGO_IsMatchModeLoaded())
		return;

	GetReserve(iClient);
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Create an http request and retrieve if the server is reserved.
 * 
 * @noreturn
 */
public void GetReserve(int iClient)
{
	Format(g_sURL, sizeof(g_sURL), "%s?ip=%s&port=%d", URL_FORSAKEN, g_sIp, g_iPort);
	if (g_cvarDebug.BoolValue)
		Forsaken_log("URL: %s", g_sURL);

	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpReserve, g_sURL);
	httpRequest.SetHeader("Content-Type", "application/json");
	httpRequest.Timeout = 5;
	httpRequest.Any = iClient;
	if(g_cvarDebug.BoolValue)
		httpRequest.SetProgressCallback(HttpProgressReserved);
	httpRequest.GET();
	delete httpRequest;
}

public void HttpProgressReserved(System2HTTPRequest request, int dlTotal, int dlNow, int ulTotal, int ulNow)
{
	PrintToServer("Reserved progress %d of %d bytes", dlNow, dlTotal);
	Forsaken_log("Reserved progress %d of %d bytes", dlNow, dlTotal);
}

public void HttpReserve(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		sUrl[256],
		sContent[10];
	int iClient = request.Any;

	request.GetURL(sUrl, sizeof(sUrl));

	if (!success)
	{
		Forsaken_log("ERROR: Couldn't retrieve URL %s. Error: %s", sUrl, error);
		return;
	}

	response.GetContent(sContent, sizeof(sContent));

	if (g_cvarDebug.BoolValue)
		Forsaken_log("GET request: %s", sContent);

	g_bReserve = view_as<bool>(StringToInt(sContent, 10));

	switch (g_bReserve)
	{
		case false:
		{
			KickClient(iClient, "%t", "KickMsg");
			if (g_cvarDebug.BoolValue)
				Forsaken_log("%N was kicked, server without unreserved.", iClient);
		}
		case true:
		{
			if (g_cvarDebug.BoolValue)
				Forsaken_log("%N was allowed in, the server was reserved.", iClient);
		}
	}
}