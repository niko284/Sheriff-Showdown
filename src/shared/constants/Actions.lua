--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local t = require(ReplicatedStorage.packages.t)

type GenericPayload = {
	action: string,
}
type ShootPayload = {
	velocity: Vector3,
	origin: CFrame,
	fromGun: number, -- server entity id of the gun that supposedly shot this bullet
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
		world:spawn(
			Components.Bullet({ origin = actionPayload.origin }),
			Components.Velocity({ velocity = actionPayload.velocity }),
			Components.Lifetime({ expiry = os.time() + gunComponent.BulletLifeTime })
		)

		return true
	end, function()
		return t.interface({
			velocity = t.Vector3,
			origin = t.CFrame,
		})
	end),
} :: { [string]: Action<any> }
