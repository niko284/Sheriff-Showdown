--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local BASE_WALK_SPEED = 16

local pair = jecs.pair

local function statModifiersApplied(world: jecs.World)
	for targetId in world:query(Components.Target) do
		local flat = 0
		local percentSum = 0
		local mult = 1

		for _, modifier: Components.StatModifier in
			world:query(Components.StatModifier, pair(Components.Affects, targetId))
		do
			if modifier.Stat ~= "WalkSpeed" then
				continue
			end
			if modifier.Category == "Flat" then
				flat += modifier.Value
			elseif modifier.Category == "PercentSum" then
				percentSum += modifier.Value
			elseif modifier.Category == "Mult" then
				mult *= modifier.Value
			end
		end

		local speed = (BASE_WALK_SPEED + flat) * (1 + percentSum) * mult
		world:set(targetId, Components.WalkSpeed, {
			speed = speed,
			modifier = mult,
		})
	end
end

return statModifiersApplied
