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

TURRET.parent = "base_cannon"
TURRET.name = "Lance-rocket"
TURRET.sprite = assets.getImage("rocketl1.png")
TURRET.cannon = assets.getImage("rocketl2.png")
TURRET.bullet = assets.getImage("rocket.png")
TURRET.iSound = assets.getSound("rocketl.wav")
TURRET.iRange = 350
TURRET.iBulletSpeed = 600
TURRET.iBulletAccel = 400
TURRET.sBulletSpeed = 100
TURRET.iMaxPower = 4
TURRET.iShootCost = 4
TURRET.iCooldown = 0
TURRET.iDamages = 70
TURRET.cost = 83
TURRET.targetType = MOB_AIR
TURRET.desc = [[Contre les ennemis aeriens.
Lent mais inflige beaucoup.]]
