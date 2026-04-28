--!strict

local Players = game:GetService("Players")

local BlinkServer = require("@server/modules/BlinkServer")
local PlayerDataService = require("@services/PlayerDataService")
local ResourceService = require("@services/ResourceService")
local StatisticsService = require("@services/StatisticsService")
local Types = require("@constants/Types")

-- // Service Variables \\

local PlayerlistService = {
	Name = "PlayerlistService",
	PlayerList = {},
}

-- // Functions \\

function PlayerlistService:OnInit()
	PlayerDataService.DocumentLoaded:Connect(function(Player, Document)
		if not Player then
			return
		end
		local documentData = Document:read()
		local playerData: Types.PlayerlistPlayer = {
			Player = Player,
			Level = documentData.Resources.Level,
			Kills = StatisticsService:GetStatistic(Player, "TotalKills"),
			Deaths = StatisticsService:GetStatistic(Player, "TotalDeaths"),
			Playtime = StatisticsService:GetStatistic(Player, "TimePlayed"),
			LongestKillStreak = StatisticsService:GetStatistic(Player, "LongestKillStreak"),
			Wins = StatisticsService:GetStatistic(Player, "TotalWins"),
		}
		PlayerlistService:AddPlayerToList(playerData)
	end)

	Players.PlayerRemoving:Connect(function(Player)
		PlayerlistService:RemovePlayerFromList(Player)
	end)
end

function PlayerlistService:OnStart()
	Players.PlayerAdded:Connect(function(player)
		BlinkServer.PlayerlistSync.Fire(player, PlayerlistService.PlayerList)
	end)

	-- update kills and deaths and level in live time, and longest kill streak.

	StatisticsService:GetStatisticChangedSignal("TotalKills"):Connect(function(Player: Player, Kills: number)
		PlayerlistService:UpdatePlayerProperty(Player, "Kills", Kills)
	end)

	StatisticsService:GetStatisticChangedSignal("TotalDeaths"):Connect(function(Player: Player, Deaths: number)
		PlayerlistService:UpdatePlayerProperty(Player, "Deaths", Deaths)
	end)

	StatisticsService:GetStatisticChangedSignal("LongestKillStreak")
		:Connect(function(Player: Player, LongestKillStreak: number)
			PlayerlistService:UpdatePlayerProperty(Player, "LongestKillStreak", LongestKillStreak)
		end)

	ResourceService:GetResourceChangedSignal("Level"):Connect(function(Player: Player, Level: number)
		PlayerlistService:UpdatePlayerLevel(Player, Level)
	end)
end

function PlayerlistService:OnPlayerRemoving(Player: Player)
	PlayerlistService:RemovePlayerFromList(Player)
end

function PlayerlistService:UpdatePlayerProperty(Player: Player, Property: string, Value: any): ()
	for _, PlayerData in pairs(PlayerlistService.PlayerList) do
		if PlayerData.Player.UserId == Player.UserId then
			PlayerData[Property] = Value
			BlinkServer.PlayerlistSync.FireAll(PlayerlistService.PlayerList)
			break
		end
	end
end

function PlayerlistService:AddPlayerToList(PlayerListData: Types.PlayerlistPlayer): ()
	table.insert(PlayerlistService.PlayerList, PlayerListData)
	BlinkServer.PlayerlistSync.FireAll(PlayerlistService.PlayerList)
end

function PlayerlistService:RemovePlayerFromList(Player: Player): ()
	for Index, PlayerData in PlayerlistService.PlayerList do
		if PlayerData.Player.UserId == Player.UserId then
			table.remove(PlayerlistService.PlayerList, Index)
			BlinkServer.PlayerlistSync.FireAll(PlayerlistService.PlayerList)
			break
		end
	end
end

function PlayerlistService:UpdatePlayerLevel(Player: Player, Level: number): ()
	for _, PlayerData in PlayerlistService.PlayerList do
		if PlayerData.Player.UserId == Player.UserId then
			PlayerData.Level = Level
			BlinkServer.PlayerlistSync.FireAll(PlayerlistService.PlayerList)
			break
		end
	end
end

return PlayerlistService
