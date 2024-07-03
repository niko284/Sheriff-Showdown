--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local Button = require(Components.buttons.Button)
local React = require(ReplicatedStorage.packages.React)
local Separator = require(Components.other.Separator)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type ConfirmationPromptProps = Types.FrameProps & {
	description: string,
	title: string,
	acceptText: string?,
	onAccept: () -> (),
	onCancel: () -> (),
}

local function ConfirmationPrompt(props: ConfirmationPromptProps)
	return e("ImageLabel", {
		Image = "rbxassetid://17884887143",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(405, 256),
	}, {
		topbar = e("ImageLabel", {
			Image = "rbxassetid://17884887261",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(405, 65),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://17884887345",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(405, 65),
			}),

			title = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.title,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 19,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(23, 25),
				Size = UDim2.fromOffset(113, 15),
			}),
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			RichText = true,
			Text = props.description,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(23, 90),
			Size = UDim2.fromOffset(361, 34),
		}),

		warning = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = "This can not be undone!",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextTransparency = 0.38,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(24, 142),
			Size = UDim2.fromOffset(149, 9),
		}),

		separator = e(Separator, {
			position = UDim2.fromOffset(25, 170),
			size = UDim2.fromOffset(359, 4),
		}),

		cancelButton = e(Button, {
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = "Cancel",
			textColor3 = Color3.fromRGB(53, 0, 12),
			textSize = 16,
			position = UDim2.fromOffset(25, 191),
			size = UDim2.fromOffset(170, 48),
			cornerRadius = UDim.new(0, 5),
			gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(252, 68, 118)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(203, 35, 67)),
			}),
			strokeThickness = 1.5,
			strokeColor = Color3.fromRGB(255, 255, 255),
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			gradientRotation = -90,
			onActivated = props.onCancel,
		}),

		acceptButton = e(Button, {
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = props.acceptText or "Accept",
			textColor3 = Color3.fromRGB(0, 54, 25),
			textSize = 16,
			position = UDim2.fromOffset(215, 191),
			size = UDim2.fromOffset(170, 48),
			cornerRadius = UDim.new(0, 5),
			gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 252, 153)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 203, 112)),
			}),
			strokeThickness = 1.5,
			strokeColor = Color3.fromRGB(255, 255, 255),
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			gradientRotation = -90,
			onActivated = props.onAccept,
		}),
	})
end

return ConfirmationPrompt
