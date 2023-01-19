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
#include <forsaken_left4dhooks>
#include <forsaken_l4d2util>

#define URL_STATUS		   "forsaken-blk.herokuapp.com/queue/matchstatus"
#define URL_STATUSV2	   "forsaken-blk.herokuapp.com/queue/matchstatusV2"
#define URL_FORSAKEN_MATCH "forsaken-blk.herokuapp.com/queue/get-match-info"
#define URL_IPV4		   "api.ipify.org?format=json"
#define DIR_IPV4		   "logs/forsaken_IPv4.json"
#define DIR_CACHEMATCH	   "logs/forsaken_match.json"
#define DIR_IP			   "configs/forsaken/IP.json"

#define DIR_FORSAKENLOG	   "logs/forsaken.log"
#define MAX_PLAYER_TEAM	   4
#define MAX_INDEX_PLAYER   3
#define CONSOLE			   0
#define UNIXTIME_4WEEKS	   2419200
#define EVALUATION_PERIOD  8

// ==================================================
// ENUMS
// ==================================================

/**
 * Basic structure of a player.
 */
enum struct PlayerBasic
{
	char steamid[MAX_AUTHID_LENGTH];	// Player SteamID
	char name[MAX_NAME_LENGTH];			// Player name
}

/**
 * Basic structure of an entity for Glicko calculation.
 */
enum struct GlickoBasic
{
	float rating;		// Glicko Score
	float deviation;	// Glicko deviation
}

/**
 * Player profile.
 *
 */
enum struct PlayerInfo
{
	int	  client;						 // client index
	char  steamid[MAX_AUTHID_LENGTH];	 // Player SteamID
	char  name[MAX_NAME_LENGTH];		 // Player name
	float rating;						 // Glicko Score
	float deviation;					 // Glicko deviation
	float skill;						 // Bonus deviation
	int	  gamesplayed;					 // Number of games played
	int	  lastgame;						 // Last Score Update
	int	  wins;							 // Number of games won
}

stock PlayerInfo  g_Players[ForsakenTeam][MAX_PLAYER_TEAM];
stock PlayerBasic g_PlayersBasic[ForsakenTeam][MAX_PLAYER_TEAM];

/**
 * Types of match.
 */
enum TypeMatch
{
	invalid		   = 0,
	scout		   = 1,
	adept		   = 2,
	veteran		   = 3,
	unranked	   = 4,
	scrims		   = 5,

	TypeMatch_Size = 6
};

/**
 * Team types in forsaken format.
 */
enum ForsakenTeam
{
	Team0			  = 0,
	TeamA			  = 1,
	TeamB			  = 2,

	ForsakenTeam_Size = 3
};

/**
 * Types of game cancellation
 */
enum MatchClosing
{
	endgame			  = 0,
	ragequit		  = 1,
	desertion		  = 2,
	admin			  = 3,
	unknown			  = 4,

	MatchClosing_Size = 5
};

/**
 * Unix time.
 */
enum UnixTime
{
	Sec			  = 0,
	Min			  = 1,
	Hour		  = 2,
	Day			  = 3,
	Week		  = 4,

	UnixTime_Size = 5
};

enum TypeBans
{
	Bancode01	 = 0,
	Bancode02	 = 1,
	Bancode03	 = 2,

	Bancode_Size = 3
};

// ==================================================
// Array
// ==================================================

/**
 * Array that names the match types
 */
stock const char sTypeMatch[TypeMatch_Size][] = {
	"Invalid",
	"Scout",
	"Adept",
	"Veteran",
	"Unranked",
	"Scrims"
};

/**
 * Array that names the team types in left4d format.
 */
stock const char sL4DTeam[4][] = {
	"Unassigned",
	"Spectator",
	"Survivor",
	"Infected"
};

/**
 * Array that names the team types in forsaken format.
 */
stock const char sForsakenTeam[ForsakenTeam_Size][] = {
	"Team0",
	"TeamA",
	"TeamB"
};

/**
 * Array that names the cancel match types.
 */
stock const char sMatchClosing[MatchClosing_Size][] = {
	"EndGame",
	"RageQuit",
	"Desertion",
	"Admin",
	"Unknown"
};

stock const char sTypeBans[Bancode_Size][] = {
	"BanCode:01",
	"BanCode:02",
	"BanCode:03"
};

// ==================================================
// FUNCTIONS
// ==================================================

stock bool IsHuman(int iClient)
{
	if (IsClientConnected(iClient) && !IsFakeClient(iClient))
		return true;
	return false;
}

/**
 * Returns a valid client indexed.
 *
 * @param iClient		Client index.
 * @return				True if the client is valid, false otherwise.
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
 * Server ip written in IP.json
 *
 * @return				IP
 */
stock char[] fkn_GetIP()
{
	char
		sIp[64],
		sPatch[128];

	BuildPath(Path_SM, sPatch, sizeof(sPatch), DIR_IP);
	JSON_Object JoIp = json_read_from_file(sPatch, JSON_ENCODE_PRETTY);
	JoIp.GetString("IP", sIp, sizeof(sIp));
	json_cleanup_and_delete(JoIp);
	return sIp;
}

/**
 * Check if the translation file exists
 *
 * @param translation	Translation name.
 * @noreturn
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
 * @return				true if the second round is being played, false if not.
 * @error				Invalid game rules handle, property and property type.
 */
stock bool InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound") ? true : false;
}

/**
 * Convert any SteamId format to SteamID64
 *
 * @param sCommunityID		SteamID64
 * @param iSize				Max size of sCommunityID
 * @param sSteamID			SteamID
 */
stock void SteamIDToCommunityID(char[] sCommunityID, int iSize, const char[] sSteamID)
{
	char sBuffer[3][32];
	ExplodeString(sSteamID, ":", sBuffer, 3, 32);
	int accountID = StringToInt(sBuffer[2]) * 2 + StringToInt(sBuffer[1]);

	IntToString((accountID + 60265728), sCommunityID, iSize);

	if (accountID >= 39734272)
	{
		strcopy(sCommunityID, iSize, sCommunityID[1]);
		Format(sCommunityID, iSize, "765611980%s", sCommunityID);
	}
	else
	{
		Format(sCommunityID, iSize, "765611979%s", sCommunityID);
	}
}

/**
 * Convert AccountID to SteamID
 *
 * @param sSteamID			SteamID
 * @param iSize				Max size of sSteamID
 * @param sCommunityID		SteamID64
 * @return					AccountID
 */
stock int GetSteam2FromAccountId(char[] buffer, int maxlen, int accountid)
{
	return Format(buffer, maxlen, "STEAM_1:%d:%d", view_as<bool>(accountid % 2), accountid / 2);
}

/**
 * Tests whether a string is found inside another string.
 *
 * @param str           String to search in.
 * @param substr        Substring to find inside the original string.
 * @param caseSensitive If true (default), search is case sensitive.
 *                      If false, search is case insensitive.
 * @return 				True if find, false otherwise.
 */
stock bool FindString(const char[] str, const char[] substr, bool caseSensitive = true)
{
	return (StrContains(str, substr, caseSensitive) != -1);
}

/**
 * Returns amounts of a set format from a unix date.
 *
 * @param iUnixTime		Unix date.
 * @param type			UnixTime Format.
 * @return				Amount of the format.
 * @error				Invalid UnixTime Format.
 * @note				Week = 604800, Day = 86400, Hour = 3600, Min = 60, Sec = 1
 */
stock int FromUnixTime(int iUnixTime, UnixTime type)
{
	if (iUnixTime == 0)
		return 0;

	switch (type)
	{
		case Week:
			return (iUnixTime / 604800);
		case Day:
			return (iUnixTime / 86400);
		case Hour:
			return (iUnixTime / 3600);
		case Min:
			return (iUnixTime / 60);
		case Sec:
			return (iUnixTime % 60);
		default:
			return 0;
	}
}

/**
 * Given a target string, like "Hydrogen", "#32", "@me", "@all", this function will populate an array of client indices
 * that match the target string.
 *
 * @param Admin                 Client index of the admin who triggered the command.
 * @param TargettedString        The string containing the target(s), such as "Hydrogen", "#32", "@me", "@all". https://wiki.alliedmods.net/Admin_Commands_(SourceMod)
 * @param FilterFlag            Filter flag rules such as COMMAND_FILTER_NO_IMMUNITY. Find them here: https://sm.alliedmods.net/api/index.php?fastload=file&id=45&
 * @param ApplicableClients        Integer array initialized to all 0s. When this function finds matches, client indices will be stored in this array.
 * @param maxlen                Maximum length of the integer array.
 *
 * @return                         The number of matching clients found (or 0 if no matching clients have been found).
 *                                 You should use this number to iterate across the ApplicableClients array in the parent function.
 */
stock int GetApplicableClients(int Admin, const char[] TargettedString, int FilterFlag, int[] ApplicableClients, int maxlen)
{
	// Initialization:
	char TargetName[MAX_TARGET_LENGTH];
	bool tn_is_ml;

	// Process it:
	int	 TargetCount = ProcessTargetString(TargettedString, Admin, ApplicableClients, maxlen, FilterFlag, TargetName, sizeof(TargetName), tn_is_ml);

	// No targets? Bail out.
	if (TargetCount <= 0)
		return 0;

	// Otherwise, success!
	return TargetCount;
}

/**
 * Returns if the current game is competitive
 *
 * @return				True if the game is competitive, false otherwise.
 */
stock bool IsGameCompetitive(TypeMatch Match)
{
	return (Match == scrims || Match == veteran || Match == adept || Match == scout);
}

stock bool AreTeamsFlipped()
{
	return GameRules_GetProp("m_bAreTeamsFlipped") ? true : false;
}

stock int LogicTeamsFlipped()
{
	return GameRules_GetProp("m_bAreTeamsFlipped") ? 2 : 1;
}

// ==================================================
// forsaken's functions
// ==================================================

stock void fkn_log(const char[] sMessage, any...)
{
	static int check = -1;
	static char
		sFormat[512],
		sFilename[64],
		sLogPath[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), DIR_FORSAKENLOG);
	VFormat(sFormat, sizeof(sFormat), sMessage, 2);

	GetPluginFilename(null, sFilename, sizeof(sFilename));
	if ((check = FindCharInString(sFilename, '/', true)) != -1 || (check = FindCharInString(sFilename, '\\', true)) != -1)
		Format(sFilename, sizeof(sFilename), "%s", sFilename[check + 1]);

	ReplaceString(sFilename, sizeof(sFilename), ".smx", "", false);
	LogToFileEx(sLogPath, "[%s] %s", sFilename, sFormat);
}

stock JSON_Object JsonObjectMatch(char[] sDirectory)
{
	char sPatch[64];
	BuildPath(Path_SM, sPatch, sizeof(sPatch), sDirectory);
	return json_read_from_file(sPatch);
}

stock int fkn_QueueID()
{
	int			iQueueID = 0;
	JSON_Object joMatch	 = JsonObjectMatch(DIR_CACHEMATCH);

	if (joMatch == null)
	{
		fkn_log("Error: fkn_QueueID() - (joMatch == null)");
		return iQueueID;
	}

	iQueueID = joMatch.GetInt("queueid");
	json_cleanup_and_delete(joMatch);
	return iQueueID;
}

stock TypeMatch fkn_TypeMatch()
{
	TypeMatch	Type	= invalid;
	JSON_Object joMatch = JsonObjectMatch(DIR_CACHEMATCH);

	if (joMatch == null)
	{
		fkn_log("Error: fkn_TypeMatch() - (joMatch == null)");
		return Type;
	}

	Type = view_as<TypeMatch>(joMatch.GetInt("region"));
	json_cleanup_and_delete(joMatch);
	return Type;
}

stock bool fkn_MapName(char[] sBuffer, int iMaxlength)
{
	JSON_Object joMatch = JsonObjectMatch(DIR_CACHEMATCH);

	if (joMatch == null)
	{
		fkn_log("Error: fkn_MapName() - (joMatch == null)");
		return false;
	}

	joMatch.GetString("map", sBuffer, iMaxlength);
	json_cleanup_and_delete(joMatch);
	return true;
}

stock bool fkn_GetIPv4(char[] sBuffer, int iMaxlength)
{
	JSON_Object joIPv4 = JsonObjectMatch(DIR_IPV4);

	if (joIPv4 == null)
	{
		fkn_log("Error: fkn_GetIPv4 - (joIPv4 == null)");
		return false;
	}

	joIPv4.GetString("ip", sBuffer, iMaxlength);
	json_cleanup_and_delete(joIPv4);
	return true;
}

stock bool fkn_Players()
{
	JSON_Object joMatch = JsonObjectMatch(DIR_CACHEMATCH);

	if (joMatch == null)
	{
		fkn_log("Error: fkn_Players() - (joMatch == null)");
		return false;
	}

	JSON_Array jaTA = view_as<JSON_Array>(joMatch.GetObject("teamA"));
	JSON_Array jaTB = view_as<JSON_Array>(joMatch.GetObject("teamB"));

	if (jaTA == null)
	{
		fkn_log("Error: fkn_Players() - (jaTA == null)");
		return false;
	}
	else if (jaTB == null)
	{
		fkn_log("Error: fkn_Players() - (jaTB == null)");
		return false;
	}

	for (int i = 0; i <= 3; i++)
	{
		JSON_Object joPlayerTA = jaTA.GetObject(i);
		JSON_Object joPlayerTB = jaTB.GetObject(i);

		joPlayerTA.GetString("steamid", g_Players[TeamA][i].steamid, MAX_AUTHID_LENGTH);
		joPlayerTB.GetString("steamid", g_Players[TeamB][i].steamid, MAX_AUTHID_LENGTH);

		joPlayerTA.GetString("personaname", g_Players[TeamA][i].name, MAX_NAME_LENGTH);
		joPlayerTB.GetString("personaname", g_Players[TeamB][i].name, MAX_NAME_LENGTH);
	}

	json_cleanup_and_delete(joMatch);
	return true;
}

stock bool fkn_PlayersBasic()
{
	JSON_Object joMatch = JsonObjectMatch(DIR_CACHEMATCH);

	if (joMatch == null)
	{
		fkn_log("Error: fkn_Players() - (joMatch == null)");
		return false;
	}

	JSON_Array jaTA = view_as<JSON_Array>(joMatch.GetObject("teamA"));
	JSON_Array jaTB = view_as<JSON_Array>(joMatch.GetObject("teamB"));

	if (jaTA == null)
	{
		fkn_log("Error: fkn_Players() - (jaTA == null)");
		return false;
	}
	else if (jaTB == null)
	{
		fkn_log("Error: fkn_Players() - (jaTB == null)");
		return false;
	}

	for (int i = 0; i <= 3; i++)
	{
		JSON_Object joPlayerTA = jaTA.GetObject(i);
		JSON_Object joPlayerTB = jaTB.GetObject(i);

		joPlayerTA.GetString("steamid", g_PlayersBasic[TeamA][i].steamid, MAX_AUTHID_LENGTH);
		joPlayerTB.GetString("steamid", g_PlayersBasic[TeamB][i].steamid, MAX_AUTHID_LENGTH);

		joPlayerTA.GetString("personaname", g_PlayersBasic[TeamA][i].name, MAX_NAME_LENGTH);
		joPlayerTB.GetString("personaname", g_PlayersBasic[TeamB][i].name, MAX_NAME_LENGTH);
	}

	json_cleanup_and_delete(joMatch);
	return true;
}