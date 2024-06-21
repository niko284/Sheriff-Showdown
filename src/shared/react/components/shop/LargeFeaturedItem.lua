--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type LargeFeaturedItemProps = Types.FrameProps & {
	icon: string,
	featuredName: string,
	rarity: Types.ItemRarity,
}

local function LargeFeaturedItem(props: LargeFeaturedItemProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		LayoutOrder = props.layoutOrder,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		gradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(72, 72, 72)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(72, 72, 72)),
			}),
			Rotation = 90,
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
		}),

		featuredIcon = e("ImageLabel", {
			Image = props.icon,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(127, 12),
			Size = UDim2.fromOffset(115, 116),
		}),

		itemName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.featuredName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			ZIndex = 2,
			Position = UDim2.fromOffset(14, 102),
			Size = UDim2.fromOffset(70, 11),
		}),

		rarity = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.rarity,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 123),
			Size = UDim2.fromOffset(24, 10),
		}),
	})
end

return React.memo(LargeFeaturedItem)
