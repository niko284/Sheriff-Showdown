-- Remote Definitions
-- August 17th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Middleware = ReplicatedStorage.middleware
local Serde = ReplicatedStorage.serde

local Deserializer = require(Middleware.Deserializer)
local Net = require(Packages.Net)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)
local t = require(Packages.t)

local detectionTypeChecker = t.union(t.literal("Zone"), t.literal("Caster"), t.literal("Projectile"))

local Definitions = Net.CreateDefinitions({

	Transactions = Net.Definitions.Namespace({
		PurchaseCrates = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string, t.string, t.numberPositive),
		}),
	}),

	Round = Net.Definitions.Namespace({
		StartMatchCountdown = Net.Definitions.ServerToClientEvent(),
	}),

	Inventory = Net.Definitions.Namespace({
		ItemAdded = Net.Definitions.ServerToClientEvent(),
		ItemRemoved = Net.Definitions.ServerToClientEvent(),
		FavoriteItem = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string, t.boolean),
			Deserializer({ UUIDSerde }),
		}),
		EquipItem = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
		UnequipItem = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
	}),

	Settings = Net.Definitions.Namespace({
		ChangeSetting = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string, t.union(t.boolean, t.string, t.number, t.map(t.string, t.boolean))),
		}),
	}),

	Voting = Net.Definitions.Namespace({
		ProcessVote = Net.Definitions.ClientToServerEvent({
			Net.Middleware.TypeChecking(t.string, t.string), -- voting field name and voting choice
		}),
	}),

	Notifications = Net.Definitions.Namespace({
		AddNotification = Net.Definitions.ServerToClientEvent(),
		RemoveNotification = Net.Definitions.ServerToClientEvent(),
	}),

	Entity = Net.Definitions.Namespace({
		ClientReady = Net.Definitions.ServerToClientEvent(),
		StateChanged = Net.Definitions.ServerToClientEvent(),
		FinishedClient = Net.Definitions.ClientToServerEvent(),
		FinishedServer = Net.Definitions.ServerToClientEvent(),
		ProcessFX = Net.Definitions.ServerToClientEvent(),
		ProcessStatus = Net.Definitions.ServerToClientEvent(),
		ProcessStatusFX = Net.Definitions.ServerToClientEvent(),
		ProcessAction = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string, t.string, t.optional(t.table)),
			Deserializer({ nil, UUIDSerde }),
		}),
		ProcessHit = (Net.Definitions :: any).BidirectionalEvent({
			Net.Middleware.TypeChecking(
				t.strictInterface({
					HitPart = t.optional(t.instanceIsA("BasePart")),
					RaycastResult = t.optional(t.RaycastResult),
					Entity = t.instanceIsA("Model"),
					DetectionType = detectionTypeChecker,
				}),
				t.optional(t.string)
			),
		}),
		ProcessServerEffect = Net.Definitions.ClientToServerEvent({
			Net.Middleware.TypeChecking(t.string),
		}),
		StopHits = Net.Definitions.ClientToServerEvent({
			Net.Middleware.TypeChecking(t.string, detectionTypeChecker),
			Deserializer({ UUIDSerde }),
		}),
		OnHit = Net.Definitions.ServerToClientEvent(),
	}),
} :: any)

return Definitions :: Types.DefinitionBuilder
