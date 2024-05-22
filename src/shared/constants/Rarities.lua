--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	Basic = {
		TagWithSerial = false,
	},
	Rare = {
		TagWithSerial = false,
	},
	Epic = {
		TagWithSerial = false,
	},
	Legendary = {
		TagWithSerial = false,
	},
	Exotic = {
		TagWithSerial = true,
	},
} :: { [Types.ItemRarity]: Types.RarityInfo }
