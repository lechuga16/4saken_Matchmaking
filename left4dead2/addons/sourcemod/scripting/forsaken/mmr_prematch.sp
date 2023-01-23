#if defined _mmr_prematch_included
	#endinput
#endif
#define _mmr_prematch_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

PlayerInfo g_TeamsInfo[ForsakenTeam][MAX_PLAYER_TEAM];	// Information to calculate mmr of a team

Database  g_dbForsaken;
TypeMatch g_TypeMatch;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

/**
 * @brief Starts a timer that gets match information in the prematch
 *
 * @noreturn
 */
public void OCD_Prematch()
{
	g_TypeMatch = fkn_TypeMatch();
	fkn_MapName(g_sMapName, sizeof(g_sMapName));
	fkn_Players(g_TypeMatch);

	if(IsGameCompetitive(g_TypeMatch) || g_TypeMatch == duel)
		PlayersPugs();
	else if(g_TypeMatch == scrims)
		PlayersScrims();
	else if(g_TypeMatch == invalid || g_TypeMatch == unranked)
		return;
}

void PlayersPugs()
{
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		DBInfoPlayers(iID, TeamA);
		DBInfoPlayers(iID, TeamB);

		if(iID == 0 && g_TypeMatch == duel)
			break;
	}
}

void PlayersScrims()
{
	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		DBInfoPlayers(iID, TeamA);
		DBInfoPlayers(iID, TeamB);

		DBInfoTeams(iID, TeamA);
		DBInfoTeams(iID, TeamB);
	}
}

void DBInfoPlayers(int Index, ForsakenTeam Team)
{
	if(g_dbForsaken == INVALID_HANDLE)
		return;
	
	char	sQuery[512];
	
	DataPack ClientInfo = new DataPack();
	ClientInfo.WriteCell(Team);
	ClientInfo.WriteCell(Index);

	if(g_TypeMatch == duel)

	g_dbForsaken.Format(sQuery, sizeof(sQuery), 
		"SELECT `m`.`Rating`,\
				`m`.`Deviation`,\
				`m`.`GamesPlayed`,\
				`m`.`LastGame`,\
				`m`.`Wins`, \
				`g`.`TeamsID` \
		FROM `users_general` AS `g`\
		INNER JOIN `%s` AS `m`\
		ON `g`.`%s` = `m`.`%s`\
		WHERE `g`.`SteamID64` LIKE '%s';", 
		(g_TypeMatch == duel) ? "duel_mmr" : "user_mmr", 
		(g_TypeMatch == duel) ? "Duel_MMRID" : "Pug_MMRID",
		(g_TypeMatch == duel) ? "Duel_MMRID" : "Pug_MMRID", 
		g_Players[Team][Index].steamid);

	fkn_log(true, "sQuery: %s", sQuery);
	g_dbForsaken.Query(OnPlayersInfoCallback, sQuery, ClientInfo);
}

void OnPlayersInfoCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		fkn_log(false, "Error: %s", error);
		return;
	}

	DataPack ClientInfo = data;
	ClientInfo.Reset();
	ForsakenTeam Team = ClientInfo.ReadCell();
	int Index = ClientInfo.ReadCell();
	CloseHandle(ClientInfo);
	fkn_log(true, "Index: %d | %s", Index, Team == TeamA ? "TeamA" : "TeamB");

	if (results.FetchRow())
	{
		g_Players[Team][Index].rating	   = results.FetchFloat(0);
		g_Players[Team][Index].deviation   = results.FetchFloat(1);
		g_Players[Team][Index].gamesplayed = results.FetchInt(2);
		g_Players[Team][Index].lastgame	   = results.FetchInt(3);
		g_Players[Team][Index].wins		   = results.FetchInt(4);
		g_Players[Team][Index].teamid		= results.FetchInt(5);
	}

	fkn_log(true, "Rating: %f | Deviation: %f | GamesPlayed: %d | LastGame: %d | Wins: %d | TeamID: %d", 
		g_Players[Team][Index].rating, 
		g_Players[Team][Index].deviation, 
		g_Players[Team][Index].gamesplayed, 
		g_Players[Team][Index].lastgame, 
		g_Players[Team][Index].wins,
		g_Players[Team][Index].teamid);

}

void DBInfoTeams(int Index, ForsakenTeam Team)
{
	if(g_dbForsaken == INVALID_HANDLE)
		return;
	
	char	sQuery[512];
	
	DataPack ClientInfo = new DataPack();
	ClientInfo.WriteCell(Team);
	ClientInfo.WriteCell(Index);

	g_dbForsaken.Format(sQuery, sizeof(sQuery), 
		"SELECT `Rating`,\
				`Deviation`,\
				`GamesPlayed`,\
				`LastGame`,\
				`Wins` \
				`Name` \
		FROM `teams_mmr` \
		WHERE `TeamsID` LIKE '%s';", g_Players[Team][Index].teamid);
	
	fkn_log(true, "sQuery: %s", sQuery);
	g_dbForsaken.Query(OnTeamsInfoCallback, sQuery, ClientInfo);
}

void OnTeamsInfoCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		fkn_log(false, "Error: %s", error);
		return;
	}

	DataPack ClientInfo = data;
	ClientInfo.Reset();
	ForsakenTeam Team = ClientInfo.ReadCell();
	int Index = ClientInfo.ReadCell();
	CloseHandle(ClientInfo);

	if (results.FetchRow())
	{
		g_TeamsInfo[Team][Index].rating		= results.FetchFloat(0);
		g_TeamsInfo[Team][Index].deviation		= results.FetchFloat(1);
		g_TeamsInfo[Team][Index].gamesplayed	= results.FetchInt(2);
		g_TeamsInfo[Team][Index].lastgame		= results.FetchInt(3);
		g_TeamsInfo[Team][Index].wins			= results.FetchInt(4);
		results.FetchString(5, g_TeamsInfo[Team][Index].name, MAX_NAME_LENGTH);
	}

	fkn_log(true, "Rating: %f | Deviation: %f | GamesPlayed: %d | LastGame: %d | Wins: %d | Name: %s", 
		g_TeamsInfo[Team][Index].rating, 
		g_TeamsInfo[Team][Index].deviation, 
		g_TeamsInfo[Team][Index].gamesplayed, 
		g_TeamsInfo[Team][Index].lastgame, 
		g_TeamsInfo[Team][Index].wins,
		g_TeamsInfo[Team][Index].name);

}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/
public void SQLConnect()
{
	if (!g_cvarEnable.BoolValue)
		return;

	if (!SQL_CheckConfig("4saken"))
		fkn_log(false, "The 4saken configuration is not found in databases.cfg");
	else
		Database.Connect(SQL4saken, "4saken");
}

void SQL4saken(Database db, const char[] error, any data)
{
	if (db == null)
		ThrowError("Error while connecting to database: %s", error);
	else
		g_dbForsaken = db;
}
