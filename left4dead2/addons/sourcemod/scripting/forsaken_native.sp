#pragma semicolon 1
#pragma newdecls required

#include <forsaken>
#include <forsaken_endgame>
#include <colors>
#include <json>
#include <sourcemod>
#include <system2>
#define PLUGIN_VERSION "0.2"

#define MAX_PLAYER_TEAM 4
#define STEAMID_LENGTH 32

public Plugin myinfo =
{
	name        = "Forsaken Native Testing",
	author      = "lechuga",
	description = "Manage the forsaken api",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lechuga16/4saken_Matchmaking"
}

public void OnPluginStart()
{
	CreateConVar("sm_native_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	RegConsoleCmd("sm_forsaken_native", ForsakenTest);
	RegConsoleCmd("sm_forsaken_endgame", EndgameTest);
}

public Action ForsakenTest(int iClient, int iArgs)
{
	char 
		g_sSteamIDTA[MAX_PLAYER_TEAM][STEAMID_LENGTH],
		g_sSteamIDTB[MAX_PLAYER_TEAM][STEAMID_LENGTH];

	TypeMatch g_Match = Forsaken_TypeMatch();

	for (int i = 0; i <= 3; i++)
	{
		Forsaken_TeamA(i, g_sSteamIDTA[i], STEAMID_LENGTH);
		Forsaken_TeamB(i, g_sSteamIDTB[i], STEAMID_LENGTH);
	}

	CReplyToCommand(iClient, "Region: %d", g_Match);

	char
		tmpBuffer[64],
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