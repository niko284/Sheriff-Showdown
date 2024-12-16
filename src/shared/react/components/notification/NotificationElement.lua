--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DependencyArray = require(ReplicatedStorage.utils.DependencyArray)
local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useRef = React.useRef
local useBinding = React.useBinding
local useEffect = React.useEffect
local useCallback = React.useCallback

type NotificationElementProps = Types.FrameProps & Types.NotificationElementPropsGeneric & { size: UDim2, children: any }

local function NotificationElement(props: NotificationElementProps)
	local _timeLeft, setTimeLeft = useBinding(props.duration)
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

	return e("ImageLabel", {
		Image = "rbxassetid://18356322141",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = styles.size,
	}, {
		topbar = e("ImageLabel", {
			Image = "rbxassetid://18356322260",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.286),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18356322392",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),

			title = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.title,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 19,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.0726, 0.385),
				Size = UDim2.fromScale(0.386, 0.246),
			}),
		}),

		children = e(React.Fragment, nil, props.children),

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
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
		}),

		notificationDescription = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = props.description,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.267, 0.396),
			Size = UDim2.fromScale(0.545, 0.119),
		}),

		separator = e("ImageLabel", {
			Image = "rbxassetid://18356333672",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0627, 0.665),
			Size = UDim2.fromScale(0.878, 0.0176),
		}),
	})
end

return React.memo(NotificationElement)
