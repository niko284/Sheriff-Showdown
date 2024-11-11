local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)

local REPLICATED_COMPONENTS = {
	Components.Gun,
	Components.Owner,
	Components.Children,
	Components.Bullet,
	Components.Velocity,
	Components.Target,
	Components.Killed,
	Components.Player,
	Components.Renderable,
	Components.Item,
	Components.MerryGoRound,
	Components.Team,
}

return MatterReplication.createReplicationSystem(REPLICATED_COMPONENTS)
