local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.constants.Items)
local Rarities = require(ReplicatedStorage.constants.Rarities)
local Types = require(ReplicatedStorage.constants.Types)

local ItemUtils = {}

function ItemUtils.GetItemInfoFromId(Id: number): Types.ItemInfo
	for _, itemInfo in ipairs(Items) do
		if itemInfo.Id == Id then
			return itemInfo
		end
	end
	return nil :: any
end

function ItemUtils.GetItemInfoFromName(Name: string): Types.ItemInfo
	for _, itemInfo in ipairs(Items) do
		if itemInfo.Name == Name then
			return itemInfo
		end
	end
	return nil :: any
end

function ItemUtils.DoesItemTagWithSerial(Id: number): boolean
	local ItemInformation = ItemUtils.GetItemInfoFromId(Id)
	local RarityInformation = Rarities[ItemInformation.Rarity]
	if RarityInformation then
		return RarityInformation.TagWithSerial
	elseif ItemInformation then
		return ItemInformation.TagWithSerial
	else
		return false
	end
end

return ItemUtils
