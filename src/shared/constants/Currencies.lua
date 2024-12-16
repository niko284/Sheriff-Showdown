--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	Coins = {
		CanPurchase = true,
		Color = Color3.fromRGB(255, 229, 87),
		Packs = {
			{
				Amount = 100,
				ProductId = 2659038681,
				Image = 130556672745897,
			},
			{
				Amount = 250,
				ProductId = 2659038770,
				Image = 139974142218616,
			},
			{
				Amount = 500,
				ProductId = 2659038863,
				Image = 113445082515743,
			},
			{
				Amount = 1000,
				ProductId = 2659038963,
				Image = 79641977224038,
			},
			{
				Amount = 2500,
				ProductId = 2659039116,
				Image = 95005839778213,
			},
			{
				Amount = 5000,
				ProductId = 2659039209,
				Image = 99591038821785,
			},
		},
	},
	Gems = {
		CanPurchase = false,
		Color = Color3.fromRGB(228, 168, 255),
	},
} :: { [Types.Currency]: Types.CurrencyData }
