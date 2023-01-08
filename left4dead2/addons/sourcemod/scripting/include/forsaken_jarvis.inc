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

#if defined _jarvis_included
  #endinput
#endif
#define _jarvis_included


#include <forsaken_stocks>

/**
 * They ban a player who is registered in the matchmaking that is not on the server
 * 
 * @param iTarget		Target's index, ForsakenID
 * @param Team			Team to ban, TeamA = 1 | TeamB = 2
 * @param iTime			Ban time
 * @param sReason		Ban reason
 * @param ...			Additional data
 * @noreturn
 * 
 */
native void ForsakenBan(int iTarget, int Team, int iTime, const char[] sReason, any ...);

public SharedPlugin __pl_jarvis =
{
    name = "forsaken_jarvis",
    file = "forsaken_jarvis.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_jarvis_SetNTVOptional()
{
    MarkNativeAsOptional("ForsakenBan");
}
#endif
