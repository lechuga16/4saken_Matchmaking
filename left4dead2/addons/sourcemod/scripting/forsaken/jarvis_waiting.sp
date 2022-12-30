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
	if (!LGO_IsMatchModeLoaded())
		return;

	if (g_bPreMatch)
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
		CreateTimer(10.0, Timer_StartEndGame);
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
		GetClientAuthId(index, AuthId_Steam2, sSteamid, sizeof(sSteamid));

		for (int iID = 0; iID <= 4; iID++)
		{
			if (StrEqual(sSteamid, g_PlayersTA[iID].steamid, false))
				g_RageQuitTA[iID].ispresent = true;
			else if (StrEqual(sSteamid, g_PlayersTB[iID].steamid, false))
				g_RageQuitTB[iID].ispresent = true;
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

	Format(tmpBufferTA, sizeof(tmpBufferTA), "%t %t:\n{olive}", "Tag", "WaitingSurvivors");
	StrCat(printBufferTA, sizeof(printBufferTA), tmpBufferTA);

	Format(tmpBufferTB, sizeof(tmpBufferTB), "%t %t:\n{olive}", "Tag", "WaitingInfected");
	StrCat(printBufferTB, sizeof(printBufferTB), tmpBufferTB);

	for (int iID = 0; iID <= 4; iID++)
	{
		if (!g_RageQuitTA[iID].ispresent)
		{
			Format(tmpBufferTA, sizeof(tmpBufferTA), "%s ", g_PlayersTA[iID].name);
			StrCat(printBufferTA, sizeof(printBufferTA), tmpBufferTA);
		}

		if (!g_RageQuitTB[iID].ispresent)
		{
			Format(tmpBufferTB, sizeof(tmpBufferTB), "%s ", g_PlayersTB[iID].name);
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
		for (int iID = 0; iID <= 3; iID++)
		{
			if (!g_RageQuitTA[iID].ispresent)
				return false;
		}
	}
	else if (Team == TeamB)
	{
		for (int iID = 0; iID <= 3; iID++)
		{
			if (!g_RageQuitTB[iID].ispresent)
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
	for (int iID = 0; iID <= 4; iID++)
	{
		if (!g_RageQuitTA[iID].ispresent)
		{
			char sBuffer[128];
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "BanDesertion");
			CreateOffLineBan(iID, TeamA, g_cvarBanDesertion.IntValue, sBuffer);
		}
		if (!g_RageQuitTB[iID].ispresent)
		{
			char sBuffer[128];
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "BanDesertion");
			CreateOffLineBan(iID, TeamB, g_cvarBanDesertion.IntValue, sBuffer);
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
		KillTimer(g_hTimerWait);
		g_hTimerWait = null;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t KillTimer(Timer Wait)", "Tag");
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
		KillTimer(g_hTimerWaitAnnouncer);
		g_hTimerWaitAnnouncer = null;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t KillTimer(Timer Wait Announcer)", "Tag");
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
		KillTimer(g_hTimerCheckList);
		g_hTimerCheckList = null;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t KillTimer(Timer Check List)", "Tag");
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