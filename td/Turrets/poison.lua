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
TURRET.name = "Lanceur de poison" -- Nom d'affichage
TURRET.sprite = assets.getImage("poison1.png") -- Image de base
TURRET.cannon = assets.getImage("poison2.png") -- Image de la partie qui tourne
TURRET.bullet = assets.getImage("poison3.png") -- Boulet
TURRET.iSound = assets.getSound("poison.wav") -- Son, effacez cette ligne si on n'en veux pas
TURRET.iRange = 180 -- Portee
TURRET.iBulletSpeed = 400 -- Vitesse du boulet
TURRET.iMaxPower = 1 -- Puissance maximum en secondes
TURRET.iShootCost = 1 -- Combien de puissance un tir enleve (en secondes)
TURRET.iCooldown = 0 -- Le temps en seconde entre les tirs d'affiles
TURRET.iDamages = 5 -- Les degats d'un boulet
TURRET.cost = 100 -- Le cout de la tourelle
TURRET.targetType = MOB_GROUND -- Le type de cible
TURRET.desc = [[Contre les ennemis au sol.]]

function TURRET:setup()
	TURRET.base.setup(self)
	self.list = {} -- Liste des cibles a taper
end

function TURRET:think(dt)
	TURRET.base.think(self, dt)
	
	for i = #self.list, 1, -1 do
		local v = self.list[i]
	
		v.time = v.time - dt
		if v.target.dead or v.time <= 0 then
			v.target.bPoison = v.target.bPoison - 1
			
			if v.target.bPoison == 0 then
				v.target.color[4] = 0
			else
				v.target.color[4] = v.target.bPoison * 25 + 75
			end
			
			table.remove(self.list, i)
		elseif not td.game.isClient then
			v.target:hurt(self.damages * dt)
		end
	end
end

function TURRET:onTargetHit(target)
	for k, v in pairs(self.list) do
		if v.target == target then
			-- Cible connue; on reset le temps
			v.time = 2.5
			return
		end
	end
	
	-- Trop de poison
	if target.bPoison >= 3 then
		return
	end

	-- On applique un filtre violet sur la cible
	target.color[1] = 255
	target.color[2] = 0
	target.color[3] = 255
	target.color[4] = target.bPoison * 25 + 75

	local tbl = {}
	tbl.time = 2.5
	tbl.target = target
	target.bPoison = target.bPoison + 1

	table.insert(self.list, tbl)
end
