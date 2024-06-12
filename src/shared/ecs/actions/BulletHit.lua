--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Types = require(ReplicatedStorage.constants.Types)
local t = require(ReplicatedStorage.packages.t)

type BulletHitPayload = {
	targetEntityId: number, -- server entity id of the entity that was hit by the bullet
	hitPart: BasePart, -- the part that was hit by the bullet
} & Types.GenericPayload

return {
	process = function(world, player, actionPayload)
		if not world:contains(actionPayload.targetEntityId) then
			warn("Invalid target entity id")
			return
		end

		-- get both the target player's and our own player's team.
		local targetRenderable: Components.Renderable? = world:get(actionPayload.targetEntityId, Components.Renderable)
		local targetTeam: Components.Team? = world:get(actionPayload.targetEntityId, Components.Team)
		local targetComponent: Components.Target? = world:get(actionPayload.targetEntityId, Components.Target)

		if targetComponent == nil or targetComponent.CanTarget == false then
			return
		end

		local attacker = player.Character
		local attackerTeam: Components.Team? = nil

		if attacker then
			local targetEntityId = attacker:GetAttribute("serverEntityId") :: number?
			if targetEntityId then
				attackerTeam = world:get(targetEntityId, Components.Team)
			end
		end

		if targetTeam and attackerTeam and targetTeam.name == attackerTeam.name then
			warn("Target and attacker are on the same team")
			return
		end

		if not targetRenderable then
			warn("Target entity has no renderable component")
			return
		end

		for eid, bullet: Components.Bullet, identifier: Components.Identifier, owner: Components.Owner in
			world:query(Components.Bullet, Components.Identifier, Components.Owner)
		do
			if identifier.uuid == actionPayload.actionId and owner.OwnedBy == player then
				local transform = world:get(eid, Components.Transform)
				world:despawn(eid) -- despawn the bullet that supposedly hit the target
				if targetRenderable.instance == player.Character then
					continue -- don't deal damage to ourselves.
				end

				local gun: Components.Gun? = world:get(bullet.gunId, Components.Gun)
				if not gun then
					continue
				end -- the gun that shot this bullet no longer exists

				if not actionPayload.hitPart:IsDescendantOf(targetRenderable.instance) then
					continue -- the hit part is not a descendant of the target entity
				end

				local hitCFrame = actionPayload.hitPart:GetPivot()

				local bulletFilter = { player.Character :: Instance?, unpack(CollectionService:GetTagged("Barrier")) }
				-- make sure that nothing is blocking the bullet's path (to prevent shooting through walls)
				local dir = (hitCFrame.Position - bullet.origin.Position)
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = bulletFilter :: { Instance }
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				local raycast = workspace:Raycast(bullet.origin.Position, dir, rayParams)
				if raycast and raycast.Instance:IsDescendantOf(targetRenderable.instance) == false then
					continue -- the bullet hit something else, not the target
				end

				-- check if the position between the server-projected bullet and the target hit is close enough.
				local diff = (hitCFrame.Position - transform.cframe.Position).Magnitude
				print(`Diff between bullet and target: ${diff}`)
				if diff > 5 then
					--continue
				end

				local slowed = world:get(actionPayload.targetEntityId, Components.Slowed)
				if slowed then -- if already slowed, slow down even more by half of the current multiplier
					world:insert(
						actionPayload.targetEntityId,
						slowed:patch({ walkspeedMultiplier = slowed.walkspeedMultiplier * 0.5 })
					)
				else
					world:insert(actionPayload.targetEntityId, Components.Slowed({ walkspeedMultiplier = 0.8 }))
				end

				-- deal damage to the target
				local health = world:get(actionPayload.targetEntityId, Components.Health)
				if health then
					local damage = gun.CriticalDamage[actionPayload.hitPart.Name] or gun.Damage

					local myChar = player.Character
					if not myChar then
						warn("Player has no character")
						return
					end

					local myEntityId = myChar:GetAttribute("serverEntityId")

					local newHealth = health.health - damage
					world:insert(
						actionPayload.targetEntityId,
						health:patch({ health = newHealth, causedBy = bullet.gunId })
					)
				end
			end
		end
	end,
	validatePayload = function()
		return t.strictInterface({
			targetEntityId = t.number,
			hitPart = t.instanceIsA("PVInstance"),
			action = t.literal("BulletHit"),
			actionId = t.string,
		})
	end,
} :: Types.Action<BulletHitPayload>
