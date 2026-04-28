--!strict

local Players = game:GetService("Players")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local Effects = require("@client/ecs/effects")
local SettingsController = require("@controllers/SettingsController")
local Teams = require("@constants/Teams")

local KillEffect = Effects.KillEffect

local function makeTeamHighlight(teamColor: Color3): Highlight
	local highlight = Instance.new("Highlight")
	highlight.OutlineColor = teamColor
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	return highlight
end

local function registerClientObservers(world: jecs.World, replecsClient: any)
	world:set(
		Components.Killed,
		jecs.OnAdd,
		function(entity: jecs.Entity, _id: jecs.Id, value: Components.Killed)
			local serverEid = replecsClient:get_server_entity(entity)
			if not serverEid then
				return
			end
			KillEffect.visualize(world, {
				killerServerEntityId = value.killerEntityId,
				killedServerEntityId = serverEid,
				replecsClient = replecsClient,
			})
		end
	)

	world:set(
		Components.Team,
		jecs.OnAdd,
		function(entity: jecs.Entity, _id: jecs.Id, value: Components.Team)
			local teamData = Teams[value.name]
			if not teamData then
				return
			end
			local renderable = world:get(entity, Components.Renderable)
			if not renderable then
				return
			end

			local myChar = Players.LocalPlayer.Character
			local myEid = myChar and myChar:GetAttribute("clientEntityId")
			if not myEid or myEid == entity then
				return
			end
			local myTeam = world:get(myEid, Components.Team)
			if myTeam and myTeam.name == value.name then
				return
			end

			local highlight = makeTeamHighlight(teamData.Color)
			highlight.Name = "TeamHighlight"
			highlight.OutlineTransparency = (SettingsController:GetSetting("Team Outlines").Value :: number) / 100
			highlight.Parent = renderable.instance
			highlight:AddTag("TeamHighlight")
		end
	)

	world:set(
		Components.Team,
		jecs.OnChange,
		function(entity: jecs.Entity, _id: jecs.Id, value: Components.Team)
			local renderable = world:get(entity, Components.Renderable)
			if not renderable then
				return
			end

			local existing = renderable.instance:FindFirstChild("TeamHighlight")
			if existing then
				existing:Destroy()
			end

			local teamData = Teams[value.name]
			if not teamData then
				return
			end

			local myChar = Players.LocalPlayer.Character
			local myEid = myChar and myChar:GetAttribute("clientEntityId")
			if not myEid or myEid == entity then
				return
			end
			local myTeam = world:get(myEid, Components.Team)
			if myTeam and myTeam.name == value.name then
				return
			end

			local highlight = makeTeamHighlight(teamData.Color)
			highlight.Name = "TeamHighlight"
			highlight.OutlineTransparency = (SettingsController:GetSetting("Team Outlines").Value :: number) / 100
			highlight.Parent = renderable.instance
			highlight:AddTag("TeamHighlight")
		end
	)

	world:set(
		Components.Team,
		jecs.OnRemove,
		function(entity: jecs.Entity)
			if not world:contains(entity) then
				return
			end
			local renderable = world:get(entity, Components.Renderable)
			if renderable then
				local highlight = renderable.instance:FindFirstChild("TeamHighlight")
				if highlight then
					highlight:Destroy()
				end
			end
		end
	)
end

return registerClientObservers
