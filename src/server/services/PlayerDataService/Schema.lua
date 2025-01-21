--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	Inventory = {
		Storage = {},
		Equipped = {},
		GrantedDefaults = {},
	},
	Resources = {
		-- Currency
		Coins = 100000,
		Gems = 0,
		-- Level
		Level = 1,
		Experience = 0,
		-- Daily rewards
		RewardSeed = -1,
		RewardDay = 1,
		LastRewardClaim = -1,
	},
	Achievements = {
		LastDailyRotation = -1,
		ActiveAchievements = {},
	},
	CodesRedeemed = {}, -- string[]
	Statistics = {
		TotalWins = 0,
		TotalKills = 0,
		RoundsPlayed = 0,
		Headshots = 0,
		TradesCompleted = 0,
		TotalDeaths = 0,
		TimePlayed = 0,
		LongestKillStreak = 0,
		KillStreak = 0, -- current kill streak
	},
	Settings = {},
	ProcessingTrades = {},
	ReceiptHistory = {},
	GiftedGamepasses = {},
} :: Types.DataSchema
