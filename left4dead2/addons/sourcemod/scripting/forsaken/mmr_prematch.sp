#if defined _mmr_prematch_included
	#endinput
#endif
#define _mmr_prematch_included

/**
 * @brief Starts a timer that gets match information in the prematch
 *
 * @noreturn
 */
public void PreMatch()
{
	if (!g_bPreMatch)
		return;

	CreateTimer(3.0, Timer_PlayersMatchData);
}

/**
 * @brief Gets the match data from forsaken.smx.
 *
 * @param timer		Timer handle.
 * @return			Stop the timer.
 */
public Action Timer_PlayersMatchData(Handle timer)
{
	if (g_cvarDebug.BoolValue)
		CPrintToChatAll("GetMatchData");

	g_TypeMatch = fkn_TypeMatch();
	fkn_MapName(g_sMapName, sizeof(g_sMapName));

	for (int i = 0; i <= 3; i++)
	{
		DBInfoPlayers(i, TeamA);
		DBInfoPlayers(i, TeamB);
	}

	return Plugin_Stop;
}

public void DBInfoPlayers(int Index, ForsakenTeam Team)
{
	DBResultSet DBResul;

	char
		sQuery[256],
		error[255];

	if (Team == TeamA)
	{
		fkn_SteamIDTA(Index, g_PlayersTA[Index].steamid, MAX_AUTHID_LENGTH);
		fkn_NameTA(Index, g_PlayersTA[Index].name, MAX_NAME_LENGTH);
	}
	else if (Team == TeamB)
	{
		fkn_SteamIDTB(Index, g_PlayersTB[Index].steamid, MAX_AUTHID_LENGTH);
		fkn_NameTB(Index, g_PlayersTB[Index].name, MAX_NAME_LENGTH);
	}

	Format(sQuery, sizeof(sQuery), "SELECT `Rating`, `Deviation`, `GamesPlayed`, `LastGame` FROM `users_mmr` WHERE `SteamID64` = '%s'", (Team == TeamA) ? g_PlayersTA[Index].steamid : g_PlayersTB[Index].steamid);

	if ((DBResul = SQL_Query(g_dbForsaken, sQuery)) == null)
	{
		SQL_GetError(g_dbForsaken, error, sizeof(error));
		LogError("FetchUsers() query failed: %s", sQuery);
		LogError("Query error: %s", error);
		return;
	}

	while (DBResul.FetchRow())
	{
		if (Team == TeamA)
		{
			g_PlayersTA[Index].rating	   = DBResul.FetchFloat(0);
			g_PlayersTA[Index].deviation   = DBResul.FetchFloat(1);
			g_PlayersTA[Index].gamesplayed = DBResul.FetchInt(2);
			g_PlayersTA[Index].lastgame	   = DBResul.FetchInt(3);
		}
		else if (Team == TeamB)
		{
			g_PlayersTB[Index].rating	   = DBResul.FetchFloat(0);
			g_PlayersTB[Index].deviation   = DBResul.FetchFloat(1);
			g_PlayersTB[Index].gamesplayed = DBResul.FetchInt(2);
			g_PlayersTB[Index].lastgame	   = DBResul.FetchInt(43);
		}
	}
}