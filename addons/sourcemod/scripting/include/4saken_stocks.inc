/*
    SourceMod Anti-Cheat
    Copyright (C) 2011-2016 SMAC Development Team
    Copyright (C) 2007-2011 CodingDirect LLC
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#if defined _4saken_stocks_included
  #endinput
#endif
#define _4saken_stocks_included

#define CONSOLE 0
#define _4SAKEN_DIR_CFG "configs/4saken.cfg"

// ==================================================
// ENGINE STOCKS
// ==================================================
static EngineVersion g_iEngine;

/**
 * @brief Returns if the server is running on Left 4 Dead 2
 *
 * @return					Returns true if server is running on Left 4 Dead 2
 */
stock bool L4D_IsEngineLeft4Dead2()
{
	if( g_iEngine == Engine_Unknown )
	{
		g_iEngine = GetEngineVersion();
	}

	return g_iEngine == Engine_Left4Dead2;
}

// ==================================================
// ENUMS
// ==================================================
enum L4DTeam
{
	L4DTeam_Unassigned				= 0,
	L4DTeam_Spectator				= 1,
	L4DTeam_Survivor				= 2,
	L4DTeam_Infected				= 3
}

// ==================================================
// FUNCTIONS
// ==================================================

/**
 * Returns the name of the plugin.
 */
stock void GetPluginBasename(Handle plugin, char[] buffer,int maxlength)
{
    GetPluginFilename(plugin, buffer, maxlength);

    int check = -1;
    if ((check = FindCharInString(buffer, '/', true)) != -1 ||
        (check = FindCharInString(buffer, '\\', true)) != -1)
    {
        Format(buffer, maxlength, "%s", buffer[check+1]);
    }
}

/**
 * Returns the clients team using L4DTeam.
 *
 * @param client		Player's index.
 * @return				Current L4DTeam of player.
 * @error				Invalid client index.
 */
stock L4DTeam L4D_GetClientTeam(int client)
{
	int team = GetClientTeam(client);
	return view_as<L4DTeam>(team);
}

/**
 * Returns a valid client indexed.
 *
 * @param client		Player's index.
 * @return				true if the client is valid, false if not.
 */
stock bool IsValidClient(int iClient)
{
	if (!IsValidClientIndex(iClient) || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return false;

	return true;
}

/**
 * Returns a client indexed.
 *
 * @param client		Player's index.
 * @return				true if the client is valid, false if not.
 */
stock bool IsValidClientIndex(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients);
}

/**
 * Get 4saken IP address using KeyValue.
 *
 * @param section       section inside the keyvalue
 * @param key        	key inside keyvalue
 * @param buffer        String to store.
 * @param maxlength     Maximum size of string buffer.
 * @return				true if a value was extracted, false if the section is not valid.
 */
stock bool _4saken_KvGet(const char[] section, char[] key, char[] buffer, int maxlength)
{
	char
		sPatch[64];

	BuildPath(Path_SM, sPatch, sizeof(sPatch), _4SAKEN_DIR_CFG);
	KeyValues kv = new KeyValues("4saken");
	kv.ImportFromFile(sPatch);

	if (!kv.JumpToKey(section))
	{
		_4saken_log("KeyValue: %s not found", sPatch);
		return false;
	}

	kv.GetString(key, buffer, maxlength, "KeyNotFound");
	if(StrEqual(buffer, "KeyNotFound", false))
	{
		_4saken_log("KeyValue: %s not found", key);
		return false;
	}
	delete kv;

	return true;
}

/**
 * Check if the translation file exists
 *
 * @param translation       translation file name
 */
stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file %s.txt", translation);
	}
	LoadTranslations(translation);
}