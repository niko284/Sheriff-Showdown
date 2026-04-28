--!strict

local Players = game:GetService("Players")

local jecs = require("@packages/jecs")

local BlinkClient = require("@client/modules/BlinkClient")
local Components = require("@ecs/components")
local UUIDSerde = require("@utilities/UUIDSerde")

type State = {
	replecsClient: any,
}

local function projectilesCollide(world: jecs.World, state: State)
	local replecsClient = state.replecsClient

	for eid, _projectile, collided in world:query(Components.Projectile, Components.Collided) do
		local raycastResult = collided.raycastResult
		if raycastResult then
			local hit = raycastResult.Instance
			local target = hit:FindFirstAncestorWhichIsA("Model")
			local identifier = world:get(eid, Components.Identifier)
			local owner = world:get(eid, Components.Owner)

			local myChar = Players.LocalPlayer.Character

			if target and myChar and identifier and owner and owner.OwnedBy == Players.LocalPlayer then
				-- Voxel hit: part has a voxelEntityId attribute
				local voxelEntityId = hit:GetAttribute("voxelEntityId")
					or (hit.Parent and hit.Parent:GetAttribute("voxelEntityId"))
				if voxelEntityId then
					BlinkClient.ProcessAction.Fire({
						action = "VoxelHit",
						actionId = UUIDSerde.Serialize(identifier.uuid),
						targetEntityId = voxelEntityId,
						hitPosition = raycastResult.Position,
					})
					world:delete(eid)
					continue
				end

				local targetServerEid = target:GetAttribute("serverEntityId")
				local myServerEid = myChar:GetAttribute("serverEntityId")

				if targetServerEid and myServerEid then
					local targetClientEid = replecsClient and replecsClient:get_client_entity(targetServerEid)
					local myClientEid = replecsClient and replecsClient:get_client_entity(myServerEid)

					local targetTeam = targetClientEid and world:get(targetClientEid, Components.Team)
					local myTeam = myClientEid and world:get(myClientEid, Components.Team)

					local targetComp = targetClientEid and world:get(targetClientEid, Components.Target)
					if targetComp and targetComp.CanTarget == false then
						world:delete(eid)
						continue
					end

					if myTeam and targetTeam and myTeam.name == targetTeam.name then
						world:delete(eid)
						continue
					end

					BlinkClient.ProcessAction.Fire({
						action = "ProjectileHit",
						actionId = UUIDSerde.Serialize(identifier.uuid),
						targetEntityId = targetServerEid,
					})
				end
			end
		end
		world:delete(eid)
	end
end

return projectilesCollide
