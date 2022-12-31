#if defined _mmr_scrims_included
	#endinput
#endif
#define _mmr_scrims_included

public void ScrimMatch()
{
	if (g_TypeMatch != scrims)
		return;

	CreateTimer(3.0, Timer_TeamsMatchData);
}

/**
 * @brief Gets the match data from forsaken.smx.
 *
 * @param timer		Timer handle.
 * @return			Stop the timer.
 */
public Action Timer_TeamsMatchData(Handle timer)
{
	if (g_cvarDebug.BoolValue)
		CPrintToChatAll("TeamsMatchData");

	// g_TeamTA.id = 1;	// inventar forma de recuperar el ID de los equipos
	// g_TeamTA.id = 2;	// inventar forma de recuperar el ID de los equipos

	g_TeamInfo[TeamA].id = 1;
	g_TeamInfo[TeamB].id = 2;

	DBInfoTeams(TeamA);
	DBInfoTeams(TeamB);

	return Plugin_Stop;
}

public void DBInfoTeams(ForsakenTeam Team)
{
	DBResultSet DBResul;

	char
		sQuery[256],
		error[255];

	Format(sQuery, sizeof(sQuery), "SELECT `Name`, `Rating`, `Deviation`, `GamesPlayed`, `LastGame`, `GamesWon` FROM `teams_mmr` WHERE `SteamID64` = 'ID'",
		   (Team == TeamA) ? g_TeamInfo[TeamA].id : g_TeamInfo[TeamB].id);

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
			DBResul.FetchString(0, g_TeamInfo[TeamA].name, MAX_NAME_LENGTH);
			g_TeamInfo[TeamA].rating	  = DBResul.FetchFloat(1);
			g_TeamInfo[TeamA].deviation	  = DBResul.FetchFloat(2);
			g_TeamInfo[TeamA].gamesplayed = DBResul.FetchInt(3);
			g_TeamInfo[TeamA].lastgame	  = DBResul.FetchInt(4);
			g_TeamInfo[TeamA].gameswon	  = DBResul.FetchInt(5);
		}
		else if (Team == TeamB)
		{
			DBResul.FetchString(0, g_TeamInfo[TeamB].name, MAX_NAME_LENGTH);
			g_TeamInfo[TeamB].rating	  = DBResul.FetchFloat(1);
			g_TeamInfo[TeamB].deviation	  = DBResul.FetchFloat(2);
			g_TeamInfo[TeamB].gamesplayed = DBResul.FetchInt(3);
			g_TeamInfo[TeamB].lastgame	  = DBResul.FetchInt(4);
			g_TeamInfo[TeamB].gameswon	  = DBResul.FetchInt(5);
		}
	}
}

public void RoundEnd_Teams()
{
	if (L4D_GetTeamScore(view_as<int>(TeamA)) > L4D_GetTeamScore(view_as<int>(TeamB)))
	{
		if (g_cvarDebug.BoolValue)
			fkn_log("TeamA Win, TA:%d TB:%d", L4D_GetTeamScore(view_as<int>(TeamA)), L4D_GetTeamScore(view_as<int>(TeamB)));
	}
	else if (L4D_GetTeamScore(view_as<int>(TeamA)) < L4D_GetTeamScore(view_as<int>(TeamB)))
	{
		if (g_cvarDebug.BoolValue)
			fkn_log("TeamB Win, TA:%d TB:%d", L4D_GetTeamScore(view_as<int>(TeamA)), L4D_GetTeamScore(view_as<int>(TeamB)));
	}
	else
	{
		if (g_cvarDebug.BoolValue)
			fkn_log("Draw, TA:%d TB:%d", L4D_GetTeamScore(view_as<int>(TeamA)), L4D_GetTeamScore(view_as<int>(TeamB)));
	}
}