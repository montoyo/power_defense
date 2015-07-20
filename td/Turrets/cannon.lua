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

TURRET.parent = "base_cannon"
TURRET.name = "La grosse bertha"
TURRET.sprite = assets.getImage("bertha1.png")
TURRET.cannon = assets.getImage("bertha2.png")
TURRET.bullet = assets.getImage("bertha3.png")
TURRET.iSound = assets.getSound("bertha.wav")
TURRET.iRange = 300
TURRET.iBulletSpeed = 200
TURRET.iMaxPower = 3
TURRET.iShootCost = 3
TURRET.iCooldown = 0
TURRET.iDamages = 30
TURRET.cost = 60
TURRET.targetType = MOB_GROUND -- Le type de cible
TURRET.desc = [[Contre les ennemis au sol.\nLent mais inflige beaucoup.]]
