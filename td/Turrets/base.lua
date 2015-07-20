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

TURRET.virtual = true

-- Initialise la tourelle avec ses valeurs par defaut
function TURRET:setup()
	self.range = self.iRange
end

-- Fait "penser" la tourelle (appele chaque ticks)
function TURRET:think(dt)
	if not td.game.isClient then
		if not self.focus or self.focus.dead then
			-- On cherche une cible
			local r2 = self.range * self.range
			local candidates = {}
		
			for k, v in pairs(td.game.mobs) do
				if bit.band(v:getType(), self.targetType) > 0 then
					local dx = v.x - self.x - 16
					local dy = v.y - self.y - 16
					
					if math.random(1, 100) >= 75 and dx * dx + dy * dy <= r2 then
						table.insert(candidates, v)
					end
				end
			end
			
			if self.targetMode == "fastest" then
				local f = 0
				local fidx
			
				for k, v in pairs(candidates) do
					if v.speed > f then
						f = v.speed
						fidx = k
					end
				end
				
				self.focus = candidates[fidx]
			elseif self.targetMode == "shielded" then
				for k, v in pairs(candidates) do
					if v.shield and v.shield > 0 then
						self.focus = v
					end
				end
			else
				self.focus = candidates[math.random(1, #candidates)]
			end
			
			if self.focus ~= self.oldFocus then
				if self.focus then
					self:sendCall("netSetTarget", self.focus.netId)
				else
					self:sendCall("netSetTarget", 0)
				end
				
				self.oldFocus = self.focus
			end
		end
	end
end

function TURRET:netSetTarget(strId)
	local id = tonumber(strId)

	if id <= 0 then
		self.focus = nil
	else
		self.focus = td.game.netList[id]
	end
end

function TURRET:sendField(name)
	if td.game.isServer and self.netId ~= nil then
		td.game.player:send("field:" .. self.netId .. ":" .. name .. ":" .. tostring(self[name]) .. "\n")
	end
end

function TURRET:sendCall(name, ...)
	if td.game.isServer and self.netId ~= nil then
		local args = { ... }
		
		if #args == 0 then
			td.game.player:send("call:" .. self.netId .. ":" .. name .. "\n")
		else
			td.game.player:send("call:" .. self.netId .. ":" .. name .. ":" .. table.concat(args, ":") .. "\n")
		end
	end
end
