#if defined _jarvis_readyup_included
	#endinput
#endif
#define _jarvis_readyup_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
	g_cvarReadyupWait,
	g_cvarBanReadyup,
	g_cvarBanReadyupx2,
	g_cvarBanReadyupx3;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_Readyup()
{
	g_cvarReadyupWait  = CreateConVar("sm_jarvis_readyupwait", "360.0", "The time to wait for the players to ready up", FCVAR_NONE, true, 0.0);
	g_cvarBanReadyup   = CreateConVar("sm_jarvis_banreadyup", "120", "The time to ban the player (in minutes, 0 = permanent) for not ready up on time", FCVAR_NONE, true, 0.0);
	g_cvarBanReadyupx2 = CreateConVar("sm_jarvis_banreadyupx2", "240", "The time to ban the player (in minutes, 0 = permanent) for not ready up on time for the second time", FCVAR_NONE, true, 0.0);
	g_cvarBanReadyupx3 = CreateConVar("sm_jarvis_banreadyupx3", "480", "The time to ban the player (in minutes, 0 = permanent) for not ready up on time for the third time", FCVAR_NONE, true, 0.0);
}

public void ORUI_Readyup()
{
	KillTimerWaitReadyup();
	g_hTimerWaitReadyup = CreateTimer(g_cvarReadyupWait.FloatValue, Timer_ReadyUpWait);
}

public Action Timer_ReadyUpWait(Handle timer)
{
	bool IsBanned = false;
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		int
			iClientTA = g_Players[TeamA][iID].client,
			iClientTB = g_Players[TeamB][iID].client;

		char sReason[128];
		Format(sReason, sizeof(sReason), "%s %t", JVPrefix, "BanReadyUp");

		if (iClientTA != CONSOLE && !IsReady(iClientTA))
		{
			switch (BansAccount(iID, TeamA, "%BanCode:03%"))
			{
				case 0: SBPP_BanPlayer(CONSOLE, iClientTA, g_cvarBanReadyup.IntValue, sReason);
				case 1: SBPP_BanPlayer(CONSOLE, iClientTA, g_cvarBanReadyupx2.IntValue, sReason);
				default: SBPP_BanPlayer(CONSOLE, iClientTA, g_cvarBanReadyupx3.IntValue, sReason);
			}

			fkn_log(true, "Player not Ready: Client: %N | TeamA | Ban: %d", iClientTA, g_cvarBanReadyup.IntValue);
			if (!IsBanned)
				IsBanned = !IsBanned;
		}
		else if (iClientTB != CONSOLE && !IsReady(iClientTB))
		{
			switch (BansAccount(iID, TeamB, "%BanCode:03%"))
			{
				case 0: SBPP_BanPlayer(CONSOLE, iClientTB, g_cvarBanReadyup.IntValue, sReason);
				case 1: SBPP_BanPlayer(CONSOLE, iClientTB, g_cvarBanReadyupx2.IntValue, sReason);
				default: SBPP_BanPlayer(CONSOLE, iClientTB, g_cvarBanReadyupx3.IntValue, sReason);
			}

			fkn_log(true, "Player not Ready: Client: %N | TeamB | Ban: %d", iClientTB, g_cvarBanReadyup.IntValue);
			if (!IsBanned)
				IsBanned = !IsBanned;
		}

		if(iID == 0 && g_TypeMatch == duel)
			break;
	}

	if (IsBanned)
		ForceEndGame(ragequit);

	return Plugin_Stop;
}

public void KillTimerWaitReadyup()
{
	if (g_hTimerWaitReadyup != null)
	{
		delete g_hTimerWaitReadyup;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Readyup{default}", "Tag");
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Readyup not found{default}", "Tag");
	}
}
