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
	},
}

return Items
