--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local function adjustWalkSpeed(world: jecs.World)
	for _id, walkSpeed, renderable in world:query(Components.WalkSpeed, Components.Renderable) do
		local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = walkSpeed.speed
		end
	end
end

return adjustWalkSpeed
