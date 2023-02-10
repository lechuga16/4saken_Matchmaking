#if defined _jarvis_waiting_included
	#endinput
#endif
#define _jarvis_waiting_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
	g_cvarTimeWait,
	g_cvarBanDesertion,
	g_cvarBanDesertionx2,
	g_cvarBanDesertionx3;

Handle
	g_hTimerWait;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public void OnPluginStart_Waiting()
{
	g_cvarTimeWait		 = CreateConVar("sm_jarvis_timewait", "5", "Time to wait for players to enter the server (in minutes).", FCVAR_NONE, true, 2.0, true, 30.0);
	g_cvarBanDesertion	 = CreateConVar("sm_jarvis_bandesertion", "720", "The time to ban the player (in minutes, 0 = permanent) for not arrive on time", FCVAR_NONE, true, 0.0);
	g_cvarBanDesertionx2 = CreateConVar("sm_jarvis_bandesertionx2", "2880", "The time to ban the player (in minutes, 0 = permanent) for not arrive on time for the second time", FCVAR_NONE, true, 0.0);
	g_cvarBanDesertionx3 = CreateConVar("sm_jarvis_bandesertionx3", "5760", "The time to ban the player (in minutes, 0 = permanent) for not arrive on time for the third time", FCVAR_NONE, true, 0.0);

	RegAdminCmd("sm_jarvis_missingplayers", Cmd_MissingPlayers, ADMFLAG_ROOT, "Print the missing players");
}

/**
 * @brief Starts the timer that checks if all players are online, start the game or ban unconnected players.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 * 		Only works if the cvar is enabled.
 *
 * @noreturn
 */
public void ORUI_Waiting()
{
	if (g_TypeMatch == invalid || g_TypeMatch == unranked)
		return;

	KillTimerWaitPlayers();
	g_hTimerWait = CreateTimer(60.0, Timer_WaitPlayers, _, TIMER_REPEAT);
}

public Action Cmd_MissingPlayers(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "[4saken] Usage: sm_jarvis_missingplayers");
		return Plugin_Handled;
	}

	MissingPlayers();
	return Plugin_Handled;
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Kill the timer that checks if all players are online, start the game or ban unconnected players.
 * 		Only works if the game is not started.
 * 		Only works if the game is not in the waiting room.
 * 		Only works if the cvar is enabled.
 *
 * @return			Stop the timer.
 */
public Action Timer_WaitPlayers(Handle iTimer)
{
	static int iCycleWait = 1;

	if (g_hTimerWait != iTimer)
	{
		iCycleWait = 1;
		return Plugin_Stop;
	}

	if (iCycleWait < g_cvarTimeWait.IntValue)
	{
		CPrintToChatAll("%t %t", "Tag", "WaitAnnouncer", (g_cvarTimeWait.IntValue - iCycleWait));
		CheckListPlayers();
		MissingPlayers();
	}
	else if (iCycleWait == g_cvarTimeWait.IntValue)
	{
		if (CheckMissingPlayers(TeamA) && CheckMissingPlayers(TeamB))
		{
			CPrintToChatAll("%t %t", "Tag", "AllConnected");
			ServerCommand("sm_forcestart");
		}
		else
		{
			CPrintToChatAll("%t %t", "Tag", "NotAllConnected");
			BanDesertionPlayers();
			CreateTimer(5.0, Timer_StartEndGame);
		}

		g_hTimerWait = null;
		return Plugin_Stop;
	}

	iCycleWait++;
	return Plugin_Continue;
}

public void CheckListPlayers()
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

			if (iID == 0 && g_TypeMatch == duel)
				break;
		}
	}
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

	Format(tmpBufferTA, sizeof(tmpBufferTA), "%t %t", "Tag", (g_TypeMatch == duel) ? "WaitingPlayerA" : "WaitingTeamA");
	StrCat(printBufferTA, sizeof(printBufferTA), tmpBufferTA);

	Format(tmpBufferTB, sizeof(tmpBufferTB), "%t %t", "Tag", (g_TypeMatch == duel) ? "WaitingPlayerB" : "WaitingTeamB");
	StrCat(printBufferTB, sizeof(printBufferTB), tmpBufferTB);

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (!g_RageQuit[TeamA][iID].ispresent)
		{
			Format(tmpBufferTA, sizeof(tmpBufferTA), "{olive}%s{default} ", g_Players[TeamA][iID].name);
			StrCat(printBufferTA, sizeof(printBufferTA), tmpBufferTA);
		}

		if (!g_RageQuit[TeamB][iID].ispresent)
		{
			Format(tmpBufferTB, sizeof(tmpBufferTB), "{olive}%s ", g_Players[TeamB][iID].name);
			StrCat(printBufferTB, sizeof(printBufferTB), tmpBufferTB);
		}

		if (iID == 0 && g_TypeMatch == duel)
			break;
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

			if (iID == 0 && g_TypeMatch == duel)
				break;
		}
	}
	else if (Team == TeamB)
	{
		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (!g_RageQuit[TeamB][iID].ispresent)
				return false;

			if (iID == 0 && g_TypeMatch == duel)
				break;
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
				case 0: CreateOffLineBan(iID, TeamA, g_cvarBanDesertion.IntValue, "%t", "BanReasonDesertion");
				case 1: CreateOffLineBan(iID, TeamA, g_cvarBanDesertionx2.IntValue, "%t", "BanReasonDesertion");
				default: CreateOffLineBan(iID, TeamA, g_cvarBanDesertionx3.IntValue, "%t", "BanReasonDesertion");
			}
		}

		if (!g_RageQuit[TeamB][iID].ispresent)
		{
			switch (BansAccount(iID, TeamB, "%BanCode:02%"))
			{
				case 0: CreateOffLineBan(iID, TeamB, g_cvarBanDesertion.IntValue, "%t", "BanReasonDesertion");
				case 1: CreateOffLineBan(iID, TeamB, g_cvarBanDesertionx2.IntValue, "%t", "BanReasonDesertion");
				default: CreateOffLineBan(iID, TeamB, g_cvarBanDesertionx3.IntValue, "%t", "BanReasonDesertion");
			}
		}

		if (iID == 0 && g_TypeMatch == duel)
			break;
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
		g_hTimerWait = null;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Wait{default}", "Tag");
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Wait not found{default}", "Tag");
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