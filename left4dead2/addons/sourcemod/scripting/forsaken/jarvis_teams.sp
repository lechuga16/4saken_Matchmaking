#if defined _jarvis_teams_included
	#endinput
#endif
#define _jarvis_teams_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
	survivor_limit,
	z_max_player_zombies;

Handle g_hTimerManager = null;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_Teams()
{
	RegAdminCmd("sm_jarvis_killtimer", Cmd_KillTimer, ADMFLAG_GENERIC, "Kills the timer for organizing teams.");

	survivor_limit		 = FindConVar("survivor_limit");
	z_max_player_zombies = FindConVar("z_max_player_zombies");
}

/**
 * Create a timer that prevents bots from dying when the game is loading.
 * 		Only works if confogl is started.
 *
 * @noreturn
 */
public void ORUI_Teams()
{
	if (!IsGameCompetitive(g_TypeMatch) || InSecondHalfOfRound())
		return;

	CreateTimer(10.0, Timer_PreventKillBot);
}

public Action Cmd_KillTimer(int iClient, int iArgs)
{
	if (iArgs != 1)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_killtimer <manager|waitplayers|waitreadyup>");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg));

	if (StrEqual(sArg, "manager", false))
	{
		KillTimerManager();
		if (!g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Organizing Teams{default}", "Tag");
	}
	else if (StrEqual(sArg, "waitplayers", false))
	{
		KillTimerWaitPlayers();
		KillTimerWaitPlayersAnnouncer();
		if (!g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Wait{default}/{green}Announcer{default}", "Tag");
	}
	else if (StrEqual(sArg, "waitreadyup", false))
	{
		KillTimerWaitReadyup();
		if (!g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Readyup Wait{default}", "Tag");
	}

	return Plugin_Continue;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

/**
 * Create a timer that organizes the teams.
 * 		Only works if confogl is started.
 *
 * @param hTimer	Timer handle.
 * @return			Stop the timer.
 */
public Action Timer_PreventKillBot(Handle hTimer)
{
	KillTimerManager();
	g_hTimerManager = CreateTimer(3.0, Timer_OrganizeTeams, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
		{
			if (GetClientTeamEx(iClient) == L4DTeam_Spectator)
				return;
			ServerCommand("sm_swapto 1 #%d", GetClientUserId(iClient));
		}
		case TeamA:
		{
			if (GetClientTeamEx(iClient) == L4DTeam_Survivor)
				return;

			if (GetTeamHumanCount(L4DTeam_Survivor) == GetTeamMaxHumans(L4DTeam_Survivor))
				ServerCommand("sm_swapto 1 #%d", GetClientUserId(iClient));
			ServerCommand("sm_swapto 2 #%d", GetClientUserId(iClient));
		}
		case TeamB:
		{
			if (GetClientTeamEx(iClient) == L4DTeam_Infected)
				return;

			if (GetTeamHumanCount(L4DTeam_Infected) == GetTeamMaxHumans(L4DTeam_Infected))
				ServerCommand("sm_swapto 1 #%d", GetClientUserId(iClient));
			ServerCommand("sm_swapto 3 #%d", GetClientUserId(iClient));
		}
	}
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
	GetClientAuthId(iClient, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	bool bAreTeamsFlipped = L4D2_AreTeamsFlipped();

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sSteamID, g_Players[TeamA][iID].steamid, false))
			return bAreTeamsFlipped ? TeamB : TeamA;
		else if (StrEqual(sSteamID, g_Players[TeamB][iID].steamid, false))
			return bAreTeamsFlipped ? TeamA : TeamB;
	}
	return Team0;
}

/**
 * Kills the timer for Manager teams.
 *
 * @noreturn
 */
public void KillTimerManager()
{
	if (g_hTimerManager != null)
	{
		delete g_hTimerManager;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Organizing Teams{default}", "Tag");
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Timer not found{default}", "Tag");
	}
}