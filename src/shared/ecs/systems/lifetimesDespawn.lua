local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Components = require(ReplicatedStorage.ecs.components)

local function lifetimesDespawn(world: Matter.World)
	for eid, lifetime in world:query(Components.Lifetime) do
		if (DateTime.now().UnixTimestampMillis / 1000) >= lifetime.expiry then
			world:despawn(eid)
		end
	end
end

return {
	system = lifetimesDespawn,
}
