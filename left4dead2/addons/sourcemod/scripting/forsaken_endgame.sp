#pragma semicolon 1
#pragma newdecls required

#define forsaken_left4dhooks_included 1
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

ConVar g_cvarTimeKick;

bool
	g_bIsEndGame	   = false,
	g_bAnnounce		   = true,
	g_bNativeAvailable = true,
	g_bRound_End	   = true;

GlobalForward
	g_gfEndGame;

Database
	g_dbForsaken;

int
	g_iTeamScore[ForsakenTeam],	   // Team score
	g_iScore_Round1;			   // Team score

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
	g_cvarEnable   = CreateConVar("sm_endgame_enable", "1", "Was the end of the game before the last map", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarTimeKick = CreateConVar("sm_endgame_timekick", "10.0", "Set counter before kicking players", FCVAR_NOTIFY, true, 0.0, true, 10.0);

	RegConsoleCmd("sm_endgame_score", Cmd_Score, "Print chapter score");
	RegAdminCmd("sm_endgame_checkmap", Cmd_CheckMap, ADMFLAG_GENERIC);
	RegAdminCmd("sm_endgame_cancel", Cmd_Cancel, ADMFLAG_GENERIC);

	DatabaseConnect();
	AutoExecConfig(true, "forsaken_endgame");
}

public void OnMapStart()
{
	g_iScore_Round1		= 0;
	g_iTeamScore[TeamA] = 0;
	g_iTeamScore[TeamB] = 0;
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
	if (!g_cvarEnable.BoolValue)
		return;

	g_bAnnounce = true;

	if (!g_bRound_End)
		g_bRound_End = !g_bRound_End;
}

public Action Cmd_CheckMap(int iClient, int iArgs)
{
	if (CurrentMapEndGame())
		CReplyToCommand(iClient, "%t %t", "Tag", "Lastmap");
	else
		CReplyToCommand(iClient, "%t %t", "Tag", "NotLastMap");
	return Plugin_Continue;
}

public Action Cmd_Cancel(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "[4saken] Usage: sm_endgame_cancel");
		return Plugin_Continue;
	}

	if (iClient == CONSOLE)
	{
		CReplyToCommand(iClient, "This command cannot be used from the console.");
		return Plugin_Continue;
	}

	int QueueID = fkn_QueueID();
	CReplyToCommand(iClient, "%t %t", "Tag", "CancelMatch", QueueID, iClient);
	fkn_log(false, "The match (ID:%d) was canceled due to %N.", QueueID, iClient);
	ChapterPoints(admin);
	StartEndGame();

	return Plugin_Continue;
}

public Action Cmd_Score(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "[4saken] Usage: sm_endgame_score");
		return Plugin_Handled;
	}

	if (!InSecondHalfOfRound())
		CReplyToCommand(iClient, "{lightgreen}Ronda 1{default}: {green}%d{default}", L4D_GetTeamScore(LogicTeamsFlipped()));
	else
		CReplyToCommand(iClient, "{lightgreen}Ronda 1{default}: {green}%d{default} | {lightgreen}Ronda 2{default}: {green}%d{default}", g_iScore_Round1, L4D_GetTeamScore(LogicTeamsFlipped()));

	CReplyToCommand(iClient, "{lightgreen}TeamA{default}: {green}%d{default} |{lightgreen}TeamB{default}: {green}%d{default}", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
	return Plugin_Handled;
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
	MatchClosing hMatchClosing = view_as<MatchClosing>(GetNativeCell(1));

	if (!g_bNativeAvailable)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Endgame has already been forced");
		fkn_log(false, "The attempt to force the game to close was rejected due to the timeout, Reason: %s", sMatchClosing[hMatchClosing]);
		CreateTimer(10.0, Timer_NativeAvailable);
		return 0;
	}

	ChapterPoints(hMatchClosing);
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
	return Plugin_Stop;
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/
public void Event_RoundEnd(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if (!g_cvarEnable.BoolValue || !LGO_IsMatchModeLoaded() || !g_bRound_End)
		return;

	g_bRound_End = !g_bRound_End;

	ScoreTeams();
	ScoreLogicTeams();

	if (!InSecondHalfOfRound())
		return;

	ChapterPoints(endgame);

	if (!g_bIsEndGame)
		return;

	StartEndGame();
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
		fkn_log(false, "The 4saken configuration is not found in databases.cfg");

	char error[255];
	g_dbForsaken = SQL_Connect("4saken", true, error, sizeof(error));

	if (g_dbForsaken == null)
		fkn_log(false, "Could not connect to database: %s", error);
}

/**
 * @brief Clears the reservation from the database, kicks the players, and restarts the server.
 *
 * @noreturn
 */
bool StartEndGame()
{
	Call_StartForward(g_gfEndGame);
	if (Call_Finish() != 0)
		fkn_log(false, "ForceEndGame: error in forward Call_Finish");

	char sQuery[256];
	Format(sQuery, sizeof(sQuery),
		   "UPDATE `l4d2_queue_game` \
			SET `status` = 0 \
			WHERE `ip` = '%s:%d' \
			ORDER BY `queueid` \
			DESC LIMIT 1;",
		   fkn_GetIP(), FindConVar("hostport").IntValue);

	if (!SQL_FastQuery(g_dbForsaken, sQuery))
	{
		char error[255];
		SQL_GetError(g_dbForsaken, error, sizeof(error));

		fkn_log(false, "Failed to query (error: %s)", error);
		fkn_log(false, "Query: %s", sQuery);
		CPrintToChatAll("%t %t", "Tag", "FailEndedReserved");

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
	return (L4D_GetCurrentChapter() == 4) ? true : false;
}

/**
 * @brief Upload game points to database
 *
 * @param hMatchClosing  Reason for the end of the game
 * @noreturn
 * @error               If the query failed.
 */
public void ChapterPoints(MatchClosing hMatchClosing)
{
	char
		sMapName[32],
		sQuery[256];

	GetCurrentMap(sMapName, sizeof(sMapName));

	Format(sQuery, sizeof(sQuery),
		   "INSERT INTO `queue_result` \
			(QueueID, MapCode, PointsTeamA, PointsTeamB, GameCanceled) \
			VALUES('%d', '%s', '%d', '%d', '%s');",
		   fkn_QueueID(), sMapName, g_iTeamScore[TeamA], g_iTeamScore[TeamB], sMatchClosing[hMatchClosing]);

	if (!SQL_FastQuery(g_dbForsaken, sQuery))
	{
		char error[255];
		SQL_GetError(g_dbForsaken, error, sizeof(error));

		fkn_log(false, "Failed to query (error: %s)", error);
		fkn_log(false, "Query: %s", sQuery);
		CPrintToChatAll("%t %t", "Tag", "FailEndedPoints");
	}

	if (g_cvarDebug.BoolValue)
		fkn_log(false, "Query:%s", sQuery);
}

/**
 * @brief Start the timer that kicks players and restarts the server.
 *
 * @return			Stop the timer.
 */
public Action KickAll(Handle timer)
{
	ServerCommand("sm_kick @all %t", "KickAll");
	return Plugin_Stop;
}

/**
 * @brief Save the score of the current round.
 *
 * @noreturn
 */
public void ScoreLogicTeams()
{
	if (!InSecondHalfOfRound())	   // Firs Half of Round
	{
		if (!AreTeamsFlipped())	   // Teams are not flipped
			g_iTeamScore[TeamA] = L4D_GetTeamScore(1);
		else
			g_iTeamScore[TeamB] = L4D_GetTeamScore(2);
	}
	else	// Second Half of Round
	{
		if (AreTeamsFlipped())	  // Teams are flipped
			g_iTeamScore[TeamB] = L4D_GetTeamScore(2);
		else
			g_iTeamScore[TeamA] = L4D_GetTeamScore(1);
	}

	CPrintToChatAll("%t %t", "Tag", "Round", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
}

public void ScoreTeams()
{
	if (!InSecondHalfOfRound())
		g_iScore_Round1 = L4D_GetTeamScore(LogicTeamsFlipped());
}