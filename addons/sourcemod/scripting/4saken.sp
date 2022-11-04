#pragma semicolon 1
#pragma newdecls required

#include <4saken>
#include <colors>
#include <sourcemod>
#include <system2>
#define PLUGIN_VERSION "0.1"
#define IPIFY_URL      "api.ipify.org"

ConVar
	g_cvarDebug,
	g_cvarEnableIp;
char
	g_sLogPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name        = "4saken Core",
	author      = "lechuga",
	description = "Manage the 4saken api",
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

	// Native
	CreateNative("_4saken_log", Native_Log);
	RegPluginLibrary("4saken");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_4saken_version", PLUGIN_VERSION, "Plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_cvarDebug    = CreateConVar("sm_4saken_debug", "0", "Debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarEnableIp = CreateConVar("sm_4saken_enableip", "1", "Enable automatic IP detection, if disabled, it should use sm_4saken_ip", FCVAR_NONE, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_4saken_showip", ShowIP, "get ip and port server");
	RegAdminCmd("sm_4saken_kv", Cmd_KeyValue, ADMFLAG_ROOT, "Manages the values of the 4saken.cfg file");
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/4saken.log");
	AutoExecConfig(true, "4saken");
	if(KVCheck())
	{
		char sBuffer[64];
		_4saken_KvGet("server", "ip", sBuffer, sizeof(sBuffer));
		if (g_cvarDebug.BoolValue)
			_4saken_log("GET IP KeyValue: %s", sBuffer);
	}
}

// native void _4saken_log(const char[] format, any ...);
public any Native_Log(Handle plugin, int numParams)
{
	char
		sFilename[64],
		sBuffer[256];
	GetPluginBasename(plugin, sFilename, sizeof(sFilename));
	FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
	LogToFileEx(g_sLogPath, "[%s] %s", sFilename, sBuffer);
	return 0;
}

public Action Cmd_KeyValue(int iClient, int iArgs)
{
	if (iArgs <= 2 || iArgs >= 5)
	{
		CReplyToCommand(iClient, "Usage: sm_4saken_kv <get/set> <section> <key> <new value>");
		return Plugin_Handled;
	}
	char
		sAction[8],
		sSection[8],
		sKey[16],
		sValue[64];
	GetCmdArg(1, sAction, sizeof(sAction));
	GetCmdArg(2, sSection, sizeof(sSection));
	GetCmdArg(3, sKey, sizeof(sKey));
	GetCmdArg(4, sValue, sizeof(sValue));

	char 
		sPatch[64],
		sBuffer[64];

	BuildPath(Path_SM, sPatch, sizeof(sPatch), _4SAKEN_DIR_CFG);
	KeyValues kv = new KeyValues("4saken");
	kv.ImportFromFile(sPatch);

	if (!kv.JumpToKey(sSection))
	{
		ReplyToCommand(iClient, "Value of <%s> is invalid or does not exist", sSection);
		delete kv;
		return Plugin_Handled;
	}

	if(StrEqual(sAction, "get", false))
	{
		if (iArgs != 3)
		{
			CReplyToCommand(iClient, "Usage: sm_4saken_kv <get/set> <section> <key> <new value>");
			return Plugin_Handled;
		}
		kv.JumpToKey(sSection);
		kv.GetString(sKey, sBuffer, sizeof(sBuffer), "KeyNotFound");
		if(StrEqual(sBuffer, "KeyNotFound", false))
		{
			_4saken_log("KeyValue: %s not found", sKey);
			return Plugin_Handled;
		}
		CReplyToCommand(iClient, "Value of <%s> is: <%s>", sKey, sBuffer);
		delete kv;
	}
	else if(StrEqual(sAction, "set", false))
	{
		if (iArgs != 4)
		{
			CReplyToCommand(iClient, "Usage: sm_4saken_kv <get/set> <section> <key> <new value>");
			return Plugin_Handled;
		}
		kv.JumpToKey(sSection);
		kv.SetString(sKey, sValue);
		kv.Rewind();
		kv.ExportToFile(sPatch);
		CReplyToCommand(iClient, "New value of <%s> is: <%s>", sKey, sValue);
		delete kv;
	}
	else
	{
		ReplyToCommand(iClient, "Value of <%s> is invalid or does not exist", sAction);
		delete kv;
	}
	return Plugin_Handled;
}

bool KVCheck()
{
	char sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), _4SAKEN_DIR_CFG);
	if (!FileExists(sPatch))
	{
		_4saken_log("KeyValue: %s not found, creating file...", sPatch);
		KVCreation();
		return false;
	}
	return true;
}

void KVCreation()
{
	char sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), _4SAKEN_DIR_CFG);
	KeyValues kv  = new KeyValues("4saken");
	kv.JumpToKey("server", true);
	kv.SetString("ip", "0.0.0.0");
	kv.Rewind();
	kv.ExportToFile(sPatch);
	delete kv;
}

public void OnConfigsExecuted()
{
	if (g_cvarEnableIp.BoolValue)
		GetIpFromIpify();
}

public Action ShowIP(int iClient, int iArgs)
{
	if (iArgs == 0)
	{
		char sBuffer[64];
		_4saken_KvGet("server", "ip", sBuffer, sizeof(sBuffer));
		CReplyToCommand(iClient, "ServerIP: {green}%s{default}:{green}%d{default}", sBuffer, FindConVar("hostport").IntValue);
	}
	else
		CReplyToCommand(iClient, "Usage: sm_4saken_showip");

	return Plugin_Handled;
}

void GetIpFromIpify()
{
	System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, IPIFY_URL);
	httpRequest.SetHeader("Content-Type", "application/json");
	httpRequest.Timeout = 5;
	httpRequest.GET();
	delete httpRequest;
}

void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	char
		url[256],
		content[128];
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

	if (g_cvarDebug.BoolValue)
		_4saken_log("GET IP: %s", content);
}