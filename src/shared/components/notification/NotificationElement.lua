--!strict

-- Notification Element
-- August 6th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils

local DependencyArray = require(Utils.DependencyArray)
local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local Types = require(Constants.Types)

local e = React.createElement
local useRef = React.useRef
local useBinding = React.useBinding
local useCallback = React.useCallback
local useEffect = React.useEffect

type NotificationElementProps = Types.FrameProps & {
	duration: number,
	id: string,
	removeNotification: (string) -> (),
	creationTime: number,
	padding: UDim,
	onFade: () -> (),
	isActive: boolean,
	options: { any },
	title: string?,
	clickToDismiss: boolean,
	onDismiss: () -> (),
	description: string,
	size: UDim2,
}

-- // Notification Element \\

local function NotificationElement(props: NotificationElementProps)
	local timeLeft, setTimeLeft = useBinding(props.duration)
	local clickClosed = useRef(false)

	local styles, api = ReactSpring.useSpring(function()
		return {
			size = props.size and UDim2.fromOffset(props.size.X.Offset, 0),
			backgroundColor = Color3.fromRGB(25, 25, 25),
			config = { duration = 0.15 },
		}
	end, { props.size })

	local closeNotification = useCallback(function()
		api.start({
			size = UDim2.fromOffset(props.size.X.Offset, -props.padding.Offset),
			config = { duration = 0.15 },
		}):andThen(function()
			props.removeNotification(props.id)
		end)
	end, { props.removeNotification, props.id } :: { any })

	useEffect(
		function()
			local timerDuration = nil
			if props.isActive and clickClosed.current == false then
				-- Open the notification
				api.start({
					size = props.size,
					config = { duration = 0.25 },
				})
				timerDuration = RunService.RenderStepped:Connect(function()
					local timeRemaining = (props.creationTime + props.duration) - os.clock()
					setTimeLeft(timeRemaining)
					if timeRemaining <= 0 and clickClosed.current == false then
						closeNotification()
						if props.onFade then
							props.onFade()
						end
						timerDuration:Disconnect()
					end
				end)
			else
				closeNotification()
			end
			return function()
				if timerDuration and timerDuration.Connected then
					timerDuration:Disconnect()
				end
			end
		end,
		DependencyArray(
			props.isActive,
			setTimeLeft,
			props.onFade,
			closeNotification,
			props.creationTime,
			props.duration,
			props.size,
			clickClosed
		) :: { any }
	)

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = styles.backgroundColor,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Size = styles.size,
	}, {
		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0.1, 0),
		}),
		options = props.options and e("Frame", {
			Position = UDim2.fromScale(0.015, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromScale(0.25, 0.85),
			BackgroundTransparency = 1,
		}, {
			optionElements = React.createElement(React.Fragment, nil, props.options),
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 7),
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),
		timerBar = e("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(1, 1),
			Size = UDim2.fromScale(1, 0.05),
		}, {
			timerBar1 = e("Frame", {
				AnchorPoint = Vector2.new(1, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(1, 1),
				Size = timeLeft:map(function(timeRemaining: number)
					return UDim2.fromScale(timeRemaining / props.duration, 1)
				end),
			}, {
				uIGradient = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 98)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(234, 0, 31)),
					}),
					Rotation = 90,
				}),
				uICorner1 = e("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
				}),
			}),
			uICorner2 = e("UICorner", {
				CornerRadius = UDim.new(0.1, 0),
			}),
		}),
		title = e("TextLabel", {
			Font = Enum.Font.FredokaOne,
			Text = props.title,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.95, 0.32),
			Size = UDim2.fromScale(0.8, 0.3),
		}),
		notificationButton = props.clickToDismiss == true and e("ImageButton", {
			BackgroundTransparency = 1,
			Image = "",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
			[React.Event.Activated] = function()
				clickClosed.current = true -- Avoid this notification returning to the pool if our component re-renders.
				if props.onDismiss then
					props.onDismiss()
				end
				closeNotification()
			end,
			[React.Event.MouseEnter] = function()
				api.start({
					backgroundColor = Color3.fromRGB(50, 50, 50),
					config = { duration = 0.1 },
				})
			end,
			[React.Event.MouseEnter] = function()
				api.start({
					backgroundColor = Color3.fromRGB(25, 25, 25),
					config = { duration = 0.1 },
				})
			end,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
		}),
		description = e("TextLabel", {
			Font = Enum.Font.FredokaOne,
			Text = props.description,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.95, 0.65),
			Size = UDim2.fromScale(0.9, 0.25),
		}),
		uIGradient1 = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(179, 179, 179)),
			}),
			Rotation = 90,
		}),
	})
end

return React.memo(NotificationElement)
