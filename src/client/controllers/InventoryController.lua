--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local ClientComm = require(PlayerScripts.ClientComm)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Net = require(ReplicatedStorage.packages.Net)
local Rarities = require(ReplicatedStorage.constants.Rarities)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local InventoryNamespace = Remotes.Client:GetNamespace("Inventory")
local ItemAdded = InventoryNamespace:Get("ItemAdded") :: Net.ClientListenerEvent
local ItemRemoved = InventoryNamespace:Get("ItemRemoved") :: Net.ClientListenerEvent

local PlayerInventoryProperty = ClientComm:GetProperty("PlayerInventory")

local InventoryController = {
	Name = "InventoryController",
	InventoryChanged = Signal.new() :: Signal.Signal<Types.PlayerInventory>,
	ItemAdded = Signal.new() :: Signal.Signal<Types.Item>,
	ItemRemoved = Signal.new() :: Signal.Signal<Types.Item>,
	SortOptions = { "Rarity", "Name", "Type" },
	Sorters = {
		Rarity = function(a: Types.Item, b: Types.Item)
			local itemAInfo = ItemUtils.GetItemInfoFromId(a.Id)
			local itemBInfo = ItemUtils.GetItemInfoFromId(b.Id)
			if not itemAInfo.Rarity or not itemBInfo.Rarity then
				return false
			end
			local rarityA = Rarities[itemAInfo.Rarity]
			local rarityB = Rarities[itemBInfo.Rarity]
			return rarityA.Weight < rarityB.Weight
		end,
		Name = function(a: Types.Item, b: Types.Item)
			local itemAInfo = ItemUtils.GetItemInfoFromId(a.Id)
			local itemBInfo = ItemUtils.GetItemInfoFromId(b.Id)
			return itemAInfo.Name < itemBInfo.Name
		end,
		Type = function(a: Types.Item, b: Types.Item)
			local itemAInfo = ItemUtils.GetItemInfoFromId(a.Id)
			local itemBInfo = ItemUtils.GetItemInfoFromId(b.Id)
			return itemAInfo.Type < itemBInfo.Type
		end,
	},
}

function InventoryController:OnInit()
	PlayerInventoryProperty:Observe(function(newInventory: Types.PlayerInventory?)
		if newInventory then
			InventoryController.InventoryChanged:Fire(newInventory)
		end
	end)
	ItemAdded:Connect(function(item: Types.Item)
		InventoryController.ItemAdded:Fire(item)
	end)
	ItemRemoved:Connect(function(item: Types.Item)
		print("Gotdirect remove signal")
		InventoryController.ItemRemoved:Fire(item)
	end)
end

function InventoryController:GetReplicatedInventory()
	return PlayerInventoryProperty:Get()
end

function InventoryController:ObserveInventoryChanged(callback: (Types.PlayerInventory) -> ())
	local inventory = PlayerInventoryProperty:Get()
	if inventory then
		callback(inventory)
	end
	return InventoryController.InventoryChanged:Connect(callback)
end

return InventoryController
