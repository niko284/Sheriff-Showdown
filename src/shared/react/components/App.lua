--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Contexts = ReplicatedStorage.react.contexts
local Providers = ReplicatedStorage.react.providers
local LocalPlayer = Players.LocalPlayer

local Controllers = LocalPlayer.PlayerScripts.controllers

local Achievements = require(Components.achievements.Achievements)
local AchievementsProvider = require(Providers.AchievementsProvider)
local AutoUIScale = require(Components.other.AutoUIScale)
local ContextStack = require(ReplicatedStorage.utils.ContextStack)
local CurrentInterfaceProvider = require(Providers.CurrentInterfaceProvider)
local DailyRewards = require(Components.dailyRewards.DailyRewards)
local DistractionViewport = require(Components.round.DistractionViewport)
local GiftingSelectionList = require(Components.shop.GiftingSelectionList)
local Inventory = require(Components.inventory.Inventory)
local InventoryProvider = require(Providers.InventoryProvider)
local NotificationController = require(Controllers.NotificationController)
local NotificationManager = require(Components.notification.NotificationManager)
local Playerlist = require(Components.playerlist.Playerlist)
local React = require(ReplicatedStorage.packages.React)
local ResourceProvider = require(Providers.ResourceProvider)
local RewardsProvider = require(Providers.RewardsProvider)
local ScaleContext = require(Contexts.ScaleContext)
local Settings = require(Components.settings.Settings)
local SettingsProvider = require(Providers.SettingsProvider)
local Shop = require(Components.shop.Shop)
local ShopProvider = require(Providers.ShopProvider)
local SideButtonHUD = require(Components.other.SideButtonHUD)
local StatisticsProvider = require(Providers.StatisticsProvider)
local TradeProvider = require(Providers.TradeProvider)
local TradeResults = require(Components.trading.TradeResults)
local Trading = require(Components.trading.Trading)
local TradingPlayerList = require(Components.trading.TradingPlayerList)
local Voting = require(Components.voting.Voting)
local StatusText = require(Components.round.StatusText)

local e = React.createElement
local useState = React.useState

local SIDE_BUTTONS = {
	Inventory = {
		Image = "rbxassetid://18128564282",
		Gradient = ColorSequence.new(Color3.fromRGB(220, 234, 58)),
		LayoutOrder = 2,
	},
	Shop = {
		Image = "rbxassetid://18128752359",
		Gradient = ColorSequence.new(Color3.fromRGB(58, 234, 119), Color3.fromRGB(43, 255, 149)),
		LayoutOrder = 1,
	},
	Settings = {
		Image = "rbxassetid://18222701262",
		LayoutOrder = 3,
		Gradient = ColorSequence.new(Color3.fromRGB(43, 43, 43), Color3.fromRGB(20, 20, 20)),
	},
	Trading = {
		Image = "rbxassetid://18355952247",
		LayoutOrder = 5,
		Gradient = ColorSequence.new(Color3.fromRGB(54, 185, 255)),
		Opacity = 0.11,
	},
	Achievements = {
		Image = "rbxassetid://18592966271",
		LayoutOrder = 4,
		Gradient = ColorSequence.new(Color3.fromRGB(255, 223, 46)),
	},
} :: { [any]: any }

local function App()
	local currentScale, setScale = useState(1)

	return e(ContextStack, {
		providers = {
			e(ScaleContext.Provider, {
				value = {
					scale = currentScale,
				},
			}),
			e(InventoryProvider),
			e(CurrentInterfaceProvider),
			e(SettingsProvider),
			e(AchievementsProvider),
			e(ResourceProvider),
			e(TradeProvider),
			e(StatisticsProvider),
			e(RewardsProvider),
		},
	}, {
		App = e("ScreenGui", {
			IgnoreGuiInset = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ResetOnSpawn = false,
			DisplayOrder = 1,
		}, {
			autoScale = e(AutoUIScale, {
				scale = currentScale,
				size = Vector2.new(1920, 1080),
				onScaleRatioChanged = function(newScale)
					setScale(newScale)
				end,
			}),
			tradeResults = e(TradeResults),
			distractionViewport = e(DistractionViewport),
			playerList = e(Playerlist),
			tradingList = e(TradingPlayerList),
			achievements = e(Achievements),
			globalNotifications = e(NotificationManager, {
				componentSize = UDim2.fromOffset(345, 81),
				position = UDim2.fromScale(0.99, 0.985),
				anchorPoint = Vector2.new(1, 1),
				notificationAdded = NotificationController.GlobalNotificationAdded,
				notificationRemoved = NotificationController.GlobalNotificationRemoved,
				padding = UDim.new(0, 7),
				maxNotifications = 8,
			}),
			shopProvider = e(ContextStack, {
				providers = {
					e(ShopProvider),
				},
			}, {
				shop = e(Shop),
				gifting = e(GiftingSelectionList),
			}),
			sideButtons = e(SideButtonHUD, {
				buttons = SIDE_BUTTONS,
			}),
			voting = e(Voting),
			inventory = e(Inventory),
			statusText = e(StatusText),
			trading = e(Trading),
			settings = e(Settings),
			dailyRewards = e(DailyRewards),
			--confirmationPrompt = e(ConfirmationPrompt),
		}),
	})
end

return App
