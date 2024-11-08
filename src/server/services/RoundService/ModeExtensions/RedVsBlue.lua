local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local Generic = require(script.Parent.Parent.Generic)
local RoundService = require(Services.RoundService)
local Types = require(Constants.Types)

local RVBExtension = {
	Data = RoundService:GetRoundModeData("Red vs Blue"),
	StartMatch = Generic.StartMatch,
} :: Types.RoundModeExtension

function RVBExtension.AllocateMatches(playerPool: { Player }): { Types.Match }
	local match = {} :: Types.Match
	match.MatchUUID = HttpService:GenerateGUID(false)

	for i = 1, 2 do
		local team = {} :: Types.Team
		team.Killed = {}
		team.Entities = {}
		team.Name = i == 1 and "Red" or "Blue"

		local teamSize = math.ceil(#playerPool / 2)
		for _j = 1, teamSize do
			if #playerPool == 0 then
				break
			end
			local player = table.remove(playerPool, math.random(1, #playerPool))
			local playerEntityId = RoundService:GetEntityIdFromPlayer(player)
			table.insert(team.Entities, playerEntityId)
		end
	end

	return { match }
end

return RVBExtension
