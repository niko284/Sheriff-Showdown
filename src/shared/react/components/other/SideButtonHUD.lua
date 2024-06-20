--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local React = require(ReplicatedStorage.packages.React)
local SideButton = require(Components.buttons.SideButton)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type SideButtonData = {
	Image: string,
	Gradient: ColorSequence,
	LayoutOrder: number,
}
type SideButtonHUDProps = {
	buttons: { [Types.Interface]: SideButtonData },
}

local function SideButtonHUD(props: SideButtonHUDProps)
	local sideButtonElements = {}

	for name, sideButton in pairs(props.buttons) do
		table.insert(
			sideButtonElements,
			e(SideButton, {
				layoutOrder = sideButton.LayoutOrder,
				icon = sideButton.Image,
				buttonPath = name,
				size = UDim2.fromOffset(78, 78),
				gradient = sideButton.Gradient,
			})
		)
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.00573, 0.219),
		Size = UDim2.fromOffset(99, 608),
	}, {
		listLayout = e("UIListLayout", {
			Padding = UDim.new(0, 15),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		buttons = e(React.Fragment, nil, sideButtonElements),
	})
end

return SideButtonHUD
