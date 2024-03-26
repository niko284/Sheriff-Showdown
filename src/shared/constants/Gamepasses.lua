--!strict
-- Gamepasses
-- March 9th, 2024
-- Nick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

return {
	{
		GamepassId = 738532594,
		Name = "Multiple Crates",
	},
} :: { Types.GamepassInfo }
