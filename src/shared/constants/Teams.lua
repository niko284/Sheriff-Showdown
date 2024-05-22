-- Teams
-- May 3rd, 2024
-- Nick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

return {
	Red = {
		Color = Color3.fromRGB(255, 0, 0),
	},
	Blue = {
		Color = Color3.fromRGB(0, 0, 255),
	},
} :: { [string]: Types.TeamData }
