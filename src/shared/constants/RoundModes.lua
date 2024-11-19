--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ReplicatedStorage.constants.Types)

local function AllOnSameTeam(RoundInstance: Types.Round): boolean
	local RoundService = require(ServerScriptService.services.RoundService) :: any

	local plrsInMatch = RoundInstance.Players

	for _, Match in pairs(RoundInstance.Matches) do
		for _, Team in pairs(Match.Teams) do
			local TeamEntities = Team.Entities

			local allInTeam = true

			for _, Player in pairs(plrsInMatch) do
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
		Name = "Juggernaut",
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
		UseSpawnType = "FFA",
		Image = 77237596598471,
	},
	{
		Name = "Revolver Relay",
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
		UseSpawnType = "FFA",
		TeamSize = 1,
		TeamsPerMatch = function()
			return #Players:GetPlayers()
		end,
		Image = 99452383534143,
	},
	{
		Name = "Hot Potato",
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
		UseSpawnType = "FFA",
		TeamSize = 1,
		TeamsPerMatch = function()
			return #Players:GetPlayers()
		end,
		Image = 75034171719400,
	},
	{
		Name = "Red vs Blue",
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
		UseSpawnType = "RVB",
		Image = 100074347186146,
	},
	--[[{
		Name = "Duos",
		TeamSize = 2,
		TeamsPerMatch = 2,
		TeamNames = { "Red", "Blue" },
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
	},--]]
	{
		Name = "Free For All",
		TeamSize = 1,
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
		TeamsPerMatch = function()
			return #Players:GetPlayers()
		end,
		UseSpawnType = "FFA",
		Image = 73093599523132,
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
