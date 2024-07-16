--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)

local e = React.createElement

type AchievementDisplayProps = {}

local function AchievementDisplay(props: AchievementDisplayProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(571, 246),
		Size = UDim2.fromOffset(253, 339),
	}, {
		acceptButton = e("ImageLabel", {
			Image = "rbxassetid://18442712278",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(13, 279),
			Size = UDim2.fromOffset(228, 39),
		}, {
			accept = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Accept",
				TextColor3 = Color3.fromRGB(0, 54, 25),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(91, 16),
				Size = UDim2.fromOffset(46, 12),
			}),
		}),

		rewardsBackground = e("ImageLabel", {
			Image = "rbxassetid://18442712213",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 190),
			Size = UDim2.fromOffset(253, 51),
		}),

		separator = e("ImageLabel", {
			Image = "rbxassetid://18442712410",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(13, 267),
			Size = UDim2.fromOffset(228, 4),
		}),

		separator1 = e("ImageLabel", {
			Image = "rbxassetid://18442712624",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(13, 149),
			Size = UDim2.fromOffset(228, 4),
		}),

		slider = e("ImageLabel", {
			Image = "rbxassetid://18442700894",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(24, 120),
			Size = UDim2.fromOffset(209, 11),
		}, {
			progress = e("ImageLabel", {
				Image = "rbxassetid://18442712157",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(2, 2),
				Size = UDim2.fromOffset(54, 7),
			}),
		}),

		completion = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "45% Compeleted",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 103),
			Size = UDim2.fromOffset(115, 13),
		}),

		rewards = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Rewards",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(27, 173),
			Size = UDim2.fromOffset(58, 11),
		}),

		selectedDescription = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = "Description goes here",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextTransparency = 0.38,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(27, 55),
			Size = UDim2.fromOffset(144, 13),
		}),

		selectedName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Name Of Achievement",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(27, 30),
			Size = UDim2.fromOffset(201, 15),
		}),

		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
		}),
	})
end

return AchievementDisplay
