#if defined jarvis_ban_included
	#endinput
#endif
#define jarvis_ban_included

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

/** 
 * @brief Represents a set of results returned from executing a query.
 * 		Only works if the cvar is enabled.
 * 
 * @param db 			Database to query
 * @param error 		Error buffer
 * @param data			Data to pass to the callback
 * @noreturn
 */
public void GotDatabase(Database db, const char[] error, any data)
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (db == null)
	{
		ThrowError("Error while connecting to database: %s", error);
		Forsaken_log("Connected to database successfully (%s).", error);
	}

	g_DBSourceBans = db;
	SQL_SetCharset(g_DBSourceBans, "utf8mb4");
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
		if(g_cvarDebug.BoolValue)
			PrintToServer("%s Loading configs/sourcebans.cfg config file", JVPrefix);
	}
	else
	{
		char Error[PLATFORM_MAX_PATH + 64];
		FormatEx(Error, sizeof(Error), "%s FATAL *** ERROR *** can not find %s", JVPrefix, ConfigFile);
		Forsaken_log("FATAL *** ERROR *** can not find %s", ConfigFile);
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
public bool CreateOffLineBan(int iTarget, ForsakenTeam Team, int iTime, const char[] sReason)
{
	// server information
	char
		sAdminIp[24]   = "",
		sAdminAuth[64] = "STEAM_ID_SERVER";
		
	Forsaken_GetIPv4(sAdminIp, sizeof(sAdminIp));

	// iTarget information
	char
		sIp[32] = "",
		sAuth[64],
		sName[MAX_NAME_LENGTH];

	if (Team == TeamA)
	{
		sAuth = g_sSteamIDTA[iTarget];
		sName = g_sNameTA[iTarget];
	}
	else if (Team == TeamB)
	{
		sAuth = g_sSteamIDTB[iTarget];
		sName = g_sNameTB[iTarget];
	}
	else
	{
		Forsaken_log("CreateOffLineBan: Team is invalid");
		CPrintToChatAll("%s %T", "Tag",  "BanFail", LANG_SERVER, "ForsakenTeam is invalid");
		return false;
	}

	if(StrEqual("", sAuth, false))
	{
		Forsaken_log("CreateOffLineBan: SteamID is invalid");
		CPrintToChatAll("%s %T", "Tag",  "BanFail", LANG_SERVER, "SteamID is invalid");
		return false;
	}

	if(StrEqual("", sName, false))
	{
		Forsaken_log("CreateOffLineBan: %s sName is invalid", sAuth);
		sName = "Unknown";
	}

	// Pack everything into a data pack so we can retain it
	DataPack dataPack = new DataPack();

	dataPack.WriteCell(iTime);
	dataPack.WriteString(sReason);
	dataPack.WriteString(sName);

	if (g_DBSourceBans != INVALID_HANDLE)
		UTIL_InsertBan(iTime, sName, sAuth, sIp, sReason, sAdminAuth, sAdminIp, dataPack);
	else
		return false;

	return true;
}

/** 
 * @brief Inserts a ban into the database
 *
 * @param iTime			Ban time
 * @param sName			Ban name
 * @param sAuthid		Ban authid
 * @param sIp			Ban ip
 * @param sReason		Ban reason
 * @param sAdminAuth	Ban admin authid
 * @param sAdminIp		Ban admin ip
 * @param dataPack		Data pack
 */
stock void UTIL_InsertBan(int iTime, const char[] sName, const char[] sAuthid, const char[] sIp, const char[] sReason, const char[] sAdminAuth, const char[] sAdminIp, DataPack dataPack)
{
	char
		sQuery[1024],
		sBufferReason[128];

	FormatEx(sBufferReason, sizeof(sBufferReason), "%s %s.", JVPrefix, sReason);
	
	FormatEx(sQuery, sizeof(sQuery), "INSERT INTO %s_bans \
 			(ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES \
 			('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', IFNULL((SELECT aid FROM %s_admins WHERE authid = '%s' OR authid REGEXP '^STEAM_[0-9]: %s$'), '0'), '%s', %d, ' ')",
			DatabasePrefix, sIp, sAuthid, sName, (iTime * 60), (iTime * 60), sBufferReason, DatabasePrefix, sAdminAuth, sAdminAuth[8], sAdminIp, iServerID);
	g_DBSourceBans.Query(VerifyInsert, sQuery, dataPack, DBPrio_High);
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
		CPrintToChatAll("%s %T", "Tag",  "BanFail", LANG_SERVER, error);
		Forsaken_log("Failed to ban player: %s", error);
		return;
	}

	if (results == null)
	{
		CPrintToChatAll("%s %T", "Tag",  "BanFailQuery", LANG_SERVER, error);
		Forsaken_log("Verify Insert Query Failed: %s", error);
		return;
	}

	char
		sName[64],
		sReason[128];

	dataPack.Reset();
	int iTime  = dataPack.ReadCell();
	dataPack.ReadString(sReason, sizeof(sReason));
	dataPack.ReadString(sName, sizeof(sName));
	delete dataPack;

	CPrintToChatAll("%t %t", "Tag", "PrintBanSuccess", sName, iTime, sReason);

	if(g_cvarDebug.BoolValue)
		Forsaken_log("%s was banned for %d minutes. Reason: %s", sName, iTime, sReason);
}