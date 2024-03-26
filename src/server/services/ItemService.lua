--!strict

-- Item Service
-- May 13th, 2022
-- Nick

-- // Variables \\

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils

local Crates = require(Constants.Crates)
local ItemList = require(Constants.Items)
local ItemTypes = require(Constants.ItemTypes)
local Promise = require(Packages.Promise)
local Rarities = require(Constants.Rarities)
local Types = require(Constants.Types)
local WeightedRandomChooser = require(Utils.WeightedRandomChooser)

local ItemDataStore = DataStoreService:GetDataStore("AnimeDungeonSerialsOfficial1")
local ITEM_KEY = "Serial_%d"

-- // Service Variables \\

local ItemService = {
	Name = "ItemService",
	Items = {} :: { Types.ItemInfo },
}

-- // Functions \\

function ItemService:Init()
	ItemService.Items = ItemList
end

function ItemService:RollItemsFromCrate(CrateType: Types.CrateType, AmountOfCrates: number): { Types.Item }
	local ItemsRolled = {}
	for _ = 1, AmountOfCrates do
		local Crate = Crates[CrateType]
		local RolledItem = ItemService:RollItemFromCrate(Crate)
		table.insert(ItemsRolled, RolledItem)
	end

	return ItemsRolled
end

function ItemService:RollItemFromCrate(Crate: Types.CrateInfo): Types.Item
	local randomChooser = WeightedRandomChooser.new()

	local itemsByRarity = {}
	for _, itemName in Crate.ItemContents do
		local itemInfo = ItemService:GetItemFromName(itemName)
		if itemInfo then
			itemsByRarity[itemInfo.Rarity] = itemsByRarity[itemInfo.Rarity] or {}
			table.insert(itemsByRarity[itemInfo.Rarity], itemInfo)

			local rarityInfo = Rarities[itemInfo.Rarity]
			randomChooser:SetWeight(itemInfo.Rarity, rarityInfo.Weight)
		end
	end

	local RandomObject = Random.new(os.time())
	local chosenRarity = randomChooser:Choose(RandomObject)

	local chosenItemInfo = itemsByRarity[chosenRarity][RandomObject:NextInteger(1, #itemsByRarity[chosenRarity])]

	local generatedItem = ItemService:GenerateItem(chosenItemInfo.Id, true):expect()

	return generatedItem
end

function ItemService:GenerateItem(Id: number, TagWithSerial: boolean?)
	return Promise.new(function(resolve, _reject)
		local ItemInformation = ItemService:GetItemFromId(Id)
		local ItemTypeInformation = ItemTypes[ItemInformation.Type]

		local NewItem = {
			Id = ItemInformation.Id,
			UUID = HttpService:GenerateGUID(false),
			Locked = false,
			Favorited = false,
		}

		-- Let's get the unique properties of the item based on its type and add them to the item
		if ItemTypeInformation.UniqueProps then
			for Property, Value in ItemTypeInformation.UniqueProps do
				local propValue = nil
				if typeof(Value) == "function" then
					local valueGetter = Value :: (any) -> any
					propValue = valueGetter(ItemInformation)
				else
					propValue = Value
				end
				NewItem[Property] = propValue
			end
		end

		if TagWithSerial == true then
			resolve(
				Promise.retryWithDelay(ItemService.GenerateSerialNumber, 5, 5, ItemService, NewItem.Id)
					:andThen(function(SerialNumber)
						NewItem.Serial = SerialNumber
						return NewItem
					end)
			)
		else
			resolve(NewItem)
		end
	end)
end

function ItemService:GenerateSerialNumber(Id: number)
	return Promise.new(function(resolve, reject)
		local ItemInformation = ItemService:GetItemFromId(Id)
		local Success, SerialNumber, _KeyInfo = pcall(function()
			return ItemDataStore:IncrementAsync(string.format(ITEM_KEY, ItemInformation.Id), 1)
		end)
		if Success then
			resolve(SerialNumber)
		else
			reject(SerialNumber)
		end
	end)
end

function ItemService:GetItemFromId(Id: number): Types.ItemInfo
	local foundItem = nil
	for _, Item in pairs(ItemService.Items) do
		if Item.Id == Id then
			foundItem = Item
		end
	end
	return foundItem
end

function ItemService:GetItemFromName(Name: string): Types.ItemInfo?
	for _, Item in ItemService.Items do
		if Item.Name == Name then
			return Item
		end
	end
	return nil
end

function ItemService:GetDefaultItems(): { Types.ItemInfo }
	local defaultItems = {}
	for _, item: Types.ItemInfo in ItemService.Items do
		if item.Default then
			table.insert(defaultItems, item)
		end
	end
	return defaultItems
end

function ItemService:GetItems(): { Types.ItemInfo }
	return ItemService.Items
end

return ItemService :: any
