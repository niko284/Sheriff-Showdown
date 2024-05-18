--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

local Transform = Components.Transform
local Renderable = Components.Renderable

type TransformRecord = MatterTypes.WorldChangeRecord<Components.Transform>
type RenderableRecord = MatterTypes.WorldChangeRecord<Components.Renderable>

local function updateTransforms(world: Matter.World)
	-- Handle Transform added/changed to existing entity with Model
	for id, transformRecord: TransformRecord in world:queryChanged(Transform) do
		if transformRecord.new then
			local renderable = world:get(id, Renderable) :: Components.Renderable?

			-- Take care to ignore the changed event if it was us that triggered it
			if renderable and not transformRecord.new.doNotReconcile then
				local instance = renderable.instance :: PVInstance
				instance:PivotTo(transformRecord.new.cframe)
			end
		end
	end

	-- Handle Renderable added/changed on existing entity with Transform
	for id, renderableRecord: RenderableRecord in world:queryChanged(Renderable) do
		if renderableRecord.new then
			local transform = world:get(id, Transform) :: Components.Transform?

			if transform then
				local instance = renderableRecord.new.instance :: PVInstance
				instance:PivotTo(transform.cframe)
			end
		end
	end

	-- Update Transform on unanchored Models
	for id, renderable: Components.Renderable, transform: Components.Transform in world:query(Renderable, Transform) do
		local instance = renderable.instance :: PVInstance

		if instance:IsA("BasePart") then
			if instance.Anchored then
				continue
			end
		elseif instance:IsA("Model") then
			if instance.PrimaryPart and instance.PrimaryPart.Anchored then
				continue
			end
		end

		local existingCFrame = transform.cframe
		local currentCFrame = instance:IsA("Model") and instance:GetPivot()
			or (instance:IsA("BasePart") and instance.CFrame)
			or error("Unsupported instance type")

		-- Only insert if actual position is different from the Transform component
		if currentCFrame ~= existingCFrame then
			world:insert(
				id,
				Transform({
					cframe = currentCFrame,
					doNotReconcile = true,
				})
			)
		end
	end
end

return updateTransforms
