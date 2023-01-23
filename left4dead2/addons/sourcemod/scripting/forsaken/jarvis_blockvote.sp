#if defined _jarvis_blockvote_included
	#endinput
#endif
#define _jarvis_blockvote_included

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart_BlockVote()
{
	AddCommandListener(VoteStart, "callvote");
}

public Action VoteStart(int iClient, const char[] sCommand, int iArg)
{
	if (!g_cvarEnable.BoolValue || g_bPreMatch || L4D_GetClientTeam(iClient) == L4DTeam_Spectator)
		return Plugin_Continue;

	if (g_TypeMatch == invalid || g_TypeMatch == unranked)
		return Plugin_Continue;

	if (!IsNewBuiltinVoteAllowed)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "TryAgain", CheckBuiltinVoteDelay());
		return Plugin_Continue;
	}

	char sVoteType[32];
	char sVoteArgument[32];

	GetCmdArg(1, sVoteType, sizeof(sVoteType));
	GetCmdArg(2, sVoteArgument, sizeof(sVoteArgument));

	if (strcmp(sVoteType, "ReturnToLobby", false) == 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoVote", sTypeMatch[g_TypeMatch]);
		return Plugin_Handled;
	}

	if (strcmp(sVoteType, "Kick", false) == 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoVote", sTypeMatch[g_TypeMatch]);
		return Plugin_Handled;
	}

	if (strcmp(sVoteType, "ChangeMission", false) == 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoVote", sTypeMatch[g_TypeMatch]);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}