--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Guns = Assets:FindFirstChild("guns") :: Folder

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local ItemUtils = require("@utilities/ItemUtils")

type State = {
	services: { [string]: any },
}

local function gunsAreRendered(world: jecs.World, state: State)
	-- Ensure active guns have a hand renderable; clean up when disabled.
	for eid, gun, gunItem in world:query(Components.Gun, Components.Item) do
		local children = world:get(eid, Components.Children) or {}
		local handRenderableId: number? = children.handRenderableId

		if gun.Disabled == true then
			if handRenderableId and world:contains(handRenderableId) then
				world:delete(handRenderableId)
				world:set(eid, Components.Children, { handRenderableId = nil, waistRenderableGunId = children.waistRenderableGunId })
			end
			continue
		end

		if handRenderableId and world:contains(handRenderableId) then
			continue
		end

		local parentId = world:parent(eid)
		if not parentId or not world:contains(parentId) then
			continue
		end

		local renderable = world:get(parentId, Components.Renderable)
		if not renderable then
			continue
		end

		local itemInfo = ItemUtils.GetItemInfoFromId(gunItem.Id)
		local gunFolder = Guns:FindFirstChild(itemInfo.Name) :: Folder?
		if not gunFolder then
			continue
		end

		local handsFolder = gunFolder:FindFirstChild("Hands") :: Folder?
		if not handsFolder then
			continue
		end

		local accessory = handsFolder:FindFirstChildOfClass("Accessory") :: Accessory?
		if not accessory then
			continue
		end

		local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			continue
		end

		local access = accessory:Clone()
		humanoid:AddAccessory(access)

		local handId = world:entity()
		world:set(handId, Components.Renderable, { instance = access })
		world:add(handId, jecs.pair(jecs.ChildOf, eid))

		world:set(eid, Components.Children, {
			handRenderableId = handId,
			waistRenderableGunId = children.waistRenderableGunId,
		})
	end

	-- Waist gun: show when player has no active gun in hand or has a disabled gun.
	for eid, _player, renderable, children in world:query(Components.Player, Components.Renderable, Components.Children) do
		local gunEntityId: number? = children.gunEntityId
		local waistRenderableGunId: number? = children.waistRenderableGunId

		local gun = (gunEntityId and world:contains(gunEntityId)) and world:get(gunEntityId, Components.Gun) or nil
		local playerComp = world:get(eid, Components.Player)

		if not gunEntityId or (gun and gun.Disabled == true) then
			local item = (gunEntityId and world:contains(gunEntityId)) and world:get(gunEntityId, Components.Item) or nil

			if item == nil and playerComp then
				item = state.services.InventoryService:GetItemsOfType(playerComp.player, "Gun", true)[1] :: any
			end

			local hasWaistGun = waistRenderableGunId and world:contains(waistRenderableGunId)
			local waistRenderable = hasWaistGun and world:get(waistRenderableGunId, Components.Renderable) or nil

			if item == nil or (waistRenderable and waistRenderable.instance:GetAttribute("ItemId") ~= item.Id) then
				if hasWaistGun then
					world:delete(waistRenderableGunId)
					world:set(eid, Components.Children, {
						gunEntityId = children.gunEntityId,
						waistRenderableGunId = nil,
					})
				end
				continue
			end

			if waistRenderableGunId then
				continue
			end

			local itemInfo = ItemUtils.GetItemInfoFromId(item.Id)
			local gunFolder = Guns:FindFirstChild(itemInfo.Name) :: Folder?
			if not gunFolder then
				continue
			end

			local waistFolder = gunFolder:FindFirstChild("Waist") :: Folder?
			if not waistFolder then
				continue
			end

			local accessory = waistFolder:FindFirstChildOfClass("Accessory") :: Accessory?
			if not accessory then
				continue
			end

			local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				continue
			end

			local access = accessory:Clone()
			humanoid:AddAccessory(access)
			access:SetAttribute("ItemId", item.Id)

			local waistId = world:entity()
			world:set(waistId, Components.Renderable, { instance = access })
			world:add(waistId, jecs.pair(jecs.ChildOf, eid))

			world:set(eid, Components.Children, {
				gunEntityId = children.gunEntityId,
				waistRenderableGunId = waistId,
			})
		else
			if waistRenderableGunId and world:contains(waistRenderableGunId) then
				world:delete(waistRenderableGunId)
				world:set(eid, Components.Children, {
					gunEntityId = children.gunEntityId,
					waistRenderableGunId = nil,
				})
			end
		end
	end
end

return gunsAreRendered
