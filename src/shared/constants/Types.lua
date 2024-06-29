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
	Image: number,
	Default: (boolean | (Player) -> boolean)?,
	TagWithSerial: boolean?,
} & ItemGunData

type GunProps = {
	Kills: number?,
}
export type Item = {
	Id: number,
	UUID: string,
	Locked: boolean,
	Favorited: boolean,
	Serial: number?,
	Level: number?,
} & GunProps

export type RarityInfo = {
	TagWithSerial: boolean,
	Color: Color3,
	Weight: number,
}

export type PlayerInventory = {
	Storage: { Item },
	Equipped: { Item },
	GrantedDefaults: { number }, -- list of item ids that the player has been granted by default (to avoid duplicates)
}
export type DataSchema = {
	Inventory: PlayerInventory,
	Resources: {
		Coins: number,
		Gems: number,
		Level: number,
		Experience: number,
	},
	CodesRedeemed: { string },
	Settings: PlayerDataSettings,
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

export type PlayerlistPlayer = {
	Player: Player,
	Level: number,
}

export type NetworkResponse = {
	Success: boolean,
	Message: string?,
}

export type Currency = "Coins" | "Gems"
export type CurrencyData = {
	CanPurchase: boolean,
	Color: Color3,
}

export type Interface = "Shop" | "Inventory" | "GiftingSelection" | "Settings" | "Voting"

export type ProductInfo = {
	Name: string,
	Description: string,
	PriceInRobux: number,
	Created: string,
	Updated: string,
	ContentRatingTypeId: number,
	MinimumMembershipLevel: number,
	IsPublicDomain: boolean,
	Creator: {
		CreatorType: "User" | "Group",
		CreatorTargetId: number,
		HasVerifiedBadge: boolean,
		Name: string,
		Id: number,
	},
	AssetId: number,
	AssetTypeId: number,
	IsForSale: boolean,
	IsLimited: boolean,
	IsLimitedUnique: boolean,
	IsNew: boolean,
	Remaining: number,
	Sales: number,
	SaleAvailabilityLocations: { Enum.ProductLocationRestriction },
	CanBeSoldInThisGame: boolean,
	ProductId: number,
	IconImageAssetId: number,
}

export type Crate = "Standard" | "Classic"
export type CrateInfo = {
	OpenAnimation: number,
	ShopImage: number,
	ShopLayoutOrder: number,
	ItemContents: { string },
}

export type Gamepass = {
	Featured: boolean,
	GamepassId: number,
}

-- >> Setting Types

export type SettingValue = boolean | string | number | KeybindMap
export type SettingType = "Slider" | "Toggle" | "Dropdown" | "List" | "Input" | "Keybind"
export type SettingChoiceInfo = {
	Color: Color3,
	LayoutOrder: number,
}
export type Setting = {
	Name: string,
	Description: string,
	Type: SettingType,
	Category: string,
	Icon: string,
	Default: SettingValue, --sliders, toggles, dropdowns/input respectively.
	Choices: { string }?, -- List setting type
	ChoiceColors: { [string]: Color3 }?, -- List setting type
	ChoiceInfo: { [string]: SettingChoiceInfo }?, -- List setting type
	Maximum: number?, -- sliders
	Minimum: number?, -- sliders
	Increment: number?, -- sliders
	Selections: { string }?, -- Dropdowns
	InputVerifiers: { (string) -> boolean }?, -- Input setting type
}

export type SettingInternal = {
	Value: SettingValue,
}

export type PlayerDataSettings = {
	[string]: SettingInternal,
}

export type DeviceType = "MouseKeyboard" | "Gamepad"
export type KeybindMap = {
	[DeviceType]: string,
}

return nil
