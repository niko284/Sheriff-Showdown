--!strict

local Types = require("@constants/Types")

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
