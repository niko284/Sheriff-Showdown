--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useState = React.useState

type CloseButtonProps = Types.FrameProps & {
	onActivated: ((rbx: ImageButton) -> ())?,
}

local function CloseButton(props: CloseButtonProps)
	local isHovered, setIsHovered = useState(false)
	local isPressed, setIsPressed = useState(false)

	local styles = ReactSpring.useSpring({
		scale = if isPressed then 0.98 elseif isHovered then 1.02 else 1,
		config = {
			duration = 0.1, -- seconds
			easing = ReactSpring.easings.easeInOutQuad,
		},
	}, { isPressed, isHovered } :: { any })

	return e("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
		[React.Event.MouseEnter] = function()
			setIsHovered(true) -- // Set the hovered state to true.
		end,
		[React.Event.MouseLeave] = function()
			setIsHovered(false) -- // Set the hovered state to false.
		end,
		[React.Event.InputBegan] = function(_rbx: Instance, InputObject: InputObject)
			if
				InputObject.UserInputState == Enum.UserInputState.Begin -- If the user is pressing down the button, set the pressed state to true
				and (
					InputObject.UserInputType == Enum.UserInputType.MouseButton1
					or InputObject.UserInputType == Enum.UserInputType.Touch
				)
			then
				setIsPressed(true)
			end
		end :: any,
		[React.Event.InputEnded] = function(_rbx: Instance, InputObject: InputObject)
			if
				InputObject.UserInputState == Enum.UserInputState.End -- If the user is releasing the button, set the pressed state to false
				and (
					InputObject.UserInputType == Enum.UserInputType.MouseButton1
					or InputObject.UserInputType == Enum.UserInputType.Touch
				)
			then
				setIsPressed(false)
			end
		end :: any,
		[React.Event.Activated] = props.onActivated :: any,
	}, {
		scale = e("UIScale", {
			Scale = styles.scale,
		}),

		closeImage = e("ImageLabel", {
			Image = "rbxassetid://17886543363",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromScale(0.442, 0.442),
		}),

		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
	})
end

return React.memo(CloseButton)
