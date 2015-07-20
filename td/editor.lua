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

-- Variables
local points = {}
local font = assets.getFont("SegoeUI.ttf", 24)
local sel = 0
local selCenter = true -- Si false, alors on a clique sur l'extremite
local selDX = 0
local selDY = 0
local deleting = false
local exchanging = false
local exchange = 0
local file = "bg1"
local lvl
local zone = 0

-- On vire tout et on met la carte en tant que fond
td.clearControls()
td.background = assets.getImage(file .. ".png")
td.showTitle = false
td.animPos = 0
td.inMenu = false
td.sampleTurrets = {}
td.music:stop()

local function loadLvl(str)
	lvl = td.newLevel()
	assert(lvl:load(str), "couldn't load level")
	
	points = lvl.points
end

--loadLvl("bg1")

-- On cree nos controles
local btnSave = ui.new("Button", 0, 550, 150, 50)
btnSave:setLabel("Enregistrer")

function btnSave:action()
	local f, err = io.open("Levels/" .. file .. ".txt", "w")
	
	if not f then
		print("Impossible d'enregistrer: " .. err)
		return
	end
	
	for k, v in pairs(points) do
		local line = tostring(math.clamp(v.x, 0, 800)) .. "," .. tostring(math.clamp(v.y, 0, 574)) .. "," .. tostring(v.angle) .. "," .. tostring(v.length)
		f:write(line .. "\n")
	end
	
	f:close()
end

td.addControl(btnSave)

local btnAdd = ui.new("Button", 150, 550, 150, 50)
btnAdd:setLabel("Point")

function btnAdd:action()
	-- On cree un nouveau point au centre de l'ecran
	local pt = {}
	pt.x = 800 / 2
	pt.y = 600 / 2
	pt.angle = math.pi / 4
	pt.length = 64
	
	table.insert(points, pt)
end

td.addControl(btnAdd)

local btnDel = ui.new("Button", 300, 550, 150, 50)
btnDel:setLabel("Supprimer")

function btnDel:action()
	if deleting then
		deleting = false
		btnDel:setLabel("Supprimer")
	else
		deleting = true
		btnDel:setLabel("Annuler")
	end
end

td.addControl(btnDel)

local btnEx = ui.new("Button", 450, 550, 150, 50)
btnEx:setLabel("Echanger")

function btnEx:action()
	if exchanging then
		exchanging = false
		exchange = 0
		btnEx:setLabel("Echanger")
	else
		exchanging = true
		btnEx:setLabel("Annuler")
	end
end

td.addControl(btnEx)

local btnBg = ui.new("Button", 600, 550, 150, 50)
btnBg:setLabel("Fond")

function btnBg:action()
	local y = 50
	local btns = {}

	-- On cree un bouton par fond
	for k, v in pairs(love.filesystem.getDirectoryItems("Images")) do
		if v:len() > 6 and v:sub(1, 2):lower() == "bg" and v:sub(v:len() - 3):lower() == ".png" then
			local btn = ui.new("Button", (800 - 200) / 2, y, 200, 32)
			btn:setLabel(v:sub(1, v:len() - 4))
			
			table.insert(btns, btn)
			td.addControl(btn)
			y = y + 37
		end
	end

	local function btnAction(self)
		file = self.label
		td.background = assets.getImage(file .. ".png")
		
		for k, v in pairs(btns) do
			v.action = nil -- J'ai peur des fuites de memoires ;(
			td.removeControl(v)
		end
		
		btns = nil -- La encore :S
	end
	
	for k, v in pairs(btns) do
		v.action = btnAction
	end
end

td.addControl(btnBg)

local btnClose = ui.new("Button", 750, 550, 50, 50)
btnClose:setLabel("X")

function btnClose:action()
	-- On supprime tout les recepteurs d'evenements
	td.removeHandler("draw", "editor")
	td.removeHandler("mousePress", "editor")
	td.removeHandler("mouseMove", "editor")
	td.removeHandler("mouseRelease", "editor")
	
	-- On vire les controles
	td.clearControls()
	
	-- Et on en profite pour nettoyer la memoire
	collectgarbage("collect")
	
	-- On affiche le menu principal
	td.showMainMenu()
end

td.addControl(btnClose)

-- Dessin de tout les points
td.on("draw", function()
	local g = love.graphics	
	local lastX1 = 0
	local lastY1 = 0
	local lastX2 = 0
	local lastY2 = 0

	for k, v in pairs(points) do
		-- Point central
		g.setColor(255, 0, 255, 200)
		g.circle("fill", v.x, v.y, 20, 16)
		
		-- Ligne & extremites
		local dx = math.cos(v.angle) * v.length
		local dy = math.sin(v.angle) * v.length
		
		g.line(v.x - dx, v.y - dy, v.x + dx, v.y + dy)
		g.circle("fill", v.x + dx, v.y + dy, 10, 8)
		
		-- Numero du point
		local kStr = tostring(k)
		g.setColor(255, 255, 255, 255)
		g.setFont(font)
		g.print(kStr, v.x - 20 + (40 - font:getWidth(kStr)) / 2, v.y - 20 + (40 - font:getHeight()) / 2)
		
		-- Liaison avec le point precedent
		if k > 1 then
			g.setColor(0, 255, 0, 200)
			g.line(lastX1, lastY1, v.x - dx, v.y - dy)
			g.line(lastX2, lastY2, v.x + dx, v.y + dy)
		end
		
		lastX1 = v.x - dx
		lastY1 = v.y - dy
		lastX2 = v.x + dx
		lastY2 = v.y + dy
	end
	
	if zone > 0 then -- NOTE: Debeugage
		local z = lvl:makeQuad(zone)
		g.setColor(0, 255, 0, 100)
		g.polygon("fill", z[1].x, z[1].y, z[2].x, z[2].y, z[3].x, z[3].y, z[4].x, z[4].y)
	end
	
	-- Ligne du bas
	g.setColor(128, 128, 128, 255)
	g.rectangle("fill", 0, 544, 800, 6)
end, "editor")

-- Clique...
td.on("mousePress", function(x, y, btn)
	if deleting or exchanging then return end

	if btn == "l" then
		for k, v in pairs(points) do
			if util.isPointInCircle(x, y, v.x, v.y, 20) then -- On teste le centre
				sel = k
				selCenter = true
				selDX = v.x - x
				selDY = v.y - y
				
				break
			else
				local dx = v.x + math.cos(v.angle) * v.length
				local dy = v.y + math.sin(v.angle) * v.length
				
				if util.isPointInCircle(x, y, dx, dy, 10) then -- On teste l'extremite
					sel = k
					selCenter = false
					selDX = dx - x
					selDY = dy - y
					
					break
				end
			end
		end
	end
end, "editor")

-- ...glisse...
td.on("mouseMove", function(x, y)
	if sel > 0 then
		local px = x + selDX
		local py = y + selDY
	
		if selCenter then
			points[sel].x = px
			points[sel].y = py
		else
			local dx = px - points[sel].x
			local dy = py - points[sel].y
			
			points[sel].length = math.sqrt(dx * dx + dy * dy)
			points[sel].angle = math.atan2(dy, dx)
		end
	end
end, "editor")

-- ...relache!
td.on("mouseRelease", function(x, y, btn)
	if y >= 574 then -- Cette zone ne nous concerne pas
		return
	end

	if btn == "l" then
		if sel > 0 then -- Point relache
			sel = 0
		elseif deleting or exchanging then -- Suppression ou echange
			local id = 0
			for k, v in pairs(points) do
				if util.isPointInCircle(x, y, v.x, v.y, 20) then
					id = k
					break
				end
			end
			
			if deleting then
				if id > 0 then
					table.remove(points, id)
				end
			
				deleting = false
				btnDel:setLabel("Supprimer")
			else -- Echange, donc
				if id > 0 then
					if exchange > 0 then
						-- L'utilisateur a choisit deux points, on procede a l'echange
						points[exchange], points[id] = points[id], points[exchange]
						
						exchange = 0
						exchanging = false
						btnEx:setLabel("Echanger")
					else
						exchange = id
					end
				else
					exchange = 0
					exchanging = false
					btnEx:setLabel("Echanger")
				end
			end
		end
	elseif btn == "r" and lvl then -- NOTE: Debeugage
		for i = 1, #points - 1 do
			if lvl.quadTest(lvl:makeQuad(i), x, y) then
				zone = i
				return
			end
		end
		
		-- Pas trouve
		zone = 0
	end
end, "editor")
