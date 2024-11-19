--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services

local PlayerDataService = require(Services.PlayerDataService)
local ResourceService = require(Services.ResourceService)

local LEVEL_CAP = math.huge -- We manually set this in the future updates.

-- // Service Variables \\

local ExperienceService = {
	Name = "ExperienceService",
}

-- // Functions \\

function ExperienceService:GetExperienceForLevel(Level: number): number
	return math.round(((1880 * math.pow(Level / 9, 2.85) + 85 * math.pow(Level + 1, 1.6)) - 230))
end

function ExperienceService:GetAmassedExperienceForLevel(Level: number): number
	local Experience = 0
	for i = 1, Level do
		Experience = Experience + ExperienceService:GetExperienceForLevel(i)
	end
	return Experience
end

function ExperienceService:AddExperience(Player: Player, Experience: number)
	local playerDocument = PlayerDataService:GetDocument(Player)
	if not playerDocument then
		return
	end
	local PlayerResources = playerDocument:read().Resources
	local CurrentExperience = PlayerResources.Experience
	local RequiredExperience = ExperienceService:GetExperienceForLevel(PlayerResources.Level + 1)

	if PlayerResources.Level >= LEVEL_CAP then
		return
	end

	if CurrentExperience + Experience >= RequiredExperience then
		local OverflowExperience = (Experience + CurrentExperience) - RequiredExperience
		ResourceService:IncrementResource(Player, "Level", 1)
		ExperienceService:SetExperience(Player, 0)
		ExperienceService:AddExperience(Player, OverflowExperience)
	elseif CurrentExperience + Experience == RequiredExperience then
		ResourceService:IncrementResource(Player, "Level", 1)
		ExperienceService:SetExperience(Player, 0)
	else
		ResourceService:IncrementResource(Player, "Experience", Experience)
	end
end

function ExperienceService:SetExperience(Player: Player, Experience: number)
	local playerDocument = PlayerDataService:GetDocument(Player)
	if not playerDocument then
		return
	end
	local resources = playerDocument:read().Resources
	local RequiredExperience = ExperienceService:GetExperienceForLevel(resources.Level + 1)
	if Experience >= RequiredExperience then
		local OverflowExperience = Experience - RequiredExperience
		ResourceService:IncrementResource(Player, "Level", 1)
		ExperienceService:AddExperience(Player, OverflowExperience)
	elseif Experience == RequiredExperience then
		ResourceService:IncrementResource(Player, "Level", 1)
		ExperienceService:SetExperience(Player, 0)
	else
		ResourceService:SetResource(Player, "Experience", Experience)
	end
end

return ExperienceService
