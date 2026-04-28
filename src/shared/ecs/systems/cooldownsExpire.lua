local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local function cooldownsExpire(world: jecs.World)
	local now = DateTime.now().UnixTimestampMillis
	for eid, cooldown in world:query(Components.Cooldown) do
		if now >= cooldown.expiry then
			world:remove(eid, Components.Cooldown)
		end
	end
end

return cooldownsExpire
