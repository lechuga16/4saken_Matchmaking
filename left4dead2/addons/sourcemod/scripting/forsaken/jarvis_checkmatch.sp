#if defined _jarvis_checkmatch_included
	#endinput
#endif
#define _jarvis_checkmatch_included

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

/**
 * @brief Check if the game mode is loaded.
 *
 */
public void ORUI_CheckMatch()
{
	if (!IsGameCompetitive(g_TypeMatch) || !L4D_IsFirstMapInScenario())
		return;

	CreateTimer(40.0, Timer_ReadCFG);
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Read the cfg name and download the game mode.
 *
 * @param hTimer	Timer handle
 * @return 			Stop the timer.
 */
public Action Timer_ReadCFG(Handle hTimer)
{
	char
		sCfgConvar[128],
		sCfgName[128],
		sCurrentMap[32];
	ConVar
		l4d_ready_cfg_name;

	g_cvarConfigCfg.GetString(sCfgConvar, sizeof(sCfgConvar));
	l4d_ready_cfg_name = FindConVar("l4d_ready_cfg_name");

	if (l4d_ready_cfg_name == null)
	{
		fkn_log("ConVar l4d_ready_cfg_name not found");
		return Plugin_Stop;
	}

	l4d_ready_cfg_name.GetString(sCfgName, sizeof(sCfgName));

	if (FindString(sCfgName, sCfgConvar, false))
	{
		if (g_cvarDebug.BoolValue)
		{
			CPrintToChatAll("%t %t", "Tag", "ConfigConfirm", sCfgName, sCfgConvar);
			fkn_log("The current cfg (%s) corresponds to %s", sCfgName, sCfgConvar);
		}
	}
	else
	{
		CPrintToChatAll("%t %t", "Tag", "ConfigChange", sCfgName, sCfgConvar);
		fkn_log("The current cfg (%s) does not correspond to %s", sCfgName, sCfgConvar);
		CreateTimer(5.0, Timer_ForceMatch);
	}

	if (!g_cvarChangeMap.BoolValue)
	{
		if (IsInReady())
		{
			KillTimerWaitPlayers();
			KillTimerWaitPlayersAnnouncer();
			KillTimerCheckPlayers();
			KillTimerWaitReadyup();
		}
		return Plugin_Stop;
	}

	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	if (StrEqual(g_sMapName, sCurrentMap, false))
	{
		if (g_cvarDebug.BoolValue)
		{
			CPrintToChatAll("%t %t", "Tag", "MapConfirm", g_sMapName, sCurrentMap);
			fkn_log("The current map (%s) corresponds to %s", g_sMapName, sCurrentMap);
		}
	}
	else
	{
		CPrintToChatAll("%t %t", "Tag", "MapChange", g_sMapName, sCurrentMap);
		fkn_log("The current map (%s) does not correspond to %s", g_sMapName, sCurrentMap);

		if (IsInReady())
		{
			KillTimerWaitPlayers();
			KillTimerWaitPlayersAnnouncer();
			KillTimerCheckPlayers();
			KillTimerWaitReadyup();
		}

		KillTimerManager();
		ServerCommand("changelevel %s", g_sMapName);
	}

	return Plugin_Stop;
}

/**
 * @brief Force the match to restart
 *
 * @param hTimer  Timer handle
 * @return        Stop the timer.
 */
public Action Timer_ForceMatch(Handle hTimer)
{
	ServerCommand("sm_resetmatch");
	return Plugin_Stop;
}