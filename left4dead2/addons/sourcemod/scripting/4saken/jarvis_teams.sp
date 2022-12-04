#if defined _jarvis_teams_included
	#endinput
#endif
#define _jarvis_teams_included

public void Event_PlayerTeam(Event hEvent, char[] sEventName, bool bDontBroadcast)
{
	int iUserId = hEvent.GetInt("userid");
	CheckTeam(iUserId);
}

public Action isplayer(int iClient, int iArgs)
{
	CheckTeam(iClient);
	return Plugin_Continue;
}

public CheckTeam(int iClient)
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
	if (g_cvarDebug.BoolValue)
		CReplyToCommand(iClient, "Team: %d", ClientTeam)
}

public Action OrganizeTeams(Handle timer)
{
	for (int index = 1; index <= MaxClients; index++)
	{
		if (IsClientInGame(index) && !IsFakeClient(index))
		{
			CheckTeam(index);
		}
	}
	return Plugin_Continue;
}

stock bool ChangeClientTeamEx(iClient, L4DTeam team)
{
	if (L4D_GetClientTeam(iClient) == team)
		return true;

	if (team != L4DTeam_Survivor)
	{
		ChangeClientTeam(iClient, view_as<int>(team));
		return true;
	}
	else
	{
		int bot = FindSurvivorBot();

		if (bot > 0)
		{
			int flags = GetCommandFlags("sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
			FakeClientCommand(iClient, "sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags);
			return true;
		}
	}
	return false;
}

stock int FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsFakeClient(client) && L4D_GetClientTeam(client) == L4DTeam_Survivor)
			return client;
	}
	return -1;
}

stock ForsakenTeam IsForsakenTeam(int iClient)
{
	char sSteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));

	for (int i = 0; i <= 4; i++)
	{
		if (StrEqual(sSteamID, SteamIDT1[i], false))
			return Team1;

		if (StrEqual(sSteamID, SteamIDT2[i], false))
			return Team2;
	}
	return Team0;
}
