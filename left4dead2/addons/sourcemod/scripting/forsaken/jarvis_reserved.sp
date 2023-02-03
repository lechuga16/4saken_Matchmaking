#if defined _jarvis_reserved_included
	#endinput
#endif
#define _jarvis_reserved_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar g_cvarReserved;
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
	g_cvarReserved = CreateConVar("sm_jarvis_reserved", "1", "Activate the reservation", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_iPort = FindConVar("hostport").IntValue;
	g_sIp	= fkn_GetIP();
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
	Format(g_sURL, sizeof(g_sURL), "%s?ip=%s&port=%d", URL_STATUS, g_sIp, g_iPort);
	fkn_log(true, "URL: %s", g_sURL);

	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpReserved, g_sURL);
	httpRequest.SetHeader("Content-Type", "application/json");
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

	if(g_cvarReserved.BoolValue)
		g_bReserve = view_as<bool>(StringToInt(sContent));
	else
	{
		g_bReserve = true;
		fkn_log(true, "Reservation disabled");
	}

	if (g_bReserve)
	{
		ServerCommand("sm_fkn_downloadCache");
		MatchInfo_PreMatch();
	}
	else
	{
		fkn_log(true, "%N was kicked, server without unreserved.", request.Any);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsHuman(i))
				continue;

			KickClientEx(i, "%t", "KickMsg");
		}
	}
}