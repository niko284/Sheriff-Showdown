-- Item Utils
-- August 19th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Items = require(Constants.Items)
local Types = require(Constants.Types)

-- // Utils \\

local ItemUtils = {}

function ItemUtils.IsDefaultItem(ItemInfo: Types.ItemInfo): boolean
	return ItemInfo.Default ~= nil
end

function ItemUtils.GetItemIdFromName(Name: string): number?
	for _, Item in Items do
		if Item.Name == Name then
			return Item.Id
		end
	end
	return nil
end

function ItemUtils.GetRandomItemOfType(ItemType: Types.ItemType)
	local validItems = {}
	for _, Item in Items do
		if Item.Type == ItemType then
			table.insert(validItems, Item)
		end
	end
	return validItems[math.random(1, #validItems)]
end

function ItemUtils.GetItemInfoFromId(Id: number): Types.ItemInfo?
	for _, Item in pairs(Items) do
		if Item.Id == Id then
			return Item
		end
	end
	return nil
end

return ItemUtils
