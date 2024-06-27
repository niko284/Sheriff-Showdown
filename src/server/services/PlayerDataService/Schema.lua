--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	Inventory = {
		Storage = {},
		Equipped = {},
		GrantedDefaults = {},
	},
	Resources = {
		-- Currency
		Coins = 100,
		Gems = 0,
		-- Level
		Level = 1,
		Experience = 0,
	},
	CodesRedeemed = {}, -- string[]
	Statistics = {},
	Settings = {},
} :: Types.DataSchema
