local Components = require("@ecs/components")
local Matter = require("@packages/Matter")

local STATUS_EFFECT_COMPONENTS = {
	Components.Killed,
	Components.Slowed,
	Components.Knocked,
}

local function statusEffectsExpire(world: Matter.World)
	for _, statusEffectComponent in ipairs(STATUS_EFFECT_COMPONENTS) do
		for eid, statusEffect: Components.StatusEffect in world:query(statusEffectComponent) do
			if
				statusEffect.expiry
				and (DateTime.now().UnixTimestampMillis / 1000) >= statusEffect.expiry
				and statusEffect.processRemoval ~= false
			then
				world:remove(eid, statusEffectComponent)
			end
		end
	end
end

return {
	system = statusEffectsExpire,
	priority = 10,
}
