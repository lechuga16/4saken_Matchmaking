#if defined _jarvis_waiting_included
	#endinput
#endif
#define _jarvis_waiting_included

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Starts the timer that checks if all players are online, start the game or ban unconnected players.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 * 		Only works if the cvar is enabled.
 *
 * @noreturn
 */
public void WaitingPlayers()
{
	if (!IsGameCompetitive(g_TypeMatch))
		return;

	KillTimerWaitPlayers();
	KillTimerWaitPlayersAnnouncer();
	KillTimerCheckPlayers();

	g_hTimerWait		  = CreateTimer(g_cvarTimeWait.FloatValue, Timer_WaitPlayers, _, TIMER_REPEAT);
	g_hTimerWaitAnnouncer = CreateTimer(g_cvarTimeWaitAnnouncer.FloatValue, Timer_WaitPlayersAnnounce, _, TIMER_REPEAT);
	g_hTimerCheckList	  = CreateTimer(2.0, Timer_CheckListPlayers, _, TIMER_REPEAT);
}

/**
 * @brief Kill the timer that checks if all players are online, start the game or ban unconnected players.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 * 		Only works if the cvar is enabled.
 *
 * @return			Stop the timer.
 */
public Action Timer_WaitPlayers(Handle timer)
{
	KillTimerWaitPlayersAnnouncer();
	if (CheckMissingPlayers(TeamA) && CheckMissingPlayers(TeamB))
	{
		CPrintToChatAll("%t %t", "Tag", "AllConnected");
		ServerCommand("sm_forcestart");
		KillTimerCheckPlayers();
	}
	else
	{
		CPrintToChatAll("%t %t", "Tag", "NotAllConnected");
		BanDesertionPlayers();
		CreateTimer(5.0, Timer_StartEndGame);
	}

	return Plugin_Stop;
}

/**
 * @brief Starts the timer that announces players who have not connected.
 * 		After the time specified in the cvar.
 * 		Only works if the cvar is enabled.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 *
 * @return			Continue the timer.
 */
public Action Timer_WaitPlayersAnnounce(Handle timer)
{
	MissingPlayers();
	return Plugin_Continue;
}

/**
 * @brief Start the timer that check if all players are connected
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 * 		Only works if the cvar is enabled.
 *
 * @return			Continue the timer.
 */
public Action Timer_CheckListPlayers(Handle timer)
{
	for (int index = 1; index <= MaxClients; index++)
	{
		if (!IsClientInGame(index) || IsFakeClient(index))
			continue;

		char sSteamid[32];
		GetClientAuthId(index, AuthId_SteamID64, sSteamid, sizeof(sSteamid));

		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (StrEqual(sSteamid, g_Players[TeamA][iID].steamid, false))
				g_RageQuit[TeamA][iID].ispresent = true;
			else if (StrEqual(sSteamid, g_Players[TeamB][iID].steamid, false))
				g_RageQuit[TeamB][iID].ispresent = true;
		}
	}
	return Plugin_Continue;
}

/**
 * @brief Print the names of the players who have not connected.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 * 		Only works if the cvar is enabled.
 *
 * @noreturn
 */
public void MissingPlayers()
{
	char
		tmpBufferTA[128],
		tmpBufferTB[128],
		printBufferTA[512],
		printBufferTB[512];

	Format(tmpBufferTA, sizeof(tmpBufferTA), "%t %t{olive}", "Tag", "WaitingTeamA");
	StrCat(printBufferTA, sizeof(printBufferTA), tmpBufferTA);

	Format(tmpBufferTB, sizeof(tmpBufferTB), "%t %t{olive}", "Tag", "WaitingTeamB");
	StrCat(printBufferTB, sizeof(printBufferTB), tmpBufferTB);

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (!g_RageQuit[TeamA][iID].ispresent)
		{
			Format(tmpBufferTA, sizeof(tmpBufferTA), "%s ", g_Players[TeamA][iID].name);
			StrCat(printBufferTA, sizeof(printBufferTA), tmpBufferTA);
		}

		if (!g_RageQuit[TeamB][iID].ispresent)
		{
			Format(tmpBufferTB, sizeof(tmpBufferTB), "%s ", g_Players[TeamB][iID].name);
			StrCat(printBufferTB, sizeof(printBufferTB), tmpBufferTB);
		}
	}

	if (!CheckMissingPlayers(TeamA))
		CPrintToChatAll(printBufferTA);
	if (!CheckMissingPlayers(TeamB))
		CPrintToChatAll(printBufferTB);
}

/**
 * @brief Check if all players are connected
 *
 * @param Team		Team to check.
 *
 * @return bool		True if all players are connected, false otherwise.
 */
public bool CheckMissingPlayers(ForsakenTeam Team)
{
	if (Team == TeamA)
	{
		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (!g_RageQuit[TeamA][iID].ispresent)
				return false;
		}
	}
	else if (Team == TeamB)
	{
		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (!g_RageQuit[TeamB][iID].ispresent)
				return false;
		}
	}

	return true;
}

/**
 * @brief Ban players who have not connected
 * 		After the time specified in the cvar.
 * 		Only works if the cvar is enabled.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 *
 * @noreturn
 */
public void BanDesertionPlayers()
{
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (!g_RageQuit[TeamA][iID].ispresent)
		{
			switch (BansAccount(iID, TeamA, "%BanCode:02%"))
			{
				case 0: CreateOffLineBan(iID, TeamA, g_cvarBanDesertion.IntValue, "%t", "BanDesertion");
				case 1: CreateOffLineBan(iID, TeamA, g_cvarBanDesertionx2.IntValue, "%t", "BanDesertion");
				default: CreateOffLineBan(iID, TeamA, g_cvarBanDesertionx3.IntValue, "%t", "BanDesertion");
			}
		}

		if (!g_RageQuit[TeamB][iID].ispresent)
		{
			switch (BansAccount(iID, TeamB, "%BanCode:02%"))
			{
				case 0: CreateOffLineBan(iID, TeamB, g_cvarBanDesertion.IntValue, "%t", "BanDesertion");
				case 1: CreateOffLineBan(iID, TeamB, g_cvarBanDesertionx2.IntValue, "%t", "BanDesertion");
				default: CreateOffLineBan(iID, TeamB, g_cvarBanDesertionx3.IntValue, "%t", "BanDesertion");
			}
		}
	}
}

/**
 * @brief Kills the timer stored in the g_hTimerWait Handle.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 *
 * @noreturn
 */
public void KillTimerWaitPlayers()
{
	if (g_hTimerWait != null)
	{
		delete g_hTimerWait;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Wait{default}", "Tag");
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Timer not found{default}", "Tag");
	}
}

/**
 * @brief Kills the timer stored in the g_hTimerWaitAnnouncer Handle.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 *
 * @noreturn
 */
public void KillTimerWaitPlayersAnnouncer()
{
	if (g_hTimerWaitAnnouncer != null)
	{
		delete g_hTimerWaitAnnouncer;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Wait Announcer{default}", "Tag");
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Timer not found{default}", "Tag");
	}
}

/**
 * @brief Kills the timer stored in the g_hTimerCheckList Handle.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 *
 * @noreturn
 */
public void KillTimerCheckPlayers()
{
	if (g_hTimerCheckList != null)
	{
		delete g_hTimerCheckList;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Check List{default}", "Tag");
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Timer not found{default}", "Tag");
	}
}

/**
 * @brief Start the timer that runs the end of the game.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 *
 * @return			Stop the timer.
 */
public Action Timer_StartEndGame(Handle timer)
{
	ForceEndGame(desertion);
	return Plugin_Stop;
}