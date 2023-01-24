#pragma semicolon 1
#pragma newdecls required

#include <forsaken>
#include <colors>
#include <json>
#include <Regex>
#include <sourcemod>
#include <system2>
#undef REQUIRE_PLUGIN
#include <confogl>
#define REQUIRE_PLUGIN

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

#define PLUGIN_VERSION	"0.1"
#define PREFIX			"[{olive}4saken{default}]"

char
	g_sURL[256],
	g_sIPv4[64],
	g_sPatchIP[64],
	g_sMapName[32] = "c5m1_waterfront_sndscape";

int
	g_iQueueID = 0,
	g_iPort;

bool g_bGetIPv4 = true;

GlobalForward  g_gfCacheDownload;

/*****************************************************************
			P L U G I N   I N F O
*****************************************************************/
public Plugin myinfo =
{
	name		= "Forsaken Core",
	author		= "lechuga",
	description = "Core for forsaken plugins, distributes relevant information",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/lechuga16/4saken_Matchmaking"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
		return APLRes_Failure;
	}
	g_gfCacheDownload = CreateGlobalForward("OnCacheDownload", ET_Ignore);
	RegPluginLibrary("forsaken");
	return APLRes_Success;
}

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public void OnPluginStart()
{
	CreateConVar("sm_fkn_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug	 = CreateConVar("sm_fkn_debug", "0", "Debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarEnable = CreateConVar("sm_fkn_enable", "1", "Activate forsaken", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_fkn_showip", Cmd_ShowIP, "Get ip and port server");
	RegAdminCmd("sm_fkn_playersinfo", Cmd_PlayersInfo, ADMFLAG_GENERIC, "Shows the name and SteamID of the players");
	RegAdminCmd("sm_fkn_downloadCache", Cmd_DownloadCache, ADMFLAG_GENERIC, "Download cache match");
	RegAdminCmd("sm_fkn_deleteCache", Cmd_DeleteCache, ADMFLAG_GENERIC, "Delete cache match");
	RegAdminCmd("sm_fkn_updatecache", Cmd_UpdateCache, ADMFLAG_GENERIC, "Update cache match");

	AutoExecConfig(true, "forsaken");

	g_iPort = FindConVar("hostport").IntValue;
	BuildPath(Path_SM, g_sPatchIP, sizeof(g_sPatchIP), DIR_IP);
	JSON_Check();
	GetIPv4();

	if(LGO_IsMatchModeLoaded())
		GetMatch();
}

public void OnPluginEnd()
{
	if (!g_cvarEnable.BoolValue)
		return;

	DeleteCache();
	DeleteIPV4();
}

public Action Cmd_ShowIP(int iClient, int iArgs)
{
	if (iArgs != 0)
		CReplyToCommand(iClient, "Usage: sm_fkn_showip");

	char sIp[64];
	sIp = fkn_GetIP();

	CReplyToCommand(iClient, "%s ServerIP: {green}%s{default}:{green}%d{default}", PREFIX, sIp, g_iPort);
	CReplyToCommand(iClient, "%s ServerIPv4: {green}%s{default}:{green}%d{default}", PREFIX, g_sIPv4, g_iPort);
	return Plugin_Handled;
}

public Action Cmd_PlayersInfo(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_fkn_playersinfo");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%s QueueID: {green}%d{default}", PREFIX, g_iQueueID);
	CReplyToCommand(iClient, "%s MapName: {green}%s{default}", PREFIX, g_sMapName);

	CReplyToCommand(iClient, "%s TeamA:\n({blue}%s{default}:%s) ({blue}%s{default}:%s)\n({blue}%s{default}:%s) ({blue}%s{default}:%s)",
					PREFIX, g_Players[TeamA][0].name, g_Players[TeamA][0].steamid,
					g_Players[TeamA][1].name, g_Players[TeamA][1].steamid,
					g_Players[TeamA][2].name, g_Players[TeamA][2].steamid,
					g_Players[TeamA][3].name, g_Players[TeamA][3].steamid);

	CReplyToCommand(iClient, "%s TeamB:\n({blue}%s{default}:%s) ({blue}%s{default}:%s)\n({blue}%s{default}:%s) ({blue}%s{default}:%s)",
					PREFIX, g_Players[TeamB][0].name, g_Players[TeamB][0].steamid,
					g_Players[TeamB][1].name, g_Players[TeamB][1].steamid,
					g_Players[TeamB][2].name, g_Players[TeamB][2].steamid,
					g_Players[TeamB][3].name, g_Players[TeamB][3].steamid);

	return Plugin_Handled;
}

public Action Cmd_DownloadCache(int iClient, int iArgs)
{
	GetMatch();
	CReplyToCommand(iClient, "%s Downloading cache match...", PREFIX);
	return Plugin_Handled;
}

public Action Cmd_DeleteCache(int iClient, int iArgs)
{
	char
		sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_CACHEMATCH);

	if(FileExists(sPatch))
		DeleteFile(sPatch);

	CReplyToCommand(iClient, "%s Cache match deleted", PREFIX);
	return Plugin_Handled;
}

public Action Cmd_UpdateCache(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		CReplyToCommand(iClient, "Usage: sm_fkn_updatecache");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%s Cache match updated", PREFIX);
	GetMatch();

	return Plugin_Handled;
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief checks for the existence of the "configs/forsaken/IP.json" file.
 *     if it does not exist, it creates it.
 *
 * @noreturn
 */
void JSON_Check()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (FileExists(g_sPatchIP))
		return;

	fkn_log(true, "%s Not found", DIR_IP);

	JSON_Create();
}

/**
 * @brief creates the "configs/forsaken/IP.json" file.
 *
 * @noreturn
 */
void JSON_Create()
{
	char	output[32];

	JSON_Object JoIp = new JSON_Object();
	JoIp.SetString("IP", "0.0.0.0");
	JoIp.Encode(output, sizeof(output));

	if (!FileExists(g_sPatchIP))
	{
		fkn_log(false, "Error: %s Invalid file path", DIR_IP);
		return;
	}

	json_write_to_file(JoIp, g_sPatchIP, JSON_ENCODE_PRETTY);

	fkn_log(true, "%s Created !", DIR_IP);
	json_cleanup_and_delete(JoIp);
}

void DeleteCache()
{
	char
		sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_CACHEMATCH);

	if(FileExists(sPatch))
		DeleteFile(sPatch);
}

void DeleteIPV4()
{
	char
		sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_IPV4);

	if(FileExists(sPatch))
		DeleteFile(sPatch);
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Create an httpRequest, and retrieve the match data.
 *
 * @noreturn
 */
public void GetMatch()
{
	if (!g_cvarEnable.BoolValue)
		return;

	char sPatch[128];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_CACHEMATCH);
	Format(g_sURL, sizeof(g_sURL), "%s?ip=%s&port=%d", URL_FORSAKEN_MATCH, fkn_GetIP(), g_iPort);
	fkn_log(true, "GetMatch URL: %s", g_sURL);

	System2HTTPRequest httpMatch = new System2HTTPRequest(HttpMatchInfo, g_sURL);
	httpMatch.SetHeader("Content-Type", "application/json");
	httpMatch.SetOutputFile(sPatch);
	if (g_cvarDebug.BoolValue)
		httpMatch.SetProgressCallback(HttpProgressMatch);
	httpMatch.GET();
	delete httpMatch;
}

void HttpProgressMatch(System2HTTPRequest request, int dlTotal, int dlNow, int ulTotal, int ulNow)
{
	PrintToServer("forsaken_match.json downloaded %d of %d bytes", dlNow, dlTotal);
	fkn_log(true, "forsaken_match.json downloaded %d of %d bytes", dlNow, dlTotal);
}

void HttpMatchInfo(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		url[256];

	request.GetURL(url, sizeof(url));

	if (!success)
	{
		fkn_log(false, "ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
		return;
	}

	Call_StartForward(g_gfCacheDownload);
	if (Call_Finish() != 0)
		fkn_log(false, "forsaken_web: error in forward Call_Finish");
}
/**
 * @brief Create an http request and retrieve the IPv4 of the server.
 *
 * @noreturn
 */
void GetIPv4()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if(!g_bGetIPv4)
		return;

	g_bGetIPv4 = !g_bGetIPv4;
	
	char sPatch[128];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_IPV4);

	System2HTTPRequest httpIPv4 = new System2HTTPRequest(HttpIPv4, URL_IPV4);
	httpIPv4.SetHeader("Content-Type", "application/json");
	httpIPv4.SetOutputFile(sPatch);
	if (g_cvarDebug.BoolValue)
		httpIPv4.SetProgressCallback(HttpProgressIpv4);
	httpIPv4.GET();
	delete httpIPv4;
}

void HttpProgressIpv4(System2HTTPRequest request, int dlTotal, int dlNow, int ulTotal, int ulNow)
{
	PrintToServer("IPv4 downloaded %d of %d bytes", dlNow, dlTotal);
}

void HttpIPv4(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char url[256];

	request.GetURL(url, sizeof(url));

	if (!success)
	{
		fkn_log(false, "ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
		return;
	}

	g_sIPv4 = fkn_GetIP();
}