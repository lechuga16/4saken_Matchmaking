#if defined _jarvis_teams_included
	#endinput
#endif
#define _jarvis_teams_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

Handle
	g_hTimerSurvivorFix = null,
	g_hTimerManager = null;

ConVar 
	survivor_limit,
	z_max_player_zombies;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_Teams()
{
	RegAdminCmd("sm_jarvis_killtimer", Cmd_KillTimer, ADMFLAG_GENERIC, "Kills the timer for organizing teams.");
	survivor_limit = FindConVar("survivor_limit");
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
	if (InSecondHalfOfRound() || g_TypeMatch == invalid || g_TypeMatch == unranked)
		return;

	g_hTimerManager = CreateTimer(2.0, Timer_OrganizeTeams, _, TIMER_REPEAT);
	g_hTimerSurvivorFix = CreateTimer(1.0, Timer_SurvivorFix);
}

public void OME_Teams()
{
	delete g_hTimerSurvivorFix;
}

public Action Cmd_KillTimer(int iClient, int iArgs)
{
	if (iArgs != 1)
	{
		CReplyToCommand(iClient, "[4saken] Usage: sm_jarvis_killtimer <manager|waitplayers|waitreadyup>");
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
		if (IsClientInGame(index) && IsClientConnected(index) && !IsFakeClient(index) && !IsClientSourceTV(index))
			CheckTeam(index);
	}

	return Plugin_Continue;
}

public Action Timer_SurvivorFix(Handle hTimer)
{
	FixBotCount();
	g_hTimerSurvivorFix = null;
	return Plugin_Stop;
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

			if(g_cvarDebugOT.BoolValue)
				CPrintToChatAll("%t {green}Organizing Teams{default}: %N | %s -> %s", "Tag", iClient, sL4DTeam[GetClientTeamEx(iClient)], sL4DTeam[ClientTeam]);
			ServerCommand("sm_swapto force 1 #%d", GetClientUserId(iClient));
		}
		case TeamA:
		{
			if (GetClientTeamEx(iClient) == L4DTeam_Survivor)
				return;

			if (GetTeamHumanCount(L4DTeam_Survivor) == GetTeamMaxHumans(L4DTeam_Survivor))
			{
				if(g_cvarDebugOT.BoolValue)
					CPrintToChatAll("%t {green}Organizing Teams{default}: %N | %s -> Team0 (TeamA Full)", "Tag", iClient, sL4DTeam[ClientTeam]);
				ServerCommand("sm_swapto 1 #%d", GetClientUserId(iClient));
				return;
			}

			if(g_cvarDebugOT.BoolValue)
				CPrintToChatAll("%t {green}Organizing Teams{default}: %N | %s -> %s", "Tag", iClient, sL4DTeam[GetClientTeamEx(iClient)], sL4DTeam[ClientTeam]);
			ServerCommand("sm_swapto force 2 #%d", GetClientUserId(iClient));
		}
		case TeamB:
		{
			if (GetClientTeamEx(iClient) == L4DTeam_Infected)
				return;

			if (GetTeamHumanCount(L4DTeam_Infected) == GetTeamMaxHumans(L4DTeam_Infected))
			{
				if(g_cvarDebugOT.BoolValue)
					CPrintToChatAll("%t {green}Organizing Teams{default}: %N | %s -> Team0 (TeamB Full)", "Tag", iClient, sL4DTeam[ClientTeam]);
				ServerCommand("sm_swapto 1 #%d", GetClientUserId(iClient));
				return;
			}

			if(g_cvarDebugOT.BoolValue)
				CPrintToChatAll("%t {green}Organizing Teams{default}: %N | %s -> %s", "Tag", iClient, sL4DTeam[GetClientTeamEx(iClient)], sForsakenTeam[ClientTeam]);
			ServerCommand("sm_swapto force 3 #%d", GetClientUserId(iClient));
		}
	}
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

		if(iID == 0 && g_TypeMatch == duel)
			break;
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
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Organizing Teams not found{default}", "Tag");
	}
}

stock void FixBotCount()
{
	int survivor_count = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeamEx(client) == L4DTeam_Survivor)
		{
			survivor_count++;
		}
	}
	int limit = GetConVarInt(survivor_limit);
	if (survivor_count < limit)
	{
		int bot;
		for (; survivor_count < limit; survivor_count++)
		{
			bot = CreateFakeClient("k9Q6CK42");
			if (bot != 0)
			{
				ChangeClientTeam(bot, view_as<int>(L4DTeam_Survivor));
				RequestFrame(OnFrame_KickBot, GetClientUserId(bot));
			}
		}
	}
	else if (survivor_count > limit)
	{
		for (int client = 1; client <= MaxClients && survivor_count > limit; client++)
		{
			if(IsClientInGame(client) && GetClientTeamEx(client) == L4DTeam_Survivor)
			{
				if (IsFakeClient(client))
				{
					survivor_count--;
					KickClient(client);
				}
			}
		}
	}
}

public void OnFrame_KickBot(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0) KickClient(client);
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