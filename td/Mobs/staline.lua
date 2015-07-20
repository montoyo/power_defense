-- PowerDefense, a 2D tower defense game (school project)
-- Copyright (C) 2015 ALTHUSER Dimitri, BARBOTIN Nicolas, WITZ Beno�t

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

MOB.name = "Staline"
MOB.parent = "base_ground"
MOB.sprite = assets.getImage("staline.png")
MOB.iSound = assets.getSound("staline.wav")
MOB.size = 81
MOB.reward = 5000
MOB.iSpeed = 30
MOB.iHealth = 7500
MOB.cost = 8000
MOB.desc = [[Boss: très dure a tuer.
Rapporte énormement à l'ennemi.]]

function MOB:setup()
	MOB.base.setup(self)
	self.sound = self.iSound:clone()
end

function MOB:hurt(dmgs)
	if not self.sound:isPlaying() then
		self.sound:play()
	end
	
	MOB.base.hurt(self, dmgs)
	
	if self.dead then
		td.game:victory()
	end
end

function MOB:draw()
	local g = love.graphics
	local w, h = self.sprite:getDimensions()
	
	g.setColor(0, 255, 0, 200)
	g.rectangle("fill", -50 / 2, -math.max(w, h) / 2 - 15, math.floor(self.health / self.iHealth * 50), 5)
	g.setColor(255, 255, 255, 200)
	g.rectangle("line", -50 / 2, -math.max(w, h) / 2 - 15, 50, 5)
	
	g.setColor(255, 255, 255, 255)
	g.draw(self.sprite, -w / 2, -h / 2)
end
