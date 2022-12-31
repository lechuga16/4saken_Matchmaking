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

	CreateCompositePlayer();

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

	Format(sQuery, sizeof(sQuery), "SELECT m.`Rating`, m.`Deviation`, m.`GamesPlayed`, m.`LastGame` FROM `users_general` AS g INNER JOIN `users_mmr`AS m on g.`MMRID` = m.`MMRID` WHERE g.`SteamID64` LIKE '%s'",
		   (Team == TeamA) ? g_Players[TeamA][Index].steamid : g_Players[TeamB][Index].steamid);

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
			g_Players[TeamA][Index].rating		= DBResul.FetchFloat(0);
			g_Players[TeamA][Index].deviation	= DBResul.FetchFloat(1);
			g_Players[TeamA][Index].gamesplayed = DBResul.FetchInt(2);
			g_Players[TeamA][Index].lastgame	= DBResul.FetchInt(3);
		}
		else if (Team == TeamB)
		{
			g_Players[TeamB][Index].rating		= DBResul.FetchFloat(0);
			g_Players[TeamB][Index].deviation	= DBResul.FetchFloat(1);
			g_Players[TeamB][Index].gamesplayed = DBResul.FetchInt(2);
			g_Players[TeamB][Index].lastgame	= DBResul.FetchInt(3);
		}
	}
}

public void CreateCompositePlayer()
{
	for (int i = 0; i <= 3; i++)
	{
		g_CPlayer[TeamA].rating += g_Players[TeamA][i].rating;
		g_CPlayer[TeamA].deviation += g_Players[TeamA][i].deviation;

		g_CPlayer[TeamB].rating += g_Players[TeamB][i].rating;
		g_CPlayer[TeamB].deviation += g_Players[TeamB][i].deviation;

		if (i == 3)
		{
			g_CPlayer[TeamA].rating	   = g_CPlayer[TeamA].rating / 4;
			g_CPlayer[TeamA].deviation = g_CPlayer[TeamA].deviation / 4;

			g_CPlayer[TeamB].rating	   = g_CPlayer[TeamB].rating / 4;
			g_CPlayer[TeamB].deviation = g_CPlayer[TeamB].deviation / 4;
		}
	}
}