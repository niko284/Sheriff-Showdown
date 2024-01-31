-- Inventory Middleware
-- August 8th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers
local Utils = ReplicatedStorage.utils

local InventoryController = require(Controllers.InventoryController)
local ItemUtils = require(Utils.ItemUtils)

-- // Middleware \\

return function(nextDispatch, store)
	return function(action)
		if action.type == "SetInventory" then
			-- If we get up to this point, we have a full snapshot of the inventory. This is usually given by the server. We can check if anything has changed.

			local oldInventory = store:getState().Inventory or { Equipped = {}, Items = {} }
			local newInventory = action.payload
			if not newInventory then
				return nextDispatch(action)
			end
			-- check if item was unequipped
			for _, oldUUID in oldInventory.Equipped do
				local itemFound = false
				for _, newUUID in newInventory.Equipped do
					if oldUUID == newUUID then
						itemFound = true
						break
					end
				end
				if not itemFound then
					local oldItem = nil
					for _, item in newInventory.Items do
						if item.UUID == oldUUID then
							oldItem = item
							break
						end
					end
					InventoryController.ItemUnequipped:Fire(oldItem)
				end
			end
			-- check if item was equipped
			for _, newUUID in newInventory.Equipped do
				local itemFound = false
				for _, oldUUID in oldInventory.Equipped do
					if oldUUID == newUUID then
						itemFound = true
						break
					end
				end
				if not itemFound then
					local newItem = nil
					for _, item in newInventory.Items do
						if item.UUID == newUUID then
							newItem = item
							break
						end
					end
					InventoryController.ItemEquipped:Fire(newItem)
				end
			end
		elseif action.type == "EquipItem" then
			InventoryController.ItemEquipped:Fire(action.payload.item, ItemUtils.GetItemInfoFromId(action.payload.item.Id))
		elseif action.type == "UnequipItem" then
			InventoryController.ItemUnequipped:Fire(action.payload.item, ItemUtils.GetItemInfoFromId(action.payload.item.Id))
		end
		return nextDispatch(action)
	end
end
