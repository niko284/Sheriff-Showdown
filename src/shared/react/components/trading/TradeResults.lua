--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Contexts = ReplicatedStorage.react.contexts
local Components = ReplicatedStorage.react.components
local Hooks = ReplicatedStorage.react.hooks
local Controllers = LocalPlayer.PlayerScripts.controllers

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local Button = require(Components.buttons.Button)
local InterfaceController = require(Controllers.InterfaceController)
local Item = require(Components.items.Item)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local React = require(ReplicatedStorage.packages.React)
local TradeContext = require(Contexts.TradeContext)
local TradingController = require(Controllers.TradingController)
local Types = require(ReplicatedStorage.constants.Types)
local animateCurrentInterface = require(Hooks.animateCurrentInterface)

local e = React.createElement
local useContext = React.useContext

type TradeResultsProps = {}

local function TradeResults(_props: TradeResultsProps)
	local tradeState = useContext(TradeContext)

	local _shouldRender, styles =
		animateCurrentInterface("TradeProcessed", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local currentTrade = tradeState.currentTrade

	local receivedItemElements = {}
	if currentTrade then
		local receivedItems: { Types.Item } = currentTrade.Sender == LocalPlayer and currentTrade.ReceiverOffer
			or currentTrade.SenderOffer
		for _, item in ipairs(receivedItems) do
			local itemInfo = ItemUtils.GetItemInfoFromId(item.Id)
			receivedItemElements[item.UUID] = e(Item, {
				size = UDim2.fromOffset(115, 115),
				itemUUID = item.UUID,
				image = string.format("rbxassetid://%d", itemInfo.Image),
				rarity = itemInfo.Rarity,
				itemName = itemInfo.Name,
				hideOptions = true,
			})
		end
	end

	return e("ImageLabel", {
		Image = "rbxassetid://18420256226",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = styles.position,
		Size = UDim2.fromOffset(848, 608),
	}, {
		tradeComplete = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Trade Completed",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(327, 168),
			Size = UDim2.fromOffset(198, 21),
		}),

		youReceived = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = "You have received:",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextTransparency = 0.38,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(358, 203),
			Size = UDim2.fromOffset(131, 11),
		}),

		receivedBackground = e(AutomaticScrollingFrame, {
			scrollBarThickness = 5,
			active = true,
			backgroundColor3 = Color3.fromRGB(46, 46, 46),
			borderSizePixel = 0,
			position = UDim2.fromOffset(26, 257),
			size = UDim2.fromOffset(798, 134),
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),

			stroke = e("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.58,
			}),

			listLayout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			items = e(React.Fragment, nil, receivedItemElements :: any),
		}),

		topbar = e("ImageLabel", {
			Image = "rbxassetid://18420183079",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(849, 87),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18420194510",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(849, 87),
			}),

			trading = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Trading\r",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(64, 35),
				Size = UDim2.fromOffset(88, 21),
			}),

			tradingIcon3 = e("ImageLabel", {
				Image = "rbxassetid://18420194779",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(22, 42),
				Size = UDim2.fromOffset(27, 15),
			}),

			tradingIcon2 = e("ImageLabel", {
				Image = "rbxassetid://18420194899",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(32, 30),
				Size = UDim2.fromOffset(8, 8),
			}),

			tradingIcon = e("ImageLabel", {
				Image = "rbxassetid://18420195031",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(30, 36),
				Size = UDim2.fromOffset(12, 17),
			}),
		}),

		accept = e(Button, {
			size = UDim2.fromOffset(793, 58),
			position = UDim2.fromScale(0.504, 0.898),
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = "Accept",
			textColor3 = Color3.fromRGB(0, 54, 25),
			anchorPoint = Vector2.new(0.5, 0.5),
			textSize = 16,
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
			onActivated = function()
				InterfaceController.InterfaceChanged:Fire(nil)
				local newTradeState = table.clone(tradeState)
				tradeState.showTradeSideButton = false
				tradeState.currentTrade = nil
				TradingController.TradeStateChanged:Fire(newTradeState)
			end,
		}),

		checkIcon = e("ImageLabel", {
			Image = "rbxassetid://18420182733",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(411, 129),
			Size = UDim2.fromOffset(25, 20),
		}),

		separator = e("ImageLabel", {
			Image = "rbxassetid://18420256401",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 428),
			Size = UDim2.fromOffset(797, 3),
		}),
	})
end

return TradeResults
