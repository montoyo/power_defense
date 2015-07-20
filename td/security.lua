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

-- Question de securite, on empeche l'utilisation de FFI
local oldRequire = require
local lower = string.lower
local tostring = tostring

require = function(thing, ...)
	if lower(tostring(thing)) == "ffi" or lower(tostring(thing)) == "debug" then
		return
	end
	
	oldRequire(thing, ...)
end

debug = nil
ffi = nil
os.execute = nil
