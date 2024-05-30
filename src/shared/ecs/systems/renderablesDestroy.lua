local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)

local useEvent = Matter.useEvent
local Renderable = Components.Renderable

type RenderableRecord = {
	new: Components.Renderable?,
	old: Components.Renderable?,
}

local function renderablesDestroy(world: Matter.World)
	-- account for the case where a renderable is removed from an entity OR the entity is despawned.
	for _eid, renderableRecord: RenderableRecord in world:queryChanged(Renderable) do
		if renderableRecord.new == nil then
			if renderableRecord.old and renderableRecord.old.instance then
				renderableRecord.old.instance:Destroy()
			end
		end
	end
	-- account for a renderable not being in the DOM.
	for eid, renderable: Components.Renderable in world:query(Renderable) do
		for _ in useEvent(renderable.instance, "AncestryChanged") do
			if renderable.instance:IsDescendantOf(game) == false then
				world:remove(eid, Renderable) -- will trigger the first part of this function.
			end
		end
	end
end

return {
	system = renderablesDestroy,
	event = "default",
}
