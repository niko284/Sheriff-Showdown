--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers
local Contexts = ReplicatedStorage.react.contexts

local AchievementController = require(Controllers.AchievementController)
local AchievementsContext = require(Contexts.AchievementsContext)
local Types = require(ReplicatedStorage.constants.Types)

local React = require(ReplicatedStorage.packages.React)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local function AchievementsProvider(props)
	local achievementState, setAchievementState = useState(function()
		local serverAchievements = AchievementController:GetAchievementsFromServer()
		return serverAchievements
	end)

	useEffect(function()
		local partialStateChanged = AchievementController.PartialAchievementsChanged:Connect(
			function(partialAchievements: Types.PlayerAchievements)
				setAchievementState(function(oldState)
					local newState = table.clone(oldState)
					if partialAchievements.ActiveAchievements then
						local newActiveAchievements = table.clone(newState.ActiveAchievements)
						for index, achievement in partialAchievements.ActiveAchievements do
							-- number indices are converted to strings when sent over the network, so we need to convert them back to numbers.
							newActiveAchievements[tonumber(index)] = achievement
						end
						newState.ActiveAchievements = newActiveAchievements
					end
					-- merge all other keys except for the ActiveAchievements since we merge those in the loop above.
					-- active achievements send partial data changes to reduce bandwidth, so we don't want to overwrite the entire state.
					for key, value in pairs(partialAchievements) do
						if key ~= "ActiveAchievements" then
							newState[key] = value
						end
					end
					return newState
				end)
			end
		)
		return function()
			partialStateChanged:Disconnect()
		end
	end, {})

	return e(AchievementsContext.Provider, {
		value = achievementState,
	}, props.children)
end

return AchievementsProvider
