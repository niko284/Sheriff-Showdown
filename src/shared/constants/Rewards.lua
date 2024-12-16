--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	{
		Day = 1,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 100,
	},
	{
		Day = 2,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 200,
	},
	{
		Day = 3,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 300,
	},
	{
		Day = 4,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 400,
	},
	{
		Day = 5,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 500,
	},
	{
		Day = 6,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 600,
	},
	{
		Day = 7,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 700,
	},
	{
		Day = 8,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 800,
	},
	{
		Day = 9,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 900,
	},
	{
		Day = 10,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 1000,
	},
	{
		Day = 11,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 1100,
	},
	{
		Day = 12,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 1200,
	},
	{
		Day = 13,
		RewardType = "Daily" :: Types.RewardType,
		Type = "Coins" :: Types.DailyRewardType,
		Amount = 1300,
	},
} :: { Types.DailyReward }
