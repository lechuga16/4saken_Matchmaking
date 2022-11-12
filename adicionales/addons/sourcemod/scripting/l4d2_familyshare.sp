
/*  This add-on is based on "Family Share Manager" v1.5.5.
 *   https://forums.alliedmods.net/showthread.php?t=293927
 */
#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sourcemod>
#include <SteamWorks>

ConVar g_cvarEnabled;

public Plugin myinfo =
{
	name        = "L4D2 Family Share",
	author      = "Lechuga",
	description = "Kick and register players with shared games.",
	version     = "1.1",
	url         = ""
};

public void OnPluginStart()
{
	LoadTranslation("l4d2_familyshare.phrases");
	g_cvarEnabled = CreateConVar("l4d2_familyshare", "0", "Enable notifications.", FCVAR_NONE, true, 0.0, true, 1.0);
}

void LoadTranslation(char[] sTranslation)
{
	char 
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", sTranslation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file %s.txt", sTranslation);
	}
	LoadTranslations(sTranslation);
}

stock int GetClientOfAuthId(int authid)
{
	for (int index = 1; index <= MaxClients; index++)
	{
		if (IsClientConnected(index))
		{
			char steamid[32];
			GetClientAuthId(index, AuthId_Steam3, steamid, sizeof(steamid));
			char split[3][32];
			ExplodeString(steamid, ":", split, sizeof(split), sizeof(split[]));
			ReplaceString(split[2], sizeof(split[]), "]", "");

			int auth = StringToInt(split[2]);
			if (auth == authid)
			{
				return index;
			}
		}
	}
	return -1;
}

public void SteamWorks_OnValidateClient(int ownerauthid, int authid)
{
	int client = GetClientOfAuthId(authid);

	if(IsValidClientIndex(client))
	{
		if (ownerauthid != authid)
		{
			char
				bufferKick[128],
				clientname[128],
				steamid[32],
				steamidowner[32],
				logFile[100];

			GetClientName(client, clientname, sizeof(clientname));
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
			GetSteam2FromAccountId(steamidowner, sizeof(steamidowner), ownerauthid);

			BuildPath(Path_SM, logFile, PLATFORM_MAX_PATH, "/logs/FamilyShare.log");
			LogToFile(logFile, "[Name: %s | Player: %s | Owner Account: %s]", clientname, steamid, steamidowner);

			Format(bufferKick, sizeof(bufferKick), "%t", "KickClient");
			if(g_cvarEnabled.BoolValue)
			{
				CPrintToChatAll("%t %t", "Tag", "KickAnnouncer", clientname);
			}
			KickClient(client, bufferKick);
		}
	}
}

// https://forums.alliedmods.net/showthread.php?t=324112
int GetSteam2FromAccountId(char[] SteamID2, int maxlen, int SteamID3)
{
	return Format(SteamID2, maxlen, "STEAM_1:%d:%d", view_as<bool>(SteamID3 % 2), SteamID3 / 2);
}

stock bool IsValidClientIndex(int client)
{
	return (client > 0 && client <= MaxClients);
}