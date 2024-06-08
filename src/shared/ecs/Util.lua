--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)

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
