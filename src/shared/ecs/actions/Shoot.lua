--!strict

local AudioUtils = require("@utilities/AudioUtils")
local Components = require("@ecs/components")
local Middlewares = require("@ecs/Middlewares")
local Types = require("@constants/Types")
local t = require("@packages/t")

local RELOAD_SOUND_ID = 139717586861911

type ShootPayload = {
	velocity: Vector3,
	origin: CFrame,
	fromGun: number,
	timestamp: number,
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

		local character = player.Character :: Model
		local characterRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		local rightHand = character:FindFirstChild("RightHand") :: Part
		if not rightHand then
			warn("RightHand not found")
			return false
		end

		local origin = actionPayload.origin.Position
		local diff = (origin - rightHand.Position).Magnitude
		if diff > 15 then
			warn("Origin is too far from the right hand: " .. diff)
			return false
		end

		local newCapacity = gunComponent.CurrentCapacity - 1
		local timeNow = DateTime.now()
		local cooldownMillis = newCapacity == 0 and gunComponent.ReloadTimeMillis or gunComponent.LocalCooldownMillis

		local reloading = cooldownMillis == gunComponent.ReloadTimeMillis
		local wasReloading = gunComponent.Reloading

		world:set(actionPayload.fromGun, Components.Cooldown, { expiry = timeNow.UnixTimestampMillis + cooldownMillis })

		local newGun: Components.Gun = {
			LocalCooldownMillis = gunComponent.LocalCooldownMillis,
			ReloadTimeMillis = gunComponent.ReloadTimeMillis,
			Damage = gunComponent.Damage,
			CriticalDamage = gunComponent.CriticalDamage,
			BulletLifeTime = gunComponent.BulletLifeTime,
			MaxCapacity = gunComponent.MaxCapacity,
			ReloadTime = gunComponent.ReloadTime,
			CurrentCapacity = newCapacity == 0 and gunComponent.MaxCapacity or newCapacity,
			BulletSpeed = gunComponent.BulletSpeed,
			BulletSoundId = gunComponent.BulletSoundId,
			KnockStrength = gunComponent.KnockStrength,
			Disabled = gunComponent.Disabled,
			Reloading = reloading or nil,
		}

		if reloading and not wasReloading then
			AudioUtils.PlaySoundOnInstance(RELOAD_SOUND_ID, characterRootPart)
		end

		world:set(actionPayload.fromGun, Components.Gun, newGun)

		local latency = workspace:GetServerTimeNow() - actionPayload.timestamp
		local interpolationTime = (player:GetNetworkPing() / 2) + 0.048

		if (latency < 0) or (latency > 0.8) then
			warn(`Invalid latency: {latency}`)
			return false
		end
		local timeLaunched = workspace:GetServerTimeNow() - latency - interpolationTime
		local timeToJump = timeLaunched - actionPayload.timestamp

		local bulletStart = actionPayload.origin.Position + actionPayload.velocity * timeToJump
		local adjustedBulletCFrame = CFrame.new(bulletStart, actionPayload.origin.LookVector)

		local bulletId = world:entity()
		world:set(bulletId, Components.Projectile, { gunId = actionPayload.fromGun, origin = actionPayload.origin })
		world:set(bulletId, Components.Velocity, { velocity = actionPayload.velocity })
		world:set(bulletId, Components.Lifetime, {
			expiry = (DateTime.now().UnixTimestampMillis / 1000) + gunComponent.BulletLifeTime,
		})
		world:set(bulletId, Components.Owner, { OwnedBy = player })
		world:set(bulletId, Components.Identifier, { uuid = actionPayload.actionId })
		world:set(bulletId, Components.Transform, { cframe = adjustedBulletCFrame })

		if gunComponent.VoxelDestructionRadius and gunComponent.VoxelDestructionRadius > 0 then
			world:set(bulletId, Components.DestructionRadius, {
				radius = gunComponent.VoxelDestructionRadius,
				shape = "Sphere",
				falloff = "Linear",
				explosionForce = gunComponent.VoxelExplosionForce or 60,
				debrisLifetime = gunComponent.VoxelDebrisLifetime or 3,
			})
		end

		return true
	end,
	validatePayload = t.strictInterface({
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
