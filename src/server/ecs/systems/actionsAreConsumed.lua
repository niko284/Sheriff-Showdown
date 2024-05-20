local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = ReplicatedStorage.utils

local Actions = require(ReplicatedStorage.ecs.Actions)
local Matter = require(ReplicatedStorage.packages.Matter)
local Remotes = require(ReplicatedStorage.Remotes)
local UUIDSerde = require(Util.UUIDSerde)

local CombatNamespace = Remotes.Server:GetNamespace("Combat")
local ProcessAction = CombatNamespace:Get("ProcessAction")

local useEvent = Matter.useEvent

local function actionsAreConsumed(world: Matter.World)
	for _, player, actionPayload in useEvent("ProcessAction", ProcessAction) do
		print(`Processing action: {actionPayload.action}`)
		local action = Actions[actionPayload.action]

		local success, actionId = pcall(function()
			return UUIDSerde.Deserialize(actionPayload.actionId)
		end)

		if not success then
			warn(`Invalid actionId: {actionId}`)
			continue
		end
		actionPayload.actionId = actionId -- Replace the serialized actionId with the deserialized actionId

		local validatePayload = action.validatePayload
		if validatePayload then
			local isValid, errorMessage = validatePayload(actionPayload)
			if not isValid then
				warn(`Invalid action payload: {errorMessage}`)
				continue
			end
		end

		action.process(world, player, actionPayload)
	end
end

return actionsAreConsumed
