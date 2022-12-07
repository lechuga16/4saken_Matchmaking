
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
	g_hTransitionTimer;
int
	g_iPointsTeamA = 0,
	g_iPointsTeamB = 0;
bool
	g_bHasTransitioned = false,
	g_bDirectionTeam   = true;

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

	RegConsoleCmd("sm_jarvis_isplayer", isplayer);
	RegConsoleCmd("sm_jarvis_deleteOT", deleteOT);
	RegConsoleCmd("sm_jarvis_adduser", adduser);
	RegConsoleCmd("sm_jarvis_direction", direction);
	RegConsoleCmd("sm_jarvis_listplayers", ListPlayers);
	survivor_limit       = FindConVar("survivor_limit");
	z_max_player_zombies = FindConVar("z_max_player_zombies");

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd);
	PreMatch();
	WaitingPlayers();
	if (g_cvarEnable.BoolValue && LGO_IsMatchModeLoaded())
		g_hTimerOT = CreateTimer(2.0, OrganizeTeams, _, TIMER_REPEAT);

	AutoExecConfig(true, "forsaken_jarvis");
}

/*****************************************************************
            L I B R A R Y   I N C L U D E S
*****************************************************************/
#include "forsaken/jarvis_prematch.sp"
#include "forsaken/jarvis_teams.sp"
#include "forsaken/jarvis_waiting.sp"

public Action isplayer(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_isplayer");
		return Plugin_Handled;
	}

	CheckTeam(iClient);
	return Plugin_Continue;
}

public Action direction(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_direction");
		return Plugin_Handled;
	}

	TeamManagement(false);
	CReplyToCommand(iClient, "Direcion: %s", TeamManagement(false) ? "normal" : "invertido");
	return Plugin_Continue;
}

public Action deleteOT(int iClient, int iArgs)
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

public Action adduser(int iClient, int iArgs)
{
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

	for (int i = 0; i <= 4; i++)
	{
		int iPlayer = 1 + i;
		CReplyToCommand(iClient, "[J.A.R.V.I.S] Team1 Player %d: %s", iPlayer, g_sSteamIDTA[i]);
	}

	for (int i = 0; i <= 4; i++)
	{
		int iPlayer = 1 + i;
		CReplyToCommand(iClient, "[J.A.R.V.I.S] Team2 Player %d: %s", iPlayer, g_sSteamIDTB[i]);
	}

	return Plugin_Handled;
}