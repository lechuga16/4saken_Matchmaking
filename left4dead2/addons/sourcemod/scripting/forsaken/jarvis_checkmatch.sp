#if defined _jarvis_checkmatch_included
	#endinput
#endif
#define _jarvis_checkmatch_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
	g_cvarCheckMap,
	g_cvarCheckCFG;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_CheckMatch()
{
	g_cvarCheckMap	= CreateConVar("sm_jarvis_checkmap", "1", "check if the map is the one defined in the lobby", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarCheckCFG = CreateConVar("sm_jarvis_checkcfg", "1", "check if the CFG is the one defined in the lobby", FCVAR_NONE, true, 0.0, true, 1.0);
}

/**
 * @brief Check if the game mode is loaded.
 *
 */
public void ORUI_CheckMatch()
{
	if (!IsGameCompetitive(g_TypeMatch) || !L4D_IsFirstMapInScenario())
		return;

	CreateTimer(40.0, Timer_CheckMatch);
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
public Action Timer_CheckMatch(Handle hTimer)
{
	CheckMap();
	CheckCFG();
	return Plugin_Stop;
}

public void CheckMap()
{
	if(!g_cvarCheckMap.BoolValue)
		return;

	fkn_MapName(g_sMapName, sizeof(g_sMapName));
	char sCurrentMap[32];

	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	if (StrEqual(g_sMapName, sCurrentMap, false))
		fkn_log(true, "The current map (%s) corresponds to %s", g_sMapName, sCurrentMap);
	else
	{
		CPrintToChatAll("%t %t", "Tag", "MapChange", g_sMapName, sCurrentMap);
		fkn_log(false, "The current map (%s) does not correspond to %s", g_sMapName, sCurrentMap);

		if(g_cvarCheckCFG.BoolValue)
			ServerCommand("confogl_match_map %s", g_sMapName);
		else
			ServerCommand("changelevel %s", g_sMapName);
	}
}

public void CheckCFG()
{
	if(!g_cvarCheckCFG.BoolValue)
		return;
		
	char sCfgName[128];
	ConVar l4d_ready_cfg_name;

	if ((l4d_ready_cfg_name = FindConVar("l4d_ready_cfg_name")) == null)
	{
		fkn_log(false, "ConVar l4d_ready_cfg_name not found");
		return;
	}

	l4d_ready_cfg_name.GetString(sCfgName, sizeof(sCfgName));
	if (FindString(sCfgName, sCFGName[g_TypeMatch], false))
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t %t", "Tag", "ConfigConfirm", sCfgName, sCFGName[g_TypeMatch]);
	}
	else
	{
		CPrintToChatAll("%t %t", "Tag", "ConfigChange", sCfgName, sCFGName[g_TypeMatch]);
		CreateTimer(5.0, Timer_ForceMatch);
	}
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