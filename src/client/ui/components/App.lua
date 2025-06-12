--!strict

local Achievements = require("@ui/components/achievements/Achievements")
local AchievementsProvider = require("@ui/providers/AchievementsProvider")
local AutoUIScale = require("@ui/components/other/AutoUIScale")
local ContextStack = require("@utilities/ContextStack")
local CrateClaim = require("@ui/components/shop/crates/CrateClaim")
local CurrentInterfaceProvider = require("@ui/providers/CurrentInterfaceProvider")
local DailyRewards = require("@ui/components/dailyRewards/DailyRewards")
local DistractionViewport = require("@ui/components/round/DistractionViewport")
local GiftingSelectionList = require("@ui/components/shop/GiftingSelectionList")
local GunCounter = require("@ui/components/combat/GunCounter")
local Inventory = require("@ui/components/inventory/Inventory")
local InventoryProvider = require("@ui/providers/InventoryProvider")
local NotificationController = require("@controllers/NotificationController")
local NotificationManager = require("@ui/components/notification/NotificationManager")
local Playerlist = require("@ui/components/playerlist/Playerlist")
local React = require("@packages/React")
local ResourceProvider = require("@ui/providers/ResourceProvider")
local RewardsProvider = require("@ui/providers/RewardsProvider")
local ScaleContext = require("@ui/contexts/ScaleContext")
local Settings = require("@ui/components/settings/Settings")
local SettingsProvider = require("@ui/providers/SettingsProvider")
local Shop = require("@ui/components/shop/Shop")
local ShopProvider = require("@ui/providers/ShopProvider")
local SideButtonHUD = require("@ui/components/other/SideButtonHUD")
local StatisticsProvider = require("@ui/providers/StatisticsProvider")
local StatusText = require("@ui/components/round/StatusText")
local TradeProvider = require("@ui/providers/TradeProvider")
local TradeResults = require("@ui/components/trading/TradeResults")
local Trading = require("@ui/components/trading/Trading")
local TradingPlayerList = require("@ui/components/trading/TradingPlayerList")
local Voting = require("@ui/components/voting/Voting")
local WorldProvider = require("@ui/providers/WorldProvider")

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
			e(WorldProvider),
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
			gunCounter = e(GunCounter),
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
			crateClaim = e(CrateClaim),
			--confirmationPrompt = e(ConfirmationPrompt),
		}),
	})
end

return App
