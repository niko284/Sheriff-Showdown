-- Currency Button
-- March 2nd, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Vendor = ReplicatedStorage.vendor

local Currencies = require(Constants.Currencies)
local FormatNumber = require(Vendor.FormatNumber)
local React = require(Packages.React)
local Types = require(Constants.Types)

local NumberFormatter = FormatNumber.NumberFormatter

local e = React.createElement
local useRef = React.useRef

-- // Currency Button \\

type CurrencyButtonProps = Types.FrameProps & {
	currency: Types.Currency,
	amount: number,
	onActivated: (Types.CratePurchaseInfo) -> (),
}

local function CurrencyButton(props: CurrencyButtonProps)
	local formatter = useRef(NumberFormatter.with():Precision(FormatNumber.Precision.integer()))

	local currencyInfo = Currencies[props.currency]

	return e("TextButton", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 22,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.00521, 0),
		Size = props.size,
		[React.Event.Activated] = props.onActivated,
	}, {
		uICorner = e("UICorner"),

		uIStroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 2,
			Transparency = 0.7,
		}, {
			uIGradient = e("UIGradient", {
				Rotation = -90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.196, 0.639),
					NumberSequenceKeypoint.new(0.731, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),

		currencyImage = e("ImageLabel", {
			Image = string.format("rbxassetid://%d", currencyInfo.Image),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.018, -0.0214),
			Size = UDim2.fromOffset(53, 53),
		}, {
			uIGradient1 = e("UIGradient", {
				Color = currencyInfo.GradientColor,
				Rotation = 115,
			}),
		}),

		amount = e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			Text = formatter.current:Format(props.amount),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.369, 0.291),
			Size = UDim2.fromOffset(97, 26),
		}),
	})
end

return React.memo(CurrencyButton)
