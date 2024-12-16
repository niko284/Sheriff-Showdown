--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)
local Types = require(ReplicatedStorage.constants.Types)

local KillEffects = {} :: Types.VisualEffect<KillEffectPayload>

type KillEffectPayload = {
	killerServerEntityId: number,
	killedServerEntityId: number,
}
for _, killEffectModule in script:GetChildren() do
	local killEffect = require(killEffectModule) :: Types.VisualEffect<KillEffectPayload>
	KillEffects[killEffect.name] = killEffect
end

return {
	name = "KillEffect",
	visualize = function(world, payload)
		local clientKillerEntityId = MatterReplication.resolveServerId(world, payload.killerServerEntityId)
		if not clientKillerEntityId then
			warn("KillEffect: killer entity not found")
			return
		end

		local killerGun: Components.Gun? = world:get(clientKillerEntityId, Components.Gun)

		-- if the killer has a gun, propagate this function to the gun's visual effect
		if killerGun then
			local gunItem: Components.Item = world:get(clientKillerEntityId, Components.Item)
			local gunInfo: Types.ItemInfo = ItemUtils.GetItemInfoFromId(gunItem.Id)

			local killEffect = KillEffects[gunInfo.Name]
			if killEffect then
				killEffect.visualize(world, payload)
			end
		end
	end,
} :: Types.VisualEffect<KillEffectPayload>
