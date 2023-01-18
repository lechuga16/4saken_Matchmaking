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

#if defined _forsaken_reserved_included
  #endinput
#endif
#define _forsaken_reserved_included

/**
 * Called when getting the name of the chapter that should start the match.
 * 
 * @noreturn
 */
forward void OnMapDownload(const char[] sMap);

public SharedPlugin __pl_forsaken_reserved =
{
    name = "forsaken_reserved",
    file = "forsaken_reserved.smx",
};