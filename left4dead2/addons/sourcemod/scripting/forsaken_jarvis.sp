
#define forsaken_left4dhooks_included 1
#include <colors>
#include <forsaken>
#include <forsaken_endgame>
#include <json>
#include <left4dhooks>
#include <sourcemod>
#include <system2>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION	"0.1"
#define MAX_PLAYER_TEAM 5	 // nota: recordatorio de poner este valor en  4 cuando este en produccion
#define JVPrefix		"[J.A.R.V.I.S]"

int 
	iServerID = 0;
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

/** 
 * 	Contains values to tell if a player is in the game or has raged.
 */
enum struct PlayerRageQuit
{
	char steamid[MAX_AUTHID_LENGTH];	// Player SteamID
	bool ispresent;						// Is the player in the game?
	Handle timer;						// Timer to check if the player has ragequitting.
}

State
	ConfigState;

SMCParser
	ConfigParser;

TypeMatch
	g_TypeMatch;

PlayerBasic g_Players[ForsakenTeam][MAX_PLAYER_TEAM];

PlayerRageQuit
	g_RageQuitTA[MAX_PLAYER_TEAM],
	g_RageQuitTB[MAX_PLAYER_TEAM];
	
ConVar
	g_cvarDebug,
	g_cvarEnable,
	g_cvarTimeWait,
	g_cvarTimeWaitAnnouncer,
	g_cvarTimerRageQuit,
	g_cvarBanRageQuit,
	g_cvarBanDesertion,
	g_cvarConfigCfg,
	g_cvarPlayersToStart,

	survivor_limit,
	z_max_player_zombies;

char
	g_sMapName[32];

bool
	g_bPreMatch	 = true;

Handle
	g_hTimerOT,
	g_hTimerWait,
	g_hTimerWaitAnnouncer,
	g_hTimerCheckList;

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
	g_cvarBanRageQuit		= CreateConVar("sm_jarvis_banragequit", "7200", "The time to ban the player for (in minutes, 0 = permanent) for ragequit", FCVAR_NONE, true, 0.0);
	g_cvarBanDesertion		= CreateConVar("sm_jarvis_bandesertion", "4320", "The time to ban the player for (in minutes, 0 = permanent) for not arrive on time", FCVAR_NONE, true, 0.0);
	g_cvarConfigCfg			= CreateConVar("sm_jarvis_configcfg", "zonemod", "The config file to load", FCVAR_NONE);
	g_cvarPlayersToStart	= CreateConVar("sm_jarvis_playerstostart", "2", "The minimum players to start the match", FCVAR_NONE, true, 2.0);

	RegConsoleCmd("sm_jarvis_listplayers", Cmd_ListPlayers, "Print the forsaken player list");
	RegConsoleCmd("sm_jarvis_info", Cmd_MatchInfo, "Displays the cfg and map that will be used..");

	RegAdminCmd("sm_jarvis_deleteOT", Cmd_DeleteOT, ADMFLAG_GENERIC, "Kills the timer for organizing teams.");
	RegAdminCmd("sm_jarvis_adduser", Cmd_AddUser, ADMFLAG_ROOT, "Add user to forsaken player list");
	RegAdminCmd("sm_jarvis_pointsteam", Cmd_PointsTeam, ADMFLAG_ROOT, "Print the points of each team");
	RegAdminCmd("sm_jarvis_missingplayers", Cmd_MissingPlayers, ADMFLAG_ROOT, "Print the missing players");
	RegAdminCmd("sm_jarvis_offlineban", Cmd_OffLineBan, ADMFLAG_ROOT, "Ban offline players");

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
	ReadConfigSourcebans();
	CheckCFG();

	if (LGO_IsMatchModeLoaded())
		g_bPreMatch = false;
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
	if (!g_cvarEnable.BoolValue)
		return;

	if (g_TypeMatch == unranked || g_TypeMatch == invalid)
		return;

	if (IsFakeClient(iClient))
		return;

	StartMatch();

	if (IsRageQuiters(iClient, sAuth))
	{
		RemoveRageQuiters(iClient, sAuth);
		fkn_log("ClientConnected: %N is ragequiter", iClient);
	}
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
		CReplyToCommand(iClient, "Usage: sm_jarvis_adduser <#1:survi|#2:infect>");
		return Plugin_Handled;
	}

	ForsakenTeam team = view_as<ForsakenTeam>(GetCmdArgInt(1));

	char
		sSteamID[32],
		sName[128];

	if (!GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID)))
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoSteamID");
		return Plugin_Handled;
	}

	if (!GetClientName(iClient, sName, sizeof(sName)))
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoName");
		return Plugin_Handled;
	}

	switch (team)
	{
		case TeamA:
		{
			CReplyToCommand(iClient, "%t %t", "Tag", "AddSurv");
			g_Players[TeamA][4].steamid = sSteamID;
			g_Players[TeamA][4].name	= sName;
		}
		case TeamB:
		{
			CReplyToCommand(iClient, "%t %t", "Tag", "AddInfect");
			g_Players[TeamB][4].steamid = sSteamID;
			g_Players[TeamB][4].name	= sName;
		}
		default:
		{
			CReplyToCommand(iClient, "Usage: sm_jarvis_adduser <#1:survi|#2:infect>");
			return Plugin_Handled;
		}
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

	CReplyToCommand(iClient, "%t %t", "Tag", "TypeLobby", sTypeMatch[g_TypeMatch]);

	char
		tmpBuffer[32],
		printBuffer[512];

	Format(tmpBuffer, sizeof(tmpBuffer), "%t TeamA: ", "Tag");
	StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	for (int i = 0; i <= 4; i++)
	{
		Format(tmpBuffer, sizeof(tmpBuffer), "%s ", g_Players[TeamA][i].steamid);
		StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	}

	CReplyToCommand(iClient, "%s", printBuffer);
	printBuffer[0] = '\0';

	Format(tmpBuffer, sizeof(tmpBuffer), "%t TeamB: ", "Tag");
	StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
	for (int i = 0; i <= 4; i++)
	{
		Format(tmpBuffer, sizeof(tmpBuffer), "%s ", g_Players[TeamB][i].steamid);
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

	char		 sBuffer[128];
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

	return Plugin_Handled;
}

public Action Cmd_MatchInfo(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_matchinfo");
		return Plugin_Handled;
	}

	char sCfgConvar[128];
	g_cvarConfigCfg.GetString(sCfgConvar, sizeof(sCfgConvar));
	CReplyToCommand(iClient, "%t %t", "Tag", "MatchInfo", sCfgConvar, g_sMapName);
	
	return Plugin_Handled;
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/** 
 * @brief Check if the game mode is loaded.
 * 
 */
public void CheckCFG()
{
	if (LGO_IsMatchModeLoaded() && !g_bPreMatch)
		CreateTimer(40.0, Timer_ReadCFG);
}

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
		sCfgName[128];
	ConVar 
		l4d_ready_cfg_name;

	g_cvarConfigCfg.GetString(sCfgConvar, sizeof(sCfgConvar));
	l4d_ready_cfg_name = FindConVar("l4d_ready_cfg_name");

	if(l4d_ready_cfg_name == null)
	{
		fkn_log("ConVar l4d_ready_cfg_name not found");
		return Plugin_Stop;
	}

	l4d_ready_cfg_name.GetString(sCfgName, sizeof(sCfgName));

	if (FindString(sCfgName, sCfgConvar, false))
	{
		if(g_cvarDebug.BoolValue)
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