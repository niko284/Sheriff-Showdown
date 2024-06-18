--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

type ItemTypeInfo = {
	UniqueProps: { [string]: any }?,
	CanEquip: boolean,
	CanSell: boolean,
}

return {
	Gun = {
		TagWithSerial = false,
		UniqueProps = {
			Kills = 0, -- amount of kills with this gun
		},
		CanEquip = true,
		CanSell = true,
	},
} :: { [Types.ItemType]: ItemTypeInfo }
