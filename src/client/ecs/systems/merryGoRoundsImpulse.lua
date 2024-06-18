local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local Remotes = require(ReplicatedStorage.network.Remotes)
local UUIDSerde = require(ReplicatedStorage.utils.UUIDSerde)

local LocalPlayer = Players.LocalPlayer

local CombatNamespace = Remotes.Client:GetNamespace("Combat")
local ProcessAction = CombatNamespace:Get("ProcessAction")

local useThrottle = Matter.useThrottle

local function merryGoRoundsImpulse(world: Matter.World)
	local character = LocalPlayer.Character

	if not character then
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

	-- account for a merry go round that is spinning too fast (this will kill the player)
	if rayDown then
		local merryGoRoundModel = rayDown.Instance:FindFirstAncestor("MerryGoRound")
		local merryGoRoundId = merryGoRoundModel and merryGoRoundModel:GetAttribute("serverEntityId")
		if merryGoRoundModel and merryGoRoundId then
			local merryGoRound = world:get(merryGoRoundId, Components.MerryGoRound) :: Components.MerryGoRound?
			if merryGoRound and merryGoRound.currentAngularVelocity >= merryGoRound.maxAngularVelocity then
				ProcessAction:SendToServer({
					actionId = UUIDSerde.Serialize(HttpService:GenerateGUID(false)),
					action = "MerryGoRoundKill",
					merryGoRoundId = merryGoRoundId,
				})
			end
		end
	end

	-- account for a merry go round that is spinning too slow when the player is on it (this will speed up the merry go round)
	if useThrottle(1) and rayDown then
		local merryGoRoundModel = rayDown.Instance:FindFirstAncestor("MerryGoRound")
		local merryGoRoundId = merryGoRoundModel and merryGoRoundModel:GetAttribute("serverEntityId")
		if merryGoRoundModel and merryGoRoundId then
			local merryGoRound = world:get(merryGoRoundId, Components.MerryGoRound) :: Components.MerryGoRound?
			if
				merryGoRound
				and merryGoRound.hardStopIn == nil
				and merryGoRound.currentAngularVelocity < merryGoRound.maxAngularVelocity
			then
				ProcessAction:SendToServer({
					actionId = UUIDSerde.Serialize(HttpService:GenerateGUID(false)),
					action = "MerryGoRoundImpulse",
					merryGoRoundId = merryGoRoundId,
				})
			end
		end
	end
end

return merryGoRoundsImpulse
