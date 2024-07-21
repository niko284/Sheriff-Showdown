--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Achievements = require(ReplicatedStorage.constants.Achievements)
local Types = require(ReplicatedStorage.constants.Types)

local AchievementUtils = {}

function AchievementUtils.GetAchievementByUUID(Achievements: { Types.Achievement }, UUID: string): Types.Achievement?
	for _, Achievement in ipairs(Achievements) do
		if Achievement.UUID == UUID then
			return Achievement
		end
	end
	return nil
end

function AchievementUtils.GetAchievementInfoFromId(Id: number): Types.AchievementInfo
	for _, AchievementInfo in Achievements do
		if AchievementInfo.Id == Id then
			return AchievementInfo
		end
	end
	return nil :: any
end

return AchievementUtils
