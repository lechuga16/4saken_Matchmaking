#if defined _jarvis_teams_included
	#endinput
#endif
#define _jarvis_teams_included

public void Teams()
{
	if (!g_cvarEnable.BoolValue || !LGO_IsMatchModeLoaded())
		return;

	g_hTimerOT = CreateTimer(2.0, OrganizeTeams, _, TIMER_REPEAT);
}

public void CheckTeam(int iClient)
{
	ForsakenTeam ClientTeam = IsForsakenTeam(iClient);

	switch (ClientTeam)
	{
		case Team0:
		{
			ChangeClientTeamEx(iClient, L4DTeam_Spectator);
		}
		case Team1:
		{
			ChangeClientTeamEx(iClient, L4DTeam_Survivor);
		}
		case Team2:
		{
			ChangeClientTeamEx(iClient, L4DTeam_Infected);
		}
	}
}

void Event_PlayerDisconnect(Handle hEvent, char[] sEventName, bool bDontBroadcast)
{
	if (!g_cvarEnable.BoolValue)
		return;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (client <= 0 || client > MaxClients)
		return;

	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	if (strcmp(steamId, "BOT") == 0)
		return;

	char reason[128];
	GetEventString(hEvent, "reason", reason, sizeof(reason));
	char playerName[128];
	GetEventString(hEvent, "name", playerName, sizeof(playerName));

	char timedOut[256];
	Format(timedOut, sizeof(timedOut), "%s timed out", playerName);

	CPrintToChatAll("[J.A.R.V.I.S] %s (%s) dejó el juego: %s", playerName, steamId, reason);
}

public Action OrganizeTeams(Handle timer)
{
	for (int index = 1; index <= MaxClients; index++)
	{
		if (IsClientInGame(index) && !IsFakeClient(index))
			CheckTeam(index);
	}

	return Plugin_Continue;
}

stock bool ChangeClientTeamEx(int client, L4DTeam team)
{
	if (GetClientTeamEx(client) == team)
		return true;

	else if (GetTeamHumanCount(team) == GetTeamMaxHumans(team))
		return false;

	if (team != L4DTeam_Survivor)
	{
		ChangeClientTeam(client, view_as<int>(team));
		if(g_cvarDebug.BoolValue)
			CPrintToChatAll("Client: %N | Team: %s", client, sL4DTeam[team]);
		return true;
	}
	else
	{
		if(g_cvarDebug.BoolValue)
			CPrintToChatAll("Client: %N | Team: %s", client, sL4DTeam[team]);
			
		int bot = FindSurvivorBot();
		if (bot > 0)
		{
			int flags = GetCommandFlags("sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags);
			return true;
		}
	}
	return false;
}

stock int GetTeamHumanCount(L4DTeam team)
{
	int humans = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeamEx(client) == team)
		{
			humans++;
		}
	}

	return humans;
}

stock int GetTeamMaxHumans(L4DTeam team)
{
	if (team == L4DTeam_Survivor)
	{
		return GetConVarInt(survivor_limit);
	}
	else if (team == L4DTeam_Infected)
	{
		return GetConVarInt(z_max_player_zombies);
	}
	return MaxClients;
}

/* return -1 if no bot found, clientid otherwise */
stock int FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeamEx(client) == L4DTeam_Survivor)
		{
			return client;
		}
	}
	return -1;
}

stock L4DTeam GetClientTeamEx(int client)
{
	return view_as<L4DTeam>(GetClientTeam(client));
}

stock ForsakenTeam IsForsakenTeam(int iClient)
{
	char sSteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));

	bool iTeamIndex = L4D2_AreTeamsFlipped();

	for (int i = 0; i <= 4; i++)
	{
		if (StrEqual(sSteamID, g_sSteamIDTA[i], false))
		{
			return iTeamIndex ? Team2 : Team1;
		}

		if (StrEqual(sSteamID, g_sSteamIDTB[i], false))
		{
			return iTeamIndex ? Team1 : Team2;
		}
	}
	return Team0;
}