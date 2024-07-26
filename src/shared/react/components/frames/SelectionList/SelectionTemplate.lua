--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local Button = require(Components.buttons.Button)
local React = require(ReplicatedStorage.packages.React)

local e = React.createElement

type SelectionTemplateProps = {
	icon: string,
	primaryText: string,
	selectionText: string,
	secondaryText: string,
	selectionActivated: (TextButton) -> (),
}

local function SelectionTemplate(props: SelectionTemplateProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BackgroundTransparency = 0.64,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(23, 213),
		Size = UDim2.fromOffset(801, 73),
	}, {
		stroke = e("UIStroke", {
			Color = Color3.fromRGB(84, 84, 84),
			Thickness = 1,
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		iconBackground = e("ImageLabel", {
			Image = "rbxassetid://18180719338",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 13),
			Size = UDim2.fromOffset(48, 48),
		}, {
			selectionIcon = e("ImageLabel", {
				Image = props.icon,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(48, 48),
			}),
		}),

		selectionButton = e(Button, {
			position = UDim2.fromOffset(689, 18),
			size = UDim2.fromOffset(98, 38),
			text = props.selectionText,
			textColor3 = Color3.fromRGB(31, 31, 31),
			gradient = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
			cornerRadius = UDim.new(1, 0),
			textSize = 17,
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(255, 255, 255),
			strokeThickness = 1,
			gradientRotation = 0,
			onActivated = props.selectionActivated,
		}),

		displayName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.primaryText,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(73, 20),
			Size = UDim2.fromOffset(65, 16),
		}),

		username = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = props.secondaryText,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextTransparency = 0.38,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(73, 43),
			Size = UDim2.fromOffset(148, 11),
		}),
	})
end

return React.memo(SelectionTemplate)
