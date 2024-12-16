local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Types = require(ReplicatedStorage.constants.Types)
local t = require(ReplicatedStorage.packages.t)

type ImpulsePayload = Types.GenericPayload & { merryGoRoundId: number }

return {
	process = function(world, player, impulsePayload)
		-- @TODO: Implement cooldown for this action on a merry-go-round per player specific basis to prevent spamming the action

		if not world:contains(impulsePayload.merryGoRoundId) then
			warn("Invalid merry go round id")
			return
		end

		local merryGoRound = world:get(impulsePayload.merryGoRoundId, Components.MerryGoRound)
		if not merryGoRound then
			warn("No merry go round component found")
			return
		end

		if merryGoRound.currentAngularVelocity >= merryGoRound.maxAngularVelocity then
			return -- they should not be able to increase the speed of the merry go round if it is already at max speed
		end

		local character = player.Character :: Model
		if not character then
			return
		end

		if character:GetAttribute("merryGoRoundImpulseCooldown" .. impulsePayload.merryGoRoundId) then
			return -- player is on cooldown for this merry go round impulse action
		end

		-- verify that the character is on the merry go round
		local rightFoot = character:FindFirstChild("RightFoot") :: BasePart?
		if not rightFoot then
			return
		end

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local rayDown = workspace:Raycast(rightFoot.Position, Vector3.new(0, -10, 0), rayParams)

		local merryGoRoundModel = rayDown.Instance:FindFirstAncestor("MerryGoRound")
		local merryGoRoundId = merryGoRoundModel and merryGoRoundModel:GetAttribute("serverEntityId")

		if merryGoRoundModel and merryGoRoundId and merryGoRoundId == impulsePayload.merryGoRoundId then
			if merryGoRound.hardStopIn == nil then -- we don't want to override the hard stop
				--[[print(
					`New target angular velocity after player-applied impulse: {merryGoRound.targetAngularVelocity + 0.1}`
				)--]]
				merryGoRound = merryGoRound:patch({
					targetAngularVelocity = merryGoRound.targetAngularVelocity + 0.1,
				})

				-- implement cooldown for this action on a merry-go-round per player specific basis to prevent spamming the action
				task.spawn(function()
					character:SetAttribute("merryGoRoundImpulseCooldown" .. impulsePayload.merryGoRoundId, true)
					task.wait(1)
					character:SetAttribute("merryGoRoundImpulseCooldown" .. impulsePayload.merryGoRoundId, nil)
				end)

				world:insert(impulsePayload.merryGoRoundId, merryGoRound)
			end
		end
	end,
	validatePayload = function()
		return t.strictInterface({
			action = t.literal("MerryGoRoundImpulse"),
			actionId = t.string,
			merryGoRoundId = t.number,
		})
	end,
} :: Types.Action<ImpulsePayload>
