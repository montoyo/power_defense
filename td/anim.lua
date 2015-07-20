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

anim = anim or {}

-- Cree une animation a partir d'une spritesheet
-- numX et numY: nombre d'images a l'horizontale et a la vertical
-- speed: vitesse de l'animation
function anim.new(img, numX, numY, speed)
	assert(type(numX) == "number", "not a number")
	assert(type(numY) == "number", "not a number")
	assert(type(speed) == "number", "not a number")

	local ret = {}
	ret.img = img
	ret.count = numX * numY
	ret.quads = {}
	ret.speed = speed
	
	local w, h = img:getDimensions()
	local qw = w / numX
	local qh = h / numY
	
	ret.halfW = qw / 2
	ret.halfH = qh / 2
	
	local x = 0
	local y = 0
	
	for i = 1, ret.count do
		ret.quads[i] = love.graphics.newQuad(x, y, qw, qh, w, h)
		
		x = x + qw
		if x >= img:getWidth() then
			x = 0
			y = y + qh
		end
	end
	
	return ret
end

-- Calcule les positions d'une animation afin que l'image soit centree
function anim.center(a, x, y)
	assert(type(a) == "table", "invalid animation")
	assert(type(x) == "number", "not a number")
	assert(type(y) == "number", "not a number")
	
	return x - a.halfW, y - a.halfH
end

-- Cree une instance d'animation qui pourra etre affichee a l'ecran
function anim.newInstance(a, x, y, loop)
	assert(type(a) == "table", "invalid animation")
	assert(type(x) == "number", "not a number")
	assert(type(y) == "number", "not a number")

	local ret = {}
	ret.anim = a
	ret.play = true
	ret.loop = util.default(loop, false)
	ret.pos = 1
	ret.x = x
	ret.y = y
	
	return ret
end

-- Dessine une instance d'animation a l'ecran
function anim.draw(a)
	if a.play then
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(a.anim.img, a.anim.quads[math.floor(a.pos)], a.x, a.y)
	end
end

-- Fait avancer une animation
-- Retourne true si celle-ci est terminee
function anim.update(a, dt)
	if a.play then
		a.pos = a.pos + a.anim.speed * dt
		
		if a.pos >= a.anim.count then
			a.pos = a.anim.count
			
			if a.loop then
				a.pos = 1
			else
				a.play = false
			end
		end
		
		return false
	else
		return true
	end
end
