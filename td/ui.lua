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

ui = ui or {}
ui.classes = {}

-- Enregistre une classe de controle IU.
function ui.register(name, tbl)
	assert(type(name) == "string", "invalid class name")
	assert(type(tbl)  == "table",  "invalid class table")
	
	util.secureMethod(tbl, "onInit")
	util.secureMethod(tbl, "onDraw")
	util.secureMethod(tbl, "onMouseMove")
	util.secureMethod(tbl, "onMousePress")
	util.secureMethod(tbl, "onMouseRelease")
	util.secureMethod(tbl, "onKeyPress")
	util.secureMethod(tbl, "onKeyRelease")
	util.secureMethod(tbl, "onText")
	
	local meta = {}
	meta.__index = tbl
	meta.__metatable = tbl
	
	ui.classes[name] = meta
end

-- Cree un nouveau controle IU du type de la classe demandee.
function ui.new(class, x, y, w, h)
	assert(type(class) == "string", "invalid class name")
	
	local cls = ui.classes[class]
	assert(cls ~= nil, "unknown UI class")
	
	local ret = {}
	setmetatable(ret, cls)
	
	ret.x = util.default(x, 0)
	ret.y = util.default(y, 0)
	ret.w = util.default(w, 100)
	ret.h = util.default(h, 100)
	ret:onInit()
	
	return ret
end

---------------------------------------------- BOUTON ----------------------------------------------

local btn = {}
btn.states = {}
btn.font = assets.getFont("SegoeUI.ttf", 24)

-- On cree un systeme 9 tranches par etate du bouton (normal, souris au dessus, clicke, desactive)
local img = assets.getImage("btns.png")
for i = 1, 4 do
	btn.states[i] = nine.create(img, 10, 10, 32, 32, 0, (i - 1) * 32)
end

-- On cree les fonctions du bouton
function btn:onInit()
	self.state = 1 -- Etat normal
	self.alpha = 255 -- Transparence
	
	-- Libelle
	self.label = ""
	self.labelW = 0
	self.labelH = 0
end

function btn:onDraw()
	local g = love.graphics
	g.setColor(255, 255, 255, self.alpha)

	nine.draw(btn.states[self.state], self.x, self.y, self.w, self.h)
	
	g.setFont(btn.font)
	g.setColor(255, 255, 255, self.alpha)
	g.print(self.label, self.x + (self.w - self.labelW) / 2, self.y + (self.h - self.labelH) / 2)
end

function btn:onMouseMove(x, y)
	if util.isPointInRect(x, y, self.x, self.y, self.w, self.h) then
		if self.state == 1 then
			self.state = 2 -- La souris est sur le bouton, on passe a l'etat suivant
		end
	elseif self.state == 2 then
		self.state = 1 -- La souris est partie du bouton, on revient a l'etat normal
	end
end

function btn:onMousePress(x, y, btn)
	if btn == "l" and self.state == 2 then -- Si bouton de gauche enfonce & la souris est sur le bouton
		self.state = 3 -- Passage a l'etat enfonce
	end
end

function btn:onMouseRelease(x, y, btn)
	if btn == "l" and self.state == 3 then -- Si bouton de gauche relache & le bouton est enfonce
		if util.isPointInRect(x, y, self.x, self.y, self.w, self.h) then
			self.state = 2 -- On revient a l'etat MouseOver
			
			if type(self.action) == "function" then
				self:action()
			end
		else
			self.state = 1 -- On revient a l'etat normal
		end
	end
end

function btn:setLabel(lbl)
	assert(type(lbl) == "string", "invalid label")
	
	self.label = lbl
	self.labelW = btn.font:getWidth(lbl)
	self.labelH = btn.font:getHeight()
end

-- On enregistre le bouton
ui.register("Button", btn)

---------------------------------------------- CHAMP DE TEXTE ----------------------------------------------

local tf = {}
tf.font = assets.getFont("SegoeUI.ttf", 14)

function tf:onInit()
	self.text = ""
	self.focused = false
end

function tf:onMouseRelease(x, y, btn)
	if btn == "l" and util.isPointInRect(x, y, self.x, self.y, self.w, self.h) then
		self.focused = true
	elseif self.focused then
		self.focused = false
	end
end

function tf:onText(txt)
	if self.focused then
		self.text = self.text .. txt
	end
end

function tf:onDraw()
	local g = love.graphics
	
	g.setColor(255, 255, 255, 100)
	g.rectangle("fill", self.x, self.y, self.w, self.h)
	
	if self.focused then
		g.setColor(0, 128, 255, 255)
	else
		g.setColor(255, 255, 255, 255)
	end
	
	g.rectangle("line", self.x, self.y, self.w, self.h)
	
	local y = (self.h - self.font:getHeight()) / 2
	g.setFont(self.font)
	g.setColor(255, 255, 255, 255)
	g.print(self.text, self.x + 5, self.y + y)
end

function tf:onKeyPress(key, repe)
	if self.focused and key == "backspace" and self.text:len() > 0 then
		self.text = self.text:sub(1, self.text:len() - 1)
	end
end

-- On enregistre le champ de text
ui.register("TextField", tf)
