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
TURRET.name = "Le Congelateur"
TURRET.sprite = assets.getImage("freezer.png")
TURRET.iSound = assets.getSound("freezer.wav")
TURRET.iRange = 200
TURRET.iDamages = 0
TURRET.targetMode = "fastest"
TURRET.cost = 80
TURRET.targetType = bit.bor(MOB_GROUND, MOB_AIR)
TURRET.desc = [[Ralentis les ennemis au sol et en l'air
Reduis de 25% de leur vitesse.]]

-- On fait "penser" la tourelle
function TURRET:think(dt)
	TURRET.base.think(self, dt)

	-- Meme en multi, je pense qu'on peut laisser ca intact
	if self.focus and not self.focus.dead then
		local dx = self.focus.x - self.x - 16
		local dy = self.focus.y - self.y - 16
		
		if not td.game.isClient and dx * dx + dy * dy > self.range * self.range then
			self.focus = nil
		else
			if not self.iSound:isPlaying() then
				self.iSound:play()
			end
		
			self.focus:addBuff("speed", "mul", 0.75, 2, self)
		end
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
		g.setColor(0, 128, 255, 150)
		g.line(self.x + 16, self.y + 16, self.focus.x, self.focus.y)
	end
end

-- Dessine la tourelle sans qu'elle soit cree
function TURRET:drawForShop(x, y)
	love.graphics.draw(self.sprite, x, y)
end
