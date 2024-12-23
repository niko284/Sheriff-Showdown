local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.ecs.components)
local EffectUtils = require(ReplicatedStorage.utils.EffectUtils)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)

local function bulletsTravel(world: Matter.World, _state)
	for eid, bullet, velocity: Components.Velocity in world:query(Components.Bullet, Components.Velocity) do
		local serverEntity = world:get(eid, MatterReplication.ServerEntity)
		local owner = world:get(eid, Components.Owner)

		if serverEntity and RunService:IsClient() and owner.OwnedBy == Players.LocalPlayer then
			continue -- we don't simulate bullets that were replicated from the server and are owned by the local player. this was already done by the client.
		end

		local deltaTime = Matter.useDeltaTime()

		local transform: Components.Transform? = world:get(eid, Components.Transform)
		if not transform then
			continue
		end

		local newCFrame =
			CFrame.lookAlong(transform.cframe.Position + velocity.velocity * deltaTime, velocity.velocity.Unit)

		local positionChange = newCFrame.Position - transform.cframe.Position

		-- Check if we hit something. (Client only)
		if RunService:IsClient() then
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = bullet.filter or {}
			local raycastResult = workspace:Raycast(transform.cframe.Position, positionChange, raycastParams)

			if raycastResult then
				local gunItem: Components.Item? =
					world:get(MatterReplication.resolveServerId(world, bullet.gunId :: number), Components.Item)

				local ownerChar = owner.OwnedBy.Character :: Model
				local gunItemInfo = gunItem and ItemUtils.GetItemInfoFromId(gunItem.Id) or nil
				EffectUtils.BulletBeam(ownerChar, raycastResult.Position, gunItem and gunItemInfo.Name or nil)

				world:insert(eid, Components.Collided({ raycastResult = raycastResult }))
			end
		end

		transform = transform:patch({
			cframe = newCFrame,
		})
		world:insert(eid, transform)
	end
end

return {
	system = bulletsTravel,
}
