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
	}),
	Shop = Net.Definitions.Namespace({
		SubmitCode = Net.Definitions.ServerAsyncFunction({
			Net.Middleware.TypeChecking(t.string),
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
