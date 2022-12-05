#if defined _jarvis_prematch_included
	#endinput
#endif
#define _jarvis_prematch_included

public void PreMatch()
{
	if (!g_cvarEnable.BoolValue || LGO_IsMatchModeLoaded())
		return;

	CreateTimer(1.0, GetMatchData);
}

public void OnClientConnected(int client)
{
	if (!g_cvarEnable.BoolValue || LGO_IsMatchModeLoaded())
		return;

	if (g_Lobby == unranked || g_Lobby == invalid)
		return;

	if (IsHuman(client))
		StartMatch();
}

public void StartMatch()
{
	switch (GetHumanCount())
	{
		case 1:
		{
			CPrintToChatAll("[J.A.R.V.I.S] Falta 1 jugador para cambiar a zonemod");
		}
		case 2:
		{
			CPrintToChatAll("[J.A.R.V.I.S] Cambiando a ZoneMod");
			ServerCommand("sm_forcematch zonemod");
		}
	}
}

public Action GetMatchData(Handle timer)
{
	g_Lobby = view_as<TypeMatch>(Forsaken_TypeMatch());
	for (int i = 0; i <= 3; i++)
	{
		Forsaken_TeamA(i, g_sSteamIDTA[i], STEAMID_LENGTH);
		Forsaken_TeamB(i, g_sSteamIDTB[i], STEAMID_LENGTH);
	}
	return Plugin_Continue;
}

public int CountPlayers()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			iCount++;
		}
	}

	return iCount;
}

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