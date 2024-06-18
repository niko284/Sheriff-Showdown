local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Util = ReplicatedStorage.utils

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)
local MatterReplication = require(Packages.MatterReplication)
local Remotes = require(ReplicatedStorage.network.Remotes)
local UUIDSerde = require(Util.UUIDSerde)

local CombatNamespace = Remotes.Client:GetNamespace("Combat")
local ProcessAction = CombatNamespace:Get("ProcessAction")

local function bulletsCollide(world: Matter.World)
	for eid, _bullet, collided in world:query(Components.Bullet, Components.Collided) do
		local raycastResult = collided.raycastResult
		if raycastResult then
			local hit = raycastResult.Instance
			local target = hit:FindFirstAncestorWhichIsA("Model")
			local identifier = world:get(eid, Components.Identifier) :: Components.Identifier?

			local owner = world:get(eid, Components.Owner) :: Components.Owner?
			-- don't send a BulletHit action if we're not the client who shot the bullet

			local myTarget = Players.LocalPlayer.Character

			if
				target
				and target:GetAttribute("serverEntityId")
				and myTarget:GetAttribute("serverEntityId")
				and identifier
				and owner
				and owner.OwnedBy == Players.LocalPlayer
			then
				local targetEntityId = target:GetAttribute("serverEntityId")
				local myEntityId = myTarget:GetAttribute("serverEntityId")

				local targetClientEntityId = MatterReplication.resolveServerId(world, targetEntityId)

				local targetTeam = world:get(targetClientEntityId, Components.Team) :: Components.Team?
				local myTeam =
					world:get(MatterReplication.resolveServerId(world, myEntityId), Components.Team) :: Components.Team?

				local targetComponent = world:get(targetClientEntityId, Components.Target)

				if targetComponent and targetComponent.CanTarget == false then
					return
				end

				if myTeam and targetTeam and myTeam.name == targetTeam.name then
					-- don't friendly fire
					return
				end

				-- if our bullet hit a target, let's tell the server about it.
				ProcessAction:SendToServer({
					action = "BulletHit",
					actionId = UUIDSerde.Serialize(identifier.uuid),
					targetEntityId = target:GetAttribute("serverEntityId"),
					hitPart = hit,
				})
			end
		end
		world:despawn(eid)
	end
end

return bulletsCollide
