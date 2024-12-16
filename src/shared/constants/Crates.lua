--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

return {
	Standard = {
		OpenAnimation = 103475632191659,
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
		PurchaseMethods = {
			{
				Type = "Coins",
				Price = 100,
			},
		},
		Weights = {
			Basic = 50,
			Rare = 25,
			Epic = 15,
			Legendary = 8,
			Exotic = 2,
		},
	},
	Classic = {
		OpenAnimation = 103475632191659,
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
		PurchaseMethods = {
			{
				Type = "Coins",
				Price = 100,
			},
		},
		Weights = {
			Basic = 50,
			Rare = 25,
			Epic = 15,
			Legendary = 8,
			Exotic = 2,
		},
	},
} :: { [Types.Crate]: Types.CrateInfo }
