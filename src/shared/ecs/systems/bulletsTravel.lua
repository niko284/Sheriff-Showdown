local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)

local function bulletsTravel(world: Matter.World, _state)
	for eid, bullet, velocity in world:query(Components.Bullet, Components.Velocity) do
		local deltaTime = Matter.useDeltaTime()
		local distanceTraveled = velocity.velocity * deltaTime

		local transform = world:get(eid, Components.Transform)

		local newPosition = bullet.currentCFrame.Position + distanceTraveled
		local positionChange = newPosition - bullet.currentCFrame.Position

		local newCFrame = CFrame.new(newPosition, bullet.currentCFrame:VectorToWorldSpace(Vector3.new(0, 0, 1)))

		if transform then
			transform = transform:patch({
				cframe = newCFrame,
			})
			world:insert(eid, transform)
		end

		bullet = bullet:patch({ currentCFrame = newCFrame })
		world:insert(eid, bullet)

		-- Check if we hit something. (Client only)
		if RunService:IsClient() then
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = bullet.filter or {}
			local raycastResult = workspace:Raycast(transform.cframe.Position, positionChange, raycastParams)

			if raycastResult then
				world:insert(eid, Components.Collided({ raycastResult = raycastResult }))
			end
		end
	end

	-- Remove bullets that have a lifetime component and have expired.
	for eid, _bullet, lifetime in world:query(Components.Bullet, Components.Lifetime) do
		if os.time() >= lifetime.expiry then
			world:despawn(eid) -- Remove the bullet from the world.
		end
	end
end

return {
	system = bulletsTravel,
}
