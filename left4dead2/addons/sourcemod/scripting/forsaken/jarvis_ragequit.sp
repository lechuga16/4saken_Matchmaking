#if defined _jarvis_ragequit_included
	#endinput
#endif
#define _jarvis_ragequit_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
	g_cvarTimerRageQuit,
	g_cvarBanRageQuit,
	g_cvarBanRageQuitx2,
	g_cvarBanRageQuitx3;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_RageQuit()
{
	g_cvarTimerRageQuit = CreateConVar("sm_jarvis_timeragequit", "300.0", "The time to check if the player ragequit", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuit	= CreateConVar("sm_jarvis_banragequit", "2880", "The time to ban the player (in minutes, 0 = permanent) for ragequit", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuitx2 = CreateConVar("sm_jarvis_banragequitx2", "5760", "The time to ban the player (in minutes, 0 = permanent) for ragequit for the second time", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuitx3 = CreateConVar("sm_jarvis_banragequitx3", "10080", "The time to ban the player (in minutes, 0 = permanent) for ragequit for the third time", FCVAR_NONE, true, 0.0);
}

public void OnCA_RageQuit(int iClient, const char[] sAuth)
{
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sAuth, g_Players[TeamA][iID].steamid, false))
			g_Players[TeamA][iID].client = iClient;
		else if (StrEqual(sAuth, g_Players[TeamB][iID].steamid, false))
			g_Players[TeamB][iID].client = iClient;
	}

	if (IsRageQuiters(iClient, sAuth))
	{
		RemoveRageQuiters(iClient, sAuth);
		fkn_log("ClientConnected: %N is ragequiter", iClient);
	}
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/
public void PlayerDisconnect_ragequit(Handle hEvent, const char[] sSteamId)
{
	char sReason[128];
	GetEventString(hEvent, "reason", sReason, sizeof(sReason));

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sSteamId, g_Players[TeamA][iID].steamid, false))
		{
			g_RageQuit[TeamA][iID].ispresent = false;

			if (IsInReady())
				continue;

			DataPack hdataPack;
			g_RageQuit[TeamA][iID].timer = CreateDataTimer(g_cvarTimerRageQuit.FloatValue, Timer_RageQuit, hdataPack);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamA);

			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_Players[TeamA][iID].name, sSteamId, g_cvarTimerRageQuit.IntValue);

			if (g_cvarDebug.BoolValue)
				fkn_log("Player %s (%s) left the game, his waiting time is %d seconds. Reason: %s", g_Players[TeamA][iID].name, sSteamId, g_cvarTimerRageQuit.IntValue, sReason);
		}

		if (StrEqual(sSteamId, g_Players[TeamB][iID].steamid, false))
		{
			g_RageQuit[TeamB][iID].ispresent = false;

			if (IsInReady())
				continue;

			DataPack hdataPack;
			g_RageQuit[TeamB][iID].timer = CreateDataTimer(g_cvarTimerRageQuit.FloatValue, Timer_RageQuit, hdataPack);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamB);

			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_Players[TeamB][iID].name, sSteamId, g_cvarTimerRageQuit.IntValue);

			if (g_cvarDebug.BoolValue)
				fkn_log("Player %s (%s) left the game, his waiting time is %d seconds. Reason: %s", g_Players[TeamB][iID].name, sSteamId, g_cvarTimerRageQuit.IntValue, sReason);
		}
	}
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * Check if the player has left the game.
 *
 * @param iClient		Client index.
 * @param sAuth			SteamID of the player.
 * @return				True if the player has left the game, false otherwise.
 **/
public bool IsRageQuiters(int iClient, const char[] sAuth)
{
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sAuth, g_Players[TeamA][iID].steamid, false))
		{
			if (g_RageQuit[TeamA][iID].timer != null)
				return true;
		}

		if (StrEqual(sAuth, g_Players[TeamB][iID].steamid, false))
		{
			if (g_RageQuit[TeamB][iID].timer != null)
				return true;
		}
	}
	return false;
}

/**
 * Remove the timer of the player who has left the game.
 *
 * @param iClient		Client index.
 * @param sAuth			SteamID of the player.
 * @noreturn
 **/
public void RemoveRageQuiters(int iClient, const char[] sAuth)
{
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sAuth, g_Players[TeamA][iID].steamid, false))
		{
			delete g_RageQuit[TeamA][iID].timer;
			g_RageQuit[TeamA][iID].timer = null;
			CPrintToChatAll("%t %t", "Tag", "PlayerReturned", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid);
			fkn_log("ClientConnected: %N no longer ragequiter", iClient);
		}

		if (StrEqual(sAuth, g_Players[TeamB][iID].steamid, false))
		{
			delete g_RageQuit[TeamB][iID].timer;
			g_RageQuit[TeamB][iID].timer = null;
			CPrintToChatAll("%t %t", "Tag", "PlayerReturned", g_Players[TeamB][iID].name, g_Players[TeamB][iID].steamid);
			fkn_log("ClientConnected: %N no longer ragequiter", iClient);
		}
	}
}

/**
 * Timer that executes the ban of the player by SourceBans.
 *
 * @param iTimer		Timer index.
 * @param iClient		Client index.
 * @return				Stop the timer.
 **/
public Action Timer_RageQuit(Handle iTimer, DataPack hPack)
{
	hPack.Reset();
	int			 iID  = hPack.ReadCell();
	ForsakenTeam Team = hPack.ReadCell();

	switch (BansAccount(iID, Team, "%BanCode:01%"))
	{
		case 0: CreateOffLineBan(iID, Team, g_cvarBanRageQuit.IntValue, "%t", "BanReasonRQ");
		case 1: CreateOffLineBan(iID, Team, g_cvarBanRageQuitx2.IntValue, "%t", "BanReasonRQ");
		default: CreateOffLineBan(iID, Team, g_cvarBanRageQuitx3.IntValue, "%t", "BanReasonRQ");
	}

	ForceEndGame(ragequit);
	return Plugin_Stop;
}
