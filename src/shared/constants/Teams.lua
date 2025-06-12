--!strict

local Types = require("@constants/Types")

return {
	Red = {
		Color = Color3.fromRGB(255, 0, 0),
	},
	Blue = {
		Color = Color3.fromRGB(0, 0, 255),
	},
} :: { [string]: Types.TeamData }
