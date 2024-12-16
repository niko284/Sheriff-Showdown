--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local InventoryContext = require(ReplicatedStorage.react.contexts.InventoryContext)
local InventoryController = require(Controllers.InventoryController)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local useState = React.useState
local useEffect = React.useEffect
local e = React.createElement

local function InventoryProvider(props)
	local inventory, setInventory = useState(nil :: Types.PlayerInventory?)

	useEffect(function()
		if inventory == nil then
			local replicatedInventory = InventoryController:GetReplicatedInventory()
			if replicatedInventory then
				setInventory(replicatedInventory)
			end
		end
		local connection = InventoryController.InventoryChanged:Connect(function(newInventory)
			setInventory(newInventory)
		end)
		local itemAdded = InventoryController.ItemAdded:Connect(function(item)
			local newInventory = table.clone(inventory)
			local newStorage = table.clone(newInventory.Storage)
			table.insert(newStorage, item)
			newInventory.Storage = newStorage
			setInventory(newInventory)
		end)
		local itemRemoved = InventoryController.ItemRemoved:Connect(function(item)
			local newInventory = table.clone(inventory)

			local storageOrEquipped = nil
			for _, itemStorage in newInventory.Storage do
				if itemStorage.UUID == item.UUID then
					storageOrEquipped = "Storage"
					break
				end
			end

			if storageOrEquipped == nil then
				for _, itemEquipped in newInventory.Equipped do
					if itemEquipped.UUID == item.UUID then
						storageOrEquipped = "Equipped"
						break
					end
				end
			end

			if storageOrEquipped then
				local newStorage = table.clone(newInventory[storageOrEquipped])
				for i, itemStorage in ipairs(newStorage) do
					if itemStorage.UUID == item.UUID then
						table.remove(newStorage, i)
						break
					end
				end
				newInventory[storageOrEquipped] = newStorage
			end

			setInventory(newInventory)
		end)
		return function()
			connection:Disconnect()
			itemAdded:Disconnect()
			itemRemoved:Disconnect()
		end
	end, { inventory })

	return e(InventoryContext.Provider, {
		value = inventory,
	}, props.children)
end

return InventoryProvider
