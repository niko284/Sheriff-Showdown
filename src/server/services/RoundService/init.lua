-- !strict
-- Round Service
-- January 22nd, 2024
-- Nick

-- // Variables \\

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Assets = ServerStorage.assets
local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages
local Services = ServerScriptService.services
local Utils = ReplicatedStorage.utils
local ActionShared = ReplicatedStorage.ActionShared
local SharedAssets = ReplicatedStorage:FindFirstChild("assets") :: Folder

local ActionService = require(Services.ActionService)
local EquipmentHandler = require(Services.EquipmentService.EquipmentHandler)
local InventoryService = require(Services.InventoryService)
local ItemUtils = require(Utils.ItemUtils)
local Maps = require(Constants.Maps)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.Remotes)
local RoundModes = require(Constants.RoundModes)
local ServerComm = require(ServerScriptService.ServerComm)
local Sift = require(Packages.Sift)
local Signal = require(Packages.Signal)
local StatusModule = require(ActionShared.StatusModule)
local Teams = require(Constants.Teams)
local Types = require(Constants.Types)

local RoundNamespace = Remotes.Server:GetNamespace("Round")
local VotingNamespace = Remotes.Server:GetNamespace("Voting")

local StartMatchClient = RoundNamespace:Get("StartMatch")
local ProcessVote = VotingNamespace:Get("ProcessVote")
local EndMatchClient = RoundNamespace:Get("EndMatch")
local ApplyTeamIndicator = RoundNamespace:Get("ApplyTeamIndicator")

local MAPS_FOLDER = Assets:WaitForChild("maps", 3)
local EFFECTS_FOLDER = SharedAssets:FindFirstChild("effects") :: Folder
local ExtensionsFolder = script.ModeExtensions
local VOTING_DURATION = 16
local MINIMUM_PLAYERS = 2
local MAP_VOTING_COUNT = 3
local ROUND_MODE_VOTING_COUNT = 3
local WINNER_CELEBRATION_DURATION = 4
local GLOW_LIGHT = EFFECTS_FOLDER:FindFirstChild("GlowLight") :: PointLight

-- // Service \\

local RoundService = {
	Name = "RoundService",
	MatchFinished = Signal.new(),
	RoundExtensions = {} :: { [Types.RoundMode]: Types.RoundModeExtension },
	CurrentRound = nil :: Types.Round?,
	RoundStatus = ServerComm:CreateProperty("RoundStatus", nil),
	VotingPoolClient = ServerComm:CreateProperty("VotingPoolClient", nil),
	StartMatchTimestamp = ServerComm:CreateProperty("StartMatchTimestamp", nil),
	VotingPool = nil :: Types.VotingPool?,
}

-- // Functions \\

function RoundService:Init()
	-- load our round extensions
	for _, extension in ExtensionsFolder:GetChildren() do
		local extensionModule = require(extension) :: Types.RoundModeExtension
		RoundService.RoundExtensions[extensionModule.Data.Name] = extensionModule
	end

	-- loop our rounds. we do this in a thread b/c we don't want to infinitely yield our server loader.

	ProcessVote:Connect(function(Player: Player, VotingField: string, VotingChoice: string)
		-- process the vote in the voting pool.
		RoundService:ProcessVote(Player, VotingField, VotingChoice)
	end)

	StatusModule.StatusApplied:Connect(function(Entity: Types.Entity, StatusName: Types.EntityStatus)
		local playerKilled = Players:GetPlayerFromCharacter(Entity)

		if StatusName == "Killed" and playerKilled then -- we need to check if the entity killed is a part of any ongoing matches.
			local round = RoundService:GetRound()
			if round then
				for _, match in round.Matches do
					for _, team in match.Teams do
						local isInTeam = table.find(team.Players, playerKilled)
						if isInTeam then
							table.insert(team.Killed, playerKilled)

							EndMatchClient:SendToPlayer(playerKilled)

							local winningTeam = RoundService:GetWinningTeam(match)
							if winningTeam then
								RoundService.MatchFinished:Fire(match.MatchUUID, winningTeam)
							end
						end
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(Player: Player)
		-- if we have an ongoing round, count the player as killed in the round.
		local round = RoundService:GetRound()
		if round then
			for _, match in round.Matches do
				for _, team in match.Teams do
					local playerIndex = table.find(team.Players, Player)
					if playerIndex then
						table.insert(team.Killed, Player)

						local winningTeam = RoundService:GetWinningTeam(match)

						if winningTeam then
							RoundService.MatchFinished:Fire(match.MatchUUID, winningTeam)
						end
					end
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			RoundService:WaitForPlayers(MINIMUM_PLAYERS)
				:andThen(function()
					return Promise.race({
						RoundService:NotEnoughPlayersPromise():andThen(function()
							-- we want to cancel the entire promise chain if there are not enough players to start a round after voting or intermission.
							return Promise.reject("Not enough players to start a round.")
						end),
						RoundService:DoIntermission():andThen(function()
							return RoundService:DoVoting()
						end),
					})
				end)
				:andThen(function(FieldWinners)
					local roundInstance = RoundService:CreateRound(FieldWinners.RoundModes.Name, FieldWinners.Maps.Name)
					RoundService.CurrentRound = roundInstance
					return RoundService:DoRound(roundInstance)
				end)
				:andThen(function(winningPlayers: { Player })
					local winnerString = "Winners: "
					for index, player in winningPlayers do
						if index == #winningPlayers then
							winnerString = winnerString .. player.Name
						else
							winnerString = winnerString .. player.Name .. ", "
						end
					end

					RoundService:SetStatus(winnerString)

					-- destroy the map
					local round = RoundService:GetRound()
					if round then
						round.Map:Destroy()
					end

					-- teleport winning players to the lobby

					--[[task.wait(5)
					for _, player in winningPlayers do
						player:LoadCharacter()
					end--]]

					return Promise.delay(8)
				end)
				:catch(function(err)
					warn("Error in round service: " .. tostring(err))
				end)
				:expect()
		end
	end)
end

function RoundService:GetRoundModeExtension(RoundMode: Types.RoundMode): Types.RoundModeExtension?
	return RoundService.RoundExtensions[RoundMode]
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

	local isValidChoice = false

	for _, choice in votingFieldData.Choices do
		if choice.Name == VotingChoice then
			isValidChoice = true
			break
		end
	end

	if not isValidChoice then
		return
	end

	votingFieldData.Votes[Player.UserId] = VotingChoice -- overwrite the player's vote for the given field.
end

function RoundService:DoIntermission()
	RoundService:SetStatus("Intermission")
	return Promise.delay(10)
end

-- resolves if there are not enough players to start a round (used in the intermission and voting phases)
function RoundService:NotEnoughPlayersPromise()
	if #Players:GetPlayers() < MINIMUM_PLAYERS then
		return Promise.resolve()
	else
		return Promise.fromEvent(Players.PlayerRemoving, function()
			return #Players:GetPlayers() < MINIMUM_PLAYERS
		end)
	end
end

function RoundService:DoVoting()
	RoundService:SetStatus("Voting in progress")

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
		table.insert(votingPool.Maps.Choices, {
			Name = shuffledMaps[i].Name,
			Image = shuffledMaps[i].Image,
		})
	end

	local maxIndexRoundModes = math.min(#shuffledRoundModes, ROUND_MODE_VOTING_COUNT)
	for i = 1, maxIndexRoundModes do
		if #shuffledRoundModes < i then -- prevent overflows
			break
		end
		table.insert(votingPool.RoundModes.Choices, {
			Name = shuffledRoundModes[i].Name,
			Image = shuffledRoundModes[i].Image,
		})
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
				tally[choice.Name] = 0
			end

			for _, vote in votes do
				tally[vote] += 1
			end

			local winningChoice = choices[1] -- by default, the first choice is the winning choice
			local highestVoteCount = tally[winningChoice.Name] -- by default, the first choice has the highest vote count

			for choice, voteCount in tally do
				if voteCount > highestVoteCount then
					for _, choiceData in choices do
						if choiceData.Name == choice then
							winningChoice = choiceData
							break
						end
					end
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
	RoundService:SetStatus("Waiting for players")
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
	RoundService:SetStatus("Round in progress")
	return RoundService:RunMatches(RoundInstance)
end

function RoundService:RunMatches(RoundInstance: Types.Round)
	local roundMode = RoundService:GetRoundModeData(RoundInstance.RoundMode)

	return Promise.new(function(resolve)
		while #RoundInstance.Matches > 0 do
			-- our match pool will get smaller and smaller as the tournament progresses. start the initial match every time.
			RoundService:StartMatch(RoundInstance, RoundInstance.Matches[1])
			RoundService:WaitForMatchesToFinish(RoundInstance):expect() -- wait for all matches to finish

			-- if the only players in the pool are from the same team in the previous matches, break the loop
			if roundMode.IsGameOver(RoundInstance) == true then -- behavior may vary depending on the round mode for the game end condition.
				break
			else
				-- we need to wait for the players from the last match to respawn before we start the next match.
				task.wait(WINNER_CELEBRATION_DURATION + 1)
			end

			RoundInstance.Matches = RoundService:AllocateMatches(RoundInstance.Players, RoundInstance.RoundMode)
		end
		resolve(RoundInstance.Players) -- return the winning players (the players that won the tournament are the only ones left in the player pool)
	end)
end

function RoundService:PlayersLeftFromSameTeam(PlayerPool: { Player }): boolean
	local round = RoundService:GetRound()
	if round then
		for _, match in round.Matches do
			for _, team in match.Teams do
				for _, player in team.Players do
					if table.find(PlayerPool, player) == nil then
						break
					end
				end
			end
		end
	end
	return true
end

function RoundService:GetAllPlayersInMatch(Match: Types.Match): { Player }
	local playersInMatch = {}
	for _, team in pairs(Match.Teams) do
		for _, player in team.Players do
			if not table.find(team.Killed, player) then
				table.insert(playersInMatch, player)
			end
		end
	end
	return playersInMatch
end

function RoundService:StartMatch(RoundInstance: Types.Round, Match: Types.Match)
	-- teleport players to their spawn points
	local mapFolder = RoundInstance.Map

	local roundModeInfo = RoundService:GetRoundModeData(RoundInstance.RoundMode)

	local mapGameModeFolder = mapFolder:FindFirstChild(roundModeInfo.UseSpawnType or RoundInstance.RoundMode)
	-- get all spawn points

	local teamPlayerColors = {}

	for _index, team in pairs(Match.Teams) do
		local spawnPoints = mapGameModeFolder:FindFirstChild(team.Name)
		local spawners = spawnPoints:GetChildren()

		StartMatchClient:SendToPlayers(team.Players)
		RunService.Heartbeat:Wait()

		teamPlayerColors[team.Name] = {
			Players = team.Players,
			Color = team.Color,
		}

		for _, player in team.Players do
			local randomSpawnerIndex = math.random(1, #spawners)
			local spawnPoint = spawners[randomSpawnerIndex]
			local character = player.Character or player.CharacterAdded:Wait()

			character:PivotTo(spawnPoint.CFrame * CFrame.new(0, 5, 0))
			local pointLight = GLOW_LIGHT:Clone()
			pointLight.Parent = character:FindFirstChild("UpperTorso")

			player:SetAttribute("IsInMatch", true)

			table.remove(spawners, randomSpawnerIndex) -- we don't want to spawn two players at the same spawn point

			-- give player hand-held equipment (their guns)
			local equippedGuns = InventoryService:GetItemsOfType(player, "Gun", true)
			local primaryGun = equippedGuns[1]
			if primaryGun then
				-- show on waist
				EquipmentHandler.EquipGun(
					character :: Types.Entity,
					ItemUtils.GetItemInfoFromId(primaryGun.Id),
					"Hands"
				)
			end
		end
	end

	ApplyTeamIndicator:SendToPlayers(RoundService:GetAllPlayersInMatch(Match), teamPlayerColors)

	local roundModeExtension = RoundService:GetRoundModeExtension(RoundInstance.RoundMode)
	if roundModeExtension then
		roundModeExtension.StartMatch(Match, RoundInstance)
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
	for index, match in ipairs(RoundInstance.Matches) do
		local matchPromise = Promise.fromEvent(
			RoundService.MatchFinished,
			function(MatchUUID: string, WinningTeam: Types.Team)
				if MatchUUID == match.MatchUUID then
					-- remove every other team's players from the round's player pool if they aren't the winning team

					local winningTeam = nil

					for _, team in match.Teams do
						if team ~= WinningTeam then
							for _, player in team.Players do
								player:SetAttribute("IsInMatch", false)
								local playerPoolIndex = table.find(RoundInstance.Players, player)
								if playerPoolIndex ~= nil then
									table.remove(RoundInstance.Players, playerPoolIndex)
								end
							end
						else
							-- respawn the winning team's players and disable combat system
							winningTeam = team
							for _, winningPlayer in team.Players do
								winningPlayer:SetAttribute("IsInMatch", false)
								ActionService:ToggleCombatSystem(false, winningPlayer)
							end
						end
					end

					-- start the next match in the RoundInstance (if there are any left)

					task.delay(WINNER_CELEBRATION_DURATION, function()
						for _, winningPlayer in winningTeam.Players do
							EndMatchClient:SendToPlayer(winningPlayer)
							winningPlayer:LoadCharacter()
						end
						local nextMatch = RoundInstance.Matches[index + 1]
						if nextMatch then
							task.wait(2)
							RoundService:StartMatch(RoundInstance, nextMatch) -- start it after the winning team respawns.
						end
					end)

					return true
				end
				return false
			end
		)
		table.insert(matchPromises, matchPromise)
	end

	return Promise.all(matchPromises)
end

function RoundService:GetWinningTeam(Match: Types.Match): Types.Team?
	local teamsWithPlayers = {}
	for _, team in pairs(Match.Teams) do
		if #team.Killed ~= #team.Players then
			table.insert(teamsWithPlayers, team)
		end
	end
	if #teamsWithPlayers == 1 then
		return teamsWithPlayers[1]
	else
		return nil
	end
end

function RoundService:CreateRound(RoundMode: Types.RoundMode, MapName: string): Types.Round
	local playerPool = RoundService:GetAllPlayers()

	local Round = {
		Players = playerPool,
		Matches = RoundService:AllocateMatches(playerPool, RoundMode),
		RoundMode = RoundMode,
		Map = RoundService:LoadMap(MapName),
	}

	local roundModeExtension = RoundService:GetRoundModeExtension(RoundMode)
	if roundModeExtension.ExtraRoundProperties then
		-- add extra properties to the round instance (we assume none of these are tables we'd need to copy, just simple values)
		for key, value in pairs(roundModeExtension.ExtraRoundProperties) do
			Round[key] = value
		end
	end

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
	local RoundModeExtension = RoundService:GetRoundModeExtension(RoundMode)

	-- create a match for each team

	local numberOfMatches = math.ceil(#shuffledPool / (RoundModeData.TeamSize * RoundModeData.TeamsPerMatch))

	for _i = 1, numberOfMatches do
		local match = {
			Teams = {},
			MatchUUID = HttpService:GenerateGUID(false),
		}

		-- add any extra match properties from the round mode extension
		if RoundModeExtension and RoundModeExtension.ExtraMatchProperties then
			-- we don't expect to have any copying issues with these properties
			for key, value in pairs(RoundModeExtension.ExtraMatchProperties) do
				match[key] = value
			end
		end

		if #shuffledPool <= 1 then
			break -- no match should have only 1 player (uneven number of players in the pool). they will play in the next round.
		end
		for j = 1, RoundModeData.TeamsPerMatch do
			local teamName = RoundModeData.TeamNames[j]
			local teamInfo = Teams[teamName]

			local team = {
				Players = {},
				Killed = {},
				Name = teamName,
				Color = teamInfo.Color,
			}
			table.insert(match.Teams, team)
		end

		-- put a player in each team one by one until we run out of players in the pool or we fill all teams in the match
		local playersInMatch = 0
		local teamIndex = 1
		while playersInMatch < (RoundModeData.TeamSize * RoundModeData.TeamsPerMatch) and #shuffledPool > 0 do
			local player = table.remove(shuffledPool, 1)
			table.insert(match.Teams[teamIndex].Players, player)
			playersInMatch += 1
			teamIndex += 1
			if teamIndex > RoundModeData.TeamsPerMatch then
				teamIndex = 1
			end
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