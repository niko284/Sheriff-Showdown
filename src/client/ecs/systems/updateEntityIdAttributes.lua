local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)

local ServerEntity = MatterReplication.ServerEntity

local function updateEntityIdAttributes(world)
	for _, renderable, serverEntity in world:query(Components.Renderable, ServerEntity) do
		if not renderable.instance:GetAttribute("ServerEntityId") then
			print(`assigning attribute ServerEntityId={serverEntity.id} to {renderable.instance}`)
			renderable.instance:SetAttribute("ServerEntityId", serverEntity.id)
		end
	end
end

return updateEntityIdAttributes
