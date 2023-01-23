#if defined _jarvis_reserved_included
	#endinput
#endif
#define _jarvis_reserved_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

int	 g_iPort;
bool g_bReserve = false;
TypeMatch g_TypeMatch;
char
	g_sURL[256],
	g_sIp[64],
	g_sMapName[32];

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public void OnPluginStart_Reserved()
{
	g_cvarEnable = CreateConVar("sm_jarvis_reserved", "1", "Activate the reservation", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_svreserved", Cmd_Reserved, "Check if the server is reserved");

	g_iPort = FindConVar("hostport").IntValue;
	g_sIp	= fkn_GetIP();
}

public Action Cmd_Reserved(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_svreserved");
		return Plugin_Handled;
	}

	Format(g_sURL, sizeof(g_sURL), "%s?ip=%s&port=%d", URL_STATUSV2, g_sIp, g_iPort);
	System2HTTPRequest httpRequest = new System2HTTPRequest(CMD_HttpReserved, g_sURL);
	httpRequest.SetHeader("Content-Type", "application/json");
	httpRequest.Any	= iClient;
	httpRequest.GET();
	delete httpRequest;

	return Plugin_Continue;
}

public void CMD_HttpReserved(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		sUrl[256],
		sContent[128];

	request.GetURL(sUrl, sizeof(sUrl));

	if (!success)
	{
		fkn_log(false, "ERROR: Couldn't retrieve URL %s. Error: %s", sUrl, error);
		return;
	}

	response.GetContent(sContent, sizeof(sContent));
	JSON_Object joInfo = json_decode(sContent);

	if (joInfo == null)
	{
		fkn_log(false, "Error: HttpReserve() - (joInfo == null)");
		return;
	}

	g_bReserve = view_as<bool>(joInfo.GetInt("status"));
	CReplyToCommand(request.Any, "%t %t", "Tag", "CmdReserved", g_bReserve ? "Reserved" : "Unreserved");
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Create an http request and retrieve if the server is reserved.
 *
 * @noreturn
 */
public void OCPIS_Reserved()
{
	Format(g_sURL, sizeof(g_sURL), "%s?ip=%s&port=%d", URL_STATUSV2, g_sIp, g_iPort);
	if (g_cvarDebug.BoolValue)
		fkn_log(false, "URL: %s", g_sURL);

	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpReserved, g_sURL);
	httpRequest.SetHeader("Content-Type", "application/json");
	httpRequest.Timeout = 5;
	if (g_cvarDebug.BoolValue)
		httpRequest.SetProgressCallback(HttpProgressReserved);
	httpRequest.GET();
	delete httpRequest;
}

public void HttpProgressReserved(System2HTTPRequest request, int dlTotal, int dlNow, int ulTotal, int ulNow)
{
	PrintToServer("[J.A.R.V.I.S] Reserved progress %d of %d bytes", dlNow, dlTotal);
	fkn_log(true, "Reserved progress %d of %d bytes", dlNow, dlTotal);
}

public void HttpReserved(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		sUrl[256],
		sContent[128];

	request.GetURL(sUrl, sizeof(sUrl));

	if (!success)
	{
		fkn_log(false, "ERROR: Couldn't retrieve URL %s. Error: %s", sUrl, error);
		return;
	}

	response.GetContent(sContent, sizeof(sContent));

	if (g_cvarDebug.BoolValue)
		fkn_log(false, "GET request: %s", sContent);

	JSON_Object joInfo = json_decode(sContent);

	if (joInfo == null)
	{
		fkn_log(false, "Error: HttpReserve() - (joInfo == null)");
		return;
	}

	g_bReserve = view_as<bool>(joInfo.GetInt("status"));
	
	if (g_bReserve)
	{
		joInfo.GetString("map", g_sMapName, sizeof(g_sMapName));
		// g_TypeMatch = view_as<MatchType>(joInfo.GetInt("type"));
		g_TypeMatch = duel;
		json_cleanup_and_delete(joInfo);
		MatchInfo_PreMatch();
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			fkn_log(false, "%N was kicked, server without unreserved.", request.Any);
		KickAllClient();
	}
}

/**
 * @brief Kick all clients from the server.
 *
 * @noreturn
 */
public void KickAllClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsHuman(i))
			continue;

		KickClientEx(i, "%t", "KickMsg");
	}
}