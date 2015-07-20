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

MOB.name = "Avion" -- Nom d'affichage
MOB.parent = "base_air" -- A votre place j'y toucherais pas
MOB.sprite = assets.getImage("aircraft.png") -- Image
MOB.size = 16 -- Taille: generalement la moitie de la hauteur de l'image de l'ennemis
MOB.reward = 40 -- Combien de dollars il rapporte
MOB.iSpeed = 50 -- Sa vitesse
MOB.iHealth = 100 -- Sa vie
MOB.cost = 120
MOB.desc = [[Avion basique.]]