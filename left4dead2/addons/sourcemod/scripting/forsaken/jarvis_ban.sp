#if defined _jarvis_ban_included
	#endinput
#endif
#define _jarvis_ban_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

int iServerID = 0;

char
	DatabasePrefix[10] = "sb",
	WebsiteAddress[128];

enum State
{
	ConfigStateNone = 0,
	ConfigStateConfig,
	ConfigStateReasons,
	ConfigStateHacking,
	ConfigStateTime
}

State	  ConfigState;
SMCParser ConfigParser;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public void OnPluginStart_Bans()
{
	LoadTranslation("common.phrases");
	RegAdminCmd("sm_jarvis_countbans", Cmd_CountBans, ADMFLAG_ROOT, "Count of bans according to client");
	RegAdminCmd("sm_jarvis_bantest", Cmd_BanTest, ADMFLAG_ROOT, "Perform a test ban, the client must be on the matchmaking list");
}

public Action Cmd_CountBans(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		CReplyToCommand(iClient, "[4saken] Usage: sm_jarvis_countbans <1:RQ|2:Desertion|3:Readyup> <#userid|name>");
		return Plugin_Handled;
	}

	int iCmdArg1 = GetCmdArgInt(1);
	if(iCmdArg1 < 1 || iCmdArg1 > 3)
	{
		CReplyToCommand(iClient, "[4saken] Usage: <1:RQ|2:Desertion|3:Readyup>");
		return Plugin_Handled;
	}

	char sCmdArg2[16];
	GetCmdArg(2, sCmdArg2, sizeof(sCmdArg2));
	int iCountBans;

	int[] iTargetList = new int[MaxClients+1];
	int iTargetCount;
	char sTargetName[MAX_TARGET_LENGTH];
	bool tn_is_ml;

	if ((iTargetCount = ProcessTargetString(sCmdArg2, iClient, iTargetList, MaxClients+1, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), tn_is_ml)) > 0)
	{
		for (int i = 0; i < iTargetCount; i++)
		{
			iCountBans = ClientBansAccount(iTargetList[i], sTypeBans[view_as<TypeBans>(iCmdArg1)]);
			if(iCountBans == 0)
				CReplyToCommand(iClient, "%t %t", "Tag", "NoBans", iTargetList[i]);
			else
				CReplyToCommand(iClient, "%t %t", "Tag", "CountBans", iCountBans, (iCountBans > 1) ? "s": "", iTargetList[i]);
		}
	}
	else
	{
		if(iClient == CONSOLE)
			return Plugin_Handled;

		iCountBans = ClientBansAccount(iClient, sTypeBans[view_as<TypeBans>(iCmdArg1)]);
		if(iCountBans == 0)
			CReplyToCommand(iClient, "%t %t", "Tag", "NoBans", iClient);
		else
			CReplyToCommand(iClient, "%t %t", "Tag", "CountBans", iCountBans, (iCountBans > 1) ? "s": "", iClient);
	}

	return Plugin_Handled;
}

public Action Cmd_BanTest(int iClient, int iArgs)
{
	if(iArgs != 1)
	{
		CReplyToCommand(iClient, "[4saken] Usage: sm_jarvis_bantest <SteamID64>");
		return Plugin_Handled;
	}

	char sCmdArg1[MAX_AUTHID_LENGTH];
	GetCmdArg(1, sCmdArg1, MAX_AUTHID_LENGTH); 

	for(int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if(StrEqual(g_Players[TeamA][iID].steamid, sCmdArg1, false))
			CreateOffLineBan(iID, TeamA, 1, "%t", "BanReasonTest");
		else if(StrEqual(g_Players[TeamB][iID].steamid, sCmdArg1, false))
			CreateOffLineBan(iID, TeamB, 1, "%t", "BanReasonTest");

		if(iID == 0 && g_TypeMatch == duel)
			break;
	}

	return Plugin_Handled;
}

/*****************************************************************
			N A T I V E S
*****************************************************************/

// OffLineBan(int iTarget, int Team, int iTime, const char[] sReason, any ...)
any Native_ForsakenBan(Handle plugin, int numParams)
{
	int
		iTarget = GetNativeCell(1),
		Team	= GetNativeCell(2),
		iTime	= GetNativeCell(3);

	char sReason[PLATFORM_MAX_PATH];
	FormatNativeString(0, 4, 5, sizeof(sReason), _, sReason);
	CreateOffLineBan(iTarget, view_as<ForsakenTeam>(Team), iTime, sReason);
	return 0;
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

/**
 * @brief Read the sourcebans.cfg file
 *
 * @noreturn
 */
stock void ReadConfigSourcebans()
{
	InitializeConfigParser();

	if (ConfigParser == null)
		return;

	char ConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigFile, sizeof(ConfigFile), "configs/sourcebans/sourcebans.cfg");

	if (FileExists(ConfigFile))
	{
		InternalReadConfig(ConfigFile);
		if (g_cvarDebug.BoolValue)
			PrintToServer("%s Loading configs/sourcebans.cfg config file", JVPrefix);
	}
	else
	{
		char Error[PLATFORM_MAX_PATH + 64];
		FormatEx(Error, sizeof(Error), "%s FATAL *** ERROR *** can not find %s", JVPrefix, ConfigFile);
		fkn_log(false, "FATAL *** ERROR *** can not find %s", ConfigFile);
		SetFailState(Error);
	}
}

/**
 * @brief Initializes the config parser
 *
 * @noreturn
 */
static void InitializeConfigParser()
{
	if (ConfigParser == null)
	{
		ConfigParser			= new SMCParser();
		ConfigParser.OnKeyValue = ReadConfig_KeyValue;
	}
}

/**
 * @brief Reads the config file
 *
 * @param path			Config file path
 * @noreturn
 */
static void InternalReadConfig(const char[] path)
{
	ConfigState	 = ConfigStateNone;

	SMCError err = ConfigParser.ParseFile(path);

	if (err != SMCError_Okay)
	{
		char buffer[64];
		PrintToServer("%s", ConfigParser.GetErrorString(err, buffer, sizeof(buffer)) ? buffer : "Fatal parse error");
	}
}

/**
 * @brief Reads the config file
 *
 * @param smc			SMC parser
 * @param key			Key
 * @param value			Value
 * @param key_quotes	True if the key is quoted
 * @param value_quotes	True if the value is quoted
 *
 * @return				True on success, false otherwise
 */
public SMCResult ReadConfig_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (!key[0])
		return SMCParse_Continue;

	switch (ConfigState)
	{
		case ConfigStateConfig:
		{
			if (strcmp("website", key, false) == 0)
			{
				strcopy(WebsiteAddress, sizeof(WebsiteAddress), value);
			}
			else if (strcmp("DatabasePrefix", key, false) == 0)
			{
				strcopy(DatabasePrefix, sizeof(DatabasePrefix), value);

				if (DatabasePrefix[0] == '\0')
				{
					DatabasePrefix = "sb";
				}
			}
			else if (strcmp("ServerID", key, false) == 0)
			{
				iServerID = StringToInt(value);
			}
		}
	}
	return SMCParse_Continue;
}

/**
 * @brief Creates a ban for a player that is not online
 *
 * @param iTarget		Target's index
 * @param Team			Target's team
 * @param iTime			Ban time
 * @param sReason		Ban reason
 * @param ...			Additional data
 *
 * @return				True on success, false otherwise
 */
public bool CreateOffLineBan(int iTarget, ForsakenTeam Team, int iTime, const char[] sReason, any...)
{
	Database  hSourceBans = Connect(); 
	if (hSourceBans == null)
	{
		fkn_log(true, "Could not connect to database (null)");
		return false;
	}

	// server information
	char
		sAdminIp[24]   = "",
		sAdminAuth[64] = "STEAM_ID_SERVER";

	fkn_GetIPv4(sAdminIp, sizeof(sAdminIp));

	// iTarget information
	char
		sIp[32] = "",
		sAuth[64],
		sName[MAX_NAME_LENGTH];

	char sFormatReason[512];
	VFormat(sFormatReason, sizeof(sFormatReason), sReason, 5);

	if (Team == TeamA)
	{
		sAuth = g_Players[TeamA][iTarget].steamid;
		sName = g_Players[TeamA][iTarget].name;
	}
	else if (Team == TeamB)
	{
		sAuth = g_Players[TeamB][iTarget].steamid;
		sName = g_Players[TeamB][iTarget].name;
	}
	else
	{
		fkn_log(false, "CreateOffLineBan: Team is invalid");
		CPrintToChatAll("%t %T", "Tag", "BanFail", LANG_SERVER, "ForsakenTeam is invalid");
		return false;
	}

	if (StrEqual("", sAuth, false))
	{
		fkn_log(false, "CreateOffLineBan: SteamID is invalid");
		CPrintToChatAll("%t %T", "Tag", "BanFail", LANG_SERVER, "SteamID is invalid");
		return false;
	}

	if ((StrContains("STEAM_", sAuth, true) == -1))
	{
		int iSteamID64[2];
		if ((StringToInt64(sAuth, iSteamID64)) == 0)
			fkn_log(false, "SteamId StringToInt failed");
		GetSteam2FromAccountId(sAuth, sizeof(sAuth), iSteamID64[0]);
	}

	if (StrEqual("", sName, false))
	{
		fkn_log(false, "CreateOffLineBan: %s sName is invalid", sAuth);
		sName = "Unknown";
	}

	// Pack everything into a data pack so we can retain it
	DataPack dataPack = new DataPack();

	dataPack.WriteCell(iTime);
	dataPack.WriteString(sFormatReason);
	dataPack.WriteString(sName);

	char
		sQuery[1024],
		sBufferReason[128];

	Format(sBufferReason, sizeof(sBufferReason), "%s %s.", JVPrefix, sFormatReason);

	hSourceBans.Format(sQuery, sizeof(sQuery), "INSERT INTO %s_bans \
 			(ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES \
 			('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', IFNULL((SELECT aid FROM %s_admins WHERE authid = '%s' OR authid REGEXP '^STEAM_[0-9]: %s$'), '0'), '%s', %d, ' ')",
			 DatabasePrefix, sIp, sAuth, sName, (iTime * 60), (iTime * 60), sBufferReason, DatabasePrefix, sAdminAuth, sAdminAuth[8], sAdminIp, iServerID);

	hSourceBans.Query(VerifyInsert, sQuery, dataPack, DBPrio_High);

	return true;
}

/**
 * @brief Verifies the insert query
 *
 * @param db			Database handle
 * @param results		Results handle
 * @param error			Error message
 * @param dataPack		Data pack
 */
public void VerifyInsert(Database db, DBResultSet results, const char[] error, DataPack dataPack)
{
	if (dataPack == INVALID_HANDLE)
	{
		CPrintToChatAll("%t %T", "Tag", "BanFail", LANG_SERVER, error);
		fkn_log(false, "Failed to ban player: %s", error);
		return;
	}

	if (results == null)
	{
		CPrintToChatAll("%t %T", "Tag", "BanFailQuery", LANG_SERVER, error);
		fkn_log(false, "Verify Insert Query Failed: %s", error);
		return;
	}

	char
		sName[64],
		sReason[128];

	dataPack.Reset();
	int iTime = dataPack.ReadCell();
	dataPack.ReadString(sReason, sizeof(sReason));
	dataPack.ReadString(sName, sizeof(sName));
	delete dataPack;

	if (g_cvarDebug.BoolValue)
		fkn_log(false, "%s was banned for %d minutes. Reason: %s", sName, iTime, sReason);

	CPrintToChatAll("%t %t", "Tag", "PrintBanSuccess", sName, iTime, sReason);
}

public int BansAccount(int iTarget, ForsakenTeam Team, char[] sBanCode)
{
	Database  hSourceBans = Connect(); 
	if (hSourceBans == null)
	{
		fkn_log(true, "Could not connect to database (null)");
		return 0;
	}

	int iSteamID64[2];
	char
		sSteamID64[MAX_AUTHID_LENGTH],
		sSteamID2[MAX_AUTHID_LENGTH];

	sSteamID64 = g_Players[Team][iTarget].steamid;
	if ((StringToInt64(sSteamID64, iSteamID64)) == 0)
		fkn_log(false, "%s StringToInt failed", JVPrefix);

	GetSteam2FromAccountId(sSteamID2, sizeof(sSteamID2), iSteamID64[0]);

	int iTimeLimit = GetTime() - UNIXTIME_4WEEKS;
	char sQuery[PLATFORM_MAX_PATH];
	Format(sQuery, sizeof(sQuery),
		"SELECT COUNT(*) \
		FROM `sb_bans` \
		WHERE `authid` LIKE '%s' \
			AND `reason` LIKE '%s' \
			AND `created` > '%d';",
		sSteamID2, sBanCode, iTimeLimit);

	fkn_log(true, "sQuery: %s", sQuery);

	char error[PLATFORM_MAX_PATH];
	DBResultSet rsSourceBans;
	if ((rsSourceBans = SQL_Query(hSourceBans, sQuery)) == null)
	{
		SQL_GetError(hSourceBans, error, sizeof(error));
		fkn_log(false, "FetchUsers() query failed: %s", sQuery);
		fkn_log(false, "Query error: %s", error);
		return 0;
	}

	int iBans;
	while (rsSourceBans.FetchRow())
	{
		iBans = rsSourceBans.FetchInt(0);
	}

	delete rsSourceBans;
	return iBans;
}

public int ClientBansAccount(int iClient, char[] sBanCode)
{
	Database  hSourceBans = Connect(); 
	if (hSourceBans == null)
	{
		fkn_log(true, "Could not connect to database (null)");
		return 0;
	}

	char sSteamID2[MAX_AUTHID_LENGTH];
	if(!GetClientAuthId(iClient, AuthId_Steam2, sSteamID2, MAX_AUTHID_LENGTH))
	{
		CReplyToCommand(iClient, "%t Error to identify the SteamID2", "Tag");
		return 0;
	}

	char sQuery[PLATFORM_MAX_PATH];
	int iTimeLimit = GetTime() - UNIXTIME_4WEEKS;
	Format(sQuery, sizeof(sQuery),
		"SELECT COUNT(*) \
		FROM `sb_bans` \
		WHERE `authid` LIKE '%s' \
			AND `reason` LIKE '%s' \
			AND `created` > '%d';",
		sSteamID2, sBanCode, iTimeLimit);

	fkn_log(true, "sQuery: %s", sQuery);

	char error[PLATFORM_MAX_PATH];
	DBResultSet rsSourceBans;
	if ((rsSourceBans = SQL_Query(hSourceBans, sQuery)) == null)
	{
		SQL_GetError(hSourceBans, error, sizeof(error));
		fkn_log(false, "FetchUsers() query failed: %s", sQuery);
		fkn_log(false, "Query error: %s", error);
		return 0;
	}

	int iBans;
	while (rsSourceBans.FetchRow())
	{
		iBans = rsSourceBans.FetchInt(0);
	}

	delete rsSourceBans;
	return iBans;
}

Database Connect()
{
	char error[PLATFORM_MAX_PATH];
	Database db;
	
	if (SQL_CheckConfig("sourcebans"))
		db = SQL_Connect("sourcebans", true, error, sizeof(error));
	
	if (db == null)
		fkn_log(false, "Could not connect to database: %s", error);

	SQL_SetCharset(db, "utf8mb4");
	return db;
}