--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hooks = ReplicatedStorage.react.hooks
local Components = ReplicatedStorage.react.components
local Contexts = ReplicatedStorage.react.contexts
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local InterfaceController = require(Controllers.InterfaceController)
local React = require(ReplicatedStorage.packages.React)
local TradeContext = require(Contexts.TradeContext)
local animateCurrentInterface = require(Hooks.animateCurrentInterface)

local e = React.createElement
local useContext = React.useContext
local useEffect = React.useEffect

type TradingProps = {}

local function Trading(_props: TradingProps)
	local _shouldRender, styles =
		animateCurrentInterface("ActiveTrade", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local tradeState = useContext(TradeContext)

	useEffect(function()
		local currentTrade = tradeState.currentTrade
		if currentTrade then
			InterfaceController.InterfaceChanged:Fire("ActiveTrade")
		end
	end, { tradeState })

	return e("ImageLabel", {
		Image = "rbxassetid://18349341250",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = styles.position,
		Size = UDim2.fromOffset(848, 608),
	}, {
		tradingWith = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Trading With Username",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(27, 132),
			Size = UDim2.fromOffset(276, 21),
		}),

		topbar = e("ImageLabel", {
			Image = "rbxassetid://18349391822",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(849, 87),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18349341421",
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

			tradeIcon3 = e("ImageLabel", {
				Image = "rbxassetid://18349342236",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(32, 30),
				Size = UDim2.fromOffset(8, 8),
			}),

			tradeIcon2 = e("ImageLabel", {
				Image = "rbxassetid://18349342382",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(30, 36),
				Size = UDim2.fromOffset(12, 17),
			}),

			tradeIcon1 = e("ImageLabel", {
				Image = "rbxassetid://18349353841",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(22, 42),
				Size = UDim2.fromOffset(27, 15),
			}),
		}),

		yourItems = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Your Items",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 216),
			Size = UDim2.fromOffset(91, 12),
		}),

		theirItems = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Username’s Items",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(565, 216),
			Size = UDim2.fromOffset(149, 12),
		}),

		denyButton = e("ImageLabel", {
			Image = "rbxassetid://18349354114",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(537, 121),
			Size = UDim2.fromOffset(137, 44),
		}, {
			deny = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Deny",
				TextColor3 = Color3.fromRGB(54, 0, 12),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(48, 16),
				Size = UDim2.fromOffset(43, 15),
			}),
		}),

		flowArrow2 = e("ImageLabel", {
			Image = "rbxassetid://18349354330",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(408, 385),
			Size = UDim2.fromOffset(32, 32),
		}),

		acceptButton = e("ImageLabel", {
			Image = "rbxassetid://18349354480",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(681, 121),
			Size = UDim2.fromOffset(137, 44),
		}, {
			accept = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Accept",
				TextColor3 = Color3.fromRGB(0, 54, 25),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(41, 16),
				Size = UDim2.fromOffset(59, 15),
			}),
		}),

		flowArrow1 = e("ImageLabel", {
			Image = "rbxassetid://18349366976",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(408, 345),
			Size = UDim2.fromOffset(32, 32),
		}),

		separator = e("ImageLabel", {
			Image = "rbxassetid://18349354566",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 188),
			Size = UDim2.fromOffset(797, 3),
		}),

		itemList = e(AutomaticScrollingFrame, {
			scrollBarThickness = 8,
			active = true,
			backgroundTransparency = 1,
			position = UDim2.fromScale(0.658, 0.413),
			size = UDim2.fromOffset(276, 268),
		}, {
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 3),
				PaddingTop = UDim.new(0, 3),
			}),

			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(7, 7),
				CellSize = UDim2.fromOffset(126, 126),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),

		itemList1 = e(AutomaticScrollingFrame, {
			scrollBarThickness = 8,
			active = true,
			backgroundTransparency = 1,
			position = UDim2.fromScale(0.0259, 0.413),
			size = UDim2.fromOffset(276, 268),
		}, {
			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(7, 7),
				CellSize = UDim2.fromOffset(126, 126),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 3),
				PaddingTop = UDim.new(0, 3),
			}),
		}),
	})
end

return Trading
