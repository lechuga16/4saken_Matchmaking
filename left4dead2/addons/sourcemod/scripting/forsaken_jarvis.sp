
#define forsaken_stocks_left4dhooks_included 1
#include <colors>
#include <forsaken>
#include <forsaken_endgame>
#include <json>
#include <left4dhooks>
#include <sourcemod>
#include <system2>
#include <sourcebanspp>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION	"0.1"
#define MAX_PLAYER_TEAM 5	 // nota: recordatorio de poner este valor en  4 cuando este en produccion
#define JVPrefix		"[J.A.R.V.I.S]"

int iServerID = 0;
char
	DatabasePrefix[10] = "sb",
	WebsiteAddress[128];

enum State
{
	ConfigStateNone = 0,
	ConfigStateConfig,
	ConfigStateReasons,
	ConfigStateHacking,
	ConfigStateTime
}

State	  ConfigState;
SMCParser ConfigParser;

TypeMatch
	g_Lobby;
ConVar
	g_cvarDebug,
	g_cvarEnable,
	g_cvarTimeWait,
	g_cvarTimeWaitAnnouncer,
	g_cvarTimerRageQuit,
	g_cvarBanRageQuit,
	g_cvarBanDesertion,
	g_cvarConfigCfg;
ConVar
	survivor_limit,
	z_max_player_zombies;
char
	g_sSteamIDTA[MAX_PLAYER_TEAM][MAX_AUTHID_LENGTH],
	g_sSteamIDTB[MAX_PLAYER_TEAM][MAX_AUTHID_LENGTH],
	g_sNameTA[MAX_PLAYER_TEAM][MAX_NAME_LENGTH],
	g_sNameTB[MAX_PLAYER_TEAM][MAX_NAME_LENGTH];
bool
	g_bCheckSteamIDTA[MAX_PLAYER_TEAM] = { false, false, false, false, false },
	g_bCheckSteamIDTB[MAX_PLAYER_TEAM] = { false, false, false, false, false },
	g_bisPreMatch = true;
Handle
	g_hTimerOT,
	g_hTimerWait,
	g_hTimerWaitAnnouncer,
	g_hTimerCheckList,
	g_hTimerRageQuitTA[MAX_PLAYER_TEAM] = { null, null, null, null, null },
	g_hTimerRageQuitTB[MAX_PLAYER_TEAM] = { null, null, null, null, null };
Database
	g_DBSourceBans;
int
	g_iPointsTeamA = 0,
	g_iPointsTeamB = 0;

/*****************************************************************
			L I B R A R Y   I N C L U D E S
*****************************************************************/

#include "forsaken/jarvis_prematch.sp"
#include "forsaken/jarvis_teams.sp"
#include "forsaken/jarvis_waiting.sp"
#include "forsaken/jarvis_ban.sp"
#include "forsaken/jarvis_ragequit.sp"

/*****************************************************************
			P L U G I N   I N F O
*****************************************************************/

public Plugin myinfo =
{
	name		= "Forsaken J.A.R.V.I.S",
	author		= "lechuga",
	description = "Manage the players and the game",
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

	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart()
{
	LoadTranslation("forsaken_jarvis.phrases");

	CreateConVar("sm_jarvis_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug				= CreateConVar("sm_jarvis_debug", "0", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarEnable			= CreateConVar("sm_jarvis_enable", "1", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarTimeWait			= CreateConVar("sm_jarvis_timewait", "180.0", "The time to wait for the players to join the server", FCVAR_NONE, true, 0.0);
	g_cvarTimeWaitAnnouncer = CreateConVar("sm_jarvis_timewaitannouncer", "30.0", "The time to announcer the players to join the server", FCVAR_NONE, true, 0.0);
	g_cvarTimerRageQuit		= CreateConVar("sm_jarvis_timeragequit", "180.0", "The time to check if the player ragequit", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuit		= CreateConVar("sm_jarvis_banragequit", "7200", "The time to ban the player for (in minutes, 0 = permanent) for ragequit", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarBanDesertion		= CreateConVar("sm_jarvis_bandesertion", "4320", "The time to ban the player for (in minutes, 0 = permanent) for not arrive on time", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarConfigCfg			= CreateConVar("sm_jarvis_configcfg", "zonemod", "The config file to load", FCVAR_NONE);

	RegConsoleCmd("sm_jarvis_checkteams", Cmd_CheckTeams, "Check the client's ForsakenTeam and switch teams.");
	RegConsoleCmd("sm_jarvis_deleteOT", Cmd_DeleteOT, "Kills the timer for organizing teams.");
	RegConsoleCmd("sm_jarvis_adduser", Cmd_AddUser, "Add user to forsaken player list");
	RegConsoleCmd("sm_jarvis_pointsteam", Cmd_PointsTeam, "Print the points of each team");
	RegConsoleCmd("sm_jarvis_listplayers", Cmd_ListPlayers, "Print the forsaken player list");
	RegConsoleCmd("sm_jarvis_missingplayers", Cmd_MissingPlayers, "Print the missing players");
	RegConsoleCmd("sm_jarvis_offlineban", Cmd_OffLineBan, "Ban offline players");
	RegConsoleCmd("sm_jarvis_cancelmatch", Cmd_CancelMatch, "Cancel the match and execute the end of the game");

	survivor_limit		 = FindConVar("survivor_limit");
	z_max_player_zombies = FindConVar("z_max_player_zombies");

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	Database.Connect(GotDatabase, "sourcebans");
	AutoExecConfig(true, "forsaken_jarvis");
}

public void OnMapStart()
{
	if (!g_cvarEnable.BoolValue)
		return;

	PreMatch();
	WaitingPlayers();
	OrganizeTeams();
	ReadConfig();

	if (LGO_IsMatchModeLoaded())
		g_bisPreMatch = false;
}

public void OnMapEnd()
{
	if (!g_cvarEnable.BoolValue)
		return;

	KillTimerOT();
}

public void OnRoundIsLive()
{
	KillTimerWaitPlayers();
	KillTimerWaitPlayersAnnouncer();
	KillTimerCheckPlayers();
}

public void OnClientAuthorized(int iClient, const char[] sAuth) 
{
	if (!g_cvarEnable.BoolValue || LGO_IsMatchModeLoaded())
		return;

	if (g_Lobby == unranked || g_Lobby == invalid)
		return;

	if(!IsClientInGame(iClient) || IsFakeClient(iClient))
		return;
	    
	if (strcmp(sAuth, "BOT") == 0)
		return;

	if(IsRageQuiters(iClient, sAuth))
	{
		RemoveRageQuiters(iClient, sAuth);
		if(g_cvarDebug.BoolValue)
			Forsaken_log("OnClientConnected: %N is ragequiter", iClient);
	}

	StartMatch();
}

public Action Cmd_CheckTeams(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		CReplyToCommand(iClient, "%t", "NoConsoleCMD");
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

public Action Cmd_PointsTeam(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_pointsteam");
		return Plugin_Handled;
	}

	if (iClient == 0)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoConsoleCMD");
		return Plugin_Handled;
	}

	int SurvivorTeamIndex = L4D2_AreTeamsFlipped();
	int InfectedTeamIndex = !L4D2_AreTeamsFlipped();

	g_iPointsTeamA		  = L4D2Direct_GetVSCampaignScore(SurvivorTeamIndex);
	g_iPointsTeamB		  = L4D2Direct_GetVSCampaignScore(InfectedTeamIndex);

	CReplyToCommand(iClient, "%t L4D2_AreTeamsFlipped: %s", "Tag", L4D2_AreTeamsFlipped() ? "True" : "False");
	CReplyToCommand(iClient, "%t Points TeamA: %d | TeamB: %d", "Tag", g_iPointsTeamA, g_iPointsTeamB);

	return Plugin_Continue;
}

public Action Cmd_DeleteOT(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_deleteOT");
		return Plugin_Handled;
	}

	KillTimerOT();
	CReplyToCommand(iClient, "%t %t", "Tag", "DeleteOT");
	return Plugin_Continue;
}

public Action Cmd_AddUser(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoConsoleCMD");
		return Plugin_Handled;
	}

	if (iArgs == 0 || iArgs >= 2)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_adduser <#team> (1:survi|2:infect)");
		return Plugin_Handled;
	}

	int	 iArg = GetCmdArgInt(1);

	char sSteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));

	if (iArg == 1)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "AddSurv");
		g_sSteamIDTA[4] = sSteamID;
	}
	else if (iArg == 2)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "AddInfect");
		g_sSteamIDTB[4] = sSteamID;
	}
	return Plugin_Continue;
}

public Action Cmd_ListPlayers(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_listplayers");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%t %t", "Tag", "TypeLobby", sTypeMatch[g_Lobby]);

	char
		tmpBuffer[32],
		printBuffer[512];

	Format(tmpBuffer, sizeof(tmpBuffer), "%t TeamA: ", "Tag");
	StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	for (int i = 0; i <= 4; i++)
	{
		Format(tmpBuffer, sizeof(tmpBuffer), "%s ", g_sSteamIDTA[i]);
		StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	}

	CReplyToCommand(iClient, "%s", printBuffer);
	printBuffer[0] = '\0';

	Format(tmpBuffer, sizeof(tmpBuffer), "%t TeamB: ", "Tag");
	StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	for (int i = 0; i <= 4; i++)
	{
		Format(tmpBuffer, sizeof(tmpBuffer), "%s ", g_sSteamIDTB[i]);
		StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	}
	CReplyToCommand(iClient, "%s", printBuffer);
	printBuffer[0] = '\0';

	return Plugin_Handled;
}

public Action Cmd_MissingPlayers(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_missingplayers");
		return Plugin_Handled;
	}

	MissingPlayers();
	return Plugin_Handled;
}

public Action Cmd_OffLineBan(int iClient, int iArgs)
{
	if (iArgs != 2)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_offlineban <#teamID> <#playerID>");
		return Plugin_Handled;
	}

	if (GetCmdArgInt(1) != 1 && GetCmdArgInt(1) != 2)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "InvalidTeam");
		return Plugin_Handled;
	}

	if (GetCmdArgInt(2) < 0 || GetCmdArgInt(2) > 4)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "PlayerInvalid");
		return Plugin_Handled;
	}

	ForsakenTeam Team	 = view_as<ForsakenTeam>(GetCmdArgInt(1));
	int			 iPlayer = GetCmdArgInt(2);

	char sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "%t %t", "Tag", "DesertionTest");

	if (Team == TeamA)
	{
		CreateOffLineBan(iPlayer, TeamA, 1, sBuffer);
	}
	else if (Team == TeamB)
	{
		CreateOffLineBan(iPlayer, TeamB, 1, sBuffer);
	}
	else
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "InvalidTeam");
	}

	return Plugin_Continue;
}

public Action Cmd_CancelMatch(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_cancelmatch");
		return Plugin_Handled;
	}

	ForceEndGame();
	return Plugin_Handled;
}