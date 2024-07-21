--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Contexts = ReplicatedStorage.react.contexts
local Components = ReplicatedStorage.react.components
local PlayerScripts = LocalPlayer.PlayerScripts
local Hooks = ReplicatedStorage.react.hooks

local AchievementController = require(PlayerScripts.controllers.AchievementController)
local AchievementDisplay = require(Components.achievements.AchievementDisplay)
local AchievementTemplate = require(Components.achievements.AchievementTemplate)
local AchievementUtils = require(ReplicatedStorage.utils.AchievementUtils)
local AchievementsContext = require(Contexts.AchievementsContext)
local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local Button = require(Components.buttons.Button)
local CloseButton = require(Components.buttons.CloseButton)
local InterfaceController = require(PlayerScripts.controllers.InterfaceController)
local React = require(ReplicatedStorage.packages.React)
local StringUtils = require(ReplicatedStorage.utils.StringUtils)
local Timer = require(ReplicatedStorage.packages.Timer)
local animateCurrentInterface = require(Hooks.animateCurrentInterface)

local useContext = React.useContext
local e = React.createElement
local useCallback = React.useCallback
local useBinding = React.useBinding
local useState = React.useState
local useEffect = React.useEffect

type AchievementCategory = "Daily" | "Main" | "Event"
type AchievementCategoryData = {
	LayoutOrder: number,
}

local ACHIEVEMENT_CATEGORIES = {
	Daily = {
		LayoutOrder = 1,
	},
	Main = {
		LayoutOrder = 2,
	},
	Event = {
		LayoutOrder = 3,
	},
} :: { [AchievementCategory]: AchievementCategoryData }

type AchievementProps = {}

local function Achievements(_props: AchievementProps)
	local achievementsState = useContext(AchievementsContext)
	local currentCategory, setCurrentCategory = useState("Daily" :: AchievementCategory)
	local timeTillRotation, setTimeTillRotation = useBinding(0)

	local selectedAchievementUUID, setSelectedAchievementUUID = useState(nil :: string?)
	local _shouldRender, styles =
		animateCurrentInterface("Achievements", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local changeSelectedAchievement = useCallback(function(uuid: string)
		setSelectedAchievementUUID(uuid)
	end, {})

	local achievementElements = {} :: { [string]: any }

	for _, achievement in achievementsState.ActiveAchievements do
		local achievementInfo = AchievementUtils.GetAchievementInfoFromId(achievement.Id)
		if not achievementInfo or achievementInfo.Type ~= currentCategory then
			continue
		end
		local requirement = achievement.Requirements[1] -- we only support one requirement for now
		achievementElements[achievement.UUID] = e(AchievementTemplate, {
			goal = requirement.Goal,
			progress = requirement.Progress,
			achievementUUID = achievement.UUID,
			achievementName = AchievementController:GetRequirementName(achievement, 1),
			onActivated = changeSelectedAchievement,
		})
	end

	local selectedAchievement = selectedAchievementUUID
		and AchievementUtils.GetAchievementByUUID(achievementsState.ActiveAchievements, selectedAchievementUUID)

	local categoryButtonElements = {} :: { [string]: any }
	for categoryName, categoryInfo in pairs(ACHIEVEMENT_CATEGORIES) do
		categoryButtonElements[categoryName] = e(Button, {
			text = categoryName,
			textColor3 = if currentCategory == categoryName
				then Color3.fromRGB(255, 255, 255)
				else Color3.fromRGB(30, 30, 30),
			gradient = if currentCategory == categoryName
				then ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(134, 134, 134)),
					ColorSequenceKeypoint.new(0.0328, Color3.fromRGB(172, 172, 172)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
				})
				else ColorSequence.new(Color3.fromRGB(255, 255, 255)),
			backgroundColor3 = if currentCategory == categoryName
				then Color3.fromRGB(72, 72, 72)
				else Color3.fromRGB(255, 255, 255),
			cornerRadius = UDim.new(0, 5),
			textSize = 16,
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			layoutOrder = categoryInfo.LayoutOrder,
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(255, 255, 255),
			strokeThickness = 1,
			size = UDim2.fromOffset(105, 42),
			gradientRotation = -90,
			onActivated = function()
				setCurrentCategory(categoryName)
			end,
		})
	end

	useEffect(function()
		local rotationTimer = nil
		if achievementsState and achievementsState.LastDailyRotation then
			rotationTimer = Timer.new(1)
			rotationTimer.Tick:Connect(function()
				local timeLeft = achievementsState.LastDailyRotation + 86400 - os.time()
				if timeLeft > 0 then
					setTimeTillRotation(timeLeft)
				else
					rotationTimer:Destroy()
					rotationTimer = nil
				end
			end)
			rotationTimer:StartNow()
		end
		return function()
			if rotationTimer then
				rotationTimer:Destroy()
			end
		end
	end, { achievementsState })

	return e("ImageLabel", {
		Image = "rbxassetid://18442700149",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = styles.position,
		Size = UDim2.fromOffset(849, 609),
	}, {
		separator = e("ImageLabel", {
			Image = "rbxassetid://18442712803",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 188),
			Size = UDim2.fromOffset(798, 4),
		}),

		topbar = e("ImageLabel", {
			Image = "rbxassetid://18442724190",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(849, 87),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18442724304",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(849, 87),
			}),

			achievements = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Achievements",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(63, 34),
				Size = UDim2.fromOffset(166, 19),
			}),

			achievementsIcon = e("ImageLabel", {
				Image = "rbxassetid://18442724463",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(23, 31),
				Size = UDim2.fromOffset(27, 27),
			}),

			close = e(CloseButton, {
				size = UDim2.fromOffset(43, 43),
				position = UDim2.fromScale(0.946, 0.517),
				onActivated = function()
					InterfaceController.InterfaceChanged:Fire(nil)
				end,
			}),
		}),

		achievements1 = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Achivevements",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(27, 216),
			Size = UDim2.fromOffset(131, 14),
		}),

		about = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "About Achivements",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(572, 216),
			Size = UDim2.fromOffset(168, 14),
		}),

		dailyTimer = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(692, 119),
			Size = UDim2.fromOffset(132, 42),
		}, {
			timeLeft = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = timeTillRotation:map(function(timeTillRotate: number)
					return StringUtils.MapSecondsToStringTime(timeTillRotate)
				end),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(52, 15),
				Size = UDim2.fromOffset(61, 13),
			}),

			timerIcon3 = e("ImageLabel", {
				Image = "rbxassetid://18442700585",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(132, 42),
			}),

			timerIcon2 = e("ImageLabel", {
				Image = "rbxassetid://18442700645",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(29, 15),
				Size = UDim2.fromOffset(8, 8),
			}),

			timerIcon = e("ImageLabel", {
				Image = "rbxassetid://18442700730",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(20, 11),
				Size = UDim2.fromOffset(21, 21),
			}),
		}),

		categoryButtonList = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0259, 0.184),
			Size = UDim2.fromOffset(421, 56),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 8),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			categoryButtonList = e(React.Fragment, nil, categoryButtonElements),
		}),

		scrolling = e(AutomaticScrollingFrame, {
			scrollBarThickness = 8,
			active = true,
			backgroundTransparency = 1,
			position = UDim2.fromScale(0.0259, 0.404),
			size = UDim2.fromOffset(534, 339),
		}, {
			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(15, 15),
				CellSize = UDim2.fromOffset(155, 155),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 5),
				PaddingTop = UDim.new(0, 5),
			}),

			achievements = e(React.Fragment, nil, achievementElements),
		}),

		selectedDisplay = selectedAchievement and e(AchievementDisplay, {
			goal = selectedAchievement.Requirements[1].Goal,
			progress = selectedAchievement.Requirements[1].Progress,
			achievementName = AchievementController:GetRequirementName(selectedAchievement, 1),
		}),
	})
end

return Achievements
