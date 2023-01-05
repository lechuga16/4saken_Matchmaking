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
	CreateTimer(3.0, Timer_GetMatchData);
}

/**
 * @brief Gets the match data from forsaken.smx.
 * 
 * @param timer		Timer handle.
 * @return			Stop the timer.
 */
public Action Timer_GetMatchData(Handle timer)
{
	g_TypeMatch = fkn_TypeMatch();
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{	
		// Get the steamids from the player index
		fkn_SteamIDTA(iID, g_Players[TeamA][iID].steamid, MAX_AUTHID_LENGTH);
		fkn_SteamIDTB(iID, g_Players[TeamB][iID].steamid, MAX_AUTHID_LENGTH);

		// Get the player names from the steamid
		fkn_NameTA(iID, g_Players[TeamA][iID].name, MAX_NAME_LENGTH);
		fkn_NameTB(iID, g_Players[TeamB][iID].name, MAX_NAME_LENGTH);

		// Get the steamids from the player index
		fkn_SteamIDTA(iID, g_RageQuit[TeamA][iID].steamid, MAX_AUTHID_LENGTH);
		fkn_SteamIDTB(iID, g_RageQuit[TeamB][iID].steamid, MAX_AUTHID_LENGTH);
	}
	fkn_MapName(g_sMapName, sizeof(g_sMapName));

	if(g_cvarDebug.BoolValue)
		CPrintToChatAll("%t GetMatchData", "Tag");
	return Plugin_Stop;
}

/**
 * @brief Starts the match.
 * 
 * @noreturn
 */
public void StartMatch()
{
	if (LGO_IsMatchModeLoaded())
		return;

	char sCfgConvar[32];
	g_cvarConfigCfg.GetString(sCfgConvar, sizeof(sCfgConvar));
	int iHumanCount = GetHumanCount();

	if(iHumanCount == g_cvarPlayersToStart.IntValue)
	{
		char
			sMatchMap[32];
		ConVar
			match_restart;

		CPrintToChatAll("%t %t", "Tag", "StartMatch", sCfgConvar, g_sMapName);
		
		match_restart = FindConVar("confogl_match_map");
		match_restart.GetString(sMatchMap, sizeof(sMatchMap));
		
		if(!StrEqual("", sMatchMap, false))
			return;

		ServerCommand("confogl_match_map %s", g_sMapName);
		ServerCommand("sm_forcematch %s", sCfgConvar);
	}
	else if(iHumanCount < g_cvarPlayersToStart.IntValue)
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