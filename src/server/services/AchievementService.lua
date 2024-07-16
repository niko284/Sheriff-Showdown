--!strict

-- Achievement Service
-- July 4th, 2022 (In the plane)
-- Nick

-- // Variables \\

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local Achievements = require(Constants.Achievements)
local Freeze = require(Packages.Freeze)
local Net = require(Packages.Net)
local PlayerDataService = require(Services.PlayerDataService)
local Remotes = require(ReplicatedStorage.network.Remotes)
local ResourceService = require(Services.ResourceService)
local Sift = require(Packages.Sift)
local Signal = require(Packages.Signal)
local StatisticsService = require(Services.StatisticsService)
local Timer = require(Packages.Timer)
local Types = require(Constants.Types)

local AchievementsNamespace = Remotes.Server:GetNamespace("Achievements")

local ClaimAchievement = AchievementsNamespace:Get("ClaimAchievement") :: Net.ServerAsyncCallback
local AchievementsChanged = AchievementsNamespace:Get("AchievementsChanged") :: Net.ServerSenderEvent
local GetAchievements = AchievementsNamespace:Get("GetAchievements") :: Net.ServerAsyncCallback

local DAILY_ACHIEVEMENT_COUNT = 5 -- Number of daily achievements to give a player.

-- // Service Variables \\

local AchievementService = {
	Name = "AchievementService",
	AchievementCompleted = Signal.new(), -- Fires when a player finishes an achievement
	AchievementClaimed = Signal.new(), -- Fires when a player claims an achievement
	Achievements = {} :: { Types.AchievementInfo },
	NewRewardTimers = {} :: { any }, -- Listeners incase player daily rewards need to rotate.
}

-- // Functions \\

function AchievementService:Init()
	-- Let's tag each achievement with it's respective ID.
	-- selene: allow(undefined_variable)
	for _, Achievement in Achievements do
		AchievementService.Achievements[Achievement.Id] = Achievement
	end
	ClaimAchievement:SetCallback(function(Player: Player, AchievementUUID: string)
		return AchievementService:ClaimAchievementRequest(Player, AchievementUUID)
	end)
	GetAchievements:SetCallback(function(Player: Player)
		local playerDocument = PlayerDataService:GetDocument(Player)
		if not playerDocument then
			return nil
		else
			return playerDocument:read().Achievements
		end
	end)
end

function AchievementService:Start()
	PlayerDataService.DocumentLoaded:Connect(function(Player: Player, PlayerDocument)
		-- Fill in progressive achievements.
		for _, AchievementInfo: Types.AchievementInfo in AchievementService.Achievements do
			-- If they don't have the progressive achievement, add it.
			if
				(AchievementInfo.Type == "Progressive" or AchievementInfo.Type == "Event")
				and AchievementService:HasAchievement(Player, AchievementInfo.Id) == false
			then
				-- if this is an achievement that expires, check if it's expired.
				if AchievementInfo.ExpirationTime and os.time() >= AchievementInfo.ExpirationTime then
					continue
				end

				local data = PlayerDocument:read()
				PlayerDocument:write(
					Freeze.Dictionary.setIn(
						data,
						{ "Achievements", "ActiveAchievements" },
						Freeze.List.push(data.Achievements.ActiveAchievements, {
							Id = AchievementInfo.Id,
							UUID = HttpService:GenerateGUID(false),
							Claimed = false,
							Requirements = Sift.Array.map(AchievementInfo.Requirements, function(Requirement)
								return {
									Progress = AchievementService:GetCurrentProgress(Player, Requirement),
									Goal = Requirement.Goal,
									Completed = AchievementService:GetCurrentProgress(Player, Requirement)
										>= Requirement.Goal,
								}
							end),
							TimesClaimed = 0,
						})
					)
				)
			elseif
				AchievementInfo.Type == "Progressive"
				and AchievementService:HasAchievement(Player, AchievementInfo.Id) == true
			then
				local numberOfSameAchievements = 0
				local newAchievements = table.clone(PlayerDocument:read().Achievements)
				local newActiveAchievements = table.clone(newAchievements.ActiveAchievements)

				for _, ActiveAchievement in pairs(newActiveAchievements) do
					if ActiveAchievement.Id == AchievementInfo.Id then
						numberOfSameAchievements = numberOfSameAchievements + 1
					end
				end
				-- remove all but one of the same achievements
				if numberOfSameAchievements > 1 then
					repeat
						for index, ActiveAchievement in pairs(newActiveAchievements) do
							if ActiveAchievement.Id == AchievementInfo.Id then
								table.remove(newActiveAchievements, index)
								break
							end
						end
						numberOfSameAchievements = numberOfSameAchievements - 1
					until numberOfSameAchievements == 1
				end

				newAchievements.ActiveAchievements = newActiveAchievements
				PlayerDocument:write(
					Freeze.Dictionary.setIn(PlayerDocument:read(), { "Achievements" }, newAchievements)
				)
			end
		end

		-- Remove any deprecated or expired achievements.

		local playerAchievements = PlayerDocument:read().Achievements

		PlayerDocument:write(
			Freeze.Dictionary.setIn(
				PlayerDocument:read(),
				{ "Achievements", "ActiveAchievements" },
				Freeze.List.filter(playerAchievements.ActiveAchievements, function(ActiveAchievement: Types.Achievement)
					local achievementInfo = AchievementService:GetAchievementFromId(ActiveAchievement.Id)

					if not achievementInfo then
						return false
					end

					if achievementInfo.ExpirationTime and os.time() >= achievementInfo.ExpirationTime then
						return false
					end

					return not achievementInfo.Deprecated
				end)
			)
		)

		playerAchievements = table.clone(PlayerDocument:read().Achievements) -- update playerAchievements and unfreeze it.

		if playerAchievements.LastDailyRotation == -1 then -- first time
			playerAchievements.LastDailyRotation = os.time()
			playerAchievements.ActiveAchievements = Sift.Array.concat(
				playerAchievements.ActiveAchievements,
				AchievementService:GenerateRandomAchievements(Player, DAILY_ACHIEVEMENT_COUNT, "Daily")
			)
		else
			local timeSinceLastRotation = os.time() - playerAchievements.LastDailyRotation
			local timeElapsedHours = timeSinceLastRotation / 3600
			if timeElapsedHours >= 24 then
				-- 24 hours have passed, rotate the achievements.
				playerAchievements.LastDailyRotation = os.time()
				local newAchievements =
					AchievementService:GenerateRandomAchievements(Player, DAILY_ACHIEVEMENT_COUNT, "Daily")
				playerAchievements.ActiveAchievements = Sift.Array.concat(
					Sift.Array.filter(
						playerAchievements.ActiveAchievements,
						function(ActiveAchievement: Types.Achievement)
							local achievementInfo = AchievementService:GetAchievementFromId(ActiveAchievement.Id)
							return achievementInfo.Type ~= "Daily" -- Remove all daily achievements.
						end
					),
					newAchievements -- Add new daily achievements.
				)
			end
		end

		PlayerDocument:write(Freeze.Dictionary.setIn(PlayerDocument:read(), { "Achievements" }, playerAchievements))

		-- Update progress for all achievements.
		for _, ActiveAchievement in playerAchievements.ActiveAchievements do
			local achievementInfo =
				AchievementService:GetAchievementFromId(ActiveAchievement.Id) :: Types.AchievementInfo
			for requirementIndex, _requirement in ActiveAchievement.Requirements do
				local requirementInfo = achievementInfo.Requirements[requirementIndex]
				AchievementService:RegisterAchievementProgress(
					Player,
					requirementInfo.Action,
					requirementInfo.Statistic :: string
				)
			end
		end

		AchievementService.NewRewardTimers[Player.UserId :: any] =
			AchievementService:ListenForDailyRotation(Player, playerAchievements.LastDailyRotation)
		AchievementsChanged:SendToPlayer(Player, PlayerDocument:read().Achievements) -- Send client their achievements once their data loads in. We don't use playerAchievements here because it might've changed when updating progress.
	end)
	local Listening = {}
	local StatisticListening = {}
	local _ResourceListeners = Sift.Array.map(Achievements, function(achievement: Types.AchievementInfo)
		for _, requirement in achievement.Requirements do
			if
				requirement.Action == "Resource"
				and requirement.Resource
				and not table.find(Listening, requirement.Resource)
			then
				return ResourceService:ObserveResourceChanged(
					requirement.Resource,
					function(Player: Player, _NewValue: number, OldValue: number?)
						AchievementService:RegisterAchievementProgress(
							Player,
							"Resource",
							requirement.Resource,
							OldValue
						)
					end :: any
				)
			end
		end
		return Sift.None
	end)
	local _StatisticListeners = Sift.Array.map(Achievements, function(achievement: Types.AchievementInfo)
		for _, requirement in achievement.Requirements do
			if
				requirement.Action == "Statistic"
				and requirement.Statistic
				and not table.find(StatisticListening, requirement.Statistic)
			then
				return StatisticsService:ObserveStatisticChanged(
					requirement.Statistic,
					function(Player: Player, _NewValue: number, OldValue: number?)
						AchievementService:RegisterAchievementProgress(
							Player,
							"Statistic",
							requirement.Statistic,
							OldValue
						)
					end
				)
			end
		end
		return Sift.None
	end)
end

function AchievementService:OnPlayerRemoving(Player: Player)
	local rotationTimer = AchievementService.NewRewardTimers[Player.UserId]
	if rotationTimer then
		rotationTimer:Stop()
		rotationTimer:Destroy()
		AchievementService.NewRewardTimers[Player.UserId] = nil
	end
end

function AchievementService:RotateDailyAchievements(Player: Player)
	local playerDocument = PlayerDataService:GetDocument(Player)
	if playerDocument then
		local playerData = playerDocument:read()
		local playerAchievements = table.clone(playerData.Achievements)

		playerAchievements.LastDailyRotation = os.time()
		local newAchievements = AchievementService:GenerateRandomAchievements(Player, DAILY_ACHIEVEMENT_COUNT, "Daily")

		playerAchievements.ActiveAchievements = Sift.Array.concat(
			Sift.Array.filter(playerAchievements.ActiveAchievements, function(ActiveAchievement: Types.Achievement)
				local achievementInfo = AchievementService:GetAchievementFromId(ActiveAchievement.Id)
				return achievementInfo.Type ~= "Daily" -- Remove all daily achievements.
			end),
			newAchievements -- Add new daily achievements.
		)

		AchievementsChanged:SendToPlayer(Player, playerAchievements)
		AchievementService.NewRewardTimers[Player.UserId] =
			AchievementService:ListenForDailyRotation(Player, playerAchievements.LastDailyRotation)

		playerDocument:write(Freeze.Dictionary.setIn(playerData, { "Achievements" }, playerAchievements))
	end
end

function AchievementService:ListenForDailyRotation(Player: Player, LastDailyRotation: number)
	local nextDailyRotation = LastDailyRotation + 86400
	local rotationTimer = Timer.new(5)
	rotationTimer.Tick:Connect(function()
		local timeLeft = nextDailyRotation - os.time()
		if timeLeft <= 0 then
			rotationTimer:Stop()
			rotationTimer:Destroy()
			AchievementService:RotateDailyAchievements(Player)
		end
	end)
	rotationTimer:StartNow()
	return rotationTimer
end

function AchievementService:RegisterAchievementProgress(
	Player: Player,
	ActionType: Types.AchievementRequirementAction,
	ActionTypeName: string,
	OldValue: number?,
	IncrementProgressBy: number?
)
	local playerDocument = PlayerDataService:GetDocument(Player)
	local currentActiveAchievements = playerDocument:read().Achievements.ActiveAchievements

	local associatedAchievements = Sift.Array.filter(currentActiveAchievements, function(achievement: Types.Achievement)
		-- Check if any of the requirements are the statistic we're listening for.
		local achievementInfo = AchievementService:GetAchievementFromId(achievement.Id) :: Types.AchievementInfo
		return Sift.Array.some(
			achievement.Requirements,
			function(_requirement: Types.AchievementRequirement, index: number)
				local requirementInfo = achievementInfo.Requirements[index]
				local passesFilter = requirementInfo.Action == ActionType
					and requirementInfo[ActionType] == ActionTypeName
				return passesFilter
			end
		)
	end)

	for _, achievement in associatedAchievements do
		-- Loop through each requirement, if it's the statistic we're listening for, update it.
		for requirementIndex, requirement in achievement.Requirements do
			-- if we don't have a new value for some reason, just continue.

			local NewVal = nil
			if ActionType == "Resource" then
				NewVal = ResourceService:GetResource(Player, ActionTypeName) :: number
			elseif ActionType == "Statistic" then
				NewVal = StatisticsService:GetStatistic(Player, ActionTypeName) :: number
			elseif ActionType == "Custom" and IncrementProgressBy then
				NewVal = requirement.Progress + IncrementProgressBy
			end

			if not NewVal then
				continue
			end

			local achievementInfo = AchievementService:GetAchievementFromId(achievement.Id) :: Types.AchievementInfo
			local requirementInfo = achievementInfo.Requirements[requirementIndex]
			if requirementInfo.UseDelta and OldValue then
				local delta = NewVal - OldValue
				NewVal = requirement.Progress + delta -- For requirements specifying a delta, we add the delta to the current progress as our new value instead.
			elseif requirementInfo.UseDelta and not OldValue then
				continue -- We don't have an old value to compare to, so we can't register progress for this requirement.
			end
			AchievementService:UpdateRequirementProgress(Player, achievement.UUID, requirementIndex, NewVal)
		end
	end

	-- Send the partial state update to the client
	-- @IMPORTANT: Our UpdateRequirementProgress function will clone achievement tables when updating them, so we can compare the old and new tables to see if anything changed.
	local changedActiveAchievements = {}
	local newActiveAchievements = playerDocument:read().Achievements.ActiveAchievements -- was updated above w/ UpdateRequirementProgress

	for _, achievement in associatedAchievements do
		local oldAchievementIndex = Sift.Array.findWhere(
			currentActiveAchievements,
			function(_achievement: Types.Achievement)
				return _achievement.UUID == achievement.UUID
			end
		)
		if oldAchievementIndex then
			local newAchievementIndex = Sift.Array.findWhere(
				newActiveAchievements,
				function(_achievement: Types.Achievement)
					return _achievement.UUID == achievement.UUID
				end
			)
			if
				newAchievementIndex
				and newActiveAchievements[newAchievementIndex] ~= currentActiveAchievements[oldAchievementIndex]
			then
				changedActiveAchievements[newAchievementIndex] = newActiveAchievements[newAchievementIndex]
			end
		end
	end

	AchievementsChanged:SendToPlayer(Player, {
		ActiveAchievements = changedActiveAchievements,
	}) -- Update client
end

function AchievementService:UpdateRequirementProgress(
	Player: Player,
	AchievementUUID: string,
	requirementIndex: number,
	NewValue: number
): boolean
	local playerDocument = PlayerDataService:GetDocument(Player)
	local playerData = playerDocument:read()
	local playerAchievements = playerData.Achievements

	for index, Achievement in playerAchievements.ActiveAchievements do
		if Achievement.UUID == AchievementUUID then
			local newActiveAchievements = table.clone(playerAchievements.ActiveAchievements)
			local newAchievement = table.clone(Achievement)
			local requirement = newAchievement.Requirements[requirementIndex]
			requirement = table.clone(requirement)
			requirement.Progress = NewValue
			newAchievement.Requirements[requirementIndex] = requirement
			newActiveAchievements[index] = newAchievement

			playerDocument:write(
				Freeze.Dictionary.setIn(playerData, { "Achievements", "ActiveAchievements" }, newActiveAchievements)
			)

			return true
		end
	end
	return false
end

function AchievementService:GetCurrentProgress(Player: Player, Requirement: Types.AchievementRequirementInfo): any?
	if Requirement.UseDelta then
		return Requirement.Progress -- start from scratch (0) if we're using a delta.
	end

	if Requirement.Action == "Resource" and Requirement.Resource then
		return ResourceService:GetResource(Player, Requirement.Resource)
	elseif Requirement.Action == "Statistic" and Requirement.Statistic then
		return StatisticsService:GetStatistic(Player, Requirement.Statistic)
	elseif Requirement.Progress then
		return Requirement.Progress -- Some achievements have a starting and static progress value, usually for non-progressive achievements.
	end
	return nil
end

function AchievementService:HasAchievement(Player: Player, AchievementId: number): boolean
	local playerDocument = PlayerDataService:GetDocument(Player)
	local playerData = playerDocument:read()

	local playerAchievements = playerData.Achievements

	for _, achievement in playerAchievements.ActiveAchievements do
		if achievement.Id == AchievementId then
			return true
		end
	end
	return false
end

function AchievementService:GenerateRandomAchievements(
	Player: Player,
	Amount: number,
	AchievementType: Types.AchievementType?
): { Types.Achievement }
	-- Generate 'Amount' number of achievements.
	local randomAchievements = {}
	local achievementList = table.clone(AchievementService.Achievements)
	local seed = Random.new()
	for _i = 1, Amount do
		if #achievementList == 0 then
			break -- We've run out of achievements to generate.
		end
		local randomIndex = seed:NextInteger(1, #achievementList)
		local randomAchievement = achievementList[randomIndex] :: Types.AchievementInfo
		if (AchievementType and randomAchievement.Type ~= AchievementType) or randomAchievement.Deprecated then
			table.remove(achievementList, randomIndex)
			repeat
				randomIndex = seed:NextInteger(1, #achievementList)
				randomAchievement = achievementList[randomIndex]
				table.remove(achievementList, randomIndex)
			until #achievementList == 0
				or (randomAchievement.Type == AchievementType and not randomAchievement.Deprecated)
		end
		if table.find(achievementList, randomAchievement) then
			table.remove(achievementList, randomIndex)
		end
		if not randomAchievement then
			break -- We've run out of achievements to generate.
		end

		-- if achievement list is empty, the random achievement we chose better be the type we want and not deprecated.. otherwise break out of the loop.
		-- note: there was a bug where we'd get duplicate ongoing achievements, this if statement fixes that.
		if #achievementList == 0 and (randomAchievement.Type ~= AchievementType or randomAchievement.Deprecated) then
			break
		end

		table.insert(randomAchievements, {
			Id = randomAchievement.Id, -- we can use this to get information about the achievement
			UUID = HttpService:GenerateGUID(false),
			Claimed = false,
			Requirements = Sift.Array.map(
				randomAchievement.Requirements,
				function(Requirement: Types.AchievementRequirementInfo)
					return {
						Progress = AchievementService:GetCurrentProgress(Player, Requirement),
						Goal = Requirement.Goal,
						Completed = AchievementService:GetCurrentProgress(Player, Requirement) >= Requirement.Goal,
					}
				end
			),
			TimesClaimed = 0,
		})
	end
	return randomAchievements
end

function AchievementService:ClaimAchievement(Player: Player, Achievement: Types.Achievement): boolean
	local playerDocument = PlayerDataService:GetDocument(Player)
	local playerAchievements = playerDocument:read().Achievements

	for index, achievement in playerAchievements.ActiveAchievements do
		if achievement.UUID == Achievement.UUID then
			local newActiveAchievements = table.clone(playerAchievements.ActiveAchievements)
			local newAchievement = table.clone(achievement) :: Types.Achievement

			newActiveAchievements[index] = newAchievement

			-- if it's progress based, we need to update our goal to the next one
			local achievementInfo = AchievementService:GetAchievementFromId(newAchievement.Id) :: Types.AchievementInfo
			if AchievementService:CanAchievementProgress(newAchievement) == true then -- Progress our achievement if we can. Otherwise, just claim it permanently.
				for requirementIndex, requirement in newAchievement.Requirements do
					local requirementInfo = achievementInfo.Requirements[requirementIndex]
					if requirementInfo.Increment then
						local increment = if typeof(requirementInfo.Increment) == "function"
							then requirementInfo.Increment(requirement.Goal)
							else requirementInfo.Increment
						requirement.Goal = requirement.Goal + increment
						if requirementInfo.ResetProgressOnIncrement then
							requirement.Progress = 0
						end
					end
				end
			else
				-- otherwise, just claim it permanently. we don't need to update anything.
				newAchievement.Claimed = true
			end

			AchievementService:GrantAchievementReward(Player, newAchievement)

			-- after granting reward above, update times claimed
			if newAchievement.TimesClaimed then
				newAchievement.TimesClaimed += 1
			else
				newAchievement.TimesClaimed = 1
			end

			AchievementService.AchievementClaimed:Fire(Player, newAchievement)

			playerDocument:write(
				Freeze.Dictionary.setIn(
					playerDocument:read(),
					{ "Achievements", "ActiveAchievements" },
					newActiveAchievements
				)
			)

			return true
		end
	end
	return false
end

function AchievementService:CanAchievementProgress(Achievement: Types.Achievement): boolean
	local AchievementInfo = AchievementService:GetAchievementFromId(Achievement.Id) :: Types.AchievementInfo
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

function AchievementService:GrantAchievementReward(Player: Player, Achievement: Types.Achievement)
	local achievementInfo = AchievementService:GetAchievementFromId(Achievement.Id) :: Types.AchievementInfo
	if achievementInfo.Rewards then
		for _, reward in achievementInfo.Rewards do -- loop through all rewards
			if reward.Type == "Currency" and reward.Amount then
				local amount = if typeof(reward.Amount) == "function"
					then reward.Amount(Achievement.TimesClaimed or 0)
					else reward.Amount
				ResourceService:IncrementResource(Player, reward.Currency, amount)
			end
		end
	end
end

function AchievementService:IsAchievementCompleted(Achievement: Types.Achievement): boolean
	-- For an achievement to be completed, all of its requirements must be completed.
	for _, requirement in Achievement.Requirements do
		if requirement.Progress < requirement.Goal then
			return false
		end
	end
	return true
end

function AchievementService:ClaimAchievementRequest(Player: Player, AchievementUUID: string): Types.NetworkResponse
	local playerDocument = PlayerDataService:GetDocument(Player)
	if not playerDocument then
		return {
			Success = false,
			Response = "Failed to get player document.",
		}
	end
	local playerAchievements = playerDocument:read().Achievements
	local achievementIndex = Sift.Array.findWhere(
		playerAchievements.ActiveAchievements,
		function(achievement: Types.Achievement)
			return achievement.UUID == AchievementUUID
		end
	)
	if not achievementIndex then
		return {
			Success = false,
			Response = "Failed to find achievement.",
		}
	else
		local achievement = playerAchievements.ActiveAchievements[achievementIndex]
		if achievement.Claimed then
			return {
				Success = false,
				Response = "Achievement already claimed.",
			}
		end
		if AchievementService:IsAchievementCompleted(achievement) == false then
			return {
				Success = false,
				Response = "Achievement not completed.",
			}
		end
		local claimed = AchievementService:ClaimAchievement(Player, achievement)
		if not claimed then
			return {
				Success = false,
				Response = "Failed to claim achievement.",
			}
		else
			return {
				Success = true,
				Response = "Successfully claimed achievement.",
			}
		end
	end
end

function AchievementService:GetAchievements(Player: Player)
	local playerDocument = PlayerDataService:GetDocument(Player)
	if not playerDocument then
		return nil
	else
		return playerDocument:read().Achievements
	end
end

function AchievementService:GetActiveAchievementsOfTypes(
	Player: Player,
	achievementTypes: { string }
): { Types.Achievement }
	local playerAchievements = AchievementService:GetAchievements(Player)
	if not playerAchievements then
		return {}
	end
	local activeAchievements = playerAchievements.ActiveAchievements
	local achievements = {}
	for _, Achievement in activeAchievements do
		local achievementInfo: Types.AchievementInfo = AchievementService:GetAchievementFromId(Achievement.Id)
		if table.find(achievementTypes, achievementInfo.Type) then
			table.insert(achievements, Achievement)
		end
	end
	return achievements
end

function AchievementService:GetAchievementFromId(AchievementId: number): Types.AchievementInfo
	return AchievementService.Achievements[AchievementId]
end

return AchievementService
