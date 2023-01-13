
#define forsaken_left4dhooks_included 1
#include <colors>
#include <forsaken>
#include <forsaken_endgame>
#include <json>
#include <left4dhooks>
#include <sourcemod>
#include <system2>
#include <builtinvotes>
#include <sourcebanspp>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>
#define REQUIRE_PLUGIN

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION "0.1"
#define JVPrefix	   "[J.A.R.V.I.S]"

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
	char   steamid[MAX_AUTHID_LENGTH];	  // Player SteamID
	bool   ispresent;					  // Is the player in the game?
	Handle timer;						  // Timer to check if the player has ragequitting.
}

State		   ConfigState;
SMCParser	   ConfigParser;
TypeMatch	   g_TypeMatch;
PlayerInfo	   g_Players[ForsakenTeam][MAX_PLAYER_TEAM];
PlayerRageQuit g_RageQuit[ForsakenTeam][MAX_PLAYER_TEAM];

ConVar
	g_cvarDebug,
	g_cvarEnable,
	g_cvarConfigCfg,
	g_cvarPlayersToStart,
	g_cvarChangeMap,

	g_cvarTimerRageQuit,
	g_cvarBanRageQuit,
	g_cvarBanRageQuitx2,
	g_cvarBanRageQuitx3,

	g_cvarTimeWait,
	g_cvarTimeWaitAnnouncer,
	g_cvarBanDesertion,
	g_cvarBanDesertionx2,
	g_cvarBanDesertionx3,

	g_cvarReadyupWait,
	g_cvarBanReadyup,
	g_cvarBanReadyupx2,
	g_cvarBanReadyupx3,

	survivor_limit,
	z_max_player_zombies;

char g_sMapName[32];
bool
	g_bPreMatch			= true,
	g_bStartMatch		= true;

Database g_DBSourceBans = null;

Handle
	g_hTimerManager		  = null,
	g_hTimerWait		  = null,
	g_hTimerWaitAnnouncer = null,
	g_hTimerCheckList	  = null,
	g_hTimerWaitReadyup	  = null;

/*****************************************************************
			L I B R A R Y   I N C L U D E S
*****************************************************************/

#include "forsaken/jarvis_prematch.sp"
#include "forsaken/jarvis_teams.sp"
#include "forsaken/jarvis_waiting.sp"
#include "forsaken/jarvis_ban.sp"
#include "forsaken/jarvis_ragequit.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
		return APLRes_Failure;
	}

	CreateNative("ForsakenBan", Native_ForsakenBan);
	RegPluginLibrary("forsaken_jarvis");
	return APLRes_Success;
}

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

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public void
	OnPluginStart()
{
	LoadTranslation("forsaken_jarvis.phrases");

	CreateConVar("sm_jarvis_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug				= CreateConVar("sm_jarvis_debug", "0", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarEnable			= CreateConVar("sm_jarvis_enable", "1", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarConfigCfg			= CreateConVar("sm_jarvis_configcfg", "zonemod", "The config file to load", FCVAR_NONE);
	g_cvarPlayersToStart	= CreateConVar("sm_jarvis_playerstostart", "2", "The minimum players to start the match", FCVAR_NONE, true, 1.0);
	g_cvarChangeMap			= CreateConVar("sm_jarvis_changemap", "1", "Change the map when it is verified that it does not correspond to the match", FCVAR_NONE, true, 0.0, true, 1.0);

	g_cvarTimerRageQuit		= CreateConVar("sm_jarvis_timeragequit", "300.0", "The time to check if the player ragequit", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuit		= CreateConVar("sm_jarvis_banragequit", "2880", "The time to ban the player (in minutes, 0 = permanent) for ragequit", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuitx2		= CreateConVar("sm_jarvis_banragequitx2", "5760", "The time to ban the player (in minutes, 0 = permanent) for ragequit for the second time", FCVAR_NONE, true, 0.0);
	g_cvarBanRageQuitx3		= CreateConVar("sm_jarvis_banragequitx3", "10080", "The time to ban the player (in minutes, 0 = permanent) for ragequit for the third time", FCVAR_NONE, true, 0.0);

	g_cvarTimeWait			= CreateConVar("sm_jarvis_timewait", "300.0", "The time to wait for the players to join the server", FCVAR_NONE, true, 0.0);
	g_cvarTimeWaitAnnouncer = CreateConVar("sm_jarvis_timewaitannouncer", "30.0", "The time to announcer the players to join the server", FCVAR_NONE, true, 0.0);
	g_cvarBanDesertion		= CreateConVar("sm_jarvis_bandesertion", "720", "The time to ban the player (in minutes, 0 = permanent) for not arrive on time", FCVAR_NONE, true, 0.0);
	g_cvarBanDesertionx2	= CreateConVar("sm_jarvis_bandesertionx2", "2880", "The time to ban the player (in minutes, 0 = permanent) for not arrive on time for the second time", FCVAR_NONE, true, 0.0);
	g_cvarBanDesertionx3	= CreateConVar("sm_jarvis_bandesertionx3", "5760", "The time to ban the player (in minutes, 0 = permanent) for not arrive on time for the third time", FCVAR_NONE, true, 0.0);

	g_cvarReadyupWait		= CreateConVar("sm_jarvis_readyupwait", "360.0", "The time to wait for the players to ready up", FCVAR_NONE, true, 0.0);
	g_cvarBanReadyup		= CreateConVar("sm_jarvis_banreadyup", "120", "The time to ban the player (in minutes, 0 = permanent) for not ready up on time", FCVAR_NONE, true, 0.0);
	g_cvarBanReadyupx2		= CreateConVar("sm_jarvis_banreadyupx2", "240", "The time to ban the player (in minutes, 0 = permanent) for not ready up on time for the second time", FCVAR_NONE, true, 0.0);
	g_cvarBanReadyupx3		= CreateConVar("sm_jarvis_banreadyupx3", "480", "The time to ban the player (in minutes, 0 = permanent) for not ready up on time for the third time", FCVAR_NONE, true, 0.0);

	RegConsoleCmd("sm_jarvis_listplayers", Cmd_ListPlayers, "Print the forsaken player list");
	RegConsoleCmd("sm_jarvis_info", Cmd_MatchInfo, "Displays the cfg and map that will be used.");
	RegConsoleCmd("sm_jarvis_clientid", Cmd_ClientID, "Print the client id of the player");

	RegAdminCmd("sm_jarvis_killtimer", Cmd_KillTimer, ADMFLAG_GENERIC, "Kills the timer for organizing teams.");
	RegAdminCmd("sm_jarvis_missingplayers", Cmd_MissingPlayers, ADMFLAG_ROOT, "Print the missing players");

	AddCommandListener(VoteStart, "callvote");
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

	if (g_bPreMatch)
	{
		PreMatch();
		ReadConfigSourcebans();
	}

	if (LGO_IsMatchModeLoaded() && g_bPreMatch)
		g_bPreMatch = !g_bPreMatch;
}

public void OnMapEnd()
{
	if (!g_cvarEnable.BoolValue)
		return;

	KillTimerManager();
}

public void OnReadyUpInitiate()
{
	if (!g_cvarEnable.BoolValue)
		return;

	WaitingPlayers();
	OrganizeTeams();
	CheckCFG();

	KillTimerWaitReadyup();
	g_hTimerWaitReadyup = CreateTimer(g_cvarReadyupWait.FloatValue, Timer_ReadyUpWait);
}

public void OnRoundIsLive()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (!IsGameCompetitive(g_TypeMatch))
		return;

	KillTimerWaitPlayers();
	KillTimerWaitPlayersAnnouncer();
	KillTimerCheckPlayers();
	KillTimerWaitReadyup();
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if (!g_cvarEnable.BoolValue || !IsGameCompetitive(g_TypeMatch) || IsFakeClient(iClient))
		return;

	StartMatch();
	VerifyPlayers(iClient, sAuth);

	if (IsRageQuiters(iClient, sAuth))
	{
		RemoveRageQuiters(iClient, sAuth);
		fkn_log("ClientConnected: %N is ragequiter", iClient);
	}
}

public void VerifyPlayers(int iClient, const char[] sAuth)
{
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(sAuth, g_Players[TeamA][iID].steamid, false))
			g_Players[TeamA][iID].client = iClient;
		else if (StrEqual(sAuth, g_Players[TeamB][iID].steamid, false))
			g_Players[TeamB][iID].client = iClient;
	}
}

public Action Timer_ReadyUpWait(Handle timer)
{
	bool IsBanned = false;
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		int
			iClientTA = g_Players[TeamA][iID].client,
			iClientTB = g_Players[TeamB][iID].client;

		char sReason[128];
		Format(sReason, sizeof(sReason), "%s %t", JVPrefix, "BanReadyUp");

		if (iClientTA != CONSOLE && !IsReady(iClientTA))
		{
			switch (BansAccount(iID, TeamA, "%BanCode:03%"))
			{
				case 0: SBPP_BanPlayer(CONSOLE, iClientTA, g_cvarBanReadyup.IntValue, sReason);
				case 1: SBPP_BanPlayer(CONSOLE, iClientTA, g_cvarBanReadyupx2.IntValue, sReason);
				default: SBPP_BanPlayer(CONSOLE, iClientTA, g_cvarBanReadyupx3.IntValue, sReason);
			}

			if (g_cvarDebug.BoolValue)
				fkn_log("Player not Ready: Client: %N | TeamA | Ban: %d", iClientTA, g_cvarBanReadyup.IntValue);
			if (!IsBanned)
				IsBanned = !IsBanned;
		}
		else if (iClientTB != CONSOLE && !IsReady(iClientTB))
		{
			switch (BansAccount(iID, TeamB, "%BanCode:03%"))
			{
				case 0: SBPP_BanPlayer(CONSOLE, iClientTB, g_cvarBanReadyup.IntValue, sReason);
				case 1: SBPP_BanPlayer(CONSOLE, iClientTB, g_cvarBanReadyupx2.IntValue, sReason);
				default: SBPP_BanPlayer(CONSOLE, iClientTB, g_cvarBanReadyupx3.IntValue, sReason);
			}

			if (g_cvarDebug.BoolValue)
				fkn_log("Player not Ready: Client: %N | TeamB | Ban: %d", iClientTB, g_cvarBanReadyup.IntValue);
			if (!IsBanned)
				IsBanned = !IsBanned;
		}
	}

	if (IsBanned)
		ForceEndGame(ragequit);

	return Plugin_Stop;
}

public Action Cmd_KillTimer(int iClient, int iArgs)
{
	if (iArgs != 1)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_killtimer <manager|waitplayers|waitreadyup>");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg));

	if (StrEqual(sArg, "manager", false))
	{
		KillTimerManager();
		if (!g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Organizing Teams{default}", "Tag");
	}
	else if (StrEqual(sArg, "waitplayers", false))
	{
		KillTimerWaitPlayers();
		KillTimerWaitPlayersAnnouncer();
		if (!g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Wait{default}/{green}Announcer{default}", "Tag");
	}
	else if (StrEqual(sArg, "waitreadyup", false))
	{
		KillTimerWaitReadyup();
		if (!g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Readyup Wait{default}", "Tag");
	}

	return Plugin_Continue;
}

public Action Cmd_ListPlayers(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_missingplayers");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%t %t", "Tag", "TypeLobby", sTypeMatch[g_TypeMatch]);

	char
		sTmpBufferTA[128],
		sTmpBufferTB[128],
		sPrintBufferTA[1024],
		sPrintBufferTB[1024];

	Format(sTmpBufferTA, sizeof(sTmpBufferTA), "%t %t", "Tag", "TeamA");
	StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

	Format(sTmpBufferTB, sizeof(sTmpBufferTB), "%t %t", "Tag", "TeamB");
	StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

	for (int iID = 0; iID <= 3; iID++)
	{
		Format(sTmpBufferTA, sizeof(sTmpBufferTA), "({olive}%s{default}:", g_Players[TeamA][iID].steamid);
		StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

		Format(sTmpBufferTA, sizeof(sTmpBufferTA), "%s) ", g_Players[TeamA][iID].name);
		StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);

		if (iID == 1)
		{
			Format(sTmpBufferTA, sizeof(sTmpBufferTA), "\n");
			StrCat(sPrintBufferTA, sizeof(sPrintBufferTA), sTmpBufferTA);
		}

		Format(sTmpBufferTB, sizeof(sTmpBufferTB), "({olive}%s{default}:", g_Players[TeamB][iID].steamid);
		StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

		Format(sTmpBufferTB, sizeof(sTmpBufferTB), "%s) ", g_Players[TeamB][iID].name);
		StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);

		if (iID == 1)
		{
			Format(sTmpBufferTB, sizeof(sTmpBufferTB), "\n");
			StrCat(sPrintBufferTB, sizeof(sPrintBufferTB), sTmpBufferTB);
		}
	}

	CReplyToCommand(iClient, sPrintBufferTA);
	CReplyToCommand(iClient, sPrintBufferTB);

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

public Action VoteStart(int iClient, const char[] sCommand, int iArg)
{
	if (!g_cvarEnable.BoolValue || g_bPreMatch || L4D_GetClientTeam(iClient) == L4DTeam_Spectator)
		return Plugin_Continue;

	if (!IsNewBuiltinVoteAllowed)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "TryAgain", CheckBuiltinVoteDelay());
		return Plugin_Continue;
	}

	char sVoteType[32];
	char sVoteArgument[32];

	GetCmdArg(1, sVoteType, sizeof(sVoteType));
	GetCmdArg(2, sVoteArgument, sizeof(sVoteArgument));

	if (strcmp(sVoteType, "Kick", false) == 0)
	{
		if (IsGameCompetitive(g_TypeMatch))
		{
			CPrintToChat(iClient, "%t %t", "Tag", "NoVote", sTypeMatch[g_TypeMatch]);
			return Plugin_Handled;
		}
	}

	if (strcmp(sVoteType, "ReturnToLobby", false) == 0)
	{
		if (IsGameCompetitive(g_TypeMatch))
		{
			CPrintToChat(iClient, "%t %t", "Tag", "NoVote", sTypeMatch[g_TypeMatch]);
			return Plugin_Handled;
		}
	}

	if (strcmp(sVoteType, "ChangeMission", false) == 0)
	{
		if (IsGameCompetitive(g_TypeMatch))
		{
			CPrintToChat(iClient, "%t %t", "Tag", "NoVote", sTypeMatch[g_TypeMatch]);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Cmd_ClientID(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_jarvis_clientid");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%t \nTeamA: [%d][%d][%d][%d]\nTeamB: [%d][%d][%d][%d]", "Tag",
					g_Players[TeamA][0].client, g_Players[TeamA][1].client, g_Players[TeamA][2].client, g_Players[TeamA][3].client,
					g_Players[TeamB][0].client, g_Players[TeamB][1].client, g_Players[TeamB][2].client, g_Players[TeamB][3].client);
	return Plugin_Handled;
}

/*****************************************************************
			N A T I V E S
*****************************************************************/

// OffLineBan(int iTarget, int Team, int iTime, const char[] sReason, any ...)
any Native_ForsakenBan(Handle plugin, int numParams)
{
	int
		iTarget = GetNativeCell(1),
		Team	= GetNativeCell(2),
		iTime	= GetNativeCell(3);

	char sReason[PLATFORM_MAX_PATH];
	FormatNativeString(0, 4, 5, sizeof(sReason), _, sReason);
	CreateOffLineBan(iTarget, view_as<ForsakenTeam>(Team), iTime, sReason);
	return 0;
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
	if (!IsGameCompetitive(g_TypeMatch) || !L4D_IsFirstMapInScenario())
		return;

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
		sCfgName[128],
		sCurrentMap[32];
	ConVar
		l4d_ready_cfg_name;

	g_cvarConfigCfg.GetString(sCfgConvar, sizeof(sCfgConvar));
	l4d_ready_cfg_name = FindConVar("l4d_ready_cfg_name");

	if (l4d_ready_cfg_name == null)
	{
		fkn_log("ConVar l4d_ready_cfg_name not found");
		return Plugin_Stop;
	}

	l4d_ready_cfg_name.GetString(sCfgName, sizeof(sCfgName));

	if (FindString(sCfgName, sCfgConvar, false))
	{
		if (g_cvarDebug.BoolValue)
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

	if (!g_cvarChangeMap.BoolValue)
	{
		if (IsInReady())
		{
			KillTimerWaitPlayers();
			KillTimerWaitPlayersAnnouncer();
			KillTimerCheckPlayers();
			KillTimerWaitReadyup();
		}
		return Plugin_Stop;
	}

	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	if (StrEqual(g_sMapName, sCurrentMap, false))
	{
		if (g_cvarDebug.BoolValue)
		{
			CPrintToChatAll("%t %t", "Tag", "MapConfirm", g_sMapName, sCurrentMap);
			fkn_log("The current map (%s) corresponds to %s", g_sMapName, sCurrentMap);
		}
	}
	else
	{
		CPrintToChatAll("%t %t", "Tag", "MapChange", g_sMapName, sCurrentMap);
		fkn_log("The current map (%s) does not correspond to %s", g_sMapName, sCurrentMap);

		if (IsInReady())
		{
			KillTimerWaitPlayers();
			KillTimerWaitPlayersAnnouncer();
			KillTimerCheckPlayers();
			KillTimerWaitReadyup();
		}

		KillTimerManager();
		ServerCommand("changelevel %s", g_sMapName);
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

public void KillTimerWaitReadyup()
{
	if (g_hTimerWaitReadyup != null)
	{
		delete g_hTimerWaitReadyup;
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Readyup Wait{default}", "Tag");
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			CPrintToChatAll("%t {red}KillTimer{default}: {green}Timer not found{default}", "Tag");
	}
}