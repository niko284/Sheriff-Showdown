--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local Util = {}

function Util.GetTargetEntityIdFromPlayer(world: jecs.World, player: Player): jecs.Entity?
	for eid, _, playerData in world:query(Components.Target, Components.Player) do
		if playerData.player == player then
			return eid
		end
	end
	return nil
end

return Util
