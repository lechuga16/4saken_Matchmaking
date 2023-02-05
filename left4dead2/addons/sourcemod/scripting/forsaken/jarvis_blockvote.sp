#if defined _jarvis_blockvote_included
	#endinput
#endif
#define _jarvis_blockvote_included

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
	g_cvarVoteLobby,
	g_cvarVoteKick,
	g_cvarVoteMission;

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_BlockVote()
{
	g_cvarVoteLobby = CreateConVar("sm_jarvis_votelobby", "1", "Block voting to return to lobby", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarVoteKick = CreateConVar("sm_jarvis_votekick", "1", "Block voting to kick a player", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarVoteMission = CreateConVar("sm_jarvis_votemission", "1", "Block voting to change mission", FCVAR_NONE, true, 0.0, true, 1.0);
	AddCommandListener(VoteStart, "callvote");
}

public Action VoteStart(int iClient, const char[] sCommand, int iArg)
{
	if (!g_cvarEnable.BoolValue || g_bPreMatch || L4D_GetClientTeam(iClient) == L4DTeam_Spectator)
		return Plugin_Continue;

	if (!IsGameCompetitive(g_TypeMatch))
		return Plugin_Continue;

	if (!IsNewBuiltinVoteAllowed)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "TryAgain", CheckBuiltinVoteDelay());
		return Plugin_Continue;
	}

	char 
		sVoteType[32],
		sVoteArgument[32];

	GetCmdArg(1, sVoteType, sizeof(sVoteType));
	GetCmdArg(2, sVoteArgument, sizeof(sVoteArgument));

	if (strcmp(sVoteType, "ReturnToLobby", false) == 0 && g_cvarVoteLobby.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoVote", sTypeMatch[g_TypeMatch]);
		return Plugin_Handled;
	}

	if (strcmp(sVoteType, "Kick", false) == 0 && g_cvarVoteKick.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoVote", sTypeMatch[g_TypeMatch]);
		return Plugin_Handled;
	}

	if (strcmp(sVoteType, "ChangeMission", false) == 0 && g_cvarVoteMission.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoVote", sTypeMatch[g_TypeMatch]);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}