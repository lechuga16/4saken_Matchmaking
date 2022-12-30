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
	if(L4D_GetTeamScore(view_as<int>(TeamA)) > L4D_GetTeamScore(view_as<int>(TeamB)))
	{
		if(g_cvarDebug.BoolValue)
			fkn_log("TeamA Win, TA:%d TB:%d", L4D_GetTeamScore(view_as<int>(TeamA)), L4D_GetTeamScore(view_as<int>(TeamB)));
	}
	else if(L4D_GetTeamScore(view_as<int>(TeamA)) < L4D_GetTeamScore(view_as<int>(TeamB)))
	{
		if(g_cvarDebug.BoolValue)
			fkn_log("TeamB Win, TA:%d TB:%d", L4D_GetTeamScore(view_as<int>(TeamA)), L4D_GetTeamScore(view_as<int>(TeamB)));
	}
	else
	{
		if(g_cvarDebug.BoolValue)
			fkn_log("Draw, TA:%d TB:%d", L4D_GetTeamScore(view_as<int>(TeamA)), L4D_GetTeamScore(view_as<int>(TeamB)));
	}
}