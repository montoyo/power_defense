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

assets = assets or {}
assets.imgs = assets.imgs or {}
assets.fonts = assets.fonts or {}
assets.sounds = assets.sounds or {}

-- Charge une image si celle-ci ne l'est pas deja puis la retourne
function assets.getImage(img)
	assert(type(img) == "string", "invalid image filename")

	if assets.imgs[img] == nil then
		assets.imgs[img] = love.graphics.newImage("Images/" .. img)
	end
	
	return assets.imgs[img]
end

-- Charge une police si celle-ci ne l'est pas deja puis la retourne
function assets.getFont(font, size)
	assert(type(font) == "string", "invalid font filename")
	assert(type(size) == "number", "invalid font size")

	local str = tostring(size) .. "_" .. font
	if assets.fonts[str] == nil then
		assets.fonts[str] = love.graphics.newFont("Fonts/" .. font, size)
	end
	
	return assets.fonts[str]
end

-- Charge un son si celui-ci ne l'est pas deja puis le retourne
function assets.getSound(snd)
	assert(type(snd) == "string", "invalid sound filename")

	if assets.sounds[snd] == nil then
		assets.sounds[snd] = love.audio.newSource("Sounds/" .. snd, "static")
	end
	
	return assets.sounds[snd]
end

-- Charge une musique si celle-ci ne l'est pas deja puis la retourne
function assets.getMusic(snd)
	assert(type(snd) == "string", "invalid music filename")

	if assets.sounds[snd] == nil then
		assets.sounds[snd] = love.audio.newSource("Sounds/" .. snd, "stream")
	end
	
	return assets.sounds[snd]
end
