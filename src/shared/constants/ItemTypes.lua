--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	Gun = {
		TagWithSerial = false,
		UniqueProps = {
			Kills = 0, -- amount of kills with this gun
		},
		EquippedAtOnce = 1, -- how many guns can be equipped at once
		CanEquip = true,
		CanSell = true,
		CanTrade = true,
		Stacks = false,
	},
	Crate = {
		TagWithSerial = false,
		CanEquip = false,
		CanSell = false,
		CanTrade = true,
		Stacks = true, -- does it show as x1, etc in inventory
	},
} :: { [Types.ItemType]: Types.ItemTypeInfo }
