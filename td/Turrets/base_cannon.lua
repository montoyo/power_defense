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

TURRET.virtual = true
TURRET.parent = "base"

-- Initialise la tourelle avec ses valeurs par defaut
function TURRET:setup()
	self.angle = 0
	self.bullets = {}
	
	self.cooldown = 0
	self.power = self.iMaxPower
	self.reloading = false
	
	self.bSpeed = self.iBulletSpeed
	self.maxPower = self.iMaxPower
	self.shootCost = self.iShootCost
	self.maxCooldown = self.iCooldown
	self.damages = self.iDamages
	self.bAccel = self.iBulletAccel
	
	TURRET.base.setup(self)
end

-- Envoie un projectile avec la vitesse unitaire donnee et l'angle donne
function TURRET:shoot(sx, sy, a)
	if not td.game.isClient then
		self:sendCall("netShoot", sx, sy, a)
	end

	local b = {}
	b.x = self.x + 16
	b.y = self.y + 16
	b.xSpeed = sx
	b.ySpeed = sy
	b.angle = a
	b.target = self.focus
	
	if self.sBulletSpeed ~= nil then
		b.speed = self.sBulletSpeed
	end
	
	table.insert(self.bullets, b)
	
	if self.iSound and not self.iSound:isPlaying() then
		self.iSound:play()
	end
end

-- Pareil que shoot, mais pour le client
function TURRET:netShoot(sx, sy, a)
	self:shoot(tonumber(sx), tonumber(sy), tonumber(a))
end

-- Enleve un projectile a partir de son ID
function TURRET:removeBullet(id)
	table.remove(self.bullets, tonumber(id))
end

-- Fait "penser" la tourelle (appele chaque ticks)
function TURRET:think(dt)
	TURRET.base.think(self, dt)

	if not td.game.isClient then
		-- On augmente la puissance jusqu'a ce qu'il y en ait un maximum
		if self.power < self.maxPower then
			self.power = self.power + dt
			
			if self.power >= self.maxPower then
				self.power = self.maxPower
				
				if self.reloading then
					self.reloading = false
				end
			end
		end
	end

	-- Si la tourelle a une cible, on la bombarde
	if self.focus and not self.focus.dead then
		local dx, dy = self.focus.x - self.x - 16, self.focus.y - self.y - 16
		local dist = math.sqrt(dx * dx + dy * dy)
		
		-- La partie suivant consiste a estimer la position de l'ennemis
		-- au moment de l'impact avec le projectile
		local sim
		if self.bAccel == nil then -- Pas d'acceleration; pas complique: t = d / v
			sim = dist / self.bSpeed
		else
			-- Soit a l'acceleration, v la vitesse, x la distance et t le temps
			-- a = self.bAccel
			-- Par integration, v = v0 + at (avec v0 = self.sBulletSpeed)
			-- Par integration, x = v0t + 1/2at²
			
			-- On cherche t ou le projectile atteint sa vitesse max (vmax = self.bSpeed)
			-- On calcule x a t1
			local t1 = (self.bSpeed - self.sBulletSpeed) / self.bAccel
			local d1 = self.sBulletSpeed * t1 + 0.5 * self.bAccel * t1 * t1
			
			if dist < d1 then
				-- Le projectile n'a pas atteint vmax, on determine t ou le projectile atteindra la cible
				-- On resout donc v0t + 1/2at² = d       (d = dist)
				--                v0t + 1/2at² - d = 0
				--                1/2at² + v0t - d = 0
				-- 
				-- On calcule donc delta, et, sachant que a > 0 et que d > 0, delta > 0
				-- Il y'a donc deux racines, on prends la plus grande pour trouver t.
				
				local delta = self.sBulletSpeed * self.sBulletSpeed + 2 * self.bAccel * dist
				sim = (math.sqrt(delta) - self.sBulletSpeed) / self.bAccel
			else
				-- Le projectile a atteint vmax
				sim = t1 + (dist - d1) / self.bSpeed
			end
		end
	
		dx, dy = self.focus:lerpPos(sim) -- On "pre-shot": on imagine la position de la cible au moment ou le projectile l'atteint
		dx, dy = dx - self.x - 16, dy - self.y - 16
		dist = math.sqrt(dx * dx + dy * dy)
		
		if dist > self.range then -- En dehors du radar
			self.focus = nil
		else
			self.angle = math.atan2(dy, dx)
			
			-- On tire si on est pas en periode de refroidissement
			if not td.game.isClient and not self.reloading then
				if self.cooldown > 0 then
					self.cooldown = math.max(self.cooldown - dt, 0)
				elseif math.random(1, 100) >= 80 then
					self.power = self.power - self.shootCost
					
					if self.power <= 0 then
						self.power = 0 -- Au cas ou ca depasse (encore)
						self.reloading = true
					else
						self.cooldown = self.maxCooldown
					end
					
					self:shoot(dx / dist, dy / dist, self.angle) -- Feu!
				end
			end
		end
	end

	-- On fait avancer les boullets
	local del = {}
	local halfw = self.bullet:getWidth() / 2
	local halfh = self.bullet:getHeight() / 2

	for i = #self.bullets, 1, -1 do
		local v = self.bullets[i]
	
		if self.bAccel ~= nil and v.speed < self.bSpeed then
			v.speed = v.speed + self.bAccel * dt
			v.x = v.x + v.xSpeed * v.speed * dt
			v.y = v.y + v.ySpeed * v.speed * dt
		else
			v.x = v.x + v.xSpeed * self.bSpeed * dt
			v.y = v.y + v.ySpeed * self.bSpeed * dt
		end
		
		if not td.game.isClient and v.target then
			if not v.target.dead and util.isColliding(v.x - halfw, v.y - halfh, halfw * 2, halfh * 2, v.target:getRect()) then
				if self.onTargetHit then
					self:onTargetHit(v.target)
				else
					v.target:hurt(self.damages)
				end
				
				self:sendCall("removeBullet", i)
				table.remove(self.bullets, i)
			elseif v.x <= -halfw or v.x >= 800 + halfw or v.y <= -halfh or v.y >= 544 + halfh then
				self:sendCall("removeBullet", i)
				table.remove(self.bullets, i)
			end
		end
	end
end

-- On dessine la tourelle
function TURRET:draw()
	-- D'abord la base
	local g = love.graphics
	g.setColor(255, 255, 255, 255)
	g.draw(self.sprite, self.x, self.y)
	
	-- Puis le canon
	g.push()
	g.translate(self.x + 16, self.y + 16)
	g.rotate(self.angle)
	g.draw(self.cannon, -16, -16)
	g.pop()
end

-- On dessine les projectiles
function TURRET:drawBullets()
	local g = love.graphics
	g.setColor(255, 255, 255, 255)
	
	local halfw = self.bullet:getWidth() / 2
	local halfh = self.bullet:getHeight() / 2

	for k, v in pairs(self.bullets) do
		g.push()
		g.translate(v.x, v.y)
		g.rotate(v.angle)
		g.draw(self.bullet, -halfw, -halfh)
		g.pop()
	end

	-- La barre de puissance, uniquement si la souris est au dessus de la tourelle
	if util.isPointInRect(love.mouse.getX(), love.mouse.getY(), self.x, self.y, 32, 32) then
		g.setColor(0, 255, 0, 128)
		g.rectangle("fill", self.x, self.y - 7, self.power / self.maxPower * 32, 5)
	end
end

-- Dessine la tourelle sans qu'elle soit cree
function TURRET:drawForShop(x, y)
	local g = love.graphics
	g.draw(self.sprite, x, y)
	
	g.push()
	g.translate(x + 16, y + 16)
	g.rotate(-math.pi / 2)
	g.draw(self.cannon, -16, -16)
	g.pop()
end

-- Mise-a-jour pour le menu principal
local modes = { ".", "+", "-" }

function TURRET:menuThink(dt)
	if not self.menuDir or not self.menuTime or not self.menuSpeed then
		self.menuDir = modes[math.floor(math.random(1, 3))]
		self.menuTime = math.random(0.2, 1)
		self.menuSpeed = math.random(math.pi / 6, math.pi)
	end
	
	self.menuTime = self.menuTime - dt
	if self.menuTime <= 0 then
		local old = self.menuDir
		while self.menuDir == old do
			self.menuDir = modes[math.floor(math.random(1, 3))]
		end
		
		self.menuTime = math.random(0.2, 1)
		self.menuSpeed = math.random(math.pi / 6, math.pi)
	end
	
	if self.menuDir == "+" then
		self.angle = self.angle + dt * math.pi
	elseif self.menuDir == "-" then
		self.angle = self.angle - dt * math.pi
	end
end
