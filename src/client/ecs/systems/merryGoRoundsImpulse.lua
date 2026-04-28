--!strict

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local jecs = require("@packages/jecs")

local BlinkClient = require("@client/modules/BlinkClient")
local Components = require("@ecs/components")
local UUIDSerde = require("@utilities/UUIDSerde")

local LocalPlayer = Players.LocalPlayer

local lastImpulseTime = 0

local function merryGoRoundsImpulse(world: jecs.World)
	local character = LocalPlayer.Character
	if not character then
		return
	end

	local rightFoot = character:FindFirstChild("RightFoot") :: BasePart?
	if not rightFoot then
		return
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = CollectionService:GetTagged("MerryGoRound")
	rayParams.FilterType = Enum.RaycastFilterType.Include
	local rayDown = workspace:Raycast(rightFoot.Position, Vector3.new(0, -10, 0), rayParams)

	if not rayDown then
		return
	end

	local merryGoRoundModel = rayDown.Instance:FindFirstAncestor("MerryGoRound")
	if not merryGoRoundModel then
		return
	end

	local serverEntityId = merryGoRoundModel:GetAttribute("serverEntityId")
	local clientEntityId = merryGoRoundModel:GetAttribute("clientEntityId")

	-- Kill player if merry-go-round is spinning at max velocity.
	if serverEntityId then
		local merryGoRound = clientEntityId and world:get(clientEntityId, Components.MerryGoRound)
		if merryGoRound and merryGoRound.currentAngularVelocity >= merryGoRound.maxAngularVelocity then
			BlinkClient.ProcessAction.Fire({
				actionId = UUIDSerde.Serialize(HttpService:GenerateGUID(false)),
				action = "MerryGoRoundKill",
				merryGoRoundId = serverEntityId,
			})
		end
	end

	-- Throttled: speed up merry-go-round once per second.
	local now = os.clock()
	if now - lastImpulseTime >= 1 and clientEntityId and serverEntityId then
		local merryGoRound = world:get(clientEntityId, Components.MerryGoRound)
		if
			merryGoRound
			and merryGoRound.hardStopIn == nil
			and merryGoRound.currentAngularVelocity < merryGoRound.maxAngularVelocity
		then
			lastImpulseTime = now
			BlinkClient.ProcessAction.Fire({
				actionId = UUIDSerde.Serialize(HttpService:GenerateGUID(false)),
				action = "MerryGoRoundImpulse",
				merryGoRoundId = serverEntityId,
			})
		end
	end
end

return merryGoRoundsImpulse
