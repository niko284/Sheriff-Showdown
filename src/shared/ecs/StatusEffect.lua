--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local pair = jecs.pair

export type StatusEffectName = "Slowed"

type StatModifierDef = {
	Stat: string,
	Category: "Flat" | "PercentSum" | "Mult",
	Value: number,
}

local EFFECT_MODIFIERS: { [StatusEffectName]: { StatModifierDef } } = {
	Slowed = {
		{ Stat = "WalkSpeed", Category = "Mult", Value = 0.95 },
	},
}

local StatusEffect = {}

-- Creates a status effect entity and attaches stat modifier children to it.
-- Returns the status effect entity id.
function StatusEffect.apply(
	world: jecs.World,
	targetEntityId: jecs.Entity,
	effect: StatusEffectName,
	duration: number?
): jecs.Entity
	local statusEffectEntity = world:entity()

	if duration then
		world:set(statusEffectEntity, Components.Lifetime, {
			expiry = (DateTime.now().UnixTimestampMillis / 1000) + duration,
		})
	end

	local effectComponent = Components[effect]
	world:add(statusEffectEntity, effectComponent)
	world:add(statusEffectEntity, pair(Components.Affects, targetEntityId))

	local modifiers = EFFECT_MODIFIERS[effect]
	if modifiers then
		for _, mod in modifiers do
			local modEntity = world:entity()
			world:set(modEntity, Components.StatModifier, {
				Category = mod.Category,
				Stat = mod.Stat,
				Value = mod.Value,
			})
			world:add(modEntity, pair(Components.Affects, targetEntityId))
			world:add(modEntity, pair(jecs.ChildOf, statusEffectEntity))
		end
	end

	return statusEffectEntity
end

-- Stacks a Slowed effect by creating a new status effect entity with a
-- multiplier that is 0.95× the current worst-case walkspeed.
-- Duration defaults to 4 seconds.
function StatusEffect.slow(world: jecs.World, targetEntityId: jecs.Entity, duration: number?)
	StatusEffect.apply(world, targetEntityId, "Slowed", duration or 4)
end

return StatusEffect
