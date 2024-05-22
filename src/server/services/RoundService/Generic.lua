-- Generic
-- April 12th, 2024
-- Nick

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services
local Packages = ReplicatedStorage.packages

local ActionService = require(Services.ActionService)
local Promise = require(Packages.Promise)
local RoundService = require(Services.RoundService)
local Types = require(Constants.Types)

-- Generic functions that are used in our Round Service, particularly our mode extensions.
local Generic = {}

function Generic.StartMatch(Match: Types.Match)
	local START_MATCH_TIMESTAMP = os.time() + 8 -- start the match in 8 seconds
	RoundService.StartMatchTimestamp:Set(START_MATCH_TIMESTAMP)

	repeat
		RunService.Heartbeat:Wait()
	until os.time() >= START_MATCH_TIMESTAMP

	-- start the match
	for _, team in pairs(Match.Teams) do
		for _, player in team.Players do
			ActionService:ToggleCombatSystem(true, player) -- enable combat system for the player
		end
	end
end

function Generic.GetCurrentMatchForPlayer(Player: Player): Types.Match?
	local currentRound = RoundService:GetRound()
	if currentRound then
		for _, match in currentRound.Matches do
			for _, team in match.Teams do
				for _, playerInTeam in team.Players do
					if playerInTeam == Player then
						return match
					end
				end
			end
		end
	end
	return nil
end

function Generic.GetPlayersInMatch(Match: Types.Match): { Player }
	local playersInMatch = {}
	for _, Teams in pairs(Match.Teams) do
		for _, player in Teams.Players do
			table.insert(playersInMatch, player)
		end
	end
	return playersInMatch
end

function Generic.MatchFinishedPromise(Match: Types.Match)
	return Promise.fromEvent(RoundService.MatchFinished, function(MatchUUID: string, _WinningTeam: Types.Team)
		return MatchUUID == Match.MatchUUID
	end)
end

return Generic
