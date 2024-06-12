local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

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

export type RoundMode = "Singles" | "Duos" | "Distraction"
export type RoundModeData = {
	Name: RoundMode,
	TeamSize: number,
	TeamsPerMatch: number,
	TeamNames: { string },
}
export type Team = {
	Entities: { number }, -- list of entity ids in this team.
	Killed: { number }, -- list of entity ids that have been killed in this team.
	Name: string,
}
export type Match = {
	Teams: { Team },
	MatchUUID: string,
}
export type Round = {
	Matches: { Match },
	RoundMode: RoundMode,
	Players: { Player },
	Map: Folder,
}
export type RoundModeExtension = {
	IsGameOver: (Round) -> boolean,
	StartMatch: (Match, Round, Matter.World) -> (),
	Data: RoundModeData,
	ExtraRoundProperties: { [string]: any },
	ExtraMatchProperties: { [string]: any },
}

export type VotingPoolField = {
	Choices: { string },
	Votes: { [Player]: string },
}
export type VotingPool = {
	Maps: VotingPoolField,
	RoundModes: VotingPoolField,
}

-- just the choices for each voting pool field
export type VotingPoolClient = {
	VotingEndTime: number,
	VotingFields: { -- we keep this as an array because it's easier for the client to route through each field and display it.
		{
			Field: string,
			Choices: {
				{
					Name: string,
					Image: number,
				}
			},
		}
	},
}

export type Distraction = "Car" | "Eagle" | "Draw"
export type DistractionData = {
	AudioId: number,
}

export type TeamData = {
	Color: Color3,
}

export type Status = "Killed" | "Slowed"

export type FrameProps = {
	anchorPoint: Vector2?,
	autoButtonColor: boolean?,
	active: boolean?,
	backgroundColor3: Color3?,
	backgroundTransparency: number?,
	borderSizePixel: number?,
	size: UDim2?,
	position: UDim2?,
	sizeConstraint: Enum.SizeConstraint?,
	visible: boolean?,
	zIndex: number?,
	layoutOrder: number?,
	clipsDescendants: boolean?,
	rotation: number?,
}

export type MiddlewareFn<T> = (world: Matter.World, player: Player, actionPayload: T) -> boolean

-- >> action types ecs
export type GenericPayload = {
	action: string,
	actionId: string,
}

export type Action<T> = {
	process: (world: Matter.World, player: Player, actionPayload: T) -> (),
	middleware: { MiddlewareFn<T> }?,
	validatePayload: (sentPayload: any) -> boolean,
}

export type VisualEffect<T> = {
	name: string,
	visualize: (world: Matter.World, effectPayload: T) -> (),
}

return nil
