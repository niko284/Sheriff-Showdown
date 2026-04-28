--!strict

local Components = require("@ecs/components")
local Types = require("@constants/Types")
local t = require("@packages/t")

type ImpulsePayload = Types.GenericPayload & { merryGoRoundId: number }

return {
	process = function(world, player, impulsePayload)
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
			return
		end

		local character = player.Character :: Model
		if not character then
			return
		end

		if character:GetAttribute("merryGoRoundImpulseCooldown" .. impulsePayload.merryGoRoundId) then
			return
		end

		local rightFoot = character:FindFirstChild("RightFoot") :: BasePart?
		if not rightFoot then
			return
		end

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local rayDown = workspace:Raycast(rightFoot.Position, Vector3.new(0, -10, 0), rayParams)
		if not rayDown then
			return
		end

		local merryGoRoundModel = rayDown.Instance:FindFirstAncestor("MerryGoRound")
		local merryGoRoundId = merryGoRoundModel and merryGoRoundModel:GetAttribute("serverEntityId")

		if merryGoRoundModel and merryGoRoundId and merryGoRoundId == impulsePayload.merryGoRoundId then
			if merryGoRound.hardStopIn == nil then
				world:set(impulsePayload.merryGoRoundId, Components.MerryGoRound, {
					targetAngularVelocity = merryGoRound.targetAngularVelocity + 0.1,
					currentAngularVelocity = merryGoRound.currentAngularVelocity,
					angularAcceleration = merryGoRound.angularAcceleration,
					maxAngularVelocity = merryGoRound.maxAngularVelocity,
					hardStopIn = merryGoRound.hardStopIn,
				})

				task.spawn(function()
					character:SetAttribute("merryGoRoundImpulseCooldown" .. impulsePayload.merryGoRoundId, true)
					task.wait(1)
					character:SetAttribute("merryGoRoundImpulseCooldown" .. impulsePayload.merryGoRoundId, nil)
				end)
			end
		end
	end,
	validatePayload = t.strictInterface({
		action = t.literal("MerryGoRoundImpulse"),
		actionId = t.string,
		merryGoRoundId = t.number,
	}),
} :: Types.Action<ImpulsePayload>
