--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.packages.Freeze)
local ItemTypes = require(ReplicatedStorage.constants.ItemTypes)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local StringUtils = require(ReplicatedStorage.utils.StringUtils)
local Types = require(ReplicatedStorage.constants.Types)

local InventoryUtils = {}

-- Returns an immutable copy of the inventory with the item equipped
function InventoryUtils.EquipItem(Inventory: Types.PlayerInventory, ItemUUID: string): Types.PlayerInventory
	local newInventory = table.clone(Inventory)
	local newStorage = table.clone(newInventory.Storage)
	local newEquipped = table.clone(newInventory.Equipped)

	local indexToRemove = nil
	for index, item in ipairs(newStorage) do
		if item.UUID == ItemUUID then
			indexToRemove = index
			break
		end
	end

	if not indexToRemove then
		return newInventory
	end

	local ItemInfo = ItemUtils.GetItemInfoFromId(newStorage[indexToRemove].Id)
	local ItemTypeInfo = ItemTypes[ItemInfo.Type]
	local equippedAtOnce = if typeof(ItemTypeInfo.EquippedAtOnce) == "function"
		then ItemTypeInfo.EquippedAtOnce(ItemInfo)
		else ItemTypeInfo.EquippedAtOnce

	if equippedAtOnce then
		local equippedItems = InventoryUtils.GetItemsOfType(Inventory, ItemInfo.Type, true)
		if #equippedItems >= equippedAtOnce then -- unequip one item if we're at the limit using the first item in the alphabet to sync with the client-side prediction
			local _uuid, index =
				StringUtils.GetFirstStringInAlphabet(Freeze.List.map(equippedItems, function(itemOfType)
					return itemOfType.UUID
				end))
			newInventory = InventoryUtils.UnequipItem(newInventory, equippedItems[index].UUID)
			newStorage = newInventory.Storage
			newEquipped = newInventory.Equipped
		end
	end

	local Item = table.remove(newStorage, indexToRemove) :: Types.Item
	table.insert(newEquipped, Item)

	newInventory.Storage = newStorage
	newInventory.Equipped = newEquipped

	return newInventory
end

function InventoryUtils.UnequipItem(Inventory: Types.PlayerInventory, ItemUUID: string): Types.PlayerInventory
	local newInventory = table.clone(Inventory)
	local newStorage = table.clone(newInventory.Storage)
	local newEquipped = table.clone(newInventory.Equipped)

	local indexToRemove = nil
	for index, item in ipairs(newEquipped) do
		if item.UUID == ItemUUID then
			indexToRemove = index
			break
		end
	end

	if not indexToRemove then
		return newInventory
	end

	local Item = table.remove(newEquipped, indexToRemove) :: Types.Item
	table.insert(newStorage, Item)

	newInventory.Storage = newStorage
	newInventory.Equipped = newEquipped

	return newInventory
end

function InventoryUtils.LockItem(
	Inventory: Types.PlayerInventory,
	ItemUUID: string,
	Locked: boolean
): Types.PlayerInventory
	local storageOrEquipped = nil
	local indexToLock = nil

	for index, item in ipairs(Inventory.Storage) do
		if item.UUID == ItemUUID then
			storageOrEquipped = Inventory.Storage
			indexToLock = index
			break
		end
	end

	if not storageOrEquipped then
		for index, item in ipairs(Inventory.Equipped) do
			if item.UUID == ItemUUID then
				storageOrEquipped = Inventory.Equipped
				indexToLock = index
				break
			end
		end
	end

	if not storageOrEquipped then
		return Inventory
	end

	local key = storageOrEquipped == Inventory.Storage and "Storage" or "Equipped"
	local newInventory = table.clone(Inventory)
	local newItems = table.clone(newInventory[key])
	local newItem = table.clone(newItems[indexToLock])

	newItem.Locked = Locked
	newItems[indexToLock] = newItem
	newInventory[key] = newItems

	return newInventory
end

function InventoryUtils.ToggleItemFavorite(
	Inventory: Types.PlayerInventory,
	ItemUUID: string,
	Favorite: boolean
): Types.PlayerInventory
	local storageOrEquipped = nil
	local indexToFavorite = nil

	for index, item in ipairs(Inventory.Storage) do
		if item.UUID == ItemUUID then
			storageOrEquipped = Inventory.Storage
			indexToFavorite = index
			break
		end
	end

	if not storageOrEquipped then
		for index, item in ipairs(Inventory.Equipped) do
			if item.UUID == ItemUUID then
				storageOrEquipped = Inventory.Equipped
				indexToFavorite = index
				break
			end
		end
	end

	if not storageOrEquipped then
		return Inventory
	end

	local key = storageOrEquipped == Inventory.Storage and "Storage" or "Equipped"
	local newInventory = table.clone(Inventory)
	local newItems = table.clone(newInventory[key])
	local newItem = table.clone(newItems[indexToFavorite])

	newItem.Favorited = Favorite
	newItems[indexToFavorite] = newItem
	newInventory[key] = newItems

	return newInventory
end

function InventoryUtils.GetItemsOfType(
	Inventory: Types.PlayerInventory,
	ItemType: Types.ItemType,
	Equipped: boolean?
): { Types.Item }
	local items = if Equipped == true then Inventory.Equipped else Inventory.Storage

	local filteredItems = {} :: { Types.Item }
	for _, Item in ipairs(items) do
		local ItemInfo = ItemUtils.GetItemInfoFromId(Item.Id)
		if ItemInfo.Type == ItemType then
			table.insert(filteredItems, Item :: any)
		end
	end

	return filteredItems
end

function InventoryUtils.IsEquipped(Inventory: Types.PlayerInventory, ItemUUID: string): boolean
	for _, Item in ipairs(Inventory.Equipped) do
		if Item.UUID == ItemUUID then
			return true
		end
	end

	return false
end

function InventoryUtils.GetItemOfUUID(Inventory: Types.PlayerInventory, ItemUUID: string): Types.Item?
	for _, Item in ipairs(Inventory.Storage) do
		if Item.UUID == ItemUUID then
			return Item
		end
	end

	for _, Item in ipairs(Inventory.Equipped) do
		if Item.UUID == ItemUUID then
			return Item
		end
	end

	return nil
end

return InventoryUtils
