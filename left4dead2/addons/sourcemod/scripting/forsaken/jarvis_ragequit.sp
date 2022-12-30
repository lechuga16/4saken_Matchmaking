#if defined _jarvis_ragequit_included
	#endinput
#endif
#define _jarvis_ragequit_included

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
		if (StrEqual(sSteamId, g_PlayersTA[iID].steamid, false))
		{
			g_RageQuitTA[iID].ispresent = false;

			if (IsInReady())
				continue;

			DataPack hdataPack;
			g_RageQuitTA[iID].timer = CreateDataTimer(g_cvarTimerRageQuit.FloatValue, Timer_RageQuit, hdataPack);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamA);

			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_PlayersTA[iID].name, sSteamId, g_cvarTimerRageQuit.IntValue);

			if(g_cvarDebug.BoolValue)
				fkn_log("Player %s (%s) left the game, his waiting time is %d seconds. Reason: %s", g_PlayersTA[iID].name, sSteamId, g_cvarTimerRageQuit.IntValue, sReason);
		}

		if (StrEqual(sSteamId, g_PlayersTB[iID].steamid, false))
		{
			g_RageQuitTB[iID].ispresent = false;

			if (IsInReady())
				continue;

			DataPack hdataPack;
			g_RageQuitTB[iID].timer = CreateDataTimer(g_cvarTimerRageQuit.FloatValue, Timer_RageQuit, hdataPack);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamB);

			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_PlayersTB[iID].name, sSteamId, g_cvarTimerRageQuit.IntValue);

			if(g_cvarDebug.BoolValue)
				fkn_log("Player %s (%s) left the game, his waiting time is %d seconds. Reason: %s", g_PlayersTB[iID].name, sSteamId, g_cvarTimerRageQuit.IntValue, sReason);
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
		if (StrEqual(sAuth, g_PlayersTA[iID].steamid, false))
		{
			if (g_RageQuitTA[iID].timer != null)
				return true;
		}

		if (StrEqual(sAuth, g_PlayersTB[iID].steamid, false))
		{
			if (g_RageQuitTB[iID].timer != null)
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
		if (StrEqual(sAuth, g_PlayersTA[iID].steamid, false))
		{
			KillTimer(g_RageQuitTA[iID].timer);
			g_RageQuitTA[iID].timer = null;
			CPrintToChatAll("%t %t", "Tag", "PlayerReturned", g_PlayersTA[iID].name, g_PlayersTA[iID].steamid);
			fkn_log("ClientConnected: %N no longer ragequiter", iClient);
		}

		if (StrEqual(sAuth, g_PlayersTB[iID].steamid, false))
		{
			KillTimer(g_RageQuitTB[iID].timer);
			g_RageQuitTB[iID].timer = null;
			CPrintToChatAll("%t %t", "Tag", "PlayerReturned", g_PlayersTB[iID].name, g_PlayersTB[iID].steamid);
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
	int iID = hPack.ReadCell();
	ForsakenTeam Team = hPack.ReadCell();

	char sBuffer[128];
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "BanReasonRQ");
	CreateOffLineBan(iID, Team, g_cvarBanRageQuit.IntValue, sBuffer)
	ForceEndGame(ragequit);
	return Plugin_Stop;
}
