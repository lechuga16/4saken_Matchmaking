#if defined _jarvis_prematch_included
	#endinput
#endif
#define _jarvis_prematch_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

/**
 * 	Contains values to tell if a player is in the game or has raged.
 */
enum struct PlayerRageQuit
{
	char   steamid[MAX_AUTHID_LENGTH];	  // Player SteamID
	bool   ispresent;					  // Is the player in the game?
	Handle timer;						  // Timer to check if the player has ragequitting.
}

PlayerRageQuit g_RageQuit[ForsakenTeam][MAX_PLAYER_TEAM];

ConVar
	g_cvarConfigCfg,
	g_cvarPlayersToStart,
	g_cvarChangeMap;

TypeMatch g_TypeMatch;
bool g_bPreMatch = true;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_prematch()
{
	g_cvarConfigCfg		 = CreateConVar("sm_jarvis_configcfg", "zonemod", "The config file to load", FCVAR_NONE);
	g_cvarPlayersToStart = CreateConVar("sm_jarvis_playerstostart", "1", "The minimum players to start the match", FCVAR_NONE, true, 1.0);
	g_cvarChangeMap		 = CreateConVar("sm_jarvis_changemap", "1", "Change the map when it is verified that it does not correspond to the match", FCVAR_NONE, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_jarvis_listplayers", Cmd_ListPlayers, "Print the forsaken player list");
	RegConsoleCmd("sm_jarvis_refreshlistplayers", Cmd_RefreshListPlayers, "Refresh the forsaken player list");
	RegConsoleCmd("sm_jarvis_info", Cmd_MatchInfo, "Displays the cfg and map that will be used.");
	RegConsoleCmd("sm_jarvis_clientid", Cmd_ClientID, "Print the client id of the player");
}

public void OMS_prematch()
{
	if (g_bPreMatch)
		ReadConfigSourcebans();
		
	if (LGO_IsMatchModeLoaded() && g_bPreMatch)
		g_bPreMatch = !g_bPreMatch;
}

public void OCD_prematch()
{
	fkn_MapName(g_sMapName, sizeof(g_sMapName));
	g_TypeMatch = fkn_TypeMatch();
	PlayersAndRQs();
	ClienIndexList();
}

public Action Cmd_ListPlayers(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_missingplayers");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%t %t", "Tag", "TypeLobby", sTypeMatch[g_TypeMatch]);

	char
		sTmpBufferTA[128],
		sTmpBufferTB[128],
		sPrintBufferTA[1024],
		sPrintBufferTB[1024];

	Format(sTmpBufferTA, sizeof(sTmpBufferTA), "%t %t", "Tag", "TeamA");
	StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

	Format(sTmpBufferTB, sizeof(sTmpBufferTB), "%t %t", "Tag", "TeamB");
	StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

	for (int iID = 0; iID <= 3; iID++)
	{
		Format(sTmpBufferTA, sizeof(sTmpBufferTA), "({olive}%s{default}:", g_Players[TeamA][iID].steamid);
		StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

		Format(sTmpBufferTA, sizeof(sTmpBufferTA), "%s) ", g_Players[TeamA][iID].name);
		StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

		if (iID == 1)
		{
			Format(sTmpBufferTA, sizeof(sTmpBufferTA), "\n");
			StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);
		}

		Format(sTmpBufferTB, sizeof(sTmpBufferTB), "({olive}%s{default}:", g_Players[TeamB][iID].steamid);
		StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

		Format(sTmpBufferTB, sizeof(sTmpBufferTB), "%s) ", g_Players[TeamB][iID].name);
		StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

		if (iID == 1)
		{
			Format(sTmpBufferTB, sizeof(sTmpBufferTB), "\n");
			StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);
		}
	}

	CReplyToCommand(iClient, sPrintBufferTA);
	CReplyToCommand(iClient, sPrintBufferTB);

	return Plugin_Handled;
}

public Action Cmd_MatchInfo(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_matchinfo");
		return Plugin_Handled;
	}

	char sCfgConvar[128];
	g_cvarConfigCfg.GetString(sCfgConvar, sizeof(sCfgConvar));
	CReplyToCommand(iClient, "%t %t", "Tag", "MatchInfo", sCfgConvar, g_sMapName);

	return Plugin_Handled;
}

public Action Cmd_ClientID(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_clientid");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%t \nTeamA: [%d][%d][%d][%d]\nTeamB: [%d][%d][%d][%d]", "Tag",
					g_Players[TeamA][0].client, g_Players[TeamA][1].client, g_Players[TeamA][2].client, g_Players[TeamA][3].client,
					g_Players[TeamB][0].client, g_Players[TeamB][1].client, g_Players[TeamB][2].client, g_Players[TeamB][3].client);
	return Plugin_Handled;
}

public Action Cmd_RefreshListPlayers(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_refreshlistplayers");
		return Plugin_Handled;
	}

	fkn_MapName(g_sMapName, sizeof(g_sMapName));
	g_TypeMatch = fkn_TypeMatch();
	PlayersAndRQs();
	ClienIndexList();
	FakeClientCommand(iClient, "sm_jarvis_listplayers");
	return Plugin_Handled;
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

public void Map_PreMatch()
{
	ConVar match_restart;
	char   sMatch_Map[32];
	match_restart = FindConVar("confogl_match_map");
	match_restart.GetString(sMatch_Map, sizeof(sMatch_Map));

	if (!StrEqual("", sMatch_Map, false))
		return;

	ServerCommand("confogl_match_map %s", g_sMapName);

	if (g_cvarDebug.BoolValue)
		fkn_log("Map: %s", g_sMapName);
}

/**
 * @brief Starts a timer that gets match information in the prematch
 *
 * @noreturn
 */
public void Start_PreMatch()
{
	CheckPlayersPresent();
	StartMatch();
}

/**
 * @brief Starts the match.
 *
 * @noreturn
 */
public void StartMatch()
{
	char sCfgConvar[32];
	g_cvarConfigCfg.GetString(sCfgConvar, sizeof(sCfgConvar));
	int iHumanCount = GetHumanCount();

	if (iHumanCount == g_cvarPlayersToStart.IntValue)
	{
		g_bPlayersToStartFull = !g_bPlayersToStartFull;
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

stock bool PlayersAndRQs()
{
	JSON_Object joMatch = JsonObjectMatch(DIR_CACHEMATCH);

	if (joMatch == null)
	{
		fkn_log("Error: fkn_Players() - (joMatch == null)");
		return false;
	}

	JSON_Array jaTA = view_as<JSON_Array>(joMatch.GetObject("teamA"));
	JSON_Array jaTB = view_as<JSON_Array>(joMatch.GetObject("teamB"));

	if (jaTA == null)
	{
		fkn_log("Error: fkn_Players() - (jaTA == null)");
		return false;
	}
	else if (jaTB == null)
	{
		fkn_log("Error: fkn_Players() - (jaTB == null)");
		return false;
	}

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		JSON_Object joPlayerTA = jaTA.GetObject(iID);
		JSON_Object joPlayerTB = jaTB.GetObject(iID);

		joPlayerTA.GetString("steamid", g_Players[TeamA][iID].steamid, MAX_AUTHID_LENGTH);
		joPlayerTB.GetString("steamid", g_Players[TeamB][iID].steamid, MAX_AUTHID_LENGTH);

		joPlayerTA.GetString("personaname", g_Players[TeamA][iID].name, MAX_NAME_LENGTH);
		joPlayerTB.GetString("personaname", g_Players[TeamB][iID].name, MAX_NAME_LENGTH);

		joPlayerTA.GetString("steamid", g_RageQuit[TeamA][iID].steamid, MAX_AUTHID_LENGTH);
		joPlayerTB.GetString("steamid", g_RageQuit[TeamB][iID].steamid, MAX_AUTHID_LENGTH);
	}

	json_cleanup_and_delete(joMatch);
	return true;
}

public void ClienIndexList()
{
	for (int i = 1; i <= MAX_INDEX_PLAYER; i++)
	{
		if (!IsHuman(i))
			continue;

		char sStemaID[32];
		if (!GetClientAuthId(i, AuthId_SteamID64, sStemaID, sizeof(sStemaID)))
			continue;

		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (StrEqual(g_Players[TeamA][iID].steamid, sStemaID))
			{
				if (g_Players[TeamA][iID].client != i)
				{
					g_Players[TeamA][iID].client = i;
					continue;
				}
			}

			if (StrEqual(g_Players[TeamB][iID].steamid, sStemaID))
			{
				if (g_Players[TeamB][iID].client != i)
				{
					g_Players[TeamB][iID].client = i;
					continue;
				}
			}
		}
	}
}