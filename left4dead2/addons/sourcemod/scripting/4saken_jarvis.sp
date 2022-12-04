#include <4saken>
#include <colors>
#include <json>
#include <sourcemod>
#include <system2>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>
#define PLUGIN_VERSION  "0.1"
#define MAX_PLAYER_TEAM 5
#define STEAMID_LENGTH  32

enum TypeMatch
{
	invalid  = 0,
	scout    = 1,
	adept    = 2,
	veteran  = 3,
	unranked = 4,
	scrims   = 5

}

enum ForsakenTeam
{
	Team0 = 0,
	Team1 = 1,
	Team2 = 2,
}

TypeMatch
	g_Lobby;

ConVar
	g_cvarDebug;
bool
	g_bEnnounceStart = true;

char
	SteamIDT1[MAX_PLAYER_TEAM][STEAMID_LENGTH],
	SteamIDT2[MAX_PLAYER_TEAM][STEAMID_LENGTH];

public Plugin myinfo =
{
	name        = "4saken End Game",
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
	LoadTranslation("4saken.phrases");
	// LoadTranslation("4saken_endgame.phrases");

	CreateConVar("sm_4saken_jarvis_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug = CreateConVar("sm_4saken_jarvis_debug", "0", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_4saken_isplayer", isplayer);
	RegConsoleCmd("sm_4saken_addlechu", addlechu);
	RegConsoleCmd("sm_4saken_teslist", TestMatch);

	HookEvent("player_team", Event_PlayerTeam);

	PreMatch();
	CreateTimer(2.0, OrganizeTeams);

	AutoExecConfig(true, "4saken_jarvis");
}

/*****************************************************************
            L I B R A R Y   I N C L U D E S
*****************************************************************/
#include "4saken/jarvis_prematch.sp"
#include "4saken/jarvis_teams.sp"

public Action addlechu(int iClient, int iArgs)
{
	char sArgs[8];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	char sSteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));

	if (StrEqual(sArgs, "1"))
	{
		CReplyToCommand(iClient, "Se agrego como survivor");
		SteamIDT1[4] = sSteamID;
	}
	else if (StrEqual(sArgs, "2"))
	{
		CReplyToCommand(iClient, "Se agrego como infected");
		SteamIDT2[4] = sSteamID;
	}
	return Plugin_Continue;
}

public Action TestMatch(int iClient, int iArgs)
{
	for (int i = 0; i <= 4; i++)
	{
		int iPlayer = 1 + i;
		CReplyToCommand(iClient, "Team1 Player %d: %s", iPlayer, SteamIDT1[i]);
	}

	for (int i = 0; i <= 4; i++)
	{
		int iPlayer = 1 + i;
		CReplyToCommand(iClient, "Team2 Player %d: %s", iPlayer, SteamIDT2[i]);
	}

	return Plugin_Handled;
}