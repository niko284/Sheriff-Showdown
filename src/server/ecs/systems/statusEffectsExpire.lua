--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

-- Slowed is now a tag propagated from status effect entities that carry Lifetime components;
-- it is removed automatically when those entities despawn via lifetimesDespawn.
local STATUS_EFFECT_COMPONENTS = {
	Components.Killed,
	Components.Knocked,
}

local function statusEffectsExpire(world: jecs.World)
	for _, statusEffectComponent in STATUS_EFFECT_COMPONENTS do
		for eid, statusEffect in world:query(statusEffectComponent) do
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

return statusEffectsExpire
