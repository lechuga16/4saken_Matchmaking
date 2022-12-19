#if defined jarvis_ragequit_included
	#endinput
#endif
#define jarvis_ragequit_included

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

public void Event_PlayerDisconnect(Handle hEvent, char[] sEventName, bool bDontBroadcast)
{
	if (!g_cvarEnable.BoolValue || !LGO_IsMatchModeLoaded())
		return;

	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClientIndex(iClient))
		return;

	char sSteamId[32];
	if(!GetClientAuthId(iClient, AuthId_Steam2, sSteamId, sizeof(sSteamId)))
		return;

	if (strcmp(sSteamId, "BOT") == 0)
		return;

	char sReason[128];
	GetEventString(hEvent, "reason", sReason, sizeof(sReason));

	for (int iID = 0; iID <= 4; iID++)
	{
		if (StrEqual(sSteamId, g_sSteamIDTA[iID], false))
		{
			g_bCheckSteamIDTA[iID] = false;

			if (IsInReady())
				continue;

			DataPack hdataPack;
			g_hTimerRageQuitTA[iID] = CreateDataTimer(g_cvarTimerRageQuit.FloatValue, Timer_RageQuit, hdataPack);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamA);

			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_sNameTA[iID], sSteamId, g_cvarTimerRageQuit.IntValue);

			if(g_cvarDebug.BoolValue)
				Forsaken_log("Player %s (%s) left the game, his waiting time is %d seconds. Reason: %s", g_sNameTA[iID], sSteamId, g_cvarTimerRageQuit.IntValue, sReason);
		}

		if (StrEqual(sSteamId, g_sSteamIDTB[iID], false))
		{
			g_bCheckSteamIDTB[iID] = false;

			if (IsInReady())
				continue;

			DataPack hdataPack;
			g_hTimerRageQuitTB[iID] = CreateDataTimer(g_cvarTimerRageQuit.FloatValue, Timer_RageQuit, hdataPack);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamB);

			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_sNameTB[iID], sSteamId, g_cvarTimerRageQuit.IntValue);

			if(g_cvarDebug.BoolValue)
				Forsaken_log("Player %s (%s) left the game, his waiting time is %d seconds. Reason: %s", g_sNameTB[iID], sSteamId, g_cvarTimerRageQuit.IntValue, sReason);
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
	for (int iID = 0; iID <= 4; iID++)
	{
		if (StrEqual(sAuth, g_sSteamIDTA[iID], false))
		{
			if (g_hTimerRageQuitTA[iID] != null)
				return true;
		}

		if (StrEqual(sAuth, g_sSteamIDTB[iID], false))
		{
			if (g_hTimerRageQuitTB[iID] != null)
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
	for (int iID = 0; iID <= 4; iID++)
	{
		if (StrEqual(sAuth, g_sSteamIDTA[iID], false))
		{
			KillTimer(g_hTimerRageQuitTA[iID]);
			g_hTimerRageQuitTA[iID] = null;
			CPrintToChatAll("%t %t", "Tag", "PlayerReturned", g_sNameTA[iID], g_sSteamIDTA[iID]);
			Forsaken_log("ClientConnected: %N no longer ragequiter", iClient);
		}

		if (StrEqual(sAuth, g_sSteamIDTB[iID], false))
		{
			KillTimer(g_hTimerRageQuitTB[iID]);
			g_hTimerRageQuitTB[iID] = null;
			CPrintToChatAll("%t %t", "Tag", "PlayerReturned", g_sNameTB[iID], g_sSteamIDTB[iID]);
			Forsaken_log("ClientConnected: %N no longer ragequiter", iClient);
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
	int iID = hPack.ReadCell();
	ForsakenTeam Team = hPack.ReadCell();

	char sBuffer[128];
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "BanReasonRQ");
	CreateOffLineBan(iID, Team, g_cvarBanRageQuit.IntValue, sBuffer)
	ForceEndGame(ragequit);
	return Plugin_Stop;
}
