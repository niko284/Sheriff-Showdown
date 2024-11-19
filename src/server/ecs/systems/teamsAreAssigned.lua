local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local Types = require(ReplicatedStorage.constants.Types)

local useEvent = Matter.useEvent

local function teamsAreAssigned(world: Matter.World)
	-- newly assigned teams
	for eid, _target: Components.Target, renderable: Components.Renderable<Types.Character> in
		world:query(Components.Target, Components.Renderable):without(Components.Team)
	do
		local teamAttribute = renderable.instance:GetAttribute("Team")
		if teamAttribute then
			world:insert(eid, Components.Team({ name = teamAttribute }))
		end
	end

	-- account for the case where we change the team of a player after it has been assigned.
	for eid, _target: Components.Target, renderable: Components.Renderable<Types.Character>, team in
		world:query(Components.Target, Components.Renderable, Components.Team)
	do
		for _ in useEvent(renderable.instance, renderable.instance:GetAttributeChangedSignal("Team")) do
			local teamAttribute = renderable.instance:GetAttribute("Team")
			if teamAttribute == nil then
				world:remove(eid, Components.Team)
			else
				world:insert(eid, team:patch({ name = teamAttribute }))
			end
		end
	end
end

return teamsAreAssigned
