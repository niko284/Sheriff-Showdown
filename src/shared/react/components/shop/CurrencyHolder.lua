--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local AutomaticFrame = require(Components.frames.AutomaticFrame)
local Currencies = require(ReplicatedStorage.constants.Currencies)
local React = require(ReplicatedStorage.packages.React)
local Separator = require(Components.other.Separator)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type CurrencyHolderProps = Types.FrameProps & {
	currency: Types.Currency,
}

local function CurrencyHolder(props: CurrencyHolderProps)
	local currencyData = Currencies[props.currency]

	print(currencyData.CanPurchase)

	return e(AutomaticFrame, {
		instanceProps = {
			BackgroundColor3 = currencyData.Color,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = props.position,
		},
		maxSize = Vector2.new(math.huge, 42),
	}, {
		separator = currencyData.CanPurchase and e(Separator, {
			image = "rbxassetid://18134633176",
			position = UDim2.fromOffset(104, 14),
			size = UDim2.fromOffset(4, 13),
		}),

		padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 7),
			PaddingBottom = UDim.new(0, 10),
		}),

		amount = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "1,000,000",
			TextColor3 = Color3.fromRGB(65, 65, 65),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 15),
			Size = UDim2.fromOffset(79, 15),
		}),

		buyIcon = currencyData.CanPurchase and e("ImageButton", {
			Image = "rbxassetid://18134633067",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(118, 11),
			Size = UDim2.fromOffset(20, 20),
		}),

		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 0.5,
		}),
	})
end

return React.memo(CurrencyHolder)
