local RunService = game:GetService("RunService")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local EffectUtils = require("@utilities/EffectUtils")
local ItemUtils = require("@utilities/ItemUtils")
local LocalComponents = require("@ecs/localComponents")
local Util = require("@ecs/Util")

type State = {
	scheduler: any,
	replecsClient: any?,
}

local function projectilesTravel(world: jecs.World, state: State)
	local deltaTime = state.scheduler:getDeltaTime()
	local replecsClient = state.replecsClient
	local isClient = RunService:IsClient()

	for eid, projectile, velocity, transform in
		world:query(Components.Projectile, Components.Velocity, Components.Transform)
	do
		if isClient and world:has(eid, LocalComponents.ProjectileHidden) then
			continue
		end

		local ownerPlayer = Util.GetOwnerPlayer(world, eid)

		local newCFrame =
			CFrame.lookAlong(transform.cframe.Position + velocity.velocity * deltaTime, velocity.velocity.Unit)
		local positionChange = newCFrame.Position - transform.cframe.Position

		if isClient then
			local filterComponent = world:get(eid, LocalComponents.ProjectileFilter)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = filterComponent and filterComponent.instances or {}
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
				local ownerChar = ownerPlayer and ownerPlayer.Character :: Model? or nil
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
