--!strict

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local AudioUtils = require("@utilities/AudioUtils")
local Components = require("@ecs/components")
local StatusEffect = require("@ecs/StatusEffect")
local Types = require("@constants/Types")
local Util = require("@ecs/Util")
local t = require("@packages/t")

local PROJECTILE_HIT_SOUND_ID = 3581383408

type ProjectileHitPayload = {
	targetEntityId: number,
} & Types.GenericPayload

return {
	process = function(world, player, actionPayload)
		if not world:contains(actionPayload.targetEntityId) then
			warn("Invalid target entity id")
			return
		end

		local targetRenderable: Components.Renderable? =
			world:get(actionPayload.targetEntityId, Components.Renderable)
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

		for eid, projectile: Components.Projectile, identifier: Components.Identifier in
			world:query(Components.Projectile, Components.Identifier)
		do
			if identifier.uuid == actionPayload.actionId and Util.GetOwnerPlayer(world, eid) == player then
				local transform = world:get(eid, Components.Transform)
				world:delete(eid)

				if targetRenderable.instance == player.Character then
					continue
				end

				local targetRootPart = targetRenderable.instance:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not targetRootPart then
					continue
				end

				local gun: Components.Gun? = world:get(projectile.gunId, Components.Gun)
				if not gun then
					continue
				end

				local bulletFilter =
					{ player.Character :: Instance?, table.unpack(CollectionService:GetTagged("Barrier")) }
				local dir = targetRootPart.Position - projectile.origin.Position
				if
					not Util.IsLineOfSightClear(
						world,
						projectile.origin.Position,
						dir,
						targetRenderable.instance,
						bulletFilter :: { Instance }
					)
				then
					continue
				end

				if transform then
					local diff = (targetRootPart.Position - transform.cframe.Position).Magnitude
					if diff > 15 then
						continue
					end
				end

				StatusEffect.slow(world, actionPayload.targetEntityId)

				local health = world:get(actionPayload.targetEntityId, Components.Health)
				if health then
					world:set(actionPayload.targetEntityId, Components.Health, {
						health = health.health - gun.Damage,
						maxHealth = health.maxHealth,
						regenRate = health.regenRate,
						causedBy = projectile.gunId,
					})
				end

				local highlight = Instance.new("Highlight")
				highlight.Enabled = true
				highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				highlight.Adornee = targetRenderable.instance
				highlight.FillTransparency = 1
				highlight.OutlineTransparency = 1
				highlight.Parent = targetRenderable.instance

				AudioUtils.PlaySoundOnInstance(PROJECTILE_HIT_SOUND_ID, targetRootPart)

				local highlightId = world:entity()
				world:set(highlightId, Components.Renderable, { instance = highlight })
				world:set(
					highlightId,
					Components.Lifetime,
					{ expiry = (DateTime.now().UnixTimestampMillis / 1000) + 0.3 }
				)

				local initTween = TweenService:Create(highlight, TweenInfo.new(0.1), { FillTransparency = 0.5 })
				initTween:Play()
				initTween.Completed:Once(function()
					TweenService:Create(highlight, TweenInfo.new(0.1), { FillTransparency = 1 }):Play()
				end)
			end
		end
	end,
	validatePayload = t.strictInterface({
		targetEntityId = t.number,
		action = t.literal("ProjectileHit"),
		actionId = t.string,
	}),
	afterProcess = {},
} :: Types.Action<ProjectileHitPayload>
