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

-- Constantes de type de mob, doivent etre des puissances de 2
MOB_GROUND = 1
MOB_AIR = 2

mobs = mobs or {}
mobs.list = mobs.list or {}

-- Meme systeme que pour les tourelles
-- Charge tous les ennemis du dossier Mobs
function mobs.load()
	mobs.list = {}

	for k, v in pairs(love.filesystem.getDirectoryItems("Mobs")) do
		if love.filesystem.isFile("Mobs/" .. v) and v:len() > 4 and v:sub(v:len() - 3):lower() == ".lua" then
			local fle = love.filesystem.lines("Mobs/" .. v)
			
			if fle then
				local pos = 0
				local func, cerr = load(function()
					if pos == 0 then
						pos = 1
						return "local MOB = {} " .. (fle() or "") .. "\n"
					elseif pos ~= 2 then
						local l = fle()
					
						if l == nil then
							pos = 2
							return "return MOB"
						elseif pos == 1 then
							return l .. "\n"
						end
					end
				end, "Mob:" .. v, "t")
			
				if func then
					local t = func(v)
					local meta = {}
					
					meta.__index = t
					meta.__metatable = t
					
					mobs.list[v:sub(1, v:len() - 4)] = meta
				else
					print("Erreur: Impossible de charger le mob " .. v .. ": " .. cerr)
				end
			else
				print("Erreur: Impossible d'ouvrir le mob " .. v .. "!")
			end
		end
	end
	
	-- Systeme de parents: le fonctions de la classe parente sont copies si celles si n'ont pas ete remplacees
	for k, v in pairs(mobs.list) do
		mobs.resolve(v.__index)
	end
	
	print(tostring(util.tableCount(mobs.list)) .. " mobs ont ete charges")
end

-- Resout les dependances parents/enfants des classes
function mobs.resolve(m)
	if m.parent and not m.base then
		local p = mobs.list[m.parent].__index
		mobs.resolve(p)
	
		for k, v in pairs(p) do
			if type(v) == "function" and m[k] == nil then
				m[k] = v
			end
		end
		
		m.base = p
	end
end

-- Cree un nouvel ennemis aux coordonnees donnees
function mobs.new(class, x, y)
	assert(type(class) == "string", "invalid mob class name")
	assert(mobs.list[class], "unknown mob class")
	assert(not mobs.list[class].__index.virtual, "cannot create a virtual mob")
	
	x = util.default(x, 0)
	y = util.default(y, 0)
	
	local ret = {}
	ret.x = x
	ret.y = y
	
	setmetatable(ret, mobs.list[class])
	ret.META = "mobs.list[\"" .. class .. "\"]" -- Info pour la sauvegarde
	ret:setup()
	
	return ret
end

-- Retourne une liste de toutes les classes de mobs disponibles
-- virt permet de garder ou non les mobs "virtuels"
function mobs.getList(virt)
	local ret = {}
	for k, v in pairs(mobs.list) do
		if virt or not v.__index.virtual then
			table.insert(ret, k)
		end
	end
	
	return ret
end

-- Retourne le nom d'un ennemis sans le creer
function mobs.getName(class)
	return mobs.list[class].__index.name
end

-- Dessine un ennemi sans la creer
function mobs.drawForShop(class, x, y)
	mobs.list[class].__index:drawForShop(x, y)
end

-- Retourne le nom d'un ennemi sans le creer
function mobs.getName(class)
	return mobs.list[class].__index.name
end

-- Retourne le prix d'un ennemi sans le creer
function mobs.getCost(class)
	return mobs.list[class].__index.cost
end

-- Retourne la description d'un ennemi sans le creer
function mobs.getDesc(class)
	return mobs.list[class].__index.desc
end

