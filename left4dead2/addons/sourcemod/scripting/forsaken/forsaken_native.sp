#if defined _forsaken_native_included
	#endinput
#endif
#define _forsaken_native_included

/*****************************************************************
			N A T I V E S
*****************************************************************/

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

	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), DIR_FORSAKENLOG);
	GetPluginBasename(plugin, sFilename, sizeof(sFilename));
	FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
	LogToFileEx(sLogPath, "[%s] %s", sFilename, sBuffer);
	return 0;
}

/**
 * Gets the type of match broadcast on 4saken.us
 *
 * @return 				An integer, 0 is that information is not yet obtained
 */
any Native_TypeMatch(Handle plugin, int numParams)
{
	return g_TypeMatch;
}

/**
 * Get lobby queue number
 *
 * @return 				An integer, 0 is that information is not yet obtained
 */
any Native_QueueID(Handle plugin, int numParams)
{
	return g_iQueueID;
}

/**
 * Gets the steamid of the players that are assigned to Team 1
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
any Native_SteamIDTA(Handle plugin, int numParams)
{
	int
		index  = GetNativeCell(1),
		maxlen = GetNativeCell(3);

	SetNativeString(2, g_Players[TeamA][index].steamid, maxlen);
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
any Native_SteamIDTB(Handle plugin, int numParams)
{
	int
		index  = GetNativeCell(1),
		maxlen = GetNativeCell(3);

	SetNativeString(2, g_Players[TeamB][index].steamid, maxlen);
	return 0;
}

/**
 * Gets the name of the players that are assigned to Team A
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
any Native_NameTA(Handle plugin, int numParams)
{
	int
		index  = GetNativeCell(1),
		maxlen = GetNativeCell(3);

	SetNativeString(2, g_Players[TeamA][index].name, maxlen);
	return 0;
}

/**
 * Gets the name of the players that are assigned to Team B
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
any Native_NameTB(Handle plugin, int numParams)
{
	int
		index  = GetNativeCell(1),
		maxlen = GetNativeCell(3);

	SetNativeString(2, g_Players[TeamB][index].name, maxlen);
	return 0;
}
/**
 * Gets the IPv4
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
any Native_GetIPv4(Handle plugin, int numParams)
{
	int maxlen = GetNativeCell(2);

	SetNativeString(1, g_sIPv4, maxlen);
	return 0;
}

/**
 * Gets the name of the map provided by Forsaken
 *
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
any Native_MapName(Handle plugin, int numParams)
{
	int maxlen = GetNativeCell(2);

	SetNativeString(1, g_sMapName, maxlen);
	return 0;
}