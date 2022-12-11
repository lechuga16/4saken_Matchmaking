
#define _4saken_stocks_left4dhooks_included 1
#include <colors>
#include <forsaken>
#include <json>
#include <left4dhooks>
#include <sourcemod>
#include <system2>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>
#define PLUGIN_VERSION  "0.1"
#define MAX_PLAYER_TEAM 5    // nota: recordatorio de poner este valor en  4 cuando este en produccion
#define STEAMID_LENGTH  32

TypeMatch
	g_Lobby;

ConVar
	g_cvarDebug,
	g_cvarEnable,
	survivor_limit,
	z_max_player_zombies;
char
	g_sSteamIDTA[MAX_PLAYER_TEAM][STEAMID_LENGTH],
	g_sSteamIDTB[MAX_PLAYER_TEAM][STEAMID_LENGTH];
Handle
	g_hTimerOT,
	g_hTimerWait;
int
	g_iPointsTeamA = 0,
	g_iPointsTeamB = 0;

public Plugin myinfo =
{
	name        = "Forsaken End Game",
	author      = "lechuga",
	description = "Handle the endgame",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lechuga16/4saken_Matchmaking"
}

public APLRes
	AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("forsaken.phrases");
	// LoadTranslation("4saken_endgame.phrases");

	CreateConVar("sm_jarvis_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug  = CreateConVar("sm_jarvis_debug", "0", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarEnable = CreateConVar("sm_jarvis_enable", "1", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_jarvis_checkteams", CheckTeams);
	RegConsoleCmd("sm_jarvis_deleteOT", DeleteOT);
	RegConsoleCmd("sm_jarvis_adduser", AddUser);
	RegConsoleCmd("sm_jarvis_pointsteam", PointsTeam);
	RegConsoleCmd("sm_jarvis_listplayers", ListPlayers);

	survivor_limit       = FindConVar("survivor_limit");
	z_max_player_zombies = FindConVar("z_max_player_zombies");

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	PreMatch();
	WaitingPlayers();
	Teams();
	AutoExecConfig(true, "forsaken_jarvis");
}

/*****************************************************************
            L I B R A R Y   I N C L U D E S
*****************************************************************/
#include "forsaken/jarvis_prematch.sp"
#include "forsaken/jarvis_teams.sp"
#include "forsaken/jarvis_waiting.sp"

public Action CheckTeams(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		CReplyToCommand(iClient, "No se puede usar desde consola");
		return Plugin_Handled;
	}

	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_checkteams");
		return Plugin_Handled;
	}

	CheckTeam(iClient);
	return Plugin_Continue;
}

public Action PointsTeam(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_pointsteam");
		return Plugin_Handled;
	}

	int SurvivorTeamIndex = L4D2_AreTeamsFlipped();
	int InfectedTeamIndex = !L4D2_AreTeamsFlipped();

	g_iPointsTeamA = L4D2Direct_GetVSCampaignScore(SurvivorTeamIndex);
	g_iPointsTeamB = L4D2Direct_GetVSCampaignScore(InfectedTeamIndex);

	CReplyToCommand(iClient, "L4D2_AreTeamsFlipped: %s", L4D2_AreTeamsFlipped() ? "True" : "False");
	CReplyToCommand(iClient, "Points TeamA: %d | TeamB: %d", g_iPointsTeamA, g_iPointsTeamB);

	return Plugin_Continue;
}

public Action DeleteOT(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_deleteOT");
		return Plugin_Handled;
	}

	KillTimer(g_hTimerOT);
	CReplyToCommand(iClient, "[J.A.R.V.I.S] Cronometro OrganizeTeams eliminado");
	return Plugin_Continue;
}

public Action AddUser(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		CReplyToCommand(iClient, "No se puede usar desde consola");
		return Plugin_Handled;
	}

	if (iArgs == 0 || iArgs >= 2)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_adduser <#team> (1:survi|2:infect)");
		return Plugin_Handled;
	}

	int iArg = GetCmdArgInt(1);

	char sSteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));

	if (iArg == 1)
	{
		CReplyToCommand(iClient, "[J.A.R.V.I.S] Se agrego como survivor");
		g_sSteamIDTA[4] = sSteamID;
	}
	else if (iArg == 2)
	{
		CReplyToCommand(iClient, "[J.A.R.V.I.S] Se agrego como infected");
		g_sSteamIDTB[4] = sSteamID;
	}
	return Plugin_Continue;
}

public Action ListPlayers(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_listplayers");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "Lobby: %s", sTypeMatch[g_Lobby]);

	char
		tmpBuffer[32],
		printBuffer[512];
	printBuffer[0] = '\0';

	Format(tmpBuffer, sizeof(tmpBuffer), "[J.A.R.V.I.S] TeamA: ");
	StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	for (int i = 0; i <= 4; i++)
	{
		Format(tmpBuffer, sizeof(tmpBuffer), "%s ", g_sSteamIDTA[i]);
		StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	}

	Format(tmpBuffer, sizeof(tmpBuffer), "\n[J.A.R.V.I.S] TeamB: ");
	StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	for (int i = 0; i <= 4; i++)
	{
		Format(tmpBuffer, sizeof(tmpBuffer), "%s ", g_sSteamIDTB[i]);
		StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	}
	CReplyToCommand(iClient, "%s", printBuffer);

	return Plugin_Handled;
}