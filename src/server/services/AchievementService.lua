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

local AchievementNamespace = Remotes.Server:GetNamespace("Achievements")

local ClaimAchievement = AchievementNamespace:Get("ClaimAchievement") :: Net.ServerAsyncCallback
local GetAchievements = AchievementNamespace:Get("GetAchievements") :: Net.ServerAsyncCallback
local AchievementsChanged = AchievementNamespace:Get("AchievementsChanged") :: Net.ServerSenderEvent

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

function AchievementService:OnInit()
	-- Let's tag each achievement with it's respective ID.
	-- selene: allow(undefined_variable)
	local AchievementModule = require(Constants.Achievements)
	for _, Achievement in AchievementModule do
		AchievementService.Achievements[Achievement.Id] = Achievement
	end
	GetAchievements:SetCallback(function(Player: Player)
		local PlayerDocument = PlayerDataService:GetDocument(Player)
		if PlayerDocument then
			return PlayerDocument:read().Achievements
		end
		return nil
	end)
	ClaimAchievement:SetCallback(function(Player: Player, AchievementUUID: string)
		return AchievementService:ClaimAchievementRequest(Player, AchievementUUID)
	end)
end

function AchievementService:OnStart()
	PlayerDataService.DocumentLoaded:Connect(function(Player, PlayerDocument)
		local newplayerAchievements = table.clone(PlayerDocument:read().Achievements)
		local newActiveAchievements = table.clone(newplayerAchievements.ActiveAchievements)

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

				table.insert(newActiveAchievements, AchievementService:GenerateAchievement(Player, AchievementInfo))
			elseif
				AchievementInfo.Type == "Progressive"
				and AchievementService:HasAchievement(Player, AchievementInfo.Id) == true
			then
				local numberOfSameAchievements = 0
				for _, ActiveAchievement in newActiveAchievements do
					if ActiveAchievement.Id == AchievementInfo.Id then
						numberOfSameAchievements = numberOfSameAchievements + 1
					end
				end
				-- remove all but one of the same achievements
				if numberOfSameAchievements > 1 then
					repeat
						for index, ActiveAchievement in newActiveAchievements do
							if ActiveAchievement.Id == AchievementInfo.Id then
								table.remove(newActiveAchievements, index)
								break
							end
						end
						numberOfSameAchievements = numberOfSameAchievements - 1
					until numberOfSameAchievements == 1
				end
			end
		end

		-- Remove any deprecated or expired achievements.
		newActiveAchievements = Sift.Array.filter(newActiveAchievements, function(ActiveAchievement: Types.Achievement)
			local achievementInfo = AchievementService:GetAchievementFromId(ActiveAchievement.Id)

			if not achievementInfo then
				return false
			end

			if achievementInfo.ExpirationTime and os.time() >= achievementInfo.ExpirationTime then
				return false
			end

			return not achievementInfo.Deprecated
		end)

		-- Fill in daily achievements, if needed.
		if newplayerAchievements.LastDailyRotation == -1 then -- first time
			newplayerAchievements.LastDailyRotation = os.time()
			newActiveAchievements = Sift.Array.concat(
				newActiveAchievements,
				AchievementService:GenerateRandomAchievements(Player, DAILY_ACHIEVEMENT_COUNT, "Daily")
			)
		else
			local timeSinceLastRotation = os.time() - newplayerAchievements.LastDailyRotation
			local timeElapsedHours = timeSinceLastRotation / 3600
			if timeElapsedHours >= 24 then
				-- 24 hours have passed, rotate the achievements.
				newplayerAchievements.LastDailyRotation = os.time()
				local newAchievements =
					AchievementService:GenerateRandomAchievements(Player, DAILY_ACHIEVEMENT_COUNT, "Daily")
				newActiveAchievements = Sift.Array.concat(
					Sift.Array.filter(newActiveAchievements, function(ActiveAchievement: Types.Achievement)
						local achievementInfo =
							AchievementService:GetAchievementFromId(ActiveAchievement.Id) :: Types.AchievementInfo
						return achievementInfo.Type ~= "Daily" and achievementInfo.Type ~= "NPC" -- Remove all daily/NPC achievements.
					end),
					newAchievements -- Add new daily achievements.
				)
			end
		end

		newplayerAchievements.ActiveAchievements = newActiveAchievements
		PlayerDocument:write(Freeze.Dictionary.set(PlayerDocument:read(), "Achievements", newplayerAchievements))

		-- Update progress for all achievements.
		for _, ActiveAchievement in newActiveAchievements do
			local achievementInfo =
				AchievementService:GetAchievementFromId(ActiveAchievement.Id) :: Types.AchievementInfo
			for requirementIndex, _requirement in pairs(ActiveAchievement.Requirements) do
				local requirementInfo = achievementInfo.Requirements[requirementIndex]
				if requirementInfo.Statistic then
					AchievementService:RegisterAchievementProgress(
						Player,
						requirementInfo.Action,
						requirementInfo.Statistic
					)
				end
			end
		end

		AchievementService.NewRewardTimers[Player.UserId :: any] =
			AchievementService:ListenForDailyRotation(Player, PlayerDocument:read().Achievements.LastDailyRotation)
		AchievementsChanged:SendToPlayer(Player, PlayerDocument:read().Achievements) -- Send client their achievements once their data loads in
	end)

	-- For statistic and resource action requirements, we need to listen for changes to the statistic/resource and update the achievement progress accordingly.
	local Listening = {}
	local StatisticListening = {}
	local _ResourceListeners = Sift.Dictionary.map(
		AchievementService.Achievements,
		function(achievement: Types.AchievementInfo)
			for _, requirement in achievement.Requirements do
				if
					requirement.Action == "Resource"
					and requirement.Resource
					and not table.find(Listening, requirement.Resource)
				then
					table.insert(Listening, requirement.Resource)
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
		end
	)
	local _StatisticListeners = Sift.Dictionary.map(
		AchievementService.Achievements,
		function(achievement: Types.AchievementInfo)
			for _, requirement in achievement.Requirements do
				if
					requirement.Action == "Statistic"
					and requirement.Statistic
					and not table.find(StatisticListening, requirement.Statistic)
				then
					table.insert(StatisticListening, requirement.Statistic)
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
		end
	)

	-- For custom action requirements, other modules register the progress manually. Don't need to listen for anything.

	-- For signal action requirements, we need to listen for the signal and update the achievement progress accordingly **only** if the signal passes the filter callback.

	local signalNamesListening = {}
	local _SignalListeners = Sift.Dictionary.map(
		AchievementService.Achievements,
		function(achievement: Types.AchievementInfo)
			for _, requirement in achievement.Requirements do
				if requirement.Action == "Signal" and requirement.Signal then
					if not table.find(signalNamesListening, requirement.Signal.Name) then
						table.insert(signalNamesListening, requirement.Signal.Name)
					else
						continue
					end
					return requirement.Signal.SignalInstance:Connect(
						function(Player: Player, Increment: number, ...: any)
							AchievementService:RegisterAchievementProgress(
								Player,
								"Signal",
								requirement.Signal.Name,
								nil,
								Increment,
								...
							) -- assume 1 for now, we can change this later if we need to.
						end
					)
				end
			end
			return Sift.None
		end
	)
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
		local playerAchievements = table.clone(playerDocument:read().Achievements)
		playerAchievements.LastDailyRotation = os.time()
		local newAchievements = AchievementService:GenerateRandomAchievements(Player, DAILY_ACHIEVEMENT_COUNT, "Daily")
		playerAchievements.ActiveAchievements = Sift.Array.concat(
			Sift.Array.filter(playerAchievements.ActiveAchievements, function(ActiveAchievement: Types.Achievement)
				local achievementInfo =
					AchievementService:GetAchievementFromId(ActiveAchievement.Id) :: Types.AchievementInfo
				return achievementInfo.Type ~= "Daily" -- Remove all daily achievements.
			end),
			newAchievements -- Add new daily achievements.
		)
		playerDocument:write(Freeze.Dictionary.set(playerDocument:read(), "Achievements", playerAchievements))
		AchievementsChanged:SendToPlayer(Player, playerAchievements)
		AchievementService.NewRewardTimers[Player.UserId] =
			AchievementService:ListenForDailyRotation(Player, playerAchievements.LastDailyRotation)
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
	IncrementProgressBy: number?,
	...
)
	local playerAchievements = AchievementService:GetAchievements(Player) :: Types.PlayerAchievements
	local currentActiveAchievements = table.clone(playerAchievements.ActiveAchievements)

	local args = { ... } -- we do this in the outer scope so we can use it in the filter callback below. luau doesn't like it when we do it in the filter callback.

	local associatedAchievements = Sift.Array.filter(currentActiveAchievements, function(achievement: Types.Achievement)
		-- Check if any of the requirements are the statistic we're listening for.
		local achievementInfo = AchievementService:GetAchievementFromId(achievement.Id) :: Types.AchievementInfo

		local atLeastOneRequirementMatches = false

		for index, requirement in pairs(achievement.Requirements) do
			local requirementInfo = achievementInfo.Requirements[index]
			local actionTypeName = requirementInfo[ActionType]
			if typeof(actionTypeName) == "function" then
				actionTypeName = (actionTypeName :: any)(achievement) -- For custom actions, we pass the achievement table to the function to get the action name.
			elseif typeof(actionTypeName) == "table" then
				actionTypeName = actionTypeName.Name -- For signals, we only care about the name.
			end -- for resources & statistics, we already have the name (string) so we don't need to do anything.
			local passesFilter = requirementInfo.Action == ActionType and actionTypeName == ActionTypeName

			-- if this is a signal requirement, we need to check if the signal passes the filter callback.
			if requirementInfo.Action == "Signal" and requirementInfo.Signal then
				-- if args is empty, we don't want to continue.
				if #args == 0 then
					continue
				end
				passesFilter = requirementInfo.Signal.Filter(achievement, Player, unpack(args))
			end

			if passesFilter then
				atLeastOneRequirementMatches = true
			else -- if we don't pass the filter, we don't need to continue. (the rest of the loop updates progress for each requirement)
				continue
			end

			local NewVal = nil
			if ActionType == "Resource" then
				NewVal = ResourceService:GetResource(Player, ActionTypeName) :: number
			elseif ActionType == "Statistic" then
				NewVal = StatisticsService:GetStatistic(Player, ActionTypeName) :: number
			elseif (ActionType == "Signal" or ActionType == "Custom") and IncrementProgressBy then
				NewVal = requirement.Progress + IncrementProgressBy
			end

			if not NewVal then
				continue
			end

			if requirementInfo.UseDelta and OldValue then
				local delta = NewVal - OldValue
				NewVal = requirement.Progress + delta -- For requirements specifying a delta, we add the delta to the current progress as our new value instead.
			elseif requirementInfo.UseDelta and not OldValue then
				continue -- We don't have an old value to compare to, so we can't register progress for this requirement.
			end

			local goal = if typeof(requirement.Goal) == "function"
				then requirement.Goal(achievement)
				else requirement.Goal
			if goal and goal <= NewVal then
				AchievementService:CompleteRequirement(Player, achievement.UUID, index, NewVal)
			elseif goal and goal > NewVal then
				AchievementService:UpdateRequirementProgress(Player, achievement.UUID, index, NewVal)
			end
		end

		return atLeastOneRequirementMatches
	end)

	-- Send the partial state update to the client
	-- @IMPORTANT: Our CompleteRequirement and UpdateRequirementProgress functions will clone achievement tables when updating them, so we can compare the old and new tables to see if anything changed.
	local changedActiveAchievements = {}
	local newAchievements = AchievementService:GetAchievements(Player) :: Types.PlayerAchievements

	for _, achievement in associatedAchievements do
		local oldAchievementIndex = Sift.Array.findWhere(
			currentActiveAchievements,
			function(_achievement: Types.Achievement)
				return _achievement.UUID == achievement.UUID
			end
		)
		if oldAchievementIndex then
			local newAchievementIndex = Sift.Array.findWhere(
				newAchievements.ActiveAchievements,
				function(_achievement: Types.Achievement)
					return _achievement.UUID == achievement.UUID
				end
			)
			if
				newAchievementIndex
				and newAchievements.ActiveAchievements[newAchievementIndex]
					~= currentActiveAchievements[oldAchievementIndex]
			then
				changedActiveAchievements[newAchievementIndex] = newAchievements.ActiveAchievements[newAchievementIndex]
			end
		end
	end

	-- @IMPORTANT: We only send the achievements that changed to the client, so we don't send the entire state every time.

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
	local playerAchievements = playerDocument:read().Achievements

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

function AchievementService:CompleteRequirement(
	Player: Player,
	AchievementUUID: string,
	requirementIndex: number,
	NewValue: number
): boolean
	local playerDocument = PlayerDataService:GetDocument(Player)
	local playerAchievements = playerDocument:read().Achievements

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
	local playerAchievements = AchievementService:GetAchievements(Player) :: Types.PlayerAchievements
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
		if
			randomAchievement and (AchievementType and randomAchievement.Type ~= AchievementType)
			or (randomAchievement and randomAchievement.Deprecated)
			or not randomAchievement
		then
			table.remove(achievementList, randomIndex)
			repeat
				randomIndex = seed:NextInteger(1, #achievementList)
				randomAchievement = achievementList[randomIndex]
				table.remove(achievementList, randomIndex)
			until #achievementList == 0
				or not randomAchievement
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

		table.insert(randomAchievements, AchievementService:GenerateAchievement(Player, randomAchievement))
	end
	return randomAchievements
end

function AchievementService:GenerateAchievement(
	Player: Player,
	AchievementInfo: Types.AchievementInfo
): Types.Achievement
	local uniqueProps = {}
	if AchievementInfo.GetUniqueProps then
		uniqueProps = AchievementInfo.GetUniqueProps(Player, PlayerDataService:GetDocument(Player):read())
	end

	local achievement: Types.Achievement = Sift.Dictionary.merge({
		Id = AchievementInfo.Id, -- we can use this to get information about the achievement
		UUID = HttpService:GenerateGUID(false),
		Claimed = false,
		Requirements = Sift.Array.map(
			AchievementInfo.Requirements,
			function(Requirement: Types.AchievementRequirementInfo)
				return {
					Progress = AchievementService:GetCurrentProgress(Player, Requirement),
				}
			end
		),
		TimesClaimed = 0,
	}, uniqueProps)

	-- go thru each requirement and add a goal field to it (we do this after so that we can pass our achievement table in if our goal is a function of the achievement)
	for requirementIndex, requirement in pairs(achievement.Requirements) do
		local requirementInfo = AchievementInfo.Requirements[requirementIndex]
		if requirementInfo.Goal then
			requirement.Goal = if typeof(requirementInfo.Goal) == "function"
				then requirementInfo.Goal(achievement)
				else requirementInfo.Goal
		end
	end

	return achievement
end

function AchievementService:ClaimAchievement(Player: Player, Achievement: Types.Achievement): boolean
	local playerDocument = PlayerDataService:GetDocument(Player)

	local playerAchievements = table.clone(playerDocument:read().Achievements)
	local newActiveAchievements = table.clone(playerAchievements.ActiveAchievements)

	for index, achievement in pairs(newActiveAchievements) do
		if achievement.UUID == Achievement.UUID then
			newActiveAchievements[index] = table.clone(achievement)
			-- if it's progress based, we need to update our goal to the next one
			local achievementInfo = AchievementService:GetAchievementFromId(achievement.Id) :: Types.AchievementInfo
			if AchievementService:CanAchievementProgress(achievement) == true then -- Progress our achievement if we can. Otherwise, just claim it permanently.
				for requirementIndex, requirement in pairs(achievement.Requirements) do
					local requirementInfo = achievementInfo.Requirements[requirementIndex]
					local goal = requirement.Goal
					if requirementInfo.Increment then
						local increment = if typeof(requirementInfo.Increment) == "function"
							then requirementInfo.Increment(goal)
							else requirementInfo.Increment
						requirement.Goal = goal + increment
						if requirementInfo.ResetProgressOnIncrement then
							requirement.Progress = 0
						end
					end
				end
			else
				-- otherwise, just claim it permanently. we don't need to update anything.
				newActiveAchievements[index].Claimed = true
			end

			AchievementService:GrantAchievementReward(Player, achievement)

			-- after granting reward above, update times claimed
			if newActiveAchievements[index].TimesClaimed then
				newActiveAchievements[index].TimesClaimed += 1
			else
				newActiveAchievements[index].TimesClaimed = 1
			end

			playerDocument:write(
				Freeze.Dictionary.setIn(
					playerDocument:read(),
					{ "Achievements", "ActiveAchievements" },
					newActiveAchievements
				)
			)

			AchievementService.AchievementClaimed:Fire(Player, achievement)
			return true
		end
	end
	return false
end

function AchievementService:CanAchievementProgress(Achievement: Types.Achievement): boolean
	local AchievementInfo = AchievementService:GetAchievementFromId(Achievement.Id) :: Types.AchievementInfo
	-- An achievement can progress if it has a requirement that is progressive. (contains the Increment property), and is not at a Maximum if it has one.
	for i, _requirement in pairs(Achievement.Requirements) do
		local requirementInfo = AchievementInfo.Requirements[i]
		if requirementInfo.Increment then
			if requirementInfo.Maximum then
				local goal = if typeof(requirementInfo.Goal) == "function"
					then requirementInfo.Goal(Achievement)
					else requirementInfo.Goal
				local increment = if typeof(requirementInfo.Increment) == "function"
					then requirementInfo.Increment(goal)
					else requirementInfo.Increment
				local newGoal = goal + increment
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
	for _, requirement in pairs(Achievement.Requirements) do
		local goal = if typeof(requirement.Goal) == "function" then requirement.Goal(Achievement) else requirement.Goal
		if requirement.Progress < goal then
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

function AchievementService:GetAchievements(Player: Player): Types.PlayerAchievements?
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
		local achievementInfo = AchievementService:GetAchievementFromId(Achievement.Id) :: Types.AchievementInfo
		if table.find(achievementTypes, achievementInfo.Type) then
			table.insert(achievements, Achievement)
		end
	end
	return achievements
end

function AchievementService:GetAchievementFromId(AchievementId: number): Types.AchievementInfo?
	for _, Achievement in pairs(AchievementService.Achievements) do
		if Achievement.Id == AchievementId then
			return Achievement
		end
	end
	return nil
end

return AchievementService
