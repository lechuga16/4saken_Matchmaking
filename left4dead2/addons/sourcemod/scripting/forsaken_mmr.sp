#pragma semicolon 1
#pragma newdecls required

#define forsaken_left4dhooks_included
#define CUSTOM_PLAYERINFO
#include <colors>
#include <sourcemod>
#include <system2>
#include <left4dhooks>
#include <forsaken>
#include <forsaken_endgame>
#include <glicko>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>
#define REQUIRE_PLUGIN

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION "1.0"

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
	int	  wins;						// Number of games won
}

ConVar
	g_cvarDebug,
	g_cvarEnable;

Database   g_dbForsaken;
TypeMatch  g_TypeMatch;

PlayerInfo g_Players[ForsakenTeam][MAX_PLAYER_TEAM];	// Information to calculate mmr of a team
TeamsInfo  g_TeamInfo[ForsakenTeam];					// Information to calculate mmr of a team
int		   g_iTeamScore[ForsakenTeam];					// Team score
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
#include "forsaken/mmr_pug.sp"
#include "forsaken/mmr_scrims.sp"
#include "forsaken/mmr_skill.sp"

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
	LoadTranslation("forsaken_mmr.phrases");
	CreateConVar("sm_mmr_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug	 = CreateConVar("sm_mmr_debug", "0", "Debug messages.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarEnable = CreateConVar("sm_mmr_enable", "1", "Activate mmr registration", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_mmr", CMD_MMR, "Show player mmr");
	RegAdminCmd("sm_mmr_stats", CMD_Stats, ADMFLAG_GENERIC, "Show player stats");

	HookEvent("round_end", Event_RoundEnd);
	SQLConnect();
	AutoExecConfig(true, "forsaken_mmr");
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (!IsHuman(iClient))
		return;

	IndexPug(iClient);
}

public void OnMapStart()
{
	if (!g_cvarEnable.BoolValue)
		return;

	PreMatch();
	if (!g_bPreMatch)
	{
		ScrimMatch();
		CleanSkills();
	}

	if (LGO_IsMatchModeLoaded())
		g_bPreMatch = false;
}

public Action CMD_MMR(int iClient, int iArgs)
{
	char TargetString[128];
	GetCmdArg(1, TargetString, sizeof(TargetString));

	int Clients[MAXPLAYERS];
	int ValidClients = GetApplicableClients(iClient, TargetString, COMMAND_FILTER_NO_BOTS, Clients, MAXPLAYERS);

	if (!ValidClients)
	{
		char sSteamID[MAX_AUTHID_LENGTH];
		GetClientAuthId(iClient, AuthId_SteamID64, sSteamID, MAX_AUTHID_LENGTH);

		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (StrEqual(g_Players[TeamA][iID].steamid, sSteamID))
			{
				if(g_Players[TeamA][iID].gamesplayed > EVALUATION_PERIOD)
					CReplyToCommand(iClient, "%t %t", "Tag", "MMR", g_Players[TeamA][iID].rating, g_Players[TeamA][iID].deviation);
				else
					CReplyToCommand(iClient, "%t %t", "Tag", "NoMMR", g_Players[TeamA][iID].gamesplayed, EVALUATION_PERIOD);
				return Plugin_Handled;
			}

			if (StrEqual(g_Players[TeamB][iID].steamid, sSteamID))
			{
				if(g_Players[TeamB][iID].gamesplayed > EVALUATION_PERIOD)
					CReplyToCommand(iClient, "%t %t", "Tag", "MMR", g_Players[TeamB][iID].rating, g_Players[TeamB][iID].deviation);
				else
					CReplyToCommand(iClient, "%t %t", "Tag", "NoMMR", g_Players[TeamB][iID].gamesplayed, EVALUATION_PERIOD);
				return Plugin_Handled;
			}
		}
		return Plugin_Handled;
	}

	for (int i = 0; i < ValidClients; i++)
	{
		char sSteamID[MAX_AUTHID_LENGTH];
		GetClientAuthId(Clients[i], AuthId_SteamID64, sSteamID, MAX_AUTHID_LENGTH);

		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (StrEqual(g_Players[TeamA][iID].steamid, sSteamID))
			{
				if(g_Players[TeamA][iID].gamesplayed > EVALUATION_PERIOD)
					CReplyToCommand(iClient, "%t %t", "Tag", "MMR", g_Players[TeamA][iID].rating, g_Players[TeamA][iID].deviation);
				else
					CReplyToCommand(iClient, "%t %t", "Tag", "NoMMR", g_Players[TeamA][iID].gamesplayed, EVALUATION_PERIOD);
				return Plugin_Handled;
			}

			if (StrEqual(g_Players[TeamB][iID].steamid, sSteamID))
			{
				if(g_Players[TeamB][iID].gamesplayed > EVALUATION_PERIOD)
					CReplyToCommand(iClient, "%t %t", "Tag", "MMR", g_Players[TeamB][iID].rating, g_Players[TeamB][iID].deviation);
				else
					CReplyToCommand(iClient, "%t %t", "Tag", "NoMMR", g_Players[TeamB][iID].gamesplayed, EVALUATION_PERIOD);
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Handled;
}

public Action CMD_Stats(int iClient, int iArgs)
{
	char TargetString[128];
	GetCmdArg(1, TargetString, sizeof(TargetString));

	int Clients[MAXPLAYERS];
	int ValidClients = GetApplicableClients(iClient, TargetString, COMMAND_FILTER_NO_BOTS, Clients, MAXPLAYERS);

	if (!ValidClients)
	{
		if (CONSOLE != iClient)
			return Plugin_Handled;

		char sSteamID[MAX_AUTHID_LENGTH];
		GetClientAuthId(iClient, AuthId_SteamID64, sSteamID, MAX_AUTHID_LENGTH);

		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (StrEqual(g_Players[TeamA][iID].steamid, sSteamID))
			{
				CReplyToCommand(iClient, "%t %t", "Tag", "Stats", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid, g_Players[TeamA][iID].rating, g_Players[TeamA][iID].deviation, g_Players[TeamA][iID].skill, g_Players[TeamA][iID].wins);
				return Plugin_Handled;
			}

			if (StrEqual(g_Players[TeamB][iID].steamid, sSteamID))
			{
				CReplyToCommand(iClient, "%t %t", "Tag", "Stats", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid, g_Players[TeamB][iID].rating, g_Players[TeamB][iID].deviation, g_Players[TeamB][iID].skill, g_Players[TeamB][iID].wins);
				return Plugin_Handled;
			}
		}
		return Plugin_Handled;
	}

	for (int i = 0; i < ValidClients; i++)
	{
		char sSteamID[MAX_AUTHID_LENGTH];
		GetClientAuthId(Clients[i], AuthId_SteamID64, sSteamID, MAX_AUTHID_LENGTH);

		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (StrEqual(g_Players[TeamA][iID].steamid, sSteamID))
			{
				CReplyToCommand(iClient, "%t %t", "Tag", "Stats", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid, g_Players[TeamA][iID].rating, g_Players[TeamA][iID].deviation, g_Players[TeamA][iID].skill, g_Players[TeamA][iID].wins);
				return Plugin_Handled;
			}

			if (StrEqual(g_Players[TeamB][iID].steamid, sSteamID))
			{
				CReplyToCommand(iClient, "%t %t", "Tag", "Stats", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid, g_Players[TeamB][iID].rating, g_Players[TeamB][iID].deviation, g_Players[TeamB][iID].skill, g_Players[TeamB][iID].wins);
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Handled;
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/
public void OnRoundLiveCountdown()
{
	if (!g_bRound_End)
		g_bRound_End = !g_bRound_End;

	ClienIndexList();
}

public void Event_RoundEnd(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if (!g_cvarEnable.BoolValue || g_bPreMatch || !g_bRound_End)
		return;

	g_bRound_End = !g_bRound_End;

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

	// CPrintToChatAll("%t %t", "Tag", "Round", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
	ProcessBonus(TeamA);
	ProcessBonus(TeamB);

	if (!InSecondHalfOfRound())
		return;

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

public void CleanSkills()
{
	if (!L4D_IsFirstMapInScenario())
		return;

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		g_Players[TeamA][iID].skill = 0.0;
		g_Players[TeamB][iID].skill = 0.0;
	}
}