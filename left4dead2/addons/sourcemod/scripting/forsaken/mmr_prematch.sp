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

	for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
	{
		DBInfoPlayers(i, TeamA);
		DBInfoPlayers(i, TeamB);
	}

	CreateCompositePlayer(TeamA);
	CreateCompositePlayer(TeamB);

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
		fkn_SteamIDTA(Index, g_Players[TeamA][Index].steamid, MAX_AUTHID_LENGTH);
		fkn_NameTA(Index, g_Players[TeamA][Index].name, MAX_NAME_LENGTH);
	}
	else if (Team == TeamB)
	{
		fkn_SteamIDTB(Index, g_Players[TeamB][Index].steamid, MAX_AUTHID_LENGTH);
		fkn_NameTB(Index, g_Players[TeamB][Index].name, MAX_NAME_LENGTH);
	}

	Format(sQuery, sizeof(sQuery), "SELECT m.`Rating`, m.`Deviation`, m.`GamesPlayed`, m.`LastGame` FROM `users_general` AS g INNER JOIN `users_mmr`AS m on g.`MMRID` = m.`MMRID` WHERE g.`SteamID64` LIKE '%s'", g_Players[Team][Index].steamid);

	if ((DBResul = SQL_Query(g_dbForsaken, sQuery)) == null)
	{
		SQL_GetError(g_dbForsaken, error, sizeof(error));
		LogError("FetchUsers() query failed: %s", sQuery);
		LogError("Query error: %s", error);
		return;
	}

	while (DBResul.FetchRow())
	{
		g_Players[Team][Index].rating	   = DBResul.FetchFloat(0);
		g_Players[Team][Index].deviation   = DBResul.FetchFloat(1);
		g_Players[Team][Index].gamesplayed = DBResul.FetchInt(2);
		g_Players[Team][Index].lastgame	   = DBResul.FetchInt(3);
	}
}

public void CreateCompositePlayer(ForsakenTeam Team)
{
	for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
	{
		g_CPlayer[Team].rating += g_Players[Team][i].rating;
		g_CPlayer[Team].deviation += g_Players[Team][i].deviation;

		if (i == 3)
		{
			g_CPlayer[Team].rating	  = g_CPlayer[Team].rating / 4;
			g_CPlayer[Team].deviation = g_CPlayer[Team].deviation / 4;
		}
	}
}