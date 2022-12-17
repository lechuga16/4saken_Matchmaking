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

#if defined _forsaken_endgame_included
  #endinput
#endif
#define _forsaken_endgame_included

/**
 * @brief Called when the round_end event starts.
 * 		The event depends on the list of maps 4sakenMaps.json.
 * 		The event was executed after the second round.
 */
forward void OnEndGame();

/**
 * @brief Check if game over is enabled on the current map.
 * 
 * @return bool     True if the game over is enabled on the current map, False is disabled.
 */
native bool IsEndGame();

/**
 * @brief Force game over by loading current player and server information.
 * 		After that, the server is restarted.
 * 
 *  @return bool    True if the game over was forced, False if not.
 * 
 */
native bool ForceEndGame();

public SharedPlugin __pl_forsaken_endgame =
{
    name = "forsaken_endgame",
    file = "forsaken_endgame.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};


#if !defined REQUIRE_PLUGIN
public __pl_forsaken_endgame_SetNTVOptional()
{
    MarkNativeAsOptional("OnEndGame");
    MarkNativeAsOptional("IsEndGame");
    MarkNativeAsOptional("ForceEndGame");
}
#endif