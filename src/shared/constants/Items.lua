export type ItemRarity = "Basic" | "Rare" | "Epic" | "Legendary" | "Exotic"
export type ItemType = "Gun"

type ItemGunData = {
	GunStatisticalData: any,
}
export type ItemInfo = {
	Id: number,
	Name: string,
	Rarity: ItemRarity,
	Type: ItemType,
	Image: number?,
} & ItemGunData

local Items: { ItemInfo } = {
	{
		Id = 1,
		Name = "Blue Hyper Laser",
		Image = 16514390321,
		Type = "Gun",
		Rarity = "Legendary",
		GunStatisticalData = {
			BulletSpeed = 100,
		},
	},
}

return Items
