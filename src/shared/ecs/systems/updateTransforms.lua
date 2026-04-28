--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

-- Per-frame Transform reconciliation for unanchored Models/BaseParts.
-- The Renderable<->Transform observer (in observers/init.lua) handles the
-- ECS->Roblox direction. This system handles the Roblox->ECS direction
-- for objects whose pivot the engine moves (physics, animations).
local function updateTransforms(world: jecs.World)
	for id, renderable, transform in world:query(Components.Renderable, Components.Transform) do
		local instance = renderable.instance

		if instance:IsA("BasePart") then
			if instance.Anchored then
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
