#if defined _jarvis_teams_included
	#endinput
#endif
#define _jarvis_teams_included


public void OnMapStart()
{
	//Set scores after a modified transition
	if (g_bHasTransitioned) {
		CreateTimer(1.0, Timer_OnMapStartDelay, _, TIMER_FLAG_NO_MAPCHANGE); //Clients have issues connecting if team swap happens exactly on map start, so we delay it
		g_bHasTransitioned = false;
	}
}

public Action Timer_OnMapStartDelay(Handle hTimer)
{
	if (g_iPointsTeamA < g_iPointsTeamB)
		TeamManagement(true);

	if (g_iPointsTeamA > g_iPointsTeamB)
		g_bDirectionTeam = TeamManagement(false);

	return Plugin_Stop;
}

public void OnMapEnd()
{
	//In case map is force-chenged before custom transition takes place
	if (g_hTransitionTimer != null)
	{
		g_bHasTransitioned = false;
		delete g_hTransitionTimer;
	}
}

public void L4D2_OnEndVersusModeRound_Post()
{
	if (InSecondHalfOfRound())
		g_hTransitionTimer = CreateTimer(15.0, OnRoundEnd_Post);
}

public Action OnRoundEnd_Post(Handle hTimer)
{
	g_hTransitionTimer = null;
	g_bHasTransitioned = true;

	g_iPointsTeamA = L4D2Direct_GetVSCampaignScore(0);
	g_iPointsTeamB = L4D2Direct_GetVSCampaignScore(1);

	return Plugin_Stop;
}

public void CheckTeam(int iClient)
{
	ForsakenTeam ClientTeam = IsForsakenTeam(iClient);

	if(InSecondHalfOfRound())
	{// second round
		switch (ClientTeam)
		{
			case Team0:
			{
				ChangeClientTeamEx(iClient, L4DTeam_Spectator);
			}
			case Team1:
			{
				ChangeClientTeamEx(iClient, L4DTeam_Infected);
			}
			case Team2:
			{
				ChangeClientTeamEx(iClient, L4DTeam_Survivor);
			}
		}
	}
	else
	{// first round
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
		return true;
	}
	else
	{
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

	for (int i = 0; i <= 4; i++)
	{
		if (StrEqual(sSteamID, g_sSteamIDTA[i], false))
			return TeamManagement(false) ? Team1 : Team2;

		if (StrEqual(sSteamID, g_sSteamIDTB[i], false))
			return TeamManagement(false) ? Team2 : Team1;
	}
	return Team0;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_cvarDebug.BoolValue)
	return;

	int	winner = event.GetInt("winner");
	int	reason = event.GetInt("reason");
	char message[64];
	event.GetString("message", message, 64);
	float time = event.GetFloat("time");
	CPrintToChatAll("winner: %d", winner);
	CPrintToChatAll("reason: %d", reason);
	CPrintToChatAll("message: %s", message);
	CPrintToChatAll("time: %.3f", time);
}


bool TeamManagement(bool ChangeDirection)
{
// if ChangeDirection is true, reverse the order, if false, just retrieve the existing value
	if(ChangeDirection)
		g_bDirectionTeam = !g_bDirectionTeam

// true, maintains the correct order. false, reverse the order
	return g_bDirectionTeam;
}