local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Util = ReplicatedStorage.utils

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)
local Remotes = require(ReplicatedStorage.Remotes)
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
			if
				target
				and target:GetAttribute("ServerEntityId")
				and identifier
				and owner
				and owner.OwnedBy == Players.LocalPlayer
			then
				-- if our bullet hit a target, let's tell the server about it.
				ProcessAction:SendToServer({
					action = "BulletHit",
					actionId = UUIDSerde.Serialize(identifier.uuid),
					targetEntityId = target:GetAttribute("ServerEntityId"),
					hitPart = hit,
				})
			end
		end
		world:despawn(eid)
	end
end

return bulletsCollide
