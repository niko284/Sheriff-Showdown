--!strict

local Goals = require("@self/Goals")
local Types = require("@constants/Types")

local function GenerateTargetRequirementGeneric(
	baseName: string,
	targetKey: string,
	customName: string
): Types.AchievementRequirementInfo
	return {
		BaseName = baseName,
		Progress = 0,
		Action = "Custom",
		Custom = customName,
		Goal = function(achievement: any)
			return achievement[targetKey]
		end,
		UseDelta = true,
	}
end

return {
	{
		Id = 1,
		Type = "Progressive",
		Requirements = {
			{
				BaseName = "Get [Goal] Wins",
				Action = "Statistic",
				Statistic = "TotalWins",
				Goal = function(achievement)
					return Goals.WinGoals[achievement.TimesClaimed + 1] or Goals.WinGoals[#Goals.WinGoals]
				end,
				Progress = 0,
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
				Action = "Statistic",
				Statistic = "TotalKills",
				Goal = function(achievement: any)
					return Goals.KillsGoals[achievement.TimesClaimed + 1] or Goals.KillsGoals[#Goals.KillsGoals]
				end, -- This is our base goal. We will increase this by 10 every time plr levels up on a player-level basis.
				Progress = 0,
			},
		},
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
				BaseName = "Trade [Goal] Time(s)",
				Action = "Statistic",
				Statistic = "TradesCompleted",
				Goal = function(achievement: any)
					return Goals.TradingGoals[achievement.TimesClaimed + 1] or Goals.TradingGoals[#Goals.TradingGoals]
				end,
				Progress = 0,
			},
		},
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
				Action = "Statistic",
				Statistic = "Headshots",
				Goal = function(achievement)
					return Goals.HeadshotGoals[achievement.TimesClaimed + 1]
						or Goals.HeadshotGoals[#Goals.HeadshotGoals]
				end,
				Progress = 0,
			},
		},
	},
	{
		Id = 5,
		Type = "Daily",
		Rewards = {
			{
				Type = "Currency",
				Currency = "Gems",
				Amount = function(achievement: any)
					return 50 + (achievement.NumberOfKills * 2)
				end,
			},
		},
		Requirements = {
			{
				BaseName = "Get [Goal] Kills",
				Action = "Statistic",
				Statistic = "TotalKills",
				Goal = function(achievement: any)
					return achievement.NumberOfKills
				end,
				UseDelta = true,
				Progress = 0,
			},
		},
		GetUniqueProps = function()
			local RNG = Random.new(os.time())
			return {
				NumberOfKills = RNG:NextInteger(10, 50),
			}
		end,
	},
	{
		Id = 6,
		Type = "Daily",
		Rewards = {
			{
				Type = "Currency",
				Currency = "Coins",
				Amount = function(achievement: any)
					return 50 + (achievement.NumberOfWins * 2)
				end,
			},
		},
		Requirements = {
			{
				BaseName = "Get [Goal] Wins",
				Action = "Statistic",
				Statistic = "TotalWins",
				UseDelta = true,
				Goal = function(achievement: any)
					return achievement.NumberOfWins
				end,
				Progress = 0,
			},
		},
		GetUniqueProps = function()
			local RNG = Random.new(os.time())
			return {
				NumberOfWins = RNG:NextInteger(1, 5),
			}
		end,
	},
	{
		Id = 7,
		Type = "Daily",
		Rewards = {
			{
				Type = "Currency",
				Currency = "Coins",
				Amount = function(achievement: any)
					return 100 + (achievement.HeadshotKills * 5)
				end,
			},
		},
		Requirements = {
			{
				BaseName = "Get [Goal] Headshots",
				Action = "Statistic",
				Statistic = "Headshots",
				Goal = function(achievement: any)
					return achievement.HeadshotKills
				end,
				UseDelta = true,
				Progress = 0,
			},
		},
		GetUniqueProps = function()
			local RNG = Random.new(os.time())
			return {
				HeadshotKills = RNG:NextInteger(1, 5),
			}
		end,
	},
	{
		Id = 8,
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
				BaseName = "Kill everyone in a round",
				Progress = 0,
				Goal = 1,
				Action = "Custom",
				Custom = "EveryoneKilled",
			},
		},
	},
	{
		Id = 9,
		Type = "Daily",
		Rewards = {
			{
				Type = "Currency",
				Currency = "Coins",
				Amount = function(achievement: any)
					return 100 + (achievement.NumberOfRounds * 2) -- scale the reward based on the random number of rounds we generated.
				end,
			},
		},
		Requirements = {
			{
				BaseName = "Play [Goal] Rounds",
				Progress = 0,
				Goal = function(achievement: any)
					return achievement.NumberOfRounds
				end,
				Action = "Statistic",
				Statistic = "RoundsPlayed",
				UseDelta = true,
			},
		},
		GetUniqueProps = function()
			local RNG = Random.new(os.time())
			return {
				NumberOfRounds = RNG:NextInteger(25, 50),
			}
		end,
	},
	{
		Id = 10,
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
				BaseName = "Play [Goal] Rounds",
				Progress = 0,
				Goal = function(achievement)
					return Goals.RoundPlayedGoals[achievement.TimesClaimed + 1]
						or Goals.RoundPlayedGoals[#Goals.RoundPlayedGoals]
				end,
				Action = "Statistic",
				Statistic = "RoundsPlayed",
			},
		},
	},
	{
		Id = 11,
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
				BaseName = "Obtain [Goal] Unique Guns",
				Progress = 0,
				Goal = function(achievement)
					return Goals.UniqueGunGoals[achievement.TimesClaimed + 1]
						or Goals.UniqueGunGoals[#Goals.UniqueGunGoals]
				end,
				Action = "Custom",
				Custom = "UniqueGunObtained",
			},
		},
	},
	{
		Id = 12,
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
				BaseName = "Own a #1 Serial item",
				Progress = 0,
				Goal = 1,
				Action = "Custom",
				Custom = "OwnsNumberOneSerial",
			},
		},
	},
} :: { Types.AchievementInfo }
