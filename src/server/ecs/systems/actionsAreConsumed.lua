--!strict

local jecs = require("@packages/jecs")

local Actions = require("@ecs/actions")
local UUIDSerde = require("@utilities/UUIDSerde")

type ActionPayload = {
	actionId: string,
	action: string,
	velocity: Vector3?,
	origin: CFrame?,
	fromGun: number?,
	timestamp: number?,
	targetEntityId: number?,
	merryGoRoundId: number?,
	hitPosition: Vector3?,
	[string]: any,
}

type QueuedAction = {
	player: Player,
	payload: ActionPayload,
}

type State = {
	actionQueue: { QueuedAction },
}

local function actionsAreConsumed(world: jecs.World, state: State)
	local queue = state.actionQueue
	state.actionQueue = {}

	for _, queued in queue do
		local player = queued.player
		local actionPayload: { [string]: any } = queued.payload

		local action = Actions[actionPayload.action]
		if not action then
			warn(`Unknown action: {actionPayload.action}`)
			continue
		end

		local success, actionId = pcall(function()
			return UUIDSerde.Deserialize(actionPayload.actionId)
		end)
		if not success then
			warn(`Invalid actionId: {actionId}`)
			continue
		end
		actionPayload.actionId = actionId

		local validatePayload = action.validatePayload
		if validatePayload then
			local isValid, errorMessage = validatePayload(actionPayload)
			if not isValid then
				warn(`Invalid action payload: {errorMessage}`)
				continue
			end
		end

		local middlewareFns = action.middleware
		if middlewareFns then
			local shouldProcess = true
			for _, middlewareFn in middlewareFns do
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

		local afterProcessFns = action.afterProcess
		if afterProcessFns then
			for _, afterProcessFn in afterProcessFns do
				afterProcessFn(world, player, actionPayload)
			end
		end
	end
end

return actionsAreConsumed
