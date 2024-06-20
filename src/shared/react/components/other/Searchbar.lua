--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local React = require(ReplicatedStorage.packages.React)
local Separator = require(Components.other.Separator)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type SearchbarProps = {
	onTextChanged: ((rbx: TextBox) -> ())?,
} & Types.FrameProps

local function Searchbar(props: SearchbarProps)
	return e("ImageLabel", {
		Image = "rbxassetid://17886544047",
		BackgroundTransparency = 1,
		Position = props.position,
		Size = props.size,
	}, {
		seperator = e(Separator, {
			position = UDim2.fromOffset(40, 16),
			size = UDim2.fromScale(0.025, 0.302),
		}),

		searchIcon = e("ImageLabel", {
			Image = "rbxassetid://17886556245",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(15, 13),
			Size = UDim2.fromScale(0.111, 0.442),
		}),

		inputBox = e("TextBox", {
			CursorPosition = -1,
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
			PlaceholderText = "Search",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextTransparency = 0.369,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = "",
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(53, 12),
			Size = UDim2.fromScale(0.642, 0.465),
			[React.Change.Text] = props.onTextChanged,
		}),
	})
end

return Searchbar
