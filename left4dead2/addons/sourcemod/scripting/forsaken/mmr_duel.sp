#if defined _mmr_1v1_included
	#endinput
#endif
#define _mmr_1v1_included

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

public void RoundEnd_Duel()
{
	if (g_TypeMatch != duel)
		return;

	if (!InSecondHalfOfRound())
		return;

	ProcesDuel();
}

void ProcesDuel()
{
	if (g_iTeamScore[TeamA] > g_iTeamScore[TeamB])
	{
		if (AreTeamsFlipped())
		{
			fkn_log(true, "TeamA Win, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingDuel(TeamA, Result_Win);
			ProcessRatingDuel(TeamB, Result_Loss);
		}
		else
		{
			fkn_log(true, "TeamB Win, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingDuel(TeamA, Result_Loss);
			ProcessRatingDuel(TeamB, Result_Win);
		}
	}
	else if (g_iTeamScore[TeamA] < g_iTeamScore[TeamB])
	{
		if (AreTeamsFlipped())
		{
			fkn_log(true, "TeamA Loss, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingDuel(TeamA, Result_Loss);
			ProcessRatingDuel(TeamB, Result_Win);
		}
		else
		{
			fkn_log(true, "TeamB Win, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingDuel(TeamA, Result_Win);
			ProcessRatingDuel(TeamB, Result_Loss);
		}
	}
	else if (g_iTeamScore[TeamA] == g_iTeamScore[TeamB])
	{
		fkn_log(true, "Team Draw, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
		ProcessRatingDuel(TeamA, Result_Draw);
		ProcessRatingDuel(TeamB, Result_Draw);
	}
	g_iTeamScore[TeamA] = 0;
	g_iTeamScore[TeamB] = 0;
}

void ProcessRatingDuel(ForsakenTeam team, MatchResults Result)
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

	fSum_d += Glicko_sum_d(g_Players[team][iID], g_Players[opponent][jID]);
	fSum_FinalRating += Glicko_sum_FinalRating(g_Players[team][iID], g_Players[opponent][jID], Result);

	fGlicko_d	 = Glicko_d(fSum_d);
	fFinalRD	 = (Glicko_FinalRD(g_Players[team][iID], fGlicko_d) - g_Players[team][iID].deviation);
	fFinalRating = (Glicko_FinalRating(g_Players[team][iID], fGlicko_d, fSum_FinalRating) - g_Players[team][iID].rating);

	if (Result == Result_Win)
		g_Players[team][iID].wins++;
	g_Players[team][iID].gamesplayed++;

	if (EVALUATION_PERIOD < g_Players[team][iID].gamesplayed)
		g_Players[team][iID].deviation += fFinalRD;
	g_Players[team][iID].rating += fFinalRating;

	if (EVALUATION_PERIOD < g_Players[team][iID].gamesplayed && IsValidClient(g_Players[team][iID].client))
		CPrintToChat(g_Players[team][iID].client, "%t %t", "Tag", "FinalScorePersonal", g_Players[team][iID].rating, g_Players[team][iID].deviation);
	else if (IsValidClient(g_Players[team][iID].client))
		CPrintToChat(g_Players[team][iID].client, "%t %t", "Tag", "FinalScoreEvaluation", (EVALUATION_PERIOD - g_Players[team][iID].gamesplayed));

	char sQuery[512];
	hForsaken.Format(sQuery, sizeof(sQuery),
		"UPDATE `duel_mmr` AS m \
		INNER JOIN `users_general` AS g \
		ON `g`.`Duel_MMRID` = `m`.`Duel_MMRID` \
		SET \
			`m`.`Rating` = %f, \
			`m`.`Deviation` = %f, \
			`m`.`GamesPlayed` = %d, \
			`m`.`LastGame` = %d, \
			`m`.`Wins` = %d \
		WHERE `g`.`SteamID64` LIKE '%s'",
		g_Players[team][iID].rating,
		g_Players[team][iID].deviation,
		g_Players[team][iID].gamesplayed,
		GetTime(),
		g_Players[team][iID].wins,
		g_Players[team][iID].steamid);

	fkn_log(true, "Query: %s", sQuery);
	hForsaken.Query(OnDuelCallback, sQuery);
}

void OnDuelCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		fkn_log(false, "Error: %s", error);
		return;
	}
}