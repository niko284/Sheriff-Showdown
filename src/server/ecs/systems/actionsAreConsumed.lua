local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = ReplicatedStorage.utils

local Actions = require(ReplicatedStorage.ecs.actions)
local Matter = require(ReplicatedStorage.packages.Matter)
local Remotes = require(ReplicatedStorage.network.Remotes)
local UUIDSerde = require(Util.UUIDSerde)

local CombatNamespace = Remotes.Server:GetNamespace("Combat")
local ProcessAction = CombatNamespace:Get("ProcessAction")

local useEvent = Matter.useEvent

local function actionsAreConsumed(world: Matter.World)
	for _, player, actionPayload in useEvent("ProcessAction", ProcessAction) do
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

		local middlewareFns = action.middleware
		local afterProcessFns = action.afterProcess

		-- any middleware that returns false will prevent the action from being processed
		if middlewareFns then
			local shouldProcess = true
			for _, middlewareFn in ipairs(middlewareFns) do
				shouldProcess = middlewareFn(world, player, actionPayload)
				if not shouldProcess then
					break
				end
			end

			if not shouldProcess then
				continue
			end
		end

		action.process(world, player, actionPayload)

		if afterProcessFns then
			for _, afterProcessFn in ipairs(afterProcessFns) do
				afterProcessFn(world, player, actionPayload)
			end
		end
	end
end

return actionsAreConsumed
