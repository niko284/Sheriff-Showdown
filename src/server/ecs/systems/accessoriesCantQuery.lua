local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

local useEvent = Matter.useEvent

type RenderableRecord = MatterTypes.WorldChangeRecord<Components.Renderable<Model>>
type TargetRecord = MatterTypes.WorldChangeRecord<Components.Target>

local function disableQueryingForAccessories(instance: Instance)
	for _, accessory in instance:GetChildren() do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChild("Handle") :: BasePart?
			if handle then
				handle.CanQuery = false
			end
		end
	end
end

local function accessoriesCantQuery(world: Matter.World)
	-- handle accessories that were added to new renderables
	for eid, renderableRecord: RenderableRecord in world:queryChanged(Components.Renderable) do
		if renderableRecord.new then
			local isTarget = world:get(eid, Components.Target)
			if isTarget then
				disableQueryingForAccessories(renderableRecord.new.instance)
			end
		end
	end

	-- handle accessories for renderables that just became targets
	for eid, targetRecord: TargetRecord in world:queryChanged(Components.Target) do
		if targetRecord.new then
			local renderable = world:get(eid, Components.Renderable)
			if renderable then
				disableQueryingForAccessories(renderable.instance)
			end
		end
	end

	-- handle accessories that were added to existing renderables
	for _, renderable in world:query(Components.Renderable, Components.Target) do
		for _, child in useEvent(renderable.instance, "ChildAdded") do
			if child:IsA("Accessory") then
				local handle = child:FindFirstChild("Handle") :: BasePart?
				if handle then
					handle.CanQuery = false
				end
			end
		end
	end
end

return accessoriesCantQuery
