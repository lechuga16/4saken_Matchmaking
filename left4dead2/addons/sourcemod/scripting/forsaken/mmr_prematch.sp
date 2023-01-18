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

	g_TypeMatch = fkn_TypeMatch();
	fkn_MapName(g_sMapName, sizeof(g_sMapName));
	fkn_Players();

	for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
	{
		DBInfoPlayers(i, TeamA);
		DBInfoPlayers(i, TeamB);
	}
}

public void DBInfoPlayers(int Index, ForsakenTeam Team)
{
	DBResultSet DBResul;
	char		sQuery[512];

	Format(sQuery, sizeof(sQuery),
		   "SELECT `m`.`Rating`,\
			`m`.`Deviation`,\
			`m`.`GamesPlayed`,\
			`m`.`LastGame`,\
			`m`.`Wins` \
	FROM `users_general` AS `g`\
	INNER JOIN `users_mmr` AS `m`\
	ON `g`.`MMRID` = `m`.`MMRID`\
	WHERE `g`.`SteamID64` LIKE '%s'",
		   g_Players[Team][Index].steamid);

	if ((DBResul = SQL_Query(g_dbForsaken, sQuery)) == null)
	{
		char error[512];
		SQL_GetError(g_dbForsaken, error, sizeof(error));
		fkn_log("Error: %s", error);
		fkn_log("Query: %s", sQuery);
		return;
	}

	while (DBResul.FetchRow())
	{
		g_Players[Team][Index].rating	   = DBResul.FetchFloat(0);
		g_Players[Team][Index].deviation   = DBResul.FetchFloat(1);
		g_Players[Team][Index].gamesplayed = DBResul.FetchInt(2);
		g_Players[Team][Index].lastgame	   = DBResul.FetchInt(3);
		g_Players[Team][Index].wins		   = DBResul.FetchInt(4);
	}
	delete DBResul;
}