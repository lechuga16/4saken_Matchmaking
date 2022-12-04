#if defined _4saken_web_included
	#endinput
#endif
#define _4saken_web_included

void GetMatch()
{
	Format(g_sURL, sizeof(g_sURL), "%s?ip=%s&port=%d", URL_4SAKEN_MATCH, _4saken_GetIp(), g_iPort);
	if (g_cvarDebug.BoolValue)
		_4saken_log("GetMatch URL: %s", g_sURL);

	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpMatchInfo, g_sURL);
	httpRequest.SetHeader("Content-Type", "application/json");
	httpRequest.Timeout = 5;
	httpRequest.GET();
	delete httpRequest;
}

void HttpMatchInfo(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		url[256],
		content[300];
	JSON_Array
		arrTeam1,
		arrTeam2;
	JSON_Object
		jsMatch;

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

	jsMatch   = json_decode(content);
	g_iRegion = jsMatch.GetInt("region");

	arrTeam1 = view_as<JSON_Array>(jsMatch.GetObject("team1"));
	arrTeam2 = view_as<JSON_Array>(jsMatch.GetObject("team2"));
	for (int i = 0; i <= 3; i++)
	{
		arrTeam1.GetString(i, g_sSteamIDT1[i], STEAMID_LENGTH);
		ReplaceString(g_sSteamIDT1[i], STEAMID_LENGTH, "STEAM_0", "STEAM_1", false);

		arrTeam2.GetString(i, g_sSteamIDT2[i], STEAMID_LENGTH);
		ReplaceString(g_sSteamIDT2[i], STEAMID_LENGTH, "STEAM_0", "STEAM_1", false);
	}
}