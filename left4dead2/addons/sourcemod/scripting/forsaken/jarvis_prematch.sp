#if defined jarvis_prematch_included
	#endinput
#endif
#define jarvis_prematch_included

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
	if(g_bisPreMatch)
		CreateTimer(3.0, GetMatchData);
}

/**
 * @brief Gets the match data from forsaken.smx.
 * 
 * @param timer		Timer handle.
 * @return			Stop the timer.
 */
public Action GetMatchData(Handle timer)
{
	g_Lobby = view_as<TypeMatch>(Forsaken_TypeMatch());
	for (int i = 0; i <= 3; i++)
	{
		Forsaken_TeamA(i, g_sSteamIDTA[i], MAX_AUTHID_LENGTH);
		Forsaken_TeamB(i, g_sSteamIDTB[i], MAX_AUTHID_LENGTH);
		Forsaken_NameTA(i, g_sNameTA[i], MAX_NAME_LENGTH);
		Forsaken_NameTB(i, g_sNameTB[i], MAX_NAME_LENGTH);
	}

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
	char sConfigCfg[128];
	g_cvarConfigCfg.GetString(sConfigCfg, sizeof(sConfigCfg));
	int iHumanCount = GetHumanCount();
	switch (iHumanCount)
	{
		case 1:
		{
			CPrintToChatAll("%t %t", "Tag", "StartAnnouncer", sConfigCfg);
			if(g_cvarDebug.BoolValue)
				CPrintToChatAll("HumanCount: %d", iHumanCount);
		}
		case 2:
		{
			CPrintToChatAll("%t %t", "Tag", "StartMatch", sConfigCfg);
			LGO_ExecuteConfigCfg(sConfigCfg);
		}
	}
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