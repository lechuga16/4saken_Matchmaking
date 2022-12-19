#if defined jarvis_teams_included
	#endinput
#endif
#define jarvis_teams_included

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

/** 
 * Create a timer that prevents bots from dying when the game is loading.
 * 		Only works if confogl is started.
 * 
 * @noreturn
 */
public void OrganizeTeams()
{
	if (!LGO_IsMatchModeLoaded())
		return;

	if (g_bPreMatch)
		return;
		
	CreateTimer(12.0, Timer_PreventKillBot, _, TIMER_REPEAT);
}

/** 
 * Create a timer that organizes the teams.
 * 		Only works if confogl is started.
 * 
 * @param hTimer	Timer handle.
 * @return			Stop the timer.
 */
public Action Timer_PreventKillBot(Handle hTimer)
{
	g_hTimerOT = CreateTimer(3.0, Timer_OrganizeTeams, _, TIMER_REPEAT);
	return Plugin_Stop;
}

/** 
 * Organize the teams.
 * 		Only works if confogl is started.
 * 
 * @param hTimer		Timer handle.
 * @return			Continue the timer.
 */
public Action Timer_OrganizeTeams(Handle hTimer)
{
	for (int index = 1; index <= MaxClients; index++)
	{
		if (!IsClientInGame(index) || IsFakeClient(index))
			continue;
		CheckTeam(index);
	}

	return Plugin_Continue;
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/** 
 * Check the client's ForsakenTeam and switch teams.
 * 
 * @param iClient		Client index.
 * @noreturn
 */
public void CheckTeam(int iClient)
{
	ForsakenTeam ClientTeam = IsForsakenTeam(iClient);

	switch (ClientTeam)
	{
		case Team0:
			ChangeClientTeamEx(iClient, L4DTeam_Spectator);
		case TeamA:
			ChangeClientTeamEx(iClient, L4DTeam_Survivor);
		case TeamB:
			ChangeClientTeamEx(iClient, L4DTeam_Infected);
	}
}

/** 
 * Changes the client's team.
 * 
 * @param client		Client index.
 * @param team			L4DTeam Team.
 * @return				True or false.
 */
stock bool ChangeClientTeamEx(int client, L4DTeam team)
{
	if (GetClientTeamEx(client) == team)
		return true;

	else if (GetTeamHumanCount(team) == GetTeamMaxHumans(team))
		return false;

	if (team != L4DTeam_Survivor)
	{
		ChangeClientTeam(client, view_as<int>(team));
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t Client: %N | Team: %s", "Tag", client, sL4DTeam[team]);
		return true;
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t Client: %N | Team: %s", "Tag", client, sL4DTeam[team]);

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

/** 
 * Returns the number of humans for a team.
 * 
 * @param team			L4DTeam Team.
 * @return				Number of humans.
 */
stock int GetTeamHumanCount(L4DTeam team)
{
	int humans = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeamEx(client) == team)
			humans++;
	}

	return humans;
}

/**
 * Returns the maximum number of humans for a team.
 * 
 * @param team			Team.
 * @return				Maximum number of humans.
 */
stock int GetTeamMaxHumans(L4DTeam team)
{
	if (team == L4DTeam_Survivor)
		return survivor_limit.IntValue;
	else if (team == L4DTeam_Infected)
		return z_max_player_zombies.IntValue;

	return MaxClients;
}

/**
 * Finds a survivor bot.
 * 
 * @return				Client index.
 */
stock int FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeamEx(client) == L4DTeam_Survivor)
			return client;
	}
	return -1;
}

/**
 * Returns the client's team.
 * 
 * @param client		Client index.
 * @return				Team.
 */
stock L4DTeam GetClientTeamEx(int client)
{
	return view_as<L4DTeam>(GetClientTeam(client));
}

/**
 * Checks if the client is a member of ForsakenTeam (Team0|TeamA|TeamB).
 *
 * @param iClient		Client index.
 * @return				Team0|TeamA|TeamB.
 */
stock ForsakenTeam IsForsakenTeam(int iClient)
{
	char sSteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));

	bool bAreTeamsFlipped = L4D2_AreTeamsFlipped();

	for (int i = 0; i <= 4; i++)
	{
		if (StrEqual(sSteamID, g_sSteamIDTA[i], false))
			return bAreTeamsFlipped ? TeamB : TeamA;
		else if (StrEqual(sSteamID, g_sSteamIDTB[i], false))
			return bAreTeamsFlipped ? TeamA : TeamB;
	}
	return Team0;
}

/**
 * Kills the timer for organizing teams.
 * 
 * @noreturn
 */
public void KillTimerOT()
{
	if (g_hTimerOT != null)
	{
		KillTimer(g_hTimerOT);
		g_hTimerOT = null;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t KillTimer(TimerOT)", "Tag");
	}
}