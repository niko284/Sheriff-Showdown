--!strict
-- Rarities
-- February 13th, 2024
-- Nick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

return {
	Basic = {
		Color = Color3.fromRGB(160, 160, 160),
		TagWithSerial = false,
		Weight = 54,
	},
	Rare = {
		Color = Color3.fromRGB(98, 255, 0),
		TagWithSerial = false,
		Weight = 25,
	},
	Epic = {
		Color = Color3.fromRGB(200, 0, 255),
		TagWithSerial = false,
		Weight = 15,
	},
	Legendary = {
		Color = Color3.fromRGB(255, 0, 0),
		TagWithSerial = false,
		Weight = 5,
	},
	Exotic = {
		TagWithSerial = true,
		Color = Color3.fromRGB(255, 196, 79),
		Weight = 1,
	},
} :: { [Types.Rarity]: Types.RarityInfo }
