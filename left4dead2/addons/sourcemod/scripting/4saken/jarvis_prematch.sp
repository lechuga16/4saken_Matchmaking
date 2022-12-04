#if defined _jarvis_prematch_included
	#endinput
#endif
#define _jarvis_prematch_included

public void PreMatch()
{
	if (LGO_IsMatchModeLoaded())
		return;

	CreateTimer(2.0, GetMatchData);

	if (g_Lobby == unranked || g_Lobby == invalid)
		return;

	CreateTimer(2.0, StartMatch);
}

public Action StartMatch(Handle timer)
{
	switch (CountPlayers())
	{
		case 1:
		{
			if (g_bEnnounceStart)
			{
				g_bEnnounceStart = false;
				CPrintToChatAll("[J.A.R.V.I.S] Falta 1 jugador para cambiar a zonemod");
			}
		}
		case 2:
		{
			CPrintToChatAll("[J.A.R.V.I.S] Cambiando a ZoneMod");
			ServerCommand("sm_forcematch zonemod");
		}
	}
	return Plugin_Continue;
}

public Action GetMatchData(Handle timer)
{
	g_Lobby = view_as<TypeMatch>(_4saken_TypeMatch());
	for (int i = 0; i <= 3; i++)
	{
		_4saken_Team1(i, SteamIDT1[i], STEAMID_LENGTH);
		_4saken_Team2(i, SteamIDT2[i], STEAMID_LENGTH);
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