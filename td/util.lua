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

-- Bloque une valeur x entre min et max
function math.clamp(x, min, max)
	if x < min then
		return min
	elseif x > max then
		return max
	else
		return x
	end
end

-- Interpole de maniere lineaire
function math.lerp(x, min, max)
	return min + x * (max - min)
end

-- Interpole de facon sinusoidale
function math.serp(x, min, max)
	return min + (math.sin(x * math.pi - math.pi / 2) + 1) / 2 * (max - min)
end

-- Decoupe une chaine de caractere a chaque occurence de tok
function string.split(str, tok)
	assert(type(str) == "string", "invalid string")
	assert(type(tok) == "string", "invalid token")

	local ret = {}
	
	while true do
		local idx = str:find(tok)
		
		if idx then
			table.insert(ret, str:sub(1, idx - 1))
			str = str:sub(idx + 1)
		else
			break
		end
	end
	
	table.insert(ret, str)
	return ret
end

-- Retourne true si deux listes contiennent la meme chose
function table.equals(a, b)
	if #a ~= #b then
		return false
	end

	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	
	return true
end

util = util or {}

-- Retourne def si x est invalide
function util.default(x, def)
	if x == nil or type(x) ~= type(def) then
		return def
	else
		return x
	end
end

-- Retourne un clone de tbl
function util.cloneTable(tbl)
	assert(type(tbl) == "table", "not a table")

	local ret = {}
	for k, v in pairs(tbl) do
		ret[k] = v
	end
	
	return ret
end

-- Retourne un clone de tbl et realise une copie de ses sous-tables
function util.cloneTableDeep(tbl)
	assert(type(tbl) == "table", "not a table")

	local ret = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			ret[k] = util.cloneTableDeep(v)
		else
			ret[k] = v
		end
	end
	
	return ret
end

-- Ajoute une fonction vide a une table si l'index n'existe pas
function util.secureMethod(t, k)
	if t[k] == nil or type(t[k]) ~= "function" then
		t[k] = function() end
	end
end

-- Verifie si un point est dans un rectangle
function util.isPointInRect(px, py, rx, ry, rw, rh)
	return (px >= rx and px < rx + rw and py >= ry and py < ry + rh)
end

-- Verifie si deux rectangle sont en collision
function util.isColliding(x1, y1, w1, h1, x2, y2, w2, h2)
	return not (x1 > x2 + w2 or x1 + w1 < x2 or y1 > y2 + h2 or y1 + h1 < y2)
end

-- Verifie si un point est dans un cercle
function util.isPointInCircle(px, py, cx, cy, r)
	local dx = cx - px
	local dy = cy - py
	
	return (dx * dx + dy * dy <= r * r) -- On evite les "au carre" et "racines carre"; c'est trop lent!
end

-- Apelle toutes les fonctions situes dans un tableau avec les parametres donnes
-- Si une des fonctions retourne une valeur non nulle (diffÃ©rente de nil, 0 et false),
-- La boucle se stoppe et retourne la valeur retournee
function util.callTable(tbl, ...)
	assert(type(tbl) == "table", "invalid table")

	for k, v in pairs(tbl) do
		local ret = v(...)
		
		if ret then
			return ret
		end
	end
end

-- Compte le nombre d'entrees presentes dans une table
-- Ne pas utiliser pour les tables ayant un index numerique
function util.tableCount(tbl)
	assert(type(tbl) == "table", "invalid table")
	
	local ret = 0
	for k, v in pairs(tbl) do
		ret = ret + 1
	end
	
	return ret
end
