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

			if target and target:GetAttribute("ServerEntityId") and identifier then
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
