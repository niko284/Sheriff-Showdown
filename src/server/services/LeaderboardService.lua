--!strict

-- Leaderboard Service
-- October 28th, 2022
-- Nick

-- // Variables \\

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages
local Services = ServerScriptService.services

local Leaderboards = require(Constants.Leaderboards)
local PlayerDataService = require(Services.PlayerDataService)
local Promise = require(Packages.Promise)
local Sift = require(Packages.Sift)
local Timer = require(Packages.Timer)
local Types = require(Constants.Types)

local MAX_FETCH_RETRIES = 3 -- Maximum number of times to retry fetching the leaderboard data
local LEADERBOARD_UPDATE_INTERVAL = 120 -- Time in seconds between leaderboard updates\

type LeaderboardInfoServer = Types.LeaderboardInfo & {
	OrderedStore: OrderedDataStore,
}

-- // Service \\

local LeaderboardService = {
	Name = "LeaderboardService",
	Leaderboards = {} :: { [string]: LeaderboardInfoServer },
}

-- // Functions \\

function LeaderboardService:OnStart()
	-- Initialize server leaderboard information.

	table.insert(PlayerDataService.BeforeDocumentCloseCallbacks, function(Player: Player)
		return LeaderboardService:SavePlayerLeaderboardData(Player)
	end)

	for _, leaderboardInfo: Types.LeaderboardInfo in Leaderboards do
		local leaderboardKey = if typeof(leaderboardInfo.LeaderboardKey) == "function"
			then leaderboardInfo.LeaderboardKey()
			else leaderboardInfo.LeaderboardKey
		local orderedStore =
			DataStoreService:GetOrderedDataStore(string.format(leaderboardKey, leaderboardInfo.LeaderboardName))
		local leaderboardInfoServer: LeaderboardInfoServer = Sift.Dictionary.merge(leaderboardInfo, {
			OrderedStore = orderedStore,
		})
		LeaderboardService.Leaderboards[leaderboardInfo.LeaderboardName] = leaderboardInfoServer
	end

	-- Every time interval, fetch each leaderboard's data, organize it, and send it to all clients.

	local updateLeaderboardsTimer = Timer.new(LEADERBOARD_UPDATE_INTERVAL)
	updateLeaderboardsTimer.Tick:Connect(function()
		-- update clients with leaderboard data
	end)
	updateLeaderboardsTimer:StartNow()
end

function LeaderboardService:SavePlayerLeaderboardData(Player: Player)
	local playerDocument = PlayerDataService:GetDocument(Player)
	local savePromises = {}
	if playerDocument then
		local playerData = playerDocument:read()
		for _, leaderboardInfo: LeaderboardInfoServer in LeaderboardService.Leaderboards do
			if leaderboardInfo.ValueType == "Resource" and leaderboardInfo.Resource then
				local resourceValue = playerData.Resources[leaderboardInfo.Resource]
				if resourceValue then
					table.insert(
						savePromises,
						LeaderboardService:SetLeaderboardValue(leaderboardInfo.LeaderboardName, Player, resourceValue)
					)
				end
			elseif leaderboardInfo.ValueType == "Statistic" and leaderboardInfo.Statistic then
				local statisticValues = {}
				if typeof(leaderboardInfo.Statistic) == "table" then
					for _, statisticName in ipairs(leaderboardInfo.Statistic) do
						local statisticValue = playerData.Statistics[statisticName]
						if statisticValue then
							table.insert(statisticValues, statisticValue)
						end
					end
				else
					local statisticValue = playerData.Statistics[leaderboardInfo.Statistic]
					if statisticValue then
						table.insert(statisticValues, statisticValue)
					end
				end
				local statisticValue = nil
				local mapper = leaderboardInfo.Mapper
				if mapper then
					statisticValue = mapper(unpack(statisticValues))
				else -- Default to the first statistic value if there is no mapper for our statistic.
					statisticValue = statisticValues[1]
				end
				if statisticValue then
					table.insert(
						savePromises,
						LeaderboardService:SetLeaderboardValue(leaderboardInfo.LeaderboardName, Player, statisticValue)
					)
				end
			end
		end
	end
	if #savePromises == 0 then
		return Promise.resolve()
	end
	return Promise.allSettled(savePromises)
end

function LeaderboardService:FetchLeaderboardData(LeaderboardName: string): DataStorePages?
	local leaderboardInformation: LeaderboardInfoServer = LeaderboardService:GetLeaderboardInfo(LeaderboardName)
	local amountPage = leaderboardInformation.DisplaySlots
	local getSortedAsync = leaderboardInformation.OrderedStore.GetSortedAsync
	local success, leaderboardData = Promise.retry(
		Promise.promisify(getSortedAsync),
		MAX_FETCH_RETRIES,
		leaderboardInformation.OrderedStore,
		false,
		amountPage + 40, -- fetch 40 extra entries to account for moderators/admins being omitted from the leaderboard
		1
	):await()
	if success then
		return leaderboardData
	else
		return nil
	end
end

function LeaderboardService:OrganizeLeaderboardData(LeaderboardName: string): { Types.LeaderboardEntry }
	local leaderboardPages: DataStorePages? = LeaderboardService:FetchLeaderboardData(LeaderboardName)
	local leaderboardInformation: LeaderboardInfoServer = LeaderboardService:GetLeaderboardInfo(LeaderboardName)
	local leaderboardEntries: { Types.LeaderboardEntry } = {}
	if leaderboardPages then
		while true do
			local PageData: { Types.LeaderboardEntry } = leaderboardPages:GetCurrentPage()
			for _, entry in ipairs(PageData) do
				table.insert(leaderboardEntries, entry)
				if #leaderboardEntries >= leaderboardInformation.DisplaySlots then
					return leaderboardEntries
				end
			end
			if not leaderboardPages.IsFinished and #leaderboardEntries < leaderboardInformation.DisplaySlots then
				leaderboardPages:AdvanceToNextPageAsync()
			else
				return leaderboardEntries
			end
		end
	end
	return leaderboardEntries
end

function LeaderboardService:SetLeaderboardValue(LeaderboardName: string, Player: Player, NewValue: number)
	local leaderboardInfo: LeaderboardInfoServer = LeaderboardService:GetLeaderboardInfo(LeaderboardName)
	local orderedStore = leaderboardInfo.OrderedStore
	return Promise.retry(
		Promise.promisify(orderedStore.SetAsync),
		MAX_FETCH_RETRIES,
		orderedStore,
		Player.UserId,
		NewValue
	)
		:catch(function(err: any)
			warn(tostring(err))
		end)
end

function LeaderboardService:GetLeaderboardInfo(LeaderboardName: string): LeaderboardInfoServer
	return LeaderboardService.Leaderboards[LeaderboardName]
end

return LeaderboardService
