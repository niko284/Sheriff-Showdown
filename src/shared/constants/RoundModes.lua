--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ReplicatedStorage.constants.Types)

local function AllOnSameTeam(RoundInstance: Types.Round): boolean
	local RoundService = require(ServerScriptService.services.RoundService) :: any

	local Players = RoundInstance.Players

	for _, Match in pairs(RoundInstance.Matches) do
		for _, Team in pairs(Match.Teams) do
			local TeamEntities = Team.Entities

			local allInTeam = true

			for _, Player in pairs(Players) do
				if not table.find(TeamEntities, RoundService:GetEntityIdFromPlayer(Player)) then
					allInTeam = false
					break
				end
			end

			if allInTeam then
				return true
			end
		end
	end

	return false
end

return {
	--[[{
		Name = "Singles",
		TeamSize = 1,
		TeamsPerMatch = 2,
		TeamNames = { "Red", "Blue" },
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
	},--]]
	{
		Name = "Duos",
		TeamSize = 2,
		TeamsPerMatch = 2,
		TeamNames = { "Red", "Blue" },
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
	},
	--[[{
		Name = "Distraction",
		UseSpawnType = "Singles",
		TeamSize = 1,
		TeamsPerMatch = 2,
		TeamNames = { "Red", "Blue" },
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
	},--]]
} :: { Types.RoundModeData }
