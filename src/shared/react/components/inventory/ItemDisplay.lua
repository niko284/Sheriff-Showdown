--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Utils = ReplicatedStorage.utils
local Constants = ReplicatedStorage.constants

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local Button = require(Components.buttons.Button)
local ItemTypes = require(Constants.ItemTypes)
local ItemUtils = require(Utils.ItemUtils)
local Rarities = require(ReplicatedStorage.constants.Rarities)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type ItemDisplayProps = Types.FrameProps & {
	itemName: string,
	itemId: number,
	serial: number?,
	rarity: Types.ItemRarity,
	image: string,
	killCount: number?,
}

local function ItemDisplay(props: ItemDisplayProps)
	local rarityInfo = Rarities[props.rarity]

	local itemInfo = ItemUtils.GetItemInfoFromId(props.itemId)
	local itemTypeInfo = ItemTypes[itemInfo.Type]

	return e("ImageLabel", {
		Image = "rbxassetid://17886556400",
		BackgroundTransparency = 1,
		Position = props.position,
		Size = props.size,
	}, {
		weaponName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.itemName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(25, 30),
			Size = UDim2.fromOffset(124, 15),
		}),

		rarity = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = props.rarity,
			TextColor3 = rarityInfo.Color,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 54),
			Size = UDim2.fromOffset(35, 11),
		}),

		itemSerial = props.serial and e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(200, 25),
			Size = UDim2.fromOffset(70, 30),
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),

			serial = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "#" .. props.serial,
				TextColor3 = Color3.fromRGB(72, 72, 72),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 11),
				Size = UDim2.fromOffset(42, 9),
			}),
		}),

		itemImage = e("ImageLabel", {
			Image = props.image,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(60, 51),
			Size = UDim2.fromOffset(178, 178),
		}),

		killText = props.killCount and e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(70, 53),
			Size = UDim2.fromOffset(65, 12),
		}, {
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
				Position = UDim2.fromOffset(17, 1),
				Size = UDim2.fromOffset(48, 11),
			}),

			deathIcon = e("ImageLabel", {
				Image = "rbxassetid://17886556724",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(13, 12),
			}),
		}),

		options = e("ImageLabel", {
			Image = "rbxassetid://17886569101",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(23, 80),
			Size = UDim2.fromOffset(56, 26),
		}, {
			lock = e("ImageLabel", {
				Image = "rbxassetid://17886569169",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(8, 6),
				Size = UDim2.fromOffset(12, 14),
			}),

			favorite = e("ImageLabel", {
				Image = "rbxassetid://17886569282",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(35, 5),
				Size = UDim2.fromOffset(16, 16),
			}),

			seperator = e("ImageLabel", {
				Image = "rbxassetid://17886569505",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(26, 6),
				Size = UDim2.fromOffset(4, 13),
			}),
		}),

		buttonList = e(AutomaticScrollingFrame, {
			scrollBarThickness = 7,
			active = true,
			backgroundTransparency = 1,
			anchorPoint = Vector2.new(0, 0),
			borderSizePixel = 0,
			position = UDim2.fromScale(0.0307, 0.674),
			size = UDim2.fromOffset(278, 100),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 5),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 5),
			}),

			equip = itemTypeInfo.CanEquip and e(Button, {
				fontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				position = UDim2.fromOffset(147, 251),
				size = UDim2.fromOffset(262, 44),
				text = "Equip",
				textColor3 = Color3.fromRGB(0, 54, 25),
				anchorPoint = Vector2.new(0.5, 0.5),
				textSize = 16,
				strokeThickness = 1.5,
				layoutOrder = 1,
				applyStrokeMode = Enum.ApplyStrokeMode.Border,
				strokeColor = Color3.fromRGB(255, 255, 255),
				cornerRadius = UDim.new(0, 5),
				gradient = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 252, 153)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 203, 112)),
				}),
				gradientRotation = -90,
			}),

			sell = itemTypeInfo.CanSell and e(Button, {
				backgroundTransparency = 1,
				position = UDim2.fromOffset(147, 303),
				anchorPoint = Vector2.new(0.5, 0.5),
				size = UDim2.fromOffset(262, 44),
				text = "Sell",
				layoutOrder = 2,
				textColor3 = Color3.fromRGB(255, 255, 255),
				textSize = 16,
				strokeThickness = 1.5,
				applyStrokeMode = Enum.ApplyStrokeMode.Border,
				strokeColor = Color3.fromRGB(255, 255, 255),
				cornerRadius = UDim.new(0, 5),
				fontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
			}),
		}),
	})
end

return ItemDisplay
