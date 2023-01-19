#if defined _jarvis_prematch_included
	#endinput
#endif
#define _jarvis_prematch_included

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Starts a timer that gets match information in the prematch
 *
 * @noreturn
 */
public void PreMatch()
{
	g_TypeMatch = fkn_TypeMatch();
	PlayersAndRQs();

	CheckPlayersPresent();
}

/**
 * @brief Starts the match.
 *
 * @noreturn
 */
public void StartMatch()
{
	if (LGO_IsMatchModeLoaded() && !g_bStartMatch)
		return;

	g_bStartMatch = !g_bStartMatch;

	char sCfgConvar[32];
	g_cvarConfigCfg.GetString(sCfgConvar, sizeof(sCfgConvar));
	int iHumanCount = GetHumanCount();

	if (iHumanCount == g_cvarPlayersToStart.IntValue)
	{
		CPrintToChatAll("%t %t", "Tag", "StartMatch", sCfgConvar, g_sMapName);
		ServerCommand("sm_forcematch %s", sCfgConvar);
	}
	else if (iHumanCount < g_cvarPlayersToStart.IntValue)
		CPrintToChatAll("%t %t", "Tag", "NotEnoughPlayers", iHumanCount, g_cvarPlayersToStart.IntValue);
}

/**
 * @brief Returns the number of human players connected to the server.
 *
 * @return			Number of human players connected to the server.
 */
stock int GetHumanCount()
{
	int humans = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client))
		{
			humans++;
		}
	}

	return humans;
}

/**
 * @brief Checks if the players are present in the match.
 *
 * @noreturn
 */
public void CheckPlayersPresent()
{
	char sAuth[MAX_AUTHID_LENGTH];
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientAuthorized(iClient) && GetClientAuthId(iClient, AuthId_SteamID64, sAuth, MAX_AUTHID_LENGTH))
		{
			if (g_cvarDebug.BoolValue)
				fkn_log("CheckPlayersPresent: [%N|%s]", iClient, sAuth);
			OnClientAuthorized(iClient, sAuth);
		}
	}
}

public void OnMapDownload(const char[] sMap)
{
	strcopy(g_sMapName, sizeof(g_sMapName), sMap);

	ConVar match_restart;
	char sMatch_Map[32];
	match_restart = FindConVar("confogl_match_map");
	match_restart.GetString(sMatch_Map, sizeof(sMatch_Map));

	if (!StrEqual("", sMatch_Map, false))
		return;

	ServerCommand("confogl_match_map %s", g_sMapName);
	
	if(g_cvarDebug.BoolValue)
		fkn_log("OnMapDownload: %s", g_sMapName);
}