#if defined _mmr_scrims_included
	#endinput
#endif
#define _mmr_scrims_included

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

public void RoundEnd_Teams()
{
	if (InSecondHalfOfRound())
		ProcesScrims();
}

void ProcesScrims()
{
	if (g_iTeamScore[TeamA] > g_iTeamScore[TeamB])
	{
		if (AreTeamsFlipped())
		{
			fkn_log(true, "TeamA Win, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingTeams(TeamA, Result_Win);
			ProcessRatingTeams(TeamB, Result_Loss);
		}
		else
		{
			fkn_log(true, "TeamB Win, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingTeams(TeamA, Result_Loss);
			ProcessRatingTeams(TeamB, Result_Win);
		}
	}
	else if (g_iTeamScore[TeamA] < g_iTeamScore[TeamB])
	{
		if (AreTeamsFlipped())
		{
			fkn_log(true, "TeamA Loss, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingTeams(TeamA, Result_Loss);
			ProcessRatingTeams(TeamB, Result_Win);
		}
		else
		{
			fkn_log(true, "TeamB Win, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingTeams(TeamA, Result_Win);
			ProcessRatingTeams(TeamB, Result_Loss);
		}
	}
	else if (g_iTeamScore[TeamA] == g_iTeamScore[TeamB])
	{
		fkn_log(true, "Team Draw, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
		ProcessRatingTeams(TeamA, Result_Draw);
		ProcessRatingTeams(TeamB, Result_Draw);
	}
	g_iTeamScore[TeamA] = 0;
	g_iTeamScore[TeamB] = 0;
}

void ProcessRatingTeams(ForsakenTeam team, MatchResults Result)
{
	Database hForsaken = Connect(); 
	if (hForsaken == null)
	{
		fkn_log(true, "Could not connect to database (null)");
		return;
	}

	ForsakenTeam opponent = GetOpponent(team);

	int 
		iID = 0,
		jID = 0;

	float
		fSum_d,
		fGlicko_d,
		fFinalRD,
		fSum_FinalRating,
		fFinalRating;

	fSum_d += Glicko_sum_d(g_TeamsInfo[team][iID], g_TeamsInfo[opponent][jID]);
	fSum_FinalRating += Glicko_sum_FinalRating(g_TeamsInfo[team][iID], g_TeamsInfo[opponent][jID], Result);

	fGlicko_d	 = Glicko_d(fSum_d);
	fFinalRD	 = (Glicko_FinalRD(g_TeamsInfo[team][iID], fGlicko_d) - g_TeamsInfo[team][iID].deviation);
	fFinalRating = (Glicko_FinalRating(g_TeamsInfo[team][iID], fGlicko_d, fSum_FinalRating) - g_TeamsInfo[team][iID].rating);

	if (Result == Result_Win)
		g_TeamsInfo[team][iID].wins++;
	g_TeamsInfo[team][iID].gamesplayed++;

	if (EVALUATION_PERIOD < g_TeamsInfo[team][iID].gamesplayed)
		g_TeamsInfo[team][iID].deviation += fFinalRD;
	g_TeamsInfo[team][iID].rating += fFinalRating;

	DataPack pack = new DataPack();
	pack.WriteCell(23);

	if (EVALUATION_PERIOD < g_TeamsInfo[team][iID].gamesplayed)
		PrintFinalScoreTeam(team);
	else
		PrintFinalScoreTeamEV(team);

	char sQuery[512];
	hForsaken.Format(sQuery, sizeof(sQuery),
		"UPDATE `teams_mmr` \
		SET `Rating` = %f, \
			`Deviation` = %f, \
			`GamesPlayed` = %d, \
			`LastGame` = %d, \
			`Wins` = %d \
		WHERE `TeamsID` LIKE '%d';",
		g_TeamsInfo[team][iID].rating,
		g_TeamsInfo[team][iID].deviation,
		g_TeamsInfo[team][iID].gamesplayed,
		GetTime(),
		g_TeamsInfo[team][iID].wins,
		g_TeamsInfo[team][iID].teamid);

	fkn_log(true, "sQuery: %s", sQuery);
	hForsaken.Query(OnScrimsCallback, sQuery);
}

void OnScrimsCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		fkn_log(false, "Error: %s", error);
		return;
	}
}

void PrintFinalScoreTeam(ForsakenTeam team)
{
	for(int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{	
		if (IsValidClient(g_Players[team][iID].client))
			CPrintToChat(g_Players[team][iID].client, "%t %t", "Tag", "FinalScorePersonal", g_TeamsInfo[team][iID].rating, g_TeamsInfo[team][iID].deviation);
	}
}

void PrintFinalScoreTeamEV(ForsakenTeam team)
{
	for(int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (IsValidClient(g_Players[team][iID].client))
			CPrintToChat(g_Players[team][iID].client, "%t %t", "Tag", "FinalScoreEvaluationTeam", (EVALUATION_PERIOD - g_TeamsInfo[team][iID].gamesplayed));
	}
}