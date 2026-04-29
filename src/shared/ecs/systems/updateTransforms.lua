--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local function updateTransforms(world: jecs.World)
	for id, renderable, transform in world:query(Components.Renderable, Components.Transform) do
		local instance = renderable.instance

		if instance:IsA("BasePart") then
			if instance.Anchored then
				continue
			end
			-- Welded into a falling voxel section: Roblox's built-in physics
			-- replication handles the whole assembly's pose; replicating via
			-- our Transform component would PivotTo on the client each tick,
			-- breaking the welds and snapping the assembly back to spawn.
			if instance:GetAttribute("voxelSectionMember") then
				continue
			end
		elseif instance:IsA("Model") then
			if instance.PrimaryPart and instance.PrimaryPart.Anchored then
				continue
			end
		end

		local currentCFrame: CFrame
		if instance:IsA("Model") then
			currentCFrame = instance:GetPivot()
		elseif instance:IsA("BasePart") then
			currentCFrame = instance.CFrame
		else
			continue
		end

		if currentCFrame ~= transform.cframe then
			world:set(id, Components.Transform, {
				cframe = currentCFrame,
				doNotReconcile = true,
			})
		end
	end
end

return updateTransforms
