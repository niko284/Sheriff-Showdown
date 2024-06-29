--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Types = require(ReplicatedStorage.constants.Types)

local useState = React.useState
local e = React.createElement

export type ButtonProps = Types.FrameProps & {
	text: string,
	textColor3: Color3,
	gradient: ColorSequence?,
	cornerRadius: UDim,
	textSize: number,
	fontFace: Font,
	applyStrokeMode: Enum.ApplyStrokeMode,
	strokeColor: Color3,
	strokeThickness: number,
	gradientRotation: number,
	strokeTransparency: number?,
	onActivated: (TextButton) -> (),
}

local function Button(props: ButtonProps)
	local isHovered, setIsHovered = useState(false)
	local isPressed, setIsPressed = useState(false)

	local styles = ReactSpring.useSpring({
		scale = if isPressed then 0.98 elseif isHovered then 1.02 else 1,
		config = {
			duration = 0.1, -- seconds
			easing = ReactSpring.easings.easeInOutQuad,
		},
	}, { isPressed, isHovered } :: { any })

	return e("TextButton", {
		AutoButtonColor = false,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = props.backgroundTransparency,
		FontFace = props.fontFace,
		Text = props.text,
		TextColor3 = props.textColor3,
		LayoutOrder = props.layoutOrder,
		TextSize = props.textSize,
		BackgroundColor3 = props.backgroundColor3 or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = props.position,
		ZIndex = props.zIndex,
		Size = props.size,
		[React.Event.Activated] = function(rbx: TextButton)
			props.onActivated(rbx)
		end,
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
	}, {
		scale = e("UIScale", {
			Scale = styles.scale,
		}),
		corner = e("UICorner", {
			CornerRadius = props.cornerRadius,
		}),
		stroke = e("UIStroke", {
			ApplyStrokeMode = props.applyStrokeMode,
			Color = props.strokeColor,
			Thickness = props.strokeThickness,
			Transparency = props.strokeTransparency,
		}),
		gradient = props.gradient and e("UIGradient", {
			Color = props.gradient,
			Rotation = props.gradientRotation,
		}),
	})
end

return React.memo(Button)
