local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local function lifetimesDespawn(world: jecs.World)
	local now = workspace:GetServerTimeNow()
	for eid, lifetime in world:query(Components.Lifetime) do
		if now >= lifetime.expiry then
			world:delete(eid)
		end
	end
end

return lifetimesDespawn
