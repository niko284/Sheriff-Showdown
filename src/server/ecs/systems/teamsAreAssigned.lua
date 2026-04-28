--!strict

local jecs = require("@packages/jecs")
local replecs = require("@packages/replecs")

local Components = require("@ecs/components")

local function teamsAreAssigned(world: jecs.World)
	for eid, _target, renderable in world:query(Components.Target, Components.Renderable):without(Components.Team) do
		local teamAttribute = renderable.instance:GetAttribute("Team")
		if teamAttribute then
			world:set(eid, Components.Team, { name = teamAttribute })
			world:add(eid, jecs.pair(replecs.reliable, Components.Team))
		end
	end

	for eid, _target, renderable, team in world:query(Components.Target, Components.Renderable, Components.Team) do
		local teamAttribute = renderable.instance:GetAttribute("Team")
		if teamAttribute == nil then
			world:remove(eid, Components.Team)
			world:remove(eid, jecs.pair(replecs.reliable, Components.Team))
		elseif teamAttribute ~= team.name then
			world:set(eid, Components.Team, { name = teamAttribute })
		end
	end
end

return teamsAreAssigned
