local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Actions = require(ReplicatedStorage.ecs.actions)
local Net = require(Packages.Net)
local t = require(Packages.t)

return Net.CreateDefinitions({
	Combat = Net.Definitions.Namespace({
		ProcessAction = Net.Definitions.ClientToServerEvent({
			Net.Middleware.TypeChecking(t.interface({
				action = t.keyOf(Actions),
			})),
		}),
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
})
