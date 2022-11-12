/*
This plugin is based on 'L4D2 Block Healing'
https://forums.alliedmods.net/showthread.php?p=1638755
*/
#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

ConVar g_cvarEnable;

public Plugin myinfo =
{
	name        = "[L4D2] Block Medikits",
	author      = "Lechuga",
	description = "Blocks the use of medikits",
	version     = PLUGIN_VERSION,
	url         = "https://pastebin.com/0pJ9z05x"
}

public APLRes
	AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_blockmedikits_version", PLUGIN_VERSION, "Plugin Version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarEnable = CreateConVar("sm_blockmedikits", "0", "Activate the lock on the medkits.", FCVAR_NONE, true, 0.0, true, 1.0);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (g_cvarEnable.BoolValue)
	{
		if (IsClientInGame(client))
		{
			if (weapon > 0 && IsValidEdict(weapon))
			{
				char classname[64];
				GetEdictClassname(weapon, classname, 64);
				if (StrEqual(classname, "weapon_first_aid_kit"))
				{
					weapon = GetPlayerMainWeapon(client);
				}
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

static int GetPlayerMainWeapon(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon <= 0 || !IsValidEdict(weapon))
	{
		weapon = GetPlayerWeaponSlot(client, 1);
		if (weapon <= 0 || !IsValidEdict(weapon))
		{
			weapon = 0;
		}
	}
	return weapon;
}