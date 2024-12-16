local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local Components = require(ReplicatedStorage.ecs.components)
local Generic = require(script.Parent.Parent.Generic)
local Matter = require(ReplicatedStorage.packages.Matter)
local RoundService = require(Services.RoundService)
local Types = require(Constants.Types)

local JuggernautExtension = {
	Data = RoundService:GetRoundModeData("Juggernaut"),
	StartMatch = Generic.StartMatch,
} :: Types.RoundModeExtension

function JuggernautExtension.AllocateMatches(playerPool: { Player }): { Types.Match }
	local match = {} :: Types.Match
	match.MatchUUID = HttpService:GenerateGUID(false)
	match.Teams = {}

	for i = 1, 2 do
		local team = {}
		team.Killed = {}
		team.Entities = {}
		team.Name = i == 1 and "Juggernaut" or "Hunters"

		local teamSize = i == 1 and 1 or #playerPool -- Juggernaut team size is 1, Hunter team size is the rest of the players

		for _j = 1, teamSize do
			if #playerPool == 0 then
				break
			end
			local player = table.remove(playerPool, math.random(1, #playerPool))
			local playerEntityId = RoundService:GetEntityIdFromPlayer(player)
			table.insert(team.Entities, playerEntityId)
		end
		table.insert(match.Teams, team)
	end

	return { match }
end

function JuggernautExtension.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: Matter.World)
	Generic.StartMatch(Match, RoundInstance, World)

	local juggernautTeam = Match.Teams[1]

	local juggernautEntity = juggernautTeam.Entities[1]

	local healthComponent: Components.Health? = World:get(juggernautEntity, Components.Health)
	local renderable: Components.Renderable<Types.Character>? = World:get(juggernautEntity, Components.Renderable)

	if healthComponent then
		World:insert(
			juggernautEntity,
			healthComponent:patch({
				maxHealth = 750,
				health = 750,
				regenRate = 0,
			})
		)
	end

	if renderable then
		local highlight = Instance.new("Highlight")
		highlight.Parent = renderable.instance
	end
end

return JuggernautExtension
