--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local Button = require(Components.buttons.Button)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type VotingTemplateProps = Types.FrameProps & {
	amountOfVotes: number,
	onActivated: (string, string) -> (),
	choice: string,
	field: string,
}

local function VotingTemplate(props: VotingTemplateProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = props.size,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 14),
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 2,
		}),

		gradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(72, 72, 72)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(43, 43, 43)),
			}),
			Rotation = -90,
		}),

		separator = e("ImageLabel", {
			Image = "rbxassetid://18250424549",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(23, 301),
			Size = UDim2.fromOffset(209, 4),
		}),

		voteAmount = props.amountOfVotes and e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = string.format("%d Votes", props.amountOfVotes),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(166, 28),
			Size = UDim2.fromOffset(59, 11),
		}),

		selectionName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.choice,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 249),
			Size = UDim2.fromOffset(111, 32),
		}),

		vote = e(Button, {
			anchorPoint = Vector2.new(0.5, 0.5),
			size = UDim2.fromOffset(228, 40),
			position = UDim2.fromScale(0.5, 0.914),
			gradient = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
			backgroundColor3 = Color3.fromRGB(255, 255, 255),
			text = "Vote",
			textColor3 = Color3.fromRGB(20, 20, 20),
			textSize = 14,
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			onActivated = function()
				props.onActivated(props.field, props.choice)
			end,
		}),
	})
end

return React.memo(VotingTemplate)
