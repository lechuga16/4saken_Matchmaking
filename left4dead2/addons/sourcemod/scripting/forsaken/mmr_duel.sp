#if defined _mmr_1v1_included
	#endinput
#endif
#define _mmr_1v1_included

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OCA_Duel(int iClient)
{
	if (g_TypeMatch == duel)
		IndexClientAuthorized_Duel(iClient);
}

public void ORLC_Duel()
{
	if (g_TypeMatch == duel)
		IndexClientAll_Duel();
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

public void RoundEnd_Duel()
{
	if (InSecondHalfOfRound())
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

	int iClient = g_Players[team][iID].client;

	if (iClient == CONSOLE)
		return;

	fSum_d += Glicko_sum_d(g_Players[team][iID], g_Players[opponent][jID]);
	fSum_FinalRating += Glicko_sum_FinalRating(g_Players[team][iID], g_Players[opponent][jID], Result);

	fGlicko_d	 = Glicko_d(fSum_d);
	fFinalRD	 = (Glicko_FinalRD(g_Players[team][iID], fGlicko_d) - g_Players[team][iID].deviation);
	fFinalRating = (Glicko_FinalRating(g_Players[team][iID], fGlicko_d, fSum_FinalRating) - g_Players[team][iID].rating);

	if (Result == Result_Win)
		g_Players[team][iID].wins++;

	int iGamesPlayed = g_Players[team][iID].gamesplayed++;

	if (EVALUATION_PERIOD < iGamesPlayed)
		g_Players[team][iID].deviation += fFinalRD;
	g_Players[team][iID].rating += fFinalRating;

	if (EVALUATION_PERIOD < iGamesPlayed)
		CPrintToChat(iClient, "%t %t", "Tag", "FinalScorePersonal", g_Players[team][iID].rating, g_Players[team][iID].deviation);
	else
		CPrintToChat(iClient, "%t %t", "Tag", "FinalScoreEvaluation", (EVALUATION_PERIOD - iGamesPlayed));

	char sQuery[512];
	g_dbForsaken.Format(sQuery, sizeof(sQuery),
		"UPDATE `duel_mmr` \
		SET `Rating` = %f, \
			`Deviation` = %f, \
			`GamesPlayed` = %d, \
			`LastGame` = %d, \
			`Wins` = %d \
		WHERE `Duel_MMRID` LIKE '%d'",
		g_Players[team][iID].rating,
		g_Players[team][iID].deviation,
		g_Players[team][iID].gamesplayed,
		GetTime(),
		g_Players[team][iID].wins,
		g_Players[team][iID].client);

	fkn_log(true, "Query: %s", sQuery);
	g_dbForsaken.Query(OnDuelCallback, sQuery);
}

void OnDuelCallback(Database db, DBResultSet results, const char[] error, any data)
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

void IndexClientAuthorized_Duel(int iClient)
{
	char sStemaID[32];
	if (!GetClientAuthId(iClient, AuthId_SteamID64, sStemaID, sizeof(sStemaID)))
		return;

	int iID = 0;
	if (StrEqual(g_Players[TeamA][iID].steamid, sStemaID))
	{
		g_Players[TeamA][iID].client = iClient;
		return;
	}

	if (StrEqual(g_Players[TeamB][iID].steamid, sStemaID))
	{
		g_Players[TeamB][iID].client = iClient;
		return;
	}
}

void IndexClientAll_Duel()
{
	for (int i = 1; i <= MAX_INDEX_PLAYER; i++)
	{
		if (!IsHuman(i))
			return;

		char sStemaID[32];
		if (!GetClientAuthId(i, AuthId_SteamID64, sStemaID, sizeof(sStemaID)))
			return;

		int iID = 0;
		if (StrEqual(g_Players[TeamA][iID].steamid, sStemaID))
		{
			g_Players[TeamA][iID].client = i;
			return;
		}

		if (StrEqual(g_Players[TeamB][iID].steamid, sStemaID))
		{
			g_Players[TeamB][iID].client = i;
			return;
		}
	}
}