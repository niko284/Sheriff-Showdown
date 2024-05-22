--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

type ItemTypeInfo = {
	UniqueProps: { [string]: any }?,
}

return {
	Gun = {
		TagWithSerial = false,
		UniqueProps = {},
	},
} :: { [Types.ItemType]: ItemTypeInfo }
