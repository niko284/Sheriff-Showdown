--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers
local Contexts = ReplicatedStorage.react.contexts
local Components = ReplicatedStorage.react.components

local CurrentInterfaceContext = require(Contexts.CurrentInterfaceContext)
local InterfaceController = require(Controllers.InterfaceController)
local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Tooltip = require(Components.other.Tooltip)
local Types = require(ReplicatedStorage.constants.Types)

local useContext = React.useContext
local e = React.createElement
local useState = React.useState

type SideButtonProps = Types.FrameProps & {
	gradient: ColorSequence,
	icon: string,
	buttonPath: Types.Interface,
}

local function SideButton(props: SideButtonProps)
	local currentInterface = useContext(CurrentInterfaceContext)

	local isHovered, setIsHovered = useState(false)
	local isPressed, setIsPressed = useState(false)

	local iconStyles = ReactSpring.useSpring({
		rotation = if not isHovered then 0 else 25,
		transparency = if isHovered then 0.75 else 0,
		scale = if not isHovered then 1 else 0.92,
		config = {
			--precision = 0,
			--mass = 5,
			--tension = 150,
			duration = 0.2,
		},
	}, { isHovered, isPressed } :: { any })

	local styles = ReactSpring.useSpring({
		scale = if isPressed then 0.9 elseif isHovered then 1.1 else 1,
		config = {
			duration = 0.15, -- seconds
			easing = ReactSpring.easings.easeInOutQuad,
		},
	}, { isPressed, isHovered } :: { any })

	return e("ImageButton", {
		AutoButtonColor = false,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
		[React.Event.Activated] = function()
			if currentInterface.current == props.buttonPath then
				InterfaceController.InterfaceChanged:Fire(nil)
			else
				InterfaceController.InterfaceChanged:Fire(props.buttonPath)
			end
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
		gradient = e("UIGradient", {
			Color = props.gradient,
		}),

		scale = e("UIScale", {
			Scale = styles.scale,
		}),

		hover = isHovered and e(Tooltip, {
			name = props.buttonPath :: string,
			size = UDim2.fromOffset(77, 26),
			startPosition = UDim2.fromScale(0.5, 0.4),
			endPosition = UDim2.fromScale(0.51, 0.05),
			strokeTransparencyEnd = 0.25,
			textSize = 22,
		}),

		stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 15),
		}),

		pattern = e("ImageLabel", {
			Image = "rbxassetid://18128482523",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(78, 78),
		}),

		buttonIcon = e("ImageLabel", {
			Image = props.icon,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(21, 20),
			Size = UDim2.fromOffset(36, 38),
			Rotation = iconStyles.rotation,
			ImageTransparency = iconStyles.transparency,
		}, {
			--[[scale = e("UIScale", {
				Scale = iconStyles.scale,
			}),--]]
		}),
	})
end

return React.memo(SideButton)
