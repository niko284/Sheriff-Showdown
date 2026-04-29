--!strict

local Players = game:GetService("Players")

local jecs = require("@packages/jecs")

local BlinkClient = require("@client/modules/BlinkClient")
local Components = require("@ecs/components")
local LocalComponents = require("@ecs/localComponents")
local UUIDSerde = require("@utilities/UUIDSerde")
local Util = require("@ecs/Util")

type State = {
	replecsClient: any,
}

local function concealProjectile(world: jecs.World, eid: jecs.Entity)
	local renderable = world:get(eid, Components.Renderable)
	if renderable then
		renderable.instance:Destroy()
		world:remove(eid, Components.Renderable)
	end

	if world:has(eid, Components.Velocity) then
		world:remove(eid, Components.Velocity)
	end

	world:add(eid, LocalComponents.ProjectileHidden)
	world:remove(eid, Components.Collided)
end

local function projectilesCollide(world: jecs.World, state: State)
	local replecsClient = state.replecsClient

	for eid, projectile, collided in world:query(Components.Projectile, Components.Collided) do
		local raycastResult = collided.raycastResult
		if not raycastResult then
			concealProjectile(world, eid)
			continue
		end

		local hit = raycastResult.Instance
		local target = hit:FindFirstAncestorWhichIsA("Model")
		local identifier = world:get(eid, Components.Identifier)
		local ownerPlayer = Util.GetOwnerPlayer(world, eid)
		local myChar = Players.LocalPlayer.Character

		if myChar and identifier and ownerPlayer == Players.LocalPlayer then
			local voxelEntityId = hit:GetAttribute("voxelEntityId")
				or (hit.Parent and hit.Parent:GetAttribute("voxelEntityId"))
			if voxelEntityId then
				local clientGunId = projectile.gunId
					and replecsClient
					and replecsClient:get_client_entity(projectile.gunId)
				local gun = clientGunId and world:get(clientGunId, Components.Gun)
				local canDestroy = gun and gun.VoxelDestructionRadius and gun.VoxelDestructionRadius > 0

				if canDestroy then
					BlinkClient.ProcessAction.Fire({
						action = "VoxelHit",
						actionId = UUIDSerde.Serialize(identifier.uuid),
						targetEntityId = voxelEntityId,
						hitPosition = raycastResult.Position,
					})
				end

				concealProjectile(world, eid)
				continue
			end
		end

		if target and myChar and identifier and ownerPlayer == Players.LocalPlayer then
			local targetServerEid = target:GetAttribute("serverEntityId")
			local myServerEid = myChar:GetAttribute("serverEntityId")

			if targetServerEid and myServerEid then
				local targetClientEid = replecsClient and replecsClient:get_client_entity(targetServerEid)
				local myClientEid = replecsClient and replecsClient:get_client_entity(myServerEid)

				local targetTeam = targetClientEid and world:get(targetClientEid, Components.Team)
				local myTeam = myClientEid and world:get(myClientEid, Components.Team)

				local targetComp = targetClientEid and world:get(targetClientEid, Components.Target)
				local sameTeam = myTeam and targetTeam and myTeam.name == targetTeam.name
				local cannotTarget = targetComp and targetComp.CanTarget == false

				if not (sameTeam or cannotTarget) then
					BlinkClient.ProcessAction.Fire({
						action = "ProjectileHit",
						actionId = UUIDSerde.Serialize(identifier.uuid),
						targetEntityId = targetServerEid,
					})
				end
			end
		end

		concealProjectile(world, eid)
	end
end

return projectilesCollide
