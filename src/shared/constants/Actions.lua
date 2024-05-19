--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local t = require(ReplicatedStorage.packages.t)

type GenericPayload = {
	action: string,
	actionId: string,
}
type ShootPayload = {
	velocity: Vector3,
	origin: CFrame,
	fromGun: number, -- server entity id of the gun that supposedly shot this bullet
	timestamp: number, -- time the action was sent by the client
} & GenericPayload
type BulletHitPayload = {
	targetEntityId: number, -- server entity id of the entity that was hit by the bullet
	hitPart: BasePart, -- the part that was hit by the bullet
} & GenericPayload

export type Action<T> = {
	process: (world: Matter.World, player: Player, actionPayload: T) -> (),
	validatePayload: (sentPayload: any) -> boolean,
}

local function actionGenerator<T>(
	action: string,
	process: (world: Matter.World, player: Player, actionPayload: T) -> (),
	validatePayload: (sentPayload: any) -> boolean
): Action<T>
	return {
		process = process,
		validatePayload = t.intersection(
			validatePayload,
			t.interface({ -- generic action payload combined with specific action payload
				action = t.literal(action),
				actionId = t.string,
			})
		),
	}
end

return {
	Shoot = actionGenerator("Shoot", function(world, player, actionPayload: ShootPayload): boolean
		if not world:contains(actionPayload.fromGun) then
			warn("Invalid gun id")
			return false
		end

		local gunOwner = world:get(actionPayload.fromGun, Components.Owner) :: Components.Owner
		if not gunOwner then
			warn("No owner found for given gun entity id")
			return false
		end

		if gunOwner.OwnedBy ~= player then
			warn("Player does not own the gun")
			return false
		end

		local cooldown = world:get(actionPayload.fromGun, Components.Cooldown) :: Components.Cooldown?
		if cooldown then
			warn("Gun is on cooldown")
			return false
		end

		local gunComponent = world:get(actionPayload.fromGun, Components.Gun) :: Components.Gun

		-- Verify that the origin is close to the player's right hand
		local character = player.Character :: Model
		local rightHand = character:FindFirstChild("RightHand") :: Part
		if not rightHand then
			warn("RightHand not found")
			return false
		end

		local origin = actionPayload.origin.Position
		local diff = (origin - rightHand.Position).Magnitude
		if diff > 5 then -- we can adjust this value if we want to be more lenient to high latency players
			warn("Origin is too far from the right hand: " .. diff)
			return false
		end

		local timeNow = DateTime.now()
		world:insert(
			actionPayload.fromGun,
			Components.Cooldown({ expiry = timeNow.UnixTimestampMillis + gunComponent.LocalCooldownMillis })
		)

		-- we're not actually spawning a bullet here, we're just making the server also aware of the bullet that was shot.
		-- the actual bullet is spawned on the client side.

		local latency = workspace:GetServerTimeNow() - actionPayload.timestamp -- the time it took for the server to receive the action from the client
		local interpolationTime = player:GetNetworkPing() + 0.048

		print(latency, interpolationTime)

		-- Validate the latency and avoid players with very slow connections
		if (latency < 0) or (latency > 0.8) then -- 800ms is the maximum latency we allow
			warn(`Invalid latency: ${latency}`)
			return false
		end
		local timeToJump = latency + interpolationTime
		print(timeToJump)

		-- Calculate the new starting position of the bullet
		local bulletStart = actionPayload.origin.Position + actionPayload.velocity * timeToJump
		local adjustedBulletCFrame =
			CFrame.new(bulletStart, actionPayload.origin:VectorToWorldSpace(Vector3.new(0, 0, 1)))

		world:spawn(
			Components.Bullet({
				currentCFrame = adjustedBulletCFrame,
				gunId = actionPayload.fromGun,
				origin = actionPayload.origin,
			}),
			Components.Velocity({ velocity = actionPayload.velocity }),
			Components.Lifetime({ expiry = os.time() + gunComponent.BulletLifeTime }),
			Components.Owner({ OwnedBy = player }),
			Components.Identifier({ uuid = actionPayload.actionId })
		)

		return true
	end, function()
		return t.interface({
			velocity = t.Vector3,
			timestamp = t.numberPositive,
			origin = t.CFrame,
		})
	end),
	BulletHit = actionGenerator("BulletHit", function(world, player, actionPayload: BulletHitPayload)
		if not world:contains(actionPayload.targetEntityId) then
			warn("Invalid target entity id")
			return
		end

		local targetRenderable = world:get(actionPayload.targetEntityId, Components.Renderable)
		if not targetRenderable then
			warn("Target entity has no renderable component")
			return
		end

		for eid, bullet: Components.Bullet, identifier: Components.Identifier, owner: Components.Owner in
			world:query(Components.Bullet, Components.Identifier, Components.Owner)
		do
			if identifier.uuid == actionPayload.actionId and owner.OwnedBy == player then
				world:despawn(eid) -- despawn the bullet that supposedly hit the target
				if targetRenderable.instance == player.Character then
					continue -- don't deal damage to ourselves.
				end

				local gun = world:get(bullet.gunId, Components.Gun) :: Components.Gun?
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
				local diff = (hitCFrame.Position - bullet.currentCFrame.Position).Magnitude
				print(`Diff between bullet and target: ${diff}`)
				if diff > 5 then
					continue
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
					local newHealth = health.health - gun.Damage
					world:insert(actionPayload.targetEntityId, health:patch({ health = newHealth }))
				end
			end
		end
	end, function()
		return t.interface({
			targetEntityId = t.number,
			hitPart = t.instanceIsA("PVInstance"),
		})
	end),
} :: { [string]: Action<any> }
