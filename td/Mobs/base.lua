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

-- Liste des fonctions pour les buffs
local FUNCS = {}
function FUNCS.mul(a, b)
	return a * b
end

function FUNCS.add(a, b)
	return a + b
end

function FUNCS.div(a, b)
	return a / b
end

function FUNCS.sub(a, b)
	return a - b
end

function FUNCS.set(a, b)
	return b
end

function MOB:setup()
	self.health = self.iHealth
	self.shield = self.iShield
	self.dead = false
	self.buffs = {}
	self.color = { 255, 255, 255, 0 }
	self.lastHealth = love.timer.getTime()
	self.lastShield = love.timer.getTime()
	
	-- Differents buffs "manuels"
	self.bPoison = 0
end

-- Retourne true si le mob a un effet correspondant a l'ID
function MOB:hasBuff(effect, id)
	for k, v in pairs(self.buffs[effect]) do
		if v.id == id then
			return true
		end
	end
	
	return false
end

-- Ajoute un buff a la cible
function MOB:addBuff(effect, func, param, time, id)
	assert(type(effect) == "string" and type(self[effect]) == "number", "invalid buff name")
	assert(type(func) == "string" and FUNCS[func], "invalid buff")
	assert(type(time) == "number", "invalid buff time")
	assert(type(param) == "number", "invalid buff param")
	
	if id ~= nil and self.buffs[effect] then
		for k, v in pairs(self.buffs[effect]) do
			if v.id == id then
				v.time = time
				return
			end
		end
	end
	
	local tbl = {}
	tbl.before = self[effect]
	tbl.func = FUNCS[func]
	tbl.time = time
	tbl.param = param
	tbl.id = id
	
	if self.buffs[effect] then
		table.insert(self.buffs[effect], tbl)
	else
		self.buffs[effect] = { tbl }
	end
	
	self[effect] = tbl.func(self[effect], param)
end

-- Met a jour/applique les buffs.
function MOB:think(dt)
	for effect, buf in pairs(self.buffs) do
		local del = false
	
		for k, v in pairs(buf) do
			v.time = v.time - dt
			
			if v.time <= 0 then
				del = true
			end
		end
		
		if del then
			local tbl = {}
			self[effect] = buf[1].before
		
			for i = 1, #buf do
				if buf[i].time > 0 then
					self[effect] = buf[i].func(self[effect], buf[i].param)
					table.insert(tbl, buf[i])
				end
			end
			
			self.buffs[effect] = tbl
		end
	end
end

function MOB:hurt(dmg)
	if self.shield and self.shield > 0 then
		self.shield = self.shield - dmg / 10
		
		-- Anti-spam
		if love.timer.getTime() - self.lastShield >= 0.1 then
			self:sendField("shield")
			self.lastShield = love.timer.getTime()
		end
		
		if self.shield < 0 then
			dmg = -self.shield
			self.shield = 0
		else
			return
		end
	end

	self.health = self.health - dmg
	
	-- Anti-spam
	if love.timer.getTime() - self.lastHealth >= 0.1 then
		self:sendField("health")
		self.lastHealth = love.timer.getTime()
	end
	
	if self.health <= 0 then
		self.health = 0
		self.dead = true
		self:sendField("dead")

		td.game:addMoneyDrop(self.reward, self.x, self.y)
	end
end

-- Retourne les coordonnes et la taille d'un rectangle encadrant l'ennemi
function MOB:getRect()
	local w, h = self.sprite:getDimensions()
	return self.x - w / 2, self.y - h / 2, w, h
end

-- Dessine la barre de vie
function MOB:drawLifeBar(g, x, y)
	g.setColor(0, 255, 0, 200)

	if self.shield and self.shield > 0 then
		local total = self.iHealth + self.shield
		local hw = math.floor(self.health / total * 50)
		local sw = math.floor(self.shield / total * 50)
		
		g.rectangle("fill", x, y, hw, 5)
		g.setColor(0, 128, 255, 200)
		g.rectangle("fill", x + hw, y, sw, 5)
	else
		g.rectangle("fill", x, y, math.floor(self.health / self.iHealth * 50), 5)
	end
	
	g.setColor(255, 255, 255, 200)
	g.rectangle("line", x, y, 50, 5)
end

-- Envoie un champ au client
function MOB:sendField(name)
	if td.game.isServer and self.netId ~= nil then
		td.game.player:send("field:" .. self.netId .. ":" .. name .. ":" .. tostring(self[name]) .. "\n")
	end
end

-- Apelle une fonction chez le client, avec les parametres precises
function MOB:sendCall(name, ...)
	if td.game.isServer and self.netId ~= nil then
		local args = { ... }
		
		if #args == 0 then
			td.game.player:send("call:" .. self.netId .. ":" .. name .. "\n")
		else
			td.game.player:send("call:" .. self.netId .. ":" .. name .. ":" .. table.concat(args, ":") .. "\n")
		end
	end
end
