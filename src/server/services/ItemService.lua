local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTypes = require(ReplicatedStorage.constants.ItemTypes)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Promise = require(ReplicatedStorage.packages.Promise)
local Types = require(ReplicatedStorage.constants.Types)

local ItemDataStore = DataStoreService:GetDataStore("ItemSerials")

local ITEM_KEY = "Serial_%d"

local ItemService = {
	Name = "ItemService",
}

function ItemService:GenerateItem(Id: number, IgnoreSerial: boolean?)
	return Promise.new(function(resolve, _reject)
		local ItemInformation = ItemUtils.GetItemInfoFromId(Id)
		local ItemTypeInformation = ItemTypes[ItemInformation.Type]
		local tagWithSerial = ItemUtils.DoesItemTagWithSerial(Id)

		local NewItem: Types.Item = {
			Id = ItemInformation.Id,
			UUID = HttpService:GenerateGUID(false),
			Locked = false,
		}

		-- Let's get the unique properties of the item based on its type and add them to the item
		if ItemTypeInformation.UniqueProps then
			for Property, Value in ItemTypeInformation.UniqueProps do
				NewItem[Property] = Value
			end
		end

		if tagWithSerial == true and IgnoreSerial ~= true then
			resolve(
				Promise.retryWithDelay(self.GenerateSerialNumber, 5, 5, self, NewItem.Id):andThen(function(SerialNumber)
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
		local ItemInformation = ItemUtils.GetItemInfoFromId(Id)
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

return ItemService
