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

require("security")
td = td or {}
td.VERSION = "0.1"
td.controls = td.controls or {}
td.port = td.port or 80
td.cheatTable = {}
td.cheatSequence = { "up", "up", "down", "down", "left", "right", "left", "right", "b", "a" }
td.cheatTime = love.timer.getTime()

-- Table d'evenements
td.events = td.events or {}
td.events.update = td.events.update or {}
td.events.draw = td.events.draw or {}
td.events.mouseMove = td.events.mouseMove or {}
td.events.mousePress = td.events.mousePress or {}
td.events.mouseRelease = td.events.mouseRelease or {}

-- Associe une fonction a un evenement
-- Lorsque l'evenement se produit, la fonction est appelee
function td.on(event, handler, name)
	assert(type(event) == "string" and td.events[event], "invalid event")
	assert(type(handler) == "function", "invalid event handler")
	
	-- Si aucun nom n'a ete choisi, on en prends un au "hasard"
	name = util.default(name, "unnamed_" .. tostring(love.timer.getTime()))
	td.events[event][name] = handler
end

function td.removeHandler(event, name)
	assert(type(event) == "string" and td.events[event], "invalid event")
	assert(type(name) == "string", "invalid handler name")
	
	td.events[event][name] = nil
end

-- Ajoute un controle d'interface utilisateur
function td.addControl(ctrl)
	assert(type(ctrl) == "table", "trying to add invalid control")
	table.insert(td.controls, ctrl)
end

-- Supprime un controle
function td.removeControl(ctrl)
	assert(type(ctrl) == "table", "trying to add invalid control")
	
	for k, v in pairs(td.controls) do
		if v == ctrl then
			table.remove(td.controls, k)
		end
	end
end

-- Vire tout les controles presents
function td.clearControls()
	td.controls = {}
end

-- Ajoute des tourelles et un ennemi exemple
function td.addSamples()
	td.sampleTurrets = {}
	td.sampleEnnemy = {}
	td.sampleEnnemy.sprite = assets.getImage("simple.png")
	td.sampleEnnemy.x = math.random(0, 800 - td.sampleEnnemy.sprite:getWidth())
	td.sampleEnnemy.y = -td.sampleEnnemy.sprite:getHeight()
	td.sampleEnnemy.time = math.random(3, 10)
	
	for i = 1, 3 do
		local x = 0
		local y = 0
		repeat
			x = math.floor(math.random(0, 800 - 32))
		until x < (800 - 300) / 2 - 32 or x > (800 - 300) / 2 + 300
		
		repeat
			y = math.floor(math.random(0, 600 - 32))
		until y < 200 - 32 or y > 370 + 75
	
		td.sampleTurrets[i] = turrets.new("simple", x, y)
	end
end

-- Affiche le menu multijoueur
function td.showMultiplayerMenu()
	-- On ajoute quelques controles
	local btn = ui.new("Button", (800 - 300) / 2, 200, 300, 75)
	btn:setLabel("Rejoindre")
	td.addControl(btn)
	
	function btn:action()
		td.clearControls()
		td.animPos = 0
		td.showIPMenu()
	end
	
	btn = ui.new("Button", (800 - 300) / 2, 285, 300, 75)
	btn:setLabel("Heberger")
	td.addControl(btn)
	
	function btn:action()
		td.game = td.newGame()
		
		if td.game:setupNetworking() then
			td.waitForNw = true
		else
			td.game = nil
		end
	end
	
	btn = ui.new("Button", (800 - 300) / 2, 370, 300, 75)
	btn:setLabel("Retour")
	td.addControl(btn)
	
	function btn:action()
		td.clearControls()
		td.showMainMenu()
	end

	td.title = "Multijoueur"
	td.titleW = td.font:getWidth(td.title)
	td.titleY = 32
	
	-- On prepare une animation
	td.animPos = 1
	td.animAlpha = 0
	
	for k, v in pairs(td.controls) do
		v.alpha = 0
	end
end

-- Affiche le menu d'IP
function td.showIPMenu()
	local tf = ui.new("TextField", (800 - 500) / 2, (600 - 26) / 2, 500, 26)
	td.addControl(tf)
	
	local btn = ui.new("Button", (800 - 500) / 2, (600 - 26) / 2 + 31, (500 - 5) / 2, 75)
	btn:setLabel("Ok")
	td.addControl(btn)
	
	function btn:action()
		if tf.text:len() == 0 then
			print("Addresse IP invalide")
			return
		end
	
		td.game = td.newGame()
		
		if td.game:setupNetworking(tf.text) then
			td.game:start("bg1")
		else
			td.game = nil
		end
	end
	
	btn = ui.new("Button", (800 - 500) / 2 + (500 - 5) / 2 + 5, (600 - 26) / 2 + 31, (500 - 5) / 2, 75)
	btn:setLabel("Retour")
	td.addControl(btn)
	
	function btn:action()
		td.clearControls()
		td.showMultiplayerMenu()
	end
	
	td.title = "Entrez une IP"
	td.titleW = td.font:getWidth(td.title)
	td.titleY = 32
end

-- Affiche le menu un joueur
function td.showSingleplayerMenu()
	local btn = ui.new("Button", (800 - 300) / 2, 200, 300, 75)
	btn:setLabel("Nouvelle partie")
	td.addControl(btn)
	
	function btn:action()
		td.game = td.newGame()
		td.game:start("bg1")
	end
	
	btn = ui.new("Button", (800 - 300) / 2, 285, 300, 75)
	btn:setLabel("Reprendre")
	td.addControl(btn)
	
	function btn:action()
		td.game = td.newGame()
		td.game:start("bg1")
		td.game:load()
	end
	
	btn = ui.new("Button", (800 - 300) / 2, 370, 300, 75)
	btn:setLabel("Retour")
	td.addControl(btn)
	
	function btn:action()
		td.clearControls()
		td.showMainMenu()
	end

	td.title = "Un Joueur"
	td.titleW = td.font:getWidth(td.title)
	td.titleY = 32
	
	-- On prepare une animation
	td.animPos = 1
	td.animAlpha = 0
	
	for k, v in pairs(td.controls) do
		v.alpha = 0
	end
end

-- Affiche le menu principal
function td.showMainMenu()
	-- On cree un bouton test
	local btn = ui.new("Button", (800 - 300) / 2, 200, 300, 75)
	btn:setLabel("Un joueur")
	td.addControl(btn)
	
	function btn:action()
		td.clearControls()
		td.showSingleplayerMenu()
	end
	
	btn = ui.new("Button", (800 - 300) / 2, 285, 300, 75)
	btn:setLabel("Multijoueur")
	td.addControl(btn)
	
	function btn:action()
		td.clearControls()
		td.showMultiplayerMenu()
	end
	
	btn = ui.new("Button", (800 - 300) / 2, 370, 145, 75)
	btn:setLabel("Options")
	td.addControl(btn)
	
	btn = ui.new("Button", (800 - 300) / 2 + 155, 370, 145, 75)
	btn:setLabel("Quitter")
	
	function btn:action()
		love.event.quit()
	end
	
	td.addControl(btn)
	
	-- On prepare une animation
	td.animPos = 1
	td.animAlpha = 0
	
	for k, v in pairs(td.controls) do
		v.alpha = 0
	end
	
	-- On definit un fond & on affiche le titre
	td.background = assets.getImage("sand.png")
	td.showTitle = true
	td.inMenu = true
	td.title = "Power Defense"
	td.titleW = td.font:getWidth(td.title)
	td.titleY = 32
	
	-- On ajoute quelques tourelles d'example
	td.addSamples()
	
	-- Son pour l'oral
	love.audio.setVolume(0.1)
	
	-- Musique!
	td.music = td.music or assets.getMusic("menu.mp3")
	td.music:setLooping(true)
	td.music:play()
end

-- Affiche un texte de chargement
function td.showLoadingScreen(msg)
	td.clearControls()
	td.background = assets.getImage("sand.png")
	td.showTitle = true
	td.inMenu = true
	td.animPos = 0
	td.title = msg
	td.titleW = td.font:getWidth(td.title)
	td.titleY = (600 - td.font:getHeight()) / 2
end

-- Retourne le nom du prochain niveau
function td.nextLevel(cur)
	for k, v in pairs(td.mapCycle) do
		if v == cur then
			return td.mapCycle[k + 1]
		end
	end
end

-- Initialisation
function love.load()
	print("Power Defense")
	print("Copyright (C) 2015 ALTHUSER, WITZ, BARBOTIN")
	print("Dossier: " .. love.filesystem.getWorkingDirectory())

	-- On charge tout ce dont on a besoin
	require("util")
	require("assets")
	require("nineslice")
	require("ui")
	require("level")
	require("anim")
	require("mobs")
	require("turrets")
	require("fireworks")
	require("game")
	require("effects")
	
	math.randomseed(os.time())
	mobs.load()
	turrets.load()
	
	-- On charge la liste des niveaux
	td.mapCycle = {}
	for map in love.filesystem.lines("Levels/map_cycle.txt") do
		table.insert(td.mapCycle, map)
	end
	
	-- On prepare les donnees pour le titre
	td.font2 = assets.getFont("SegoeUI.ttf", 14)
	td.font = assets.getFont("NexaRustSlab.otf", 64)
	td.inMenu = false
	
	-- Quelque parametres
	if love.system.getOS() == "Android" then
		td.blur = false
		td.scale = 720 / 600
	else
		td.scale = 1
		td.blur = true
		td.menuCanvas = love.graphics.newCanvas(800, 600)
	end
	
	-- On affiche le menu principal
	td.showMainMenu()
	td.startTime = love.timer.getTime()
	
	-- Repetition
	love.keyboard.setKeyRepeat(true)
end

-- Mise a jour. dt est le temps en secondes qui s'est ecoule depuis
-- le dernier appel a cette fonction
function love.update(dt)
	if td.waitForNw then
		if td.game:tickNetworking() then
			td.waitForNw = false
			td.game:start("bg1")
		end
	end

	for k, v in pairs(td.sampleTurrets) do
		v:menuThink(dt)
	end
	
	if td.inMenu then
		if td.sampleEnnemy.time <= 0 then
			td.sampleEnnemy.y = td.sampleEnnemy.y + 35 * dt
			
			if td.sampleEnnemy.y >= 600 then
				td.sampleEnnemy.x = math.random(0, 800 - td.sampleEnnemy.sprite:getWidth())
				td.sampleEnnemy.y = -td.sampleEnnemy.sprite:getHeight()
				td.sampleEnnemy.time = math.random(3, 10)
			end
		else
			td.sampleEnnemy.time = td.sampleEnnemy.time - dt
		end
	end

	if td.animPos > 0 then
		td.animAlpha = math.min(td.animAlpha + 255 * 3 * dt, 255)
		td.controls[td.animPos].alpha = td.animAlpha
		
		if td.animAlpha >= 255 then
			td.animAlpha = 0
			td.animPos = td.animPos + 1
			
			if td.animPos > #td.controls then
				td.animPos = 0 -- L'animation est terminee
			end
		end
	end
	
	util.callTable(td.events.update, dt)
	
	if td.game and not td.waitForNw then
		td.game:update(dt)
	end
end

-- Dessin
function love.draw()
	local g = love.graphics
	g.scale(td.scale, td.scale)
	
	if td.inMenu and td.blur then
		g.setCanvas(td.menuCanvas)
	end
	
	if td.background then
		g.setColor(255, 255, 255, 255)
		g.draw(td.background)
	end
	
	for k, v in pairs(td.sampleTurrets) do
		v:draw()
	end
	
	if td.inMenu then
		if td.sampleEnnemy.time <= 0 then
			g.draw(td.sampleEnnemy.sprite, td.sampleEnnemy.x, td.sampleEnnemy.y, math.pi / 2)
		end
	end
	
	if td.showTitle then
		g.setFont(td.font)
		g.print(td.title, (800 - td.titleW) / 2, td.titleY)
	end
	
	if td.game and not td.waitForNw then
		td.game:draw()
	end
	
	if td.inMenu and td.blur then
		g.setCanvas()
		g.setShader(td.effects.scanlines)
		td.effects.scanlines:send("iGlobalTime", love.timer.getTime() - td.startTime)
		g.setColor(255, 255, 255, 255)
		g.draw(td.menuCanvas)
		g.setShader()
	end
	
	for k, v in pairs(td.controls) do
		v:onDraw()
	end
	
	util.callTable(td.events.draw)
	
	g.setFont(td.font2)
	g.setColor(255, 255, 255, 255)
	g.print("Power Defense - Github - IPS: " .. tostring(love.timer.getFPS()), 5, 5)
end

-- Souris bougee
function love.mousemoved(x, y, dx, dy)
	x = x / td.scale
	y = y / td.scale

	if util.callTable(td.events.mouseMove, x, y, dx, dy) then
		return
	end
	
	if td.game then
		td.game:onMouseMove(x, y)
	end

	for k, v in pairs(td.controls) do
		v:onMouseMove(x, y)
	end
end

-- Souris appuyee
function love.mousepressed(x, y, btn)
	x = x / td.scale
	y = y / td.scale

	if util.callTable(td.events.mousePress, x, y, btn) then
		return
	end
	
	if td.game then
		td.game:onMousePress(btn, x, y)
	end

	for k, v in pairs(td.controls) do
		v:onMousePress(x, y, btn)
	end
end

-- Test de securite: si security.lua n'a pas ete inclus, on quite tout de suite
pcall(function()
	local ffi = require("ffi")
	ffi.cdef("void exit(int status);")
	ffi.C.exit(1234)
end)

-- Souris relachee
function love.mousereleased(x, y, btn)
	x = x / td.scale
	y = y / td.scale

	if util.callTable(td.events.mouseRelease, x, y, btn) then
		return
	end
	
	if td.game then
		td.game:onMouseRelease(btn, x, y)
	end

	for k, v in pairs(td.controls) do
		v:onMouseRelease(x, y, btn)
	end
end

-- Touche presee
function love.keypressed(key, repe)
	for k, v in pairs(td.controls) do
		v:onKeyPress(key, repe)
	end
end

-- Touche relachee
function love.keyreleased(key)
	if key == "`" then
		-- On charge l'editeur
		require("editor")
	elseif key == "f10" then
		td.blur = not td.blur
	elseif key == "f6" and td.game then
		td.game:save()
	elseif td.game then
		if love.timer.getTime() - td.cheatTime > 2 then
			td.cheatTable = { key }
		else
			table.insert(td.cheatTable, key)
			
			if #td.cheatTable == #td.cheatSequence then
				local wrong = false
				for i = 1, #td.cheatTable do
					if td.cheatTable[i] ~= td.cheatSequence[i] then
						wrong = true
						break
					end
				end
				
				if wrong then
					td.cheatTable = {}
				else
					td.game.money = 9999
				end
			end
		end
		
		td.cheatTime = love.timer.getTime()
	end
end

-- Texte
function love.textinput(txt)
	for k, v in pairs(td.controls) do
		v:onText(txt)
	end
end

local oldGetX = love.mouse.getX
love.mouse.getX = function()
	return oldGetX() / td.scale
end

local oldGetY = love.mouse.getY
love.mouse.getY = function()
	return oldGetY() / td.scale
end

local oldGetPos = love.mouse.getPosition
love.mouse.getPosition = function()
	local x, y = oldGetPos()
	return x / td.scale, y / td.scale
end
