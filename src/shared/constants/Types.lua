-- Types
-- January 22nd, 2024
-- Nick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local JanitorModule = require(Packages.Janitor)
local Net = require(Packages.Net)
local Promise = require(Packages.Promise)
local Signal = require(Packages.Signal)

-- >> Network Types

export type NetworkResponse = {
	Success: boolean,
	Response: any,
} & { [string]: any } -- other key/value pairs

-- >> Audio Types

export type Audio = {
	AudioId: string,
	Looped: boolean,
	Volume: number?,
	SoundGroupName: string?,
	Materials: { string }?,
}

-- >> Transaction Types

export type ProductReceipt = {
	PurchaseId: string,
	PlayerId: number,
	ProductId: number,
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType,
	PlaceIdWherePurchased: number,
}
export type PurchaseType = "Gems" | "Coins" | "Robux"
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
export type GamepassInfo = {
	GamepassId: number,
	Name: string,
}

-- >> Crate Types

export type CratePurchaseInfo = {
	ProductId: number?, -- for robux
	Price: number?, -- for gems and coins
	PurchaseType: PurchaseType,
}
export type CrateInfo = {
	OpenAnimation: number,
	ShopImage: number,
	ShopLayoutOrder: number,
	ItemContents: { string },
	PurchaseInfo: { CratePurchaseInfo },
}
export type CrateType = "Standard" | "Standard"

-- >> Rarity Types

export type Rarity = "Basic" | "Rare" | "Epic" | "Legendary" | "Exotic"
export type RarityInfo = {
	Color: Color3,
	Weight: number,
	TagWithSerial: boolean,
}

-- >> Item Types

export type ItemType = "Gun"
export type WeaponStyle = "OneHandedDefault"
type ItemWeaponInfo = {
	Style: WeaponStyle,
	ShootAudio: number?,
}
export type ItemInfo = {
	Name: string,
	Featured: boolean,
	Rarity: Rarity,
	Image: number,
	Id: number,
	Type: ItemType,
	Default: (boolean | (Player) -> boolean)?,
	EquipOnDefault: boolean?, -- do we equip the item as soon as it is granted?
} & ItemWeaponInfo
export type Item = {
	Id: number,
	UUID: string,
	Favorited: boolean,
	Locked: boolean,
	Serial: number?,
	Level: number?,
} & {
	[string]: any, -- This is for unique props like StatisticMultipliers, etc.
}

-- >> Package Types

export type Signal = Signal.Signal<any>
export type Janitor = JanitorModule.Janitor
export type Promise = typeof(Promise.new())

-- >> Action Types

export type ActionState = "Draw" | "Bird" | "Mikey"

-- >> Frame Types

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

-- >> Popup Types

export type ActionPopup = {
	State: ActionState,
}

-- >> Inventory Types

export type Inventory = {
	Items: { Item },
	Equipped: { string },
	Capacity: number,
	GrantedDefaults: { number },
}

-- >> Setting Types

export type SettingValue = boolean | string | number
export type SettingType = "Keybind" | "Slider" | "Toggle" | "Dropdown" | "List"
export type Device = "Touch" | "Gamepad" | "MouseKeyboard"
export type SettingChoiceInfo = {
	Color: Color3,
	LayoutOrder: number,
}
export type Setting = {
	Name: string,
	Type: SettingType,
	Category: string,
	Icon: string,
	Default: { [Device]: string } | number | boolean | string, -- Keybinds, sliders, toggles, dropdowns respectively.
	Choices: { string }?, -- List setting type
	ChoiceColors: { [string]: Color3 }?, -- List setting type
	ChoiceInfo: { [string]: SettingChoiceInfo }?, -- List setting type
	Maximum: number?,
	Minimum: number?,
	Increment: number?,
	Selections: { string }?, -- Dropdowns
	ActionItemType: string?,
	ActionItemNumber: number?,
	ShowInMenu: boolean?,
}

-- >> Data Types

export type SettingInternal = {
	Value: SettingValue,
}

export type PlayerDataSettings = {
	[string]: SettingInternal | {
		-- our nested key string here is our device type for keybind settings
		[string]: SettingInternal,
	},
}

export type PlayerData = {
	Resources: { [string]: any },
	Inventory: Inventory,
	Settings: PlayerDataSettings,
}

-- >> Round Types

export type RoundMode = "Singles" | "Duos"
export type RoundModeData = {
	Name: RoundMode,
	TeamSize: number,
	TeamsPerMatch: number,
	TeamNames: { string },
}
export type Team = {
	Players: { Player }, -- list of players in this team.
	Killed: { Player }, -- list of players eliminated from the round in this team.
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

-- >> Map Types

export type Map = {
	Name: string,
	Image: number,
}

-- >> Action System Types

type Action = {
	StateInternal: ActionStateInfo?,
	Processes: {},
	Events: { [string]: BindableEvent },
}

export type ActionStateMetaData = { [string]: any }

-- >> Entity Types

export type Entity = Model & { HumanoidRootPart: BasePart, Humanoid: Humanoid }
export type EntityStatus = "Killed"
export type EntityStatusState = {
	Status: EntityStatus,
	EndMillis: number?,
}
export type ActionStateInfo = {
	Finished: boolean,
	TimestampMillis: number,
	Interruptable: boolean,
	GlobalCooldownFinishTimeMillis: number,
	CooldownFinishTimeMillis: number,
	ActionHandlerName: string,
	CancelPreviousAction: boolean?,
	Sustaining: boolean,
	Priority: string,
	ActionSpecific: {
		Combo: number?,
		Direction: string?,
		MaxCombo: number?,
		BeforeSpeed: number?,
		Target: Entity?,
		[string]: any,
	},
	UUID: string,
	MetaData: ActionStateMetaData?,
}

export type EntityState = {
	DefenseLevel: number,
	AttackLevel: number,
	ActionHistory: { [string]: ActionStateInfo },
	LastActionState: ActionStateInfo?,
	Statuses: { [EntityStatus]: EntityStatusState },
}

-- >> Style Types

export type AnimationInfo = {
	StyleDictionary: Style,
	StyleName: string,
	CurrentPassive: Animation?,
	PlayingTrack: AnimationTrack?,
	Animations: { [Animation]: AnimationTrack },
}
export type PlayingAnimation = {
	Animation: Animation,
	Track: AnimationTrack,
	AnimationId: number,
}

export type StylesTable = { [string]: Style }
export type Style = {
	PassiveAnimations: {
		walk: Animation?,
		run: Animation?,
		idle: Animation?,
		fall: Animation?,
		jump: Animation?,
		climb: Animation?,
	}?,
	LightAttack: { Animation }?,
	HeavyAttack: Animation?,
	Block: Animation?,
	BlockBroken: Animation?,
	Parried: Animation?,
	Grip: Animation?,
	GotGripped: Animation?,
	Pulling: Animation?,
	FishingIdle: Animation?,
	Cast: Animation?,
	Dodge: {
		Front: Animation?,
		Right: Animation?,
		Left: Animation?,
		Back: Animation?,
	}?,
	Abilities: {
		[string]: Animation,
	}?,
	Death: Animation?,
	CasterCombos: { { string } }?,
}

-- >> Hit Types

export type HitProps = {
	DelayedDamage: { DelayedDamageProps }?,
	Initial: GenericHitProps,
	StoreInHitQueue: boolean?, -- Do we store the entity we hit in a hit queue for later processing? (used for things like animation marker damage), where we want synced damage.
}
export type Verifier = "Zone" | "Caster" | "Projectile" | "Decay"
export type CasterEntry = {
	HitPart: PVInstance?,
	RaycastResult: RaycastResult?,
	Entity: Entity?,
	HitPosition: Vector3?,
	DetectionType: Verifier,
	ZoneCFrame: CFrame?,
	Timestamp: number?,
}
export type VFXArguments = {
	CFrame: CFrame?,
	Actor: Entity?,
	HitPart: Instance?,
	State: ActionStateInfo?,
	TargetEntity: Entity?,
	ArgPack: ProcessArgs?, -- LOCAL CLIENT USE ONLY,
	[string]: any, -- any other key/value pairs.
}
export type GenericHitProps = {
	ParryTime: number?,
	CanBlockBreak: boolean?,
	CanKnock: ((
		TargetEntity: Entity,
		ActorEntity: Entity,
		TargetState: EntityState,
		ActorState: EntityState
	) -> (boolean?, number?))?,
	RegisterWhileActorStunned: boolean?,
	NoStun: (boolean | (Entity, Entity, EntityState, EntityState) -> boolean)?,
	ApplyCustomStatus: ((TargetEntity: Entity, ActorEntity: Entity) -> ())?,
}

export type DelayedDamageProps = {
	Delay: number,
	BaseDamage: number?,
} & GenericHitProps -- GeneralHitProps are also in delayed damage and dealt with separately from the initial hit.
export type HitVerifier = (CasterEntry) -> boolean
export type InputType = "Touch" | "Gamepad" | "MouseKeyboard"

-- >> Status Types

export type StatusData = {
	Name: EntityStatus,
	DurationMillis: number?,
	CompatibleStatuses: ({ EntityStatus } | boolean)?, -- If true, all statuses are compatible with this one.
	-- If false, no statuses are compatible with this one. If a table, only the statuses in the table are compatible with this one.
	OverlapWithSelf: boolean?, -- If true, this status can overlap with itself (extend the duration of itself if re-applied).
	Exceptions: { EntityStatus }?, -- If a status is in this table, it will not be cleared when this status is applied.
}

export type StatusHandler = {
	Data: StatusData,
	Apply: (Entity) -> (boolean, Janitor?),
	ApplyFX: ((Entity) -> boolean)?,
	Clear: (Entity, Janitor?) -> boolean,
	Process: ((Entity, EntityState) -> ())?,
	ProcessClient: ((Entity, EntityState) -> ())?,
}

-- >> Handler Types

export type Handlers = {
	[string]: ActionHandler,
}
export type ProcessArgs = {
	Entity: Entity,
	EntityIsPlayer: boolean,
	Store: { [string]: any },
	HitVerifiers: { [string]: HitVerifier },
	Callbacks: {
		[string]: (any) -> any,
		MetaDataBuilder: ((ProcessArgs, ActionStateInfo) -> { [string]: any })?,
		VerifyActionPayload: ((actionPayload: { [string]: any }) -> boolean)?,
		VerifyHits: ((ArgPack: ProcessArgs, VerifierType: Verifier, Entry: CasterEntry) -> boolean)?,
	},
	Janitor: Janitor,
	HandlerData: ActionHandlerData,
	Handler: ActionHandler,
	Finished: Signal.Signal<boolean, string, boolean?>,
	Interfaces: { Client: Interface, Server: Interface, Comm: { [string]: any } },
	InputObject: InputObject?, -- LOCAL CLIENT USE ONLY
	ActionPayload: {
		[string]: any,
	}?,
}

export type Delegate = (ProcessArgs, ActionStateInfo) -> (boolean, string?)

export type Process = {
	ProcessName: string,
	OnServer: boolean,
	OnClient: boolean,
	OnAI: boolean?, -- If true, process will run on AI entities on the server.
	Async: boolean,
	Delegate: Delegate,
}
export type ActionSettingsData = {
	InputData: {
		[InputType]: { Enum.UserInputType | Enum.KeyCode | Enum.SwipeDirection }
			| (Enum.UserInputType | Enum.KeyCode | Enum.SwipeDirection)?,
	}?,
	Held: ({ Enum.KeyCode } | true)?,
	DoubleTap: { Enum.KeyCode }?,
	Name: string,
	Icon: string?,
}
export type ActionHandlerData = {
	Name: string,
	GlobalCooldownMillis: number,
	CooldownMillis: number,
	Interruptable: boolean?, -- can this action be stopped by status effects?
	OverlappableActions: { string }?, -- can any action keep playing while this one is playing?
	BaseDamage: number? | ((CasterEntry) -> number)?,
	AttackLevel: number?,
	DefenseLevel: number?,
	Cancellable: boolean?,
	AlwaysOn: (() -> boolean)?,
	IsBaseAction: boolean,
	ServerFinish: boolean?, -- If true, action finishes on server.
	Sustained: boolean,
	Priority: string,
	SettingsData: ActionSettingsData,
}
export type ActionHandler = {
	Data: ActionHandlerData,
	Callbacks: { [string]: (...any) -> ...any }, -- note we use the variadic type here because we don't know the number of arguments per callback
	ProcessStack: { VerifyStack: { Process }, ActionStack: { Process } },
}
export type Interface = { [string]: { [any]: any } }

-- >> Shop Interface Types

export type ShopViewInfo = {
	Name: string,
	Image: number,
	Type: "Crate" | "Item",
}

-- >> Currency Types

export type Currency = "Gems" | "Coins"
export type CurrencyInfo = {
	Image: number,
	GradientColor: ColorSequence,
}

-- >> Net Types

export type ServerNamespace = {
	Get: (
		self: ServerNamespace,
		name: string
	) -> Net.ServerSenderEvent & Net.ServerListenerEvent & Net.ServerAsyncCallback & Net.ServerAsyncCaller,
}

export type ClientNamespace = {
	Get: (
		self: ClientNamespace,
		name: string
	) -> Net.ClientAsyncCallback & Net.ClientAsyncCaller & Net.ClientSenderEvent & Net.ClientListenerEvent,
}

export type ServerDefinitionBuilder = {
	GetNamespace: (self: ServerDefinitionBuilder, namespace: string) -> ServerNamespace,
}

export type ClientDefinitionBuilder = {
	GetNamespace: (self: ClientDefinitionBuilder, namespace: string) -> ClientNamespace,
}

export type DefinitionBuilder = {
	Server: ServerDefinitionBuilder,
	Client: ClientDefinitionBuilder,
}

-- >> Serializer Types

export type Serializer = {
	Serialize: (any) -> string,
	Deserialize: (string) -> any,
}
export type NextMiddleware = (Player: Player, ...any) -> any

-- >> Notification Types

export type NotificationType = "Toast" | "Text"
export type Notification = {
	Title: string?,
	Description: string,
	UUID: string,
	Duration: number,
	ClickToDismiss: boolean?,
	Options: { any }?,
	OnFade: (() -> ())?,
	OnDismiss: (() -> ())?,
	OnHeartbeat: (() -> string)?,
}

-- >> Voting Types

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

return {}
