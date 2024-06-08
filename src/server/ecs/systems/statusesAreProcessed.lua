local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Components = require(ReplicatedStorage.ecs.components)

local STATUS_EFFECT_COMPONENTS = {
	Killed = Components.Killed,
	Slowed = Components.Slowed,
}

local function statusesAreProcessed(world: Matter.World, state)
	for name, component in STATUS_EFFECT_COMPONENTS do
		for eid, statusRecord in world:queryChanged(component) do
			if statusRecord.new and statusRecord.old == nil then
				state.services.StatusService.StatusProcessed:Fire(eid, name)
			end
		end
	end
end

return statusesAreProcessed
