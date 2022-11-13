#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

public Plugin myinfo =
{
	name        = "SourceTV Anti Kick",
	description = "Prevents customers from kicking the sourcetv bot",
	author      = "Psyk0tik, Lechuga",
	version     = "2.0",
	url         = "https://forums.alliedmods.net/showthread.php?t=328435"
};

public void OnPluginStart()
{
	LoadTranslations("sourcetv_antikick.phrases");
	AddCommandListener(CmdCallVote, "callvote");
}

public Action CmdCallVote(int client, const char[] command, int argc)
{
	if(client == 0)
	{
		CReplyToCommand(client, "%t", "FailKickConsole");
		return Plugin_Continue;
	}

	if(!IsClientInGame(client))
		return Plugin_Continue;

	if(!IsClientConnected(client))
		return Plugin_Continue;


	char sType[16];
	GetCmdArg(1, sType, sizeof sType);
	if (!StrEqual(sType, "kick", false))
		return Plugin_Continue;

	char sTarget[32];
	GetCmdArg(2, sTarget, sizeof sTarget);
	int ClientTarget = GetClientOfUserId(StringToInt(sTarget));

	if(ClientTarget == 0)
		return Plugin_Continue;

	if (IsClientSourceTV(ClientTarget))
	{	
		CPrintToChat(client, "%t %t", "Tag", "FailKick");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}