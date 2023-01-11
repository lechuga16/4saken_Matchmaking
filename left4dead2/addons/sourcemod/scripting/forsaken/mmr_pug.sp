#if defined _mmr_pug_included
	#endinput
#endif
#define _mmr_pug_included

#define CONSTANT_SCORE 4.0	   // 4.0 players
public void RoundEnd_Pugs()
{
	if (g_iTeamScore[L4DTeam_Survivor] > g_iTeamScore[L4DTeam_Infected])
	{
		if (L4D2_AreTeamsFlipped())
		{
			if(g_cvarDebug.BoolValue)
				fkn_log("TeamA Win, TA:%d TB:%d", g_iTeamScore[L4DTeam_Survivor], g_iTeamScore[L4DTeam_Infected]);
			ProcessMMR(TeamA, Result_Win);
			ProcessMMR(TeamB, Result_Loss);
		}
		else
		{
			if(g_cvarDebug.BoolValue)
				fkn_log("TeamB Win, TA:%d TB:%d", g_iTeamScore[L4DTeam_Survivor], g_iTeamScore[L4DTeam_Infected]);
			ProcessMMR(TeamA, Result_Loss);
			ProcessMMR(TeamB, Result_Win);
		}
	}
	else if (g_iTeamScore[L4DTeam_Survivor] < g_iTeamScore[L4DTeam_Infected])
	{
		if (L4D2_AreTeamsFlipped())
		{
			if(g_cvarDebug.BoolValue)
				fkn_log("TeamA Loss, TA:%d TB:%d", g_iTeamScore[L4DTeam_Survivor], g_iTeamScore[L4DTeam_Infected]);
			ProcessMMR(TeamA, Result_Loss);
			ProcessMMR(TeamB, Result_Win);
		}
		else
		{
			if(g_cvarDebug.BoolValue)
				fkn_log("TeamB Win, TA:%d TB:%d", g_iTeamScore[L4DTeam_Survivor], g_iTeamScore[L4DTeam_Infected]);
			ProcessMMR(TeamA, Result_Win);
			ProcessMMR(TeamB, Result_Loss);
		}
	}
	else if (g_iTeamScore[L4DTeam_Survivor] == g_iTeamScore[L4DTeam_Infected])
	{
		if(g_cvarDebug.BoolValue)
			fkn_log("Team Draw, TA:%d TB:%d", g_iTeamScore[L4DTeam_Survivor], g_iTeamScore[L4DTeam_Infected]);
		ProcessMMR(TeamA, Result_Draw);
		ProcessMMR(TeamB, Result_Draw);
	}
	g_iTeamScore[L4DTeam_Survivor] = 0;
	g_iTeamScore[L4DTeam_Infected] = 0;
}

public void ProcessMMR(ForsakenTeam team, MatchResults Result)
{
	ForsakenTeam opponent;
	if (team == TeamA)
		opponent = TeamB;
	else
		opponent = TeamA;

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		float
			fSum_d,
			fGlicko_d,
			fFinalRD,
			fSum_FinalRating,
			fFinalRating;

		int iClient = g_Players[team][iID].client;

		if (iClient == CONSOLE)
			continue;

		for (int j = 0; j <= MAX_INDEX_PLAYER; j++)
		{
			fSum_d += Glicko_sum_d(g_Players[team][iID], g_Players[opponent][j]);
			fSum_FinalRating += Glicko_sum_FinalRating(g_Players[team][iID], g_Players[opponent][j], Result);
		}

		fGlicko_d	 = Glicko_d(fSum_d);
		fFinalRD	 = (Glicko_FinalRD(g_Players[team][iID], fGlicko_d) - g_Players[team][iID].deviation) / CONSTANT_SCORE;
		fFinalRating = (Glicko_FinalRating(g_Players[team][iID], fGlicko_d, fSum_FinalRating) - g_Players[team][iID].rating) / CONSTANT_SCORE;

		if (g_Players[team][iID].skill > 0.0)
		{
			fFinalRD += g_Players[team][iID].skill;
			g_Players[team][iID].skill = 0.0;
		}

		if (Result == Result_Win)
			g_Players[team][iID].wins++;

		int iGamesPlayed = g_Players[team][iID].gamesplayed++;

		if(EVALUATION_PERIOD < iGamesPlayed)
			g_Players[team][iID].deviation += fFinalRD;
		g_Players[team][iID].rating += fFinalRating;

		if(EVALUATION_PERIOD < iGamesPlayed)
			CPrintToChat(iClient, "%t %t", "Tag", "FinalScorePersonal", g_Players[TeamA][iID].rating, g_Players[TeamA][iID].deviation);
		else
			CPrintToChat(iClient, "%t %t", "Tag", "FinalScoreEvaluation", iGamesPlayed);

		char sQuery[512];
		Format(sQuery, sizeof(sQuery),
			   "UPDATE `users_mmr` AS m \
			INNER JOIN `users_general` AS g \
			ON \
				`g`.`MMRID` = `m`.`MMRID` \
			SET \
				`m`.`Rating` = %f, \
				`m`.`Deviation` = %f, \
				`m`.`GamesPlayed` = %d, \
				`m`.`LastGame` = %d, \
				`m`.`Wins` = %d \
			WHERE \
				`g`.`SteamID64` LIKE '%s'",
			   g_Players[team][iID].rating,
			   g_Players[team][iID].deviation,
			   g_Players[team][iID].gamesplayed,
			   GetTime(),
			   g_Players[team][iID].wins,
			   g_Players[team][iID].steamid);

		if (!SQL_FastQuery(g_dbForsaken, sQuery))
		{
			char error[512];
			SQL_GetError(g_dbForsaken, error, sizeof(error));
			fkn_log("Error: %s", error);
			fkn_log("Query: %s", sQuery);
			return;
		}
	}
}

public void ClienIndexList()
{
	for (int i = 1; i <= MAX_INDEX_PLAYER; i++)
	{
		if (!IsHuman(i))
			continue;

		char sStemaID[32];
		if (!GetClientAuthId(i, AuthId_SteamID64, sStemaID, sizeof(sStemaID)))
			continue;

		for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
		{
			if (StrEqual(g_Players[TeamA][iID].steamid, sStemaID))
			{
				if (g_Players[TeamA][iID].client != i)
				{
					g_Players[TeamA][iID].client = i;
					continue;
				}
			}

			if (StrEqual(g_Players[TeamB][iID].steamid, sStemaID))
			{
				if (g_Players[TeamB][iID].client != i)
				{
					g_Players[TeamB][iID].client = i;
					continue;
				}
			}
		}
	}
}

public void IndexPug(int iClient)
{
	if (g_TypeMatch == unranked || g_TypeMatch == invalid)
		return;

	char sStemaID[32];
	if (!GetClientAuthId(iClient, AuthId_SteamID64, sStemaID, sizeof(sStemaID)))
		return;

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		if (StrEqual(g_Players[TeamA][iID].steamid, sStemaID))
		{
			g_Players[TeamA][iID].client = iClient;
			continue;
		}

		if (StrEqual(g_Players[TeamB][iID].steamid, sStemaID))
		{
			g_Players[TeamB][iID].client = iClient;
			continue;
		}
	}
}

public void ProcessBonus(ForsakenTeam team)
{
	ForsakenTeam opponent;
	if (team == TeamA)
		opponent = TeamB;
	else
		opponent = TeamA;

	for (int iID = 0; iID <= MAX_INDEX_PLAYER; iID++)
	{
		float
			fSum_d,
			fGlicko_d,
			fFinalRD;

		int iClient = g_Players[team][iID].client;

		if (iClient == CONSOLE)
			continue;

		for (int j = 0; j <= MAX_INDEX_PLAYER; j++)
		{
			fSum_d += Glicko_sum_d(g_Players[team][iID], g_Players[opponent][j]);
		}

		fGlicko_d = Glicko_d(fSum_d);
		fFinalRD  = (Glicko_FinalRD(g_Players[team][iID], fGlicko_d) - g_Players[team][iID].deviation) / CONSTANT_SCORE;

		if (SURVMVP_GetMVP() == iClient)
		{
			float fBonus = fFinalRD * 0.3 * -1;
			g_Players[team][iID].skill += fBonus;
			CPrintToChat(iClient, "%t %t", "Tag", "BonusMVP", fBonus);
		}
		if (SURVMVP_GetMVPCI() == iClient)
		{
			float fBonus = fFinalRD * 0.3 * -1;
			g_Players[team][iID].skill += fBonus;
			CPrintToChat(iClient, "%t %t", "Tag", "BonusMVPCI", fBonus);
		}
	}
}