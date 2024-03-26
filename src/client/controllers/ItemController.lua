--!strict

-- Item Controller
-- May 23rd, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages

local ItemTypes = require(Constants.ItemTypes)
local Items = require(Constants.Items)
local Rarities = require(Constants.Rarities)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)

-- // Controller Variables \\

local ItemController = {
	Name = "ItemController",
	Items = {},
}

-- // Functions \\

function ItemController:Init()
	self.Items = Items
end

function ItemController:GetItemFromId(Id: number): Types.ItemInfo?
	for _, Item in pairs(self.Items) do
		if Item.Id == Id then
			return Item
		end
	end
	return nil
end

function ItemController:GetRarityProbabilities()
	local TotalWeight = 0
	for _, Rarity in Rarities do
		TotalWeight += Rarity.Weight
	end
	local RarityProbabilities = {}
	for RarityName, Rarity in pairs(Rarities) do
		RarityProbabilities[RarityName] = Rarity.Weight / TotalWeight
	end
	return RarityProbabilities
end

function ItemController:BuildBaseItemProps(Id: number, ExtraProps: { [string]: any }?)
	local ItemInfo = ItemController:GetItemFromId(Id)
	assert(ItemInfo, string.format("Item with id %d does not exist.", Id))

	local ItemTypeInfo = ItemTypes[ItemInfo.Type]
	local RarityInfo = nil

	local itemColor = nil
	if ItemInfo.Rarity then
		RarityInfo = Rarities[ItemInfo.Rarity]
		itemColor = RarityInfo.Color
	else
		itemColor = ItemTypeInfo.Color -- special case for item types that don't have a rarity but need a color. for example, the "boost" item type.
	end
	local hue, saturation, value = itemColor:ToHSV()

	return Sift.Dictionary.merge({
		icon = string.format("rbxassetid://%d", ItemInfo.Image or 0),
		name = ItemInfo.Name,
		strokeColor = RarityInfo and RarityInfo.Color,
		textStroke = RarityInfo and RarityInfo.Color,
		dashColor = RarityInfo and RarityInfo.Color,
		itemId = Id,
		strokeThickness = 1.5,
		gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, saturation, value * 0.4)), -- Make the gradient color darker.
			ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 34, 34)),
		}),
		iconSize = ItemTypeInfo.IconSize, -- Let's let the item's size override the item type's size.
	}, ExtraProps or {})
end

return ItemController
