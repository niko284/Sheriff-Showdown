--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type AcceptIndicatorProps = Types.FrameProps & {
	text: string,
	position: UDim2,
}
local function AcceptIndicator(props: AcceptIndicatorProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.position,
		Size = UDim2.fromOffset(260, 49),
	}, {
		indicatorText = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = props.text,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(49, 18),
			Size = UDim2.fromOffset(160, 15),
		}),

		stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(51, 51, 51),
			Thickness = 2,
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
	})
end

return React.memo(AcceptIndicator)
