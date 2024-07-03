--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

type ItemTypeInfo = {
	UniqueProps: { [string]: any }?,
	CanEquip: boolean,
	CanSell: boolean,
	EquippedAtOnce: (number | (Types.ItemInfo) -> number)?,
}

return {
	Gun = {
		TagWithSerial = false,
		UniqueProps = {
			Kills = 0, -- amount of kills with this gun
		},
		EquippedAtOnce = 1, -- how many guns can be equipped at once
		CanEquip = true,
		CanSell = true,
	},
	Crate = {
		TagWithSerial = false,
		CanEquip = false,
		CanSell = false,
	},
} :: { [Types.ItemType]: ItemTypeInfo }
