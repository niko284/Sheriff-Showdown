local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)
local MatterReplication = require(Packages.MatterReplication)
local Remotes = require(ReplicatedStorage.Remotes)

local CombatNamespace = Remotes.Client:GetNamespace("Combat")
local ProcessHit = CombatNamespace:Get("ProcessHit")

local function bulletsCollide(world: Matter.World)
	for eid, _bullet, collided in world:query(Components.Bullet, Components.Collided) do
		local raycastResult = collided.raycastResult
		if raycastResult then
			local hit = raycastResult.Instance
			local target = hit:FindFirstChildWhichIsA("Model")
			if target and target:GetAttribute("ServerEntityId") then
				-- if our bullet hit a target, let's tell the server about it.
				ProcessHit:SendToServer({
					action = "BulletHitTarget",
					targetEntityId = target:GetAttribute("ServerEntityId"),
					bulletEntityId = eid,
				})
			end
		end
		world:despawn(eid)
	end
end

return bulletsCollide
