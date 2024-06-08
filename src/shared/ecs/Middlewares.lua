--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)
local Types = require(ReplicatedStorage.constants.Types)
local WorldUtils = require(ReplicatedStorage.ecs.Util)

local Middlewares: { [string]: (any) -> Types.MiddlewareFn<any> } = {}

function Middlewares.DoesNotHaveComponents(components: { MatterTypes.Component<any> })
	return function(world, player, _actionPayload)
		local entityId = WorldUtils.GetTargetEntityIdFromPlayer(world, player)

		local hasComponent = false
		for _, component in components do
			if world:get(entityId, component) then
				hasComponent = true
				break
			end
		end

		if hasComponent then
			print(`Player ${player.Name} has a component that they should not have.`)
			return false
		end

		return true
	end
end

return Middlewares
