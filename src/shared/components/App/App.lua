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

local ActionPopup = require(ActionComponents.ActionPopup)
local ActionPopupManager = require(ActionComponents.ActionPopupManager)
local AutoUIScale = require(Components.common.AutoUIScale)
local PopupController = require(Controllers.PopupController)
local React = require(Packages.React)

local e = React.createElement

local function changeScaleRatio(scaleRatio: number)
	local InterfaceController = require(Controllers.InterfaceController) :: any -- no circular dependency :(
	InterfaceController.ScaleRatioChanged:Fire(scaleRatio)
end

-- // App \\

local function App()
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
		actions = e(ActionPopupManager, {
			size = UDim2.fromScale(1, 1),
			anchorPoint = Vector2.new(0.5, 0.5),
			component = ActionPopup,
			componentSize = UDim2.fromOffset(343, 289),
			maxPopups = 1,
			popupAdded = PopupController.ActionPopupAdded,
			popupRemoved = PopupController.ActionPopupRemoved,
		}),
	})
end

return App
