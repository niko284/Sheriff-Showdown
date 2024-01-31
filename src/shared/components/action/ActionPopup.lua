--!strict
-- Action Popup
-- Nick
-- January 21st, 2024

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local React = require(Packages.React)

local e = React.createElement

type ActionPopupProps = {
	size: UDim2,
	text: string,
}

local function ActionPopup(props: ActionPopupProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
	}, {
		actionbackground = e("ImageLabel", {
			Image = "rbxassetid://16072535230",
			ImageColor3 = Color3.fromRGB(255, 25, 25),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}),

		actiontext = e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/Guru.json"),
			Text = props.text,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 80,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			uIStroke = e("UIStroke", {
				Thickness = 10,
			}),
		}),
	})
end

return ActionPopup
