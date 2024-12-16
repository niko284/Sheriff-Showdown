local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)

local useEvent = Matter.useEvent
local Renderable = Components.Renderable

type RenderableRecord = {
	new: Components.Renderable<Instance>?,
	old: Components.Renderable<Instance>?,
}

local function renderablesDestroy(world: Matter.World)
	-- account for the case where a renderable is removed from an entity OR the entity is despawned.
	for eid, renderableRecord: RenderableRecord in world:queryChanged(Renderable) do
		if renderableRecord.new == nil then
			if renderableRecord.old and renderableRecord.old.instance then
				if
					world:contains(eid)
					and RunService:IsClient() == true
					and world:get(eid, MatterReplication.ServerEntity)
				then
					return -- don't destroy the renderable if it's a server entity and we're on the client.
				end
				renderableRecord.old.instance:Destroy()
			end
		end
	end
	-- account for a renderable not being in the DOM.
	for eid, renderable: Components.Renderable<Instance> in world:query(Renderable) do
		for _ in useEvent(renderable.instance, "AncestryChanged") do
			if renderable.instance:IsDescendantOf(game) == false then
				if
					world:contains(eid)
					and RunService:IsClient() == true
					and world:get(eid, MatterReplication.ServerEntity)
				then
					return -- don't destroy the renderable if it's a server entity and we're on the client.
				end

				if world:contains(eid) then -- renderables tagged in our collection bootstrap will also despawn so we need to check if the entity still exists.
					world:remove(eid, Renderable) -- will trigger the first part of this function.
				end
			end
		end
	end
end

return {
	system = renderablesDestroy,
	event = "default",
}
