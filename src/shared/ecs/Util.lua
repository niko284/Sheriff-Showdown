--!strict

local Components = require("@ecs/components")
local Matter = require("@packages/Matter")

local Util = {}

function Util.GetTargetEntityIdFromPlayer(World: Matter.World, Player: Player): number?
	for eid, _target: Components.Target, player: Components.PlayerComponent in
		World:query(Components.Target, Components.Player)
	do
		if player.player == Player then
			return eid
		end
	end
	return nil
end

return Util
