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

TURRET.parent = "base"
TURRET.name = "Illuminati"
TURRET.sprite = assets.getImage("illuminati.png")
TURRET.iSound = assets.getSound("illuminati.wav")
TURRET.iRange = 200
TURRET.iDamages = 0
TURRET.targetMode = "shielded"
TURRET.cost = 75
TURRET.targetType = bit.bor(MOB_GROUND, MOB_AIR)
TURRET.desc = [[DÃ©truit le bouclier des ennemis.
Anti-air et anti-sol.]]

function TURRET:setup()
	TURRET.base.setup(self)
	self.load = 0
end

-- On fait "penser" la tourelle
function TURRET:think(dt)
	TURRET.base.think(self, dt)

	-- Meme en multi, je pense qu'on peut laisser ca intact
	if self.focus and not self.focus.dead then
		if not self.iSound:isPlaying() then
			self.iSound:play()
		end
	
		self.load = self.load + dt
		if not td.game.isClient and self.load >= 2 then
			self.focus.shield = 0
			self.focus = nil
			self.load = 0
		end
	elseif self.load > 0 then
		self.load = 0
	end
end

-- On dessine la tourelle
function TURRET:draw()
	local g = love.graphics
	g.setColor(255, 255, 255, 255)
	g.draw(self.sprite, self.x, self.y)
end

-- On dessine le laser
function TURRET:drawBullets()
	if self.focus and not self.focus.dead then
		local g = love.graphics
		g.setColor(255, 200, 0, self.load / 2 * 200)
		--g.line(self.x + 16, self.y + 16, self.focus.x, self.focus.y)
		
		local dx = self.focus.x - self.x - 16
		local dy = self.focus.y - self.y - 16
		local dist = math.sqrt(dx * dx + dy * dy)
		local w = self.load / 2 * 5
		
		g.push()
		g.translate(self.x + 16, self.y + 16)
		g.rotate(math.atan2(dy, dx))
		g.rectangle("fill", 0, -w / 2, dist, w)
		g.pop()
	end
end

-- Dessine la tourelle sans qu'elle soit cree
function TURRET:drawForShop(x, y)
	love.graphics.draw(self.sprite, x, y)
end
