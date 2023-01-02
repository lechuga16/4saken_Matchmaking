#if defined _mmr_pug_included
	#endinput
#endif
#define _mmr_pug_included

public void PugMatch()
{
	if (g_TypeMatch != scout || g_TypeMatch != adept || g_TypeMatch != veteran)
		return;
}

public void RoundEnd_Pugs()
{
	if (L4D_GetTeamScore(view_as<int>(TeamA)) > L4D_GetTeamScore(view_as<int>(TeamB)))
	{
		if (g_cvarDebug.BoolValue)
			fkn_log("TeamA Win, TA:%d TB:%d", L4D_GetTeamScore(view_as<int>(TeamA)), L4D_GetTeamScore(view_as<int>(TeamB)));

		float fSum_d;
		for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
		{
			fSum_d += Glicko_sum_d(g_Players[TeamA][i], g_Players[TeamB][i]);
		}

		float fGlicko_d = Glicko_d(fSum_d);

		for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
		{
			g_Players[TeamA][i].deviation = Glicko_FinalRD(g_Players[TeamA][i], fGlicko_d)
		}

		float fSum_FinalRating;
		for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
		{
			fSum_FinalRating += Glicko_sum_FinalRating(g_Players[TeamA][i], g_Players[TeamB][i], Result_Win);
		}

		for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
		{
			g_Players[TeamA][i].rating = Glicko_FinalRating(g_Players[TeamA][i], fGlicko_d, fSum_FinalRating);
		}
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

public void ProcessMMR(ForsakenTeam Winner, MatchResults Result)
{
	ForsakenTeam Loose;
	if(Winner == TeamA)
		Loose = TeamB;
	else
		Loose = TeamA;

	for (int i = 0; i <= 3; i++)
	{
		float
			fSum_d,
			fGlicko_d,
			fSum_FinalRating;
		for (int j = 0; i <= 3; i++)
		{
			fSum_d += Glicko_sum_d(g_Players[Winner][i], g_Players[Loose][j]);
			fSum_FinalRating += Glicko_sum_FinalRating(g_Players[Winner][i], g_Players[Loose][j], Result);
		}

		fGlicko_d					   = Glicko_d(fSum_d);
		g_Players[Winner][i].deviation = Glicko_FinalRD(g_Players[Winner][i], fGlicko_d);
		g_Players[Winner][i].rating	   = Glicko_FinalRating(g_Players[Winner][i], fGlicko_d, fSum_FinalRating);
	}
}