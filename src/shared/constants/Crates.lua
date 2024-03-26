--!strict
-- Crates
-- February 19th, 2024
-- Nick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

return {
	Standard = {
		OpenAnimation = 16440704773,
		ShopLayoutOrder = 1,
		ShopImage = 16417980472,
		ItemContents = {
			"Halo",
			"Water",
			"Holographic",
			"Obsidian",
			"Line",
			"Aqua",
			"Oil Slick",
			"Grain",
			"Scorched",
			"Point",
			"Rose",
			"Crimson",
			"Sun",
			"White",
			"Grayscale",
			"Pixel",
		},
		PurchaseInfo = {
			{
				PurchaseType = "Gems",
				Price = 100,
			},
			{
				PurchaseType = "Coins",
				Price = 100,
			},
		},
	},
	Classic = {
		OpenAnimation = 16440704773,
		ShopLayoutOrder = 2,
		ShopImage = 16560968952,
		ItemContents = {
			"Luger",
			"Blue Hyper Laser",
			"Red Hyper Laser",
			"Laser Pistol",
			"Laser Gun",
			"Assault Laser",
			"Space Ray Gun",
			"Orange Paintball Gun",
			"Magenta Paintball Gun",
			"Green Paintball Gun",
			"Blue Paintball Gun",
			"Red Paintball Gun",
			"Pirate's Flintlock",
			"Cowboy Pistol",
			"Revolver",
			"Colt 45",
		},
		PurchaseInfo = {
			{
				PurchaseType = "Gems",
				Price = 100,
			},
			{
				PurchaseType = "Coins",
				Price = 100,
			},
		},
	},
} :: { [Types.CrateType]: Types.CrateInfo }
