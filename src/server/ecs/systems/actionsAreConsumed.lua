local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Actions = require(ReplicatedStorage.constants.Actions)
local Matter = require(ReplicatedStorage.packages.Matter)
local Remotes = require(ReplicatedStorage.Remotes)

local CombatNamespace = Remotes.Server:GetNamespace("Combat")
local ProcessAction = CombatNamespace:Get("ProcessAction")

local useEvent = Matter.useEvent

local function actionsAreConsumed(world: Matter.World)
	for _, player, actionPayload in useEvent("ProcessAction", ProcessAction) do
		print(`Processing action: {actionPayload.action}`)
		local action = Actions[actionPayload.action]

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
