--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type CloseButtonProps = Types.FrameProps & {}

local function CloseButton(props: CloseButtonProps)
	return e("ImageButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
	}, {
		closeImage = e("ImageLabel", {
			Image = "rbxassetid://17886543363",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromScale(0.442, 0.442),
		}),

		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
	})
end

return CloseButton
