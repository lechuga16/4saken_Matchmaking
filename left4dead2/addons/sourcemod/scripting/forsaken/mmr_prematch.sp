#if defined _mmr_prematch_included
	#endinput
#endif
#define _mmr_prematch_included

/**
 * @brief Starts a timer that gets match information in the prematch
 *
 * @noreturn
 */
public void OCD_Prematch()
{
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
	if(g_dbForsaken == INVALID_HANDLE)
		return;
	
	char	sQuery[512];
	
	DataPack ClientInfo = new DataPack();
	ClientInfo.WriteCell(Team);
	ClientInfo.WriteCell(Index);

	g_dbForsaken.Format(sQuery, sizeof(sQuery), 
		"SELECT `m`.`Rating`,\
				`m`.`Deviation`,\
				`m`.`GamesPlayed`,\
				`m`.`LastGame`,\
				`m`.`Wins` \
		FROM `users_general` AS `g`\
		INNER JOIN `users_mmr` AS `m`\
		ON `g`.`MMRID` = `m`.`MMRID`\
		WHERE `g`.`SteamID64` LIKE '%s';", g_Players[Team][Index].steamid);
	
	fkn_log("sQuery: %s", sQuery);
	g_dbForsaken.Query(OnCallback, sQuery, ClientInfo);
}

public void OnCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		fkn_log("Error: %s", error);
		return;
	}

	DataPack ClientInfo = data;
	ClientInfo.Reset();
	ForsakenTeam Team = ClientInfo.ReadCell();
	int Index = ClientInfo.ReadCell();
	CloseHandle(ClientInfo);

	if(g_cvarDebug.BoolValue)
		fkn_log("Index: %d | %s", Index, Team == TeamA ? "TeamA" : "TeamB");

	if (results.FetchRow())
	{
		g_Players[Team][Index].rating	   = results.FetchFloat(0);
		g_Players[Team][Index].deviation   = results.FetchFloat(1);
		g_Players[Team][Index].gamesplayed = results.FetchInt(2);
		g_Players[Team][Index].lastgame	   = results.FetchInt(3);
		g_Players[Team][Index].wins		   = results.FetchInt(4);
	}
	if(g_cvarDebug.BoolValue)
		fkn_log("Rating: %f | Deviation: %f | GamesPlayed: %d | LastGame: %d | Wins: %d", 
			g_Players[Team][Index].rating, 
			g_Players[Team][Index].deviation, 
			g_Players[Team][Index].gamesplayed, 
			g_Players[Team][Index].lastgame, 
			g_Players[Team][Index].wins);

}