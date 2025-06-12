local Components = require("@ecs/components")
local Matter = require("@packages/Matter")

local function cooldownsExpire(world: Matter.World)
	local now = DateTime.now()
	for eid, cooldown: Components.Cooldown in world:query(Components.Cooldown) do
		if now.UnixTimestampMillis >= cooldown.expiry then
			world:remove(eid, Components.Cooldown)
		end
	end
end

return cooldownsExpire
