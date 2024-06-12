local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)

local function bulletsTravel(world: Matter.World, _state)
	for eid, bullet, velocity in world:query(Components.Bullet, Components.Velocity) do
		local serverEntity = world:get(eid, MatterReplication.ServerEntity)
		local owner = world:get(eid, Components.Owner)

		if serverEntity and RunService:IsClient() and owner.OwnedBy == Players.LocalPlayer then
			continue -- we don't simulate bullets that were replicated from the server and are owned by the local player. this was already done by the client.
		end

		local deltaTime = Matter.useDeltaTime()
		local distanceTraveled = velocity.velocity * deltaTime

		local transform = world:get(eid, Components.Transform)

		local newPosition = transform.cframe.Position + distanceTraveled
		local positionChange = newPosition - transform.cframe.Position

		local newCFrame = CFrame.new(newPosition, velocity.velocity.Unit + newPosition)

		transform = transform:patch({
			cframe = newCFrame,
		})
		world:insert(eid, transform)

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
end

return {
	system = bulletsTravel,
}
