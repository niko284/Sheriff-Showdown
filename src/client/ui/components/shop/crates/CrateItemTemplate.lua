--!strict

local Rarities = require("@constants/Rarities")
local React = require("@packages/React")
local Types = require("@constants/Types")
local UIStroke = require("@ui/components/other/UIStroke")

local e = React.createElement

type CrateItemTemplateProps = {
	icon: string,
	layoutOrder: number,
	itemName: string,
	itemRarity: Types.ItemRarity?,
	rarity: number,
}

local function CrateItemTemplate(props: CrateItemTemplateProps)
	local rarityInfo = props.itemRarity and Rarities[props.itemRarity] or nil

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e(UIStroke, {
			color = Color3.fromRGB(255, 255, 255),
		}),

		grad = rarityInfo and e("ImageLabel", {
			ZIndex = -1,
			Image = "rbxassetid://17886581996",
			ImageColor3 = rarityInfo.Color,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.00685, 0.479),
			Size = UDim2.fromScale(1, 0.521),
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
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 100),
			Size = UDim2.fromOffset(68, 9),
			ZIndex = 3,
		}, {
			stroke = e(UIStroke, {
				color = Color3.fromRGB(0, 0, 0),
				thickness = 1.8,
			}),
		}),

		rarity = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = string.format("%d%%", props.rarity),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(11, 120),
			Size = UDim2.fromOffset(25, 9),
			ZIndex = 3,
		}, {
			stroke = e(UIStroke, {
				color = Color3.fromRGB(0, 0, 0),
				thickness = 1.8,
			}),
		}),
	})
end

return React.memo(CrateItemTemplate)
