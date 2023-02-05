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

int g_iTeamScore[ForsakenTeam];	   // Team score
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
#include "forsaken/mmr_duel.sp"
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

	RegConsoleCmd("sm_mmr", CMD_MMR, "show ranking of a player");
	RegConsoleCmd("sm_mmr_team", CMD_Team, "show team ranking");
	RegAdminCmd("sm_mmr_stats", CMD_Stats, ADMFLAG_GENERIC, "show detailed ranking of a player");
	RegAdminCmd("sm_mmr_allplayers", CMD_All, ADMFLAG_GENERIC, "show ranking of all players");
	RegAdminCmd("sm_mmr_win", CMD_Win, ADMFLAG_ROOT);

	HookEvent("round_end", Event_RoundEnd);
	AutoExecConfig(true, "forsaken_mmr");
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if (!g_cvarEnable.BoolValue || !IsGameCompetitive(g_TypeMatch) || IsFakeClient(iClient))
		return;

	char sAuth64[MAX_AUTHID_LENGTH];
	GetClientAuthId(iClient, AuthId_SteamID64, sAuth64, MAX_AUTHID_LENGTH);
	ONCA_IndexPlayers(iClient, sAuth64);
}

public void OnCacheDownload()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (g_bPreMatch)
		return;

	OCD_Prematch();
}

public void OnMapStart()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (!g_bPreMatch)
		OMS_skill();

	if (LGO_IsMatchModeLoaded())
		g_bPreMatch = false;
}

public void OnRoundIsLive()
{
	if (!g_bRound_End)
		g_bRound_End = !g_bRound_End;

	if (!InSecondHalfOfRound() && L4D_IsFirstMapInScenario() && g_TypeMatch == scrims)
		CPrintToChatAll("%t %t", "Tag", "ScrimStarted", g_TeamsInfo[TeamA][0].name, g_TeamsInfo[TeamB][0].name);
}

Action CMD_MMR(int iClient, int iArgs)
{
	if (iArgs > 1)
	{
		CReplyToCommand(iClient, "[4saken] Usage: sm_mmr <#userid|name>");
		return Plugin_Handled;
	}

	if (g_TypeMatch == scrims)
	{
		FakeClientCommand(iClient, "sm_mmr_team");
		return Plugin_Handled;
	}

	char sCmdArg[16];
	GetCmdArg(1, sCmdArg, sizeof(sCmdArg));

	int[] iTargetList = new int[MaxClients + 1];
	int	 iTargetCount;
	char sTargetName[MAX_TARGET_LENGTH];
	bool tn_is_ml;

	if ((iTargetCount = ProcessTargetString(sCmdArg, iClient, iTargetList, MaxClients + 1, COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), tn_is_ml)) > 0)
	{
		for (int i = 0; i < iTargetCount; i++)
		{
			for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
			{
				if (g_Players[TeamA][iID].client == iTargetList[i])
				{
					if (g_Players[TeamA][iID].gamesplayed > EVALUATION_PERIOD)
						CReplyToCommand(iClient, "%t %t", "Tag", "MMR", g_Players[TeamA][iID].rating, g_Players[TeamA][iID].deviation);
					else
						CReplyToCommand(iClient, "%t %t", "Tag", "NoMMR", g_Players[TeamA][iID].gamesplayed, EVALUATION_PERIOD);
					return Plugin_Handled;
				}

				if (g_Players[TeamB][iID].client == iTargetList[i])
				{
					if (g_Players[TeamB][iID].gamesplayed > EVALUATION_PERIOD)
						CReplyToCommand(iClient, "%t %t", "Tag", "MMR", g_Players[TeamB][iID].rating, g_Players[TeamB][iID].deviation);
					else
						CReplyToCommand(iClient, "%t %t", "Tag", "NoMMR", g_Players[TeamB][iID].gamesplayed, EVALUATION_PERIOD);
					return Plugin_Handled;
				}

				if (iID == 0 && g_TypeMatch == duel)
					break;
			}
		}
	}
	else
	{
		if (iClient == CONSOLE)
			return Plugin_Handled;

		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (g_Players[TeamA][iID].client == iClient)
			{
				if (g_Players[TeamA][iID].gamesplayed > EVALUATION_PERIOD)
					CReplyToCommand(iClient, "%t %t", "Tag", "MMR", g_Players[TeamA][iID].rating, g_Players[TeamA][iID].deviation);
				else
					CReplyToCommand(iClient, "%t %t", "Tag", "NoMMR", g_Players[TeamA][iID].gamesplayed, EVALUATION_PERIOD);
				return Plugin_Handled;
			}

			if (g_Players[TeamB][iID].client == iClient)
			{
				if (g_Players[TeamB][iID].gamesplayed > EVALUATION_PERIOD)
					CReplyToCommand(iClient, "%t %t", "Tag", "MMR", g_Players[TeamB][iID].rating, g_Players[TeamB][iID].deviation);
				else
					CReplyToCommand(iClient, "%t %t", "Tag", "NoMMR", g_Players[TeamB][iID].gamesplayed, EVALUATION_PERIOD);
				return Plugin_Handled;
			}

			if (iID == 0 && g_TypeMatch == duel)
				break;
		}
	}

	return Plugin_Handled;
}

Action CMD_Stats(int iClient, int iArgs)
{
	if (iArgs > 1)
	{
		CReplyToCommand(iClient, "[4saken] Usage: sm_mmr <#userid|name>");
		return Plugin_Handled;
	}

	char sCmdArg[16];
	GetCmdArg(1, sCmdArg, sizeof(sCmdArg));

	int[] iTargetList = new int[MaxClients + 1];
	int	 iTargetCount;
	char sTargetName[MAX_TARGET_LENGTH];
	bool tn_is_ml;

	if ((iTargetCount = ProcessTargetString(sCmdArg, iClient, iTargetList, MaxClients + 1, COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), tn_is_ml)) > 0)
	{
		for (int i = 0; i < iTargetCount; i++)
		{
			for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
			{
				if (g_Players[TeamA][iID].client == iTargetList[i])
				{
					CReplyToCommand(iClient, "%t %t", "Tag", "Stats", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid, g_Players[TeamA][iID].rating, g_Players[TeamA][iID].deviation, g_Players[TeamA][iID].skill, g_Players[TeamA][iID].wins);
					return Plugin_Handled;
				}

				if (g_Players[TeamB][iID].client == iTargetList[i])
				{
					CReplyToCommand(iClient, "%t %t", "Tag", "Stats", g_Players[TeamB][iID].name, g_Players[TeamB][iID].steamid, g_Players[TeamB][iID].rating, g_Players[TeamB][iID].deviation, g_Players[TeamB][iID].skill, g_Players[TeamB][iID].wins);
					return Plugin_Handled;
				}

				if (iID == 0 && g_TypeMatch == duel)
					break;
			}
		}
	}
	else
	{
		if (iClient == CONSOLE)
			return Plugin_Handled;

		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (g_Players[TeamA][iID].client == iClient)
			{
				CReplyToCommand(iClient, "%t %t", "Tag", "Stats", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid, g_Players[TeamA][iID].rating, g_Players[TeamA][iID].deviation, g_Players[TeamA][iID].skill, g_Players[TeamA][iID].wins);
				return Plugin_Handled;
			}

			if (g_Players[TeamA][iID].client == iClient)
			{
				CReplyToCommand(iClient, "%t %t", "Tag", "Stats", g_Players[TeamA][iID].name, g_Players[TeamA][iID].steamid, g_Players[TeamB][iID].rating, g_Players[TeamB][iID].deviation, g_Players[TeamB][iID].skill, g_Players[TeamB][iID].wins);
				return Plugin_Handled;
			}

			if (iID == 0 && g_TypeMatch == duel)
				break;
		}
	}

	return Plugin_Handled;
}

Action CMD_All(int iClient, int iArgs)
{
	CReplyToCommand(iClient, "%t TeamA %s:%.0f|%s:%.0f|%s:%.0f|%s:%.0f ", "Tag",
					g_Players[TeamA][0].name, g_Players[TeamA][0].rating,
					g_Players[TeamA][1].name, g_Players[TeamA][1].rating,
					g_Players[TeamA][2].name, g_Players[TeamA][2].rating,
					g_Players[TeamA][3].name, g_Players[TeamA][3].rating);

	CReplyToCommand(iClient, "%t TeamB %s:%.0f|%s:%.0f|%s:%.0f|%s:%.0f ", "Tag",
					g_Players[TeamB][0].name, g_Players[TeamB][0].rating,
					g_Players[TeamB][1].name, g_Players[TeamB][1].rating,
					g_Players[TeamB][2].name, g_Players[TeamB][2].rating,
					g_Players[TeamB][3].name, g_Players[TeamB][3].rating);

	return Plugin_Handled;
}

Action CMD_Team(int iClient, int iArgs)
{
	if (L4D_GetClientTeam(iClient) == L4DTeam_Spectator)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoPlayer");
		return Plugin_Handled;
	}

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (g_Players[TeamA][iID].client == iClient)
		{
			CReplyToCommand(iClient, "%t %t", "Tag", "TeamInfo",
							g_TeamsInfo[TeamA][iID].name,
							g_TeamsInfo[TeamA][iID].rating,
							g_TeamsInfo[TeamA][iID].deviation,
							g_TeamsInfo[TeamA][iID].wins);
		}
		else if (g_Players[TeamB][iID].client == iClient)
		{
			CReplyToCommand(iClient, "%t %t", "Tag", "TeamInfo",
							g_TeamsInfo[TeamB][iID].name,
							g_TeamsInfo[TeamB][iID].rating,
							g_TeamsInfo[TeamB][iID].deviation,
							g_TeamsInfo[TeamB][iID].wins);
		}
	}
	return Plugin_Handled;
}

Action CMD_Win(int iClient, int iArgs)
{
	if (iArgs > 1)
	{
		CReplyToCommand(iClient, "[4saken] Usage: sm_mmr_win <1:TeamA Win | 2:TeamB Win | 3:Draw>");
		return Plugin_Handled;
	}

	int iCmdArg1 = GetCmdArgInt(1);

	if (iCmdArg1 == 1)
	{
		ProcessRatingDuel(TeamA, Result_Win);
		ProcessRatingDuel(TeamB, Result_Loss);
	}
	else if (iCmdArg1 == 2)
	{
		ProcessRatingDuel(TeamA, Result_Loss);
		ProcessRatingDuel(TeamB, Result_Win);
	}
	else if (iCmdArg1 == 3)
	{
		ProcessRatingDuel(TeamA, Result_Draw);
		ProcessRatingDuel(TeamB, Result_Draw);
	}

	return Plugin_Handled;
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/
public void Event_RoundEnd(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if (!g_cvarEnable.BoolValue || g_bPreMatch || !g_bRound_End)
		return;

	g_bRound_End = !g_bRound_End;

	LogicTeamScore();

	RoundEnd_Pugs();
	RoundEnd_Scrims();
	RoundEnd_Duel();
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

stock int DaysLastGame(PlayerInfo Player)
{
	if (Player.lastgame == 0)
		return 0;
	return FromUnixTime(GetTime() - Player.lastgame, Day);
}

void LogicTeamScore()
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
}

public ForsakenTeam GetOpponent(ForsakenTeam team)
{
	return (team == TeamA) ? TeamB : TeamA;
}

public void IndexClientAuthorized(int iClient)
{
	char sStemaID[32];
	if (!GetClientAuthId(iClient, AuthId_SteamID64, sStemaID, sizeof(sStemaID)))
		return;

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(g_Players[TeamA][iID].steamid, sStemaID))
		{
			g_Players[TeamA][iID].client = iClient;
			continue;
		}
		if (StrEqual(g_Players[TeamB][iID].steamid, sStemaID))
		{
			g_Players[TeamB][iID].client = iClient;
			continue;
		}
	}
}

Database Connect()
{
	char	 error[PLATFORM_MAX_PATH];
	Database db;

	if (SQL_CheckConfig("4saken"))
		db = SQL_Connect("4saken", true, error, sizeof(error));

	if (db == null)
		fkn_log(false, "Could not connect to database: %s", error);

	return db;
}

public void ONCA_IndexPlayers(int iClient, const char[] sAuth64)
{
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sAuth64, g_Players[TeamA][iID].steamid, false))
			g_Players[TeamA][iID].client = iClient;
		else if (StrEqual(sAuth64, g_Players[TeamB][iID].steamid, false))
			g_Players[TeamB][iID].client = iClient;

		if (iID == 0 && g_TypeMatch == duel)
			break;
	}
}