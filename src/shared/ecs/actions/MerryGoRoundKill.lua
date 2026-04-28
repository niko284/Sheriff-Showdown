--!strict

local Components = require("@ecs/components")
local Types = require("@constants/Types")
local t = require("@packages/t")

type MerryGoRoundKillPayload = Types.GenericPayload & { merryGoRoundId: number }

return {
	process = function(world, player, actionPayload)
		if not world:contains(actionPayload.merryGoRoundId) then
			warn("Invalid merry go round id")
			return
		end

		local merryGoRound: Components.MerryGoRound? = world:get(actionPayload.merryGoRoundId, Components.MerryGoRound)
		if not merryGoRound then
			warn("No merry go round component found")
			return
		end

		if merryGoRound.currentAngularVelocity < merryGoRound.maxAngularVelocity then
			return
		end

		local character = player.Character
		if not character then
			return
		end

		local serverEntityIdCharacter = character:GetAttribute("serverEntityId") :: number?
		if not serverEntityIdCharacter then
			warn("Character has no server entity id")
			return
		end

		if world:get(serverEntityIdCharacter, Components.Killed) then
			return
		end

		world:set(serverEntityIdCharacter, Components.Killed, {
			killerEntityId = actionPayload.merryGoRoundId,
			expiry = os.time() + 6,
			processRemoval = false,
		})
	end,
	validatePayload = t.strictInterface({
		merryGoRoundId = t.number,
		action = t.literal("MerryGoRoundKill"),
		actionId = t.string,
	}),
	afterProcess = {},
} :: Types.Action<MerryGoRoundKillPayload>
