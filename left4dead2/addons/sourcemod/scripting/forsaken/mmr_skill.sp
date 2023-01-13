#if defined _mmr_skill_included
	#endinput
#endif
#define _mmr_skill_included

native int	 SURVMVP_GetMVP();
native int	 SURVMVP_GetMVPCI();
native float SURVMVP_GetMVPDmgPercent(int client);
native float SURVMVP_GetMVPCIPercent(int client);

public SharedPlugin __pl_survivor_mvp = {
	required = 0,
};

public void __pl_survivor_mvp_SetNTVOptional()
{
	MarkNativeAsOptional("SURVMVP_GetMVP");
	MarkNativeAsOptional("SURVMVP_GetMVPCI");
	MarkNativeAsOptional("SURVMVP_GetMVPDmgPercent");
	MarkNativeAsOptional("SURVMVP_GetMVPCIPercent");
}

public int CheckMVPList(bool bIsMVP)
{
	if (ClientMVP(bIsMVP) == CONSOLE)
		return 0;

	if (!AreTeamsFlipped())
		return MVPListed(TeamA, bIsMVP);
	else
		return MVPListed(TeamB, bIsMVP);
}

public int MVPListed(ForsakenTeam team, bool bIsMVP)
{
	for (int i = 0; i <= MAX_INDEX_PLAYER; i++)
	{
		char sSteamID[32];
		GetClientAuthId(ClientMVP(bIsMVP), AuthId_SteamID64, sSteamID, sizeof(sSteamID));
		if (StrEqual(g_Players[team][i].steamid, sSteamID))
		{
			return i;
		}
	}
	return 0;
}

public float ClientDMGPercent(bool bIsMVP)
{
	if (bIsMVP)
		return SURVMVP_GetMVPDmgPercent(ClientMVP(bIsMVP));
	else
		return SURVMVP_GetMVPCIPercent(ClientMVP(bIsMVP));
}

public int ClientMVP(bool bIsMVP)
{
	if (bIsMVP)
		return SURVMVP_GetMVP();
	else
		return SURVMVP_GetMVPCI();
}