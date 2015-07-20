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

nine = nine or {}

-- Cree un systeme 9 tranches. Img: Image, Ew: Largeur d'un coin, Eh: Hauteur d'un coin
function nine.create(img, ew, eh, iw, ih, ox, oy)
	iw = util.default(iw, img:getWidth())
	ih = util.default(ih, img:getHeight())
	ox = util.default(ox, 0)
	oy = util.default(oy, 0)

	local ret = {}
	local nq = love.graphics.newQuad
	local rw = img:getWidth()
	local rh = img:getHeight()
	
	ret.img = img
	ret.ew = ew
	ret.eh = eh
	ret.iw = iw
	ret.ih = ih
	
	ret.e1 = nq(ox,           oy,           ew,          eh,          rw, rh) -- Gauche, Haut
	ret.e2 = nq(ox + iw - ew, oy,           ew,          eh,          rw, rh) -- Droite, Haut
	ret.e3 = nq(ox + iw - ew, oy + ih - eh, ew,          eh,          rw, rh) -- Droite, Bas
	ret.e4 = nq(ox,           oy + ih - eh, ew,          eh,          rw, rh) -- Gauche, Bas
	ret.c  = nq(ox + ew,      oy + eh,      iw - 2 * ew, ih - 2 * eh, rw, rh)
	ret.l1 = nq(ox + ew,      oy,           iw - 2 * ew, eh,          rw, rh) -- Haut
	ret.l2 = nq(ox + ew,      oy + ih - eh, iw - 2 * ew, eh,          rw, rh) -- Bas
	ret.l3 = nq(ox,           oy + eh,      ew,          ih - 2 * eh, rw, rh) -- Gauche
	ret.l4 = nq(ox + iw - ew, oy + eh,      ew,          ih - 2 * eh, rw, rh) -- Droite
	
	return ret
end

-- Dessine le systeme - tranche a l'ecran
function nine.draw(n, x, y, w, h)
	local d = love.graphics.draw
	local ew = n.ew
	local eh = n.eh
	local sw = (w - 2 * ew) / (n.iw - 2 * ew)
	local sh = (h - 2 * eh) / (n.ih - 2 * eh)
	local img = n.img
	
	-- Ligne du Haut
	d(img, n.e1, x, y, 0)
	d(img, n.l1, x + ew, y, 0, sw, 1)
	d(img, n.e2, x + w - ew, y)
	
	-- Ligne du milieu
	d(img, n.l3, x, y + eh, 0, 1, sh)
	d(img, n.c, x + ew, y + eh, 0, sw, sh)
	d(img, n.l4, x + w - ew, y + eh, 0, 1, sh)
	
	-- Ligne du Bas
	d(img, n.e4, x, y + h - eh)
	d(img, n.l2, x + ew, y + h - eh, 0, sw, 1)
	d(img, n.e3, x + w - ew, y + h - eh)
end
