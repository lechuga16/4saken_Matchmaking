#if defined jarvis_ragequit_included
	#endinput
#endif
#define jarvis_ragequit_included

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

public void Event_PlayerDisconnect(Handle hEvent, char[] sEventName, bool bDontBroadcast)
{
	if (!g_cvarEnable.BoolValue)
		return;

	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (iClient <= 0 || iClient > MaxClients)
		return;

	char sSteamId[32];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamId, sizeof(sSteamId));
	if (strcmp(sSteamId, "BOT") == 0)
		return;

	char
		sReason[128],
		sPlayerName[128];

	GetEventString(hEvent, "reason", sReason, sizeof(sReason));
	GetEventString(hEvent, "name", sPlayerName, sizeof(sPlayerName));

	for (int iID = 0; iID <= 4; iID++)
	{
		if (StrEqual(sSteamId, g_sSteamIDTA[iID], false))
		{
			g_bCheckSteamIDTA[iID] = false;

			if (IsInReady())
				continue;

			g_hTimerRageQuitTA[iID] = CreateTimer(g_cvarTimerRageQuit.FloatValue, Timer_RageQuit, iClient, TIMER_REPEAT);
			CPrintToChatAll("%t %t", "Tag", "RageQuit", sPlayerName, sSteamId, g_cvarTimerRageQuit.FloatValue);

			if(g_cvarDebug.BoolValue)
				Forsaken_log("Player %s (%s) left the game, his waiting time is %.1f seconds.Reason: %s", sPlayerName, sSteamId, g_cvarTimerRageQuit.FloatValue, sReason);
		}

		if (StrEqual(sSteamId, g_sSteamIDTB[iID], false))
		{
			g_bCheckSteamIDTB[iID] = false;

			if (IsInReady())
				continue;

			g_hTimerRageQuitTB[iID] = CreateTimer(g_cvarTimerRageQuit.FloatValue, Timer_RageQuit, iClient, TIMER_REPEAT);
			CPrintToChatAll("%t %t", "Tag", "RageQuit", sPlayerName, sSteamId, g_cvarTimerRageQuit.FloatValue);

			if(g_cvarDebug.BoolValue)
				Forsaken_log("Player %s (%s) left the game, his waiting time is %.1f seconds.Reason: %s", sPlayerName, sSteamId, g_cvarTimerRageQuit.FloatValue, sReason);
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
		}

		if (StrEqual(sAuth, g_sSteamIDTB[iID], false))
		{
			KillTimer(g_hTimerRageQuitTB[iID]);
			g_hTimerRageQuitTB[iID] = null;
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
public Action Timer_RageQuit(Handle iTimer, int iClient)
{
	char sReason[64];
	Format(sReason, sizeof(sReason), "%t %t", "Tag", "ReasonRageQuit");
	SBPP_BanPlayer(CONSOLE, iClient, g_cvarBanRageQuit.IntValue, sReason);
	return Plugin_Stop;
}
