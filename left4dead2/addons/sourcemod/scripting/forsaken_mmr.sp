#pragma semicolon 1
#pragma newdecls required

#include <forsaken>
#include <colors>
#include <sourcemod>
#include <system2>
#undef REQUIRE_PLUGIN
#include <readyup>

ConVar
	g_cvarSub_URL,
	// g_cvarStartingMMR,
	g_cvarKValue,
	g_cvarDebug,
	g_cvarEnable;
Database
	g_Database;
int
	g_iRating[MAXPLAYERS + 1],
	g_iTeam[MAXPLAYERS + 1];
char
	g_sTeam[MAXPLAYERS + 1][64];
bool
	g_IsTeamGame = false;
char
	g_TeamName[2][64],
	g_TeamCaptain[2][64],
	g_sIp[64];
int
	g_TeamRating[2];

int g_LastSub[MAXPLAYERS + 1] = { -1, ... };

public Plugin myinfo =
{
	name        = "Forsaken MMR",
	author      = "Drixevel",
	description = "Manages the 4saken MMR/Teams system.",
	version     = "1.0.1",
	url         = "https://github.com/lechuga16/4saken_Matchmaking"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!L4D_IsEngineLeft4Dead2())
	{
		strcopy(error, err_max, "Plugin only support L4D2 engine");
	}

	g_sIp = Forsaken_GetIP();
	if (StrEqual(g_sIp, "0.0.0.0", false))
	{
		strcopy(error, err_max, "ERROR: The server ip was not configured");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("forsaken_mmr.phrases");
	Database.Connect(OnSQLConnect, "4saken");

	g_cvarDebug   = CreateConVar("sm_mmr_debug", "0", "Debug messages.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarEnable  = CreateConVar("sm_mmr_enable", "1", "Activate mmr registration", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSub_URL = CreateConVar("sm_mmr_suburl", "", "HTTP url to send the sub request to.", FCVAR_NOTIFY);
	g_cvarKValue  = CreateConVar("sm_mmr_kvalue", "16.0", "What should the KValue be for calculating player MMR values?", FCVAR_NOTIFY, true, 0.0);

	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_end", Event_OnRoundEnd);

	RegConsoleCmd("sm_sub", Command_Sub, "Call to the website to find a substitute.");
	RegConsoleCmd("sm_mmr", Command_MMR, "get mmr.");

	AutoExecConfig(true, "forsaken_mmr");
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i))
			OnClientConnected(i);
}

public void OnRoundIsLive()
{
	if (!g_cvarEnable.BoolValue)
		return;

	int[] survivors = new int[4];
	int totalsurvivors;

	int[] infected = new int[4];
	int totalinfected;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		switch (L4D_GetClientTeam(i))
		{
			case L4DTeam_Survivor:
				survivors[totalsurvivors++] = i;
			case L4DTeam_Infected:
				infected[totalinfected++] = i;
		}

		if (g_IsTeamGame)
		{
			char sQuery[256];
			g_Database.Format(sQuery, sizeof(sQuery), "SELECT name, captainid, mmr FROM `mmr_team` WHERE name = '%s';", g_sTeam[survivors[0]]);
			g_Database.Query(OnParseTeamMMR, sQuery, GetTeamInt(L4DTeam_Survivor));

			g_Database.Format(sQuery, sizeof(sQuery), "SELECT name, captainid, mmr FROM `mmr_team` WHERE name = '%s';", g_sTeam[infected[0]]);
			g_Database.Query(OnParseTeamMMR, sQuery, GetTeamInt(L4DTeam_Infected));
		}
	}
}

public void OnParseTeamMMR(Database db, DBResultSet results, const char[] error, any team)
{
	if (results == null)
	{
		g_IsTeamGame = false;
		ThrowError("Error while parsing team MMR: %s", error);
	}

	if (results.FetchRow())
	{
		results.FetchString(0, g_TeamName[team], 64);
		results.FetchString(1, g_TeamCaptain[team], 64);
		g_TeamRating[team] = results.FetchInt(2);
	}
}

public void OnSQLConnect(Database db, const char[] error, any data)
{
	if (!g_cvarEnable.BoolValue)
		return;
	if (db == null)
		ThrowError("Error while connecting to database: %s", error);

	g_Database = db;
	if (g_cvarDebug.BoolValue)
		Forsaken_log("Connected to database successfully.");

	char auth[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientAuthorized(i) && GetClientAuthId(i, AuthId_Engine, auth, sizeof(auth)))
			OnClientAuthorized(i, auth);
	}
}

public void OnEndGame()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (!g_IsTeamGame)
		return;

	int[] survivors = new int[4];
	int totalsurvivors;

	int[] infected = new int[4];
	int totalinfected;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if (L4D_GetClientTeam(i) == L4DTeam_Survivor)
			survivors[totalsurvivors++] = i;
		else if (L4D_GetClientTeam(i) == L4DTeam_Infected)
			infected[totalinfected++] = i;
	}

	char sQuery[256];
	int  team;

	team = GetTeamInt(L4DTeam_Survivor);
	g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `mmr_team` SET mmr = '%i' WHERE name = '%s';", g_TeamRating[team], g_TeamName[team]);
	g_Database.Query(OnUpdateTeamMMR, sQuery, 0);

	team = GetTeamInt(L4DTeam_Infected);
	g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `mmr_team` SET mmr = '%i' WHERE name = '%s';", g_TeamRating[team], g_TeamName[team]);
	g_Database.Query(OnUpdateTeamMMR, sQuery, 1);
}

public void OnUpdateTeamMMR(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while updating team MMR: %s", error);
}

public void OnClientConnected(int client)
{
	g_sTeam[client][0] = '\0';
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsFakeClient(client) || g_Database == null)
		return;

	char sSteamID[64];
	if (!GetClientAuthId(client, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
		return;

	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "SELECT u.mmr, u.team FROM `l4d2_users` AS u WHERE `steamid` = '%s';", sSteamID);
	g_Database.Query(OnParseMMR, sQuery, GetClientUserId(client));

	if (!g_IsTeamGame)
		return;

	char sQueryTeam[256];
	g_Database.Format(sQueryTeam, sizeof(sQueryTeam), "SELECT t.mmr FROM `l4d2_teams` AS t WHERE `id` = '%s';", g_iTeam[client]);
	g_Database.Query(OnParseTeam, sQueryTeam, GetClientUserId(client));
}

public void OnParseMMR(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	if (client == CONSOLE)
		return;

	if (results == null)
		ThrowError("Error while parsing player MMR: %s", error);

	if (results.FetchRow())
	{
		g_iRating[client] = results.FetchInt(0);
		g_iTeam[client] = results.FetchInt(1);
	}
}

public void OnParseTeam(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	if (client == CONSOLE)
		return;

	if (results == null)
		ThrowError("Error while parsing Team: %s", error);

	if (results.FetchRow())
		g_iTeam[client] = results.FetchInt(0);
}

public void OnSaveMMR(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while saving player MMR on disconnect: %s", error);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvarEnable.BoolValue)
		return;

	int  victim        = GetClientOfUserId(event.GetInt("userid"));
	int  attacker      = GetClientOfUserId(event.GetInt("attacker"));
	bool attackerisbot = event.GetBool("attackerisbot");
	bool victimisbot   = event.GetBool("victimisbot");

	if (victim < 1 || victim > MaxClients || victimisbot)
		return;

	if (attacker < 1 || attacker > MaxClients || attackerisbot)
		return;

	L4DTeam team_victim = L4D_GetClientTeam(victim);
	if (team_victim != L4DTeam_Infected)
		return;

	L4DTeam team_attacker = L4D_GetClientTeam(attacker);
	if (team_attacker != L4DTeam_Survivor)
		return;

	int difference = RoundFloat(g_cvarKValue.FloatValue * (1 - (1 / (Pow(10.0, float((g_iRating[victim] - g_iRating[attacker])) / 400) + 1))));

	g_iRating[victim] -= difference;
	g_iRating[attacker] += difference;

	if (g_IsTeamGame)
	{
		int team;

		team = GetTeamInt(team_victim);
		if (g_TeamRating[team] != -1)
			g_TeamRating[team] -= difference;

		team = GetTeamInt(team_attacker);
		if (g_TeamRating[team] != -1)
			g_TeamRating[team] += difference;
	}

	if (g_cvarDebug.BoolValue)
	{
		CPrintToChat(victim, "MMR Update: %i [Difference: %i]", g_iRating[victim], difference);
		CPrintToChat(attacker, "MMR Update: %i [Difference: %i]", g_iRating[attacker], difference);
	}
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (g_Database == null)
		return;

	char sSteamID[64];
	char sQuery[256];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if (!GetClientAuthId(i, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
			continue;

		g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `l4d2_users` SET `mmr`= '%i' WHERE `steamid` = '%s';", g_iRating[i], sSteamID);
		g_Database.Query(OnUpdateMMR, sQuery);
	}
}

public void OnUpdateMMR(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while saving %s MMR on round end: %s", g_IsTeamGame ? "team" : "player", error);
}

public Action Command_Sub(int client, int args)
{
	int time = GetTime();

	if (g_LastSub[client] != -1 && g_LastSub[client] > time)
	{
		ReplyToCommand(client, "You must wait a bit to send another sub request.");
		return Plugin_Handled;
	}

	g_LastSub[client] = time + 60;

	char sURL[256];
	g_cvarSub_URL.GetString(sURL, sizeof(sURL));

	if (strlen(sURL) == 0)
	{
		ReplyToCommand(client, "Unknown error while sending a sub request, please contact an administrator.");
		return Plugin_Handled;
	}

	System2_URLEncode(sURL, sizeof(sURL), sURL);

	char sSub[256];
	FormatEx(sSub, sizeof(sSub), "%N has requested a sub on server: %s:%d", client, g_sIp, FindConVar("hostport").IntValue);

	System2HTTPRequest httpRequest = new System2HTTPRequest(Http_OnSendSubRequest, sURL);
	httpRequest.SetData("sub=%s", sSub);
	httpRequest.POST();

	ReplyToCommand(client, "Sub request has been sent.");

	return Plugin_Handled;
}

public void Http_OnSendSubRequest(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	if (!success)
		ThrowError("Error while sending sub: %s", error);

	char sURL[128];
	response.GetLastURL(sURL, sizeof(sURL));

	PrintToServer("Request to %s finished with status code %d in %.2f seconds.", sURL, response.StatusCode, response.TotalTime);
}

public Action Command_MMR(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		char sCommand[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		CReplyToCommand(iClient, "[SM] Usage: %s", sCommand);
		return Plugin_Handled;
	}
	CReplyToCommand(iClient, "You mmr: %d ", g_iRating[iClient]);
	return Plugin_Continue;
}

int GetTeamInt(L4DTeam team)
{
	return view_as<int>(team) - 2;
}