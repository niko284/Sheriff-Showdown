-- Side Button
-- February 7th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Components = ReplicatedStorage.components

local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local Tooltip = require(Components.common.Tooltip)
local Types = require(Constants.Types)

local e = React.createElement
local useState = React.useState

type SideButtonProps = Types.FrameProps & {
	name: string,
	image: string,
	onActivated: (rbx: ImageButton) -> (),
}

-- // Side Button \\

local function SideButton(props: SideButtonProps)
	local isHovered, setIsHovered = useState(false)
	local isPressed, setIsPressed = useState(false)

	local styles = ReactSpring.useSpring({
		scale = if isPressed then 0.9 elseif isHovered then 1.1 else 1,
		config = {
			duration = 0.15, -- seconds
			easing = ReactSpring.easings.easeInOutQuad,
		},
	}, { isPressed, props.size, isHovered } :: { any })

	return e("ImageButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Active = true,
		ZIndex = props.layoutOrder or 1,
		LayoutOrder = props.layoutOrder or 1,
		Image = "",
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
		[React.Event.Activated] = props.onActivated,
	}, {
		label = e("ImageLabel", {
			Image = props.image,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}),

		hover = isHovered and e(Tooltip, {
			name = props.name,
			size = UDim2.fromOffset(77, 26),
			startPosition = UDim2.fromScale(0.5, 0.4),
			endPosition = UDim2.fromScale(0.5, 0.05),
			strokeTransparencyEnd = 0.8,
			textSize = 25,
		}),

		scale = e("UIScale", {
			Scale = styles.scale,
		}),

		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0.01, 8),
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 3,
			Transparency = 0.3,
		}, {
			uIGradient = e("UIGradient", {
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

		uIGradient1 = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40)),
			}),
			Rotation = -90,
		}),
	})
end

return React.memo(SideButton)
