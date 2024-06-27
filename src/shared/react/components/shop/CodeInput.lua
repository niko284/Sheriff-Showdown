--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.packages.Freeze)
local MappedInterpolation = require(ReplicatedStorage.utils.MappedInterpolation)
local Net = require(ReplicatedStorage.packages.Net)
local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Types = require(ReplicatedStorage.constants.Types)

local useRef = React.useRef
local e = React.createElement
local useCallback = React.useCallback

local ShopNamespace = Remotes.Client:GetNamespace("Shop")
local SubmitCode = ShopNamespace:Get("SubmitCode") :: Net.ClientAsyncCaller

local DEFAULT_PROPS = {
	inputRange = { 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 },
	outputRange = { 0, -15, 15, -15, 15, -15, 15, -15, 15, -15, 0 },
}

type CodeInputProps = {
	onCodeEntered: ((code: string) -> ())?,
	position: UDim2,
	codesPosition: UDim2,
	inputRange: { number },
	outputRange: { number },
}

local function CodeInput(props: CodeInputProps)
	props = Freeze.Dictionary.merge(DEFAULT_PROPS, props)

	local textBoxRef = useRef(nil :: TextBox?)
	local isShaking = useRef(false)

	local styles, api = ReactSpring.useSpring(function()
		return {
			from = {
				x = 0,
				y = 0,
				buttonColor = Color3.fromRGB(120, 120, 120),
				size = UDim2.fromOffset(423, 42),
			},
		}
	end)

	local animateIncorrectCode = useCallback(function()
		if isShaking.current == true then
			return
		end

		isShaking.current = true
		api.start({
			to = {
				x = 1,
				y = 1,
				buttonColor = Color3.fromRGB(255, 100, 98),
				size = UDim2.fromOffset(453, 72),
			},
		})
			:andThenCall(function()
				return api.start({
					buttonColor = Color3.fromRGB(120, 120, 120),
					size = UDim2.fromOffset(423, 42),
				})
			end)
			:andThenCall(api.start, {
				x = 0,
				y = 0,
				immediate = true,
			})
			:finally(function()
				isShaking.current = false
			end)
	end, {})

	local animateCorrectCode = useCallback(function()
		if isShaking.current == true then
			return
		end
		isShaking.current = true

		api.start({
			to = {
				buttonColor = Color3.fromRGB(100, 255, 98),
				size = UDim2.fromOffset(423, 42),
				x = 0,
				y = 0,
			},
		})
			:andThenCall(api.start, {
				buttonColor = Color3.fromRGB(120, 120, 120),
				size = UDim2.fromOffset(453, 72),
			})
			:finally(function()
				isShaking.current = false
			end)
	end, {})

	local submitCode = useCallback(function()
		local textBox = textBoxRef.current
		if textBox then
			local code = textBox.Text
			SubmitCode:CallServerAsync(code)
				:andThen(function(response: Types.NetworkResponse)
					if response.Success == false then
						animateIncorrectCode()
					else
						animateCorrectCode()
					end
				end)
				:catch(function(err)
					animateIncorrectCode()
					warn(tostring(err))
				end)
		end
	end, {})

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.position,
		Size = UDim2.fromOffset(447, 163),
	}, {
		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		codes = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = styles.buttonColor,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = React.joinBindings({ styles.x, styles.y } :: { any }):map(function(values)
				if not props.codesPosition then
					return UDim2.new(0, 0, 0, 0) -- Button might be in a layout, so we don't want to move it.
				end
				if values[1] == 0 or values[2] == 0 then
					return props.codesPosition
				end
				local xInterpolated =
					MappedInterpolation(values[1], props.inputRange, props.outputRange, "identity", "identity")
				return UDim2.fromScale(props.codesPosition.X.Scale, props.codesPosition.Y.Scale)
					+ UDim2.fromOffset(xInterpolated, 0)
			end),
			Size = styles.size,
		}, {
			enterArrow = e("ImageButton", {
				Image = "rbxassetid://18192556265",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(390, 14),
				Size = UDim2.fromOffset(14, 14),
				[React.Event.Activated] = function(_imageButton)
					if textBoxRef.current and props.onCodeEntered then
						props.onCodeEntered(textBoxRef.current.Text)
					end
					submitCode()
				end,
			}),

			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),

			codeInput = e("TextBox", {
				ref = textBoxRef,
				CursorPosition = -1,
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
				PlaceholderText = "Enter Code Here",
				Text = "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.369,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Position = UDim2.fromOffset(17, 7),
				Size = UDim2.fromOffset(344, 28),
			}),
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = "Follow us on Twitter for codes! @SheriffShowdown",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextTransparency = 0.369,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 45),
			Size = UDim2.fromOffset(80, 14),
		}),

		enterCodes = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Enter Codes",
			TextColor3 = Color3.fromRGB(87, 255, 242),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 23),
			Size = UDim2.fromOffset(100, 12),
		}),
	})
end

return React.memo(CodeInput)
