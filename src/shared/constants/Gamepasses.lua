--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	{
		GamepassId = 52316442,
		Featured = true,
	},
	{
		GamepassId = 52316520,
		Featured = true,
	},
	{
		GamepassId = 52316801,
		Featured = false,
	},
	{
		GamepassId = 52316852,
		Featured = false,
	},
	{
		GamepassId = 52316881,
		Featured = false,
	},
	{
		GamepassId = 52316915,
		Featured = false,
	},
} :: { Types.Gamepass }
