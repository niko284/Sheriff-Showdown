--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type OptionButtonProps = {
	image: string,
} & Types.FrameProps

local function OptionButton(props: OptionButtonProps)
	return e("ImageButton", {
		ScaleType = Enum.ScaleType.Tile,
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
	}, {
		gradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(134, 134, 134)),
				ColorSequenceKeypoint.new(0.0328, Color3.fromRGB(172, 172, 172)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			Rotation = -90,
		}),

		stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
		}),

		image = e("ImageLabel", {
			Image = props.image,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(11, 10),
			Size = UDim2.fromOffset(22, 22),
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
	})
end

return OptionButton
