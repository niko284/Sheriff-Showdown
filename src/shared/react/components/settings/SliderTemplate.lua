--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local React = require(ReplicatedStorage.packages.React)
local Slider = require(Components.frames.Slider)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type SliderTemplateProps = Types.FrameProps & {
	name: string,
	description: string,
	minimum: number,
	maximum: number,
	percentage: number,
	increment: number,
}

local function SliderTemplate(props: SliderTemplateProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BackgroundTransparency = 0.64,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Position = UDim2.fromOffset(22, 368),
		Size = UDim2.fromOffset(799, 71),
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 0.5,
			Transparency = 0.67,
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = props.description,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextTransparency = 0.38,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 42),
			Size = UDim2.fromOffset(200, 11),
		}),

		name = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 19),
			Size = UDim2.fromOffset(115, 16),
		}),

		slider = e(Slider, {
			position = UDim2.fromOffset(593, 32),
			percentage = props.percentage,
			minimum = props.minimum,
			maximum = props.maximum,
			increment = props.increment,
			snap = true,
		}),
	})
end

return SliderTemplate
