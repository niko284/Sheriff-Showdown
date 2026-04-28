--!strict

local HttpService = game:GetService("HttpService")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local Generic = require("../Generic")
local RoundService = require("@services/RoundService")
local Types = require("@constants/Types")

local JuggernautExtension = {
	Data = RoundService:GetRoundModeData("Juggernaut"),
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

		local teamSize = i == 1 and 1 or #playerPool

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

function JuggernautExtension.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: jecs.World)
	Generic.StartMatch(Match, RoundInstance, World)

	local juggernautTeam = Match.Teams[1]
	local juggernautEntity = juggernautTeam.Entities[1]

	local health: Components.Health? = World:get(juggernautEntity, Components.Health)
	local renderable: Components.Renderable? = World:get(juggernautEntity, Components.Renderable)

	if health then
		World:set(juggernautEntity, Components.Health, {
			health = 750,
			maxHealth = 750,
			regenRate = health.regenRate,
		})
	end

	if renderable then
		local highlight = Instance.new("Highlight")
		highlight.Parent = renderable.instance
	end
end

return JuggernautExtension
