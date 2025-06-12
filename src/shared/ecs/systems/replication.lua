--!strict

local Components = require("@ecs/components")
local MatterReplication = require("@packages/MatterReplication")

local REPLICATED_COMPONENTS = {
	Components.Gun,
	Components.Owner,
	Components.Children,
	Components.Bullet,
	Components.Velocity,
	Components.Target,
	Components.Killed,
	Components.Player,
	Components.Item,
	Components.MerryGoRound,
	Components.Team,
	Components.Ragdolled,
	Components.Renderable,
}

return MatterReplication.createReplicationSystem(REPLICATED_COMPONENTS)
