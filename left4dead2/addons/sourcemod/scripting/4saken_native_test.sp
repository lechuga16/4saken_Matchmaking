#pragma semicolon 1
#pragma newdecls required

#include <4saken>
#include <colors>
#include <json>
#include <sourcemod>
#include <system2>
#define PLUGIN_VERSION "0.1"

#define MAX_PLAYER_TEAM 4
#define STEAMID_LENGTH 32
char SteamIDT1[MAX_PLAYER_TEAM][STEAMID_LENGTH];
char SteamIDT2[MAX_PLAYER_TEAM][STEAMID_LENGTH];
int iRegion;

public Plugin myinfo =
{
	name        = "4saken Native Testing",
	author      = "lechuga",
	description = "Manage the 4saken api",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lechuga16/4saken_Matchmaking"


}

public void
	OnPluginStart()
{
	CreateConVar("sm_4saken_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	RegConsoleCmd("sm_4saken_native_test", NativeTest, "Get steam player id and game type");
}

public Action NativeTest(int iClient, int iArgs)
{

	iRegion = _4saken_TypeMatch();
	for (int i = 0; i <= 3; i++)
	{
		_4saken_Team1(i, SteamIDT1[i], STEAMID_LENGTH);
		_4saken_Team2(i, SteamIDT2[i], STEAMID_LENGTH);
	}

	CReplyToCommand(iClient, "Region: %d", iRegion);

	for (int i = 0; i <= 3; i++)
	{
		int iPlayer = 1 + i;
		CReplyToCommand(iClient, "Team1 Player %d: %s", iPlayer, SteamIDT1[i]);
	}

	for (int i = 0; i <= 3; i++)
	{
		int iPlayer = 1 + i;
		CReplyToCommand(iClient, "Team2 Player %d: %s", iPlayer, SteamIDT2[i]);
	}

	return Plugin_Handled;
}