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
	TagWithSerial: boolean?,
} & ItemGunData
export type Item = {
	Id: number,
	UUID: string,
	Locked: boolean?,
	Serial: number?,
	Level: number?,
}

export type RarityInfo = {
	TagWithSerial: boolean,
}

export type DataSchema = {
	Inventory: {
		Storage: { Item },
		Equipped: { Item },
	},
	Resources: {
		Coins: number,
		Gems: number,
		Level: number,
		Experience: number,
	},
}

-- >> Leaderboard Types

export type LeaderboardValueType = "Resource" | "Statistic" -- Leaderboard value types
export type LeaderboardEntry = {
	key: string, -- Where key is the player's userId
	value: number, -- Where value is the player's datastore value
}
export type LeaderboardInfo = {
	LeaderboardName: string,
	DisplaySlots: number,
	ValueType: LeaderboardValueType,
	LeaderboardKey: string | () -> string,
	DisplayName: string?, -- If nil, uses LeaderboardName
	DisplayColor: Color3?,
	Resource: string?,
	Statistic: (string | { string })?,
	RewardItems: {
		{
			ItemName: string,
			MinimumPlacement: number,
		}
	}?,
	Mapper: ((...any) -> any)?, -- A function that maps the value to a different value
}

return nil
