--!strict

local Components = require("@ecs/components")
local ItemUtils = require("@utilities/ItemUtils")
local Types = require("@constants/Types")

local KillEffects = {} :: Types.VisualEffect<KillEffectPayload>

type KillEffectPayload = {
	killerServerEntityId: number,
	killedServerEntityId: number,
	replecsClient: any,
}
for _, killEffectModule in script:GetChildren() do
	local killEffect = require(killEffectModule) :: Types.VisualEffect<KillEffectPayload>
	KillEffects[killEffect.name] = killEffect
end

return {
	name = "KillEffect",
	visualize = function(world, payload)
		local clientKillerEntityId = payload.replecsClient
			and payload.replecsClient:get_client_entity(payload.killerServerEntityId)
		if not clientKillerEntityId then
			warn("KillEffect: killer entity not found")
			return
		end

		local killerGun: Components.Gun? = world:get(clientKillerEntityId, Components.Gun)

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
