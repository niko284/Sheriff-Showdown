--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local Rarities = require(ReplicatedStorage.constants.Rarities)
local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Separator = require(Components.other.Separator)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useState = React.useState

type ItemProps = Types.FrameProps & {
	image: string,
	rarity: Types.ItemRarity?,
	itemName: string,
	isLocked: boolean,
	isFavorited: boolean,
	itemUUID: string,
	onItemClicked: (uuid: string) -> (),
	itemSerial: number?,
	gradient: Color3?,
	killCount: number?,
	hideOptions: boolean?, -- show or hide the favorite and lock options
	stackAmount: number,
}

local function Item(props: ItemProps)
	local rarityInfo = nil
	if props.rarity then
		rarityInfo = Rarities[props.rarity]
	end

	local isHovered, setIsHovered = useState(false)

	local styles = ReactSpring.useSpring({
		scale = if isHovered then 1.08 else 1,
		config = {
			duration = 0.1, -- seconds
			easing = ReactSpring.easings.easeInOutQuad,
		},
	}, { isHovered } :: { any })

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = props.size,
	}, {
		killCount = props.killCount and e("Frame", {
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

			kills = e("TextLabel", {
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

		stackAmount = props.stackAmount and props.stackAmount > 0 and e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = string.format("x%d", props.stackAmount),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 30,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(-0.0411, -0.137),
			Size = UDim2.fromScale(0.713, 0.308),
			ZIndex = 2,
		}, {
			stroke = e("UIStroke"),
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
			[React.Event.MouseEnter] = function()
				setIsHovered(true) -- // Set the hovered state to true.
			end,
			[React.Event.MouseLeave] = function()
				setIsHovered(false) -- // Set the hovered state to false.
			end,
		}),

		itemImage = e("ImageLabel", {
			Image = props.image,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.507, 0.562),
			Size = UDim2.fromScale(0.781, 0.781),
		}, {
			scale = e("UIScale", {
				Scale = styles.scale,
			}),
		}),

		options = props.hideOptions ~= true and e("ImageLabel", {
			Image = "rbxassetid://17886582104",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.548, 0.0685),
			Size = UDim2.fromScale(0.384, 0.185),
		}, {
			favorite = e("ImageButton", {
				Image = "rbxassetid://17886594006",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.607, 0.222),
				Size = UDim2.fromScale(0.286, 0.593),
				ImageColor3 = if props.isFavorited then Color3.fromRGB(255, 170, 0) else Color3.fromRGB(255, 255, 255),
			}),

			lock = e("ImageLabel", {
				Image = "rbxassetid://17886530096",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.125, 0.259),
				Size = UDim2.fromScale(0.214, 0.519),
				ImageColor3 = if props.isLocked then Color3.fromRGB(255, 170, 0) else Color3.fromRGB(255, 255, 255),
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

		rarity = rarityInfo and e("TextLabel", {
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

		gradient = rarityInfo and e("ImageLabel", {
			Image = "rbxassetid://17886581996",
			ImageColor3 = props.gradient or rarityInfo and rarityInfo.Color,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.00685, 0.479),
			Size = UDim2.fromScale(1, 0.521),
		}),
	})
end

return React.memo(Item)
