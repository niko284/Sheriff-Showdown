--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type FeaturedItemProps = Types.FrameProps & {
	icon: string,
	featuredName: string,
	rarity: Types.ItemRarity,
}

local function FeaturedItem(props: FeaturedItemProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = props.size,
	}, {
		gradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(72, 72, 72)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(72, 72, 72)),
			}),
			Rotation = 90,
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
		}),

		featuredIcon = e("ImageLabel", {
			Image = props.icon,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(7, 15),
			Size = UDim2.fromOffset(133, 133),
		}),

		gradientImg = e("ImageLabel", {
			Image = "rbxassetid://18134658384",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(163, 163),
		}),

		featuredName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.featuredName,
			ZIndex = 2,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 105),
			Size = UDim2.fromOffset(92, 12),
		}),

		rarity = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			ZIndex = 2,
			Text = props.rarity,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 129),
			Size = UDim2.fromOffset(32, 10),
		}),
	})
end

return React.memo(FeaturedItem)
