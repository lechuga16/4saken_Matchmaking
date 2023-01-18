#if defined _forsaken_web_included
	#endinput
#endif
#define _forsaken_web_included

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Create an httpRequest, and retrieve the match data.
 *
 * @noreturn
 */
void GetMatch()
{
	if (!g_cvarEnable.BoolValue)
		return;

	char sPatch[128];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_CACHEMATCH);
	Format(g_sURL, sizeof(g_sURL), "%s?ip=%s&port=%d", URL_FORSAKEN_MATCH, fkn_GetIP(), g_iPort);
	if (g_cvarDebug.BoolValue)
		fkn_log("GetMatch URL: %s", g_sURL);

	System2HTTPRequest httpMatch = new System2HTTPRequest(HttpMatchInfo, g_sURL);
	httpMatch.SetHeader("Content-Type", "application/json");
	httpMatch.SetOutputFile(sPatch);
	if (g_cvarDebug.BoolValue)
		httpMatch.SetProgressCallback(HttpProgressMatch);
	httpMatch.GET();
	delete httpMatch;
}

public void HttpProgressMatch(System2HTTPRequest request, int dlTotal, int dlNow, int ulTotal, int ulNow)
{
	PrintToServer("forsaken_match.json downloaded %d of %d bytes", dlNow, dlTotal);
	fkn_log("forsaken_match.json downloaded %d of %d bytes", dlNow, dlTotal);
}

void HttpMatchInfo(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		url[256];

	request.GetURL(url, sizeof(url));

	if (!success)
	{
		fkn_log("ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
		return;
	}
	Call_StartForward(g_gfCacheDownload);
	if (Call_Finish() != 0)
		fkn_log("forsaken_web: error in forward Call_Finish");
}

/**
 * @brief Create an http request and retrieve the IPv4 of the server.
 *
 * @noreturn
 */
public void GetIPv4()
{
	if (!g_cvarEnable.BoolValue)
		return;
	char sPatch[128];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_IPV4);

	System2HTTPRequest httpIPv4 = new System2HTTPRequest(HttpIPv4, URL_IPV4);
	httpIPv4.SetHeader("Content-Type", "application/json");
	httpIPv4.SetOutputFile(sPatch);
	if (g_cvarDebug.BoolValue)
		httpIPv4.SetProgressCallback(HttpProgressIpv4);
	httpIPv4.GET();
	delete httpIPv4;
}

public void HttpProgressIpv4(System2HTTPRequest request, int dlTotal, int dlNow, int ulTotal, int ulNow)
{
	PrintToServer("IPv4 downloaded %d of %d bytes", dlNow, dlTotal);
}

public void HttpIPv4(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char url[256];

	request.GetURL(url, sizeof(url));

	if (!success)
	{
		fkn_log("ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
		return;
	}

	char sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_IPV4);
	JSON_Object joIPv4	= json_read_from_file(sPatch);
	joIPv4.GetString("ip", g_sIPv4, sizeof(g_sIPv4));
}