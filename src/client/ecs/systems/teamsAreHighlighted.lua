--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = Players.LocalPlayer.PlayerScripts.controllers

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)
local SettingsController = require(Controllers.SettingsController)
local Teams = require(ReplicatedStorage.constants.Teams)
local Types = require(ReplicatedStorage.constants.Types)
local useCollectionService = require(ReplicatedStorage.ecs.hooks.useCollectionService)
local useSetting = require(ReplicatedStorage.ecs.hooks.useSetting)

type TeamChangeRecord = MatterTypes.WorldChangeRecord<Components.Team>

local function makeTeamHighlight(teamColor: Color3): Highlight
	local highlight = Instance.new("Highlight")
	highlight.OutlineColor = teamColor
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	return highlight
end

local function teamsAreHighlighted(world: Matter.World)
	for eid, teamRecord: TeamChangeRecord in world:queryChanged(Components.Team) do
		if not world:contains(eid) then
			continue
		end

		if teamRecord.new then
			local team = teamRecord.new
			local teamData = Teams[team.name]

			if teamData then
				local renderable: Components.Renderable<Types.Character>? = world:get(eid, Components.Renderable)
				if renderable then
					if (teamRecord.old and teamRecord.old.name ~= team.name) or not teamRecord.old then
						local myEntityId = (Players.LocalPlayer.Character :: any):GetAttribute("clientEntityId")

						if not myEntityId then
							return
						end -- not ready yet

						if myEntityId == eid then -- don't myself
							return
						else
							local myTeam = world:get(myEntityId, Components.Team)
							if myTeam and myTeam.name == team.name then -- only highlight the other team
								return
							end
						end

						local highlight = makeTeamHighlight(teamData.Color)
						highlight.Name = "TeamHighlight"
						highlight.OutlineTransparency = SettingsController:GetSetting("Team Outlines").Value :: number
							/ 100
						highlight.Parent = renderable.instance
						highlight:AddTag("TeamHighlight")
					end
				end
			end
		elseif teamRecord.new == nil and teamRecord.old then
			local renderable: Components.Renderable<Types.Character>? = world:get(eid, Components.Renderable)
			if renderable then
				local highlight = renderable.instance:FindFirstChild("TeamHighlight")
				if highlight then
					highlight:Destroy()
				end
			end
		end
	end

	for outlineTransparency in useSetting("Team Outlines") do
		for highlight: Highlight in useCollectionService("TeamHighlight") do
			highlight.OutlineTransparency = (outlineTransparency.Value / 100)
		end
	end
end

return teamsAreHighlighted
