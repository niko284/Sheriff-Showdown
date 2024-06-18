--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local Rarities = require(ReplicatedStorage.constants.Rarities)
local React = require(ReplicatedStorage.packages.React)
local Separator = require(Components.other.Separator)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type ItemProps = Types.FrameProps & {
	image: string,
	rarity: Types.ItemRarity,
	itemName: string,
	itemUUID: string,
	onItemClicked: (uuid: string) -> (),
	itemSerial: number?,
	killCount: number?,
}

local function Item(props: ItemProps)
	local rarityInfo = Rarities[props.rarity]

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		killCount = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.53, 0.808),
			Size = UDim2.fromScale(0.445, 0.0822),
			ZIndex = 2,
		}, {
			image = e("ImageLabel", {
				Image = "rbxassetid://17886530345",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.215, 1),
			}),

			kills = props.killCount and e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				Text = props.killCount,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.262, 0.0833),
				Size = UDim2.fromScale(0.738, 0.917),
			}),
		}),

		clickButton = e("ImageButton", {
			Image = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			[React.Event.Activated] = function()
				props.onItemClicked(props.itemUUID)
			end,
		}),

		itemImage = e("ImageLabel", {
			Image = props.image,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.116, 0.171),
			Size = UDim2.fromScale(0.781, 0.781),
		}),

		options = e("ImageLabel", {
			Image = "rbxassetid://17886582104",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.548, 0.0685),
			Size = UDim2.fromScale(0.384, 0.185),
		}, {
			favorite = e("ImageLabel", {
				Image = "rbxassetid://17886594006",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.607, 0.222),
				Size = UDim2.fromScale(0.286, 0.593),
			}),

			lock = e("ImageLabel", {
				Image = "rbxassetid://17886530096",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.125, 0.259),
				Size = UDim2.fromScale(0.214, 0.519),
			}),

			seperator = e(Separator, {
				position = UDim2.fromScale(0.446, 0.259),
				size = UDim2.fromScale(0.0893, 0.481),
			}),
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
			Position = UDim2.fromScale(0.0822, 0.692),
			Size = UDim2.fromScale(0.466, 0.0616),
			ZIndex = 2,
		}),

		rarity = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.ExtraBold,
				Enum.FontStyle.Normal
			),
			Text = props.rarity,
			TextColor3 = rarityInfo.Color,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0822, 0.815),
			Size = UDim2.fromScale(0.185, 0.0616),
			ZIndex = 2,
		}),

		serials = props.itemSerial and e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = string.format("#%d", props.itemSerial),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0753, 0.13),
			Size = UDim2.fromScale(0.192, 0.0616),
			ZIndex = 2,
		}),

		stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		gradient = e("ImageLabel", {
			Image = "rbxassetid://17886581996",
			ImageColor3 = rarityInfo.Color,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.00685, 0.479),
			Size = UDim2.fromScale(1, 0.521),
		}),
	})
end

return React.memo(Item)
