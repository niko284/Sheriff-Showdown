--!strict

-- Inventory Service
-- April 2nd, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Services = ServerScriptService.services
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.serde
local Utils = ReplicatedStorage.utils

local DataService = require(Services.DataService)
local InventoryUtils = require(Utils.InventoryUtils)
local ItemSerde = require(Serde.ItemSerde)
local ItemService = require(Services.ItemService)
local ItemTypes = require(Constants.ItemTypes)
local ItemUtils = require(Utils.ItemUtils)
local Remotes = require(ReplicatedStorage.Remotes)
local ServerComm = require(ServerScriptService.ServerComm)
local Sift = require(Packages.Sift)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local InventoryRemotes = Remotes.Server:GetNamespace("Inventory")
local ItemAdded = InventoryRemotes:Get("ItemAdded")
local ItemRemoved = InventoryRemotes:Get("ItemRemoved")

local DEFAULT_ITEMS_GRANTED_MAP = {} :: { [Player]: boolean }

-- // Service Variables \\

local InventoryService = {
	Name = "InventoryService",
	PlayerInventory = ServerComm:CreateProperty("PlayerInventory", nil),
	ItemEquipped = Signal.new(),
	ItemUnequipped = Signal.new(),
	ItemUsed = Signal.new(),
	ItemUpgraded = Signal.new(),
	InventoryLoaded = Signal.new(),
	DefaultItemsGranted = Signal.new(), -- Fired when default items are granted to a player.
	FishCaught = Signal.new(), -- Fired when a player catches a fish.
	DefaultGrantMap = DEFAULT_ITEMS_GRANTED_MAP,
}

-- // Functions \\

function InventoryService:Start()
	DataService.PlayerDataLoaded:Connect(function(Player: Player, PlayerProfile: DataService.PlayerProfile)
		local grantedDefaultItems = PlayerProfile.Data.Inventory.GrantedDefaults

		for _, ItemInfo in ItemService:GetItems() do
			local itemsOfType = InventoryService:GetItemsOfId(Player, ItemInfo, false)

			if not table.find(grantedDefaultItems, ItemInfo.Id) and #itemsOfType == 0 then
				local isDefault = if typeof(ItemInfo.Default) == "function"
					then ItemInfo.Default(Player)
					else ItemInfo.Default
				if not isDefault then
					continue
				end
				ItemService:GenerateItem(ItemInfo.Id)
					:andThen(function(Item: Types.Item)
						table.insert(grantedDefaultItems, ItemInfo.Id)
						InventoryService:AddItem(Player, Item)
						if ItemInfo.EquipOnDefault == true then
							InventoryService:EquipItem(Player, Item, false)
						end
					end)
					:catch(function() end)
					:awaitStatus()
			end
		end

		DEFAULT_ITEMS_GRANTED_MAP[Player] = true
		InventoryService.DefaultItemsGranted:Fire(Player)

		local inventoryMerge = Sift.Dictionary.merge(PlayerProfile.Data.Inventory, {
			Items = ItemSerde:SerializeTable(PlayerProfile.Data.Inventory.Items),
			Equipped = UUIDSerde:SerializeTable(PlayerProfile.Data.Inventory.Equipped),
		})

		InventoryService.PlayerInventory:SetFor(Player, inventoryMerge)
		InventoryService.InventoryLoaded:Fire(Player, PlayerProfile.Data.Inventory)
	end)
end

function InventoryService:OnPlayerRemoving(Player: Player)
	DEFAULT_ITEMS_GRANTED_MAP[Player] = nil
end

function InventoryService:GetInventory(Player: Player): Types.Inventory?
	local playerProfile = DataService:GetData(Player)
	if not playerProfile then
		return nil
	else
		return playerProfile.Data.Inventory
	end
end

function InventoryService:AddItem(Player: Player, Item: Types.Item)
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	if not Inventory then
		return
	end
	Inventory.Items = Sift.Array.append(Inventory.Items, Item)
	ItemAdded:SendToPlayer(Player, ItemSerde.Serialize(Item))
end

function InventoryService:AddItems(Player: Player, Items: { Types.Item })
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	if not Inventory then
		return
	end
	for _, Item in Items do
		Inventory.Items = Sift.Array.append(Inventory.Items, Item)
		ItemAdded:SendToPlayer(Player, ItemSerde.Serialize(Item))
	end
end

function InventoryService:UnequipItem(Player: Player, Item: Types.Item): boolean
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	if not table.find(Inventory.Equipped, Item.UUID) then
		return false
	else
		table.remove(Inventory.Equipped, table.find(Inventory.Equipped, Item.UUID))
		InventoryService.ItemUnequipped:Fire(Player, InventoryService:GetItemFromUUID(Player, Item.UUID) :: Types.Item)
		return true
	end
end

function InventoryService:EquipItem(Player: Player, Item: Types.Item, shouldSendEvent: boolean?): boolean
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	if Sift.Array.find(Inventory.Equipped, Item.UUID) then
		return false
	end

	local itemInfo = ItemService:GetItemFromId(Item.Id) :: Types.ItemInfo
	local itemTypeInfo = ItemTypes[itemInfo.Type]
	if itemTypeInfo.UnequipItemsOfType then -- If this item type does not support being equipped simultaneously with items of another type, then unequip all items of that type. (For example, a fishing rod and a weapon).
		for _, itemType in itemTypeInfo.UnequipItemsOfType do
			local itemsToUnequip = InventoryService:GetItemsOfType(Player, itemType, true)
			for _, itemToUnequip in pairs(itemsToUnequip) do
				InventoryService:UnequipItem(Player, itemToUnequip)
			end
		end
	end

	for _i, InventoryItem in Inventory.Items :: { Types.Item } do
		if InventoryItem.UUID == Item.UUID then
			Inventory.Equipped = Sift.Array.append(Inventory.Equipped, Item.UUID)
			if shouldSendEvent ~= false then
				InventoryService.ItemEquipped:Fire(Player, InventoryItem)
			end
			return true
		end
	end
	return false
end

function InventoryService:GetItemsOfType(Player: Player, ItemType: Types.ItemType, areEquipped: boolean?): { Types.Item }
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	local Items = {}
	for _i, InventoryItem in Inventory.Items do
		local itemInfo = ItemUtils.GetItemInfoFromId(InventoryItem.Id)
		if itemInfo and itemInfo.Type == ItemType then
			if areEquipped then
				if table.find(Inventory.Equipped, InventoryItem.UUID) then
					table.insert(Items, InventoryItem)
				end
			else
				table.insert(Items, InventoryItem)
			end
		end
	end
	return Items
end

function InventoryService:RemoveItem(Player: Player, Item: Types.Item, shouldSendEvent: boolean?)
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	Inventory.Items = Sift.Array.filter(Inventory.Items, function(inventoryItem: Types.Item)
		local isRemovedItem = inventoryItem.UUID == Item.UUID
		if isRemovedItem and shouldSendEvent ~= false then
			ItemRemoved:SendToPlayer(Player, ItemSerde.Serialize(inventoryItem))
		end
		return not isRemovedItem
	end)
end

function InventoryService:RemoveItems(Player: Player, Items: { Types.Item })
	for _i, Item in Items do
		InventoryService:RemoveItem(Player, Item)
	end
end

function InventoryService:GetItemsOfId(Player: Player, Id: number, areEquipped: boolean?): { Types.Item }
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	local Items = {}
	for _i, InventoryItem in Inventory.Items do
		if InventoryItem.Id == Id then
			if areEquipped then
				if table.find(Inventory.Equipped, InventoryItem.UUID) then
					table.insert(Items, InventoryItem)
				end
			else
				table.insert(Items, InventoryItem)
			end
		end
	end
	return Items
end

function InventoryService:GetItemFromUUID(Player: Player, UUID: string): Types.Item?
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	if Inventory then
		for _i, InventoryItem in Inventory.Items do
			if InventoryItem.UUID == UUID then
				return InventoryItem
			end
		end
	end
	return nil
end

function InventoryService:HasItemInStorage(Player: Player, ItemUUID: string): boolean
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	for _i, item in Inventory.Items do
		if item.UUID == ItemUUID and not table.find(Inventory.Equipped, ItemUUID) then
			return true
		end
	end
	return false
end

function InventoryService:GetSpaceLeft(Player: Player): number
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	return Inventory.Capacity - InventoryUtils.GetTakenInventorySpace(Inventory)
end

function InventoryService:HasItem(Player: Player, ItemInfo: Types.ItemInfo): boolean
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	for _i, item in Inventory.Items do
		if item.Id == ItemInfo.Id then
			return true
		end
	end
	return false
end

function InventoryService:IsInventoryFull(Player: Player): boolean
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	return InventoryUtils.GetTakenInventorySpace(Inventory) >= Inventory.Capacity
end

function InventoryService:GetItemsInIdRange(Player: Player, MinId: number, MaxId: number, OneOfEach: boolean?): { Types.Item }
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	local Items = {}
	for _i, item in Inventory.Items do
		local itemId = item.Id :: number
		if itemId >= MinId and itemId <= MaxId then
			if OneOfEach == true then
				-- only insert if no other item of same id is in the table
				local alreadyInserted = false
				for _, insertedItem in pairs(Items) do
					if insertedItem.Id == item.Id then
						alreadyInserted = true
						break
					end
				end
				if not alreadyInserted then
					table.insert(Items, item)
				end
			else
				table.insert(Items, item)
			end
		end
	end
	return Items
end

function InventoryService:IsEquipped(Player: Player, Item: Types.Item): boolean
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	return table.find(Inventory.Equipped, Item.UUID) ~= nil
end

function InventoryService:GetEquippedItems(Player: Player): { Types.Item }
	local equippedItems = {}
	local Inventory = InventoryService:GetInventory(Player) :: Types.Inventory
	for _, ItemUUID in Inventory.Equipped do
		local item = InventoryService:GetItemFromUUID(Player, ItemUUID)
		if item then
			table.insert(equippedItems, item)
		end
	end
	return equippedItems
end

return InventoryService
