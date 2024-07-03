--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Contexts = ReplicatedStorage.react.contexts
local Components = ReplicatedStorage.react.components

local AutomaticFrame = require(Components.frames.AutomaticFrame)
local Currencies = require(ReplicatedStorage.constants.Currencies)
local FormatNumber = require(ReplicatedStorage.utils.FormatNumber)
local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local ResourceContext = require(Contexts.ResourceContext)
local Separator = require(Components.other.Separator)
local Types = require(ReplicatedStorage.constants.Types)

local NumberFormatter = FormatNumber.NumberFormatter

local e = React.createElement
local useContext = React.useContext
local useRef = React.useRef

type CurrencyHolderProps = Types.FrameProps & {
	currency: Types.Currency,
}

local function CurrencyHolder(props: CurrencyHolderProps)
	local currencyData = Currencies[props.currency]

	local resources = useContext(ResourceContext)
	local formatter = useRef(NumberFormatter.with():Precision(FormatNumber.Precision.integer()))

	local amount = resources and resources[props.currency] or 0

	local displayStyles = ReactSpring.useSpring({
		amount = amount,
		config = {
			duration = 0.5,
			easing = ReactSpring.easings.easeOutQuad,
		},
	}, { amount })

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
			Text = displayStyles.amount:map(function(newCurrency: number?)
				if not newCurrency then
					return "0"
				end
				if formatter.current and typeof(newCurrency) == "number" then
					--print(newCurrency)
					local success, formattedNumber = pcall(function()
						return formatter.current:Format(newCurrency) -- pcall because FormatNumber is a bit buggy
					end)
					return success and formattedNumber or newCurrency
				else
					return "0"
				end
			end),
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
