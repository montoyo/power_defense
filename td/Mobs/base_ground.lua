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

	self.targetIdx = 1
	self.angle = 0
	self.speed = self.iSpeed
	self.xSpeed = 0
	self.ySpeed = 0
end

function MOB:think(dt)
	MOB.base.think(self, dt)

	if not td.game.isClient then
		if self.path then
			local p = self.path[self.targetIdx]
			local dx = p.x - self.x
			local dy = p.y - self.y
			
			if dx * dx + dy * dy < 2 then
				if self.targetIdx + 1 > #self.path then -- On a atteint la fin du parcours
					self.dead = true
					self.path = nil
					self.xSpeed = 0
					self.ySpeed = 0
					td.game:removeLife()
					
					self:sendField("dead")
				else -- On a atteint le prochain point
					self.targetIdx = self.targetIdx + 1
					p = self.path[self.targetIdx]
					dx = p.x - self.x
					dy = p.y - self.y
					
					local sz = math.sqrt(dx * dx + dy * dy)
					self.angle = math.atan2(dy, dx)
					self.xSpeed = dx / sz
					self.ySpeed = dy / sz
					
					self:sendField("angle")
					self:sendField("xSpeed")
					self:sendField("ySpeed")
				end
			end
		end
	end
	
	self.x = self.x + self.xSpeed * self.speed * dt
	self.y = self.y + self.ySpeed * self.speed * dt
end

function MOB:draw()
	local g = love.graphics
	local w, h = self.sprite:getDimensions()

	self:drawLifeBar(g, -25, -math.floor(math.max(w, h) / 2) - 15)
	
	g.push()
	g.rotate(self.angle)
	g.setShader(td.effects.colorBlend)
	g.setColor(unpack(self.color))
	g.draw(self.sprite, -w / 2, -h / 2)
	g.setShader()
	g.pop()
end

function MOB:lerpPos(dt)
	return self.x + self.xSpeed * self.speed * dt, self.y + self.ySpeed * self.speed * dt
end

function MOB:warpToFirstPoint()
	self.x = self.path[1].x
	self.y = self.path[1].y
end

function MOB:isAir()
	return false
end

function MOB:isGround()
	return true
end

function MOB:getType()
	return MOB_GROUND
end

-- Dessine l'ennemi sans qu'elle soit cree
function MOB:drawForShop(x, y)
	local g = love.graphics
	local s = math.min(32 / self.sprite:getWidth(), 32 / self.sprite:getHeight())
	
	g.push()
	g.translate(x + 16, y + 16)
	g.rotate(-math.pi / 2)
	g.scale(s, s)
	g.draw(self.sprite, -self.sprite:getWidth() / 2, -self.sprite:getHeight() / 2)
	g.pop()
end
