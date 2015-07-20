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
TURRET.name = "Tourelle Simple" -- Nom d'affichage
TURRET.sprite = assets.getImage("bcannon1.png") -- Image de base
TURRET.cannon = assets.getImage("bcannon2.png") -- Image de la partie qui tourne
TURRET.bullet = assets.getImage("bullet.png") -- Boulet
TURRET.iSound = assets.getSound("piou.wav") -- Son, effacez cette ligne si on n'en veux pas
TURRET.iRange = 200 -- Portee
TURRET.iBulletSpeed = 500 -- Vitesse du boulet
TURRET.iMaxPower = 1.5 -- Puissance maximum en secondes
TURRET.iShootCost = 0.65 -- Combien de puissance un tir enleve (en secondes)
TURRET.iCooldown = 0.2 -- Le temps en seconde entre les tirs d'affiles
TURRET.iDamages = 7 -- Les degats d'un boulet
TURRET.cost = 50 -- Le cout de la tourelle
TURRET.targetType = MOB_GROUND -- Le type de cible
TURRET.desc = [[Contre les ennemis au sol.]]
