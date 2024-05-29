local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

type TargetRecord = MatterTypes.WorldChangeRecord<Components.Target>

local function resolveGunId(world: Matter.World, ownedBy: Instance)
	for eid, _gunComponent: Components.Gun, owner: Components.Owner in world:query(Components.Gun, Components.Owner) do
		if owner and owner.OwnedBy == ownedBy then
			return eid
		end
	end
	return nil
end

-- when targets despawn, guns owned by them should despawn too.
local function gunsDespawn(world: Matter.World)
	for eid, _target, _despawning in world:query(Components.Target, Components.Despawn) do
		local playerComponent: Components.PlayerComponent? = world:get(eid, Components.Player)
		if playerComponent then
			local gunId = resolveGunId(world, playerComponent.player)
			if gunId then
				world:insert(gunId, Components.Despawn())
			end
		end
	end
end

return gunsDespawn
