#if defined _4saken_web_included
	#endinput
#endif
#define _4saken_web_included

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
	char sPatch[128];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_CACHEMATCH);

	Format(g_sURL, sizeof(g_sURL), "%s?ip=%s&port=%d", URL_FORSAKEN_MATCH, Forsaken_GetIP(), g_iPort);
	if (g_cvarDebug.BoolValue)
		Forsaken_log("GetMatch URL: %s", g_sURL);

	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpMatchInfo, g_sURL);
	httpRequest.SetHeader("Content-Type", "application/json");
	httpRequest.SetOutputFile(sPatch);
	if(g_cvarDebug.BoolValue)
		httpRequest.SetProgressCallback(HttpProgressMatch);
	httpRequest.GET();
	delete httpRequest;
}

public void HttpProgressMatch(System2HTTPRequest request, int dlTotal, int dlNow, int ulTotal, int ulNow)
{
	PrintToServer("forsaken_match.json downloaded %d of %d bytes", dlNow, dlTotal);
	Forsaken_log("forsaken_match.json downloaded %d of %d bytes", dlNow, dlTotal);
}

void HttpMatchInfo(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		url[256];

	request.GetURL(url, sizeof(url));

	if (!success)
	{
		Forsaken_log("ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
		return;
	}

	char
		sPatch[64];
	JSON_Object
		joMatch;
	JSON_Array
		jaTA,
		jaTB;

	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_CACHEMATCH);

	if(!FileExists(sPatch))
	{
		Forsaken_log("Error: %s File not found", DIR_CACHEMATCH);
		return;
	}

	joMatch	  = json_read_from_file(sPatch);
	g_sMapName = "c10m1_caves";

	g_TypeMatch = view_as<TypeMatch>(joMatch.GetInt("region"));
	jaTA	    = view_as<JSON_Array>(joMatch.GetObject("team1"));
	jaTB	    = view_as<JSON_Array>(joMatch.GetObject("team2"));

	if (joMatch == null)
	{
		Forsaken_log("Error: JSON_Object joMatch == null");
		return;
	}

	if (jaTA == null)
	{
		Forsaken_log("Error: JSON_Array jaTA == null");
		return;
	}

	if (jaTB == null)
	{
		Forsaken_log("Error: JSON_Array jaTB == null");
		return;
	}

	for (int i = 0; i <= 3; i++)
	{
		JSON_Object joPlayerTA = jaTA.GetObject(i);
		JSON_Object joPlayerTB = jaTB.GetObject(i);

		joPlayerTA.GetString("steamid", g_sSteamIDTA[i], MAX_AUTHID_LENGTH);
		joPlayerTB.GetString("steamid", g_sSteamIDTB[i], MAX_AUTHID_LENGTH);

		ReplaceString(g_sSteamIDTA[i], MAX_AUTHID_LENGTH, "STEAM_0", "STEAM_1", false);
		ReplaceString(g_sSteamIDTB[i], MAX_AUTHID_LENGTH, "STEAM_0", "STEAM_1", false);

		joPlayerTA.GetString("personaname", g_sNameTA[i], MAX_NAME_LENGTH);
		joPlayerTB.GetString("personaname", g_sNameTB[i], MAX_NAME_LENGTH);
	}

	json_cleanup_and_delete(joMatch);
}

/** 
 * @brief Create an http request and retrieve the IPv4 of the server.
 * 
 * @noreturn
 */
public void GetIPv4()
{
	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpIPv4, URL_IPV4);
	httpRequest.SetHeader("Content-Type", "application/json");
	if(g_cvarDebug.BoolValue)
		httpRequest.SetProgressCallback(HttpProgressIpv4);
	httpRequest.GET();
	delete httpRequest;
}

public void HttpProgressIpv4(System2HTTPRequest request, int dlTotal, int dlNow, int ulTotal, int ulNow)
{
	PrintToServer("IPv4 downloaded %d of %d bytes", dlNow, dlTotal);
}

public void HttpIPv4(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		url[256],
		content[128];

	request.GetURL(url, sizeof(url));

	if (!success)
	{
		Forsaken_log("ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
		return;
	}

	for (int found = 0; found < response.ContentLength;)
	{
		found += response.GetContent(content, sizeof(content), found);
	}

	JSON_Object jsIP = json_decode(content);
	jsIP.GetString("ip", g_sIPv4, sizeof(g_sIPv4));
}