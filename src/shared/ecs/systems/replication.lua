local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)

local REPLICATED_COMPONENTS = {
	Components.Gun,
	Components.Renderable,
	Components.Owner,
	Components.Target,
}

return MatterReplication.createReplicationSystem(REPLICATED_COMPONENTS)
