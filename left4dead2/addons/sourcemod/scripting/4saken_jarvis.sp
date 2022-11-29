#include <4saken>
#include <colors>
#include <json>
#include <sourcemod>
#include <system2>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>
#define PLUGIN_VERSION "0.1"

enum TypeMatch
{
	unrank = 1,
	rank,
	teams

}

TypeMatch
	g_Lobby = rank;
ConVar
	g_cvarDebug;
bool
	g_bMatchModeLoaded,
	g_bIsRank;

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

	g_bMatchModeLoaded = LGO_IsMatchModeLoaded();

	AutoExecConfig(true, "4saken_jarvis");

	char sAuth[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientAuthorized(i) && GetClientAuthId(i, AuthId_Engine, sAuth, sizeof(sAuth)))
			OnClientAuthorized(i, sAuth);
	}
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if (g_Lobby == unrank)
		return;

	if (g_bMatchModeLoaded)
	{
		OrganizeTeams(iClient);
		return;
	}

	switch (CountPlayers())
	{
		case 1:
			CPrintToChatAll("[J.A.R.V.I.S] Falta 1 jugador para cambiar a zonemod");

		case 2:
		{
			CPrintToChatAll("[J.A.R.V.I.S] Cambiando a ZoneMod");
			ServerCommand("sm_forcestart zonemod");
		}
	}
}

public void OrganizeTeams(int iClient)
{
	if (!IsClientInGame(iClient) && IsFakeClient(iClient))
		return;

	char sAuthId[64];
	GetClientAuthId(iClient, AuthId_Engine, sAuthId, 64);
	if(ChangeClientTeamEx(iClient, L4DTeam_Spectator))
	{
		CPrintToChat(iClient, "[J.A.R.V.I.S] Debes permanecer como espectador");
	}

}

public int CountPlayers()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			iCount++;
		}
	}

	return iCount;
}

stock bool ChangeClientTeamEx(iClient, L4DTeam team)
{
	if (L4D_GetClientTeam(iClient) == team)
		return true;

	if (team != L4DTeam_Survivor)
	{
		ChangeClientTeam(iClient, view_as<int>(team));
		return true;
	}
	else
	{
		int bot = FindSurvivorBot();

		if (bot > 0)
		{
			int flags = GetCommandFlags("sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
			FakeClientCommand(iClient, "sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags);
			return true;
		}
	}
	return false;
}

stock int FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsFakeClient(client) && L4D_GetClientTeam(client) == L4DTeam_Survivor)
			return client;
	}
	return -1;
}