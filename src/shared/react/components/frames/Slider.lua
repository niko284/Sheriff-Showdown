--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local DependencyArray = require(ReplicatedStorage.utils.DependencyArray)
local Freeze = require(ReplicatedStorage.packages.Freeze)
local Janitor = require(ReplicatedStorage.packages.Janitor)
local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useRef = React.useRef
local useBinding = React.useBinding
local useCallback = React.useCallback
local useEffect = React.useEffect

type SliderProps = Types.FrameProps & {
	percentage: number,
	minimum: number,
	snap: boolean,
	increment: number,
	maximum: number,
	onSliderReleased: (number) -> (),
}

local defaultProps = {
	minimum = 0,
	maximum = 100,
	snap = true,
	size = UDim2.fromScale(1, 0),
	percentage = 100,
	increment = 1,
}

local function Slider(props: SliderProps)
	props = Freeze.Dictionary.merge(defaultProps, props)

	local draggerInstance = useRef(nil :: ImageButton?)
	local sliderInstance = useRef(nil :: Frame?)
	local dragging = useRef(false :: boolean)
	local sliderJanitor = useRef(Janitor.new())
	local draggerPosition, setDraggerPosition = useBinding(UDim2.fromScale(props.percentage / 100, 0.5))

	local _styles, api = ReactSpring.useSpring(function()
		return {
			draggerSize = UDim2.fromScale(0.2, 0.2),
			config = ReactSpring.config.gentle,
		}
	end)

	local onDragged = useCallback(
		function(InputObject: InputObject)
			local draggerRef = draggerInstance
			local sliderRef = sliderInstance
			if draggerRef and draggerRef.current and sliderInstance.current and sliderRef and sliderRef.current then
				local dragPosition = draggerRef.current.Position
				local percentage = nil
				if InputObject.KeyCode == Enum.KeyCode.Thumbstick1 then
					local movePosition = InputObject.Position.X
					if math.abs(movePosition) > 0.15 then
						percentage = dragPosition.X.Scale + (movePosition > 0 and 0.01 or -0.01)
					end
				elseif
					InputObject.UserInputType == Enum.UserInputType.MouseMovement
					or InputObject.UserInputType == Enum.UserInputType.Touch
					or InputObject.UserInputType == Enum.UserInputType.MouseButton1
				then
					local sliderStart = sliderRef.current.AbsolutePosition
					local mousePosition = InputObject.Position
					local mouseDifference = mousePosition.X - sliderStart.X
					percentage = mouseDifference / sliderRef.current.AbsoluteSize.X
				end
				if percentage ~= nil then
					percentage = math.clamp(percentage, 0, 1)
					local newValue = props.minimum + ((props.maximum - props.minimum) * percentage)
					if props.snap then
						newValue = math.round(newValue)
					end
					setDraggerPosition(
						UDim2.fromScale((percentage * (1 / props.increment)) / (1 / props.increment), 0.5)
					)
				end
			end
		end,
		DependencyArray(
			draggerInstance,
			dragging,
			setDraggerPosition,
			props.minimum,
			props.maximum,
			props.snap,
			sliderInstance,
			props.increment
		) :: { any }
	)

	useEffect(
		function()
			if sliderJanitor.current then
				sliderJanitor.current:Add(UserInputService.InputChanged:Connect(function(InputObject: InputObject)
					if dragging.current == true then
						onDragged(InputObject)
					end
				end))
				sliderJanitor.current:Add(UserInputService.InputEnded:Connect(function(InputObject: InputObject)
					if
						(
							InputObject.UserInputType == Enum.UserInputType.MouseButton1
							or InputObject.UserInputType == Enum.UserInputType.Touch
						) and dragging.current == true
					then
						dragging.current = false
						if props.onSliderReleased and typeof(props.onSliderReleased) == "function" then
							props.onSliderReleased(draggerPosition:getValue().X.Scale * 100)
						end
					end
				end))
				setDraggerPosition(UDim2.fromScale(props.percentage / 100, 0.5))
			end
			return function()
				if sliderJanitor.current then
					sliderJanitor.current:Cleanup()
				end
			end
		end,
		DependencyArray(
			props.percentage,
			setDraggerPosition,
			props.onSliderReleased,
			dragging,
			draggerPosition,
			sliderJanitor,
			onDragged,
			api
		) :: { any }
	)

	return e("Frame", {
		ref = sliderInstance,
		BackgroundTransparency = 0.81,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.position,
		Size = UDim2.fromOffset(167, 8),
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),

		sliderButton = e("TextButton", {
			ZIndex = 2,
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1.1, 2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			[React.Event.Activated] = function(_rbx: TextButton, input: InputObject)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					onDragged(input)
				end
			end,
			[React.Event.InputBegan] = function(_rbx: TextButton, input: InputObject)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragging.current = true
				end
			end,
		}),

		value = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = draggerPosition:map(function(position: UDim2)
				local newValue = props.minimum + ((props.maximum - props.minimum) * position.X.Scale)
				if props.snap then
					newValue = math.clamp(math.round(newValue), props.minimum, props.maximum)
				end
				return newValue
			end),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextTransparency = 0.694,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(176, -1),
			Size = UDim2.fromOffset(14, 10),
		}),

		sliderBar = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0.5),
			Size = draggerPosition,
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),

		dragger = e("ImageButton", {
			ref = draggerInstance,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			LayoutOrder = 2,
			AutoButtonColor = false,
			Position = draggerPosition,
			Size = UDim2.fromScale(0.07, 0.07),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			[React.Event.SelectionGained] = function()
				dragging.current = true
			end,
			[React.Event.SelectionLost] = function()
				dragging.current = false
				if props.onSliderReleased and typeof(props.onSliderReleased) == "function" then
					props.onSliderReleased(draggerPosition:getValue().X.Scale * 100)
				end
			end,
			[React.Event.InputBegan] = function(_rbx, input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragging.current = true
				end
			end :: any,
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(0.5, 0),
			}),

			gradient = e("UIGradient", {
				Rotation = 90,
			}),
		}),
	})
end

return React.memo(Slider)
