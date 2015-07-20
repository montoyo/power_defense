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

MOB.virtual = true
MOB.parent = "base"

function MOB:setup()
	MOB.base.setup(self)

	self.speed = self.iSpeed
	self.x = 800
	self.y = math.random(self.sprite:getHeight() / 2, 544 - self.sprite:getHeight() / 2)
end

function MOB:think(dt)
	MOB.base.think(self, dt)
	self.x = self.x - self.speed * dt
	
	if not td.game.isClient and self.x < -self.sprite:getWidth() then
		self.dead = true
		self.speed = 0
		td.game:removeLife()
		self:sendField("dead")
	end
end

function MOB:draw()
	local g = love.graphics
	local w, h = self.sprite:getDimensions()
	
	self:drawLifeBar(g, -25, -math.floor(h / 2) - 15)
	g.setColor(255, 255, 255, 255)
	g.draw(self.sprite, -w / 2, -h / 2)
end

function MOB:lerpPos(dt)
	return self.x - self.speed * dt, self.y
end

function MOB:isAir()
	return true
end

function MOB:isGround()
	return false
end

function MOB:getType()
	return MOB_AIR
end

-- Dessine l'ennemi sans qu'elle soit cree
function MOB:drawForShop(x, y)
	local g = love.graphics
	local s = math.min(32 / self.sprite:getWidth(), 32 / self.sprite:getHeight())
	
	g.push()
	g.translate(x + 16, y + 16)
	g.rotate(math.pi / 2)
	g.scale(s, s)
	g.draw(self.sprite, -self.sprite:getWidth() / 2, -self.sprite:getHeight() / 2)
	g.pop()
end
