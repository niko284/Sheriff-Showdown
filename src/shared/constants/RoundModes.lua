--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Types = require("@constants/Types")

local function AllOnSameTeam(RoundInstance: Types.Round): boolean
	local RoundService = require("@services/RoundService") :: any

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
		Description = "One super-strong player vs everyone else. Team up to stop them!",
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
		UseSpawnType = "FFA",
		Image = 77237596598471,
		TimeLimit = 60 * 3,
	},
	{
		Name = "Revolver Relay",
		Description = "Dodge the gun wielder! When they miss, the gun moves to someone new.",
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
		TimeLimit = 60 * 3,
	},
	{
		Name = "Hot Potato",
		Description = "You’ve got the gun! Shoot someone to pass it on before it explodes in your hands!",
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
		Description = "Two teams fight—Red vs Blue. Work together to win!",
		IsGameOver = function(RoundInstance: Types.Round)
			-- the game is over when the player pool consists of only people that were in the same team last round.
			return AllOnSameTeam(RoundInstance)
		end,
		UseSpawnType = "RVB",
		Image = 100074347186146,
		TimeLimit = 60 * 3,
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
		Description = "It’s every player for themselves! Shoot and dodge to be the last one standing!",
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
		TimeLimit = 60 * 3,
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
