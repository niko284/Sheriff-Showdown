local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Network = ReplicatedStorage.network
local Serde = Network.serde
local Middleware = Network.middleware

local Actions = require(ReplicatedStorage.ecs.actions)
local Deserializer = require(Middleware.Deserializer)
local Net = require(Packages.Net)
local UUIDSerde = require(Serde.UUIDSerde)
local t = require(Packages.t)

return Net.CreateDefinitions({
	Combat = Net.Definitions.Namespace({
		ProcessAction = Net.Definitions.ClientToServerEvent({
			Net.Middleware.TypeChecking(t.interface({
				action = t.keyOf(Actions),
			})),
		}),
		VisualizeEffect = Net.Definitions.ServerToClientEvent(),
	}),
	Rewards = Net.Definitions.Namespace({
		ClaimDailyReward = Net.Definitions.ServerAsyncFunction({}),
	}),
	Achievements = Net.Definitions.Namespace({
		ClaimAchievement = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
		GetAchievements = Net.Definitions.ServerAsyncFunction(),
		AchievementsChanged = Net.Definitions.ServerToClientEvent(),
	}),
	Round = Net.Definitions.Namespace({
		StartMatch = Net.Definitions.ServerToClientEvent(),
		EndMatch = Net.Definitions.ServerToClientEvent(),
		ApplyTeamIndicator = Net.Definitions.ServerToClientEvent(),
		SendDistraction = Net.Definitions.ServerToClientEvent(),
	}),
	Voting = Net.Definitions.Namespace({
		ProcessVote = Net.Definitions.ClientToServerEvent({
			Net.Middleware.TypeChecking(t.string, t.string), -- voting field name and voting choice
		}),
	}),
	Inventory = Net.Definitions.Namespace({
		ItemAdded = Net.Definitions.ServerToClientEvent(),
		ItemRemoved = Net.Definitions.ServerToClientEvent(),
		LockItem = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
		UnlockItem = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
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
		ToggleItemFavorite = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string, t.boolean),
			Deserializer({ UUIDSerde }),
		}),
		OpenCrate = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
	}),
	Shop = Net.Definitions.Namespace({
		SubmitCode = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
		}),
		PurchaseCrate = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string, t.numberMin(1)),
		}),
	}),

	Notifications = Net.Definitions.Namespace({
		AddNotification = Net.Definitions.ServerToClientEvent(),
		RemoveNotification = Net.Definitions.ServerToClientEvent(),
	}),

	Trading = Net.Definitions.Namespace({
		TradeCompleted = Net.Definitions.ServerToClientEvent(),
		TradeReceived = Net.Definitions.ServerToClientEvent(),
		TradeProcessed = Net.Definitions.ServerToClientEvent(),
		SendTradeToPlayer = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.instanceIsA("Player")),
		}),
		AcceptTradeRequest = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
		DeclineTradeRequest = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
		AddItemToTrade = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string, t.string),
			Deserializer({ UUIDSerde, UUIDSerde }),
		}),
		RemoveItemFromTrade = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string, t.string),
			Deserializer({ UUIDSerde, UUIDSerde }),
		}),
		AcceptTrade = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
		DeclineTrade = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
		ConfirmTrade = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
			Deserializer({ UUIDSerde }),
		}),
	}),

	Settings = Net.Definitions.Namespace({
		ChangeSetting = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(
				t.string,
				t.union(t.boolean, t.string, t.number, t.map(t.string, t.boolean), t.map(t.string, t.string))
			),
		}),
	}),
})
