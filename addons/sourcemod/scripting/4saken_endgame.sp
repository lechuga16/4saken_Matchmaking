#include <4saken>
#include <colors>
#include <sourcemod>
#include <system2>
#include <json>
#undef REQUIRE_PLUGIN
#include <readyup>
#define PLUGIN_VERSION "0.1"

ConVar
	g_cvarDebug,
	g_cvarEnable,
	g_cvarTimeKick;

bool
	g_bIsEndGame = false,
	g_bAnnounce = true;

GlobalForward
	g_gfEndGame;

public Plugin myinfo =
{
	name        = "4saken End Game",
	author      = "lechuga",
	description = "Handle the endgame",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lechuga16/4saken_Matchmaking"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
		return APLRes_Failure;
	}
	CreateNative("IsEndGame", Native_IsEndGame);
	RegPluginLibrary("4saken_endgame");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("4saken.phrases");
	LoadTranslation("4saken_endgame.phrases");

	HookEvent("round_end", Event_RoundEnd);

	CreateConVar("sm_4saken_endgame_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug		= CreateConVar("sm_4saken_endgame_debug", "0", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarEnable    = CreateConVar("sm_4saken_enable", "1", "Was the end of the game before the last map", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarTimeKick	= CreateConVar("sm_4saken_timekick", "10.0", "Set counter before kicking players", FCVAR_NONE, true, 0.0, true, 10.0);
	RegAdminCmd("sm_4saken_checkmap", Cmd_CheckMap, ADMFLAG_ROOT);
	RegAdminCmd("sm_4saken_maplist", Cmd_Maplist, ADMFLAG_ROOT);

	g_gfEndGame = CreateGlobalForward("OnEndGame", ET_Ignore);

	AutoExecConfig(true, "4saken_endgame");
}

// ======================================
// Natives
// ======================================

public int Native_IsEndGame(Handle plugin, int numParams)
{
    return g_bIsEndGame;
}

public void OnRoundLiveCountdown()
{
	if(!g_cvarEnable.BoolValue)
		return;

	if(g_bAnnounce)
	{
		g_bAnnounce = false;
		CPrintToChatAll("%t %t", "Tag", "Lastmap");
	}

	if(InSecondHalfOfRound())
		return;

	if (CurrentMapEndGame())
		g_bIsEndGame = true;
}

public void OnRoundIsLive()
{
	g_bAnnounce = true;
}

public void Event_RoundEnd(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if(g_cvarDebug.BoolValue)
		CPrintToChatAll("%t EndGame: {olive}%s{default}", "Tag", g_bIsEndGame ? "True" : "False");

	if(!g_bIsEndGame)
		return;

	if(!InSecondHalfOfRound())
		return;

	Call_StartForward(g_gfEndGame);
	Call_Finish();
	CPrintToChatAll("%t %t", "Tag", "Ended");
	CreateTimer(g_cvarTimeKick.FloatValue, KickAll);
}

public Action Cmd_CheckMap(int iClient, int iArgs)
{
	if (CurrentMapEndGame())
		CReplyToCommand(iClient, "%t %t", "Tag", "Lastmap");
	else
		CReplyToCommand(iClient, "%t %t", "Tag", "NotLastMap");
	return Plugin_Continue;
}

public Action Cmd_Maplist(int iClient, int iArgs)
{
	JSON_Array jaMaps = _4saken_Maps();

	int iLength = jaMaps.Length;
	for (int index = 0; index < iLength; index += 1)
	{
		char sListMap[32];
		jaMaps.GetString(index, sListMap, sizeof(sListMap));
		CPrintToChatAll("%t %s", "Tag", sListMap);
	}
	json_cleanup_and_delete(jaMaps);
	return Plugin_Continue;
}

public bool CurrentMapEndGame()
{
	JSON_Array jaMaps = _4saken_Maps();

	int iLength = jaMaps.Length;
	for (int index = 0; index < iLength; index += 1)
	{
		char sListMap[32];
		jaMaps.GetString(index, sListMap, sizeof(sListMap));

		char sMapName[32];
		GetCurrentMap(sMapName, sizeof(sMapName));
		if (strcmp(sMapName, sListMap) == 0)
		{
			return true;
		}
	}
	json_cleanup_and_delete(jaMaps);
	return false;
}

public Action KickAll(Handle timer)
{
	ServerCommand("sm_kick @all %t", "KickAll");
	return Plugin_Continue;
}