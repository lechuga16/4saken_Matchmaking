#pragma semicolon 1
#pragma newdecls required

#include <4saken>
#include <colors>
#include <json>
#include <Regex>
#include <sourcemod>
#include <system2>
#define PLUGIN_VERSION  "0.1"
#define MAX_PLAYER_TEAM 4
#define STEAMID_LENGTH  32

ConVar
	g_cvarDebug;

char
	SteamIDT1[MAX_PLAYER_TEAM][STEAMID_LENGTH],
	SteamIDT2[MAX_PLAYER_TEAM][STEAMID_LENGTH],
	sURL[256];

int
	g_iPort,
	iRegion = 0;

JSON_Object
	jsMatch;

JSON_Array
	arrTeam1,
	arrTeam2;

public Plugin myinfo =
{
	name        = "4saken Core",
	author      = "lechuga",
	description = "Manage the 4saken api",
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

	// Native
	CreateNative("_4saken_log", Native_Log);
	CreateNative("_4saken_TypeMatch", Native_TypeMatch);
	CreateNative("_4saken_Team1", Native_Team1);
	CreateNative("_4saken_Team2", Native_Team2);
	RegPluginLibrary("4saken");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_4saken_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug = CreateConVar("sm_4saken_debug", "0", "Debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_4saken_showip", ShowIP, "Get ip and port server");
	RegConsoleCmd("sm_4saken_match", TestMatch, "Get steam player id and game type");
	g_iPort = FindConVar("hostport").IntValue;

	AutoExecConfig(true, "4saken");
	JSON_Check();
	GetMatch();
}

/*****************************************************************
            L I B R A R Y   I N C L U D E S
*****************************************************************/
#include "4saken/4saken_native.sp"

bool JSON_Check()
{
	char sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), "configs/4saken.json");

	if (FileExists(sPatch))
		return true;

	if (g_cvarDebug.BoolValue)
		_4saken_log("4saken.json: Not found");

	JSON_Create();
	return false;
}

public void JSON_Create()
{
	char
		output[32],
		sPatch[64];
	JSON_Object JoIp = new JSON_Object();
	JoIp.SetString("IP", "0.0.0.0");
	JoIp.Encode(output, sizeof(output));

	BuildPath(Path_SM, sPatch, sizeof(sPatch), "configs/4saken.json");
	json_write_to_file(JoIp, sPatch, JSON_ENCODE_PRETTY);
	json_cleanup_and_delete(JoIp);
	if (g_cvarDebug.BoolValue)
		_4saken_log("4saken.json: Created !");
}

public Action ShowIP(int iClient, int iArgs)
{
	if (iArgs != 0)
		CReplyToCommand(iClient, "Usage: sm_4saken_showip");
	CReplyToCommand(iClient, "ServerIP: {green}%s{default}:{green}%d{default}", _4saken_GetIp(), FindConVar("hostport").IntValue);
	return Plugin_Handled;
}

public Action TestMatch(int iClient, int iArgs)
{
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

void GetMatch()
{
	Format(sURL, sizeof(sURL), "%s?ip=%s&port=%d", URL_4SAKEN_MATCH, _4saken_GetIp(), g_iPort);
	if (g_cvarDebug.BoolValue)
		_4saken_log("GetMatch URL: %s", sURL);

	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, sURL);
	httpRequest.SetHeader("Content-Type", "application/json");
	httpRequest.Timeout = 5;
	httpRequest.GET();
	delete httpRequest;
}

void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		url[256],
		content[300];

	request.GetURL(url, sizeof(url));

	if (!success)
	{
		_4saken_log("ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
		return;
	}

	for (int found = 0; found < response.ContentLength;)
	{
		found += response.GetContent(content, sizeof(content), found);
	}

	jsMatch = json_decode(content);
	iRegion = jsMatch.GetInt("region");

	arrTeam1 = view_as<JSON_Array>(jsMatch.GetObject("team1"));
	arrTeam2 = view_as<JSON_Array>(jsMatch.GetObject("team2"));
	for (int i = 0; i <= 3; i++)
	{
		arrTeam1.GetString(i, SteamIDT1[i], STEAMID_LENGTH);
		ReplaceString(SteamIDT1[i], STEAMID_LENGTH, "STEAM_0", "STEAM_1", false);

		arrTeam2.GetString(i, SteamIDT2[i], STEAMID_LENGTH);
		ReplaceString(SteamIDT2[i], STEAMID_LENGTH, "STEAM_0", "STEAM_1", false);
	}
}