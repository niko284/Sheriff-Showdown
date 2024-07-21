--!strict

-- Statistics Service
-- June 10th, 2022
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services
local Packages = ReplicatedStorage.packages

local Freeze = require(Packages.Freeze)
local PlayerDataService = require(Services.PlayerDataService)
local ProfileSchema = require(Services.PlayerDataService.Schema)
local ServerComm = require(ServerScriptService.ServerComm)
local Signal = require(Packages.Signal)

-- // Service Variables \\

local StatisticsService = {
	Name = "StatisticsService",
	PlayerStatistics = ServerComm:CreateProperty("PlayerStatistics", {}),
	JoinTimestamps = {} :: { [number]: number },
	StatisticSignals = {} :: { [string]: Signal.Signal<...any> },
}

-- // Functions \\

function StatisticsService:OnInit()
	for StatisticName, _ in pairs(ProfileSchema.Statistics) do
		StatisticsService.StatisticSignals[StatisticName] = Signal.new()
	end

	table.insert(PlayerDataService.BeforeDocumentCloseCallbacks, function(Player: Player)
		StatisticsService:SavePlayTime(Player)
	end)

	PlayerDataService.DocumentLoaded:Connect(function(Player: Player, PlayerDocument)
		local playerData = PlayerDocument:read()

		local Statistics = playerData.Statistics

		for StatisticName, _ in pairs(ProfileSchema.Statistics) do
			StatisticsService.StatisticSignals[StatisticName]:Fire(Player, Statistics[StatisticName])
		end

		StatisticsService.PlayerStatistics:SetFor(Player, Statistics) -- Set the statistics for the player on initial join
	end)
end

function StatisticsService:OnPlayerAdded(Player: Player)
	StatisticsService.JoinTimestamps[Player.UserId] = os.time()
end

function StatisticsService:GetStatistics(Player: Player): { [string]: any }
	local playerDocument = PlayerDataService:GetDocument(Player)
	if playerDocument then
		return playerDocument:read().Statistics
	end
	return {}
end

function StatisticsService:ObserveStatisticChanged(
	StatisticName: string,
	Callback: (Player, ...any) -> ()
): Signal.Connection
	local signal = StatisticsService.StatisticSignals[StatisticName]

	-- fire for all players
	for _, Player in Players:GetPlayers() do
		local PlayerStatistics = StatisticsService:GetStatistics(Player)
		if PlayerStatistics then
			local StatisticValue = PlayerStatistics[StatisticName]
			if StatisticValue then
				signal:Fire(Player, StatisticValue)
			end
		end
	end

	return signal:Connect(Callback)
end

function StatisticsService:GetStatistic(Player: Player, Statistic: string): any?
	local playerStatistics = StatisticsService:GetStatistics(Player)
	if playerStatistics then
		return playerStatistics[Statistic]
	else
		return nil
	end
end

function StatisticsService:SavePlayTime(Player: Player)
	local timeJoined = StatisticsService.JoinTimestamps[Player.UserId]
	if timeJoined then
		StatisticsService:IncrementStatistic(Player, "TimePlayed", os.time() - timeJoined)
		StatisticsService.JoinTimestamps[Player.UserId] = nil
	end
end

function StatisticsService:SetStatistic(
	Player: Player,
	StatisticName: string,
	StatisticValue: any,
	shouldSendNetworkEvent: boolean?
)
	local PlayerStatistics = StatisticsService:GetStatistics(Player)
	local oldValue = PlayerStatistics[StatisticName]

	local playerDocument = PlayerDataService:GetDocument(Player)
	local playerData = playerDocument:read()

	playerDocument:write(Freeze.Dictionary.setIn(playerData, { "Statistics", StatisticName }, StatisticValue))

	StatisticsService.StatisticSignals[StatisticName]:Fire(Player, StatisticValue, oldValue)
	if shouldSendNetworkEvent ~= false then -- sometimes we don't want to send a network event to reduce bandwidth.
		StatisticsService.PlayerStatistics:SetFor(Player, { -- send partial state to reduce network traffic
			[StatisticName] = StatisticValue,
		})
	end
end

function StatisticsService:IncrementStatistic(
	Player: Player,
	StatisticName: string,
	Increment: number,
	shouldSendNetworkEvent: boolean?
)
	local PlayerStatistics = StatisticsService:GetStatistics(Player)
	local oldValue: number? = PlayerStatistics[StatisticName]
	local newValue = (oldValue or 0) + Increment

	local playerDocument = PlayerDataService:GetDocument(Player)
	local playerData = playerDocument:read()

	playerDocument:write(Freeze.Dictionary.setIn(playerData, { "Statistics", StatisticName }, newValue))

	StatisticsService.StatisticSignals[StatisticName]:Fire(Player, newValue, oldValue)
	if shouldSendNetworkEvent ~= false then -- sometimes we don't want to send a network event to reduce bandwidth.
		StatisticsService.PlayerStatistics:SetFor(Player, { -- send partial state to reduce network traffic
			[StatisticName] = newValue,
		})
	end
end

return StatisticsService
