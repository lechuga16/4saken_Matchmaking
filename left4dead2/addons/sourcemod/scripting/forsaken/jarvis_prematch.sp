#if defined _jarvis_prematch_included
	#endinput
#endif
#define _jarvis_prematch_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar g_cvarChangeMap;
bool g_bPreMatch = true;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_prematch()
{
	g_cvarChangeMap	= CreateConVar("sm_jarvis_changemap", "1", "Change the map when it is verified that it does not correspond to the match", FCVAR_NONE, true, 0.0, true, 1.0);

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
	fkn_log(true, "g_sMapName: %s | g_TypeMatch: %s", g_sMapName, g_TypeMatch);
	fkn_MapName(g_sMapName, sizeof(g_sMapName));
	g_TypeMatch = fkn_TypeMatch();
	fkn_Players(g_TypeMatch, false, true);
	ClienIndexList();
}

public Action Cmd_ListPlayers(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_listplayers");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%t %t", "Tag", "TypeLobby", sTypeMatch[g_TypeMatch]);

	char
		sTmpBufferTA[128],
		sTmpBufferTB[128],
		sPrintBufferTA[1024],
		sPrintBufferTB[1024];

	Format(sTmpBufferTA, sizeof(sTmpBufferTA), "%t %t", "Tag", (g_TypeMatch == duel) ? "PlayerA" : "TeamA");
	StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

	Format(sTmpBufferTB, sizeof(sTmpBufferTB), "%t %t", "Tag", (g_TypeMatch == duel) ? "PlayerB" : "TeamB");
	StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		Format(sTmpBufferTA, sizeof(sTmpBufferTA), "({olive}%s{default}:{green}%s{default})", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid);
		StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

		Format(sTmpBufferTB, sizeof(sTmpBufferTB), "({olive}%s{default}:{green}%s{default})", g_Players[TeamB][iID].name, g_Players[TeamB][iID].steamid);
		StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

		if(iID == 0 && g_TypeMatch == duel)
			break;

		if (iID == 1)
		{
			StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), "\n");
			StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), "\n");
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


	CReplyToCommand(iClient, "%t %t", "Tag", "MatchInfo", sTypeCFG[g_TypeMatch], g_sMapName);

	return Plugin_Handled;
}

public Action Cmd_ClientID(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_clientid");
		return Plugin_Handled;
	}

	char
		sTmpBufferTA[32],
		sTmpBufferTB[32],
		sPrintBufferTA[128],
		sPrintBufferTB[128];

	Format(sTmpBufferTA, sizeof(sTmpBufferTA), "%t Team A", "Tag");
	StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

	Format(sTmpBufferTB, sizeof(sTmpBufferTB), "%t Team B", "Tag");
	StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		Format(sTmpBufferTA, sizeof(sTmpBufferTA), "[{olive}%s{default}:{green}%d{default}]", g_Players[TeamA][iID].name, g_Players[TeamA][iID].client);
		StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

		Format(sTmpBufferTB, sizeof(sTmpBufferTB), "[{olive}%s{default}:{green}%d{default}]", g_Players[TeamB][iID].name, g_Players[TeamB][iID].client);
		StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

		if(iID == 0 && g_TypeMatch == duel)
			break;
	}

	CReplyToCommand(iClient, sPrintBufferTA);
	CReplyToCommand(iClient, sPrintBufferTB);
	return Plugin_Handled;
}

public Action Cmd_RefreshListPlayers(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_refreshlistplayers");
		return Plugin_Handled;
	}

	fkn_Players(g_TypeMatch, false, true);
	ClienIndexList();
	FakeClientCommand(iClient, "sm_jarvis_listplayers");
	return Plugin_Handled;
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

public void MatchInfo_PreMatch()
{
	if(g_TypeMatch == duel)
		ServerCommand("sv_maxplayers 6");

	CreateTimer(5.0, Timer_MatchInfo);
}

Action Timer_MatchInfo(Handle hTimer)
{

	if(g_cvarChangeMap.BoolValue)
		ServerCommand("confogl_match_map %s", g_sMapName);

	fkn_log(true, "Map: %s", g_sMapName);

	ServerCommand("sm_forcematch %s", sTypeCFG[g_TypeMatch]);
	return Plugin_Stop;
}

void ClienIndexList()
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
			
			if(iID == 0 && g_TypeMatch == duel)
				break;
		}
	}
}