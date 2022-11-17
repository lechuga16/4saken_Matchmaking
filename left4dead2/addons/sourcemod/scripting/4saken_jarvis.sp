#include <4saken>
#include <colors>
#include <sourcemod>
#include <system2>
#include <json>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <pause>
#define PLUGIN_VERSION "0.1"

ConVar
	g_cvarDebug,

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
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("4saken.phrases");
	// LoadTranslation("4saken_endgame.phrases");

	CreateConVar("sm_4saken_jarvis_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug		= CreateConVar("sm_4saken_jarvis_debug", "0", "Turn on debug messages", FCVAR_NONE, true, 0.0, true, 1.0);


	AutoExecConfig(true, "4saken_jarvis");
}
