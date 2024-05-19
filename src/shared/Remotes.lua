local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Actions = require(ReplicatedStorage.constants.Actions)
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
})
