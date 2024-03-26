--!strict

-- Profile Schema
-- January 22nd, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

return {
	Resources = {
		Gems = 0,
		Coins = 100,
	},
	Settings = {},
	Inventory = {
		Items = {},
		Equipped = {},
		Capacity = 1000,
		GrantedDefaults = {},
	} :: Types.Inventory,
} :: Types.PlayerData
