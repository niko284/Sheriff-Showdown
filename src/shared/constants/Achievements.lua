--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	{
		Id = 1,
		Type = "Progressive",
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
	{
		Id = 2,
		Type = "Progressive",
		Rewards = {
			{
				Type = "Currency",
				Currency = "Gems",
				Amount = 150,
			},
		},
		Requirements = {
			{
				BaseName = "Get [Goal] Kills",
				Action = "Custom",
				Custom = "EnemyKilled",
				Goal = function(achievement: any)
					return achievement.KillsToGet
				end, -- This is our base goal. We will increase this by 10 every time plr levels up on a player-level basis.
				UseDelta = true,
				Progress = 0,
			},
		},
		GetUniqueProps = function()
			local RNG = Random.new(os.time())
			local killsToGet = RNG:NextInteger(10, 20)
			return {
				KillsToGet = killsToGet, -- This will be a random number between 10 and 20.
			}
		end,
	},
	{
		Id = 3,
		Type = "Progressive",
		Rewards = {
			{
				Type = "Currency",
				Currency = "Coins",
				Amount = 150,
			},
		},
		Requirements = {
			{
				BaseName = "Trade [Goal] Items",
				Action = "Custom",
				Custom = "ItemsTraded",
				Goal = function(achievement: any)
					return achievement.ItemsToTrade
				end,
				UseDelta = true,
				Progress = 0,
			},
		},
		GetUniqueProps = function()
			local RNG = Random.new(os.time())
			local itemsToTrade = RNG:NextInteger(5, 10) -- This will be a random number between 5 and 10.
			return {
				ItemsToTrade = itemsToTrade,
			}
		end,
	},
	{
		Id = 4,
		Type = "Progressive",
		Rewards = {
			{
				Type = "Currency",
				Currency = "Gems",
				Amount = 150,
			},
		},
		Requirements = {
			{
				BaseName = "Get [Goal] Headshots",
				Action = "Custom",
				Custom = "Headshots",
				Goal = function(achievement: any)
					return achievement.HeadshotsToGet
				end,
				UseDelta = true,
				Progress = 0,
			},
		},
		GetUniqueProps = function()
			local RNG = Random.new(os.time())
			local headshotsToGet = RNG:NextInteger(5, 10) -- This will be a random number between 5 and 10.
			return {
				HeadshotsToGet = headshotsToGet,
			}
		end,
	},
} :: { Types.AchievementInfo }
