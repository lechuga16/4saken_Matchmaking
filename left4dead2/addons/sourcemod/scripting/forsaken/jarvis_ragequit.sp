#if defined _jarvis_ragequit_included
	#endinput
#endif
#define _jarvis_ragequit_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
	g_cvarBanRageQuit,
	g_cvarBanRageQuitx2,
	g_cvarBanRageQuitx3;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_RageQuit()
{
	g_cvarBanRageQuit	= CreateConVar("sm_jarvis_banragequit", "2880", "The time to ban the player (in minutes, 0 = permanent) for ragequit", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuitx2 = CreateConVar("sm_jarvis_banragequitx2", "5760", "The time to ban the player (in minutes, 0 = permanent) for ragequit for the second time", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuitx3 = CreateConVar("sm_jarvis_banragequitx3", "10080", "The time to ban the player (in minutes, 0 = permanent) for ragequit for the third time", FCVAR_NONE, true, 0.0);
}

public void ONCA_RageQuit(int iClient, const char[] sAuth64)
{
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sAuth64, g_Players[TeamA][iID].steamid, false))
		{
			DataPack pack = new DataPack();
			pack.WriteCell(TeamA);
			pack.WriteCell(iID);

			if (IsRageQuiters(iClient, pack))
			{
				RemoveRageQuiters(iClient, pack);
				fkn_log(false, "ClientConnected: %N is ragequiter", iClient);
			}
		}
		else if (StrEqual(sAuth64, g_Players[TeamB][iID].steamid, false))
		{
			DataPack pack = new DataPack();
			pack.WriteCell(TeamB);
			pack.WriteCell(iID);

			if (IsRageQuiters(iClient, pack))
			{
				RemoveRageQuiters(iClient, pack);
				fkn_log(false, "ClientConnected: %N is ragequiter", iClient);
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
			g_RageQuit[TeamA][iID].ispresent = false;

			DataPack hdataPack;
			g_RageQuit[TeamA][iID].timer = CreateDataTimer(60.0, Timer_RageQuit, hdataPack);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamA);

			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_Players[TeamA][iID].name, sSteamId, 5);
			fkn_log(true, "Player %s (%s) left the game, his waiting time is %d minutes. Reason: %s", g_Players[TeamA][iID].name, sSteamId, 5, sReason);
		}

		if (StrEqual(sSteamId, g_Players[TeamB][iID].steamid, false))
		{
			g_RageQuit[TeamB][iID].ispresent = false;

			DataPack hdataPack;
			g_RageQuit[TeamB][iID].timer = CreateDataTimer(60.0, Timer_RageQuit, hdataPack);
			hdataPack.WriteCell(iID);
			hdataPack.WriteCell(TeamB);

			CPrintToChatAll("%t %t", "Tag", "RageQuit", g_Players[TeamB][iID].name, sSteamId, 5);
			fkn_log(true, "Player %s (%s) left the game, his waiting time is %d minutes. Reason: %s", g_Players[TeamB][iID].name, sSteamId, 5, sReason);
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
public bool IsRageQuiters(int iClient, DataPack pack)
{
	pack.Reset();
	int 
		iID = pack.ReadCell(),
		Team = pack.ReadCell();

	if (g_RageQuit[Team][iID].timer != null)
		return true;

	return false;
}

/**
 * Remove the timer of the player who has left the game.
 *
 * @param iClient		Client index.
 * @param sAuth			SteamID of the player.
 * @noreturn
 **/
public void RemoveRageQuiters(int iClient, DataPack pack)
{
	pack.Reset();
	int 
		iID = pack.ReadCell(),
		Team = pack.ReadCell();

	delete g_RageQuit[Team][iID].timer;
	g_RageQuit[Team][iID].timer = null;
	CPrintToChatAll("%t %t", "Tag", "PlayerReturned", g_Players[Team][iID].name, g_Players[Team][iID].steamid);
	fkn_log(false, "ClientConnected: %N no longer ragequiter", iClient);
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
	static int 
		iTimerCycle = 0,
		iTimerInvert = 5;

	switch (iTimerCycle)
	{
		case 2: CPrintToChatAll("%t %t", "Tag", "RageQuitAnnouncer", iTimerInvert);
		case 3: CPrintToChatAll("%t %t", "Tag", "RageQuitAnnouncer", iTimerInvert);
		case 4: CPrintToChatAll("%t %t", "Tag", "RageQuitAnnouncer", iTimerInvert);
		case 5: BanRageQuit(hPack);
	}

	if(iTimerCycle  == 5)
		return Plugin_Stop;

	iTimerInvert--;
	iTimerCycle++;
	return Plugin_Continue;
}

void BanRageQuit(DataPack hPack)
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
}