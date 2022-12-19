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

#if defined forsaken_included
  #endinput
#endif
#define forsaken_included


#include <forsaken_stocks>

/**
 * Logs a message to 4saken file.  The log message will be in the normal
 *
 * @param format        Formatting rules.
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native void Forsaken_log(const char[] format, any ...);

/**
 * Gets the type of match broadcast on 4saken.us
 *
 * @return An integer, -1 is that information is not yet obtained
 */
native TypeMatch Forsaken_TypeMatch();

/**
 * Gets the steamid of the players that are assigned to Team A
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void Forsaken_TeamA(int index, char[] buffer, int maxlength);

/**
 * Gets the steamid of the players that are assigned to Team B
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void Forsaken_TeamB(int index, char[] buffer, int maxlength);

/**
 * Gets the name of the players that are assigned to Team A
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void Forsaken_NameTA(int index, char[] buffer, int maxlength);

/**
 * Gets the name of the players that are assigned to Team B
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void Forsaken_NameTB(int index, char[] buffer, int maxlength);

/**
 * Gets the IP of the server
 *
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void Forsaken_GetIPv4(char[] buffer, int maxlength);

/**
 * Gets the name of the map provided by Forsaken
 *
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void Forsaken_MapName(char[] buffer, int maxlength);

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
    MarkNativeAsOptional("Forsaken_log");
    MarkNativeAsOptional("Forsaken_TypeMatch");
    MarkNativeAsOptional("Forsaken_Team1");
    MarkNativeAsOptional("Forsaken_TeamB");
    MarkNativeAsOptional("Forsaken_NameTA");
    MarkNativeAsOptional("Forsaken_NameTB");
    MarkNativeAsOptional("Forsaken_GetIPv4");
    MarkNativeAsOptional("Forsaken_MapName");
}
#endif
