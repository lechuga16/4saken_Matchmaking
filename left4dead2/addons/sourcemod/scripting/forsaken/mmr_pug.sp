#if defined _mmr_pug_included
	#endinput
#endif
#define _mmr_pug_included

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

public void RoundEnd_Pugs()
{
	if (!IsPug(g_TypeMatch))
		return;

	ProcessBonus(TeamA);
	ProcessBonus(TeamB);

	if (!InSecondHalfOfRound())
		return;

	ProcesPug();
}

void ProcesPug()
{
	if (g_iTeamScore[TeamA] > g_iTeamScore[TeamB])
	{
		if (AreTeamsFlipped())
		{
			fkn_log(true, "TeamA Win, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingPug(TeamA, Result_Win);
			ProcessRatingPug(TeamB, Result_Loss);
		}
		else
		{
			fkn_log(true, "TeamB Win, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingPug(TeamA, Result_Loss);
			ProcessRatingPug(TeamB, Result_Win);
		}
	}
	else if (g_iTeamScore[TeamA] < g_iTeamScore[TeamB])
	{
		if (AreTeamsFlipped())
		{
			fkn_log(true, "TeamA Loss, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingPug(TeamA, Result_Loss);
			ProcessRatingPug(TeamB, Result_Win);
		}
		else
		{
			fkn_log(true, "TeamB Win, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
			ProcessRatingPug(TeamA, Result_Win);
			ProcessRatingPug(TeamB, Result_Loss);
		}
	}
	else if (g_iTeamScore[TeamA] == g_iTeamScore[TeamB])
	{
		fkn_log(true, "Team Draw, TA:%d TB:%d", g_iTeamScore[TeamA], g_iTeamScore[TeamB]);
		ProcessRatingPug(TeamA, Result_Draw);
		ProcessRatingPug(TeamB, Result_Draw);
	}
	g_iTeamScore[TeamA] = 0;
	g_iTeamScore[TeamB] = 0;
}

void ProcessRatingPug(ForsakenTeam team, MatchResults Result)
{
	Database hForsaken = Connect(); 
	if (hForsaken == null)
	{
		fkn_log(true, "Could not connect to database (null)");
		return;
	}

	ForsakenTeam opponent = GetOpponent(team);

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		float
			fSum_d,
			fGlicko_d,
			fFinalRD,
			fSum_FinalRating,
			fFinalRating;

		for (int jID = 0; jID <= MAX_INDEX_PLAYER; jID++)
		{
			fSum_d += Glicko_sum_d(g_Players[team][iID], g_Players[opponent][jID]);
			fSum_FinalRating += Glicko_sum_FinalRating(g_Players[team][iID], g_Players[opponent][jID], Result);
		}

		fGlicko_d	 = Glicko_d(fSum_d);
		fFinalRD	 = (Glicko_FinalRD(g_Players[team][iID], fGlicko_d) - g_Players[team][iID].deviation);
		fFinalRating = (Glicko_FinalRating(g_Players[team][iID], fGlicko_d, fSum_FinalRating) - g_Players[team][iID].rating);

		if (g_Players[team][iID].skill > 0.0)
		{
			fFinalRD += g_Players[team][iID].skill;
			g_Players[team][iID].skill = 0.0;
		}

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
			"UPDATE `users_mmr` AS m \
			INNER JOIN `users_general` AS g \
			ON `g`.`Pug_MMRID` = `m`.`Pug_MMRID` \
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

		fkn_log(true, "sQuery: %s", sQuery);

		hForsaken.Query(OnPugCallback, sQuery);
	}
}

void OnPugCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		fkn_log(false, "Error: %s", error);
		return;
	}
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

public void ProcessBonus(ForsakenTeam team)
{
	ForsakenTeam opponent;
	if (team == TeamA)
		opponent = TeamB;
	else
		opponent = TeamA;

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		int 
			iMVP = SURVMVP_GetMVP(),
			iMVPCI = SURVMVP_GetMVPCI();

		if (iMVP != g_Players[team][iID].client && iMVPCI != g_Players[team][iID].client)
			return;

		if (EVALUATION_PERIOD >= (g_Players[team][iID].gamesplayed + 1) && IsValidClient(g_Players[team][iID].client))
		{
			CPrintToChat(g_Players[team][iID].client, "%t %t", "Tag", "NoBonus");
			continue;
		}

		float
			fSum_d,
			fGlicko_d,
			fFinalRD;

		for (int j = 0; j <= MAX_INDEX_PLAYER; j++)
		{
			fSum_d += Glicko_sum_d(g_Players[team][iID], g_Players[opponent][j]);
		}

		fGlicko_d = Glicko_d(fSum_d);
		fFinalRD  = (Glicko_FinalRD(g_Players[team][iID], fGlicko_d) - g_Players[team][iID].deviation);

		if (iMVP == g_Players[team][iID].client)
		{
			g_Players[team][iID].skill += (fFinalRD * 0.3 * -1);
			if(IsValidClient(g_Players[team][iID].client))
				CPrintToChat(g_Players[team][iID].client, "%t %t", "Tag", "BonusMVP", (fFinalRD * 0.3 * -1));
		}
		if (iMVPCI == g_Players[team][iID].client)
		{
			g_Players[team][iID].skill += (fFinalRD * 0.3 * -1);
			if(IsValidClient(g_Players[team][iID].client))
				CPrintToChat(g_Players[team][iID].client, "%t %t", "Tag", "BonusMVPCI", (fFinalRD * 0.3 * -1));
		}
	}
}
