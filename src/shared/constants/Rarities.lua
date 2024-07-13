--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	Basic = {
		Color = Color3.fromRGB(160, 160, 160),
		TagWithSerial = false,
		Weight = 50,
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
		Weight = 8,
	},
	Exotic = {
		TagWithSerial = true,
		Color = Color3.fromRGB(255, 196, 79),
		Weight = 2,
	},
} :: { [Types.ItemRarity]: Types.RarityInfo }
