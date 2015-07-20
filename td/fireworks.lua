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

-- Un systeme de feu d'artifices fait a la va-vite gourmand en ressources...
-- Simple particule qui avance et disparait
local function pSimple(self, dt)
	self.speed = math.max(0, self.speed - dt * self.des)
	self.x = self.x + self.xSpeed * self.speed * dt
	self.y = self.y + self.ySpeed * self.speed * dt

	if self.time >= 2.5 then
		self.a = self.a - dt * 255 / 2
		
		if self.a <= 0 then
			return true
		end
	end
	
	return false
end

-- Particule qui ne bouge pas mais disparait
local function pTrail(self, dt)
	if self.time >= 2 then
		self.a = self.a - dt * 255 / 2
		
		if self.a <= 0 then
			return true
		end
	end
	
	return false
end

-- Particule qui avance, cree des pTrail et disparait
local sTrail = assets.getImage("sTrail.png")
local function pTrailHead(self, dt)
	self.speed = self.speed - dt * self.des
	self.x = self.x + self.xSpeed * self.speed * dt
	self.y = self.y + self.ySpeed * self.speed * dt

	if self.time >= 1.15 and self.time <= 2.3 then
		firework.add(self.parent, sTrail, pTrail, self.x, self.y, 255, 218, 71, 100)
	elseif self.time >= 2.5 then
		self.a = self.a - dt * 255
		
		if self.a <= 0 then
			return true
		end
	end
	
	return false
end

-- Metatable d'une particule
local particle = {}
local pMeta = {}
pMeta.__index = particle
pMeta.__metatable = particle

function particle:update(dt)
	self.time = self.time + dt * 2.5
	return self.func(self, dt)
end

local g = love.graphics
function particle:draw()
	g.setColor(self.r, self.g, self.b, self.a)
	g.draw(self.sprite, self.x, self.y)
end

-- Feu d'artifice
firework = firework or {}

-- Creer un nouveau
local fSnd = assets.getSound("firework.wav")
function firework.new(x, y)
	local ret = {}
	ret.x = x
	ret.y = y
	ret.time = 0
	ret.array = {}
	ret.fuse = 2
	
	fSnd:clone():play()
	return ret
end

-- Ajouter une particule
function firework.add(f, sprite, func, x, y, r, g, b, a)
	local p = {}
	p.time = 0
	p.sprite = sprite
	p.func = func
	p.x = x
	p.y = y
	p.r = r
	p.g = g
	p.b = b
	p.a = a
	p.parent = f
	
	table.insert(f.array, setmetatable(p, pMeta))
	return p
end

local sFw = assets.getImage("fireworks.png")
local fFw = assets.getImage("flare.png")

-- Mettre a jour
function firework.update(f, dt)
	if f.fuse > 0 then
		f.fuse = f.fuse - dt
		return false
	end

	f.time = f.time + dt
	
	-- On creer les particules
	if f.time < 0.2 then
		for i = 0, 359, 4 do
			if math.random(1, 100) <= 1 then
				local add
				if math.random(1, 100) <= 50 then
					add = firework.add(f, sFw, pSimple, 0, 0, 255, 0, 0, 200)
				else
					add = firework.add(f, sFw, pSimple, 0, 0, 0, 255, 0, 200)
				end
				
				add.xSpeed = math.cos(math.rad(i))
				add.ySpeed = math.sin(math.rad(i))
				add.speed = 800
				add.des = 300
			end
		end
	elseif f.time >= 0.25 and not f.trailed then
		for i = 0, 359, 4 do
			if math.random(1, 100) <= 60 then
				local add = firework.add(f, sFw, pTrailHead, 0, 0, 0, 100, 255, 200)
				add.xSpeed = math.cos(math.rad(i))
				add.ySpeed = math.sin(math.rad(i))
				add.speed = 800
				add.des = 300
			end
		end
		
		f.trailed = true
	elseif f.time >= 0.5 and f.time <= 1 then
		for i = 0, 359, 4 do
			if math.random(1, 100) <= 1 then
				if math.random(1, 100) <= 50 then
					add = firework.add(f, sFw, pSimple, 0, 0, 255, 0, 0, 200)
				else
					add = firework.add(f, sFw, pSimple, 0, 0, 255, 204, 0, 200)
				end
	
				add.xSpeed = math.cos(math.rad(i))
				add.ySpeed = math.sin(math.rad(i))
				add.speed = 300
				add.des = 150
			end
		end
	end

	-- On met a jour les particules
	for i = #f.array, 1, -1 do
		if f.array[i]:update(dt) then
			table.remove(f.array, i)
		end
	end
	
	return f.time >= 4
end

-- Dessiner a l'ecran
function firework.draw(f)
	g.push()
	g.translate(f.x, f.y)
	
	if f.fuse <= 0 and f.time < 0.1 then
		g.setColor(255, 255, 255, 255)
		g.draw(fFw, -128, -128)
	end
	
	g.scale(0.25, 0.25)

	for k, v in pairs(f.array) do
		v:draw()
	end
	
	g.pop()
end
