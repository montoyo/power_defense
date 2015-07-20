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

TURRET.parent = "base_cannon" -- A votre place j'y toucherais pas
TURRET.name = "Vodka" -- Nom d'affichage
TURRET.sprite = assets.getImage("rocketl1.png") -- Image de base
TURRET.cannon = assets.getImage("rocketl3.png") -- Image de la partie qui tourne
TURRET.bullet = assets.getImage("poliakov.png") -- Boulet
TURRET.glassSnd = assets.getSound("vodka.wav")
TURRET.iRange = 300 -- Portee
TURRET.iBulletSpeed = 300 -- Vitesse du boulet
TURRET.iMaxPower = 3 -- Puissance maximum en secondes
TURRET.iShootCost = 3 -- Combien de puissance un tir enleve (en secondes)
TURRET.iCooldown = 0 -- Le temps en seconde entre les tirs d'affiles
TURRET.iDamages = 1 -- Les degats d'un boulet
TURRET.cost = 120 -- Le cout de la tourelle
TURRET.targetType = MOB_GROUND -- Le type de cible
TURRET.desc = [[DÃ©soriente les ennemis au sol.]]

function TURRET:setup()
	TURRET.base.setup(self)
	self.tourbilol = {}
end

function TURRET:think(dt)
	TURRET.base.think(self, dt)
	
	for i = #self.tourbilol, 1, -1 do
		local v = self.tourbilol[i]
		
		if v:hasBuff("speed", self) then
			v.angle = v.angle + 4 * math.pi * dt
		else
			table.remove(self.tourbilol, i)
		end
	end
end

function TURRET:netDoEffect(tg)
	local target = td.game.netList[tonumber(tg)]
	self.glassSnd:stop()
	self.glassSnd:play()
	
	for k, v in pairs(self.tourbilol) do
		if v == target then
			return
		end
	end
	
	target:addBuff("speed", "set", 0, 1, self)
	table.insert(self.tourbilol, target)
end

function TURRET:onTargetHit(target)
	self.glassSnd:stop()
	self.glassSnd:play()
	self:sendCall("netDoEffect", target.netId)

	if not td.game.isClient then
		for k, v in pairs(self.tourbilol) do
			if v == target then
				return
			end
		end

		target:addBuff("speed", "set", 0, 1, self)
		table.insert(self.tourbilol, target)
	end
end
