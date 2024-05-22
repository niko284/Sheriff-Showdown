--!strict
-- Round Modes
-- January 25th, 2024
-- Nick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

local function AllOnSameTeam(RoundInstance: Types.Round): boolean
	local Players = RoundInstance.Players

	for _, Match in pairs(RoundInstance.Matches) do
		for _, Team in pairs(Match.Teams) do
			local TeamPlayers = Team.Players

			local allInTeam = true

			for _, Player in pairs(Players) do
				if not table.find(TeamPlayers, Player) then
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
	{
		Name = "Singles",
		TeamSize = 1,
		TeamsPerMatch = 2,
		TeamNames = { "Red", "Blue" },
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
	},
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
	{
		Name = "Distraction",
		UseSpawnType = "Singles",
		TeamSize = 1,
		TeamsPerMatch = 2,
		TeamNames = { "Red", "Blue" },
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
	},
} :: { Types.RoundModeData }
