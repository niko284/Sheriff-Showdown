--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local React = require(ReplicatedStorage.packages.React)
local Separator = require(Components.other.Separator)

local e = React.createElement

type CategoryTemplateProps = {
	description: string,
	layoutOrder: number,
	name: string,
}

local function CategoryTemplate(props: CategoryTemplateProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Position = UDim2.fromScale(0.026, 0.163),
		Size = UDim2.fromOffset(799, 86),
	}, {
		seperator = e(Separator, {
			position = UDim2.fromOffset(0, 75),
			size = UDim2.fromOffset(795, 1),
			image = "rbxassetid://18199915110",
		}),

		categoryDescription = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = props.description,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextTransparency = 0.663,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 39),
			Size = UDim2.fromOffset(210, 11),
		}),

		categoryName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(1, 9),
			Size = UDim2.fromOffset(191, 21),
		}),
	})
end

return React.memo(CategoryTemplate)
