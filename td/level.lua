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

td = td or {}

local level = {}
local meta = {}
meta.__index = level
meta.__metatable = level

-- Cree un nouveau niveau
-- Ne pas oublier de le charger avec load()!
function td.newLevel()
	return setmetatable({}, meta)
end

-- Charge un niveau depuis un fichier
function level:load(str)
	assert(type(str) == "string", "invalid file name")

	-- Lecture des points
	self.points = {}

	for line in love.filesystem.lines("Levels/" .. str .. ".txt") do
		local x, y, angle, length = line:match("(-?[%d%.]+),(-?[%d%.]+),(-?[%d%.]+),(-?[%d%.]+)")
		local pt = {}
		pt.x = tonumber(x)
		pt.y = tonumber(y)
		pt.angle = tonumber(angle)
		pt.length = tonumber(length)
		
		table.insert(self.points, pt)
	end
	
	local start = love.timer.getTime()
	self:buildGrid()
	print("Grille construite en " .. tostring((love.timer.getTime() - start) * 1000) .. "ms !")
	
	return true
end

-- Remplace une valeur dans la grille
-- x et y sont des coordonees de cellule (/32 !!)
function level:setGridValue(x, y, val)
	assert(type(x) == "number" and x == math.floor(x) and x >= 1 and x <= 25, "invalid x cell coord")
	assert(type(y) == "number" and y == math.floor(y) and y >= 1 and y <= 17, "invalid y cell coord")
	assert(type(val) == "boolean", "invalid value")

	self.grid[x][y] = val
end

-- Retourne true si une tourelle peut etre placee dans une cellule
-- x et y sont des coordonees de cellule (/32 !!)
function level:canPlaceTurretAt(x, y)
	assert(type(x) == "number" and x == math.floor(x) and x >= 1 and x <= 25, "invalid x cell coord")
	assert(type(y) == "number" and y == math.floor(y) and y >= 1 and y <= 17, "invalid y cell coord")

	return self.grid[x][y]
end

-- Trouve des points au hasard qui constitueront le chemin a suivre par un vehicule
-- sz: La taille de vehicule
function level:buildPath(sz)
	assert(type(sz) == "number", "invalid vehicle size")
	assert(type(self.points) == "table", "level wasn't loaded")

	local ret = {}
	local l
	
	for k, v in pairs(self.points) do
		if k == 1 then
			l = math.random(-v.length + sz, v.length - sz)
		else
			l = math.clamp(math.random(l - 20, l + 20), -v.length + sz, v.length - sz)
		end
		
		local pt = {}
		pt.x = v.x + math.floor(math.cos(v.angle) * l)
		pt.y = v.y + math.floor(math.sin(v.angle) * l)
		
		table.insert(ret, pt)
	end
	
	return ret
end

-- Retourne les indexes des deux plus petites valeurs dans la liste des points
-- idx specifie la composante du point a comparer: x ou y
local function get2Smallest(points, idx)
	local ret = {}
	
	for i = 1, 2 do
		local smallest = math.huge
		
		for k, v in pairs(points) do
			if (i == 1 or k ~= ret[1]) and v[idx] < smallest then
				ret[i] = k
				smallest = v[idx]
			end
		end
	end
	
	return ret
end

-- Retourne un point inferieur ou superieur, en accord avec mode (+ ou -)
-- Si l'index de ce point est en dehors des limites, l'index retourne sera
-- le debut ou la fin de la liste.
local function nextPoint(i, mode)
	if mode == "+" then
		if i >= 4 then
			return 1
		else
			return i + 1
		end
	elseif mode == "-" then
		if i <= 1 then
			return 4
		else
			return i - 1
		end
	end
end

-- Reorganise les points dans le sens des aiguilles d'une montre,
-- en partant du point en haut a gauche
local function reorderPoints(points)
	local top = get2Smallest(points, "y")
	local first
	
	if points[top[1]].x < points[top[2]].x then
		first = top[1]
	else
		first = top[2]
	end
	
	-- On cherche dans quel sens les points sont organises
	local secA = points[nextPoint(first, "+")].y
	local secB = points[nextPoint(first, "-")].y
	local dir
	
	if secA < secB then
		dir = "+"
	else
		dir = "-"
	end
	
	-- On reorganise
	local ret = {}
	
	for i = 1, 4 do
		ret[i] = points[first]
		first = nextPoint(first, dir)
	end
	
	return ret
end

-- Verifie si un point est sous/sur (depends de test) une droite
-- ou si un point est a gauche/droite d'une droite (depends de swap)
local function lineTest(points, px, py, a, b, test, swap)
	local ax
	local ay
	local bx
	local by

	if swap then
		px, py = py, px
		ax = points[a].y
		ay = points[a].x
		bx = points[b].y
		by = points[b].x
	else
		ax = points[a].x
		ay = points[a].y
		bx = points[b].x
		by = points[b].y
	end

	local step = (by - ay) / (bx - ax)
	local iy = ay + step * (px - ax)
	
	if test == "g" then
		return (py >= iy)
	elseif test == "l" then
		return (py <= iy)
	end
end

-- Verifie si un point est a l'interieur d'un quadrilatere
-- Marche uniquement si les points ont ete reorganises au prealable
local function quadTest(points, x, y)
	local a = lineTest(points, x, y, 1, 2, "g", false)
	local b = lineTest(points, x, y, 2, 3, "l", true)
	local c = lineTest(points, x, y, 4, 3, "l", false)
	local d = lineTest(points, x, y, 1, 4, "g", true)
	
	return (a and b and c and d)
end

-- Parcourt chaques cases de la grille et verifie si elle passe par le chemin
-- Utilise par level:buildGrid(), ne pas appeler.
function level:checkQuad(points)
	--[[
	-- Tentative d'optimisation: echec (et temps gagne faible: 5ms)
	local minX =  math.huge
	local maxX = -math.huge
	local minY =  math.huge
	local maxY = -math.huge
	
	-- On cherche les limites du rectangle
	for k, p in pairs(points) do
		if p.x < minX then
			minX = p.x
		end
		
		if p.x > maxX then
			maxX = p.x
		end
		
		if p.y < minY then
			minY = p.y
		end
		
		if p.y > maxY then
			maxY = p.y
		end
	end
	
	minX = math.max(math.floor(minX / 32) + 1, 1)
	maxX = math.min(math.ceil(maxX / 32) + 1, 25)
	minY = math.max(math.floor(minY / 32) + 1, 1)
	maxY = math.min(math.ceil(maxY / 32) + 1, 17)
	]]--
	
	local minX = 1
	local maxX = 25
	local minY = 1
	local maxY = 17

	for x = minX, maxX do
		local gx = self.grid[x]
	
		for y = minY, maxX do
			if gx[y] then -- Si pas deja interdit
				local a = quadTest(points, (x - 1) * 32, (y - 1) * 32)
				local b = quadTest(points,  x * 32 - 1,  (y - 1) * 32)
				local c = quadTest(points,  x * 32 - 1,   y * 32 - 1)
				local d = quadTest(points, (x - 1) * 32,  y * 32 - 1)
				
				gx[y] = not (a or b or c or d)
			end
		end
	end
end

-- Construit un quadrilatere a partir des points i et i+1
-- Utilise par level:buildGrid(), ne pas appeler.
function level:makeQuad(i)
	local pts = {}	
	local p = self.points[i]
	local dx = math.cos(p.angle) * p.length
	local dy = math.sin(p.angle) * p.length
	pts[1] = { ["x"] = p.x - dx, ["y"] = p.y - dy }
	pts[2] = { ["x"] = p.x + dx, ["y"] = p.y + dy }
		
	p = self.points[i + 1]
	dx = math.cos(p.angle) * p.length
	dy = math.sin(p.angle) * p.length
	pts[3] = { ["x"] = p.x + dx, ["y"] = p.y + dy }
	pts[4] = { ["x"] = p.x - dx, ["y"] = p.y - dy }
		
	return reorderPoints(pts)
end

-- Construit une grille permetant de savoir si oui ou non une tourelle
-- peut etre placee dans une cellule. Utilise par level:load(), ne pas appeler.
function level:buildGrid()
	self.grid = {}
	for x = 1, 25 do
		local g = {}
		
		for y = 1, 17 do
			g[y] = true
		end
		
		self.grid[x] = g
	end
	
	for i = 1, #self.points - 1 do
		self:checkQuad(self:makeQuad(i))
	end
	
	collectgarbage("collect")
end

-- NOTE: Debeugage
level.quadTest = quadTest
