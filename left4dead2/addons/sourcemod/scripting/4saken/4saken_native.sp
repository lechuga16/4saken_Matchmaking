#if defined _4saken_native_included
	#endinput
#endif
#define _4saken_native_included

/**
 * Logs a message to 4saken file.  The log message will be in the normal
 *
 * @param format        Formatting rules.
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
any Native_Log(Handle plugin, int numParams)
{
	char
		sFilename[64],
		sBuffer[PLATFORM_MAX_PATH],
		sLogPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs/4saken.log");
	GetPluginBasename(plugin, sFilename, sizeof(sFilename));
	FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
	LogToFileEx(sLogPath, "[%s] %s", sFilename, sBuffer);
	return 0;
}

/**
 * Gets the type of match broadcast on 4saken.us
 *
 * @return An integer, -1 is that information is not yet obtained
 */
any Native_TypeMatch(Handle plugin, int numParams)
{
	return iRegion;
}


/**
 * Gets the steamid of the players that are assigned to Team 1
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
any Native_Team1(Handle plugin, int numParams)
{
	int
		index  = GetNativeCell(1),
		maxlen = GetNativeCell(3);

	SetNativeString(2, SteamIDT1[index], maxlen);
	return 0;
}


/**
 * Gets the steamid of the players that are assigned to Team 2
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
any Native_Team2(Handle plugin, int numParams)
{
	int
		index  = GetNativeCell(1),
		maxlen = GetNativeCell(3);

	SetNativeString(2, SteamIDT2[index], maxlen);
	return 0;
}
