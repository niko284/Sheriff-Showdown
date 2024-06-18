local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

local Items: { Types.ItemInfo } = {
	{
		Id = 1,
		Name = "Blue Hyper Laser",
		Image = 16514390321,
		Type = "Gun",
		Rarity = "Legendary",
		GunStatisticalData = {
			BulletSpeed = 100,
			BulletSoundId = 130113322,
		},
	},
	{
		Id = 2,
		Name = "Default",
		Type = "Gun",
		Rarity = "Basic",
		Image = 16381222990,
		GunStatisticalData = {
			BulletSoundId = 1905367471,
		},
		Default = true,
	},
	{
		Id = 3,
		Name = "Halo",
		Type = "Gun",
		Rarity = "Exotic",
		Image = 16410415588,
	},
	{
		Id = 4,
		Name = "Zombie Launcher",
		Type = "Gun",
		Rarity = "Exotic",
		Image = 17475397607,
		GunStatisticalData = {
			BulletSoundId = 30324676,
		},
	},
	{
		Id = 5,
		Name = "Bugged",
		Type = "Gun",
		Rarity = "Exotic",
		Image = 17826514316,
	},
}

return Items
