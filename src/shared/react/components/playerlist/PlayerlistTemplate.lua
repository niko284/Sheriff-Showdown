--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hooks = ReplicatedStorage.react.hooks
local Components = ReplicatedStorage.react.components

local AutomaticFrame = require(Components.frames.AutomaticFrame)
local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Types = require(ReplicatedStorage.constants.Types)
local usePlayerThumbnail = require(Hooks.usePlayerThumbnail)

local e = React.createElement
local useState = React.useState

type TemplateProps = Types.FrameProps & {
	player: Player,
	level: number,
	size: UDim2,
	kills: number,
	deaths: number,
	playTime: number,
	longestKillStreak: number,
	wins: number,
}

local function PlayerlistTemplate(props: TemplateProps)
	local playerThumbnail =
		usePlayerThumbnail(props.player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)

	local showInformation, setShowInformation = useState(false)

	local hours = math.floor(props.playTime / 3600)
	local minutes = math.floor((props.playTime % 3600) / 60)
	local seconds = math.floor(props.playTime % 60)
	local timePlayed = string.format("%02d:%02d:%02d", hours, minutes, seconds)

	return e(AutomaticFrame, {
		className = "Frame",
		instanceProps = {
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = props.size,
		},
		maxSize = Vector2.new(props.size.X.Offset, math.huge),
	}, {
		stroke = e("UIStroke", {
			Color = Color3.fromRGB(173, 173, 173),
			Thickness = 1,
		}),
		gradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 43, 43)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20)),
			}),
			Rotation = -90,
		}),
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
		toggleInformation = e("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 3,
			Size = UDim2.fromScale(1, 1),
			[React.Event.Activated] = function()
				setShowInformation(function(show)
					return not show
				end)
			end,
		}),

		statsSeparator = showInformation and e("ImageLabel", {
			Image = "rbxassetid://17860565450",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(3, 45),
			Size = UDim2.fromOffset(212, 3),
		}),

		playerStats = showInformation and e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(4, 59),
			Size = UDim2.fromOffset(208, 59),
		}, {
			kills = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Medium,
					Enum.FontStyle.Normal
				),
				Text = "Kills",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 9,
				TextTransparency = 0.38,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.00765, 0),
				Size = UDim2.fromOffset(18, 7),
			}),

			deaths = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Medium,
					Enum.FontStyle.Normal
				),
				Text = "Deaths",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 9,
				TextTransparency = 0.38,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.26, 0),
				Size = UDim2.fromOffset(31, 7),
			}),

			killCount = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.kills,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.00481, 0.22),
				Size = UDim2.fromOffset(19, 9),
			}),

			deathCount = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.deaths,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.26, 0.22),
				Size = UDim2.fromOffset(13, 9),
			}),

			timeSpent = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Medium,
					Enum.FontStyle.Normal
				),
				Text = "Playtime",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 9,
				TextTransparency = 0.38,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.606, 0.627),
				Size = UDim2.fromOffset(50, 9),
			}),

			timePlayed = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = timePlayed,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.611, 0.847),
				Size = UDim2.fromOffset(60, 9),
			}),

			longest = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Medium,
					Enum.FontStyle.Normal
				),
				Text = "Longest Kill Streak",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 9,
				TextTransparency = 0.38,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.00481, 0.627),
				Size = UDim2.fromOffset(81, 9),
			}),

			killStreak = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = string.format("%d Kills", props.longestKillStreak),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.00481, 0.831),
				Size = UDim2.fromOffset(39, 10),
			}),

			winsText = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Medium,
					Enum.FontStyle.Normal
				),
				Text = "Wins",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 9,
				TextTransparency = 0.38,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.611, 0),
				Size = UDim2.fromOffset(82, 7),
			}),

			winsAmount = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.wins,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.611, 0.22),
				Size = UDim2.fromOffset(15, 9),
			}),
		}),

		padding = e("UIPadding", {
			PaddingRight = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 8),
		}),

		icon = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(3, 10),
			Size = UDim2.fromOffset(22, 22),
		}, {
			iconBackground = e("ImageLabel", {
				Image = "rbxassetid://17860566135",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(1, 0),
				Size = UDim2.fromOffset(21, 22),
			}),

			playerIcon = e("ImageLabel", {
				Image = playerThumbnail,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(2, 0),
				Size = UDim2.fromOffset(21, 22),
			}),
		}),

		seperator = e("ImageLabel", {
			Image = "rbxassetid://17860374967",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(190, 13),
			Size = UDim2.fromOffset(3, 16),
		}),

		seperator1 = e("ImageLabel", {
			Image = "rbxassetid://17860375061",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(31, 13),
			Size = UDim2.fromOffset(3, 16),
		}),

		level = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.level,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(202, 17),
			Size = UDim2.fromOffset(15, 9),
		}),

		username = e(AutomaticFrame, {
			className = "TextLabel",
			instanceProps = {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.player.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(43, 17),
			},
			maxSize = Vector2.new(math.huge, 11), -- only scale width
		}),
	})
end

return React.memo(PlayerlistTemplate)
