--!strict

-- Dropdown Setting
-- February 24th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.react.components
local Constants = ReplicatedStorage.constants

local BaseButton = require(Components.buttons.Button)
local Dropdown = require(Components.frames.Dropdown)
local React = require(Packages.React)
local Types = require(Constants.Types)

local e = React.createElement
local useBinding = React.useBinding

type DropdownSettingProps = Types.FrameProps & {
	name: string,
	description: string,
	selections: { string },
	currentSelection: string,
	changeSetting: (settingName: string, settingValue: Types.SettingValue) -> (),
}

local function DropdownTemplate(props: DropdownSettingProps)
	local zIndex, setZIndex = useBinding(props.zIndex or 1)
	return e("Frame", {
		ZIndex = zIndex,
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BackgroundTransparency = 0.64,
		LayoutOrder = props.layoutOrder,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
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

		dropdown = e(Dropdown, {
			buttonSizeX = 122, -- size in pixels
			buttonSizeY = 36,
			paddingTop = 5,
			selectionElement = BaseButton,
			selections = props.selections,
			anchorPoint = Vector2.new(0.5, 0),
			onSelection = function(selection: string)
				props.changeSetting(props.name, selection)
			end,
			onToggle = function(toggled: boolean)
				if props.layoutOrder then
					setZIndex(toggled and (1 / props.layoutOrder) * 100 or -1)
				end
			end,
			currentSelection = props.currentSelection,
			position = UDim2.fromScale(0.907, 0.253),
		}),
	})
end

return React.memo(DropdownTemplate)
