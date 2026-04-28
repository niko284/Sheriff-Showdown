--!strict

local jecs = require("@packages/jecs")

local Types = require("@constants/Types")
local WorldUtils = require("@ecs/Util")

local Middlewares: { [string]: (any) -> Types.MiddlewareFn<any> } = {}

function Middlewares.DoesNotHaveComponents(components: { jecs.Entity })
	return function(world: jecs.World, player: Player, _actionPayload)
		local entityId = WorldUtils.GetTargetEntityIdFromPlayer(world, player)
		if entityId == nil then
			return false
		end

		for _, component in components do
			if world:has(entityId, component) then
				print(`Player ${player.Name} has a component that they should not have.`)
				return false
			end
		end

		return true
	end
end

return Middlewares
