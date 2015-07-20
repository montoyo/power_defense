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

turrets = turrets or {}
turrets.list = turrets.list or {}

-- Charge toutes les tourelles situes dans le dossier Turrets
function turrets.load()
	turrets.list = {}

	for k, v in pairs(love.filesystem.getDirectoryItems("Turrets")) do
		if love.filesystem.isFile("Turrets/" .. v) and v:len() > 4 and v:sub(v:len() - 3):lower() == ".lua" then
			local fle = love.filesystem.lines("Turrets/" .. v)
			
			if fle then
				local pos = 0
				local func, cerr = load(function()
					if pos == 0 then
						pos = 1
						return "local TURRET = {} " .. (fle() or "") .. "\n"
					elseif pos ~= 2 then
						local l = fle()
					
						if l == nil then
							pos = 2
							return "return TURRET"
						elseif pos == 1 then
							return l .. "\n"
						end
					end
				end, "Turret:" .. v, "t")
			
				if func then
					local t = func(v)
					local meta = {}
					
					meta.__index = t
					meta.__metatable = t
					
					turrets.list[v:sub(1, v:len() - 4)] = meta
				else
					print("Erreur: Impossible de charger la tourelle " .. v .. ": " .. cerr)
				end
			else
				print("Erreur: Impossible d'ouvrir la tourelle " .. v .. "!")
			end
		end
	end
	
	-- Systeme de parents: le fonctions de la classe parente sont copies si celles si n'ont pas ete remplacees
	for k, v in pairs(turrets.list) do
		turrets.resolve(v.__index)
	end
	
	print(tostring(util.tableCount(turrets.list)) .. " tourelles ont ete chargees")
end

-- Resout les dependances parents/enfants des classes
function turrets.resolve(m)
	if m.parent and not m.base then
		local p = turrets.list[m.parent].__index
		turrets.resolve(p)
	
		for k, v in pairs(p) do
			if type(v) == "function" and m[k] == nil then
				m[k] = v
			end
		end
		
		m.base = p
	end
end

-- Cree une nouvelle tourelle aux coordonnees donnees
function turrets.new(class, x, y)
	assert(type(class) == "string", "invalid turret class name")
	assert(turrets.list[class], "unknown turret class")
	assert(not turrets.list[class].__index.virtual, "cannot create a virtual turret")
	
	x = util.default(x, 0)
	y = util.default(y, 0)
	
	local ret = {}
	ret.x = x
	ret.y = y
	
	setmetatable(ret, turrets.list[class])
	ret.META = "turrets.list[\"" .. class .. "\"]" -- Info pour la sauvegarde
	ret:setup()
	
	return ret
end

-- Retourne une liste de toutes les classes de tourelles disponibles
-- virt permet de garder ou non les tourelles "virtuelles"
function turrets.getList(virt)
	local ret = {}
	for k, v in pairs(turrets.list) do
		if virt or not v.__index.virtual then
			table.insert(ret, k)
		end
	end
	
	return ret
end

-- Dessine une tourelle sans la creer
function turrets.drawForShop(class, x, y)
	turrets.list[class].__index:drawForShop(x, y)
end

-- Retourne la portee d'une tourelle sans la creer
function turrets.getRange(class)
	return turrets.list[class].__index.iRange
end

-- Retourne le nom d'une tourelle sans la creer
function turrets.getName(class)
	return turrets.list[class].__index.name
end

-- Retourne le prix d'une tourelle sans la creer
function turrets.getCost(class)
	return turrets.list[class].__index.cost
end

-- Retourne la description d'une tourelle sans la creer
function turrets.getDesc(class)
	return turrets.list[class].__index.desc
end
