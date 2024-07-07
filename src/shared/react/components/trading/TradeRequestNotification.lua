--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Hooks = ReplicatedStorage.react.hooks

local Button = require(Components.buttons.Button)
local NotificationElement = require(Components.notification.NotificationElement)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)
local usePlayerThumbnail = require(Hooks.usePlayerThumbnail)

local useCallback = React.useCallback
local e = React.createElement

type TradeRequestNotificationProps = {
	playerId: number,
} & Types.NotificationElementPropsGeneric

local function TradeRequestNotification(props: TradeRequestNotificationProps)
	local icon = usePlayerThumbnail(props.playerId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)

	local acceptTradeRequest = useCallback(function() end, {})
	local declineTradeRequest = useCallback(function() end, {})

	return e(NotificationElement, {
		title = props.title,
		description = props.description,
		removeNotification = props.removeNotification,
		onFade = props.onFade,
		creationTime = props.creationTime,
		onDismiss = props.onDismiss,
		id = props.id,
		padding = props.padding,
		duration = props.duration,
		isActive = props.isActive,
		size = UDim2.fromOffset(303, 227),
	}, {
		iconBackground = e("ImageLabel", {
			Image = "rbxassetid://18356322538",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0627, 0.361),
			Size = UDim2.fromScale(0.162, 0.216),
		}, {
			notifIcon = e("ImageLabel", {
				Image = icon,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),
		}),

		deny = e(Button, {
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = "Decline",
			textColor3 = Color3.fromRGB(53, 0, 12),
			textSize = 16,
			position = UDim2.fromScale(0.274, 0.848),
			anchorPoint = Vector2.new(0.5, 0.5),
			size = UDim2.fromScale(0.422, 0.172),
			cornerRadius = UDim.new(0, 5),
			gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(252, 68, 118)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(203, 35, 67)),
			}),
			strokeThickness = 1.5,
			strokeColor = Color3.fromRGB(255, 255, 255),
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			gradientRotation = -90,
			onActivated = declineTradeRequest,
		}),

		accept = e(Button, {
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = "Accept",
			textColor3 = Color3.fromRGB(0, 54, 25),
			anchorPoint = Vector2.new(0.5, 0.5),
			textSize = 16,
			size = UDim2.fromScale(0.422, 0.172),
			position = UDim2.fromScale(0.729, 0.848),
			strokeThickness = 1.5,
			layoutOrder = 1,
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(255, 255, 255),
			cornerRadius = UDim.new(0, 5),
			gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 252, 153)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 203, 112)),
			}),
			gradientRotation = -90,
			onActivated = acceptTradeRequest,
		}),
	})
end

return TradeRequestNotification
