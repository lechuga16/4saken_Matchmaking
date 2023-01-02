#pragma semicolon 1
#pragma newdecls required

#define forsaken_left4dhooks_included
#define CUSTOM_PLAYERINFO
#include <forsaken>
#include <colors>
#include <sourcemod>
#include <system2>
#include <left4dhooks>
#include <glicko>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION "1.0"

/**
 * Player profile.
 *
 */
enum struct PlayerInfo
{
	char  steamid[MAX_AUTHID_LENGTH];	 // Player SteamID
	char  name[MAX_NAME_LENGTH];		 // Player name
	float rating;						 // Glicko Score
	float deviation;					 // Glicko deviation
	int	  gamesplayed;					 // Number of games played
	int	  lastgame;						 // Last Score Update
	int	  gameswon;						 // Number of games won
}

/**
 * Team profile.
 *
 */
enum struct TeamsInfo
{
	int	  id;						// Team ID
	char  name[MAX_NAME_LENGTH];	// Team name
	float rating;					// Glicko Score
	float deviation;				// Glicko deviation
	int	  gamesplayed;				// Number of games played
	int	  lastgame;					// Last Score Update
	int	  gameswon;					// Number of games won
}

ConVar
	g_cvarDebug,
	g_cvarEnable;

Database	g_dbForsaken;
TypeMatch	g_TypeMatch;

PlayerInfo	g_Players[ForsakenTeam][MAX_PLAYER_TEAM];	 // Information to calculate mmr of a team
TeamsInfo	g_TeamInfo[ForsakenTeam];					 // Information to calculate mmr of a team
GlickoBasic g_CPlayer[ForsakenTeam];					 // Composite of the members of a team

char
	g_sMapName[32],
	g_sIp[64];

bool
	g_bRound_End = true,	// True if endgame event triggered (used to avoid multiple triggers, l4d2 stuff).
	g_bPreMatch	 = true;	// True if map still not restarted after confogl load.

/*****************************************************************
			L I B R A R Y   I N C L U D E S
*****************************************************************/

#include "forsaken/mmr_prematch.sp"
#include "forsaken/mmr_glicko.sp"
#include "forsaken/mmr_pug.sp"
#include "forsaken/mmr_scrims.sp"

/*****************************************************************
			P L U G I N   I N F O
*****************************************************************/
public Plugin myinfo =
{
	name		= "Forsaken MMR",
	author		= "lechuga",
	description = "Manages a glicko based rating system for pugs and scrims games.",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/lechuga16/4saken_Matchmaking"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
		strcopy(error, err_max, "Plugin only support L4D2 engine");

	g_sIp = fkn_GetIP();
	if (StrEqual(g_sIp, "0.0.0.0", false))
	{
		strcopy(error, err_max, "ERROR: The server ip was not configured");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public void OnPluginStart()
{
	// LoadTranslation("forsaken_mmr.phrases");
	CreateConVar("sm_mmr_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug	 = CreateConVar("sm_mmr_debug", "0", "Debug messages.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarEnable = CreateConVar("sm_mmr_enable", "1", "Activate mmr registration", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_mmr", CMD_MMR);
	RegConsoleCmd("sm_score", CMD_Score);
	RegConsoleCmd("sm_win", CMD_Win);

	HookEvent("round_end", Event_RoundEnd);
	SQLConnect();
	AutoExecConfig(true, "forsaken_mmr");
}

public void OnMapStart()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (!g_bRound_End)
		g_bRound_End = !g_bRound_End;

	PreMatch();
	if (!g_bPreMatch)
	{
		PugMatch();
		ScrimMatch();
	}

	if (LGO_IsMatchModeLoaded())
		g_bPreMatch = false;
}

public void OnRoundIsLive()
{
	if (!g_cvarEnable.BoolValue)
		return;
	// roundislive
}

public void OnEndGame()
{
	if (!g_cvarEnable.BoolValue)
		return;

	// endagame
}

public Action CMD_MMR(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CPrintToChat(iClient, "Usage: sm_mmr <steamid>");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "TeamA :\n");

	for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
	{
		CReplyToCommand(iClient, "Name: %s SteamID: %s\nRating: %.0f Deviation: %.0f\n Games: %d Lastgame: %d days",
						g_Players[TeamA][i].name, g_Players[TeamA][i].steamid, g_Players[TeamA][i].rating, g_Players[TeamA][i].deviation, g_Players[TeamA][i].gamesplayed, DaysLastGame(g_Players[TeamA][i]));
	}

	CReplyToCommand(iClient, "----------------------------------------\nTeamB :\n");
	for (int i = 0; i <= 3; i++)
	{
		CReplyToCommand(iClient, "Name: %s SteamID: %s\nRating: %.0f Deviation: %.0f\n Games: %d LastGame: %d days",
						g_Players[TeamB][i].name, g_Players[TeamB][i].steamid, g_Players[TeamB][i].rating, g_Players[TeamB][i].deviation, g_Players[TeamB][i].gamesplayed, DaysLastGame(g_Players[TeamB][i]));
	}

	CReplyToCommand(iClient, "----------------------------------------\nCompositePlayer :\n");
	CReplyToCommand(iClient, "[TeamA] Rating: %.0f Deviation: %.0f", g_CPlayer[TeamA].rating, g_CPlayer[TeamA].deviation);
	CReplyToCommand(iClient, "[TeamB] Rating: %.0f Deviation: %.0f", g_CPlayer[TeamB].rating, g_CPlayer[TeamB].deviation);

	return Plugin_Handled;
}

public Action CMD_Score(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CPrintToChat(iClient, "Usage: sm_score");
		return Plugin_Handled;
	}

	ReplyToCommand(iClient, "ScoreTA: %d", L4D_GetTeamScore(view_as<int>(TeamA)));
	ReplyToCommand(iClient, "ScoreTB: %d", L4D_GetTeamScore(view_as<int>(TeamB)));
	return Plugin_Handled;
}

public Action CMD_Win(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CPrintToChat(iClient, "Usage: sm_win");
		return Plugin_Handled;
	}

	ProcessMMR(TeamA, Result_Win);

	CReplyToCommand(iClient, "TeamA :\n");

	for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
	{
		CReplyToCommand(iClient, "Name: %s SteamID: %s\nRating: %.0f Deviation: %.0f\n Games: %d Lastgame: %d days",
						g_Players[TeamA][i].name, g_Players[TeamA][i].steamid, g_Players[TeamA][i].rating, g_Players[TeamA][i].deviation, g_Players[TeamA][i].gamesplayed, DaysLastGame(g_Players[TeamA][i]));
	}

	CReplyToCommand(iClient, "----------------------------------------\nTeamB :\n");
	for (int i = 0; i <= 3; i++)
	{
		CReplyToCommand(iClient, "Name: %s SteamID: %s\nRating: %.0f Deviation: %.0f\n Games: %d LastGame: %d days",
						g_Players[TeamB][i].name, g_Players[TeamB][i].steamid, g_Players[TeamB][i].rating, g_Players[TeamB][i].deviation, g_Players[TeamB][i].gamesplayed, DaysLastGame(g_Players[TeamB][i]));
	}

	return Plugin_Handled;
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/
public void Event_RoundEnd(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if (!g_cvarEnable.BoolValue || g_bPreMatch || !g_bRound_End || !InSecondHalfOfRound())
		return;

	g_bRound_End = !g_bRound_End;

	if (g_TypeMatch == scrims)
	{
		RoundEnd_Teams();
		return;
	}

	if (g_TypeMatch == scout || g_TypeMatch == adept || g_TypeMatch == veteran)
	{
		RoundEnd_Pugs();
		return;
	}
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/
public void SQLConnect()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (!SQL_CheckConfig("4saken"))
		fkn_log("The 4saken configuration is not found in databases.cfg");
	else
		Database.Connect(SQL4saken, "4saken");
}

public void SQL4saken(Database db, const char[] error, any data)
{
	if (db == null)
		ThrowError("Error while connecting to database: %s", error);
	else
		g_dbForsaken = db;
}

stock int DaysLastGame(PlayerInfo Player)
{
	if (Player.lastgame == 0)
		return 0;
	return FromUnixTime(GetTime() - Player.lastgame, Day);
}