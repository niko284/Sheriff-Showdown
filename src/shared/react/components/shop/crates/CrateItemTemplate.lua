--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)

local e = React.createElement

type CrateItemTemplateProps = {
	icon: string,
	itemName: string,
	rarity: number,
}

local function CrateItemTemplate(props: CrateItemTemplateProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
		}),

		gradient = e("ImageLabel", {
			Image = "rbxassetid://18134658384",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(145, 145),
			ZIndex = 2,
		}),

		gunImage = e("ImageLabel", {
			Image = props.icon,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 17),
			Size = UDim2.fromOffset(114, 115),
		}),

		itemName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = props.itemName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 100),
			Size = UDim2.fromOffset(68, 9),
			ZIndex = 3,
		}),

		rarity = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = string.format("%d%%", props.rarity),
			TextColor3 = Color3.fromRGB(156, 221, 250),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(11, 118),
			Size = UDim2.fromOffset(25, 9),
			ZIndex = 3,
		}),
	})
end

return React.memo(CrateItemTemplate)
