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

#if defined _4saken_stocks_left4dhooks_included
  #endinput
#endif
#define _4saken_stocks_left4dhooks_included

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
	L4DTeam_Unassigned	= 0,
	L4DTeam_Spectator	= 1,
	L4DTeam_Survivor	= 2,
	L4DTeam_Infected	= 3
}

// ==================================================
// FUNCTIONS
// ==================================================


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