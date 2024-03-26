-- Price Indicator
-- March 2nd, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vendor = ReplicatedStorage.vendor
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Hooks = ReplicatedStorage.hooks
local Components = ReplicatedStorage.components
local FrameComponents = Components.frames

local AutomaticFrame = require(FrameComponents.AutomaticFrame)
local FormatNumber = require(Vendor.FormatNumber)
local React = require(Packages.React)
local Types = require(Constants.Types)
local useProductInfoFromId = require(Hooks.useProductInfoFromId)

local NumberFormatter = FormatNumber.NumberFormatter

local e = React.createElement
local useRef = React.useRef

local PURCHASE_TYPE_SIZES = {
	Coins = {
		ImageSize = UDim2.fromOffset(25, 25),
		GradientColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.121, Color3.fromRGB(255, 234, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 151, 2)),
		}),
	},
	Robux = {
		ImageSize = UDim2.fromOffset(25, 25),
	},
	Gems = {
		ImageSize = UDim2.fromOffset(25, 25),
		GradientColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.0657, Color3.fromRGB(229, 255, 255)),
			ColorSequenceKeypoint.new(0.419, Color3.fromRGB(7, 255, 255)),
			ColorSequenceKeypoint.new(0.796, Color3.fromRGB(73, 231, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 106, 120)),
		}),
	},
}

-- // Price Indicator \\

type PriceIndicatorProps = Types.FrameProps & {
	PurchaseType: Types.PurchaseType,
	Price: number?,
	ProductId: number?,
}

local function PriceIndicator(props: PriceIndicatorProps)
	local formatter = useRef(NumberFormatter.with():Precision(FormatNumber.Precision.integer()))
	local productInfo = useProductInfoFromId(props.ProductId, Enum.InfoType.Product)

	local priceToShow = props.Price
	if productInfo and productInfo.PriceInRobux then
		priceToShow = productInfo.PriceInRobux
	end

	local iconSize = PURCHASE_TYPE_SIZES[props.PurchaseType].ImageSize
	local gradientColor = PURCHASE_TYPE_SIZES[props.PurchaseType].GradientColor

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.0761, 0.29),
		Size = props.size,
	}, {
		cost = e(AutomaticFrame, {
			instanceProps = {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = priceToShow and formatter.current:Format(priceToShow) or "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 15,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.425, 0),
			},
			className = "TextLabel",
			maxSize = Vector2.new(math.huge, 34),
		}),

		priceImage = props.PurchaseType ~= "Robux" and e("ImageLabel", {
			Image = "rbxassetid://16419213714",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.04, -0.2),
			Size = iconSize,
		}, {
			uIGradient = e("UIGradient", {
				Color = gradientColor,
				Rotation = 115,
			}),
		}) or e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Text = "",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 22,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0116, 0.0436),
			Size = UDim2.fromOffset(31, 31),
		}),
	})
end

return React.memo(PriceIndicator)
