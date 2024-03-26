--!strict
-- Text Notification Element
-- November 8th, 2023
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

local useEffect = React.useEffect
local useCallback = React.useCallback
local useRef = React.useRef
local e = React.createElement
local useState = React.useState

-- // Text Notification Element \\

type NotificationElementProps = Types.FrameProps & {
	duration: number?,
	id: string,
	removeNotification: (string) -> (),
	onHeartbeat: (() -> string)?,
	creationTime: number,
	padding: UDim,
	onFade: () -> (),
	isActive: boolean,
	richText: boolean?,
	options: { any },
	clickToDismiss: boolean,
	onDismiss: () -> (),
	description: string,
	size: UDim2,
}

local function TextNotificationElement(props: NotificationElementProps)
	local text, setText = useState(props.description)
	local clickClosed = useRef(false)

	local styles, api = ReactSpring.useSpring(function()
		return {
			size = props.size and UDim2.fromOffset(props.size.X.Offset, 0),
			textTransparency = 0,
			config = { duration = 0.25 },
		}
	end, { props.size })

	local closeNotification = useCallback(function()
		api.start({
			size = UDim2.fromOffset(props.size.X.Offset, -props.padding.Offset),
			textTransparency = 1,
			config = { duration = 0.25 },
		}):andThen(function()
			props.removeNotification(props.id)
		end)
	end, { props.removeNotification, props.id, api } :: { any })

	useEffect(
		function()
			local timerDuration = nil
			if props.isActive and clickClosed.current == false then
				-- Open the notification
				api.start({
					size = props.size,
					config = { duration = 0.25 },
				})
				if props.duration then
					timerDuration = RunService.RenderStepped:Connect(function()
						local timeRemaining = (props.creationTime + props.duration) - os.clock()

						if props.onHeartbeat then
							setText(props.onHeartbeat())
						end

						if timeRemaining <= 0 and clickClosed.current == false then
							closeNotification()
							if props.onFade then
								props.onFade()
							end
							timerDuration:Disconnect()
						end
					end)
				end
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
			props.onFade,
			closeNotification,
			props.creationTime,
			props.duration,
			props.size,
			clickClosed,
			setText,
			props.onHeartbeat
		) :: { any }
	)

	return e("TextLabel", {
		RichText = true,
		Text = text,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Font = Enum.Font.FredokaOne,
		TextTransparency = styles.textTransparency,
		TextSize = styles.size:map(function(size)
			-- get percent of size
			local percent = size.Y.Offset / props.size.Y.Offset
			return percent > 0 and percent * 25 or 0
		end),
		Size = styles.size,
	}, {
		dismissButton = props.clickToDismiss and e("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Text = "",
			[React.Event.Activated] = function()
				clickClosed.current = true -- Avoid this notification returning to the pool if our component re-renders.
				if props.onDismiss then
					props.onDismiss()
				end
				closeNotification()
			end,
		}),
		stroke = e("UIStroke", {
			Color = Color3.fromRGB(0, 0, 0),
			Thickness = 2,
		}),
	})
end

return React.memo(TextNotificationElement)
