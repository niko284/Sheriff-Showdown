--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers
local Contexts = ReplicatedStorage.react.contexts

local InterfaceController = require(Controllers.InterfaceController)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local React = require(ReplicatedStorage.packages.React)
local TradeContext = require(Contexts.TradeContext)
local TradingController = require(Controllers.TradingController)
local Types = require(ReplicatedStorage.constants.Types)

local useCallback = React.useCallback
local useContext = React.useContext
local e = React.createElement

type TradeItemTemplateProps = {
	canAddItem: boolean, -- is this element allowed to add items (if false, it will be a placeholder/visual)
	item: Types.Item?,
	tradeUUID: string,
}

local function TradeItemTemplate(props: TradeItemTemplateProps)
	local itemInfo: Types.ItemInfo? = props.item and ItemUtils.GetItemInfoFromId(props.item.Id)

	local tradeState = useContext(TradeContext)

	local openTradeInventory = useCallback(function()
		local newTradeState = table.clone(tradeState)
		newTradeState.isInInventory = true
		TradingController.TradeStateChanged:Fire(newTradeState)
		InterfaceController.InterfaceChanged:Fire("Inventory")
	end, { tradeState, props.tradeUUID } :: { any })

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(100, 100),
	}, {
		addIcon = props.canAddItem and e("ImageLabel", {
			Image = "rbxassetid://18349367356",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(44, 44),
			Size = UDim2.fromOffset(37, 37),
		}),

		addButton = props.canAddItem and props.item and e("ImageButton", {
			Image = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			[React.Event.Activated] = function()
				openTradeInventory()
			end,
		}),

		itemImage = itemInfo and e("ImageLabel", {
			Image = string.format("rbxassetid://%d", itemInfo.Image),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.9),
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 0.5,
		}),
	})
end

return React.memo(TradeItemTemplate)
