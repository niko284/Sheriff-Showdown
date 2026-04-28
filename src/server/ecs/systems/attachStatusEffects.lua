--!strict

local jecs = require("@packages/jecs")
local replecs = require("@packages/replecs")

local Components = require("@ecs/components")

local pair = jecs.pair

-- Status effect component tags that should be propagated to the affected entity
-- so systems can query e.g. world:query(Components.Slowed) to find all slowed entities.
local STATUS_EFFECT_TAGS: { jecs.Entity } = {
	Components.Slowed,
}

local initialized = false

local function attachStatusEffects(world: jecs.World)
	if initialized then
		return
	end
	initialized = true

	for _, tag in STATUS_EFFECT_TAGS do
		world:set(tag, jecs.OnAdd, function(statusEffectEntity: jecs.Entity)
			local affectedEntity = world:target(statusEffectEntity, Components.Affects)
			if not affectedEntity then
				return
			end
			world:add(affectedEntity, tag)
			world:add(affectedEntity, jecs.pair(replecs.reliable, tag))
		end)

		world:set(tag, jecs.OnRemove, function(statusEffectEntity: jecs.Entity)
			local affectedEntity = world:target(statusEffectEntity, Components.Affects)
			if not affectedEntity then
				return
			end

			-- Only remove the tag from the target if no other status effect entities
			-- of this type still affect it (jecs OnRemove fires before the archetype changes,
			-- so this entity is still in the query — skip it explicitly).
			local canRemove = true
			for otherEntity in world:query(tag, pair(Components.Affects, affectedEntity)) do
				if otherEntity ~= statusEffectEntity then
					canRemove = false
					break
				end
			end

			if canRemove then
				world:remove(affectedEntity, tag)
			end
		end)
	end
end

return attachStatusEffects
