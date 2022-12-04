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

#if defined _4saken_included
  #endinput
#endif
#define _4saken_included

#include <4saken_stocks>

/**
 * Logs a message to 4saken file.  The log message will be in the normal
 *
 * @param format        Formatting rules.
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native void _4saken_log(const char[] format, any ...);

/**
 * Gets the type of match broadcast on 4saken.us
 *
 * @return An integer, -1 is that information is not yet obtained
 */
native int _4saken_TypeMatch();

/**
 * Gets the steamid of the players that are assigned to Team 1
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void _4saken_Team1(int index, char[] buffer, int maxlength);

/**
 * Gets the steamid of the players that are assigned to Team 2
 *
 * @param index         Index in the team.
 * @param buffer        Buffer to copy to.
 * @param maxlength     Maximum size of the buffer.
 * @noreturn
 */
native void _4saken_Team2(int index, char[] buffer, int maxlength);

public SharedPlugin __pl_4saken =
{
    name = "4saken",
    file = "4saken.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_4saken_SetNTVOptional()
{
    MarkNativeAsOptional("_4saken_log");
    MarkNativeAsOptional("_4saken_TypeMatch");
    MarkNativeAsOptional("_4saken_Team1");
    MarkNativeAsOptional("_4saken_Team2");
}
#endif
