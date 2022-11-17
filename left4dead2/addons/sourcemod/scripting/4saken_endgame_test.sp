#include <4saken>
#include <colors>
#include <sourcemod>
#define PLUGIN_VERSION "0.1"

public Plugin myinfo =
{
	name        = "4saken End Game Test",
	author      = "lechuga",
	description = "Testing handle the endgame",
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
}

public void OnEndGame()
{
	CPrintToChatAll("%t The endgame event was {blue}successfully called{default}.", "Tag");
}