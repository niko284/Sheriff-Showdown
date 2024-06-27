--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Contexts = ReplicatedStorage.react.contexts
local Providers = ReplicatedStorage.react.providers

local AutoUIScale = require(Components.other.AutoUIScale)
local ConfirmationPrompt = require(Components.other.ConfirmationPrompt)
local ContextStack = require(ReplicatedStorage.utils.ContextStack)
local CurrentInterfaceProvider = require(Providers.CurrentInterfaceProvider)
local DistractionViewport = require(Components.round.DistractionViewport)
local GiftingSelectionList = require(Components.shop.GiftingSelectionList)
local Inventory = require(Components.inventory.Inventory)
local InventoryProvider = require(Providers.InventoryProvider)
local Playerlist = require(Components.playerlist.Playerlist)
local React = require(ReplicatedStorage.packages.React)
local ScaleContext = require(Contexts.ScaleContext)
local Settings = require(Components.settings.Settings)
local SettingsProvider = require(Providers.SettingsProvider)
local Shop = require(Components.shop.Shop)
local ShopProvider = require(Providers.ShopProvider)
local SideButtonHUD = require(Components.other.SideButtonHUD)

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
}

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
			distractionViewport = e(DistractionViewport),
			playerList = e(Playerlist),
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
			inventory = e(Inventory),
			settings = e(Settings),
			--confirmationPrompt = e(ConfirmationPrompt),
		}),
	})
end

return App
