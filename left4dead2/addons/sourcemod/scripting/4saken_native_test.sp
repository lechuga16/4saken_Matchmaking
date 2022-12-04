#pragma semicolon 1
#pragma newdecls required

#include <4saken>
#include <4saken_endgame>
#include <colors>
#include <json>
#include <sourcemod>
#include <system2>
#define PLUGIN_VERSION "0.2"

#define MAX_PLAYER_TEAM 4
#define STEAMID_LENGTH 32

public Plugin myinfo =
{
	name        = "4saken Native Testing",
	author      = "lechuga",
	description = "Manage the 4saken api",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lechuga16/4saken_Matchmaking"
}

public void OnPluginStart()
{
	CreateConVar("sm_4saken_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	RegConsoleCmd("sm_4saken_native", ForsakenTest);
	RegConsoleCmd("sm_4saken_endgame", EndgameTest);
}

public Action ForsakenTest(int iClient, int iArgs)
{
	char 
		sSteamIDT1[MAX_PLAYER_TEAM][STEAMID_LENGTH],
		sSteamIDT2[MAX_PLAYER_TEAM][STEAMID_LENGTH];

	TypeMatch g_Match = _4saken_TypeMatch();

	for (int i = 0; i <= 3; i++)
	{
		_4saken_Team1(i, sSteamIDT1[i], STEAMID_LENGTH);
		_4saken_Team2(i, sSteamIDT2[i], STEAMID_LENGTH);
	}

	CReplyToCommand(iClient, "Region: %d", g_Match);

	for (int i = 0; i <= 3; i++)
	{
		int iPlayer = 1 + i;
		CReplyToCommand(iClient, "Team1 Player %d: %s", iPlayer, sSteamIDT1[i]);
	}

	for (int i = 0; i <= 3; i++)
	{
		int iPlayer = 1 + i;
		CReplyToCommand(iClient, "Team2 Player %d: %s", iPlayer, sSteamIDT2[i]);
	}

	return Plugin_Continue;
}

public Action EndgameTest(int iClient, int iArgs)
{
	CReplyToCommand(iClient, "EndGame %s", IsEndGame() ? "True" : "False");
	return Plugin_Continue;
}

public void OnEndGame()
{
	CPrintToChatAll("Forward EndGame is on");
}