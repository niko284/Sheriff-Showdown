--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.assets :: Folder
local Guns = Assets:FindFirstChild("guns") :: Folder

local jecs = require("@packages/jecs")

local AudioUtils = require("@utilities/AudioUtils")
local Components = require("@ecs/components")
local ItemUtils = require("@utilities/ItemUtils")

type State = {
	replecsClient: any,
}

local function projectilesAreVisualized(world: jecs.World, state: State)
	local replecsClient = state.replecsClient

	for eid, projectile, owner in world:query(Components.Projectile, Components.Owner):without(Components.Renderable) do
		local isServerReplicated = replecsClient and replecsClient:get_server_entity(eid) ~= nil
		if isServerReplicated and owner.OwnedBy == Players.LocalPlayer then
			continue
		end

		local clientGunId = projectile.gunId and replecsClient and replecsClient:get_client_entity(projectile.gunId)
			or nil
		if not clientGunId then
			continue
		end

		local item = world:get(clientGunId, Components.Item)
		local gun = world:get(clientGunId, Components.Gun)

		local bulletInstance: BasePart | Model | nil = nil
		if item then
			local itemInfo = ItemUtils.GetItemInfoFromId(item.Id)
			local gunAssets = Guns:FindFirstChild(itemInfo.Name)
			if gunAssets then
				local bulletModel = gunAssets:FindFirstChild("Bullet")
				if bulletModel then
					bulletInstance = bulletModel:Clone() :: Model
				end
			end
		end

		if not bulletInstance then
			local part = Instance.new("Part")
			part.CanCollide = false
			part.Size = Vector3.new(1, 1, 1)
			part.Shape = Enum.PartType.Ball
			bulletInstance = part
		end

		bulletInstance.Parent = workspace

		if gun then
			local ownerChar = owner.OwnedBy.Character :: Model
			AudioUtils.PlaySoundOnInstance(gun.BulletSoundId, ownerChar.PrimaryPart :: BasePart)
		end

		if bulletInstance then
			world:set(eid, Components.Renderable, { instance = bulletInstance })
		end
		if projectile.origin then
			world:set(eid, Components.Transform, { cframe = projectile.origin })
		end
	end
end

return projectilesAreVisualized
