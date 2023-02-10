#if defined _jarvis_ragequit_included
	#endinput
#endif
#define _jarvis_ragequit_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
	g_cvarTimerRageQuit,
	g_cvarPauseRageQuit,
	g_cvarBanRageQuit,
	g_cvarBanRageQuitx2,
	g_cvarBanRageQuitx3;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_RageQuit()
{
	g_cvarTimerRageQuit = CreateConVar("sm_jarvis_timeragequit", "5", "The time to wait before the player can reconnect (in minutes).", FCVAR_NONE, true, 2.0, true, 30.0);
	g_cvarPauseRageQuit = CreateConVar("sm_jarvis_pauseragequit", "1", "Pause the game when a player ragequit", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarBanRageQuit	= CreateConVar("sm_jarvis_banragequit", "2880", "The time to ban the player (in minutes, 0 = permanent) for ragequit", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuitx2 = CreateConVar("sm_jarvis_banragequitx2", "5760", "The time to ban the player (in minutes, 0 = permanent) for ragequit for the second time", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuitx3 = CreateConVar("sm_jarvis_banragequitx3", "10080", "The time to ban the player (in minutes, 0 = permanent) for ragequit for the third time", FCVAR_NONE, true, 0.0);
}

public void ONCA_RageQuit(int iClient)
{
	char  sAuth64[MAX_AUTHID_LENGTH];
	GetClientAuthId(iClient, AuthId_SteamID64, sAuth64, MAX_AUTHID_LENGTH);
	ONCA_IndexPlayers(iClient, sAuth64);

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sAuth64, g_Players[TeamA][iID].steamid, false))
		{
			if (IsRageQuiters(iID, TeamA))
			{
				if(IsInPause() && g_cvarPauseRageQuit.BoolValue)
					ServerCommand("sm_forceunpause");
				CPrintToChatAll("%t %t", "Tag", "PlayerReturned", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid);
			}

		}
		else if (StrEqual(sAuth64, g_Players[TeamB][iID].steamid, false))
		{
			if (IsRageQuiters(iID, TeamB))
			{
				if(IsInPause() && g_cvarPauseRageQuit.BoolValue)
					ServerCommand("sm_forceunpause");
				CPrintToChatAll("%t %t", "Tag", "PlayerReturned", g_Players[TeamB][iID].name, g_Players[TeamB][iID].steamid);
			}
		}

		if(iID == 0 && g_TypeMatch == duel)
			break;
	}
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/
public void PlayerDisconnect_ragequit(Handle hEvent, const char[] sSteamId)
{
	if (IsInReady())
		return;

	char sReason[128];
	GetEventString(hEvent, "reason", sReason, sizeof(sReason));

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sSteamId, g_Players[TeamA][iID].steamid, false))
		{
			if (g_RageQuit[TeamA][iID].timer != null)
				fkn_log(true, "Ragequit Timer is not null, Client: %s", g_Players[TeamA][iID].name);

			g_RageQuit[TeamA][iID].ispresent = false;

			DataPack hdataPack;
			g_RageQuit[TeamA][iID].timer = CreateDataTimer(60.0, Timer_RageQuit, hdataPack, TIMER_REPEAT);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamA);
			hdataPack.Reset();

			if(!IsInPause() && g_cvarPauseRageQuit.BoolValue)
				ServerCommand("sm_forcepause");
			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_Players[TeamA][iID].name);
			CPrintToChatAll("%t %t", "Tag", "RageQuitAnnouncer", g_cvarTimerRageQuit.IntValue);
			fkn_log(true, "Player %s (%s) left the game, his waiting time is %d minutes. Reason: %s", g_Players[TeamA][iID].name, sSteamId, g_cvarTimerRageQuit.IntValue, sReason);
		}

		if (StrEqual(sSteamId, g_Players[TeamB][iID].steamid, false))
		{
			if (g_RageQuit[TeamA][iID].timer != null)
				fkn_log(true, "Ragequit Timer is not null, Client: %s", g_Players[TeamB][iID].name);

			g_RageQuit[TeamB][iID].ispresent = false;

			DataPack hdataPack;
			g_RageQuit[TeamB][iID].timer = CreateDataTimer(60.0, Timer_RageQuit, hdataPack, TIMER_REPEAT);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamB);

			if(!IsInPause() && g_cvarPauseRageQuit.BoolValue)
				ServerCommand("sm_forcepause");
			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_Players[TeamB][iID].name, g_cvarTimerRageQuit.IntValue);
			CPrintToChatAll("%t %t", "Tag", "RageQuitAnnouncer", g_cvarTimerRageQuit.IntValue);
			fkn_log(true, "Player %s (%s) left the game, his waiting time is %d minutes. Reason: %s", g_Players[TeamB][iID].name, sSteamId, g_cvarTimerRageQuit.IntValue, sReason);
		}

		if(iID == 0 && g_TypeMatch == duel)
			break;
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
public bool IsRageQuiters(int iID, ForsakenTeam Team)
{
	if (g_RageQuit[Team][iID].timer != null)
	{
		g_RageQuit[Team][iID].timer = null;
		return true;
	}
	return false;
}

/**
 * Timer that executes the ban of the player by SourceBans.
 *
 * @param iTimer		Timer index.
 * @param iClient		Client index.
 * @return				Stop the timer.
 **/
Action Timer_RageQuit(Handle iTimer, DataPack hPack)
{
	static int iTimerCycle = 1;
	hPack.Reset();
	int iID  = hPack.ReadCell();
	ForsakenTeam Team = hPack.ReadCell();

	if (g_RageQuit[Team][iID].timer != iTimer)
	{
		iTimerCycle = 1;
		return Plugin_Stop;
	}

	if(!IsInPause() && g_cvarPauseRageQuit.BoolValue)
		ServerCommand("sm_forcepause");

	if (iTimerCycle < g_cvarTimerRageQuit.IntValue)
		CPrintToChatAll("%t %t", "Tag", "RageQuitAnnouncer", (g_cvarTimerRageQuit.IntValue - iTimerCycle));
	else if(iTimerCycle == g_cvarTimerRageQuit.IntValue)
	{

		BanRageQuit(iID, Team);
		g_RageQuit[Team][iID].timer = null;
		return Plugin_Stop;
	}

	iTimerCycle++;
	return Plugin_Continue;
}

void BanRageQuit(int iID, ForsakenTeam Team)
{

	switch (BansAccount(iID, Team, "%BanCode:01%"))
	{
		case 0: CreateOffLineBan(iID, Team, g_cvarBanRageQuit.IntValue, "%t", "BanReasonRQ");
		case 1: CreateOffLineBan(iID, Team, g_cvarBanRageQuitx2.IntValue, "%t", "BanReasonRQ");
		default: CreateOffLineBan(iID, Team, g_cvarBanRageQuitx3.IntValue, "%t", "BanReasonRQ");
	}
	
	CreateTimer(2.0, Timer_EndGame);
}

Action Timer_EndGame(Handle iTimer)
{
	ForceEndGame(ragequit);
	return Plugin_Stop;
}