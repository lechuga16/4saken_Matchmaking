/*
    4Saken_stocks.inc
    Copyright (C) 2022 Lechuga

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

#if defined _forsaken_stocks_included
  #endinput
#endif
#define _forsaken_stocks_included

#include <sdktools_gamerules>
#include <json>
#include <forsaken_stocks_left4dhooks>

#define URL_FORSAKEN     	"forsaken-blk.herokuapp.com/queue/matchstatus"
#define URL_FORSAKEN_MATCH	"forsaken-blk.herokuapp.com/queue/get-match-info"
#define CONSOLE 0


// ==================================================
// ENUMS
// ==================================================

enum TypeMatch
{
	invalid  = 0,
	scout    = 1,
	adept    = 2,
	veteran  = 3,
	unranked = 4,
	scrims   = 5

}

enum ForsakenTeam
{
	Team0 = 0,
	Team1 = 1,
	Team2 = 2,
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

stock bool IsHuman(int iClient)
{
	if (IsClientConnected(iClient) && !IsFakeClient(iClient))
		return true;
	return false;
}

/**
 * Return true if the client is on the infected team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsInfected(int client)
{
	return (IsClientInGame(client) && L4D_GetClientTeam(client) == L4DTeam_Infected);
}

/**
 * Return true if the valid client index and is client on the infected team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsValidInfected(int client)
{
	return (IsValidClientIndex(client) && IsInfected(client));
}

/**
 * Returns true if the client is currently on the survivor team. 
 *
 * @param client client ID
 * @return bool
 */
stock bool IsSurvivor(int client)
{
	return (IsClientInGame(client) && L4D_GetClientTeam(client) == L4DTeam_Survivor);
}

/**
 * Return true if the valid client index and is client on the survivor team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsValidSurvivor(int client)
{
	return (IsValidClientIndex(client) && IsSurvivor(client));
}

/**
 * Returns a valid client indexed.
 *
 * @param client		Player's index.
 * @return				true if the client is valid, false if not.
 */
stock bool IsValidClient(int iClient)
{
	if (!IsValidClientIndex(iClient))
		return false;

	if (!IsClientInGame(iClient))
		return false;

	if (IsFakeClient(iClient))
		return false;

	return true;
}

/**
 * Returns a valid client indexed.
 *
 * @param client		Player's index.
 * @return				true if the client is valid, false if not.
 */
stock bool IsValidClientConsole(int iClient)
{
	if (iClient == CONSOLE)
		return true;

	if (iClient >= MaxClients)
		return false;

	if (!IsValidClientIndex(iClient))
		return false;

	if (!IsClientInGame(iClient))
		return false;

	if (IsFakeClient(iClient))
		return false;

	return true;
}

/**
 * Client indexed.
 *
 * @param client		Player's index.
 * @return				true if the client is valid, false if not.
 */
stock bool IsValidClientIndex(int iClient)
{
	return (iClient > CONSOLE && iClient <= MaxClients);
}

/**
 * Server ip written in IP.json
 *
 * @return				true when it returns the ip in char (length 64)
*/
stock char[] Forsaken_GetIP()
{
	char sIp[64];
	JSON_Object JoIp = Forsaken_JSON();
	JoIp.GetString("IP", sIp, sizeof(sIp));
	json_cleanup_and_delete(JoIp);
	return sIp;
}

/**
 * Get a json object from file IP.json
 *
 * @return				a JSON_Object
 */
stock JSON_Object Forsaken_JSON()
{
	char
		sPatch[128];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), "configs/forsaken/IP.json");

	JSON_Object obj = json_read_from_file(sPatch, JSON_ENCODE_PRETTY);
	return obj;
}

/**
 * Retrieves a list of maps from file Maps.json
 *
 * @return				a JSON_Array
 */
stock JSON_Array Forsaken_Maps()
{
	char
		sPatch[128];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), "configs/forsaken/Maps.json");

	JSON_Array arr = view_as<JSON_Array>(json_read_from_file(sPatch, JSON_NONE));
	return arr;
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

/**
 * Is the second round of this map currently being played?
 *
 * @return true is the second round, false if not.
 */
stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}