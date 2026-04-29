--!strict

local jecs = require("@packages/jecs")
local replecs = require("@packages/replecs")

local AudioUtils = require("@utilities/AudioUtils")
local Components = require("@ecs/components")
local Middlewares = require("@ecs/Middlewares")
local Types = require("@constants/Types")
local Util = require("@ecs/Util")
local t = require("@packages/t")

local RELOAD_SOUND_ID = 139717586861911

type ShootPayload = {
	velocity: Vector3,
	origin: CFrame,
	fromGun: number,
	timestamp: number,
} & Types.GenericPayload

local function hashString(value: string): number
	local hash = 2166136261

	for i = 1, #value do
		hash = bit32.bxor(hash, string.byte(value, i))
		hash = (hash * 16777619) % 4294967296
	end

	return hash
end

return {
	process = function(world, player: Player, actionPayload): boolean
		if not world:contains(actionPayload.fromGun) then
			warn("Invalid gun id")
			return false
		end

		local gunOwnerPlayer = Util.GetOwnerPlayer(world, actionPayload.fromGun :: any)
		if gunOwnerPlayer ~= player then
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

		local newGun: Components.Gun = table.clone(gunComponent)
		newGun.CurrentCapacity = newCapacity == 0 and gunComponent.MaxCapacity or newCapacity
		newGun.Reloading = reloading or nil

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

		local timeToJump = math.max(0, latency - interpolationTime)
		local bulletStart = actionPayload.origin.Position + actionPayload.velocity * timeToJump
		local adjustedBulletCFrame = CFrame.new(bulletStart, actionPayload.origin.Position + actionPayload.velocity)

		local ownerEntity = world:target(actionPayload.fromGun :: any, jecs.ChildOf)

		local bulletId = world:entity()
		world:add(bulletId, replecs.networked)
		world:set(bulletId, Components.Projectile, { gunId = actionPayload.fromGun, origin = actionPayload.origin })
		world:add(bulletId, jecs.pair(replecs.reliable, Components.Projectile))
		world:set(bulletId, Components.ProjectilePrediction, { uuid = actionPayload.actionId })
		world:add(bulletId, jecs.pair(replecs.reliable, Components.ProjectilePrediction))
		world:add(bulletId, jecs.pair(replecs.custom, Components.ProjectilePrediction))
		world:set(bulletId, Components.Velocity, { velocity = actionPayload.velocity })
		world:add(bulletId, jecs.pair(replecs.reliable, Components.Velocity))
		world:set(bulletId, Components.Lifetime, {
			expiry = (DateTime.now().UnixTimestampMillis / 1000) + gunComponent.BulletLifeTime,
		})
		world:add(bulletId, jecs.pair(replecs.reliable, Components.Lifetime))
		if ownerEntity then
			world:add(bulletId, jecs.pair(Components.OwnedBy, ownerEntity))
			world:add(bulletId, jecs.pair(replecs.relation, Components.OwnedBy))
		end
		world:set(bulletId, Components.Identifier, { uuid = actionPayload.actionId })
		world:add(bulletId, jecs.pair(replecs.reliable, Components.Identifier))
		world:set(bulletId, Components.Transform, { cframe = adjustedBulletCFrame })
		world:add(bulletId, jecs.pair(replecs.reliable, Components.Transform))

		if gunComponent.VoxelDestructionRadius and gunComponent.VoxelDestructionRadius > 0 then
			world:set(bulletId, Components.DestructionRadius, {
				radius = gunComponent.VoxelDestructionRadius,
				shape = "Sphere",
				falloff = "Linear",
				explosionForce = gunComponent.VoxelExplosionForce or 60,
				debrisLifetime = gunComponent.VoxelDebrisLifetime or 3,
				variance = 0.35,
				roughness = 0.28,
				seed = hashString(actionPayload.actionId),
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
