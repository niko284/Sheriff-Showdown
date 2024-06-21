--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	Coins = {
		CanPurchase = true,
		Color = Color3.fromRGB(255, 229, 87),
	},
	Gems = {
		CanPurchase = false,
		Color = Color3.fromRGB(228, 168, 255),
	},
} :: { [Types.Currency]: Types.CurrencyData }
