--!strict

-- Notification Manager
-- August 6th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.components
local Constants = ReplicatedStorage.constants

local AutomaticFrame = require(Components.frames.AutomaticFrame)
local React = require(Packages.React)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useCallback = React.useCallback

type NotificationManagerProps = Types.FrameProps & {
	padding: UDim,
	maxNotifications: number,
	component: React.ComponentType<any>,
	componentSize: UDim2,
	notificationAdded: any,
	notificationRemoved: any,
}
type NotificationInternal = {
	id: string,
	title: string?,
	duration: number?,
	description: string,
	options: { any }?,
	onDismiss: () -> ()?,
	clickToDismiss: boolean,
	onFade: () -> ()?,
	onHeartbeat: (() -> string)?,
	padding: UDim,
	creationTime: number,
	isActive: boolean,
}

-- // Notification Manager \\

local function NotificationManager(props: NotificationManagerProps)
	local notifications, setNotifications = useState({} :: { NotificationInternal })

	local addNotification = useCallback(function(notification: Types.Notification)
		setNotifications(function(oldNotifications)
			local newNotifications = table.clone(oldNotifications)
			table.insert(newNotifications, 1, {
				key = notification.UUID,
				id = notification.UUID,
				title = notification.Title,
				duration = notification.Duration,
				description = notification.Description,
				options = notification.Options,
				onDismiss = notification.OnDismiss,
				clickToDismiss = if notification.ClickToDismiss ~= nil then notification.ClickToDismiss else React.None,
				onFade = notification.OnFade,
				onHeartbeat = notification.OnHeartbeat,
				padding = props.padding,
				creationTime = os.clock(),
				isActive = true,
			})
			return newNotifications
		end)
	end, { setNotifications, props.padding } :: { any })

	local disableNotification = useCallback(function(id: string)
		setNotifications(function(oldNotifications: { NotificationInternal })
			local newNotifications = table.clone(oldNotifications)
			for i, notification in newNotifications do
				if notification.id == id then
					newNotifications[i] = table.clone(notification)
					newNotifications[i].isActive = false
					break
				end
			end
			return newNotifications
		end)
	end, { setNotifications })

	local removeNotification = useCallback(function(id: string)
		setNotifications(function(oldNotifications: { any })
			local newNotifications = table.clone(oldNotifications)
			for i, notification in newNotifications do
				if notification.id == id then
					table.remove(newNotifications, i)
					break
				end
			end
			return newNotifications
		end)
	end, { setNotifications })

	-- Create the notification elements

	local notificationElements = {}
	for index, notification in notifications do
		-- Check if the notification is still valid.
		local isActive = index <= props.maxNotifications
		if notification.isActive == false then
			isActive = false -- the notification was dismissed manually.
		end
		table.insert(
			notificationElements,
			e(
				props.component,
				Sift.Dictionary.merge(notification, {
					size = props.componentSize,
					isActive = isActive,
					removeNotification = removeNotification,
				})
			)
		)
	end

	useEffect(function()
		local addedConnection = nil
		local removedConnection = nil
		if props.notificationAdded then
			addedConnection = props.notificationAdded:Connect(function(notification: Types.Notification)
				addNotification(notification)
			end)
		end
		if props.notificationRemoved then
			removedConnection = props.notificationRemoved:Connect(function(id: string)
				disableNotification(id)
			end)
		end
		return function()
			if addedConnection then
				addedConnection:Disconnect()
			end
			if removedConnection then
				removedConnection:Disconnect()
			end
		end
	end, { props.notificationAdded, addNotification, disableNotification, props.notificationRemoved })

	return e(AutomaticFrame, {
		instanceProps = {
			BackgroundTransparency = 1,
			Position = props.position,
			AnchorPoint = props.anchorPoint,
		},
	}, {
		listLayout = e("UIListLayout", {
			Padding = props.padding,
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		elements = React.createElement(React.Fragment, nil, notificationElements),
	})
end

return NotificationManager
