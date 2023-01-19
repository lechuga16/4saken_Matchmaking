
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

#define PLUGIN_VERSION "1.0"
#define JVPrefix	   "[J.A.R.V.I.S]"

ConVar
	g_cvarDebug,
	g_cvarEnable;

bool g_bPlayersToStartFull = false;

/*****************************************************************
			L I B R A R Y   I N C L U D E S
*****************************************************************/

#include "forsaken/jarvis_reserved.sp"
#include "forsaken/jarvis_prematch.sp"
#include "forsaken/jarvis_teams.sp"
#include "forsaken/jarvis_ragequit.sp"
#include "forsaken/jarvis_waiting.sp"
#include "forsaken/jarvis_readyup.sp"
#include "forsaken/jarvis_ban.sp"
#include "forsaken/jarvis_blockvote.sp"
#include "forsaken/jarvis_checkmatch.sp"

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

public void OnPluginStart()
{
	LoadTranslation("forsaken_jarvis.phrases");
	CreateConVar("sm_jarvis_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug	 = CreateConVar("sm_jarvis_debug", "0", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarEnable = CreateConVar("sm_jarvis_enable", "1", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);

	OnPluginStart_Reserved();
	OnPluginStart_prematch();
	OnPluginStart_Teams();
	OnPluginStart_RageQuit();
	OnPluginStart_Waiting();
	OnPluginStart_Readyup();
	OnPluginStart_Bans();
	OnPluginStart_BlockVote();

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	AutoExecConfig(true, "forsaken_jarvis");
}

public void OnMapStart()
{
	if (!g_cvarEnable.BoolValue)
		return;

	OMS_prematch();
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
	
	ORUI_Teams();
	ORUI_Waiting();
	ORUI_CheckMatch();
	ORUI_Readyup();
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

public void OnClientPutInServer(int iClient)
{
	if (!g_cvarEnable.BoolValue || LGO_IsMatchModeLoaded())
		return;

	if (IsFakeClient(iClient))
		return;

	if (!g_bPlayersToStartFull)
		OCPIS_Reserved();
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if (!g_cvarEnable.BoolValue || !IsGameCompetitive(g_TypeMatch) || IsFakeClient(iClient))
		return;

	OnCA_RageQuit(iClient, sAuth);
}

public void OnCacheDownload()
{
	if (!g_cvarEnable.BoolValue || !LGO_IsMatchModeLoaded())
		return;
		
	OCD_prematch();
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/
public void Event_PlayerDisconnect(Handle hEvent, char[] sEventName, bool bDontBroadcast)
{
	if (!g_cvarEnable.BoolValue || !LGO_IsMatchModeLoaded())
		return;

	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClientIndex(iClient))
		return;

	char sSteamId[32];
	if (!GetClientAuthId(iClient, AuthId_SteamID64, sSteamId, sizeof(sSteamId)))
		return;

	if (strcmp(sSteamId, "BOT") == 0)
		return;

	PlayerDisconnect_ragequit(hEvent, sSteamId);
}