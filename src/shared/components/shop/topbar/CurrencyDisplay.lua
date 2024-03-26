-- Currency Indicator
-- February 24th, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Controllers = PlayerScripts.controllers
local Vendor = ReplicatedStorage.vendor

local Currencies = require(Constants.Currencies)
local FormatNumber = require(Vendor.FormatNumber)
local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local ResourceController = require(Controllers.ResourceController)
local Types = require(Constants.Types)

local NumberFormatter = FormatNumber.NumberFormatter

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useEffect = React.useEffect

-- // Currency Indicator \\

type CurrencyIndicatorProps = Types.FrameProps & {
	currency: Types.Currency,
	gradientColor: ColorSequence,
}

local function CurrencyIndicator(props: CurrencyIndicatorProps)
	local currency, setCurrency = useState(ResourceController:GetResource(props.currency) :: number?)
	local formatter = useRef(NumberFormatter.with():Precision(FormatNumber.Precision.integer()))

	local currencyInfo = Currencies[props.currency]

	local displayStyles = ReactSpring.useSpring({
		amount = currency or 0,
		config = {
			duration = 0.5,
			easing = ReactSpring.easings.easeOutQuad,
		},
	}, { currency })

	useEffect(function()
		local resourceChanged = ResourceController.ResourceChanged:Connect(
			function(resourceName: string, resource: number)
				if resourceName == props.currency then
					setCurrency(resource)
				end
			end
		)
		return function()
			resourceChanged:Disconnect()
		end
	end, { setCurrency })

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
	}, {
		currencyImage = e("ImageLabel", {
			Image = string.format("rbxassetid://%d", currencyInfo.Image),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(-0.148, -0.178),
			Size = UDim2.fromOffset(57, 57),
		}, {
			uIGradient = e("UIGradient", {
				Color = props.gradientColor,
				Rotation = 115,
			}),
		}),

		uIGradient1 = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 13, 13)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 36, 36)),
			}),
			Rotation = -90,
		}),

		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0.01, 8),
		}),

		coins = e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
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
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0855, 0.0157),
			Size = UDim2.fromOffset(180, 44),
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 3,
			Transparency = 0.3,
		}, {
			uIGradient2 = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
				}),
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.798),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),
	})
end

return React.memo(CurrencyIndicator)
