--!strict
-- Distractions (for the distraction Round Mode)
-- Nick
-- April 13th, 2024

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

return {
	Car = {
		AudioId = 5945905639,
	},
	Eagle = {
		AudioId = 491270608,
	},
	Draw = {
		AudioId = 240784215,
	},
} :: { [Types.Distraction]: Types.DistractionData }
