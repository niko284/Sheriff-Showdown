local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Components = require(ReplicatedStorage.ecs.components)

local STATUS_EFFECT_COMPONENTS = {
	Components.Killed,
	Components.Slowed,
	Components.Knocked,
}

local function statusEffectsExpire(world: Matter.World)
	for _, statusEffectComponent in ipairs(STATUS_EFFECT_COMPONENTS) do
		for eid, statusEffect: Components.StatusEffect in world:query(statusEffectComponent) do
			if statusEffect.expiry and (DateTime.now().UnixTimestampMillis / 1000) >= statusEffect.expiry then
				world:remove(eid, statusEffectComponent)
			end
		end
	end
end

return {
	system = statusEffectsExpire,
	priority = 10,
}
