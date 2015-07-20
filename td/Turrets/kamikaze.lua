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

TURRET.name = "Kamikaze"
TURRET.iRange = 200
TURRET.iERange = 100
TURRET.cost = 3000
TURRET.iSpeed = 150
TURRET.iDamages = 500
TURRET.sprite = assets.getImage("kamikaze.png")
TURRET.iSound = assets.getSound("kamikaze.wav")
TURRET.targetType = MOB_GROUND -- Le type de cible
TURRET.desc = [[Tourelle a usage unique,
contre les ennemis au sol.]]

-- Initialise le kamikaze avec ses valeurs par defaut
function TURRET:setup()
	self.scale = 32 / 94
	self.range = self.iRange
	self.eRange = self.iERange
	self.speed = self.iSpeed
	self.damages = self.iDamages
	self.hasTarget = false
	self.sound = self.iSound:clone()
end

-- Le kamikaze pense!!!! OH MON DIEU!!!
function TURRET:think(dt)
	if self.hasTarget then
		-- On se dirige vers la cible...
		self.x = self.x + self.xSpeed * self.speed * dt
		self.y = self.y + self.ySpeed * self.speed * dt
		
		local dx = self.tx - self.x - 16
		local dy = self.ty - self.y - 16
		local dist = math.sqrt(dx * dx + dy * dy)
		
		-- ... ET BOOM!
		if dist <= 4 then
			td.game:addExplosion(self.x + 16, self.y + 16)
		
			if not td.game.isClient then
				for k, v in pairs(td.game.mobs) do
					dx = v.x - self.x - 16
					dy = v.y - self.y - 16
					dist = math.sqrt(dx * dx + dy * dy)
					
					if dist < self.eRange then
						v:hurt((1 - dist / self.eRange) * self.damages)
					end
				end
			end
			
			td.game:removeTurret(self)
			return
		end
		
		self.scale = math.lerp(math.cos((1 - dist / self.td) * math.pi - math.pi / 2), 32 / 94, 1)
	elseif not td.game.isClient then
		-- On cherche une cible potentielle...
		for k, v in pairs(td.game.mobs) do
			local dx = v.x - self.x - 16
			local dy = v.y - self.y - 16
			local dist = dx * dx + dy * dy
			
			if dist <= self.range * self.range then
				self.tx, self.ty = v:lerpPos(math.sqrt(dist) / (self.speed * 2)) -- C'est fait expres!
				dx, dy = self.tx - self.x - 16, self.ty - self.y - 16
				dist = math.sqrt(dx * dx + dy * dy)
			
				self.td = dist -- Distance initiale jusqu'a la cible
				self.xSpeed = dx / dist
				self.ySpeed = dy / dist
				self.hasTarget = true
				self.sound:play()
				
				if td.game.isServer and self.netId ~= nil then
					td.game.player:send("call:" .. self.netId .. ":netSetTarget:" .. self.tx .. ":" .. self.ty .. ":" .. self.td .. ":" .. self.xSpeed .. ":" .. self.ySpeed .. "\n")
				end
				
				break
			end
		end
	end
end

function TURRET:netSetTarget(tx, ty, td, xs, ys)
	self.tx = tonumber(tx)
	self.ty = tonumber(ty)
	self.td = tonumber(td)
	self.xSpeed = tonumber(xs)
	self.ySpeed = tonumber(ys)
	self.hasTarget = true
	self.sound:play()
end

-- On dessine le kamikaze...
function TURRET:myDraw()
	local g = love.graphics
	g.setColor(255, 255, 255, 255)
	
	g.push()
	g.translate(self.x + 16, self.y + 16)
	g.scale(self.scale, self.scale)
	g.draw(self.sprite, -47, -47)
	g.pop()
end

-- ... a terre ...
function TURRET:draw()
	if not self.hasTarget then
		self:myDraw()
	end
end

-- ... et quand il saute!
function TURRET:drawBullets()
	if self.hasTarget then
		self:myDraw()
	end
end

-- On le dessine pour le magasin
function TURRET:drawForShop(x, y)
	local g = love.graphics

	g.push()
	g.translate(x + 16, y + 16)
	g.scale(32 / 94, 32 / 94)
	g.draw(self.sprite, -47, -47)
	g.pop()
end
