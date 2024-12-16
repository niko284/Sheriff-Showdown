--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Middlewares = require(ReplicatedStorage.ecs.Middlewares)
local Types = require(ReplicatedStorage.constants.Types)
local t = require(ReplicatedStorage.packages.t)

type ShootPayload = {
	velocity: Vector3,
	origin: CFrame,
	fromGun: number, -- server entity id of the gun that supposedly shot this bullet
	timestamp: number, -- time the action was sent by the client
	spawnedBullet: number, -- server entity id of the bullet that was spawned
} & Types.GenericPayload

return {
	process = function(world, player: Player, actionPayload): boolean
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

		if gunComponent.Disabled == true then
			warn("Gun is disabled")
			return false
		end

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
		local interpolationTime = (player:GetNetworkPing() / 2) + 0.048

		-- Validate the latency and avoid players with very slow connections
		if (latency < 0) or (latency > 0.8) then -- 800ms is the maximum latency we allow
			warn(`Invalid latency: ${latency}`)
			return false
		end
		local timeLaunched = workspace:GetServerTimeNow() - latency - interpolationTime
		local timeToJump = timeLaunched - actionPayload.timestamp

		-- Calculate the new starting position of the bullet
		local bulletStart = actionPayload.origin.Position + actionPayload.velocity * timeToJump
		local adjustedBulletCFrame = CFrame.new(bulletStart, actionPayload.origin.LookVector)

		actionPayload.spawnedBullet = world:spawn(
			Components.Bullet({
				gunId = actionPayload.fromGun,
				origin = actionPayload.origin,
			}),
			Components.Velocity({ velocity = actionPayload.velocity }),
			Components.Lifetime({ expiry = os.time() + gunComponent.BulletLifeTime }),
			Components.Owner({ OwnedBy = player }),
			Components.Identifier({ uuid = actionPayload.actionId }),
			Components.Transform({ cframe = adjustedBulletCFrame })
		)

		return true
	end,
	validatePayload = t.strictInterface({ -- generic action payload combined with specific action payload
		action = t.literal("Shoot"),
		actionId = t.string,
		velocity = t.Vector3,
		timestamp = t.numberPositive,
		origin = t.CFrame,
		fromGun = t.numberPositive,
	}),
	middleware = {
		Middlewares.DoesNotHaveComponents({
			Components.Killed,
		}),
	},
	afterProcess = {},
} :: Types.Action<ShootPayload>
