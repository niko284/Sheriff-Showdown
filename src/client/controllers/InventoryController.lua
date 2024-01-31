-- Inventory Controller
-- May 6th, 2022
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.serde
local Utils = ReplicatedStorage.utils
local Slices = PlayerScripts.rodux.slices

local ClientComm = require(PlayerScripts.ClientComm)
local InventorySlice = require(Slices.InventorySlice)
local InventoryUtils = require(Utils.InventoryUtils)
local ItemSerde = require(Serde.ItemSerde)
local ItemUtils = require(Utils.ItemUtils)
local Remotes = require(ReplicatedStorage.Remotes)
local SettingsController = require(Controllers.SettingsController)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local InventoryRemotes = Remotes.Client:GetNamespace("Inventory")
local ItemAdded = InventoryRemotes:Get("ItemAdded")
local ItemRemoved = InventoryRemotes:Get("ItemRemoved")
local PlayerInventoryProperty = ClientComm:GetProperty("PlayerInventory")

-- // Controller Variables \\

local InventoryController = {
	Name = "InventoryController",
	ItemEquipped = Signal.new(),
	ItemUnequipped = Signal.new(),
	SellModeActivated = Signal.new(),
}

-- // Functions \\

function InventoryController:Init()
	self.Store = require(PlayerScripts.rodux.Store)
end

function InventoryController:Start()
	PlayerInventoryProperty:Observe(function(inventory)
		if inventory then
			inventory.Items = ItemSerde:DeserializeTable(inventory.Items)
			inventory.Equipped = UUIDSerde:DeserializeTable(inventory.Equipped)
		end
		self.Store:dispatch(InventorySlice.actions.SetInventory(inventory))
	end)

	ItemAdded:Connect(function(SerItem)
		self.Store:dispatch(InventorySlice.actions.AddItem({
			item = ItemSerde.Deserialize(SerItem),
		}))
	end)

	ItemRemoved:Connect(function(SerItem)
		self.Store:dispatch(InventorySlice.actions.RemoveItem({
			item = ItemSerde.Deserialize(SerItem),
		}))
	end)
end

function InventoryController:IsInventoryFull(): boolean
	local state = self.Store:getState()
	if not state.Inventory or not state.Inventory.Capacity then
		return false
	end
	return InventoryUtils.GetTakenInventorySpace(state.Inventory) >= state.Inventory.Capacity
end

function InventoryController:GetInventory(): Types.Inventory
	return self.Store:getState().Inventory
end

function InventoryController:GetEquippedItems(): { Types.Item }
	local inventory = self.Store:getState().Inventory
	local equippedItems = {}
	for _, item in inventory.Items do
		if table.find(inventory.Equipped, item.UUID) then
			table.insert(equippedItems, item)
		end
	end
	return equippedItems
end

function InventoryController:GetKeybindSettingForItem(Item: Types.Item): Types.Setting?
	local itemInfo = ItemUtils.GetItemInfoFromId(Item.Id)
	local keybindSettings = {}
	-- Find what keybind setting(s), if any, are associated with this item.
	for _, setting in SettingsController:GetAllSettingInformation() do
		if setting.ActionItemType and setting.ActionItemType == itemInfo.Type then
			table.insert(keybindSettings, setting)
		end
	end
	if #keybindSettings == 0 then
		return nil
	end
	-- Get the items of the same type we have equipped.
	local itemsSameTypeEquipped = InventoryController:GetItemsOfType({ Type = itemInfo.Type } :: any, true)
	-- Which number is this item in the list of items of the same type we have equipped?
	local itemNumber = table.find(itemsSameTypeEquipped, Item)
	if #keybindSettings == 1 then
		return keybindSettings[1]
	else
		-- If we have more than one keybind for this type of item, we return the keybind setting with the ActionItemNumber equal to the number of this item in the list.
		for _, setting in keybindSettings do
			if setting.ActionItemNumber == itemNumber then
				return setting
			end
		end
	end
	return nil
end

function InventoryController:GetItemsOfType(ItemType: Types.ItemType, areEquipped: boolean): { Types.Item }
	local inventory = self.Store:getState().Inventory
	local Items = {}
	for _i, InventoryItem in inventory.Items do
		local itemInfo = ItemUtils.GetItemInfoFromId(InventoryItem.Id)
		if itemInfo and itemInfo.Type == ItemType then
			if areEquipped then
				if table.find(inventory.Equipped, InventoryItem.UUID) then
					table.insert(Items, InventoryItem)
				end
			else
				table.insert(Items, InventoryItem)
			end
		end
	end
	return Items
end

function InventoryController:GetItemFromUUID(UUID: string): Types.Item?
	local inventory = self.Store:getState().Inventory
	for _, item in inventory.Items do
		if item.UUID == UUID then
			return item
		end
	end
	return nil
end

return InventoryController
