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

td = td or {}

local game = {}
local meta = {}
meta.__index = game
meta.__metatable = game

-- Cree une nouvelle partie
function td.newGame()
	local ret = {}
	ret.showMenu = false 													-- Si le menu est affiche ou non
	ret.menuOver = false 													-- Si la souris est sur la barre du menu ou non
	ret.menuLen  = 0 														-- Largeur du menu en pixel
	ret.lifeE    = assets.getImage("lifeEmpty.png") 						-- La barre de vie quand elle est vide
	ret.lifeF    = assets.getImage("lifeFull.png") 							-- La barre de vie quand elle est pleine
	ret.arrow    = assets.getImage("arrow.png") 							-- La fleche de la liste des vagues
	ret.font     = assets.getFont("SegoeUI.ttf", 24) 						-- Police n°1
	ret.font2    = assets.getFont("SegoeUI.ttf", 14) 						-- Police n°2
	ret.fpos     = (200 - ret.font:getWidth("Tourelles")) / 2				-- Position du titre du menu
	ret.mobs     = {} 														-- Liste d'ennemis
	ret.turrets  = {} 														-- Liste des tourelles
	ret.cTurret  = 0 														-- Tourelle en dessous de la souris
	ret.mTurret  = 0 														-- Tourelle a placer
	ret.sndExp   = assets.getSound("explosion.wav") 						-- Son d'explosion
	ret.animExp  = anim.new(assets.getImage("explosion.png"), 5, 5, 75) 	-- Animation d'explosion
	ret.animBeam = anim.new(assets.getImage("beam.png"), 3, 1, 50) 			-- Animation du rayon laser
	ret.anims    = {} 														-- Liste des animations sur le terrain
	ret.drops    = {}														-- Les "drops"
	ret.money    = 200 														-- Argent
	ret.lives    = 6 														-- Nombre de vies
	ret.startY   = 544 + (56 - ret.font2:getHeight() * 2) / 2 				-- Debut sur l'axe Y de la liste des vagues
	ret.cWave    = 1 														-- Vague qui va etre lancee
	ret.waveTime = 9999														-- Temps, en secondes, avant la prochaine vague
	ret.doWaves  = true 													-- Y'a-t-il encore des vagues?
	ret.doFirew  = false													-- Est-ce que c'est la fete?
	ret.winMusic = assets.getMusic("win.mp3")								-- Musique de victoire
	ret.winTime  = 0														-- Temps avant son de victoire
	ret.fwForced = false													-- Feu d'artifice force
	ret.lwPlayed = false													-- Si le son des ennemis aerien a ete joue
	ret.lwSound  = assets.getSound("luftwaffe.wav")							-- Le son des ennemis aerien
	ret.moneySnd = assets.getSound("money.wav")								-- Le son quand y'a plus d'argent
	ret.moneyPos = 0														-- La position de l'animation quand y'a plus d'argent
	ret.moneyTim = 0.3														-- Le temps de l'animation quand y'a plus d'argent
	ret.spawnLst = {}														-- La liste des ennemis invincibles
	ret.netCount = 0														-- Nombres d'objets dans ret.netList
	ret.netList  = {}														-- Liste d'objets partages entre client et serveurs
	
	return setmetatable(ret, meta)
end

-- Charge la liste des tourelles
function game:loadShop()
	if self.isClient then
		self.shop = mobs.getList()
		
		-- On trie les mobs
		table.sort(self.shop, function(a, b)
			return mobs.getCost(a) < mobs.getCost(b)
		end)
	else
		self.shop = turrets.getList()
		
		-- On trie les tourelles
		table.sort(self.shop, function(a, b)
			return turrets.getCost(a) < turrets.getCost(b)
		end)
	end
	
	-- On cree les info-bulles
	self.shopInfos = {}
	
	for k, v in pairs(self.shop) do
		local txt = {}
		txt.w = 0
		txt.h = 0
		
		if self.isClient then
			txt.text = mobs.getName(v) .. "\nPrix: " .. tostring(mobs.getCost(v)) .. "$\n" .. mobs.getDesc(v)
		else
			txt.text = turrets.getName(v) .. "\nPrix: " .. tostring(turrets.getCost(v)) .. "$\n" .. turrets.getDesc(v)
		end
		
		local last = 1
		local slen = txt.text:len()
		
		-- On mesure les dimensions du texte
		for i = 1, slen do
			if txt.text:sub(i, i) == "\n" or i == slen then
				local tw = self.font2:getWidth(txt.text:sub(last, i == slen and i or i - 1))
				
				if tw > txt.w then
					txt.w = tw
				end
				
				txt.h = txt.h + self.font2:getHeight()
				last = i + 1
			end
		end
		
		self.shopInfos[k] = txt
	end
end

-- Cree des donnees pour une vage
function game:createWave(line)
	local list = (type(line) == "string") and string.split(line, ",") or line
	local tbl = {}
	local maxw = 0
	local wy = self.startY
	
	tbl.w = 0
	tbl.array = {}
	
	for k, v in pairs(list) do
		if wy + self.font2:getHeight() + 5 >= 600 then
			wy = self.startY
			tbl.w = tbl.w + maxw + 10
			maxw = 0
		end
	
		local cnt
		local cls
		local entry = {}
		
		if type(v) == "string" then
			cnt, cls = v:match("(%d+)%*(.+)")
		else
			cnt = v.count
			cls = v.class
		end
		
		entry.count = tonumber(cnt)
		entry.class = cls
		entry.str = cnt .. "x " .. mobs.getName(cls)
		entry.w = self.font2:getWidth(entry.str)
		
		if entry.w > maxw then
			maxw = entry.w
		end
		
		wy = wy + self.font2:getHeight()
		tbl.array[k] = entry
	end
	
	tbl.w = 90 + tbl.w + maxw
	return tbl
end

-- Charge une liste de vague d'ennemis
function game:loadWave(txt)
	assert(type(txt) == "string", "invalid wave name")

	-- Lecture des vagues
	local sum = 0
	self.waves = {}
	
	for line in love.filesystem.lines("Waves/" .. txt .. ".txt") do
		local tbl = self:createWave(line)
		tbl.sum = sum
		table.insert(self.waves, tbl)
		
		sum = sum + tbl.w
	end
	
	return true
end

-- Demarre une partie
-- lvl est le nom (sans extension ni chemin) du niveau a charger
function game:start(lvl)
	-- On enleve les trucs qu'il y avait avant
	td.clearControls()
	td.background = nil
	td.showTitle = false
	td.animPos = 0
	td.inMenu = false
	td.sampleTurrets = {}
	td.music:stop()
	
	-- On charge le niveau
	self.lvlName = lvl
	self.level = td.newLevel()
	if not self.level:load(lvl) then
		return false, "Impossible de charger le niveau"
	end
	
	if not self.isClient and not self.isServer then
		-- On charge les vagues
		if not self:loadWave(lvl .. "_normal") then
			return false, "Impossible de charger les vagues"
		end
	else
		self.waves = {}
	end
	
	self.bg = assets.getImage(lvl .. ".png")
	self.beam = anim.newInstance(self.animBeam, 0, 544, true)
	
	if td.blur then
		self.canvas1 = love.graphics.newCanvas(800, 544)
		self.canvas2 = love.graphics.newCanvas(800, 544)
	end
	
	self:loadShop()
	
	-- On cree l'IU
	self.waveBtn = ui.new("Button", 695, 549, 100, 46)
	self.waveBtn:setLabel("Lancer")
	td.addControl(self.waveBtn)
	
	function self.waveBtn.action(b)
		if #self.waves == 0 then
			return
		end
	
		if self.isClient then
			if self.waves[#self.waves].sent then
				return
			end
		
			local wave = "wave:"
			for k, v in pairs(self.waves[#self.waves].array) do
				wave = wave .. v.count .. "*" .. v.class
				
				if k ~= #self.waves[#self.waves].array then
					wave = wave .. ","
				end
			end
		
			self.doWaves = true
			self.waves[#self.waves].sent = true
			self.socket:send(wave .. "\n")
		else
			self:addMoneyDrop(math.floor(math.min(30, self.waveTime) / 30 * 50), 272, 400)
			self:launchWave()
			
			if self.isServer then
				self.player:send("gotoWave:" .. self.cWave .. "\n")
			end
		end
	end

	-- Fireworks
	self.fireworks = {}
	return true
end

-- Dessine le jeu a l'ecran
function game:draw()
	local g = love.graphics
	local ml = math.serp(self.menuLen / 200, 10, 200)

	if td.blur then
		td.effects.blurX:send("size", 800)
		td.effects.blurY:send("size", 544)
		
		-- On dessine tout dans un canvas
		g.setCanvas(self.canvas1)
	end
	
	g.setColor(255, 255, 255, 255)
	g.draw(self.bg)
	
	-- Les tourelles
	for k, v in pairs(self.turrets) do
		if v.spawning then
			local function stencil()
				g.rectangle("fill", v.x, v.y, 32, v.spawnAnim)
			end
			
			g.setStencil(stencil)
			v:draw()
			
			td.effects.edgeDetection:send("texSize", { 32, 32 })
			g.setInvertedStencil(stencil)
			g.setShader(td.effects.edgeDetection)
			v:draw()
			g.setShader()
			g.setStencil()
			
			g.setColor(40, 190, 240, 255)
			g.line(v.x - 4, v.y + v.spawnAnim, v.x + 40, v.y + v.spawnAnim)
		else
			v:draw()
		end
	end
	
	-- On dessine les ennemis
	for k, v in pairs(self.mobs) do
		g.push()
		g.translate(v.x, v.y)
		v:draw()
		g.pop()
	end
	
	-- Les animations (explosions, etc...)
	for k, v in pairs(self.anims) do
		anim.draw(v)
	end
	
	-- Les projectiles des tourelles
	for k, v in pairs(self.turrets) do
		v:drawBullets()
	end
	
	-- Les feux d'artifices
	for k, v in pairs(self.fireworks) do
		firework.draw(v)
	end
	
	-- Les drops
	for k, v in pairs(self.drops) do
		g.setColor(0, 128, 255, v.alpha)
		g.setFont(self.font2)
		g.print(v.str, v.x, v.y)
	end
	
	if td.blur then
		g.setCanvas()
		g.setColor(255, 255, 255, 255)
		g.draw(self.canvas1)
		
		-- Flou gaussien 9 prises, 2 passes
		-- On commence un flou horizontal
		g.setCanvas(self.canvas2)
		g.setShader(td.effects.blurX)
		g.draw(self.canvas1)
		
		-- Puis vertical
		g.setCanvas(self.canvas1)
		g.setShader(td.effects.blurY)
		g.draw(self.canvas2)
		g.setShader()
		
		-- Puis re-horizontal
		g.setCanvas(self.canvas2)
		g.setShader(td.effects.blurX)
		g.draw(self.canvas1)
		g.setCanvas()
	end
	
	g.setStencil(function()
		-- On selectionne les zones ou on veut notre flou
		
		if self.mTurret ~= 0 then
			g.circle("fill", love.mouse.getX(), love.mouse.getY(), turrets.getRange(self.shop[self.mTurret]), 64)
		elseif self.menuOver or self.menuLen > 0 then
			g.rectangle("fill", 790 - ml, 10, ml, 524)
		end
	end)
	
	if td.blur then
		-- Puis re-vertical (cette fois on l'affiche a l'ecran)
		g.setShader(td.effects.blurY)
		g.draw(self.canvas2)
		g.setShader()
	else
		g.setColor(128, 128, 128, 150)
		g.rectangle("fill", 0, 0, 800, 544)
	end
	
	g.setStencil()
	
	-- La tourelle a placer
	if self.mTurret ~= 0 then
		local t = self.shop[self.mTurret]
		local mx, my = love.mouse.getPosition()
		
		local gx, gy = math.floor(mx / 32), math.floor(my / 32)
		if gx >= 0 and gx < 25 and gy >= 0 and gy < 17 then
			if self.level:canPlaceTurretAt(gx + 1, gy + 1) then
				g.setColor(0, 255, 0, 128)
			else
				g.setColor(255, 0, 0, 128)
			end
			
			g.rectangle("fill", gx * 32, gy * 32, 32, 32)
		end
		
		td.effects.edgeDetection:send("texSize", { 32, 32 })
		g.setShader(td.effects.edgeDetection)
		g.setColor(255, 255, 255, 255)
		turrets.drawForShop(t, mx - 16, my - 16)
		g.setShader()
		
		g.setColor(150, 150, 150, 255)
		g.circle("line", mx, my, turrets.getRange(t), 64)
		
		local mul = math.sin(math.fmod(love.timer.getTime() * 1.5, math.pi / 2))
		g.setColor(0, 255, 0, math.lerp(1 - mul, 40, 255))
		g.circle("line", mx, my, mul * turrets.getRange(t), 64)
	end
	
	-- La barre du bas, avec un joli (ou pas) degrade
	local grad = td.effects.gradientY
	grad:send("sColor", { 0.8, 0.8, 0.8, 1 })
	grad:send("eColor", { 0.4, 0.4, 0.4, 1 })
	grad:send("yStart", 0)
	grad:send("yEnd", 56)
	g.setShader(grad)
	g.setColor(255, 255, 255, 255)
	g.rectangle("fill", 0, 544, 800, 56)
	g.setShader()

	-- On dessine les vagues qui vont arriver
	if self.cWave <= #self.waves then
		g.setStencil(function()
			g.rectangle("fill", 16, 544, 674, 56)
		end)
	
		local ww
		if self.cWave == 1 then
			ww = 90
		else
			ww = self.waves[self.cWave - 1].w
		end
		
		local wx = math.floor(math.min(30, self.waveTime) / 30 * ww) + 5 - self.waves[self.cWave].sum
		local wy = self.startY
		
		g.setColor(255, 255, 255, 255)
		for k, v in pairs(self.waves) do
			local maxw = 0
			
			if wx + 11 >= 16 then
				g.draw(self.arrow, wx, 544)
			end
			
			wx = wx + 50
			
			for wk, wv in pairs(v.array) do
				if wy + self.font2:getHeight() + 5 >= 600 then
					wy = self.startY
					wx = wx + maxw + 10
					maxw = 0
					
					if wx >= 690 then
						break
					end
				end
			
				if wx + wv.w >= 16 then
					g.print(wv.str, wx, wy)
				end
				
				if wv.w > maxw then
					maxw = wv.w
				end
				
				wy = wy + self.font2:getHeight()
			end
			
			wy = self.startY
			wx = wx + maxw + 40
		end
		
		g.setStencil()
	end
	
	anim.draw(self.beam)
	
	-- Le menu, si le joueur na pas de tourelle en main
	if self.mTurret ~= 0 then
		return
	end
	
	if self.menuOver or self.menuLen > 0 then
		g.setColor(150, 150, 150, 255)
		g.rectangle("line", 790 - ml, 10, ml, 524)
	else
		g.setColor(150, 150, 150, 100)
		g.rectangle("fill", 790 - ml, 10, ml, 524)
	end
	
	if self.menuLen > 0 then
		g.setStencil(function()
			g.rectangle("fill", 790 - ml, 10, ml, 524)
		end)
		
		-- Les tourelles a vendre
		local tx = 600
		local ty = 30 + self.font:getHeight()
		
		for k, v in pairs(self.shop) do
			if self.cTurret == k then
				g.setColor(150, 150, 150, 128)
				g.rectangle("fill", tx - 2, ty - 2, 36, 36)
			end
		
			g.setColor(255, 255, 255, 255)
			
			if self.isClient then
				mobs.drawForShop(v, tx, ty)
			else
				turrets.drawForShop(v, tx, ty)
			end
			
			tx = tx + 37
			if tx + 42 >= 790 then
				tx = 600
				ty = ty + 37
			end
		end
		
		g.setColor(255, 255, 255, 255)
		g.setFont(self.font)
		g.print(self.isClient and "Tanks" or "Tourelles", 590 + self.fpos, 20)
		
		if self.moneyPos % 2 ~= 0 then
			g.setColor(255, 0, 0, 255)
		end
		
		g.print("Argent: " .. tostring(self.money) .. "$", 600, 524 - self.font:getHeight())
		g.setColor(255, 255, 255, 255)
		
		if not self.isClient then
			local ly = 524 - self.font:getHeight() - 42
			g.draw(self.lifeE, 600, ly)
			
			g.setStencil(function()
				g.rectangle("fill", 790 - ml, ly, math.max(0, 600 + self.lives / 6 * 180 - (790 - ml)), 32)
			end)
			
			g.draw(self.lifeF, 600, ly)
		end
		
		g.setStencil()
		
		if self.cTurret ~= 0 then
			local txt = self.shopInfos[self.cTurret]
			local bx, by = love.mouse.getX() + 20, love.mouse.getY() + 20
			
			if bx + txt.w + 15 >= 800 then
				bx = 800 - txt.w - 15
			end
			
			g.setColor(0, 0, 0, 255)
			g.rectangle("fill", bx, by, txt.w + 10, txt.h + 10)
			g.setFont(self.font2)
			g.setColor(255, 255, 255, 255)
			g.print(txt.text, bx + 5, by + 5)
		end
	end
end

-- On fait avancer la simulation
function game:update(dt)
	-- Reseau
	if self.isClient or self.isServer then
		local sock = self.isServer and self.player or self.socket
		local r, w, err = socket.select({ sock }, {}, 0)
		
		if #r > 0 then
			local str, err = sock:receive("*l")
			
			if str then
				print("[NET] " .. str)
				local data = string.split(str, ":")
				
				if data and #data > 0 and self.netHandlers[data[1]] then
					local handler = data[1]
					table.remove(data, 1)
					
					self.netHandlers[handler](self, unpack(data))
				else
					print("Impossible de parser le packet " .. str)
				end
			else
				print("Erreur de reception: " .. err)
			end
		elseif err ~= "timeout" then
			print("Erreur de selection: " .. err)
		end
	end

	-- Le laser
	anim.update(self.beam, dt)
	
	-- L'animation quand y'a plus d'argent
	if self.moneyPos > 0 then
		self.moneyTim = self.moneyTim - dt
		
		if self.moneyTim <= 0 then
			self.moneyPos = self.moneyPos + 1
			self.moneyTim = 0.3
			
			if self.moneyPos >= 5 then
				self.moneyPos = 0
			end
		end
	end
	
	-- Les ennemis invincibles
	for i = #self.spawnLst, 1, -1 do
		self.spawnLst[i].time = self.spawnLst[i].time - dt
		
		if self.spawnLst[i].time < 0 then
			table.remove(self.spawnLst, i)
		else
			self.spawnLst[i].mob.health = self.spawnLst[i].mob.iHealth
		end
	end
	
	-- Les drops
	for i = #self.drops, 1, -1 do
		local v = self.drops[i]
		v.alpha = v.alpha - dt * 255
		v.y = v.y - dt * 20
		
		if v.alpha <= 0 then
			table.remove(self.drops, i)
		end
	end

	-- Animation du menu
	if self.showMenu then
		if self.menuLen < 200 then
			self.menuLen = math.min(self.menuLen + 300 * dt, 200)
		end
	elseif self.menuLen > 0 then
		self.menuLen = math.max(self.menuLen - 300 * dt, 0)
		
		if self.menuLen <= 0 then
			if not util.isPointInRect(love.mouse.getX(), love.mouse.getY(), 780, 10, 10, 524) then
				self.menuOver = false
			end
		end
	end
	
	-- Les ennemis
	for i = #self.mobs, 1, -1 do
		local v = self.mobs[i]
		v:think(dt)
		
		if v.dead then
			self.netList[v.netId] = nil
			table.remove(self.mobs, i)
		end
	end
	
	-- Les tourelles
	for k, v in pairs(self.turrets) do
		if v.spawning then
			v.spawnAnim = v.spawnAnim + dt * 80
			
			if v.spawnAnim >= 32 then
				v.spawning = false
			end
		end
		
		v:think(dt)
	end
	
	-- Les feux d'artifices
	if self.winTime > 0 then
		self.winTime = self.winTime - dt
		
		if self.winTime <= 0 then
			self.winMusic:play()
			self.doFirew = true
			self.fwForced = true
			self.waveBtn:setLabel("Suivant")
			
			local cl = td.nextLevel(self.lvlName)
			print("Prochain niveau: " .. cl)
			
			self.waveBtn.action = function()
				td.game = nil
				collectgarbage("collect")
				
				if cl then
					td.game = td.newGame()
					td.game:start(cl)
				else
					td.clearControls()
					td.showMainMenu()
				end
			end
		end
	end
	
	if self.doFirew and not self.winMusic:isPlaying() and (self.fwForced or math.random(0, 1000 * (#self.fireworks + 1)) < 5) then
		table.insert(self.fireworks, firework.new(math.random(100, 700), math.random(100, 444)))
		self.fwForced = false
	end
	
	for i = #self.fireworks, 1, -1 do
		if firework.update(self.fireworks[i], dt) then
			table.remove(self.fireworks, i)
		end
	end
	
	-- Les vagues
	if #self.mobs == 0 and self.doWaves then
		if not self.isClient or (self.cWave <= #self.waves and self.waves[self.cWave].sent) then
			self.waveTime = self.waveTime - dt
			
			if self.waveTime <= 0 then
				self:launchWave()
			end
		end
	end
	
	-- Les animations
	for i = #self.anims, 1, -1 do
		if anim.update(self.anims[i], dt) then
			table.remove(self.anims, i)
		end
	end
end

-- La souris a bouge!
function game:onMouseMove(x, y)
	if self.mTurret ~= 0 then
		return
	end

	if util.isPointInRect(x, y, 780, 10, 10, 524) then
		self.menuOver = true
	elseif self.menuOver then
		self.menuOver = false
	end
		
	if self.menuLen > 0 then
		local tx = 600
		local ty = 30 + self.font:getHeight()
		local found = false
		
		-- Au dessus d'une tourelle?
		for k, v in pairs(self.shop) do
			if util.isPointInRect(x, y, tx, ty, 32, 32) then
				found = true
				self.cTurret = k
				break
			end
			
			tx = tx + 37
			if tx + 42 >= 790 then
				tx = 600
				ty = ty + 37
			end
		end
		
		if self.cTurret ~= 0 and not found then
			self.cTurret = 0
		end
	end
end

-- Souris pressee
function game:onMousePress(btn, x, y)
end

-- Souris relachee
function game:onMouseRelease(btn, x, y)
	if btn == "l" then
		if self.mTurret == 0 then
			if self.showMenu then
				local ml = math.serp(self.menuLen / 200, 10, 200)
				
				if not util.isPointInRect(x, y, 790 - ml, 10, ml, 524) then
					self.showMenu = false
				end
			elseif self.menuOver then
				self.showMenu = true
			end
			
			if self.cTurret ~= 0 then
				local cost = self.isClient and mobs.getCost(self.shop[self.cTurret]) or turrets.getCost(self.shop[self.cTurret])
			
				if self.money < cost then
					if not self.moneySnd:isPlaying() then
						self.moneySnd:play()
						self.moneyPos = 1
					end
				elseif self.isClient then
					self:addMobToWave(self.shop[self.cTurret])
					self.money = self.money - cost
				else
					self.mTurret = self.cTurret
				end
			end
		else
			self:addTurret(self.shop[self.mTurret], math.floor(x / 32) + 1, math.floor(y / 32) + 1)
			
			if self.money < turrets.getCost(self.shop[self.mTurret]) or not (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
				self.mTurret = 0
				self.cTurret = 0
			end
		end
	elseif btn == "r" and self.mTurret ~= 0 then
		self.cTurret = 0
		self.mTurret = 0
	end
end

-- Permet d'ajouter un ennemis
function game:addMob(class)
	if self.isClient then
		return
	end

	local mob = mobs.new(class)
	self.netCount = self.netCount + 1
	self.netList[self.netCount] = mob
	mob.netId = self.netCount
	
	if self.isServer then
		self.player:send("mob:" .. class .. "\n")
	end
	
	if mob:isGround() then
		mob.path = self.level:buildPath(mob.size)
		mob:warpToFirstPoint()
	elseif not self.lwPlayed then
		self.lwSound:play()
		self.lwPlayed = true
	end
	
	-- On le teleporte un peu en arriere
	mob:think(1 / 1000)
	mob.x, mob.y = mob:lerpPos(-1)
	
	mob:sendField("x")
	mob:sendField("y")
	
	-- On l'ajoute a la liste des invincibles pendant 2.5 secondes
	local tbl = {}
	tbl.mob = mob
	tbl.time = 2.5
	
	table.insert(self.spawnLst, tbl)
	table.insert(self.mobs, mob)
	return mob
end

-- Permet d'ajouter une tourelle
-- x et y sont les coordonnees de la grille (1/25, 1/17)
function game:addTurret(class, x, y)
	if x >= 1 and x <= 25 and y >= 1 and y <= 17 and self.level:canPlaceTurretAt(x, y) then
		local t = turrets.new(class, (x - 1) * 32, (y - 1) * 32)
		t.gridX = x
		t.gridY = y
		t.spawning = true
		t.spawnAnim = 0
		
		table.insert(self.turrets, t)
		self.level:setGridValue(x, y, false)
		self.money = self.money - turrets.getCost(class)
		
		if self.isServer then
			self.player:send("turret:" .. class .. ":" .. x .. ":" .. y .. "\n")
		end
		
		self.netCount = self.netCount + 1
		self.netList[self.netCount] = t
		t.netId = self.netCount
		
		return true
	else
		return false
	end
end

-- Supprime une tourelle, et libere sa place
function game:removeTurret(t)
	self.netList[t.netId] = nil

	for k, v in pairs(self.turrets) do
		if v == t then
			if not self.isClient then
				self.level:setGridValue(t.gridX, t.gridY, true)
			end
			
			table.remove(self.turrets, k)
			return
		end
	end
end

-- Ajoute une explosion a un endroit
function game:addExplosion(x, y)
	self.sndExp:clone():play()
	table.insert(self.anims, anim.newInstance(self.animExp, anim.center(self.animExp, x, y)))
end

-- Enleve un point de vie au joueur
-- Si il ne lui en reste plus, game over.
function game:removeLife()
	self.lives = self.lives - 1
	
	-- Game over, on en profite pour nettoyer la memoire
	if self.lives <= 0 then
		td.game = nil
		td.removeControl(self.waveBtn)
		td.showMainMenu()
		collectgarbage("collect")
	end
end

-- Lance la prochaine vague d'ennemis
function game:launchWave()
	if not self.doWaves then return end

	for k, v in pairs(self.waves[self.cWave].array) do
		for i = 1, v.count do
			self:addMob(v.class)
		end
	end
	
	self.waveTime = 30
	self.cWave = self.cWave + 1
	
	if self.cWave > #self.waves or self.waves[self.cWave].sent == false then
		self.doWaves = false
		
		--[[if not self.isClient and not self.isServer then
			self.waveBtn.state = 4 -- On desactive le bouton
		end]]--
	end
end

-- Ajoute de l'argent
function game:addMoneyDrop(amount, x, y)
	assert(type(amount) == "number", "invalid amount")
	assert(type(x) == "number", "invalid x coord")
	assert(type(y) == "number", "invalid y coord")
	
	local drop = {}
	drop.str = "+ " .. tostring(amount) .. "$"
	drop.x = x - self.font2:getWidth(drop.str) / 2
	drop.y = y - self.font2:getHeight() / 2
	drop.alpha = 255
	
	table.insert(self.drops, drop)
	self.money = self.money + amount
end

-- Debute la fete!
function game:victory()
	self.winTime = 3
end

-- Ajoute un ennemis a la prochaine vague
function game:addMobToWave(class)
	if #self.waves == 0 or self.waves[#self.waves].sent then
		table.insert(self.waves, { ["sum"] = 0, ["array"] = {} })
	end
	
	local w = self.waves[#self.waves]
	local found = false
	
	for k, v in pairs(w.array) do
		if v.class == class then
			v.count = v.count + 1
			found = true
			break
		end
	end
	
	if not found then
		local entry = {}
		entry.class = class
		entry.count = 1
		
		table.insert(w.array, entry)
	end
	
	self.waves[#self.waves] = self:createWave(w.array)
	
	local sum = 0
	for k, v in pairs(self.waves) do
		v.sum = sum
		sum = sum + v.w
	end
end

-- Pour le multijoueur. str contient l'IP du serveur si il s'agit d'un client
function game:setupNetworking(str)
	assert(str == nil or type(str) == "string", "invalid ip given")
	require("socket")
	
	self.socket   = socket.tcp()
	self.isServer = str == nil
	self.isClient = str ~= nil
	self.doWaves  = false
	
	if self.isServer then
		local ret, err = self.socket:bind("*", td.port)
		if not ret then
			print("Erreur lors de l'association du serveur: " .. err)
			return false
		end
		
		ret, err = self.socket:listen(1)
		if not ret then
			print("Erreur lors du passage en mode ecoute: " .. err)
			return false
		end
		
		self.socket:settimeout(3)
		td.showLoadingScreen("Connexion")
		print("En attente d'une connexion a " .. self.socket:getsockname())
	else -- Client
		local ip
		local port
		local loc = str:find(":")
		
		if loc then
			ip = str:sub(1, loc - 1)
			port = tonumber(str:sub(loc + 1))
		else
			ip = str
			port = td.port
		end
		
		print("Connexion a " .. ip .. ":" .. port)
		local ret, err = self.socket:connect(ip, port)
		if not ret then
			print("Erreur lors de la connexion au serveur: " .. err)
			return false
		end
		
		ret, err = self.socket:receive("*l")
		if not ret then
			print("Impossible de recevoir: " .. err)
			return false
		end
		
		local g, v = ret:match("(%a+) (%d+%.%d+)")
		if g ~= "TowerDefense" or v ~= td.VERSION then
			print("Le joueur possede un jeu different: " .. ret)
			return false
		end
		
		self.socket:send("Salut!\n")
		self.netHandlers = self:setupClientHandlers()
		self.fpos = (200 - self.font:getWidth("Tanks")) / 2
	end
	
	return true
end

-- Retourne true si le jeu est pret a etre lance
function game:tickNetworking()
	local r, w, err = socket.select({ self.socket }, {}, 0)
	if #r == 0 then
		return false
	end

	self.player = self.socket:accept()
	if self.player == nil then
		return false
	end
	
	self.player:send("TowerDefense " .. td.VERSION .. "\n")
	local msg, err = self.player:receive("*l")
	
	if msg == "Salut!" then
		self.netHandlers = self:setupServerHandlers()
		return true
	elseif msg == nil then
		print("Impossible de recevoir: " .. err)
		return false
	else
		print("Le joueur adverse n'est pas compatible car il a repondu " .. msg)
		return false
	end
end

-- Installe les handlers reseau cote client
function game:setupClientHandlers()
	local h = {}

	function h:turret(class, x, y)
		local t = turrets.new(class, (x - 1) * 32, (y - 1) * 32)
		t.gridX = x
		t.gridY = y
		t.spawning = true
		t.spawnAnim = 0
		
		table.insert(self.turrets, t)
		
		self.netCount = self.netCount + 1
		self.netList[self.netCount] = t
		t.netId = self.netCount
	end
	
	function h:mob(class)
		local mob = mobs.new(class)
		self.netCount = self.netCount + 1
		self.netList[self.netCount] = mob
		mob.netId = self.netCount
		
		table.insert(self.mobs, mob)
	end
	
	function h:field(strId, name, value)
		local id = tonumber(strId)
	
		if self.netList[id] then
			if value == "true" then
				self.netList[id][name] = true
			elseif value == "false" then
				self.netList[id][name] = false
			else
				self.netList[id][name] = tonumber(value)
			end
		else
			print("ID reseau invalide " .. id)
		end
	end
	
	function h:call(strId, name, ...)
		local id = tonumber(strId)
	
		if self.netList[id] then
			if type(self.netList[id][name]) == "function" then
				self.netList[id][name](self.netList[id], ...)
			else
				print("Fonction " .. name .. " inconnu pour " .. self.netList[id].name)
			end
		else
			print("ID reseau invalide " .. id)
		end
	end
	
	function h:gotoWave(num)
		self.cWave = tonumber(num)
		self.waveTime = 30
	end
	
	return h
end

-- Installe les handlers reseau cote server
function game:setupServerHandlers()
	local h = {}
	
	function h:wave(wave)
		self.doWaves = true
		table.insert(self.waves, self:createWave(wave))
		
		local sum = 0
		for k, v in pairs(self.waves) do
			v.sum = sum
			sum = sum + v.w
		end
	end
	
	return h
end

-- Sauvegarde la partie
function game:save()
	-- Liste des variables a sauvegarder
	local whitelist = { "netCount", "netList", "mobs", "turrets", "money", "lives", "cWave", "waveTime", "doWaves", "doFirew", "winTime", "fwForced", "lwPlayed", "spawnLst" }
	
	local function serialize(f, o, serNet)
		if type(o) == "number" then
			f:write(tostring(o))
		elseif type(o) == "boolean" then
			f:write(o and "true" or "false")
		elseif type(o) == "string" then
			f:write("'" .. o .. "'") -- Note: si y'a des \ ca va crash!
		elseif type(o) == "table" then
			if (not serNet or serNet <= 0) and type(o.netId) == "number" then
				f:write("td.game.netList[" .. tostring(o.netId) .. "]")
				return
			end
			
			if type(o.META) == "string" then
				f:write("setmetatable({ ")
			else
				f:write("{ ")
			end
			
			local first = true
			for k, v in pairs(o) do
				if serNet and serNet <= 1 and type(v) == "table" and type(v.netId) == "number" then
					print("Sauvegarde: " .. k .. " ignore")
				else
					if type(v) == "number" or type(v) == "string" or type(v) == "table" or type(v) == "boolean" then
						if first then
							first = false
						else
							f:write(", ")
						end
						
						if type(k) == "number" then
							f:write("[" .. tostring(k) .. "] = ")
						else
							f:write("[\"" .. k .. "\"] = ")  -- Note: si y'a des \ ca va crash!
						end
						
						serialize(f, v, serNet and (serNet - 1) or nil)
					end
				end
			end
			
			if type(o.META) == "string" then
				f:write(" }, " .. o.META .. ")")
			else
				f:write(" }")
			end
		end
	end
	
	local function writeRefs(f, o, lvl, root)
		if lvl <= 0 then
			if type(o.netId) == "number" then
				f:write(root .. " = td.game.netList[" .. o.netId .. "]\n")
			end
		else
			for k, v in pairs(o) do
				if type(v) == "table" then
					if type(k) == "number" then
						writeRefs(f, v, lvl - 1, root .. "[" .. k .. "]")
					else
						writeRefs(f, v, lvl - 1, root .. "[\"" .. k .. "\"]")
					end
				end
			end
		end
	end

	local f = love.filesystem.newFile("save.txt")
	local ok, err = f:open("w")
	if not ok then
		print("Impossible de sauvegarder: " .. err)
		return
	end
	
	for k, v in pairs(whitelist) do
		f:write("td.game." .. v .. " = ")
	
		if k == 2 then
			serialize(f, self[v], 2)
		else
			serialize(f, self[v])
		end
		
		f:write("\n")
	end
	
	writeRefs(f, self.netList, 2, "td.game.netList")
	f:close()
end

-- Charge une partie
function game:load()
	local f = love.filesystem.newFile("save.txt")
	local ok, err = f:open("r")
	if not ok then
		print("Impossible de charger: " .. err)
		return
	end
	
	local g, err = loadstring(f:read())
	f:close()
	
	if not g then
		print("Impossible de charger: " .. err)
		return
	end
	
	g()
end
