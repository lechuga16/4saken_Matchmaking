#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <system2>
#include <4saken>
#include <colors>

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

ConVar
	convar_Sub_URL,
	convar_Table_MMR,
	convar_Table_Teams,
	convar_StartingMMR,
	convar_KValue,
	convar_Debug;
Database
	g_Database;
int 
	g_Rating[MAXPLAYERS + 1];
char
	g_Team[MAXPLAYERS + 1][64];
bool
	g_IsTeamGame;
char
	g_TeamName[2][64],
	g_TeamCaptain[2][64];
int
	g_TeamRating[2];

int g_LastSub[MAXPLAYERS + 1] = { -1, ... };

public Plugin myinfo =
{
	name        = "4saken Pugs",
	author      = "Drixevel",
	description = "Manages the 4saken MMR/Teams system.",
	version     = "1.0.1",
	url         = "https://github.com/lechuga16/4saken_Matchmaking"
};

public void OnPluginStart()
{
	LoadTranslation("4saken_mmr.phrases");
	Database.Connect(OnSQLConnect, "4saken");

	convar_Sub_URL     = CreateConVar("sm_4saken_sub_url", "", "HTTP url to send the sub request to.", FCVAR_NOTIFY);
	convar_Table_MMR   = CreateConVar("sm_4saken_table_mmr", "l4d2_mmr", "What should the table name be for player MMR values?", FCVAR_NOTIFY);
	convar_Table_Teams = CreateConVar("sm_4saken_table_teams", "l4d2_teams", "What should the table name be for player teams be?", FCVAR_NOTIFY);
	convar_StartingMMR = CreateConVar("sm_4saken_starting_mmr", "1200", "What MMR should players start with?", FCVAR_NOTIFY, true, 0.0);
	convar_KValue      = CreateConVar("sm_4saken_kvalue", "16.0", "What should the KValue be for calculating player MMR values?", FCVAR_NOTIFY, true, 0.0);
	convar_Debug       = CreateConVar("sm_4saken_debug", "0", "Enable debug mode to see how MMR is being affected.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_end", Event_OnRoundEnd);
	// HookEvent("versus_match_finished", Event_OnVersusFinished);

	RegConsoleCmd("sm_sub", Command_Sub, "Call to the website to find a substitute.");

	RegConsoleCmd("sm_createteam", Command_CreateTeam, "Create a team and invite others to the team.");
	RegConsoleCmd("sm_teaminvite", Command_TeamInvite, "Invite a certain player to your team.");
	RegConsoleCmd("sm_kickfromteam", Command_KickFromTeam, "Kick players from your team.");
	RegConsoleCmd("sm_disband", Command_Disband, "Disband your current team.");

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i))
			OnClientConnected(i);
}

public void OnRoundIsLive()
{
	int[] survivors = new int[4];
	int totalsurvivors;

	int[] infected = new int[4];
	int totalinfected;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if (GetClientTeam(i) == TEAM_SURVIVOR)
			survivors[totalsurvivors++] = i;
		else if (GetClientTeam(i) == TEAM_INFECTED)
			infected[totalinfected++] = i;
	}

	// This is so dumb.
	if (StrEqual(g_Team[survivors[0]], g_Team[survivors[1]]) && StrEqual(g_Team[survivors[1]], g_Team[survivors[2]]) && StrEqual(g_Team[survivors[2]], g_Team[survivors[3]]) && StrEqual(g_Team[infected[0]], g_Team[infected[1]]) && StrEqual(g_Team[infected[1]], g_Team[infected[2]]) && StrEqual(g_Team[infected[2]], g_Team[infected[3]]))
		g_IsTeamGame = true;

	if (g_IsTeamGame)
	{
		char sTable[64];
		convar_Table_Teams.GetString(sTable, sizeof(sTable));

		char sQuery[256];
		g_Database.Format(sQuery, sizeof(sQuery), "SELECT name, captainid, mmr FROM `%s` WHERE name = '%s';", sTable, g_Team[survivors[0]]);
		g_Database.Query(OnParseTeamMMR, sQuery, GetTeamInt(TEAM_SURVIVOR));

		g_Database.Format(sQuery, sizeof(sQuery), "SELECT name, captainid, mmr FROM `%s` WHERE name = '%s';", sTable, g_Team[infected[0]]);
		g_Database.Query(OnParseTeamMMR, sQuery, GetTeamInt(TEAM_INFECTED));
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
	if (db == null)
		ThrowError("Error while connecting to database: %s", error);

	g_Database = db;
	_4saken_log("Connected to database successfully.");

	char sTable[64];
	char sQuery[256];

	convar_Table_MMR.GetString(sTable, sizeof(sTable));
	g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT , `steamid` VARCHAR(64) NOT NULL , `mmr` INT NOT NULL DEFAULT %i, `team` VARCHAR(64) NOT NULL DEFAULT '' , PRIMARY KEY (`id`), UNIQUE (`steamid`)) ENGINE = InnoDB;", sTable, convar_StartingMMR.IntValue);
	g_Database.Query(OnCreateTable, sQuery);

	convar_Table_Teams.GetString(sTable, sizeof(sTable));
	g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT , `name` VARCHAR(64) NOT NULL DEFAULT '', `captainid` VARCHAR(64) NOT NULL DEFAULT '', `mmr` INT NOT NULL DEFAULT %i , PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTable, convar_StartingMMR.IntValue);
	g_Database.Query(OnCreateTable, sQuery);

	char auth[64];
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientAuthorized(i) && GetClientAuthId(i, AuthId_Engine, auth, sizeof(auth)))
			OnClientAuthorized(i, auth);
}

public void OnCreateTable(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while creating table: %s", error);
}

public void OnEndGame()
{
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

		if (GetClientTeam(i) == TEAM_SURVIVOR)
			survivors[totalsurvivors++] = i;
		else if (GetClientTeam(i) == TEAM_INFECTED)
			infected[totalinfected++] = i;
	}

	char sTable[64];
	convar_Table_Teams.GetString(sTable, sizeof(sTable));

	char sQuery[256];
	int  team;

	team = GetTeamInt(TEAM_SURVIVOR);
	g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `%s` SET mmr = '%i' WHERE name = '%s';", sTable, g_TeamRating[team], g_TeamName[team]);
	g_Database.Query(OnUpdateTeamMMR, sQuery, 0);

	team = GetTeamInt(TEAM_INFECTED);
	g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `%s` SET mmr = '%i' WHERE name = '%s';", sTable, g_TeamRating[team], g_TeamName[team]);
	g_Database.Query(OnUpdateTeamMMR, sQuery, 1);
}

/*
public void Event_OnVersusFinished(Event event, const char[] name, bool dontBroadcast)
{
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

		if (GetClientTeam(i) == TEAM_SURVIVOR)
			survivors[totalsurvivors++] = i;
		else if (GetClientTeam(i) == TEAM_INFECTED)
			infected[totalinfected++] = i;
	}

	char sTable[64];
	convar_Table_Teams.GetString(sTable, sizeof(sTable));

	char sQuery[256];
	int  team;

	team = GetTeamInt(TEAM_SURVIVOR);
	g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `%s` SET mmr = '%i' WHERE name = '%s';", sTable, g_TeamRating[team], g_TeamName[team]);
	g_Database.Query(OnUpdateTeamMMR, sQuery, 0);

	team = GetTeamInt(TEAM_INFECTED);
	g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `%s` SET mmr = '%i' WHERE name = '%s';", sTable, g_TeamRating[team], g_TeamName[team]);
	g_Database.Query(OnUpdateTeamMMR, sQuery, 1);
}
*/

public void OnUpdateTeamMMR(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while updating team MMR: %s", error);
}

public void OnClientConnected(int client)
{
	g_Rating[client]  = convar_StartingMMR.IntValue;
	g_Team[client][0] = '\0';
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsFakeClient(client) || g_Database == null)
		return;

	char sTable[64];
	convar_Table_MMR.GetString(sTable, sizeof(sTable));

	char sSteamID[64];
	if (!GetClientAuthId(client, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
		return;

	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "SELECT mmr, team FROM `%s` WHERE steamid = '%s';", sTable, sSteamID);
	g_Database.Query(OnParseMMR, sQuery, GetClientUserId(client));
}

public void OnParseMMR(Database db, DBResultSet results, const char[] error, any data)
{
	int client;
	if ((client = GetClientOfUserId(data)) == 0)
		return;

	if (results == null)
		ThrowError("Error while parsing player MMR: %s", error);

	if (results.FetchRow())
	{
		g_Rating[client] = results.FetchInt(0);
		results.FetchString(1, g_Team[client], 64);
	}
	else
		SaveData(client);
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
		return;

	SaveData(client);
}

void SaveData(int client)
{
	if (g_Database == null)
		return;

	char sTable[64];
	convar_Table_MMR.GetString(sTable, sizeof(sTable));

	char sSteamID[64];
	if (!GetClientAuthId(client, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
		return;

	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (steamid, mmr, team) VALUES ('%s', '%i', '%s') ON DUPLICATE KEY UPDATE mmr = '%i', team = '%s';", sTable, sSteamID, g_Rating[client], g_Team[client], g_Rating[client], g_Team[client]);
	g_Database.Query(OnSaveMMR, sQuery);
}

public void OnSaveMMR(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while saving player MMR on disconnect: %s", error);
}

public void OnClientDisconnect_Post(int client)
{
	g_Rating[client]  = convar_StartingMMR.IntValue;
	g_Team[client][0] = '\0';
	g_LastSub[client] = -1;
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int  victim        = GetClientOfUserId(event.GetInt("userid"));
	int  attacker      = GetClientOfUserId(event.GetInt("attacker"));
	bool attackerisbot = event.GetBool("attackerisbot");
	bool victimisbot   = event.GetBool("victimisbot");

	if (victim < 1 || victim > MaxClients || victimisbot)
		return;

	if (attacker < 1 || attacker > MaxClients || attackerisbot)
		return;

	int team_victim = GetClientTeam(victim);
	if (team_victim != TEAM_INFECTED)
		return;

	int team_attacker = GetClientTeam(attacker);
	if (team_attacker != TEAM_SURVIVOR)
		return;

	int difference = RoundFloat(convar_KValue.FloatValue * (1 - (1 / (Pow(10.0, float((g_Rating[victim] - g_Rating[attacker])) / 400) + 1))));

	g_Rating[victim] -= difference;
	g_Rating[attacker] += difference;

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

	if (convar_Debug.BoolValue)
	{
		CPrintToChat(victim, "MMR Update: %i [Difference: %i]", g_Rating[victim], difference);
		CPrintToChat(attacker, "MMR Update: %i [Difference: %i]", g_Rating[attacker], difference);
	}
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_Database == null)
		return;

	char sTable[64];
	convar_Table_MMR.GetString(sTable, sizeof(sTable));

	char sSteamID[64];
	char sQuery[256];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if (!GetClientAuthId(i, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
			continue;

		g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (steamid, mmr, team) VALUES ('%s', '%i', '%s') ON DUPLICATE KEY UPDATE mmr = '%i', team = '%s';", sTable, sSteamID, g_Rating[i], g_Team[i], g_Rating[i], g_Team[i]);
		g_Database.Query(OnUpdateMMR, sQuery);
	}
	
}

public void OnUpdateMMR(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while saving player MMR on round end: %s", error);
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
	convar_Sub_URL.GetString(sURL, sizeof(sURL));

	if (strlen(sURL) == 0)
	{
		ReplyToCommand(client, "Unknown error while sending a sub request, please contact an administrator.");
		return Plugin_Handled;
	}

	System2_URLEncode(sURL, sizeof(sURL), sURL);

	char sIP[64];
	// This function does not allow to recover domains.
	// GetServerIP(sIP, sizeof(sIP), true);
	if(!_4saken_KvGet("server", "ip", sIP, sizeof(sIP)))
		sIP = "No_IP";

	char sSub[256];
	FormatEx(sSub, sizeof(sSub), "%N has requested a sub on server: %s:%d", client, sIP, FindConVar("hostport").IntValue);

	System2HTTPRequest httpRequest = new System2HTTPRequest(Http_OnSendSubRequest, sURL);
	httpRequest.SetData("sub=%s", sSub);
	httpRequest.POST();

	ReplyToCommand(client, "Sub request has been sent.");

	return Plugin_Handled;
}

/*
void GetServerIP(char[] buffer, int size, bool showport = false)
{
	int ip = FindConVar("hostip").IntValue;

	int ips[4];
	ips[0] = (ip >> 24) & 0x000000FF;
	ips[1] = (ip >> 16) & 0x000000FF;
	ips[2] = (ip >> 8) & 0x000000FF;
	ips[3] = ip & 0x000000FF;

	Format(buffer, size, "%d.%d.%d.%d", ips[0], ips[1], ips[2], ips[3]);

	if (showport)
		Format(buffer, size, "%s:%d", buffer, FindConVar("hostport").IntValue);
}
*/

public void Http_OnSendSubRequest(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	if (!success)
		ThrowError("Error while sending sub: %s", error);

	char sURL[128];
	response.GetLastURL(sURL, sizeof(sURL));

	PrintToServer("Request to %s finished with status code %d in %.2f seconds.", sURL, response.StatusCode, response.TotalTime);
}

public Action Command_CreateTeam(int client, int args)
{
	if (args == 0)
	{
		char sCommand[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		CReplyToCommand(client, "[SM] Usage: %s <name>", sCommand);
		return Plugin_Handled;
	}

	if (strlen(g_Team[client]) > 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "LeaveToStart");
		return Plugin_Handled;
	}

	char sSteamID[64];
	if (!GetClientAuthId(client, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
	{
		CPrintToChat(client, "%t %t", "Tag", "NoSteam");
		return Plugin_Handled;
	}

	char sTable[256];
	convar_Table_Teams.GetString(sTable, sizeof(sTable));

	char sName[64];
	GetCmdArgString(sName, sizeof(sName));

	// Escape the string so players can't use exploits with the name.
	int size            = 2 * strlen(sName) + 1;
	char[] sEscapedName = new char[size];
	g_Database.Escape(sName, sEscapedName, size);

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(size);
	pack.WriteString(sEscapedName);
	pack.WriteString(sSteamID);

	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "SELECT name FROM `%s` WHERE name = '%s';", sTable, sEscapedName);
	g_Database.Query(OnCheckTeamName, sQuery, pack);

	return Plugin_Handled;
}

public void OnCheckTeamName(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();

	int userid = pack.ReadCell();
	int size   = pack.ReadCell();

	char[] sEscapedName = new char[size];
	pack.ReadString(sEscapedName, size);

	char sSteamID[64];
	pack.ReadString(sSteamID, sizeof(sSteamID));

	int client;
	if ((client = GetClientOfUserId(userid)) == 0 || !IsClientInGame(client))
	{
		delete pack;
		return;
	}

	if (results == null)
	{
		delete pack;
		CPrintToChat(client, "%t %t", "Tag", "Error_CreatingTeam");
		ThrowError("Error while checking team name: %s", error);
	}

	if (results.RowCount > 0)
	{
		delete pack;
		CPrintToChat(client, "%t %t", "Tag", "CurrentlyTaken", sEscapedName);
		return;
	}

	char sTable[256];
	convar_Table_Teams.GetString(sTable, sizeof(sTable));

	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (name, captainid, mmr) VALUES ('%s', '%s', '%i');", sTable, sEscapedName, sSteamID, convar_StartingMMR.IntValue);
	g_Database.Query(OnCreateTeam, sQuery, pack);
}

public void OnCreateTeam(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();

	int userid = pack.ReadCell();
	int size   = pack.ReadCell();

	char[] sEscapedName = new char[size];
	pack.ReadString(sEscapedName, size);

	char sSteamID[64];
	pack.ReadString(sSteamID, sizeof(sSteamID));

	delete pack;

	int client;
	if ((client = GetClientOfUserId(userid)) == 0 || !IsClientInGame(client))
		return;

	if (results == null)
	{
		CPrintToChat(client, "%t %t", "Tag", "Error_CreatingTeam2");
		ThrowError("Error while creating team: %s", error);
	}

	strcopy(g_Team[client], sizeof(g_Team[]), sEscapedName);
	CPrintToChat(client, "%t %t", "Tag", "StartedTeam", sEscapedName);

	SaveData(client);
}

public Action Command_TeamInvite(int client, int args)
{
	if (args == 0)
	{
		char sCommand[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		CReplyToCommand(client, "[SM] Usage: %s <target>", sCommand);
		return Plugin_Handled;
	}

	if (strlen(g_Team[client]) == 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "NoPartTeam");
		return Plugin_Handled;
	}

	if (!IsTeamCaptain(client))
	{
		CPrintToChat(client, "%t %t", "Tag", "NoCaptain");
		return Plugin_Handled;
	}

	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArgString(sTarget, sizeof(sTarget));

	int target = FindTarget(client, sTarget, true, false);

	if (target < 1)
	{
		CPrintToChat(client, "%t %t", "Tag", "TargetNotFound", sTarget);
		return Plugin_Handled;
	}

	if (strlen(g_Team[target]) > 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "TargetReady", target);
		return Plugin_Handled;
	}

	SendTeamInvite(client, target);

	return Plugin_Handled;
}

void SendTeamInvite(int client, int target)
{
	char
		sMenuTitle[64],
		sMenuYes[4],
		sMenuNo[4];
	Menu menu = new Menu(MenuHandler_TeamInvite);

	Format(sMenuTitle, sizeof sMenuTitle, "%t", "MenuTitle_Invite");
	menu.SetTitle(sMenuTitle, client, g_Team[client]);

	Format(sMenuYes, sizeof sMenuYes, "%t", "Menu_Yes");
	menu.AddItem("yes", sMenuYes);
	Format(sMenuNo, sizeof sMenuNo, "%t", "Menu_No");
	menu.AddItem("no", sMenuNo);

	PushMenuInt(menu, "client", GetClientUserId(client));
	PushMenuString(menu, "team", g_Team[client]);

	menu.Display(target, MENU_TIME_FOREVER);
}

public int MenuHandler_TeamInvite(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			int client = GetClientOfUserId(GetMenuInt(menu, "client"));

			char sTeam[64];
			GetMenuString(menu, "team", sTeam, sizeof(sTeam));

			if (StrEqual(sInfo, "yes"))
			{
				if (client > 0)
					CPrintToChat(client, "%t %t", "Tag", "JoinedTeam", param1);

				SetPlayerTeam(param1, sTeam);
			}
			else
			{
				if (client > 0)
					CPrintToChat(client, "%t %t", "Tag", "DeclinedTeam", param1);

				CPrintToChat(param1, "%t %t", "Tag", "YouDeclinedTeam", sTeam);
			}
		}

		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void SetPlayerTeam(int client, const char[] team)
{
	char sTable[64];
	convar_Table_MMR.GetString(sTable, sizeof(sTable));

	char sSteamID[64];
	if (!GetClientAuthId(client, AuthId_SteamID64, sSteamID, sizeof(sSteamID)))
		return;

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteString(team);

	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `%s` SET team = '%s' WHERE steamid = '%s';", sTable, team, sSteamID);
	g_Database.Query(OnJoinTeam, sQuery, pack);
}

public void OnJoinTeam(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();

	int userid = pack.ReadCell();

	char sTeam[64];
	pack.ReadString(sTeam, sizeof(sTeam));

	delete pack;

	int client;
	if ((client = GetClientOfUserId(userid)) == 0)
		return;

	if (results == null)
		ThrowError("Error while player joining team: %s", error);

	strcopy(g_Team[client], 64, sTeam);

	if (strlen(sTeam) > 0)
		CPrintToChat(client, "%t %t", "Tag", "YouJoinedTeam", sTeam);
	else
		CPrintToChat(client, "%t %t", "Tag", "YouNoJoinedTeam");
}

stock bool PushMenuInt(Menu menu, const char[] id, int value)
{
	char sBuffer[128];
	IntToString(value, sBuffer, sizeof(sBuffer));
	return menu.AddItem(id, sBuffer, ITEMDRAW_IGNORE);
}

stock int GetMenuInt(Menu menu, const char[] id, int defaultvalue = 0)
{
	char info[128];
	char data[128];
	for (int i = 0; i < menu.ItemCount; i++)
		if (menu.GetItem(i, info, sizeof(info), _, data, sizeof(data)) && StrEqual(info, id))
			return StringToInt(data);

	return defaultvalue;
}

stock bool PushMenuString(Menu menu, const char[] id, const char[] value)
{
	return menu.AddItem(id, value, ITEMDRAW_IGNORE);
}

stock bool GetMenuString(Menu menu, const char[] id, char[] buffer, int size)
{
	char info[128];
	char data[8192];
	for (int i = 0; i < menu.ItemCount; i++)
	{
		if (menu.GetItem(i, info, sizeof(info), _, data, sizeof(data)) && StrEqual(info, id))
		{
			strcopy(buffer, size, data);
			return true;
		}
	}

	return false;
}

public Action Command_KickFromTeam(int client, int args)
{
	if (args == 0)
	{
		char sCommand[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		CReplyToCommand(client, "[SM] Usage: %s <target>", sCommand);
		return Plugin_Handled;
	}

	if (strlen(g_Team[client]) == 0)
	{
		CPrintToChat(client, "You aren't part of a team to kick players from.");
		return Plugin_Handled;
	}

	if (!IsTeamCaptain(client))
	{
		CPrintToChat(client, "You aren't the team captain, you can't kick players.");
		return Plugin_Handled;
	}

	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArgString(sTarget, sizeof(sTarget));

	int target = FindTarget(client, sTarget, true, false);

	if (target < 1)
	{
		CPrintToChat(client, "Target %s not found, please try again.", sTarget);
		return Plugin_Handled;
	}

	if (client == target)
	{
		CPrintToChat(client, "You aren't allowed to kick yourself from your own team, please disband it.");
		return Plugin_Handled;
	}

	if (strlen(g_Team[target]) == 0)
	{
		CPrintToChat(client, "Target %N is not a part of a team currently.", target);
		return Plugin_Handled;
	}

	if (!StrEqual(g_Team[client], g_Team[target], false))
	{
		CPrintToChat(client, "Target %N is not a part of the same team as you.", target);
		return Plugin_Handled;
	}

	ConfirmKickMenu(client, target);

	return Plugin_Handled;
}

void ConfirmKickMenu(int client, int target)
{
	Menu menu = new Menu(MenuHandler_KickTeammate);
	menu.SetTitle("Are you sure you want to kick %N from %s?", target, g_Team[client]);

	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");

	PushMenuInt(menu, "target", GetClientUserId(target));
	PushMenuString(menu, "team", g_Team[client]);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_KickTeammate(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			int target = GetClientOfUserId(GetMenuInt(menu, "target"));

			char sTeam[64];
			GetMenuString(menu, "team", sTeam, sizeof(sTeam));

			if (StrEqual(sInfo, "yes"))
			{
				if (target > 0)
					CPrintToChat(target, "%N has kicked you from the team.", param1);

				CPrintToChat(param1, "%N has been kicked from the team.", target);
				SetPlayerTeam(target, "");
			}
			else
				CPrintToChat(param1, "%N hasn't been kicked from the team.", target);
		}

		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public Action Command_Disband(int client, int args)
{
	if (strlen(g_Team[client]) == 0)
	{
		CPrintToChat(client, "You aren't a part of a team to disband.");
		return Plugin_Handled;
	}

	if (!IsTeamCaptain(client))
	{
		CPrintToChat(client, "You aren't the team captain, you can't disband your team.");
		return Plugin_Handled;
	}

	ConfirmDisbandTeam(client);

	return Plugin_Handled;
}

void ConfirmDisbandTeam(int client)
{
	Menu menu = new Menu(MenuHandler_DisbandTeam);
	menu.SetTitle("Are you sure you want to disband your team?");

	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_DisbandTeam(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			if (StrEqual(sInfo, "yes", false))
			{
				CPrintToChat(param1, "Disbanding your team...");
				DisbandTeam(g_Team[param1]);
			}
			else
				CPrintToChat(param1, "Your team hasn't been disbanded.");
		}

		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void DisbandTeam(const char[] team)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (StrEqual(g_Team[i], team, false))
		{
			CPrintToChat(i, "Your team has been disbanded.");
			SetPlayerTeam(i, "");
		}
	}

	char sTable[64];
	convar_Table_Teams.GetString(sTable, sizeof(sTable));

	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "DELETE FROM `%s` WHERE name = '%s';", sTable, team);
	g_Database.Query(OnDeleteTeam, sQuery);
}

public void OnDeleteTeam(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while deleting team: %s", error);
}

bool IsTeamCaptain(int client)
{
	int team;

	team = GetTeamInt(TEAM_SURVIVOR);
	if (StrEqual(g_Team[client], g_TeamCaptain[team]))
		return true;

	team = GetTeamInt(TEAM_INFECTED);
	if (StrEqual(g_Team[client], g_TeamCaptain[team]))
		return true;

	return false;
}

int GetTeamInt(int team)
{
	return team - 2;
}