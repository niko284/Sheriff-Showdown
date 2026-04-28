--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

type State = {
	scheduler: any,
}

local function healthUpdates(world: jecs.World, state: State)
	local deltaTime = state.scheduler:getDeltaTime()

	for eid, health in world:query(Components.Health) do
		if health.regenRate ~= 0 and health.health ~= health.maxHealth then
			world:set(eid, Components.Health, {
				health = math.min(health.health + health.regenRate * deltaTime, health.maxHealth),
				maxHealth = health.maxHealth,
				regenRate = health.regenRate,
				causedBy = health.causedBy,
			})
		end
	end
	-- Humanoid sync and kill insertion on health-reaches-zero are handled by
	-- the Health OnChange observer in server/ecs/observers.lua.
end

return healthUpdates
