/*
    4Saken.inc
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

#if defined _forsaken_included
  #endinput
#endif
#define _forsaken_included


#include <forsaken_stocks>

/**
 * Logs a message to 4saken file.  The log message will be in the normal
 *
 * @param format        Formatting rules.
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native void fkn_log(const char[] format, any ...);

/**
 * Gets the type of match broadcast on 4saken.us
 *
 * @return              An integer, 0 is that information is not yet obtained
 */
native TypeMatch fkn_TypeMatch();

/**
 * Get lobby queue number
 *
 * @return              An integer, 0 is that information is not yet obtained
 */
native int fkn_QueueID();

/**
 * Gets the steamid of the players that are assigned to Team A
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void fkn_SteamIDTA(int index, char[] buffer, int maxlength);

/**
 * Gets the steamid of the players that are assigned to Team B
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void fkn_SteamIDTB(int index, char[] buffer, int maxlength);

/**
 * Gets the name of the players that are assigned to Team A
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void fkn_NameTA(int index, char[] buffer, int maxlength);

/**
 * Gets the name of the players that are assigned to Team B
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void fkn_NameTB(int index, char[] buffer, int maxlength);

/**
 * Gets the IP of the server
 *
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void fkn_GetIPv4(char[] buffer, int maxlength);

/**
 * Gets the name of the map provided by Forsaken
 *
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void fkn_MapName(char[] buffer, int maxlength);

public SharedPlugin __pl_forsaken =
{
    name = "forsaken",
    file = "forsaken.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_forsaken_SetNTVOptional()
{
    MarkNativeAsOptional("fkn_log");
    MarkNativeAsOptional("fkn_TypeMatch");
    MarkNativeAsOptional("fkn_QueueID");
    MarkNativeAsOptional("fkn_teamIDTA");
    MarkNativeAsOptional("fkn_SteamIDTB");
    MarkNativeAsOptional("fkn_NameTA");
    MarkNativeAsOptional("fkn_NameTB");
    MarkNativeAsOptional("fkn_GetIPv4");
    MarkNativeAsOptional("fkn_MapName");
}
#endif
