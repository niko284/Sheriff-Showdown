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
local AchievementsContext = require(Contexts.AchievementsContext)
local CloseButton = require(Components.buttons.CloseButton)
local React = require(ReplicatedStorage.packages.React)
local animateCurrentInterface = require(Hooks.animateCurrentInterface)

local useContext = React.useContext
local e = React.createElement
local useCallback = React.useCallback
local useState = React.useState

type AchievementProps = {}

local function Achievements(props: AchievementProps)
	local achievementsState = useContext(AchievementsContext)

	local selectedAchievementUUID, setSelectedAchievementUUID = useState(nil :: string?)
	local _shouldRender, styles =
		animateCurrentInterface("Achievements", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local changeSelectedAchievement = useCallback(function(uuid: string)
		setSelectedAchievementUUID(uuid)
	end, {})

	local achievementElements = {}

	for _, achievement in achievementsState.ActiveAchievements do
		local requirement = achievement.Requirements[1] -- we only support one requirement for now
		achievementElements[achievement.UUID] = e(AchievementTemplate, {
			goal = requirement.Goal,
			progress = requirement.Progress,
			achievementUUID = achievement.UUID,
			achievementName = AchievementController:GetRequirementName(achievement, 1),
			onActivated = changeSelectedAchievement,
		})
	end

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

			closeButton = e("ImageLabel", {
				Image = "rbxassetid://18442724763",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(781, 23),
				Size = UDim2.fromOffset(43, 43),
			}, {
				closeIcon = e("ImageLabel", {
					Image = "rbxassetid://18442724970",
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 12),
					Size = UDim2.fromOffset(19, 19),
				}),
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
				Text = "12:53:14",
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
			dailyButton = e("ImageLabel", {
				Image = "rbxassetid://18442725086",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(22, 118),
				Size = UDim2.fromOffset(106, 43),
			}, {
				daily = e("TextLabel", {
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Text = "Daily",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(34, 15),
					Size = UDim2.fromOffset(42, 17),
				}),
			}),

			uIListLayout = e("UIListLayout", {
				Padding = UDim.new(0, 8),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		}),

		scrolling = e("ScrollingFrame", {
			ScrollBarThickness = 8,
			Active = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0259, 0.404),
			Size = UDim2.fromOffset(534, 339),
		}, {
			uIGridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(15, 15),
				CellSize = UDim2.fromOffset(155, 155),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			uIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 5),
				PaddingTop = UDim.new(0, 5),
			}),

			achievementTemplate = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(72, 72, 72),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(100, 100),
			}, {
				uICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 5),
				}),

				description = e("TextLabel", {
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Medium,
						Enum.FontStyle.Normal
					),
					Text = "Description goes \rhere",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.0979, 0.713),
					Size = UDim2.fromScale(0.657, 0.161),
				}),

				name = e("TextLabel", {
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Text = "Name Of it",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.0979, 0.587),
					Size = UDim2.fromScale(0.51, 0.0839),
				}),

				progress = e("TextLabel", {
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Text = "0/100",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.0909, 0.126),
					Size = UDim2.fromScale(0.259, 0.0909),
				}),

				uIStroke = e("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
				}),
			}),
		}),

		selectedDisplay = e(AchievementDisplay, {}),
	})
end

return Achievements
