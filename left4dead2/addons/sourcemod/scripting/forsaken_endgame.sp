#define forsaken_stocks_left4dhooks_included 1
#include <forsaken>
#include <forsaken_endgame>
#include <colors>
#include <sourcemod>
#include <system2>
#include <json>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION "0.1"

ConVar
	g_cvarDebug,
	g_cvarEnable,
	g_cvarTimeKick;

bool
	g_bIsEndGame	   = false,
	g_bAnnounce		   = true,
	g_bNativeAvailable = true,
	g_bRound_End	   = true;

GlobalForward
	g_gfEndGame;

Database
	g_dbForsaken;

CancelMatch
	g_CancelMatch;

/*****************************************************************
			P L U G I N   I N F O
*****************************************************************/
public Plugin myinfo =
{
	name		= "Forsaken End Game",
	author		= "lechuga",
	description = "Manage the endgame",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/lechuga16/4saken_Matchmaking"


}

public APLRes
	AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
		return APLRes_Failure;
	}
	CreateNative("IsEndGame", Native_IsEndGame);
	CreateNative("ForceEndGame", Native_ForceEndGame);
	RegPluginLibrary("forsaken_endgame");
	g_gfEndGame = CreateGlobalForward("OnEndGame", ET_Ignore);
	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public void OnPluginStart()
{
	LoadTranslation("forsaken_endgame.phrases");

	HookEvent("round_end", Event_RoundEnd);

	CreateConVar("sm_endgame_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug	   = CreateConVar("sm_endgame_debug", "0", "Debug messagess", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarEnable   = CreateConVar("sm_endgame_enable", "1", "Was the end of the game before the last map", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_cvarTimeKick = CreateConVar("sm_endgame_timekick", "10.0", "Set counter before kicking players", FCVAR_NOTIFY, true, 0.0, true, 10.0);

	RegAdminCmd("sm_endgame_checkmap", Cmd_CheckMap, ADMFLAG_ROOT);
	RegAdminCmd("sm_endgame_maplist", Cmd_Maplist, ADMFLAG_ROOT);
	RegAdminCmd("sm_endgame_cancel", Cmd_Cancel, ADMFLAG_ROOT);

	DatabaseConnect();
	AutoExecConfig(true, "forsaken_endgame");
}

public void OnMapStart()
{
	if (!g_cvarEnable.BoolValue || !LGO_IsMatchModeLoaded())
		return;

	if (!g_bRound_End)
		g_bRound_End = !g_bRound_End;
}

public void OnRoundLiveCountdown()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (g_bAnnounce && CurrentMapEndGame())
	{
		g_bAnnounce = false;
		CPrintToChatAll("%t %t", "Tag", "Lastmap");
	}

	if (InSecondHalfOfRound())
		return;

	if (CurrentMapEndGame())
		g_bIsEndGame = true;
}

public void OnRoundIsLive()
{
	if (!g_bRound_End)
		g_bRound_End = !g_bRound_End;

	g_bAnnounce = true;
}

public Action Cmd_CheckMap(int iClient, int iArgs)
{
	if (CurrentMapEndGame())
		CReplyToCommand(iClient, "%t %t", "Tag", "Lastmap");
	else
		CReplyToCommand(iClient, "%t %t", "Tag", "NotLastMap");
	return Plugin_Continue;
}

public Action Cmd_Maplist(int iClient, int iArgs)
{
	JSON_Array jaMaps = Forsaken_Maps();

	int
		iLength = jaMaps.Length;
	char
		sTmpBuffer[32],
		sPrintBuffer[512];

	Format(sTmpBuffer, sizeof(sTmpBuffer), "%t :\n", "Tag");
	StrCat(sPrintBuffer, sizeof(sPrintBuffer), sTmpBuffer);

	for (int index = 0; index < iLength; index++)
	{
		char sListMap[32];
		jaMaps.GetString(index, sListMap, sizeof(sListMap));

		Format(sTmpBuffer, sizeof(sTmpBuffer), "%s ", sListMap);
		StrCat(sPrintBuffer, sizeof(sPrintBuffer), sTmpBuffer);
		if (index == 3 || index == 7)
		{
			Format(sTmpBuffer, sizeof(sTmpBuffer), "\n", sListMap);
			StrCat(sPrintBuffer, sizeof(sPrintBuffer), sTmpBuffer);
		}
	}

	CReplyToCommand(iClient, "%t %s", "Tag", sPrintBuffer);
	json_cleanup_and_delete(jaMaps);
	return Plugin_Continue;
}

public Action Cmd_Cancel(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_endgame_cancel");
		return Plugin_Continue;
	}

	ForceEndGame(unknown);
	return Plugin_Continue;
}

/*****************************************************************
			N A T I V E S
*****************************************************************/

/**
 * @brief Called when the round_end event starts.
 * 		The event depends on the list of maps 4sakenMaps.json.
 * 		The event was executed after the second round.
 */
public int Native_IsEndGame(Handle plugin, int numParams)
{
	return g_bIsEndGame;
}

/**
 * @brief Force the game over on the current map.
 *
 * @return bool     True if the game over was forced, False if not.
 * @error           If the game over is not enabled on the current map.
 */
any Native_ForceEndGame(Handle plugin, int numParams)
{
	g_CancelMatch = view_as<CancelMatch>(GetNativeCell(1));

	if (!g_bNativeAvailable)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Endgame has already been forced");
		Forsaken_log("The attempt to force the game to close was rejected due to the timeout, Reason: %s", sCancelMatch[g_CancelMatch]);
		CreateTimer(10.0, Timer_NativeAvailable);
		return 0;
	}
	if(!IsInReady() && InSecondHalfOfRound())
		ChapterPoints();

	StartEndGame();
	return 0;
}

/**
 * @brief Timer that restores the availability of the native Force Endgame
 *
 * @param timer     Timer handle
 * @return          Stop the timer
 */
public Action Timer_NativeAvailable(Handle timer)
{
	g_bNativeAvailable = true;
	g_CancelMatch	   = unknown;
	return Plugin_Stop;
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/
public void Event_RoundEnd(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if(!g_cvarEnable.BoolValue || !LGO_IsMatchModeLoaded() || !g_bRound_End)
		return;
	g_bRound_End = !g_bRound_End;

	if (g_cvarDebug.BoolValue)
		CPrintToChatAll("%t EndGame: {olive}%s{default}", "Tag", g_bIsEndGame ? "True" : "False");

	if (InSecondHalfOfRound())
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t ChapterPoints", "Tag");
		ChapterPoints();

		if (g_bIsEndGame)
			StartEndGame(true);
	}
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * Connect to the database.
 *
 * @noreturn
 */
public void DatabaseConnect()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (!SQL_CheckConfig("4saken"))
		Forsaken_log("The 4saken configuration is not found in databases.cfg");

	char error[255];
	g_dbForsaken = SQL_Connect("4saken", true, error, sizeof(error));

	if (g_dbForsaken == null)
		Forsaken_log("Could not connect to database: %s", error);
}

/**
 * @brief Force game over by loading current player and server information.
 * 		After that, the server is restarted.
 *
 *  @return bool    True if the game over was forced, False if not.
 *
 */
bool StartEndGame(bool iscallback = false)
{
	Call_StartForward(g_gfEndGame);
	if (Call_Finish() != 0)
		Forsaken_log("ForceEndGame: error in forward Call_Finish");

	char sQuery[256];
	Format(sQuery, sizeof(sQuery), "UPDATE `l4d2_queue_game` SET `status`= 0 WHERE `ip` = '%s:%d' ORDER BY `queueid` DESC LIMIT 1;", Forsaken_GetIP(), FindConVar("hostport").IntValue);

	if (!SQL_FastQuery(g_dbForsaken, sQuery))
	{
		char error[255];
		SQL_GetError(g_dbForsaken, error, sizeof(error));

		Forsaken_log("Failed to query (error: %s)", error);
		CPrintToChatAll("%t %t", "Tag", "FailEndedReserved");

		if (iscallback)
			CreateTimer(g_cvarTimeKick.FloatValue, KickAll);

		return false;
	}
	else
	{
		CPrintToChatAll("%t %t", "Tag", "Ended");
		CreateTimer(g_cvarTimeKick.FloatValue, KickAll);
		return true;
	}
}

/**
 * @brief Check if the current map is in the map list Maps.json
 *
 * @return bool     True if the current map is in the map list, False if not.
 */
public bool CurrentMapEndGame()
{
	JSON_Array jaMaps  = Forsaken_Maps();

	int		   iLength = jaMaps.Length;
	for (int index = 0; index < iLength; index += 1)
	{
		char sListMap[32];
		jaMaps.GetString(index, sListMap, sizeof(sListMap));

		char sMapName[32];
		GetCurrentMap(sMapName, sizeof(sMapName));
		if (strcmp(sMapName, sListMap) == 0)
		{
			return true;
		}
	}
	json_cleanup_and_delete(jaMaps);
	return false;
}

public void ChapterPoints()
{
	TypeMatch Match = Forsaken_TypeMatch();

	if (Match == unranked || Match == invalid)
		return;

	int
		iSurvivorTeamIndex,
		iInfectedTeamIndex,
		iPointsTeamA,
		iPointsTeamB,
		iQueueID = 1;

	char
		sMapName[32],
		sQuery[256];

	GetCurrentMap(sMapName, sizeof(sMapName));
	iSurvivorTeamIndex = L4D2_AreTeamsFlipped();
	iInfectedTeamIndex = !L4D2_AreTeamsFlipped();

	iPointsTeamA	   = L4D2Direct_GetVSCampaignScore(iSurvivorTeamIndex);
	iPointsTeamB	   = L4D2Direct_GetVSCampaignScore(iInfectedTeamIndex);

	Format(sQuery, sizeof(sQuery), "INSERT INTO `l4d2_queue_result` \
	(QueueID, MapCode, TeamsFlipped, PointsTeamA, PointsTeamB, GameCanceled) VALUES \
	('%d', '%s', '%d', '%d', '%d', '%s');",
		   iQueueID, sMapName, iInfectedTeamIndex, iPointsTeamA, iPointsTeamB, sCancelMatch[g_CancelMatch]);

	if (!SQL_FastQuery(g_dbForsaken, sQuery))
	{
		char error[255];
		SQL_GetError(g_dbForsaken, error, sizeof(error));

		Forsaken_log("Failed to query (error: %s)", error);
		CPrintToChatAll("%t %t", "Tag", "FailEndedPoints");
	}
}

/**
 * @brief Start the timer that kicks players and restarts the server.
 *
 * @return			Stop the timer.
 */
public Action KickAll(Handle timer)
{
	ServerCommand("sm_kick @all %t", "KickAll");
	ServerCommand("_restart");
	return Plugin_Stop;
}