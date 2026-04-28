local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local EffectUtils = require("@utilities/EffectUtils")
local ItemUtils = require("@utilities/ItemUtils")

type State = {
	scheduler: any,
	replecsClient: any?,
}

local function projectilesTravel(world: jecs.World, state: State)
	local deltaTime = state.scheduler:getDeltaTime()
	local replecsClient = state.replecsClient
	local isClient = RunService:IsClient()

	for eid, projectile, velocity in world:query(Components.Projectile, Components.Velocity) do
		local owner = world:get(eid, Components.Owner)

		if isClient and replecsClient and owner and owner.OwnedBy == Players.LocalPlayer then
			if replecsClient:get_server_entity(eid) ~= nil then
				continue
			end
		end

		local transform = world:get(eid, Components.Transform)
		if not transform then
			continue
		end

		local newCFrame =
			CFrame.lookAlong(transform.cframe.Position + velocity.velocity * deltaTime, velocity.velocity.Unit)
		local positionChange = newCFrame.Position - transform.cframe.Position

		if isClient then
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = projectile.filter or {}
			local raycastResult = workspace:Raycast(transform.cframe.Position, positionChange, raycastParams)

			if raycastResult then
				local gunEid = projectile.gunId
				if gunEid and replecsClient then
					local clientGunEid = replecsClient:get_client_entity(gunEid)
					if clientGunEid then
						gunEid = clientGunEid
					end
				end

				local gunItem = gunEid and world:get(gunEid, Components.Item) or nil
				local ownerChar = owner and owner.OwnedBy.Character :: Model? or nil
				local gunItemInfo = gunItem and ItemUtils.GetItemInfoFromId(gunItem.Id) or nil
				if ownerChar then
					EffectUtils.BulletBeam(ownerChar, raycastResult.Position, gunItemInfo and gunItemInfo.Name or nil)
				end

				world:set(eid, Components.Collided, { raycastResult = raycastResult })
			end
		end

		world:set(eid, Components.Transform, {
			cframe = newCFrame,
			doNotReconcile = transform.doNotReconcile,
		})
	end
end

return projectilesTravel
