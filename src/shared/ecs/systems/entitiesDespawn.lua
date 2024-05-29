local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)

local function entitiesDespawn(world: Matter.World)
	for eid, _despawn in world:query(Components.Despawn) do
		world:despawn(eid)
	end
end

return {
	priority = math.huge,
	system = entitiesDespawn,
}
