local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.packages.Comm)
local Matter = require(ReplicatedStorage.packages.Matter)
local React = require(ReplicatedStorage.packages.React)
local Signal = require(ReplicatedStorage.packages.Signal)

export type ItemRarity = "Basic" | "Rare" | "Epic" | "Legendary" | "Exotic"
export type ItemType = "Gun" | "Crate"
type ItemGunData = {
	GunStatisticalData: any,
}
export type ItemInfo = {
	Id: number,
	Name: string,
	Rarity: ItemRarity?,
	Type: ItemType,
	Image: number,
	Default: (boolean | (Player) -> boolean)?,
	TagWithSerial: boolean?,
	CanTrade: boolean?, -- some guns can't be traded even if they're of an item type that can be traded (like your default gun)
} & ItemGunData

export type ItemTypeInfo = {
	UniqueProps: { [string]: any }?,
	CanEquip: boolean,
	CanSell: boolean,
	CanTrade: boolean,
	EquippedAtOnce: (number | (ItemInfo) -> number)?,
}

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
export type PlayerResources = {
	Coins: number,
	Gems: number,
	Level: number,
	Experience: number,
}
export type PlayerStatistics = {}
export type PlayerAchievements = {
	LastDailyRotation: number,
	ActiveAchievements: { Achievement },
}

export type DataSchema = {
	Inventory: PlayerInventory,
	Resources: PlayerResources,
	CodesRedeemed: { string },
	Settings: PlayerDataSettings,
	ProcessingTrades: { ProcessingTrade },
	Statistics: PlayerStatistics,
	Achievements: PlayerAchievements,
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

export type RoundMode = "Singles" | "Duos" | "Distraction" | "Free For All" | "Red vs Blue" | "Revolver Relay"
export type RoundModeData = {
	Name: RoundMode,
	TeamSize: ((() -> number) | number)?,
	TeamsPerMatch: ((() -> number) | number)?,
	TeamNames: { string }?,
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
	AllocateMatches: (({ Player }) -> { Match })?,
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
export type AfterProcessFn<T> = (world: Matter.World, player: Player, actionPayload: T) -> ()

-- >> action types ecs
export type GenericPayload = {
	action: string,
	actionId: string,
}

export type Action<T> = {
	process: (world: Matter.World, player: Player, actionPayload: T) -> (),
	middleware: { MiddlewareFn<T> }?,
	validatePayload: (sentPayload: any) -> boolean,
	afterProcess: { AfterProcessFn<T> },
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

export type Interface =
	"Shop"
	| "Inventory"
	| "GiftingSelection"
	| "Settings"
	| "Voting"
	| "Trading"
	| "ActiveTrade"
	| "TradeProcessed"
	| "Achievements"

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
	PurchaseMethods: {
		{
			Type: "Coins" | "Gems" | "Robux",
			Price: number?,
			ProductId: number?,
		}
	},
	Weights: { [ItemRarity]: number },
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

export type ShopContext = {
	giftRecipient: Player?,
	crateToView: Crate?,
}

export type TradeStatus = "Confirming" | "Pending" | "Started" | "Completed"
export type Trade = {
	Sender: Player,
	Receiver: Player,
	SenderOffer: { Item },
	ReceiverOffer: { Item },
	Accepted: { Player },
	Confirmed: { Player },
	UUID: string,
	Status: TradeStatus,
	MaximumItems: number,
	CooldownEnd: number?,
}

export type ProcessingTrade = {
	Giving: { Item },
	Receiving: { Item },
	TradeUUID: string,
}

export type ServerRemoteProperty = typeof(Comm.ServerComm.new(Instance.new("Folder")):CreateProperty(nil, "string"))

-- >> Notification Types

export type Notification = {
	Title: string,
	Description: string,
	UUID: string,
	Duration: number,
	Component: React.ComponentType<any>,
	Props: { [string]: any }?,
	ClickToDismiss: boolean?,
	OnFade: (() -> ())?,
	OnDismiss: (() -> ())?,
}
export type NotificationElementPropsGeneric = {
	creationTime: number,
	padding: UDim,
	removeNotification: (string) -> (),
	closeNotification: (string) -> (),
	onFade: () -> (),
	onDismiss: () -> (),
	title: string,
	id: string,
	duration: number,
	clickToDismiss: boolean,
	description: string,
	isActive: boolean,
}

export type AchievementReward = {
	Type: "Currency" | "Item" | "Badge",
	Currency: Currency,
	ItemId: number?, -- only used if we're giving an item as a reward
	BadgeId: number?, -- only used if we're giving a badge as a reward
	Amount: number | (claimCount: number) -> number,
}

export type AchievementType = "Progressive" | "Daily" | "Event"
export type AchievementRequirementAction = "Resource" | "Statistic" | "Custom" | "Signal"

export type AchievementRequirementInfo = {
	BaseName: string,

	Action: AchievementRequirementAction,
	[AchievementRequirementAction]: string | (
		Achievement
	) -> string | {
		SignalInstance: Signal.Signal<...any>,
		Filter: (Achievement, Player, ...any) -> boolean,
		Name: string,
	},
	Resource: string?,
	Statistic: string?,

	Signal: { SignalInstance: Signal.Signal<...any>, Filter: (...any) -> boolean, Name: string }?, -- repeat of the above, but so we can index .Signal directly.

	Increment: number? | ((number) -> number)?,
	ResetProgressOnIncrement: boolean?,
	UseDelta: boolean?, -- do we take the difference between the current value and the previous value as our increment?
	Progress: number?,
	Goal: number | (Achievement) -> number,
	Maximum: number?,

	StrokeColor: Color3?,
}

export type AchievementInfo = {
	Id: number,
	Type: string,
	GetUniqueProps: ((Player: Player, PlayerData: DataSchema) -> { [string]: any })?,
	ExpirationTime: number?,
	Requirements: { AchievementRequirementInfo },
	Rewards: { AchievementReward },
	Deprecated: boolean?,
}

export type AchievementRequirement = {
	Progress: number, -- How much progress we have made towards our goal?
	Goal: number, -- How much progress we need to make to complete our goal?
}
export type Achievement = {
	Id: number,
	TimesClaimed: number,
	UUID: string,
	Claimed: boolean, -- Was our achievement claimed?
	Requirements: { AchievementRequirement }, -- Our requirements
}

export type Character = {
	Humanoid: Humanoid,
	PrimaryPart: BasePart,
	HumanoidRootPart: BasePart,
} & { [string]: any }

export type PlayerChildren = {
	gunEntityId: number?,
	waistRenderableGunId: number?,
}

export type GunChildren = {
	handRenderableId: number?,
}

return nil
