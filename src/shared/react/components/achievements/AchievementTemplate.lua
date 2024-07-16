--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)

local e = React.createElement

type AchievementTemplateProps = {
	progress: number,
	goal: number,
	achievementUUID: string,
	achievementName: string,
	onActivated: (uuid: string) -> (),
}

local function AchievementTemplate(props: AchievementTemplateProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(100, 100),
	}, {
		corner = e("UICorner", {
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

		selected = e("ImageButton", {
			Size = UDim2.fromScale(1, 1),
			Image = "",
			BackgroundTransparency = 1,
			ZIndex = 3,
			[React.Event.Activated] = function()
				props.onActivated(props.achievementUUID)
			end,
		}),

		name = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.achievementName,
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
			Text = string.format("%d/%d", props.progress, props.goal),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0909, 0.126),
			Size = UDim2.fromScale(0.259, 0.0909),
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
		}),
	})
end

return React.memo(AchievementTemplate)
