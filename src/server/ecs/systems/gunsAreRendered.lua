local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Guns = Assets:FindFirstChild("guns") :: Folder

local Components = require(ReplicatedStorage.ecs.components)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)
local Types = require(ReplicatedStorage.constants.Types)

local function gunsAreRendered(world: Matter.World, server)
	for eid, gunRecord: MatterTypes.WorldChangeRecord<Components.Gun> in world:queryChanged(Components.Gun) do
		if gunRecord.new and (not gunRecord.old and gunRecord.new.Disabled ~= true) then -- put in their hand
			local parent: Components.Parent? = world:get(eid, Components.Parent)

			if not parent or not world:contains(parent.id) then
				continue
			end

			local renderable: Components.Renderable<Types.Character>? = world:get(parent.id, Components.Renderable)

			local gunItem: Components.Item = world:get(eid, Components.Item)
			local itemInfo = ItemUtils.GetItemInfoFromId(gunItem.Id)
			local gunFolder = Guns:FindFirstChild(itemInfo.Name) :: Folder?

			if gunFolder and renderable then
				local handsFolder = gunFolder:FindFirstChild("Hands") :: Folder?
				if handsFolder then
					local accessory = handsFolder:FindFirstChildOfClass("Accessory") :: Accessory?
					if accessory then
						local access = accessory:Clone()
						renderable.instance.Humanoid:AddAccessory(access)
						local handRenderableId = world:spawn(
							Components.Renderable({
								instance = access,
							}),
							Components.Parent({ id = eid })
						)

						local children: Components.Children<Types.GunChildren> = world:get(eid, Components.Children)
						local newChildren = children and table.clone(children.children or {})
						newChildren.handRenderableId = handRenderableId

						world:insert(
							eid,
							children:patch({
								children = newChildren,
							})
						)
					end
				end
			end
		elseif gunRecord.new and gunRecord.new.Disabled == true then -- remove from their hand. the gun component getting removed is handled automatically by children cleanup. so we don't check here.
			local children: Components.Children<Types.GunChildren> = world:get(eid, Components.Children)
			if children then
				local handRenderableId = children.children.handRenderableId
				if handRenderableId then
					world:despawn(handRenderableId)
				end
			end
		end
	end

	-- waist should show gun if player doesn't have gun in hand or has gun in hand but it's disabled
	for
		eid,
		_target: Components.Target,
		renderable: Components.Renderable<Types.Character>,
		children: Components.Children<Types.PlayerChildren>
	in world:query(Components.Target, Components.Renderable, Components.Children) do
		local gunEntityId = children.children.gunEntityId
		local waistRenderableGunId = children.children.waistRenderableGunId

		local gun = world:contains(gunEntityId) and world:get(gunEntityId, Components.Gun) or nil

		local playerComponent: Components.PlayerComponent? = world:get(eid, Components.Player)

		if not gunEntityId or (gun and gun.Disabled == true) then
			local item: Components.Item = world:contains(gunEntityId) and world:get(gunEntityId, Components.Item) or nil

			if item == nil and playerComponent then
				item =
					server.services.InventoryService:GetItemsOfType(playerComponent.player, "Gun", true)[1] :: Types.ItemInfo
			end

			local hasWaistGun = waistRenderableGunId and world:contains(waistRenderableGunId)
			local waistRenderableGun: Components.Renderable<Accessory> = hasWaistGun
					and world:get(waistRenderableGunId, Components.Renderable)
				or nil

			if
				item == nil or (waistRenderableGun and waistRenderableGun.instance:GetAttribute("ItemId") ~= item.Id)
			then
				if hasWaistGun then -- unequipped from inventory OR switched to another gun in inventory with different id.
					world:despawn(waistRenderableGunId)
				end

				continue
			end

			if waistRenderableGunId then
				continue
			end

			local itemInfo = ItemUtils.GetItemInfoFromId(item.Id)

			local gunFolder = Guns:FindFirstChild(itemInfo.Name) :: Folder?

			if gunFolder then
				local waistFolder = gunFolder:FindFirstChild("Waist") :: Folder?
				if waistFolder then
					local accessory = waistFolder:FindFirstChildOfClass("Accessory") :: Accessory?
					if accessory then
						local access = accessory:Clone()
						renderable.instance.Humanoid:AddAccessory(access)

						access:SetAttribute("ItemId", item.Id)

						local id = world:spawn(
							Components.Renderable({
								instance = access,
							}),
							Components.Parent({ id = eid })
						)

						local newChildren = children and table.clone(children.children or {})
						newChildren.waistRenderableGunId = id

						world:insert(
							eid,
							children:patch({
								children = newChildren,
							})
						)
					end
				end
			end
		else
			if waistRenderableGunId then
				world:despawn(waistRenderableGunId)
			end
		end
	end
end

return gunsAreRendered
