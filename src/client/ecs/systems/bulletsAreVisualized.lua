local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.assets :: Folder
local Guns = Assets:FindFirstChild("guns") :: Folder

local AudioUtils = require(ReplicatedStorage.utils.AudioUtils)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)

local Components = require(ReplicatedStorage.ecs.components)

local function bulletsAreVisualized(world: Matter.World)
	for eid, bullet: Components.Bullet, owner: Components.Owner in
		world:query(Components.Bullet, Components.Owner):without(Components.Renderable)
	do
		local serverEntity = world:get(eid, MatterReplication.ServerEntity)

		if serverEntity and owner.OwnedBy == Players.LocalPlayer then
			continue -- we don't simulate bullets that were replicated from the server and are owned by the local player. this was already done by the client.
		end

		local bulletInstance = nil
		local clientId = MatterReplication.resolveServerId(world, bullet.gunId :: number)
		if not clientId then
			continue
		end

		local item = world:get(clientId, Components.Item) :: Components.Item
		local gunThatShotBullet = world:get(clientId, Components.Gun) :: Components.Gun

		if item then
			local itemInfo = ItemUtils.GetItemInfoFromId(item.Id)
			local gunAssets = Guns:FindFirstChild(itemInfo.Name)
			if gunAssets then
				local bulletModel = gunAssets:FindFirstChild("Bullet")
				if bulletModel then
					bulletInstance = bulletModel:Clone()
				end
			end
		end
		if not bulletInstance then -- use the default bullet if our gun isn't associated with a custom bullet
			bulletInstance = Instance.new("Part")
			bulletInstance.CanCollide = false
			bulletInstance.Size = Vector3.new(1, 1, 1)
			bulletInstance.Shape = Enum.PartType.Ball
		end

		bulletInstance.Parent = workspace

		local ownerChar = owner.OwnedBy.Character :: Model
		AudioUtils.PlaySoundOnInstance(gunThatShotBullet.BulletSoundId, ownerChar.PrimaryPart :: BasePart)

		world:insert(
			eid,
			Components.Renderable({
				instance = bulletInstance,
			})
		)
		world:insert(
			eid,
			Components.Transform({
				cframe = bullet.origin,
			})
		)
	end
end

return bulletsAreVisualized
