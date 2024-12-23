--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services
local Constants = ReplicatedStorage.constants

local PlayerDataService = require(Services.PlayerDataService)
local ResourceService = require(Services.ResourceService)
local ServerComm = require(ServerScriptService.ServerComm)
local StatisticsService = require(Services.StatisticsService)
local Types = require(Constants.Types)

-- // Service Variables \\

local PlayerlistService = {
	Name = "PlayerlistService",
	ReplicatedPlayerList = ServerComm:CreateProperty("ReplicatedPlayerList", {}),
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

function PlayerlistService:Start()
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
			PlayerlistService.ReplicatedPlayerList:Set(PlayerlistService.PlayerList)
			break
		end
	end
end

function PlayerlistService:AddPlayerToList(PlayerListData: Types.PlayerlistPlayer): ()
	table.insert(PlayerlistService.PlayerList, PlayerListData)
	PlayerlistService.ReplicatedPlayerList:Set(PlayerlistService.PlayerList)
end

function PlayerlistService:RemovePlayerFromList(Player: Player): ()
	for Index, PlayerData in PlayerlistService.PlayerList do
		if PlayerData.Player.UserId == Player.UserId then
			table.remove(PlayerlistService.PlayerList, Index)
			PlayerlistService.ReplicatedPlayerList:Set(PlayerlistService.PlayerList)
			break
		end
	end
end

function PlayerlistService:UpdatePlayerLevel(Player: Player, Level: number): ()
	for _, PlayerData in PlayerlistService.PlayerList do
		if PlayerData.Player.UserId == Player.UserId then
			PlayerData.Level = Level
			PlayerlistService.ReplicatedPlayerList:Set(PlayerlistService.PlayerList)
			break
		end
	end
end

return PlayerlistService
