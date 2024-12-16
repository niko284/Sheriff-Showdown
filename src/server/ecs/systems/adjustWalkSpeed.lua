local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)

local function adjustWalkSpeed(world: Matter.World)
	for _id, walkSpeed, renderable in world:query(Components.WalkSpeed, Components.Renderable) do
		if renderable.instance:FindFirstChildOfClass("Humanoid") then
			renderable.instance.Humanoid.WalkSpeed = walkSpeed.speed
		end
	end
end

return adjustWalkSpeed
