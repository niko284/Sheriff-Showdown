-- !strict
-- Round Service
-- January 22nd, 2024
-- Nick

-- // Variables \\

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Assets = ServerStorage.assets
local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages

local Maps = require(Constants.Maps)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.Remotes)
local RoundModes = require(Constants.RoundModes)
local ServerComm = require(ServerScriptService.ServerComm)
local Sift = require(Packages.Sift)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local VotingNamespace = Remotes.Server:GetNamespace("Voting")
local ProcessVote = VotingNamespace:Get("ProcessVote")

local MAPS_FOLDER = Assets:WaitForChild("maps", 3)
local VOTING_DURATION = 16
local MINIMUM_PLAYERS = 1
local MAP_VOTING_COUNT = 3
local ROUND_MODE_VOTING_COUNT = 3

-- // Service \\

local RoundService = {
	Name = "RoundService",
	MatchFinished = Signal.new(),
	CurrentRound = nil :: Types.Round?,
	RoundStatus = ServerComm:CreateProperty("RoundStatus", nil),
	VotingPoolClient = ServerComm:CreateProperty("VotingPoolClient", nil),
	VotingPool = nil :: Types.VotingPool?,
}

-- // Functions \\

function RoundService:Init()
	-- loop our rounds. we do this in a thread b/c we don't want to infinitely yield our server loader.

	ProcessVote:Connect(function(Player: Player, VotingField: string, VotingChoice: string)
		-- process the vote in the voting pool.
		RoundService:ProcessVote(Player, VotingField, VotingChoice)
	end)

	task.spawn(function()
		while true do
			RoundService:SetStatus("Waiting for players")
			RoundService:WaitForPlayers(MINIMUM_PLAYERS)
				:andThen(function()
					return RoundService:DoVoting()
				end)
				:andThen(function(FieldWinners)
					local roundInstance = RoundService:CreateRound(FieldWinners.RoundModes, FieldWinners.Maps)
					return RoundService:DoRound(roundInstance)
				end)
				:expect()
		end
	end)
end

function RoundService:SetStatus(Status: string)
	RoundService.RoundStatus:Set(Status)
end

function RoundService:ProcessVote(Player: Player, VotingField: string, VotingChoice: string)
	local votingPool = RoundService.VotingPool
	if not votingPool then
		return
	end

	local votingFieldData = votingPool[VotingField] :: Types.VotingPoolField
	if not votingFieldData then
		return
	end

	local isValidChoice = table.find(votingFieldData.Choices, VotingChoice) ~= nil
	if not isValidChoice then
		return
	end

	votingFieldData.Votes[Player.UserId] = VotingChoice -- overwrite the player's vote for the given field.
end

function RoundService:DoVoting()
	-- shuffle maps and round modes
	local shuffledMaps = Sift.Array.shuffle(Maps)
	local shuffledRoundModes = Sift.Array.shuffle(RoundModes)

	-- pick MAP_VOTING_COUNT maps and ROUND_MODE_VOTING_COUNT round modes

	local votingPool = {
		Maps = {
			Choices = {},
			Votes = {},
		},
		RoundModes = {
			Choices = {},
			Votes = {},
		},
	}
	RoundService.VotingPool = votingPool

	local maxIndexMaps = math.min(#shuffledMaps, MAP_VOTING_COUNT)
	for i = 1, maxIndexMaps do
		table.insert(votingPool.Maps.Choices, shuffledMaps[i].Name)
	end

	local maxIndexRoundModes = math.min(#shuffledRoundModes, ROUND_MODE_VOTING_COUNT)
	for i = 1, maxIndexRoundModes do
		if #shuffledRoundModes < i then -- prevent overflows
			break
		end
		table.insert(votingPool.RoundModes.Choices, shuffledRoundModes[i].Name)
	end

	-- to reduce bandwidth we can also just pass the non-shuffled indices of the maps and round modes to the client but not necessary, very negligible
	RoundService.VotingPoolClient:Set({
		VotingFields = {
			{
				Field = "Maps",
				Choices = votingPool.Maps.Choices,
			},
			{
				Field = "RoundModes",
				Choices = votingPool.RoundModes.Choices,
			},
		},
	})

	return Promise.delay(VOTING_DURATION):andThen(function()
		-- tally the votes in each field and pick the winning choice
		local fieldsWithWinningChoices = {}

		for field, fieldData in votingPool do
			local votes = fieldData.Votes
			local choices = fieldData.Choices

			local tally = {}
			for _, choice in choices do
				tally[choice] = 0
			end

			for _, vote in votes do
				tally[vote] += 1
			end

			local winningChoice = choices[1] -- by default, the first choice is the winning choice
			local highestVoteCount = tally[winningChoice] -- by default, the first choice has the highest vote count

			for choice, voteCount in tally do
				if voteCount > highestVoteCount then
					winningChoice = choice
					highestVoteCount = voteCount
				end
			end

			fieldsWithWinningChoices[field] = winningChoice
		end

		RoundService.VotingPoolClient:Set(nil) -- close the voting interface

		return fieldsWithWinningChoices
	end)
end

function RoundService:WaitForPlayers(PlayerCount: number)
	local playerCount = #Players:GetPlayers()
	if playerCount >= PlayerCount then
		return Promise.resolve()
	else
		return Promise.fromEvent(Players.PlayerAdded, function()
			return #Players:GetPlayers() >= PlayerCount
		end)
	end
end

function RoundService:LoadMap(MapName: string)
	local map = nil
	for _, mapData in Maps do
		if mapData.Name == MapName then
			map = mapData
			break
		end
	end
	if map == nil then
		error("Map " .. MapName .. " does not exist!")
		return
	end
	local mapModel = MAPS_FOLDER:FindFirstChild(map.Name)
	if mapModel == nil then
		error("Map " .. map .. " does not exist!")
		return
	end

	local mapClone = mapModel:Clone()
	mapClone.Parent = workspace -- add the map to the workspace (load it in)

	return mapClone
end

function RoundService:DoRound(RoundInstance: Types.Round)
	return RoundService:RunMatches(RoundInstance)
end

function RoundService:RunMatches(RoundInstance: Types.Round)
	local matchPool = RoundInstance.Matches
	return Promise.new(function(resolve)
		while #matchPool > 0 do
			-- our match pool will get smaller and smaller as the tournament progresses. start the initial match every time.
			RoundService:StartMatch(RoundInstance, matchPool[1])
			RoundService:WaitForMatchesToFinish(RoundInstance):expect() -- wait for all matches to finish
			-- then, re-allocate the matches
			matchPool = RoundService:AllocateMatches(RoundInstance.Players, RoundInstance.RoundMode)
		end
		resolve()
	end)
end

function RoundService:StartMatch(RoundInstance: Types.Round, Match: Types.Match)
	-- teleport players to their spawn points
	local mapFolder = RoundInstance.Map
	local mapGameModeFolder = mapFolder:FindFirstChild(RoundInstance.RoundMode)
	-- get all spawn points
	for _index, team in Match.Teams do
		local spawnPoints = mapGameModeFolder:FindFirstChild(team.Name)
		local spawners = spawnPoints:GetChildren()
		for _, player in team.Players do
			local randomSpawnerIndex = math.random(1, #spawners)
			local spawnPoint = spawners[randomSpawnerIndex]
			local character = player.Character or player.CharacterAdded:Wait()
			character:PivotTo(spawnPoint.CFrame)
			table.remove(spawners, randomSpawnerIndex) -- we don't want to spawn two players at the same spawn point
		end
	end
end

function RoundService:GetRound(): Types.Round?
	-- get the current round
	return RoundService.CurrentRound
end

function RoundService:OnSameTeam(Player1: Player, Player2: Player): boolean
	-- loop through all matches and teams to see if the players are on the same team
	local round = RoundService:GetRound()
	if round then
		for _, match in ipairs(round.Matches) do
			for _, team in ipairs(match.Teams) do
				if table.find(team.Players, Player1) ~= nil and table.find(team.Players, Player2) ~= nil then
					return true
				end
			end
		end
	end
	return false
end

function RoundService:WaitForMatchesToFinish(RoundInstance: Types.Round)
	local matchPromises = {}
	for _, match in ipairs(RoundInstance.Matches) do
		local matchPromise = Promise.any({
			RoundService:TeamsStillInMatch(match),
			Promise.fromEvent(RoundService.MatchFinished, function(MatchUUID: string, WinningTeam: Types.Team)
				if MatchUUID == match.MatchUUID then
					-- remove every other team's players from the round's player pool if they aren't the winning team
					for _, team in match.Teams do
						if team ~= WinningTeam then
							for _, player in team.Players do
								local playerPoolIndex = table.find(RoundInstance.Players, player)
								if playerPoolIndex ~= nil then
									table.remove(RoundInstance.Players, playerPoolIndex)
								end
							end
						end
					end
					return true
				end
				return false
			end),
		})
		table.insert(matchPromises, matchPromise)
	end

	return Promise.all(matchPromises)
end

function RoundService:TeamsStillInMatch(match: Types.Match)
	return Promise.fromEvent(Players.PlayerRemoving, function()
		-- make sure that at least 2 teams have at least one player in them, otherwise the match is over. the team with players left wins.
		local teamsWithPlayers = Sift.Array.filter(match.Teams, function(team: Types.Team)
			local plrCount = 0
			for _, player in team.Players do
				if player:IsDescendantOf(Players) == true then
					plrCount += 1
				end
			end
			return plrCount > 0
		end)
		return #teamsWithPlayers >= 2
	end)
end

function RoundService:CreateRound(RoundMode: Types.RoundMode, MapName: string): Types.Round
	local playerPool = RoundService:GetAllPlayers()
	local Round = {
		Players = playerPool,
		Matches = RoundService:AllocateMatches(playerPool, RoundMode),
		RoundMode = RoundMode,
		Map = RoundService:LoadMap(MapName),
	}
	return Round
end

function RoundService:GetRoundModeData(RoundMode: Types.RoundMode): Types.RoundModeData
	local roundModeData = nil
	for _, data in RoundModes do
		if data.Name == RoundMode then
			roundModeData = data
			break
		end
	end
	return roundModeData
end

function RoundService:AllocateMatches(PlayerPool: { Player }, RoundMode: Types.RoundMode): { Types.Match }
	-- create a table of matches to return where each team in a match has TeamSize number of players.
	-- leave extra players in the player pool if there are not enough players to fill a match.

	local Matches = {}
	-- shuffle the player pool
	local shuffledPool = Sift.Array.shuffle(PlayerPool)

	local RoundModeData = RoundService:GetRoundModeData(RoundMode)

	-- create a match for each team
	local numberOfMatches = math.floor(#shuffledPool / RoundModeData.TeamSize)

	for _i = 1, numberOfMatches do
		local match = {
			Teams = {},
			MatchUUID = HttpService:GenerateGUID(false),
		}
		for j = 1, RoundModeData.TeamsPerMatch do
			local team = {
				Players = {},
				Name = RoundModeData.TeamNames[j],
			}
			for _k = 1, RoundModeData.TeamSize do
				local player = table.remove(shuffledPool)
				table.insert(team.Players, player)
			end
			table.insert(match.Teams, team)
		end
		table.insert(Matches, match)
	end

	return Matches
end

function RoundService:GetAllPlayers(): { Player }
	local playersInGame = Players:GetPlayers()
	return playersInGame
end

return RoundService
