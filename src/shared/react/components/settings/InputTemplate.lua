--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MappedInterpolation = require(ReplicatedStorage.utils.MappedInterpolation)
local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local StringUtils = require(ReplicatedStorage.utils.StringUtils)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useCallback = React.useCallback
local useRef = React.useRef

type InputTemplateProps = Types.FrameProps & {
	name: string,
	description: string,
	currentInput: string,
	changeSetting: (settingName: string, settingValue: Types.SettingValue) -> (),
	inputRange: { number },
	outputRange: { number },
	inputVerifiers: { (input: string) -> boolean }?,
}

local function InputTemplate(props: InputTemplateProps)
	local isShaking = useRef(false)

	local styles, api = ReactSpring.useSpring(function()
		return {
			from = {
				x = 0,
				y = 0,
			},
		}
	end)

	local animateInvalidInput = useCallback(function()
		if isShaking.current == true then
			return
		end

		isShaking.current = true
		api.start({
			to = {
				x = 1,
				y = 1,
			},
		})
			:andThenCall(api.start, {
				x = 0,
				y = 0,
				immediate = true,
			})
			:finally(function()
				isShaking.current = false
			end)
	end, {})

	local verifyInput = useCallback(function(input: string)
		local isValid = true

		if props.inputVerifiers then
			for _, verifier in props.inputVerifiers do
				isValid = isValid and verifier(input) -- if already false, it will stay false
			end
		end

		return isValid
	end, { props.inputVerifiers })

	local inputBoxPosition = UDim2.fromScale(0.907, 0.507)

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BackgroundTransparency = 0.64,
		LayoutOrder = props.layoutOrder,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 1,
			Transparency = 0.67,
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = props.description,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextTransparency = 0.38,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 42),
			Size = UDim2.fromOffset(200, 11),
		}),

		name = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 19),
			Size = UDim2.fromOffset(115, 16),
		}),

		inputBox = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.89,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = React.joinBindings({ styles.x, styles.y } :: { any }):map(function(values)
				if not inputBoxPosition then
					return UDim2.new(0, 0, 0, 0) -- Button might be in a layout, so we don't want to move it.
				end
				if values[1] == 0 or values[2] == 0 then
					return inputBoxPosition
				end
				local xInterpolated =
					MappedInterpolation(values[1], props.inputRange, props.outputRange, "identity", "identity")
				return UDim2.fromScale(inputBoxPosition.X.Scale, inputBoxPosition.Y.Scale)
					+ UDim2.fromOffset(xInterpolated, 0)
			end),
			Size = UDim2.fromOffset(122, 36),
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),

			stroke = e("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 1.4,
				Transparency = 0.69,
			}),

			textBox = e("TextBox", {
				CursorPosition = -1,
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Text = props.currentInput,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20,
				TextScaled = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.86, 0.6),
				[React.Event.FocusLost] = function(rbx)
					local onlySpaces = StringUtils.ContainsOnlySpaces(rbx.Text)
					if verifyInput(rbx.Text) or onlySpaces then
						if onlySpaces then
							return
						end
						props.changeSetting(props.name, rbx.Text)
					else
						animateInvalidInput()
						rbx.Text = props.currentInput
					end
				end,
			}),
		}),
	})
end

return React.memo(InputTemplate)
