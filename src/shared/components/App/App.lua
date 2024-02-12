-- App
-- January 21st, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.components
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers
local ActionComponents = Components.action
local ButtonComponents = Components.buttons
local NotificationComponents = Components.notification
local VotingComponents = Components.voting

local ActionPopup = require(ActionComponents.ActionPopup)
local ActionPopupManager = require(ActionComponents.ActionPopupManager)
local AutoUIScale = require(Components.common.AutoUIScale)
local NotificationController = require(Controllers.NotificationController)
local NotificationManager = require(NotificationComponents.NotificationManager)
local PopupController = require(Controllers.PopupController)
local React = require(Packages.React)
local SideButtons = require(ButtonComponents.SideButtons)
local TextNotificationElement = require(NotificationComponents.TextNotificationElement)
local VotingManager = require(VotingComponents.VotingManager)

local e = React.createElement
local useEffect = React.useEffect

local function changeScaleRatio(scaleRatio: number)
	local InterfaceController = require(Controllers.InterfaceController)
	InterfaceController.ScaleRatioChanged:Fire(scaleRatio)
end

-- // App \\

local function App()
	useEffect(function()
		local InterfaceController = require(Controllers.InterfaceController)
		InterfaceController.AppLoaded:Fire() -- Fires when the app is loaded/mounted.
	end, {}) -- only runs on initial mount

	return e("ScreenGui", {
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = 1,
		-- selene: allow(roblox_incorrect_roact_usage)
		Name = "App",
	}, {
		scale = e(AutoUIScale, {
			size = Vector2.new(1920, 1080),
			scale = 1,
			onScaleRatioChanged = changeScaleRatio,
		}),
		hud = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			sideButtons = e(SideButtons),
		}),
		actions = e(ActionPopupManager, {
			size = UDim2.fromScale(1, 1),
			anchorPoint = Vector2.new(0.5, 0.5),
			component = ActionPopup,
			componentSize = UDim2.fromOffset(343, 289),
			maxPopups = 1,
			popupAdded = PopupController.ActionPopupAdded,
			popupRemoved = PopupController.ActionPopupRemoved,
		}),
		voting = e(VotingManager),
		textNotifications = e(NotificationManager, {
			component = TextNotificationElement :: any,
			componentSize = UDim2.fromOffset(700, 55),
			position = UDim2.fromScale(0.5, 0.06),
			notificationAdded = NotificationController.TextNotificationAdded,
			notificationRemoved = NotificationController.TextNotificationRemoved,
			padding = UDim.new(0, 7),
			anchorPoint = Vector2.new(0.5, 0.5),
			maxNotifications = 1,
		}),
	})
end

return App
