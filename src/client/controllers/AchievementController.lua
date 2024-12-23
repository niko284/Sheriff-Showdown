--!strict

-- Achievement Controller
-- July 4th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages

local Achievements = require(Constants.Achievements)
local Net = require(Packages.Net)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local AchievementsNamespace = Remotes.Client:GetNamespace("Achievements")
local AchievementsChanged = AchievementsNamespace:Get("AchievementsChanged") :: Net.ClientListenerEvent
local GetAchievements = AchievementsNamespace:Get("GetAchievements") :: Net.ClientAsyncCaller

-- // Controller Variables \\

local AchievementController = {
	Name = "AchievementController",
	Achievements = {},
	AchievementCompleted = Signal.new(),
	PartialAchievementsChanged = Signal.new() :: Signal.Signal<Types.PlayerAchievements>,
}

-- // Functions \\

function AchievementController:Init()
	AchievementsChanged:Connect(function(partialAchievementState)
		AchievementController.PartialAchievementsChanged:Fire(partialAchievementState)
	end)
end

function AchievementController:IsAchievementCompleted(Achievement: Types.Achievement): boolean
	for _, requirement in Achievement.Requirements do
		if requirement.Progress < requirement.Goal then
			return false
		end
	end
	return true
end

function AchievementController:CanAchievementProgress(Achievement: Types.Achievement): boolean
	local AchievementInfo = AchievementController:GetAchievementInfoFromId(Achievement.Id) :: Types.AchievementInfo
	-- An achievement can progress if it has a requirement that is progressive. (contains the Increment property), and is not at a Maximum if it has one.
	for i, requirement in Achievement.Requirements do
		local requirementInfo = AchievementInfo.Requirements[i]
		if requirementInfo.Increment then
			if requirementInfo.Maximum then
				local increment = if typeof(requirementInfo.Increment) == "function"
					then requirementInfo.Increment(requirement.Goal)
					else requirementInfo.Increment
				local newGoal = requirement.Goal + increment
				if newGoal <= requirementInfo.Maximum then
					return true
				end
			else
				return true
			end
		end
	end
	return false
end

function AchievementController:GetRequirementName(Achievement: Types.Achievement, RequirementIndex: number): string
	local achievementInfo = AchievementController:GetAchievementInfoFromId(Achievement.Id)
	if not achievementInfo then
		return "Unknown"
	end
	local requirement: Types.AchievementRequirement = Achievement.Requirements[RequirementIndex]
	local requirementInfo = achievementInfo.Requirements[RequirementIndex]
	-- go through every string that's wrapped in []
	local requirementName = requirementInfo.BaseName
	local newName = string.gsub(requirementName, "%b[]", function(wrappedString)
		local stringToReplace = string.sub(wrappedString, 2, #wrappedString - 1)
		local value = requirement[stringToReplace] or requirementInfo[stringToReplace :: any]
		if value then
			return value
		end
		return wrappedString
	end)
	return newName
end

function AchievementController:GetAchievementInfoFromId(Id: number): Types.AchievementInfo?
	for _, achievementInfo in Achievements do
		if achievementInfo.Id == Id then
			return achievementInfo
		end
	end
	return nil
end

function AchievementController:GetAchievementsFromServer()
	return GetAchievements:CallServerAsync():expect()
end

return AchievementController
