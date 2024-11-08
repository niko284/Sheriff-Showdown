--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Types = require(ReplicatedStorage.constants.Types)
local t = require(ReplicatedStorage.packages.t)

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
			return -- merry go round is not spinning fast enough to kill. this check isn't 100% necessary but it's good to have.
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
			return -- character is already dead
		end

		world:insert(
			serverEntityIdCharacter,
			Components.Killed({
				killerEntityId = actionPayload.merryGoRoundId,
				expiry = os.time() + 5,
			})
		)
	end,
	validatePayload = function()
		return t.strictInterface({
			merryGoRoundId = t.number,
			action = t.literal("MerryGoRoundKill"),
			actionId = t.string,
		})
	end,
	afterProcess = {},
} :: Types.Action<MerryGoRoundKillPayload>
