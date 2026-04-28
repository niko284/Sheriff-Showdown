--!strict

local BlinkClient = require("@client/modules/BlinkClient")
local ItemUtils = require("@utilities/ItemUtils")
local Rarities = require("@constants/Rarities")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")

local InventoryController = {
	Name = "InventoryController",
	InventoryChanged = Signal.new() :: Signal.Signal<Types.PlayerInventory>,
	ItemAdded = Signal.new() :: Signal.Signal<Types.Item>,
	ItemRemoved = Signal.new() :: Signal.Signal<Types.Item>,
	CurrentInventory = nil :: Types.PlayerInventory?,
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
	BlinkClient.InventorySync.On(function(newInventory: Types.PlayerInventory)
		InventoryController.CurrentInventory = newInventory
		InventoryController.InventoryChanged:Fire(newInventory)
	end)
	BlinkClient.InventoryItemAdded.On(function(item: Types.Item)
		InventoryController.ItemAdded:Fire(item)
	end)
	BlinkClient.InventoryItemRemoved.On(function(item: Types.Item)
		InventoryController.ItemRemoved:Fire(item)
	end)
end

function InventoryController:GetReplicatedInventory()
	return InventoryController.CurrentInventory
end

function InventoryController:ObserveInventoryChanged(callback: (Types.PlayerInventory) -> ())
	local inventory = InventoryController.CurrentInventory
	if inventory then
		callback(inventory)
	end
	return InventoryController.InventoryChanged:Connect(callback)
end

return InventoryController
