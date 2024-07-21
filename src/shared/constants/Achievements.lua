--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	{
		Id = 1,
		Type = "Daily",
		Requirements = {
			{
				BaseName = "Get 10 Wins",
				Action = "Statistic",
				Statistic = "TotalWins",
				Goal = 10,
				Progress = 0,
				UseDelta = true, -- This will take the difference between the current and previous value to increment our progress by instead of just setting it to the new value.
			},
		},
		Rewards = {
			{
				Type = "Currency",
				Currency = "Coins",
				Amount = 150,
			},
		},
	},
} :: { Types.AchievementInfo }
