--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	Inventory = {
		Storage = {},
		Equipped = {},
	},
	Resources = {
		-- Currency
		Coins = 100,
		Gems = 0,
		-- Level
		Level = 1,
		Experience = 0,
	},
	Statistics = {},
} :: Types.DataSchema
