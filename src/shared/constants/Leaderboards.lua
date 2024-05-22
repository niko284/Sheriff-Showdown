--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

return {
	{
		LeaderboardName = "MostKillsAllTime",
		LeaderboardKey = "LeaderboardMostKillsAllTime", -- static key.
		DisplayName = "Most Kills",
		DisplaySlots = 10,
		ValueType = "Statistic",
		Statistic = "Kills",
	},
	{
		LeaderboardName = "MostKillsWeekly",
		LeaderboardKey = function()
			-- we want a new unique week ID every monday at 12 PM eastern time.
			local weeksSinceEpoch = math.floor((os.time() - 1615824000) / 604800) -- where 1615824000 is a base epoch time of 12 PM on March 15th, 2021.
			return "LeaderboardMostKillsWeekly_" .. weeksSinceEpoch
		end,
		DisplayName = "Most Kills [Weekly]",
		DisplaySlots = 10,
		ValueType = "Statistic",
		Statistic = "Kills",
	},
} :: { Types.LeaderboardInfo }
