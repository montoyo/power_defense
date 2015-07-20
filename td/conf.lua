-- PowerDefense, a 2D tower defense game (school project)
-- Copyright (C) 2015 ALTHUSER Dimitri, BARBOTIN Nicolas, WITZ Benoît

-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

function love.conf(t)
	-- On met en place certains parametres
	t.identity = "PowerDefense"
	t.window.title = "Power Defense"
	t.window.icon = "Images/icon.png"
	t.window.width = 800
	t.window.height = 600
	t.window.resizable = false
	t.window.vsync = false
	t.window.fsaa = 8
	t.console = true
	
	-- On desactives les modules qui ne nous interessent pas
	t.modules.joystick = false
	t.modules.physics = false
	t.modules.thread = false
end
